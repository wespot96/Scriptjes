<#
.SYNOPSIS
	Appends system usage information to a text log file.
.DESCRIPTION
	Writes a timestamped snapshot containing overall CPU usage, top 5 processes
	by short-interval CPU usage, overall RAM usage, and top 5 processes by RAM
	usage. The script is intended to run on Windows Server and defaults to
	storing both the script and log file in D:\Logs.
.PARAMETER LogDirectory
	Directory where the log file is stored. Defaults to D:\Logs.
.PARAMETER LogFileName
	Name of the text log file. Defaults to SystemUsageLog.txt.
.PARAMETER SampleSeconds
	CPU sampling window in seconds used to estimate top CPU-consuming
	processes. Defaults to 1 second.
.PARAMETER EnableRamAlert
	When set to $true, sends an email alert if RAM usage is above the alert
	threshold.
.PARAMETER RamAlertThresholdPercent
	RAM usage percentage that triggers the email alert. Defaults to 80.
.PARAMETER SmtpServer
	SMTP server used for sending the RAM alert email.
.PARAMETER SmtpPort
	SMTP port used for sending the RAM alert email. Defaults to 25.
.PARAMETER MailTo
	Recipient address for the RAM alert email.
.PARAMETER MailFrom
	Sender address for the RAM alert email.
.EXAMPLE
	.\LogSystem-usage.ps1
.EXAMPLE
	.\LogSystem-usage.ps1 -LogDirectory 'D:\Logs' -LogFileName 'Usage.txt'
#>

[CmdletBinding()]
param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$LogDirectory = 'D:\Logs',

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$LogFileName = 'SystemUsageLog.txt',

	[Parameter()]
	[ValidateRange(1, 30)]
	[int]$SampleSeconds = 1,

	[Parameter()]
	[bool]$EnableRamAlert = $false,

	[Parameter()]
	[ValidateRange(1, 100)]
	[int]$RamAlertThresholdPercent = 80,

	[Parameter()]
	[string]$SmtpServer = 'smtp.yourdomain.local',

	[Parameter()]
	[ValidateRange(1, 65535)]
	[int]$SmtpPort = 25,

	[Parameter()]
	[string]$MailTo = 'admin@yourdomain.local',

	[Parameter()]
	[string]$MailFrom = 'server-monitor@yourdomain.local'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Format-Percent {
	param(
		[Parameter(Mandatory)]
		[double]$Value
	)

	return ('{0:N2}%' -f $Value)
}

function Format-SizeGB {
	param(
		[Parameter(Mandatory)]
		[double]$Value
	)

	return ('{0:N2} GB' -f $Value)
}

function Get-TopCpuProcesses {
	param(
		[Parameter(Mandatory)]
		[int]$IntervalSeconds,

		[Parameter()]
		[int]$Top = 5
	)

	$logicalProcessorCount = [Environment]::ProcessorCount

	$startSample = @{}
	foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
		$cpuValue = if ($null -ne $process.CPU) { [double]$process.CPU } else { 0.0 }
		$startSample[$process.Id] = [pscustomobject]@{
			Name = $process.ProcessName
			CPU  = $cpuValue
		}
	}

	Start-Sleep -Seconds $IntervalSeconds

	$results = foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
		if (-not $startSample.ContainsKey($process.Id)) {
			continue
		}

		$endCpu = if ($null -ne $process.CPU) { [double]$process.CPU } else { 0.0 }
		$startCpu = $startSample[$process.Id].CPU
		$deltaCpu = $endCpu - $startCpu

		if ($deltaCpu -lt 0) {
			continue
		}

		$cpuPercent = 0.0
		if ($logicalProcessorCount -gt 0 -and $IntervalSeconds -gt 0) {
			$cpuPercent = ($deltaCpu / $IntervalSeconds) * 100 / $logicalProcessorCount
		}

		[pscustomobject]@{
			Name       = $process.ProcessName
			Id         = $process.Id
			CpuPercent = [math]::Round($cpuPercent, 2)
		}
	}

	return $results |
		Sort-Object -Property CpuPercent -Descending |
		Select-Object -First $Top
}

function Send-RamAlertEmail {
	param(
		[Parameter(Mandatory)]
		[double]$UsedPercent,

		[Parameter(Mandatory)]
		[double]$UsedGigabytes,

		[Parameter(Mandatory)]
		[double]$TotalGigabytes,

		[Parameter(Mandatory)]
		[object[]]$TopProcesses
	)

	if ([string]::IsNullOrWhiteSpace($SmtpServer) -or
		[string]::IsNullOrWhiteSpace($MailTo) -or
		[string]::IsNullOrWhiteSpace($MailFrom)) {
		throw 'RAM alert email is enabled, but SmtpServer, MailTo, or MailFrom is not configured.'
	}

	$processLines = if ($TopProcesses.Count -eq 0) {
		'No RAM process data available.'
	}
	else {
		($TopProcesses | ForEach-Object {
			'{0,-25} PID {1,-8} {2,10}' -f $_.Name, $_.Id, (Format-SizeGB -Value $_.MemoryGB)
		}) -join [Environment]::NewLine
	}

	$subject = "[$env:COMPUTERNAME] RAM usage alert: $(Format-Percent -Value $UsedPercent)"
	$body = @"
Server: $env:COMPUTERNAME
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
RAM Usage: $(Format-Percent -Value $UsedPercent)
Memory Used: $(Format-SizeGB -Value $UsedGigabytes) of $(Format-SizeGB -Value $TotalGigabytes)

Top 5 Processes by RAM Usage:
$processLines
"@

	Send-MailMessage `
		-To $MailTo `
		-From $MailFrom `
		-Subject $subject `
		-Body $body `
		-SmtpServer $SmtpServer `
		-Port $SmtpPort
}

if (-not (Test-Path -Path $LogDirectory)) {
	New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

$logPath = Join-Path -Path $LogDirectory -ChildPath $LogFileName
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

$totalMemoryBytes = [double]$os.TotalVisibleMemorySize * 1KB
$freeMemoryBytes = [double]$os.FreePhysicalMemory * 1KB
$usedMemoryBytes = $totalMemoryBytes - $freeMemoryBytes
$usedMemoryPercent = if ($totalMemoryBytes -gt 0) {
	($usedMemoryBytes / $totalMemoryBytes) * 100
}
else {
	0
}

$topCpuProcesses = Get-TopCpuProcesses -IntervalSeconds $SampleSeconds -Top 5
$topRamProcesses = Get-Process -ErrorAction SilentlyContinue |
	Sort-Object -Property WorkingSet64 -Descending |
	Select-Object -First 5 |
	ForEach-Object {
		[pscustomobject]@{
			Name     = $_.ProcessName
			Id       = $_.Id
			MemoryGB = [math]::Round($_.WorkingSet64 / 1GB, 2)
		}
	}

$logLines = [System.Collections.Generic.List[string]]::new()
$logLines.Add(('=' * 72))
$logLines.Add("Timestamp: $timestamp")
$logLines.Add("ComputerName: $env:COMPUTERNAME")
$logLines.Add("CPU Usage: $(Format-Percent -Value $cpuUsage)")
$logLines.Add("RAM Usage: $(Format-Percent -Value $usedMemoryPercent) ($(Format-SizeGB -Value ($usedMemoryBytes / 1GB)) used of $(Format-SizeGB -Value ($totalMemoryBytes / 1GB)))")
$logLines.Add('')
$logLines.Add('Top 5 Processes by CPU Usage:')

if ($topCpuProcesses.Count -eq 0) {
	$logLines.Add('  No CPU process data available.')
}
else {
	foreach ($process in $topCpuProcesses) {
		$logLines.Add(('  {0,-25} PID {1,-8} {2,8}' -f $process.Name, $process.Id, (Format-Percent -Value $process.CpuPercent)))
	}
}

$logLines.Add('')
$logLines.Add('Top 5 Processes by RAM Usage:')

if ($topRamProcesses.Count -eq 0) {
	$logLines.Add('  No RAM process data available.')
}
else {
	foreach ($process in $topRamProcesses) {
		$logLines.Add(('  {0,-25} PID {1,-8} {2,10}' -f $process.Name, $process.Id, (Format-SizeGB -Value $process.MemoryGB)))
	}
}

$logLines.Add('')
Add-Content -Path $logPath -Value $logLines

if ($EnableRamAlert -and $usedMemoryPercent -ge $RamAlertThresholdPercent) {
	Send-RamAlertEmail `
		-UsedPercent $usedMemoryPercent `
		-UsedGigabytes ($usedMemoryBytes / 1GB) `
		-TotalGigabytes ($totalMemoryBytes / 1GB) `
		-TopProcesses $topRamProcesses
}

Write-Host "Usage snapshot appended to $logPath"

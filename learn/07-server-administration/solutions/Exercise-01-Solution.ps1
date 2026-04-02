<#
.SYNOPSIS
    Solution — Exercise 01: Server Health Check
.DESCRIPTION
    Collects CPU, RAM, disk, and event-log data from the local server and
    outputs a structured health report with colour-coded status indicators.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.NOTES
    Module  : 07-server-administration
    Exercise: 01 (Solution)
#>

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Thresholds ────────────────────────────────────────────────────────────────
$CpuWarnPercent  = 80
$CpuCritPercent  = 95
$DiskWarnPercent = 90
$DiskCritPercent = 95
$RamWarnPercent  = 85

# ── Helper ────────────────────────────────────────────────────────────────────
function Get-StatusLabel {
    param(
        [double]$Value,
        [double]$WarnThreshold,
        [double]$CritThreshold
    )
    if ($Value -ge $CritThreshold) { return 'CRITICAL' }
    if ($Value -ge $WarnThreshold) { return 'WARNING'  }
    return 'OK'
}

function Write-StatusLine {
    param([string]$Label, [string]$Text, [string]$Status)
    $color = switch ($Status) {
        'CRITICAL' { 'Red'    }
        'WARNING'  { 'Yellow' }
        default    { 'Green'  }
    }
    Write-Host ("  {0,-18} {1}  [{2}]" -f $Label, $Text, $Status) -ForegroundColor $color
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1 — CPU Usage
# ══════════════════════════════════════════════════════════════════════════════
$cpuLoad = (Get-CimInstance Win32_Processor |
    Measure-Object -Property LoadPercentage -Average).Average

$cpuStatus = Get-StatusLabel -Value $cpuLoad `
    -WarnThreshold $CpuWarnPercent -CritThreshold $CpuCritPercent

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2 — RAM Usage
# ══════════════════════════════════════════════════════════════════════════════
$os = Get-CimInstance Win32_OperatingSystem

# TotalVisibleMemorySize and FreePhysicalMemory are in KB.
# Dividing KB by 1MB (1 048 576) gives GB.
$ramTotalGB     = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$ramFreeGB      = [Math]::Round($os.FreePhysicalMemory     / 1MB, 2)
$ramUsedGB      = [Math]::Round($ramTotalGB - $ramFreeGB, 2)
$ramUsedPercent = [Math]::Round(($ramUsedGB / $ramTotalGB) * 100, 1)

$ramStatus = Get-StatusLabel -Value $ramUsedPercent `
    -WarnThreshold $RamWarnPercent -CritThreshold 95

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3 — Disk Space
# ══════════════════════════════════════════════════════════════════════════════
$diskReport = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    ForEach-Object {
        $totalGB     = [Math]::Round($_.Size      / 1GB, 2)
        $freeGB      = [Math]::Round($_.FreeSpace  / 1GB, 2)
        $usedPercent = if ($_.Size -gt 0) {
            [Math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
        } else { 0 }

        [PSCustomObject]@{
            DeviceID    = $_.DeviceID
            TotalGB     = $totalGB
            FreeGB      = $freeGB
            UsedPercent = $usedPercent
            Status      = Get-StatusLabel -Value $usedPercent `
                            -WarnThreshold $DiskWarnPercent `
                            -CritThreshold $DiskCritPercent
        }
    }

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4 — Recent Error Events
# ══════════════════════════════════════════════════════════════════════════════
$errorEvents = @()
try {
    # Level 2 = Error in the System event log
    $errorEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level   = 2
    } -MaxEvents 10 |
        Select-Object TimeCreated, Id, ProviderName,
            @{ Name = 'Message'; Expression = { $_.Message.Split("`n")[0] } }
}
catch {
    # No matching events — safe to continue
    Write-Verbose "No System error events found: $_"
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5 — Assemble & Output Report
# ══════════════════════════════════════════════════════════════════════════════
$report = [PSCustomObject]@{
    ComputerName   = $env:COMPUTERNAME
    ReportTime     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    CpuLoadPercent = $cpuLoad
    CpuStatus      = $cpuStatus
    RamTotalGB     = $ramTotalGB
    RamUsedGB      = $ramUsedGB
    RamFreeGB      = $ramFreeGB
    RamUsedPercent = $ramUsedPercent
    RamStatus      = $ramStatus
    DiskReport     = $diskReport
    ErrorEvents    = $errorEvents
}

# ── Console output ───────────────────────────────────────────────────────────
Write-Host ''
Write-Host '═══ Server Health Report ═══' -ForegroundColor Cyan
Write-Host ("  Computer:  {0}" -f $report.ComputerName)
Write-Host ("  Time:      {0}" -f $report.ReportTime)
Write-Host ''

Write-StatusLine -Label 'CPU Load:' `
    -Text ("{0}%" -f $report.CpuLoadPercent) -Status $report.CpuStatus

Write-StatusLine -Label 'RAM Used:' `
    -Text ("{0} / {1} GB ({2}%)" -f $report.RamUsedGB, $report.RamTotalGB, $report.RamUsedPercent) `
    -Status $report.RamStatus

Write-Host ''
Write-Host '  ── Disk Space ──' -ForegroundColor Cyan
foreach ($disk in $report.DiskReport) {
    Write-StatusLine -Label ("  {0}" -f $disk.DeviceID) `
        -Text ("{0} GB free of {1} GB ({2}% used)" -f $disk.FreeGB, $disk.TotalGB, $disk.UsedPercent) `
        -Status $disk.Status
}

Write-Host ''
Write-Host '  ── Recent System Errors ──' -ForegroundColor Cyan
if ($report.ErrorEvents.Count -eq 0) {
    Write-Host '  No error events found.' -ForegroundColor Green
}
else {
    $report.ErrorEvents | Format-Table -AutoSize | Out-String | Write-Host
}

# Return the report object for pipeline use
$report

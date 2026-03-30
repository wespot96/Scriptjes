<#
.SYNOPSIS
    Server Health Dashboard Script
.DESCRIPTION
    Collects CPU, RAM, disk, uptime, event logs, services, top processes,
    and network adapter stats, then outputs a styled HTML dashboard report.
.PARAMETER OutputPath
    Path for the HTML report. Defaults to the script directory.
.PARAMETER ComputerName
    Target computer. Defaults to localhost.
.PARAMETER EventLogHours
    How many hours back to pull event log entries. Defaults to 24.
.EXAMPLE
    .\ServerHealthDashboard.ps1
    .\ServerHealthDashboard.ps1 -ComputerName "SERVER01" -EventLogHours 48
#>

[CmdletBinding()]
param(
    [string]$OutputPath   = (Join-Path $PSScriptRoot "ServerHealthReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"),
    [string]$ComputerName = $env:COMPUTERNAME,
    [int]$EventLogHours   = 24
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Helper ──────────────────────────────────────────────────────────────
function Get-ColorClass {
    param([double]$Value, [double]$WarnThreshold = 75, [double]$CritThreshold = 90)
    if ($Value -ge $CritThreshold) { return 'crit' }
    if ($Value -ge $WarnThreshold) { return 'warn' }
    return 'ok'
}

function Format-Bytes {
    param([long]$Bytes)
    switch ($Bytes) {
        { $_ -ge 1TB } { return "{0:N2} TB" -f ($_ / 1TB) }
        { $_ -ge 1GB } { return "{0:N2} GB" -f ($_ / 1GB) }
        { $_ -ge 1MB } { return "{0:N2} MB" -f ($_ / 1MB) }
        default        { return "{0:N2} KB" -f ($_ / 1KB) }
    }
}

function New-GaugeBar {
    param([double]$Percent, [string]$Class)
    $pct = [math]::Round($Percent, 1)
    return @"
<div class="bar-wrap"><div class="bar $Class" style="width:$pct%"></div></div>
<span class="pct $Class">$pct%</span>
"@
}
#endregion

#region ── Data Collection ─────────────────────────────────────────────────────
Write-Host "[*] Collecting data from $ComputerName ..." -ForegroundColor Cyan

$sb = {
    param($EventLogHours)

    $report = @{}

    # ── OS / Uptime ──────────────────────────────────────────────────────────
    $os      = Get-CimInstance Win32_OperatingSystem
    $cs      = Get-CimInstance Win32_ComputerSystem
    $bios    = Get-CimInstance Win32_BIOS
    $uptime  = (Get-Date) - $os.LastBootUpTime
    $report.OS = [ordered]@{
        ComputerName  = $env:COMPUTERNAME
        OSName        = $os.Caption
        OSVersion     = $os.Version
        Architecture  = $os.OSArchitecture
        Manufacturer  = $cs.Manufacturer
        Model         = $cs.Model
        BIOSVersion   = $bios.SMBIOSBIOSVersion
        LoggedOnUsers = (Get-CimInstance Win32_ComputerSystem).UserName
        LastBoot      = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
        Uptime        = '{0}d {1}h {2}m' -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        TimeZone      = [System.TimeZoneInfo]::Local.DisplayName
        ReportTime    = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }

    # ── CPU ──────────────────────────────────────────────────────────────────
    $cpuLoad    = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $cpuInfo    = Get-CimInstance Win32_Processor | Select-Object -First 1
    $report.CPU = [ordered]@{
        Name         = $cpuInfo.Name.Trim()
        Cores        = $cpuInfo.NumberOfCores
        LogicalProcs = $cpuInfo.NumberOfLogicalProcessors
        MaxSpeedMHz  = $cpuInfo.MaxClockSpeed
        LoadPercent  = [math]::Round($cpuLoad, 1)
    }

    # ── RAM ──────────────────────────────────────────────────────────────────
    $totalRAM   = $os.TotalVisibleMemorySize * 1KB
    $freeRAM    = $os.FreePhysicalMemory   * 1KB
    $usedRAM    = $totalRAM - $freeRAM
    $ramPct     = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    $report.RAM = [ordered]@{
        TotalBytes  = $totalRAM
        UsedBytes   = $usedRAM
        FreeBytes   = $freeRAM
        UsedPercent = $ramPct
    }

    # ── Disk ─────────────────────────────────────────────────────────────────
    $report.Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $pct = if ($_.Size -gt 0) { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1) } else { 0 }
            [ordered]@{
                DeviceID    = $_.DeviceID
                VolumeName  = $_.VolumeName
                FileSystem  = $_.FileSystem
                TotalBytes  = $_.Size
                FreeBytes   = $_.FreeSpace
                UsedBytes   = $_.Size - $_.FreeSpace
                UsedPercent = $pct
            }
        }

    # ── Network Adapters ─────────────────────────────────────────────────────
    $report.Network = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" |
        ForEach-Object {
            [ordered]@{
                Description = $_.Description
                MACAddress  = $_.MACAddress
                IPAddresses = ($_.IPAddress -join ', ')
                DNSServers  = ($_.DNSServerSearchOrder -join ', ')
                DHCP        = $_.DHCPEnabled
            }
        }

    # ── Top 10 Processes by CPU ───────────────────────────────────────────────
    $report.TopProcessesCPU = Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [ordered]@{
                Name        = $_.Name
                PID         = $_.Id
                CPU         = [math]::Round($_.CPU, 2)
                WorkingSetMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
            }
        }

    # ── Top 10 Processes by RAM ───────────────────────────────────────────────
    $report.TopProcessesRAM = Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [ordered]@{
                Name         = $_.Name
                PID          = $_.Id
                CPU          = [math]::Round($_.CPU, 2)
                WorkingSetMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
            }
        }

    # ── Critical / Important Services ────────────────────────────────────────
    $criticalServices = @(
        'wuauserv','WinDefend','EventLog','Schedule','LanmanServer',
        'LanmanWorkstation','Dnscache','RemoteRegistry','BITS','W32Time',
        'Spooler','TermService','WSearch','Winmgmt','RpcSs'
    )
    $report.Services = foreach ($svc in $criticalServices) {
        try {
            $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($s) {
                [ordered]@{ Name = $s.Name; DisplayName = $s.DisplayName; Status = $s.Status.ToString() }
            }
        } catch { }
    }

    # ── Event Logs (Errors & Warnings, last N hours) ──────────────────────────
    $since = (Get-Date).AddHours(-$EventLogHours)
    $logs  = @('System','Application')
    $report.EventLogs = foreach ($log in $logs) {
        try {
            Get-EventLog -LogName $log -EntryType Error,Warning -After $since -Newest 50 -ErrorAction SilentlyContinue |
                ForEach-Object {
                    [ordered]@{
                        Log       = $log
                        TimeGen   = $_.TimeGenerated.ToString('yyyy-MM-dd HH:mm:ss')
                        EntryType = $_.EntryType.ToString()
                        Source    = $_.Source
                        EventID   = $_.EventID
                        Message   = ($_.Message -replace '\r?\n', ' ').Substring(0, [math]::Min(200, $_.Message.Length))
                    }
                }
        } catch { }
    }

    return $report
}

# Run locally or via PSRemoting
if ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq 'localhost') {
    $data = & $sb -EventLogHours $EventLogHours
} else {
    $data = Invoke-Command -ComputerName $ComputerName -ScriptBlock $sb -ArgumentList $EventLogHours
}
#endregion

#region ── HTML Generation ─────────────────────────────────────────────────────
Write-Host "[*] Building HTML report ..." -ForegroundColor Cyan

$cpuClass  = Get-ColorClass -Value $data.CPU.LoadPercent
$ramClass  = Get-ColorClass -Value $data.RAM.UsedPercent
$cpuGauge  = New-GaugeBar   -Percent $data.CPU.LoadPercent -Class $cpuClass
$ramGauge  = New-GaugeBar   -Percent $data.RAM.UsedPercent -Class $ramClass

# ── Disk rows ────────────────────────────────────────────────────────────────
$diskRows = foreach ($d in $data.Disks) {
    $dc    = Get-ColorClass -Value $d.UsedPercent
    $gauge = New-GaugeBar   -Percent $d.UsedPercent -Class $dc
    $volLabel = if ($d.VolumeName) { $d.VolumeName } else { '—' }
    @"
<tr>
  <td><strong>$($d.DeviceID)</strong></td>
  <td>$volLabel</td>
  <td>$($d.FileSystem)</td>
  <td>$(Format-Bytes $d.TotalBytes)</td>
  <td>$(Format-Bytes $d.UsedBytes)</td>
  <td>$(Format-Bytes $d.FreeBytes)</td>
  <td>$gauge</td>
</tr>
"@
}

# ── Network rows ─────────────────────────────────────────────────────────────
$netRows = foreach ($n in $data.Network) {
    $dhcp = if ($n.DHCP) { 'Yes' } else { 'No' }
    @"
<tr>
  <td>$($n.Description)</td>
  <td>$($n.MACAddress)</td>
  <td>$($n.IPAddresses)</td>
  <td>$($n.DNSServers)</td>
  <td>$dhcp</td>
</tr>
"@
}

# ── Top process rows (CPU) ────────────────────────────────────────────────────
$procCPURows = foreach ($p in $data.TopProcessesCPU) {
    "<tr><td>$($p.Name)</td><td>$($p.PID)</td><td>$($p.CPU)s</td><td>$($p.WorkingSetMB) MB</td></tr>"
}

# ── Top process rows (RAM) ────────────────────────────────────────────────────
$procRAMRows = foreach ($p in $data.TopProcessesRAM) {
    "<tr><td>$($p.Name)</td><td>$($p.PID)</td><td>$($p.CPU)s</td><td>$($p.WorkingSetMB) MB</td></tr>"
}

# ── Service rows ──────────────────────────────────────────────────────────────
$svcRows = foreach ($s in $data.Services) {
    $sc = if ($s.Status -eq 'Running') { 'badge-ok' } else { 'badge-crit' }
    "<tr><td>$($s.DisplayName)</td><td>$($s.Name)</td><td><span class='badge $sc'>$($s.Status)</span></td></tr>"
}

# ── Event log rows ────────────────────────────────────────────────────────────
$evtRows = foreach ($e in $data.EventLogs) {
    $ec = if ($e.EntryType -eq 'Error') { 'badge-crit' } else { 'badge-warn' }
    @"
<tr>
  <td>$($e.Log)</td>
  <td>$($e.TimeGen)</td>
  <td><span class='badge $ec'>$($e.EntryType)</span></td>
  <td>$($e.Source)</td>
  <td>$($e.EventID)</td>
  <td class="msg-cell" title="$([System.Web.HttpUtility]::HtmlEncode($e.Message))">$($e.Message)</td>
</tr>
"@
}

if (-not $evtRows) {
    $evtRows = "<tr><td colspan='6' style='text-align:center;color:#6b7280'>No errors or warnings in the past $EventLogHours hours.</td></tr>"
}

# ── OS info rows ──────────────────────────────────────────────────────────────
$osRows = $data.OS.GetEnumerator() | ForEach-Object {
    "<tr><td>$($_.Key)</td><td>$($_.Value)</td></tr>"
}

# ── HTML Document ─────────────────────────────────────────────────────────────
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Server Health Dashboard – $($data.OS.ComputerName)</title>
<style>
  :root {
    --bg:#0f172a; --surface:#1e293b; --surface2:#273549;
    --border:#334155; --text:#e2e8f0; --muted:#94a3b8;
    --ok:#22c55e; --warn:#f59e0b; --crit:#ef4444;
    --accent:#38bdf8; --radius:8px;
  }
  *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
  body { background:var(--bg); color:var(--text); font-family:'Segoe UI',system-ui,sans-serif; font-size:14px; }
  header { background:linear-gradient(135deg,#0ea5e9,#6366f1); padding:24px 32px; }
  header h1 { font-size:1.6rem; font-weight:700; letter-spacing:.5px; }
  header p  { color:rgba(255,255,255,.75); margin-top:4px; font-size:.9rem; }
  main { max-width:1400px; margin:0 auto; padding:24px 16px; }

  /* KPI cards */
  .kpi-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(180px,1fr)); gap:16px; margin-bottom:28px; }
  .kpi { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:16px 20px; }
  .kpi-label { font-size:.75rem; color:var(--muted); text-transform:uppercase; letter-spacing:.8px; }
  .kpi-value { font-size:1.6rem; font-weight:700; margin-top:4px; }
  .kpi-sub   { font-size:.78rem; color:var(--muted); margin-top:2px; }

  /* Gauge bar */
  .bar-wrap { background:var(--surface2); border-radius:20px; height:8px; overflow:hidden; margin-bottom:4px; }
  .bar      { height:8px; border-radius:20px; transition:width .4s ease; }
  .bar.ok   { background:var(--ok); }
  .bar.warn { background:var(--warn); }
  .bar.crit { background:var(--crit); }
  .pct      { font-size:.78rem; font-weight:600; }
  .pct.ok   { color:var(--ok); }
  .pct.warn { color:var(--warn); }
  .pct.crit { color:var(--crit); }

  /* Sections */
  .section { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); margin-bottom:24px; }
  .section-header { padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:10px; }
  .section-header h2 { font-size:1rem; font-weight:600; }
  .section-body { padding:16px 20px; overflow-x:auto; }

  /* Tables */
  table { width:100%; border-collapse:collapse; }
  th { text-align:left; padding:8px 12px; background:var(--surface2); color:var(--muted); font-size:.75rem; text-transform:uppercase; letter-spacing:.6px; position:sticky; top:0; }
  td { padding:8px 12px; border-top:1px solid var(--border); vertical-align:top; }
  tr:hover td { background:var(--surface2); }
  .msg-cell { max-width:360px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; cursor:help; }

  /* Badges */
  .badge { display:inline-block; padding:2px 10px; border-radius:20px; font-size:.73rem; font-weight:600; }
  .badge-ok   { background:rgba(34,197,94,.15);  color:var(--ok); }
  .badge-warn { background:rgba(245,158,11,.15); color:var(--warn); }
  .badge-crit { background:rgba(239,68,68,.15);  color:var(--crit); }

  /* Pill icons */
  .icon { font-size:1.2rem; }

  footer { text-align:center; color:var(--muted); font-size:.78rem; padding:20px 0 32px; }
</style>
</head>
<body>
<header>
  <h1>&#x1F5A5;&nbsp; Server Health Dashboard</h1>
  <p>Host: <strong>$($data.OS.ComputerName)</strong> &nbsp;|&nbsp; $($data.OS.OSName) &nbsp;|&nbsp; Report generated: $($data.OS.ReportTime)</p>
</header>
<main>

<!-- KPI Cards -->
<div class="kpi-grid">
  <div class="kpi">
    <div class="kpi-label">CPU Load</div>
    <div class="kpi-value $cpuClass">$($data.CPU.LoadPercent)%</div>
    <div class="kpi-sub">$($data.CPU.Cores) cores / $($data.CPU.LogicalProcs) threads</div>
  </div>
  <div class="kpi">
    <div class="kpi-label">RAM Used</div>
    <div class="kpi-value $ramClass">$($data.RAM.UsedPercent)%</div>
    <div class="kpi-sub">$(Format-Bytes $data.RAM.UsedBytes) / $(Format-Bytes $data.RAM.TotalBytes)</div>
  </div>
  <div class="kpi">
    <div class="kpi-label">Uptime</div>
    <div class="kpi-value" style="font-size:1.1rem;padding-top:6px">$($data.OS.Uptime)</div>
    <div class="kpi-sub">Since $($data.OS.LastBoot)</div>
  </div>
  <div class="kpi">
    <div class="kpi-label">Event Log Errors</div>
    <div class="kpi-value $(if(($data.EventLogs | Where-Object {$_.EntryType -eq 'Error'}).Count -gt 0){'crit'}else{'ok'})">
      $(($data.EventLogs | Where-Object {$_.EntryType -eq 'Error'}).Count)
    </div>
    <div class="kpi-sub">Last $EventLogHours hours (Sys + App)</div>
  </div>
  <div class="kpi">
    <div class="kpi-label">Warnings</div>
    <div class="kpi-value $(if(($data.EventLogs | Where-Object {$_.EntryType -eq 'Warning'}).Count -gt 0){'warn'}else{'ok'})">
      $(($data.EventLogs | Where-Object {$_.EntryType -eq 'Warning'}).Count)
    </div>
    <div class="kpi-sub">Last $EventLogHours hours (Sys + App)</div>
  </div>
  <div class="kpi">
    <div class="kpi-label">Services Monitored</div>
    <div class="kpi-value">$(@($data.Services).Count)</div>
    <div class="kpi-sub">$((@($data.Services) | Where-Object {$_.Status -ne 'Running'}).Count) not running</div>
  </div>
</div>

<!-- CPU & RAM -->
<div class="section">
  <div class="section-header"><span class="icon">&#x1F4BB;</span><h2>CPU &amp; Memory</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Metric</th><th>Detail</th><th style="min-width:220px">Usage</th></tr></thead>
      <tbody>
        <tr>
          <td><strong>CPU</strong></td>
          <td>$($data.CPU.Name) — $($data.CPU.MaxSpeedMHz) MHz</td>
          <td>$cpuGauge</td>
        </tr>
        <tr>
          <td><strong>RAM</strong></td>
          <td>$(Format-Bytes $data.RAM.UsedBytes) used of $(Format-Bytes $data.RAM.TotalBytes) &nbsp;($(Format-Bytes $data.RAM.FreeBytes) free)</td>
          <td>$ramGauge</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>

<!-- Disk -->
<div class="section">
  <div class="section-header"><span class="icon">&#x1F4BE;</span><h2>Disk Usage</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Drive</th><th>Label</th><th>FS</th><th>Total</th><th>Used</th><th>Free</th><th style="min-width:200px">Usage</th></tr></thead>
      <tbody>$diskRows</tbody>
    </table>
  </div>
</div>

<!-- Network -->
<div class="section">
  <div class="section-header"><span class="icon">&#x1F310;</span><h2>Network Adapters</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Adapter</th><th>MAC</th><th>IP Address(es)</th><th>DNS Servers</th><th>DHCP</th></tr></thead>
      <tbody>$netRows</tbody>
    </table>
  </div>
</div>

<!-- Processes CPU -->
<div class="section">
  <div class="section-header"><span class="icon">&#x26A1;</span><h2>Top 10 Processes — CPU Time</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Process</th><th>PID</th><th>CPU Time</th><th>Working Set</th></tr></thead>
      <tbody>$procCPURows</tbody>
    </table>
  </div>
</div>

<!-- Processes RAM -->
<div class="section">
  <div class="section-header"><span class="icon">&#x1F9E0;</span><h2>Top 10 Processes — Memory</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Process</th><th>PID</th><th>CPU Time</th><th>Working Set</th></tr></thead>
      <tbody>$procRAMRows</tbody>
    </table>
  </div>
</div>

<!-- Services -->
<div class="section">
  <div class="section-header"><span class="icon">&#x2699;&#xFE0F;</span><h2>Critical Services</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Display Name</th><th>Service Name</th><th>Status</th></tr></thead>
      <tbody>$svcRows</tbody>
    </table>
  </div>
</div>

<!-- Event Logs -->
<div class="section">
  <div class="section-header"><span class="icon">&#x1F4CB;</span><h2>Event Log — Errors &amp; Warnings (last $EventLogHours hours)</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Log</th><th>Time</th><th>Type</th><th>Source</th><th>Event ID</th><th>Message (truncated)</th></tr></thead>
      <tbody>$evtRows</tbody>
    </table>
  </div>
</div>

<!-- OS Info -->
<div class="section">
  <div class="section-header"><span class="icon">&#x2139;&#xFE0F;</span><h2>System Information</h2></div>
  <div class="section-body">
    <table>
      <thead><tr><th>Property</th><th>Value</th></tr></thead>
      <tbody>$osRows</tbody>
    </table>
  </div>
</div>

</main>
<footer>Generated by ServerHealthDashboard.ps1 &nbsp;|&nbsp; $($data.OS.ReportTime)</footer>
</body>
</html>
"@
#endregion

#region ── Output ──────────────────────────────────────────────────────────────
$html | Out-File -FilePath $OutputPath -Encoding utf8 -Force
Write-Host "[+] Report saved to: $OutputPath" -ForegroundColor Green

# Auto-open in default browser
try {
    Start-Process $OutputPath
} catch {
    Write-Warning "Could not auto-open the report. Open it manually: $OutputPath"
}
#endregion

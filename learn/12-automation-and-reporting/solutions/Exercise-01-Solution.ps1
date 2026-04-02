<#
.SYNOPSIS
    Solution for Exercise 01 - HTML Server Report Generator

.DESCRIPTION
    Complete, working implementation that collects disk, service, and event
    log data, then generates a styled HTML report with color-coded status
    rows and multiple sections, saved to a timestamped file.

    Inspired by ServerHealthDashboard.ps1 but simplified for learning.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 12-Automation-and-Reporting
    Author : PowerShell Learning Series
#>

[CmdletBinding()]
param(
    [string]$OutputDirectory = $PSScriptRoot,

    [string]$ComputerName = $env:COMPUTERNAME,

    [ValidateRange(1, 168)]
    [int]$EventLogHours = 24
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Build the timestamped output path
$reportPath = Join-Path $OutputDirectory "ServerReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

#region ── CSS Stylesheet ──────────────────────────────────────────────────────

$css = @"
<style>
    body {
        font-family: Arial, sans-serif;
        background-color: #f4f6f9;
        margin: 0;
        padding: 20px 40px;
        color: #333;
    }
    h1 {
        color: #2c3e50;
        border-bottom: 3px solid #4472C4;
        padding-bottom: 10px;
    }
    h2 {
        color: #4472C4;
        margin-top: 0;
    }
    table {
        border-collapse: collapse;
        width: 100%;
        background-color: #fff;
    }
    th {
        background-color: #4472C4;
        color: #fff;
        padding: 10px 12px;
        text-align: left;
        font-size: 0.85rem;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    td {
        border: 1px solid #ddd;
        padding: 8px 12px;
    }
    tr:hover td {
        background-color: #eef2f7;
    }
    .status-ok {
        background-color: #d4edda;
    }
    .status-warning {
        background-color: #fff3cd;
    }
    .status-critical {
        background-color: #f8d7da;
    }
    .report-header {
        margin-bottom: 30px;
    }
    .report-header p {
        color: #555;
        margin: 4px 0;
    }
    .section {
        background-color: #fff;
        border: 1px solid #ddd;
        border-radius: 6px;
        padding: 20px;
        margin-bottom: 30px;
    }
    footer {
        text-align: center;
        color: #888;
        font-size: 0.8rem;
        padding: 20px 0;
    }
</style>
"@

#endregion

#region ── Data Collection ─────────────────────────────────────────────────────

Write-Verbose "Collecting disk information from $ComputerName..."

# Disk information
$diskData = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" `
                          -ComputerName $ComputerName -ErrorAction Stop |
    ForEach-Object {
        $totalGB    = [math]::Round($_.Size / 1GB, 2)
        $freeGB     = [math]::Round($_.FreeSpace / 1GB, 2)
        $usedGB     = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
        $pctUsed    = if ($_.Size -gt 0) {
                          [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
                      } else { 0 }

        $status = if ($pctUsed -ge 90) { 'Critical' }
                  elseif ($pctUsed -ge 75) { 'Warning' }
                  else { 'OK' }

        [PSCustomObject]@{
            Drive       = $_.DeviceID
            TotalGB     = $totalGB
            FreeGB      = $freeGB
            UsedGB      = $usedGB
            PercentUsed = $pctUsed
            Status      = $status
        }
    }

Write-Verbose "Collecting service status..."

# Service status
$serviceNames = @(
    'wuauserv', 'EventLog', 'Schedule', 'Spooler',
    'WinDefend', 'LanmanServer', 'Dnscache', 'W32Time'
)

$serviceData = foreach ($name in $serviceNames) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($null -ne $svc) {
        [PSCustomObject]@{
            ServiceName = $svc.Name
            DisplayName = $svc.DisplayName
            Status      = $svc.Status.ToString()
            StatusClass = if ($svc.Status -eq 'Running') { 'status-ok' } else { 'status-critical' }
        }
    }
    else {
        [PSCustomObject]@{
            ServiceName = $name
            DisplayName = 'N/A'
            Status      = 'NotFound'
            StatusClass = 'status-critical'
        }
    }
}

Write-Verbose "Collecting event log entries (last $EventLogHours hours)..."

# Event log errors and warnings
$since     = (Get-Date).AddHours(-$EventLogHours)
$logNames  = @('System', 'Application')
$eventData = @()

foreach ($logName in $logNames) {
    try {
        $entries = Get-EventLog -LogName $logName -EntryType Error, Warning `
                                -After $since -Newest 25 -ErrorAction SilentlyContinue
        foreach ($entry in $entries) {
            $msgTruncated = ($entry.Message -replace '\r?\n', ' ')
            if ($msgTruncated.Length -gt 150) {
                $msgTruncated = $msgTruncated.Substring(0, 150) + '...'
            }
            $eventData += [PSCustomObject]@{
                Log     = $logName
                Time    = $entry.TimeGenerated.ToString('yyyy-MM-dd HH:mm:ss')
                Type    = $entry.EntryType.ToString()
                Source  = $entry.Source
                EventID = $entry.EventID
                Message = $msgTruncated
            }
        }
    }
    catch {
        Write-Verbose "Could not read $logName log: $_"
    }
}

#endregion

#region ── HTML Report Assembly ────────────────────────────────────────────────

# Disk rows with color-coding
$diskRows = foreach ($d in $diskData) {
    $cssClass = switch ($d.Status) {
        'Critical' { 'status-critical' }
        'Warning'  { 'status-warning' }
        default    { 'status-ok' }
    }
    @"
<tr class="$cssClass">
  <td>$($d.Drive)</td>
  <td>$($d.TotalGB)</td>
  <td>$($d.UsedGB)</td>
  <td>$($d.FreeGB)</td>
  <td>$($d.PercentUsed)%</td>
  <td>$($d.Status)</td>
</tr>
"@
}

# Service rows with color-coding
$serviceRows = foreach ($s in $serviceData) {
    @"
<tr class="$($s.StatusClass)">
  <td>$($s.ServiceName)</td>
  <td>$($s.DisplayName)</td>
  <td>$($s.Status)</td>
</tr>
"@
}

# Event log rows with color-coding
if ($eventData.Count -gt 0) {
    $eventRows = foreach ($e in $eventData) {
        $evtClass = if ($e.Type -eq 'Error') { 'status-critical' } else { 'status-warning' }
        @"
<tr class="$evtClass">
  <td>$($e.Log)</td>
  <td>$($e.Time)</td>
  <td>$($e.Type)</td>
  <td>$($e.Source)</td>
  <td>$($e.EventID)</td>
  <td>$($e.Message)</td>
</tr>
"@
    }
}
else {
    $eventRows = "<tr><td colspan='6' style='text-align:center;color:#888'>No errors or warnings in the last $EventLogHours hours.</td></tr>"
}

# Assemble the full HTML document
$html = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Server Report - $ComputerName</title>
  $css
</head>
<body>
  <div class="report-header">
    <h1>&#x1F5A5; Server Health Report</h1>
    <p><strong>Computer:</strong> $ComputerName</p>
    <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
  </div>

  <div class="section">
    <h2>&#x1F4BE; Disk Usage</h2>
    <table>
      <tr>
        <th>Drive</th><th>Total GB</th><th>Used GB</th>
        <th>Free GB</th><th>% Used</th><th>Status</th>
      </tr>
      $($diskRows -join "`n")
    </table>
  </div>

  <div class="section">
    <h2>&#x2699;&#xFE0F; Critical Services</h2>
    <table>
      <tr>
        <th>Service</th><th>Display Name</th><th>Status</th>
      </tr>
      $($serviceRows -join "`n")
    </table>
  </div>

  <div class="section">
    <h2>&#x1F4CB; Event Log &mdash; Errors &amp; Warnings (last $EventLogHours hours)</h2>
    <table>
      <tr>
        <th>Log</th><th>Time</th><th>Type</th>
        <th>Source</th><th>Event ID</th><th>Message</th>
      </tr>
      $($eventRows -join "`n")
    </table>
  </div>

  <footer>Generated by Exercise-01-Solution.ps1 | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</footer>
</body>
</html>
"@

#endregion

#region ── Save Report ─────────────────────────────────────────────────────────

$html | Out-File -FilePath $reportPath -Encoding utf8 -Force
Write-Host "Report saved to: $reportPath" -ForegroundColor Green

#endregion

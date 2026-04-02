<#
.SYNOPSIS
    Exercise 01 Solution - Log File Parser

.DESCRIPTION
    Complete solution for the Log File Parser exercise.  Demonstrates
    Select-String, -match with capture groups, -replace, -split, the -f
    format operator, and here-strings to parse a Combined Log Format
    sample and produce a summary report.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 03 - Strings and Regular Expressions
    File   : Exercise-01-Solution.ps1
    Type   : Solution (fully working)

.EXAMPLE
    .\Exercise-01-Solution.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Sample Data Generation ─────────────────────────────────────────
$sampleLog = @(
    '192.168.1.10 - - [15/Jan/2025:08:12:34 +0000] "GET /index.html HTTP/1.1" 200 5123'
    '10.0.0.55 - - [15/Jan/2025:08:12:35 +0000] "POST /api/login HTTP/1.1" 401 312'
    '192.168.1.10 - - [15/Jan/2025:08:13:01 +0000] "GET /dashboard HTTP/1.1" 200 10245'
    '172.16.0.3 - - [15/Jan/2025:08:13:45 +0000] "GET /api/users HTTP/1.1" 500 0'
    '10.0.0.55 - - [15/Jan/2025:08:14:02 +0000] "GET /favicon.ico HTTP/1.1" 404 0'
    '192.168.1.10 - - [15/Jan/2025:08:14:30 +0000] "POST /api/data HTTP/1.1" 200 834'
    '172.16.0.3 - - [15/Jan/2025:08:15:12 +0000] "GET /reports HTTP/1.1" 403 0'
    '10.0.0.99 - - [15/Jan/2025:08:15:45 +0000] "GET /index.html HTTP/1.1" 200 5123'
    '10.0.0.55 - - [15/Jan/2025:08:16:00 +0000] "POST /api/login HTTP/1.1" 401 312'
    '172.16.0.3 - - [15/Jan/2025:08:16:22 +0000] "GET /api/users HTTP/1.1" 500 0'
    '192.168.1.10 - - [15/Jan/2025:08:17:05 +0000] "GET /style.css HTTP/1.1" 304 0'
    '10.0.0.99 - - [15/Jan/2025:08:17:30 +0000] "DELETE /api/session HTTP/1.1" 200 28'
)
#endregion

# ── TASK 1 — Extract fields from each log line ──────────────────────────
# Pattern captures: IP, timestamp, method, path, status code, size.
$logPattern = '^(\S+) .+ \[(.+?)\] "(\S+) (\S+) .+?" (\d{3}) (\d+)$'

$parsedEntries = @()
foreach ($line in $sampleLog) {
    if ($line -match $logPattern) {
        $parsedEntries += [PSCustomObject]@{
            IP           = $Matches[1]
            Timestamp    = $Matches[2]
            Method       = $Matches[3]
            Path         = $Matches[4]
            StatusCode   = $Matches[5]
            Size         = [int]$Matches[6]
            FriendlyTime = ''          # populated in Task 4
        }
    }
}

Write-Host "Parsed $($parsedEntries.Count) log entries." -ForegroundColor Cyan

# ── TASK 2 — Identify error entries (4xx / 5xx) ─────────────────────────
# StatusCode is a string; match codes starting with 4 or 5.
$errorEntries = $parsedEntries | Where-Object { $_.StatusCode -match '^[45]\d{2}$' }

# ── TASK 3 — Unique IP addresses ────────────────────────────────────────
$uniqueIPs = $parsedEntries | Select-Object -ExpandProperty IP -Unique

# ── TASK 4 — Clean timestamps with -replace ─────────────────────────────
# Raw : 15/Jan/2025:08:12:34 +0000
# Goal: 2025-Jan-15 08:12:34
foreach ($entry in $parsedEntries) {
    $entry.FriendlyTime = $entry.Timestamp -replace `
        '(\d{2})/(\w{3})/(\d{4}):(\d{2}:\d{2}:\d{2}) .+', '$3-$2-$1 $4'
}

# ── TASK 5 — Requests and errors per IP ─────────────────────────────────
$ipGroups = $parsedEntries | Group-Object -Property IP

$perIpLines = @()
foreach ($group in $ipGroups) {
    $ip       = $group.Name
    $total    = $group.Count
    $errors   = @($group.Group | Where-Object { $_.StatusCode -match '^[45]' }).Count
    # -f with column widths: IP 18 left, Requests 8 right, Errors 6 right
    $perIpLines += "{0,-18} {1,8} {2,6}" -f $ip, $total, $errors
}

# ── TASK 6 — Select-String for 10.0.0.* subnet ─────────────────────────
$subnetMatches = $sampleLog | Select-String -Pattern '^10\.0\.0\.\d+'
Write-Host "`nLines from 10.0.0.* subnet: $($subnetMatches.Count)" -ForegroundColor Cyan

# ── TASK 7 — Build the summary report with a here-string ────────────────
$errorDetail = ($errorEntries | ForEach-Object {
    "  {0,-20} {1,-18} {2,4} {3}" -f $_.FriendlyTime, $_.IP, $_.StatusCode, $_.Path
}) -join "`n"

$perIpTable = $perIpLines -join "`n"

$report = @"
========================================
       LOG FILE ANALYSIS REPORT
========================================
Total Lines Parsed : $($parsedEntries.Count)
Unique IP Addresses: $($uniqueIPs.Count)
Error Entries (4xx/5xx): $($errorEntries.Count)

── Requests Per IP ────────────────────
{0,-18} {1,8} {2,6}
{3,-18} {4,8} {5,6}
$perIpTable

── Error Details ──────────────────────
  {6,-20} {7,-18} {8,4} {9}
  {10,-20} {11,-18} {12,4} {13}
$errorDetail

========================================
Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
"@ -f 'IP Address', 'Requests', 'Errors', `
     ('─' * 18), ('─' * 8), ('─' * 6), `
     'Timestamp', 'IP Address', 'Code', 'Path', `
     ('─' * 20), ('─' * 18), ('─' * 4), ('─' * 20)

Write-Output $report

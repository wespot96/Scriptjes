<#
.SYNOPSIS
    File Inventory Report — scan a directory and produce a summary of its contents.

.DESCRIPTION
    Recursively enumerates files under a target directory, then reports:
      - Overall file count and total size
      - Breakdown by file extension (count and size)
      - Files older than a configurable threshold
      - Files larger than a configurable threshold
      - Specific summary of *.log files

    Uses Get-ChildItem, Where-Object, Measure-Object, and Group-Object.

    Target: Windows Server 2022 / PowerShell 5.1 — no external modules required.

.PARAMETER Path
    Root directory to inventory. Defaults to the current working directory.

.PARAMETER OlderThanDays
    Flag files whose LastWriteTime is more than this many days ago.
    Default: 30

.PARAMETER LargerThanMB
    Flag files whose size exceeds this threshold (in megabytes).
    Default: 10

.EXAMPLE
    .\Exercise-01-Solution.ps1 -Path "C:\Logs"

.EXAMPLE
    .\Exercise-01-Solution.ps1 -Path "C:\Data" -OlderThanDays 90 -LargerThanMB 50
#>

param(
    [Parameter()]
    [string]$Path = $PWD,

    [Parameter()]
    [int]$OlderThanDays = 30,

    [Parameter()]
    [int]$LargerThanMB = 10
)

# ── 0. Validate the target path ────────────────────────────────────────
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "Path '$Path' does not exist or is not a directory."
    exit 1
}

$resolvedPath = (Resolve-Path -Path $Path).Path

# ── 1. Enumerate all files recursively ─────────────────────────────────
$allFiles = Get-ChildItem -Path $resolvedPath -Recurse -File -ErrorAction SilentlyContinue

if (-not $allFiles) {
    Write-Host "No files found under '$resolvedPath'."
    exit 0
}

# ── 2. Overall summary ─────────────────────────────────────────────────
$stats = $allFiles | Measure-Object -Property Length -Sum
$totalSizeMB = [Math]::Round($stats.Sum / 1MB, 2)

Write-Host "`n=== File Inventory Report for $resolvedPath ==="
Write-Host "Total files : $($stats.Count)"
Write-Host "Total size  : $totalSizeMB MB"

# ── 3. Group files by extension ─────────────────────────────────────────
Write-Host "`n--- Breakdown by Extension ---"

$allFiles |
    Group-Object -Property Extension |
    ForEach-Object {
        $groupSize = ($_.Group | Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Extension = if ($_.Name) { $_.Name } else { '(none)' }
            Count     = $_.Count
            SizeMB    = [Math]::Round($groupSize / 1MB, 2)
        }
    } |
    Sort-Object -Property SizeMB -Descending |
    Format-Table -AutoSize

# ── 4. Find old files (older than $OlderThanDays) ──────────────────────
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
$oldFiles   = $allFiles | Where-Object { $_.LastWriteTime -lt $cutoffDate }

Write-Host "--- Files Older Than $OlderThanDays Days (before $($cutoffDate.ToString('yyyy-MM-dd'))) ---"

if ($oldFiles) {
    $oldCount = ($oldFiles | Measure-Object).Count
    Write-Host "Found $oldCount file(s)."
    Write-Host "Top 10 largest:"

    $oldFiles |
        Sort-Object -Property Length -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [PSCustomObject]@{
                Name          = $_.Name
                SizeMB        = [Math]::Round($_.Length / 1MB, 2)
                LastWriteTime = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            }
        } |
        Format-Table -AutoSize
}
else {
    Write-Host "No files older than $OlderThanDays days.`n"
}

# ── 5. Find large files (larger than $LargerThanMB) ────────────────────
$thresholdBytes = $LargerThanMB * 1MB
$largeFiles     = $allFiles | Where-Object { $_.Length -gt $thresholdBytes }

Write-Host "--- Files Larger Than $LargerThanMB MB ---"

if ($largeFiles) {
    $largeCount = ($largeFiles | Measure-Object).Count
    Write-Host "Found $largeCount file(s)."

    $largeFiles |
        Sort-Object -Property Length -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                FullName      = $_.FullName
                SizeMB        = [Math]::Round($_.Length / 1MB, 2)
                LastWriteTime = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            }
        } |
        Format-Table -AutoSize
}
else {
    Write-Host "No files larger than $LargerThanMB MB.`n"
}

# ── 6. Find *.log files specifically ────────────────────────────────────
$logFiles = $allFiles | Where-Object { $_.Extension -eq '.log' }
$logStats = $logFiles | Measure-Object -Property Length -Sum

$logSizeMB = if ($logStats.Sum) { [Math]::Round($logStats.Sum / 1MB, 2) } else { 0 }
Write-Host "Log files: $($logStats.Count)  Total size: $logSizeMB MB"

# ── 7. Print completion message ─────────────────────────────────────────
Write-Host "`n=== Report complete ==="

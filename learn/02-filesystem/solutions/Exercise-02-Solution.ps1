<#
.SYNOPSIS
    Directory Cleanup Tool — move old files into a date-organized backup and compress them.

.DESCRIPTION
    Scans a source directory for files older than a configurable threshold,
    moves them into a backup tree organized by year and month, compresses
    each month folder into a .zip archive, and prints a summary.

    Inspired by the cleanlogs.ps1 patterns (Compress-Archive, age filtering,
    safe error handling).

    Target: Windows Server 2022 / PowerShell 5.1 — no external modules required.

.PARAMETER SourcePath
    Directory to clean up. Defaults to the current working directory.

.PARAMETER BackupRoot
    Root folder where backups are stored. Default: .\Backup

.PARAMETER OlderThanDays
    Move files whose LastWriteTime is more than this many days ago.
    Default: 30

.PARAMETER Filter
    Wildcard filter for target files (e.g., "*.log", "*.tmp").
    Default: "*" (all files)

.EXAMPLE
    .\Exercise-02-Solution.ps1 -SourcePath "C:\Logs" -OlderThanDays 60 -Filter "*.log"

.EXAMPLE
    .\Exercise-02-Solution.ps1 -SourcePath "C:\Temp" -BackupRoot "D:\Archive"
#>

param(
    [Parameter()]
    [string]$SourcePath = $PWD,

    [Parameter()]
    [string]$BackupRoot = (Join-Path -Path $PWD -ChildPath 'Backup'),

    [Parameter()]
    [int]$OlderThanDays = 30,

    [Parameter()]
    [string]$Filter = '*'
)

# ── 0. Validate source path ────────────────────────────────────────────
if (-not (Test-Path -Path $SourcePath -PathType Container)) {
    Write-Error "Source path '$SourcePath' does not exist or is not a directory."
    exit 1
}

$resolvedSource = (Resolve-Path -Path $SourcePath).Path

# ── 1. Calculate the cutoff date ───────────────────────────────────────
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
Write-Host "Cleanup target : $resolvedSource"
Write-Host "Backup root    : $BackupRoot"
Write-Host "Cutoff date    : $($cutoffDate.ToString('yyyy-MM-dd HH:mm'))"
Write-Host "File filter    : $Filter"
Write-Host ''

# ── 2. Collect candidate files ─────────────────────────────────────────
$oldFiles = Get-ChildItem -Path $resolvedSource -Filter $Filter -File |
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if (-not $oldFiles) {
    Write-Host "No files older than $OlderThanDays days matching '$Filter'. Nothing to do."
    exit 0
}

$fileCount = ($oldFiles | Measure-Object).Count
Write-Host "Found $fileCount file(s) to move."

# ── 3. Create backup structure and move files ───────────────────────────
# Track every action for the summary report
$movedFiles = [System.Collections.ArrayList]::new()

foreach ($file in $oldFiles) {
    # Derive year/month subfolder from the file's last-write date
    $year  = $file.LastWriteTime.ToString('yyyy')
    $month = $file.LastWriteTime.ToString('MM')
    $destDir = Join-Path -Path $BackupRoot -ChildPath (Join-Path $year $month)

    # Create the subfolder if needed
    if (-not (Test-Path -Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }

    $destFile = Join-Path -Path $destDir -ChildPath $file.Name

    try {
        Move-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
        [void]$movedFiles.Add([PSCustomObject]@{
            Name        = $file.Name
            Source      = $file.FullName
            Destination = $destFile
            SizeBytes   = $file.Length
            YearMonth   = "$year-$month"
        })
        Write-Host "  Moved: $($file.Name) -> $year\$month\"
    }
    catch {
        Write-Warning "  Failed to move '$($file.Name)': $_"
    }
}

# ── 4. Compress each year/month folder ──────────────────────────────────
Write-Host "`nCompressing backup folders..."

# Collect year folders, then month folders within each
$yearDirs = Get-ChildItem -Path $BackupRoot -Directory -ErrorAction SilentlyContinue

$archivesCreated = [System.Collections.ArrayList]::new()

foreach ($yearDir in $yearDirs) {
    $monthDirs = Get-ChildItem -Path $yearDir.FullName -Directory -ErrorAction SilentlyContinue

    foreach ($monthDir in $monthDirs) {
        # Only compress folders that contain files
        $contents = Get-ChildItem -Path $monthDir.FullName -File
        if (-not $contents) { continue }

        $archiveName = "$($yearDir.Name)-$($monthDir.Name).zip"
        $archivePath = Join-Path -Path $BackupRoot -ChildPath $archiveName

        try {
            Compress-Archive -Path (Join-Path $monthDir.FullName '*') `
                             -DestinationPath $archivePath `
                             -CompressionLevel Optimal `
                             -Force `
                             -ErrorAction Stop

            # Remove the uncompressed month folder after successful compression
            Remove-Item -Path $monthDir.FullName -Recurse -Force

            $archiveSize = (Get-Item -Path $archivePath).Length
            [void]$archivesCreated.Add([PSCustomObject]@{
                Archive = $archiveName
                SizeMB  = [Math]::Round($archiveSize / 1MB, 2)
            })

            Write-Host "  Created: $archiveName"
        }
        catch {
            Write-Warning "  Failed to compress '$($monthDir.FullName)': $_"
        }
    }

    # Remove the year folder if it is now empty
    if (-not (Get-ChildItem -Path $yearDir.FullName -Recurse)) {
        Remove-Item -Path $yearDir.FullName -Force
    }
}

# ── 5. Generate summary report ─────────────────────────────────────────
Write-Host "`n--- Cleanup Summary ---"

$totalMoved    = $movedFiles.Count
$totalSizeMB   = [Math]::Round(($movedFiles | Measure-Object -Property SizeBytes -Sum).Sum / 1MB, 2)

Write-Host "Files moved  : $totalMoved"
Write-Host "Total size   : $totalSizeMB MB"

if ($archivesCreated.Count -gt 0) {
    Write-Host "`nArchives created:"
    $archivesCreated | Format-Table -Property Archive, SizeMB -AutoSize
}
else {
    Write-Host "No archives were created."
}

# ── 6. Completion ──────────────────────────────────────────────────────
Write-Host "`n=== Cleanup complete ==="

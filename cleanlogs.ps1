<#
.SYNOPSIS
    Finds *.log files older than 1 month in a target directory, compresses each
    one individually into a .zip archive, and moves the archives to a LogArchive
    subdirectory.

.PARAMETER Directory
    Path to the directory to scan. Defaults to the current working directory.
#>

param(
    [Parameter()]
    [string]$Directory = $PWD
)

$resolvedDir = Resolve-Path -Path $Directory -ErrorAction Stop
$archiveDir  = Join-Path -Path $resolvedDir -ChildPath 'LogArchive'
$cutoffDate  = (Get-Date).AddMonths(-1)

# Create the archive subdirectory if it does not already exist
if (-not (Test-Path -Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
    Write-Host "Created archive directory: $archiveDir"
}

# Find all *.log files older than 1 month (excluding the LogArchive subdirectory)
$logFiles = Get-ChildItem -Path $resolvedDir -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if (-not $logFiles) {
    Write-Host 'No log files older than 1 month found.'
    exit 0
}

foreach ($log in $logFiles) {
    $zipName = "$($log.BaseName).zip"
    $zipPath = Join-Path -Path $archiveDir -ChildPath $zipName

    try {
        Compress-Archive -Path $log.FullName -DestinationPath $zipPath -CompressionLevel Optimal -ErrorAction Stop
        Remove-Item -Path $log.FullName -Force
        Write-Host "Archived: $($log.Name) -> LogArchive\$zipName"
    }
    catch {
        Write-Warning "Failed to archive '$($log.Name)': $_"
    }
}

Write-Host 'Done.'

<#
.SYNOPSIS
    Directory Cleanup Tool — move old files into a date-organized backup and compress them.

.DESCRIPTION
    This exercise builds a cleanup utility inspired by the cleanlogs.ps1 script.
    You will practice:
      - Creating directory structures with New-Item
      - Filtering files by age with Where-Object
      - Moving files with Move-Item
      - Compressing files with Compress-Archive
      - Building a summary report of actions taken

    Complete every TODO block to finish the script.

    Target: Windows Server 2022 / PowerShell 5.1 — no external modules required.

.PARAMETER SourcePath
    Directory to clean up. Defaults to the current working directory.

.PARAMETER BackupRoot
    Root folder where backups are stored. A timestamped subfolder is created
    automatically. Default: .\Backup

.PARAMETER OlderThanDays
    Move files whose LastWriteTime is more than this many days ago.
    Default: 30

.PARAMETER Filter
    Wildcard filter for target files (e.g., "*.log", "*.tmp").
    Default: "*" (all files)

.EXAMPLE
    .\Exercise-02.ps1 -SourcePath "C:\Logs" -OlderThanDays 60 -Filter "*.log"
    Moves .log files older than 60 days from C:\Logs into a backup folder and
    compresses them.

.EXAMPLE
    .\Exercise-02.ps1 -SourcePath "C:\Temp" -BackupRoot "D:\Archive"
    Cleans up C:\Temp, storing backups under D:\Archive.
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
# TODO: Use Test-Path to confirm $SourcePath exists and is a container.
#       Exit with an error message if it does not.



# ── 1. Calculate the cutoff date ───────────────────────────────────────
# TODO: Create a $cutoffDate variable using (Get-Date).AddDays(-$OlderThanDays).
#       Print the cutoff date so the operator can verify the threshold.



# ── 2. Collect candidate files ─────────────────────────────────────────
# TODO: Use Get-ChildItem with -File and -Filter to list files in
#       $SourcePath (non-recursive is fine for this exercise).
#       Pipe to Where-Object to keep only files older than $cutoffDate.
#       Store the result in $oldFiles.
#       If none are found, print a message and exit gracefully.



# ── 3. Create the backup directory structure ────────────────────────────
# TODO: For each file in $oldFiles, derive a year/month subfolder from
#       the file's LastWriteTime (e.g., "2024\01").
#       Use Join-Path to build the full destination path under $BackupRoot.
#       Create the subfolder with New-Item -ItemType Directory -Force
#       if it does not already exist.
#
#       Hint: $file.LastWriteTime.ToString('yyyy') and
#             $file.LastWriteTime.ToString('MM')



# ── 4. Move files into the backup structure ─────────────────────────────
# TODO: Loop through $oldFiles. For each file:
#         a. Build the destination path (BackupRoot\yyyy\MM\filename).
#         b. Use Move-Item to relocate the file.
#         c. Track the moved file's name, original path, destination path,
#            and size so you can report on it later.
#       Wrap each Move-Item in a try/catch to handle errors gracefully.



# ── 5. Compress each year/month folder ──────────────────────────────────
# TODO: After all files are moved, find every year\month subfolder under
#       $BackupRoot that contains files.
#       For each subfolder, call Compress-Archive to create a .zip named
#       like "2024-01.zip" in $BackupRoot.
#       After successful compression, remove the uncompressed folder.
#
#       Hint: Get-ChildItem -Path $BackupRoot -Directory -Recurse -Depth 1



# ── 6. Generate summary report ─────────────────────────────────────────
# TODO: Print a summary that includes:
#         - Total number of files moved
#         - Total size moved (in MB)
#         - List of archive .zip files created with their sizes
#       Use Measure-Object and Format-Table or Write-Host as needed.



# ── 7. Completion ──────────────────────────────────────────────────────
Write-Host "`n=== Cleanup complete ==="

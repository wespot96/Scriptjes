<#
.SYNOPSIS
    File Inventory Report — scan a directory and produce a summary of its contents.

.DESCRIPTION
    This exercise builds a file-inventory report for a target directory.
    You will practice:
      - Recursive file enumeration with Get-ChildItem
      - Filtering with Where-Object (age, size, extension)
      - Aggregating data with Measure-Object and Group-Object
      - Formatting output for a human-readable report

    Complete every TODO block to finish the script.

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
    .\Exercise-01.ps1 -Path "C:\Logs"
    Generates a file inventory report for C:\Logs with default thresholds.

.EXAMPLE
    .\Exercise-01.ps1 -Path "C:\Data" -OlderThanDays 90 -LargerThanMB 50
    Reports on files older than 90 days or larger than 50 MB.
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
# TODO: Use Test-Path to verify $Path exists and is a directory.
#       If it does not exist, write an error message and exit.



# ── 1. Enumerate all files recursively ─────────────────────────────────
# TODO: Use Get-ChildItem with -Recurse and -File to collect every file
#       under $Path. Store the result in $allFiles.



# ── 2. Overall summary ─────────────────────────────────────────────────
# TODO: Use Measure-Object on the Length property to calculate:
#         - Total file count
#         - Total size (sum)
#       Print a header such as:
#         "=== File Inventory Report for <Path> ==="
#         "Total files : <count>"
#         "Total size  : <size> MB"



# ── 3. Group files by extension ─────────────────────────────────────────
# TODO: Use Group-Object on the Extension property of $allFiles.
#       For each group, display:
#         - Extension name
#         - Number of files
#         - Combined size in MB
#       Sort the output by combined size descending.



# ── 4. Find old files (older than $OlderThanDays) ──────────────────────
# TODO: Calculate a cutoff date using (Get-Date).AddDays(-$OlderThanDays).
#       Filter $allFiles with Where-Object to find files with
#       LastWriteTime before the cutoff.
#       Display the count and list the top 10 largest old files
#       (Name, SizeMB, LastWriteTime).



# ── 5. Find large files (larger than $LargerThanMB) ────────────────────
# TODO: Convert $LargerThanMB to bytes ($thresholdBytes = $LargerThanMB * 1MB).
#       Filter $allFiles with Where-Object for Length -gt $thresholdBytes.
#       Display the count and list all large files
#       (FullName, SizeMB, LastWriteTime).



# ── 6. Find *.log files specifically ────────────────────────────────────
# TODO: Filter $allFiles for items whose Extension equals '.log'.
#       Use Measure-Object to get their count and total size.
#       Print a summary line, e.g.:
#         "Log files: <count>  Total size: <size> MB"



# ── 7. Print completion message ─────────────────────────────────────────
Write-Host "`n=== Report complete ==="

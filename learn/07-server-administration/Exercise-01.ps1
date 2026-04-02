<#
.SYNOPSIS
    Exercise 01 — Server Health Check
.DESCRIPTION
    Build a script that collects CPU, RAM, disk, and event-log data from the
    local server and outputs a structured health report with status indicators.

    Skills practised:
      - Get-CimInstance (Win32_Processor, Win32_OperatingSystem, Win32_LogicalDisk)
      - Get-WinEvent with -FilterHashtable
      - Calculated properties and PSCustomObject output
      - Threshold-based status logic

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.NOTES
    Module  : 07-server-administration
    Exercise: 01
    See also: ServerHealthDashboard.ps1 in the repo root for CIM/WMI patterns.
#>

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Thresholds ────────────────────────────────────────────────────────────────
$CpuWarnPercent  = 80   # CPU usage above this = Warning
$CpuCritPercent  = 95   # CPU usage above this = Critical
$DiskWarnPercent = 90   # Disk used above this = Warning
$DiskCritPercent = 95   # Disk used above this = Critical
$RamWarnPercent  = 85   # RAM used above this  = Warning

# ── Helper: return 'OK', 'WARNING', or 'CRITICAL' based on thresholds ────────
function Get-StatusLabel {
    param(
        [double]$Value,
        [double]$WarnThreshold,
        [double]$CritThreshold
    )
    # TODO: Return 'CRITICAL' if Value >= CritThreshold,
    #       'WARNING' if Value >= WarnThreshold, else 'OK'.
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1 — CPU Usage
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Use Get-CimInstance Win32_Processor to get the average LoadPercentage.
#       Store the result in $cpuLoad (a [double]).
#       Hint: Measure-Object -Property LoadPercentage -Average

$cpuLoad = 0  # ← replace with your CIM query

# TODO: Build a status label using Get-StatusLabel with $CpuWarnPercent / $CpuCritPercent.
$cpuStatus = ''  # ← replace

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2 — RAM Usage
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Use Get-CimInstance Win32_OperatingSystem to read:
#         TotalVisibleMemorySize  (KB)
#         FreePhysicalMemory      (KB)
#       Calculate used RAM and the percentage used.
#       Store in $ramTotalGB, $ramUsedGB, $ramFreeGB, $ramUsedPercent.
#       Hint: divide KB values by 1MB to get GB (PowerShell treats 1MB = 1048576).

$ramTotalGB      = 0
$ramUsedGB       = 0
$ramFreeGB       = 0
$ramUsedPercent  = 0

# TODO: Build a status label for RAM using $RamWarnPercent (use 95 as crit).
$ramStatus = ''  # ← replace

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3 — Disk Space
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Use Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" to get
#       local fixed disks. For each disk, calculate UsedPercent and a status
#       label. Output an array of PSCustomObjects with these properties:
#         DeviceID, TotalGB, FreeGB, UsedPercent, Status
#       Hint: Size and FreeSpace are in bytes; divide by 1GB.
#       Hint: Use [Math]::Round() for clean numbers.

$diskReport = @()  # ← replace with your pipeline

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4 — Recent Error Events
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Use Get-WinEvent with -FilterHashtable to retrieve the last 10 Error
#       events (Level = 2) from the System log. Select these properties:
#         TimeCreated, Id, ProviderName, Message
#       Store in $errorEvents.
#       Wrap in try/catch — if no errors are found, Get-WinEvent throws.

$errorEvents = @()  # ← replace

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5 — Assemble & Output Report
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Create a [PSCustomObject] named $report with these properties:
#         ComputerName, ReportTime,
#         CpuLoadPercent, CpuStatus,
#         RamTotalGB, RamUsedGB, RamFreeGB, RamUsedPercent, RamStatus,
#         DiskReport   (the array from Section 3),
#         ErrorEvents  (the array from Section 4)
#       Then display the summary to the console and list each disk and event.

$report = $null  # ← replace

# Display summary
Write-Host '═══ Server Health Report ═══' -ForegroundColor Cyan
# TODO: Write CPU, RAM, and per-disk summaries with colour coding:
#       OK = Green, WARNING = Yellow, CRITICAL = Red
# TODO: List the error events (if any) in a table.

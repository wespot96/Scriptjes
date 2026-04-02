<#
.SYNOPSIS
    Exercise 02 — Service Audit and Scheduled Task Creator
.DESCRIPTION
    Build a script that audits automatic services, checks for pending updates,
    reads a registry value, and creates a scheduled task for weekly health checks.

    Skills practised:
      - Get-Service filtering (StartType, Status)
      - Get-CimInstance for Windows Update queries
      - Get-ItemProperty for registry access
      - New-ScheduledTaskTrigger / New-ScheduledTaskAction / Register-ScheduledTask

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.NOTES
    Module  : 07-server-administration
    Exercise: 02
    See also: README.md § Scheduled Tasks for the Register-ScheduledTask pattern.
#>

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Configuration ─────────────────────────────────────────────────────────────
$HealthCheckScriptPath = 'C:\Scripts\HealthCheck.ps1'   # Script the task will run
$TaskName              = 'WeeklyHealthCheck'             # Scheduled task name
$TaskRunDay            = 'Sunday'                        # Day of week
$TaskRunTime           = '02:00AM'                       # Time to run
$RegistryPath          = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
$RegistryValueName     = 'ProgramFilesDir'               # A safe, always-present value

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1 — Find Automatic Services That Are Stopped
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Use Get-Service to find all services where:
#         StartType -eq 'Automatic'  AND  Status -ne 'Running'
#       These are services that should be running but are not.
#       Store the results in $stoppedAutoServices.
#       Output a table with: Name, DisplayName, Status, StartType

$stoppedAutoServices = @()  # ← replace with your pipeline

Write-Host '═══ Stopped Automatic Services ═══' -ForegroundColor Cyan
# TODO: If none found, write "All automatic services are running."
#       Otherwise, display the list as a formatted table.

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2 — Check for Pending Windows Updates
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Query the CIM class 'ROOT\ccm\ClientSDK:CCM_SoftwareUpdate' to find
#       pending updates. This class is available when SCCM/MECM client is
#       installed. Because many servers don't have it, wrap the call in
#       try/catch and fall back to the COM-based approach:
#
#       Fallback (COM):
#         $updateSession  = New-Object -ComObject Microsoft.Update.Session
#         $updateSearcher = $updateSession.CreateUpdateSearcher()
#         $pendingUpdates = $updateSearcher.Search("IsInstalled=0").Updates
#
#       Store the count in $pendingUpdateCount and list titles if any exist.

$pendingUpdateCount = 0  # ← replace

Write-Host "`n═══ Pending Windows Updates ═══" -ForegroundColor Cyan
# TODO: Display the count. If > 0, list update titles.

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3 — Read a Registry Value
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Use Get-ItemProperty to read $RegistryValueName from $RegistryPath.
#       Store the result in $regValue.
#       Display: "Registry value '$RegistryValueName' = <value>"
#       Wrap in try/catch to handle missing keys gracefully.

$regValue = $null  # ← replace

Write-Host "`n═══ Registry Value ═══" -ForegroundColor Cyan
# TODO: Display the registry value or an error message.

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4 — Create a Scheduled Task for Weekly Health Check
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Build and register a scheduled task that runs the health-check script
#       weekly. Follow these steps:
#
#   4a. Check if a task named $TaskName already exists.
#       If it does, display a message and skip creation.
#       Hint: Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
#
#   4b. Create the trigger:
#       $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $TaskRunDay -At $TaskRunTime
#
#   4c. Create the action:
#       $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
#                   -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$HealthCheckScriptPath`""
#
#   4d. (Optional) Create settings:
#       $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
#                     -DontStopIfGoingOnBatteries -StartWhenAvailable
#
#   4e. Register the task:
#       Register-ScheduledTask -TaskName $TaskName -Trigger $trigger `
#                              -Action $action -Settings $settings `
#                              -RunLevel Highest -Description 'Weekly server health check'
#
#   4f. Confirm creation by retrieving the task and displaying its State.

Write-Host "`n═══ Scheduled Task ═══" -ForegroundColor Cyan
# TODO: Implement steps 4a–4f above.

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5 — Summary
# ══════════════════════════════════════════════════════════════════════════════
# TODO: Output a final PSCustomObject summarising:
#         StoppedAutoServiceCount, PendingUpdateCount, RegistryValue, TaskStatus
#       Display it with Format-List.

$summary = $null  # ← replace

Write-Host "`n═══ Audit Summary ═══" -ForegroundColor Cyan
# TODO: Display $summary | Format-List

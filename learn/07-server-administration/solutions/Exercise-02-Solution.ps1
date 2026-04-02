<#
.SYNOPSIS
    Solution — Exercise 02: Service Audit and Scheduled Task Creator
.DESCRIPTION
    Audits automatic services that are stopped, checks for pending Windows
    updates, reads a registry value, and creates a scheduled task for a
    weekly health check.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.NOTES
    Module  : 07-server-administration
    Exercise: 02 (Solution)
#>

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Configuration ─────────────────────────────────────────────────────────────
$HealthCheckScriptPath = 'C:\Scripts\HealthCheck.ps1'
$TaskName              = 'WeeklyHealthCheck'
$TaskRunDay            = 'Sunday'
$TaskRunTime           = '02:00AM'
$RegistryPath          = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
$RegistryValueName     = 'ProgramFilesDir'

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1 — Find Automatic Services That Are Stopped
# ══════════════════════════════════════════════════════════════════════════════
# Services with StartType 'Automatic' that are not currently running
# may indicate a problem (crash, failed dependency, etc.).
$stoppedAutoServices = Get-Service |
    Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } |
    Select-Object Name, DisplayName, Status, StartType

Write-Host '═══ Stopped Automatic Services ═══' -ForegroundColor Cyan
if ($stoppedAutoServices.Count -eq 0) {
    Write-Host '  All automatic services are running.' -ForegroundColor Green
}
else {
    $stoppedAutoServices | Format-Table -AutoSize | Out-String | Write-Host
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2 — Check for Pending Windows Updates
# ══════════════════════════════════════════════════════════════════════════════
$pendingUpdateCount = 0
$pendingUpdateTitles = @()

# Try the SCCM/MECM CIM class first; fall back to the COM-based Windows
# Update Agent API which is available on all Windows editions.
try {
    $updates = Get-CimInstance -Namespace 'ROOT\ccm\ClientSDK' `
        -ClassName 'CCM_SoftwareUpdate' -ErrorAction Stop
    $pendingUpdateCount  = $updates.Count
    $pendingUpdateTitles = $updates | Select-Object -ExpandProperty Name
}
catch {
    # SCCM not available — use the COM Windows Update Session
    try {
        $updateSession  = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult   = $updateSearcher.Search("IsInstalled=0")
        $pendingUpdateCount  = $searchResult.Updates.Count
        $pendingUpdateTitles = @(
            foreach ($update in $searchResult.Updates) { $update.Title }
        )
    }
    catch {
        Write-Warning "Unable to query Windows Updates: $_"
    }
}

Write-Host "`n═══ Pending Windows Updates ═══" -ForegroundColor Cyan
if ($pendingUpdateCount -eq 0) {
    Write-Host '  No pending updates found.' -ForegroundColor Green
}
else {
    Write-Host ("  {0} pending update(s):" -f $pendingUpdateCount) -ForegroundColor Yellow
    foreach ($title in $pendingUpdateTitles) {
        Write-Host ("    - {0}" -f $title)
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3 — Read a Registry Value
# ══════════════════════════════════════════════════════════════════════════════
$regValue = $null
try {
    $regProps = Get-ItemProperty -Path $RegistryPath -Name $RegistryValueName -ErrorAction Stop
    $regValue = $regProps.$RegistryValueName
}
catch {
    Write-Warning "Could not read registry value '$RegistryValueName' from '$RegistryPath': $_"
}

Write-Host "`n═══ Registry Value ═══" -ForegroundColor Cyan
if ($null -ne $regValue) {
    Write-Host ("  '{0}' = {1}" -f $RegistryValueName, $regValue) -ForegroundColor Green
}
else {
    Write-Host ("  Registry value '{0}' not found." -f $RegistryValueName) -ForegroundColor Yellow
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4 — Create a Scheduled Task for Weekly Health Check
# ══════════════════════════════════════════════════════════════════════════════
$taskStatus = 'Unknown'

Write-Host "`n═══ Scheduled Task ═══" -ForegroundColor Cyan

# 4a. Check if the task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    $taskStatus = $existingTask.State.ToString()
    Write-Host ("  Task '{0}' already exists (State: {1}). Skipping creation." -f $TaskName, $taskStatus) `
        -ForegroundColor Yellow
}
else {
    # 4b. Create the trigger — run weekly on the specified day and time
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $TaskRunDay -At $TaskRunTime

    # 4c. Create the action — launch PowerShell with the health-check script
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$HealthCheckScriptPath`""

    # 4d. Create settings for reliability
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable

    # 4e. Register the task
    Register-ScheduledTask `
        -TaskName    $TaskName `
        -Trigger     $trigger `
        -Action      $action `
        -Settings    $settings `
        -RunLevel    Highest `
        -Description 'Weekly server health check' |
        Out-Null

    # 4f. Confirm creation
    $createdTask = Get-ScheduledTask -TaskName $TaskName
    $taskStatus  = $createdTask.State.ToString()
    Write-Host ("  Task '{0}' created successfully (State: {1})." -f $TaskName, $taskStatus) `
        -ForegroundColor Green
}

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5 — Summary
# ══════════════════════════════════════════════════════════════════════════════
$summary = [PSCustomObject]@{
    StoppedAutoServiceCount = $stoppedAutoServices.Count
    PendingUpdateCount      = $pendingUpdateCount
    RegistryValue           = if ($null -ne $regValue) { $regValue } else { '(not found)' }
    TaskStatus              = $taskStatus
}

Write-Host "`n═══ Audit Summary ═══" -ForegroundColor Cyan
$summary | Format-List | Out-String | Write-Host

# Return the summary object for pipeline use
$summary

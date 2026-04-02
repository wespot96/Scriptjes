<#
.SYNOPSIS
    Solution for Exercise 02 - Production-Ready Automation Wrapper

.DESCRIPTION
    Complete, working capstone script that performs server maintenance (cleans
    old log files), optionally self-registers as a weekly scheduled task,
    and sends an email summary. Demonstrates every major production-readiness
    pattern from the learning series:

      - #Requires -RunAsAdministrator
      - SupportsShouldProcess (-WhatIf / -Confirm)
      - Start-Transcript / Stop-Transcript
      - Scheduled task registration (repo README.md pattern)
      - Send-MailMessage email notification
      - Proper exit codes and structured error handling
      - Full comment-based help

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 12-Automation-and-Reporting
    Author : PowerShell Learning Series
#>

#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Performs weekly server maintenance and sends a summary email.

.DESCRIPTION
    Cleans log files older than the specified retention period, optionally
    registers itself as a Windows scheduled task, and emails a summary to
    the operations team. All actions honour -WhatIf and -Confirm, and the
    entire session is captured by Start-Transcript.

.PARAMETER LogPath
    Directory containing log files to clean and where transcripts are saved.
    Defaults to "C:\Logs". Cannot be null or empty.

.PARAMETER RetentionDays
    Files older than this many days are removed. Defaults to 30.
    Valid range: 1-365.

.PARAMETER SmtpServer
    SMTP relay host for email notifications. Defaults to "smtp.company.com".

.PARAMETER EmailTo
    Recipient email address. Defaults to "admin@company.com".

.PARAMETER EmailFrom
    Sender email address. Defaults to "automation@company.com".

.PARAMETER RegisterTask
    When present, registers this script as a weekly scheduled task running
    as SYSTEM every Sunday at 11:00 PM.

.PARAMETER TaskName
    Name for the scheduled task. Defaults to "WeeklyMaintenance".

.EXAMPLE
    .\Exercise-02-Solution.ps1 -WhatIf
    Previews all maintenance actions without making changes.

.EXAMPLE
    .\Exercise-02-Solution.ps1 -LogPath "C:\Logs" -RetentionDays 7 -Verbose
    Cleans logs older than 7 days with verbose output.

.EXAMPLE
    .\Exercise-02-Solution.ps1 -RegisterTask -WhatIf
    Previews scheduled task registration without creating it.

.EXAMPLE
    .\Exercise-02-Solution.ps1 -RetentionDays 14 -Confirm
    Cleans logs older than 14 days, prompting before each deletion.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = 'C:\Logs',

    [ValidateRange(1, 365)]
    [int]$RetentionDays = 30,

    [string]$SmtpServer = 'smtp.company.com',

    [string]$EmailTo = 'admin@company.com',

    [string]$EmailFrom = 'automation@company.com',

    [switch]$RegisterTask,

    [string]$TaskName = 'WeeklyMaintenance'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$exitCode = 0

#region ── Helper: Write-Log ───────────────────────────────────────────────────

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry     = "$timestamp [$Level] $Message"

    # Append to persistent log file
    $logFile = Join-Path $LogPath 'automation.log'
    Add-Content -Path $logFile -Value $entry -ErrorAction SilentlyContinue

    # Console output with colour
    switch ($Level) {
        'Info'    { Write-Host $entry -ForegroundColor Green  }
        'Warning' { Write-Host $entry -ForegroundColor Yellow }
        'Error'   { Write-Host $entry -ForegroundColor Red    }
    }
}

#endregion

#region ── Start Transcript ────────────────────────────────────────────────────

# Ensure log directory exists
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

$transcriptPath = Join-Path $LogPath "maintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $transcriptPath

#endregion

#region ── Main Logic ──────────────────────────────────────────────────────────

try {
    Write-Log -Message "=== Maintenance script starting on $env:COMPUTERNAME ==="

    #region ── Step 1: Clean Old Log Files ─────────────────────────────────────

    Write-Log -Message "Scanning $LogPath for *.log files older than $RetentionDays days..."

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $oldFiles   = Get-ChildItem -Path $LogPath -Filter '*.log' -File -ErrorAction SilentlyContinue |
                      Where-Object { $_.LastWriteTime -lt $cutoffDate }

    $removedCount  = 0
    $removedSizeMB = 0

    foreach ($file in $oldFiles) {
        if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove old log file')) {
            $removedSizeMB += $file.Length / 1MB
            Remove-Item -Path $file.FullName -Force
            $removedCount++
            Write-Log -Message "Deleted: $($file.Name) ($([math]::Round($file.Length / 1KB)) KB)"
        }
    }

    $removedSizeMB = [math]::Round($removedSizeMB, 2)
    Write-Log -Message "Cleanup complete: removed $removedCount file(s), reclaimed $removedSizeMB MB."

    #endregion

    #region ── Step 2: Register Scheduled Task (optional) ──────────────────────

    $taskRegistered = $false

    if ($RegisterTask) {
        if ($PSCmdlet.ShouldProcess($TaskName, 'Register weekly scheduled task')) {
            $scriptPath = $MyInvocation.MyCommand.Path

            $action = New-ScheduledTaskAction `
                -Execute 'powershell.exe' `
                -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

            $trigger = New-ScheduledTaskTrigger `
                -Weekly `
                -DaysOfWeek Sunday `
                -At 11:00PM

            $principal = New-ScheduledTaskPrincipal `
                -UserId 'SYSTEM' `
                -LogonType ServiceAccount `
                -RunLevel Highest

            $settings = New-ScheduledTaskSettingsSet `
                -StartWhenAvailable

            Register-ScheduledTask `
                -TaskName $TaskName `
                -Action $action `
                -Trigger $trigger `
                -Principal $principal `
                -Settings $settings `
                -Description "Weekly maintenance - cleans logs older than $RetentionDays days"

            $taskRegistered = $true
            Write-Log -Message "Scheduled task '$TaskName' registered (Sunday 11:00 PM as SYSTEM)."
        }
    }

    #endregion

    #region ── Step 3: Build Summary ───────────────────────────────────────────

    $summary = @"
=== Maintenance Summary ===
Computer     : $env:COMPUTERNAME
Script       : $($MyInvocation.MyCommand.Name)
Run Time     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Log Cleanup:
  Path           : $LogPath
  Retention      : $RetentionDays days
  Files Removed  : $removedCount
  Space Reclaimed: $removedSizeMB MB

Scheduled Task:
  Registered     : $taskRegistered
  Task Name      : $(if ($RegisterTask) { $TaskName } else { 'N/A (not requested)' })

Status: SUCCESS
"@

    Write-Log -Message $summary

    #endregion

    #region ── Step 4: Send Email Notification ─────────────────────────────────

    try {
        Send-MailMessage `
            -To $EmailTo `
            -From $EmailFrom `
            -Subject "Maintenance Complete - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd')" `
            -Body $summary `
            -SmtpServer $SmtpServer

        Write-Log -Message "Summary email sent to $EmailTo."
    }
    catch {
        Write-Log -Message "Could not send email: $_" -Level Warning
    }

    #endregion

    Write-Log -Message 'Maintenance script completed successfully.'
}
catch {
    Write-Log -Message "FATAL: $_" -Level Error
    $exitCode = 1
    Write-Error "Maintenance script failed: $_"
}
finally {
    Stop-Transcript
}

#endregion

exit $exitCode

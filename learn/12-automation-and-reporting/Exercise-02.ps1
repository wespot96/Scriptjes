<#
.SYNOPSIS
    Exercise 02 - Production-Ready Automation Wrapper

.DESCRIPTION
    Build a capstone automation script that ties together every major concept
    from the learning series into one production-ready workflow. This exercise
    practises:

      - #Requires -RunAsAdministrator for privilege enforcement
      - [CmdletBinding(SupportsShouldProcess)] for -WhatIf / -Confirm
      - Full comment-based help (.SYNOPSIS through .EXAMPLE)
      - Start-Transcript / Stop-Transcript for session logging
      - Registering a weekly scheduled task (README.md pattern)
      - Sending a summary email with Send-MailMessage
      - Proper exit codes (0 = success, 1 = failure)
      - Structured error handling with try/catch/finally

    The script performs a simple server maintenance routine (cleans old log
    files and generates a summary) then optionally self-registers as a
    weekly scheduled task and emails the results.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 12-Automation-and-Reporting
    Author : PowerShell Learning Series
#>

# ============================================================================
# TODO: Complete the Production-Ready Automation Wrapper below.
#       Replace every "# TODO:" section with working code.
#       Refer to the README.md, ServerHealthDashboard.ps1, and the repo
#       root README.md (scheduled task pattern) for guidance.
# ============================================================================

# TODO: Add the #Requires statement for administrator privileges.
#   Hint: #Requires -RunAsAdministrator

# TODO: Add [CmdletBinding(SupportsShouldProcess=$true)] and a param block
#   with the following parameters:
#
#   -LogPath [string] — defaults to "C:\Logs"
#     Directory where old log files will be cleaned and where this script's
#     own transcript will be saved.
#     Apply [ValidateNotNullOrEmpty()].
#
#   -RetentionDays [int] — defaults to 30
#     Files older than this many days will be removed.
#     Apply [ValidateRange(1, 365)].
#
#   -SmtpServer [string] — defaults to "smtp.company.com"
#     SMTP relay for email notifications.
#
#   -EmailTo [string] — defaults to "admin@company.com"
#     Recipient for the summary email.
#
#   -EmailFrom [string] — defaults to "automation@company.com"
#     Sender address for the summary email.
#
#   -RegisterTask [switch]
#     When present, the script registers itself as a weekly scheduled task.
#
#   -TaskName [string] — defaults to "WeeklyMaintenance"
#     Name of the scheduled task to register.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$exitCode = 0

#region ── Helper: Write-Log ───────────────────────────────────────────────────

# TODO: Create a Write-Log function that:
#   - Accepts parameters: -Message [string], -Level [ValidateSet('Info','Warning','Error')]
#   - Builds a timestamped log entry: "yyyy-MM-dd HH:mm:ss [Level] Message"
#   - Appends the entry to a log file at "$LogPath\automation.log" using Add-Content
#   - Writes to the console with colour: Info=Green, Warning=Yellow, Error=Red
#
#   Hint: Use a switch statement on $Level for Write-Host -ForegroundColor.

#endregion

#region ── Start Transcript ────────────────────────────────────────────────────

# TODO: Ensure the $LogPath directory exists (use New-Item -Force if needed).
# TODO: Build a transcript path with timestamp:
#   $transcriptPath = Join-Path $LogPath "maintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
# TODO: Start the transcript with Start-Transcript -Path $transcriptPath.

#endregion

#region ── Main Logic ──────────────────────────────────────────────────────────

try {
    # TODO: Call Write-Log to record that the maintenance script is starting.

    #region ── Step 1: Clean Old Log Files ─────────────────────────────────────

    # TODO: Use Get-ChildItem to find *.log files in $LogPath that are older
    #   than $RetentionDays. Store the results in $oldFiles.
    #
    #   Hint: Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }

    # TODO: Initialise counters: $removedCount = 0, $removedSizeMB = 0

    # TODO: Loop through $oldFiles. For each file:
    #   1. Use $PSCmdlet.ShouldProcess($file.FullName, "Remove old log file")
    #      to respect -WhatIf and -Confirm.
    #   2. If ShouldProcess returns $true:
    #      - Accumulate file size: $removedSizeMB += $file.Length / 1MB
    #      - Remove the file with Remove-Item -Force
    #      - Increment $removedCount
    #      - Call Write-Log to record the deletion.

    # TODO: Call Write-Log to summarise: "Removed $removedCount files ($removedSizeMB MB)"

    #endregion

    #region ── Step 2: Register Scheduled Task (optional) ──────────────────────

    # TODO: Check if the -RegisterTask switch was supplied.
    #   If yes, and if $PSCmdlet.ShouldProcess($TaskName, "Register weekly scheduled task"):
    #     1. Build $action using New-ScheduledTaskAction:
    #          -Execute "powershell.exe"
    #          -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    #     2. Build $trigger using New-ScheduledTaskTrigger:
    #          -Weekly -DaysOfWeek Sunday -At 11:00PM
    #     3. Build $principal using New-ScheduledTaskPrincipal:
    #          -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    #     4. Build $settings using New-ScheduledTaskSettingsSet:
    #          -StartWhenAvailable
    #     5. Register with Register-ScheduledTask using the variables above,
    #        passing -TaskName $TaskName and -Description.
    #     6. Call Write-Log to confirm registration.
    #
    #   Pattern reference: see the repo root README.md scheduled task example.

    #endregion

    #region ── Step 3: Build Summary ───────────────────────────────────────────

    # TODO: Create a $summary string that includes:
    #   - Script name and run time
    #   - Number of files removed and space reclaimed
    #   - Whether a scheduled task was registered
    #   - Timestamp of completion

    # TODO: Call Write-Log with the summary.

    #endregion

    #region ── Step 4: Send Email Notification ─────────────────────────────────

    # TODO: Use Send-MailMessage to email the summary:
    #   -To $EmailTo
    #   -From $EmailFrom
    #   -Subject "Maintenance Complete - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd')"
    #   -Body $summary
    #   -SmtpServer $SmtpServer
    #
    #   Wrap in try/catch — email failure should log a warning but not fail
    #   the entire script. Use Write-Log -Level Warning on failure.

    #endregion

    Write-Log -Message "Maintenance script completed successfully." -Level Info
}
catch {
    # TODO: Log the error with Write-Log -Level Error.
    # TODO: Set $exitCode = 1.
    Write-Error "Maintenance script failed: $_"
}
finally {
    # TODO: Stop the transcript with Stop-Transcript.
}

#endregion

# TODO: Exit with $exitCode.
#   Hint: exit $exitCode

# ============================================================================
# Test your script — uncomment the lines below after completing the TODOs.
# ============================================================================
# .\Exercise-02.ps1 -WhatIf
# .\Exercise-02.ps1 -LogPath "C:\Logs" -RetentionDays 7 -Verbose -WhatIf
# .\Exercise-02.ps1 -RegisterTask -WhatIf
# .\Exercise-02.ps1 -LogPath "C:\Logs" -RetentionDays 30 -Confirm

<#
.SYNOPSIS
    Exercise 01 Solution - AD User Audit Report

.DESCRIPTION
    Audits Active Directory user accounts for security and compliance.
    Queries disabled accounts, stale logins, privileged group members,
    and locked-out accounts, then exports results to CSV files with a
    summary report.

.NOTES
    Module  : 08 - Active Directory
    Requires: Windows Server 2022, PowerShell 5.1, ActiveDirectory RSAT module
    Domain  : An Active Directory domain is required to run this script.
              All AD cmdlets will fail without connectivity to a DC.
    Safety  : Read-only — this script does not modify any AD objects.

.EXAMPLE
    .\Exercise-01-Solution.ps1
    Runs the full audit and saves CSV reports to the output folder.
#>

#Requires -Modules ActiveDirectory

# ============================================================================
# Configuration
# ============================================================================

$SearchBaseOU = "OU=Users,DC=contoso,DC=com"
$OutputFolder = "C:\ADReports"
$InactiveDays = 90

# ============================================================================
# Setup — Create output folder if it does not exist
# ============================================================================

if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    Write-Host "Created output folder: $OutputFolder" -ForegroundColor Cyan
}

# ============================================================================
# Task 1: Find Disabled User Accounts in the Target OU
# ============================================================================
# Get-ADUser -Filter queries AD directly using server-side filtering, which
# is far more efficient than retrieving all users and filtering client-side.
# -SearchBase limits the query to a specific OU subtree.
# -Properties pulls attributes beyond the default set.
# ============================================================================

$DisabledUsers = Get-ADUser -Filter { Enabled -eq $false } `
    -SearchBase $SearchBaseOU `
    -Properties LastLogonDate, WhenCreated, Description |
    Select-Object Name, SamAccountName, DistinguishedName, Enabled,
        LastLogonDate, WhenCreated, Description

Write-Host "Disabled accounts found: $($DisabledUsers.Count)" -ForegroundColor Yellow

$DisabledUsers | Export-Csv -Path "$OutputFolder\DisabledUsers.csv" -NoTypeInformation

# ============================================================================
# Task 2: Find Users Who Haven't Logged In for 90+ Days
# ============================================================================
# Search-ADAccount -AccountInactive uses the lastLogonTimestamp attribute,
# which replicates across DCs (unlike lastLogon). The -TimeSpan parameter
# accepts a [TimeSpan] or a string like "90.00:00:00" (90 days).
# ============================================================================

$InactiveUsers = Search-ADAccount -AccountInactive `
    -TimeSpan ([TimeSpan]::FromDays($InactiveDays)) `
    -UsersOnly `
    -SearchBase $SearchBaseOU |
    ForEach-Object {
        # Enrich each result with department and manager info
        Get-ADUser -Identity $_.SamAccountName `
            -Properties Department, Manager, Title, LastLogonDate |
            Select-Object Name, SamAccountName, Department, Title,
                LastLogonDate, Manager, Enabled
    }

Write-Host "Inactive accounts (${InactiveDays}+ days): $($InactiveUsers.Count)" -ForegroundColor Yellow

$InactiveUsers | Export-Csv -Path "$OutputFolder\InactiveUsers.csv" -NoTypeInformation

# ============================================================================
# Task 3: List Members of "Domain Admins" Recursively
# ============================================================================
# -Recursive expands nested group memberships. A user who belongs to
# GroupA, which is a member of Domain Admins, will appear in the output.
# We then enrich with Get-ADUser to get login and password details.
# ============================================================================

$DomainAdminMembers = Get-ADGroupMember -Identity "Domain Admins" -Recursive |
    Where-Object { $_.objectClass -eq 'user' } |
    ForEach-Object {
        Get-ADUser -Identity $_.SamAccountName `
            -Properties Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires |
            Select-Object Name, SamAccountName, Enabled, LastLogonDate,
                PasswordLastSet, PasswordNeverExpires
    }

Write-Host "Domain Admin members: $($DomainAdminMembers.Count)" -ForegroundColor Yellow

$DomainAdminMembers | Export-Csv -Path "$OutputFolder\DomainAdmins.csv" -NoTypeInformation

# ============================================================================
# Task 4: Find Locked-Out Accounts
# ============================================================================
# Search-ADAccount -LockedOut returns accounts where the lockoutTime
# attribute is set. This is critical for helpdesk triage.
# ============================================================================

$LockedAccounts = Search-ADAccount -LockedOut |
    ForEach-Object {
        Get-ADUser -Identity $_.SamAccountName `
            -Properties AccountLockoutTime, LastLogonDate, LockedOut |
            Select-Object Name, SamAccountName, LockedOut,
                AccountLockoutTime, LastLogonDate
    }

Write-Host "Locked-out accounts: $($LockedAccounts.Count)" -ForegroundColor Yellow

$LockedAccounts | Export-Csv -Path "$OutputFolder\LockedAccounts.csv" -NoTypeInformation

# ============================================================================
# Task 5: Generate a Summary Report
# ============================================================================

$Summary = [PSCustomObject]@{
    ReportDate         = Get-Date -Format "yyyy-MM-dd HH:mm"
    SearchBase         = $SearchBaseOU
    InactiveThreshold  = "$InactiveDays days"
    DisabledAccounts   = ($DisabledUsers | Measure-Object).Count
    InactiveAccounts   = ($InactiveUsers | Measure-Object).Count
    DomainAdminMembers = ($DomainAdminMembers | Measure-Object).Count
    LockedOutAccounts  = ($LockedAccounts | Measure-Object).Count
}

$Summary | Format-List

$Summary | Export-Csv -Path "$OutputFolder\AuditSummary.csv" -NoTypeInformation

Write-Host "`nAudit complete. Reports saved to: $OutputFolder" -ForegroundColor Green

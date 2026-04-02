<#
.SYNOPSIS
    Exercise 01 - AD User Audit Report

.DESCRIPTION
    Build a script that audits Active Directory user accounts for security
    and compliance purposes. You will query disabled accounts, stale logins,
    privileged group members, and locked-out accounts, then export results
    to CSV files.

    Skills practiced:
    - Get-ADUser with -Filter, -SearchBase, and -Properties
    - Search-ADAccount for disabled, inactive, and locked-out accounts
    - Get-ADGroupMember with -Recursive
    - Exporting results with Export-Csv

.NOTES
    Module  : 08 - Active Directory
    Requires: Windows Server 2022, PowerShell 5.1, ActiveDirectory RSAT module
    Domain  : An Active Directory domain is required to run this script.
              The commands will fail without a domain controller.
    Safety  : This script only reads AD data (no changes). Still, always test
              in a non-production environment first.

.EXAMPLE
    .\Exercise-01.ps1
    Runs the audit and exports CSV reports to the specified output folder.
#>

#Requires -Modules ActiveDirectory

# ============================================================================
# Configuration
# ============================================================================

# TODO: Set the target OU distinguished name for your environment
$SearchBaseOU = "OU=Users,DC=contoso,DC=com"

# TODO: Set the output folder for CSV reports
$OutputFolder = "C:\ADReports"

# Number of days without logon to consider an account "stale"
$InactiveDays = 90

# ============================================================================
# Setup — Create output folder if it does not exist
# ============================================================================

# TODO: Test if $OutputFolder exists; if not, create it with New-Item
# Hint: Use Test-Path and New-Item -ItemType Directory


# ============================================================================
# Task 1: Find Disabled User Accounts in the Target OU
# ============================================================================
# Use Get-ADUser with -Filter and -SearchBase to find disabled accounts.
# Select useful properties: Name, SamAccountName, DistinguishedName, Enabled,
# LastLogonDate, WhenCreated.
#
# Cmdlet reference:
#   Get-ADUser -Filter { Enabled -eq $false } -SearchBase $SearchBaseOU `
#       -Properties LastLogonDate, WhenCreated
# ============================================================================

# TODO: Query disabled users and store in $DisabledUsers


# TODO: Export $DisabledUsers to "$OutputFolder\DisabledUsers.csv"
# Hint: Use Export-Csv -NoTypeInformation


# ============================================================================
# Task 2: Find Users Who Haven't Logged In for 90+ Days
# ============================================================================
# Use Search-ADAccount with -AccountInactive and -TimeSpan to find stale
# accounts. The -UsersOnly switch limits results to user objects.
#
# Cmdlet reference:
#   Search-ADAccount -AccountInactive -TimeSpan "$InactiveDays.00:00:00" `
#       -UsersOnly -SearchBase $SearchBaseOU
# ============================================================================

# TODO: Query inactive users and store in $InactiveUsers


# TODO: For each inactive user, retrieve additional properties (Department,
#       Manager, Title) using Get-ADUser -Identity ... -Properties ...
# Hint: Pipe $InactiveUsers to ForEach-Object and call Get-ADUser inside


# TODO: Export results to "$OutputFolder\InactiveUsers.csv"


# ============================================================================
# Task 3: List Members of "Domain Admins" Recursively
# ============================================================================
# Use Get-ADGroupMember with -Recursive to expand nested group memberships.
# Then enrich each member with Get-ADUser to retrieve extra properties.
#
# Cmdlet reference:
#   Get-ADGroupMember -Identity "Domain Admins" -Recursive
# ============================================================================

# TODO: Get recursive members of "Domain Admins" and store in $DomainAdmins


# TODO: For each member, get Name, SamAccountName, Enabled, LastLogonDate,
#       PasswordLastSet using Get-ADUser
# Hint: Pipe members to ForEach-Object { Get-ADUser -Identity $_.SamAccountName -Properties ... }


# TODO: Export to "$OutputFolder\DomainAdmins.csv"


# ============================================================================
# Task 4: Find Locked-Out Accounts
# ============================================================================
# Use Search-ADAccount with -LockedOut to find accounts that are currently
# locked. This is useful for helpdesk and security monitoring.
#
# Cmdlet reference:
#   Search-ADAccount -LockedOut
# ============================================================================

# TODO: Query locked-out accounts and store in $LockedAccounts


# TODO: Select Name, SamAccountName, LastLogonDate, LockedOut, AccountLockoutTime
# Hint: You may need Get-ADUser -Properties AccountLockoutTime for the timestamp


# TODO: Export to "$OutputFolder\LockedAccounts.csv"


# ============================================================================
# Task 5: Generate a Summary Report
# ============================================================================
# Create a PSCustomObject with counts from each section and display it.
# Also export the summary to a text or CSV file.
# ============================================================================

# TODO: Build a summary object with counts
# Example:
#   [PSCustomObject]@{
#       ReportDate          = Get-Date -Format "yyyy-MM-dd HH:mm"
#       DisabledAccounts    = ($DisabledUsers | Measure-Object).Count
#       InactiveAccounts    = ($InactiveUsers | Measure-Object).Count
#       DomainAdminMembers  = ($DomainAdmins | Measure-Object).Count
#       LockedOutAccounts   = ($LockedAccounts | Measure-Object).Count
#   }


# TODO: Display the summary to the console with Write-Output or Format-Table


# TODO: Export summary to "$OutputFolder\AuditSummary.csv"


Write-Host "`nAudit complete. Reports saved to: $OutputFolder" -ForegroundColor Green

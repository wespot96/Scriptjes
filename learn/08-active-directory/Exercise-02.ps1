<#
.SYNOPSIS
    Exercise 02 - Bulk User Creator from CSV

.DESCRIPTION
    Build a script that reads user data from a CSV file and creates Active
    Directory accounts in bulk. The script should validate input, use
    splatting with New-ADUser, assign users to groups, and produce a
    completion report. Full -WhatIf support is required so the script can
    be safely tested before making changes.

    Skills practiced:
    - Import-Csv for bulk data ingestion
    - New-ADUser with parameter splatting
    - Add-ADGroupMember for group assignment
    - SupportsShouldProcess / -WhatIf for safe execution
    - Error handling with try/catch
    - Reporting with Export-Csv

.NOTES
    Module  : 08 - Active Directory
    Requires: Windows Server 2022, PowerShell 5.1, ActiveDirectory RSAT module
    Domain  : An Active Directory domain is required to run this script.
              New-ADUser and Add-ADGroupMember will fail without a DC.
    Safety  : Always run with -WhatIf first to preview changes.

.PARAMETER CsvPath
    Path to the CSV file containing user data.

.PARAMETER DefaultPassword
    Default password assigned to all new accounts as a SecureString.

.PARAMETER TargetOU
    Distinguished name of the OU where users will be created.

.PARAMETER WhatIf
    Preview changes without creating any AD objects.

.EXAMPLE
    .\Exercise-02.ps1 -CsvPath "C:\NewUsers.csv" -TargetOU "OU=Users,DC=contoso,DC=com" -WhatIf
    Previews user creation without making changes.

.EXAMPLE
    .\Exercise-02.ps1 -CsvPath "C:\NewUsers.csv" -TargetOU "OU=Users,DC=contoso,DC=com"
    Creates all users defined in the CSV.
#>

#Requires -Modules ActiveDirectory

# ============================================================================
# Script Parameters
# ============================================================================

# TODO: Add [CmdletBinding(SupportsShouldProcess)] and param() block
# Parameters needed:
#   [string]$CsvPath          — Path to the input CSV (mandatory)
#   [SecureString]$DefaultPassword — Default password (mandatory)
#   [string]$TargetOU         — Target OU distinguished name (mandatory)
#   [string]$Domain           — Domain suffix for UPN, e.g. "contoso.com"
#   [string]$ReportPath       — Path for the output report CSV

# Hint:
# [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
# param(
#     [Parameter(Mandatory)]
#     [ValidateScript({ Test-Path $_ -PathType Leaf })]
#     [string]$CsvPath,
#
#     [Parameter(Mandatory)]
#     [SecureString]$DefaultPassword,
#
#     [Parameter(Mandatory)]
#     [string]$TargetOU,
#
#     [string]$Domain = "contoso.com",
#
#     [string]$ReportPath = "C:\ADReports\BulkUserReport.csv"
# )


# ============================================================================
# CSV Format Reference
# ============================================================================
# The input CSV should have these columns:
#
#   FirstName,LastName,SamAccountName,Department,Title,Office,Groups
#   Jane,Doe,jdoe,Engineering,Developer,Seattle,"Developers;VPN Users"
#   John,Smith,jsmith,Sales,Manager,Chicago,"Sales Team;VPN Users"
#
# - Groups column: semicolon-separated list of AD group names
# ============================================================================


# ============================================================================
# Task 1: Validate the CSV File
# ============================================================================
# Import the CSV and verify it contains the required columns.
# Required columns: FirstName, LastName, SamAccountName, Department, Title
# ============================================================================

# TODO: Import the CSV with Import-Csv and store in $Users


# TODO: Validate that required columns exist
# Hint: Check ($Users[0].PSObject.Properties.Name) contains each required column
# If a column is missing, Write-Error and exit


# TODO: Validate each row — check that SamAccountName is not empty and is
#       not longer than 20 characters (SAM account name limit)
# Hint: Loop through $Users and collect validation errors


# ============================================================================
# Task 2: Create AD Users with Splatting
# ============================================================================
# For each valid user row, build a parameter hashtable (splat) and call
# New-ADUser @params. Wrap in try/catch for error handling.
#
# The splat should include:
#   Name, GivenName, Surname, SamAccountName, UserPrincipalName,
#   DisplayName, Department, Title, Office, Path, AccountPassword, Enabled
#
# Cmdlet reference:
#   $params = @{
#       Name              = "$($user.FirstName) $($user.LastName)"
#       GivenName         = $user.FirstName
#       ...
#       AccountPassword   = $DefaultPassword
#       Enabled           = $true
#   }
#   New-ADUser @params
# ============================================================================

# TODO: Initialize a results collection: $Results = [System.Collections.Generic.List[PSObject]]::new()


# TODO: Loop through each user in $Users and:
#   1. Build the parameter splat hashtable
#   2. Use $PSCmdlet.ShouldProcess() to check -WhatIf before calling New-ADUser
#   3. Call New-ADUser @params inside a try block
#   4. Catch errors and record the failure
#   5. Add a result object to $Results with: SamAccountName, Status, Message

# Hint for ShouldProcess:
#   if ($PSCmdlet.ShouldProcess("$($user.FirstName) $($user.LastName)", "Create AD User")) {
#       New-ADUser @params
#   }


# ============================================================================
# Task 3: Add Users to Groups
# ============================================================================
# After creating each user, parse the Groups column (semicolon-separated)
# and add the user to each group with Add-ADGroupMember.
#
# Cmdlet reference:
#   Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
# ============================================================================

# TODO: Inside the user creation loop (or a separate loop), split the Groups
#       column by ";" and call Add-ADGroupMember for each group
# Hint: $groups = $user.Groups -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }


# TODO: Wrap each Add-ADGroupMember call in try/catch
# TODO: Use ShouldProcess before adding to groups


# ============================================================================
# Task 4: Generate Completion Report
# ============================================================================
# Export $Results to a CSV file showing which users were created
# successfully and which failed.
# ============================================================================

# TODO: Export $Results to $ReportPath with Export-Csv -NoTypeInformation


# TODO: Display a summary to the console:
#   - Total users processed
#   - Successfully created
#   - Failed
#   - Skipped (WhatIf)

# Hint:
#   $successCount = ($Results | Where-Object Status -eq 'Created').Count
#   $failCount    = ($Results | Where-Object Status -eq 'Failed').Count
#   Write-Host "Created: $successCount | Failed: $failCount"


Write-Host "`nBulk user creation complete. Report: $ReportPath" -ForegroundColor Green

<#
.SYNOPSIS
    Exercise 02 Solution - Bulk User Creator from CSV

.DESCRIPTION
    Reads user data from a CSV file, validates it, creates Active Directory
    accounts using splatting, assigns users to groups, and produces a
    completion report. Supports -WhatIf for safe dry-run testing.

.NOTES
    Module  : 08 - Active Directory
    Requires: Windows Server 2022, PowerShell 5.1, ActiveDirectory RSAT module
    Domain  : An Active Directory domain is required. New-ADUser and
              Add-ADGroupMember will fail without a domain controller.
    Safety  : Always run with -WhatIf first to preview changes.

.PARAMETER CsvPath
    Path to the input CSV file with user data.

.PARAMETER DefaultPassword
    SecureString password assigned to all new accounts.

.PARAMETER TargetOU
    Distinguished name of the OU where users will be created.

.PARAMETER Domain
    Domain suffix for UserPrincipalName (e.g. "contoso.com").

.PARAMETER ReportPath
    Path for the output report CSV.

.EXAMPLE
    $pw = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
    .\Exercise-02-Solution.ps1 -CsvPath "C:\NewUsers.csv" `
        -DefaultPassword $pw `
        -TargetOU "OU=Users,DC=contoso,DC=com" -WhatIf

.EXAMPLE
    $pw = Read-Host -AsSecureString -Prompt "Default password"
    .\Exercise-02-Solution.ps1 -CsvPath "C:\NewUsers.csv" `
        -DefaultPassword $pw `
        -TargetOU "OU=Users,DC=contoso,DC=com"
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter(Mandatory)]
    [SecureString]$DefaultPassword,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [string]$Domain = "contoso.com",

    [string]$ReportPath = "C:\ADReports\BulkUserReport.csv"
)

# ============================================================================
# CSV Format Reference
# ============================================================================
# FirstName,LastName,SamAccountName,Department,Title,Office,Groups
# Jane,Doe,jdoe,Engineering,Developer,Seattle,"Developers;VPN Users"
# John,Smith,jsmith,Sales,Manager,Chicago,"Sales Team;VPN Users"
# ============================================================================

# ============================================================================
# Task 1: Validate the CSV File
# ============================================================================

$Users = Import-Csv -Path $CsvPath

if ($Users.Count -eq 0) {
    Write-Error "CSV file is empty: $CsvPath"
    return
}

# Verify required columns exist
$RequiredColumns = @('FirstName', 'LastName', 'SamAccountName', 'Department', 'Title')
$CsvColumns = $Users[0].PSObject.Properties.Name

$MissingColumns = $RequiredColumns | Where-Object { $_ -notin $CsvColumns }
if ($MissingColumns) {
    Write-Error "CSV is missing required columns: $($MissingColumns -join ', ')"
    return
}

# Validate each row
$ValidationErrors = [System.Collections.Generic.List[string]]::new()

foreach ($user in $Users) {
    $lineNum = [array]::IndexOf($Users, $user) + 2  # +2 for header row + 1-based

    if ([string]::IsNullOrWhiteSpace($user.SamAccountName)) {
        $ValidationErrors.Add("Row $lineNum : SamAccountName is empty")
    }
    elseif ($user.SamAccountName.Length -gt 20) {
        $ValidationErrors.Add("Row $lineNum : SamAccountName '$($user.SamAccountName)' exceeds 20 chars")
    }

    if ([string]::IsNullOrWhiteSpace($user.FirstName)) {
        $ValidationErrors.Add("Row $lineNum : FirstName is empty")
    }

    if ([string]::IsNullOrWhiteSpace($user.LastName)) {
        $ValidationErrors.Add("Row $lineNum : LastName is empty")
    }
}

if ($ValidationErrors.Count -gt 0) {
    Write-Warning "Validation errors found:"
    $ValidationErrors | ForEach-Object { Write-Warning "  $_" }
    Write-Error "Fix the above errors and re-run. Aborting."
    return
}

Write-Host "CSV validated: $($Users.Count) users to process." -ForegroundColor Cyan

# ============================================================================
# Task 2 & 3: Create AD Users with Splatting and Assign Groups
# ============================================================================

# Ensure report output directory exists
$ReportDir = Split-Path -Path $ReportPath -Parent
if (-not (Test-Path -Path $ReportDir)) {
    New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
}

$Results = [System.Collections.Generic.List[PSObject]]::new()

foreach ($user in $Users) {
    $displayName = "$($user.FirstName) $($user.LastName)"
    $upn         = "$($user.SamAccountName)@$Domain"
    $status      = 'Skipped'
    $message     = ''
    $groupStatus = ''

    # Build the parameter splat for New-ADUser
    $NewUserParams = @{
        Name              = $displayName
        GivenName         = $user.FirstName
        Surname           = $user.LastName
        SamAccountName    = $user.SamAccountName
        UserPrincipalName = $upn
        DisplayName       = $displayName
        Department        = $user.Department
        Title             = $user.Title
        Path              = $TargetOU
        AccountPassword   = $DefaultPassword
        Enabled           = $true
        ChangePasswordAtLogon = $true
    }

    # Add optional properties only if present in the CSV
    if ($user.PSObject.Properties.Name -contains 'Office' -and $user.Office) {
        $NewUserParams['Office'] = $user.Office
    }

    if ($user.PSObject.Properties.Name -contains 'EmailAddress' -and $user.EmailAddress) {
        $NewUserParams['EmailAddress'] = $user.EmailAddress
    }
    else {
        # Default email to UPN
        $NewUserParams['EmailAddress'] = $upn
    }

    # --- Create the user ---
    if ($PSCmdlet.ShouldProcess($displayName, "Create AD User in $TargetOU")) {
        try {
            New-ADUser @NewUserParams
            $status  = 'Created'
            $message = "User created successfully"
            Write-Host "  [+] Created: $displayName ($($user.SamAccountName))" -ForegroundColor Green
        }
        catch {
            $status  = 'Failed'
            $message = $_.Exception.Message
            Write-Warning "  [!] Failed: $displayName — $message"
        }
    }
    else {
        $status  = 'WhatIf'
        $message = 'Skipped (WhatIf mode)'
    }

    # --- Assign to groups ---
    if ($user.PSObject.Properties.Name -contains 'Groups' -and $user.Groups) {
        $groups = $user.Groups -split ';' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' }

        $groupResults = [System.Collections.Generic.List[string]]::new()

        foreach ($groupName in $groups) {
            if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Add to group '$groupName'")) {
                try {
                    Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
                    $groupResults.Add("$groupName : OK")
                }
                catch {
                    $groupResults.Add("$groupName : FAILED - $($_.Exception.Message)")
                    Write-Warning "  [!] Group '$groupName' for $($user.SamAccountName): $($_.Exception.Message)"
                }
            }
            else {
                $groupResults.Add("$groupName : WhatIf")
            }
        }

        $groupStatus = $groupResults -join ' | '
    }

    # Record result
    $Results.Add([PSCustomObject]@{
        SamAccountName = $user.SamAccountName
        DisplayName    = $displayName
        Department     = $user.Department
        Status         = $status
        GroupStatus    = $groupStatus
        Message        = $message
        Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    })
}

# ============================================================================
# Task 4: Generate Completion Report
# ============================================================================

$Results | Export-Csv -Path $ReportPath -NoTypeInformation

# Summary counts
$createdCount = ($Results | Where-Object Status -eq 'Created').Count
$failedCount  = ($Results | Where-Object Status -eq 'Failed').Count
$whatIfCount  = ($Results | Where-Object Status -eq 'WhatIf').Count

Write-Host "`n=============================" -ForegroundColor Cyan
Write-Host "  Bulk User Creation Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Total processed : $($Results.Count)"
Write-Host "  Created         : $createdCount" -ForegroundColor Green
Write-Host "  Failed          : $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Skipped (WhatIf): $whatIfCount" -ForegroundColor Yellow
Write-Host "  Report saved to : $ReportPath"
Write-Host "=============================`n" -ForegroundColor Cyan

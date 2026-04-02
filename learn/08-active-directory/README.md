# Module 08: Active Directory

## Learning Goals

- Query users, computers, and groups with Get-AD* cmdlets
- Create and modify AD objects using New-AD* and Set-AD* cmdlets
- Search with LDAP filters and -Filter syntax
- Use Search-ADAccount for advanced queries
- Manage group memberships and organizational units

## Key Concepts

### 1. Get-ADUser: Query Users
```powershell
# List all users
Get-ADUser -Filter *

# Get specific user
Get-ADUser -Identity "jsmith"
Get-ADUser -Identity "CN=John Smith,OU=Users,DC=contoso,DC=com"

# Get with properties
Get-ADUser -Filter * -Properties Name, Mail, Department

# Filter users
Get-ADUser -Filter { Enabled -eq $true }
Get-ADUser -Filter { Department -like "Engineering" }
Get-ADUser -Filter { LastLogonDate -gt (Get-Date).AddDays(-30) }

# Search by pattern
Get-ADUser -Filter { Name -like "John*" }

# Get user properties
$user = Get-ADUser -Identity "jsmith"
$user.Name
$user.SamAccountName
$user.Enabled
$user.DistinguishedName
```

### 2. Get-ADComputer: Query Computers
```powershell
# List all computers
Get-ADComputer -Filter *

# Get specific computer
Get-ADComputer -Identity "Server01"

# Filter computers
Get-ADComputer -Filter { Name -like "WEB*" }
Get-ADComputer -Filter { OperatingSystem -like "Windows Server 2022" }

# Get properties
Get-ADComputer -Filter * -Properties Name, OperatingSystem, OperatingSystemVersion

# Active computers (modified recently)
$lastLogon = (Get-Date).AddDays(-30)
Get-ADComputer -Filter { LastLogonDate -gt $lastLogon } -Properties LastLogonDate
```

### 3. Get-ADGroup: Query Groups
```powershell
# List all groups
Get-ADGroup -Filter *

# Get specific group
Get-ADGroup -Identity "Admins"

# Filter by scope
Get-ADGroup -Filter { GroupScope -eq "Global" }

# Group members
$group = Get-ADGroup -Identity "Admins"
Get-ADGroupMember -Identity $group

# Members recursively
Get-ADGroupMember -Identity "Admins" -Recursive

# Get group properties
Get-ADGroup -Identity "Admins" -Properties GroupScope, GroupCategory, Members
```

### 4. New-ADUser: Create Users
```powershell
# Create basic user
New-ADUser -Name "Jane Doe" `
    -SamAccountName "jdoe" `
    -UserPrincipalName "jdoe@contoso.com" `
    -DisplayName "Jane Doe" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) `
    -Enabled $true

# Create with properties
New-ADUser -Name "Jane Doe" `
    -SamAccountName "jdoe" `
    -UserPrincipalName "jdoe@contoso.com" `
    -Department "Engineering" `
    -Title "Senior Developer" `
    -Office "Seattle" `
    -EmailAddress "jane.doe@contoso.com" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) `
    -Enabled $true `
    -Path "OU=Users,DC=contoso,DC=com"

# Enable account after creation
$user = New-ADUser -Name "Jane Doe" -SamAccountName "jdoe" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) `
    -Enabled $false -PassThru

Enable-ADAccount -Identity $user
```

### 5. Set-ADUser: Modify Users
```powershell
# Update user properties
Set-ADUser -Identity "jsmith" -Department "Sales" -Title "Manager"

# Change email
Set-ADUser -Identity "jsmith" -EmailAddress "john.smith@contoso.com"

# Change description
Set-ADUser -Identity "jsmith" -Description "Sales Manager - Seattle Office"

# Batch update
Get-ADUser -Filter { Department -eq "Engineering" } | 
    Set-ADUser -Office "Seattle"

# Disable account
Disable-ADAccount -Identity "jsmith"

# Enable account
Enable-ADAccount -Identity "jsmith"

# Reset password
Set-ADAccountPassword -Identity "jsmith" `
    -NewPassword (ConvertTo-SecureString "NewP@ss123" -AsPlainText -Force) `
    -Reset
```

### 6. New-ADComputer and New-ADGroup
```powershell
# Create computer object
New-ADComputer -Name "Server01" `
    -Path "OU=Servers,DC=contoso,DC=com" `
    -SamAccountName "Server01$"

# Create group
New-ADGroup -Name "Developers" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,DC=contoso,DC=com" `
    -Description "Development team members"

# Distribution group
New-ADGroup -Name "Engineering" `
    -GroupScope Universal `
    -GroupCategory Distribution `
    -Path "OU=Groups,DC=contoso,DC=com"
```

### 7. Add/Remove-ADGroupMember
```powershell
# Add user to group
Add-ADGroupMember -Identity "Admins" -Members "jsmith"

# Add multiple users
Add-ADGroupMember -Identity "Developers" `
    -Members "jsmith", "jdoe", "mwilson"

# Remove from group
Remove-ADGroupMember -Identity "Admins" -Members "jsmith" -Confirm:$false

# Clear all members
Get-ADGroupMember -Identity "TestGroup" | 
    Remove-ADGroupMember -Identity "TestGroup" -Confirm:$false
```

### 8. Search-ADAccount: Advanced Queries
```powershell
# Inactive computers (not logged in for 30 days)
Search-ADAccount -AccountInactive -TimeSpan 30.00:00:00 -ComputersOnly

# Disabled accounts
Search-ADAccount -AccountDisabled

# Locked accounts
Search-ADAccount -LockedOut

# Accounts with expired passwords
Search-ADAccount -PasswordNotRequired

# Inactive users (no logon in 90 days)
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly | Select-Object Name, LastLogonDate
```

### 9. LDAP Filters and -LDAPFilter
```powershell
# PowerShell filter syntax
Get-ADUser -Filter { Manager -eq $null }

# LDAP filter syntax (alternative)
Get-ADUser -LDAPFilter "(manager=*)"

# Common LDAP patterns
# (cn=*Smith*)              - Name contains Smith
# (objectClass=user)        - User objects
# (userAccountControl:1.2.840.113556.1.4.803:=2)  - Disabled accounts
# (lastLogonDate>=...) - Complex time comparisons

# Wildcard matching
Get-ADUser -LDAPFilter "(cn=*test*)"

# Negation
Get-ADUser -LDAPFilter "(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))))"
```

### 10. Get-ADOrganizationalUnit
```powershell
# List OUs
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName

# Get specific OU
Get-ADOrganizationalUnit -Identity "OU=Users,DC=contoso,DC=com"

# Create OU
New-ADOrganizationalUnit -Name "Engineering" `
    -Path "OU=Departments,DC=contoso,DC=com"

# Move user to OU
Move-ADObject -Identity "CN=Jane Doe,OU=Users,DC=contoso,DC=com" `
    -TargetPath "OU=Engineers,DC=contoso,DC=com"
```

### 11. Get-ADPrincipalGroupMembership
```powershell
# User's group memberships
Get-ADPrincipalGroupMembership -Identity "jsmith"

# Nested groups
Get-ADPrincipalGroupMembership -Identity "Admins"

# Who's in a group
Get-ADGroupMember -Identity "Admins" -Recursive

# Export group members
Get-ADGroupMember -Identity "Developers" | 
    Select-Object Name, SamAccountName | 
    Export-Csv "C:\developers.csv"
```

### 12. Bulk Operations
```powershell
# Bulk create users from CSV
Import-Csv "C:\users.csv" | ForEach-Object {
    New-ADUser -Name $_.Name `
        -SamAccountName $_.SamAccountName `
        -UserPrincipalName "$($_.SamAccountName)@contoso.com" `
        -Path "OU=Users,DC=contoso,DC=com" `
        -AccountPassword (ConvertTo-SecureString $_.Password -AsPlainText -Force) `
        -Enabled $true
}

# Bulk disable accounts
Get-ADUser -Filter { LastLogonDate -lt (Get-Date).AddDays(-90) } | 
    Disable-ADAccount

# Bulk set property
Get-ADUser -Filter { Department -eq "Engineering" } | 
    Set-ADUser -Office "Redmond"
```

## Real-World Example: AD Reporting

Reference: Common AD administration patterns.

```powershell
function Get-ADSecurityReport {
    [PSCustomObject]@{
        DisabledUsers = (Search-ADAccount -AccountDisabled -UsersOnly).Count
        LockedAccounts = (Search-ADAccount -LockedOut).Count
        InactiveComputers = (Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -ComputersOnly).Count
        PasswordNotRequired = (Search-ADAccount -PasswordNotRequired -UsersOnly).Count
    }
}

# Export users with managers
Get-ADUser -Filter * -Properties Manager, Title, Department |
    Select-Object Name, Title, Department, Manager |
    Export-Csv "C:\users.csv" -NoTypeInformation
```

## Quick Reference: AD Cmdlets

| Task | Cmdlet |
|------|--------|
| Query users | `Get-ADUser` |
| Create user | `New-ADUser` |
| Modify user | `Set-ADUser` |
| Query groups | `Get-ADGroup` |
| Add to group | `Add-ADGroupMember` |
| Query computers | `Get-ADComputer` |
| Advanced query | `Search-ADAccount` |
| Query OUs | `Get-ADOrganizationalUnit` |
| Group members | `Get-ADGroupMember` |
| User groups | `Get-ADPrincipalGroupMembership` |
| Move object | `Move-ADObject` |

## Try It: Hands-On Exercises

### Exercise 1: List all users in department
```powershell
Get-ADUser -Filter { Department -eq "Sales" } | Select-Object Name, Mail
```

### Exercise 2: Inactive computers
```powershell
Search-ADAccount -AccountInactive -TimeSpan 60.00:00:00 -ComputersOnly | Select-Object Name
```

### Exercise 3: Group members export
```powershell
Get-ADGroupMember -Identity "Developers" -Recursive | 
    Select-Object Name, SamAccountName | 
    Export-Csv "C:\devs.csv"
```

### Exercise 4: Locked accounts
```powershell
Search-ADAccount -LockedOut | Select-Object Name, LockedOut
```

### Exercise 5: User's groups
```powershell
Get-ADPrincipalGroupMembership -Identity "jsmith" | Select-Object Name
```

### Exercise 6: Computers by OS
```powershell
Get-ADComputer -Filter * -Properties OperatingSystem | 
    Group-Object OperatingSystem | 
    Select-Object Name, Count
```

### Exercise 7: Create test user
```powershell
New-ADUser -Name "TestUser" `
    -SamAccountName "testuser" `
    -UserPrincipalName "testuser@contoso.com" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
    -Enabled $true -WhatIf
```

### Exercise 8: Bulk disable inactive accounts
```powershell
$inactive = Search-ADAccount -AccountInactive -TimeSpan 180.00:00:00 -UsersOnly
$inactive | ForEach-Object { Write-Host "Would disable: $($_.Name)" }
```

## Further Reading

- [Get-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser)
- [New-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser)
- [Search-ADAccount](https://learn.microsoft.com/en-us/powershell/module/activedirectory/search-adaccount)
- [LDAP Filter Syntax](https://ldapwiki.com/wiki/LDAP%20Filter%20Syntax)
- [Active Directory Cmdlets](https://learn.microsoft.com/en-us/powershell/module/activedirectory/)

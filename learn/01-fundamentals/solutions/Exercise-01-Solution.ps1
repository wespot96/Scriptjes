<#
.SYNOPSIS
    Solution for Exercise 01 - PowerShell Discovery Explorer

.DESCRIPTION
    Complete, working solutions for every section in Exercise-01.ps1.
    Each answer includes comments explaining the "why" behind the approach.

    Target: Windows Server 2022, PowerShell 5.1 (no external modules required)

.NOTES
    Module : 01-fundamentals
    Theme  : PowerShell Discovery Explorer (Solution)
#>

# ============================================================================
# SECTION 1: Cmdlet Discovery with Get-Command
# ============================================================================

# 1a. List every cmdlet whose verb is "Get" and count them.
#     -Verb filters to a specific approved verb; Measure-Object counts objects.
Get-Command -Verb Get | Measure-Object

# 1b. Find all cmdlets with noun "Service" and show only the Name.
#     -Noun narrows results to a specific resource category.
Get-Command -Noun Service | Select-Object Name

# 1c. Search for commands whose name contains "Event".
#     Wildcards (*) allow partial matching on the -Name parameter.
Get-Command -Name *Event* | Select-Object Name


# ============================================================================
# SECTION 2: Object Introspection with Get-Member
# ============================================================================

# 2a. Pipe Get-Process to Get-Member to see the object's type and members.
#     The TypeName header tells you this returns System.Diagnostics.Process.
Get-Process | Get-Member

# 2b. Show only Property members of Get-Service output.
#     -MemberType Property filters out methods, events, etc.
Get-Service | Get-Member -MemberType Property

# 2c. Show Method members of Get-Date, then call AddDays(30).
#     Get-Member reveals that DateTime has AddDays, AddHours, etc.
Get-Date | Get-Member -MemberType Method

#     Wrapping Get-Date in parentheses lets us call a method on the result
#     directly — this is the "parentheses for evaluation" pattern.
(Get-Date).AddDays(30)


# ============================================================================
# SECTION 3: Comparison Operators and Filtering
# ============================================================================

# 3a. Filter server names starting with "WEB" using -like.
#     -like uses wildcard patterns (* = any chars, ? = one char).
$servers = @("WEB01", "DB01", "WEB02", "APP01", "DB02", "FILE01")
$servers | Where-Object { $_ -like 'WEB*' }

# 3b. Filter with -match using a regex pattern.
#     -match tests against a regular expression; \d+ means "one or more digits".
$servers | Where-Object { $_ -match 'DB\d+' }

# 3c. Test membership with -contains and store result.
#     -contains checks if a collection includes a specific value.
#     Note: the collection goes on the LEFT side of -contains.
$hasAppServer = $servers -contains "APP01"
$hasAppServer


# ============================================================================
# SECTION 4: Variables, Types, and Casting
# ============================================================================

# 4a. Create variables of different types and inspect them.
#     PowerShell infers the type from the value assigned.
$name  = "SERVER01"
$count = 42
$price = 19.99

# .GetType().Name returns the short .NET type name (String, Int32, Double).
$name.GetType().Name
$count.GetType().Name
$price.GetType().Name

# 4b. Cast a string to int and verify the type change.
#     [int] is a type accelerator — PowerShell converts the string to Int32.
$numericString = "256"
$asInt = [int]$numericString

$numericString.GetType().Name   # String
$asInt.GetType().Name           # Int32

# 4c. Cast a date string to DateTime and read DayOfWeek.
#     [datetime] parses common date formats automatically.
$myDate = [datetime]"2024-06-15"
$myDate.DayOfWeek


# ============================================================================
# SECTION 5: String Interpolation and Subexpressions
# ============================================================================

# 5a. Double-quoted strings expand $variables automatically.
$computerName = $env:COMPUTERNAME
"This script is running on $computerName"

# 5b. Subexpressions $() let you embed commands or expressions in strings.
#     Without $(), PowerShell would try to expand a simple variable name and fail.
"Today is $(Get-Date -Format 'dddd'), $(Get-Date)"

# 5c. Single vs double quotes.
#     Double quotes: variable is replaced with its value.
#     Single quotes: everything is treated as literal text.
$fruit = "apple"
"I like $fruit"    # Output: I like apple
'I like $fruit'    # Output: I like $fruit


# ============================================================================
# SECTION 6: Putting It Together — Mini Pipeline Challenge
# ============================================================================

# 6a. Running services — filter, select, sort in one pipeline.
#     Where-Object filters, Select-Object picks properties, Sort-Object orders.
Get-Service | Where-Object { $_.Status -eq 'Running' } |
    Select-Object Name, DisplayName |
    Sort-Object Name

# 6b. Cmdlets with the most parameters from a specific module.
#     The calculated property counts parameters by accessing the Parameters
#     dictionary that every cmdlet info object exposes.
Get-Command -Module Microsoft.PowerShell.Management |
    Select-Object Name, @{
        Name       = 'ParameterCount'
        Expression = { $_.Parameters.Count }
    } |
    Sort-Object ParameterCount -Descending |
    Select-Object -First 3


Write-Host "`nExercise 01 Solution complete!" -ForegroundColor Green

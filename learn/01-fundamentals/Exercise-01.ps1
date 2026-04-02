<#
.SYNOPSIS
    Exercise 01 - PowerShell Discovery Explorer

.DESCRIPTION
    Practice the core discovery and introspection tools that make PowerShell
    self-documenting: Get-Command, Get-Member, variables, types, operators,
    and string interpolation.

    Target: Windows Server 2022, PowerShell 5.1 (no external modules required)

.NOTES
    Module : 01-fundamentals
    Theme  : PowerShell Discovery Explorer
    Instructions:
      - Replace every "# TODO: Your code here" with working PowerShell code.
      - Run the script section-by-section in an interactive console, or
        execute the whole file with:  .\Exercise-01.ps1
      - Each section is independent; you can work on them in any order.
#>

# ============================================================================
# SECTION 1: Cmdlet Discovery with Get-Command
# ============================================================================
# PowerShell cmdlets follow a Verb-Noun naming convention.
# Use Get-Command to explore what is available on the system.

# 1a. List every cmdlet whose verb is "Get" and count how many there are.
#     Hint: pipe Get-Command to Measure-Object.
# TODO: Your code here


# 1b. Find all cmdlets that have "Service" as the noun.
#     Display only the Name property.
# TODO: Your code here


# 1c. Search for any command whose name contains the word "Event".
#     Use the -Name parameter with a wildcard pattern.
# TODO: Your code here


# ============================================================================
# SECTION 2: Object Introspection with Get-Member
# ============================================================================
# PowerShell pipelines pass objects, not text.
# Get-Member reveals the properties and methods an object has.

# 2a. Pipe Get-Process to Get-Member.
#     What type of object does Get-Process return? Note the TypeName at the top.
# TODO: Your code here


# 2b. List only the *Property* members of objects returned by Get-Service.
#     Hint: use the -MemberType parameter.
# TODO: Your code here


# 2c. Pipe Get-Date to Get-Member and filter to show only *Method* members.
#     Then pick one method (e.g., AddDays) and call it on today's date
#     to calculate the date 30 days from now.
# TODO: Your code here (Get-Member line)

# TODO: Your code here (call the method to get date 30 days from now)


# ============================================================================
# SECTION 3: Comparison Operators and Filtering
# ============================================================================
# PowerShell uses -eq, -ne, -gt, -lt, -ge, -le, -like, -match, -contains.

# 3a. Create an array of server names:
#       @("WEB01", "DB01", "WEB02", "APP01", "DB02", "FILE01")
#     Use Where-Object (or its alias ?) to filter only servers that start
#     with "WEB".  Use the -like operator.
# TODO: Your code here


# 3b. Using the same array, filter servers whose names match the regex
#     pattern "DB\d+" (i.e., "DB" followed by one or more digits).
#     Use the -match operator.
# TODO: Your code here


# 3c. Check whether the array -contains "APP01". Store the boolean result
#     in a variable named $hasAppServer and output it.
# TODO: Your code here


# ============================================================================
# SECTION 4: Variables, Types, and Casting
# ============================================================================
# Every value in PowerShell is a .NET object with a specific type.

# 4a. Create three variables:
#       $name   = a string with any server name
#       $count  = an integer (e.g., 42)
#       $price  = a double  (e.g., 19.99)
#     For each one, call .GetType().Name to display its type.
# TODO: Your code here


# 4b. Create a string variable $numericString = "256".
#     Cast it to [int] and store in $asInt.
#     Verify the type changed by calling .GetType().Name on both.
# TODO: Your code here


# 4c. Create a DateTime variable by casting the string "2024-06-15" to
#     [datetime]. Display the DayOfWeek property.
# TODO: Your code here


# ============================================================================
# SECTION 5: String Interpolation and Subexpressions
# ============================================================================
# Double-quoted strings expand variables; single-quoted strings are literal.

# 5a. Set $computerName = $env:COMPUTERNAME.
#     Use double-quoted string interpolation to output:
#       "This script is running on <computername>"
# TODO: Your code here


# 5b. Use a subexpression $() inside a double-quoted string to output:
#       "Today is <DayOfWeek>, <full date>"
#     Hint: $(Get-Date -Format 'dddd') and $(Get-Date)
# TODO: Your code here


# 5c. Demonstrate the difference between single and double quotes.
#     Create $fruit = "apple" and output both:
#       "I like $fruit"   (should expand)
#       'I like $fruit'   (should stay literal)
# TODO: Your code here


# ============================================================================
# SECTION 6: Putting It Together — Mini Pipeline Challenge
# ============================================================================
# Combine what you learned: discovery, piping, filtering, and formatting.

# 6a. In a single pipeline, get all running services, select only the
#     Name and DisplayName properties, and sort by Name.
# TODO: Your code here


# 6b. Get the 3 cmdlets from the Microsoft.PowerShell.Management module
#     that have the most parameters.
#     Hint: use Get-Command with -Module, pipe to Select-Object with a
#     calculated property for parameter count, then Sort and Select -First.
# TODO: Your code here


Write-Host "`nExercise 01 complete — review your output above!" -ForegroundColor Green

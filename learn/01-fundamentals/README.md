# Module 01: PowerShell Fundamentals

## Learning Goals

- Understand the pipeline and how objects flow through PowerShell
- Learn Verb-Noun cmdlet naming convention and discovery
- Work with variables, types, and operators
- Use Get-Help, Get-Command, and Get-Member effectively
- Grasp core differences from batch/VBScript and similarities to programming languages

## Key Concepts

### 1. The Pipeline (`|`)
Everything in PowerShell connects through pipelines. Objects (not text) flow left-to-right.

```powershell
# Get processes, pipe to Where-Object to filter, pipe to Select-Object to project
Get-Process | Where-Object { $_.Memory -gt 100MB } | Select-Object Name, Memory

# Comparison: Batch (text output), PowerShell (objects)
# Objects have properties you can access: $_. notation
```

### 2. Verb-Noun Cmdlet Convention
All cmdlets follow `Verb-Noun` format. Common verbs: Get, Set, New, Remove, Start, Stop, Test, Invoke.

```powershell
# Discover cmdlets
Get-Command -Verb Get | Select-Object Name
Get-Command -Noun Service | Select-Object Name
Get-Command -Name *Event* | Select-Object Name
```

### 3. Get-Help: Your Documentation Lifeline
```powershell
Get-Help Get-Process
Get-Help Get-Process -Full
Get-Help Get-Process -Examples
Get-Help -Name Get-Service -Online  # Open in browser
Update-Help  # Download latest offline help
```

### 4. Get-Command: Discovery
```powershell
Get-Command  # List all cmdlets
Get-Command -CommandType Function
Get-Command -CommandType Alias
Get-Command -Module ActiveDirectory  # Module-specific commands
```

### 5. Get-Member: Object Introspection
```powershell
Get-Process | Get-Member  # See properties and methods
Get-Process | Get-Member -MemberType Property
Get-Service | Get-Member -MemberType Method
```

### 6. Variables and Types
```powershell
$name = "Server01"  # String
$count = 42  # Int32
$price = 19.99  # Double
$flag = $true  # Boolean
$date = Get-Date  # DateTime
$array = @(1, 2, 3)  # Array
$hash = @{ Name = "Server01"; IP = "192.168.1.1" }  # Hashtable

# Type casting
[int]"42"
[datetime]"2024-01-15"
$name.GetType()
```

### 7. Operators
```powershell
# Comparison operators
$x -eq 5      # Equal
$x -ne 5      # Not equal
$x -lt 5      # Less than
$x -gt 5      # Greater than
$x -le 5      # Less than or equal
-match/-notmatch  # Regex matching
-contains/-in     # Membership

# Logical operators
-and, -or, -not

# Assignment operators
$x = 5
$x += 10  # $x is now 15
$x *= 2   # $x is now 30
```

### 8. Automatic Variables
```powershell
$_      # Current object in pipeline
$PSVersionTable  # PowerShell version info
$HOME   # User home directory
$PWD    # Current directory
$null   # Null/nothing
$true, $false  # Booleans
$Error  # Last error
```

### 9. String Interpolation
```powershell
$name = "Server01"
"Hello, $name"  # String interpolation
"Hello, $(Get-Hostname)"  # Subexpression
'Hello, $name'  # Literal (single quotes)
```

### 10. Array and Collection Basics
```powershell
$array = 1, 2, 3, 4, 5
$array[0]  # First element
$array[-1]  # Last element
$array.Count
$array += 6  # Add element
@()  # Empty array
```

### 11. Hashtable Basics
```powershell
$hash = @{
    Name = "Server01"
    IP = "192.168.1.1"
    Role = "WebServer"
}
$hash.Name
$hash['IP']
$hash.Keys
$hash.Values
```

### 12. Parentheses and Subexpressions
```powershell
# Parentheses for grouping and evaluation
(Get-Date).AddDays(7)
(5 + 3) * 2

# Subexpressions in strings
"Today is $(Get-Date -Format 'dddd')"

# Command substitution
$processes = $(Get-Process)
```

## Real-World Example: System Quick Check

```powershell
# Get CPU, Memory, and running service count
$ComputerName = $env:COMPUTERNAME
$CPU = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$Memory = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
$ServiceCount = (Get-Service | Where-Object { $_.Status -eq 'Running' }).Count

"Computer: $ComputerName"
"Average CPU Load: $CPU%"
"Total Memory: $([Math]::Round($Memory / 1GB, 2)) GB"
"Running Services: $ServiceCount"
```

## Quick Reference: PowerShell vs Other Languages

| Concept | PowerShell | C# | Python |
|---------|-----------|-----|--------|
| Objects | Native (`Get-Process`) | Classes | Objects |
| Pipeline | `\|` operator | LINQ | Method chaining |
| Variable prefix | `$` | None | None |
| String interpolation | `"$var"` | `$"{var}"` | `f"{var}"` |
| Null | `$null` | `null` | `None` |
| Array index | `$arr[0]` | `arr[0]` | `arr[0]` |
| Loop | `foreach ($x in $collection)` | `foreach (var x in collection)` | `for x in collection:` |
| Comments | `#` | `//` or `/* */` | `#` |
| Comparison | `-eq`, `-lt` | `==`, `<` | `==`, `<` |

## Try It: Hands-On Exercises

### Exercise 1: Explore cmdlets by verb
```powershell
# List all Get cmdlets
Get-Command -Verb Get | Measure-Object

# List all Set cmdlets and pipe to help
Get-Command -Verb Set | Select-Object -First 3 | ForEach-Object { Get-Help $_.Name }
```

### Exercise 2: Process inspection
```powershell
# Get all processes, display name and memory
Get-Process | Select-Object Name, @{ Name = 'Memory (MB)'; Expression = { $_.Memory / 1MB } }

# Find the process using most memory
Get-Process | Sort-Object Memory -Descending | Select-Object -First 1
```

### Exercise 3: Variable types and casting
```powershell
# Create different types
$str = "42"
$int = [int]$str
$double = [double]$str

# Compare types
$str.GetType()
$int.GetType()
$double.GetType()
```

### Exercise 4: String operations
```powershell
$server = "SERVER01"
"Hostname: $server"
"Server is $(if ($server -like 'SERVER*') { 'named correctly' } else { 'check name' })"
```

### Exercise 5: Array filtering
```powershell
$servers = @("WEB01", "DB01", "WEB02", "FILE01", "DB02")
$webServers = $servers | Where-Object { $_ -like 'WEB*' }
$webServers
```

### Exercise 6: Hashtable creation and access
```powershell
$config = @{
    Database = "Production"
    Backup = "Enabled"
    Retention = 30
}
$config.Database
"Backup is $($config.Backup)"
```

### Exercise 7: Piping and filtering
```powershell
# Pipeline: Get all services, filter to running, count
Get-Service | Where-Object { $_.Status -eq 'Running' } | Measure-Object

# Same with explicit variable
$running = Get-Service | Where-Object { $_.Status -eq 'Running' }
$running.Count
```

### Exercise 8: Using Get-Member
```powershell
$date = Get-Date
$date | Get-Member -MemberType Property | Select-Object Name
$date | Get-Member -MemberType Method | Select-Object Name
```

## Further Reading

- [Microsoft Docs: PowerShell Overview](https://learn.microsoft.com/en-us/powershell/)
- [PowerShell Operators Reference](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators)
- [Get-Help Examples and Syntax](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-help)
- [About Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables)
- [About Objects](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_objects)

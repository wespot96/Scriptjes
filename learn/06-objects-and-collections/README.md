# Module 06: Objects and Collections

## Learning Goals

- Create custom objects with PSCustomObject
- Work with hashtables and advanced collections
- Use Where-Object, Select-Object, Sort-Object, Group-Object for data manipulation
- Import and export CSV and JSON formats
- Use Generic.List for efficient collection management

## Key Concepts

### 1. PSCustomObject: Creating Custom Objects
```powershell
# Create single object
$obj = [PSCustomObject]@{
    Name = "Server01"
    IP = "192.168.1.1"
    Status = "Online"
}

# Access properties
$obj.Name
$obj."IP"  # Use quotes if special chars

# Object from hashtable
$hash = @{ ComputerName = "DB01"; Memory = 16384 }
$obj = [PSCustomObject]$hash

# Reorder properties
$obj = [PSCustomObject]@{
    Name = "Server01"
    IP = "192.168.1.1"
    Status = "Online"
} | Select-Object Name, IP, Status
```

### 2. Hashtables: Key-Value Collections
```powershell
# Create hashtable
$config = @{
    Server = "DB01"
    Port = 5432
    Database = "Production"
    Encryption = $true
}

# Access values
$config.Server
$config["Port"]
$config['Database']

# Add/modify
$config.User = "admin"
$config["Password"] = "secret"

# Iterate
foreach ($key in $config.Keys) {
    Write-Host "$key : $($config[$key])"
}

# Check if key exists
if ($config.ContainsKey("Server")) { }

# Ordered hashtable (maintains order)
$ordered = [ordered]@{
    First = 1
    Second = 2
    Third = 3
}
```

### 3. Arrays and Collections
```powershell
# Array initialization
$arr = @()
$arr = @(1, 2, 3)
$arr = 1, 2, 3

# Add to array
$arr += 4  # Creates new array
$arr | Measure-Object  # Count elements

# Array access
$arr[0]      # First element
$arr[-1]     # Last element
$arr[0, 2]   # Multiple elements
$arr[1..3]   # Range

# Array slicing
$arr[0..2]   # First three
$arr[-3..-1] # Last three
```

### 4. Where-Object: Filtering
```powershell
# Simple filter
Get-Process | Where-Object { $_.Memory -gt 100MB }

# Multiple conditions
Get-Process | Where-Object { $_.Memory -gt 100MB -and $_.CPU -gt 10 }

# String matching
Get-Process | Where-Object { $_.Name -like "pow*" }

# Advanced filtering with -FilterScript
$services = Get-Service | Where-Object { $_.Status -eq "Running" }

# Negation
Get-Service | Where-Object { $_.Status -ne "Running" }
```

### 5. Select-Object: Projection and Limiting
```powershell
# Select specific properties
Get-Process | Select-Object Name, Memory

# First N items
Get-Process | Select-Object -First 5

# Last N items
Get-Service | Select-Object -Last 3

# Skip items
Get-Process | Select-Object -Skip 10 -First 5

# Calculated properties
Get-Process | Select-Object Name, @{ Name = 'Memory(MB)'; Expression = { $_.Memory / 1MB } }

# Unique values
Get-Service | Select-Object -Property Status -Unique
```

### 6. Sort-Object: Ordering
```powershell
# Sort ascending
Get-Process | Sort-Object Memory

# Sort descending
Get-Process | Sort-Object Memory -Descending

# Multiple sort keys
Get-Process | Sort-Object Name, Memory -Descending

# Custom sort
$data | Sort-Object { [int]($_.Value) }
```

### 7. Group-Object: Grouping
```powershell
# Group by property
Get-Service | Group-Object -Property Status

# Access group results
$grouped = Get-Service | Group-Object Status
$grouped[0].Name        # Group key
$grouped[0].Count       # Item count
$grouped[0].Group       # Items in group

# Multiple grouping
Get-Process | Group-Object -Property ProcessName, Company
```

### 8. Measure-Object: Statistics
```powershell
# Count items
Get-Process | Measure-Object
Get-Process | Measure-Object -Property Memory

# Sum values
$data = 1, 2, 3, 4, 5
$data | Measure-Object -Sum  # Returns 15

# Multiple statistics
Get-Process | Measure-Object -Property Memory -Sum -Average -Maximum -Minimum

# Count with filtering
(Get-Service | Where-Object { $_.Status -eq "Running" } | Measure-Object).Count
```

### 9. Generic.List: Efficient Collection
```powershell
# Create strongly-typed list
$list = [System.Collections.Generic.List[PSCustomObject]]::new()

# Add items (faster than array +=)
$list.Add([PSCustomObject]@{ Name = "Server01" })
$list.Add([PSCustomObject]@{ Name = "Server02" })

# Iteration
foreach ($item in $list) {
    $item.Name
}

# Convert to array
$array = $list.ToArray()

# Benefits: No array reallocation on each Add, strongly typed
```

### 10. Import-Csv and Export-Csv
```powershell
# Export to CSV
Get-Service | Select-Object Name, Status | Export-Csv -Path "C:\services.csv" -NoTypeInformation

# Import from CSV
$data = Import-Csv -Path "C:\services.csv"

# Specify delimiter
Export-Csv -Path "C:\data.csv" -Delimiter "`t"
$data = Import-Csv -Path "C:\data.csv" -Delimiter "`t"

# Access imported data
$data[0].Name   # First item's Name property
$data.Count     # Number of rows
```

### 11. ConvertTo-Json and ConvertFrom-Json
```powershell
# Convert to JSON
$obj = [PSCustomObject]@{
    Name = "Server01"
    IP = "192.168.1.1"
    Status = "Online"
}
$json = $obj | ConvertTo-Json

# Pretty print
$obj | ConvertTo-Json -Depth 10

# Convert from JSON
$jsonText = '{"Name":"Server01","IP":"192.168.1.1"}'
$obj = $jsonText | ConvertFrom-Json
$obj.Name  # "Server01"

# Array of objects
$array = @(@{Name="S1"}, @{Name="S2"}) | ConvertTo-Json -AsArray
```

### 12. Advanced Collection Operations
```powershell
# Remove duplicates
$data = 1, 2, 2, 3, 3, 3
$unique = $data | Select-Object -Unique

# Compare collections
$set1 = 1, 2, 3
$set2 = 2, 3, 4
$set1 | Where-Object { $_ -notin $set2 }  # 1 (in set1 but not set2)

# Flatten nested arrays
$nested = @(1, @(2, 3), 4)
$nested | ForEach-Object { $_ }  # Still nested

# Join array as string
$servers = "WEB01", "WEB02", "WEB03"
$servers -join ", "  # "WEB01, WEB02, WEB03"
```

## Real-World Example: Server Inventory Report

Reference: **ConnectionTest.ps1** and **ServerHealthDashboard.ps1**

These scripts demonstrate:
- Building collections of custom objects
- Filtering and grouping data
- Exporting results in multiple formats
- Real-time data aggregation

```powershell
function Get-ServerInventory {
    param([string[]]$ComputerName)
    
    $inventory = @()
    
    foreach ($computer in $ComputerName) {
        if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
            $os = Get-WmiObject -ComputerName $computer -Class Win32_OperatingSystem
            $proc = Get-WmiObject -ComputerName $computer -Class Win32_Processor
            
            $inventory += [PSCustomObject]@{
                ComputerName = $computer
                OS = $os.Caption
                Memory = [Math]::Round($os.TotalVisibleMemorySize / 1MB)
                CPUCores = $proc.NumberOfCores
                Status = "Online"
            }
        } else {
            $inventory += [PSCustomObject]@{
                ComputerName = $computer
                Status = "Offline"
            }
        }
    }
    
    return $inventory
}

# Usage
$servers = Get-ServerInventory "Server01", "Server02", "Server03"
$servers | Group-Object Status
$servers | Export-Csv "C:\inventory.csv" -NoTypeInformation
```

## Quick Reference: Collection Operations

| Operation | Cmdlet | Purpose |
|-----------|--------|---------|
| Filter | `Where-Object` | Keep items matching condition |
| Project | `Select-Object` | Choose/calculate properties |
| Sort | `Sort-Object` | Order by property |
| Group | `Group-Object` | Organize into buckets |
| Count | `Measure-Object` | Statistics |
| Unique | `Select-Object -Unique` | Remove duplicates |
| Export | `Export-Csv` | Save to file |
| Convert | `ConvertTo-Json` | Format conversion |
| Filter | `Where-Object` | Filter items |

## Try It: Hands-On Exercises

### Exercise 1: Create custom objects
```powershell
$servers = @(
    [PSCustomObject]@{ Name = "WEB01"; Role = "WebServer"; Memory = 8 },
    [PSCustomObject]@{ Name = "DB01"; Role = "Database"; Memory = 16 },
    [PSCustomObject]@{ Name = "WEB02"; Role = "WebServer"; Memory = 8 }
)

$servers | Format-Table
```

### Exercise 2: Filter and select
```powershell
$servers | Where-Object { $_.Role -eq "WebServer" } |
    Select-Object Name, Memory
```

### Exercise 3: Group and count
```powershell
$servers | Group-Object -Property Role |
    Select-Object Name, Count
```

### Exercise 4: Calculated properties
```powershell
Get-Process | Select-Object Name,
    @{ Name = 'Handles'; Expression = { $_.Handles } },
    @{ Name = 'Memory (MB)'; Expression = { [Math]::Round($_.Memory / 1MB, 2) } }
```

### Exercise 5: Export and import
```powershell
# Export
Get-Service | Select-Object Name, Status | Export-Csv "C:\services.csv"

# Import and filter
Import-Csv "C:\services.csv" | Where-Object { $_.Status -eq "Running" }
```

### Exercise 6: JSON conversion
```powershell
$data = [PSCustomObject]@{ Name = "Server"; Status = "Online" }
$json = $data | ConvertTo-Json
$data2 = $json | ConvertFrom-Json
```

### Exercise 7: Statistics with Measure-Object
```powershell
$processes = Get-Process
$processes | Measure-Object -Property Memory -Average -Maximum -Minimum
```

### Exercise 8: Generic.List for performance
```powershell
$list = [System.Collections.Generic.List[int]]::new()
1..1000 | ForEach-Object { $list.Add($_) }
$list.Count
```

## Further Reading

- [PSCustomObject](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_object_creation)
- [Hashtables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables)
- [Where-Object](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object)
- [Select-Object](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-object)
- [ConvertTo-Json](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-json)
- [Import-Csv](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-csv)

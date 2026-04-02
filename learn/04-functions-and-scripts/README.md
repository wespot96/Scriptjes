# Module 04: Functions and Scripts

## Learning Goals

- Write reusable functions with parameters and return values
- Apply CmdletBinding for advanced parameter features
- Create comment-based help for self-documenting scripts
- Implement pipeline input with begin/process/end blocks
- Package scripts as modules for reuse

## Key Concepts

### 1. Basic Function Structure
```powershell
# Simplest function
function Get-Greeting {
    Write-Output "Hello, World!"
}

# Function with parameters
function Get-Greeting {
    param($Name)
    Write-Output "Hello, $Name!"
}

# Explicit return value
function Add-Numbers {
    param($A, $B)
    return $A + $B
}

# Multiple return values
function Get-Status {
    return "Online", "OK", 100
}

$status = Get-Status
# $status is array: @("Online", "OK", 100)
```

### 2. Parameter Declaration and Types
```powershell
function Connect-Server {
    param(
        [string]$ComputerName,
        [int]$Port = 3389,
        [bool]$Encrypted = $true
    )
    Write-Output "Connecting to $ComputerName on port $Port"
}

# Type validation
function Set-Configuration {
    param(
        [string[]]$Servers,     # Array of strings
        [ValidateRange(1, 65535)][int]$Port,
        [ValidateSet("TCP", "UDP", "BOTH")][string]$Protocol,
        [ValidatePattern("^\d{1,3}\.\d{1,3}$")][string]$Subnet
    )
}

# Mandatory parameters
function Remove-Service {
    param(
        [Parameter(Mandatory=$true)][string]$ServiceName,
        [string]$ComputerName
    )
}
```

### 3. CmdletBinding for Advanced Features
```powershell
function Get-ServerInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$ComputerName,
        
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Credential
    )

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Processing $computer"
            Get-WmiObject -ComputerName $computer -Class Win32_ComputerSystem
        }
    }
}

# Enables: -Verbose, -Debug, -ErrorAction, -WarningAction, etc.
```

### 4. Comment-Based Help
```powershell
function Get-ServiceStatus {
    <#
    .SYNOPSIS
    Gets the status of specified Windows services.

    .DESCRIPTION
    Retrieves service status and startup type from local or remote computers.

    .PARAMETER ComputerName
    The computer name to query. Default is localhost.

    .PARAMETER ServiceName
    The name of the service to retrieve. Wildcards supported.

    .EXAMPLE
    Get-ServiceStatus -ServiceName "Windows*"
    Lists all services starting with "Windows"

    .EXAMPLE
    Get-ServiceStatus -ServiceName "w3svc" -ComputerName "WEB01"
    Gets IIS service status from WEB01

    .INPUTS
    System.String

    .OUTPUTS
    PSCustomObject with Status and StartupType

    .NOTES
    Author: Admin
    Date: 2024-01-15
    #>
    param(
        [string]$ServiceName = "*",
        [string]$ComputerName = $env:COMPUTERNAME
    )
    Get-Service -DisplayName $ServiceName -ComputerName $ComputerName
}

# Access help
Get-Help Get-ServiceStatus
Get-Help Get-ServiceStatus -Full
Get-Help Get-ServiceStatus -Examples
```

### 5. Begin, Process, End Blocks
```powershell
function Process-Servers {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string[]]$ComputerName
    )

    begin {
        # Runs once at start
        Write-Host "Starting batch process"
        $totalProcessed = 0
    }

    process {
        # Runs once for each input object
        foreach ($computer in $ComputerName) {
            Write-Host "Processing: $computer"
            Get-Service -ComputerName $computer
            $totalProcessed++
        }
    }

    end {
        # Runs once at end
        Write-Host "Processed $totalProcessed servers"
    }
}

# Usage with pipeline
@("Server01", "Server02") | Process-Servers
```

### 6. Pipeline Input
```powershell
function Stop-ProcessByName {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Name")]
        [string[]]$ProcessName
    )

    process {
        foreach ($name in $ProcessName) {
            $processes = Get-Process -Name $name -ErrorAction SilentlyContinue
            foreach ($proc in $processes) {
                if ($PSCmdlet.ShouldProcess($proc.Name, "Stop-Process")) {
                    $proc | Stop-Process -Force
                }
            }
        }
    }
}

# Usage
"notepad", "calc" | Stop-ProcessByName
Get-Process | Where-Object { $_.Memory -gt 100MB } | Stop-ProcessByName -WhatIf
```

### 7. Advanced Parameters
```powershell
function Backup-Database {
    [CmdletBinding()]
    param(
        # Positional, mandatory
        [Parameter(Mandatory=$true, Position=0)]
        [string]$DatabaseName,

        # Accepts values from pipeline
        [Parameter(ValueFromPipeline=$true)]
        [string]$BackupPath,

        # Switch parameter (boolean without value)
        [switch]$Compressed,

        # Array with default
        [string[]]$ExcludedTables = @()
    )

    # Code here
}

# Calling patterns
Backup-Database "Production"
Backup-Database "Production" -BackupPath "C:\Backups" -Compressed
"C:\Backups" | Backup-Database "Production" -Compressed
```

### 8. Return Values and Output
```powershell
function Get-ServerReport {
    param([string]$ComputerName)

    # Create object with properties
    $report = [PSCustomObject]@{
        ComputerName = $ComputerName
        Timestamp = Get-Date
        Online = (Test-Connection $ComputerName -Quiet -Count 1)
        Services = (Get-Service -ComputerName $ComputerName).Count
    }

    return $report
    # Or just: $report (implicit return)
}

# Results can be piped
Get-ServerReport "Server01" | Select-Object ComputerName, Online
```

### 9. Error Handling in Functions
```powershell
function Get-FileContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        Get-Content -Path $FilePath
    }
    catch {
        Write-Error "Failed to read file: $_"
    }
    finally {
        Write-Verbose "Cleanup completed"
    }
}
```

### 10. Script Files and Dot-Sourcing
```powershell
# Script file: Get-Utilities.ps1
function Get-DiskSpace {
    param([string]$ComputerName)
    Get-WmiObject -Class Win32_LogicalDisk -ComputerName $ComputerName
}

function Get-MemoryUsage {
    param([string]$ComputerName)
    Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
}

# Use in another script
. "C:\Scripts\Get-Utilities.ps1"  # Dot-source to load functions
Get-DiskSpace "Server01"
```

### 11. Writing Modules (Simplified)
```powershell
# File: C:\Users\Admin\Documents\PowerShell\Modules\MyTools\MyTools.psm1
function Get-ServerHealth {
    param([string[]]$ComputerName)
    # Implementation
}

function Restart-RemoteService {
    param(
        [string]$ComputerName,
        [string]$ServiceName
    )
    # Implementation
}

# In profile or script:
Import-Module MyTools
Get-ServerHealth "Server01"
```

### 12. Validation and Error Prevention
```powershell
function Set-ServerConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ConfigPath,

        [ValidateRange(1, 65535)]
        [int]$Port = 3389,

        [ValidateSet("HTTP", "HTTPS")]
        [string]$Protocol = "HTTPS",

        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    # Parameters are guaranteed valid at this point
}
```

## Real-World Example: Connection Test

Reference: **ConnectionTest.ps1**

This script demonstrates:
- Function parameters with validation
- Pipeline input handling
- Comment-based help
- Error handling with try/catch
- Return values and object construction

```powershell
function Test-ServerConnection {
    <#
    .SYNOPSIS
    Tests connectivity and basic service status on a server.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$ComputerName,

        [int[]]$Ports = @(3389, 445, 135)
    )

    process {
        foreach ($computer in $ComputerName) {
            $ping = Test-Connection -ComputerName $computer -Count 1 -Quiet
            
            $result = [PSCustomObject]@{
                ComputerName = $computer
                Responsive = $ping
                Timestamp = Get-Date
                Services = if ($ping) { 
                    @(Get-Service -ComputerName $computer -ErrorAction SilentlyContinue).Count 
                } else { 
                    0 
                }
            }
            $result
        }
    }
}

# Usage
@("Server01", "Server02") | Test-ServerConnection -Ports 3389, 445
```

## Quick Reference: Function Features

| Feature | Syntax | Purpose |
|---------|--------|---------|
| Parameter | `param($name)` | Accept arguments |
| Type | `[string]$name` | Enforce type |
| Mandatory | `[Parameter(Mandatory=$true)]` | Required parameter |
| Pipeline | `[Parameter(ValueFromPipeline=$true)]` | Accept pipe input |
| Default | `$param = "default"` | Default value |
| Validation | `[ValidateRange(1, 100)]` | Restrict values |
| Help | `<# .SYNOPSIS ... #>` | Documentation |
| CmdletBinding | `[CmdletBinding()]` | Advanced features |
| Begin/Process/End | `begin { } process { } end { }` | Pipeline stages |
| Return | `return $value` | Explicit return |

## Try It: Hands-On Exercises

### Exercise 1: Simple function with parameters
```powershell
function Get-Greeting {
    param([string]$Name = "World")
    "Hello, $Name!"
}

Get-Greeting
Get-Greeting -Name "PowerShell"
```

### Exercise 2: Function with validation
```powershell
function Set-Port {
    param(
        [ValidateRange(1, 65535)]
        [int]$Port
    )
    "Setting port to $Port"
}

Set-Port -Port 8080
Set-Port -Port 99999  # Error due to validation
```

### Exercise 3: Comment-based help
```powershell
function Multiply {
    <#
    .SYNOPSIS
    Multiplies two numbers.
    
    .EXAMPLE
    Multiply -A 5 -B 3
    #>
    param([int]$A, [int]$B)
    $A * $B
}

Get-Help Multiply -Examples
```

### Exercise 4: Pipeline input
```powershell
function Get-Length {
    param([Parameter(ValueFromPipeline=$true)][string]$Text)
    process {
        $Text.Length
    }
}

"Hello", "PowerShell", "World" | Get-Length
```

### Exercise 5: Return PSCustomObject
```powershell
function New-Report {
    param([string]$ComputerName)
    [PSCustomObject]@{
        Computer = $ComputerName
        Date = Get-Date
        User = $env:USERNAME
    }
}

New-Report -ComputerName "Server01" | Format-List
```

### Exercise 6: Begin/Process/End
```powershell
function Count-Items {
    begin { $count = 0 }
    process { $count++ }
    end { "Total items: $count" }
}

1, 2, 3, 4, 5 | Count-Items
```

### Exercise 7: Error handling
```powershell
function Get-SafeFile {
    param([string]$Path)
    try {
        Get-Content $Path -ErrorAction Stop
    }
    catch {
        Write-Error "Cannot read $Path : $_"
    }
}
```

### Exercise 8: Switch parameter
```powershell
function Show-Info {
    param([switch]$Detailed)
    
    if ($Detailed) {
        Get-ChildItem -Force
    } else {
        Get-ChildItem
    }
}

Show-Info
Show-Info -Detailed
```

## Further Reading

- [Writing Functions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions)
- [Advanced Functions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced)
- [Comment-Based Help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [Parameter Attributes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters)
- [Writing Modules](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules)

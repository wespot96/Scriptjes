# Module 05: Error Handling

## Learning Goals

- Implement try/catch/finally blocks for robust error handling
- Understand terminating vs non-terminating errors
- Control error behavior with ErrorActionPreference
- Use Set-StrictMode to catch common mistakes
- Log and report errors effectively

## Key Concepts

### 1. Try/Catch/Finally Blocks
```powershell
try {
    # Code that might error
    Get-Item -Path "C:\NonExistent.txt" -ErrorAction Stop
}
catch {
    # Handles terminating errors
    Write-Error "File not found: $_"
}
finally {
    # Always runs (cleanup)
    Write-Host "Operation completed"
}

# Multiple catch blocks
try {
    [int]"NotANumber"
}
catch [System.InvalidOperationException] {
    Write-Error "Invalid operation"
}
catch [System.FormatException] {
    Write-Error "Format error"
}
catch {
    Write-Error "Other error: $_"
}
```

### 2. Error Object and Properties
```powershell
try {
    Get-Item "C:\Invalid" -ErrorAction Stop
}
catch {
    $error = $_
    
    # Error object properties
    $error.Exception           # Exception type
    $error.Exception.Message   # Error message
    $error.InvocationInfo      # Where it occurred
    $error.InvocationInfo.ScriptName
    $error.InvocationInfo.Line
    $error.CategoryInfo        # Error category
}

# Access error history
$Error           # Array of all errors
$Error[0]        # Most recent
$Error.Count     # Number of errors
$Error.Clear()   # Clear error log
```

### 3. ErrorActionPreference: Control Error Behavior
```powershell
# -ErrorAction parameter (preferred)
Get-Item -Path "C:\Invalid" -ErrorAction Stop        # Terminate
Get-Item -Path "C:\Invalid" -ErrorAction Continue    # Warn and continue (default)
Get-Item -Path "C:\Invalid" -ErrorAction SilentlyContinue  # Suppress
Get-Item -Path "C:\Invalid" -ErrorAction Inquire      # Prompt user
Get-Item -Path "C:\Invalid" -ErrorAction Ignore       # No error msg

# Set preference for scope
$ErrorActionPreference = "Stop"
$ErrorActionPreference = "SilentlyContinue"

# Using common parameter aliases
Get-Item "C:\Invalid" -ea Stop
Get-Item "C:\Invalid" -ea SilentlyContinue
```

### 4. Terminating vs Non-Terminating Errors
```powershell
# Non-terminating: Error occurs but script continues
Get-Item -Path "C:\Valid", "C:\Invalid", "C:\Valid2"  # Processes all items

# Terminating: Error stops execution
Get-Item -Path "C:\Invalid" -ErrorAction Stop  # Stops here

# Make non-terminating error terminating
Get-Service "InvalidService" -ErrorAction Stop  # Now terminates

# In function, stop on first error
function Get-SafeData {
    $ErrorActionPreference = "Stop"  # Convert to terminating
    $data = Get-Item "C:\config.txt"
    $data | Process-Data  # Won't run if Get-Item fails
}
```

### 5. Set-StrictMode: Enforce Code Quality
```powershell
# Enable strict mode (Version 2.0 recommended)
Set-StrictMode -Version 2.0

# Catches common mistakes:
$undefined  # Error: variable not defined
$x[0]       # Error: accessing non-existent array index
$null | Get-Member  # Error: piping to command that requires input

# Without strict mode, these return $null or silently fail
# Practical use in functions
function Do-Something {
    Set-StrictMode -Version 2.0
    
    # All variables must be initialized
    $result = @()
    $result += Get-Process
}

# Check current mode
$PSVersionTable.PSVersion
```

### 6. Trap Statement (Legacy)
```powershell
# Trap: catches errors in current scope (older approach)
trap {
    Write-Error "Caught error: $_"
    continue  # Resume execution
}

Get-Item "C:\Invalid"  # Error caught by trap
Write-Host "Continuing after error"

# Modern replacement: try/catch/finally
```

### 7. Write-Error and Error Reporting
```powershell
# Write non-terminating error
Write-Error "Something went wrong"
Write-Error "Invalid value: $value" -ErrorAction Stop  # Make terminating

# Error with details
Write-Error -Message "Database unreachable" `
            -ErrorId "DB_Unreachable" `
            -TargetObject $database `
            -Category ConnectionError

# Write-Warning for non-critical issues
Write-Warning "This feature is deprecated"

# Write-Verbose for diagnostic info
Write-Verbose "Attempting connection to $server"
Write-Verbose "Retry attempt 2 of 3"
```

### 8. Custom Error Handling Patterns
```powershell
# Pattern: Validate before operation
function Remove-OldFiles {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "Path does not exist: $Path"  # Terminate function
    }
    
    try {
        Remove-Item -Path "$Path\*.tmp" -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to remove files: $_"
        return $false
    }
    return $true
}

# Pattern: Retry logic
function Invoke-RetryCommand {
    param(
        [scriptblock]$Command,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 1
    )
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            & $Command
            return
        }
        catch {
            if ($i -eq $MaxAttempts) { throw }
            Write-Warning "Attempt $i failed, retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}
```

### 9. Throwing Errors
```powershell
# Throw exception to terminate
if ($count -le 0) {
    throw "Count must be greater than 0"
}

# Throw specific exception
throw [System.InvalidOperationException]"Operation not valid"

# In function with CmdletBinding
function Validate-Input {
    [CmdletBinding()]
    param([int]$Value)
    
    if ($Value -lt 0) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.ArgumentException]"Value cannot be negative",
                "NegativeValue",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Value
            )
        )
    }
}
```

### 10. Logging Errors to File
```powershell
# Append error to log file
function Log-Error {
    param(
        [string]$Message,
        [string]$LogPath = "C:\Logs\error.log"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | ERROR | $Message" | Add-Content -Path $LogPath
}

# Usage in error handler
try {
    Get-Item "C:\Invalid" -ErrorAction Stop
}
catch {
    Log-Error -Message "Failed to get item: $_"
    Write-Error $_
}
```

### 11. ErrorVariable to Capture Errors
```powershell
# Capture error without -ErrorAction Stop
Get-Item -Path "C:\Invalid" -ErrorVariable myError -ErrorAction SilentlyContinue
if ($myError) {
    Write-Host "Error occurred: $($myError.Exception.Message)"
}

# Append to error variable
$allErrors = @()
Get-Item "C:\File1" -ErrorVariable +allErrors -ErrorAction SilentlyContinue
Get-Item "C:\File2" -ErrorVariable +allErrors -ErrorAction SilentlyContinue
```

### 12. Testing Error Conditions
```powershell
# Unit test error handling
function Test-ErrorHandling {
    # Should handle missing file
    $result = & {
        try {
            Get-Content "C:\NonExistent.txt" -ErrorAction Stop
            $false
        }
        catch {
            $true  # Caught error as expected
        }
    }
    $result  # Returns $true
}
```

## Real-World Example: Connection Test with Error Handling

Reference: **ConnectionTest.ps1** and **http_header_removal.ps1**

These scripts demonstrate:
- Try/catch blocks for network operations
- ErrorActionPreference settings
- Proper error reporting
- Retry logic for transient failures

```powershell
function Test-Connection-Robust {
    param(
        [string[]]$ComputerName,
        [int]$MaxRetries = 2
    )
    
    foreach ($computer in $ComputerName) {
        $connected = $false
        
        for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
            try {
                Write-Verbose "Testing $computer (attempt $attempt)"
                Test-Connection -ComputerName $computer -Count 1 -ErrorAction Stop
                $connected = $true
                break
            }
            catch {
                if ($attempt -lt $MaxRetries) {
                    Start-Sleep -Seconds 2
                } else {
                    Write-Error "Connection failed to $computer after $MaxRetries attempts"
                }
            }
        }
        
        [PSCustomObject]@{
            ComputerName = $computer
            Connected = $connected
            Timestamp = Get-Date
        }
    }
}
```

## Quick Reference: Error Handling

| Statement | Purpose | Terminating |
|-----------|---------|-------------|
| `try` | Wrap risky code | - |
| `catch` | Handle terminating errors | - |
| `finally` | Cleanup code | - |
| `throw` | Raise error | Yes |
| `Write-Error` | Report error | No (unless -ErrorAction Stop) |
| `-ErrorAction Stop` | Convert to terminating | Converts |
| `-ErrorAction SilentlyContinue` | Suppress | No |
| `$ErrorActionPreference = "Stop"` | Set scope default | Converts |
| `Set-StrictMode` | Enforce code quality | Converts undefined vars |
| `trap` | Catch errors (legacy) | No |

## Try It: Hands-On Exercises

### Exercise 1: Basic try/catch
```powershell
try {
    $num = [int]"not a number"
}
catch {
    Write-Error "Conversion failed: $_"
}
```

### Exercise 2: Multiple catch blocks
```powershell
try {
    Get-Item -Path (Read-Host "Enter path")
}
catch [System.ItemNotFoundException] {
    Write-Error "Path not found"
}
catch {
    Write-Error "Other error: $_"
}
```

### Exercise 3: -ErrorAction parameter
```powershell
# Try different error actions
Get-Item "C:\Invalid1" -ErrorAction Stop
Get-Item "C:\Invalid2" -ErrorAction SilentlyContinue
Get-Item "C:\Invalid3" -ErrorAction Continue
```

### Exercise 4: Strict mode
```powershell
Set-StrictMode -Version 2.0
$x = 1, 2, 3
$x[10]  # Error: index doesn't exist
```

### Exercise 5: Error logging
```powershell
function Log-Operation {
    param([string]$Operation)
    
    try {
        Write-Output "Performing: $Operation"
        throw "Simulated error"
    }
    catch {
        "$(Get-Date): ERROR - $Operation - $_" | 
            Add-Content "C:\Logs\operation.log"
    }
}

Log-Operation "Database backup"
```

### Exercise 6: Retry logic
```powershell
function Retry-Command {
    param([scriptblock]$Command, [int]$MaxRetries = 3)
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            & $Command
            return
        }
        catch {
            Write-Warning "Attempt $i failed: $_"
            if ($i -eq $MaxRetries) { throw }
        }
    }
}

Retry-Command { Get-Item "C:\file.txt" -ErrorAction Stop }
```

### Exercise 7: Error variable capture
```powershell
$errors = @()
Get-Item "C:\File1" -ErrorVariable +errors -ErrorAction SilentlyContinue
Get-Item "C:\File2" -ErrorVariable +errors -ErrorAction SilentlyContinue

Write-Host "Captured $($errors.Count) errors"
```

### Exercise 8: Testing error handling
```powershell
function Test-SafeRead {
    param([string]$Path)
    
    try {
        Get-Content $Path -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Test-SafeRead "C:\NonExistent"  # Returns $false
```

## Further Reading

- [about_Try_Catch_Finally](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)
- [about_Trap](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_trap)
- [Error Handling](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions)
- [ErrorActionPreference](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables)
- [Set-StrictMode](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode)

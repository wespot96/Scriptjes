# Module 07: Server Administration

## Learning Goals

- Monitor services and processes with Get-Service and Get-Process
- Query system events with Get-WinEvent
- Retrieve hardware and system information with Get-CimInstance
- Access and modify Windows Registry
- Manage scheduled tasks and Windows Features

## Key Concepts

### 1. Get-Service: Monitor Windows Services
```powershell
# List all services
Get-Service

# Filter by status
Get-Service | Where-Object { $_.Status -eq "Running" }
Get-Service -Status Running

# Get specific service
Get-Service -Name "w3svc"
Get-Service -DisplayName "*IIS*"

# Service properties
$service = Get-Service -Name "w3svc"
$service.Name           # Service name
$service.DisplayName    # Display name
$service.Status         # Running, Stopped, Paused
$service.StartType      # Automatic, Manual, Disabled

# Start/Stop service
Start-Service -Name "w3svc"
Stop-Service -Name "w3svc"
Restart-Service -Name "w3svc"

# Set startup type
Set-Service -Name "w3svc" -StartupType Automatic
```

### 2. Get-Process: Monitor Running Processes
```powershell
# List all processes
Get-Process

# Get specific process
Get-Process -Name "notepad"
Get-Process -Name "pow*"

# Process properties
$proc = Get-Process -Name "explorer"
$proc.Name              # Process name
$proc.Id                # Process ID
$proc.Memory            # Memory in bytes
$proc.Threads.Count     # Thread count
$proc.CPU               # CPU time
$proc.WorkingSet        # Working set memory

# Find processes by memory usage
Get-Process | Where-Object { $_.Memory -gt 500MB } | Sort-Object Memory -Descending

# Find processes by CPU usage
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

# Stop process (caution)
Get-Process -Name "notepad" | Stop-Process -Force
```

### 3. Get-WinEvent: Query Windows Events
```powershell
# List available logs
Get-WinEvent -ListLog *

# Get events from log
Get-WinEvent -LogName "System" -MaxEvents 10
Get-WinEvent -LogName "Application" -MaxEvents 10

# Filter by event level
Get-WinEvent -LogName "System" -FilterHashtable @{
    Level = 2  # 1=Critical, 2=Error, 3=Warning, 4=Info
} | Select-Object -First 10

# Complex filtering
Get-WinEvent -LogName "Security" -FilterHashtable @{
    ID = 4624          # Successful logon
    StartTime = (Get-Date).AddDays(-1)
} -MaxEvents 100

# Search by event ID
Get-WinEvent -LogName "System" -FilterHashtable @{
    ID = 1000  # Application Error
}

# Count events by source
Get-WinEvent -LogName "Application" | Group-Object -Property ProviderName | Sort-Object Count -Descending
```

### 4. Get-CimInstance: Query System Information
```powershell
# List available classes
Get-CimClass -ClassName "Win32_*" | Select-Object -First 10

# Computer system info
Get-CimInstance -ClassName "Win32_ComputerSystem" | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory

# Operating system
Get-CimInstance -ClassName "Win32_OperatingSystem" | Select-Object Caption, Version, BuildNumber, InstallDate

# Processor info
Get-CimInstance -ClassName "Win32_Processor" | Select-Object Name, Cores, Threads, MaxClockSpeed

# Disk drives
Get-CimInstance -ClassName "Win32_LogicalDisk" | Select-Object DeviceID, Size, FreeSpace

# Network adapters
Get-CimInstance -ClassName "Win32_NetworkAdapter" | Select-Object Name, MACAddress, Speed

# Query remote computer
Get-CimInstance -ClassName "Win32_ComputerSystem" -ComputerName "Server01"
```

### 5. Registry Access with Get-Item
```powershell
# List registry paths
Get-Item -Path "HKLM:\Software\Microsoft\Windows"

# Get registry value
$value = Get-ItemProperty -Path "HKLM:\Software\Microsoft" -Name "Windows"

# Create registry key
New-Item -Path "HKLM:\Software\MyApp" -Force

# Set registry value
Set-ItemProperty -Path "HKLM:\Software\MyApp" -Name "Setting" -Value "Value"

# Get all values in key
Get-ItemProperty -Path "HKLM:\Software\MyApp"

# Remove registry value
Remove-ItemProperty -Path "HKLM:\Software\MyApp" -Name "Setting"

# Registry paths (common)
# HKLM:\ - HKEY_LOCAL_MACHINE
# HKCU:\ - HKEY_CURRENT_USER
# HKCR:\ - HKEY_CLASSES_ROOT
```

### 6. Windows Features
```powershell
# List all features
Get-WindowsFeature

# List installed features
Get-WindowsFeature | Where-Object { $_.InstallState -eq "Installed" }

# Install feature
Install-WindowsFeature -Name "Web-Server" -IncludeAllSubFeature

# Remove feature
Uninstall-WindowsFeature -Name "Web-Server"

# Check if role installed
(Get-WindowsFeature -Name "AD-Domain-Services").InstallState

# Note: Requires Windows Server OS
```

### 7. Scheduled Tasks
```powershell
# List all scheduled tasks
Get-ScheduledTask

# Get specific task
Get-ScheduledTask -TaskName "Backup"

# Task details
$task = Get-ScheduledTask -TaskName "Backup"
$task.Triggers      # When it runs
$task.Actions       # What it does
$task.Settings      # Settings

# Get task status
Get-ScheduledTaskInfo -TaskName "Backup"

# Disable task
Disable-ScheduledTask -TaskName "Backup"

# Enable task
Enable-ScheduledTask -TaskName "Backup"

# Run task immediately
Start-ScheduledTask -TaskName "Backup"

# Create new task
$trigger = New-ScheduledTaskTrigger -At 2:00AM -Daily
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -File C:\Scripts\Backup.ps1"
Register-ScheduledTask -TaskName "DailyBackup" -Trigger $trigger -Action $action -RunLevel Highest
```

### 8. System Performance Monitoring
```powershell
# CPU usage
Get-WmiObject -Class Win32_Processor | Select-Object Name, LoadPercentage

# Memory usage
$os = Get-WmiObject -Class Win32_OperatingSystem
[PSCustomObject]@{
    Total = [Math]::Round($os.TotalVisibleMemorySize / 1MB)
    Free = [Math]::Round($os.FreePhysicalMemory / 1MB)
    UsedPercent = [Math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100)
}

# Disk usage
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID,
    @{ Name = 'Total(GB)'; Expression = { [Math]::Round($_.Size / 1GB) } },
    @{ Name = 'Free(GB)'; Expression = { [Math]::Round($_.FreeSpace / 1GB) } }

# Network statistics
Get-NetAdapterStatistics | Select-Object Name, ReceivedBytes, SentBytes
```

### 9. User Accounts
```powershell
# List local users
Get-LocalUser

# Get specific user
Get-LocalUser -Name "Administrator"

# User properties
$user = Get-LocalUser -Name "Administrator"
$user.Name
$user.Enabled
$user.LastLogon

# Create user
New-LocalUser -Name "NewUser" -Password (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force)

# Add user to group
Add-LocalGroupMember -Group "Administrators" -Member "NewUser"

# List group members
Get-LocalGroupMember -Group "Administrators"
```

### 10. Power Management
```powershell
# Restart computer
Restart-Computer -ComputerName "Server01" -Force

# Shutdown
Stop-Computer -ComputerName "Server01" -Force

# Sleep mode
rundll32.exe powrprof.dll,SetSuspendState 0,1,0

# Hibernate
rundll32.exe powrprof.dll,SetSuspendState 1,1,0

# Get power settings
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
```

### 11. Event Log Management
```powershell
# Get log size and stats
Get-EventLog -List

# Oldest entries
Get-EventLog -LogName "System" -Newest 10

# Clear log
Clear-EventLog -LogName "Application"

# Export events
Get-WinEvent -LogName "System" -MaxEvents 1000 | Export-Clixml "C:\events.xml"
```

### 12. System Configuration
```powershell
# Computer name and domain
$comp = Get-WmiObject -Class Win32_ComputerSystem
$comp.Name
$comp.Domain

# Uptime
$uptime = Get-WmiObject -Class Win32_OperatingSystem
[Math]::Round(([DateTime]::Now - ([Management.ManagementDateTimeConverter]::ToDateTime($uptime.LastBootUpTime))).TotalDays)

# System locale
Get-WmiObject -Class Win32_OperatingSystem | Select-Object Locale, TimeZone
```

## Real-World Example: Server Health Dashboard

Reference: **ServerHealthDashboard.ps1**

This script demonstrates:
- Multiple Get-Service and Get-WinEvent queries
- System performance aggregation
- Real-time monitoring capabilities
- Formatted output for dashboard display

```powershell
function Get-ServerHealthReport {
    param([string]$ComputerName = $env:COMPUTERNAME)
    
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
    $proc = Get-CimInstance -ClassName Win32_Processor -ComputerName $ComputerName
    
    $serviceCount = (Get-Service -ComputerName $ComputerName | Where-Object { $_.Status -eq "Running" }).Count
    
    [PSCustomObject]@{
        ComputerName = $ComputerName
        OS = $os.Caption
        UpTime = [Math]::Round((New-TimeSpan -Start ([Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)) -End (Get-Date)).TotalDays)
        Memory_GB = [Math]::Round($os.TotalVisibleMemorySize / 1MB)
        Cores = $proc.NumberOfCores
        RunningServices = $serviceCount
    }
}

Get-ServerHealthReport "Server01"
```

## Quick Reference: Admin Cmdlets

| Task | Cmdlet |
|------|--------|
| List services | `Get-Service` |
| Start service | `Start-Service` |
| Stop service | `Stop-Service` |
| Get processes | `Get-Process` |
| Stop process | `Stop-Process` |
| Query events | `Get-WinEvent` |
| Get system info | `Get-CimInstance` |
| List features | `Get-WindowsFeature` |
| Get tasks | `Get-ScheduledTask` |
| Create task | `Register-ScheduledTask` |
| Access registry | `Get-ItemProperty` |
| Set registry | `Set-ItemProperty` |

## Try It: Hands-On Exercises

### Exercise 1: Services report
```powershell
Get-Service | Group-Object -Property Status | Select-Object Name, Count
```

### Exercise 2: High-memory processes
```powershell
Get-Process | Sort-Object Memory -Descending | Select-Object -First 10 Name, Memory
```

### Exercise 3: System information
```powershell
$os = Get-CimInstance Win32_OperatingSystem
"OS: $($os.Caption)`nVersion: $($os.Version)"
```

### Exercise 4: Recent errors
```powershell
Get-WinEvent -LogName System -FilterHashtable @{ Level = 2 } -MaxEvents 10
```

### Exercise 5: Disk space
```powershell
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,
    @{ Name = 'Free(GB)'; Expression = { [Math]::Round($_.FreeSpace / 1GB) } }
```

### Exercise 6: Scheduled tasks list
```powershell
Get-ScheduledTask | Select-Object TaskName, State | Sort-Object TaskName
```

### Exercise 7: User accounts
```powershell
Get-LocalUser | Select-Object Name, Enabled, LastLogon
```

### Exercise 8: Registry query
```powershell
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion"
```

## Further Reading

- [Get-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service)
- [Get-Process](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-process)
- [Get-WinEvent](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent)
- [Get-CimInstance](https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance)
- [Windows Server Administration](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands)

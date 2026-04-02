# Module 12: Automation and Reporting

## Learning Goals

- Schedule PowerShell scripts with Windows Task Scheduler
- Generate HTML reports with ConvertTo-Html
- Log script execution with Start-Transcript
- Implement -WhatIf and -Confirm for safe operations
- Create production-ready deployment and monitoring workflows

## Key Concepts

### 1. Scheduled Tasks with Register-ScheduledTask
```powershell
# Create trigger (daily at 2 AM)
$trigger = New-ScheduledTaskTrigger -At 2:00AM -Daily

# Create action (run PowerShell script)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -NonInteractive -File C:\Scripts\Backup.ps1"

# Register task
Register-ScheduledTask -TaskName "DailyBackup" `
    -Trigger $trigger `
    -Action $action `
    -RunLevel Highest `
    -Description "Daily backup of critical data"

# List scheduled tasks
Get-ScheduledTask -TaskName "DailyBackup"

# Run task immediately
Start-ScheduledTask -TaskName "DailyBackup"

# Disable task
Disable-ScheduledTask -TaskName "DailyBackup"

# Remove task
Unregister-ScheduledTask -TaskName "DailyBackup" -Confirm:$false
```

### 2. ConvertTo-Html: Generate Reports
```powershell
# Simple HTML table
$data = @(
    @{ ComputerName = "Server01"; Memory = 8; Cores = 4 },
    @{ ComputerName = "Server02"; Memory = 16; Cores = 8 }
)
$data | ConvertTo-Html | Out-File "report.html"

# With CSS styling
$css = @"
<style>
    body { font-family: Arial; }
    table { border-collapse: collapse; }
    th, td { border: 1px solid black; padding: 8px; }
    th { background-color: #4CAF50; color: white; }
</style>
"@

$data | ConvertTo-Html -Head $css -Title "Server Report" | Out-File "report.html"

# With properties specified
Get-Service | Select-Object Name, Status, StartType | 
    ConvertTo-Html -Title "Windows Services" | Out-File "services.html"

# Fragment (no HTML wrapper)
$table = Get-Process | ConvertTo-Html -Fragment
```

### 3. Custom HTML Report Generation
```powershell
# Advanced report with headers and summaries
function New-SystemReport {
    param([string]$ComputerName = $env:COMPUTERNAME)
    
    $os = Get-WmiObject -ComputerName $ComputerName -Class Win32_OperatingSystem
    $proc = Get-WmiObject -ComputerName $ComputerName -Class Win32_Processor
    $disk = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk
    
    $html = @"
    <html>
    <head>
        <title>System Report - $ComputerName</title>
        <style>
            body { font-family: Arial; background-color: #f5f5f5; }
            h1 { color: #333; }
            table { border-collapse: collapse; width: 100%; background-color: white; }
            th { background-color: #4CAF50; color: white; padding: 10px; }
            td { border: 1px solid #ddd; padding: 8px; }
        </style>
    </head>
    <body>
        <h1>System Report: $ComputerName</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        
        <h2>System Information</h2>
        <table>
            <tr><td>OS</td><td>$($os.Caption)</td></tr>
            <tr><td>CPU Cores</td><td>$($proc.NumberOfCores)</td></tr>
            <tr><td>Memory</td><td>$([Math]::Round($os.TotalVisibleMemorySize / 1MB)) GB</td></tr>
        </table>
        
        <h2>Disk Usage</h2>
        $($disk | ConvertTo-Html -Fragment)
    </body>
    </html>
"@
    
    return $html
}

New-SystemReport | Out-File "system-report.html"
```

### 4. Start-Transcript: Session Logging
```powershell
# Start logging all output
Start-Transcript -Path "C:\Logs\script.log"

# Do work
Get-Service
Get-Process

# Stop logging
Stop-Transcript

# Log with timestamp
$logPath = "C:\Logs\$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $logPath

# Append to existing log
Start-Transcript -Path "C:\Logs\script.log" -Append

# Output format in transcript
# ==================================================
# Windows PowerShell Transcript Start
# Start time: 20240115T143022.3426154Z
# Username: DOMAIN\User
# RunAs User: DOMAIN\User
# Machine: SERVER01 (Windows Server 2022)
# ==================================================
```

### 5. Logging Function with Error Handling
```powershell
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')][string]$Level = 'Info',
        [string]$LogPath = "C:\Logs\app.log"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    Add-Content -Path $LogPath -Value $logEntry
    
    switch ($Level) {
        'Info'    { Write-Host $logEntry -ForegroundColor Green }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        'Error'   { Write-Host $logEntry -ForegroundColor Red }
    }
}

# Usage
Write-Log "Script started" -Level Info
Write-Log "Database backup completed" -Level Info
Write-Log "Retry attempt 2" -Level Warning
Write-Log "Connection failed" -Level Error
```

### 6. SupportsShouldProcess: WhatIf and Confirm
```powershell
function Remove-OldFiles {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$Path,
        [int]$DaysOld = 30
    )
    
    $files = Get-ChildItem -Path $Path |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld) }
    
    foreach ($file in $files) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove")) {
            Remove-Item -Path $file.FullName
            Write-Host "Deleted: $($file.Name)"
        }
    }
}

# Usage
Remove-OldFiles -Path "C:\Temp" -DaysOld 30 -WhatIf  # Preview changes
Remove-OldFiles -Path "C:\Temp" -DaysOld 30 -Confirm # Ask for confirmation
Remove-OldFiles -Path "C:\Temp" -DaysOld 30          # Execute immediately
```

### 7. Email Notifications
```powershell
# Send report email
function Send-Report {
    param(
        [string]$To = "admin@company.com",
        [string]$Subject = "Daily Report",
        [string]$Body = "See attached report",
        [string]$Attachment
    )
    
    # Using SMTP (requires SMTP server)
    $SMTPClient = New-Object System.Net.Mail.SmtpClient("smtp.company.com")
    $SMTPClient.Port = 587
    $SMTPClient.EnableSsl = $true
    
    $MailMessage = New-Object System.Net.Mail.MailMessage
    $MailMessage.From = "automation@company.com"
    $MailMessage.To.Add($To)
    $MailMessage.Subject = $Subject
    $MailMessage.Body = $Body
    $MailMessage.IsBodyHtml = $true
    
    if ($Attachment) {
        $MailMessage.Attachments.Add($Attachment)
    }
    
    try {
        $SMTPClient.Send($MailMessage)
        Write-Host "Email sent to $To"
    }
    catch {
        Write-Error "Failed to send email: $_"
    }
    finally {
        $MailMessage.Dispose()
        $SMTPClient.Dispose()
    }
}

# Usage
Send-Report -To "ops@company.com" -Subject "Daily Backup Report" `
    -Body "Backup completed successfully" -Attachment "C:\Reports\backup.html"
```

### 8. Error Handling in Automation
```powershell
# Robust automation wrapper
function Invoke-AutomationScript {
    param([string]$ScriptPath)
    
    $logFile = "C:\Logs\automation-$(Get-Date -Format 'yyyyMMdd').log"
    
    try {
        Start-Transcript -Path $logFile -Append
        
        Write-Log "Starting script: $ScriptPath"
        & $ScriptPath
        Write-Log "Script completed successfully"
    }
    catch {
        Write-Log "Script failed: $_" -Level Error
        Send-Report -Subject "Automation Script Failed" `
            -Body "Script: $ScriptPath`nError: $_"
        exit 1
    }
    finally {
        Stop-Transcript
    }
}
```

### 9. Production Checklist
```powershell
# Pre-deployment checklist
function Test-ProductionReadiness {
    param([string]$ScriptPath)
    
    $checks = @{
        "Error handling" = $false
        "Logging enabled" = $false
        "Help documentation" = $false
        "Parameter validation" = $false
        "Transcript enabled" = $false
    }
    
    $content = Get-Content -Path $ScriptPath
    
    if ($content -match "try\s*\{") { $checks["Error handling"] = $true }
    if ($content -match "Write-Log|Add-Content.*Log") { $checks["Logging enabled"] = $true }
    if ($content -match "\.SYNOPSIS|\.DESCRIPTION") { $checks["Help documentation"] = $true }
    if ($content -match "ValidateRange|ValidateSet|ValidatePattern") { $checks["Parameter validation"] = $true }
    if ($content -match "Start-Transcript") { $checks["Transcript enabled"] = $true }
    
    $passed = ($checks.Values | Where-Object { $_ -eq $true }).Count
    $total = $checks.Keys.Count
    
    Write-Host "Production Readiness: $passed/$total"
    $checks
}

Test-ProductionReadiness "C:\Scripts\Backup.ps1"
```

### 10. Monitoring and Health Checks
```powershell
# Server health monitoring script
function Get-ServerHealthStatus {
    param([string[]]$ComputerName)
    
    $report = @()
    
    foreach ($computer in $ComputerName) {
        try {
            $os = Get-WmiObject -ComputerName $computer -Class Win32_OperatingSystem
            $disk = Get-WmiObject -ComputerName $computer -Class Win32_LogicalDisk |
                Where-Object { $_.DeviceID -eq "C:" }
            
            $memPercent = [Math]::Round(100 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize * 100))
            $diskPercent = [Math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100)
            
            $status = "OK"
            if ($memPercent -gt 90) { $status = "WARNING" }
            if ($diskPercent -gt 95) { $status = "CRITICAL" }
            
            $report += [PSCustomObject]@{
                Computer = $computer
                MemUsage = "$memPercent%"
                DiskUsage = "$diskPercent%"
                Status = $status
                Timestamp = Get-Date
            }
        }
        catch {
            Write-Error "Failed to query $computer : $_"
        }
    }
    
    return $report
}
```

### 11. Configuration File for Automation
```powershell
# JSON configuration file: C:\Scripts\config.json
@"
{
    "logPath": "C:\Logs",
    "reportPath": "C:\Reports",
    "smtpServer": "smtp.company.com",
    "emailTo": "ops@company.com",
    "emailFrom": "automation@company.com",
    "retentionDays": 30,
    "servers": ["Server01", "Server02", "Server03"]
}
"@ | Out-File "C:\Scripts\config.json"

# Load config in script
$config = Get-Content -Path "C:\Scripts\config.json" | ConvertFrom-Json
$servers = $config.servers
$logPath = $config.logPath
```

### 12. Deployment Best Practices
```powershell
# Production deployment template
function Deploy-Automation {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$ScriptName,
        [string]$Schedule = "2:00 AM"
    )
    
    $scriptPath = "C:\Scripts\$ScriptName.ps1"
    $logPath = "C:\Logs\$ScriptName.log"
    
    if (-not (Test-Path $scriptPath)) {
        throw "Script not found: $scriptPath"
    }
    
    # Test script before deployment
    Write-Host "Testing script..."
    & powershell.exe -File $scriptPath -ErrorAction Stop | Out-Null
    
    # Create scheduled task
    if ($PSCmdlet.ShouldProcess($ScriptName, "Deploy")) {
        $trigger = New-ScheduledTaskTrigger -At $Schedule -Daily
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
            -Argument "-NoProfile -File $scriptPath"
        
        Register-ScheduledTask -TaskName $ScriptName `
            -Trigger $trigger `
            -Action $action `
            -RunLevel Highest `
            -Description "Automated: $ScriptName"
        
        Write-Host "Deployment successful: $ScriptName"
    }
}

Deploy-Automation -ScriptName "DailyBackup" -Schedule "2:00 AM" -WhatIf
```

## Real-World Example: Daily Health Report

Reference: **ServerHealthDashboard.ps1**

```powershell
# Complete daily monitoring and reporting script
$servers = @("Server01", "Server02", "Server03")
$logPath = "C:\Logs\daily-health.log"
$reportPath = "C:\Reports\health-$(Get-Date -Format 'yyyyMMdd').html"

Start-Transcript -Path $logPath

try {
    $report = @()
    
    foreach ($server in $servers) {
        $status = Get-ServerHealthStatus $server
        $report += $status
    }
    
    # Generate HTML
    $html = $report | ConvertTo-Html -Title "Daily Health Report" -As Table
    $html | Out-File $reportPath
    
    # Email report
    Send-Report -Subject "Daily Health Report" `
        -Body "See attached daily server health report" `
        -Attachment $reportPath
    
    Write-Host "Report completed: $reportPath"
}
catch {
    Write-Error "Report generation failed: $_"
}
finally {
    Stop-Transcript
}
```

## Quick Reference: Automation Cmdlets

| Task | Cmdlet |
|------|--------|
| Schedule task | `Register-ScheduledTask` |
| Start task | `Start-ScheduledTask` |
| List tasks | `Get-ScheduledTask` |
| Generate HTML | `ConvertTo-Html` |
| Start logging | `Start-Transcript` |
| Stop logging | `Stop-Transcript` |
| Send mail | `Send-MailMessage` |
| Config from JSON | `ConvertFrom-Json` |
| ShouldProcess | `[CmdletBinding(SupportsShouldProcess=$true)]` |

## Try It: Hands-On Exercises

### Exercise 1: Create scheduled task
```powershell
$trigger = New-ScheduledTaskTrigger -At 3:00AM -Daily
$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-File C:\Scripts\Test.ps1"
Register-ScheduledTask -TaskName "TestTask" -Trigger $trigger -Action $action -WhatIf
```

### Exercise 2: Generate HTML report
```powershell
Get-Service | ConvertTo-Html -Title "Services Report" | Out-File "report.html"
```

### Exercise 3: Log script execution
```powershell
Start-Transcript -Path "C:\Logs\test.log"
Write-Host "This is logged"
Stop-Transcript
```

### Exercise 4: WhatIf implementation
```powershell
function Test-ShouldProcess {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string]$Name)
    
    if ($PSCmdlet.ShouldProcess($Name, "Delete")) {
        Write-Host "Deleted $Name"
    }
}

Test-ShouldProcess "item" -WhatIf
```

### Exercise 5: Load JSON configuration
```powershell
@{ servers = "Server01", "Server02"; action = "backup" } | ConvertTo-Json | Set-Content config.json
$config = Get-Content config.json | ConvertFrom-Json
```

### Exercise 6: Email notification
```powershell
$report = "Backup completed at $(Get-Date)"
Send-MailMessage -To "admin@company.com" -From "script@company.com" `
    -Subject "Backup Report" -Body $report -SmtpServer "smtp.company.com"
```

### Exercise 7: Production readiness check
```powershell
Get-Content "C:\Scripts\script.ps1" | Select-String "try|catch|error" | Measure-Object
```

### Exercise 8: Monitor system health
```powershell
$cpu = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty LoadPercentage
$mem = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty FreePhysicalMemory
Write-Host "CPU: $cpu%, Memory Free: $([Math]::Round($mem/1MB)) MB"
```

## Further Reading

- [Register-ScheduledTask](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask)
- [ConvertTo-Html](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-html)
- [Start-Transcript](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.host/start-transcript)
- [SupportsShouldProcess](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute)
- [PowerShell Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction)

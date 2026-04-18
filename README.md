# PowerShell Scripts

Random collection of PowerShell scripts.

## Schedule a Script as a Task

Use the example below to register a weekly scheduled task that runs as `SYSTEM`.

```powershell
$scriptPath = "C:\Path\To\script.ps1"
$taskName = "Weekly script (SYSTEM)"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File \"$scriptPath\""

$trigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Sunday `
    -At 11:00PM

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Task description"
```

## Log System Usage Every 10 Minutes

Place the script at `D:\Logs\LogSystem-usage.ps1`. It will append snapshots to `D:\Logs\SystemUsageLog.txt` each time it runs.

Run PowerShell as Administrator on the Windows Server and register the task like this:

```powershell
$scriptPath = "D:\Logs\LogSystem-usage.ps1"
$taskName = "Log system usage every 10 minutes"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 10) `
    -RepetitionDuration ([TimeSpan]::MaxValue)

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Appends CPU and RAM usage snapshots to D:\Logs\SystemUsageLog.txt"
```

Notes:

- Creating a scheduled task that runs as `SYSTEM` with highest privileges requires local administrator rights.
- Writing to `D:\Logs` may also require elevated permissions depending on the server configuration.
- Test the script once manually before scheduling it.

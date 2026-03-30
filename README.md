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
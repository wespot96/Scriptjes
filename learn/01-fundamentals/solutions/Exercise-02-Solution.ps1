<#
.SYNOPSIS
    Solution for Exercise 02 - System Info One-Liners

.DESCRIPTION
    Complete, working one-liner solutions for every section in Exercise-02.ps1.
    Each answer is a single pipeline with comments explaining the approach.

    Target: Windows Server 2022, PowerShell 5.1 (no external modules required)

.NOTES
    Module : 01-fundamentals
    Theme  : System Info One-Liners (Solution)
#>

# ============================================================================
# SECTION 1: Top Processes by Memory
# ============================================================================

# 1a. Top 5 processes by working-set memory.
#     WorkingSet64 is in bytes, so dividing by 1MB converts to megabytes.
#     [Math]::Round() gives a clean decimal display.
Get-Process |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 5 Name, Id, @{
        Name       = 'MemoryMB'
        Expression = { [Math]::Round($_.WorkingSet64 / 1MB, 2) }
    }

# 1b. Same query, formatted as an auto-sized table.
#     Format-Table -AutoSize adjusts column widths to fit the data,
#     making console output easier to read.
Get-Process |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 5 Name, Id, @{
        Name       = 'MemoryMB'
        Expression = { [Math]::Round($_.WorkingSet64 / 1MB, 2) }
    } |
    Format-Table -AutoSize


# ============================================================================
# SECTION 2: Service Status Summary
# ============================================================================

# 2a. Count of running services.
#     Wrapping in (...).Count is the most direct way to get a plain number.
(Get-Service | Where-Object { $_.Status -eq 'Running' }).Count

# 2b. Count of stopped services — same pattern, different filter value.
(Get-Service | Where-Object { $_.Status -eq 'Stopped' }).Count

# 2c. Grouped summary by status.
#     Group-Object collects objects into buckets by a property value.
#     The output shows Count and Name (the status label) per group.
Get-Service | Group-Object -Property Status


# ============================================================================
# SECTION 3: OS Version and Uptime
# ============================================================================

# 3a. OS caption and version.
#     Win32_OperatingSystem is a WMI class available on all Windows systems.
#     Caption gives the friendly name ("Microsoft Windows Server 2022 ...").
Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version

# 3b. System uptime from LastBootUpTime.
#     WMI stores dates in a CIM datetime string; the ManagementDateTimeConverter
#     utility class converts it to a .NET DateTime.
#     Subtracting two DateTimes yields a TimeSpan with Days, Hours, Minutes.
$os       = Get-WmiObject Win32_OperatingSystem
$bootTime = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
$uptime   = (Get-Date) - $bootTime
"Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"


# ============================================================================
# SECTION 4: Select-Object with Calculated Properties
# ============================================================================

# 4a. Running services with a NameLength calculated property.
#     Calculated properties use a hashtable with Name and Expression keys.
#     The Expression scriptblock runs for each object in the pipeline.
Get-Service |
    Where-Object { $_.Status -eq 'Running' } |
    Select-Object Name, DisplayName, @{
        Name       = 'NameLength'
        Expression = { $_.Name.Length }
    } |
    Sort-Object NameLength -Descending |
    Select-Object -First 10

# 4b. Logical disk space report.
#     DriveType 3 = local fixed disk (filters out CD-ROMs, network drives).
#     Dividing by 1GB and rounding produces human-friendly numbers.
Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{ Name = 'SizeGB';  Expression = { [Math]::Round($_.Size / 1GB, 2) } },
        @{ Name = 'FreeGB';  Expression = { [Math]::Round($_.FreeSpace / 1GB, 2) } }

# 4c. 5 newest files in C:\Windows\Logs.
#     -File limits to files (not directories).
#     -ErrorAction SilentlyContinue skips access-denied subfolders gracefully.
#     Length is in bytes; dividing by 1KB is more readable for log files.
Get-ChildItem -Path C:\Windows\Logs -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 Name,
        @{ Name = 'SizeKB'; Expression = { [Math]::Round($_.Length / 1KB, 1) } },
        LastWriteTime


# ============================================================================
# SECTION 5: Bonus One-Liner Challenges
# ============================================================================

# 5a. Environment variables whose value contains "Windows".
#     Env: is a PSDrive that exposes environment variables as objects with
#     Name and Value properties — perfect for pipeline filtering.
Get-ChildItem Env: | Where-Object { $_.Value -like '*Windows*' } | Select-Object Name, Value

# 5b. 5 most recent System event log entries with truncated message.
#     [Math]::Min prevents Substring from throwing when the message is
#     shorter than 80 characters.
Get-EventLog -LogName System -Newest 5 |
    Select-Object TimeGenerated, EntryType, Source, @{
        Name       = 'Message'
        Expression = { $_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)) }
    }


Write-Host "`nExercise 02 Solution complete!" -ForegroundColor Green

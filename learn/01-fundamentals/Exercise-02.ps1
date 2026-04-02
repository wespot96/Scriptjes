<#
.SYNOPSIS
    Exercise 02 - System Info One-Liners

.DESCRIPTION
    Build practical one-liner pipelines that retrieve system information.
    Each task should be completed in a single pipeline statement.

    Target: Windows Server 2022, PowerShell 5.1 (no external modules required)

.NOTES
    Module : 01-fundamentals
    Theme  : System Info One-Liners
    Instructions:
      - Replace every "# TODO: Your code here" with a single pipeline.
      - Each answer should be ONE statement (semicolons are not allowed —
        chain with the pipe operator instead).
      - Run the script section-by-section or execute the whole file.
#>

# ============================================================================
# SECTION 1: Top Processes by Memory
# ============================================================================

# 1a. Get the top 5 processes consuming the most working-set memory.
#     Display: Name, Id, and WorkingSet64 (in MB, rounded to 2 decimals).
#     Hint: Sort-Object -Descending, Select-Object -First 5, and a
#     calculated property @{ Name='MemoryMB'; Expression={...} }.
# TODO: Your code here


# 1b. Same as above but format the output as a table with auto-sized columns.
#     Hint: pipe to Format-Table -AutoSize.
# TODO: Your code here


# ============================================================================
# SECTION 2: Service Status Summary
# ============================================================================

# 2a. Count how many services are currently in the "Running" state.
#     Output just the number (use Measure-Object and .Count or
#     Select-Object -ExpandProperty Count).
# TODO: Your code here


# 2b. Count how many services are currently "Stopped".
# TODO: Your code here


# 2c. Produce a grouped summary showing the count per status.
#     Hint: Get-Service | Group-Object -Property Status
#     The output should show each status and how many services are in it.
# TODO: Your code here


# ============================================================================
# SECTION 3: OS Version and Uptime
# ============================================================================

# 3a. Retrieve the operating system caption (name) and version number.
#     Use Get-WmiObject Win32_OperatingSystem and select Caption and Version.
# TODO: Your code here


# 3b. Calculate system uptime.
#     Get the LastBootUpTime from Win32_OperatingSystem, convert it with
#     [Management.ManagementDateTimeConverter]::ToDateTime(), and subtract
#     from the current date.
#     Display the result showing Days, Hours, and Minutes.
#     Hint: (Get-Date) - $bootTime gives a TimeSpan object.
# TODO: Your code here


# ============================================================================
# SECTION 4: Select-Object with Calculated Properties
# ============================================================================
# Calculated properties let you reshape pipeline output on the fly using
# @{ Name = 'Label'; Expression = { <scriptblock> } }.

# 4a. List all running services, but add a calculated property called
#     "NameLength" that contains the character count of the service name.
#     Display: Name, DisplayName, NameLength.
#     Sort by NameLength descending and show the top 10.
# TODO: Your code here


# 4b. Get logical disk information from Win32_LogicalDisk (DriveType 3 = local).
#     Display: DeviceID, a calculated "SizeGB" (Size / 1GB rounded to 2),
#     and a calculated "FreeGB" (FreeSpace / 1GB rounded to 2).
# TODO: Your code here


# 4c. Get the 5 newest files in C:\Windows\Logs (or another directory).
#     Display: Name, a calculated "SizeKB" (Length / 1KB rounded to 1),
#     and LastWriteTime.
#     Hint: Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue,
#           Sort-Object LastWriteTime -Descending, Select-Object -First 5.
# TODO: Your code here


# ============================================================================
# SECTION 5: Bonus One-Liner Challenges
# ============================================================================

# 5a. Find all environment variables whose value contains the word "Windows".
#     Display the Name and Value.
#     Hint: Get-ChildItem Env: | Where-Object ...
# TODO: Your code here


# 5b. Get the 5 most recent entries from the System event log
#     (use Get-EventLog -LogName System -Newest 5) and display:
#     TimeGenerated, EntryType, Source, and a truncated Message (first 80 chars).
#     Use a calculated property to truncate: $_.Message.Substring(0, [Math]::Min(80, $_.Message.Length))
# TODO: Your code here


Write-Host "`nExercise 02 complete — review your one-liner output above!" -ForegroundColor Green

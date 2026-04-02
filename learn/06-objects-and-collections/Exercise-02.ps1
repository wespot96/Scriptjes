<#
.SYNOPSIS
    Module 06 Exercise 02: Process Analytics Dashboard
.DESCRIPTION
    Practice collecting live process data, creating calculated properties,
    grouping by memory usage tiers, converting to JSON, and building a
    summary hashtable with statistics.

    Each section includes a comment mapping the PowerShell pipeline
    operation to its LINQ / SQL equivalent for developers coming from
    those backgrounds.

    Complete each TODO section below. Run the script when finished to
    verify your work produces the expected output.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.EXAMPLE
    .\Exercise-02.ps1
.NOTES
    Module  : 06 - Objects and Collections
    Exercise: 02 - Process Analytics Dashboard
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================================================================
# STEP 1 — Collect process data snapshot
# =========================================================================
# PowerShell : Get-Process
# LINQ       : dbContext.Processes.ToList()
# SQL        : SELECT * FROM sys.dm_exec_requests
#
# TODO: Capture all running processes into $processes using Get-Process.

Write-Host '=== Process Analytics Dashboard ===' -ForegroundColor Cyan
Write-Host "Snapshot taken: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"



# =========================================================================
# STEP 2 — Create calculated properties (Select-Object)
# =========================================================================
# PowerShell : Select-Object with @{Name=...; Expression=...}
# LINQ       : .Select(p => new { p.Name, MemoryMB = p.WS / 1MB, ... })
# SQL        : SELECT Name, WorkingSet64/1048576 AS MemoryMB FROM ...
#
# TODO: Pipe $processes through Select-Object to create $enriched.
#       Include these properties:
#         - Name          (original)
#         - Id            (original)
#         - MemoryMB      (calculated: WorkingSet64 / 1MB, rounded to 2 decimals)
#         - HandleCount   (original: Handles)
#         - MemoryTier    (calculated: see rules below)
#
#       MemoryTier rules based on WorkingSet64 / 1MB:
#         >= 500  → 'High'
#         >= 100  → 'Medium'
#         >= 10   → 'Low'
#         <  10   → 'Minimal'
#
# Hint for MemoryTier calculated property:
#   @{
#       Name = 'MemoryTier'
#       Expression = {
#           $mb = $_.WorkingSet64 / 1MB
#           if     ($mb -ge 500) { 'High' }
#           elseif ($mb -ge 100) { 'Medium' }
#           elseif ($mb -ge 10)  { 'Low' }
#           else                 { 'Minimal' }
#       }
#   }

Write-Host '--- Enriched Process Data (Top 10 by Memory) ---' -ForegroundColor Yellow



# =========================================================================
# STEP 3 — Filter: Exclude minimal-memory processes (Where-Object)
# =========================================================================
# PowerShell : Where-Object { $_.MemoryTier -ne 'Minimal' }
# LINQ       : .Where(p => p.MemoryTier != "Minimal")
# SQL        : WHERE MemoryTier <> 'Minimal'
#
# TODO: Filter $enriched to keep only processes where MemoryTier is NOT
#       'Minimal'. Store in $significant.

Write-Host "`n--- Significant Processes (excluding Minimal) ---" -ForegroundColor Yellow



# =========================================================================
# STEP 4 — Sort: Top 10 memory consumers (Sort-Object)
# =========================================================================
# PowerShell : Sort-Object MemoryMB -Descending | Select-Object -First 10
# LINQ       : .OrderByDescending(p => p.MemoryMB).Take(10)
# SQL        : SELECT TOP 10 ... ORDER BY MemoryMB DESC
#
# TODO: Sort $significant by MemoryMB descending, take the first 10.
#       Store in $top10. Display with Format-Table -AutoSize.

Write-Host "`n--- Top 10 Memory Consumers ---" -ForegroundColor Green



# =========================================================================
# STEP 5 — Group: Processes by MemoryTier (Group-Object)
# =========================================================================
# PowerShell : Group-Object -Property MemoryTier
# LINQ       : .GroupBy(p => p.MemoryTier)
# SQL        : SELECT MemoryTier, COUNT(*) FROM ... GROUP BY MemoryTier
#
# TODO: Group $enriched by MemoryTier. Store in $tierGroups.
#       Display a summary table showing the tier name, count, and total
#       memory (MB) for each tier.
#
# Hint: Loop through $tierGroups and for each group:
#   $group.Name  — the tier label
#   $group.Count — number of processes
#   ($group.Group | Measure-Object -Property MemoryMB -Sum).Sum — total MB

Write-Host "`n--- Memory Tier Distribution ---" -ForegroundColor Magenta



# =========================================================================
# STEP 6 — Convert top consumers to JSON (ConvertTo-Json)
# =========================================================================
# PowerShell : ConvertTo-Json -Depth 2
# LINQ       : JsonConvert.SerializeObject(top10)
# SQL        : FOR JSON PATH
#
# TODO: Convert $top10 to a JSON string. Store in $jsonOutput.
#       Display the JSON string to the console.

Write-Host "`n--- Top 10 as JSON ---" -ForegroundColor Yellow



# =========================================================================
# STEP 7 — Build a summary hashtable (Measure-Object)
# =========================================================================
# PowerShell : Measure-Object -Property MemoryMB -Sum -Average -Maximum -Minimum
# LINQ       : new { Sum = list.Sum(p=>p.Mem), Avg = list.Average(p=>p.Mem), ... }
# SQL        : SELECT SUM(MemoryMB), AVG(MemoryMB), MAX(MemoryMB), MIN(MemoryMB) ...
#
# TODO: Create an [ordered] hashtable named $summary with these keys:
#
#   SnapshotTime     — current date/time as string (Get-Date -Format 'o')
#   TotalProcesses   — total count of all processes
#   SignificantCount  — count of processes in $significant
#   MemoryStats       — nested ordered hashtable with:
#       TotalMB      — sum of MemoryMB across $enriched (rounded to 2 decimals)
#       AverageMB    — average MemoryMB across $enriched (rounded to 2 decimals)
#       MaxMB        — maximum MemoryMB across $enriched (rounded to 2 decimals)
#       MinMB        — minimum MemoryMB across $enriched (rounded to 2 decimals)
#   TierBreakdown     — nested ordered hashtable mapping each tier name to its count
#                        (built from $tierGroups)
#   TopConsumer       — Name of the process with the highest MemoryMB in $top10
#
# Hint: Use Measure-Object on $enriched for the MemoryStats values.
#       Use a foreach loop over $tierGroups to build TierBreakdown.

Write-Host "`n--- Dashboard Summary ---" -ForegroundColor Cyan



# =========================================================================
# STEP 8 — Display the summary
# =========================================================================
# TODO: Display $summary as a formatted JSON string with Depth 3.
#       Also display key statistics using Write-Host:
#
#   Total Processes  : <TotalProcesses>
#   Significant      : <SignificantCount>
#   Total Memory (MB): <MemoryStats.TotalMB>
#   Top Consumer     : <TopConsumer>



Write-Host "`n=== Exercise 02 Complete ===" -ForegroundColor Green

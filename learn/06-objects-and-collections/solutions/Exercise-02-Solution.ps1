<#
.SYNOPSIS
    Module 06 Exercise 02 Solution: Process Analytics Dashboard
.DESCRIPTION
    Complete solution that collects live process data, creates calculated
    properties, groups by memory usage tiers, converts top consumers to
    JSON, and generates a summary hashtable with statistics.

    Each pipeline operation is annotated with its LINQ and SQL equivalent.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.EXAMPLE
    .\Exercise-02-Solution.ps1
.NOTES
    Module  : 06 - Objects and Collections
    Exercise: 02 - Process Analytics Dashboard (Solution)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================================================================
# STEP 1 — Collect process data snapshot
# =========================================================================
# PowerShell : Get-Process
# LINQ       : dbContext.Processes.ToList()
# SQL        : SELECT * FROM sys.dm_exec_requests
$processes = Get-Process

Write-Host '=== Process Analytics Dashboard ===' -ForegroundColor Cyan
Write-Host "Snapshot taken: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# =========================================================================
# STEP 2 — Create calculated properties (Select-Object)
# =========================================================================
# PowerShell : Select-Object with @{Name=...; Expression=...}
# LINQ       : .Select(p => new { p.Name, MemoryMB = p.WS / 1MB, ... })
# SQL        : SELECT Name, WorkingSet64/1048576 AS MemoryMB FROM ...
$enriched = $processes | Select-Object `
    Name,
    Id,
    @{
        Name       = 'MemoryMB'
        Expression = { [Math]::Round($_.WorkingSet64 / 1MB, 2) }
    },
    @{
        Name       = 'HandleCount'
        Expression = { $_.Handles }
    },
    @{
        Name       = 'MemoryTier'
        Expression = {
            $mb = $_.WorkingSet64 / 1MB
            if     ($mb -ge 500) { 'High' }
            elseif ($mb -ge 100) { 'Medium' }
            elseif ($mb -ge 10)  { 'Low' }
            else                 { 'Minimal' }
        }
    }

Write-Host '--- Enriched Process Data (Top 10 by Memory) ---' -ForegroundColor Yellow
$enriched | Sort-Object MemoryMB -Descending |
    Select-Object -First 10 |
    Format-Table -AutoSize

# =========================================================================
# STEP 3 — Filter: Exclude minimal-memory processes (Where-Object)
# =========================================================================
# PowerShell : Where-Object { $_.MemoryTier -ne 'Minimal' }
# LINQ       : .Where(p => p.MemoryTier != "Minimal")
# SQL        : WHERE MemoryTier <> 'Minimal'
$significant = $enriched | Where-Object { $_.MemoryTier -ne 'Minimal' }

Write-Host "`n--- Significant Processes (excluding Minimal) ---" -ForegroundColor Yellow
Write-Host "  Count: $(($significant | Measure-Object).Count)"

# =========================================================================
# STEP 4 — Sort: Top 10 memory consumers (Sort-Object)
# =========================================================================
# PowerShell : Sort-Object MemoryMB -Descending | Select-Object -First 10
# LINQ       : .OrderByDescending(p => p.MemoryMB).Take(10)
# SQL        : SELECT TOP 10 ... ORDER BY MemoryMB DESC
$top10 = $significant |
    Sort-Object MemoryMB -Descending |
    Select-Object -First 10

Write-Host "`n--- Top 10 Memory Consumers ---" -ForegroundColor Green
$top10 | Format-Table Name, Id, MemoryMB, HandleCount, MemoryTier -AutoSize

# =========================================================================
# STEP 5 — Group: Processes by MemoryTier (Group-Object)
# =========================================================================
# PowerShell : Group-Object -Property MemoryTier
# LINQ       : .GroupBy(p => p.MemoryTier)
# SQL        : SELECT MemoryTier, COUNT(*) FROM ... GROUP BY MemoryTier
$tierGroups = $enriched | Group-Object -Property MemoryTier

Write-Host "`n--- Memory Tier Distribution ---" -ForegroundColor Magenta

# Build a display table from the grouped results
$tierSummary = foreach ($group in $tierGroups) {
    $totalMB = ($group.Group | Measure-Object -Property MemoryMB -Sum).Sum
    [PSCustomObject][ordered]@{
        Tier       = $group.Name
        Count      = $group.Count
        'TotalMB'  = [Math]::Round($totalMB, 2)
    }
}
$tierSummary | Sort-Object TotalMB -Descending | Format-Table -AutoSize

# =========================================================================
# STEP 6 — Convert top consumers to JSON (ConvertTo-Json)
# =========================================================================
# PowerShell : ConvertTo-Json -Depth 2
# LINQ       : JsonConvert.SerializeObject(top10)
# SQL        : FOR JSON PATH
$jsonOutput = $top10 | ConvertTo-Json -Depth 2

Write-Host "`n--- Top 10 as JSON ---" -ForegroundColor Yellow
Write-Host $jsonOutput

# =========================================================================
# STEP 7 — Build a summary hashtable (Measure-Object)
# =========================================================================
# PowerShell : Measure-Object -Property MemoryMB -Sum -Average -Maximum -Minimum
# LINQ       : new { Sum = list.Sum(p=>p.Mem), Avg = list.Average(p=>p.Mem), ... }
# SQL        : SELECT SUM(MemoryMB), AVG(MemoryMB), MAX(MemoryMB), MIN(MemoryMB) ...
$memStats = $enriched | Measure-Object -Property MemoryMB -Sum -Average -Maximum -Minimum

# Build the tier breakdown hashtable from the grouped data
$tierBreakdown = [ordered]@{}
foreach ($group in ($tierGroups | Sort-Object { $_.Count } -Descending)) {
    $tierBreakdown[$group.Name] = $group.Count
}

$summary = [ordered]@{
    SnapshotTime    = Get-Date -Format 'o'
    TotalProcesses  = ($processes | Measure-Object).Count
    SignificantCount = ($significant | Measure-Object).Count
    MemoryStats     = [ordered]@{
        TotalMB   = [Math]::Round($memStats.Sum,     2)
        AverageMB = [Math]::Round($memStats.Average,  2)
        MaxMB     = [Math]::Round($memStats.Maximum,  2)
        MinMB     = [Math]::Round($memStats.Minimum,  2)
    }
    TierBreakdown   = $tierBreakdown
    TopConsumer     = $top10[0].Name
}

# =========================================================================
# STEP 8 — Display the summary
# =========================================================================
Write-Host "`n--- Dashboard Summary ---" -ForegroundColor Cyan

# Full summary as JSON for structured output
$summary | ConvertTo-Json -Depth 3

# Human-readable key statistics
Write-Host ''
Write-Host "  Total Processes  : $($summary.TotalProcesses)"
Write-Host "  Significant      : $($summary.SignificantCount)"
Write-Host "  Total Memory (MB): $($summary.MemoryStats.TotalMB)"
Write-Host "  Top Consumer     : $($summary.TopConsumer)"

Write-Host "`n=== Exercise 02 Complete ===" -ForegroundColor Green

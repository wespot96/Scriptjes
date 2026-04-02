<#
.SYNOPSIS
    Module 06 Exercise 01 Solution: Server Inventory Builder
.DESCRIPTION
    Complete solution demonstrating PSCustomObject creation, Generic.List
    usage, pipeline operations (Where-Object, Sort-Object, Group-Object,
    Measure-Object, Select-Object), CSV export/import, and Compare-Object.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.EXAMPLE
    .\Exercise-01-Solution.ps1
.NOTES
    Module  : 06 - Objects and Collections
    Exercise: 01 - Server Inventory Builder (Solution)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Configuration ──────────────────────────────────────────────────
$CsvPath = Join-Path $PSScriptRoot 'ServerInventory.csv'
#endregion

# =========================================================================
# STEP 1 — Create a Generic.List to hold server inventory objects
# =========================================================================
# Generic.List avoids the O(n) reallocation cost of $array += on every add.
$servers = [System.Collections.Generic.List[PSCustomObject]]::new()

# =========================================================================
# STEP 2 — Define server data and populate the list
# =========================================================================
# Using a data-driven approach: define rows in a compact array of hashtables,
# then iterate and add each as a PSCustomObject to the typed list.
$serverData = @(
    @{ Name = 'WEB01'; IP = '10.0.1.10'; Role = 'WebServer';        OS = 'Windows Server 2022'; Status = 'Online'  }
    @{ Name = 'WEB02'; IP = '10.0.1.11'; Role = 'WebServer';        OS = 'Windows Server 2022'; Status = 'Online'  }
    @{ Name = 'DB01';  IP = '10.0.2.10'; Role = 'Database';         OS = 'Windows Server 2022'; Status = 'Online'  }
    @{ Name = 'DB02';  IP = '10.0.2.11'; Role = 'Database';         OS = 'Windows Server 2019'; Status = 'Offline' }
    @{ Name = 'APP01'; IP = '10.0.3.10'; Role = 'AppServer';        OS = 'Windows Server 2022'; Status = 'Online'  }
    @{ Name = 'APP02'; IP = '10.0.3.11'; Role = 'AppServer';        OS = 'Windows Server 2022'; Status = 'Online'  }
    @{ Name = 'DC01';  IP = '10.0.4.10'; Role = 'DomainController'; OS = 'Windows Server 2022'; Status = 'Online'  }
    @{ Name = 'DC02';  IP = '10.0.4.11'; Role = 'DomainController'; OS = 'Windows Server 2019'; Status = 'Offline' }
)

foreach ($entry in $serverData) {
    # [ordered] guarantees property order matches the hashtable literal order
    $servers.Add([PSCustomObject][ordered]@{
        Name   = $entry.Name
        IP     = $entry.IP
        Role   = $entry.Role
        OS     = $entry.OS
        Status = $entry.Status
    })
}

# =========================================================================
# STEP 3 — Display the full inventory
# =========================================================================
Write-Host "`n=== Full Server Inventory ===" -ForegroundColor Cyan
$servers | Format-Table -AutoSize

# =========================================================================
# STEP 4 — Filter: Online servers only (Where-Object)
# =========================================================================
$onlineServers = $servers | Where-Object { $_.Status -eq 'Online' }

Write-Host "`n=== Online Servers ===" -ForegroundColor Green
$onlineServers | Format-Table -AutoSize

# =========================================================================
# STEP 5 — Sort: Order by Role then Name (Sort-Object)
# =========================================================================
$sortedServers = $servers | Sort-Object -Property Role, Name

Write-Host "`n=== Servers Sorted by Role, Name ===" -ForegroundColor Yellow
$sortedServers | Format-Table -AutoSize

# =========================================================================
# STEP 6 — Group: Count servers per Role (Group-Object)
# =========================================================================
Write-Host "`n=== Servers per Role ===" -ForegroundColor Magenta
$servers | Group-Object -Property Role |
    Select-Object Name, Count |
    Format-Table -AutoSize

# =========================================================================
# STEP 7 — Measure: Inventory statistics (Measure-Object)
# =========================================================================
$totalCount   = ($servers   | Measure-Object).Count
$onlineCount  = ($servers   | Where-Object { $_.Status -eq 'Online' }  | Measure-Object).Count
$offlineCount = ($servers   | Where-Object { $_.Status -eq 'Offline' } | Measure-Object).Count

Write-Host "`n=== Inventory Statistics ===" -ForegroundColor Cyan
Write-Host "  Total servers : $totalCount"
Write-Host "  Online        : $onlineCount"
Write-Host "  Offline       : $offlineCount"

# =========================================================================
# STEP 8 — Select: Create a calculated property (Select-Object)
# =========================================================================
# Extract the third octet from each IP to identify the subnet.
Write-Host "`n=== Server Subnets ===" -ForegroundColor Yellow
$servers | Select-Object Name, Role, @{
    Name       = 'Subnet'
    Expression = { ($_.IP -split '\.')[2] }
} | Format-Table -AutoSize

# =========================================================================
# STEP 9 — Export to CSV
# =========================================================================
$servers | Export-Csv -Path $CsvPath -NoTypeInformation

Write-Host "`n=== Exported to $CsvPath ===" -ForegroundColor Green

# =========================================================================
# STEP 10 — Import from CSV and compare (Compare-Object)
# =========================================================================
$imported = Import-Csv -Path $CsvPath

# Compare on the Name property — if both sets have identical names the
# result is $null (no differences).
$diff = Compare-Object -ReferenceObject $servers -DifferenceObject $imported -Property Name

Write-Host "`n=== CSV Round-Trip Comparison ===" -ForegroundColor Cyan
if (-not $diff) {
    Write-Host '  CSV round-trip successful — no differences found.' -ForegroundColor Green
}
else {
    Write-Host '  Differences detected:' -ForegroundColor Red
    $diff | Format-Table -AutoSize
}

# =========================================================================
# STEP 11 — Cleanup
# =========================================================================
Remove-Item -Path $CsvPath -ErrorAction SilentlyContinue

Write-Host "`n=== Exercise 01 Complete ===" -ForegroundColor Green

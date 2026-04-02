<#
.SYNOPSIS
    Module 06 Exercise 01: Server Inventory Builder
.DESCRIPTION
    Practice creating PSCustomObjects, storing them in a Generic.List,
    performing pipeline operations (Where-Object, Sort-Object, Group-Object,
    Measure-Object), exporting to CSV, re-importing, and comparing with
    Compare-Object.

    Complete each TODO section below. Run the script when finished to verify
    your work produces the expected output.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.
.EXAMPLE
    .\Exercise-01.ps1
.NOTES
    Module  : 06 - Objects and Collections
    Exercise: 01 - Server Inventory Builder
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Configuration ──────────────────────────────────────────────────
$CsvPath = Join-Path $PSScriptRoot 'ServerInventory.csv'
#endregion

# =========================================================================
# STEP 1 — Create a Generic.List to hold server inventory objects
# =========================================================================
# TODO: Create a [System.Collections.Generic.List[PSCustomObject]] named
#       $servers. This is more efficient than using $array += for repeated
#       additions because it avoids reallocating the entire array each time.
#
# Hint: $servers = [System.Collections.Generic.List[PSCustomObject]]::new()



# =========================================================================
# STEP 2 — Define server data and populate the list
# =========================================================================
# TODO: Create PSCustomObjects for each server below and add them to $servers
#       using the .Add() method. Each object must have these properties:
#
#       Name   (string)  — server hostname
#       IP     (string)  — IPv4 address
#       Role   (string)  — WebServer, Database, AppServer, or DomainController
#       OS     (string)  — operating system caption
#       Status (string)  — Online or Offline
#
# Use these servers:
#   WEB01  | 10.0.1.10  | WebServer        | Windows Server 2022 | Online
#   WEB02  | 10.0.1.11  | WebServer        | Windows Server 2022 | Online
#   DB01   | 10.0.2.10  | Database         | Windows Server 2022 | Online
#   DB02   | 10.0.2.11  | Database         | Windows Server 2019 | Offline
#   APP01  | 10.0.3.10  | AppServer        | Windows Server 2022 | Online
#   APP02  | 10.0.3.11  | AppServer        | Windows Server 2022 | Online
#   DC01   | 10.0.4.10  | DomainController | Windows Server 2022 | Online
#   DC02   | 10.0.4.11  | DomainController | Windows Server 2019 | Offline



# =========================================================================
# STEP 3 — Display the full inventory
# =========================================================================
# TODO: Pipe $servers to Format-Table -AutoSize to display all records.

Write-Host "`n=== Full Server Inventory ===" -ForegroundColor Cyan



# =========================================================================
# STEP 4 — Filter: Online servers only (Where-Object)
# =========================================================================
# TODO: Use Where-Object to filter $servers for Status -eq 'Online'.
#       Store the result in $onlineServers. Display with Format-Table.

Write-Host "`n=== Online Servers ===" -ForegroundColor Green



# =========================================================================
# STEP 5 — Sort: Order by Role then Name (Sort-Object)
# =========================================================================
# TODO: Sort $servers by Role (ascending), then by Name (ascending).
#       Store in $sortedServers. Display with Format-Table.

Write-Host "`n=== Servers Sorted by Role, Name ===" -ForegroundColor Yellow



# =========================================================================
# STEP 6 — Group: Count servers per Role (Group-Object)
# =========================================================================
# TODO: Group $servers by the Role property.
#       Select the Name (group key) and Count properties.
#       Display with Format-Table.

Write-Host "`n=== Servers per Role ===" -ForegroundColor Magenta



# =========================================================================
# STEP 7 — Measure: Inventory statistics (Measure-Object)
# =========================================================================
# TODO: Use Measure-Object to count the total number of servers.
#       Also count how many are Online and how many are Offline.
#       Print the results with Write-Host.
#
# Example output:
#   Total servers : 8
#   Online        : 6
#   Offline       : 2

Write-Host "`n=== Inventory Statistics ===" -ForegroundColor Cyan



# =========================================================================
# STEP 8 — Select: Create a calculated property (Select-Object)
# =========================================================================
# TODO: Use Select-Object to output Name, Role, and a calculated property
#       called 'Subnet' that extracts the third octet from the IP address.
#       Example: 10.0.1.10 → Subnet = 1
#
# Hint: ($_.IP -split '\.')[2]

Write-Host "`n=== Server Subnets ===" -ForegroundColor Yellow



# =========================================================================
# STEP 9 — Export to CSV
# =========================================================================
# TODO: Export $servers to the CSV file at $CsvPath.
#       Use -NoTypeInformation to omit the #TYPE header line.

Write-Host "`n=== Exported to $CsvPath ===" -ForegroundColor Green



# =========================================================================
# STEP 10 — Import from CSV and compare (Compare-Object)
# =========================================================================
# TODO: Import the CSV back into $imported.
#       Use Compare-Object to verify $servers and $imported have the same
#       data. Compare on the Name property.
#       If Compare-Object returns nothing, the sets match.
#
# Hint:
#   $diff = Compare-Object -ReferenceObject $servers -DifferenceObject $imported -Property Name
#   if (-not $diff) { Write-Host 'CSV round-trip successful!' }

Write-Host "`n=== CSV Round-Trip Comparison ===" -ForegroundColor Cyan



# =========================================================================
# STEP 11 — Cleanup
# =========================================================================
# TODO: Remove the CSV file created in Step 9 if it exists.
#       Use Remove-Item with -ErrorAction SilentlyContinue.



Write-Host "`n=== Exercise 01 Complete ===" -ForegroundColor Green

<#
.SYNOPSIS
    Exercise 01 - IIS Site Inventory

.DESCRIPTION
    Build a script that inventories all IIS websites, their bindings, application
    pool states, and key web.config properties, then generates a summary report.

    Skills practised:
      - Get-Website for site enumeration
      - Get-WebBinding for binding details
      - Get-WebAppPoolState for pool health checks
      - Get-WebConfigurationProperty for reading web.config values

    Complete each TODO section to build the full inventory tool.

.NOTES
    Prerequisites:
      - Windows Server 2022 with IIS role installed
      - PowerShell 5.1
      - WebAdministration module (built-in with IIS Management Tools)
      - Run as Administrator
#>

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# Section 1: Module Import and Validation
# ============================================================================

# TODO: Import the WebAdministration module.
#       If it is not available, write an error and exit.
# Hint: Use Get-Module -ListAvailable to check, then Import-Module.



# ============================================================================
# Section 2: Enumerate All Websites
# ============================================================================

# TODO: Use Get-Website to retrieve all IIS websites.
#       For each site, capture: Name, State, PhysicalPath, ApplicationPool,
#       and EnabledProtocols.
#       Store the results in a variable called $siteInventory (an array of
#       PSCustomObjects).
# Hint: Pipe Get-Website into ForEach-Object and build [PSCustomObject] for
#       each site.



# ============================================================================
# Section 3: Collect Binding Information
# ============================================================================

# TODO: For each site in $siteInventory, use Get-WebBinding to retrieve its
#       bindings. Add a 'Bindings' property that is a string summarising all
#       bindings (e.g. "http *:80:, https *:443:mysite.com").
# Hint: Get-WebBinding -Name $site.Name returns binding objects with
#       .Protocol and .BindingInformation properties.



# ============================================================================
# Section 4: Check Application Pool States
# ============================================================================

# TODO: Get the unique application pool names from $siteInventory.
#       For each pool, use Get-WebAppPoolState to check if it is Started.
#       Store results in $poolStates (array of PSCustomObjects with Name and
#       State properties).
# Hint: Get-WebAppPoolState -Name $poolName returns an object with .Value
#       (Started, Stopped, etc.).



# ============================================================================
# Section 5: Read Web Configuration Properties
# ============================================================================

# TODO: For each site, read two configuration properties:
#       1. Anonymous authentication enabled (boolean)
#          Filter: /system.webServer/security/authentication/anonymousAuthentication
#          Property: enabled
#       2. Default documents enabled (boolean)
#          Filter: /system.webServer/defaultDocument
#          Property: enabled
#       Add 'AnonAuthEnabled' and 'DefaultDocEnabled' properties to each site
#       in $siteInventory.
# Hint: Use Get-WebConfigurationProperty with -PSPath "IIS:\Sites\$siteName"
#       and -Filter / -Name parameters.



# ============================================================================
# Section 6: Generate Summary Report
# ============================================================================

# TODO: Output the inventory data in a formatted report:
#       1. Print a header with timestamp and total site count.
#       2. Print $siteInventory as a table (Name, State, ApplicationPool,
#          Bindings, AnonAuthEnabled).
#       3. Print $poolStates as a table.
#       4. Print a summary line: how many sites are Started vs Stopped,
#          how many pools are Started vs Stopped.
# Hint: Use Format-Table, Write-Host, and Group-Object for counts.




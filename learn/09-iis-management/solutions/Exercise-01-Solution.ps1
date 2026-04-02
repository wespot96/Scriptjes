<#
.SYNOPSIS
    Exercise 01 Solution - IIS Site Inventory

.DESCRIPTION
    Inventories all IIS websites with their bindings, application pool states,
    and key web.config properties, then generates a formatted summary report.

    Demonstrates:
      - Get-Website for site enumeration
      - Get-WebBinding for binding details
      - Get-WebAppPoolState for pool health
      - Get-WebConfigurationProperty for web.config values
      - Formatted console reporting

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

if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    Write-Error "WebAdministration module not found. Install IIS Management Tools first."
    exit 1
}
Import-Module WebAdministration -ErrorAction Stop

# ============================================================================
# Section 2: Enumerate All Websites
# ============================================================================

$websites = Get-Website
if (-not $websites) {
    Write-Warning "No IIS websites found on this server."
    exit 0
}

# Build initial inventory with core site properties
$siteInventory = $websites | ForEach-Object {
    [PSCustomObject]@{
        Name             = $_.Name
        State            = $_.State
        PhysicalPath     = $_.PhysicalPath
        ApplicationPool  = $_.ApplicationPool
        EnabledProtocols = $_.EnabledProtocols
        Bindings         = ''
        AnonAuthEnabled  = $null
        DefaultDocEnabled = $null
    }
}

# ============================================================================
# Section 3: Collect Binding Information
# ============================================================================

# Enrich each site with a human-readable bindings summary
foreach ($site in $siteInventory) {
    $bindings = Get-WebBinding -Name $site.Name -ErrorAction SilentlyContinue
    if ($bindings) {
        # Format: "protocol IP:Port:HostHeader" joined by ", "
        $site.Bindings = ($bindings | ForEach-Object {
            "$($_.Protocol) $($_.BindingInformation)"
        }) -join ', '
    } else {
        $site.Bindings = '(none)'
    }
}

# ============================================================================
# Section 4: Check Application Pool States
# ============================================================================

# Get unique pool names referenced by sites
$poolNames = $siteInventory | Select-Object -ExpandProperty ApplicationPool -Unique

$poolStates = $poolNames | ForEach-Object {
    $state = try {
        (Get-WebAppPoolState -Name $_).Value
    } catch {
        'Unknown'
    }
    [PSCustomObject]@{
        Name  = $_
        State = $state
    }
}

# ============================================================================
# Section 5: Read Web Configuration Properties
# ============================================================================

foreach ($site in $siteInventory) {
    $sitePath = "IIS:\Sites\$($site.Name)"

    # Anonymous authentication status
    $site.AnonAuthEnabled = try {
        (Get-WebConfigurationProperty `
            -PSPath $sitePath `
            -Filter '/system.webServer/security/authentication/anonymousAuthentication' `
            -Name 'enabled').Value
    } catch {
        'N/A'
    }

    # Default document status
    $site.DefaultDocEnabled = try {
        (Get-WebConfigurationProperty `
            -PSPath $sitePath `
            -Filter '/system.webServer/defaultDocument' `
            -Name 'enabled').Value
    } catch {
        'N/A'
    }
}

# ============================================================================
# Section 6: Generate Summary Report
# ============================================================================

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$totalSites = $siteInventory.Count

Write-Host ''
Write-Host '====================================================' -ForegroundColor Cyan
Write-Host "  IIS Site Inventory Report - $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "  Generated: $timestamp" -ForegroundColor Cyan
Write-Host "  Total Sites: $totalSites" -ForegroundColor Cyan
Write-Host '====================================================' -ForegroundColor Cyan

# Site details table
Write-Host "`n--- Website Details ---" -ForegroundColor Yellow
$siteInventory |
    Format-Table -Property Name, State, ApplicationPool, Bindings, AnonAuthEnabled -AutoSize |
    Out-String | Write-Host

# App pool states table
Write-Host '--- Application Pool States ---' -ForegroundColor Yellow
$poolStates |
    Format-Table -Property Name, State -AutoSize |
    Out-String | Write-Host

# Summary counts
$startedSites  = ($siteInventory | Where-Object { $_.State -eq 'Started' }).Count
$stoppedSites  = $totalSites - $startedSites
$startedPools  = ($poolStates | Where-Object { $_.State -eq 'Started' }).Count
$stoppedPools  = $poolStates.Count - $startedPools

Write-Host '--- Summary ---' -ForegroundColor Yellow
Write-Host "  Sites   : $startedSites Started, $stoppedSites Stopped (of $totalSites)" -ForegroundColor White
Write-Host "  App Pools: $startedPools Started, $stoppedPools Stopped (of $($poolStates.Count))" -ForegroundColor White
Write-Host ''

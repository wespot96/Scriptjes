<#
.SYNOPSIS
    Exercise 02 Solution - IIS Security Hardening Checker

.DESCRIPTION
    Audits IIS security configuration across all websites and outputs a
    compliance report. Inspired by the http_header_removal.ps1 remediation
    script, this checker verifies that common hardening steps are in place.

    Checks performed:
      1. Server header suppressed (removeServerHeader = true)
      2. X-Powered-By custom header removed
      3. HTTPS bindings present on every site
      4. App pool identities not running as LocalSystem
      5. Per-site and overall compliance summary

    Demonstrates:
      - Get-WebConfigurationProperty with -PSPath scoping (server vs site)
      - Custom header collection inspection
      - Get-WebBinding protocol filtering
      - App pool ProcessModel.IdentityType inspection
      - Structured compliance reporting

.NOTES
    Prerequisites:
      - Windows Server 2022 with IIS role installed
      - PowerShell 5.1
      - WebAdministration module (built-in with IIS Management Tools)
      - Run as Administrator

    Reference: http_header_removal.ps1 in the repository root demonstrates
    the remediation side of these same checks.
#>

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# Section 1: Module Import and Validation
# ============================================================================

if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    Write-Error "WebAdministration module not found. Ensure the IIS role and Management Tools are installed."
    exit 1
}
Import-Module WebAdministration -ErrorAction Stop

# ============================================================================
# Section 2: Initialise Report Collection
# ============================================================================

$complianceResults = @()

# ============================================================================
# Section 3: Check Server Header Suppression (Server-Wide)
# ============================================================================

# The removeServerHeader attribute on requestFiltering is a server-wide setting
# in IIS 10+ that strips the "Server: Microsoft-IIS/10.0" header from responses.
$serverHeaderSuppressed = $false
try {
    $value = (Get-WebConfigurationProperty `
        -PSPath 'MACHINE/WEBROOT/APPHOST' `
        -Filter 'system.webServer/security/requestFiltering' `
        -Name 'removeServerHeader').Value
    $serverHeaderSuppressed = [bool]$value
} catch {
    # Attribute may not exist on older IIS versions
    $serverHeaderSuppressed = $false
}

# ============================================================================
# Section 4: Per-Site Security Checks
# ============================================================================

$websites = Get-Website
if (-not $websites) {
    Write-Warning "No IIS websites found on this server."
    exit 0
}

foreach ($site in $websites) {
    $siteName = $site.Name
    $sitePath = "IIS:\Sites\$siteName"

    # --- 4a. X-Powered-By Header Check ---
    # Read the custom headers collection at the site level and look for
    # an entry named "X-Powered-By". If present, the header is still being sent.
    $xPoweredByRemoved = $true
    try {
        $customHeaders = Get-WebConfigurationProperty `
            -PSPath $sitePath `
            -Filter 'system.webServer/httpProtocol/customHeaders' `
            -Name '.'
        $xpbEntry = $customHeaders | Where-Object { $_.name -ieq 'X-Powered-By' }
        $xPoweredByRemoved = ($null -eq $xpbEntry)
    } catch {
        # If we cannot read the property, flag as non-compliant
        $xPoweredByRemoved = $false
    }

    # --- 4b. HTTPS Binding Check ---
    # Every production site should have at least one HTTPS binding.
    $hasHttpsBinding = $false
    try {
        $httpsBindings = Get-WebBinding -Name $siteName |
            Where-Object { $_.Protocol -eq 'https' }
        $hasHttpsBinding = ($null -ne $httpsBindings)
    } catch {
        $hasHttpsBinding = $false
    }

    # --- 4c. App Pool Identity Check ---
    # LocalSystem grants the worker process full access to the OS, which is a
    # significant security risk. Acceptable identities include
    # ApplicationPoolIdentity, NetworkService, LocalService, or SpecificUser.
    $poolIdentitySafe = $true
    try {
        $poolName     = $site.ApplicationPool
        $identityType = (Get-WebAppPool -Name $poolName).ProcessModel.IdentityType
        $poolIdentitySafe = ($identityType -ne 'LocalSystem')
    } catch {
        $poolIdentitySafe = $false
    }

    # --- 4d. Determine Overall Pass ---
    $overallPass = (
        $serverHeaderSuppressed -and
        $xPoweredByRemoved -and
        $hasHttpsBinding -and
        $poolIdentitySafe
    )

    # --- 4e. Add result to collection ---
    $complianceResults += [PSCustomObject]@{
        SiteName               = $siteName
        ServerHeaderSuppressed = $serverHeaderSuppressed
        XPoweredByRemoved      = $xPoweredByRemoved
        HasHttpsBinding        = $hasHttpsBinding
        PoolIdentitySafe       = $poolIdentitySafe
        OverallPass            = $overallPass
    }
}

# ============================================================================
# Section 5: Output Compliance Report
# ============================================================================

$timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$totalSites = $complianceResults.Count
$passCount  = ($complianceResults | Where-Object { $_.OverallPass }).Count
$failCount  = $totalSites - $passCount

Write-Host ''
Write-Host '====================================================' -ForegroundColor Cyan
Write-Host "  IIS Security Hardening Report - $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "  Generated: $timestamp" -ForegroundColor Cyan
Write-Host '====================================================' -ForegroundColor Cyan

# Server-wide check
$headerColor = if ($serverHeaderSuppressed) { 'Green' } else { 'Red' }
$headerStatus = if ($serverHeaderSuppressed) { 'PASS' } else { 'FAIL' }
Write-Host "`n  Server Header Suppressed (server-wide): [$headerStatus]" -ForegroundColor $headerColor

# Per-site results table
Write-Host "`n--- Per-Site Compliance ---" -ForegroundColor Yellow
$complianceResults |
    Format-Table -Property SiteName, ServerHeaderSuppressed, XPoweredByRemoved,
        HasHttpsBinding, PoolIdentitySafe, OverallPass -AutoSize |
    Out-String | Write-Host

# Summary
Write-Host '--- Summary ---' -ForegroundColor Yellow
Write-Host "  Total sites checked : $totalSites" -ForegroundColor White
Write-Host "  Passed              : $passCount" -ForegroundColor Green
Write-Host "  Failed              : $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Green' })

# Detail failing sites
if ($failCount -gt 0) {
    Write-Host "`n--- Failed Sites Detail ---" -ForegroundColor Red
    $complianceResults | Where-Object { -not $_.OverallPass } | ForEach-Object {
        $failures = @()
        if (-not $_.ServerHeaderSuppressed) { $failures += 'ServerHeader' }
        if (-not $_.XPoweredByRemoved)      { $failures += 'X-Powered-By' }
        if (-not $_.HasHttpsBinding)        { $failures += 'NoHTTPS' }
        if (-not $_.PoolIdentitySafe)       { $failures += 'PoolIdentity' }
        Write-Host "  $($_.SiteName): $($failures -join ', ')" -ForegroundColor Red
    }
}

Write-Host ''

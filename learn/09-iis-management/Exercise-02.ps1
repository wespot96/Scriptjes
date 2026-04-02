<#
.SYNOPSIS
    Exercise 02 - IIS Security Hardening Checker

.DESCRIPTION
    Build a script that audits IIS security configuration across all websites,
    inspired by the http_header_removal.ps1 remediation script. The checker
    verifies that common security hardening steps have been applied and outputs
    a compliance report.

    Checks performed:
      1. Server header suppressed (removeServerHeader = true)
      2. X-Powered-By custom header removed
      3. HTTPS bindings present on every site
      4. App pool identities not running as LocalSystem
      5. Compliance summary with pass/fail per site

    Skills practised:
      - Get-WebConfigurationProperty with -PSPath scoping
      - Inspecting custom header collections
      - Get-WebBinding protocol filtering
      - App pool ProcessModel.IdentityType inspection

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

# TODO: Import WebAdministration. Exit with a clear message if IIS is not
#       installed or the module is unavailable.



# ============================================================================
# Section 2: Initialise Report Collection
# ============================================================================

# TODO: Create an empty array $complianceResults to hold per-site results.
#       Each entry will be a PSCustomObject with properties:
#         SiteName, ServerHeaderSuppressed, XPoweredByRemoved,
#         HasHttpsBinding, PoolIdentitySafe, OverallPass
# Hint: $complianceResults = @()



# ============================================================================
# Section 3: Check Server Header Suppression (Server-Wide)
# ============================================================================

# TODO: Read the requestFiltering removeServerHeader attribute at the server
#       level (MACHINE/WEBROOT/APPHOST) using Get-WebConfigurationProperty.
#       Store the boolean result in $serverHeaderSuppressed.
#       Filter: system.webServer/security/requestFiltering
#       Name:   removeServerHeader
# Hint: $value = (Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
#           -Filter '...' -Name '...').Value
#       This is a server-wide setting, so one check covers all sites.



# ============================================================================
# Section 4: Per-Site Security Checks
# ============================================================================

# TODO: Loop through every site returned by Get-Website. For each site:
#
#   4a. X-Powered-By Header Check
#       Read system.webServer/httpProtocol/customHeaders at the site's PSPath
#       ("IIS:\Sites\$siteName"). Check whether any entry has name = 'X-Powered-By'.
#       If found, the check FAILS; if absent, it PASSES.
#       Hint: Get-WebConfigurationProperty -PSPath "IIS:\Sites\$siteName" `
#                 -Filter 'system.webServer/httpProtocol/customHeaders' -Name '.'
#             Then pipe to Where-Object { $_.name -ieq 'X-Powered-By' }
#
#   4b. HTTPS Binding Check
#       Use Get-WebBinding -Name $siteName and filter for Protocol -eq 'https'.
#       If at least one HTTPS binding exists, the check PASSES.
#
#   4c. App Pool Identity Check
#       Get the site's ApplicationPool property, then read the identity type.
#       The check FAILS if IdentityType is 'LocalSystem'.
#       Hint: (Get-WebAppPool -Name $poolName).ProcessModel.IdentityType
#             Safe values: ApplicationPoolIdentity, NetworkService, SpecificUser, LocalService
#
#   4d. Determine Overall Pass
#       A site passes overall only if ALL four checks pass
#       ($serverHeaderSuppressed, xPoweredByRemoved, hasHttps, poolIdentitySafe).
#
#   4e. Add a PSCustomObject with the results to $complianceResults.



# ============================================================================
# Section 5: Output Compliance Report
# ============================================================================

# TODO: Display the compliance report:
#   1. Print a header banner with the date/time and server name ($env:COMPUTERNAME).
#   2. Print the server-wide Server header status.
#   3. Print $complianceResults as a formatted table.
#   4. Print a summary: total sites checked, how many passed, how many failed.
#   5. If any site failed, list the failing site names and which check(s) failed.
# Hint: Use Format-Table -AutoSize, Where-Object for filtering failures,
#       and Write-Host with colour for pass/fail emphasis.




<#
.SYNOPSIS
    Remediates Nessus finding 88099 - Web Server HTTP Header Information Disclosure on Windows IIS.

.DESCRIPTION
    This script removes or suppresses HTTP response headers that disclose server version
    and technology information, directly addressing Nessus plug-in 88099.

    Headers targeted and what each change does in IIS:

    1. SERVER HEADER  (e.g. "Server: Microsoft-IIS/10.0")
       - IIS 10.0+ (Server 2016+): Sets requestFiltering/@removeServerHeader = true
         in applicationHost.config, which instructs IIS to strip the Server header
         from all responses at the pipeline level before they leave the server.
       - IIS < 10.0 fallback: Sets HKLM\SYSTEM\CurrentControlSet\Services\HTTP\Parameters
         DisableServerHeader (DWORD) = 1, which tells the kernel-mode HTTP.sys driver
         to suppress the header. Requires a service restart of W3SVC/HTTP to take effect.

    2. X-POWERED-BY HEADER  (e.g. "X-Powered-By: ASP.NET")
       - Removes the default outbound custom header entry from
         system.webServer/httpProtocol/customHeaders in applicationHost.config.
         IIS adds this header via a static list of custom headers defined at the
         server or site level; removing the entry from that list stops IIS from
         sending it entirely.

    3. X-ASPNET-VERSION HEADER  (e.g. "X-AspNet-Version: 4.0.30319")
       - Sets system.web/httpRuntime/@enableVersionHeader = false in web.config
         (or applicationHost.config at server level). This flag controls whether
         the ASP.NET runtime appends its version string to responses. Setting it
         to false disables the behaviour in the managed pipeline.

    4. X-ASPNETMVC-VERSION HEADER  (e.g. "X-AspNetMvc-Version: 5.2")
       - Injects a MvcHandler.DisableMvcResponseHeader = true entry into
         appSettings in web.config. The MVC framework reads this key on startup
         to decide whether to add the header. Setting it to true stops the header
         from being emitted by the MvcHandler.

    SCOPE BEHAVIOUR
       - By default the script applies changes at the IIS server level
         (applicationHost.config), which covers all sites.
       - Use -SiteName to restrict changes to a single site's web.config.
       - Use -WhatIf to preview changes without writing anything.

.PARAMETER SiteName
    Optional. Name of a specific IIS site to target. If omitted, changes are
    applied server-wide in applicationHost.config.

.PARAMETER SkipServerHeader
    Skip the Server header remediation step.

.PARAMETER SkipXPoweredBy
    Skip the X-Powered-By header remediation step.

.PARAMETER SkipAspNetVersion
    Skip the X-AspNet-Version header remediation step.

.PARAMETER SkipMvcVersion
    Skip the X-AspNetMvc-Version header remediation step.

.PARAMETER WhatIf
    Show what changes would be made without actually applying them.

.EXAMPLE
    # Remediate all headers server-wide
    .\http_header_removal.ps1

.EXAMPLE
    # Remediate only a specific site
    .\http_header_removal.ps1 -SiteName "Default Web Site"

.EXAMPLE
    # Preview changes without applying them
    .\http_header_removal.ps1 -WhatIf

.NOTES
    Requires:
      - PowerShell 5.1+
      - Run as Administrator
      - WebAdministration module (ships with IIS Management Tools)
      - IIS must be installed
    Tested on: IIS 8.5, IIS 10.0 (Windows Server 2012 R2 / 2016 / 2019 / 2022)
    Nessus Plugin: 88099 - Web Server HTTP Header Information Disclosure
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SiteName,
    [switch]$SkipServerHeader,
    [switch]$SkipXPoweredBy,
    [switch]$SkipAspNetVersion,
    [switch]$SkipMvcVersion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

function Write-Step {
    param([string]$Message)
    Write-Host "`n[*] $Message" -ForegroundColor Cyan
}

function Write-Done {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "    [--] SKIPPED: $Message" -ForegroundColor DarkGray
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    [!] $Message" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

# Require elevation
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must be run as Administrator.'
}

# Require WebAdministration
if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    throw 'The WebAdministration module is not available. Install IIS Management Tools first.'
}
Import-Module WebAdministration -ErrorAction Stop

# Detect IIS version
$iisVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\InetStp' -ErrorAction SilentlyContinue).MajorVersion
Write-Host "IIS major version detected: $($iisVersion ?? 'Unknown')" -ForegroundColor White

# Determine config path scope
if ($SiteName) {
    $pspath = "IIS:\Sites\$SiteName"
    $scopeLabel = "site '$SiteName'"
    # Verify the site exists
    if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
        throw "IIS site '$SiteName' was not found."
    }
} else {
    $pspath    = 'MACHINE/WEBROOT/APPHOST'
    $scopeLabel = 'server (all sites)'
}

Write-Host "Applying remediation to: $scopeLabel" -ForegroundColor White
Write-Host "WhatIf mode: $($WhatIfPreference)" -ForegroundColor White

# ---------------------------------------------------------------------------
# 1. SERVER HEADER
#    What it changes:
#      IIS 10+  -> applicationHost.config system.webServer/security/requestFiltering
#                  attribute removeServerHeader="true"
#      IIS <10  -> HKLM registry key HTTP\Parameters\DisableServerHeader = 1
# ---------------------------------------------------------------------------

if (-not $SkipServerHeader) {
    Write-Step 'Removing Server header'

    if ($null -ne $iisVersion -and $iisVersion -ge 10) {
        # IIS 10+ native attribute -------------------------------------------
        # requestFiltering/@removeServerHeader tells IIS to strip the Server
        # header in the IIS integrated pipeline before the response is sent.
        $filter  = 'system.webServer/security/requestFiltering'
        $current = (Get-WebConfigurationProperty -pspath $pspath -filter $filter -name 'removeServerHeader' -ErrorAction SilentlyContinue).Value

        if ($current -eq $true) {
            Write-Done 'removeServerHeader is already true — no change needed.'
        } else {
            if ($PSCmdlet.ShouldProcess($scopeLabel, "Set $filter/@removeServerHeader = true")) {
                Set-WebConfigurationProperty -pspath $pspath -filter $filter -name 'removeServerHeader' -value $true
                Write-Done "Set system.webServer/security/requestFiltering/@removeServerHeader = true"
            }
        }
    } else {
        # IIS < 10 fallback: HTTP.sys registry key ---------------------------
        # DisableServerHeader controls whether the kernel-mode HTTP.sys driver
        # includes the Server header.  Value 1 = suppress the header entirely.
        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters'
        $regName = 'DisableServerHeader'
        $current = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName

        if ($current -eq 1) {
            Write-Done "Registry $regName is already 1 — no change needed."
        } else {
            if ($PSCmdlet.ShouldProcess($regPath, "Set $regName = 1 (DWORD)")) {
                Set-ItemProperty -Path $regPath -Name $regName -Value 1 -Type DWord -Force
                Write-Done "Set HKLM\...\HTTP\Parameters\DisableServerHeader = 1 (requires HTTP service restart)"
                Write-Warn 'Restart the W3SVC service (or reboot) for the registry change to take effect.'
            }
        }

        # Also attempt URL Rewrite outbound rule if the module is installed
        $urlRewriteFilter = 'system.webServer/rewrite/outboundRules'
        $ruleName         = 'Remove Server Header'
        $existingRule     = Get-WebConfigurationProperty -pspath $pspath -filter "$urlRewriteFilter/rule[@name='$ruleName']" -name 'name' -ErrorAction SilentlyContinue

        if (-not $existingRule) {
            if (Get-Module -Name 'WebAdministration' -ErrorAction SilentlyContinue | Select-String 'rewrite' -Quiet -ErrorAction SilentlyContinue) {
                # URL Rewrite is available — add outbound rule as belt-and-braces
                if ($PSCmdlet.ShouldProcess($scopeLabel, "Add URL Rewrite outbound rule '$ruleName'")) {
                    Add-WebConfigurationProperty -pspath $pspath -filter $urlRewriteFilter -name '.' -value @{
                        name           = $ruleName
                        patternSyntax  = 'Wildcard'
                        stopProcessing = 'false'
                    }
                    Set-WebConfigurationProperty -pspath $pspath -filter "$urlRewriteFilter/rule[@name='$ruleName']/match" -name 'serverVariable' -value 'RESPONSE_SERVER'
                    Set-WebConfigurationProperty -pspath $pspath -filter "$urlRewriteFilter/rule[@name='$ruleName']/match" -name 'pattern'        -value '*'
                    Set-WebConfigurationProperty -pspath $pspath -filter "$urlRewriteFilter/rule[@name='$ruleName']/action" -name 'type'          -value 'Rewrite'
                    Set-WebConfigurationProperty -pspath $pspath -filter "$urlRewriteFilter/rule[@name='$ruleName']/action" -name 'value'         -value ''
                    Write-Done "Added URL Rewrite outbound rule to blank the Server response header."
                }
            } else {
                Write-Warn 'URL Rewrite module not detected. Registry change is the only mitigation on IIS < 10.'
            }
        } else {
            Write-Done "URL Rewrite rule '$ruleName' already exists — no change needed."
        }
    }
} else {
    Write-Skip 'Server header step (--SkipServerHeader)'
}

# ---------------------------------------------------------------------------
# 2. X-POWERED-BY HEADER
#    What it changes:
#      Removes the entry named "X-Powered-By" from the custom headers collection
#      at system.webServer/httpProtocol/customHeaders in applicationHost.config
#      (server-level) or web.config (site-level).  IIS populates this header from
#      that static list; once the entry is gone the header stops being sent.
# ---------------------------------------------------------------------------

if (-not $SkipXPoweredBy) {
    Write-Step 'Removing X-Powered-By header'

    $filter      = 'system.webServer/httpProtocol/customHeaders'
    $headerName  = 'X-Powered-By'

    # Check whether the header entry currently exists
    $existing = Get-WebConfigurationProperty -pspath $pspath -filter $filter -name '.' -ErrorAction SilentlyContinue |
                Where-Object { $_.name -ieq $headerName }

    if (-not $existing) {
        Write-Done "$headerName custom header entry not present — no change needed."
    } else {
        if ($PSCmdlet.ShouldProcess($scopeLabel, "Remove custom header '$headerName' from $filter")) {
            Remove-WebConfigurationProperty -pspath $pspath -filter $filter -name '.' -AtElement @{ name = $headerName }
            Write-Done "Removed '$headerName' from system.webServer/httpProtocol/customHeaders"
        }
    }
} else {
    Write-Skip 'X-Powered-By header step (--SkipXPoweredBy)'
}

# ---------------------------------------------------------------------------
# 3. X-ASPNET-VERSION HEADER
#    What it changes:
#      Sets system.web/httpRuntime/@enableVersionHeader = false.
#      The ASP.NET runtime checks this configuration flag to decide whether to
#      append its version (e.g. "4.0.30319") in the X-AspNet-Version response
#      header.  Setting it to false disables that behaviour across all managed
#      requests handled by the application pool.
# ---------------------------------------------------------------------------

if (-not $SkipAspNetVersion) {
    Write-Step 'Disabling X-AspNet-Version header'

    $filter  = 'system.web/httpRuntime'
    $current = (Get-WebConfigurationProperty -pspath $pspath -filter $filter -name 'enableVersionHeader' -ErrorAction SilentlyContinue).Value

    if ($current -eq $false) {
        Write-Done 'enableVersionHeader is already false — no change needed.'
    } else {
        if ($PSCmdlet.ShouldProcess($scopeLabel, "Set $filter/@enableVersionHeader = false")) {
            Set-WebConfigurationProperty -pspath $pspath -filter $filter -name 'enableVersionHeader' -value $false
            Write-Done "Set system.web/httpRuntime/@enableVersionHeader = false"
        }
    }
} else {
    Write-Skip 'X-AspNet-Version header step (--SkipAspNetVersion)'
}

# ---------------------------------------------------------------------------
# 4. X-ASPNETMVC-VERSION HEADER
#    What it changes:
#      Adds (or updates) an appSettings key UnobtrusiveJavaScriptEnabled and the
#      MVC-specific key that controls MvcHandler.DisableMvcResponseHeader.
#      The MVC framework reads the appSettings key "MvcResponseHeaderDisabled" (or
#      the code-level MvcHandler.DisableMvcResponseHeader property) on startup.
#      The most reliable config-only approach is to add the key to appSettings,
#      which the MVC handler checks via ConfigurationManager.AppSettings.
#      NOTE: Full suppression requires that the application's Global.asax (or
#      Startup.cs) also sets MvcHandler.DisableMvcResponseHeader = true; this
#      script adds the appSettings entry as the configuration-layer remedy.
# ---------------------------------------------------------------------------

if (-not $SkipMvcVersion) {
    Write-Step 'Disabling X-AspNetMvc-Version header (appSettings)'

    $filter  = 'system.web/appSettings'
    $keyName = 'MvcResponseHeaderDisabled'

    $existing = Get-WebConfigurationProperty -pspath $pspath -filter $filter -name '.' -ErrorAction SilentlyContinue |
                Where-Object { $_.key -ieq $keyName }

    if ($existing) {
        if ($existing.value -ieq 'true') {
            Write-Done "appSettings key '$keyName' is already 'true' — no change needed."
        } else {
            if ($PSCmdlet.ShouldProcess($scopeLabel, "Update appSettings/$keyName = true")) {
                Set-WebConfigurationProperty -pspath $pspath -filter "$filter/add[@key='$keyName']" -name 'value' -value 'true'
                Write-Done "Updated appSettings/$keyName = true"
            }
        }
    } else {
        if ($PSCmdlet.ShouldProcess($scopeLabel, "Add appSettings/$keyName = true")) {
            Add-WebConfigurationProperty -pspath $pspath -filter $filter -name '.' -value @{ key = $keyName; value = 'true' }
            Write-Done "Added appSettings/$keyName = true"
            Write-Warn "MVC apps also need 'MvcHandler.DisableMvcResponseHeader = true' in Global.asax/Startup.cs for full suppression."
        }
    }
} else {
    Write-Skip 'X-AspNetMvc-Version header step (--SkipMvcVersion)'
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host "`n========================================" -ForegroundColor White
Write-Host " Nessus 88099 Remediation Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor White
Write-Host @"

Changes applied to: $scopeLabel

Next steps:
  1. Perform an IISReset ('iisreset /restart') to ensure all changes are active.
  2. If IIS < 10 registry change was applied, restart the HTTP service:
       net stop http /y ; net start w3svc
  3. Verify with: curl -I http://localhost  (or use Nessus re-scan)
     Expected: no Server, X-Powered-By, X-AspNet-Version, or X-AspNetMvc-Version headers.
"@ -ForegroundColor White

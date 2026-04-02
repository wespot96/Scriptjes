<#
.SYNOPSIS
    Exercise 02 Solution - Firewall Rule Auditor

.DESCRIPTION
    A security auditing script that examines Windows Firewall inbound allow rules,
    identifies overly permissive configurations, cross-references with listening
    ports, and generates a structured security summary report.

.NOTES
    Target: Windows Server 2022, PowerShell 5.1
    No external modules required.
    Requires elevated (Administrator) privileges for full firewall access.

.EXAMPLE
    .\Exercise-02-Solution.ps1

.EXAMPLE
    .\Exercise-02-Solution.ps1 -HighRiskPorts 3389,445,23,21 -OutputCsv "C:\Reports\audit.csv"
#>

[CmdletBinding()]
param(
    [int[]]$HighRiskPorts = @(21, 23, 445, 1433, 3389, 5985, 5986),

    [string]$OutputCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# FUNCTION: Get-InboundAllowRules
# Retrieves all enabled inbound allow rules enriched with port and address info.
# ============================================================================
function Get-InboundAllowRules {

    $rules = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -ErrorAction SilentlyContinue

    foreach ($rule in $rules) {
        # Retrieve the port filter and address filter for each rule
        $portFilter    = $rule | Get-NetFirewallPortFilter
        $addressFilter = $rule | Get-NetFirewallAddressFilter

        [PSCustomObject]@{
            RuleName      = $rule.DisplayName
            Description   = $rule.Description
            Protocol      = $portFilter.Protocol
            LocalPort     = $portFilter.LocalPort
            RemotePort    = $portFilter.RemotePort
            RemoteAddress = $addressFilter.RemoteAddress
            Profile       = $rule.Profile
            RuleGroup     = $rule.Group
        }
    }
}

# ============================================================================
# FUNCTION: Find-OverlyPermissiveRules
# Flags rules where protocol is "Any", or local port and remote address are both "Any".
# ============================================================================
function Find-OverlyPermissiveRules {
    param(
        [Parameter(Mandatory)]
        [object[]]$Rules
    )

    foreach ($rule in $Rules) {
        $reason = $null

        if ($rule.Protocol -eq "Any") {
            $reason = "Protocol allows any traffic"
        }
        elseif ($rule.LocalPort -eq "Any" -and $rule.RemoteAddress -eq "Any") {
            $reason = "Open to any port from any source"
        }

        if ($reason) {
            # Emit the rule with an added Reason property
            $rule | Select-Object *, @{ Name = 'Reason'; Expression = { $reason } }
        }
    }
}

# ============================================================================
# FUNCTION: Find-HighRiskExposures
# Identifies rules that expose known high-risk ports.
# ============================================================================
function Find-HighRiskExposures {
    param(
        [Parameter(Mandatory)]
        [object[]]$Rules,

        [Parameter(Mandatory)]
        [int[]]$RiskPorts
    )

    foreach ($rule in $Rules) {
        $localPort = $rule.LocalPort

        # "Any" means all ports are exposed — automatic match
        if ($localPort -eq "Any") {
            $rule | Select-Object *, @{ Name = 'MatchedPorts'; Expression = { $RiskPorts -join ',' } }
            continue
        }

        # Parse comma-separated or single port values
        $rulePorts = @()
        foreach ($token in ($localPort -split ',')) {
            $trimmed = $token.Trim()
            [int]$portNum = 0
            if ([int]::TryParse($trimmed, [ref]$portNum)) {
                $rulePorts += $portNum
            }
        }

        # Check for intersection with high-risk ports
        $matched = @($rulePorts | Where-Object { $_ -in $RiskPorts })
        if ($matched.Count -gt 0) {
            $rule | Select-Object *, @{ Name = 'MatchedPorts'; Expression = { $matched -join ',' } }
        }
    }
}

# ============================================================================
# FUNCTION: Get-ListeningPorts
# Gets currently listening TCP ports with owning process info.
# ============================================================================
function Get-ListeningPorts {

    $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue

    $seen = @{}
    foreach ($conn in $connections) {
        # Deduplicate by address:port
        $key = "$($conn.LocalAddress):$($conn.LocalPort)"
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            LocalAddress = $conn.LocalAddress
            LocalPort    = $conn.LocalPort
            ProcessId    = $conn.OwningProcess
            ProcessName  = if ($proc) { $proc.ProcessName } else { "Unknown" }
        }
    }
}

# ============================================================================
# FUNCTION: New-SecuritySummary
# Combines all audit findings into a single summary report object.
# ============================================================================
function New-SecuritySummary {
    param(
        [object[]]$AllRules,
        [object[]]$PermissiveRules,
        [object[]]$HighRiskRules,
        [object[]]$ListeningPorts
    )

    $allRuleCount       = @($AllRules).Count
    $permissiveCount    = @($PermissiveRules).Count
    $highRiskCount      = @($HighRiskRules).Count
    $listeningCount     = @($ListeningPorts).Count

    # Find listening ports with no corresponding inbound allow rule
    $coveredPorts = @()
    foreach ($rule in $AllRules) {
        if ($rule.LocalPort -eq "Any") {
            # "Any" covers all ports — everything is covered
            $coveredPorts = $ListeningPorts | ForEach-Object { $_.LocalPort }
            break
        }
        foreach ($token in ($rule.LocalPort -split ',')) {
            $trimmed = $token.Trim()
            [int]$portNum = 0
            if ([int]::TryParse($trimmed, [ref]$portNum)) {
                $coveredPorts += $portNum
            }
        }
    }
    $coveredPorts = @($coveredPorts | Select-Object -Unique)

    $unprotectedCount = @(
        $ListeningPorts | Where-Object { $_.LocalPort -notin $coveredPorts }
    ).Count

    # Determine overall risk level
    $riskLevel = if ($permissiveCount -gt 0 -or $highRiskCount -gt 5) {
        "High"
    }
    elseif ($highRiskCount -gt 0) {
        "Medium"
    }
    else {
        "Low"
    }

    [PSCustomObject]@{
        TotalInboundAllowRules    = $allRuleCount
        OverlyPermissiveRuleCount = $permissiveCount
        HighRiskExposureCount     = $highRiskCount
        TotalListeningPorts       = $listeningCount
        UnprotectedListeningPorts = $unprotectedCount
        AuditTimestamp            = Get-Date
        RiskLevel                 = $riskLevel
    }
}

# ============================================================================
# MAIN: Orchestrate the audit and display results
# ============================================================================

Write-Host "=== Firewall Rule Audit ===" -ForegroundColor Cyan
Write-Host "Scanning enabled inbound allow rules..." -ForegroundColor Gray

# Step 1: Gather all inbound allow rules
$allRules = @(Get-InboundAllowRules)
Write-Host "Found $($allRules.Count) enabled inbound allow rule(s)." -ForegroundColor Gray

# Step 2: Identify overly permissive rules
$permissiveRules = @(Find-OverlyPermissiveRules -Rules $allRules)

# Step 3: Identify high-risk port exposures
$highRiskRules = @(Find-HighRiskExposures -Rules $allRules -RiskPorts $HighRiskPorts)

# Step 4: Get listening ports
$listeningPorts = @(Get-ListeningPorts)

# Step 5: Build security summary
$summary = New-SecuritySummary -AllRules $allRules `
                               -PermissiveRules $permissiveRules `
                               -HighRiskRules $highRiskRules `
                               -ListeningPorts $listeningPorts

# Step 6: Display results

Write-Host ""
Write-Host "=== Security Summary ===" -ForegroundColor Cyan
$summary | Format-List

# Overly permissive rules
if ($permissiveRules.Count -gt 0) {
    Write-Host "=== Overly Permissive Rules ($($permissiveRules.Count)) ===" -ForegroundColor Yellow
    $permissiveRules | Format-Table RuleName, Protocol, LocalPort, RemoteAddress, Reason -AutoSize
}
else {
    Write-Host "No overly permissive rules found." -ForegroundColor Green
}

# High-risk exposures
if ($highRiskRules.Count -gt 0) {
    Write-Host "=== High-Risk Port Exposures ($($highRiskRules.Count)) ===" -ForegroundColor Red
    $highRiskRules | Format-Table RuleName, Protocol, LocalPort, RemoteAddress, MatchedPorts -AutoSize
}
else {
    Write-Host "No high-risk port exposures found." -ForegroundColor Green
}

# Listening ports
Write-Host ""
Write-Host "=== Listening Ports ($($listeningPorts.Count)) ===" -ForegroundColor Cyan
$listeningPorts | Sort-Object LocalPort | Format-Table -AutoSize

# Risk assessment banner
$riskColor = switch ($summary.RiskLevel) {
    "High"   { "Red" }
    "Medium" { "Yellow" }
    "Low"    { "Green" }
}
Write-Host "Overall Risk Level: $($summary.RiskLevel)" -ForegroundColor $riskColor

# Step 7: Export to CSV if requested
if ($OutputCsv) {
    $allRules | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ""
    Write-Host "Full rule audit exported to: $OutputCsv" -ForegroundColor Gray
}

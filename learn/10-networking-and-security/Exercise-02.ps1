<#
.SYNOPSIS
    Exercise 02 - Firewall Rule Auditor

.DESCRIPTION
    Build a security auditing script that examines Windows Firewall inbound allow
    rules, identifies overly permissive configurations, cross-references with
    listening ports, and generates a structured security summary report.

    Skills practiced:
      - Querying firewall rules with Get-NetFirewallRule
      - Filtering by port with Get-NetFirewallPortFilter
      - Identifying listening ports with Get-NetTCPConnection
      - Building structured reports with PSCustomObject
      - Security analysis and risk assessment logic

.NOTES
    Target: Windows Server 2022, PowerShell 5.1
    No external modules required.
    Requires elevated (Administrator) privileges for full firewall access.

.EXAMPLE
    .\Exercise-02.ps1

.EXAMPLE
    .\Exercise-02.ps1 -HighRiskPorts 3389,445,23,21 -OutputCsv "C:\Reports\firewall-audit.csv"
#>

[CmdletBinding()]
param(
    # Ports considered high-risk when exposed via inbound allow rules
    [int[]]$HighRiskPorts = @(21, 23, 445, 1433, 3389, 5985, 5986),

    # Optional path to export the audit report as CSV
    [string]$OutputCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# FUNCTION: Get-InboundAllowRules
# Retrieves all enabled inbound firewall rules with Action = Allow.
# Returns rule objects with their associated port filters.
# ============================================================================
function Get-InboundAllowRules {

    # TODO 1: Get all enabled inbound allow rules and enrich with port info.
    #         1. Use Get-NetFirewallRule with filters:
    #              -Direction Inbound -Action Allow -Enabled True
    #         2. For each rule, get its port filter:
    #              $portFilter = $rule | Get-NetFirewallPortFilter
    #         3. Output a [PSCustomObject] per rule with these properties:
    #              RuleName     = $rule.DisplayName
    #              Description  = $rule.Description
    #              Protocol     = $portFilter.Protocol
    #              LocalPort    = $portFilter.LocalPort
    #              RemotePort   = $portFilter.RemotePort
    #              RemoteAddress = ($rule | Get-NetFirewallAddressFilter).RemoteAddress
    #              Profile      = $rule.Profile
    #              RuleGroup    = $rule.Group
    #
    # Hint: Pipe Get-NetFirewallRule output through ForEach-Object to build each object.

}

# ============================================================================
# FUNCTION: Find-OverlyPermissiveRules
# Identifies rules that are overly permissive (any source, any port patterns).
# A rule is "overly permissive" if:
#   - LocalPort is "Any" AND RemoteAddress is "Any", OR
#   - Protocol is "Any"
# ============================================================================
function Find-OverlyPermissiveRules {
    param(
        [Parameter(Mandatory)]
        [object[]]$Rules
    )

    # TODO 2: Filter $Rules to find overly permissive entries.
    #         - A rule is permissive if Protocol -eq "Any"
    #           OR (LocalPort -eq "Any" AND RemoteAddress -eq "Any")
    #         - Return matching rules with an added property:
    #              Reason = <why it's flagged, e.g. "Protocol allows any traffic">
    #
    # Hint: Use Where-Object with compound conditions.
    #       Add the Reason property with Select-Object @{Name=...;Expression=...}
    #       or by creating new PSCustomObjects.

}

# ============================================================================
# FUNCTION: Find-HighRiskExposures
# Cross-references firewall rules against the $HighRiskPorts list.
# Returns rules that expose known high-risk ports.
# ============================================================================
function Find-HighRiskExposures {
    param(
        [Parameter(Mandatory)]
        [object[]]$Rules,

        [Parameter(Mandatory)]
        [int[]]$RiskPorts
    )

    # TODO 3: Filter $Rules to find those that expose any port in $RiskPorts.
    #         - Check if LocalPort matches any port in $RiskPorts.
    #         - Handle the case where LocalPort may be "Any" (matches all risk ports).
    #         - Handle comma-separated port values (e.g., "80,443").
    #         - Return matching rules.
    #
    # Hint: For each rule, parse LocalPort into actual port numbers
    #       and check for intersection with $RiskPorts.
    #       LocalPort "Any" automatically qualifies as a match.

}

# ============================================================================
# FUNCTION: Get-ListeningPorts
# Gets currently listening TCP ports using Get-NetTCPConnection.
# Returns structured objects with port, process, and process name.
# ============================================================================
function Get-ListeningPorts {

    # TODO 4: Get all TCP connections in the Listen state and enrich with process info.
    #         1. Use Get-NetTCPConnection -State Listen
    #         2. For each connection, look up the owning process:
    #              $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    #         3. Output a [PSCustomObject] with:
    #              LocalAddress = $conn.LocalAddress
    #              LocalPort    = $conn.LocalPort
    #              ProcessId    = $conn.OwningProcess
    #              ProcessName  = $proc.ProcessName (or "Unknown")
    #         4. Sort results by LocalPort and return unique entries.
    #
    # Hint: Pipe Get-NetTCPConnection through ForEach-Object.

}

# ============================================================================
# FUNCTION: New-SecuritySummary
# Generates a summary report combining all audit findings.
# ============================================================================
function New-SecuritySummary {
    param(
        [object[]]$AllRules,
        [object[]]$PermissiveRules,
        [object[]]$HighRiskRules,
        [object[]]$ListeningPorts
    )

    # TODO 5: Build and return a [PSCustomObject] summary report with:
    #         TotalInboundAllowRules     = count of $AllRules
    #         OverlyPermissiveRuleCount  = count of $PermissiveRules
    #         HighRiskExposureCount      = count of $HighRiskRules
    #         TotalListeningPorts        = count of $ListeningPorts
    #         UnprotectedListeningPorts  = count of listening ports that have
    #                                      NO corresponding firewall allow rule
    #         AuditTimestamp             = (Get-Date)
    #         RiskLevel                  = "High" if PermissiveRules > 0 or HighRiskRules > 5
    #                                      "Medium" if HighRiskRules > 0
    #                                      "Low" otherwise
    #
    # Hint: To find unprotected ports, compare ListeningPorts against AllRules
    #       where LocalPort matches.

}

# ============================================================================
# MAIN: Run the audit and display results
# ============================================================================

# TODO 6: Orchestrate the audit by calling each function and displaying results.
#         1. Call Get-InboundAllowRules -> $allRules
#         2. Call Find-OverlyPermissiveRules -Rules $allRules -> $permissiveRules
#         3. Call Find-HighRiskExposures -Rules $allRules -RiskPorts $HighRiskPorts -> $highRiskRules
#         4. Call Get-ListeningPorts -> $listeningPorts
#         5. Call New-SecuritySummary with all results -> $summary
#         6. Display results using Write-Host or Format-Table:
#              - Print the summary report
#              - List overly permissive rules (if any)
#              - List high-risk exposures (if any)
#              - List listening ports
#         7. If $OutputCsv is provided, export $allRules to CSV.
#
# Hint: Use section headers like "=== Security Summary ===" for readability.

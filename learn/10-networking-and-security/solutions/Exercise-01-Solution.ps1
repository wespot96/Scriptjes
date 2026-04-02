<#
.SYNOPSIS
    Exercise 01 Solution - Network Connectivity Tester

.DESCRIPTION
    A reusable network connectivity testing tool inspired by ConnectionTest.ps1.
    Accepts host:port pairs, resolves DNS via [System.Net.Dns], tests TCP
    connectivity with [System.Net.Sockets.TcpClient] using async connect with
    timeout, and outputs structured PSCustomObject results.

.NOTES
    Target: Windows Server 2022, PowerShell 5.1
    No external modules required.

.EXAMPLE
    .\Exercise-01-Solution.ps1 -Targets "google.com:443","1.1.1.1:53" -TimeoutMs 3000

.EXAMPLE
    .\Exercise-01-Solution.ps1 -Targets "myserver:3389","dbhost:1433" | Export-Csv results.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$Targets,

    [int]$TimeoutMs = 5000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# FUNCTION: Resolve-HostAddress
# Resolves a hostname to its IP addresses using [System.Net.Dns].
# ============================================================================
function Resolve-HostAddress {
    param(
        [Parameter(Mandatory)]
        [string]$HostName
    )

    try {
        # GetHostAddresses returns all A/AAAA records for the host
        [System.Net.Dns]::GetHostAddresses($HostName) |
            Where-Object {
                $_.AddressFamily -in @(
                    [System.Net.Sockets.AddressFamily]::InterNetwork,     # IPv4
                    [System.Net.Sockets.AddressFamily]::InterNetworkV6    # IPv6
                )
            } |
            ForEach-Object { $_.ToString() } |
            Select-Object -Unique
    }
    catch {
        # DNS resolution failed — return empty array so callers can check .Count
        @()
    }
}

# ============================================================================
# FUNCTION: Test-TcpPort
# Tests TCP connectivity with async connect and configurable timeout.
# ============================================================================
function Test-TcpPort {
    param(
        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [int]$Timeout
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        # BeginConnect starts the TCP handshake asynchronously
        $async = $client.BeginConnect($HostName, $Port, $null, $null)

        # Wait up to $Timeout ms for the handshake to complete
        $waited = $async.AsyncWaitHandle.WaitOne($Timeout, $false)

        if (-not $waited) {
            return @{ Success = $false; Error = "TCP timeout after $Timeout ms" }
        }

        # EndConnect throws if the connection failed (e.g., refused)
        $client.EndConnect($async)
        return @{ Success = $true; Error = "" }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
    finally {
        $client.Dispose()
    }
}

# ============================================================================
# FUNCTION: Parse-Target
# Splits "host:port" into a hashtable and validates the port number.
# ============================================================================
function Parse-Target {
    param(
        [Parameter(Mandatory)]
        [string]$TargetString
    )

    $parts = $TargetString.Split(':', 2)
    if ($parts.Count -ne 2) {
        throw "Invalid target format '$TargetString'. Expected host:port (e.g., google.com:443)."
    }

    $hostPart = $parts[0].Trim()
    $portText = $parts[1].Trim()

    if ([string]::IsNullOrWhiteSpace($hostPart)) {
        throw "Host cannot be empty in target '$TargetString'."
    }

    [int]$portValue = 0
    if (-not [int]::TryParse($portText, [ref]$portValue) -or $portValue -lt 1 -or $portValue -gt 65535) {
        throw "Invalid port '$portText' in target '$TargetString'. Must be 1-65535."
    }

    @{ Host = $hostPart; Port = $portValue }
}

# ============================================================================
# MAIN: Process targets, run DNS + TCP tests, output structured results
# ============================================================================

$results = foreach ($target in $Targets) {
    try {
        $parsed = Parse-Target -TargetString $target
    }
    catch {
        Write-Warning "Skipping invalid target '$target': $($_.Exception.Message)"
        continue
    }

    $hostName = $parsed.Host
    $port     = $parsed.Port

    # Step 1: DNS resolution
    $resolvedIPs = @(Resolve-HostAddress -HostName $hostName)
    $dnsResolved = $resolvedIPs.Count -gt 0

    # Step 2: TCP connectivity test
    $tcpResult   = Test-TcpPort -HostName $hostName -Port $port -Timeout $TimeoutMs
    $tcpSucceeded = [bool]$tcpResult.Success

    # Step 3: Determine overall status
    $status = if ($dnsResolved -and $tcpSucceeded) { "Open" } else { "Failed" }

    # Step 4: Emit structured result to the pipeline
    [PSCustomObject]@{
        Timestamp    = Get-Date
        Host         = $hostName
        Port         = $port
        DnsResolved  = $dnsResolved
        ResolvedIPs  = ($resolvedIPs -join ';')
        TcpSucceeded = $tcpSucceeded
        Status       = $status
        Error        = $tcpResult.Error
    }
}

# Display the results as a table
$results | Format-Table -AutoSize

# Summary
$total   = @($results).Count
$open    = @($results | Where-Object { $_.Status -eq "Open" }).Count
$failed  = $total - $open

Write-Host ""
Write-Host "=== Connectivity Test Summary ===" -ForegroundColor Cyan
Write-Host "Total tests : $total"
Write-Host "Succeeded   : $open"  -ForegroundColor Green
Write-Host "Failed      : $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

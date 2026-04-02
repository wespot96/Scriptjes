<#
.SYNOPSIS
    Exercise 01 - Network Connectivity Tester

.DESCRIPTION
    Build a reusable network connectivity testing tool inspired by ConnectionTest.ps1.
    The script accepts a list of host:port pairs, resolves DNS, tests TCP connectivity
    with a configurable timeout, and outputs structured PSCustomObject results.

    Skills practiced:
      - DNS resolution with [System.Net.Dns]
      - TCP socket testing with [System.Net.Sockets.TcpClient] and async connect
      - Structured output with PSCustomObject
      - Parameter validation and error handling

.NOTES
    Target: Windows Server 2022, PowerShell 5.1
    No external modules required.

.EXAMPLE
    .\Exercise-01.ps1 -Targets "google.com:443","1.1.1.1:53" -TimeoutMs 3000
#>

[CmdletBinding()]
param(
    # Array of host:port strings, e.g. "google.com:443", "10.0.0.1:3389"
    [Parameter(Mandatory)]
    [string[]]$Targets,

    # TCP connection timeout in milliseconds (default 5000)
    [int]$TimeoutMs = 5000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# FUNCTION: Resolve-HostAddress
# Resolves a hostname to its IP addresses using [System.Net.Dns].
# Returns an array of IP address strings, or an empty array on failure.
# ============================================================================
function Resolve-HostAddress {
    param(
        [Parameter(Mandatory)]
        [string]$HostName
    )

    # TODO 1: Use [System.Net.Dns]::GetHostAddresses($HostName) to resolve the host.
    #         - Filter results to only IPv4 (InterNetwork) and IPv6 (InterNetworkV6).
    #         - Convert each address to a string with .ToString().
    #         - Return unique addresses using Select-Object -Unique.
    #         - Wrap in try/catch; return @() on failure.
    #
    # Hint: See ConnectionTest.ps1's Resolve-HostIPs function for the pattern.
    # Example output: @("142.250.80.46")

}

# ============================================================================
# FUNCTION: Test-TcpPort
# Tests TCP connectivity to a host:port with a timeout using TcpClient.
# Returns a hashtable with keys: Success (bool) and Error (string).
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

    # TODO 2: Create a [System.Net.Sockets.TcpClient] and use the async connect pattern:
    #         1. $client = [System.Net.Sockets.TcpClient]::new()
    #         2. $async  = $client.BeginConnect($HostName, $Port, $null, $null)
    #         3. $waited = $async.AsyncWaitHandle.WaitOne($Timeout, $false)
    #         4. If $waited is $false, return @{ Success = $false; Error = "Timeout" }
    #         5. Call $client.EndConnect($async) to complete the connection.
    #         6. Return @{ Success = $true; Error = "" }
    #         - Use try/catch to handle connection errors; return the exception message.
    #         - Always call $client.Dispose() in a finally block.
    #
    # Hint: See ConnectionTest.ps1's Test-TcpPort function.

}

# ============================================================================
# FUNCTION: Parse-Target
# Parses a "host:port" string into a hashtable with Host and Port keys.
# Validates the port is between 1 and 65535.
# ============================================================================
function Parse-Target {
    param(
        [Parameter(Mandatory)]
        [string]$TargetString
    )

    # TODO 3: Split $TargetString on ':' into host and port parts.
    #         - Validate exactly 2 parts exist; throw if not.
    #         - Parse the port as [int]; throw if not a valid number 1-65535.
    #         - Return @{ Host = <host>; Port = <port> }
    #
    # Example: "google.com:443" -> @{ Host = "google.com"; Port = 443 }

}

# ============================================================================
# MAIN: Process each target, run DNS + TCP tests, output results
# ============================================================================

# TODO 4: Loop through each entry in $Targets:
#         1. Call Parse-Target to extract host and port.
#         2. Call Resolve-HostAddress to get resolved IPs.
#         3. Determine $dnsResolved = ($resolvedIPs.Count -gt 0)
#         4. Call Test-TcpPort with the host, port, and $TimeoutMs.
#         5. Determine overall status: "Open" if DNS and TCP both succeeded, else "Failed".
#         6. Output a [PSCustomObject] with these properties:
#              Timestamp    = (Get-Date)
#              Host         = <host>
#              Port         = <port>
#              DnsResolved  = <bool>
#              ResolvedIPs  = <IPs joined with ';'>
#              TcpSucceeded = <bool>
#              Status       = <"Open" or "Failed">
#              Error        = <error message or "">
#
# Hint: Use foreach ($target in $Targets) { ... } and emit objects to the pipeline.

# TODO 5 (Bonus): After testing all targets, write a summary to the console:
#         - Total tests run
#         - Number of successful / failed tests
#         - Use Write-Host or Write-Output for the summary.

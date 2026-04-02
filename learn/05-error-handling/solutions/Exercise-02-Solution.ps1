<#
.SYNOPSIS
    Exercise 02 Solution - Service Monitor with Error Handling

.DESCRIPTION
    Complete solution demonstrating advanced error handling for a service
    monitoring function.  Uses -ErrorAction, -ErrorVariable, typed catch
    blocks, retry logic, and structured result objects.

    Inspired by the try/catch/finally patterns in ConnectionTest.ps1.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module  : 05-error-handling
    Exercise: 02 - Solution
    Author  : PowerShell Learning Path

.EXAMPLE
    .\Exercise-02-Solution.ps1
    Runs the service monitor against localhost with the built-in service list
    and displays results.
#>

Set-StrictMode -Version 2.0

# ── Function: Test-ServiceStatus ─────────────────────────────────────────────

function Test-ServiceStatus {
    <#
    .SYNOPSIS
        Checks service status on one or more computers with full error handling.
    .OUTPUTS
        [PSCustomObject] per computer/service combination.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$ServiceName,

        [ValidateRange(1, 10)]
        [int]$MaxRetries = 2
    )

    # TODO 2: Scope-level preference converts non-terminating errors.
    $ErrorActionPreference = 'Stop'

    # TODO 3: Loop through each computer.
    foreach ($Computer in $ComputerName) {

        # Verify connectivity before querying services.
        $isReachable = $false
        try {
            # Test-Connection with -Count 1 for a quick ping check.
            # -Quiet returns $true/$false (PS 5.1 compatible).
            $isReachable = Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction Stop
        }
        catch {
            Write-Warning "Connectivity test failed for ${Computer}: $($_.Exception.Message)"
        }

        if (-not $isReachable) {
            # Emit a ConnectionFailed result for every requested service.
            foreach ($Service in $ServiceName) {
                [PSCustomObject]@{
                    ComputerName = $Computer
                    ServiceName  = $Service
                    Status       = $null
                    StartType    = $null
                    CheckResult  = 'ConnectionFailed'
                    ErrorMessage = "Unable to reach $Computer."
                    Timestamp    = Get-Date
                }
            }
            Write-Warning "Skipping all services on $Computer - host unreachable."
            continue
        }

        # TODO 4: Check each service on the reachable computer.
        foreach ($Service in $ServiceName) {

            $attempt   = 0
            $succeeded = $false

            while ($attempt -lt $MaxRetries -and -not $succeeded) {
                $attempt++
                $svcError = $null

                try {
                    $svc = Get-Service -ComputerName $Computer -Name $Service `
                                       -ErrorAction Stop -ErrorVariable svcError

                    # Build success result.
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        ServiceName  = $svc.Name
                        Status       = $svc.Status.ToString()
                        StartType    = $svc.StartType.ToString()
                        CheckResult  = 'Success'
                        ErrorMessage = $null
                        Timestamp    = Get-Date
                    }
                    $succeeded = $true
                }
                catch [System.InvalidOperationException] {
                    # Service not found on the target computer.
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        ServiceName  = $Service
                        Status       = $null
                        StartType    = $null
                        CheckResult  = 'ServiceNotFound'
                        ErrorMessage = $_.Exception.Message
                        Timestamp    = Get-Date
                    }
                    $succeeded = $true   # No point retrying a missing service.
                }
                catch [System.UnauthorizedAccessException] {
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        ServiceName  = $Service
                        Status       = $null
                        StartType    = $null
                        CheckResult  = 'AccessDenied'
                        ErrorMessage = $_.Exception.Message
                        Timestamp    = Get-Date
                    }
                    $succeeded = $true   # Retry won't fix permissions.
                }
                catch {
                    if ($attempt -lt $MaxRetries) {
                        Write-Warning ("Attempt $attempt failed for $Service on " +
                            "${Computer}: $($_.Exception.Message) - retrying...")
                        Start-Sleep -Seconds 1
                    }
                    else {
                        # Final attempt failed; emit error result.
                        [PSCustomObject]@{
                            ComputerName = $Computer
                            ServiceName  = $Service
                            Status       = $null
                            StartType    = $null
                            CheckResult  = 'Error'
                            ErrorMessage = $_.Exception.Message
                            Timestamp    = Get-Date
                        }
                    }
                }
                finally {
                    Write-Verbose ("[$Computer] $Service - attempt $attempt - " +
                        "$(if ($succeeded) { 'done' } else { 'pending' })")
                }
            }
        }
    }
}

# ── Test data ────────────────────────────────────────────────────────────────

$Computers = @(
    "localhost"
    "FAKE-SERVER-01"
    $env:COMPUTERNAME
)

$Services = @(
    "W32Time"
    "Spooler"
    "FakeServiceXYZ123"
    "WinRM"
)

# ── Execute ──────────────────────────────────────────────────────────────────

# TODO 5: Call the function with -Verbose to see diagnostic output.
$AllResults = Test-ServiceStatus -ComputerName $Computers `
                                 -ServiceName  $Services `
                                 -Verbose

# ── Summary report ───────────────────────────────────────────────────────────

# TODO 6: Display full table and grouped counts.
$AllResults | Format-Table -Property ComputerName, ServiceName, Status,
                                     StartType, CheckResult, ErrorMessage -AutoSize

Write-Host "`n── Summary ────────────────────────────────────────"

$grouped = $AllResults | Group-Object -Property CheckResult
foreach ($group in $grouped) {
    Write-Host ("{0,-20}: {1}" -f $group.Name, $group.Count)
}

$failedComputers = $AllResults |
    Where-Object { $_.CheckResult -eq 'ConnectionFailed' } |
    Select-Object -ExpandProperty ComputerName -Unique

if ($failedComputers) {
    Write-Host "`nUnreachable computers:"
    $failedComputers | ForEach-Object { Write-Host "  - $_" }
}

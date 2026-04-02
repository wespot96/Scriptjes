<#
.SYNOPSIS
    Exercise 02 - Service Monitor with Error Handling

.DESCRIPTION
    Practice advanced error handling by building a function that checks Windows
    services across one or more computers.  The function must handle connection
    failures, permission errors, and missing services differently, and return
    structured results for every check.

    Skills practised:
      - -ErrorAction and -ErrorVariable parameters
      - try / catch / finally with typed exceptions
      - Returning structured result objects (success + failure)
      - CmdletBinding and parameter validation
      - Patterns inspired by ConnectionTest.ps1

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module  : 05-error-handling
    Exercise: 02
    Author  : PowerShell Learning Path

.EXAMPLE
    .\Exercise-02.ps1
    Runs the service monitor against localhost with the built-in service list
    and displays results.
#>

Set-StrictMode -Version 2.0

# ── Function: Test-ServiceStatus ─────────────────────────────────────────────

# TODO 1: Define the function Test-ServiceStatus with [CmdletBinding()].
#         Parameters (all mandatory except MaxRetries):
#           [string[]]   $ComputerName  - one or more computer names
#           [string[]]   $ServiceName   - one or more service names to check
#           [int]        $MaxRetries    - retry attempts for transient failures (default 2)
#
# function Test-ServiceStatus {
#     [CmdletBinding()]
#     param( ... )

    # TODO 2: Set $ErrorActionPreference = 'Stop' inside the function so all
    #         errors become terminating within this scope.

    # TODO 3: Loop through each computer in $ComputerName.
    #         For each computer, first verify connectivity:
    #           - Use Test-Connection (or Test-WSMan) wrapped in try/catch.
    #           - On failure, output a result object for EVERY service on that
    #             computer with Status 'ConnectionFailed' and continue to the
    #             next computer.

    # TODO 4: For each service on a reachable computer:
    #   try {
    #       - Use Get-Service -ComputerName ... -Name ... -ErrorAction Stop
    #         to retrieve the service.
    #       - Also use -ErrorVariable to capture any error into a variable.
    #       - Build a result [PSCustomObject] with:
    #           ComputerName, ServiceName, Status (Running/Stopped/etc.),
    #           StartType, CheckResult ('Success'), ErrorMessage ($null),
    #           Timestamp
    #   }
    #   catch [System.InvalidOperationException] {
    #       - This typically means the service was not found.
    #       - Output a result with CheckResult 'ServiceNotFound'.
    #   }
    #   catch [System.UnauthorizedAccessException] {
    #       - Output a result with CheckResult 'AccessDenied'.
    #   }
    #   catch {
    #       - Handle any other error.
    #       - Implement retry logic: if the attempt count < $MaxRetries,
    #         wait 1 second and retry.  Otherwise output a result with
    #         CheckResult 'Error'.
    #       - Use Write-Warning to log each retry attempt.
    #   }
    #   finally {
    #       - Write-Verbose with the computer name, service name, and outcome.
    #   }

# }   # End of function


# ── Test data ────────────────────────────────────────────────────────────────
# These lists exercise the happy path and several error paths.
$Computers = @(
    "localhost"
    "FAKE-SERVER-01"          # Connection will fail
    $env:COMPUTERNAME         # Should succeed (same as localhost)
)

$Services = @(
    "W32Time"                 # Windows Time - usually exists
    "Spooler"                 # Print Spooler - usually exists
    "FakeServiceXYZ123"       # Does not exist - triggers ServiceNotFound
    "WinRM"                   # Windows Remote Management - usually exists
)


# ── Execute ──────────────────────────────────────────────────────────────────

# TODO 5: Call Test-ServiceStatus with -Verbose, passing $Computers and
#         $Services.  Store the results in $AllResults.


# ── Summary report ───────────────────────────────────────────────────────────

# TODO 6: Display results.
#   - Show the full $AllResults as a table.
#   - Group by CheckResult and display counts:
#       Success          : X
#       ServiceNotFound  : X
#       ConnectionFailed : X
#       AccessDenied     : X
#       Error            : X
#   - List any failed computers separately.


<#
.SYNOPSIS
    Exercise 02 - Test-ServiceHealth Function

.DESCRIPTION
    Build a pipeline-capable advanced function that checks whether Windows
    services are running and returns structured health-check objects. This
    exercise practises:

      - Pipeline input with [Parameter(ValueFromPipeline=$true)]
      - begin / process / end blocks
      - [CmdletBinding()] and Write-Verbose
      - Returning [PSCustomObject] per service
      - Error handling for missing or inaccessible services

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 04-Functions-and-Scripts
    Author : PowerShell Learning Series
#>

# ============================================================================
# TODO: Complete the Test-ServiceHealth function below.
#       Replace every "# TODO:" section with working code.
#       Refer to the README.md and ConnectionTest.ps1 for patterns.
# ============================================================================

function Test-ServiceHealth {
    # TODO: Add comment-based help inside the function.
    #       Include at minimum:
    #         .SYNOPSIS   - One-line summary
    #         .DESCRIPTION - Explain pipeline usage and return objects
    #         .PARAMETER ServiceName - Describe the parameter
    #         .EXAMPLE    - Show direct call and pipeline examples
    #         .INPUTS     - System.String
    #         .OUTPUTS    - PSCustomObject

    # TODO: Add [CmdletBinding()] attribute here.

    # TODO: Add a param block with the following parameter:
    #   -ServiceName [string] — must be:
    #     [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    #     Also add [ValidateNotNullOrEmpty()].

    # TODO: Add a begin block.
    #   - Initialise a counter variable ($checkedCount = 0).
    #   - Use Write-Verbose to log that the health check is starting.

    # TODO: Add a process block.
    #   For each $ServiceName received from the pipeline:
    #     1. Write-Verbose which service is being checked.
    #     2. Use Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    #        to attempt retrieval.
    #     3. If the service is found, output a [PSCustomObject] with:
    #          ServiceName  - the name you queried
    #          DisplayName  - the friendly display name
    #          Status       - Running / Stopped / etc.
    #          IsHealthy    - $true if Status is "Running", else $false
    #          CheckedAt    - current date/time (Get-Date)
    #     4. If the service is NOT found, output a [PSCustomObject] with:
    #          ServiceName  - the name you queried
    #          DisplayName  - "N/A"
    #          Status       - "NotFound"
    #          IsHealthy    - $false
    #          CheckedAt    - current date/time
    #     5. Increment $checkedCount.

    # TODO: Add an end block.
    #   - Use Write-Verbose to log the total number of services checked.
}

# ============================================================================
# Test your function — uncomment the lines below after completing the TODOs.
# ============================================================================
# Test-ServiceHealth -ServiceName "wuauserv"
# Test-ServiceHealth -ServiceName "wuauserv" -Verbose
# "wuauserv", "Spooler", "FakeService123" | Test-ServiceHealth -Verbose
# "wuauserv", "Spooler" | Test-ServiceHealth | Format-Table -AutoSize

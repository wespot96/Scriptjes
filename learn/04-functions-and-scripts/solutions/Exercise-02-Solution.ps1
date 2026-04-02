<#
.SYNOPSIS
    Solution for Exercise 02 - Test-ServiceHealth Function

.DESCRIPTION
    Complete, working implementation of the Test-ServiceHealth function.
    Demonstrates pipeline input with begin/process/end blocks, CmdletBinding,
    comment-based help, and structured PSCustomObject output.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 04-Functions-and-Scripts
    Author : PowerShell Learning Series
#>

function Test-ServiceHealth {
    <#
    .SYNOPSIS
    Checks whether Windows services are running and returns health-check objects.

    .DESCRIPTION
    Accepts one or more service names (directly or via the pipeline), queries
    each service with Get-Service, and outputs a PSCustomObject per service
    that includes its status and an IsHealthy flag. Services that cannot be
    found return a status of "NotFound" with IsHealthy set to $false.

    .PARAMETER ServiceName
    The name of the Windows service to check. Accepts pipeline input and
    pipeline input by property name. Cannot be null or empty.

    .EXAMPLE
    Test-ServiceHealth -ServiceName "wuauserv"
    Checks the Windows Update service.

    .EXAMPLE
    "wuauserv", "Spooler", "FakeService123" | Test-ServiceHealth -Verbose
    Pipes three service names and checks each one with verbose output.

    .EXAMPLE
    Get-Content .\services.txt | Test-ServiceHealth | Format-Table -AutoSize
    Reads service names from a file, checks each, and formats the results.

    .INPUTS
    System.String

    .OUTPUTS
    PSCustomObject with ServiceName, DisplayName, Status, IsHealthy, CheckedAt.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    begin {
        $checkedCount = 0
        Write-Verbose "Starting service health check..."
    }

    process {
        Write-Verbose "Checking service '$ServiceName'..."

        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($null -ne $svc) {
            [PSCustomObject]@{
                ServiceName = $svc.Name
                DisplayName = $svc.DisplayName
                Status      = $svc.Status.ToString()
                IsHealthy   = ($svc.Status -eq 'Running')
                CheckedAt   = Get-Date
            }
        }
        else {
            Write-Verbose "  Service '$ServiceName' was not found."
            [PSCustomObject]@{
                ServiceName = $ServiceName
                DisplayName = "N/A"
                Status      = "NotFound"
                IsHealthy   = $false
                CheckedAt   = Get-Date
            }
        }

        $checkedCount++
    }

    end {
        Write-Verbose "Service health check complete. Total services checked: $checkedCount."
    }
}

# ============================================================================
# Usage examples
# ============================================================================
Test-ServiceHealth -ServiceName "wuauserv"
Test-ServiceHealth -ServiceName "wuauserv" -Verbose
"wuauserv", "Spooler", "FakeService123" | Test-ServiceHealth -Verbose
"wuauserv", "Spooler" | Test-ServiceHealth | Format-Table -AutoSize

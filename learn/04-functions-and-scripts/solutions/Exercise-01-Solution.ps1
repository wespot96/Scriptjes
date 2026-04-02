<#
.SYNOPSIS
    Solution for Exercise 01 - Get-DiskSpace Function

.DESCRIPTION
    Complete, working implementation of the Get-DiskSpace advanced function.
    Demonstrates CmdletBinding, comment-based help, validation attributes,
    PSCustomObject output, and Write-Verbose logging.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 04-Functions-and-Scripts
    Author : PowerShell Learning Series
#>

function Get-DiskSpace {
    <#
    .SYNOPSIS
    Retrieves disk space information for fixed drives on a computer.

    .DESCRIPTION
    Queries Win32_LogicalDisk via WMI to return total size, free space,
    and percent-used for every fixed disk (DriveType 3) on the target
    computer. Supports local and remote queries.

    .PARAMETER ComputerName
    The name of the computer to query. Defaults to "localhost".
    Cannot be null or empty.

    .EXAMPLE
    Get-DiskSpace
    Returns disk space for all fixed drives on the local computer.

    .EXAMPLE
    Get-DiskSpace -ComputerName "SERVER01" -Verbose
    Returns disk space for SERVER01 with verbose logging enabled.

    .OUTPUTS
    PSCustomObject with ComputerName, DriveLetter, TotalGB, FreeGB, PercentUsed.
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = "localhost"
    )

    Write-Verbose "Querying disk space on '$ComputerName'..."

    try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk `
                               -Filter "DriveType=3" `
                               -ComputerName $ComputerName `
                               -ErrorAction Stop

        foreach ($disk in $disks) {
            $totalGB  = [math]::Round($disk.Size / 1GB, 2)
            $freeGB   = [math]::Round($disk.FreeSpace / 1GB, 2)
            $pctUsed  = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)

            Write-Verbose "  $($disk.DeviceID) — $freeGB GB free of $totalGB GB ($pctUsed% used)"

            [PSCustomObject]@{
                ComputerName = $ComputerName
                DriveLetter  = $disk.DeviceID
                TotalGB      = $totalGB
                FreeGB       = $freeGB
                PercentUsed  = $pctUsed
            }
        }
    }
    catch {
        Write-Error "Failed to query disk space on '$ComputerName': $_"
    }
}

# ============================================================================
# Usage examples
# ============================================================================
Get-DiskSpace
Get-DiskSpace -ComputerName "localhost" -Verbose
Get-DiskSpace -ComputerName "localhost" | Format-Table -AutoSize

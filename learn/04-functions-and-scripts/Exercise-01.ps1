<#
.SYNOPSIS
    Exercise 01 - Get-DiskSpace Function

.DESCRIPTION
    Build an advanced function that retrieves disk space information from
    local or remote Windows computers. This exercise practises:

      - [CmdletBinding()] and advanced parameters
      - Comment-based help (.SYNOPSIS, .DESCRIPTION, .EXAMPLE)
      - Validation attributes ([ValidateNotNullOrEmpty()])
      - Returning [PSCustomObject] with calculated properties
      - Write-Verbose for operational logging

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 04-Functions-and-Scripts
    Author : PowerShell Learning Series
#>

# ============================================================================
# TODO: Complete the Get-DiskSpace function below.
#       Replace every "# TODO:" section with working code.
#       Refer to the README.md and ConnectionTest.ps1 for patterns.
# ============================================================================

function Get-DiskSpace {
    # TODO: Add comment-based help inside the function.
    #       Include at minimum:
    #         .SYNOPSIS   - One-line summary
    #         .DESCRIPTION - Paragraph explaining what the function does
    #         .PARAMETER ComputerName - Describe the parameter
    #         .EXAMPLE    - Show at least two usage examples
    #         .OUTPUTS    - PSCustomObject

    # TODO: Add [CmdletBinding()] attribute here.

    # TODO: Add a param block with the following parameter:
    #   -ComputerName [string] — default value "localhost"
    #     Apply [ValidateNotNullOrEmpty()] so the caller cannot pass $null or "".

    # TODO: Use Write-Verbose to log which computer you are querying.

    # TODO: Query fixed disks on $ComputerName.
    #   Hint: Use Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    #         Pass -ComputerName $ComputerName to support remote queries.

    # TODO: Loop through each disk returned and output a [PSCustomObject]
    #       with these properties:
    #         ComputerName  - the computer that was queried
    #         DriveLetter   - e.g. "C:"
    #         TotalGB       - total size in GB, rounded to 2 decimal places
    #         FreeGB        - free space in GB, rounded to 2 decimal places
    #         PercentUsed   - percentage of disk used, rounded to 1 decimal place
    #
    #   Hint: 1 GB = 1073741824 bytes (1GB PowerShell shorthand works too).
    #         PercentUsed = (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100
    #
    #   Wrap the WMI call in try/catch and use Write-Error on failure.
}

# ============================================================================
# Test your function — uncomment the lines below after completing the TODOs.
# ============================================================================
# Get-DiskSpace
# Get-DiskSpace -ComputerName "localhost" -Verbose
# Get-DiskSpace -ComputerName "localhost" | Format-Table -AutoSize

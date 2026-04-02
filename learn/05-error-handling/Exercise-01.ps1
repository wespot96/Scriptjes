<#
.SYNOPSIS
    Exercise 01 - Robust File Processor

.DESCRIPTION
    Practice error handling by building a script that processes a list of file
    paths.  Each operation must be wrapped in try/catch/finally so the script
    keeps running even when individual files fail.

    Skills practised:
      - try / catch / finally
      - Typed catch blocks (FileNotFoundException, UnauthorizedAccessException)
      - $ErrorActionPreference and Set-StrictMode
      - Write-Warning for error logging
      - Returning structured results

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module  : 05-error-handling
    Exercise: 01
    Author  : PowerShell Learning Path

.EXAMPLE
    .\Exercise-01.ps1
    Processes the built-in file list and displays a summary table.
#>

# ── Setup ────────────────────────────────────────────────────────────────────
# TODO 1: Enable Set-StrictMode (Version 2.0) to catch uninitialised variables
#         and invalid property references.


# TODO 2: Set $ErrorActionPreference to 'Stop' so that non-terminating errors
#         become terminating and can be caught by try/catch.


# ── Test data ────────────────────────────────────────────────────────────────
# This list intentionally contains paths that will succeed and paths that will
# fail in different ways.  Do NOT change this list.
$FilePaths = @(
    "$env:SystemRoot\System32\drivers\etc\hosts"   # Should succeed (readable)
    "C:\NonExistent\FakeFile.txt"                   # FileNotFoundException
    "$env:SystemRoot\System32\config\SAM"           # UnauthorizedAccessException (locked)
    "$env:SystemRoot\System32\drivers\etc\services" # Should succeed (readable)
    ""                                              # Empty string  - ArgumentException
    "C:\AnotherMissing\ghost.log"                   # FileNotFoundException
)

# ── Results collection ───────────────────────────────────────────────────────
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

# ── Main processing loop ─────────────────────────────────────────────────────
foreach ($FilePath in $FilePaths) {

    # TODO 3: Validate the file path before attempting to read.
    #         If $FilePath is null or empty, add a result with Status 'Skipped'
    #         and ErrorType 'ArgumentException', then continue to the next item.


    # TODO 4: Wrap the file-read operation in a try/catch/finally block.
    #
    #   try {
    #       - Use Get-Content with -ErrorAction Stop to read the file.
    #       - Capture the line count.
    #       - Add a result with Status 'Success' to $Results.
    #   }
    #   catch [System.IO.FileNotFoundException] {
    #       - Write-Warning with a message that includes the file path.
    #       - Add a result with Status 'Failed' and ErrorType 'FileNotFound'.
    #   }
    #   catch [System.UnauthorizedAccessException] {
    #       - Write-Warning with a message about access denied.
    #       - Add a result with Status 'Failed' and ErrorType 'AccessDenied'.
    #   }
    #   catch {
    #       - Catch any other error type.
    #       - Write-Warning with the full exception message.
    #       - Add a result with Status 'Failed' and ErrorType 'Unknown'.
    #   }
    #   finally {
    #       - Write-Verbose indicating processing is complete for this path.
    #   }
    #
    # Each result should be a [PSCustomObject] with these properties:
    #   FilePath, Status, LineCount, ErrorType, ErrorMessage, Timestamp

}

# ── Summary report ───────────────────────────────────────────────────────────

# TODO 5: Display a formatted summary.
#   - Output the $Results collection as a table (Format-Table).
#   - Count and display the number of successes, failures, and skipped items.
#   - Example output:
#       Total files : 6
#       Succeeded   : 2
#       Failed      : 3
#       Skipped     : 1


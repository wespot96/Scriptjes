<#
.SYNOPSIS
    Exercise 01 Solution - Robust File Processor

.DESCRIPTION
    Complete solution demonstrating try/catch/finally blocks with typed
    exception handling, Set-StrictMode, $ErrorActionPreference, and
    structured result reporting.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module  : 05-error-handling
    Exercise: 01 - Solution
    Author  : PowerShell Learning Path

.EXAMPLE
    .\Exercise-01-Solution.ps1
    Processes the built-in file list and displays a summary table.
#>

# ── Setup ────────────────────────────────────────────────────────────────────

# TODO 1: Strict mode catches uninitialised variables and bad property access.
Set-StrictMode -Version 2.0

# TODO 2: Convert non-terminating errors to terminating so try/catch works.
$ErrorActionPreference = 'Stop'

# ── Test data ────────────────────────────────────────────────────────────────

$FilePaths = @(
    "$env:SystemRoot\System32\drivers\etc\hosts"   # Should succeed
    "C:\NonExistent\FakeFile.txt"                   # FileNotFoundException
    "$env:SystemRoot\System32\config\SAM"           # UnauthorizedAccessException
    "$env:SystemRoot\System32\drivers\etc\services" # Should succeed
    ""                                              # Empty string - ArgumentException
    "C:\AnotherMissing\ghost.log"                   # FileNotFoundException
)

# ── Results collection ───────────────────────────────────────────────────────

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

# ── Main processing loop ─────────────────────────────────────────────────────

foreach ($FilePath in $FilePaths) {

    # TODO 3: Validate the path early; skip empty/null strings.
    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        $Results.Add([PSCustomObject]@{
            FilePath     = '(empty)'
            Status       = 'Skipped'
            LineCount    = 0
            ErrorType    = 'ArgumentException'
            ErrorMessage = 'File path was null or empty.'
            Timestamp    = Get-Date
        })
        Write-Warning "Skipped: file path is null or empty."
        continue
    }

    # TODO 4: Wrap the read in try/catch/finally with typed catch blocks.
    try {
        $content  = Get-Content -Path $FilePath -ErrorAction Stop
        $lineCount = ($content | Measure-Object -Line).Lines

        $Results.Add([PSCustomObject]@{
            FilePath     = $FilePath
            Status       = 'Success'
            LineCount    = $lineCount
            ErrorType    = $null
            ErrorMessage = $null
            Timestamp    = Get-Date
        })
    }
    catch [System.IO.FileNotFoundException] {
        Write-Warning "File not found: $FilePath"
        $Results.Add([PSCustomObject]@{
            FilePath     = $FilePath
            Status       = 'Failed'
            LineCount    = 0
            ErrorType    = 'FileNotFound'
            ErrorMessage = $_.Exception.Message
            Timestamp    = Get-Date
        })
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "Access denied: $FilePath"
        $Results.Add([PSCustomObject]@{
            FilePath     = $FilePath
            Status       = 'Failed'
            LineCount    = 0
            ErrorType    = 'AccessDenied'
            ErrorMessage = $_.Exception.Message
            Timestamp    = Get-Date
        })
    }
    catch {
        Write-Warning "Unexpected error for ${FilePath}: $($_.Exception.Message)"
        $Results.Add([PSCustomObject]@{
            FilePath     = $FilePath
            Status       = 'Failed'
            LineCount    = 0
            ErrorType    = 'Unknown'
            ErrorMessage = $_.Exception.Message
            Timestamp    = Get-Date
        })
    }
    finally {
        Write-Verbose "Finished processing: $FilePath"
    }
}

# ── Summary report ───────────────────────────────────────────────────────────

# TODO 5: Display the table and counts.
$Results | Format-Table -Property FilePath, Status, LineCount, ErrorType, ErrorMessage -AutoSize

$successCount = ($Results | Where-Object { $_.Status -eq 'Success' }).Count
$failedCount  = ($Results | Where-Object { $_.Status -eq 'Failed'  }).Count
$skippedCount = ($Results | Where-Object { $_.Status -eq 'Skipped' }).Count

Write-Host ""
Write-Host "Total files : $($Results.Count)"
Write-Host "Succeeded   : $successCount"
Write-Host "Failed      : $failedCount"
Write-Host "Skipped     : $skippedCount"

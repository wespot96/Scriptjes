<#
.SYNOPSIS
    Exercise 01 - HTML Server Report Generator

.DESCRIPTION
    Build a script that collects system health data and generates a styled
    HTML report saved to a timestamped file. This exercise practises:

      - Collecting disk, service, and event log data with WMI / Get-Service
      - Building a complete HTML document using a CSS here-string
      - Using ConvertTo-Html -Fragment for table sections
      - Color-coding status rows (OK / Warning / Critical)
      - Combining multiple report sections into one HTML file
      - Saving output with a timestamped filename

    Inspired by ServerHealthDashboard.ps1 but simplified for learning.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 12-Automation-and-Reporting
    Author : PowerShell Learning Series
#>

# ============================================================================
# TODO: Complete the HTML Server Report Generator below.
#       Replace every "# TODO:" section with working code.
#       Refer to the README.md and ServerHealthDashboard.ps1 for patterns.
# ============================================================================

# TODO: Add [CmdletBinding()] and a param block with:
#   -OutputDirectory [string] — defaults to $PSScriptRoot
#     Where the HTML report file will be saved.
#   -ComputerName [string] — defaults to $env:COMPUTERNAME
#     The computer to collect data from.
#   -EventLogHours [int] — defaults to 24, validated range 1-168
#     How many hours of event log history to include.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TODO: Build the output file path with a timestamp.
#   Hint: $reportPath = Join-Path $OutputDirectory "ServerReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

#region ── CSS Stylesheet ──────────────────────────────────────────────────────

# TODO: Define a $css variable using a here-string (@" ... "@) containing a
#       <style> block. Include at minimum:
#         - body   : font-family Arial/sans-serif, background colour, padding
#         - h1, h2 : colour and margin styling
#         - table  : border-collapse: collapse, width: 100%
#         - th     : background colour (e.g. #4472C4), white text, padding 10px
#         - td     : border: 1px solid #ddd, padding 8px
#         - .status-ok       : background-color: #d4edda (green tint)
#         - .status-warning  : background-color: #fff3cd (yellow tint)
#         - .status-critical : background-color: #f8d7da (red tint)
#         - .report-header   : margin-bottom 20px
#         - .section         : margin-bottom 30px
#
#   Example:
#     $css = @"
#     <style>
#         body { font-family: Arial, sans-serif; ... }
#         ...
#     </style>
#     "@

#endregion

#region ── Data Collection ─────────────────────────────────────────────────────

# TODO: Collect disk information.
#   Use Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" to get
#   fixed disks. For each disk, create a [PSCustomObject] with:
#     Drive       - DeviceID (e.g. "C:")
#     TotalGB     - Size in GB, rounded to 2 decimal places
#     FreeGB      - FreeSpace in GB, rounded to 2 decimal places
#     UsedGB      - (Size - FreeSpace) in GB, rounded to 2 decimal places
#     PercentUsed - usage percentage, rounded to 1 decimal place
#     Status      - "OK" if <75%, "Warning" if 75-89%, "Critical" if >=90%
#
#   Store the results in a $diskData array.

# TODO: Collect critical service status.
#   Define a list of service names to monitor:
#     $serviceNames = @('wuauserv','EventLog','Schedule','Spooler',
#                       'WinDefend','LanmanServer','Dnscache','W32Time')
#   Loop through each name, use Get-Service -Name $name -ErrorAction
#   SilentlyContinue, and create a [PSCustomObject] with:
#     ServiceName - the short name
#     DisplayName - the friendly display name (or "N/A" if not found)
#     Status      - Running / Stopped / NotFound
#     StatusClass - "status-ok" if Running, "status-critical" otherwise
#
#   Store the results in a $serviceData array.

# TODO: Collect recent event log errors and warnings.
#   Query the System and Application logs for Error and Warning entries
#   from the last $EventLogHours hours. Use Get-EventLog with:
#     -LogName $logName -EntryType Error,Warning
#     -After (Get-Date).AddHours(-$EventLogHours) -Newest 25
#   Wrap in try/catch (some logs may be inaccessible).
#   Create [PSCustomObject] entries with:
#     Log       - "System" or "Application"
#     Time      - TimeGenerated formatted as 'yyyy-MM-dd HH:mm:ss'
#     Type      - EntryType (Error / Warning)
#     Source    - the event source
#     EventID   - the event ID
#     Message   - first 150 characters of the message
#
#   Store the results in an $eventData array.

#endregion

#region ── HTML Report Assembly ────────────────────────────────────────────────

# TODO: Build the disk usage HTML table.
#   Loop through $diskData. For each disk, determine the CSS class based on
#   the Status property ("status-ok", "status-warning", or "status-critical").
#   Build HTML <tr> rows with class="$cssClass" on the row, for example:
#     <tr class="status-ok"><td>C:</td><td>100</td>...</tr>
#   Collect all rows into a $diskRows string.

# TODO: Build the service status HTML table.
#   Loop through $serviceData and build <tr> rows using StatusClass for
#   color-coding. Collect into a $serviceRows string.

# TODO: Build the event log HTML table.
#   Loop through $eventData. Assign "status-critical" for Error entries
#   and "status-warning" for Warning entries. Collect into $eventRows.
#   If $eventData is empty, set $eventRows to a single row saying
#   "No errors or warnings in the last N hours."

# TODO: Assemble the full HTML document in a $html here-string.
#   Structure:
#     <!DOCTYPE html>
#     <html>
#     <head>
#       <title>Server Report - $ComputerName</title>
#       $css
#     </head>
#     <body>
#       <div class="report-header">
#         <h1>Server Health Report</h1>
#         <p>Computer: $ComputerName</p>
#         <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
#       </div>
#
#       <div class="section">
#         <h2>Disk Usage</h2>
#         <table>
#           <tr><th>Drive</th><th>Total GB</th><th>Used GB</th>
#               <th>Free GB</th><th>% Used</th><th>Status</th></tr>
#           $diskRows
#         </table>
#       </div>
#
#       <div class="section">
#         <h2>Critical Services</h2>
#         <table>
#           <tr><th>Service</th><th>Display Name</th><th>Status</th></tr>
#           $serviceRows
#         </table>
#       </div>
#
#       <div class="section">
#         <h2>Event Log - Errors & Warnings (last $EventLogHours hours)</h2>
#         <table>
#           <tr><th>Log</th><th>Time</th><th>Type</th>
#               <th>Source</th><th>Event ID</th><th>Message</th></tr>
#           $eventRows
#         </table>
#       </div>
#
#       <footer>Generated by Exercise-01.ps1</footer>
#     </body>
#     </html>

#endregion

#region ── Save Report ─────────────────────────────────────────────────────────

# TODO: Save the $html string to $reportPath using Out-File with UTF-8 encoding.
#   Then write a message to the console confirming the file location:
#     Write-Host "Report saved to: $reportPath" -ForegroundColor Green

#endregion

# ============================================================================
# Test your script — uncomment the lines below after completing the TODOs.
# ============================================================================
# .\Exercise-01.ps1
# .\Exercise-01.ps1 -OutputDirectory "C:\Reports" -Verbose
# .\Exercise-01.ps1 -EventLogHours 48

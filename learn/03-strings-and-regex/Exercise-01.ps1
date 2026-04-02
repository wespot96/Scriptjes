<#
.SYNOPSIS
    Exercise 01 - Log File Parser

.DESCRIPTION
    Practice string matching, regex extraction, and formatting by parsing
    a simulated web-server log file. You will:
      1. Generate sample log data (provided).
      2. Use Select-String and -match to extract IP addresses, timestamps,
         and HTTP status codes from each log line.
      3. Use -replace, -split, and the -f format operator to build a
         summary report showing unique IPs, error counts, and a formatted
         table of entries.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 03 - Strings and Regular Expressions
    File   : Exercise-01.ps1
    Type   : Template (contains TODO markers)

.EXAMPLE
    .\Exercise-01.ps1
    Generates sample log data, parses it, and prints a summary report.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Sample Data Generation (do NOT modify) ─────────────────────────
# Each line follows the Combined Log Format:
#   IP - - [DD/Mon/YYYY:HH:MM:SS +0000] "METHOD /path HTTP/1.1" STATUS SIZE
$sampleLog = @(
    '192.168.1.10 - - [15/Jan/2025:08:12:34 +0000] "GET /index.html HTTP/1.1" 200 5123'
    '10.0.0.55 - - [15/Jan/2025:08:12:35 +0000] "POST /api/login HTTP/1.1" 401 312'
    '192.168.1.10 - - [15/Jan/2025:08:13:01 +0000] "GET /dashboard HTTP/1.1" 200 10245'
    '172.16.0.3 - - [15/Jan/2025:08:13:45 +0000] "GET /api/users HTTP/1.1" 500 0'
    '10.0.0.55 - - [15/Jan/2025:08:14:02 +0000] "GET /favicon.ico HTTP/1.1" 404 0'
    '192.168.1.10 - - [15/Jan/2025:08:14:30 +0000] "POST /api/data HTTP/1.1" 200 834'
    '172.16.0.3 - - [15/Jan/2025:08:15:12 +0000] "GET /reports HTTP/1.1" 403 0'
    '10.0.0.99 - - [15/Jan/2025:08:15:45 +0000] "GET /index.html HTTP/1.1" 200 5123'
    '10.0.0.55 - - [15/Jan/2025:08:16:00 +0000] "POST /api/login HTTP/1.1" 401 312'
    '172.16.0.3 - - [15/Jan/2025:08:16:22 +0000] "GET /api/users HTTP/1.1" 500 0'
    '192.168.1.10 - - [15/Jan/2025:08:17:05 +0000] "GET /style.css HTTP/1.1" 304 0'
    '10.0.0.99 - - [15/Jan/2025:08:17:30 +0000] "DELETE /api/session HTTP/1.1" 200 28'
)
#endregion

# ─────────────────────────────────────────────────────────────────────────
# TASK 1 — Extract fields from each log line
# ─────────────────────────────────────────────────────────────────────────
# Parse each line and store results in a collection of objects with
# properties: IP, Timestamp, Method, Path, StatusCode, Size

# Regex hint — the Combined Log Format can be captured with a pattern like:
#   ^(\S+) .+ \[(.+?)\] "(\S+) (\S+) .+?" (\d{3}) (\d+)$

$parsedEntries = @()

foreach ($line in $sampleLog) {
    # TODO: Use -match with a regex pattern to capture:
    #       Group 1 → IP address
    #       Group 2 → Timestamp (inside the brackets)
    #       Group 3 → HTTP method (GET, POST, etc.)
    #       Group 4 → Request path
    #       Group 5 → HTTP status code
    #       Group 6 → Response size
    # Then create a [PSCustomObject] and append it to $parsedEntries.

}

# ─────────────────────────────────────────────────────────────────────────
# TASK 2 — Identify error entries (status codes 400-599)
# ─────────────────────────────────────────────────────────────────────────
# Filter $parsedEntries to find only entries whose StatusCode starts with
# 4 or 5.  Use -match on the StatusCode property.

# TODO: Create $errorEntries by filtering $parsedEntries where StatusCode
#       matches the pattern for 4xx or 5xx codes.


# ─────────────────────────────────────────────────────────────────────────
# TASK 3 — Build a list of unique IP addresses
# ─────────────────────────────────────────────────────────────────────────
# Use Select-Object -Unique (or a hashtable) to get distinct IPs.

# TODO: Create $uniqueIPs — an array of unique IP strings from
#       $parsedEntries.


# ─────────────────────────────────────────────────────────────────────────
# TASK 4 — Clean up timestamps with -replace
# ─────────────────────────────────────────────────────────────────────────
# The raw timestamp looks like "15/Jan/2025:08:12:34 +0000".
# Convert it to a friendlier format: "2025-Jan-15 08:12:34"
# Use -replace with capture groups.

# TODO: Write a function or expression that uses -replace to reformat the
#       timestamp.  Apply it to each entry in $parsedEntries and store the
#       result in a new property called FriendlyTime.


# ─────────────────────────────────────────────────────────────────────────
# TASK 5 — Count requests per IP using -split and the -f operator
# ─────────────────────────────────────────────────────────────────────────
# Group entries by IP and produce a count.  Then format each line as:
#   "IP Address       Requests  Errors"
#   "192.168.1.10            4       0"

# TODO: Use Group-Object or a hashtable to count requests (and errors)
#       per IP.  Format each summary line with the -f operator and
#       appropriate column widths.


# ─────────────────────────────────────────────────────────────────────────
# TASK 6 — Select-String: Search the raw log for specific patterns
# ─────────────────────────────────────────────────────────────────────────
# Use Select-String against the $sampleLog array (piped as input) to find
# all lines that contain an IP matching 10.0.0.* .

# TODO: Pipe $sampleLog into Select-String with an appropriate -Pattern
#       and store the matching lines in $subnetMatches.


# ─────────────────────────────────────────────────────────────────────────
# TASK 7 — Build the final summary report
# ─────────────────────────────────────────────────────────────────────────
# Combine all your results into a single report string using a here-string.
# The report should include:
#   • Total lines parsed
#   • Number of unique IPs
#   • Number of error entries (4xx / 5xx)
#   • The per-IP table from Task 5
#   • A list of error entries with FriendlyTime, IP, StatusCode, and Path

# TODO: Build $report using a here-string (@" ... "@) and Write-Output it.


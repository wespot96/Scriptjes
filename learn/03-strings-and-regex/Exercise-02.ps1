<#
.SYNOPSIS
    Exercise 02 - Config File Processor

.DESCRIPTION
    Practice regex validation, string transformation, and here-string output
    by building a configuration file processor.  Inspired by the .env
    parsing in OAuthSMTP.ps1, you will:
      1. Generate sample key=value config data (provided).
      2. Parse each line using -split, skipping comments and blank lines.
      3. Validate keys and values against regex patterns.
      4. Transform values (Trim, case conversion, placeholder expansion).
      5. Generate a formatted output report using a here-string.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 03 - Strings and Regular Expressions
    File   : Exercise-02.ps1
    Type   : Template (contains TODO markers)

.EXAMPLE
    .\Exercise-02.ps1
    Parses sample config data, validates entries, and prints a report.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Sample Config Data (do NOT modify) ─────────────────────────────
# Simulates reading a .env / config file.  Includes comments, blank lines,
# valid entries, and intentionally invalid entries for validation practice.
$configLines = @(
    '# Application Settings'
    ''
    'APP_NAME = My Server App'
    'APP_ENV=production'
    'APP_DEBUG =  false  '
    ''
    '# Network Configuration'
    'SERVER_HOST = 192.168.1.100 '
    'SERVER_PORT=8443'
    'BIND_ADDRESS=0.0.0.0'
    ''
    '# Database'
    'DB_HOST=db-server.local'
    'DB_PORT = 5432'
    'DB_NAME =   appdb  '
    'DB_USER=  svc_account  '
    'DB_PASS=P@ssw0rd!#2025'
    ''
    '# Mail (see OAuthSMTP.ps1 for context)'
    'SMTP_SERVER = smtp.office365.com'
    'SMTP_PORT=587'
    'MAIL_FROM = alerts@company.com'
    'MAIL_TO=admin@company.com'
    ''
    '# --- Intentionally invalid entries for validation ---'
    '123_BAD_KEY=should fail'
    'GOOD_KEY='
    '=missing_key'
    'NO-HYPHENS-ALLOWED=value'
    'VALID_URL=https://api.example.com/v2/health'
    'BAD_PORT=99999'
)
#endregion

# ─────────────────────────────────────────────────────────────────────────
# TASK 1 — Parse config lines into key/value pairs
# ─────────────────────────────────────────────────────────────────────────
# Loop through $configLines.  Skip blank lines and comment lines (lines
# whose first non-space character is #).  For each remaining line, split
# on the FIRST '=' to get a key and a value.  Trim whitespace from both.
#
# Store results in an array of [PSCustomObject] with properties:
#   RawLine, Key, Value, LineNumber

$entries = @()
$lineNum = 0

foreach ($line in $configLines) {
    $lineNum++

    # TODO: Skip blank lines and comment lines.
    #       Hint: use -match with ^\s*$ and ^\s*#

    # TODO: Split $line on the first '=' only.
    #       Hint: ($line -split '=', 2) gives at most two parts.

    # TODO: Trim key and value, create a [PSCustomObject], and add to
    #       $entries.

}

# ─────────────────────────────────────────────────────────────────────────
# TASK 2 — Validate keys using regex
# ─────────────────────────────────────────────────────────────────────────
# A valid key must:
#   • Start with a letter (A-Z, a-z)
#   • Contain only letters, digits, and underscores
#   • Be at least 2 characters long
# Pattern hint: ^[A-Za-z]\w{1,}$

# TODO: For each entry in $entries, add a boolean property IsValidKey by
#       testing the Key against the regex.  Also flag entries where the
#       key is empty as invalid.


# ─────────────────────────────────────────────────────────────────────────
# TASK 3 — Validate values using regex
# ─────────────────────────────────────────────────────────────────────────
# Apply type-specific validation based on the key name:
#   • Keys ending in _PORT  → value must be digits only AND between 1-65535
#   • Keys ending in _HOST or _SERVER → value must match a hostname or IP
#     pattern (simple check: letters, digits, dots, hyphens)
#   • Keys containing MAIL  → value must look like an email address
#   • Keys containing URL   → value must start with http:// or https://
#   • All other keys        → value must not be empty
#
# Store the validation result in a property IsValidValue (boolean) and
# a property ValidationNote (string describing the issue or "OK").

# TODO: Loop through $entries and apply the validation rules above.


# ─────────────────────────────────────────────────────────────────────────
# TASK 4 — Transform values
# ─────────────────────────────────────────────────────────────────────────
# For every valid entry (IsValidKey -and IsValidValue), create a
# CleanValue property:
#   • Trim leading/trailing whitespace (already done in Task 1, but
#     double-check).
#   • If the key contains _ENV, convert the value to lowercase.
#   • If the key is APP_NAME, convert the value to Title Case using
#     the culture TextInfo object:
#       (Get-Culture).TextInfo.ToTitleCase($value.ToLower())
#   • If the value is 'true' or 'false' (case-insensitive), normalise
#     to lowercase.

# TODO: Add a CleanValue property to each entry.


# ─────────────────────────────────────────────────────────────────────────
# TASK 5 — Build a formatted validation report
# ─────────────────────────────────────────────────────────────────────────
# Use the -f format operator to print a table of all entries:
#
#   Line  Key                  Valid?  Value
#   ----  ---                  ------  -----
#      3  APP_NAME             OK      My Server App
#     25  123_BAD_KEY          FAIL    (Invalid key: must start with letter)
#
# Column widths: Line = 4 right-aligned, Key = 20 left-aligned,
# Valid = 6, Value = remainder.

# TODO: Print the table header, then loop through $entries and format
#       each row with the -f operator.


# ─────────────────────────────────────────────────────────────────────────
# TASK 6 — Generate final output using a here-string
# ─────────────────────────────────────────────────────────────────────────
# Build a here-string that looks like a clean .env file containing only
# the valid, cleaned entries — one per line in KEY=VALUE format.
# Prepend a comment header with a generation timestamp.
#
# Example output:
#   # Generated: 2025-01-15 08:30:00
#   # Valid entries: 14
#   APP_NAME=My Server App
#   APP_ENV=production
#   ...

# TODO: Collect valid entries, build $outputLines (array of strings),
#       and wrap them in a here-string that includes the header comment.
#       Write-Output the final result.


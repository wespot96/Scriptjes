<#
.SYNOPSIS
    Exercise 02 Solution - Config File Processor

.DESCRIPTION
    Complete solution for the Config File Processor exercise.  Demonstrates
    -split, -match, -replace, regex validation, string methods (Trim,
    ToLower, ToTitleCase), the -f format operator, and here-strings to
    parse and validate a key=value config file.

    Inspired by the .env parsing pattern in OAuthSMTP.ps1.

    Target: Windows Server 2022, PowerShell 5.1, no external modules.

.NOTES
    Module : 03 - Strings and Regular Expressions
    File   : Exercise-02-Solution.ps1
    Type   : Solution (fully working)

.EXAMPLE
    .\Exercise-02-Solution.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Sample Config Data ─────────────────────────────────────────────
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

# ── TASK 1 — Parse config lines into key/value pairs ────────────────────
$entries = @()
$lineNum = 0

foreach ($line in $configLines) {
    $lineNum++

    # Skip blank lines
    if ($line -match '^\s*$') { continue }

    # Skip comment lines (first non-space char is #)
    if ($line -match '^\s*#') { continue }

    # Split on the first '=' only — preserves '=' chars inside values
    $parts = $line -split '=', 2
    $key   = $parts[0].Trim()
    $value = if ($parts.Count -ge 2) { $parts[1].Trim() } else { '' }

    $entries += [PSCustomObject]@{
        RawLine        = $line
        LineNumber     = $lineNum
        Key            = $key
        Value          = $value
        IsValidKey     = $false
        IsValidValue   = $false
        ValidationNote = ''
        CleanValue     = ''
    }
}

Write-Host "Parsed $($entries.Count) config entries (skipped comments/blanks)." -ForegroundColor Cyan

# ── TASK 2 — Validate keys ──────────────────────────────────────────────
# Valid key: starts with a letter, then letters/digits/underscores, ≥ 2 chars.
$keyPattern = '^[A-Za-z]\w{1,}$'

foreach ($entry in $entries) {
    if ([string]::IsNullOrWhiteSpace($entry.Key)) {
        $entry.IsValidKey     = $false
        $entry.ValidationNote = 'Empty key'
    }
    elseif ($entry.Key -match $keyPattern) {
        $entry.IsValidKey = $true
    }
    else {
        $entry.IsValidKey     = $false
        $entry.ValidationNote = 'Invalid key: must start with a letter and contain only letters, digits, underscores'
    }
}

# ── TASK 3 — Validate values ────────────────────────────────────────────
foreach ($entry in $entries) {
    if (-not $entry.IsValidKey) {
        # Already flagged; skip value validation
        if ($entry.ValidationNote -eq '') {
            $entry.ValidationNote = 'Skipped (invalid key)'
        }
        continue
    }

    $key   = $entry.Key
    $value = $entry.Value

    switch -Regex ($key) {
        '_PORT$' {
            # Must be digits 1-65535
            if ($value -match '^\d+$') {
                $port = [int]$value
                if ($port -ge 1 -and $port -le 65535) {
                    $entry.IsValidValue   = $true
                    $entry.ValidationNote = 'OK'
                }
                else {
                    $entry.ValidationNote = "Port out of range (1-65535): $value"
                }
            }
            else {
                $entry.ValidationNote = "Port must be numeric: $value"
            }
            break
        }
        '(_HOST|_SERVER)$' {
            # Simple hostname/IP: letters, digits, dots, hyphens
            if ($value -match '^[A-Za-z0-9][A-Za-z0-9.\-]+$') {
                $entry.IsValidValue   = $true
                $entry.ValidationNote = 'OK'
            }
            else {
                $entry.ValidationNote = "Invalid hostname/IP: $value"
            }
            break
        }
        'MAIL' {
            # Basic email check
            if ($value -match '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$') {
                $entry.IsValidValue   = $true
                $entry.ValidationNote = 'OK'
            }
            else {
                $entry.ValidationNote = "Invalid email address: $value"
            }
            break
        }
        'URL' {
            # Must start with http:// or https://
            if ($value -match '^https?://\S+$') {
                $entry.IsValidValue   = $true
                $entry.ValidationNote = 'OK'
            }
            else {
                $entry.ValidationNote = "Invalid URL (must start with http/https): $value"
            }
            break
        }
        default {
            # General: value must not be empty
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $entry.IsValidValue   = $true
                $entry.ValidationNote = 'OK'
            }
            else {
                $entry.ValidationNote = 'Value must not be empty'
            }
        }
    }
}

# ── TASK 4 — Transform values ───────────────────────────────────────────
foreach ($entry in $entries) {
    if (-not ($entry.IsValidKey -and $entry.IsValidValue)) {
        $entry.CleanValue = $entry.Value
        continue
    }

    $clean = $entry.Value.Trim()

    # ENV keys → lowercase value
    if ($entry.Key -match '_ENV') {
        $clean = $clean.ToLower()
    }

    # APP_NAME → Title Case
    if ($entry.Key -eq 'APP_NAME') {
        $clean = (Get-Culture).TextInfo.ToTitleCase($clean.ToLower())
    }

    # Boolean normalisation
    if ($clean -match '^(true|false)$') {
        $clean = $clean.ToLower()
    }

    $entry.CleanValue = $clean
}

# ── TASK 5 — Formatted validation report ────────────────────────────────
Write-Host ''
Write-Host '── Configuration Validation Report ─────────────────────────────' -ForegroundColor Yellow

# Header row
$headerFmt = "{0,4}  {1,-22} {2,-6}  {3}"
Write-Host ($headerFmt -f 'Line', 'Key', 'Valid?', 'Note / Value')
Write-Host ($headerFmt -f '────', ('─' * 22), '──────', ('─' * 40))

foreach ($entry in $entries) {
    $status = if ($entry.IsValidKey -and $entry.IsValidValue) { 'OK' } else { 'FAIL' }
    $detail = if ($status -eq 'OK') { $entry.CleanValue } else { "($($entry.ValidationNote))" }

    $color = if ($status -eq 'OK') { 'Green' } else { 'Red' }
    Write-Host ($headerFmt -f $entry.LineNumber, $entry.Key, $status, $detail) -ForegroundColor $color
}

# ── TASK 6 — Here-string output of clean .env file ──────────────────────
$validEntries = $entries | Where-Object { $_.IsValidKey -and $_.IsValidValue }
$validCount   = $validEntries.Count

$outputLines = $validEntries | ForEach-Object {
    "{0}={1}" -f $_.Key, $_.CleanValue
}

$outputBody = $outputLines -join "`n"

$cleanEnv = @"
# ─────────────────────────────────────────────────
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Valid entries: $validCount
# ─────────────────────────────────────────────────
$outputBody
"@

Write-Host ''
Write-Host '── Generated Clean Config ─────────────────────────────────────' -ForegroundColor Yellow
Write-Output $cleanEnv

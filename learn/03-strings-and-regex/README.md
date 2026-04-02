# Module 03: Strings and Regular Expressions

## Learning Goals

- Master string matching with -match and -replace operators
- Use -split to parse delimited data
- Apply regex patterns effectively with Select-String
- Work with here-strings for multi-line content
- Use the -f string formatting operator

## Key Concepts

### 1. String Matching with -match
```powershell
# Basic pattern matching
"ServerName" -match "Server"  # Returns $true

# Capture groups
if ("Error 401 Unauthorized" -match "Error (\d+)") {
    $errorCode = $Matches[1]  # $Matches auto-populated
}

# Case-insensitive (default)
"server" -match "SERVER"  # $true

# Case-sensitive
"server" -cmatch "SERVER"  # $false

# Array matching
@("Server01", "Client02", "Server03") -match "Server"  # Returns matching items
```

### 2. String Replacement with -replace
```powershell
# Simple replacement
"old text" -replace "old", "new"  # "new text"

# Multiple replacements
"Hello World" -replace "l", "L"  # "HeLLo WorLd"

# Regex replacement
"User123" -replace "\d+", "X"  # "UserX"

# Case-insensitive (default)
"HELLO" -replace "hello", "bye"  # "bye"

# Case-sensitive
"HELLO" -creplace "hello", "bye"  # "HELLO" (no match)
```

### 3. String Splitting with -split
```powershell
# Split by delimiter
"C:\Windows\System32\drivers" -split "\\"  # Array of path components

# Split by space
"Server01 Status Running" -split " "  # @("Server01", "Status", "Running")

# Split with limit
"A,B,C,D,E" -split "," -MaxSubstringLength 2  # First 2 elements

# Split and remove empty
"A::B::C" -split ":+" | Where-Object { $_ }  # Removes empty elements
```

### 4. Select-String: Pattern Search
```powershell
# Search file for pattern
Select-String -Path "C:\logs\app.log" -Pattern "Error"

# Regex pattern
Select-String -Path "C:\logs\*.log" -Pattern "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"

# Inline string search
"Server01`nServer02`nClient03" | Select-String "Server"

# Count matches
(Select-String -Path "C:\app.log" -Pattern "Warning").Count

# Show context
Select-String -Path "C:\app.log" -Pattern "Error" -Context 2, 2
```

### 5. Regular Expression ([regex])
```powershell
# Static method for quick matching
[regex]::IsMatch("user@domain.com", "@")

# Replace with static method
[regex]::Replace("123-456-7890", "-", "")

# Matches method returns match details
$text = "Session 12345 started"
$match = [regex]::Match($text, "Session (\d+)")
$match.Groups[1].Value  # "12345"

# Matches method (all matches)
$matches = [regex]::Matches("A1B2C3", "\d")
$matches.Value  # @("1", "2", "3")
```

### 6. Here-Strings: Multi-Line Text
```powershell
# Here-string with variables (interpolation)
$server = "DB01"
$config = @"
Server=$server
Port=5432
Database=Production
Backup=Enabled
"@

# Literal here-string (no interpolation)
$template = @'
This is literal text.
Variables like $server are NOT expanded.
$null is still $null.
'@

# Use case: HTML content
$html = @"
<html>
<body>
<h1>Report for $server</h1>
<p>Generated: $(Get-Date)</p>
</body>
</html>
"@
```

### 7. String Formatting with -f
```powershell
# Format string placeholders
"Name: {0}, Age: {1}" -f "Alice", 30

# Multiple uses of same index
"Repeat: {0}, {0}, {0}" -f "X"

# Padding and alignment
"{0,10}" -f "right"      # Right-aligned in 10 chars
"{0,-10}" -f "left"      # Left-aligned in 10 chars

# Numeric formatting
"Value: {0:N2}" -f 1234.56789  # "Value: 1,234.57"
"Percent: {0:P}" -f 0.85       # "Percent: 85.00 %"
"Hex: {0:X}" -f 255            # "Hex: FF"
```

### 8. String Methods
```powershell
# Common string methods
$text = "PowerShell"
$text.ToUpper()           # "POWERSHELL"
$text.ToLower()           # "powershell"
$text.Substring(5)        # "Shell"
$text.Substring(0, 5)     # "Power"
$text.IndexOf("Shell")    # 5
$text.Contains("Power")   # $true
$text.StartsWith("Power") # $true
$text.Trim()              # Remove leading/trailing spaces
$text.Replace("Shell", "Bash")  # "PowerBash"
```

### 9. Array Joining
```powershell
# Join array elements into string
$servers = @("WEB01", "WEB02", "WEB03")
$servers -join ", "       # "WEB01, WEB02, WEB03"
$servers -join "`n"       # Multi-line output

# Split back into array
"A,B,C" -split ","
```

### 10. Regex Special Characters
```powershell
# . matches any character (except newline)
"a.c" -match "a.c"  # Matches: "abc", "aXc", etc.

# * means zero or more
"Pattern: A*BC" -match "A*BC"  # Matches: "BC", "ABC", "AABC"

# + means one or more
"Error: \d+" -match "[0-9]+"

# ? means zero or one
"Colou?r" -match "Color|Colour"

# ^ start of string, $ end of string
"^Server" -match "^Server"
"^Server" -match "Server$"  # $false

# Character class: [abc], [0-9], [a-z]
"[0-9]" -match "5"  # $true
```

### 11. Escaping Special Characters
```powershell
# Escape regex special chars with \
"Price: $100" -match '\$\d+'  # Match "$" literally

# In regular strings, use `
"Path: C:\Windows" | Select-String "C:\\Windows"

# Or use [regex]::Escape()
[regex]::Escape(".*+?[]{}()")
```

### 12. Practical Parsing Examples
```powershell
# Parse key=value lines
$line = "ServerName=DB01,Port=5432,Status=Online"
$line -split "," | ForEach-Object {
    $key, $value = $_ -split "="
    Write-Host "$key : $value"
}

# Extract email from text
$text = "Contact us at support@company.com for help"
$text -match "[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+"
$Matches[0]  # "support@company.com"
```

## Real-World Example: Log Parsing

Reference: **OAuthSMTP.ps1**

This script demonstrates:
- String matching and extraction
- Regular expressions for pattern matching
- Multi-line string handling for templates
- String formatting for output

```powershell
# Parse SMTP connection log
$logLines = Get-Content -Path "C:\mail.log"
$logLines | Select-String "Authentication|Failed|Connected" | ForEach-Object {
    if ($_ -match "(\w+)\s+(\d+:\d+:\d+)\s+(.*)") {
        $time = $Matches[2]
        $message = $Matches[3]
        "{0}: {1}" -f $time, $message
    }
}

# Extract sender/recipient
$email = "FROM:<sender@company.com> TO:<recipient@company.com>"
if ($email -match "FROM:<(.+?)> TO:<(.+?)>") {
    "Sender: {0}, Recipient: {1}" -f $Matches[1], $Matches[2]
}
```

## Quick Reference: Regex Patterns

| Pattern | Meaning | Example |
|---------|---------|---------|
| `.` | Any character | `c.t` matches "cat", "cot" |
| `*` | Zero or more | `ab*c` matches "ac", "abc", "abbc" |
| `+` | One or more | `\d+` matches one or more digits |
| `?` | Zero or one | `colou?r` matches "color", "colour" |
| `^` | Start of line | `^Error` matches "Error" at start |
| `$` | End of line | `OK$` matches "OK" at end |
| `[abc]` | Character class | `[aeiou]` matches any vowel |
| `[a-z]` | Range | `[0-9]` matches any digit |
| `\d` | Digit | `\d{3}` matches exactly 3 digits |
| `\w` | Word char | `\w+` matches words |
| `\s` | Whitespace | `\s+` matches one or more spaces |
| `(...)` | Capture group | `(\w+)` captures word into `$Matches[1]` |
| `\|` | OR | `cat\|dog` matches "cat" or "dog" |

## Try It: Hands-On Exercises

### Exercise 1: Test pattern matching
```powershell
# Determine if strings match patterns
$test = @(
    "Server01",
    "Client02",
    "DB-Server03",
    "WebServer-04"
)

$test | Where-Object { $_ -match "^Server" }
$test | Where-Object { $_ -match "\d+$" }
```

### Exercise 2: Extract numbers from text
```powershell
# Parse log entries and extract error codes
$logs = @(
    "Error 404: Page not found",
    "Error 500: Internal server error",
    "Warning 301: Moved permanently"
)

$logs | ForEach-Object {
    if ($_ -match "Error (\d+)") {
        "Error code: $($Matches[1])"
    }
}
```

### Exercise 3: Replace and format
```powershell
# Convert dates from MM/DD/YYYY to YYYY-MM-DD
$date = "12/25/2024"
$date -replace "(\d+)/(\d+)/(\d+)", '$3-$1-$2'
```

### Exercise 4: Split and parse CSV
```powershell
# Parse CSV line
$csv = "Server01,Running,98.2%,1024MB"
$parts = $csv -split ","
"Name: $($parts[0]), Status: $($parts[1])"
```

### Exercise 5: Search file for patterns
```powershell
# Find all IP addresses in log
$logFile = "C:\Windows\System32\LogFiles\firewall.log"
Select-String -Path $logFile -Pattern "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
```

### Exercise 6: Here-string email template
```powershell
$recipient = "admin@company.com"
$server = "DB01"
$message = @"
Subject: Server Alert
To: $recipient

The following server requires attention:
Server Name: $server
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Please investigate immediately.
"@
Write-Output $message
```

### Exercise 7: Format output nicely
```powershell
# Create formatted report
$data = @(
    @{ Name = "Server01"; Memory = 8192; CPU = 65 },
    @{ Name = "Server02"; Memory = 16384; CPU = 42 },
    @{ Name = "Server03"; Memory = 4096; CPU = 89 }
)

$data | ForEach-Object {
    "Name: {0,-12} Memory: {1,6}MB  CPU: {2,3}%" -f $_.Name, $_.Memory, $_.CPU
}
```

### Exercise 8: Regex email validation
```powershell
$email = "user@company.co.uk"
if ($email -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
    "Valid email"
} else {
    "Invalid email"
}
```

## Further Reading

- [About Operators: -match](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators)
- [Regular Expressions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions)
- [Select-String](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-string)
- [String Formatting with -f](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_string_formatting)
- [RFC 5234: Augmented BNF](https://tools.ietf.org/html/rfc5234) - Regex standard reference



Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Step 1: Test basic TCP connectivity to the SMTP endpoint.
function Test-SmtpConnection {
    param(
        [string]$Server,
        [int]$Port,
        [int]$TimeoutMs = 8000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $ar = $client.BeginConnect($Server, $Port, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            throw "Timeout after $TimeoutMs ms"
        }
        $client.EndConnect($ar)
        Write-Host "SMTP connection test succeeded: $Server`:$Port"
        return $true
    }
    catch {
        Write-Host "SMTP connection test failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        $client.Dispose()
    }
}

# Step 2: Import .env values into environment.
# Expected keys in .env:
# tenantId=...
# clientId=...
# clientSecret=...
# fromAddress=...
# toAddress=...
get-content .env |foreach{
    $name, $value = $_.split ('=')
    set-content env:$name $value
}

# Step 3: Read required values from environment.
$tenantId = $env:tenantId
$clientId = $env:clientId
$clientSecret = $env:clientSecret
$fromAddress = $env:fromAddress
$toAddress = $env:toAddress

# Step 4: Define fixed configuration values.
$scope = "https://outlook.office365.com/.default"
$smtpServer = "smtp.office365.com"
$smtpPort = "587"
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$subject = "OAuth SMTP Test"
$body = "Hello from OAuth SMTP "

# Step 5: Request OAuth token from Azure AD.
try {
    $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body @{
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = $scope
        grant_type    = "client_credentials"
    }
}
catch {
    Write-Host "Token acquisition failed: $($_.Exception.Message)"
    exit 1
}

$accessToken = [string]$tokenResponse.access_token
if ([string]::IsNullOrWhiteSpace($accessToken)) {
    Write-Host "Token acquisition failed: No access token returned"
    throw "No access token returned"
}
Write-Host "Token acquisition succeeded"

# Step 6: Verify SMTP host and port can be reached.
if (-not (Test-SmtpConnection -Server $smtpServer -Port ([int]$smtpPort))) {
    exit 1
}

# Step 7: Build curl SMTP arguments with OAuth bearer token.
$curl = (Get-Command curl -ErrorAction Stop).Source
$args = @(
    "--url", "smtp://$smtpServer`:$smtpPort",
    "--ssl-reqd",
    "--mail-from", $fromAddress,
    "--mail-rcpt", $toAddress,
    "--user", "$fromAddress:",
    "--oauth2-bearer", $accessToken,
    "--upload-file", "-",
    "--silent",
    "--show-error"
)

# Step 8: Send message body and report success/failure.
try {
    $body | & $curl @args 2>&1 | Out-String | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_.Trim())) {
            Write-Host $_.Trim()
        }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "curl exited with code $LASTEXITCODE"
    }
    Write-Host "Mail sent successfully"
}
catch {
    Write-Host "Mail send failed: $($_.Exception.Message)"
    exit 1
}

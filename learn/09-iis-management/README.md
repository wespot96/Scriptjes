# Module 09: IIS Management

## Learning Goals

- Manage websites and app pools using WebAdministration module
- Configure IIS bindings and site properties
- Use Get/Set-WebConfigurationProperty for configuration
- Manipulate web configuration programmatically
- Reference practical IIS administration scripts

## Key Concepts

### 1. Get-Website: List and Query Websites
```powershell
# Import module (auto-loaded on IIS servers)
Import-Module WebAdministration

# List all websites
Get-Website

# Get specific website
Get-Website -Name "Default Web Site"

# Website properties
$site = Get-Website -Name "Default Web Site"
$site.Name
$site.Id
$site.State        # Started, Stopped
$site.PhysicalPath
$site.ApplicationPool
$site.EnabledProtocols

# Check site status
if ((Get-Website -Name "Default Web Site").State -eq "Started") {
    Write-Host "Site is running"
}

# Get all site details
Get-Website | Select-Object Name, State, ApplicationPool, PhysicalPath
```

### 2. Start/Stop-Website
```powershell
# Start website
Start-Website -Name "Default Web Site"

# Stop website
Stop-Website -Name "Default Web Site"

# Restart (stop then start)
Stop-Website -Name "MyWebsite"
Start-Website -Name "MyWebsite"

# Start all websites
Get-Website | Start-Website

# Stop all except production
Get-Website | Where-Object { $_.Name -notlike "*Prod*" } | Stop-Website
```

### 3. New-Website: Create Website
```powershell
# Create basic website
New-Website -Name "MyWebsite" `
    -PhysicalPath "C:\inetpub\MyWebsite" `
    -Port 8080

# Create with SSL binding
New-WebBinding -Name "MyWebsite" `
    -IPAddress "*" `
    -Port 443 `
    -Protocol https `
    -HostHeader "mysite.com"

# Create with app pool
New-Website -Name "MyWebsite" `
    -PhysicalPath "C:\inetpub\MyWebsite" `
    -Port 8080 `
    -ApplicationPool "MyAppPool"

# Create folder if needed
New-Item -Path "C:\inetpub\MyWebsite" -ItemType Directory -Force
```

### 4. Get-WebAppPool: Manage Application Pools
```powershell
# List all app pools
Get-WebAppPool

# Get specific app pool
Get-WebAppPool -Name "DefaultAppPool"

# App pool properties
$pool = Get-WebAppPool -Name "DefaultAppPool"
$pool.Name
$pool.State         # Started, Stopped
$pool.ManagedRuntimeVersion  # v4.0, v2.0, etc.
$pool.Enable32BitAppOn64Bit
$pool.ProcessModel.IdentityType

# Filter by runtime
Get-WebAppPool | Where-Object { $_.ManagedRuntimeVersion -eq "v4.0" }
```

### 5. Start/Stop-WebAppPool
```powershell
# Start app pool
Start-WebAppPool -Name "DefaultAppPool"

# Stop app pool
Stop-WebAppPool -Name "DefaultAppPool"

# Recycle app pool
Restart-WebAppPool -Name "DefaultAppPool"

# Start all pools
Get-WebAppPool | Start-WebAppPool

# Find and restart pool by name pattern
Get-WebAppPool | Where-Object { $_.Name -like "*Test*" } | Restart-WebAppPool
```

### 6. New-WebAppPool: Create Application Pools
```powershell
# Create app pool with .NET Framework
New-WebAppPool -Name "MyAppPool" -Force

# Set runtime version
$pool = Get-WebAppPool -Name "MyAppPool"
$pool.ManagedRuntimeVersion = "v4.0"
$pool | Set-Item

# Create with no managed code
New-WebAppPool -Name "StaticContentPool"
$pool = Get-WebAppPool -Name "StaticContentPool"
$pool.ManagedRuntimeVersion = ""
$pool | Set-Item

# Configure identity
Set-ItemProperty -Path "IIS:\AppPools\MyAppPool" `
    -Name "ProcessModel.IdentityType" `
    -Value "ApplicationPoolIdentity"

# Configure recycling
Set-ItemProperty -Path "IIS:\AppPools\MyAppPool" `
    -Name "Recycling.PeriodicRestart.Schedule[0]" `
    -Value "04:00:00"
```

### 7. Get-WebBinding: Website Bindings
```powershell
# List all bindings
Get-WebBinding

# Get bindings for specific site
Get-WebBinding -Name "Default Web Site"

# Binding properties
$binding = Get-WebBinding -Name "Default Web Site" | Select-Object -First 1
$binding.BindingInformation  # IP:Port:HostHeader
$binding.Protocol            # http, https, net.tcp, etc.

# Get HTTPS bindings
Get-WebBinding | Where-Object { $_.Protocol -eq "https" }

# Get binding by host header
Get-WebBinding -Name "MyWebsite" | Where-Object { $_.HostHeader -eq "mysite.com" }
```

### 8. New-WebBinding: Add Bindings
```powershell
# Add HTTP binding
New-WebBinding -Name "MyWebsite" `
    -IPAddress "*" `
    -Port 80 `
    -Protocol http `
    -HostHeader "mysite.com"

# Add HTTPS binding
New-WebBinding -Name "MyWebsite" `
    -IPAddress "192.168.1.1" `
    -Port 443 `
    -Protocol https `
    -HostHeader "secure.mysite.com"

# Add FTP binding
New-WebBinding -Name "MyFTPSite" `
    -IPAddress "*" `
    -Port 21 `
    -Protocol ftp
```

### 9. Get-WebConfigurationProperty: Read Configuration
```powershell
# Get authentication settings
Get-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" `
    -Name enabled

# Get default document
Get-WebConfigurationProperty -Filter "/system.webServer/defaultDocument/files" `
    -Name "*"

# Get site bindings via config
Get-WebConfigurationProperty -PSPath "IIS:\Sites\Default Web Site" `
    -Filter "/system.applicationHost/sites/site[@name='Default Web Site']/bindings" `
    -Name "binding"

# Get handler mappings
Get-WebConfigurationProperty -Filter "/system.webServer/handlers" `
    -Name "*"
```

### 10. Set-WebConfigurationProperty: Modify Configuration
```powershell
# Enable anonymous authentication
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" `
    -PSPath "IIS:\Sites\MyWebsite" `
    -Name "enabled" `
    -Value "true"

# Set default document
Set-WebConfigurationProperty -Filter "/system.webServer/defaultDocument" `
    -PSPath "IIS:\Sites\MyWebsite" `
    -Name "enabled" `
    -Value "true"

# Add default document
Add-WebConfigurationProperty -Filter "/system.webServer/defaultDocument/files" `
    -PSPath "IIS:\Sites\MyWebsite" `
    -Name "." `
    -Value @{value="index.html"}

# Set application pool
Set-WebConfigurationProperty -PSPath "IIS:\Sites\MyWebsite" `
    -Filter "." `
    -Name "applicationPool" `
    -Value "MyAppPool"
```

### 11. Get-WebApplication and Get-WebVirtualDirectory
```powershell
# List applications under site
Get-WebApplication -Site "Default Web Site"

# Get specific application
Get-WebApplication -Site "Default Web Site" -Name "MyApp"

# Virtual directories
Get-WebVirtualDirectory -Site "Default Web Site"

# Application properties
$app = Get-WebApplication -Site "Default Web Site" -Name "MyApp"
$app.Path           # Virtual path
$app.PhysicalPath   # Disk path
$app.ApplicationPool
```

### 12. HTTP Headers and Security Configuration
```powershell
# Add response header
Add-WebConfigurationProperty -Filter "/system.webServer/httpProtocol/customHeaders" `
    -PSPath "IIS:\Sites\MyWebsite" `
    -Name "." `
    -Value @{name="X-Custom-Header"; value="CustomValue"}

# Remove header
Remove-WebConfigurationProperty -Filter "/system.webServer/httpProtocol/customHeaders" `
    -PSPath "IIS:\Sites\MyWebsite" `
    -Name "." `
    -AtIndex 0

# Enable compression
Set-WebConfigurationProperty -Filter "/system.webServer/httpCompression" `
    -PSPath "IIS:\Sites\MyWebsite" `
    -Name "directory" `
    -Value "C:\inetpub\temp\IIS Temporary Compressed Files"
```

## Real-World Example: HTTP Header Removal

Reference: **http_header_removal.ps1**

This script demonstrates:
- Querying website configuration
- Modifying HTTP response headers
- Removing security-sensitive headers
- Batch operations across multiple sites

```powershell
function Remove-ResponseHeader {
    param(
        [string]$SiteName,
        [string]$HeaderName
    )
    
    try {
        $filter = "/system.webServer/httpProtocol/customHeaders/add[@name='$HeaderName']"
        Remove-WebConfigurationProperty -Filter $filter `
            -PSPath "IIS:\Sites\$SiteName" `
            -ErrorAction Stop
        
        Write-Host "Removed $HeaderName from $SiteName"
    }
    catch {
        Write-Error "Failed to remove $HeaderName : $_"
    }
}

# Usage: Remove insecure headers from all sites
Get-Website | ForEach-Object {
    Remove-ResponseHeader -SiteName $_.Name -HeaderName "Server"
    Remove-ResponseHeader -SiteName $_.Name -HeaderName "X-AspNet-Version"
}
```

## Quick Reference: IIS Cmdlets

| Task | Cmdlet |
|------|--------|
| List websites | `Get-Website` |
| Start website | `Start-Website` |
| Stop website | `Stop-Website` |
| Create website | `New-Website` |
| List app pools | `Get-WebAppPool` |
| Start app pool | `Start-WebAppPool` |
| Create app pool | `New-WebAppPool` |
| Get bindings | `Get-WebBinding` |
| Add binding | `New-WebBinding` |
| Get configuration | `Get-WebConfigurationProperty` |
| Set configuration | `Set-WebConfigurationProperty` |
| Get applications | `Get-WebApplication` |

## Try It: Hands-On Exercises

### Exercise 1: List all websites and status
```powershell
Get-Website | Select-Object Name, State, PhysicalPath, ApplicationPool
```

### Exercise 2: Create website
```powershell
New-Item -Path "C:\inetpub\TestSite" -ItemType Directory -Force
New-Website -Name "TestSite" -PhysicalPath "C:\inetpub\TestSite" -Port 8081
```

### Exercise 3: App pool management
```powershell
New-WebAppPool -Name "TestPool"
Get-WebAppPool -Name "TestPool" | Select-Object Name, State, ManagedRuntimeVersion
```

### Exercise 4: Bindings
```powershell
Get-WebBinding | Select-Object HostHeader, Protocol, Port
```

### Exercise 5: Stop test sites
```powershell
Get-Website | Where-Object { $_.Name -like "*Test*" } | Stop-Website
```

### Exercise 6: Query configuration
```powershell
Get-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" `
    -PSPath "IIS:\Sites\Default Web Site" -Name enabled
```

### Exercise 7: Enable compression
```powershell
Set-WebConfigurationProperty -Filter "/system.webServer/httpCompression" `
    -PSPath "IIS:\Sites\Default Web Site" `
    -Name "enabled" -Value "true"
```

### Exercise 8: List virtual directories
```powershell
Get-WebVirtualDirectory -Site "Default Web Site" | Select-Object Name, PhysicalPath
```

## Further Reading

- [IIS PowerShell Cmdlets](https://learn.microsoft.com/en-us/iis-administration/powershell/overview)
- [WebAdministration Module](https://learn.microsoft.com/en-us/powershell/module/webadministration/)
- [IIS Configuration Reference](https://learn.microsoft.com/en-us/iis/configuration/)
- [IIS 10.0 Administration](https://learn.microsoft.com/en-us/iis/get-started/getting-started-with-iis)

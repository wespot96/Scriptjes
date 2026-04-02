# Module 10: Networking and Security

## Learning Goals

- Test network connectivity with Test-NetConnection and Resolve-DnsName
- Query network adapters and firewall rules
- Use TcpClient for advanced connection testing
- Resolve DNS names and perform lookups
- Configure firewall rules programmatically

## Key Concepts

### 1. Test-NetConnection: Network Diagnostics
```powershell
# Basic connectivity test
Test-NetConnection -ComputerName "server.example.com"

# Ping with count
Test-NetConnection -ComputerName "8.8.8.8" -Ping

# Test specific port
Test-NetConnection -ComputerName "server.example.com" -Port 443

# Test multiple ports
Test-NetConnection -ComputerName "server.example.com" -CommonTCPPort HTTP, HTTPS, RDP

# Show detailed output
Test-NetConnection -ComputerName "server.example.com" | Format-List

# Trace route
Test-NetConnection -ComputerName "server.example.com" -TraceRoute

# DiagnosticDescription for non-responsive hosts
$result = Test-NetConnection "192.168.1.1"
$result.DiagnosticsDescription  # Reason for failure
$result.RemoteAddress
$result.NameResolutionSucceeded
```

### 2. Resolve-DnsName: DNS Resolution
```powershell
# Resolve hostname
Resolve-DnsName -Name "server.example.com"

# Get all record types
Resolve-DnsName -Name "example.com" -Type A
Resolve-DnsName -Name "example.com" -Type MX
Resolve-DnsName -Name "example.com" -Type CNAME
Resolve-DnsName -Name "example.com" -Type SOA
Resolve-DnsName -Name "example.com" -Type SRV

# Reverse DNS lookup
Resolve-DnsName -Name "8.8.8.8" -Type PTR

# Query specific DNS server
Resolve-DnsName -Name "server.example.com" -Server "8.8.8.8"

# DNS resolution details
$result = Resolve-DnsName -Name "server.example.com"
$result.IPAddress       # Resolved IP
$result.Type           # Record type
```

### 3. Get-NetAdapter: Network Adapters
```powershell
# List all adapters
Get-NetAdapter

# Get specific adapter
Get-NetAdapter -Name "Ethernet"

# Adapter properties
$adapter = Get-NetAdapter -Name "Ethernet"
$adapter.Name
$adapter.MacAddress
$adapter.Status         # Up, Down, Disabled
$adapter.Speed         # 1 Gbps, 10 Gbps, etc.
$adapter.InterfaceDescription
$adapter.IfIndex

# Filter by status
Get-NetAdapter -Status Up

# Get virtual adapters
Get-NetAdapter | Where-Object { $_.Virtual -eq $true }

# Hardware address lookup
Get-NetAdapter | Select-Object Name, MacAddress
```

### 4. Get-NetIPConfiguration: IP Settings
```powershell
# Get IP config
Get-NetIPConfiguration

# Specific adapter
Get-NetIPConfiguration -InterfaceAlias "Ethernet"

# Properties
$config = Get-NetIPConfiguration -InterfaceAlias "Ethernet"
$config.IPv4Address     # IP address details
$config.IPv6Address
$config.IPv4DefaultGateway
$config.DNSServer       # DNS servers

# All addresses
Get-NetIPConfiguration -All | Select-Object InterfaceAlias, IPv4Address

# Filter by address family
Get-NetIPConfiguration | Where-Object { $_.IPv4Address.IPAddress -like "10.*" }
```

### 5. Get-NetFirewallRule: Firewall Rules
```powershell
# List all rules
Get-NetFirewallRule

# Get specific rule
Get-NetFirewallRule -DisplayName "Windows Remote Management*"

# Filter by direction
Get-NetFirewallRule -Direction Inbound

# Filter by action
Get-NetFirewallRule -Action Allow

# Rules for program
Get-NetFirewallRule -Program "C:\Program Files\*\*.exe"

# Enabled rules
Get-NetFirewallRule -Enabled True

# Rules with port info
Get-NetFirewallRule | Get-NetFirewallPortFilter |
    Where-Object { $_.LocalPort -eq 443 } |
    Select-Object -ExpandProperty OwningRule

# Rule details
$rule = Get-NetFirewallRule -DisplayName "RDP" | Select-Object -First 1
$rule.DisplayName
$rule.Direction
$rule.Action
$rule.Enabled
$rule.Description
```

### 6. New-NetFirewallRule: Create Firewall Rules
```powershell
# Allow inbound port
New-NetFirewallRule -DisplayName "Allow HTTP" `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 80

# Allow specific program
New-NetFirewallRule -DisplayName "Allow MyApp" `
    -Direction Inbound `
    -Action Allow `
    -Program "C:\Apps\myapp.exe"

# Allow specific source
New-NetFirewallRule -DisplayName "Allow Server" `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 3389 `
    -RemoteAddress "192.168.1.100"

# Block rule
New-NetFirewallRule -DisplayName "Block Internet" `
    -Direction Outbound `
    -Action Block `
    -RemoteAddress "0.0.0.0/0" `
    -RemotePort 443
```

### 7. Set-NetFirewallRule: Modify Rules
```powershell
# Enable rule
Set-NetFirewallRule -DisplayName "RDP" -Enabled $true

# Disable rule
Set-NetFirewallRule -DisplayName "RDP" -Enabled $false

# Change action
Set-NetFirewallRule -DisplayName "MyRule" -Action Block

# Update description
Set-NetFirewallRule -DisplayName "MyRule" -Description "Updated rule"

# Bulk operations
Get-NetFirewallRule -DisplayName "*Legacy*" | Set-NetFirewallRule -Enabled $false
```

### 8. TcpClient: Low-Level Network Testing
```powershell
# Test connection to port
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect("server.example.com", 443)
if ($client.Connected) { Write-Host "Port 443 is open" }
$client.Close()

# Timeout setting
$client = New-Object System.Net.Sockets.TcpClient
$asyncResult = $client.BeginConnect("server.example.com", 443, $null, $null)
$wait = $asyncResult.AsyncWaitHandle.WaitOne(5000, $false)
if ($wait -and $client.Connected) { Write-Host "Connected" }
$client.Close()

# Function for multiple ports
function Test-Port {
    param([string]$ComputerName, [int[]]$Ports)
    
    foreach ($port in $Ports) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $client.Connect($ComputerName, $port)
            Write-Host "Port $port : OPEN"
        }
        catch {
            Write-Host "Port $port : CLOSED"
        }
        finally {
            $client.Close()
        }
    }
}
```

### 9. Get-NetRoute: Routing Table
```powershell
# List all routes
Get-NetRoute

# Routes to destination
Get-NetRoute -DestinationPrefix "192.168.1.0/24"

# Routes by interface
Get-NetRoute -InterfaceAlias "Ethernet"

# Route details
$route = Get-NetRoute | Select-Object -First 1
$route.DestinationPrefix
$route.NextHop
$route.InterfaceAlias
$route.RouteMetric

# Default gateway
Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }
```

### 10. Get-NetConnectionProfile: Network Profiles
```powershell
# List network profiles
Get-NetConnectionProfile

# Profile properties
$profile = Get-NetConnectionProfile | Select-Object -First 1
$profile.Name
$profile.NetworkCategory   # Public, Private, DomainAuthenticated
$profile.InterfaceAlias
$profile.IPv6Connectivity
$profile.IPv4Connectivity

# Change profile category
Set-NetConnectionProfile -Name "Network" -NetworkCategory Private
```

### 11. Get-NetTCPConnection: Active Connections
```powershell
# List all TCP connections
Get-NetTCPConnection

# Listening ports
Get-NetTCPConnection -State Listen

# Established connections
Get-NetTCPConnection -State Established

# Connection details
$conn = Get-NetTCPConnection | Select-Object -First 1
$conn.LocalAddress
$conn.LocalPort
$conn.RemoteAddress
$conn.RemotePort
$conn.State           # Listen, Established, TimeWait, etc.
$conn.OwningProcess   # Process ID

# Connections by process
Get-NetTCPConnection -OwningProcess (Get-Process -Name "explorer").Id
```

### 12. Ping and Latency
```powershell
# Simple ping
Test-NetConnection -ComputerName "8.8.8.8" -Ping

# Multiple ping packets
for ($i = 1; $i -le 4; $i++) {
    $result = Test-NetConnection -ComputerName "8.8.8.8" -Ping
    $result.PingReplyDetails.RoundTripTime
}

# Average latency
$results = @()
for ($i = 1; $i -le 4; $i++) {
    $result = Test-NetConnection -ComputerName "server.example.com" -Ping
    if ($result.PingSucceeded) {
        $results += $result.PingReplyDetails.RoundTripTime
    }
}
if ($results) {
    [Math]::Round(($results | Measure-Object -Average).Average, 2)
}
```

## Real-World Example: Connection Testing

Reference: **ConnectionTest.ps1**

This script demonstrates:
- Multiple network connectivity tests
- Port scanning for service availability
- DNS resolution verification
- Network diagnostics and reporting

```powershell
function Test-ServerConnection {
    param(
        [string]$ComputerName,
        [int[]]$Ports = @(3389, 445, 135)
    )
    
    # Test basic connectivity
    $ping = Test-NetConnection -ComputerName $ComputerName -Ping
    
    # Resolve DNS
    $dns = try { 
        Resolve-DnsName -Name $ComputerName -ErrorAction Stop
        $true 
    } catch { 
        $false 
    }
    
    # Test ports
    $openPorts = @()
    foreach ($port in $Ports) {
        $result = Test-NetConnection -ComputerName $ComputerName -Port $port
        if ($result.TcpTestSucceeded) {
            $openPorts += $port
        }
    }
    
    [PSCustomObject]@{
        ComputerName = $ComputerName
        Responsive = $ping.PingSucceeded
        DnsResolved = $dns
        OpenPorts = $openPorts -join ","
        Timestamp = Get-Date
    }
}

Test-ServerConnection "Server01"
```

## Quick Reference: Network Cmdlets

| Task | Cmdlet |
|------|--------|
| Test connectivity | `Test-NetConnection` |
| Resolve DNS | `Resolve-DnsName` |
| List adapters | `Get-NetAdapter` |
| Get IP config | `Get-NetIPConfiguration` |
| Firewall rules | `Get-NetFirewallRule` |
| Create rule | `New-NetFirewallRule` |
| Routing table | `Get-NetRoute` |
| Active connections | `Get-NetTCPConnection` |
| Network profiles | `Get-NetConnectionProfile` |

## Try It: Hands-On Exercises

### Exercise 1: Test connectivity
```powershell
Test-NetConnection -ComputerName "8.8.8.8" -Ping
```

### Exercise 2: Resolve DNS
```powershell
Resolve-DnsName -Name "microsoft.com" -Type A
```

### Exercise 3: Test ports
```powershell
Test-NetConnection -ComputerName "server.example.com" -Port 443
```

### Exercise 4: List network adapters
```powershell
Get-NetAdapter | Select-Object Name, MacAddress, Status
```

### Exercise 5: Trace route
```powershell
Test-NetConnection -ComputerName "8.8.8.8" -TraceRoute
```

### Exercise 6: Firewall rules
```powershell
Get-NetFirewallRule -Enabled $true | Measure-Object
```

### Exercise 7: Active connections
```powershell
Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort
```

### Exercise 8: Network profile
```powershell
Get-NetConnectionProfile | Select-Object Name, NetworkCategory, InterfaceAlias
```

## Further Reading

- [Test-NetConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection)
- [Resolve-DnsName](https://learn.microsoft.com/en-us/powershell/module/dnsclient/resolve-dnsname)
- [NetTCPIP Module](https://learn.microsoft.com/en-us/powershell/module/nettcpip/)
- [NetSecurity Module](https://learn.microsoft.com/en-us/powershell/module/netsecurity/)
- [Windows Firewall Rules](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/windows-firewall-with-advanced-security)

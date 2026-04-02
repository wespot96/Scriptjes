# Module 11: Azure VM Basics

## Learning Goals

- Connect to Azure with Connect-AzAccount
- Query and manage virtual machines with Get-AzVM
- Create snapshots for disaster recovery
- Create restore points for rollback capability
- Understand Azure infrastructure-as-code patterns

**Note:** This module requires the Azure PowerShell module (Az). Install with `Install-Module -Name Az -AllowClobber`.

## Key Concepts

### 1. Install and Import Azure Module
```powershell
# Install Azure PowerShell module (one-time)
Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Import module
Import-Module Az

# Or just use it directly (auto-loads)
Connect-AzAccount

# Check installed version
Get-Module Az -ListAvailable | Select-Object Name, Version
```

### 2. Connect-AzAccount: Authenticate to Azure
```powershell
# Interactive login (opens browser)
Connect-AzAccount

# Device code authentication
Connect-AzAccount -DeviceCode

# Service principal authentication (automation)
$credential = New-Object System.Management.Automation.PSCredential `
    ("AppID", (ConvertTo-SecureString "Secret" -AsPlainText -Force))
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant "TenantID"

# Specify subscription
Connect-AzAccount -Subscription "SubscriptionName"

# Check current context
Get-AzContext

# List subscriptions
Get-AzSubscription

# Switch subscription
Set-AzContext -SubscriptionId "SubscriptionID"
```

### 3. Get-AzVM: Query Virtual Machines
```powershell
# List all VMs
Get-AzVM

# Get specific VM
Get-AzVM -Name "MyVM"

# Get VM in resource group
Get-AzVM -ResourceGroupName "Production" -Name "WebServer01"

# Get VM properties
$vm = Get-AzVM -Name "MyVM"
$vm.Name
$vm.VmId
$vm.StorageProfile.OsDisk.OsType  # Linux, Windows
$vm.HardwareProfile.VmSize        # Size like Standard_D2s_v3
$vm.OSProfile.ComputerName
$vm.ProvisioningState               # Succeeded, Failed, etc.

# List all VMs in resource group
Get-AzVM -ResourceGroupName "Production"

# Get VMs by tag
Get-AzVM | Where-Object { $_.Tags.Environment -eq "Prod" }
```

### 4. Get-AzVMStatus: Check VM Status
```powershell
# Get VM status
Get-AzVMStatus -ResourceGroupName "Production" -Name "MyVM"

# Status properties
$status = Get-AzVMStatus -ResourceGroupName "Production" -Name "MyVM"
$status.ProvisioningState    # Succeeded, Updating, etc.
$status.PowerState           # VM running, deallocated, etc.
$status.Statuses             # Array of status details

# All VMs status
Get-AzVM -ResourceGroupName "Production" | Get-AzVMStatus

# Filter by power state
Get-AzVM -ResourceGroupName "Production" | Get-AzVMStatus |
    Where-Object { $_.PowerState -eq "VM running" }
```

### 5. Start/Stop-AzVM: Control VMs
```powershell
# Start VM
Start-AzVM -ResourceGroupName "Production" -Name "MyVM"

# Stop VM (keeps resources allocated)
Stop-AzVM -ResourceGroupName "Production" -Name "MyVM" -Force

# Deallocate VM (releases compute resources)
Stop-AzVM -ResourceGroupName "Production" -Name "MyVM" -Force -StayProvisioned:$false

# Restart VM
Restart-AzVM -ResourceGroupName "Production" -Name "MyVM"

# Start multiple VMs
Get-AzVM -ResourceGroupName "Production" | Start-AzVM
```

### 6. New-AzSnapshot: Create Snapshots
```powershell
# Create snapshot from VM disk
$vm = Get-AzVM -ResourceGroupName "Production" -Name "MyVM"
$disk = Get-AzDisk -ResourceGroupName "Production" -Name $vm.StorageProfile.OsDisk.Name

$snapshotConfig = New-AzSnapshotConfig `
    -SourceUri $disk.Id `
    -Location "East US" `
    -CreateOption Copy

$snapshot = New-AzSnapshot -ResourceGroupName "Production" `
    -SnapshotName "MyVM-Backup-$(Get-Date -Format 'yyyyMMdd')" `
    -Snapshot $snapshotConfig

# Snapshot properties
$snapshot.Name
$snapshot.TimeCreated
$snapshot.Id
```

### 7. New-AzRestorePoint: Create Restore Points
```powershell
# Create restore point (if restore point collection exists)
$vm = Get-AzVM -ResourceGroupName "Production" -Name "MyVM"

New-AzRestorePoint -ResourceGroupName "Production" `
    -RestorePointCollectionName "MyVM-Restore" `
    -RestorePointName "BeforePatchUpdate-$(Get-Date -Format 'yyyyMMdd-HHmm')" `
    -VirtualMachineId $vm.Id

# List restore points
Get-AzRestorePoint -ResourceGroupName "Production" `
    -RestorePointCollectionName "MyVM-Restore"

# Restore from restore point (requires disk replacement)
```

### 8. Create-AzRestorePointCollection: Set Up Recovery
```powershell
# Create restore point collection first
$vm = Get-AzVM -ResourceGroupName "Production" -Name "MyVM"

New-AzRestorePointCollection -ResourceGroupName "Production" `
    -Name "MyVM-Recovery" `
    -Location "East US" `
    -VMId $vm.Id `
    -VirtualMachineId $vm.Id

# Enable restore point collection
$collection = Get-AzRestorePointCollection -ResourceGroupName "Production" `
    -Name "MyVM-Recovery"

# Add restore point
New-AzRestorePoint -ResourceGroupName "Production" `
    -RestorePointCollectionName "MyVM-Recovery" `
    -RestorePointName "Daily-$(Get-Date -Format 'yyyyMMdd')" `
    -VirtualMachineId $vm.Id
```

### 9. Get-AzSnapshot: Recover from Snapshots
```powershell
# List snapshots
Get-AzSnapshot -ResourceGroupName "Production"

# Get specific snapshot
$snapshot = Get-AzSnapshot -ResourceGroupName "Production" -SnapshotName "MyVM-Backup-20240115"

# Create disk from snapshot
$diskConfig = New-AzDiskConfig `
    -Location "East US" `
    -SourceResourceId $snapshot.Id `
    -CreateOption Copy

$disk = New-AzDisk -ResourceGroupName "Production" `
    -DiskName "MyVM-Restored-Disk" `
    -Disk $diskConfig

# Attach restored disk to new VM
$vm = New-AzVMConfig -VMName "RestoredVM" -VMSize "Standard_D2s_v3"
$vm = Add-AzVMDataDisk -VM $vm -ManagedDiskId $disk.Id -Lun 0 -CreateOption Attach
```

### 10. Backup and Recovery Patterns
```powershell
# Script: Daily snapshot backup
function Backup-AzVMDisk {
    param(
        [string]$ResourceGroup,
        [string]$VMName
    )
    
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
    $disk = Get-AzDisk -ResourceGroupName $ResourceGroup -Name $vm.StorageProfile.OsDisk.Name
    
    $snapshotConfig = New-AzSnapshotConfig -SourceUri $disk.Id -Location "East US" -CreateOption Copy
    $snapshotName = "$VMName-Backup-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    
    $snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroup `
        -SnapshotName $snapshotName `
        -Snapshot $snapshotConfig
    
    Write-Host "Snapshot created: $snapshotName"
    return $snapshot
}

# Usage
Backup-AzVMDisk -ResourceGroup "Production" -VMName "WebServer01"
```

### 11. Get-AzVMImage and Deployment
```powershell
# List available VM images
Get-AzVMImage -Location "East US" -PublisherName "MicrosoftWindowsServer" `
    -Offer "WindowsServer" -Skus "2022-Datacenter"

# Get VM resource details
$vm = Get-AzVM -ResourceGroupName "Production" -Name "MyVM" -Status

# VM networking
$vm.VirtualMachineProfile.NetworkProfile.NetworkInterfaces

# Get associated NICs
$nic = Get-AzNetworkInterface | Where-Object { $_.VirtualMachine.Id -eq $vm.Id }
```

### 12. Cost Management and Monitoring
```powershell
# Get VM size and estimate cost
$vm = Get-AzVM -Name "MyVM"
$vm.HardwareProfile.VmSize

# List running VMs to optimize costs
Get-AzVM | Get-AzVMStatus | Where-Object { $_.PowerState -eq "VM running" } |
    ForEach-Object { Get-AzVM -Name $_.Name }

# Deallocate unused VMs
Get-AzVM -ResourceGroupName "Development" | Get-AzVMStatus |
    Where-Object { $_.PowerState -eq "VM deallocated" } |
    Select-Object Name
```

## Real-World Example: Backup and Restore Workflow

Reference: Common Azure disaster recovery patterns.

```powershell
# Complete backup workflow
function Backup-AzureVM {
    param(
        [string]$ResourceGroup,
        [string]$VMName,
        [int]$RetentionDays = 30
    )
    
    # Create snapshot
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
    $disk = Get-AzDisk -ResourceGroupName $ResourceGroup `
        -Name $vm.StorageProfile.OsDisk.Name
    
    $config = New-AzSnapshotConfig -SourceUri $disk.Id `
        -Location "East US" -CreateOption Copy
    
    $date = Get-Date -Format 'yyyyMMdd-HHmm'
    $snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroup `
        -SnapshotName "$VMName-$date" -Snapshot $config
    
    # Create restore point
    New-AzRestorePoint -ResourceGroupName $ResourceGroup `
        -RestorePointCollectionName "$VMName-Recovery" `
        -RestorePointName "Backup-$date" `
        -VirtualMachineId $vm.Id
    
    # Log backup
    Write-Host "Backup completed: $($snapshot.Name)"
    return $snapshot
}

# Usage
Backup-AzureVM -ResourceGroup "Production" -VMName "WebServer01"
```

## Quick Reference: Azure VM Cmdlets

| Task | Cmdlet |
|------|--------|
| Connect to Azure | `Connect-AzAccount` |
| List VMs | `Get-AzVM` |
| Get VM status | `Get-AzVMStatus` |
| Start VM | `Start-AzVM` |
| Stop VM | `Stop-AzVM` |
| Create snapshot | `New-AzSnapshot` |
| List snapshots | `Get-AzSnapshot` |
| Create restore point | `New-AzRestorePoint` |
| Create collection | `New-AzRestorePointCollection` |
| Get context | `Get-AzContext` |
| Set subscription | `Set-AzContext` |

## Try It: Hands-On Exercises

**Prerequisites:** Must have Azure subscription and Az module installed.

### Exercise 1: Connect and list VMs
```powershell
Connect-AzAccount
Get-AzVM | Select-Object Name, ResourceGroupName
```

### Exercise 2: Check VM status
```powershell
$vm = Get-AzVM -Name "MyVM"
Get-AzVMStatus -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
```

### Exercise 3: Start/Stop VM
```powershell
Start-AzVM -ResourceGroupName "MyResourceGroup" -Name "MyVM"
Stop-AzVM -ResourceGroupName "MyResourceGroup" -Name "MyVM" -Force
```

### Exercise 4: Create snapshot
```powershell
$vm = Get-AzVM -Name "MyVM"
$disk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -Name $vm.StorageProfile.OsDisk.Name
$config = New-AzSnapshotConfig -SourceUri $disk.Id -Location "East US" -CreateOption Copy
New-AzSnapshot -ResourceGroupName $vm.ResourceGroupName -SnapshotName "MyVM-Backup" -Snapshot $config
```

### Exercise 5: List snapshots
```powershell
Get-AzSnapshot | Select-Object Name, TimeCreated
```

### Exercise 6: Get running VMs
```powershell
Get-AzVM | Get-AzVMStatus | Where-Object { $_.PowerState -eq "VM running" }
```

### Exercise 7: Switch subscription
```powershell
Get-AzSubscription
Set-AzContext -SubscriptionName "MySubscription"
```

### Exercise 8: VM resource details
```powershell
$vm = Get-AzVM -Name "MyVM" -ResourceGroupName "MyResourceGroup"
$vm | Select-Object Name, HardwareProfile, StorageProfile
```

## Further Reading

- [Azure PowerShell Module](https://learn.microsoft.com/en-us/powershell/azure/)
- [Get-AzVM Reference](https://learn.microsoft.com/en-us/powershell/module/az.compute/get-azvm)
- [Azure Snapshots](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/snapshot-copy-managed-disk)
- [Restore Points](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/create-restore-points)
- [Azure VM Management](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-powershell)

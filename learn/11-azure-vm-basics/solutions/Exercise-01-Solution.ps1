<#
.SYNOPSIS
    Exercise 01 Solution - Azure VM Snapshot Manager

.DESCRIPTION
    Connects to Azure, lists all VMs and their power states, creates a
    date-stamped snapshot of a specified VM's OS disk, lists existing snapshots
    for a resource group, and identifies snapshots older than a given threshold.

.NOTES
    Module:      11-azure-vm-basics
    Requires:    Az.Accounts, Az.Compute modules
                 Install-Module Az.Compute -Scope CurrentUser
    Target:      Windows Server 2022, PowerShell 5.1
    Author:      PoSh Learning Series

.EXAMPLE
    .\Exercise-01-Solution.ps1 -ResourceGroupName "Production" -VMName "WebServer01"

.EXAMPLE
    .\Exercise-01-Solution.ps1 -ResourceGroupName "Production" -VMName "WebServer01" -Location "East US" -AgeDaysThreshold 14
#>

#Requires -Modules Az.Accounts, Az.Compute

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure Resource Group name")]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true, HelpMessage = "Virtual Machine name to snapshot")]
    [string]$VMName,

    [Parameter(HelpMessage = "Azure region for the snapshot (defaults to VM location)")]
    [string]$Location,

    [Parameter(HelpMessage = "Number of days after which a snapshot is considered old")]
    [int]$AgeDaysThreshold = 30
)

# ---------------------------------------------------------------------------
# Section 1: Connect to Azure
# ---------------------------------------------------------------------------
$context = Get-AzContext
if (-not $context) {
    Write-Verbose "No Azure context found. Prompting for login..."
    Connect-AzAccount | Out-Null
    $context = Get-AzContext
}
Write-Host "Connected to subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Section 2: List All VMs and Their Power States
# ---------------------------------------------------------------------------
Write-Host "`n--- VMs in Resource Group: $ResourceGroupName ---" -ForegroundColor Cyan

$vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status

$vmReport = foreach ($v in $vms) {
    # PowerState is in the Statuses array; the entry whose Code starts with "PowerState/"
    $powerState = ($v.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

    [PSCustomObject]@{
        Name              = $v.Name
        ResourceGroupName = $v.ResourceGroupName
        PowerState        = $powerState
        VmSize            = $v.HardwareProfile.VmSize
    }
}

$vmReport | Format-Table -AutoSize

# ---------------------------------------------------------------------------
# Section 3: Create a Date-Stamped Snapshot of the VM's OS Disk
# ---------------------------------------------------------------------------
Write-Host "--- Creating Snapshot for VM: $VMName ---" -ForegroundColor Cyan

# Get the VM (without -Status so StorageProfile is populated)
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
if (-not $vm) {
    Write-Error "VM '$VMName' not found in resource group '$ResourceGroupName'."
    return
}

$osDiskName = $vm.StorageProfile.OsDisk.Name
Write-Verbose "OS Disk: $osDiskName"

$disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $osDiskName
if (-not $disk) {
    Write-Error "Disk '$osDiskName' not found."
    return
}

# Default location to the VM's region when not specified
if (-not $Location) {
    $Location = $vm.Location
    Write-Verbose "Using VM location: $Location"
}

$snapshotConfig = New-AzSnapshotConfig `
    -SourceUri $disk.Id `
    -Location $Location `
    -CreateOption Copy

$snapshotName = "{0}-snap-{1}" -f $VMName, (Get-Date -Format 'yyyyMMdd-HHmm')

Write-Verbose "Creating snapshot: $snapshotName"
$snapshot = New-AzSnapshot `
    -ResourceGroupName $ResourceGroupName `
    -SnapshotName $snapshotName `
    -Snapshot $snapshotConfig

Write-Host "Snapshot created successfully:" -ForegroundColor Green
Write-Host "  Name:        $($snapshot.Name)"
Write-Host "  TimeCreated: $($snapshot.TimeCreated)"
Write-Host "  DiskSizeGB:  $($snapshot.DiskSizeGB)"

# ---------------------------------------------------------------------------
# Section 4: List Existing Snapshots for the Resource Group
# ---------------------------------------------------------------------------
Write-Host "`n--- Snapshots in Resource Group: $ResourceGroupName ---" -ForegroundColor Cyan

$snapshots = Get-AzSnapshot -ResourceGroupName $ResourceGroupName

$snapshots |
    Select-Object Name, TimeCreated, DiskSizeGB, ProvisioningState |
    Format-Table -AutoSize

# ---------------------------------------------------------------------------
# Section 5: Find Snapshots Older Than the Threshold
# ---------------------------------------------------------------------------
Write-Host "--- Snapshots Older Than $AgeDaysThreshold Days ---" -ForegroundColor Cyan

$cutoffDate = (Get-Date).AddDays(-$AgeDaysThreshold)

$oldSnapshots = $snapshots | Where-Object { $_.TimeCreated -lt $cutoffDate }

if ($oldSnapshots) {
    $oldReport = foreach ($s in $oldSnapshots) {
        $ageDays = [math]::Floor(((Get-Date) - $s.TimeCreated).TotalDays)
        [PSCustomObject]@{
            Name        = $s.Name
            TimeCreated = $s.TimeCreated
            AgeDays     = $ageDays
        }
    }
    $oldReport | Format-Table -AutoSize
    Write-Host "Total old snapshots found: $($oldSnapshots.Count)" -ForegroundColor Yellow
}
else {
    Write-Host "No snapshots older than $AgeDaysThreshold days." -ForegroundColor Green
}

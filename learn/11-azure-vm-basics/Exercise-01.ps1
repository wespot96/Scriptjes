<#
.SYNOPSIS
    Exercise 01 - Azure VM Snapshot Manager

.DESCRIPTION
    Build a script that connects to Azure, lists all VMs and their power states,
    creates a date-stamped snapshot of a specified VM's OS disk, lists existing
    snapshots for a resource group, and identifies snapshots older than 30 days.

    Skills practiced:
    - Connect-AzAccount authentication
    - Get-AzVM and VM status queries
    - New-AzSnapshot with date-stamped naming
    - Get-AzSnapshot filtering and age calculations

.NOTES
    Module:      11-azure-vm-basics
    Requires:    Az.Accounts, Az.Compute modules
                 Install-Module Az.Compute -Scope CurrentUser
    Target:      Windows Server 2022, PowerShell 5.1
    Author:      PoSh Learning Series

.EXAMPLE
    .\Exercise-01.ps1 -ResourceGroupName "Production" -VMName "WebServer01"

.EXAMPLE
    .\Exercise-01.ps1 -ResourceGroupName "Production" -VMName "WebServer01" -Location "East US"
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
# TODO: Connect to Azure using Connect-AzAccount.
#       - Check if already connected with Get-AzContext before prompting login.
#       - If no context exists, call Connect-AzAccount.
#       - Print the current subscription name after connecting.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 2: List All VMs and Their Power States
# ---------------------------------------------------------------------------
# TODO: Retrieve every VM in the specified resource group.
#       - Use Get-AzVM with -ResourceGroupName.
#       - For each VM, get its status using Get-AzVM -Status to read PowerState.
#       - Output a table with columns: Name, ResourceGroupName, PowerState, VmSize.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 3: Create a Date-Stamped Snapshot of the VM's OS Disk
# ---------------------------------------------------------------------------
# TODO: Create a snapshot of the target VM's OS disk.
#       Steps:
#       1. Get the VM object with Get-AzVM.
#       2. Read the OS disk name from $vm.StorageProfile.OsDisk.Name.
#       3. Get the disk object with Get-AzDisk.
#       4. If -Location was not provided, default to the VM's Location.
#       5. Build a snapshot config with New-AzSnapshotConfig:
#            -SourceUri $disk.Id -Location $loc -CreateOption Copy
#       6. Generate a snapshot name: "<VMName>-snap-yyyyMMdd-HHmm"
#       7. Create the snapshot with New-AzSnapshot.
#       8. Output the snapshot name and TimeCreated.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 4: List Existing Snapshots for the Resource Group
# ---------------------------------------------------------------------------
# TODO: List all snapshots in the resource group.
#       - Use Get-AzSnapshot -ResourceGroupName.
#       - Output a table: Name, TimeCreated, DiskSizeGB, ProvisioningState.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 5: Find Snapshots Older Than the Threshold
# ---------------------------------------------------------------------------
# TODO: Filter snapshots older than $AgeDaysThreshold days.
#       - Calculate the cutoff date: (Get-Date).AddDays(-$AgeDaysThreshold).
#       - Filter with Where-Object { $_.TimeCreated -lt $cutoffDate }.
#       - For each old snapshot, output: Name, TimeCreated, and age in days.
#       - Print a summary count of old snapshots found.
# ---------------------------------------------------------------------------


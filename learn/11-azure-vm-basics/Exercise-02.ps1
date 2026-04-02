<#
.SYNOPSIS
    Exercise 02 - Snapshot Rotation Policy

.DESCRIPTION
    Build a script that implements a snapshot retention policy for Azure VMs.
    The script lists all snapshots per VM, keeps only the N most recent,
    removes older snapshots with -WhatIf support, tags snapshots with creation
    date and VM name metadata, and generates a retention report.

    Skills practiced:
    - Get-AzSnapshot with filtering and grouping
    - Remove-AzSnapshot with SupportsShouldProcess / -WhatIf
    - Update-AzSnapshot for tagging
    - Retention policy logic and reporting

.NOTES
    Module:      11-azure-vm-basics
    Requires:    Az.Accounts, Az.Compute modules
                 Install-Module Az.Compute -Scope CurrentUser
    Target:      Windows Server 2022, PowerShell 5.1
    Author:      PoSh Learning Series

.EXAMPLE
    .\Exercise-02.ps1 -ResourceGroupName "Production" -RetainCount 5

.EXAMPLE
    .\Exercise-02.ps1 -ResourceGroupName "Production" -RetainCount 3 -WhatIf

.EXAMPLE
    .\Exercise-02.ps1 -ResourceGroupName "Production" -RetainCount 5 -TagSnapshots
#>

#Requires -Modules Az.Accounts, Az.Compute

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure Resource Group name")]
    [string]$ResourceGroupName,

    [Parameter(HelpMessage = "Number of most-recent snapshots to keep per VM")]
    [ValidateRange(1, 100)]
    [int]$RetainCount = 5,

    [Parameter(HelpMessage = "Apply CreationDate and VMName tags to all snapshots")]
    [switch]$TagSnapshots
)

# ---------------------------------------------------------------------------
# Section 1: Connect to Azure
# ---------------------------------------------------------------------------
# TODO: Ensure an Azure connection exists.
#       - Use Get-AzContext to check; call Connect-AzAccount if needed.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 2: Retrieve and Group Snapshots by VM
# ---------------------------------------------------------------------------
# TODO: Get all snapshots in the resource group and group them by source VM.
#       Steps:
#       1. Get all snapshots with Get-AzSnapshot -ResourceGroupName.
#       2. For each snapshot, extract the source VM name.
#          Hint: Parse the snapshot name prefix (e.g., "WebServer01-snap-20240115-1030"
#          -> VM name is "WebServer01") or inspect the snapshot's
#          CreationData.SourceResourceId to find the disk/VM.
#       3. Group snapshots using Group-Object on the VM name.
#       4. Output a summary: VM name and snapshot count per group.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 3: Identify Snapshots to Remove (Keep N Most Recent)
# ---------------------------------------------------------------------------
# TODO: For each VM group, sort snapshots by TimeCreated descending and mark
#       those beyond $RetainCount for removal.
#       Steps:
#       1. Sort each group's snapshots by TimeCreated descending.
#       2. The first $RetainCount snapshots are "keep"; the rest are "remove".
#       3. Collect all "remove" candidates into a list.
#       4. Output a table of candidates: Name, TimeCreated, VMName, Action.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 4: Remove Old Snapshots with -WhatIf Support
# ---------------------------------------------------------------------------
# TODO: Delete each snapshot marked for removal, respecting ShouldProcess.
#       - Use $PSCmdlet.ShouldProcess($snapshotName, "Remove snapshot") to
#         gate the actual Remove-AzSnapshot call.
#       - Track successes and failures.
#       - When run with -WhatIf, no snapshots should be deleted; only
#         "What if" messages should appear.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 5: Tag Snapshots with Metadata
# ---------------------------------------------------------------------------
# TODO: When -TagSnapshots is specified, update every snapshot in the resource
#       group with the following tags:
#         CreationDate  = snapshot's TimeCreated in "yyyy-MM-dd" format
#         VMName        = source VM name (parsed in Section 2)
#         ManagedBy     = "SnapshotRotationPolicy"
#       Steps:
#       1. Only run this section when $TagSnapshots is present.
#       2. For each snapshot, build a hashtable of tags (merge with existing).
#       3. Use Update-AzSnapshot or New-AzSnapshotUpdateConfig + Update-AzSnapshot
#          to apply the tags.
#       4. Output each tagged snapshot name.
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Section 6: Generate Retention Report
# ---------------------------------------------------------------------------
# TODO: Produce a summary report to the console (and optionally a file).
#       Include:
#         - Total snapshots scanned
#         - Snapshots retained (per VM)
#         - Snapshots removed (or marked for removal in -WhatIf mode)
#         - Snapshots tagged (if -TagSnapshots was used)
#         - Oldest and newest snapshot dates
#       Format the report with Write-Host or a PSCustomObject collection.
# ---------------------------------------------------------------------------


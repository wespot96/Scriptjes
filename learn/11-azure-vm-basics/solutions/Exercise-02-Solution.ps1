<#
.SYNOPSIS
    Exercise 02 Solution - Snapshot Rotation Policy

.DESCRIPTION
    Implements a snapshot retention policy for Azure VMs. Lists all snapshots
    per VM, keeps only the N most recent, removes older snapshots with -WhatIf
    support, tags snapshots with creation date and VM name, and generates a
    retention report.

.NOTES
    Module:      11-azure-vm-basics
    Requires:    Az.Accounts, Az.Compute modules
                 Install-Module Az.Compute -Scope CurrentUser
    Target:      Windows Server 2022, PowerShell 5.1
    Author:      PoSh Learning Series

.EXAMPLE
    .\Exercise-02-Solution.ps1 -ResourceGroupName "Production" -RetainCount 5

.EXAMPLE
    .\Exercise-02-Solution.ps1 -ResourceGroupName "Production" -RetainCount 3 -WhatIf

.EXAMPLE
    .\Exercise-02-Solution.ps1 -ResourceGroupName "Production" -RetainCount 5 -TagSnapshots
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
$context = Get-AzContext
if (-not $context) {
    Write-Verbose "No Azure context found. Prompting for login..."
    Connect-AzAccount | Out-Null
    $context = Get-AzContext
}
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Section 2: Retrieve and Group Snapshots by VM
# ---------------------------------------------------------------------------
Write-Host "`n--- Retrieving Snapshots in Resource Group: $ResourceGroupName ---" -ForegroundColor Cyan

$allSnapshots = Get-AzSnapshot -ResourceGroupName $ResourceGroupName

if (-not $allSnapshots -or $allSnapshots.Count -eq 0) {
    Write-Warning "No snapshots found in resource group '$ResourceGroupName'."
    return
}

# Parse VM name from snapshot name (convention: "<VMName>-snap-yyyyMMdd-HHmm")
# Falls back to SourceResourceId if name doesn't match the convention.
function Get-VMNameFromSnapshot {
    param([object]$Snapshot)

    # Try name-based parsing first: everything before "-snap-"
    if ($Snapshot.Name -match '^(.+)-snap-\d{8}') {
        return $Matches[1]
    }

    # Fallback: extract disk name from SourceResourceId and strip common suffixes
    if ($Snapshot.CreationData.SourceResourceId) {
        $sourceId = $Snapshot.CreationData.SourceResourceId
        # Pattern: .../disks/<diskName>
        if ($sourceId -match '/disks/(.+)$') {
            $diskName = $Matches[1]
            # Remove common OS-disk suffixes like "_OsDisk_1_..."
            return ($diskName -replace '_OsDisk.*$', '')
        }
    }

    return "Unknown"
}

# Build a lookup of VM name per snapshot
$snapshotVMMap = @{}
foreach ($snap in $allSnapshots) {
    $snapshotVMMap[$snap.Name] = Get-VMNameFromSnapshot -Snapshot $snap
}

# Group by VM name
$grouped = $allSnapshots | Group-Object { $snapshotVMMap[$_.Name] }

Write-Host "`nSnapshots per VM:" -ForegroundColor Cyan
foreach ($group in $grouped) {
    Write-Host "  $($group.Name): $($group.Count) snapshot(s)"
}

# ---------------------------------------------------------------------------
# Section 3: Identify Snapshots to Remove (Keep N Most Recent)
# ---------------------------------------------------------------------------
Write-Host "`n--- Retention Analysis (Keep newest $RetainCount per VM) ---" -ForegroundColor Cyan

$toRetain  = [System.Collections.ArrayList]::new()
$toRemove  = [System.Collections.ArrayList]::new()

foreach ($group in $grouped) {
    $sorted = $group.Group | Sort-Object TimeCreated -Descending

    $keep   = $sorted | Select-Object -First $RetainCount
    $remove = $sorted | Select-Object -Skip  $RetainCount

    foreach ($s in $keep)   { [void]$toRetain.Add($s) }
    foreach ($s in $remove) { [void]$toRemove.Add($s) }
}

if ($toRemove.Count -gt 0) {
    Write-Host "`nSnapshots marked for removal:" -ForegroundColor Yellow
    $toRemove | ForEach-Object {
        [PSCustomObject]@{
            Name        = $_.Name
            VMName      = $snapshotVMMap[$_.Name]
            TimeCreated = $_.TimeCreated
            Action      = "Remove"
        }
    } | Format-Table -AutoSize
}
else {
    Write-Host "No snapshots exceed the retention count." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Section 4: Remove Old Snapshots with -WhatIf Support
# ---------------------------------------------------------------------------
$removedCount = 0
$failedCount  = 0

foreach ($snap in $toRemove) {
    $target = "Snapshot '$($snap.Name)' (Created: $($snap.TimeCreated))"

    if ($PSCmdlet.ShouldProcess($target, "Remove snapshot")) {
        try {
            Remove-AzSnapshot -ResourceGroupName $ResourceGroupName `
                              -SnapshotName $snap.Name `
                              -Force `
                              -ErrorAction Stop
            Write-Verbose "Removed: $($snap.Name)"
            $removedCount++
        }
        catch {
            Write-Warning "Failed to remove $($snap.Name): $_"
            $failedCount++
        }
    }
}

# ---------------------------------------------------------------------------
# Section 5: Tag Snapshots with Metadata
# ---------------------------------------------------------------------------
$taggedCount = 0

if ($TagSnapshots) {
    Write-Host "`n--- Tagging Snapshots ---" -ForegroundColor Cyan

    # Re-fetch snapshots (some may have been removed in Section 4)
    $currentSnapshots = Get-AzSnapshot -ResourceGroupName $ResourceGroupName

    foreach ($snap in $currentSnapshots) {
        $vmName = Get-VMNameFromSnapshot -Snapshot $snap

        # Merge new tags with any existing tags
        $tags = @{}
        if ($snap.Tags) {
            foreach ($key in $snap.Tags.Keys) {
                $tags[$key] = $snap.Tags[$key]
            }
        }
        $tags['CreationDate'] = $snap.TimeCreated.ToString('yyyy-MM-dd')
        $tags['VMName']       = $vmName
        $tags['ManagedBy']    = 'SnapshotRotationPolicy'

        $updateConfig = New-AzSnapshotUpdateConfig -Tag $tags

        Update-AzSnapshot -ResourceGroupName $ResourceGroupName `
                          -SnapshotName $snap.Name `
                          -SnapshotUpdate $updateConfig | Out-Null

        Write-Verbose "Tagged: $($snap.Name)"
        $taggedCount++
    }

    Write-Host "Tagged $taggedCount snapshot(s)." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Section 6: Generate Retention Report
# ---------------------------------------------------------------------------
Write-Host "`n===== Snapshot Retention Report =====" -ForegroundColor Cyan

$allDates = $allSnapshots | ForEach-Object { $_.TimeCreated } | Sort-Object

$report = [PSCustomObject]@{
    ResourceGroup     = $ResourceGroupName
    TotalScanned      = $allSnapshots.Count
    RetainedCount     = $toRetain.Count
    RemovedCount      = $removedCount
    FailedRemovals    = $failedCount
    MarkedForRemoval  = $toRemove.Count
    TaggedCount       = $taggedCount
    OldestSnapshot    = if ($allDates.Count -gt 0) { $allDates[0].ToString('yyyy-MM-dd HH:mm') } else { 'N/A' }
    NewestSnapshot    = if ($allDates.Count -gt 0) { $allDates[-1].ToString('yyyy-MM-dd HH:mm') } else { 'N/A' }
    RetainCountPolicy = $RetainCount
    WhatIfMode        = $WhatIfPreference
}

$report | Format-List

# Per-VM breakdown
Write-Host "Per-VM Breakdown:" -ForegroundColor Cyan
foreach ($group in $grouped) {
    $sorted     = $group.Group | Sort-Object TimeCreated -Descending
    $keepCount  = [math]::Min($RetainCount, $sorted.Count)
    $dropCount  = [math]::Max(0, $sorted.Count - $RetainCount)

    [PSCustomObject]@{
        VMName   = $group.Name
        Total    = $group.Count
        Retained = $keepCount
        Removed  = $dropCount
    }
} | Format-Table -AutoSize

Write-Host "===== End of Report =====" -ForegroundColor Cyan

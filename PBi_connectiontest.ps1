<#
.SYNOPSIS
  Generic host/port TCP connectivity test with optional GUI target builder.

.DESCRIPTION
  Test one or more host/port combinations, export results to CSV, and optionally
  use a Windows Forms GUI to add and manage targets interactively.

.EXAMPLE
  .\PBi_connectiontest.ps1

.EXAMPLE
  .\PBi_connectiontest.ps1 -NoGui -Targets "google.com:443,80","1.1.1.1:53" -TimeoutMs 3000
#>

[CmdletBinding()]
param(
    [string[]]$Targets = @(),
    [string]$OutputFolder = "$HOME/ConnectionTest",
    [int]$TimeoutMs = 5000,
    [switch]$NoGui
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-Target {
    param(
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][int[]]$Ports,
        [string]$Category = "Custom"
    )

    [pscustomobject]@{
        Host = $Host.Trim()
        Ports = $Ports | Sort-Object -Unique
        Category = if ([string]::IsNullOrWhiteSpace($Category)) { "Custom" } else { $Category.Trim() }
    }
}

function ConvertTo-PortList {
    param([Parameter(Mandatory)][string]$PortText)

    $ports = @()
    foreach ($item in ($PortText -split ',')) {
        $token = $item.Trim()
        if ([string]::IsNullOrWhiteSpace($token)) {
            continue
        }

        [int]$portValue = 0
        if (-not [int]::TryParse($token, [ref]$portValue) -or $portValue -lt 1 -or $portValue -gt 65535) {
            throw "Invalid port '$token'. Use values between 1 and 65535."
        }
        $ports += $portValue
    }

    if ($ports.Count -eq 0) {
        throw "At least one port is required."
    }

    $ports | Sort-Object -Unique
}

function ConvertTo-TargetsFromCli {
    param([string[]]$TargetArgs)

    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in $TargetArgs) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $parts = $entry.Split(':', 2)
        if ($parts.Count -ne 2) {
            throw "Target '$entry' is invalid. Expected format: host:port1,port2"
        }

        $host = $parts[0].Trim()
        $ports = ConvertTo-PortList -PortText $parts[1]
        $list.Add((New-Target -Host $host -Ports $ports -Category "CLI"))
    }

    return $list
}

function Resolve-HostIPs {
    param([Parameter(Mandatory)][string]$Host)

    try {
        [System.Net.Dns]::GetHostAddresses($Host) |
            Where-Object { $_.AddressFamily -in @([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.AddressFamily]::InterNetworkV6) } |
            ForEach-Object { $_.ToString() } |
            Select-Object -Unique
    }
    catch {
        @()
    }
}

function Test-TcpPort {
    param(
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][int]$Port,
        [Parameter(Mandatory)][int]$Timeout
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect($Host, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($Timeout, $false)) {
            return @{ Success = $false; Error = "TCP timeout after $Timeout ms" }
        }

        $client.EndConnect($async)
        return @{ Success = $true; Error = "" }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
    finally {
        $client.Dispose()
    }
}

function Test-Endpoint {
    param(
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][int]$Port,
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][int]$Timeout
    )

    $dnsIPs = Resolve-HostIPs -Host $Host
    $dnsOK = $dnsIPs.Count -gt 0

    $tcpResult = Test-TcpPort -Host $Host -Port $Port -Timeout $Timeout
    $tcpOK = [bool]$tcpResult.Success
    $status = if ($dnsOK -and $tcpOK) { "Open" } else { "Failed" }

    [pscustomobject]@{
        Timestamp = Get-Date
        Category = $Category
        Host = $Host
        Port = $Port
        DNSResolved = $dnsOK
        ResolvedIPs = ($dnsIPs -join ';')
        TcpSucceeded = $tcpOK
        Status = $status
        Error = $tcpResult.Error
    }
}

function Show-TargetBuilderGui {
    [CmdletBinding()]
    param()

    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
    }
    catch {
        throw "GUI is not available on this PowerShell host. Use -NoGui with -Targets instead."
    }

    [System.Windows.Forms.Application]::EnableVisualStyles()

    $targets = [System.Collections.Generic.List[object]]::new()

    $form = [System.Windows.Forms.Form]::new()
    $form.Text = "Connection Test - Target Builder"
    $form.StartPosition = "CenterScreen"
    $form.Size = [System.Drawing.Size]::new(860, 560)

    $lblHost = [System.Windows.Forms.Label]::new()
    $lblHost.Text = "Host"
    $lblHost.Location = [System.Drawing.Point]::new(15, 15)
    $lblHost.AutoSize = $true
    $form.Controls.Add($lblHost)

    $txtHost = [System.Windows.Forms.TextBox]::new()
    $txtHost.Location = [System.Drawing.Point]::new(15, 35)
    $txtHost.Size = [System.Drawing.Size]::new(310, 24)
    $form.Controls.Add($txtHost)

    $lblPorts = [System.Windows.Forms.Label]::new()
    $lblPorts.Text = "Ports (comma-separated)"
    $lblPorts.Location = [System.Drawing.Point]::new(340, 15)
    $lblPorts.AutoSize = $true
    $form.Controls.Add($lblPorts)

    $txtPorts = [System.Windows.Forms.TextBox]::new()
    $txtPorts.Location = [System.Drawing.Point]::new(340, 35)
    $txtPorts.Size = [System.Drawing.Size]::new(230, 24)
    $txtPorts.Text = "443"
    $form.Controls.Add($txtPorts)

    $lblCategory = [System.Windows.Forms.Label]::new()
    $lblCategory.Text = "Category (optional)"
    $lblCategory.Location = [System.Drawing.Point]::new(585, 15)
    $lblCategory.AutoSize = $true
    $form.Controls.Add($lblCategory)

    $txtCategory = [System.Windows.Forms.TextBox]::new()
    $txtCategory.Location = [System.Drawing.Point]::new(585, 35)
    $txtCategory.Size = [System.Drawing.Size]::new(240, 24)
    $txtCategory.Text = "Custom"
    $form.Controls.Add($txtCategory)

    $btnAdd = [System.Windows.Forms.Button]::new()
    $btnAdd.Text = "Add Target"
    $btnAdd.Location = [System.Drawing.Point]::new(15, 70)
    $btnAdd.Size = [System.Drawing.Size]::new(110, 30)
    $form.Controls.Add($btnAdd)

    $btnRemove = [System.Windows.Forms.Button]::new()
    $btnRemove.Text = "Remove Selected"
    $btnRemove.Location = [System.Drawing.Point]::new(135, 70)
    $btnRemove.Size = [System.Drawing.Size]::new(130, 30)
    $form.Controls.Add($btnRemove)

    $btnClear = [System.Windows.Forms.Button]::new()
    $btnClear.Text = "Clear All"
    $btnClear.Location = [System.Drawing.Point]::new(275, 70)
    $btnClear.Size = [System.Drawing.Size]::new(90, 30)
    $form.Controls.Add($btnClear)

    $btnRun = [System.Windows.Forms.Button]::new()
    $btnRun.Text = "Run Tests"
    $btnRun.Location = [System.Drawing.Point]::new(735, 480)
    $btnRun.Size = [System.Drawing.Size]::new(90, 30)
    $btnRun.BackColor = [System.Drawing.Color]::LightGreen
    $form.Controls.Add($btnRun)

    $grid = [System.Windows.Forms.DataGridView]::new()
    $grid.Location = [System.Drawing.Point]::new(15, 115)
    $grid.Size = [System.Drawing.Size]::new(810, 355)
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.ReadOnly = $true
    $grid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $grid.MultiSelect = $false
    $form.Controls.Add($grid)

    $table = [System.Data.DataTable]::new()
    [void]$table.Columns.Add("Host", [string])
    [void]$table.Columns.Add("Ports", [string])
    [void]$table.Columns.Add("Category", [string])
    $grid.DataSource = $table

    $refreshGrid = {
        $table.Rows.Clear()
        foreach ($t in $targets) {
            [void]$table.Rows.Add($t.Host, ($t.Ports -join ','), $t.Category)
        }
    }

    $btnAdd.Add_Click({
        try {
            if ([string]::IsNullOrWhiteSpace($txtHost.Text)) {
                throw "Host is required."
            }

            $ports = ConvertTo-PortList -PortText $txtPorts.Text
            $target = New-Target -Host $txtHost.Text -Ports $ports -Category $txtCategory.Text
            $targets.Add($target)
            & $refreshGrid
            $txtHost.Clear()
            $txtHost.Focus()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Invalid Target", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        }
    })

    $btnRemove.Add_Click({
        if ($grid.SelectedRows.Count -gt 0) {
            $idx = $grid.SelectedRows[0].Index
            if ($idx -ge 0 -and $idx -lt $targets.Count) {
                $targets.RemoveAt($idx)
                & $refreshGrid
            }
        }
    })

    $btnClear.Add_Click({
        $targets.Clear()
        & $refreshGrid
    })

    $script:runClicked = $false
    $btnRun.Add_Click({
        if ($targets.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Add at least one target before running tests.", "No Targets", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            return
        }

        $script:runClicked = $true
        $form.Close()
    })

    # Optional starter rows that users can edit/remove.
    $targets.Add((New-Target -Host "google.com" -Ports @(443) -Category "Web"))
    $targets.Add((New-Target -Host "1.1.1.1" -Ports @(53) -Category "DNS"))
    & $refreshGrid

    [void]$form.ShowDialog()

    if (-not $script:runClicked) {
        return [System.Collections.Generic.List[object]]::new()
    }

    return $targets
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

$targetsToTest = $null
if (-not $NoGui) {
    try {
        $targetsToTest = Show-TargetBuilderGui
    }
    catch {
        Write-Warning $_.Exception.Message
        Write-Warning "Falling back to CLI mode. Use -NoGui to suppress this warning."
    }
}

if ($null -eq $targetsToTest -or $targetsToTest.Count -eq 0) {
    if ($Targets.Count -eq 0) {
        throw "No targets provided. Use GUI to add targets or pass -Targets 'host:port1,port2'."
    }

    $targetsToTest = ConvertTo-TargetsFromCli -TargetArgs $Targets
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$detailedCsv = Join-Path $OutputFolder "ConnectionTest-Detailed-$ts.csv"

$results = foreach ($t in $targetsToTest) {
    foreach ($p in $t.Ports) {
        Test-Endpoint -Host $t.Host -Port $p -Category $t.Category -Timeout $TimeoutMs
    }
}

$results | Sort-Object Status,Host,Port | Export-Csv -Path $detailedCsv -NoTypeInformation -Encoding UTF8

$failed = $results | Where-Object { $_.Status -eq "Failed" }

Write-Host ""
Write-Host "Detailed CSV : $detailedCsv"
Write-Host "Total tests  : $($results.Count)"
Write-Host "Failures     : $($failed.Count)"

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed checks:"
    $failed | Select-Object Timestamp,Category,Host,Port,DNSResolved,TcpSucceeded,Error | Format-Table -AutoSize
    exit 1
}

Write-Host "All checks succeeded."
exit 0
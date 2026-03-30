<#
.SYNOPSIS
  Generic host/port TCP connectivity test with optional GUI target builder.

.DESCRIPTION
  Test one or more host/port combinations, export results to CSV, and optionally
  use a Windows Forms GUI to add and manage targets interactively.

.EXAMPLE
  .\ConnectionTest.ps1

.EXAMPLE
  .\ConnectionTest.ps1 -NoGui -Targets "google.com:443,80","1.1.1.1:53" -TimeoutMs 3000
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

function Add-OrMergeTarget {
    param(
        [Parameter(Mandatory)][System.Collections.Generic.List[object]]$TargetList,
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][int[]]$Ports,
        [string]$Category = "Custom"
    )

    $normalizedHost = $Host.Trim()
    $normalizedCategory = if ([string]::IsNullOrWhiteSpace($Category)) { "Custom" } else { $Category.Trim() }

    $existing = $TargetList | Where-Object {
        $_.Host.Equals($normalizedHost, [System.StringComparison]::OrdinalIgnoreCase) -and
        $_.Category.Equals($normalizedCategory, [System.StringComparison]::OrdinalIgnoreCase)
    } | Select-Object -First 1

    if ($null -eq $existing) {
        $TargetList.Add((New-Target -Host $normalizedHost -Ports $Ports -Category $normalizedCategory))
        return
    }

    $existing.Ports = @($existing.Ports + $Ports) | Sort-Object -Unique
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

function Import-TargetsFromCsv {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -Path $Path)) {
        throw "CSV file not found: $Path"
    }

    $rows = Import-Csv -Path $Path -Header Host,Port
    $list = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 1

    foreach ($row in $rows) {
        $host = [string]$row.Host
        $portText = [string]$row.Port
        $host = $host.Trim()
        $portText = $portText.Trim()

        if ($lineNumber -eq 1 -and $host -match '^(host|hostname)$' -and $portText -match '^port$') {
            $lineNumber++
            continue
        }

        if ([string]::IsNullOrWhiteSpace($host) -and [string]::IsNullOrWhiteSpace($portText)) {
            $lineNumber++
            continue
        }

        if ([string]::IsNullOrWhiteSpace($host)) {
            throw "CSV line $lineNumber is missing hostname in column 1."
        }

        $ports = ConvertTo-PortList -PortText $portText
        Add-OrMergeTarget -TargetList $list -Host $host -Ports $ports -Category "CSV"
        $lineNumber++
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
    $form.Size = [System.Drawing.Size]::new(980, 560)

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

    $btnImport = [System.Windows.Forms.Button]::new()
    $btnImport.Text = "Import CSV"
    $btnImport.Location = [System.Drawing.Point]::new(375, 70)
    $btnImport.Size = [System.Drawing.Size]::new(100, 30)
    $form.Controls.Add($btnImport)

    $btnRun = [System.Windows.Forms.Button]::new()
    $btnRun.Text = "Run Tests"
    $btnRun.Location = [System.Drawing.Point]::new(855, 480)
    $btnRun.Size = [System.Drawing.Size]::new(90, 30)
    $btnRun.BackColor = [System.Drawing.Color]::LightGreen
    $form.Controls.Add($btnRun)

    $grid = [System.Windows.Forms.DataGridView]::new()
    $grid.Location = [System.Drawing.Point]::new(15, 115)
    $grid.Size = [System.Drawing.Size]::new(930, 355)
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
            Add-OrMergeTarget -TargetList $targets -Host $txtHost.Text -Ports $ports -Category $txtCategory.Text
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

    $btnImport.Add_Click({
        try {
            $dialog = [System.Windows.Forms.OpenFileDialog]::new()
            $dialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
            $dialog.Title = "Select CSV with Hostname in column 1 and Port in column 2"
            $dialog.Multiselect = $false

            if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }

            $imported = Import-TargetsFromCsv -Path $dialog.FileName
            foreach ($item in $imported) {
                Add-OrMergeTarget -TargetList $targets -Host $item.Host -Ports $item.Ports -Category $item.Category
            }

            & $refreshGrid
            [System.Windows.Forms.MessageBox]::Show("Imported $($imported.Count) target row(s).", "Import Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CSV Import Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
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
    Add-OrMergeTarget -TargetList $targets -Host "google.com" -Ports @(443) -Category "Web"
    Add-OrMergeTarget -TargetList $targets -Host "1.1.1.1" -Ports @(53) -Category "DNS"
    & $refreshGrid

    [void]$form.ShowDialog()

    if (-not $script:runClicked) {
        return [System.Collections.Generic.List[object]]::new()
    }

    return $targets
}

function Show-ResultsGui {
    param(
        [Parameter(Mandatory)][object[]]$Results,
        [Parameter(Mandatory)][string]$CsvPath
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $form = [System.Windows.Forms.Form]::new()
    $form.Text = "Connection Test - Results"
    $form.StartPosition = "CenterScreen"
    $form.Size = [System.Drawing.Size]::new(1150, 620)

    $failedCount = @($Results | Where-Object { $_.Status -eq "Failed" }).Count
    $summary = [System.Windows.Forms.Label]::new()
    $summary.Text = "Total tests: $($Results.Count)    Failed: $failedCount    CSV: $CsvPath"
    $summary.Location = [System.Drawing.Point]::new(15, 15)
    $summary.Size = [System.Drawing.Size]::new(1110, 24)
    $form.Controls.Add($summary)

    $grid = [System.Windows.Forms.DataGridView]::new()
    $grid.Location = [System.Drawing.Point]::new(15, 45)
    $grid.Size = [System.Drawing.Size]::new(1110, 490)
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.ReadOnly = $true
    $grid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $grid.MultiSelect = $false
    $grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::DisplayedCells
    $form.Controls.Add($grid)

    $btnOpenCsv = [System.Windows.Forms.Button]::new()
    $btnOpenCsv.Text = "Open CSV"
    $btnOpenCsv.Location = [System.Drawing.Point]::new(925, 545)
    $btnOpenCsv.Size = [System.Drawing.Size]::new(95, 30)
    $form.Controls.Add($btnOpenCsv)

    $btnClose = [System.Windows.Forms.Button]::new()
    $btnClose.Text = "Close"
    $btnClose.Location = [System.Drawing.Point]::new(1030, 545)
    $btnClose.Size = [System.Drawing.Size]::new(95, 30)
    $form.Controls.Add($btnClose)

    $table = [System.Data.DataTable]::new()
    [void]$table.Columns.Add("Timestamp", [string])
    [void]$table.Columns.Add("Category", [string])
    [void]$table.Columns.Add("Host", [string])
    [void]$table.Columns.Add("Port", [int])
    [void]$table.Columns.Add("DNSResolved", [bool])
    [void]$table.Columns.Add("ResolvedIPs", [string])
    [void]$table.Columns.Add("TcpSucceeded", [bool])
    [void]$table.Columns.Add("Status", [string])
    [void]$table.Columns.Add("Error", [string])

    foreach ($r in ($Results | Sort-Object Status,Host,Port)) {
        [void]$table.Rows.Add(
            $r.Timestamp,
            $r.Category,
            $r.Host,
            $r.Port,
            $r.DNSResolved,
            $r.ResolvedIPs,
            $r.TcpSucceeded,
            $r.Status,
            $r.Error
        )
    }

    $grid.DataSource = $table

    $grid.add_DataBindingComplete({
        foreach ($row in $grid.Rows) {
            if ($row.Cells[7].Value -eq "Failed") {
                $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::MistyRose
            }
            else {
                $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Honeydew
            }
        }
    })

    $btnOpenCsv.Add_Click({
        try {
            Start-Process -FilePath $CsvPath
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Unable to open CSV: $CsvPath", "Open CSV Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    })

    $btnClose.Add_Click({
        $form.Close()
    })

    [void]$form.ShowDialog()
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
    $exitCode = 1
}
else {
    Write-Host "All checks succeeded."
    $exitCode = 0
}

if (-not $NoGui) {
    try {
        Show-ResultsGui -Results $results -CsvPath $detailedCsv
    }
    catch {
        Write-Warning "Could not show results GUI: $($_.Exception.Message)"
    }
}

exit $exitCode
param(
    [Parameter(Mandatory = $true)]
    [int]$TargetPid
)
$history = @{}

while ($true) {
    # Fetch current TCP states for the target PID
    $currentConnections = Get-NetTCPConnection | 
        # Change -ine to -eq to include only connections for the target PID
        Where-Object { $_.OwningProcess -ine $TargetPid } |
        Select-Object LocalAdress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}}

    $currentKeys = @()

    foreach ($conn in $currentConnections) {
        $key = "$($conn.RemoteAddress):$($conn.RemotePort)"
        $currentKeys += $key
        $stateString = $conn.State.ToString()

        # Check if the connection is new or the state has changed
        if (-not $history.ContainsKey($key)) {
            Write-Host "[NEW]      $key - $stateString - PID: $($conn.OwningProcess) - ProcessName: $($conn.ProcessName)" -ForegroundColor Cyan
            $history[$key] = $stateString
        } 
        elseif ($history[$key] -ne $stateString) {
            Write-Host "[CHANGED]  $key - $($history[$key]) -> $stateString - PID: $($conn.OwningProcess)" -ForegroundColor Yellow
            "$((Get-Date).ToString('yyyy-mm-dd HH:mm:ss')) - $history[$key] - $stateString - PID: $($conn.OwningProcess)" | Out-File "connection_log.txt" -Append
            $history[$key] = $stateString
        }
    }

    # Cleanup: Remove closed connections from history to keep memory clean
    @($history.Keys) | Where-Object { $_ -notin $currentKeys } | ForEach-Object {
        Write-Host "[CLOSED]   $_" -ForegroundColor Red
        $history.Remove($_)
    }

    Start-Sleep -Seconds 1
}

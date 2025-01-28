# Script for nightly Task Scheduler shutdown

# Message to display shutdown
$timer = 30
while ($timer -gt 0) {
    if ([console]::KeyAvaliable) {
        [void][console]::ReadKey($true)
        Write-Host "`nShutdown aborted."
        break
    }
    Write-Host -NoNewline "`rSystem will shutdown in $timer seconds. Press any key to abort"
    Start-Sleep -Seconds 1
    $timer--
}
# Shutdown
if ($timer -eq 0) {
    Write-Host "`nShutting down..."
    Stop-Computer -Force
}

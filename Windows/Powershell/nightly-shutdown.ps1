# Script for nightly Task Scheduler shutdown

# Message to display shutdown
$timer = 30
while ($timer -gt 0) {
    if ([console]::KeyAvaliable) {
        [void][console]::ReadKey($true)
        Write-Host -ForegroundColor Green -BackgroundColor Black "`nShutdown aborted."
        break
    }
    Write-Host -NoNewline -ForegroundColor Red -BackgroundColor Black "`rSystem will shutdown in $timer seconds. Press any key to abort"
    Start-Sleep -Seconds 1
    $timer--
}
# Shutdown
if ($timer -eq 0) {
    Write-Host -ForegroundColor Red -BackgroundColor Black "`nShutting down..." 
    Stop-Computer -Force
}

# Script for running various maintenance tasks on Windows PCs

# This script performs the following tasks:
# 1. Sets Restore Point
# 3. Disk Cleanup
# 4. Disk Optimization
# 5. Windows Updates
# 6. Software Updates
# 7. Reboot if necessary
# 9. Checks for driver updates
# 10. Creates a report of proccesses/files using high CPU, memory, and/or disk usage

# Check if gsudo is installed
$sudoSource = Get-Command gsudo -ErrorAction SilentlyContinue | Select-Object Source
if ($null -eq $sudoSource) {
    $response = Read-Host "gsudo is not installed. Would you like to install it? [Y/N]"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Installing gsudo..." -ForegroundColor Green -BackgroundColor Black
        winget install gerardog.gsudo
    }
    else {
        Write-Host "Not installing gsudo. Ending script" -ForegroundColor Red -BackgroundColor Black
        Start-Sleep -Seconds 5
        exit
    }
# This script is used to start the MySQL Workbench and the MySQL80 service.
# I have the service set as manual, due to it being a memory hog.

# Check if gsudo is installed
$sudoSource = Get-Command gsudo -ErrorAction SilentlyContinue | Select-Object Source
if ($null -eq $sudoSource) {
    $response = Read-Host "gsudo is not installed. Would you like to install it? [Y/N]"
    if ($response -eq 'Y' -or $response -eq 'y'){
        Write-Host "Installing gsudo..." -ForegroundColor Green -BackgroundColor Black
        winget install gerardog.gsudo
    }
    else {
        Write-Host "Not installing gsudo. Ending script" -ForegroundColor Red -BackgroundColor Black
        Start-Sleep -Seconds 5
        exit
    }

}
# Start MySQL80 service

# Check if MySQL80 service is running
$service = Get-Service -Name MySQL80
if ($service.Status -eq 'Running') {
    Write-Host "MySQL80 service is already running."
}
else {
    Write-Host "Starting MySQL80 service..."
    gsudo Start-Service -Name MySQL80
}

# Wait for MySQL80 service to start
while ($true) {
    Start-Sleep -Seconds 1
    $service = Get-Service -Name MySQL80
    if ($service.Status -eq 'Running') {
        break
    }
    
}

# Start MySQL Workbench 8.0 CE
try {
    Start-Process -FilePath "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\MySQLWorkbench.exe" -NoNewWindow
}

catch {
    Write-Host "MySQL Workbench 8.0 CE not found." -ForegroundColor Red
    Write-Host "Please install MySQL Workbench 8.0 CE." -ForegroundColor Red
    Write-Host "https://dev.mysql.com/downloads/workbench/" -ForegroundColor Red
}
finally {
    Write-Host "MySQL Workbench 8.0 CE started." -ForegroundColor Green
}
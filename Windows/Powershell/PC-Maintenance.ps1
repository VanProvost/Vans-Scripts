# Script for running various maintenance tasks on Windows PCs

# This script performs the following tasks:
# 1. Sets Restore Point
# 2. Disk Cleanup
# 3. Disk Optimization
# 4. Windows Updates
# 5. Software Updates
# 6. Reboot if necessary
# 7. Checks for driver updates
# 8. Creates a report of processes/files using high CPU, memory, and/or disk usage

# Check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# If not running as admin, restart script with elevation
function Start-Administrator {
    if (-not (Test-Administrator)) {
        Write-Host "Restarting script with administrative privileges..." -ForegroundColor Cyan -BackgroundColor Black
        $scriptPath = $MyInvocation.MyCommand.Path
        if (-not $scriptPath) { $scriptPath = $PSCommandPath }
        if (Get-Command 'gsudo' -ErrorAction SilentlyContinue) {
            & gsudo powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath
        } else {
            Start-Process -FilePath powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath) -Verb RunAs
        }
        Exit
    }
}
Start-Administrator

# Get needed computer information for later tasks
function Get-ComputerInfo {
    # Get all drives with a drive letter
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | Select-Object Name, @{Name = "Used(GB)"; Expression = { [math]::round($_.Used / 1GB, 2) } }, @{Name = "Free(GB)"; Expression = { [math]::round($_.Free / 1GB, 2) } }
    
    # Get CPU information
    $cpu = Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
    
    # Get Memory information
    $memory = Get-WmiObject Win32_ComputerSystem | Select-Object TotalPhysicalMemory, FreePhysicalMemory
    
    return [PSCustomObject]@{
        Drives = $drives
        CPU    = $cpu
        Memory = $memory
    }
}

# Check if a restore point was already created in the past 24 hours
function Create-RestorePoint {
    $existingRestorePoint = Get-ComputerRestorePoint | Where-Object { 
        $_.Description -eq "Before PC-Maintenance" -and $_.CreationTime -gt (Get-Date).AddHours(-24) 
    } | Select-Object -First 1

    # Create a restore point only if one doesn't exist in the past 24 hours
    if ($existingRestorePoint) {
        Write-Host "Restore point already created in the last 24 hours." -ForegroundColor Yellow -BackgroundColor Black
    }
    else {
        Write-Host "Creating new restore point..." -ForegroundColor Cyan -BackgroundColor Black
        Checkpoint-Computer -Description "Before PC-Maintenance" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    
        # Verify the restore point was created
        $newRestorePoint = Get-ComputerRestorePoint | Where-Object { 
            $_.Description -eq "Before PC-Maintenance" -and $_.CreationTime -gt (Get-Date).AddMinutes(-5) 
        } | Select-Object -First 1
    
        if ($newRestorePoint) {
            Write-Host "Restore point created successfully." -ForegroundColor Green -BackgroundColor Black
        }
        else {
            Write-Host "Failed to create restore point." -ForegroundColor Red -BackgroundColor Black
        }
    }
}
Create-RestorePoint

function Start-DiskCleanup {
    [CmdletBinding()]
    param(
        [switch]$AllDrives
    )
    
    Write-Host "Starting Disk Cleanup process..." -ForegroundColor Cyan -BackgroundColor Black
    
    # Get computer info including drives
    $computerInfo = Get-ComputerInfo
    
    # Define which drives to clean
    $systemDrive = $env:SystemDrive
    $drivesToClean = if ($AllDrives) {
        # Extract drive letters from computerInfo and convert to drive paths
        $computerInfo.Drives | ForEach-Object { "$($_.Name):" }
    }
    else {
        @($systemDrive)
    }
    
    # Store initial space information
    $drivesBeforeCleanup = @{}
    foreach ($drive in $drivesToClean) {
        $driveLetter = $drive[0]
        $driveInfo = $computerInfo.Drives | Where-Object { $_.Name -eq $driveLetter } | Select-Object -First 1
        if ($driveInfo) {
            $drivesBeforeCleanup[$drive] = $driveInfo.'Free(GB)' * 1GB
        }
    }
    
    # Run DISM component cleanup on system drive
    if ($drivesToClean -contains $systemDrive) {
        Write-Host "Running system component cleanup on $systemDrive..." -ForegroundColor Cyan -BackgroundColor Black
        $startTime = Get-Date
        $outFile = [IO.Path]::GetTempFileName()
        $errFile = [IO.Path]::GetTempFileName()
        $args = @('/Online','/Cleanup-Image','/StartComponentCleanup','/NoRestart')
        $proc = Start-Process dism.exe -ArgumentList $args -RedirectStandardOutput $outFile -RedirectStandardError $errFile -NoNewWindow -PassThru
        while (-not $proc.HasExited) {
            $elapsed = (Get-Date) - $startTime
            Write-Progress -Activity "DISM Component Cleanup" -Status "Elapsed: $([math]::Round($elapsed.TotalMinutes,1)) min" -PercentComplete (($elapsed.TotalSeconds % 60)/0.6)
            if ($elapsed.TotalMinutes -gt 30) { Write-Warning "DISM cleanup running longer than 30 minutes..." }
            Start-Sleep -Seconds 5
        }
        $exitCode = $proc.ExitCode
        $dismOutput = Get-Content $outFile -ErrorAction SilentlyContinue
        Remove-Item $outFile, $errFile -ErrorAction SilentlyContinue
        if ($exitCode -eq 0) {
            Write-Host "System component cleanup completed successfully." -ForegroundColor Green -BackgroundColor Black
        } else {
            Write-Warning "System component cleanup finished with exit code $exitCode"
            Write-Host $dismOutput -ForegroundColor DarkGray -BackgroundColor Black
        }
    }
    
    # Define common temp folders to clean
    $tempFolders = @(
        "$env:TEMP",
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\Prefetch",
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:USERPROFILE\AppData\Local\Temp"
    )
    
    # Clean temp folders
    Write-Host "Cleaning temporary files..." -ForegroundColor Cyan -BackgroundColor Black
    foreach ($folder in $tempFolders) {
        if (Test-Path $folder) {
            try {
                Write-Host "  Cleaning $folder..." -ForegroundColor DarkGray -BackgroundColor Black
                Get-ChildItem -Path $folder -Force -ErrorAction SilentlyContinue | 
                Where-Object { !$_.PSIsContainer } | 
                Remove-Item -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "  Error cleaning $folder`: $($_.Exception.Message)" -ForegroundColor Yellow -BackgroundColor Black
            }
        }
    }
    
    # Run Windows built-in disk cleanup utility if available
    if (Test-Path "$env:SystemRoot\System32\cleanmgr.exe") {
        Write-Host "Setting up Windows Disk Cleanup..." -ForegroundColor Cyan -BackgroundColor Black
        
        # Set up registry settings for unattended cleanup
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        $sageset = 65535
        
        $cleanupSettings = @{
            "Active Setup Temp Folders"      = 1
            "Downloaded Program Files"       = 1 
            "Internet Cache Files"           = 1
            "Old ChkDsk Files"               = 1
            "Setup Log Files"                = 1
            "System error memory dump files" = 1
            "System error minidump files"    = 1
            "Temporary Files"                = 1
            "Temporary Setup Files"          = 1
            "Thumbnail Cache"                = 1
            "Update Cleanup"                 = 1
            "Windows Defender"               = 1
            "Windows Update Cleanup"         = 1
            "Windows Upgrade Log Files"      = 1
        }
        
        try {
            # Configure registry for unattended cleanup
            foreach ($key in $cleanupSettings.Keys) {
                $path = Join-Path $regPath $key
                if (Test-Path $path) {
                    Set-ItemProperty -Path $path -Name "StateFlags$sageset" -Value $cleanupSettings[$key] -Type DWord -ErrorAction SilentlyContinue
                }
            }
            
            # Run cleanmgr on each drive
            foreach ($drive in $drivesToClean) {
                Write-Host "Running Windows Disk Cleanup on drive $drive..." -ForegroundColor Cyan -BackgroundColor Black
                
                try {
                    $cleanmgrArgs = "/sagerun:$sageset /d $drive"
                    $process = Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList $cleanmgrArgs -Wait -NoNewWindow -PassThru
                    
                    if ($process.ExitCode -eq 0) {
                        Write-Host "  Windows Disk Cleanup completed successfully on drive $drive." -ForegroundColor Green -BackgroundColor Black
                    }
                    else {
                        Write-Host "  Windows Disk Cleanup exited with code $($process.ExitCode) on drive $drive." -ForegroundColor Yellow -BackgroundColor Black
                    }
                }
                catch {
                    Write-Host "  Error running Windows Disk Cleanup on drive $drive`: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
            }
        }
        catch {
            Write-Host "Error configuring or running Windows Disk Cleanup: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
        }
    }
    
    # Get updated computer info for results reporting
    $computerInfoAfter = Get-ComputerInfo
    
    # Report on space saved
    Write-Host "`nDisk Cleanup Results:" -ForegroundColor Cyan -BackgroundColor Black
    foreach ($drive in $drivesToClean) {
        $driveLetter = $drive[0]
        $driveInfoBefore = $drivesBeforeCleanup[$drive]
        $driveInfoAfter = ($computerInfoAfter.Drives | Where-Object { $_.Name -eq $driveLetter } | Select-Object -First 1).'Free(GB)' * 1GB
        
        if ($driveInfoBefore -and $driveInfoAfter) {
            $spaceBefore = $driveInfoBefore / 1GB
            $spaceAfter = $driveInfoAfter / 1GB
            $spaceSaved = $spaceAfter - $spaceBefore
            
            if ($spaceSaved -gt 0) {
                Write-Host "  Drive $drive - Space freed: $([math]::Round($spaceSaved, 2)) GB" -ForegroundColor Green -BackgroundColor Black
            }
            else {
                Write-Host "  Drive $drive - No measurable space freed" -ForegroundColor Yellow -BackgroundColor Black
            }
        }
    }
    
    Write-Host "Disk cleanup process completed." -ForegroundColor Green -BackgroundColor Black
}
Start-DiskCleanup
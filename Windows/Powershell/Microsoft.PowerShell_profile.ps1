# Version 1.0

# C:\Users\Van\Documents\Powershell\Microsoft.Powershell_profile.ps1

# Posh init with theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/uew.omp.json" | Invoke-Expression # Requires oh-my-posh to be installed

# Icons init
Import-Module Terminal-Icons

# Aliases list for Unix Style
Set-Alias -Name "ls" -Value "Get-ChildItem"
Set-Alias -Name "rm" -Value "Remove-Item"
Set-Alias -Name "mv" -Value "Move-Item"
Set-Alias -Name "cp" -Value "Copy-Item" -Scope "Global" -Option "AllScope"      # Allscope option is needed to make powershell shutup about alias errors
Set-Alias -Name "clear" -Value "Clear-Host"
Set-Alias -Name "clr" -Value "Clear-Host"
Set-Alias -Name "pwd" -Value "Get-Location"
Set-Alias -Name "cat" -Value "Get-Content"
Set-Alias -Name "sudo" -Value "gsudo" # Requires gsudo to be installed
function up {Set-Location ..}

# Alias list for quick access to common executables
Set-Alias -Name "np" -Value "C:\Program Files\Notepad++\notepad++.exe"

# Alias list for quick access to common directories and files
function school {Set-Location "C:\Users\Van\Documents\School"}
function onedrive {Set-Location "C:\Users\Van\OneDrive"}
function desktop {Set-Location "C:\Users\Van\Desktop"}
function downloads {Set-Location "C:\Users\Van\Downloads"}
function documents {Set-Location "C:\Users\Van\Documents"}

# Misc.
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete    # Tab completion

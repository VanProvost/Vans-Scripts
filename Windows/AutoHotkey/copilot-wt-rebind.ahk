#Requires AutoHotkey v2.0-a
#SingleInstance

; Focus existing Windows Terminal or launch one if none exists when Microsoft Copilot key is pressed
; Maintains only one Terminal window and ensures focus


+#f23::{
    ; Try to find an existing Windows Terminal window
    if WinExist("ahk_exe WindowsTerminal.exe") {
        ; If found, activate/focus it
        WinActivate("ahk_exe WindowsTerminal.exe")
        ; Ensure it's brought to the foreground
        WinShow("ahk_exe WindowsTerminal.exe")
    } else {
        ; If not found, launch a new instance
        Run("wt.exe")
        ; Wait for the window to appear and then focus it
        WinWait("ahk_exe WindowsTerminal.exe", , 3)
        WinActivate("ahk_exe WindowsTerminal.exe")
        WinShow("ahk_exe WindowsTerminal.exe")
    }
}
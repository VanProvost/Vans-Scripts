#Requires AutoHotkey v2.0-a
#SingleInstance

; Toggle Windows Terminal focus/minimize when Microsoft Copilot key is pressed
; If no terminal exists, launch one and focus it
; If terminal exists and is active, minimize it
; If terminal exists but is not active, focus it

+#f23::{
    ; Try to find an existing Windows Terminal window
    if WinExist("ahk_exe WindowsTerminal.exe") {
        ; Check if the Terminal window is currently active
        if WinActive("ahk_exe WindowsTerminal.exe") {
            ; If Terminal is active, minimize it
            WinMinimize("ahk_exe WindowsTerminal.exe")
        } else {
            ; If Terminal exists but is not active, focus it
            WinActivate("ahk_exe WindowsTerminal.exe")
            WinShow("ahk_exe WindowsTerminal.exe")
        }
    } else {
        ; If no Terminal found, launch a new instance
        Run("wt.exe")
        ; Wait for the window to appear and then focus it
        WinWait("ahk_exe WindowsTerminal.exe", , 3)
        WinActivate("ahk_exe WindowsTerminal.exe")
        WinShow("ahk_exe WindowsTerminal.exe")
    }
}
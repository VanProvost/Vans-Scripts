; Remaps the Copilot key to open Flow Launcher, can easily change this functionality
; by changing "FlowLauncherPath" and "FlowLauncherName" to the program you want to 
; open

#Requires AutoHotkey v2.0-a
#SingleInstance

*>+>#f23::Send "{Blind}{RShift Up}{RWin Up}{RControl Down}"

+#f23::
{
    FlowLauncherPath := "C:\Users\Van\AppData\Local\FlowLauncher\Flow.Launcher.exe"
    FlowLauncherName := "Flow.Launcher.exe"

    if WinExist("ahk_exe " FlowLauncherName)
    {
        ; If Flow Launcher is already running and visible, send Escape to hide it
        WinActivate("ahk_exe " FlowLauncherName)
        Send "{Esc}"
    }
    else
    {
        ; Run Flow Launcher if it's not running
        Run FlowLauncherPath
    }
}
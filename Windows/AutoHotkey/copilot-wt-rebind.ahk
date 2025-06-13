#Requires AutoHotkey v2.0-a
#SingleInstance

*>+>#f23::Send "{Blind}{RShift Up}{RWin Up}{RControl Down}"

; Launch Windows Terminal when Windows key is pressed
LWin::Run "wt.exe"

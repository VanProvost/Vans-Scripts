; Rebinds Alt+Tab to the more superior Win+Tab menu.

#Requires AutoHotkey v2.0
isTaskViewOpen := false  ; Initialize the global variable

; LAlt + Tab to toggle Task View
LAlt & Tab::
{
    global isTaskViewOpen  ; Declare the variable as global
    if (isTaskViewOpen) {
        Send("{LWin Down}{Tab Down}")  ; Simulate LWin + Tab to close Task View
        Sleep(50)                      ; Small delay to ensure the keypress is registered
        Send("{LWin Up}{Tab Up}")
        isTaskViewOpen := false
    } else {
        Send("{LWin Down}{Tab Down}")  ; Simulate LWin + Tab to open Task View
        Sleep(50)
        Send("{LWin Up}{Tab Up}")
        isTaskViewOpen := true
    }
}

; LWin + Tab to toggle Task View
LWin & Tab::
{
    global isTaskViewOpen  ; Declare the variable as global
    if (isTaskViewOpen) {
        Send("{LWin Down}{Tab Down}")  ; Close Task View
        Sleep(50)
        Send("{LWin Up}{Tab Up}")
        isTaskViewOpen := false
    } else {
        Send("{LWin Down}{Tab Down}")  ; Open Task View
        Sleep(50)
        Send("{LWin Up}{Tab Up}")
        isTaskViewOpen := true
    }
}

DetectHiddenWindows, On
hwnd:=WinExist("ahk_pid " . DllCall("GetCurrentProcessId","Uint"))
hwnd+=0x1000<<32

hVirtualDesktopAccessor := DllCall("LoadLibrary", Str, ".\VirtualDesktopAccessor.dll", "Ptr")
GoToDesktopNumberProc         := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc   := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetCurrentDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "MoveWindowToDesktopNumber", "Ptr")
IsPinnedWindowProc            := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsPinnedWindow", "Ptr")
PinWindowProc                 := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "PinWindow", "Ptr")
UnPinWindowProc               := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnPinWindow", "Ptr")
;IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsWindowOnCurrentVirtualDesktop", "Ptr")
;RegisterPostMessageHookProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "RegisterPostMessageHook", "Ptr")
;UnregisterPostMessageHookProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnregisterPostMessageHook", "Ptr")
;RestartVirtualDesktopAccessorProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "RestartVirtualDesktopAccessor", "Ptr")

activeWindowByDesktop := {}

; Restart the virtual desktop accessor when Explorer.exe crashes, or restarts (e.g. when coming from fullscreen game)
explorerRestartMsg := DllCall("user32\RegisterWindowMessage", "Str", "TaskbarCreated")
OnMessage(explorerRestartMsg, "OnExplorerRestart")
OnExplorerRestart(wParam, lParam, msg, hwnd) {
    global RestartVirtualDesktopAccessorProc
    DllCall(RestartVirtualDesktopAccessorProc, UInt, result)
}


Capslock::Esc

CloseCurrentWindow() {
	WinGet, active_id, ID, A
;	MsgBox, The active window's ID is "%active_id%".
	PostMessage, 0x0112, 0xF060,,, ahk_id %active_id%
;	WinClose, ahk_id %active_id%
}


+#q::CloseCurrentWindow()



GoToDesktopNumber(num) {
	global GoToDesktopNumberProc, GetCurrentDesktopNumberProc, activeWindowByDesktop
;   get current desktop
	currentDesktop := DllCall(GetCurrentDesktopNumberProc, UInt)
	if (num == currentDesktop)
	    return
;   save current active windows
	WinGet, activeHwnd, ID, A
;	MsgBox, The 2 active window's ID is "%activeHwnd%" on "%currentDesktop%".
	activeWindowByDesktop[currentDesktop] := activeHwnd
;   got to new desktop
	DllCall(GoToDesktopNumberProc, Int, num)
;   restore active window on deskto
    hwnd := activeWindowByDesktop[num]
;	MsgBox, Restored window's ID is "%hwnd%" on "%num%".
;   if no saved active window, select window under cursor
    if (!hwnd) {
        MouseGetPos,,, hwnd
;    	MsgBox, Restore window under cursor ID is "%hwnd%" on "%num%".
    }
    WinActivate, ahk_id %hwnd%
}

MoveCurrentWindowToDesktop(number) {
	global MoveWindowToDesktopNumberProc, activeWindowByDesktop

	WinGet, activeHwnd, ID, A
	activeWindowByDesktop[number] := activeHwnd
	DllCall(MoveWindowToDesktopNumberProc, UInt, activeHwnd, UInt, number)

    Sleep, 100
    MouseGetPos,,, hwnd
    WinActivate, ahk_id %hwnd%
}

TogglePinActiveWindow() {
    global IsPinnedWindowProc, PinWindowProc, UnPinWindowProc

	WinGet, activeHwnd, ID, A
	ispinned := DllCall(IsPinnedWindowProc, UInt, activeHwnd)
;	MsgBox, Window "%activeHwnd%" is pinned "%ispinned%".
	if (ispinned) {
	    DllCall(UnPinWindowProc, UInt, activeHwnd)
	} else {
	    DllCall(PinWindowProc, UInt, activeHwnd)
	}
}

#1:: GoToDesktopNumber(0)
#2:: GoToDesktopNumber(1)
#3:: GoToDesktopNumber(2)
#4:: GoToDesktopNumber(3)

+#1:: MoveCurrentWindowToDesktop(0)
+#2:: MoveCurrentWindowToDesktop(1)
+#3:: MoveCurrentWindowToDesktop(2)
+#4:: MoveCurrentWindowToDesktop(3)

+#a::TogglePinActiveWindow()

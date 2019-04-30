#NoEnv
#SingleInstance FORCE
SendMode Input
SetWorkingDir %A_ScriptDir%
Plugin.Properties()
return

#Include *i Libraries\Functions.lib

; ----------- User functions here -------------

RCtrl::
	Send ^{Backspace}
return

#If WinActive("ahk_exe explorer.exe") || WinActive("ahk_exe notepad.exe")
	RCtrl::
		Send ^+{Left}{Delete}
	return
#If
#NoEnv
#SingleInstance FORCE
SendMode Input
SetWorkingDir %A_ScriptDir%
Plugin.Properties()
return

#Include *i Libraries\Functions.lib

; ----------- User functions here ------------


#If MouseIsOver("ahk_class Shell_TrayWnd") || MouseIsOver("ahk_class Progman")
Hotkey, If, MouseIsOver("ahk_class Shell_TrayWnd") || MouseIsOver("ahk_class Progman")
	MButton::
		MouseGetPos, xbef
	return

	MButton Up::
		MouseGetPos, xaft
		if(xbef!=null && xbef-xaft>60)
		{
			Send {Media_Prev}
			RSNotify("Previous")
		}
		else if(xbef!=null && xbef-xaft<-60)
		{
			Send {Media_Next}
			RSNotify("Next", 95)
		}
		else if(xbef!=null)
		{
			Send {Media_Play_Pause}
			sleep 40
			RSNotify("Play/Pause")
		}
		xbef:=null
	return
#If
#NoEnv
#SingleInstance FORCE
SendMode Input
SetWorkingDir %A_ScriptDir%
Plugin.Properties()
return

#Include *i Libraries\Functions.lib

; ----------- User functions here ------------


CapsLock & SC022:: ; g
	SetKeyDelay, 0, 0
	Send {Esc}{Space}
	SendRaw { get; set; } 
	SetKeyDelay, 10, 10
return

CapsLock & SC027:: ; ;
	SendInput {Esc}{End};
return

CapsLock & Enter::
	Send {Esc}{End}{Enter}
return

CapsLock & SC030:: ; b
	SendInput {Esc}{End}
	sleep 10
	SendInput {Enter}
	sleep 40
	SendInput {Raw}{
	sleep 30
	SendInput {Enter}
return

CapsLock & SC024:: ; j
	Send {Down}

	SetTimer, WaitForCapsLockRelease, 10
return
CapsLock & SC016:: ; u
	Send {Up}

	SetTimer, WaitForCapsLockRelease, 10
return
WaitForCapsLockRelease:
	if !GetKeyState("CapsLock", "P")
	{
		Send {Enter}
		SetTimer, WaitForCapsLockRelease, Off
	}
return

CapsLock & SC025:: ; k
	Send {Enter}
return

+Up::
	If !UpTimeoutVar
	{
		Send {Esc}{End}
		UpTimeoutVar:=true
	}

	Send +{Up}+{End}
	SetTimer, UpTimeout, 2750
return
UpTimeout:
	UpTimeoutVar:=false
return

#IfWinActive, ahk_exe Ssms.exe
CapsLock & SC019:: ; Button: [p] - Action: Parameter Scraper
    prevClip := ClipboardAll

    Send ^{SC02E}

    Sleep 100

    params := Clipboard
    params := StrReplace(params, "DECLARE", "SET")
    params := RegExReplace(params, "[\S]+`r`n", "= `n")
    params := RegExReplace(params, "[\S]+$", "= `n")

	If InStr(params, "SET")
	{
		Clipboard := params
		Send {Down}
		Sleep 50
		Send ^{SC02F}
	}
    
    Sleep 200
	Clipboard=
	Clipboard := prevClip
return

CapsLock & SC021:: ; f
	Send {AppsKey 3}
	Send {Down 2}{Right}{Down}{Enter}
	Sleep 40
	Send {Tab 2}
return

CapsLock & SC01F:: ; s
	SetKeyDelay, 0, 0
	SendInput SELECT * FROM
	Send {Space}
	SetKeyDelay, 10, 10
return

CapsLock & SC017:: ; i
	SetKeyDelay, 0, 0
	SendInput INNER JOIN
	Send {Space}
	SetKeyDelay, 10, 10
return

CapsLock & SC018:: ; o
	SetKeyDelay, 0, 0
	Send {Space}
	SendInput ORDER BY  DESC
	Send {Left 5}
	SetKeyDelay, 10, 10
return

CapsLock & SC012:: ; e
	SetKeyDelay, 0, 0
	SendInput {Esc}{End}
	SendInput +{Up}
	SendInput ^{SC012}
	SetKeyDelay, 10, 10
return

CapsLock & SC011:: ; w
	SetKeyDelay, 0, 0
	Send {Space}
	SendInput WITH(NOLOCK)
	SetKeyDelay, 10, 10
return
#If

#IfWinActive, Filter Settings ahk_exe Ssms.exe
*Enter::
	Send {Enter}{Esc}{Enter}
	Sleep 40
	Send {Enter}
return
#If

#If WinActive("ahk_exe devenv.exe") || WinActive("ahk_exe Ssms.exe")
^SC026::
	Send ^+{SC026}{Left}
return
#If
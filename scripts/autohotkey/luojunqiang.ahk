;; Alt !, Ctrl ^,  Shift +, Win #
;#z::Run www.autohotkey.com


; KeyboardLayout code can found in registry: 
; HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts
;kbl_En = 0x00000409 ; Us
kbl_En = 0x08040804 ; Chinese (People's Republic of China) US Keyboard
kbl_Cn = 0xE0200804 ; Google PinYin

; shift caps up => Chinese Input Method
+Capslock up::
;SoundBeep
SendInput !+9
SendInput !+0
;SendInput {F13}
;SendInput, {CTRLDOWN}{SHIFTDOWN}{SHIFTUP}{CTRLUP}
Return

; control caps up => English Input Method
^Capslock up::
SendInput !+9
Return

; alt caps up
!Capslock up::  PostMessage, 0x50, 2, 0,, A  ; Switch lang to next

#4::
SoundBeep
kbl := DllCall("GetKeyboardLayout", Int, DllCall("GetWindowThreadProcessId", Int, WinActive("A"), Int,0))
kbl := kbl & 0xFFFFFFFF
;SetFormat, IntegerFast, hex
;tooltip % "kbl=" . kbl
if (kbl != kbl_Cn) {
	PostMessage, 0x50, 0, kbl_Cn,, A
} else {
	PostMessage, 0x50, 0, kbl_En,, A
}
Return


#7::
IfWinExist, GeeTeeDee ahk_class QWidget
	WinActivate
Else
	Run, E:\software\GeeTeeDeePortable\GeeTeeDeePortable.exe
Return


#j::
WinShow, eSpace
IfWinExist, eSpace
	WinActivate
Else
	Run, E:\software\eSpace-ecs\eSpace.exe
	;Run, eSpace
Return


#0::
SoundSet, +1, Microphone, mute
TrayTip, Toggle Mic, Mic mute toggled, 2, 1
SoundBeep, 800, 300
Return

#=::
SendInput {= 80}
;SendInput {Raw}================================================================================
SendInput {Enter}
Return

#-::
SendInput {Raw}--------------------------------------------------------------------------------
SendInput {Enter}
Return

#i:: SendInput {Raw}00231957
#k:: SendInput {Raw}Fa4@huawei

#\::
FormatTime, CurrentDate,, yyyy-MM-dd
SendInput %CurrentDate%
return

#|::
FormatTime, CurrentDateTime,, yyyy-MM-dd HH:mm:ss
SendInput %CurrentDateTime%
Return

#/::
StringReplace, clipboard, clipboard, \, /, All
Return

#IfWinActive ahk_class PuTTY
#RAlt::LAlt
#IfWinActive

;#InputLevel 20
;Capslock & i:: SendInput {Blind}{Up}
;Capslock & k:: SendInput {Blind}{Down}
;Capslock & j:: SendInput {Blind}{Left}
;Capslock & l:: SendInput {Blind}{Right}
;Capslock & 8:: SendInput {Blind}^{Up}
;Capslock & ,:: SendInput {Blind}^{Down}
;Capslock & h:: SendInput {Blind}^{Left}
;Capslock & `;:: SendInput {Blind}^{Right}
;Capslock & u:: SendInput {Blind}{Home}
;Capslock & o:: SendInput {Blind}{End}
;Capslock & y:: SendInput {Blind}{PgUp}
;Capslock & p:: SendInput {Blind}{End}

Capslock & k:: SendInput {Blind}{Up}
Capslock & j:: SendInput {Blind}{Down}
Capslock & h:: SendInput {Blind}{Left}
Capslock & l:: SendInput {Blind}{Right}
Capslock & i:: SendInput {Blind}{PgUp}
Capslock & u:: SendInput {Blind}{PgDn}
Capslock & y:: SendInput {Blind}{Home}
Capslock & o:: SendInput {Blind}{End}

Capslock & Backspace:: SendInput {Blind}{Del}
;#InputLevel 0

;#Include %A_ScriptDir%\DragToScroll.ahk
;#Include %A_ScriptDir%\test.ahk

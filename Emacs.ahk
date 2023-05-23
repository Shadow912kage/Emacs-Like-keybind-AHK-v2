; AutoHotKey V2's Script, Emacs like keybind
;; Shadow912kage@gmail.com
;; Reference:
;;   AutoHotKey v1->v2への移行 ～Emacs-likeなキーバインド設定編～ - Qiita
;;     https://qiita.com/asublue/items/0e3fad2667545793466d
;;	 IfWinActive with the Windows 10 clipboard history (Win+V) : r/AutoHotkey
;;	   https://www.reddit.com/r/AutoHotkey/comments/11lro53/ifwinactive_with_the_windows_10_clipboard_history/

;;; ***** NOTICE! *****
;;; Emacs-like keyboard operations on the clipboard history (Win+v) do NOT work well while this script runs.
;;; Please use the Up/Down arrow key or mouse. 

; AutoHotKey 2.0 configuration
#Requires AutoHotkey v2.0
#Warn ; Enable warnings to assist with detecting common errors.
#SingleInstance force ; Determines whether a script is allowed to run again when it is already running.
#UseHook
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.

TraySetIcon "keyboard.png" ; Icon source from https://icooon-mono.com/
A_IconTip := "Emacs like keybind v0.3.6"

; Swapping CapsLock and Left Ctrl are implemented by Ctrl2Cap.
;; ****** When using Ctrl2Cap, DO NOT remap the key to CapsLock... don't work well. *****
;; Swap CapsLock <-> Ctrl, Disable Shit+CapsLock
;;  CapsLock -> Ctrl by Ctrl2Cap, https://learn.microsoft.com/ja-jp/sysinternals/downloads/ctrl2cap

;; Remove the commented-out of Emacs you are using and #HotIf.
; Ignore Emacses List
;GroupAdd "IgnoreApp", "ahk_class ConsoleWindowClass" ; Cygwin, Ubuntu
;GroupAdd "IgnoreApp", "ahk_class cygwin/x X rl-xterm-XTerm-0"
;GroupAdd "IgnoreApp", "ahk_class VMwareUnityHostWndClass"
;GroupAdd "IgnoreApp", "ahk_class Vim" ; GVIM
;GroupAdd "IgnoreApp", "ahk_class Emacs" ; NTEmacs
;GroupAdd "IgnoreApp", "ahk_class XEmacs" ; XEmacs on Cygwin
;GroupAdd "IgnoreApp", "ahk_exe vcxsrv.exe" ; gnome-terminal
;GroupAdd "IgnoreApp", "ahk_exe xyzzy.exe" ; xyzzy
;GroupAdd "IgnoreApp", "ahk_exe putty.exe" ; PuTTY
;GroupAdd "IgnoreApp", "ahk_exe ttermpro.exe" ; TeraTerm
;GroupAdd "IgnoreApp", "ahk_exe TurboVNC.exe" ; VNC
;GroupAdd "IgnoreApp", "ahk_exe vncviewer.exe" ; VNC
;#HotIf !WinActive("ahk_group IgnoreApp")

; Emacs-like functions

; Set a suspending toggle key
#SuspendExempt
^F1::Suspend
#SuspendExempt False

; This script configuration
CBWT := 0.2 ; Clipboard Waiting Time[sec]
BPWT := 50 ; Buffer Processing Waiting Time[msec]

; Global variables and flags
IsPreEscp := False ; ESC prefix flag
IsPreCtrX := False ; C-x prefix flag
IsPreCSpc := False ; C-SPC prefix flag
IsSrching := False ; Searching flag
CursorDir := "" ; Cursor direction after copy region

RstPreFlgs() ; Reset prefix flags
{
  Global
  IsPreEscp := False
  IsPreCtrX := False
  IsPreCSpc := False
}
RstAllFlgs() ; Reset all flags
{
  Global
	IsSrching := False
	CursorDir := ""
  RstPreFlgs()
}

; Emacs like functions
DelChar() ; Delete forward character
{
  Send "{Del}"
  RstAllFlgs()
}
DelBkChar() ; Delete backward character
{
  Send "{BS}"
  RstAllFlgs()
}
KillLine() ; Delete to the end of line
{
  Global CBWT, BPWT
	SaveClipBd()
	A_Clipboard := ""
  Send "{ShiftDown}{END}{ShiftUp}"
  Sleep BPWT
  Send "^x"
  If ClipWait(CBWT, 1) ; Wait for the clipboard to contain text.
	{
		tmp := A_Clipboard
		RstrClipBd()
		A_Clipboard := tmp
	}
	Else
  { ; Case the cursor position is the end of the line, ClipWait() returns False (used to return w/o WaitForAnyData).
    Send "{ShiftDown}{Right}{ShiftUp}"
    Sleep BPWT
		Send "^x"
		RstrClipBd()
  }
  RstAllFlgs()
}
OpenLine() ; Open line at the cursor position
{
  Send "{Enter}{Home}{Left}" ; need "{Home}" for Notepad++, ad hoc.
  RstAllFlgs()
}
Quit() ; Quit operation
{
  Send "{ESC}"
  RstAllFlgs()
}
NewLine() ; Enter new line
{
  Send "{Enter}"
  RstAllFlgs()
}
TabIndent(dir) ; Indent for tab and moving to next(True)/previous(False) input field
{
	If dir
		Send "{Tab}"
	Else
		Send "+{Tab}"
  RstAllFlgs()
}
NewLineTab() ; New line and indent
{
  Send "{Enter}{Tab}"
  RstAllFlgs()
}
IncSearch(dir) ; Incremental search forward(True)/backward(False)
{
  Global IsSrching
  If IsSrching
  {
    If dir
      Send "{F3}"
		Else
			Send "+{F3}" 
  }
  Else
  {
    Send "^f"
		IsSrching := True
  }
  RstPreFlgs()
}
KillRegion(kill) ; Kill(True)/Copy(False) a region
{
  Global IsPreCSpc, CursorDir, CB₽T
  If kill
    Send "^x"
  Else
	{
    Send "^c"
		If IsPreCSpc && CursorDir
			Send CursorDir
	}
	ClipWait(CBWT)
  RstAllFlgs()
}
Yank() ; Copy from a ring buffer(Clipboard)
{
  Send "^v"
  RstAllFlgs()
}
Undo() ; Undo
{
  Send "^z"
  RstAllFlgs()
}
FindFile() ; Find a file
{
  Send "^o"
  RstAllFlgs()
}
SaveBuf() ; Save a buffer
{
  Send "^s"
  RstAllFlgs()
}
KillWin() ; Close the window
{
  Send "!{F4}"
  RstAllFlgs()
}
KillBuf() ; Close a tab/buffer
{
  Send "^w"
  RstAllFlgs()
}
_MoveCore(loc) ; Core function of move
{
  Global IsPreCSpc, CursorDir
  If IsPreCSpc
	{
    Send "+" loc
		Switch loc
		{
		case "{Right}", "{END}", "{Down}", "^{Right}", "^{END}", "{PgDn}":
			CursorDir := "{Right}"
		case "{Left}", "{HOME}", "{Up}", "^{Left}", "^{HOME}", "{PgUp}":
			CursorDir := "{Left}"
		default:
			CursorDir := ""
		}
  }
	Else
	{
		Send loc
		RstAllFlgs()
	}
}
BgnEndLine(dir) ; Move to the beginning(True)/end(False) of the line
{
  If dir
    loc := "{HOME}"
  Else
		loc := "{END}"
  _MoveCore(loc)
}
PrevNextLine(dir) ; Move to the previous(True)/next(False) line
{
  If dir
    loc := "{Up}"
  Else
    loc := "{Down}"
  _MoveCore(loc)
}
FwdBkwdChar(dir) ; Move to the forward(True)/Backward(False) character
{
  If dir
    loc := "{Right}"
  Else
    loc := "{Left}"
  _MoveCore(loc)
}
FwdBkwdWord(dir) ; Move to the forward(True)/backward(False) word
{
	If dir
		loc := "^{Right}"
	Else
		loc := "^{Left}"
	_MoveCore(loc)
}
/* Not implemented on the Windows shortcut keys...
FwdBkwdSentence(dir) ; Move to the forward(True)/backward(False) sentence
{
  ;Emacs's sentence end regex: "[.?!][]\"')]*\\($\\|\t\\|  \\)[ \t\n]*"
}
*/
ScrollUpDwn(dir) ; Scroll up(True)/down(False)
{
  If dir
    loc := "{PgUp}"
  Else
    loc := "{PgDn}"
  _MoveCore(loc)
}
PageTopBtm(dir) ; Page up to the top(True)/down to the bottom(False)
{
  If dir
    loc := "^{HOME}"
  Else
    loc := "^{END}"
  _MoveCore(loc)
}

; Emacs like keybind hotkeys
^x:: Global IsPreCtrX := True
Esc::
^[::
{
	Global IsPreEscp
	If IsPreEscp
	{
		Send "{Esc}"
		IsPreEscp := False
	}
	Else
		IsPreEscp := True
}
^f::
{
	Global IsPreCtrX
	If IsPreCtrX
		FindFile()
	Else
		FwdBkwdChar(True)
}
^c::
{
	global IsPreCtrX
	If IsPreCtrX
		KillWin()
	Else
		Send "^c"
}
^d:: DelChar()
^h:: DelBkChar()
^k:: KillLine()
k::
{
	global IsPreCtrX
	If IsPreCtrX
		KillBuf()
	Else
		Send A_ThisHotkey
}
^o:: OpenLine()
^g:: Quit()
^j:: NewLineTab()
^m:: NewLine()
^i:: TabIndent(True)
^+i:: TabIndent(False)
^s::
{
	Global IsPreCtrX
	If IsPreCtrX
		SaveBuf()
	Else
		IncSearch(True)
}
^r:: IncSearch(False)
^w:: KillRegion(True)
!w:: KillRegion(False)
w::
{
	Global IsPreEscp
	If IsPreEscp
	{
		KillRegion(False)
		IsPreEscp := False
	}
	Else
		Send A_ThisHotkey
}
^y:: Yank()
^/:: Undo()
u::
{
	global IsPreCtrX
	If IsPreCtrX
		Undo()
	Else
		Send A_ThisHotkey
}
^Space::
{
	global IsPreCSpc
	IsPreCSpc := !IsPreCSpc
}
^a:: BgnEndLine(True)
^e:: BgnEndLine(False)
^p:: PrevNextLine(True)
^n:: PrevNextLine(False)
^b:: FwdBkwdChar(False)
^+f:: Send "+{Right}" ; For increase of IME conversion range
^+b:: Send "+{Left}" ; For decrease of IME conversion range
!f:: FwdBkwdWord(True)
f::
{
	Global IsPreEscp
	If IsPreEscp
	{
		FwdBkwdWord(True)
		IsPreEscp := False
	}
	Else
		Send A_ThisHotkey
}
!b:: FwdBkwdWord(False)
b::
{
	Global IsPreEscp
	If IsPreEscp
	{
		FwdBkwdWord(False)
		IsPreEscp := False
	}
	Else
		Send A_ThisHotkey
}
!v:: ScrollUpDwn(True)
v::
{
	Global IsPreEscp
	If IsPreEscp
	{
		ScrollUpDwn(True)
		IsPreEscp := False
	}
	Else
		Send A_ThisHotkey
}
^v::
{
	Global Win10Oct2018
	If VerCompare(A_OSVersion, Win10Oct2018)
	{
		If IsHiddenClpbdHst(GetHWNDClpbdHst())
			ScrollUpDwn(False)
		Else
			Send A_ThisHotkey
	}
	Else
		ScrollUpDwn(False)
}
/*
~#v::
{
	Global Win10Oct2018
	If VerCompare(A_OSVersion, Win10Oct2018)
	{
	}
}
*/
!<:: PageTopBtm(True)
<::
{
	global IsPreEscp
	If IsPreEscp
	{
		PageTopBtm(True)
		IsPreEscp := False
	}
	Else
		Send A_ThisHotkey
}
!>:: PageTopBtm(False)
>::
{
	global IsPreEscp
	If IsPreEscp
	{
		PageTopBtm(False)
		IsPreEscp := False
	}
	Else
		Send A_ThisHotkey
}

; Save/restore clipboard buffer
ClipSaved := ""
SaveClipBd()
{
	global ClipSaved := ClipboardAll() ; Save the entire clipboard to a variable of your choice.
	A_Clipboard := "" ; Start off empty to allow ClipWait to detect when the text has arrived.
}
RstrClipBd()
{
	global ClipSaved
	A_Clipboard := ClipSaved ; Restore the original clipboard. Note the use of A_Clipboard (not ClipboardAll).
	ClipSaved := "" ; Free the memory in case the clipboard was very large.
}
#HotIf
; ======= End of Emacs like keybind =====

; Sub-functions for the clipboard history
;  Sequence of Win+v processing:
;   1. You press Win+v.
;   2. Windows open the clipboard history window.
;   3. If you select an item, Windows copy it to the clipboard and send Ctrl+v.
;   4. Windows close the clipboard history window.
Win10Oct2018 := ">=10.0.17763" ; Version numbper of Windows 10 October 2018 Update or later,
															 ; Clipboard history was implemented
Win11OrigRel := ">=10.0.22000" ; Version number of Windows 11 Original Release
#HotIf VerCompare(A_OSVersion, Win10Oct2018)
; If the Clipboard history window is existed, Return its HWND. Else return False.
GetHWNDClpbdHst()
{
	Global Win10Oct2018, Win11OrigRel
	UWPAppClass1 := "ApplicationFrameWindow"
	UWPAppClass2 := "Windows.UI.Core.CoreWindow"
	ClpbdHstTxtWin10 := "Microsoft Text Input Application"
	ClpbdHstTxtWin11 := "Windows Input Experience"
	TargetProcess := "TextInputHost.exe"

	Parent := DllCall("FindWindowEx", "ptr", 0, "ptr", 0, "str", UWPAppClass1, "ptr", 0)
	If VerCompare(A_OSVersion, Win11OrigRel)
		Child := DllCall("FindWindowEx", "ptr", Parent, "ptr", 0, "str", UWPAppClass2, "str", ClpbdHstTxtWin11)
	Else
		Child := DllCall("FindWindowEx", "ptr", Parent, "ptr", 0, "str", UWPAppClass2, "str", ClpbdHstTxtWin10)
	If !Child ; Shortly after Windows boots (Win+v not yet pressed), "TextInputHost.exe" is not found.
		Return False
	If WinGetProcessName(Child) = TargetProcess
		Return Child
	Else
		Return False
}
IsHiddenClpbdHst(Child)
{
	DwmGetWinAttr := "dwmapi\DwmGetWindowAttribute" 
	Return (DllCall(DwmGetWinAttr, "ptr", Child, "int", 14, "int*", &cloaked := 0, "int", 4) = 0)?cloaked:False
}
/*; For debug & development
DebugLog := ""
^F2::
{ ; use DebugLog for printf debugging
	Global
	MsgBox DebugLog
	DebugLog := ""
}
IsOpnClpbdHst := False ; Change to True, when the clipboard history window is opened (edge trigger)
IsClsClpbdHst := False ; Change to True, when the clipboard history window is closed (edge trigger)
SetTimer ChkClpbdHst, 100
ChkClpbdHst()
{
	Global IsOpnClpbdHst, IsClsClpbdHst
	Static PstClpbdStat := False ; opened: True / closed: False
	If IsHiddenClpbdHst(GetHWNDClpbdHst())
	{ ; Case: closed
		If PstClpbdStat ; Case: opened -> closed
		{
			IsOpnClpbdHst := False
			IsClsClpbdHst := True
			PstClpbdStat := False
		}
	}
	Else
	{ ; Case: opened
		If !PstClpbdStat ; Case: closed -> opened
		{
			IsOpnClpbdHst := True
			IsClsClpbdHst := False
			PstClpbdStat := True
		}
	}
}
*/

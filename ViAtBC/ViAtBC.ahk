#IfTimeout, 500
Setkeydelay,-1
SetControlDelay,-1
DetectHiddenWindows,on
Coordmode,Menu,Window

;=======================================================
; ViAtBC - Vi-style navigation for Beyond Compare
; Based on ViATc pattern for Total Commander
; Version 0.1.0
;=======================================================
Init()

Global BCEXE := GetPath_BCEXE()
Global VIABC_INI := GetPath_VIABC_INI()

; Vim mode: 0 = Normal (command), 1 = Insert (pass-through)
Global VimMode := 0

; BC window class (configurable via INI [Global] BCClass=)
Global BCClass := "TBCWindow"
cfgClass := VIABC_IniRead("Global", "BCClass")
if (cfgClass != "")
    BCClass := cfgClass

ReadConfigToRegHK()

if (BCEXE != "")
    TrayTip,,ViAtBC loaded`nBC: %BCEXE%,,17
else
    TrayTip,,ViAtBC loaded (BC path not configured),,17
Sleep,2500
TrayTip
return

;===================================================
; Init placeholder
Init()
{
    return
}

;===================================================
; Read INI sections and register hotkeys
ReadConfigToRegHK()
{
    ConfigSection := VIABC_IniRead()
    Loop,Parse,ConfigSection,`n
    {
        ; [Global] - hotkeys active for any BC window
        If RegExMatch(A_LoopField,"i)^Global$")
        {
            CLASS := ""
            KeyList := VIABC_IniRead("Global")
            Loop,Parse,KeyList,`n
            {
                ParseAndRegister(A_LoopField, CLASS)
            }
        }
        ; [BC_ClassName] - hotkeys for specific BC window class
        If RegExMatch(A_LoopField,"^BC_")
        {
            CLASS := SubStr(A_LoopField,4,StrLen(A_LoopField))
            KeyList := VIABC_IniRead(A_LoopField)
            Loop,Parse,KeyList,`n
            {
                ParseAndRegister(A_LoopField, CLASS)
            }
        }
    }
}

; Parse a single INI line and register the hotkey
ParseAndRegister(Line, CLASS)
{
    Key := RegExReplace(Line,"=[\[<\(\{].*[\]\}\)>]$")
    Action := SubStr(Line,StrLen(Key)+2,StrLen(Line))

    ; $ prefix: resolve before registering
    If RegExMatch(Key,"^\$")
    {
        Key := SubStr(Key,2)
        If !RegExMatch(Key,"^\$")
        {
            Key := ResolveHotkey(Key)
            SetHotkey(Key.1,Action,CLASS)
            Return
        }
    }
    RegisterHotkey(Key,Action,CLASS)
}

;===================================================
; INI read/write/delete helpers
VIABC_IniRead(section="",key="")
{
    Global VIABC_INI
    IniRead,Value,%VIABC_INI%,%section%,%key%
    If RegExMatch(Value,"ERROR")
    {
        Value := Options(key)
        If !RegExMatch(Value,"^ERROR$")
        {
            IniWrite,%Value%,%VIABC_INI%,%section%,%key%
        }
        Else
            Value := ""
    }
    Return Value
}

VIABC_IniWrite(section,key,value)
{
    Global VIABC_INI
    IniWrite,%value%,%VIABC_INI%,%section%,%key%
    Return ErrorLevel
}

VIABC_IniDelete(section,key)
{
    Global VIABC_INI
    IniDelete,%VIABC_INI%,%section%,%key%
    Return ErrorLevel
}

;===================================================
; Options with default values (non-hotkey config items)
Options(opt)
{
    If (opt = "BCClass")
        Return "TBCWindow"
    Return "ERROR"
}

;===================================================
; Find viabc.ini file path
; Search order: script dir -> registry -> BC dir -> prompt
GetPath_VIABC_INI()
{
    NeedRegWrite := False
    Loop
    {
        ; Script directory
        gPath := A_ScriptDir "\viabc.ini"
        If FileExist(gPath)
            Break

        ; VIATC registry
        RegRead,gPath,HKEY_CURRENT_USER,Software\ViAtBC,ViAtBCIni
        If FileExist(gPath)
            Break
        Else
            NeedRegWrite := True

        ; BC directory
        Global BCEXE
        SplitPath,BCEXE,,BCDir
        gPath := BCDir "\viabc.ini"
        If FileExist(gPath)
            Break

        ; Prompt user to select
        FileSelectFile,gPath,3,,Find viabc.ini,*.ini
        If ErrorLevel
        {
            MsgBox,4,ViAtBC,viabc.ini not found. Create in script directory?
            IfMsgBox,Yes
                gPath := A_ScriptDir "\viabc.ini"
            Else
                Return
        }
        Break
    }
    If (gPath != "")
    {
        If NeedRegWrite
            RegWrite,REG_SZ,HKEY_CURRENT_USER,Software\ViAtBC,ViAtBCIni,%gPath%
        Return gPath
    }
}

;===================================================
; Find Beyond Compare executable path
; Search order: ViAtBC registry -> BC registry (x64/x86) -> process -> script dir -> common paths -> prompt
GetPath_BCEXE()
{
    NeedRegWrite := False
    Loop
    {
        ; ViAtBC registry
        RegRead,gPath,HKEY_CURRENT_USER,Software\ViAtBC,BCInstallDir
        If FileExist(gPath)
            Break
        Else
            NeedRegWrite := True

        ; BC registry (x64)
        RegRead,gPath,HKEY_LOCAL_MACHINE,SOFTWARE\Scooter Software\Beyond Compare,ExePath
        If FileExist(gPath)
            Break

        ; BC registry (x86 on x64)
        RegRead,gPath,HKEY_LOCAL_MACHINE,SOFTWARE\WOW6432Node\Scooter Software\Beyond Compare,ExePath
        If FileExist(gPath)
            Break

        ; Running process (BCompare.exe)
        Process,Exist,BCompare.exe
        PID := ErrorLevel
        If PID
        {
            WinGet,gPath,ProcessPath,ahk_pid %PID%
            If (gPath != "" and FileExist(gPath))
                Break
        }

        ; Running process (BC.exe, older versions)
        Process,Exist,BC.exe
        PID := ErrorLevel
        If PID
        {
            WinGet,gPath,ProcessPath,ahk_pid %PID%
            If (gPath != "" and FileExist(gPath))
                Break
        }

        ; Script directory
        gPath := A_ScriptDir "\BCompare.exe"
        If FileExist(gPath)
            Break
        gPath := A_ScriptDir "\BC.exe"
        If FileExist(gPath)
            Break

        ; Common install paths
        gPath := "C:\Program Files\Beyond Compare 5\BCompare.exe"
        If FileExist(gPath)
            Break
        gPath := "C:\Program Files\Beyond Compare 4\BCompare.exe"
        If FileExist(gPath)
            Break
        gPath := "C:\Program Files (x86)\Beyond Compare 4\BCompare.exe"
        If FileExist(gPath)
            Break
        gPath := "C:\Program Files\Beyond Compare 3\BCompare.exe"
        If FileExist(gPath)
            Break

        ; Prompt user to select
        FileSelectFile,gPath,3,,Locate BCompare.exe or BC.exe,*.exe
        If ErrorLevel
        {
            Msgbox,4096,ViAtBC,Beyond Compare executable not found!`nViAtBC cannot function without it.
            Return ""
        }
        Break
    }
    If FileExist(gPath)
    {
        If NeedRegWrite
            RegWrite,REG_SZ,HKEY_CURRENT_USER,Software\ViAtBC,BCInstallDir,%gPath%
        Return gPath
    }
    Return ""
}

;===================================================
; Vim mode management
Vim_NormalMode()
{
    Global VimMode
    VimMode := 0
    ToolTip,Normal Mode
    SetTimer,Vim_ClearToolTip,-600
}

Vim_InsertMode()
{
    Global VimMode
    VimMode := 1
    ToolTip,Insert Mode
    SetTimer,Vim_ClearToolTip,-600
}

Vim_ClearToolTip:
    ToolTip
    Return

; Condition: BC window active AND in Normal mode (for navigation hotkeys)
Vim_IsBCNormal()
{
    Global BCClass, VimMode
    Return WinActive("ahk_class " BCClass) and (VimMode = 0)
}

; Condition: BC window active (for mode switching hotkeys)
Vim_IsBCActive()
{
    Global BCClass
    Return WinActive("ahk_class " BCClass)
}

;===================================================
; Hotkey definitions - Normal mode navigation
; Only fire when BC is active AND VimMode = 0
;===================================================
#If Vim_IsBCNormal()
$j:: Send, {Down}
$k:: Send, {Up}
$h:: Send, {Left}
$l:: Send, {Right}
$i:: Vim_InsertMode()

; Shift+J - select down (like Shift+Down)
$+j:: Send, +{Down}
; Shift+K - select up (like Shift+Up)
$+k:: Send, +{Up}

; gg - double press g to go to top (Ctrl+Home)
$g::
    if (A_PriorHotkey = "$g" and A_TimeSincePriorHotkey < 500)
        Send, {Home}
    Return

; G (Shift+g) - go to bottom (End)
$+g:: Send, {End}

; Ctrl+u - move up 15 lines
$^u:: Send, {Up 15}

; Ctrl+d - move down 15 lines
$^d:: Send, {Down 15}

; x - delete file (BC shortcut: Shift+Del)
$x:: Send, +{Delete}
#If

;===================================================
; Hotkey definitions - Always active in BC
; Mode switching hotkeys work regardless of current mode
;===================================================
#If Vim_IsBCActive()
$Esc::
    Vim_NormalMode()
    Send, {Esc}
    Return
$Insert:: Vim_InsertMode()
#If

;===================================================
; Dynamic hotkey handler labels (for INI-registered hotkeys)
;===================================================
Vim_DoDown:
    Send, {Down}
    Return

Vim_DoUp:
    Send, {Up}
    Return

Vim_DoLeft:
    Send, {Left}
    Return

Vim_DoRight:
    Send, {Right}
    Return

Vim_DoInsertMode:
    Vim_InsertMode()
    Return

Vim_DoNormalMode:
    Vim_NormalMode()
    Return

;===================================================
; Register a hotkey dynamically (called from ReadConfigToRegHK)
;  Key     - the key combination (e.g. "j", "<lwin>e")
;  Action  - the action (e.g. "Down", "Up", "<InsertMode>")
;  WinClass- AHK window class to scope the hotkey to
;===================================================
RegisterHotkey(Key, Action, WinClass="")
{
    Global BCClass

    if (WinClass = "")
        WinClass := BCClass
    if (WinClass = "")
        Return

    ; Map action to handler label
    Handler := ""
    if (Action = "Down")
        Handler := "Vim_DoDown"
    else if (Action = "Up")
        Handler := "Vim_DoUp"
    else if (Action = "Left")
        Handler := "Vim_DoLeft"
    else if (Action = "Right")
        Handler := "Vim_DoRight"
    else if (Action = "<InsertMode>")
        Handler := "Vim_DoInsertMode"
    else if (Action = "<NormalMode>")
        Handler := "Vim_DoNormalMode"

    if (Handler = "")
        Return

    Hotkey, IfWinActive, ahk_class %WinClass%
    Hotkey, % "$" Key, %Handler%, On, UseErrorLevel
    Hotkey, IfWinActive  ; Reset context
}

;===================================================
; ResolveHotkey / SetHotkey (simplified stubs matching ViATc API)
ResolveHotkey(Key)
{
    Return [Key]
}

SetHotkey(Key, Action, WinClass)
{
    RegisterHotkey(Key, Action, WinClass)
}

;===================================================
EmptyMem()
{
    Return
}

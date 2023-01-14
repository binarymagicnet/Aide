#include "lib/RAEdit.h"
#include "raEdit.h"
$PRAGMA lib "lib/libRAEditC.a"

SUB RaNewEdit()
    DIM pn
    DIM AS RECT rc

    pn = TabCtrl_GetItemCount(ghMainTab)

    GetClientRect (ghMainTab, &rc)
    AdjustWindowRect (&rc, 0, 0)

    IF pn THEN
      BCX_ADDTAB(ghMainTab, pn, "New.bas")
      ghEdit[pn] =  BCX_CONTROL("RAEdit", ghTab[pn], "This is Page ", pn+6000, rc.left,rc.top,rc.right-rc.left-8,rc.bottom-rc.top-26, _
        WS_CHILD OR WS_VISIBLE OR WS_BORDER OR ES_LEFT OR ES_MULTILINE OR STYLE_AUTOSIZELINENUM OR STYLE_NOLINENUMBER OR STYLE_DRAGDROP OR STYLE_NOSIZEGRIP) 
    END IF

    RaConfigEditor(ghEdit[pn])
  
END SUB

SUB RaConfigEditor(hEDT as HWND)  

    ' Set Editor Font
    BCX_SET_FONT(hEDT, "Consolas", 12)

    ' Enable Line Numbers
    CheckDlgButton(hEDT,-2,TRUE)
    SendMessage(hEDT, WM_COMMAND, -2, 0)

    ' Highlite Active Line in Editor
    SendMessage(hEDT, REM_HILITEACTIVELINE, 0, 2)
    
    ' Set the comment character
    SendMessage(hEDT, REM_SETCHARTAB, ASC(";"), CT_OPER)
    SendMessage(hEDT, REM_SETCHARTAB, ASC("'"), CT_CMNTCHAR)


    ' Enable Block Guides
    SendMessage(hEDT, REM_SETSTYLEEX, STYLEEX_BLOCKGUIDE,0)

    ' Set up tabbing; 4 spaces, also convert to spaces on load?
    SendMessage(hEDT, CONVERT_TABTOSPACE, 0, 0)
    SendMessage(hEDT, REM_TABWIDTH, 4, TRUE)

    ' SendMEssage(RAEdit, REM_CONVERT, CONVERT_UPPERCASE, 0)

    SendMessage(hEDT, REM_SETSTYLEEX, STILEEX_STRINGMODEFB, 0)

    SendMessage(hEDT, REM_SETSTYLEEX, STILEEX_LINECHANGED, 0)

    ' Set Colors and Keywords
    RaSetColors(hEDT)
    RaLoadKeyWords(hEDT)

    ' Set Folding Words, minimal list
    ' [$] is a placeholder, [!] disable folding if following word is at eol?
    ' Optional Number or define at end of function call specifies the type of styling
    RaSetBlocks(hEDT,"begin events", "end events",0)
    RaSetBlocks(hEDT,"begin dialog", "end dialog",0)
    RaSetBlocks(hEDT,"begin modal dialog", "end dialog",0)
    RaSetBlocks(hEDT,"%private %public Function $","end Function")
    RaSetBlocks(hEDT,"if $! then", "EndIf|End If")
    RaSetBlocks(hEDT,"with $", "end with")
    RaSetBlocks(hEDT,"select case !end select","End Select")
    RaSetBlocks(hEDT,"%private %public sub $","end sub")
    RaSetBlocks(hEDT,"enum", "end enum",0)
    RaSetBlocks(hEDT,"while $ !wend", "wend",0)
    RaSetBlocks(hEDT,"type!as","End Type",0)
    RaSetBlocks(hEDT,"do!loop","Loop",0)
    RaSetBlocks(hEDT,"while $ !wend","wend",0)
    RaSetBlocks(hEDT,"for $ !next","next",0)
    
    SetFocus(hEDT)
END SUB
' Sets keyword blocks for folding
Function RaSetBlocks OPTIONAL (hEDT as HWND, start_block AS STRING, end_block AS STRING, flag AS INTEGER = 0) AS INTEGER
    DIM AS RABLOCKDEF blockdef
    SendMessage(hEDT, REM_SETBLOCKS,0,0)
    WITH blockdef
        .lpszStart	= start_block
        .lpszEnd 	= end_block
        .lpszNot1	= 0
        .lpszNot2	= 0
        .flag 		= flag
    END WITH
    
  FUNCTION = SendMessage(hEDT, REM_ADDBLOCKDEF, 0, &blockdef)
END FUNCTION

Function RaLoadKeyWords(hEDT AS HWND) As INTEGER
    DIM AS INTEGER r
    DIM AS DWORD rcSize

    r = SendMessage(hEDT, REM_SETHILITEWORDS, 0xc48a4c, (LPCSTR)GetResource(RC_KEYWORDS, RT_RCDATA, &rcSize))
    r = SendMessage(hEDT, REM_SETHILITEWORDS, 0x5f5fce, (LPCSTR)GetResource(RC_WINAPI, RT_RCDATA, &rcSize))

  FUNCTION  = r
End Function

' Configure color scheme for RAEdit object
SUB RaSetColors(hEDT as HWND)
    DIM AS RACOLOR colors
    
    WITH colors
        .bckcol         =		QBCOLOR(0)      '  Back color
        .txtcol         =		QBCOLOR(11)     '  Text color
        .selbckcol      =		0xd89f62        '  Sel back color
        .seltxtcol      =		SELTXTCLR       '  Sel text color
        .cmntcol        =		QBCOLOR(24)     '  Comment color
        .strcol         =		RGB(0,193,0)    '  String color
        .oprcol         =		0x5f5fce        '  Operator color
        .hicol1         =		HILITE1         '  Line hilite 1  [ current line color option 1 ]
        .hicol2         =		0x303030        '  Line hilite 2 [ current line color option 2 ]
        .hicol3         =		HILITE3         '  Line hilite 3  [ current line color option 3 ]
        .selbarbck      =		RGB(20,20,20)   '  Line numbers panel background
        .selbarpen      =		SELBARPEN       '  Selection bar pen
        .lnrcol         =		0xffffff        '  Line numbers color
        .numcol         =		0x5f5fce        '  Numbers & hex color
        .cmntback       =		QBCOLOR(0)      '  Comment back color
        .strback        =		QBCOLOR(0)      '  String back color
        .numback        =		QBCOLOR(0)      '  Numbers & hex back color
        .oprback        =		QBCOLOR(0)      '  Operator back color
        .changed        =		CHANGEDCLR      '  Line changed indicator
        .changesaved    =   	CHANGESAVEDCLR  '  Line saved chane indicator
    END WITH

    SendMessage(hEDT, REM_SETCOLOR, 0, &colors)
END SUB

' Loads file into RAEdit object
FUNCTION RaLoadFile(edt AS HWND) AS STRING
    DIM RetStr$
    DIM AS CHARRANGE chrg
    RetStr$ = GetFileName$("Open File...", "BCX Files|*.BAS;*.INC;*.bi;*.bci")
    IF Len(RetStr$) THEN


        EDITLOADFILE(edt, RetStr$)
        chrg.cpMin = 0
        chrg.cpMax = 0
        SendMessage(edt, EM_EXSETSEL, 0, &chrg)
        SendMessage(edt, EM_SCROLLCARET, 0, 0)
        SendMessage(edt, REM_HILITEACTIVELINE, 0, 2)
        SendMessage(edt, EM_SETMODIFY, FALSE, 0)
        SendMessage(edt, REM_SETCHANGEDSTATE, FALSE, 0)
        SetFocus(edt)
        
    END IF
    FUNCTION = RetStr$
END FUNCTION

SUB RaSaveFile(hEDT as HWND)
    DIM eSIZE, fNAME$, tabName$

    eSIZE = GetWindowTextLength(hEDT)
    DIM eTEXT$*eSIZE+1

    tabName$ = RaGetTabLabelText(TabCtrl_GetCurSel(ghMainTab))

    IF tabName$ = "New.bas" THEN
        fNAME$ = GETFILENAME$("Save","BCX Files|*.BAS;*.INC;*.bi;*.bci",1,ghMainFrm,0,0,tabName$,0)
    ELSE
        fNAME$ = tabName$
    END IF

    IF LEN(fNAME$) THEN
        eTEXT$ = BCX_GET_TEXT$(hEDT)
        OPEN fNAME$ FOR BINARY NEW AS FP1
        PUT$ FP1, eTEXT$, LEN(eTEXT$)
        CLOSE FP1
        RaSetTabLabelText(fNAME$, RaGetTab())
    END IF
END SUB

FUNCTION RaGetTab() AS INTEGER
    FUNCTION = TabCtrl_GetCurSel(ghMainTab)
END FUNCTION

FUNCTION RaGetTabLabelText$(index AS INTEGER)
    DIM AS TCITEM tabItem
    DIM tabLabel$

    tabItem.mask = TCIF_TEXT
    tabItem.pszText = tabLabel
    tabItem.cchTextMax = sizeof(tabLabel)

    TabCtrl_GetItem(ghMainTab, index, &tabItem)
    
    FUNCTION =  TRIM$(tabLabel)
END FUNCTION

SUB RaSetTabLabelText(fname$, index AS INTEGER)
    DIM AS TCITEM tabItem

    tabItem.mask=TCIF_TEXT
    tabItem.pszText = BCXSPLITPATH$(fname$,FNAME OR FEXT)
    tabItem.cchTextMax = BCXSTRSIZE

    TabCtrl_SetItem(ghMainTab, index, &tabItem)
END SUB

SUB RaGotoLine(hEDT as HWND, Line AS INTEGER)
    Dim chrg As CHARRANGE
    DIM GotoLine

    GotoLine = SendMessage(hEDT, EM_LINEINDEX, Line, 0)
    chrg.cpMin = GotoLine
    chrg.cpMax = GotoLine

    SendMessage(hEDT, EM_EXSETSEL, 0, &chrg)
    SendMessage(hEDT, EM_SCROLLCARET, 0, 0)
END SUB

SUB RaCut(hEDT as HWND)
    SendMessage(hEDT, WM_CUT, 0, 0)
    SetFocus(hEDT)
END SUB

SUB RaCopy(hEDT as HWND)
    SendMessage(hEDT, WM_COPY, 0, 0)
    SetFocus(hEDT)
END SUB

SUB RaPaste(hEDT as HWND)
    SendMessage(hEDT, WM_PASTE, 0, 0)
    SetFocus(hEDT)
END SUB

SUB RaSelectAll(hEDT as HWND)
    SendMessage(hEDT, EM_SETSEL, 0, -1)
    SetFocus(hEDT)
END SUB

SUB RaUndo(hEDT as HWND)
    SendMessage(hEDT, EM_UNDO, 0, 0)
    SetFocus(hEDT)
END SUB

SUB RaRedo(hEDT as HWND)
    SendMessage(hEDT, EM_REDO, 0, 0)
    SetFocus(hEDT)
END SUB

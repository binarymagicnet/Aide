$ACCELERATOR ghAccTable
GUI "Color_Tab", PIXELS, ICON, 6666

$include "raedit.inc"

CONST fWidth = 900
CONST fHeight = 600
CONST nTabs = 20

GLOBAL ghMainFrm AS CONTROL
GLOBAL ghMainTab AS CONTROL
GLOBAL ghStatus  AS CONTROL

GLOBAL ghTab[nTabs]  AS HWND
GLOBAL ghEdit[nTabs] AS HWND

SET gTabPage$[nTabs]
    "<Untitled.bas>"
END SET
   


ENUM
    mnuNew = 9000
    mnuOpen
    mnuSave
    mnuCut
    mnuCopy
    mnuPaste
    mnuUNDO
    mnuREDO
    mnuSELECTALL
    mnuAbout
    mnuEXIT
    ID_TAB
    ID_EDIT1
END ENUM
   
  '================================================================
 SUB FORMLOAD()
    IF FINDFIRSTINSTANCE(BCX_CLASSNAME$) THEN PostQuitMessage(0)
    SET sAccel[] AS ACCEL
        FCONTROL OR FVIRTKEY, ASC("N"), mnuNew,
        FCONTROL OR FVIRTKEY, ASC("O"), mnuOpen,
        FCONTROL OR FVIRTKEY, ASC("S"), mnuSave,
        FCONTROL OR FVIRTKEY, ASC("Q"), mnuEXIT
    END SET

    GLOBAL AS HACCEL ghAccTable 
    ghAccTable = CreateAcceleratorTable(sAccel, 4)

    InstallRAEdit(BCX_hInstance, FALSE)

    ghMainFrm = BCX_FORM("AIDE Demo", 0, 0, fWidth, fHeight)
   
    
   
    DIM rc AS RECT
    GetClientRect (ghMainFrm, &rc)
    AdjustWindowRect (&rc, 0, 0)

    ghMainTab = BCX_TAB(ghMainFrm, ID_TAB, 1, ghTab, gTabPage$, 0, 0, fWidth, fHeight-26,NULL)
    BCX_SET_FONT(ghMainTab, "Verdana", 9)

    ghEdit[0] =  BCX_CONTROL("RAEdit", ghTab[0], "", 6000, rc.left,rc.top,rc.right-rc.left-8,rc.bottom-rc.top-46, _
      WS_CHILD OR WS_VISIBLE OR WS_BORDER OR ES_LEFT OR ES_MULTILINE OR STYLE_AUTOSIZELINENUM OR STYLE_NOLINENUMBER OR STYLE_DRAGDROP OR STYLE_NOSIZEGRIP)

    RaConfigEditor(ghEdit[0])

    SetupMenu(ghMainFrm)

    ghStatus = BCX_STATUS("Line: 1, Column: 1", ghMainFrm)

    'Generate a WM_SIZE message
    MoveWindow(ghMainFrm, 0, 0, fWidth, fHeight, TRUE) 'Force a WM_SIZE
   
    CENTER(ghMainFrm)
    SHOW(ghMainFrm)
   
    ' SetFocus(ghEdit[0])
   
  END SUB
   

SUB SetupMenu(parent as HWND)
    GLOBAL AS HMENU MainMenu, FileMenu, EditMenu, HelpMenu
    MainMenu = CreateMenu()
    FileMenu = CreateMenu()
    EditMenu = CreateMenu()
    HelpMenu = CreateMenu()
    
    InsertMenu(MainMenu,  0, MF_POPUP, FileMenu, "&File")
    AppendMenu(FileMenu, MF_STRING, mnuNew, E"New\tCtrl-N")
    AppendMenu(FileMenu, MF_STRING, mnuOpen, E"Open\tCtrl-O")
    AppendMenu(FileMenu, MF_STRING, mnuSave, E"Save\tCtrl-S")
    AppendMenu(FileMenu, MF_SEPARATOR, 0, NULL)
    AppendMenu(FileMenu, MF_STRING, mnuEXIT, E"Exit\tAlt-F4")

    Insertmenu(MainMenu, 1, MF_POPUP, EditMenu, "&Edit")
    AppendMenu(EditMenu, MF_STRING, mnuCut, E"Cut\tCtrl-X")
    AppendMenu(EditMenu, MF_STRING, mnuCopy, E"Copy\tCtrl-C")
    AppendMenu(EditMenu, MF_STRING, mnuPaste, E"Paste\tCtrl-V")
    AppendMenu(EditMenu, MF_SEPARATOR, 0, NULL)
    AppendMenu(EditMenu, MF_STRING, mnuSELECTALL, E"Select All\tCtrl-A")
    AppendMenu(EditMenu, MF_SEPARATOR, 0, NULL)
    AppendMenu(EditMenu, MF_STRING, mnuUNDO, E"Undo\tCtrl-Z")
    AppendMenu(EditMenu, MF_STRING, mnuREDO, E"Redo\tCtrl-Y")

    Insertmenu(MainMenu, 2, MF_POPUP, HelpMenu, "Help")
    AppendMenu(HelpMenu, MF_STRING, mnuAbout, "About")

    SetMenu(parent, MainMenu)

END SUB

FUNCTION GetTabLabelText$(index AS INTEGER)
    DIM AS TCITEM tabItem
    DIM tabLabel$

    tabItem.mask = TCIF_TEXT
    tabItem.pszText = tabLabel
    tabItem.cchTextMax = sizeof(tabLabel)

    TabCtrl_GetItem(ghMainTab, index, &tabItem)
    
    FUNCTION =  TRIM$(tabLabel)
END FUNCTION

SUB SetTabLabelText(fname$, index AS INTEGER)
    DIM AS TCITEM tabItem

    tabItem.mask=TCIF_TEXT
    tabItem.pszText = BCXSPLITPATH$(fname$,FNAME OR FEXT)
    tabItem.cchTextMax = BCXSTRSIZE

    TabCtrl_SetItem(ghMainTab, index, &tabItem)
END SUB

SUB RaSaveFile(hEDT as HWND)
    DIM eSIZE, fNAME$, tabName$

    eSIZE = GetWindowTextLength(hEDT)
    DIM eTEXT$*eSIZE+1

    tabName$ = GetTabLabelText(TabCtrl_GetCurSel(ghMainTab))

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
        SetTabLabelText(fNAME$, TabCtrl_GetCurSel(ghMainTab))
    END IF


END SUB
  '================================================================
  
BEGIN EVENTS
    SELECT CASE CBMSG
   
        CASE WM_SHOWWINDOW
            SetTabLabelText("New.bas",0)
        CASE WM_COMMAND
                SELECT CASE CBCTL
                    CASE mnuOpen
                        dim fname$

                        IF TRIM$(GetTabLabelText(TabCtrl_GetCurSel(ghMainTab))) <> "New.bas" THEN
                            RaNewEdit()
                        END IF

                        fname$ = RaLoadFile(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                        IF LEN(fname$) THEN
                            SetTabLabelText(fname$, TabCtrl_GetCurSel(ghMainTab))
                        END IF

                    CASE mnuSave
                        RaSaveFile(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuNew
                        RaNewEdit()

                    CASE mnuCut
                        RaCut(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuCopy
                        RaCopy(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuPaste
                        RaPaste(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuSELECTALL
                        RaSelectAll(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuUNDO
                        RaUndo(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuREDO
                        RaRedo(ghEdit[TabCtrl_GetCurSel(ghMainTab)])

                    CASE mnuEXIT
                        PostMessage(hWnd, WM_CLOSE, 0, 0)

                END SELECT
        
        CASE WM_SIZE
            DIM cxClient%
            DIM cyClient%
            DIM rc AS RECT

            cxClient=LOWORD(lParam)
            cyClient=HIWORD(lParam)
    
            MoveWindow(ghMainTab, 0, 2, cxClient+1, cyClient-22, TRUE)

            
        
            GetClientRect (ghMainTab, &rc)
            AdjustWindowRect (&rc, 0, 0)
            FOR INTEGER i = 0 to sizeof(ghEdit)/sizeof(ghEdit[0])
                IF ghEdit[i] THEN
                    SetWindowPos(ghEdit[i], NULL, rc.left, rc.top+2, (rc.right - rc.left)-8, (rc.bottom - rc.top)-26, SWP_NOZORDER OR SWP_NOMOVE )
                END IF
            NEXT
            
            SendMessage(ghStatus, WM_SIZE, 0, 0)
    
        CASE WM_NOTIFY
            DIM LPNMHDR AS NMHDR*
            DIM PageNo  AS LONG
            DIM bm, buff$
            DIM AS RASELCHANGE PTR lpRASELCHANGE = (RASELCHANGE PTR)lParam
            
            LPNMHDR = (NMHDR*)lParam
        
            IF LPNMHDR->code >= TCN_LAST && LPNMHDR->code <= TCN_FIRST THEN
                SELECT CASE LPNMHDR->code
                    CASE TCN_SELCHANGE
                        PageNo = TabCtrl_GetCurSel(ghMainTab)
                        SetFocus(ghEdit[PageNo])
                END SELECT
            END IF

            IF LPNMHDR->hwndFrom = ghEdit[TabCtrl_GetCurSel(ghMainTab)] THEN

                IF LPNMHDR->code = EN_SELCHANGE THEN
                    ' Update statusbar
                    SPRINT buff,"Line:", lpRASELCHANGE->line+1, ", Column:", lpRASELCHANGE->chrg.cpMin - lpRASELCHANGE->cpLine+1
                    SetWindowText(ghStatus, buff)
                END IF

                IF lpRASELCHANGE->seltyp = SEL_OBJECT THEN
                    ' Bookmark clicked
                    bm=SendMessage(ghEdit[TabCtrl_GetCurSel(ghMainTab)],REM_GETBOOKMARK, lpRASELCHANGE->line,0)
                    SELECT CASE bm
                        CASE 1
                            ' Collapse
                            SendMessage(ghEdit[TabCtrl_GetCurSel(ghMainTab)],REM_COLLAPSE, lpRASELCHANGE->line,0)     
                        CASE 2
                            ' Expand
                            SendMessage(ghEdit[TabCtrl_GetCurSel(ghMainTab)],REM_EXPAND, lpRASELCHANGE->line,0)
                    END SELECT
                ELSE
                    ' Selection changed
                    IF lpRASELCHANGE->fchanged THEN
                        ' Update block bookmarks
                        SendMessage(ghEdit[TabCtrl_GetCurSel(ghMainTab)],REM_SETBLOCKS,0,0)
                    END IF
                END IF
            END IF

            

        CASE WM_CLOSE
            DestroyWindow(hWnd)

        
        CASE WM_DESTROY
            PostQuitMessage(0)


        Case WM_CONTEXTMENU
            DIM AS POINT pt
            If wParam=(WPARAM)ghTab[TabCtrl_GetCurSel(ghMainTab)] Then
                pt.x = LOWORD(lParam)
                pt.y = HIWORD(lParam)
                TrackPopupMenu( GetSubMenu( GetMenu(hWnd), 1 ), TPM_LEFTALIGN or TPM_RIGHTBUTTON, pt.x, pt.y, 0, hWnd, 0 )
            EndIf


        CASE WM_GETMINMAXINFO
            DIM AS LPMINMAXINFO mm = cast(LPMINMAXINFO,lParam)
            DIM AS UINT wDpi = GetDpiForWindow(hWnd)
            DIM AS DOUBLE scalingFactor = (double)wDpi / 96
            DIM AS POINT defDims

            defDims.x = fWidth + wDpi + scalingFactor '+ (fWidth  * scalingFactor)
            defDims.y = fHeight + wDpi + scalingFactor '+ (fHeight * scalingFactor)

            mm->ptMinTrackSize = defDims   

    END SELECT
END EVENTS


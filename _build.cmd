@SETLOCAL 
@ECHO OFF

:: *********************************************
:: EDIT THESE TWO VARIABLES TO POINT TO THE
:: LOCATIONS OF PELLESC AND BC.EXE
@SET PellesFolder=c:\Users\riveraa\Apps\PellesC
@SET BCX=c:\Users\riveraa\Apps
:: *********************************************

SET APP=Aide

@IF NOT EXIST %APP%.bas (
    @ECHO %APP%.bas was not found. Operation aborted.
    GOTO Done
)

@IF EXIST %APP%.exe @DEL %APP%.exe

@SET  PATH=%PellesFolder%\Bin;%BCX%;%PATH%;
@SET  INCLUDE=%PellesFolder%\Include;%PellesFolder%\Include\Win;%INCLUDE%;
@SET  LIB=%PellesFolder%\Lib;%PellesFolder%\Lib\Win64;%LIB%;

@SET  PoccOPTS= /Go /Gn /W1 /Gd /Ze /Zx /Tx64-coff /D NTDDI_VERSION=0x0A000007 /std:c17 /fp:precise 
@SET  PolinkOPTS= -release -machine:x64 /subsystem:windows,5.02 /STACK:10485760               
@SET  PolinkLIBS= kernel32.lib advapi32.lib delayimp.lib user32.lib gdi32.lib comctl32.lib comdlg32.lib ole32.lib oleaut32.lib

@ECHO ON 
@ECHO **************************************************************************

@IF EXIST %APP%.bas (
    @ECHO.
    @ECHO BCX is converting [%APP%.bas] to C file [%APP%.c]
    bc %APP%.bas -q
)

@IF EXIST %APP%.rc (
    @ECHO.
    @ECHO Pelles C is converting rc script [ %APP%.rc ] into a 64-bit RESOURCE file.
    porc   %APP%.rc 
    @ IF EXIST %APP%.res SET PolinkLIBS=%PolinkLIBS% %APP%.res
) 

@IF EXIST %APP%.c (
    @ECHO.
    @ECHO Pelles C is compiling [ %APP%.c ] as a 64-bit GUI application.
    pocc    %PoccOPTS%    "%APP%.c"
    polink  %PolinkLIBS%  %PolinkOPTS%    "%APP%.obj"  %2 %3 %4 %5 %6 %7 %8 %9  
    @ECHO.
)

@IF EXIST %APP%.exe @ECHO Pelles C built [ %APP%.exe ]
@ECHO.
@ECHO **************************************************************************
@ECHO OFF
:Done
@ENDLOCAL

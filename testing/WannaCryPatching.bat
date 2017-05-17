@ECHO OFF

REM XP32bit
@ver | find "5.1.2600"
if "%ERRORLEVEL%"=="0" (
    ECHO= Please download http://download.windowsupdate.com/d/csa/csa/secu/2017/02/windowsxp-kb4012598-x86-custom-enu_eceb7d5023bbb23c0dc633e46b9c2f14fa6ee9dd.exe
)

REM XP64bit/2003/2003R2
@ver | find "5.2.3790"
if "%ERRORLEVEL%"=="0" (
    if exist "%ProgramFiles(x86)%" (
    ECHO= Please download http://download.windowsupdate.com/d/csa/csa/secu/2017/02/windowsserver2003-kb4012598-x64-custom-enu_f24d8723f246145524b9030e4752c96430981211.exe
    ) else (
    ECHO= Please download http://download.windowsupdate.com/c/csa/csa/secu/2017/02/windowsserver2003-kb4012598-x86-custom-enu_f617caf6e7ee6f43abe4b386cb1d26b3318693cf.exe
    ) 
)

REM VISTA/2008
@ver | find "6.0.600"
if "%ERRORLEVEL%"=="0" (
    if exist "%ProgramFiles(x86)%" (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/d/msdownload/update/software/secu/2017/02/windows6.0-kb4012598-x64_6a186ba2b2b98b2144b50f88baf33a5fa53b5d76.msu
    ) else (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/d/msdownload/update/software/secu/2017/02/windows6.0-kb4012598-x86_13e9b3d77ba5599764c296075a796c16a85c745c.msu
    )
    CALL :PATCHING
)

REM WIN7/2008R2
@ver | find "6.1.760"
if "%ERRORLEVEL%"=="0" (
    if exist "%ProgramFiles(x86)%" (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/d/msdownload/update/software/secu/2017/02/windows6.1-kb4012212-x64_2decefaa02e2058dcd965702509a992d8c4e92b3.msu
    ) else (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/d/msdownload/update/software/secu/2017/02/windows6.1-kb4012212-x86_6bb04d3971bb58ae4bac44219e7169812914df3f.msu
    )
    CALL :PATCHING
)

REM WIN8/2012
@ver | find "6.2.9200"
if "%ERRORLEVEL%"=="0" (
    if exist "%ProgramFiles(x86)%" (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/c/msdownload/update/software/secu/2017/05/windows8-rt-kb4012598-x64_f05841d2e94197c2dca4457f1b895e8f632b7f8e.msu
    ) else (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/c/msdownload/update/software/secu/2017/05/windows8-rt-kb4012598-x86_a0f1c953a24dd042acc540c59b339f55fb18f594.msu
    )
    CALL :PATCHING
)

REM WIN8.1/2012R2
@ver | find "6.3.9"
if "%ERRORLEVEL%"=="0" (
    if exist "%ProgramFiles(x86)%" (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/c/msdownload/update/software/secu/2017/02/windows8.1-kb4012213-x64_5b24b9ca5a123a844ed793e0f2be974148520349.msu
    ) else (
    @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/c/msdownload/update/software/secu/2017/02/windows8.1-kb4012213-x86_e118939b397bc983971c88d9c9ecc8cbec471b05.msu
    )
    CALL :PATCHING
)

REM WIN10
REM @ver | find "10.0.1"
REM if "%ERRORLEVEL%"=="0" (
REM     CALL :PATCHING
REM )

REM 2016
REM @ver | find "10.0.1"
REM if "%ERRORLEVEL%"=="0" (
REM     @SET REMOTE_SOURCE_BATCH_URL=http://download.windowsupdate.com/c/msdownload/update/software/secu/2017/03/windows10.0-kb4013429-x64_delta_24521980a64972e99692997216f9d2cf73803b37.msu
REM     CALL :PATCHING
REM )

:PATCHING
@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
FOR %%a in ("%REMOTE_SOURCE_BATCH_URL%\.") do SET PATCH_NAME=%%~nxa
@SET DOWNLOAD_COMMAND=$webClient=new-object System.Net.WebClient; $webClient.DownloadFile('%REMOTE_SOURCE_BATCH_URL%', '%PATCH_NAME%')
powershell -noprofile -noninteractive -command "%DOWNLOAD_COMMAND%"
FOR /R "%~dp0" %%A IN (*Windows*-KB*.MSU) DO (
        CALL :SUB %%~nA
    >NUL net stop wuauserv
    START /WAIT "Installing KB!KB_NUM!" WUSA "%%A" /quiet /norestart)
    SET ReturnCode=%ERRORLEVEL%

If %ReturnCode%==1707 set ReturnCode=3010
If %ReturnCode%==2359301 set ReturnCode=3010
If %ReturnCode%==2359302 set ReturnCode=0
If %ReturnCode%==2359303 set ReturnCode=0
If %ReturnCode%==-2145124343 set ReturnCode=1618
If %ReturnCode%==-2145124330 set ReturnCode=1641
If %ReturnCode%==-2145124329 set ReturnCode=0
If %ReturnCode%==2149842953 set ReturnCode=1618
If %ReturnCode%==2149842966 set ReturnCode=1641
If %ReturnCode%==2149842967 set ReturnCode=0

If %ReturnCode%==0 ECHO Success, no reboot required
If %ReturnCode%==1618 ECHO Fast Retry
If %ReturnCode%==1641 ECHO Soft Reboot required
If %ReturnCode%==3010 ECHO Success, reboot required

@ENDLOCAL
EXIT /B %ReturnCode%

:SUB
SET "KB_NUM=%*"
FOR /F "DELIMS=-" %%B IN ("%KB_NUM:*-KB=%") DO SET "KB_NUM=%%B"
EXIT /B 0

:: This batch file stops CAB and CPS files filling up temporary storage caused by Trusted Installed and Windows Update services.
@ECHO OFF

:: Title for Batch Script
title The Fumigator

:: Display Text
Echo Executing The Fumigator, hold your breath.

:: Stop Windows Update Service
net stop wuauserv

:: Delete all files/folders WITHIN Temp directory
del /f/s/q C:\Windows\Temp > nul
rmdir /s/q C:\Windows\Temp

:: Rename Folder
Rename  C:\Windows\SoftwareDistribution C:\Windows\SoftwareDistribution.old

:: Start Windows Update Service
net start wuauserv

:: Wait 30 seconds (User can't skip)
timeout /t 30 /nobreak

:: Delete Folder
RD /S /Q "C:\Windows\SoftwareDistribution.old"

:: Wait 10 seconds (User can't skip)
timeout /t 10 /nobreak

:: Stop Windows Module Installer
net stop TrustedInstaller

:: Delete all files/folders WITHIN CBS directory
del /f/s/q C:\Windows\Logs\CBS > nul
rmdir /s/q C:\Windows\Logs\CBS

:: Wait 60 seconds (User can't skip)
timeout /t 60 /nobreak

:: Start Windows Module Installer
net start TrustedInstaller

:: Query the WSUS server for its needed patches
wuauclt.exe /resetauthorization /detectnow

:: Display Text
echo.
echo.
echo.
echo Your CAB files are no longer an issue.
echo.
echo.
echo This script was written by ***** on behalf of *****.

:: Leaves window open
PAUSE
@echo off

echo Cleaning Printer Spooler.
echo.
echo.

ping -n 2 localhost 2>nul >nul

taskkill /f /im spoolsv.exe
taskkill /f /im spoolsv.exe
taskkill /f /im spoolsv.exe
taskkill /f /im spoolsv.exe
taskkill /f /im spoolsv.exe


del /f /q c:\windows\system32\spool\printers

taskkill /f /im spoolsv.exe

del /f /q c:\windows\system32\spool\printers

taskkill /f /im spoolsv.exe

del /f /q c:\windows\system32\spool\printers

taskkill /f /im spoolsv.exe

del /f /q c:\windows\system32\spool\printers

taskkill /f /im spoolsv.exe

del /f /q c:\windows\system32\spool\printers

taskkill /f /im spoolsv.exe

del /f /q c:\windows\system32\spool\printers

net start spooler

ping -n 6 localhost 2>nul >nul


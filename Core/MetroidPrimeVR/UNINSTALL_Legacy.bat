@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_MetroidPrimeVR.ps1" -Variant Legacy %*
exit /b %errorlevel%

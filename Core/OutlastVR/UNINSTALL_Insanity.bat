@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Insanity.ps1" %*
if errorlevel 1 pause
exit /b %errorlevel%

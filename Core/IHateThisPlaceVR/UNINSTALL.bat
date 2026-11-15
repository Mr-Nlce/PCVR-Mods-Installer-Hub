@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_IHateThisPlaceVR.ps1" %*
exit /b %ERRORLEVEL%

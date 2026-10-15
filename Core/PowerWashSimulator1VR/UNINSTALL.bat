@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_PowerWashSimulator1VR.ps1" %*
exit /b %ERRORLEVEL%

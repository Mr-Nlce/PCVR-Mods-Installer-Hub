@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\DescentVRShared\Uninstall-DescentVR.ps1" -Key d2 %*
exit /b %ERRORLEVEL%

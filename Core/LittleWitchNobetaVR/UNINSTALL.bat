@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_NobetaVR.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
exit /b %PCVR_EXIT%

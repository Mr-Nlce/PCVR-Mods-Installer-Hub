@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_TurokVR.ps1" -NoPause %*
set "PCVR_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %PCVR_EXIT%

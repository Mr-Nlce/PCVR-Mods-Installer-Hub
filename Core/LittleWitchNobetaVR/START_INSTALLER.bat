@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0LittleWitchNobetaVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %PCVR_EXIT%

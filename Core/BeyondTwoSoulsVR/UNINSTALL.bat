@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_BeyondTwoSoulsVR.ps1" %*
exit /b %ERRORLEVEL%

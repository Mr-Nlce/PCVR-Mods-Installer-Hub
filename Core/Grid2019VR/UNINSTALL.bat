@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Grid2019VR.ps1" %*
exit /b %ERRORLEVEL%
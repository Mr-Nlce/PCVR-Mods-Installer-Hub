@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_GrayHorizonFH5.ps1" %*
exit /b %ERRORLEVEL%


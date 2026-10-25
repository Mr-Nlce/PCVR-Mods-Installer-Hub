@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_GrayHorizonFH4.ps1" %*
exit /b %ERRORLEVEL%


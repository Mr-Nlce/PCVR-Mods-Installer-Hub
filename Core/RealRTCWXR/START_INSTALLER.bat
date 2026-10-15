@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RealRTCWXR-core.ps1"
exit /b %ERRORLEVEL%

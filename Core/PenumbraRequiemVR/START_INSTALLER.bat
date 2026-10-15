@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PenumbraRequiemVR-core.ps1"
exit /b %ERRORLEVEL%

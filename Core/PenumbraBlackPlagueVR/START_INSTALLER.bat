@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PenumbraBlackPlagueVR-core.ps1"
exit /b %ERRORLEVEL%

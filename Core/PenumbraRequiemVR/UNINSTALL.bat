@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\PenumbraFrameworkVR\PenumbraFrameworkVR-core.ps1" -Game Requiem -Mode Manage
exit /b %ERRORLEVEL%

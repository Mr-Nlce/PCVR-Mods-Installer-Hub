@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SinEpisodesVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
endlocal & exit /b %PCVR_EXIT%
@echo off
color 0B
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RaftVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL.ps1" %*
set "rc=%errorlevel%"
if not "%rc%"=="0" (
  echo.
  echo The SiN VR uninstaller stopped safely. The error above remains visible.
  pause
)
endlocal & exit /b %rc%

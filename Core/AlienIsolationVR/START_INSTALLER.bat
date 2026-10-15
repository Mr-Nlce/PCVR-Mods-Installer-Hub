@echo off
setlocal
title Alien: Isolation VR Mod Installer
color 0B

net session >nul 2>&1
if %errorlevel%==0 goto elevated

echo ============================================================
echo  Alien: Isolation VR needs administrator permission to write
echo  to the game folder and apply its Windows 11 registry fix.
echo  Windows will show a UAC prompt after you press Enter.
echo ============================================================
set "PCVR_ALIEN_CORE=%~dp0AlienIsolationVR-core.ps1"
set "PCVR_ALIEN_CONFIRM="
set /p "PCVR_ALIEN_CONFIRM=Press Enter to request administrator access: "
if defined PCVR_ALIEN_CONFIRM (
    echo Cancelled before requesting administrator access.
    endlocal & exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $a=@('-NoProfile','-ExecutionPolicy','Bypass','-File',([char]34 + $env:PCVR_ALIEN_CORE + [char]34)); $p=Start-Process -FilePath 'powershell.exe' -ArgumentList $a -Verb RunAs -Wait -PassThru -ErrorAction Stop; if($null -eq $p){exit 1}; exit $p.ExitCode } catch { Write-Host 'Administrator permission was declined or the installer could not start.' -ForegroundColor Yellow; exit 1 }"
set "PCVR_EXIT=%ERRORLEVEL%"
endlocal & exit /b %PCVR_EXIT%

:elevated
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0AlienIsolationVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" (
    echo.
    echo Installer failed. Check the message above before closing this window.
    pause
)
endlocal & exit /b %PCVR_EXIT%

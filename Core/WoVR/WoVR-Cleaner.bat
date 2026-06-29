echo off
SET batFolder=%~dp0
echo Deleting unneeded folders/files from %batFolder%
pause

rmdir /S /Q "%batFolder%Cache"
rmdir /S /Q "%batFolder%Errors"
rmdir /S /Q "%batFolder%Interface\AddOns"
rmdir /S /Q "%batFolder%Logs"
rmdir /S /Q "%batFolder%vr"
rmdir /S /Q "%batFolder%WTF"

del /Q "%batFolder%d3d9.dll"
del /Q "%batFolder%openvr_api.dll"

rmdir /S /Q "%batFolder%Updates"
del /Q "%batFolder%BackgroundDownloader.exe"
del /Q "%batFolder%Battle.net.dll"
del /Q "%batFolder%dbghelp.dll"
del /Q "%batFolder%ijl15.dll"
del /Q "%batFolder%Launcher.exe"
del /Q "%batFolder%Microsoft.VC80.CRT.manifest"
del /Q "%batFolder%msvcr80.dll"
del /Q "%batFolder%Patch.html"
del /Q "%batFolder%Patch.txt"
del /Q "%batFolder%Repair.exe"
del /Q "%batFolder%Scan.dll"
del /Q "%batFolder%unicows.dll"
del /Q "%batFolder%WowError.exe"

del /Q "%batFolder%WoVR-Cleaner.bat"

# ============================================================
#  Devil May Cry 5 - REFramework VR Installer
#  REFramework Nightly v01320 by praydog
# ============================================================

$Host.UI.RawUI.WindowTitle = "DMC5 VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME   = "Devil May Cry 5"
$GAME_EXE    = "DevilMayCry5.exe"
$DOWNLOAD_URL = "https://github.com/praydog/REFramework-nightly/releases/download/nightly-01320-8dc91e696d944d95f0fa690851c3c0411ad20d41/DMC5.zip"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "   Devil May Cry 5 - REFramework VR Installer" -ForegroundColor Magenta; Write-Host "   REFramework Nightly v01320 by praydog" -ForegroundColor Gray; Write-Host "   Gamepad or Virtual Desktop touch input" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
function Write-Step   { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK     { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Warn   { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail   { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-Info   { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }; return $null
}
function Get-SteamLibraries {
    param($sp); $libs=@($sp)
    $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
    if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
    return $libs
}

Write-Header

# STEP 1: Locate Devil May Cry 5
Write-Step 1 3 "Locating Devil May Cry 5"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Devil May Cry 5"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
$gamePath  = $null
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $c = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; break }
    }
}
if ($gamePath) {
    Write-OK "Found: $gamePath"
} else {
    Write-Warn "Devil May Cry 5 not found automatically."
    Write-Host "  Please enter the game folder (containing DevilMayCry5.exe):" -ForegroundColor White
    while (-not $gamePath) {
        $r=(Read-Host "  Path").Trim().Trim('"')
        if(Test-Path (Join-Path $r $GAME_EXE)){$gamePath=$r; Write-OK "Path set: $gamePath"} else{Write-Fail "DevilMayCry5.exe not found in: $r"}
    }
}

# STEP 2: Select VR platform
Write-Step 2 3 "Select VR Platform"

Write-Host "  REFramework supports SteamVR (OpenVR) and Oculus/Meta (OpenXR)." -ForegroundColor White
Write-Host ""
Write-Host "    [1] SteamVR  - Steam Link, Valve Index, HTC Vive, WMR" -ForegroundColor White
Write-Host "                 (Virtual Desktop: set to SteamVR mode)" -ForegroundColor Gray
Write-Host "    [2] OpenXR   - Quest via Link/Air Link (Oculus PC app)" -ForegroundColor White
Write-Host "                 (Virtual Desktop: set to OpenXR mode)" -ForegroundColor Gray
Write-Host ""

$vrChoice = ""
while ($vrChoice -notin @("1","2")) { $vrChoice = (Read-Host "  Enter 1 or 2").Trim() }

$useOpenXR = $vrChoice -eq "2"
if ($useOpenXR) { Write-OK "Platform: OpenXR (Quest via Link/Air Link)" }
else             { Write-OK "Platform: SteamVR (Steam Link, Index, Vive, WMR, or Virtual Desktop SteamVR)" }

# STEP 3: Download and install
Write-Step 3 3 "Downloading and Installing REFramework"

$tempDir = Join-Path $env:TEMP "DMC5VRInstaller_$([System.IO.Path]::GetRandomFileName())"
try {
    New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Warn "Could not create a temp folder in TEMP: $_"
    # Fallback: use a temp folder next to the game instead of %TEMP%.
    $tempDir = Join-Path $gamePath "_DMC5VR_dl_tmp"
    try {
        New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction Stop | Out-Null
        Write-Info "Using fallback temp folder: $tempDir"
    } catch {
        Write-Fail "Could not create a working temp folder anywhere: $_"
        Write-Host "  Free up disk space or check folder permissions, then re-run." -ForegroundColor Yellow
        Pause-User "Press Enter to exit..."
        exit 1
    }
}
$zipFile = Join-Path $tempDir "DMC5.zip"

Write-Host "  Downloading REFramework Nightly v01320 ... " -NoNewline -ForegroundColor White
$r = Invoke-DownloadOrFallback -Url $DOWNLOAD_URL -Destination $zipFile `
        -Label "REFramework Nightly DMC5" `
        -ManualUrl "https://github.com/praydog/REFramework-nightly/releases" `
        -Instructions "Download the latest 'DMC5.zip' from the REFramework-nightly releases page. Place it at '$zipFile' and choose Retry." `
        -SkipMessage "Skipped - DMC5 VR mod files not downloaded; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Download was skipped. Install cannot continue. Press Enter to exit..."; exit 1 }

Write-Host "  Extracting into game folder ... " -NoNewline -ForegroundColor White
$efb = Expand-ArchiveOrFallback -ArchivePath $zipFile -DestinationFolder $gamePath `
        -Label "DMC5.zip" `
        -SkipMessage "Skipped - REFramework was NOT extracted into the game folder; the mod cannot run."
if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") { Write-Host "OK" -ForegroundColor Green }

# Verify
$dllCheck = Join-Path $gamePath "dinput8.dll"
if (Test-Path $dllCheck) { Write-OK "dinput8.dll verified." }
else {
    Write-Warn "dinput8.dll not found - the mod may not have extracted correctly."
    $vfb = Invoke-InstallerFallback -Action "REFramework extraction check" `
        -Url "https://github.com/praydog/REFramework-nightly/releases" `
        -Instructions "Open the downloaded DMC5.zip and extract its contents directly into '$gamePath' so that 'dinput8.dll' sits next to the game EXE. Then choose Retry." `
        -SkipMessage "Skipped - dinput8.dll is missing; the VR mod will not load until it is in the game folder." `
        -DestFolder "$gamePath" `
        -AllowSkip $true
    if ([string]$vfb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$vfb -eq "retry") {
        if (Test-Path $dllCheck) { Write-OK "dinput8.dll now present." }
        else { Write-Warn "Still not found - continuing, but check $gamePath manually." }
    }
}

# Handle OpenXR: delete openvr_api.dll
if ($useOpenXR) {
    $openvrDll = Join-Path $gamePath "openvr_api.dll"
    if (Test-Path $openvrDll) {
        try {
            Remove-Item $openvrDll -Force
            Write-OK "openvr_api.dll removed (OpenXR mode)."
        } catch {
            Write-Warn "Could not remove openvr_api.dll: $_"
            Write-Info "Please delete it manually from: $gamePath"
        }
    }
}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Done
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Platform: $(if ($useOpenXR) { 'OpenXR - Quest via Link/Air Link' } else { 'SteamVR' })" -ForegroundColor Cyan
Write-Host ""
Write-Host "--- Controls ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  This mod uses gamepad controls - no motion controls." -ForegroundColor White
Write-Host ""
Write-Host "  Options:" -ForegroundColor White
Write-Host "    - Use a physical gamepad" -ForegroundColor Gray
Write-Host "    - Virtual Desktop users: in the VD Input tab," -ForegroundColor Gray
Write-Host "      enable 'Use touch controllers as gamepad'" -ForegroundColor Gray
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "  Son of Sparda, now in VR. Stylish!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the game folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

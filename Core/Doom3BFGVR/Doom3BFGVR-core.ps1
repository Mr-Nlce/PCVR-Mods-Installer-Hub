# ============================================================
#  DOOM 3 BFG Edition - Fully Possessed VR Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Doom 3 BFG VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME   = "DOOM 3 BFG Edition"
$GAME_EXE    = "Doom3BFG.exe"
$VR_EXE      = "Doom3BFGVR.exe"
$DOWNLOAD_URL = "https://github.com/NPi2Loup/DOOM-3-BFG-VR/releases/download/v0.021j-Alpha/Doom3BFGVR_Fully_Possessed_Alpha021j.zip"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "   DOOM 3 BFG Edition - Fully Possessed VR Installer" -ForegroundColor Magenta; Write-Host "   v0.021j-Alpha by NPi2Loup" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
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

# STEP 1: Locate DOOM 3 BFG Edition
Write-Step 1 3 "Locating DOOM 3 BFG Edition"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Doom 3 BFG"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
$gamePath  = $null
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $c = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path $c) { $gamePath = $c; break }
    }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "208200" -SteamFolderNames @("DOOM 3 BFG Edition") -ProbeExe "Doom3BFGVR.exe" -GogNames @("DOOM 3 BFG Edition","Doom 3 BFG") }
if ($gamePath) {
    Write-OK "DOOM 3 BFG Edition found: $gamePath"
} else {
    Write-Warn "DOOM 3 BFG Edition not found in Steam libraries automatically."
    Write-Host "  Please enter the game installation folder:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\DOOM 3 BFG Edition" -ForegroundColor Gray
    while (-not $gamePath) {
        $r=(Read-Host "  Path").Trim().Trim('"')
        if(Test-Path $r){$gamePath=$r; Write-OK "Path set: $gamePath"} else{Write-Fail "Not found: $r"}
    }
}

# STEP 2: Download and install
Write-Step 2 3 "Downloading Fully Possessed v0.021j"

$tempDir = Join-Path $env:TEMP "Doom3BFGVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$vrZip = Join-Path $tempDir "Doom3BFGVR.zip"

Write-Host "  Downloading (~350 MB, please wait) ... " -NoNewline -ForegroundColor White
$r = Invoke-DownloadOrFallback -Url $DOWNLOAD_URL -Destination $vrZip `
        -Label "Doom 3 BFG VR (Fully Possessed Alpha 021j)" `
        -ManualUrl "https://github.com/NPi2Loup/DOOM-3-BFG-VR/releases" `
        -Instructions "Download 'Doom3BFGVR_Fully_Possessed_Alpha021j.zip' from the GitHub releases page. Place it at '$vrZip' and choose Retry." `
        -SkipMessage "Skipped - Doom 3 BFG VR mod files not downloaded; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without the mod files. Press Enter to exit..."; exit 1 }

Write-Host "  Extracting into game folder ... " -NoNewline -ForegroundColor White
try {
    Expand-Archive -Path $vrZip -DestinationPath $gamePath -Force
    Write-Host "OK" -ForegroundColor Green
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Host "    $_" -ForegroundColor Gray
    Pause-User "Press Enter to exit."; exit 1
}

# Verify key files
$vrExePath = Join-Path $gamePath $VR_EXE
if (Test-Path $vrExePath) { Write-OK "$VR_EXE verified." }
else { Write-Warn "$VR_EXE not found - check $gamePath manually." }

$fpFolder = Join-Path $gamePath "Fully Possessed"
if (Test-Path $fpFolder) { Write-OK "'Fully Possessed' mod folder verified." }
else { Write-Warn "'Fully Possessed' folder not found - extraction may be incomplete." }

# Record the install path so the Hub flips this game to "VR Ready"
# right after the installer runs, even when the user never pressed
# Check Installed (the post-install single-game refresh reads this).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# STEP 3: Desktop shortcut
Write-Step 3 3 "Creating Desktop Shortcut"

try {
     $origExe = Join-Path $gamePath $GAME_EXE
     $shortcut = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Doom 3 BFG VR.lnk" -TargetPath $vrExePath -WorkingDir $gamePath -IconPath $(if (Test-Path $origExe) { "$origExe,0" } else { "$vrExePath,0" }) -Description "DOOM 3 BFG VR - Fully Possessed"
    Write-OK "Desktop shortcut 'Doom 3 BFG VR' created."
} catch {
    Write-Warn "Could not create shortcut: $_"
    Write-Info "Launch manually: $vrExePath"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Launch via the 'Doom 3 BFG VR' shortcut on your Desktop." -ForegroundColor White
Write-Host "  Do NOT launch via Steam - use Doom3BFGVR.exe directly!" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "--- Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Only DOOM 3 BFG Edition is supported (not Classic Doom 3)." -ForegroundColor White
Write-Host "  - Settings saved in: %UserProfile%\Saved Games\id Software\DOOM 3 BFG\Fully Possessed\" -ForegroundColor Gray
Write-Host "  - VR options: in-game menu, or edit vr_openvr.cfg / vr_oculus.cfg there." -ForegroundColor Gray
Write-Host "  - If body turn feels sluggish, add:  set vr_deadzoneYaw ""0""  to vr_openvr.cfg" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  The Mars facility breathes wrong. Trust your flashlight." -ForegroundColor Magenta
Write-Host ""
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
Pause-User "Press Enter to exit."

# ============================================================
#  Deep Rock Galactic - VRG VR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Deep Rock Galactic VRG Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME     = "Deep Rock Galactic"
$GAME_EXE      = "FSD.exe"
$STEAM_APP_ID  = "548430"

$CONFIG_ZIP_ID = "1wDEOfIzzERFYEKojBfTtBFjJa_i7UUBf"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "   Deep Rock Galactic - VRG VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   Rock and Stone in VR, Miner!" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Step {
    param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

function Get-SteamLibraries {
    param($steamPath)
    $libraries = @($steamPath)
    $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $vdfPath) {
        $content = Get-Content $vdfPath -Raw
        $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
        foreach ($m in $found) {
            $lib = $m.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $lib) { $libraries += $lib }
        }
    }
    return $libraries
}

function Find-GamePath {
    param($libraries)
    foreach ($lib in $libraries) {
        $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# -------------------------------------------------------
# STEP 1: Locate Deep Rock Galactic
# -------------------------------------------------------
Write-Header

Write-Host "  IMPORTANT: Before continuing, make sure you have completed the" -ForegroundColor Yellow
Write-Host "  tutorial cave in Deep Rock Galactic!" -ForegroundColor Yellow
Write-Host "  The VR mod will NOT work correctly without finishing the tutorial." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to confirm the tutorial is complete and continue..."

Write-Step 1 5 "Locating Deep Rock Galactic"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Deep Rock Galactic"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
if (-not $steamPath) {
    Write-Warn "Could not find Steam in registry. Please enter Steam path manually:"
    while (-not $steamPath) {
        $rawInput = (Read-Host "  Steam path").Trim().Trim('"')
        if (Test-Path $rawInput) { $steamPath = $rawInput; Write-OK "Steam path: $steamPath" }
        else { Write-Fail "Not found: $rawInput" }
    }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath  = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "548430" -SteamFolderNames @("Deep Rock Galactic") }

if (-not $gamePath) {
    Write-Warn "Deep Rock Galactic not found automatically."
    Write-Host "  Enter the folder containing FSD.exe:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Deep Rock Galactic" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path: $gamePath" }
        else { Write-Fail "Not found: $rawInput" }
    }
} else {
    Write-Info "Deep Rock Galactic found: $gamePath"
}

$fsdDir = Join-Path $gamePath "FSD"
if (Test-Path (Join-Path $gamePath $GAME_EXE)) { Write-Info "FSD.exe verified." }
else { Write-Warn "FSD.exe not found in game folder." }

# -------------------------------------------------------
# STEP 2: Backup Input.ini + Install Config.zip
# -------------------------------------------------------
Write-Step 2 5 "Installing VR Config files"

# Backup Input.ini
$inputIniPath = Join-Path $env:LOCALAPPDATA "..\..\AppData\Local\FSD\Saved\Config\WindowsNoEditor\Input.ini"
# Correct path pattern for DRG
$savedConfigDir = Join-Path $gamePath "FSD\Saved\Config\WindowsNoEditor"

# DRG stores config in AppData, not game folder
$appDataConfig = Join-Path $env:LOCALAPPDATA "FSD\Saved\Config\WindowsNoEditor"
if (-not (Test-Path $appDataConfig)) {
    # Try the game folder location
    $appDataConfig = $savedConfigDir
}

$inputIni = Join-Path $appDataConfig "Input.ini"
if (Test-Path $inputIni) {
    $backup = "$inputIni.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $inputIni $backup -Force
    Write-Info "Input.ini backed up to: $backup"
} else {
    Write-Info "Input.ini not found at $inputIni - will be created by game on first run."
}

# Download Config.zip from Google Drive
Write-Host "  Downloading Config.zip (VR controller bindings) ... " -NoNewline -ForegroundColor White
$tempDir  = Join-Path $env:TEMP "DRGVRGInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$configZip = Join-Path $tempDir "Config.zip"

$downloadOk = $false
try {
    # Google Drive large file download with confirm token
    $session   = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $cookie    = New-Object System.Net.Cookie
    $cookie.Name  = "download_warning_$CONFIG_ZIP_ID"
    $cookie.Value = "t"
    $cookie.Domain = ".google.com"
    $session.Cookies.Add($cookie)

    $dlUrls = @(
      "https://drive.usercontent.google.com/download?id=$CONFIG_ZIP_ID&export=download&authuser=0&confirm=t",
      "https://drive.google.com/uc?id=$CONFIG_ZIP_ID&export=download&confirm=t"
    )
    foreach ($dlUrl in $dlUrls) {
        try {
            Invoke-WebRequest -Uri $dlUrl -OutFile $configZip -WebSession $session -UseBasicParsing -ErrorAction Stop
            if ((Test-Path $configZip) -and ((Get-Item $configZip).Length -gt 1000)) {
                Write-Host "OK" -ForegroundColor Green
                $downloadOk = $true
                break
            }
        } catch {
            Write-Host "  source failed - trying next..." -ForegroundColor Yellow
        }
    }
    if (-not $downloadOk) {
        Write-Host "FAILED (all sources)" -ForegroundColor Red
    }
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Host "    $_" -ForegroundColor Gray
}

if ($downloadOk) {
    # Extract Config.zip into FSD\ folder (creates Config\ subfolder next to Binaries, Content etc)
    $fsdTarget = $fsdDir
    if (-not (Test-Path $fsdTarget)) {
        New-Item -ItemType Directory -Path $fsdTarget -Force | Out-Null
    }
    $efb = Expand-ArchiveOrFallback -ArchivePath $configZip -DestinationFolder $fsdTarget -Label "DRG Config.zip" `
            -SkipMessage "Skipped - Config was not extracted; VR may not function correctly."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        Write-Info "Config.zip extracted to FSD\"
    }

    $configFolder = Join-Path $fsdDir "Config"
    if (Test-Path $configFolder) {
        Write-Info "Config folder present: $configFolder"
    } else {
        Write-Warn "Config folder not found after extraction - check manually."
    }
} else {
    Write-Host ""
    Write-Warn "Automatic download failed. Manual download required:"
    Write-Host "  1. Open this URL in your browser:" -ForegroundColor White
    Write-Host "     https://drive.google.com/file/d/$CONFIG_ZIP_ID/view" -ForegroundColor Yellow
    Write-Host "  2. Download Config.zip" -ForegroundColor White
    Write-Host "  3. Extract it into: $fsdDir" -ForegroundColor White
    Write-Host "     (You should see a Config folder next to Binaries, Content, etc.)" -ForegroundColor Gray
    Write-Host ""
    Start-Process "https://drive.google.com/file/d/$CONFIG_ZIP_ID/view"
    Pause-User "Press Enter once you have extracted Config.zip into $fsdDir ..."
}

# -------------------------------------------------------
# STEP 3: Set Steam Launch Options
# -------------------------------------------------------
Write-Step 3 5 "Steam Launch Options"

$launchOptions = "-overridenohmd -dx11"

try { Set-Clipboard -Value $launchOptions } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Steam Launch Options" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  (-overridenohmd -dx11  |  DX12 causes jittering in VR)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
Write-Host "  Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Steam Launch Options..."

Start-Process "steam://gameproperties/$STEAM_APP_ID"
try { Set-Clipboard -Value $launchOptions } catch {}

Pause-User "Press Enter once you have pasted the launch options and closed Properties..."

# -------------------------------------------------------
# STEP 4: Subscribe to VRG on mod.io
# -------------------------------------------------------
Write-Step 4 5 "Subscribe to VRG on mod.io"

Write-Host "  The VRG mod is installed via the in-game mod.io integration." -ForegroundColor White
Write-Host "  You need to subscribe to it on mod.io first." -ForegroundColor White
Write-Host ""
Write-Host "  Steps:" -ForegroundColor White
Write-Host "    1. Log in to mod.io with your Steam account (if not already done)" -ForegroundColor Gray
Write-Host "    2. Click Subscribe on the VRG mod page that will open now" -ForegroundColor Gray
Write-Host "    3. After subscribing, come back here" -ForegroundColor Gray
Write-Host ""

Pause-User "Press Enter to open the VRG mod page on mod.io..."

Start-Process "https://mod.io/g/drg/m/vrg"
Pause-User "Press Enter once you have subscribed to VRG on mod.io..."

Write-Host "  Next: in-game steps to enable the mod." -ForegroundColor White
Write-Host ""
Write-Host "  1. Launch Deep Rock Galactic (without VR for now)" -ForegroundColor Gray
Write-Host "  2. Go to the Modding menu (gear icon in Space Rig)" -ForegroundColor Gray
Write-Host "  3. Log in to mod.io with your Steam account if prompted" -ForegroundColor Gray
Write-Host "  4. Find VRG in your subscribed mods (may show as Outdated)" -ForegroundColor Gray
Write-Host "  5. IMPORTANT: uncheck 'Disable Outdated Mods' in the mod menu" -ForegroundColor Yellow
Write-Host "  6. Click 'Active' next to VRG to enable it" -ForegroundColor Yellow
Write-Host "  7. Close the game" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter once VRG is Active and 'Disable Outdated Mods' is unchecked..."

# -------------------------------------------------------
# STEP 5: Final instructions
# -------------------------------------------------------
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Step 5 5 "First Launch Instructions"

Write-Host "  VRG requires two launches to fully initialize." -ForegroundColor White
Write-Host ""
Write-Host "  LAUNCH 1 (binding setup):" -ForegroundColor Cyan
Write-Host "    - Put on your headset" -ForegroundColor White
Write-Host "    - Launch Deep Rock Galactic via Steam" -ForegroundColor White
Write-Host "    - Ignore the Steam warning 'DRG does not support VR' - click OK" -ForegroundColor White
Write-Host "    - Press a controller button to get past the 'press button' screen" -ForegroundColor White
Write-Host "      (Oculus Link/Air Link users: press a keyboard key instead)" -ForegroundColor Gray
Write-Host "    - The game installs VR bindings on this first run" -ForegroundColor White
Write-Host "    - Once in the Space Rig, close the game" -ForegroundColor White
Write-Host ""
Write-Host "  LAUNCH 2 (fully working VR):" -ForegroundColor Cyan
Write-Host "    - Put on your headset and launch again" -ForegroundColor White
Write-Host "    - You will automatically enter VR when your dwarf spawns in the Space Rig" -ForegroundColor White
Write-Host "    - Motion controls and all features are now active" -ForegroundColor White
Write-Host ""

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Setup Complete - Quick Reference" -ForegroundColor White
Write-Host ""
Write-Host "    Launch options set : -overridenohmd -dx11" -ForegroundColor Green
Write-Host "    Config.zip         : installed to FSD\" -ForegroundColor Green
Write-Host "    VRG mod            : subscribed via mod.io (install in-game)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Basic VR Controls ---" -ForegroundColor Cyan
Write-Host "  Holsters: 2 leg, 1 torso, 2 shoulder (grab to equip weapon)" -ForegroundColor Gray
Write-Host "  Right stick press: VR settings menu / recenter height" -ForegroundColor Gray
Write-Host "  Right B: mine  |  Right A: jump  |  Left B: use/reload" -ForegroundColor Gray
Write-Host "  Toggle VR on/off: hold right stick 2 sec (Space Rig only)" -ForegroundColor Gray
Write-Host ""
Write-Host "--- Performance Tips ---" -ForegroundColor Cyan
Write-Host "  Set Shadows, Post-Processing and Effects to Low" -ForegroundColor Gray
Write-Host "  Optional: install VRPerfKit for extra performance boost" -ForegroundColor Gray
Write-Host "    https://github.com/fholger/vrperfkit" -ForegroundColor Gray
Write-Host ""
Write-Host "  Rock and Stone, Miner!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Deep Rock Galactic folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

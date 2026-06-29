# ============================================================
#  Subnautica: Below Zero - SubmersedVR BZ Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Subnautica Below Zero VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME    = "SubnauticaZero"
$GAME_EXE     = "SubnauticaZero.exe"
$STEAM_APP_ID = "848450"

$BEPINEX_URL  = "https://github.com/jbusfield/SubmersedVR_BZ/releases/download/v0.8.0/Tobey.s.BepInEx.Pack.for.Subnautica.zip"
$SVRBZ_URL    = "https://github.com/jbusfield/SubmersedVR_BZ/releases/download/v0.8.0/SubmersedVR_BZ_0.8.0.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Subnautica: Below Zero - SubmersedVR BZ Installer" -ForegroundColor Cyan
    Write-Host "   BepInEx for Subnautica  +  SubmersedVR BZ 0.8.0" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
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
# STEP 1: Pre-flight checks
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Pre-Flight Checks"

Write-Host "  Please confirm the following before continuing:" -ForegroundColor White
Write-Host ""
Write-Host "  [1] Subnautica: Below Zero is on the DEFAULT Steam branch." -ForegroundColor White
Write-Host "      (Not legacy or experimental.)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] No other Below Zero VR mods are installed." -ForegroundColor White
Write-Host "      They are not compatible with SubmersedVR BZ." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to confirm and continue..."

# -------------------------------------------------------
# STEP 2: Locate Subnautica: Below Zero
# -------------------------------------------------------
Write-Step 2 4 "Locating Subnautica: Below Zero"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Subnautica: Below Zero"
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
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "848450" -SteamFolderNames @("SubnauticaZero") -GogNames @("Subnautica Zero") -EpicNames @("SubnauticaBelowZero","Subnautica Below Zero","Subnautica Zero") }

if (-not $gamePath) {
    Write-Warn "Subnautica: Below Zero not found automatically."
    Write-Host "  Enter the folder containing SubnauticaZero.exe:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\SubnauticaZero" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path: $gamePath" }
        else { Write-Fail "Not found: $rawInput" }
    }
} else {
    Write-OK "Subnautica: Below Zero found: $gamePath"
}

if (Test-Path (Join-Path $gamePath $GAME_EXE)) { Write-OK "SubnauticaZero.exe verified." }
else { Write-Warn "SubnauticaZero.exe not found - folder may still be correct." }

# -------------------------------------------------------
# STEP 3: Install BepInEx + SubmersedVR BZ
# -------------------------------------------------------
Write-Step 3 4 "Installing BepInEx + SubmersedVR BZ 0.8.0"

$tempDir = Join-Path $env:TEMP "SubmersedVRBZInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed = @()

# --- BepInEx for Subnautica (same pack works for BZ) ---
$bepZip     = Join-Path $tempDir "BepInEx.zip"
$bepExtract = Join-Path $tempDir "BepInEx"
$r = Invoke-DownloadOrFallback -Url $BEPINEX_URL -Destination $bepZip `
        -Label "Tobey's BepInEx Pack for Subnautica BZ" `
        -ManualUrl "https://github.com/jbusfield/SubmersedVR_BZ/releases/tag/v0.8.0" `
        -Instructions "Download 'Tobey.s.BepInEx.Pack.for.Subnautica.zip' from the GitHub releases page. Place it at '$bepZip' and choose Retry." `
        -SkipMessage "Skipped - BepInEx pack missing; the VR mod will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "BepInEx" }

if (Test-Path $bepZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $bepExtract -Label "BepInEx pack" `
            -SkipMessage "Skipped - BepInEx was not extracted; VR mod will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            Get-ChildItem -Path $bepExtract | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            if (Test-Path (Join-Path $gamePath "winhttp.dll"))   { Write-OK "winhttp.dll verified." }
            else { Write-Warn "winhttp.dll not found." }
            if (Test-Path (Join-Path $gamePath "BepInEx\core")) { Write-OK "BepInEx\core verified." }
            else { Write-Warn "BepInEx\core not found." }
            Write-OK "BepInEx installed!"
        } catch {
            Write-Host "FAILED to install BepInEx: $_" -ForegroundColor Red
            $failed += "BepInEx"
        }
    } else {
        $failed += "BepInEx"
    }
}

# --- SubmersedVR BZ ---
$svrZip     = Join-Path $tempDir "SubmersedVR_BZ.zip"
$svrExtract = Join-Path $tempDir "SubmersedVR_BZ"
$r = Invoke-DownloadOrFallback -Url $SVRBZ_URL -Destination $svrZip `
        -Label "SubmersedVR BZ v0.8.0" `
        -ManualUrl "https://github.com/jbusfield/SubmersedVR_BZ/releases/tag/v0.8.0" `
        -Instructions "Download 'SubmersedVR_BZ_0.8.0.zip' from the GitHub releases page. Place it at '$svrZip' and choose Retry." `
        -SkipMessage "Skipped - SubmersedVR BZ mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "SubmersedVR BZ" }

if (Test-Path $svrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $svrZip -DestinationFolder $svrExtract -Label "SubmersedVR BZ" `
            -SkipMessage "Skipped - SubmersedVR BZ was not extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            Get-ChildItem -Path $svrExtract | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            $checks = @(
                "BepInEx\plugins\SubmersedVR.dll",
                "BepInEx\patchers\GlobalGameManagerVRPatcher\GlobalGameManagerVRPatcher.dll",
                "BepInEx\patchers\GlobalGameManagerVRPatcher\VRPatcher.dll",
                "SubnauticaZero_Data\Managed\SteamVR.dll",
                "SubnauticaZero_Data\StreamingAssets\SteamVR\actions.json",
                "SubnauticaZero_Data\StreamingAssets\SteamVR\bindings_oculus_touch.json",
                "SubnauticaZero_Data\StreamingAssets\amplify_resources",
                "VRMODE.txt"
            )
            $allVerified = $true
            foreach ($check in $checks) {
                $fullPath = Join-Path $gamePath $check
                if (Test-Path $fullPath) { Write-OK $check }
                else { Write-Warn "Missing: $check"; $allVerified = $false }
            }
            if ($allVerified) { Write-OK "SubmersedVR BZ 0.8.0 fully installed!" }
            else {
                Write-Warn "Some files are missing - controllers or VR may not work correctly."
                Write-Warn "Do NOT use mod managers like Vortex - they can skip required files."
            }
        } catch {
            Write-Host "FAILED to install SubmersedVR BZ: $_" -ForegroundColor Red
            $failed += "SubmersedVR BZ"
        }
    } else {
        $failed += "SubmersedVR BZ"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 4: Launch Options (Oculus/AirLink users)
# -------------------------------------------------------
Write-Step 4 4 "Launch Options"

Write-Host "  SubmersedVR BZ uses SteamVR (OpenVR). Oculus Runtime is NOT supported." -ForegroundColor White
Write-Host ""
Write-Host "  Are you using an Oculus headset (Rift, Quest via Link/AirLink)?" -ForegroundColor White
Write-Host "  If YES: add  -vrmode openvr  to Steam Launch Options" -ForegroundColor Yellow
Write-Host "          and start SteamVR MANUALLY before launching the game." -ForegroundColor Yellow
Write-Host "  If NO:  no extra launch options needed." -ForegroundColor Gray
Write-Host "          (Virtual Desktop works fine without extra options.)" -ForegroundColor Gray
Write-Host ""

$answer = Read-Host "  Are you using an Oculus headset? (y/n)"
if ($answer -match "^[yYjJ]") {
    $launchOpt = "-vrmode openvr"
    try { Set-Clipboard -Value $launchOpt } catch {}

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host "   ACTION REQUIRED - Steam Launch Option" -ForegroundColor Yellow
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  (-vrmode openvr)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
    Write-Host "  Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
    Write-Host ""
    Pause-User "Press Enter to open the game properties in Steam..."
    Start-Process "steam://gameproperties/$STEAM_APP_ID"
    try { Set-Clipboard -Value $launchOpt } catch {}
    Pause-User "Press Enter once you have pasted -vrmode openvr and closed Properties..."
} else {
    Write-OK "No extra launch option needed for your headset."
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("SubmersedVR BZ" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
if ("BepInEx"        -notin $failed) { Write-Host "    [x] BepInEx for Subnautica" -ForegroundColor Green   } else { Write-Host "    [ ] BepInEx            -- FAILED" -ForegroundColor Red }
if ("SubmersedVR BZ" -notin $failed) { Write-Host "    [x] SubmersedVR BZ 0.8.0" -ForegroundColor Green     } else { Write-Host "    [ ] SubmersedVR BZ 0.8.0 -- FAILED" -ForegroundColor Red }
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "--- How to Play ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Start SteamVR first." -ForegroundColor White
Write-Host "  2. Launch Subnautica: Below Zero via Steam." -ForegroundColor White
Write-Host "     (Oculus users: start SteamVR FIRST, then launch from Steam)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Issues: https://github.com/jbusfield/SubmersedVR_BZ/issues" -ForegroundColor Gray
Write-Host ""
Write-Host "  Stay warm out there, and watch out for the Shadow Leviathan!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Subnautica: Below Zero folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

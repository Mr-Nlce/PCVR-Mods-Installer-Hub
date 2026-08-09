# ============================================================
#  Subnautica - SubmersedVR Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Subnautica VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME    = "Subnautica"
$GAME_EXE     = "Subnautica.exe"
$STEAM_APP_ID = "264710"

$BEPINEX_URL  = "https://github.com/toebeann/BepInEx.Subnautica/releases/latest/download/Tobey.s.BepInEx.Pack.for.Subnautica.zip"
$SVRVR_URL    = "https://github.com/Okabintaro/SubmersedVR/releases/download/0.2.0/SubmersedVR_0.2.0.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Subnautica - SubmersedVR Installer" -ForegroundColor Cyan
    Write-Host "   BepInEx for Subnautica  +  SubmersedVR 0.2.0" -ForegroundColor Gray
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
Write-Host " SubmersedVR by Okabintaro modernizes Subnautica's VR support, adding" -ForegroundColor White
Write-Host " full motion controls and a proper in-VR HUD." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Pre-Flight Checks"

Write-Host "  Before installing, please confirm the following:" -ForegroundColor White
Write-Host ""
Write-Host "  [1] Subnautica is on the default Steam branch" -ForegroundColor White
Write-Host "      (NOT legacy or experimental - those are not supported)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] You do NOT have these mods installed:" -ForegroundColor White
Write-Host "      - Subnautica VR Enhancements Mod" -ForegroundColor Yellow
Write-Host "      - Motion Controls Mod (SN1MC)" -ForegroundColor Yellow
Write-Host "      These conflict with SubmersedVR!" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm and continue..."

# -------------------------------------------------------
# STEP 2: Locate Subnautica
# -------------------------------------------------------
Write-Step 2 4 "Locating Subnautica"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Subnautica"
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
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "264710" -SteamFolderNames @("Subnautica") -EpicNames @("Subnautica") }

if (-not $gamePath) {
    Write-Warn "Subnautica not found automatically."
    Write-Host "  Enter the folder containing Subnautica.exe:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Subnautica" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path: $gamePath" }
        else { Write-Fail "Not found: $rawInput" }
    }
} else {
    Write-OK "Subnautica found: $gamePath"
}

if (Test-Path (Join-Path $gamePath $GAME_EXE)) { Write-OK "Subnautica.exe verified." }
else { Write-Warn "Subnautica.exe not found - folder may still be correct." }

# Check for conflicting mods
$conflictPaths = @(
    (Join-Path $gamePath "BepInEx\plugins\SubnauticaVREnhancements.dll"),
    (Join-Path $gamePath "BepInEx\plugins\SN1MC.dll"),
    (Join-Path $gamePath "QMods\SubnauticaVREnhancements"),
    (Join-Path $gamePath "QMods\SN1MC")
)
foreach ($conflict in $conflictPaths) {
    if (Test-Path $conflict) {
        Write-Warn "Conflicting mod found: $conflict"
        Write-Warn "Please remove it before continuing!"
    }
}

# -------------------------------------------------------
# STEP 3: Install BepInEx + SubmersedVR
# -------------------------------------------------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gamePath -ModFile "BepInEx\plugins\SubmersedVR.dll"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile "BepInEx\plugins\SubmersedVR.dll" -Label "SubmersedVR"
Write-Step 3 4 "Installing BepInEx + SubmersedVR 0.2.0"

$tempDir = Join-Path $env:TEMP "SubmersedVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed = @()

# --- BepInEx for Subnautica ---
$bepZip     = Join-Path $tempDir "BepInEx.zip"
$bepExtract = Join-Path $tempDir "BepInEx"
$r = Invoke-DownloadOrFallback -Url $BEPINEX_URL -Destination $bepZip `
        -Label "Tobey's BepInEx Pack for Subnautica (latest)" `
        -ManualUrl "https://github.com/toebeann/BepInEx.Subnautica/releases/latest" `
        -Instructions "Download 'Tobey.s.BepInEx.Pack.for.Subnautica.zip' from the latest GitHub release. Place it at '$bepZip' and choose Retry." `
        -SkipMessage "Skipped - BepInEx pack missing; the VR mod will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "BepInEx" }

if (Test-Path $bepZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $bepExtract -Label "BepInEx pack" `
            -SkipMessage "Skipped - BepInEx was not extracted; VR mod will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            # Payload-verified (BepInEx pack is pulled from releases/LATEST,
            # so its layout can change any day).
            $bepPayload = Get-ExtractedPayloadRoot -ExtractDir $bepExtract -RelModFile "winhttp.dll" -Markers @("BepInEx")
            Get-ChildItem -Path $bepPayload | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            if (Test-Path -LiteralPath "$gamePath\winhttp.dll")    { Write-OK "winhttp.dll verified." }
            else { Write-Warn "winhttp.dll not found." }
            if (Test-Path -LiteralPath "$gamePath\BepInEx\core")   { Write-OK "BepInEx\core verified." }
            else { Write-Warn "BepInEx\core not found." }
            Write-OK "BepInEx for Subnautica installed!"
        } catch {
            Write-Host "FAILED to install BepInEx: $_" -ForegroundColor Red
            $failed += "BepInEx"
        }
    } else {
        $failed += "BepInEx"
    }
}

# --- SubmersedVR ---
$svrZip     = Join-Path $tempDir "SubmersedVR.zip"
$svrExtract = Join-Path $tempDir "SubmersedVR"
$r = Invoke-DownloadOrFallback -Url $SVRVR_URL -Destination $svrZip `
        -Label "SubmersedVR v0.2.0" `
        -ManualUrl "https://github.com/Okabintaro/SubmersedVR/releases/tag/0.2.0" `
        -Instructions "Download 'SubmersedVR_0.2.0.zip' from the GitHub releases page. Place it at '$svrZip' and choose Retry." `
        -SkipMessage "Skipped - SubmersedVR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "SubmersedVR" }

if (Test-Path $svrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $svrZip -DestinationFolder $svrExtract -Label "SubmersedVR" `
            -SkipMessage "Skipped - SubmersedVR was not extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            Get-ChildItem -Path $svrExtract | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            $checks = @(
                "BepInEx\plugins\SubmersedVR.dll",
                "Subnautica_Data\Managed\SteamVR.dll",
                "Subnautica_Data\StreamingAssets\SteamVR\actions.json",
                "Subnautica_Data\StreamingAssets\SteamVR\bindings_oculus_touch.json",
                "Subnautica_Data\StreamingAssets\amplify_resources"
            )
            $allVerified = $true
            foreach ($check in $checks) {
                $fullPath = Join-Path $gamePath $check
                if (Test-Path $fullPath) { Write-OK $check }
                else { Write-Warn "Missing: $check"; $allVerified = $false }
            }
            if ($allVerified) { Write-OK "SubmersedVR 0.2.0 fully installed!" }
            else {
                Write-Warn "Some files are missing. Controllers may not function correctly."
                Write-Warn "Do NOT use mod managers like Vortex - they can skip required files."
            }
        } catch {
            Write-Host "FAILED to install SubmersedVR: $_" -ForegroundColor Red
            $failed += "SubmersedVR"
        }
    } else {
        $failed += "SubmersedVR"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 4: Launch Options (Oculus users)
# -------------------------------------------------------
Write-Step 4 4 "Launch Options"

Write-Host "  SubmersedVR requires SteamVR (OpenVR). Oculus Runtime is NOT supported." -ForegroundColor White
Write-Host ""
Write-Host "  Are you using an Oculus headset (Rift, Quest via Link/AirLink)?" -ForegroundColor White
Write-Host "  If YES: you need to add  -vrmode openvr  to Steam Launch Options." -ForegroundColor Yellow
Write-Host "          and start SteamVR MANUALLY before launching Subnautica." -ForegroundColor Yellow
Write-Host "  If NO:  no extra launch options needed - just start SteamVR normally." -ForegroundColor Gray
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
if ("SubmersedVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
if ("BepInEx"     -notin $failed) { Write-Host "    [x] BepInEx for Subnautica" -ForegroundColor Green } else { Write-Host "    [ ] BepInEx         -- FAILED" -ForegroundColor Red }
if ("SubmersedVR" -notin $failed) { Write-Host "    [x] SubmersedVR 0.2.0" -ForegroundColor Green      } else { Write-Host "    [ ] SubmersedVR 0.2.0 -- FAILED" -ForegroundColor Red }
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
Write-Host "  1. Start SteamVR." -ForegroundColor White
Write-Host "  2. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or via Steam." -ForegroundColor White
Write-Host "     (Oculus users: start SteamVR FIRST, then launch from Steam)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Issues: https://github.com/Okabintaro/SubmersedVR/issues" -ForegroundColor Gray
Write-Host ""
Write-Host "  Dive safe, and watch out for the Leviathans!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Subnautica folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

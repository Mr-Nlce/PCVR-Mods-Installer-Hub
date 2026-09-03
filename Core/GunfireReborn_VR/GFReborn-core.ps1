# ============================================================
#  Gunfire Reborn - VR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Gunfire Reborn VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$DEPOT_APPID    = "1217060"
$DEPOT_DEPOTID  = "1217061"
$DEPOT_MANIFEST = "969403333909649972"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Final stable install location - completely separate from the
# retail Gunfire Reborn so Steam updates can't overwrite it. The
# game launches via a desktop shortcut, not via Steam.
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME    = "Gunfire Reborn VR"
$DEFAULT_PATH   = Join-PathLexical $DEFAULT_PARENT $TARGET_NAME
$GAME_EXE       = "Gunfire Reborn.exe"

$VRMOD_URL    = "https://github.com/Astienth/gunfire-reborn-bhaptics/releases/download/1.0.0/GunfireRebornVR.V1.0.9.1.zip"
$BHAPTICS_URL = "https://github.com/Astienth/gunfire-reborn-bhaptics/releases/download/1.0.0/GunfireRebornBhapticsMod_1.0.4.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host "   Gunfire Reborn - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   VRMod v1.0.9.1 + bHaptics 1.0.4" -ForegroundColor Gray
    Write-Host "=============================================" -ForegroundColor Magenta
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
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
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
            if (Test-LiteralPathSafe -Path $lib -PathType Container) { $libraries += $lib }
        }
    }
    return $libraries
}

# -------------------------------------------------------
# STEP 1: Steam Depot Download
# -------------------------------------------------------
Write-Header
Write-Host " GunfireRebornVR by Astienth (based on PureDark's port) - full VR with" -ForegroundColor White
Write-Host " motion controls for the roguelite FPS Gunfire Reborn." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Steam Depot Download"

Write-Host "  Here's what's about to happen:" -ForegroundColor Cyan
Write-Host "    1) The Steam Console will open automatically" -ForegroundColor White
Write-Host "    2) The download command is already copied to your clipboard" -ForegroundColor White
Write-Host "    3) Paste with Ctrl+V into the Steam Console and hit Enter" -ForegroundColor Yellow
Write-Host "    4) Wait for Steam to finish, then come back here" -ForegroundColor White
Write-Host ""
Write-Host "  When Steam finishes it will show:" -ForegroundColor Gray
Write-Host "    Depot download complete : ...\depot_1217061" -ForegroundColor Yellow
Write-Host ""

try {
    Set-Clipboard -Value $DEPOT_COMMAND
    Write-OK "Download command copied to clipboard!"
} catch {
    Write-Warn "Could not copy to clipboard. Command to paste manually:"
    Write-Host "    $DEPOT_COMMAND" -ForegroundColor Yellow
}

Write-Host "  In Steam Console: CLICK THE INPUT FIELD AND USE CTRL+V TO PASTE" -ForegroundColor Yellow
Write-Host ""

Write-Host ""
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
    Write-Host "  (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
    Write-Host "      automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
    Write-Host "      doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
    Write-Host "      then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
    Write-Host "      next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
    Write-Host ""
}
# !!! LOOK BEFORE ASKING. Steam keeps a finished depot in
# steamapps\content, so a second run - or a run after a crash - already
# has the files. Prompting first and probing only afterwards sends the
# user to fetch gigabytes that are already on disk. Find-SteamDepotPath
# is cheap and touches nothing.
$script:PreFoundDepot = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE
if ($script:PreFoundDepot) {
    Write-OK "The depot is already downloaded: $script:PreFoundDepot"
    Write-Info "Skipping the download - nothing to fetch again."
}
if (-not $script:PreFoundDepot) {

Pause-User "Press Enter to open the Steam Console..."
# Both protocol addresses: depending on the Steam build only one works.
foreach ($cu in @("steam://open/console", "steam://nav/console")) {
    try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
}
}
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
# Auto-detect Steam path and depot path
# -------------------------------------------------------
Write-Host ""
$steamPath = Get-SteamPath

if (-not $steamPath) {
    Write-Warn "Could not find Steam installation in registry."
    Write-Host "  Please enter your Steam installation path manually:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam" -ForegroundColor Gray
    while (-not $steamPath) {
        $rawInput = (Read-Host "  Steam path").Trim().Trim('"')
        if (Test-Path $rawInput) {
            $steamPath = $rawInput
            Write-OK "Steam path set: $steamPath"
        } else {
            Write-Fail "Path not found: $rawInput"
        }
    }
}

$probePaths = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -AdditionalSteamRoots @($steamPath))
$depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamPath)
if ($depotPath) { Write-OK "Depot folder found automatically: $depotPath" }
else { Write-Warn "Depot folder not found in any Steam library." }

if (-not $depotPath) {
    $depotPath = Resolve-DepotPath -GameName "Gunfire Reborn" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 2: Move depot to stable folder
# -------------------------------------------------------
# The depot lives in steamapps\content\app_<id>\depot_<id> which
# Steam can overwrite during a future depot download. Move it to
# a completely separate location under C:\Games\ so the VR
# install survives Steam updates and stays separate from the
# retail Gunfire Reborn (which we leave entirely alone).
Write-Step 2 4 "Moving game to stable folder"

Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use default, or type a different full path").Trim().Trim('"')
if (-not $userInput) {
    $targetPath = $DEFAULT_PATH
} else {
    $targetPath = $userInput
}

$targetParent = Get-PathParentLexical $targetPath
if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) {
    Write-Fail "The target folder is not writable: $targetParent"
    Pause-User "Press Enter to exit..."; exit 1
}

if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Info "Merging the pinned build; saves, BepInEx configs/plugins and other additional files are preserved."
}

try {
    $parentOfDepot = Get-PathParentLexical $depotPath
    $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "Gunfire Reborn depot build"
    Write-OK "Game installed at: $targetPath"
    # Clean up empty app_<id> folder
    try {
        if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
            Remove-Item $parentOfDepot -Force
        }
    } catch {}
} catch {
    Write-Fail "Merge failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Pause-User "Press Enter to exit..."
    exit 1
}

$gamePath = $targetPath

# -------------------------------------------------------
# STEP 3: Download and install mods
# -------------------------------------------------------
Write-Step 3 4 "Installing Mods"

$tempDir = Join-Path $env:TEMP "GunfireVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$ignore = @("manifest.json","README.md","icon.png","CHANGELOG.md","changelog.txt")
$failed = @()

# --- VR Mod ---
$vrZip     = Join-Path $tempDir "VRMod.zip"
$vrExtract = Join-Path $tempDir "VRMod"
$r = Invoke-DownloadOrFallback -Url $VRMOD_URL -Destination $vrZip `
        -Label "Gunfire Reborn VR mod v1.0.9.1" `
        -ManualUrl "https://github.com/Astienth/gunfire-reborn-bhaptics/releases/tag/1.0.0" `
        -Instructions "Download 'GunfireRebornVR.V1.0.9.1.zip' from the GitHub releases page. Place it at '$vrZip' and choose Retry." `
        -SkipMessage "Skipped - VR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "VRMod" }

if (Test-Path $vrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $vrZip -DestinationFolder $vrExtract -Label "VRMod" `
            -SkipMessage "Skipped - VRMod was not extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            Get-ChildItem -Path $vrExtract | Where-Object { $_.Name -notin $ignore } | ForEach-Object {
                $target = Join-Path $gamePath $_.Name
                $keep = if ($_.Name -ieq "BepInEx") { @("config") } else { @() }
                $null = Merge-PathItemVerified -Source $_.FullName -Destination $target -Label "$($_.Name) VRMod files" `
                    -KeepExistingRelativePaths $keep
            }
            Write-OK "VRMod installed!"
        } catch {
            Write-Host "FAILED to copy VRMod files: $_" -ForegroundColor Red
            $failed += "VRMod"
        }
    } else {
        $failed += "VRMod"
    }
}

# --- bHaptics Mod ---
$bhZip     = Join-Path $tempDir "bHaptics.zip"
$bhExtract = Join-Path $tempDir "bHaptics"
$r = Invoke-DownloadOrFallback -Url $BHAPTICS_URL -Destination $bhZip `
        -Label "Gunfire Reborn bHaptics mod 1.0.4" `
        -ManualUrl "https://github.com/Astienth/gunfire-reborn-bhaptics/releases/tag/1.0.0" `
        -Instructions "Download 'GunfireRebornBhapticsMod_1.0.4.zip' from the GitHub releases page. Place it at '$bhZip' and choose Retry." `
        -SkipMessage "Skipped - bHaptics integration missing; VR still works without haptic feedback (low impact)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "bHaptics" }

if (Test-Path $bhZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $bhZip -DestinationFolder $bhExtract -Label "bHaptics" `
            -SkipMessage "Skipped - bHaptics was not extracted; haptic feedback unavailable."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            $pluginsPath = Join-Path $gamePath "BepInEx\plugins"
            if (-not (Test-Path $pluginsPath)) { New-Item -ItemType Directory -Path $pluginsPath | Out-Null }
            Get-ChildItem -Path $bhExtract | Where-Object { $_.Name -notin $ignore } | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $pluginsPath -Recurse -Force
            }
            Write-OK "bHaptics installed!"
        } catch {
            Write-Host "FAILED to copy bHaptics files: $_" -ForegroundColor Red
            $failed += "bHaptics"
        }
    } else {
        $failed += "bHaptics"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# Drop a steam_appid.txt so the VR build can talk to Steam
# (achievements, friends, etc.) without needing a manifest.
try { Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Desktop shortcut for the VR build - this is how the user will
# launch the game from now on. Steam will still launch the
# retail flat version if used directly.
$vrExePath = Join-Path $gamePath $GAME_EXE
if (Test-Path $vrExePath) {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
         $sc = New-DesktopShortcut -LnkPath (Join-Path $desktopPath "Gunfire Reborn VR.lnk") -TargetPath $vrExePath -WorkingDir $gamePath -IconPath "$vrExePath,0" -Arguments "-vrmode OpenVR" -Description "Gunfire Reborn (VR Version)"
        Write-OK "Desktop shortcut created: Gunfire Reborn VR"
    } catch {
        Write-Warn "Could not create shortcut: $_"
    }
}

# -------------------------------------------------------
# STEP 4: Done - guided finish
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

Write-Host "  Installed:" -ForegroundColor White
if ("VRMod"    -notin $failed) { Write-Host "    [x] VRMod v1.0.9.1" -ForegroundColor Green    } else { Write-Host "    [ ] VRMod v1.0.9.1  -- FAILED, install manually" -ForegroundColor Red }
if ("bHaptics" -notin $failed) { Write-Host "    [x] bHaptics Mod 1.0.4" -ForegroundColor Green } else { Write-Host "    [ ] bHaptics Mod 1.0.4  -- FAILED, install manually" -ForegroundColor Red }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  Important notes:" -ForegroundColor White
Write-Host ""
Write-Host "  - Game installed at: $gamePath" -ForegroundColor Gray
Write-Host ""
Write-Host "  - Launch with" -NoNewline -ForegroundColor Yellow; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor Yellow
Write-Host "    'Gunfire Reborn VR' desktop" -ForegroundColor Yellow
Write-Host "    shortcut, NOT via Steam!" -ForegroundColor Yellow
Write-Host "    (Steam would launch your retail flat copy)" -ForegroundColor Gray
Write-Host ""
Write-Host "  - First launch takes longer than usual." -ForegroundColor White
Write-Host "    BepInEx configures itself on first run." -ForegroundColor Gray
Write-Host ""
Write-Host "  - Bypass the DLC/Roadmap screen (press OK)" -ForegroundColor White
Write-Host "    before the game puts you into VR." -ForegroundColor Gray
Write-Host ""
Write-Host "  - Disable SteamVR Theatre Mode:" -ForegroundColor White
Write-Host "    SteamVR Settings -> Dashboard ->" -ForegroundColor Gray
Write-Host "    Present Non-VR Apps on Theater Screen -> OFF" -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""

try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

Write-Host ""
Write-Host "  Lock and load. The dungeons await in VR!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

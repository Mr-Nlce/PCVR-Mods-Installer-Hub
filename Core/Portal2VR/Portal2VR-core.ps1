# ============================================================
#  Portal 2 - Portal2VR Roomscale Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Portal 2 VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_APPID  = "620"
$GAME_NAME   = "Portal 2"
$GAME_EXE    = "portal2.exe"

# Spencer0187's roomscale fork - adds motion controls on top of Gistix's original
$PORTAL2VR_URL = "https://github.com/Spencer0187/portal2vr-roomscale/releases/download/V0.2.2/Simple_P2VR_install_v2_roomscale.zip"

# Launch parameters from the mod's included INSTRUCTIONS.txt
$LAUNCH_PARAMS = "-insecure -window -novid +mat_motion_blur_percent_of_screen_max 0 +mat_queue_mode 0 +mat_vsync 0 +mat_antialias 0 +mat_grain_scale_override 0 +snd_surround_speakers 5"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Portal 2 - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   Portal2VR Roomscale v0.2.2 by Spencer0187" -ForegroundColor Gray
    Write-Host "   (based on Portal2VR by Gistix)" -ForegroundColor DarkGray
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
# STEP 1: Clean install reminder
# -------------------------------------------------------
Write-Header
Write-Step 1 5 "Before You Start"

Write-Host "  This mod requires a CLEAN Portal 2 install:" -ForegroundColor White
Write-Host ""
Write-Host "    - Back up your save files if you want to keep them" -ForegroundColor Gray
Write-Host "    - Unsubscribe from any Steam Workshop mods" -ForegroundColor Gray
Write-Host "    - Launch Portal 2 once to the main menu, then quit" -ForegroundColor Gray
Write-Host ""
Write-Host "  This ensures the game is in a known good state before modding." -ForegroundColor White
Write-Host ""

Pause-User "Press Enter once Portal 2 is ready..."

# -------------------------------------------------------
# STEP 2: Locate Portal 2
# -------------------------------------------------------
Write-Step 2 5 "Locating Portal 2"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Portal 2"
    }
} catch {}
# --- End detection library attempt ---

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

$libraries = Get-SteamLibraries $steamPath
$gamePath  = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "620" -SteamFolderNames @("Portal 2") }

if (-not $gamePath) {
    Write-Warn "Portal 2 not found in Steam libraries automatically."
    Write-Host "  Please enter the Portal 2 installation folder path manually:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Portal 2" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Portal 2 path").Trim().Trim('"')
        if (Test-Path $rawInput) {
            $gamePath = $rawInput
            Write-OK "Portal 2 path set: $gamePath"
        } else {
            Write-Fail "Path not found: $rawInput"
        }
    }
} else {
    Write-OK "Portal 2 found: $gamePath"
}

$gameExe = Join-Path $gamePath $GAME_EXE
if (Test-Path $gameExe) {
    Write-OK "Game executable found: $GAME_EXE"
} else {
    Write-Warn "Could not find portal2.exe - folder may still be correct."
}

# -------------------------------------------------------
# STEP 3: Download and install Portal2VR Roomscale
# -------------------------------------------------------
Write-Step 3 5 "Installing Portal2VR Roomscale v0.2.2"

$tempDir = Join-Path $env:TEMP "Portal2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed  = @()

$vrZip     = Join-Path $tempDir "Portal2VR.zip"
$vrExtract = Join-Path $tempDir "Portal2VR"
$r = Invoke-DownloadOrFallback -Url $PORTAL2VR_URL -Destination $vrZip `
        -Label "Portal 2 VR Roomscale v0.2.2" `
        -ManualUrl "https://github.com/Spencer0187/portal2vr-roomscale/releases/tag/V0.2.2" `
        -Instructions "Download 'Simple_P2VR_install_v2_roomscale.zip' from the GitHub releases page. Place it at '$vrZip' and choose Retry." `
        -SkipMessage "Skipped - Portal 2 VR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "Portal2VR" }

if (Test-Path $vrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $vrZip -DestinationFolder $vrExtract -Label "Portal 2 VR" `
            -SkipMessage "Skipped - Portal 2 VR mod was NOT extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            # ZIP layout:
            #   Simple_P2VR_install_v2_roomscale/
            #       CREDITS.txt / INSTRUCTIONS.txt
            #       P2VR_install/          <-- the CONTENTS of this folder go into Portal 2\
            #           dsound.dll, bin\, portal2\, VR\, ...
            # Find P2VR_install recursively, then copy its children to the game folder.
            $payload = Get-ChildItem -Path $vrExtract -Directory -Recurse |
                       Where-Object { $_.Name -eq "P2VR_install" } |
                       Select-Object -First 1
            if (-not $payload) {
                throw "P2VR_install folder not found inside the downloaded archive."
            }

            Write-Host "  Copying VR mod files into game folder ... " -NoNewline -ForegroundColor White
            Get-ChildItem -Path $payload.FullName -Force | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            Write-Host "OK" -ForegroundColor Green
            Write-OK "Portal2VR Roomscale v0.2.2 installed!"
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Fail "Install error: $_"
            Write-Info "You can download manually from:"
            Write-Info "  https://github.com/Spencer0187/portal2vr-roomscale/releases"
            $failed += "Portal2VR"
        }
    } else {
        $failed += "Portal2VR"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 4: Steam launch parameters
# -------------------------------------------------------
Write-Step 4 5 "Steam Launch Parameters"

try { Set-Clipboard -Value $LAUNCH_PARAMS } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Steam Launch Parameters" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  (Also disable Steam Overlay in the General tab.)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
Write-Host "  Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Steam game properties..."
Start-Process "steam://gameproperties/$GAME_APPID"
Pause-User "Press Enter once you have pasted the launch parameters and closed Steam properties..."

# -------------------------------------------------------
# Manual fallback: create a visible shortcut/relay to the
# UpdateSoundCache.cmd in case the user needs it later (e.g.
# after a game update). The auto-run step below is the primary
# path - this just guarantees the manual button is also there.
# -------------------------------------------------------
$soundCacheSrc = Join-Path $gamePath "portal2_dlc3\UpdateSoundCache.cmd"
$soundFixLink  = Join-Path $gamePath "Fix-Sound-issue-VR.lnk"
$linkCreated   = $false
if (Test-Path $soundCacheSrc) {
    try {
        $wsh = New-Object -ComObject WScript.Shell
        $lnk = $wsh.CreateShortcut($soundFixLink)
        $lnk.TargetPath       = $soundCacheSrc
        $lnk.WorkingDirectory = (Split-Path -Parent $soundCacheSrc)
        $lnk.Description      = "Run this if Portal 2 VR has no sound after a game update."
        $lnk.Save()
        $linkCreated = $true
    } catch {
        # COM / permission issue - fall back to a tiny relay .cmd
        try {
            $relay = Join-Path $gamePath "Fix-Sound-issue-VR.cmd"
@"
@echo off
rem Runs the Portal2VR sound cache updater from portal2_dlc3 with the
rem correct working directory, then waits so you can see the result.
pushd "%~dp0portal2_dlc3"
call UpdateSoundCache.cmd
popd
echo.
echo Sound cache updated. You can close this window.
pause
"@ | Set-Content -Path $relay -Encoding ASCII
            $linkCreated = $true
            $soundFixLink = $relay
        } catch {}
    }
}

# -------------------------------------------------------
# STEP 5: Sound Cache Fix
#   Portal 2 VR has no sound on first launch until
#   UpdateSoundCache.cmd runs. The cmd needs the game to have
#   been started at least once so the maps\soundcache directory
#   exists. Reaching the main menu is enough - the user does
#   not need to load a level. We do this in-installer so it's
#   not a footer note that gets missed.
# -------------------------------------------------------
Write-Step 5 5 "Sound Cache Fix"

if (-not (Test-Path $soundCacheSrc)) {
    Write-Warn "UpdateSoundCache.cmd not found at expected location."
    Write-Warn "  Expected: $soundCacheSrc"
    Write-Warn "  Skipping auto-fix. If the game has no sound, run the"
    Write-Warn "  cmd manually from the portal2_dlc3 folder."
} else {
    Write-Host "  Portal 2 VR ships without a sound cache for the modded" -ForegroundColor White
    Write-Host "  configuration. The game must build it before VR audio works -" -ForegroundColor White
    Write-Host "  but the VR mod blocks Portal 2 from reaching the main menu." -ForegroundColor White
    Write-Host "  So the installer temporarily disables VR (renames bin\openvr_api.dll)," -ForegroundColor White
    Write-Host "  you build the cache in flat mode, then it re-enables VR for you." -ForegroundColor White
    Write-Host "  Nothing to rename or switch yourself." -ForegroundColor White
    Write-Host ""

    $openvrDll      = Join-Path $gamePath "bin\openvr_api.dll"
    $openvrDisabled = "$openvrDll-"
    $vrWasDisabled  = $false

    Write-Host "  [5a] Disabling VR temporarily ... " -NoNewline -ForegroundColor White
    if (Test-Path $openvrDll) {
        try {
            if (Test-Path $openvrDisabled) { Remove-Item -LiteralPath $openvrDisabled -Force -ErrorAction Stop }
            Rename-Item -LiteralPath $openvrDll -NewName (Split-Path -Leaf $openvrDisabled) -Force -ErrorAction Stop
            $vrWasDisabled = $true
            Write-Host "OK" -ForegroundColor Green
            Write-OK "Renamed bin\openvr_api.dll -> openvr_api.dll- (VR off, flat mode)."
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Warn "Could not rename bin\openvr_api.dll: $_"
            Write-Warn "  Add a '-' to the end of bin\openvr_api.dll yourself before launching,"
            Write-Warn "  otherwise the game starts in VR and won't reach the menu."
            Pause-User "Press Enter once bin\openvr_api.dll is renamed (VR off)..."
        }
    } elseif (Test-Path $openvrDisabled) {
        $vrWasDisabled = $true
        Write-Host "already off" -ForegroundColor Green
    } else {
        Write-Host "SKIPPED" -ForegroundColor Yellow
        Write-Warn "bin\openvr_api.dll not found. If Portal 2 won't reach the menu,"
        Write-Warn "  disable the VR mod manually before continuing."
    }

    Write-Host ""
    Write-Host "  [5b] Build the sound cache   " -ForegroundColor Cyan -NoNewline
    Write-Host "let Portal 2 reach the MAIN MENU, then quit the game" -ForegroundColor Yellow
    Write-Host "       Flat mode now - no SteamVR needed. The menu must fully load." -ForegroundColor DarkGray
    Pause-User "Press Enter to launch Portal 2 via Steam..."
    try { Start-Process "steam://rungameid/$GAME_APPID" } catch { Write-Warn "Could not launch via Steam - start Portal 2 from your library." }
    Write-Host ""
    Pause-User "Press Enter ONLY after Portal 2 reached the main menu and was closed..."

    Write-Host ""
    Write-Host "  [5c] Rebuilding sound cache ... " -NoNewline -ForegroundColor White

    # Sanity check that the game has actually been launched -
    # without a maps\soundcache directory the cmd has nothing
    # to work with and will error out unhelpfully. If missing,
    # tell the user to retry the launch step rather than just
    # printing a cryptic error from the cmd.
    $soundcacheDir = Join-Path $gamePath "portal2_dlc3\maps\soundcache"
    if (-not (Test-Path $soundcacheDir)) {
        $soundcacheDir = Join-Path $gamePath "portal2\maps\soundcache"
    }
    if (-not (Test-Path $soundcacheDir)) {
        Write-Host "SKIPPED" -ForegroundColor Yellow
        Write-Warn "It looks like Portal 2 hasn't been launched yet (no soundcache"
        Write-Warn "  folder found). You can finish this step later by running"
        Write-Warn "  '$([System.IO.Path]::GetFileName($soundFixLink))' from the"
        Write-Warn "  Portal 2 folder after starting and quitting the game once."
    } else {
        # Run the cmd with the correct working directory. Capture
        # output and exit code so we can report success cleanly.
        # Sound cache builds can take 30-60 seconds on slower disks.
        try {
            $proc = Start-Process -FilePath "cmd.exe" `
                -ArgumentList "/c", "UpdateSoundCache.cmd" `
                -WorkingDirectory (Split-Path -Parent $soundCacheSrc) `
                -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                Write-Host "OK" -ForegroundColor Green
                Write-OK "Sound cache rebuilt. VR audio should now work on next launch."
            } else {
                Write-Host "FAILED" -ForegroundColor Red
                Write-Warn "UpdateSoundCache.cmd returned exit code $($proc.ExitCode)."
                Write-Warn "  Try running '$([System.IO.Path]::GetFileName($soundFixLink))'"
                Write-Warn "  manually from the Portal 2 folder."
            }
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Warn "Could not run UpdateSoundCache.cmd: $_"
            Write-Warn "  Try running '$([System.IO.Path]::GetFileName($soundFixLink))'"
            Write-Warn "  manually from the Portal 2 folder."
        }
    }

    Write-Host ""
    Write-Host "  [5d] Re-enabling VR ... " -NoNewline -ForegroundColor White
    if ($vrWasDisabled -and (Test-Path $openvrDisabled)) {
        try {
            if (Test-Path $openvrDll) { Remove-Item -LiteralPath $openvrDll -Force -ErrorAction Stop }
            Rename-Item -LiteralPath $openvrDisabled -NewName (Split-Path -Leaf $openvrDll) -Force -ErrorAction Stop
            Write-Host "OK" -ForegroundColor Green
            Write-OK "Restored bin\openvr_api.dll (VR on). Portal 2 launches in VR again."
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Warn "Could not restore bin\openvr_api.dll: $_"
            Write-Warn "  Rename 'openvr_api.dll-' back to 'openvr_api.dll' in the bin folder"
            Write-Warn "  yourself, otherwise VR will not start."
            Pause-User "Press Enter once bin\openvr_api.dll is restored (VR on)..."
        }
    } else {
        Write-Host "skipped" -ForegroundColor Gray
        Write-Host "       (VR was not auto-disabled - nothing to restore)" -ForegroundColor DarkGray
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("Portal2VR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
if ("Portal2VR" -notin $failed) {
    Write-Host "  [x] Portal2VR Roomscale v0.2.2 installed" -ForegroundColor Green
} else {
    Write-Host "  [ ] Portal2VR Roomscale v0.2.2  -- FAILED, install manually" -ForegroundColor Red
}
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- First Launch ---" -ForegroundColor Cyan
Write-Host "  Start SteamVR BEFORE launching Portal 2." -ForegroundColor White
Write-Host "  Launch the game from inside SteamVR." -ForegroundColor White

Write-Host ""
Write-Host "--- Mod Settings (optional) ---" -ForegroundColor Cyan
Write-Host "  Edit <Portal 2>\VR\config.txt for mod settings." -ForegroundColor Gray
Write-Host "  Motion-sick from portal rotation? In config.txt change:" -ForegroundColor Gray
Write-Host "    CameraUprightRecoverySpeed=0.04 -> 100" -ForegroundColor Gray
Write-Host "  Play flat for a while without uninstalling:" -ForegroundColor Gray
Write-Host "    rename <Portal 2>\bin\openvr_api.dll - add a '-' to turn VR off," -ForegroundColor Gray
Write-Host "    remove the '-' to turn VR back on." -ForegroundColor Gray

Write-Host ""
Write-Host "  Calibrate height in-game:" -ForegroundColor Yellow
Write-Host "  Press LEFT STICK DOWN (click) to recenter, or your head" -ForegroundColor White
Write-Host "  may be stuck at the ceiling." -ForegroundColor White

Write-Host ""
Write-Host "  If audio breaks again later (e.g. after a Portal 2 update):" -ForegroundColor Gray
Write-Host "  Run 'Fix-Sound-issue-VR' from the Portal 2 folder to rebuild the cache." -ForegroundColor Gray

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host "  In SteamVR menu -> VR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "  The cake is a lie. The VR is real." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Portal 2 folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

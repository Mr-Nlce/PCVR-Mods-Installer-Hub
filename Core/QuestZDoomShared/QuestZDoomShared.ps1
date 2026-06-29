# ============================================================
#  Doom-family VR - Shared GZDoomVR Engine Installer Library
# ============================================================
#  Used by DoomVR, Doom2VR, HereticVR, HexenVR, StrifeVR.
#  Each game-specific installer dot-sources this file and then
#  calls Install-QuestZDoomGame (kept as the entry-point name
#  for compatibility) with its own WAD name + Steam folders +
#  launcher label.
#
#  Engine: hh79's GZDoomVR. Has working laser-pointer aim out
#  of the box. The shared engine extracts to the install root;
#  subsequent installs detect it's already there and skip
#  straight to the WAD copy + launcher creation.
# ============================================================

$ErrorActionPreference = "Stop"

# Engine download. Direct asset URL on hh79's GitHub release.
$QZD_ENGINE_URL = "https://github.com/hh79/gzdoomvr/releases/download/gvr4.13.2.2/gzdoomvr-4-13-2-2.zip"
$QZD_ENGINE_VER = "4.13.2.2"
$QZD_INSTALL_ROOT_NAME = "GZDoomVR"

# Directory of this shared library (captured when a wrapper dot-sources
# it). Used to write the per-title .installed_path_<safeTitle> marker the
# Hub's post-install VR-Ready refresh reads back.
$QZD_SHARED_DIR = $PSScriptRoot

function Write-Header { param($Title)
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   $Title" -ForegroundColor Cyan
    Write-Host "   GZDoomVR v$QZD_ENGINE_VER (PC VR fork by hh79)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($x="Press Enter to continue...") Write-Host ""; Write-Host "  $x" -ForegroundColor White; Read-Host "  " }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }
    return $null
}
function Get-SteamLibraries {
    param($sp); $libs=@($sp)
    $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $c = Get-Content $vdf -Raw
        [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object {
            $l=$_.Groups[1].Value -replace '\\\\','\'
            if (Test-Path $l) { $libs+=$l }
        }
    }
    return $libs
}

# Search Steam libraries for any of the supplied folder names.
# Each game has multiple possible install names because of the
# 2024 KEX re-releases (e.g. "Ultimate Doom" vs "DOOM" + "Doom 2"
# vs "DOOM II"). Returns the first match or $null.
function Find-SteamGameFolder {
    param([string[]]$FolderNames)
    $sp = Get-SteamPath
    if (-not $sp) { return $null }
    foreach ($lib in (Get-SteamLibraries $sp)) {
        foreach ($name in $FolderNames) {
            $candidate = Join-Path $lib "steamapps\common\$name"
            if (Test-Path $candidate) { return $candidate }
        }
    }
    return $null
}

# Look for the WAD inside a Steam game folder. Tries the root
# of the folder, then a series of subfolders known to hold the
# original-engine WADs in various Steam re-releases (DOOM+DOOM II
# 2024 KEX uses \base\, Heretic + Hexen 2025 KEX uses similar
# nested locations). Final fallback is a recursive scan in case
# Steam moves things in a future re-release.
function Find-WadInGameFolder {
    param([string]$GameFolder, [string]$WadName)
    $candidates = @(
        (Join-Path $GameFolder $WadName),
        (Join-Path $GameFolder "base\$WadName"),
        (Join-Path $GameFolder "base\doom\$WadName"),
        (Join-Path $GameFolder "base\doom2\$WadName"),
        (Join-Path $GameFolder "base\heretic\$WadName"),
        (Join-Path $GameFolder "base\hexen\$WadName"),
        (Join-Path $GameFolder "base\classic\$WadName"),
        (Join-Path $GameFolder "rerelease\base\$WadName"),
        (Join-Path $GameFolder "classicwads\$WadName"),
        (Join-Path $GameFolder "wads\$WadName")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    # Fallback: recursive scan, max depth 4, catches anything we
    # didn't anticipate (KEX re-releases love nested subfolders).
    try {
        $found = Get-ChildItem -Path $GameFolder -Filter $WadName -Recurse -Depth 4 -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        if ($found) { return $found.FullName }
    } catch {}
    return $null
}

function Test-EngineInstalled {
    param([string]$InstallRoot)
    # GZDoomVR ships gzdoomvr.exe at the root and openvr_api.dll
    # alongside it. Both being present means the engine was
    # extracted successfully.
    $exe = Join-Path $InstallRoot "gzdoomvr.exe"
    $dll = Join-Path $InstallRoot "openvr_api.dll"
    return ((Test-Path $exe) -and (Test-Path $dll))
}

function Install-Engine {
    param([string]$InstallRoot)
    Write-Info "Engine not yet installed - downloading from GitHub..."

    $tempDir = Join-Path $env:TEMP "QZDInstall_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $zipPath = Join-Path $tempDir "gzdoomvr-engine.zip"

    Write-Host "  Downloading ~30 MB ... " -NoNewline -ForegroundColor White
    $r = Invoke-DownloadOrFallback -Url $QZD_ENGINE_URL -Destination $zipPath `
            -Label "GZDoomVR engine 4.13.2.2" `
            -ManualUrl "https://github.com/hh79/gzdoomvr/releases/tag/gvr4.13.2.2" `
            -Instructions "Download 'gzdoomvr-4-13-2-2.zip' from the GitHub releases page. Place it at '$zipPath' and choose Retry." `
            -SkipMessage "Skipped - GZDoomVR engine missing; the VR mod will NOT run (questionable result)."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if (-not ($r -is [bool] -and $r)) {
        Pause-User "Install cannot continue without the GZDoomVR engine. Press Enter to exit..."
        exit 1
    }

    Write-Host "  Install path: $InstallRoot" -ForegroundColor DarkGray
    Write-Host "  Extracting engine ... " -NoNewline -ForegroundColor White
    try {
        # Make sure InstallRoot exists. Don't blow away an existing
        # one - a previous run may have left files we want to keep
        # (wads/, per-game .bats from sibling installers). The
        # Copy-Item -Force below merges over what's already there.
        if (-not (Test-Path $InstallRoot)) {
            New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
        }
        $extractTemp = Join-Path $tempDir "extract"
        $efb = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $extractTemp -Label "GZDoomVR engine" `
                -SkipMessage "Skipped - GZDoomVR engine was not extracted; the VR mod will NOT run."
        if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        if ([string]$efb -ne "ok" -and [string]$efb -ne "manual") {
            Pause-User "Engine extraction skipped. Install cannot continue. Press Enter to exit..."
            exit 1
        }

        # GZDoomVR's ZIP usually extracts files directly to the
        # root (gzdoomvr.exe at the top). Detect both: if it's at
        # extractTemp, use that as the payload root. Otherwise look
        # one level deeper.
        $payload = $extractTemp
        if (-not (Test-Path (Join-Path $payload "gzdoomvr.exe"))) {
            $rootChild = Get-ChildItem -Path $extractTemp -Directory |
                         Where-Object { Test-Path (Join-Path $_.FullName "gzdoomvr.exe") } |
                         Select-Object -First 1
            if ($rootChild) { $payload = $rootChild.FullName }
        }
        Get-ChildItem -Path $payload | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $InstallRoot -Recurse -Force
        }

        # Portable mode: GZDoom's config code looks for
        # gzdoom_portable.ini next to the executable. If found,
        # config + savegames stay local instead of going to
        # Documents\My Games\<name>. QuestZDoom is a GZDoom fork
        # so it honors the same marker. Keeps each Hub install
        # self-contained.
        $portableIni = Join-Path $InstallRoot "gzdoom_portable.ini"
        if (-not (Test-Path $portableIni)) {
            New-Item -ItemType File -Path $portableIni -Force | Out-Null
        }

        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Fail "Extraction failed: $_"
        Write-Host "  Tip: if the path above sits in Program Files or another" -ForegroundColor Yellow
        Write-Host "  protected location, try running this installer as admin," -ForegroundColor Yellow
        Write-Host "  or report this so we can adjust the install path." -ForegroundColor Yellow
        Pause-User "Press Enter to exit..."
        exit 1
    } finally {
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }

    # Make sure the wads/ folder exists - it doesn't ship in the
    # ZIP and the engine won't auto-create it.
    $wadsDir = Join-Path $InstallRoot "wads"
    if (-not (Test-Path $wadsDir)) { New-Item -ItemType Directory -Path $wadsDir | Out-Null }
    Write-Info "Engine installed: $InstallRoot"
}

# ------------------------------------------------------------
#  Public entry point.
#
#  Parameters:
#    -GameTitle       e.g. "Doom VR" - shown in headers + shortcut
#    -WadName         e.g. "DOOM.WAD" - the IWAD file we copy
#    -SteamFolders    array, e.g. @("Ultimate Doom", "DOOM") - all
#                     Steam folder names to search for the WAD
#    -BatLabel        e.g. "Start Doom VR.bat" - filename of the
#                     per-game launcher we drop next to gzdoomvr.exe
# ------------------------------------------------------------
function Install-QuestZDoomGame {
    param(
        [Parameter(Mandatory=$true)][string]$GameTitle,
        [Parameter(Mandatory=$true)][string]$WadName,
        [Parameter(Mandatory=$true)][string[]]$SteamFolders,
        [Parameter(Mandatory=$true)][string]$BatLabel,
        # Per-game closing one-liner (e.g. "Rip and tear, until it
        # is done." for Doom). Each game's wrapper script passes
        # its own. Empty string suppresses the line.
        [string]$Flavor = ""
    )

    Write-Header "$GameTitle Installer"

    # Decide install location. We need a writable, per-user spot
    # that survives Steam reinstalls and doesn't require admin.
    # Steam's parent is usually "Program Files (x86)" which fails
    # with "Access denied" without elevation - that was the source
    # of the original bug. AppData\Local\GZDoomVR is the right
    # call: per-user, no UAC prompt, persistent across game updates.
    $localAppData  = [Environment]::GetFolderPath("LocalApplicationData")
    $installRoot   = Join-Path $localAppData $QZD_INSTALL_ROOT_NAME

    # ---- STEP 1: Locate IWAD ----
    Write-Step 1 4 "Locating $WadName"

    $sourceWad = $null
    $gameFolder = Find-SteamGameFolder -FolderNames $SteamFolders
    if ($gameFolder) {
        $sourceWad = Find-WadInGameFolder -GameFolder $gameFolder -WadName $WadName
        if ($sourceWad) {
            Write-Info "Found via Steam: $sourceWad"
        } else {
            Write-Warn "Steam folder found at $gameFolder but $WadName is missing."
        }
    }

    if (-not $sourceWad) {
        Write-Warn "$WadName not found automatically."
        Write-Host "  Enter the full path to your $WadName file:" -ForegroundColor White
        Write-Host "  Steam:   ...steamapps\common\<game>\base\$WadName" -ForegroundColor Gray
        Write-Host "  GOG:     ...GOG Games\<game>\$WadName" -ForegroundColor Gray
        Write-Host "  Or skip if you don't have the WAD - the engine will" -ForegroundColor Gray
        Write-Host "  install but the game won't be playable until you" -ForegroundColor Gray
        Write-Host "  drop a $WadName into the wads\ folder yourself." -ForegroundColor Gray
        Write-Host ""
        $r = (Read-Host "  Path (or empty to skip)").Trim().Trim('"')
        if ($r -and (Test-Path $r)) { $sourceWad = $r; Write-Info "Path set: $sourceWad" }
    }

    # ---- STEP 2: Engine ----
    Write-Step 2 4 "GZDoomVR Engine"

    if (Test-EngineInstalled -InstallRoot $installRoot) {
        Write-Info "Engine already present at $installRoot - reusing."
    } else {
        Install-Engine -InstallRoot $installRoot
    }

    # ---- STEP 3: WAD ----
    Write-Step 3 4 "Installing $WadName"

    $wadsDir = Join-Path $installRoot "wads"
    if (-not (Test-Path $wadsDir)) { New-Item -ItemType Directory -Path $wadsDir | Out-Null }

    if ($sourceWad) {
        $destWad = Join-Path $wadsDir $WadName
        Write-Host "  Copying $WadName ... " -NoNewline -ForegroundColor White
        try {
            Copy-Item -Path $sourceWad -Destination $destWad -Force
            Write-Host "OK" -ForegroundColor Green
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Fail "Copy failed: $_"
        }
    } else {
        Write-Warn "$WadName was not located - skipping copy."
        Write-Host "  Drop the file into: $wadsDir" -ForegroundColor Yellow
    }

    # ---- STEP 4: Launcher ----
    Write-Step 4 4 "Creating launcher"

    # The laser-sight PK3 ships at the root of the engine zip
    # (verified by inspecting gzdoomvr-4-13-2-2.zip - no mods\
    # subfolder exists in the archive) and gzdoomvr autoloads
    # it. Earlier code added an explicit download + -file flag
    # which made the engine load the mod twice and crash with
    # "cvar 'm8f_wm_ShowLaserSight' already exists". So: no
    # explicit -file for laser-sight here.

    # Per-game launcher .bat. We set:
    #   -iwad <wad>    which game data to load (ZDoom Wiki + Doom Wiki:
    #                  standard parameter across all Doom engines)
    #   +vr_mode 10    OpenVR / SteamVR / Quest via Link (verified:
    #                  ZDoom Forum original post by cmbruns, ModDB
    #                  gz3doom page lists vr_mode as the CVAR)
    #
    # The engine ZIP ships laser-sight.pk3 at the install root and
    # gzdoomvr autoloads it - we deliberately do NOT pass -file for
    # it here. Adding a second -file copy made the engine load the
    # mod twice and crash with "cvar 'm8f_wm_ShowLaserSight' already
    # exists" the moment any map loaded.
    #
    # gzdoom_portable.ini next to the exe activates portable mode
    # (created during engine install) so config + saves stay local.
    #
    # The .bat exists as a manual fallback for users who want to
    # tweak args or invoke from a terminal. The desktop shortcut
    # below points directly at gzdoomvr.exe instead, so that:
    #   - The shortcut icon is the real game icon (Windows ignores
    #     IconLocation when the target is a .bat).
    #   - There's no brief cmd.exe console flash on launch.
    #   - Right-click + properties shows clear arguments.
    $batPath = Join-Path $installRoot $BatLabel
    $iwadRel = "wads\$WadName"
    $sharedArgs = "-iwad `"$iwadRel`" +vr_mode 10"

    $batLines = @(
        '@echo off'
        'cd /d "%~dp0"'
        'gzdoomvr.exe ^'
        "  -iwad `"$iwadRel`" ^"
        '  +vr_mode 10'
    )
    Set-Content -Path $batPath -Value $batLines -Encoding ASCII
    Write-Info "Launcher (fallback): $batPath"

    # Record install path for the post-install VR-Ready refresh. Keyed by
    # title (.installed_path_<safeTitle>) because every GZDoomVR game shares
    # this installer folder - matches Get-InstalledPathFile's multi-game rule.
    if ($QZD_SHARED_DIR) {
        try {
            $__safeTitle = ($GameTitle -replace '[^A-Za-z0-9]', '_')
            Set-Content -Path (Join-Path $QZD_SHARED_DIR ".installed_path_$__safeTitle") -Value $installRoot -Encoding UTF8 -Force
        } catch {}
    }

    # Desktop shortcut points directly at gzdoomvr.exe with the
    # right arguments. This gives a real exe icon, no console
    # flash, and -iwad wired in so we land in the right game
    # without going through the engine's IWAD picker.
    try {
        $shell    = New-Object -ComObject WScript.Shell
        $lnkName  = ($GameTitle -replace '[\\/:*?"<>|]', '_') + ".lnk"
        $lnkPath  = Join-Path ([Environment]::GetFolderPath("Desktop")) $lnkName
        $shortcut = $shell.CreateShortcut($lnkPath)
        $shortcut.TargetPath       = (Join-Path $installRoot "gzdoomvr.exe")
        $shortcut.Arguments        = $sharedArgs
        $shortcut.WorkingDirectory = $installRoot
        $shortcut.Description      = "$GameTitle (GZDoomVR PC VR)"
        $shortcut.IconLocation     = (Join-Path $installRoot "gzdoomvr.exe") + ",0"
        $shortcut.Save()
        Write-Info "Desktop shortcut '$GameTitle' created."
    } catch {
        Write-Warn "Could not create shortcut: $_"
    }

    # ---- Summary ----
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Installation Summary" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "    [x] GZDoomVR v$QZD_ENGINE_VER" -ForegroundColor Green
    if ($sourceWad) {
        Write-Host "    [x] $WadName installed" -ForegroundColor Green
    } else {
        Write-Host "    [ ] $WadName missing - drop it into wads\ to play" -ForegroundColor Yellow
    }
    Write-Host "    [x] Launcher: $BatLabel" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Start SteamVR BEFORE launching the game." -ForegroundColor White
    Write-Host "  2. Launch via the desktop shortcut (or $BatLabel)." -ForegroundColor White
    Write-Host "  3. SteamVR -> Settings -> Dashboard: Theatre Mode OFF." -ForegroundColor White
    Write-Host ""
    Write-Host "  Quest Touch / Index controller defaults:" -ForegroundColor Cyan
    Write-Host "    Right trigger      Fire" -ForegroundColor Gray
    Write-Host "    Right grip         Hold for secondary actions" -ForegroundColor Gray
    Write-Host "    Right A            Open door / use switch" -ForegroundColor Gray
    Write-Host "    Right B            Jump" -ForegroundColor Gray
    Write-Host "    Right A + grip     Main menu" -ForegroundColor Gray
    Write-Host "    Left X (A)         Item use" -ForegroundColor Gray
    Write-Host "    Left Y (B)         Toggle automap" -ForegroundColor Gray
    Write-Host "    Left grip          Run" -ForegroundColor Gray
    Write-Host "    Left thumbstick    Move" -ForegroundColor Gray
    Write-Host "    Right thumbstick   Snap turn" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  If the world looks doubled / off-axis on first launch:" -ForegroundColor Yellow
    Write-Host "    Press the Oculus / Meta button on your Quest controller" -ForegroundColor White
    Write-Host "    to recenter the view. (This is a SteamVR / Quest" -ForegroundColor White
    Write-Host "    runtime function - not the game itself.)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Handedness, snap-turn angle, and bindings can all be" -ForegroundColor Gray
    Write-Host "  changed in-game: Options -> VR Options." -ForegroundColor Gray
    Write-Host ""
    if ($Flavor) {
        Write-Host "  $Flavor" -ForegroundColor Magenta
        Write-Host ""
    }
    Pause-User "Press Enter to exit."
    try { Start-Process explorer.exe "`"$installRoot`"" } catch {}
}

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
# Optional 3D-weapons mod (iAmErmac's Universal_Doom_3DWeapons_VR). ONE
# universal .pk3 that FILTER/s per IWAD, so it fits Doom, Doom 2, Heretic,
# Hexen and Strife. Stored in a mods\ subfolder (NOT the engine root, so
# gzdoomvr does not autoload it globally) and wired per-game via -file.
$QZD_WEAPONS_URL  = "https://github.com/iAmErmac/Universal_Doom_3DWeapons_VR/releases/download/v1.0.0/HDVRweapons_Plus_v1.0.pk3"
$QZD_WEAPONS_FILE = "HDVRweapons_Plus_v1.0.pk3"
# Optional "items 3D" pack (Doom / Doom 2 ONLY) - the old QuestZDoom MEGA pack.
# Its bundled 3D WEAPONS and MONSTERS do NOT hook into this gzdoomvr fork's VR
# system (2020-era build), so ONLY the loose item models render in 3D. Offered
# with an honest "(covers some items in 3D)" label. Hosted on MEGA (no direct
# link), so it's a manual drag-and-drop of the zip. Loaded via -file AFTER the
# modern weapon pack, so it never overrides the working VR hand weapons.
$QZD_FULLPACK_URL   = "https://mega.nz/#!TOpgkKbL!MJshOqaPWtVLU4YjwN1RITiJeXByJBgNERf7cYpt_rg"
$QZD_FULLPACK_ZIP   = "GZDOOM.MonstersAndWeapons.For.OpenVRDoom.zip"
$QZD_FULLPACK_ITEMS = "Item_3DModels.pk3"
# HD texture pack (Doom Neural Upscale 2x, ModDB) - Doom / Doom 2 ONLY, a
# SEPARATE opt-in stacked on top of the weapons/full-pack choice. Manual zip
# (ModDB red "Download Now"); the zip carries a junk __MACOSX copy we skip.
$QZD_HDTEX_URL  = "https://www.moddb.com/downloads/doom-neural-upscale-2x"
$QZD_HDTEX_ZIP  = "NeuralUpscale2x_v1.0.pk3.zip"
$QZD_HDTEX_FILE = "NeuralUpscale2x_v1.0.pk3"

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
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
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
    param([string[]]$FolderNames, [string]$WadName = "")
    # Build the list of roots to scan: every Steam library's common\ folder,
    # plus GOG (C/D/E:\GOG Games) and Xbox (C/D/E:\XboxGames) roots. Xbox nests
    # the game under a \Content subfolder, so each name is tried both bare and
    # with \Content appended.
    $roots = New-Object System.Collections.Generic.List[string]
    $sp = Get-SteamPath
    if ($sp) { foreach ($lib in (Get-SteamLibraries $sp)) { [void]$roots.Add((Join-Path $lib "steamapps\common")) } }
    foreach ($d in @("C","D","E")) {
        [void]$roots.Add("${d}:\GOG Games")
        [void]$roots.Add("${d}:\XboxGames")
    }
    $firstExisting = $null
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($name in $FolderNames) {
            foreach ($sub in @("", "\Content")) {
                $candidate = Join-Path $root ($name + $sub)
                if (Test-Path $candidate) {
                    if (-not $firstExisting) { $firstExisting = $candidate }
                    # Prefer a folder that ACTUALLY holds the WAD - avoids a
                    # competing/empty "Heretic" beating the real "Heretic + Hexen".
                    if ($WadName -and (Find-WadInGameFolder -GameFolder $candidate -WadName $WadName)) {
                        return $candidate
                    }
                    if (-not $WadName) { return $candidate }
                }
            }
        }
    }
    return $firstExisting
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
        [string]$Flavor = "",
        # Optional per-game .ico (filename, shipped next to this shared
        # script). Copied into the install root and used as the shortcut
        # icon; falls back to the gzdoomvr.exe icon.
        [string]$IconFile = ""
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
    $gameFolder = Find-SteamGameFolder -FolderNames $SteamFolders -WadName $WadName
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
    # ---- Optional: 3D content ----
    # Weapons-only (auto, universal HDVR pk3) for every game. Doom / Doom 2 can
    # ALSO add the loose-item 3D models on top. The old MEGA pack's 3D monsters
    # and 3D weapons do NOT work with this gzdoomvr fork, so only its item
    # models are used - loaded AFTER the working weapon pack so nothing clashes.
    $weaponsArg = ""
    $modsDir = Join-Path $installRoot "mods"
    $isDoom = ($GameTitle -match '^Doom')
    Write-Host ""
    if ($isDoom) {
        Write-Host "  >>> OPTIONAL 3D CONTENT - your choice:" -ForegroundColor Yellow
        Write-Host "      [W] 3D weapons only                     (auto download)" -ForegroundColor Cyan
        Write-Host "      [I] 3D weapons + items                  (drag and drop)" -ForegroundColor Cyan
        Write-Host "          (covers some items in 3D - monsters stay 2D)" -ForegroundColor Gray
        Write-Host "      [N] None" -ForegroundColor Cyan
        $c3d = (Read-Host "  >>> Choose W / I / N").Trim().ToLower()
        if ($c3d -ne "w" -and $c3d -ne "i") { $c3d = "n" }
    } else {
        Write-Host "  >>> OPTIONAL: 3D WEAPONS - swaps the flat weapon sprites for" -ForegroundColor Yellow
        Write-Host "      3D models (adapts to $GameTitle via the mod's filter)." -ForegroundColor Yellow
        $ans = (Read-Host "  >>> Install the 3D weapons mod for $GameTitle? (Y/N)").Trim()
        $c3d = if ($ans -match '^(y|yes|j|ja)$') { "w" } else { "n" }
    }

    if ($c3d -eq "w" -or $c3d -eq "i") {
        try { New-Item -ItemType Directory -Path $modsDir -Force -EA SilentlyContinue | Out-Null } catch {}
        $wpk3 = Join-Path $modsDir $QZD_WEAPONS_FILE
        if (-not (Test-Path $wpk3)) {
            Invoke-SafeDownload -Urls @($QZD_WEAPONS_URL) -Destination $wpk3 `
                -Label "3D weapons mod" `
                -ManualUrl "https://github.com/iAmErmac/Universal_Doom_3DWeapons_VR/releases/latest" `
                -SkipMessage "Skipped - 3D weapons not installed; the game runs with its default weapon sprites." | Out-Null
        } else {
            Write-Info "3D weapons mod already downloaded - reusing it."
        }
        if (Test-Path $wpk3) {
            $weaponsArg = " -file `"mods\$QZD_WEAPONS_FILE`""
            Write-OK "3D weapons enabled for $GameTitle."
        }
    }

    # Doom-only: add the loose-item 3D models on top of the weapons.
    if ($c3d -eq "i") {
        $itemPk3 = Join-Path $modsDir $QZD_FULLPACK_ITEMS
        if (-not (Test-Path $itemPk3)) {
            Write-Host ""
            Write-Host "  MANUAL STEP - the 3D item models live on MEGA:" -ForegroundColor Yellow
            Write-Host "    1. Press Enter to open the MEGA download page." -ForegroundColor Yellow
            Write-Host "    2. Download '$QZD_FULLPACK_ZIP'." -ForegroundColor Yellow
            Write-Host "    3. DRAG the downloaded .zip onto THIS window, then press Enter." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "  >>> Press Enter to open the download page" | Out-Null
            try { Start-Process $QZD_FULLPACK_URL } catch {}
            Write-Host ""
            $zin = (Read-Host "  Drop the .zip here (or Enter to skip)").Trim().Trim('"')
            if ($zin -and (Test-Path -LiteralPath $zin)) {
                $tmpEx = Join-Path $installRoot "_pack_tmp"
                try {
                    if (Test-Path $tmpEx) { Remove-Item $tmpEx -Recurse -Force -EA SilentlyContinue }
                    Expand-ArchiveOrFallback -ArchivePath $zin -DestinationFolder $tmpEx -Label "3D item models" `
                        -SkipMessage "Skipped - the 3D item models were not extracted." | Out-Null
                    $__src = Get-ChildItem -Path $tmpEx -Filter $QZD_FULLPACK_ITEMS -Recurse -EA SilentlyContinue | Select-Object -First 1
                    if ($__src) { Copy-Item -LiteralPath $__src.FullName -Destination $itemPk3 -Force }
                    Remove-Item $tmpEx -Recurse -Force -EA SilentlyContinue
                } catch { Write-Warn "Could not unpack the item models: $_" }
            } else {
                Write-Info "Skipped the 3D item models."
            }
        } else {
            Write-Info "3D item models already installed - reusing them."
        }
        # Append items AFTER the weapon pack so the working VR hand weapons win
        # on any shared definition. Items are pure model swaps, so no clash.
        if (Test-Path $itemPk3) {
            if ($weaponsArg) { $weaponsArg = $weaponsArg + " `"mods\$QZD_FULLPACK_ITEMS`"" }
            else             { $weaponsArg = " -file `"mods\$QZD_FULLPACK_ITEMS`"" }
            Write-OK "3D item models enabled for $GameTitle (some items in 3D; monsters stay 2D)."
        }
    }

    if ($c3d -eq "n") {
        Write-Info "Skipped 3D content - default sprites."
    }

    # ---- Optional (Doom 1/2 only): HD texture pack, stacked on the above ----
    if ($isDoom) {
        Write-Host ""
        Write-Host "  >>> OPTIONAL: HD TEXTURE PACK (Neural Upscale 2x) - can be" -ForegroundColor Yellow
        Write-Host "      combined with your choice above." -ForegroundColor Yellow
        $hd = (Read-Host "  >>> Add the HD texture pack? (Y/N)").Trim()
        if ($hd -match '^(y|yes|j|ja)$') {
            try { New-Item -ItemType Directory -Path $modsDir -Force -EA SilentlyContinue | Out-Null } catch {}
            $hdpk3 = Join-Path $modsDir $QZD_HDTEX_FILE
            if (-not (Test-Path $hdpk3)) {
                Write-Host ""
                Write-Host "  MANUAL STEP - the HD textures are on ModDB:" -ForegroundColor Yellow
                Write-Host "    1. Press Enter to open the ModDB download page." -ForegroundColor Yellow
                Write-Host "    2. Click the RED 'Download Now' button (~126 MB)." -ForegroundColor Yellow
                Write-Host "    3. DRAG the downloaded '$QZD_HDTEX_ZIP' onto THIS window, Enter." -ForegroundColor Yellow
                Write-Host ""
                Read-Host "  >>> Press Enter to open the download page" | Out-Null
                try { Start-Process $QZD_HDTEX_URL } catch {}
                Write-Host ""
                $hzin = (Read-Host "  Drop the .zip here (or Enter to skip)").Trim().Trim('"')
                if ($hzin -and (Test-Path -LiteralPath $hzin)) {
                    $htmp = Join-Path $installRoot "_hdtex_tmp"
                    try {
                        if (Test-Path $htmp) { Remove-Item $htmp -Recurse -Force -EA SilentlyContinue }
                        Expand-ArchiveOrFallback -ArchivePath $hzin -DestinationFolder $htmp -Label "HD texture pack" `
                            -SkipMessage "Skipped - the HD textures were not extracted." | Out-Null
                        # Ignore the __MACOSX duplicate the zip ships.
                        $hsrc = Get-ChildItem -Path $htmp -Filter $QZD_HDTEX_FILE -Recurse -EA SilentlyContinue |
                                Where-Object { $_.FullName -notmatch '__MACOSX' } | Select-Object -First 1
                        if ($hsrc) { Copy-Item -LiteralPath $hsrc.FullName -Destination $hdpk3 -Force }
                        Remove-Item $htmp -Recurse -Force -EA SilentlyContinue
                    } catch { Write-Warn "Could not unpack the HD textures: $_" }
                } else {
                    Write-Info "Skipped the HD texture pack."
                }
            } else {
                Write-Info "HD texture pack already installed - reusing it."
            }
            if (Test-Path $hdpk3) {
                # Append to the SAME -file list (or start one if nothing else chosen).
                if ($weaponsArg) { $weaponsArg = $weaponsArg + " `"mods\$QZD_HDTEX_FILE`"" }
                else { $weaponsArg = " -file `"mods\$QZD_HDTEX_FILE`"" }
                Write-OK "HD texture pack enabled for $GameTitle."
            }
        }
    }

    $batPath = Join-Path $installRoot $BatLabel
    $iwadRel = "wads\$WadName"
    $sharedArgs = "-iwad `"$iwadRel`" +vr_mode 10$weaponsArg"

    $batLines = @(
        '@echo off'
        'cd /d "%~dp0"'
        "gzdoomvr.exe -iwad `"$iwadRel`" +vr_mode 10$weaponsArg"
    )
    Set-Content -Path $batPath -Value $batLines -Encoding ASCII
    Write-Info "Launcher (fallback): $batPath"

    # Record the FULL launch args (iwad + vr_mode + any 3D-mod -file entries)
    # so the Hub's "Start in VR" button launches with the exact same mods as
    # the desktop shortcut. Without this, Start-in-VR used only the catalog's
    # static LaunchArgs (iwad + vr_mode, NO -file), so weapon/3D mods loaded
    # from the shortcut but NOT from Start-in-VR.
    #
    # Keyed by WadName because every GZDoomVR game shares this one install
    # folder - a single .vrlaunchargs would let the last-installed game's args
    # clobber the others. Start-GameInVR resolves the same per-WAD file.
    try {
        $__argKey = ($WadName -replace '[^A-Za-z0-9]', '_')
        Set-Content -Path (Join-Path $installRoot ".vrlaunchargs_$__argKey") -Value $sharedArgs -Encoding UTF8 -Force
    } catch {}

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
    $__gzIcon = $((Join-Path $installRoot "gzdoomvr.exe") + ",0")
    if ($IconFile) {
        $__icoSrc = Join-Path $QZD_SHARED_DIR $IconFile
        $__icoDst = Join-Path $installRoot $IconFile
        if (Test-Path $__icoSrc) {
            try { Copy-Item -LiteralPath $__icoSrc -Destination $__icoDst -Force } catch {}
            if (Test-Path $__icoDst) { $__gzIcon = $__icoDst }
        }
    }
    try {
        $sc = New-DesktopShortcut -ShortcutName ($GameTitle -replace '[\\/:*?"<>|]', '_') -TargetPath (Join-Path $installRoot "gzdoomvr.exe") -WorkingDir $installRoot -IconPath $__gzIcon -Arguments $sharedArgs
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

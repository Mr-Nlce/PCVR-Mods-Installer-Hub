# -------------------------------------------------------
# Lunacid VR Mod Installer
# "Lunacid VR Beta" by Tesseract - distributed via Nexus Mods
#
# Walks the user through:
# 1. Locate Lunacid (Steam library scan, else manual path)
# 2. BepInEx 5 - downloaded straight from GitHub (public asset),
#    skipped when the loader is already in place
# 3. Nexus download (free login gated - opens the Files page),
#    located via a Downloads scan, else drag-and-drop
# 4. Merge the contents of the archive's "LUNACID VR" folder into
#    the game ROOT
#
# The mod ships replacements for files the game already has
# (steam_api64.dll among them), so every file we overwrite is
# backed up as <name>.hubbak first.
#
# BepInEx 5 is pinned on purpose: the mod page says explicitly
# "Make sure you install BepInEx 5 and not 6" - BepInEx 6 is a
# different loader and the plugin will not load under it.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-InstallerFallback,
# Find-SteamGameFolder, Invoke-SafeDownload). These replace hard
# "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Lunacid VR Installer"

$MOD_NAME    = "Lunacid VR Beta"
$MOD_VERSION = "v0.7.3"
$MOD_AUTHOR  = "Tesseract"

$GAME_APPID = "1745510"
$GAME_NAME  = "Lunacid"
$GAME_EXE   = "LUNACID.exe"

# Nexus Mods page. The file sits behind a free Nexus login, so it
# cannot be pulled automatically - we open the Files tab and let the
# user grab it, then bring it back here.
$NEXUS_URL       = "https://www.nexusmods.com/lunacid/mods/23"
$NEXUS_FILES_URL = "$NEXUS_URL`?tab=files"

# BepInEx 5 (x64). Public GitHub release asset - no login, so this
# one downloads by itself.
$BEPINEX_VERSION = "5.4.23.5"
$BEPINEX_URL     = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.5/BepInEx_win_x64_5.4.23.5.zip"
$BEPINEX_PAGE    = "https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.5"

# The folder inside the mod archive whose CONTENTS go into the game
# root, and the file that proves the install worked.
$PAYLOAD_FOLDER = "LUNACID VR"
$MOD_REL_DLL    = "BepInEx\plugins\LUNACID VR\LUNACIDVR.dll"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Lunacid VR Mod Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m"  -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m"  -ForegroundColor Red }
function Pause-User {
    param($text = "Press Enter to continue...", $Color = "Yellow")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}

function Get-SteamPath {
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path -LiteralPath $p)) { return $p }
        } catch {}
    }
    return $null
}

function Get-SteamLibraries {
    param($SteamPath)
    $libs = @()
    if (-not $SteamPath) { return $libs }
    $libs += $SteamPath
    $vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
    if (Test-Path -LiteralPath $vdf) {
        [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
            $l = $_.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path -LiteralPath $l) { $libs += $l }
        }
    }
    return ($libs | Select-Object -Unique)
}

function Find-LunacidGamePath {
    # Steam libraries. String concatenation instead of Join-Path on
    # purpose: a library entry may point at a drive that no longer
    # exists, and Join-Path throws on a dead drive letter.
    $sp = Get-SteamPath
    if ($sp) {
        foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
            $candidate = "$lib\steamapps\common\$GAME_NAME"
            if (Test-Path -LiteralPath "$candidate\$GAME_EXE") { return $candidate }
        }
    }
    # Common manual locations, in case Steam's registry entry is gone.
    foreach ($guess in @(
        "C:\Program Files (x86)\Steam\steamapps\common\Lunacid",
        "C:\Program Files\Steam\steamapps\common\Lunacid",
        "D:\Steam\steamapps\common\Lunacid",
        "D:\SteamLibrary\steamapps\common\Lunacid",
        "E:\SteamLibrary\steamapps\common\Lunacid"
    )) {
        if (Test-Path -LiteralPath "$guess\$GAME_EXE") { return $guess }
    }
    return $null
}

# Copy a folder's contents over an existing tree, backing up every
# file we are about to overwrite as <name>.hubbak. Files that are
# already byte-identical are left alone - that keeps a re-run from
# turning the mod's own files into a second set of .hubbak copies.
# Returns the number of backups made.
function Copy-MergeWithBackup {
    param([string]$Source, [string]$Target)
    $backups = 0
    $items = Get-ChildItem -LiteralPath $Source -Recurse -File -ErrorAction Stop
    foreach ($item in $items) {
        $rel  = $item.FullName.Substring($Source.Length).TrimStart('\')
        $dest = Join-Path $Target $rel
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        if (Test-Path -LiteralPath $dest) {
            # Same file already in place (re-run / repair): nothing to
            # back up and nothing to copy.
            $same = $false
            try {
                $existing = Get-Item -LiteralPath $dest
                if ($existing.Length -eq $item.Length) {
                    $h1 = (Get-FileHash -LiteralPath $dest -Algorithm MD5).Hash
                    $h2 = (Get-FileHash -LiteralPath $item.FullName -Algorithm MD5).Hash
                    $same = ($h1 -eq $h2)
                }
            } catch {}
            if ($same) { continue }
            $bak = "$dest.hubbak"
            if (-not (Test-Path -LiteralPath $bak)) {
                try { Copy-Item -LiteralPath $dest -Destination $bak -Force; $backups++ } catch {}
            }
        }
        Copy-Item -LiteralPath $item.FullName -Destination $dest -Force
    }
    return $backups
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Lunacid VR adds full stereoscopic VR and motion controller" -ForegroundColor White
Write-Host " support to Lunacid - you swing melee weapons with your own" -ForegroundColor White
Write-Host " arm, aim spells from your off hand and reach over your" -ForegroundColor White
Write-Host " shoulder to swap weapons." -ForegroundColor White
Write-Host ""
Write-Host " This mod runs on SteamVR only. Set SteamVR as your active" -ForegroundColor White
Write-Host " runtime before playing - other OpenXR runtimes will not" -ForegroundColor White
Write-Host " bring the game up in VR." -ForegroundColor White
Write-Host ""
Write-Host " It is an early beta by the author's own description." -ForegroundColor Gray
Write-Host " The installer sets up BepInEx 5 and the mod itself." -ForegroundColor Gray

Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: locate Lunacid
# -------------------------------------------------------
Write-Step 1 4 "Locating Lunacid"

$gamePath = Find-LunacidGamePath
if (-not $gamePath) {
    $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Lunacid") -ProbeExe $GAME_EXE
}

if ($gamePath) {
    Write-OK "Found Lunacid at: $gamePath"
} else {
    Write-Warn "Could not auto-locate Lunacid."
    Write-Host " Please paste the path to your Lunacid folder" -ForegroundColor White
    Write-Host " (the folder where $GAME_EXE lives)." -ForegroundColor White
    Write-Host ""
    while (-not $gamePath) {
        $r = (Read-Host " Lunacid folder").Trim().Trim('"').Trim("'")
        if (-not $r) { continue }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "Folder not found: $r"; continue }
        if (-not (Test-Path -LiteralPath (Join-Path $r $GAME_EXE))) {
            Write-Fail "That folder does not contain $GAME_EXE."
            continue
        }
        $gamePath = $r
        Write-OK "Game folder set: $gamePath"
    }
}

# -------------------------------------------------------
# STEP 2: BepInEx 5
# -------------------------------------------------------
Write-Step 2 4 "BepInEx 5 mod loader"

$winhttp = Join-Path $gamePath "winhttp.dll"
$bepCore = Join-Path $gamePath "BepInEx\core\BepInEx.dll"

if ((Test-Path -LiteralPath $winhttp) -and (Test-Path -LiteralPath $bepCore)) {
    Write-OK "BepInEx is already installed - skipping this step."
} else {
    Write-Info "Downloading BepInEx $BEPINEX_VERSION (x64)..."
    $bepZip = Join-Path $env:TEMP "BepInEx_win_x64_$BEPINEX_VERSION.zip"
    $got = Invoke-SafeDownload -Urls @($BEPINEX_URL) -Destination $bepZip `
        -Label "BepInEx $BEPINEX_VERSION" `
        -ManualUrl $BEPINEX_PAGE `
        -Instructions "Download BepInEx_win_x64_$BEPINEX_VERSION.zip from the release page and save it as '$bepZip'. Then choose Retry." `
        -SkipMessage "Skipped - without BepInEx the VR plugin cannot load."

    if ($got -and (Test-Path -LiteralPath $bepZip)) {
        $bepTemp = Join-Path $env:TEMP "LunacidVR_bep_$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $bepTemp | Out-Null
        try {
            Expand-Archive -LiteralPath $bepZip -DestinationPath $bepTemp -Force
            # The BepInEx zip is flat: BepInEx\, winhttp.dll,
            # doorstop_config.ini, .doorstop_version, changelog.txt.
            Get-ChildItem -LiteralPath $bepTemp -Force | ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $gamePath -Recurse -Force
            }
            Write-OK "BepInEx $BEPINEX_VERSION installed into the game folder."
        } catch {
            Write-Fail "BepInEx setup failed: $_"
            $__fb = Invoke-InstallerFallback -Action "BepInEx extraction" `
                -Instructions "Open '$bepZip' and copy everything inside it (the BepInEx folder, winhttp.dll, doorstop_config.ini) into '$gamePath'. Then choose Skip to continue." `
                -SkipMessage "Skipped - the VR plugin will not load until BepInEx is in place." `
                -SourceFolder (Split-Path "$bepZip" -Parent) `
                -DestFolder "$gamePath" `
                -AllowSkip $true
            if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        }
        try { Remove-Item -LiteralPath $bepTemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        try { Remove-Item -LiteralPath $bepZip -Force -ErrorAction SilentlyContinue } catch {}
    } else {
        Write-Warn "Continuing without BepInEx - install it manually before playing:"
        Write-Host "     $BEPINEX_PAGE" -ForegroundColor Gray
    }
}

# -------------------------------------------------------
# STEP 3: get the mod from Nexus
# -------------------------------------------------------
Write-Step 3 4 "Downloading Lunacid VR from Nexus Mods"

Write-Host " The mod is behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host " downloaded automatically." -ForegroundColor White
Write-Host ""
Write-Host " Pressing Enter opens the Files page - no need to copy or click:" -ForegroundColor Yellow
Write-Host "     (  $NEXUS_FILES_URL )" -ForegroundColor Gray
Write-Host ""
Write-Host " 1) Log in to Nexus Mods (free account)." -ForegroundColor White
Write-Host " 2) Download the Lunacid VR file (Manual download)." -ForegroundColor White
Write-Host " 3) Come back here - the installer looks in your Downloads" -ForegroundColor White
Write-Host "    folder, or you can drag the file onto this window." -ForegroundColor White
# Look for the archive BEFORE sending anyone to the browser - it is often
# already there from an earlier run. Only when nothing turns up do we open
# the Nexus page.
$modZip = Find-PredownloadedFile -Patterns @("*LUNACID*VR*.zip","*LUNACID*.zip") -Label "the Lunacid VR mod"

if (-not $modZip) {
    Pause-User "Press Enter to open the download page on Nexus Mods..."
    try { Start-Process $NEXUS_FILES_URL } catch { Write-Warn "Open manually: $NEXUS_FILES_URL" }

    # Look again once the user is back - the first pass ran before the
    # download could possibly exist.
    Pause-User "Press Enter once the download has finished..."
    $modZip = Find-PredownloadedFile -Patterns @("*LUNACID*VR*.zip","*LUNACID*.zip") -Label "the Lunacid VR mod" -PageAlreadyOpen
}

if (-not $modZip) {
    Write-Host ""
    while (-not $modZip) {
        Write-Host " Drag-and-drop the downloaded archive into this window," -ForegroundColor Yellow
        Write-Host " or paste/type its full path, then press Enter" -ForegroundColor White
        Write-Host " (leave empty to cancel):" -ForegroundColor DarkGray
        $r = (Read-Host " Archive path").Trim().Trim('"').Trim("'")
        if (-not $r) {
            Write-Fail "No file provided - cannot install without the mod."
            Pause-User "Press Enter to exit..."
            exit 1
        }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
        if ($r -notmatch '\.zip$|\.7z$|\.rar$') { Write-Fail "Path is not a ZIP/7z/RAR archive: $r"; continue }
        $modZip = $r
        Write-OK "Archive located: $modZip"
    }
}

# -------------------------------------------------------
# STEP 4: extract + merge into the game root
# -------------------------------------------------------
Write-Step 4 4 "Installing the mod"

$tempExtract = Join-Path $env:TEMP "LunacidVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

try {
    Write-Host " Extracting archive..." -ForegroundColor Gray
    Expand-Archive -LiteralPath $modZip -DestinationPath $tempExtract -Force
} catch {
    Write-Fail "Extract failed: $_"
    $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
        -Instructions "Open '$modZip' with 7-Zip or Windows Explorer and extract its contents into '$tempExtract'. Then choose Retry." `
        -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
        -SourceFolder (Split-Path "$modZip" -Parent) `
        -DestFolder "$tempExtract" `
        -AllowSkip $true
    if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") {
        Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
        exit 1
    }
}

# The archive wraps everything in a "LUNACID VR" folder whose CONTENTS
# belong in the game root. Find it wherever it sits; if the author ever
# drops the wrapper, fall back to the folder that holds BepInEx, then
# to the extract root itself.
$srcRoot = $null
$wrapper = Get-ChildItem -LiteralPath $tempExtract -Directory -Recurse -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -eq $PAYLOAD_FOLDER -and (Test-Path -LiteralPath (Join-Path $_.FullName "BepInEx")) } |
           Select-Object -First 1
if ($wrapper) {
    $srcRoot = $wrapper.FullName
} else {
    $dllHit = Get-ChildItem -LiteralPath $tempExtract -Filter "LUNACIDVR.dll" -Recurse -File -ErrorAction SilentlyContinue |
              Select-Object -First 1
    if ($dllHit) {
        # <root>\BepInEx\plugins\LUNACID VR\LUNACIDVR.dll -> up four levels
        $p = $dllHit.Directory
        for ($i = 0; $i -lt 3 -and $p -and $p.Parent; $i++) { $p = $p.Parent }
        if ($p) { $srcRoot = $p.FullName }
    }
}
if (-not $srcRoot) { $srcRoot = $tempExtract }
Write-Info "Payload root: $srcRoot"

Write-Host " Copying mod files into: $gamePath" -ForegroundColor Gray
$backupCount = 0
try {
    $backupCount = Copy-MergeWithBackup -Source $srcRoot -Target $gamePath
    Write-OK "Mod files installed into the game folder."
    if ($backupCount -gt 0) {
        Write-Info "$backupCount original file(s) backed up as *.hubbak."
    }
} catch {
    Write-Fail "Copy failed: $_"
    $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
        -Instructions "Manually copy everything inside '$srcRoot' into '$gamePath' (the Lunacid game folder), merging when asked. Watch for UAC permission prompts. Then choose Skip to continue." `
        -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
        -SourceFolder "$srcRoot" `
        -DestFolder "$gamePath" `
        -AllowSkip $true
    if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") {
        Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
        exit 1
    }
}

try { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Sanity check
$modDll = Join-Path $gamePath $MOD_REL_DLL
if (-not (Test-Path -LiteralPath (Join-Path $gamePath "winhttp.dll"))) {
    Write-Warn "winhttp.dll is missing from the game folder - BepInEx will not start."
} elseif (-not (Test-Path -LiteralPath $modDll)) {
    Write-Warn "LUNACIDVR.dll did not land in BepInEx\plugins\LUNACID VR."
} else {
    Write-OK "BepInEx + LUNACIDVR.dll present in the game folder."
}

# -------------------------------------------------------
# Record install path so the Hub can mark VR Ready
# -------------------------------------------------------
try {
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
} catch {}
try {
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $MOD_VERSION -Encoding UTF8 -Force
    # ALSO write the durable stamp next to the GAME (2026-08-20).
    # The line above lands inside the Hub folder and is gone as
    # soon as a new Hub build is dropped in; the scan then finds
    # no marker and seeds the CURRENT online tag, swallowing a
    # pending update. The game-side stamp survives that.
    Save-InstalledStamp -GameDir @($gamePath, $destDir) -Version $MOD_VERSION
} catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " +==========================================================+" -ForegroundColor Yellow
Write-Host " |             REQUIRED IN-GAME SETTINGS                    |" -ForegroundColor Yellow
Write-Host " +==========================================================+" -ForegroundColor Yellow
Write-Host "   Aesthetic must be " -NoNewline -ForegroundColor White
Write-Host " Clean " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " - Midnight and PSX invert" -ForegroundColor White
Write-Host "   the view in VR. Open Options from the main menu (or the" -ForegroundColor White
Write-Host "   Settings tab in-game) to change it." -ForegroundColor White
Write-Host ""
Write-Host "   The author warns the menu can LIE about this: even when it" -ForegroundColor White
Write-Host "   already reads Clean, cycle through the aesthetics with the" -ForegroundColor White
Write-Host "   arrows and land back on Clean." -ForegroundColor White
Write-Host ""
Write-Host "   Runtime: " -NoNewline -ForegroundColor White
Write-Host " SteamVR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " - this mod supports nothing else." -ForegroundColor White
Write-Host ""
Write-Host " +==========================================================+" -ForegroundColor Yellow
Write-Host " |         PHOTOSENSITIVITY / COMFORT WARNING               |" -ForegroundColor Yellow
Write-Host " +==========================================================+" -ForegroundColor Yellow
Write-Host "  Lighting can flicker heavily where many light sources meet." -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  The author advises against this mod if you are sensitive to" -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  flashing lights or prone to nausea in VR." -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host " Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host " starting sometimes out of focus, then launch with" -ForegroundColor White
Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or from Steam." -ForegroundColor White
Write-Host ""
Write-Host " Melee swings need real arm speed, weapons swap by reaching" -ForegroundColor Gray
Write-Host " over your shoulder, and the mod has its own settings under" -ForegroundColor Gray
Write-Host " BepInEx\config. This game's page in the Hub has the full control" -ForegroundColor Gray
Write-Host " list and" -ForegroundColor Gray
Write-Host " the known beta issues." -ForegroundColor Gray
Write-Host ""
Write-Host " The moon is watching. Go down." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

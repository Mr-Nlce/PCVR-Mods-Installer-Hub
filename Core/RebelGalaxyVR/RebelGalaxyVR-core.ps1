# ============================================================
#  Rebel Galaxy VR - Installer (RebelGalaxyVR by Destroyjevski)
# ============================================================
#  Stereoscopic OpenXR VR for Rebel Galaxy: 6DoF head tracking,
#  the UI on its own spatial OpenXR quad layer, two world scales
#  and separate supersampling for world and HUD. Gamepad only -
#  motion controllers are not supported.
#
#  PACKAGE (read from the real v1.1.5 archive: Steam 14 files, Epic 15 -
#  the extra one is Epic_Repair_XInput.bat. v1.1.5 ships FLAT, with no
#  wrapper folder; v1.1.2 had one. Both work, see below):
#    XINPUT1_3.dll        <- THE HOOK (proxy DLL, this is the mod)
#    openxr_loader.dll
#    RebelGalaxyVR.ini
#    Play in Flat.bat / Back to VR.bat
#    Set_Resolution_High|Medium|Low.bat
#    Set_Scale_Human_1to1|Diorama.bat
#    INSTALL_EN.txt / INSTALLATION_DE.txt / LICENSE.txt
#    CHANGELOG.txt        <- new in v1.1.2
#  Everything goes NEXT TO THE GAME EXE, never in a subfolder.
#  The v1.1.2 archive wraps it all in RebelGalaxyVR_Steam_v1.1.2\ - note
#  the store in the folder name, v1.0.0 had none. The payload root is
#  resolved by searching for XINPUT1_3.dll, so any wrapper name works.
#
#  TWO SEPARATE ARCHIVES ON NEXUS, ONE PER STORE - this is easy to get
#  wrong and it matters:
#    MAIN FILE      -> the Steam build   (folder RebelGalaxyVR_Steam_...)
#    OPTIONAL FILES -> the Epic build    (entry starts "RebelGalaxyVR Epic")
#  No version number is spelled out anywhere in this installer's text:
#  Nexus has no version API, we cannot auto-update, and the number will
#  move. The store word is what identifies the file, not the version.
#  The HOOK IS IDENTICAL in both (XINPUT1_3.dll, 202752 bytes in v1.1.5,
#  same sha256 in the Steam and Epic packages - re-checked 2026-08-20; same build
#  stamp) - what differs is the game exe the helper bats watch for, and
#  the Epic-only xinput handling below.
#
#  EPIC NEEDS A RENAME BEFORE EXTRACTING. The Epic build of the game
#  ships its own real xinput1_3.dll in the game folder. The mod IS a
#  file of that name, so extracting on top of it destroys the original.
#  The Epic archive's own instructions therefore say: rename
#  xinput1_3.dll -> xinput1_3_original.dll FIRST. This installer does
#  that itself. Its Play in Flat.bat then restores that original copy
#  while the mod is parked as .disabled, which is why Epic can end up
#  with BOTH names on disk - see FlatVRDisabledWins in the catalog.
#  The Steam build has no xinput1_3.dll of its own and needs none of it.
#
#  GAME SETTINGS ARE NOT OUR JOB ANY MORE. Since v1.1.2 the mod sets
#  the three it needs at startup itself: gamepad on, shadows off,
#  distortion on. Shadows go off because the game computes them from the
#  game camera, so in VR the shadow would follow the head. Nothing here
#  edits those, and nothing asks the user to.
#
#  32-BIT RUNTIME: Rebel Galaxy is a 32-bit game, so it needs an OpenXR
#  runtime with 32-bit support. Since v1.1.2 the mod's log names the
#  registered 32-bit runtime, and says so when there is none.
#
#  FLAT/VR SWITCH: the mod's own bats just rename
#  XINPUT1_3.dll <-> XINPUT1_3.dll.disabled. The catalog carries the
#  same pair as FlatVREnabled/FlatVRDisabled, so the Hub's own
#  Flat/VR button on the detail page does it too and shows which mode
#  is live. ModFileAlt is the .disabled name - without it the tile
#  would drop to "not installed" in flat mode and the switch button
#  (which needs vrinstalled) would vanish exactly when it is needed.
#
#  NEXUS: free-login gated, so no automatic download. Files page is
#  opened, the Downloads folder is scanned, drag & drop as last resort.
#
#  STORES: only the Steam build is TESTED by the author, but the mod
#  is a plain proxy DLL next to the exe, so we look everywhere (Steam,
#  GOG, GOG Galaxy, Epic, Origin legacy, EA app, Humble) - Martin's
#  call, because that is expected to broaden shortly.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Rebel Galaxy VR Installer"

$MOD_NAME    = "RebelGalaxyVR"
$MOD_VERSION = "v1.1.5"
$MOD_AUTHOR  = "Destroyjevski"

$GAME_APPID  = "290300"
$GAME_TITLE  = "Rebel Galaxy"

$NEXUS_URL       = "https://www.nexusmods.com/rebelgalaxy/mods/11"
$NEXUS_FILES_URL = "https://www.nexusmods.com/rebelgalaxy/mods/11?tab=files"

# The hook, and the files we verify after copying.
$REL_MOD_FILE = "XINPUT1_3.dll"
$REL_DISABLED = "XINPUT1_3.dll.disabled"
$REL_LOADER   = "openxr_loader.dll"
$REL_INI      = "RebelGalaxyVR.ini"

# Epic only: the game's own xinput1_3.dll, and the name the mod expects
# it to be parked under. Epic_Repair_XInput.bat is unique to the Epic
# archive, so it is also how we tell the two downloads apart.
$EPIC_ORIGINAL = "xinput1_3_original.dll"
$EPIC_REPAIR   = "Epic_Repair_XInput.bat"
$EPIC_GAME_EXE = "RebelGalaxy.exe"

# Exes that prove a folder is Rebel Galaxy. The first two are unique to
# the game; the launcher names are generic, so they only count when the
# folder itself is named after the game (the Epic build ships only
# Launcher.exe).
$GAME_EXES_UNIQUE  = @("RebelGalaxySteam.exe", "RebelGalaxyGOG.exe", "RebelGalaxy.exe")
$GAME_EXES_LAUNCH  = @("SteamLauncher.exe", "GoGLauncher.exe", "Launcher.exe")

# -------------------------------------------------------
#  Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Rebel Galaxy VR - Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$n, [int]$t, [string]$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!]  $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [X]  $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Is this folder a Rebel Galaxy install? Never Join-Path over a drive
# that may not exist - it throws - so build with [IO.Path]::Combine and
# guard every probe.
function Test-RGRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $Root)) { return $false }
        foreach ($exe in $GAME_EXES_UNIQUE) {
            if (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $exe))) { return $true }
        }
        $leaf = Split-Path -Leaf $Root
        if ($leaf -replace '[^A-Za-z]', '' -match '(?i)rebelgalaxy') {
            foreach ($exe in $GAME_EXES_LAUNCH) {
                if (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $exe))) { return $true }
            }
        }
    } catch { return $false }
    return $false
}

# The exe the Hub should start for a NON-Steam install: prefer the
# store launcher that actually exists, else the game exe itself.
function Get-RGLaunchExe {
    param([string]$Root)
    foreach ($exe in @("SteamLauncher.exe", "GoGLauncher.exe", "Launcher.exe", "RebelGalaxyGOG.exe", "RebelGalaxySteam.exe", "RebelGalaxy.exe")) {
        $full = [System.IO.Path]::Combine($Root, $exe)
        if (Test-Path -LiteralPath $full) { return $full }
    }
    return $null
}

# Which store is this game folder from? Decided by the exe that is
# actually there, not by where the folder sits - a moved or manually
# dropped folder still answers correctly. "Steam" also covers GOG and
# anything else that keeps its own xinput1_3.dll out of the way; only
# Epic needs the extra handling, so only Epic is named separately.
function Get-RGStore {
    param([string]$Root)
    if (-not $Root) { return "unknown" }
    try {
        if (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, "RebelGalaxySteam.exe"))) { return "steam" }
        if (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, "RebelGalaxyGOG.exe")))   { return "steam" }
        if (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $EPIC_GAME_EXE)))         { return "epic" }
    } catch {}
    return "unknown"
}

# Which store is this ARCHIVE for? Epic_Repair_XInput.bat exists only in
# the Epic package, so its presence in the listing is the marker. The file
# NAME is deliberately not used: Nexus mangles download names, and the
# version in them will move.
function Get-RGArchiveStore {
    param([string]$ArchivePath)
    try {
        $top = Get-ArchiveTopLevel -ArchivePath $ArchivePath
        if (-not $top.Ok) { return "unknown" }
        foreach ($e in $top.Entries) {
            if (([string]$e) -match [regex]::Escape($EPIC_REPAIR)) { return "epic" }
        }
        return "steam"
    } catch {}
    return "unknown"
}

Write-Header
Write-Host " Rebel Galaxy VR renders the game in real stereoscopic 3D over" -ForegroundColor White
Write-Host " OpenXR, with 6DoF head tracking and the whole interface on its" -ForegroundColor White
Write-Host " own layer standing in the world instead of stuck to your face." -ForegroundColor White
Write-Host " You play it on a GAMEPAD - motion controllers are not supported." -ForegroundColor White
Write-Host ""
Write-Host " Run the game in Borderless Window or Windowed mode." -ForegroundColor Yellow
Write-Host " Steam and Epic each have their OWN download on Nexus." -ForegroundColor Yellow
Write-Host " The game is 32-bit, so your OpenXR runtime needs 32-bit" -ForegroundColor Yellow
Write-Host " support - SteamVR has it, some others do not." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
#  STEP 1: get the mod from Nexus (free login gated)
# -------------------------------------------------------
Write-Step 1 4 "Downloading Rebel Galaxy VR from Nexus Mods"

Write-Host " The file sits behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host " fetched automatically." -ForegroundColor White
Write-Host ""
Write-Host " THERE ARE TWO DOWNLOADS - one per store. Take the one that" -ForegroundColor Yellow
Write-Host " matches your copy of the game:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Steam  ->  the MAIN FILE at the top of the page" -ForegroundColor White
Write-Host "   Epic   ->  under " -NoNewline -ForegroundColor White
Write-Host " OPTIONAL FILES " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ", the entry whose name" -ForegroundColor White
Write-Host "              starts with " -NoNewline -ForegroundColor White
Write-Host " RebelGalaxyVR Epic " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host " Grabbed the wrong one? This installer notices and says so." -ForegroundColor Gray
Write-Host ""
Write-Host " $NEXUS_FILES_URL" -ForegroundColor Gray
Write-Host ""

$zipPatterns = @("*RebelGalaxy*VR*.zip", "*RebelGalaxyVR*.zip", "*Rebel*Galaxy*.zip")
$modZip = Find-PredownloadedFile -Patterns $zipPatterns -Label "the Rebel Galaxy VR mod"
if (-not $modZip) {
    Write-Host " 1) Log in to Nexus Mods." -ForegroundColor White
    Write-Host " 2) Download the file for YOUR store (Manual download) -" -ForegroundColor White
    Write-Host "    Steam from the main files, Epic from Optional Files." -ForegroundColor White
    Write-Host " 3) Come back here - your Downloads folder is checked, or you" -ForegroundColor White
    Write-Host "    can drag the file onto this window." -ForegroundColor White
    Pause-User "Press Enter to open the download page..." | Out-Null
    try { Start-Process $NEXUS_FILES_URL } catch { Write-Warn "Open it manually: $NEXUS_FILES_URL" }
}

# -------------------------------------------------------
#  STEP 2: locate the downloaded archive
# -------------------------------------------------------
Write-Step 2 4 "Locating the downloaded file"

if (-not $modZip) {
    Pause-User "Press Enter once the download has finished..." | Out-Null
    $modZip = Find-PredownloadedFile -Patterns $zipPatterns -Label "the Rebel Galaxy VR mod" -PageAlreadyOpen
}
while (-not $modZip) {
    Write-Host " Drag & drop the downloaded file onto this window, or paste" -ForegroundColor White
    Write-Host " its full path, then press Enter." -ForegroundColor White
    Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host " Archive").Trim().Trim('"').Trim("'")
    if (-not $raw) { Write-Fail "No file - cannot install without the mod."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (-not (Test-Path -LiteralPath $raw)) { Write-Fail "File not found: $raw"; continue }
    if ($raw -notmatch '(?i)\.(zip|7z|rar)$') { Write-Fail "Not a ZIP/7z/RAR archive: $raw"; continue }
    $modZip = $raw
}
Write-OK "Archive: $modZip"

# -------------------------------------------------------
#  STEP 3: locate the game (every store, not just Steam)
# -------------------------------------------------------
Write-Step 3 4 "Locating $GAME_TITLE"

$gamePath = $null

if (-not $gamePath -and (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue)) {
    $gamePath = Find-SteamGameFolder -AppId $GAME_APPID `
        -SteamFolderNames @("RebelGalaxy", "Rebel Galaxy") `
        -ProbeExe "RebelGalaxySteam.exe" `
        -EpicNames @("RebelGalaxy", "Rebel Galaxy")
    if ($gamePath -and -not (Test-RGRoot -Root $gamePath)) { $gamePath = $null }
}
# Store defaults across C:/D:/E:. Every one of these is a verified layout
# for this game, and the folder name differs per store (RebelGalaxy vs
# Rebel Galaxy), so both spellings are probed.
if (-not $gamePath) {
    $candidates = @()
    foreach ($d in @("C:", "D:", "E:")) {
        foreach ($name in @("RebelGalaxy", "Rebel Galaxy")) {
            $candidates += "$d\GOG Games\$name"
            $candidates += "$d\Program Files (x86)\GOG Galaxy\Games\$name"
            $candidates += "$d\Program Files\Epic Games\$name"
            $candidates += "$d\Program Files (x86)\Epic Games\$name"
            $candidates += "$d\Program Files (x86)\Origin Games\$name"
            $candidates += "$d\Program Files\EA Games\$name"
            $candidates += "$d\Program Files (x86)\EA Games\$name"
            $candidates += "$d\Games\$name"
            $candidates += "$d\$name"
        }
    }
    foreach ($cand in $candidates) {
        if (Test-RGRoot -Root $cand) { $gamePath = $cand; break }
    }
}
# A path this installer recorded earlier.
if (-not $gamePath) {
    $rec = $null
    try { $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
    if ($rec) { $rec = $rec.Trim() }
    if (Test-RGRoot -Root $rec) { $gamePath = $rec }
}
# Manual fallback (typed or dropped folder) - covers Humble and any
# custom install location.
while (-not $gamePath) {
    Write-Warn "Could not find the game automatically."
    Write-Host " Drag & drop your $GAME_TITLE GAME FOLDER onto this window -" -ForegroundColor White
    Write-Host " the one holding RebelGalaxySteam.exe (Steam), RebelGalaxy.exe" -ForegroundColor White
    Write-Host " (Epic) or RebelGalaxyGOG.exe -" -ForegroundColor White
    Write-Host " then press Enter." -ForegroundColor White
    Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host " Game folder").Trim().Trim('"')
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-RGRoot -Root $raw) { $gamePath = $raw }
    else { Write-Fail "No Rebel Galaxy executable found in that folder." }
}
Write-OK "Found: $gamePath"

# The store decides which archive is the right one and whether the Epic
# xinput rename is needed. Both are read off the disk / out of the ZIP,
# never assumed.
$store = Get-RGStore -Root $gamePath
switch ($store) {
    "epic"  { Write-Info "This is the Epic build (found $EPIC_GAME_EXE)." }
    "steam" { Write-Info "This is the Steam/GOG build." }
    default { Write-Warn "Could not tell which store this folder is from - continuing without the store checks." }
}

# Wrong download for this store? Say which one is needed and take another
# archive, rather than installing helper bats that watch the wrong exe.
if ($store -ne "unknown") {
    while ($true) {
        $archStore = Get-RGArchiveStore -ArchivePath $modZip
        if ($archStore -eq "unknown") {
            Write-Warn "Could not read the archive to check which store it is for - continuing."
            break
        }
        if ($archStore -eq $store) {
            Write-OK "Archive matches this install ($store build)."
            break
        }
        Write-Host ""
        Write-Fail "This archive is the $archStore package, but your game is the $store build."
        if ($store -eq "epic") {
            Write-Host " You need the Epic download: on the mod's Files page it sits" -ForegroundColor White
            Write-Host " under " -NoNewline -ForegroundColor White
            Write-Host " OPTIONAL FILES " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ", named " -NoNewline -ForegroundColor White
            Write-Host " RebelGalaxyVR Epic ... " -ForegroundColor Black -BackgroundColor Yellow
        } else {
            Write-Host " You need the Steam download: the MAIN FILE at the top of" -ForegroundColor White
            Write-Host " the mod's Files page, not the Optional Files entry." -ForegroundColor White
        }
        Write-Host " $NEXUS_FILES_URL" -ForegroundColor Gray
        Pause-User "Press Enter to open the Files page..." | Out-Null
        try { Start-Process $NEXUS_FILES_URL } catch {}
        $newZip = $null
        while (-not $newZip) {
            Write-Host " Drag & drop the correct archive onto this window, or paste" -ForegroundColor White
            Write-Host " its full path, then press Enter." -ForegroundColor White
            Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
            $raw2 = (Read-Host " Archive").Trim().Trim('"').Trim("'")
            if (-not $raw2) { Write-Fail "No file - cannot install the wrong package."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
            if (-not (Test-Path -LiteralPath $raw2)) { Write-Fail "File not found: $raw2"; continue }
            if ($raw2 -notmatch '(?i)\.(zip|7z|rar)$') { Write-Fail "Not a ZIP/7z/RAR archive: $raw2"; continue }
            $newZip = $raw2
        }
        $modZip = $newZip
    }
}

$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile $REL_MOD_FILE -Label "RebelGalaxyVR"

# -------------------------------------------------------
#  STEP 4: install next to the game exe
# -------------------------------------------------------
Write-Step 4 4 "Installing the mod files"

$tempExtract = Join-Path $env:TEMP ("RGVR_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null

$extractOk = $false
try {
    Expand-Archive -LiteralPath $modZip -DestinationPath $tempExtract -Force -ErrorAction Stop
    $extractOk = $true
} catch {
    Write-Fail "Extraction failed: $($_.Exception.Message)"
    $fb = Invoke-InstallerFallback -Action "mod archive extraction" `
        -Instructions "Open '$modZip' with 7-Zip or Explorer and extract its contents into '$tempExtract'. Then choose Retry." `
        -SkipMessage "Skipped - the mod files were NOT extracted." `
        -SourceFolder (Split-Path -Parent $modZip) `
        -DestFolder $tempExtract `
        -AllowSkip $true
    if ([string]$fb -eq "retry") { $extractOk = (Test-Path -LiteralPath $tempExtract) }
    if ([string]$fb -eq "quit")  { Pause-User "Press Enter to exit." | Out-Null; exit 1 }
}

# The archive wraps everything in RebelGalaxyVR_v<ver>\. Resolve the real
# payload root by finding the hook itself - immune to any wrapper depth or
# renaming of that folder.
$srcRoot = $tempExtract
$hookHit = $null
try {
    $hookHit = Get-ChildItem -LiteralPath $tempExtract -Filter $REL_MOD_FILE -Recurse -File -ErrorAction SilentlyContinue |
               Select-Object -First 1
} catch {}
if ($hookHit) { $srcRoot = $hookHit.DirectoryName }
if (-not $hookHit) {
    Write-Fail "$REL_MOD_FILE was not found inside the archive - wrong file, or the package layout changed."
    Pause-User "Press Enter to exit." | Out-Null; exit 1
}
Write-Info "Payload: $srcRoot"

# A previous run may have left the mod switched to Flat. Copying a fresh
# enabled hook next to a stale .disabled copy would leave two hooks and a
# confusing state for the mod's own switch bats, so the stale one goes.
$disabledFull = [System.IO.Path]::Combine($gamePath, $REL_DISABLED)
if (Test-Path -LiteralPath $disabledFull) {
    try { Remove-Item -LiteralPath $disabledFull -Force -ErrorAction Stop; Write-Info "Removed the old disabled hook ($REL_DISABLED)." } catch {}
}

# EPIC ONLY, AND IT HAS TO HAPPEN BEFORE THE COPY. The Epic build ships
# its own real xinput1_3.dll; the mod is a file of that same name, so
# copying first would destroy the original with no way back except
# Epic_Repair_XInput.bat. Park it as xinput1_3_original.dll - which is
# also exactly the name the mod's own Play in Flat.bat expects to find.
# Guarded on both sides: if the parked copy already exists we are looking
# at an earlier install and must NOT overwrite it with the mod's own hook.
if ($store -eq "epic") {
    $xiLive = [System.IO.Path]::Combine($gamePath, $REL_MOD_FILE)
    $xiPark = [System.IO.Path]::Combine($gamePath, $EPIC_ORIGINAL)
    if (Test-Path -LiteralPath $xiPark) {
        Write-OK "$EPIC_ORIGINAL is already in place - left untouched."
    } elseif (Test-Path -LiteralPath $xiLive) {
        # Only the GAME's own dll may be parked. If what sits there is
        # already the mod (same size as the one in the archive), parking
        # it would save the mod as the "original" and the real one would
        # be lost for good - so that case is left to the repair bat.
        $liveLen = 0; $modLen = 0
        try { $liveLen = (Get-Item -LiteralPath $xiLive).Length } catch {}
        try { $modLen  = (Get-Item -LiteralPath ([System.IO.Path]::Combine($srcRoot, $REL_MOD_FILE))).Length } catch {}
        if ($modLen -gt 0 -and $liveLen -eq $modLen) {
            Write-Warn "The xinput1_3.dll in the game folder is already the mod - not parking it."
            Write-Host "   If flat mode ever complains about a missing original, run" -ForegroundColor Gray
            Write-Host "   $EPIC_REPAIR in the game folder." -ForegroundColor Gray
        } else {
            try {
                Rename-Item -LiteralPath $xiLive -NewName $EPIC_ORIGINAL -Force -ErrorAction Stop
                Write-OK "Parked the game's own xinput1_3.dll as $EPIC_ORIGINAL."
            } catch {
                Write-Fail "Could not rename the game's xinput1_3.dll: $($_.Exception.Message)"
                Write-Host "   Close the game and the Epic launcher, then run this again." -ForegroundColor White
                Pause-User "Press Enter to exit." | Out-Null
                exit 1
            }
        }
    } else {
        Write-Info "No xinput1_3.dll in the game folder - nothing to park."
    }
}

Write-Info "Copying into: $gamePath"
$copyOk = $true
try {
    Get-ChildItem -LiteralPath $srcRoot | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $gamePath -Recurse -Force -ErrorAction Stop
    }
} catch {
    $copyOk = $false
    Write-Fail "Copy failed: $($_.Exception.Message)"
    $fb = Invoke-InstallerFallback -Action "copying the mod into the game folder" `
        -Instructions "Copy everything from '$srcRoot' into '$gamePath' (next to the game exe, NOT into a subfolder), overwriting when asked. Then choose Skip to continue." `
        -SkipMessage "Skipped - the mod files were NOT copied; the install is incomplete." `
        -SourceFolder $srcRoot `
        -DestFolder $gamePath `
        -AllowSkip $true
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit." | Out-Null; exit 1 }
}
try { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Verify at the TARGET, not in the temp folder.
$missing = @()
foreach ($rel in @($REL_MOD_FILE, $REL_LOADER, $REL_INI)) {
    if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $rel)))) { $missing += $rel }
}
if ($missing.Count -eq 0) {
    Write-OK "Mod files in place ($REL_MOD_FILE, $REL_LOADER, $REL_INI)."
} else {
    Write-Fail "Missing after copy: $($missing -join ', ')"
    Write-Warn "Copy the files from the archive into $gamePath by hand, then start the game."
}

# -------------------------------------------------------
#  Hub markers + launch route
# -------------------------------------------------------
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $MOD_VERSION -Encoding UTF8 -Force } catch {}
# ALSO write the durable stamp next to the GAME (2026-08-20).
# The line above lands inside the Hub folder and is gone as
# soon as a new Hub build is dropped in; the scan then finds
# no marker and seeds the CURRENT online tag, swallowing a
# pending update. The game-side stamp survives that.
Save-InstalledStamp -GameDir $gamePath -Version $MOD_VERSION

# Steam installs launch through Steam (the store handles its own DRM and
# overlay), so no .launch_exe there. Every other store gets a direct exe
# marker plus a desktop shortcut, because steam://rungameid would fail.
$isSteamInstall = ($gamePath -match '(?i)steamapps\\common')
if (-not $isSteamInstall) {
    $launchExe = Get-RGLaunchExe -Root $gamePath
    if ($launchExe) {
        try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launchExe -Encoding UTF8 -Force } catch {}
        # The store launchers (Launcher.exe, GoGLauncher.exe, ...) have no
        # usable icon resource. We ship RebelGalaxy_VR.ico (16/32/48/64)
        # and copy it into the game folder for a stable icon path (same
        # approach as Forza Horizon 5/6, BotW and Total Chaos). Fallback
        # chain: our icon -> the GAME exe -> the launcher itself.
        $iconArg = "$launchExe,0"
        foreach ($ge in $GAME_EXES_UNIQUE) {
            $gf = [System.IO.Path]::Combine($gamePath, $ge)
            if (Test-Path -LiteralPath $gf) { $iconArg = "$gf,0"; break }
        }
        $iconDest = [System.IO.Path]::Combine($gamePath, "RebelGalaxy_VR.ico")
        try {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot "RebelGalaxy_VR.ico") -Destination $iconDest -Force -ErrorAction Stop
            if (Test-Path -LiteralPath $iconDest) { $iconArg = $iconDest }
        } catch {}
        try {
            [void](New-DesktopShortcut -ShortcutName "Rebel Galaxy VR" `
                -TargetPath $launchExe `
                -WorkingDir ([System.IO.Path]::GetDirectoryName($launchExe)) `
                -IconPath $iconArg `
                -Description "Launch Rebel Galaxy in VR")
            Write-OK "Desktop shortcut created: Rebel Galaxy VR"
        } catch {}
    }
} else {
    try { Remove-Item -LiteralPath (Join-Path $PSScriptRoot ".launch_exe") -Force -ErrorAction SilentlyContinue } catch {}
}

# -------------------------------------------------------
#  The one game-side setting that can break this mod
# -------------------------------------------------------
# The game's own abandoned VR path is switched on with <INTEGER>VR:1 in
# local_settings.txt and must stay 0 - the mod brings its own OpenXR
# path. We only READ the file and report it; the Hub does not edit
# settings outside the game folder.
$vrOneFound = $false
$settingsPath = $null
try {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { $docs = [System.IO.Path]::Combine($env:USERPROFILE, "Documents") }
    $settingsPath = [System.IO.Path]::Combine($docs, "My Games\Double Damage Games\RebelGalaxy\local_settings.txt")
    if (Test-Path -LiteralPath $settingsPath) {
        $txt = Get-Content -LiteralPath $settingsPath -Raw -ErrorAction Stop
        if ($txt -match '(?i)VR:\s*1') { $vrOneFound = $true }
    }
} catch {}

# -------------------------------------------------------
#  DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Rebel Galaxy VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ($vrOneFound) {
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |            CHANGE THIS ONE GAME SETTING                  |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "   Your game config has the game's OWN old VR path switched on." -ForegroundColor White
    Write-Host "   It must be off - this mod brings its own OpenXR path." -ForegroundColor White
    Write-Host "   Open:" -ForegroundColor White
    Write-Host "     $settingsPath" -ForegroundColor Gray
    Write-Host "   and set the line to " -NoNewline -ForegroundColor White
    Write-Host " <INTEGER>VR:0 " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
}
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |               WHAT IS LEFT FOR YOU                       |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   Display mode  " -NoNewline -ForegroundColor White
Write-Host " Borderless Window or Windowed " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Desktop res   " -NoNewline -ForegroundColor White
Write-Host " 2560 x 1440 recommended " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Your OpenXR runtime has to be active before you launch, and" -ForegroundColor White
Write-Host "   it needs 32-BIT support - Rebel Galaxy is a 32-bit game." -ForegroundColor White
Write-Host "   SteamVR has it. If VR stays dark, the mod log now names the" -ForegroundColor White
Write-Host "   registered 32-bit runtime, or says there is none." -ForegroundColor White
Write-Host ""
Write-Host "   Gamepad, shadows and distortion the mod sets by itself at" -ForegroundColor Gray
Write-Host "   startup - nothing to change in the game menu. Shadows go off" -ForegroundColor Gray
Write-Host "   on purpose: the game computes them from the game camera, so" -ForegroundColor Gray
Write-Host "   in VR the shadow would follow your head." -ForegroundColor Gray
Write-Host ""
Write-Host "  Start with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or through Steam." -ForegroundColor White
Write-Host "  Gamepad: LB + RB + A recenters the view." -ForegroundColor White
Write-Host ""
if ($store -eq "epic") {
    Write-Host "  Epic build: the game's own xinput1_3.dll is parked as" -ForegroundColor Gray
    Write-Host "  $EPIC_ORIGINAL and comes back when you play flat." -ForegroundColor Gray
    Write-Host "  If that file ever goes missing, run $EPIC_REPAIR" -ForegroundColor Gray
    Write-Host "  in the game folder." -ForegroundColor Gray
    Write-Host ""
}
Write-Host "  Image quality and world scale are preset .bat files in the" -ForegroundColor Gray
Write-Host "  game folder (Set_Resolution_*, Set_Scale_*). To play flat for" -ForegroundColor Gray
Write-Host "  a while, use the Flat / VR switch on this game's Hub page -" -ForegroundColor Gray
Write-Host "  it shows which mode is live. This game's page in the Hub has" -ForegroundColor Gray
Write-Host "  the rest." -ForegroundColor Gray
Write-Host ""
Write-Host "  Broadside a pirate cruiser with the nebula wrapped around you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close." | Out-Null

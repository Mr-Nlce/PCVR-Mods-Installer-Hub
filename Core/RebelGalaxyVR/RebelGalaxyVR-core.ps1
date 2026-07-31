# ============================================================
#  Rebel Galaxy VR - Installer (RebelGalaxyVR by Destroyjevski)
# ============================================================
#  Stereoscopic OpenXR VR for Rebel Galaxy: 6DoF head tracking,
#  the UI on its own spatial OpenXR quad layer, two world scales
#  and separate supersampling for world and HUD. Gamepad only -
#  motion controllers are not supported.
#
#  PACKAGE (read from the real v1.0.0 archive, 13 files, flat):
#    XINPUT1_3.dll        <- THE HOOK (proxy DLL, this is the mod)
#    openxr_loader.dll
#    RebelGalaxyVR.ini
#    Play in Flat.bat / Back to VR.bat
#    Set_Resolution_High|Medium|Low.bat
#    Set_Scale_Human_1to1|Diorama.bat
#    INSTALL_EN.txt / INSTALLATION_DE.txt / LICENSE.txt
#  Everything goes NEXT TO THE GAME EXE, never in a subfolder.
#  The archive wraps it all in RebelGalaxyVR_v<ver>\, so the payload
#  root is resolved by searching for XINPUT1_3.dll.
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
$MOD_VERSION = "v1.0.0"
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

# Exes that prove a folder is Rebel Galaxy. The first two are unique to
# the game; the launcher names are generic, so they only count when the
# folder itself is named after the game (the Epic build ships only
# Launcher.exe).
$GAME_EXES_UNIQUE  = @("RebelGalaxySteam.exe", "RebelGalaxyGOG.exe")
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
    foreach ($exe in @("SteamLauncher.exe", "GoGLauncher.exe", "Launcher.exe", "RebelGalaxyGOG.exe", "RebelGalaxySteam.exe")) {
        $full = [System.IO.Path]::Combine($Root, $exe)
        if (Test-Path -LiteralPath $full) { return $full }
    }
    return $null
}

Write-Header
Write-Host " Rebel Galaxy VR renders the game in real stereoscopic 3D over" -ForegroundColor White
Write-Host " OpenXR, with 6DoF head tracking and the whole interface on its" -ForegroundColor White
Write-Host " own layer standing in the world instead of stuck to your face." -ForegroundColor White
Write-Host " You play it on a GAMEPAD - motion controllers are not supported." -ForegroundColor White
Write-Host ""
Write-Host " Run the game in Borderless Window or Windowed mode." -ForegroundColor Yellow
Write-Host " Only the Steam version is tested by the author." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
#  STEP 1: get the mod from Nexus (free login gated)
# -------------------------------------------------------
Write-Step 1 4 "Downloading Rebel Galaxy VR from Nexus Mods"

Write-Host " The file sits behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host " fetched automatically." -ForegroundColor White
Write-Host ""
Write-Host " $NEXUS_FILES_URL" -ForegroundColor Gray
Write-Host ""

$zipPatterns = @("*RebelGalaxy*VR*.zip", "*RebelGalaxyVR*.zip", "*Rebel*Galaxy*.zip")
$modZip = Find-PredownloadedFile -Patterns $zipPatterns -Label "the Rebel Galaxy VR mod"
if (-not $modZip) {
    Write-Host " 1) Log in to Nexus Mods." -ForegroundColor White
    Write-Host " 2) Download the Rebel Galaxy VR file (Manual download)." -ForegroundColor White
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
    Write-Host " the one holding RebelGalaxySteam.exe or RebelGalaxyGOG.exe -" -ForegroundColor White
    Write-Host " then press Enter." -ForegroundColor White
    Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host " Game folder").Trim().Trim('"')
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-RGRoot -Root $raw) { $gamePath = $raw }
    else { Write-Fail "No Rebel Galaxy executable found in that folder." }
}
Write-OK "Found: $gamePath"
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
Write-Host "  |               REQUIRED GAME SETTINGS                     |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   Display mode  " -NoNewline -ForegroundColor White
Write-Host " Borderless Window or Windowed " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Desktop res   " -NoNewline -ForegroundColor White
Write-Host " 2560 x 1440 recommended " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Your OpenXR runtime has to be active before you launch." -ForegroundColor White
Write-Host ""
Write-Host "  Start with 'Start in VR' in the Hub, or through Steam." -ForegroundColor White
Write-Host "  Gamepad: LB + RB + A recenters the view." -ForegroundColor White
Write-Host ""
Write-Host "  Image quality and world scale are preset .bat files in the" -ForegroundColor Gray
Write-Host "  game folder (Set_Resolution_*, Set_Scale_*). To play flat for" -ForegroundColor Gray
Write-Host "  a while, use the Flat / VR switch on this game's Hub page -" -ForegroundColor Gray
Write-Host "  it shows which mode is live. See the README for the rest." -ForegroundColor Gray
Write-Host ""
Write-Host "  Broadside a pirate cruiser with the nebula wrapped around you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close." | Out-Null

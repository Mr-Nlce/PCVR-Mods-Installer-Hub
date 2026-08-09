# -------------------------------------------------------
# Hollow Knight Silksong VR Mod Installer
#
# TWO MODS, ONE GAME FOLDER.
#   A. HollowKnightSilksong_VR by Astienth - Discord ZIP, brings its
#      own BepInEx, adds parallax depth between the sprite layers.
#   B. SilksongFlatToVR4 by SadMonsterParty - Nexus 942, needs
#      BepInEx 5.4.23.5 and openvr_api.dll from SteamVR; renders the
#      flat game onto floating OpenVR overlay planes.
#
# Both are BepInEx plugins in the SAME plugins folder and would fight
# over the screen, so only ONE may be live at a time. The inactive one
# is parked as <name>.dll.off. Once BOTH are on disk the installer
# writes two launchers into <game>\VRLaunch\ - each one flips the pair
# and then starts the game through Steam. Those two bats are what the
# Hub tile detects for its split Play button (catalog: TwoMods).
#
# Neither mod adds motion controls: this is a 2D game and stays on
# gamepad or keyboard.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$SCRIPT_DIR = $PSScriptRoot

$GAME_APPID = "1030300"
$GAME_NAME  = "Hollow Knight Silksong"
$DATA_DIR   = "Hollow Knight Silksong_Data"

# Mod A - Astienth, via Discord
$A_NAME = "Astienth"
$A_DLL  = "HollowKnightSilksong_VR.dll"
$A_BAT  = "Silksong VR (Astienth).bat"
$DISCORD_INVITE_URL   = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL    = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1414940597579419679/1440826936698998785"
$DISCORD_INFO_URL     = "https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679"

# Mod B - SadMonsterParty, via Nexus. No direct download link exists
# (Nexus gates every file), so the Files tab is opened and the user
# brings the ZIP. Keep BOTH URLs current when a new version lands.
$B_NAME = "Flat to VR"
$B_DLL  = "SilksongFlatToVR4.dll"
$B_BAT  = "Silksong VR (Flat to VR).bat"
$NEXUS_FILES_URL = "https://www.nexusmods.com/hollowknightsilksong/mods/942?tab=files"
$NEXUS_INFO_URL  = "https://www.nexusmods.com/hollowknightsilksong/mods/942?tab=description"

# BepInEx 5.4.23.5 x64 - pinned, only fetched when the game folder has
# none. Mod A ships its own copy inside its ZIP.
$BEPINEX_URL = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.5/BepInEx_win_x64_5.4.23.5.zip"

$LAUNCH_REL = "VRLaunch"
$PLUGINS_REL = "BepInEx\plugins"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Hollow Knight Silksong VR Mod Installer" -ForegroundColor Cyan
    Write-Host "  Two VR mods - pick one, or run this twice to get both" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host "  [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [X] $m"  -ForegroundColor Red }
function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host | Out-Null
}

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
    param($SteamPath)
    $libs = @()
    if (-not $SteamPath) { return $libs }
    $libs += $SteamPath
    $vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
            $l = $_.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $l) { $libs += $l }
        }
    }
    return ($libs | Select-Object -Unique)
}

function Find-SilksongGamePath {
    $sp = Get-SteamPath
    if (-not $sp) { return $null }
    foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
        foreach ($folder in @("Hollow Knight Silksong", "HollowKnightSilksong", "Silksong")) {
            $candidate = Join-Path $lib "steamapps\common\$folder"
            if (Test-Path -LiteralPath "$candidate\$DATA_DIR") { return $candidate }
        }
    }
    return $null
}

# The SteamVR copy of openvr_api.dll, mod B's third ingredient. Steam
# can put SteamVR in any library, so all of them are checked.
# win64 FIRST, win32 only as a fallback. The Nexus instructions say
# bin\win32 - that is wrong for this game: Silksong is a 64-bit Unity
# build, and a 64-bit process cannot load a 32-bit DLL. Windows then
# reports the load failure, and the mod passes it on as
# "openvr_api.dll not found" - which sends everyone looking for a
# missing file that is sitting right there in the wrong architecture.
function Find-OpenVrApiDll {
    $sp = Get-SteamPath
    if (-not $sp) { return $null }
    foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
        foreach ($arch in @("win64", "win32")) {
            $c = "$lib\steamapps\common\SteamVR\bin\$arch\openvr_api.dll"
            if (Test-Path -LiteralPath $c) { return $c }
        }
    }
    return $null
}

# The game executable, read off the disk rather than assumed: Unity
# pairs <Name>.exe with <Name>_Data, and that data folder is what we
# already located the install by. Returns $null when nothing matches,
# and the launcher bats then simply skip their running-game check.
function Get-GameExeName {
    param([string]$Root)
    try {
        foreach ($exe in (Get-ChildItem -LiteralPath $Root -Filter "*.exe" -File -ErrorAction SilentlyContinue)) {
            $data = Join-Path $Root ($exe.BaseName + "_Data")
            if (Test-Path -LiteralPath $data) { return $exe.Name }
        }
    } catch {}
    return $null
}

function Test-ModAInstalled { param([string]$Root) return (Test-Path -LiteralPath (Join-Path $Root "$PLUGINS_REL\$A_DLL")) -or (Test-Path -LiteralPath (Join-Path $Root "$PLUGINS_REL\$A_DLL.off")) }
function Test-ModBInstalled { param([string]$Root) return (Test-Path -LiteralPath (Join-Path $Root "$PLUGINS_REL\$B_DLL")) -or (Test-Path -LiteralPath (Join-Path $Root "$PLUGINS_REL\$B_DLL.off")) }

# Makes one plugin live and parks the other as .dll.off. Called at the
# end of whichever branch ran, so the mod just installed is the one
# that loads on the next launch.
function Set-ActivePlugin {
    param([string]$Root, [string]$LiveDll, [string]$ParkDll)
    $plug = Join-Path $Root $PLUGINS_REL
    $live = Join-Path $plug $LiveDll
    $park = Join-Path $plug $ParkDll
    try {
        if ((Test-Path -LiteralPath "$live.off") -and -not (Test-Path -LiteralPath $live)) {
            Rename-Item -LiteralPath "$live.off" -NewName $LiveDll -Force
        }
    } catch {}
    try {
        if (Test-Path -LiteralPath $park) {
            if (Test-Path -LiteralPath "$park.off") { Remove-Item -LiteralPath "$park.off" -Force -ErrorAction SilentlyContinue }
            Rename-Item -LiteralPath $park -NewName "$ParkDll.off" -Force
        }
    } catch {}
}

# One launcher per mod. Pure CMD, ASCII, quoted paths. Each one parks
# the other plugin, brings its own back from .off, refuses to run while
# the game is open (a loaded DLL is locked and the rename would fail
# silently), then starts the game through Steam.
function Write-LauncherBat {
    param([string]$Path, [string]$Title, [string]$PluginDir, [string]$LiveDll, [string]$ParkDll, [string]$ExeName)
    $lines = @()
    $lines += "@echo off"
    $lines += "title $Title"
    $lines += "rem Written by the PCVR Mods Installer Hub."
    $lines += "rem Makes this mod the active BepInEx plugin, then starts the game."
    $lines += "setlocal"
    $lines += "set ""PLUG=$PluginDir"""
    if ($ExeName) {
        $lines += "tasklist /FI ""IMAGENAME eq $ExeName"" 2>nul | find /I ""$ExeName"" >nul"
        $lines += "if not errorlevel 1 ("
        $lines += "  echo The game is still running. Close it, then run this again."
        $lines += "  pause"
        $lines += "  exit /b 1"
        $lines += ")"
    }
    $lines += "if exist ""%PLUG%\$ParkDll"" ("
    $lines += "  if exist ""%PLUG%\$ParkDll.off"" del ""%PLUG%\$ParkDll.off"" >nul 2>&1"
    $lines += "  ren ""%PLUG%\$ParkDll"" ""$ParkDll.off"" >nul 2>&1"
    $lines += ")"
    $lines += "if exist ""%PLUG%\$LiveDll.off"" if not exist ""%PLUG%\$LiveDll"" ren ""%PLUG%\$LiveDll.off"" ""$LiveDll"" >nul 2>&1"
    $lines += "if not exist ""%PLUG%\$LiveDll"" ("
    $lines += "  echo Could not activate this mod - $LiveDll is missing."
    $lines += "  echo Re-run the installer for it from the PCVR Mods Installer Hub."
    $lines += "  pause"
    $lines += "  exit /b 1"
    $lines += ")"
    $lines += "start """" ""steam://rungameid/$GAME_APPID"""
    $lines += "endlocal"
    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII -Force
}

# Both bats, but only once BOTH mods are parked on disk - with a single
# mod there is nothing to switch between, and the tile then shows the
# normal start (catalog: TwoModsRequireBoth). Stale bats from an earlier
# two-mod install are removed so the tile cannot offer a missing mod.
function Update-SwitchLaunchers {
    param([string]$Root, [string]$ExeName)
    $launchDir = Join-Path $Root $LAUNCH_REL
    $plug = Join-Path $Root $PLUGINS_REL
    $haveA = Test-ModAInstalled -Root $Root
    $haveB = Test-ModBInstalled -Root $Root
    if ($haveA -and $haveB) {
        if (-not (Test-Path -LiteralPath $launchDir)) { New-Item -ItemType Directory -Path $launchDir -Force | Out-Null }
        Write-LauncherBat -Path (Join-Path $launchDir $A_BAT) -Title "Silksong VR - $A_NAME" `
            -PluginDir $plug -LiveDll $A_DLL -ParkDll $B_DLL -ExeName $ExeName
        Write-LauncherBat -Path (Join-Path $launchDir $B_BAT) -Title "Silksong VR - $B_NAME" `
            -PluginDir $plug -LiveDll $B_DLL -ParkDll $A_DLL -ExeName $ExeName
        Write-OK "Both mods on disk - switch launchers written to $LAUNCH_REL"
        return $true
    }
    foreach ($stale in @($A_BAT, $B_BAT)) {
        $sp = Join-Path $launchDir $stale
        if (Test-Path -LiteralPath $sp) { try { Remove-Item -LiteralPath $sp -Force -ErrorAction Stop } catch {} }
    }
    return $false
}

function Resolve-GameFolder {
    $p = Find-SilksongGamePath
    if (-not $p) { $p = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Hollow Knight Silksong") -GogNames @("Hollow Knight Silksong") }
    if ($p) { Write-OK "Found $GAME_NAME at: $p"; return $p }
    Write-Warn "Could not auto-locate $GAME_NAME."
    Write-Host "  Paste the path to the folder that contains '$DATA_DIR'." -ForegroundColor White
    Write-Host ""
    while ($true) {
        $r = (Read-Host "  $GAME_NAME folder").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-Path -LiteralPath $r) { Write-OK "Game folder set: $r"; return $r }
        Write-Fail "Folder not found: $r"
    }
}

# -------------------------------------------------------
# Intro + mode choice
# -------------------------------------------------------
Write-Header

Write-Host "  Silksong is a 2D game. NEITHER of these mods puts you INSIDE" -ForegroundColor White
Write-Host "  a VR world - you look at the game on a screen in front of you," -ForegroundColor White
Write-Host "  and the mods give that picture depth. No motion controls: you" -ForegroundColor White
Write-Host "  play with a gamepad or keyboard, exactly like the flat game." -ForegroundColor White
Write-Host ""
Write-Host "  [1] $A_NAME - parallax depth between the sprite layers." -ForegroundColor White
Write-Host "      Free, but the download sits behind a Discord login." -ForegroundColor Gray
Write-Host "  [2] $B_NAME by SadMonsterParty - a 3D SCREEN, not a room." -ForegroundColor White
Write-Host "      The game is split across several floating SteamVR planes at" -ForegroundColor Gray
Write-Host "      different distances, so it reads like a layered diorama in" -ForegroundColor Gray
Write-Host "      front of you. From Nexus, and it needs SteamVR running." -ForegroundColor Gray
Write-Host ""
Write-Host "  Only one can be active at a time. With both installed the Hub" -ForegroundColor Gray
Write-Host "  tile gets a split Play button and switches for you." -ForegroundColor Gray
Write-Host ""

Pause-User "Press Enter to start..."

$gameRoot = $null
Write-Step 1 4 "Locating $GAME_NAME"
$gameRoot = Resolve-GameFolder
$exeName = Get-GameExeName -Root $gameRoot

$aHere = Test-ModAInstalled -Root $gameRoot
$bHere = Test-ModBInstalled -Root $gameRoot

Write-Host ""
Write-Host "  Which mod do you want to install?" -ForegroundColor White
Write-Host ""
if ($aHere) { Write-Host "  [1] $A_NAME (Discord)      - already installed, this reinstalls it" -ForegroundColor DarkGray }
else        { Write-Host "  [1] $A_NAME (Discord)      - not installed yet" -ForegroundColor Green }
if ($bHere) { Write-Host "  [2] $B_NAME by SadMonsterParty (Nexus) - already installed, this reinstalls it" -ForegroundColor DarkGray }
else        { Write-Host "  [2] $B_NAME by SadMonsterParty (Nexus) - not installed yet" -ForegroundColor Green }
Write-Host ""
$defaultMode = if (-not $aHere) { "1" } elseif (-not $bHere) { "2" } else { "1" }
Write-Host "  Enter alone picks [$defaultMode]." -ForegroundColor DarkGray
$mode = ""
while ($mode -notin @("1","2")) {
    $mode = (Read-Host "  Your choice (1/2)").Trim()
    if (-not $mode) { $mode = $defaultMode }
}
$doA = ($mode -eq "1")

# -------------------------------------------------------
# Shared gate: the game must have run once
# -------------------------------------------------------
Write-Step 2 4 "Pre-install: launch the game once"
Write-Host "  Both mods expect the game's first-run files to exist." -ForegroundColor White
Write-Host "  Have you already launched $GAME_NAME once and gotten past" -ForegroundColor White
Write-Host "  the initial settings?" -ForegroundColor White
Write-Host ""
Write-Host "  [Y] Yes" -ForegroundColor White
Write-Host "  [N] No - I will do it now and come back" -ForegroundColor White
Write-Host ""
$firstRun = ""
while ($firstRun -notin @("y","Y","n","N")) { $firstRun = (Read-Host "  Your choice (Y/N)").Trim() }
if ($firstRun -in @("n","N")) {
    Write-Host ""
    Write-Host "  Launch Silksong via Steam, get past the initial settings," -ForegroundColor Gray
    Write-Host "  close the game, then run this installer again." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 0
}

# =======================================================
# BRANCH A - Astienth, via Discord
# =======================================================
if ($doA) {

Write-Step 3 4 "Getting the $A_NAME mod"
Write-Host "  This mod is handed out in the FarmerTrueVR Discord." -ForegroundColor White
Write-Host "  Are you already a member with the rules accepted?" -ForegroundColor White
Write-Host ""
Write-Host "  [Y] Yes - go straight to the download post" -ForegroundColor White
Write-Host "  [N] No - walk me through joining first" -ForegroundColor White
Write-Host ""
$member = ""
while ($member -notin @("y","Y","n","N")) { $member = (Read-Host "  Your choice (Y/N)").Trim() }

if ($member -in @("n","N")) {
    Write-Host ""
    Write-Host "  Server invite - click Accept Invite:" -ForegroundColor White
    Write-Host "  $DISCORD_INVITE_URL" -ForegroundColor DarkGray
    Pause-User "Press Enter to open the invite..."
    try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open the browser - use the URL above." }

    Write-Host ""
    Write-Host "  Rules channel - read them, then click the AK-47 emoji" -ForegroundColor White
    Write-Host "  under the rules post. That unlocks the rest of the server." -ForegroundColor White
    Write-Host "  $DISCORD_RULES_URL" -ForegroundColor DarkGray
    Pause-User "Press Enter to open the rules channel..."
    try { Start-Process $DISCORD_RULES_URL } catch {}
}

Write-Host ""
Write-Host "  Mod download post - download the ZIP there:" -ForegroundColor White
Write-Host "  $DISCORD_DOWNLOAD_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the download post..."
try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}

Write-Host ""
$modZip = $null
while (-not $modZip) {
    Write-Host "  Drag the downloaded ZIP into this window, or paste its" -ForegroundColor Yellow
    Write-Host "  full path, then press Enter:" -ForegroundColor White
    $r = (Read-Host "  ZIP path").Trim().Trim('"')
    if (-not $r) { continue }
    if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
    if ($r -notmatch '\.zip$|\.7z$|\.rar$') { Write-Fail "Not an archive: $r"; continue }
    $modZip = $r
    Write-OK "Archive located: $modZip"
}

Write-Step 4 4 "Installing $A_NAME"

# R1 - read the archive before opening it.
$top = Get-ArchiveTopLevel -ArchivePath $modZip
if ($top.Ok) {
    if ($top.Roots -and $top.Roots.Count -eq 1 -and $top.Roots[0] -ne "BepInEx") {
        Write-Info "Archive wraps its files in '$($top.Roots[0])' - that will be resolved."
    } else {
        Write-Info "Archive listed: $($top.Entries.Count) entries."
    }
} else {
    Write-Warn "Could not list the archive - continuing, the result is verified afterwards."
}

$aTarget = Join-Path $gameRoot "$PLUGINS_REL\$A_DLL"
# A parked copy would survive the merge and shadow the fresh file.
try { if (Test-Path -LiteralPath "$aTarget.off") { Remove-Item -LiteralPath "$aTarget.off" -Force -ErrorAction SilentlyContinue } } catch {}

# R2 - the payload root is RESOLVED, never guessed, and the anchor is
# the mod's own DLL: whatever the ZIP wraps its files in, the folder
# that holds BepInEx\plugins\<the DLL> is the real root. Expand-
# ArchiveToTarget does exactly that and then merges into the game
# folder, which is what this mod needs - it ships a whole BepInEx set.
Write-Info "Extracting..."
$st = Expand-ArchiveToTarget -ArchivePath $modZip -TargetDir $gameRoot `
        -RelModFile "$PLUGINS_REL\$A_DLL" -Markers @("winhttp.dll", "doorstop_config.ini", "BepInEx") `
        -Label "$A_NAME mod" -SkipMessage "Skipped - the mod files were NOT installed." -AllowSkip $true

# R3 - der Beweis liegt AM ZIEL: die Datei ist da. NICHT "sie hat sich
# gegenueber vorher geaendert" - eine zweite Installation derselben
# Version kopiert dieselbe Datei mit demselben Zeitstempel, und genau
# das hat der alte Vergleich als MISSERFOLG gemeldet, obwohl alles
# richtig lag. Ein unveraenderter Zeitstempel ist bei einem Kopiervorgang
# kein Fehler, sondern der Normalfall beim Neuinstallieren.
$installedOk = (Test-Path -LiteralPath $aTarget)

if (-not $installedOk) {
    # R4 - say where things stand instead of failing into the void.
    Write-Host ""
    Write-Fail "$A_DLL did not arrive in $PLUGINS_REL."
    Write-Host "  Open the ZIP by hand and copy its contents into:" -ForegroundColor White
    Write-Host "    $gameRoot" -ForegroundColor Yellow
    Write-Host "  Afterwards $A_DLL must sit in:" -ForegroundColor White
    Write-Host "    $(Join-Path $gameRoot $PLUGINS_REL)" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}

Set-ActivePlugin -Root $gameRoot -LiveDll $A_DLL -ParkDll $B_DLL
Write-OK "$A_NAME is the active mod."

}
# =======================================================
# BRANCH B - Flat to VR, via Nexus
# =======================================================
else {

Write-Step 3 4 "Getting the $B_NAME mod"
Write-Host "  Nexus does not allow direct downloads, so you fetch the file" -ForegroundColor White
Write-Host "  and drop it here. Mod page:" -ForegroundColor White
Write-Host "  $NEXUS_INFO_URL" -ForegroundColor DarkGray
Write-Host ""

$modZip = Find-PredownloadedFile -Patterns @("*SilkSong*flat*VR*.zip", "*SMP_SilkSong*.zip", "*SilksongFlatToVR*.zip") -Label "the Flat to VR mod"
if (-not $modZip) {
    Write-Host ""
    Write-Host "  Download the main file from the Files tab:" -ForegroundColor White
    Write-Host "  $NEXUS_FILES_URL" -ForegroundColor DarkGray
    Pause-User "Press Enter to open the Files page..."
    try { Start-Process $NEXUS_FILES_URL } catch { Write-Warn "Could not open the browser - use the URL above." }
    $modZip = Find-PredownloadedFile -Patterns @("*SilkSong*flat*VR*.zip", "*SMP_SilkSong*.zip", "*SilksongFlatToVR*.zip") -Label "the Flat to VR mod" -PageAlreadyOpen
}
while (-not $modZip) {
    Write-Host ""
    Write-Host "  Drag the downloaded ZIP into this window, or paste its" -ForegroundColor Yellow
    Write-Host "  full path, then press Enter:" -ForegroundColor White
    $r = (Read-Host "  ZIP path").Trim().Trim('"')
    if (-not $r) { continue }
    if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
    if ($r -notmatch '\.zip$|\.7z$|\.rar$') { Write-Fail "Not an archive: $r"; continue }
    $modZip = $r
}
Write-OK "Archive located: $modZip"

Write-Step 4 4 "Installing $B_NAME"

# --- 1/3 BepInEx ------------------------------------------------
# Mod A brings its own; only fetch a copy when the folder has none.
$bepCore = Join-Path $gameRoot "BepInEx\core\BepInEx.dll"
$winhttp = Join-Path $gameRoot "winhttp.dll"
if ((Test-Path -LiteralPath $bepCore) -and (Test-Path -LiteralPath $winhttp)) {
    Write-OK "BepInEx is already in the game folder - left as it is."
} else {
    Write-Info "BepInEx is missing - fetching 5.4.23.5 (x64)."
    $bepZip = Join-Path $env:TEMP ("BepInEx_5_4_23_5_" + [System.IO.Path]::GetRandomFileName() + ".zip")
    $dl = Invoke-SafeDownload -Urls @($BEPINEX_URL) -Destination $bepZip -Label "BepInEx 5.4.23.5" `
            -ManualUrl $BEPINEX_URL `
            -Instructions "Download BepInEx_win_x64_5.4.23.5.zip from the URL above and save it to '$bepZip', then choose Retry." `
            -SkipMessage "Skipped - without BepInEx the mod cannot load."
    if ((Test-Path -LiteralPath $bepZip) -and ((Get-Item -LiteralPath $bepZip).Length -gt 0)) {
        # R1 - list before extracting. This archive is flat by design.
        $btop = Get-ArchiveTopLevel -ArchivePath $bepZip
        if ($btop.Ok) { Write-Info "BepInEx archive listed: $($btop.Entries.Count) entries." }
        try {
            $bTmp = Join-Path $env:TEMP ("BepInExEx_" + [System.IO.Path]::GetRandomFileName())
            New-Item -ItemType Directory -Path $bTmp -Force | Out-Null
            Expand-Archive -LiteralPath $bepZip -DestinationPath $bTmp -Force
            # R2 - marker-resolved, so a future wrapped release still lands right.
            $bmv = Move-PayloadIntoPlace -SearchRoot $bTmp -TargetDir $gameRoot -Marker "doorstop_config.ini"
            if (-not $bmv.Ok) { Write-Warn "BepInEx payload: $($bmv.Message)" }
            try { Remove-Item -LiteralPath $bTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        } catch {
            Write-Fail "BepInEx extract failed: $($_.Exception.Message)"
        }
        try { Remove-Item -LiteralPath $bepZip -Force -ErrorAction SilentlyContinue } catch {}
    }
    # R3 - proof at the destination.
    if ((Test-Path -LiteralPath $bepCore) -and (Test-Path -LiteralPath $winhttp)) {
        Write-OK "BepInEx installed."
    } else {
        Write-Host ""
        Write-Fail "BepInEx is not in the game folder."
        Write-Host "  Unpack BepInEx_win_x64_5.4.23.5.zip into:" -ForegroundColor White
        Write-Host "    $gameRoot" -ForegroundColor Yellow
        Write-Host "  $BEPINEX_URL" -ForegroundColor DarkGray
        Pause-User "Press Enter to exit."
        exit 1
    }
}

# --- 2/3 the plugin ---------------------------------------------
$plugDir = Join-Path $gameRoot $PLUGINS_REL
if (-not (Test-Path -LiteralPath $plugDir)) { New-Item -ItemType Directory -Path $plugDir -Force | Out-Null }
$bTarget = Join-Path $plugDir $B_DLL
try { if (Test-Path -LiteralPath "$bTarget.off") { Remove-Item -LiteralPath "$bTarget.off" -Force -ErrorAction SilentlyContinue } } catch {}

# R1 + R2. The Nexus archive holds the single DLL, so the marker IS the
# mod file - resolved recursively in case a future upload wraps it.
$mTop = Get-ArchiveTopLevel -ArchivePath $modZip
if ($mTop.Ok) { Write-Info "Mod archive listed: $($mTop.Entries.Count) entries." }
$mTmp = Join-Path $env:TEMP ("SilkFlatVR_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $mTmp -Force | Out-Null
try {
    Expand-Archive -LiteralPath $modZip -DestinationPath $mTmp -Force
} catch {
    Write-Fail "Extract failed: $($_.Exception.Message)"
}
$src = $null
try { $src = Get-ChildItem -LiteralPath $mTmp -Filter $B_DLL -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
if (-not $src) {
    # The Nexus page text says "SilksongFlatToVR.dll" while the file in
    # the archive is SilksongFlatToVR4.dll - accept any of that family
    # rather than stopping on the author's typo.
    try { $src = Get-ChildItem -LiteralPath $mTmp -Filter "SilksongFlatToVR*.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
}
if ($src) {
    try { Copy-Item -LiteralPath $src.FullName -Destination $bTarget -Force } catch { Write-Fail "Copy failed: $($_.Exception.Message)" }
}
try { Remove-Item -LiteralPath $mTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# R3 - der Beweis ist ein Vergleich ZIEL gegen QUELLE, nicht Ziel gegen
# "wie es vorher war". Beim zweiten Lauf derselben Version ist die Datei
# byte- und zeitgleich - der alte Vor/Nach-Vergleich hielt das fuer einen
# Fehlschlag und brach mit "did not arrive" ab, obwohl die DLL korrekt lag.
$bOk = $false
if (Test-Path -LiteralPath $bTarget) {
    if ($src) {
        try { $bOk = ((Get-Item -LiteralPath $bTarget).Length -eq $src.Length) } catch { $bOk = $true }
    } else {
        # Kein Quellobjekt (Archiv nicht lesbar), aber die Datei liegt am
        # Ziel - dann ist sie von einem frueheren Lauf und in Ordnung.
        $bOk = $true
    }
}
if (-not $bOk) {
    Write-Host ""
    Write-Fail "$B_DLL did not arrive in $PLUGINS_REL."
    Write-Host "  Open the ZIP by hand and copy the DLL into:" -ForegroundColor White
    Write-Host "    $plugDir" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "$B_DLL installed."

# --- 3/3 openvr_api.dll -----------------------------------------
# ZWEI ZIELE, und das zweite ist das entscheidende. Die Mod ruft
# openvr_api ueber P/Invoke auf; aufgeloest wird das von Unitys Mono,
# und Mono sucht native Bibliotheken einer Unity-App in
# <Spiel>_Data\Plugins\x86_64\ - nicht zuverlaessig im Spielordner.
# Liegt die DLL nur in der Wurzel, meldet die Mod genau das, was der
# Nutzer sieht: "openvr_api.dll not found: openvr_api assembly:
# <unknown assembly>", die Mono-Meldung fuer eine nicht gefundene
# native Bibliothek. Dass Plugins\x86_64 der richtige Ort ist, ist
# belegt: Star Trucker VR und Outbound VR liefern ihre eigenen
# OpenXR-Bibliotheken genau dort aus (<Spiel>_Data\Plugins\x86_64\
# openxr_loader.dll). Wir legen sie in BEIDE Ordner - die Wurzel steht
# so in der Nexus-Anleitung, Plugins\x86_64 ist das, was laedt.
$ovrName    = "openvr_api.dll"
$ovrTargets = @( (Join-Path $gameRoot $ovrName) )
$pluginNative = Join-Path $gameRoot "$DATA_DIR\Plugins\x86_64"
if (Test-Path -LiteralPath (Join-Path $gameRoot $DATA_DIR)) {
    try { if (-not (Test-Path -LiteralPath $pluginNative)) { New-Item -ItemType Directory -Path $pluginNative -Force | Out-Null } } catch {}
    $ovrTargets += (Join-Path $pluginNative $ovrName)
}

$ovrSrc = Find-OpenVrApiDll
$ovrDone = @()
$ovrMissing = @()
foreach ($t in $ovrTargets) {
    if ($ovrSrc) {
        try { Copy-Item -LiteralPath $ovrSrc -Destination $t -Force } catch {}
    }
    if (Test-Path -LiteralPath $t) { $ovrDone += $t } else { $ovrMissing += $t }
}

if ($ovrDone.Count -gt 0) {
    $arch = if ($ovrSrc -and ($ovrSrc -match '\\win64\\')) { "64-bit (win64)" }
            elseif ($ovrSrc) { "32-bit (win32)" }
            else { "already present" }
    Write-OK "$ovrName in place, $arch"
    foreach ($t in $ovrDone) { Write-Host "     $t" -ForegroundColor Gray }
    if ($ovrSrc -and ($ovrSrc -notmatch '\\win64\\')) {
        Write-Warn "Only the 32-bit copy was on this machine. Silksong is 64-bit,"
        Write-Host "   so replace both with ...\SteamVR\bin\win64\$ovrName" -ForegroundColor Yellow
    }
}
if ($ovrMissing.Count -gt 0) {
    Write-Host ""
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |  ONE FILE LEFT FOR YOU                                   |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  Copy this file:" -ForegroundColor White
    Write-Host "    ...\steamapps\common\SteamVR\bin\win64\$ovrName " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  into each of these folders:" -ForegroundColor White
    foreach ($t in $ovrMissing) {
        Write-Host "    $(Split-Path -Parent $t) " -ForegroundColor Black -BackgroundColor Yellow
    }
    Write-Host "  Without it the mod starts but stays disconnected from OpenVR." -ForegroundColor White
    Write-Host ""
    Pause-User "Press Enter once that is done..."
}

Set-ActivePlugin -Root $gameRoot -LiveDll $B_DLL -ParkDll $A_DLL
Write-OK "$B_NAME is the active mod."

}

# =======================================================
# Shared tail
# =======================================================
$bothNow = Update-SwitchLaunchers -Root $gameRoot -ExeName $exeName

# R5 - the marker is written only after the checks above passed. It is
# the game ROOT, so the catalog's ModFile / ModFileAlt resolve against it.
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
if ($doA) { Write-Host "  $A_NAME installed" -ForegroundColor Green }
else      { Write-Host "  $B_NAME installed" -ForegroundColor Green }
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

if ($bothNow) {
    Write-Host "  Both mods are on disk. The Hub tile now has a split Play" -ForegroundColor White
    Write-Host "  button - pick a mod there and it starts with that one." -ForegroundColor White
} else {
    Write-Host "  Launch with " -NoNewline -ForegroundColor White
    Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "in the Hub, or from Steam." -ForegroundColor White
    Write-Host "  Run this installer again to add the other mod as well." -ForegroundColor Gray
}
Write-Host ""
if ($doA) {
    Write-Host "  Recenter: SteamVR recenter, or hold Up + QuickMap + Pause." -ForegroundColor White
    Write-Host "  Vignette on/off: hold Start." -ForegroundColor White
} else {
    Write-Host "  WHAT YOU WILL SEE: a 3D screen, not a VR world. The game" -ForegroundColor White
    Write-Host "  hangs in front of you on several planes at different" -ForegroundColor White
    Write-Host "  distances - foreground closer, background further away - so" -ForegroundColor White
    Write-Host "  it reads with depth. You are not standing in Pharloom, and" -ForegroundColor White
    Write-Host "  you cannot walk or look around in it." -ForegroundColor White
    Write-Host ""
    Write-Host "  Start SteamVR before the game to avoid it potentially" -ForegroundColor White
    Write-Host "  starting sometimes out of focus." -ForegroundColor White
    Write-Host ""
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |  THE KEYS YOU NEED IN GAME                               |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "    F9  " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  overlays on / off" -ForegroundColor White
    Write-Host "    F10 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  settings panel, and re-centres the view" -ForegroundColor White
    Write-Host "    F11 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  VR on / off - the mod's own panel labels it" -ForegroundColor White
    Write-Host "          'VR Enabled (F11)'" -ForegroundColor Gray
    Write-Host "    F12 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  re-initialise OpenVR" -ForegroundColor White
    Write-Host "    Numpad 7/1 and 9/3 move the background and foreground" -ForegroundColor White
    Write-Host "    planes, +/- the width, 5 resets." -ForegroundColor White
    Write-Host ""
    Write-Host "  Nothing in the headset? Open the panel with F10 - it shows" -ForegroundColor White
    Write-Host "  whether OpenVR is connected." -ForegroundColor White
}
Write-Host ""
Write-Host "  See the README for settings, tuning and known issues." -ForegroundColor Gray
Write-Host ""
Write-Host "  Climb high, Hornet. The Citadel waits." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

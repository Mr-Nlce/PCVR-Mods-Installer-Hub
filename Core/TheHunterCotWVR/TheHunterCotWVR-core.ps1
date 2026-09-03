# ============================================================
#  theHunter: Call of the Wild VR - by Vaas993
# ------------------------------------------------------------
#  A SIMPLE FLOW, BUT WITH TWO SPECIAL CASES:
#  1. The mod brings its OWN settings program ("theHunterCotW VR
#     Settings.exe"). Without one run of it nothing is configured -
#     the author makes it step 5 of his own instructions. So we
#     start it ourselves.
#  2. It is built against GAME VERSION 9.2 and identifies the game
#     by fingerprint. On a newer game build it does NOT start at
#     all and does not guess either - that is the author's
#     intention and the most common "nothing happens" case.
#
#  STEAM ONLY. Other editions are not supported.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "theHunter Call of the Wild VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers.
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
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}

$GAME_NAME   = "theHunter: Call of the Wild"
$APP_ID      = "518790"
$GAME_EXE    = "theHunterCotW_F.exe"
$MOD_NAME    = "theHunterCotW-VR"
$MOD_AUTHOR  = "Vaas993"
$REPO        = "vaas993/theHunterCotW-VR"
$RELEASES    = "https://github.com/$REPO/releases"
$SETTINGS_EXE = "theHunterCotW VR Settings.exe"
# Taken in full from the author's uninstall list.
$MOD_FILES   = @("cotwvr.dll", "XINPUT9_1_0.dll", "openxr_loader.dll",
                 "nvngx_dlss.dll", "cotwvr.ini", "cotwvr_launcher.cfg",
                 $SETTINGS_EXE)

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " theHunter: Call of the Wild VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Real stereo VR: the world is drawn once per eye from the" -ForegroundColor White
Write-Host "  game's own camera. Your head turns the view, you can lean" -ForegroundColor White
Write-Host "  and step around inside it, and the weapon has depth." -ForegroundColor White
Write-Host ""
Write-Host "  We start by opening the game flat, so you can set its own" -ForegroundColor White
Write-Host "  video options before installing the VR mod." -ForegroundColor White
Write-Host ""
Write-Host "  One thing to know before that:" -ForegroundColor White
Write-Host "   - " -NoNewline -ForegroundColor White
Write-Host " BUILT FOR GAME UPDATE 9.2 (PERU HUNTING RESERVE) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     The mod checks the game by fingerprint and refuses to" -ForegroundColor White
Write-Host "     guess. On a newer game build it simply does nothing -" -ForegroundColor White
Write-Host "     that is by design, not a fault." -ForegroundColor White
Write-Host ""
Write-Host "  Single player only - do not use it in multiplayer sessions." -ForegroundColor Gray
Write-Host "  No RTX card? You lose nothing: the mod brings its own" -ForegroundColor Gray
Write-Host "  per-eye smoothing for every other card. DLSS is optional." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("theHunterCotW") -ProbeExe $GAME_EXE
if (-not $gameDir) {
    Write-Warn "Could not find the game automatically."
    Write-Host "  Point me at the folder that holds $GAME_EXE, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\theHunterCotW" -ForegroundColor Gray
    $gameDir = (Read-Host "  Game folder").Trim().Trim('"')
}
if (-not $gameDir -or -not (Test-Path -LiteralPath (Join-Path $gameDir $GAME_EXE))) {
    Write-Fail "No $GAME_EXE in that folder - stopping rather than guessing."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameDir"

# Probe write access quietly - the announcement comes where it applies.
$needsAdmin = $false
try {
    $probe = Join-Path $gameDir ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }

# ---- 2. Download ----------------------------------------------
# ---- 2. The game first, in flat mode ---------------------------
# Open the game flat first so the user can set the video options the
# mod requires.
Write-Step 2 5 "The game's own settings - do this first, flat"
Write-Host ""
Write-Host "  The game opens now, WITHOUT VR. In its VIDEO menu set:" -ForegroundColor White
Write-Host ""
Write-Host "        Anti-aliasing    FXAA + TAA " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Display mode     windowed   " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        V-Sync           off        " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Field of view    90         " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Motion blur      off        " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  FIELD OF VIEW 90 IS THE ONE THAT MATTERS MOST - 90 is the" -ForegroundColor Yellow
Write-Host "  game's maximum, and the mod builds its picture around it." -ForegroundColor White
Write-Host ""
Write-Host "  Then CLOSE the game and come back here." -ForegroundColor White
Write-Host ""
if (Read-YesNo "  Open the game now?") {
    try { Start-Process -FilePath (Join-Path $gameDir $GAME_EXE) -WorkingDirectory $gameDir }
    catch { Write-Warn "Could not start it - open it from Steam instead." }
    Pause-User "Press Enter when the game is CLOSED again..." | Out-Null
} else {
    Write-Info "Skipped - but the five settings above still have to be set."
}

Write-Step 3 5 "Downloading $MOD_NAME"

$tmp = Join-Path $env:TEMP ("cotwvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "theHunterCotW-VR.zip"

$url = $null; $tag = "latest"
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
    if (Test-IsPayloadRelease -Release $rel) {
        $pick = Select-PayloadAsset -Assets $rel.assets -PlatformPattern '(?i)cotw|hunter' -MinBytes 100000
        if ($pick -and $pick.browser_download_url) {
            $url = [string]$pick.browser_download_url
            $tag = [string]$rel.tag_name
        }
    }
    if ($url) { Write-OK "Release: $tag" }
} catch { Write-Warn "GitHub could not be reached - trying the direct link." }
if (-not $url) { $url = "https://github.com/$REPO/releases/latest/download/theHunterCotW-VR-v1.1.zip" }

Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
    -ManualUrl $RELEASES `
    -Instructions "Download the theHunterCotW-VR zip from the releases page, save it as '$zip', then choose Retry."
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No archive - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 3. Put the files in place --------------------------------
Write-Step 4 5 "Copying the files next to $GAME_EXE"

$ex = Join-Path $tmp "x"
New-Item -ItemType Directory -Path $ex -Force | Out-Null
[void](Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ex -Label $MOD_NAME)

# The files may sit flat or inside a wrapper folder - so search the
# WHOLE tree for each name.
$allFiles = @(Get-ChildItem -LiteralPath $ex -Recurse -File -Force -ErrorAction SilentlyContinue)
if ($needsAdmin) {
    Pause-User "Press Enter to copy the files into the game folder - UAC required..." | Out-Null
}
$sources = @(); $copyFailed = $false
foreach ($f in $MOD_FILES) {
    $hit = $allFiles | Where-Object { $_.Name -ieq $f } | Select-Object -First 1
    if (-not $hit) { continue }
    $sources += $hit.FullName
    try { Copy-Item -LiteralPath $hit.FullName -Destination (Join-Path $gameDir $f) -Force -ErrorAction Stop }
    catch { $copyFailed = $true }
}
if ($copyFailed -and $sources.Count -gt 0) {
    Write-Warn "Copying into that folder needs administrator rights. Asking for them ..."
    $srcList = ($sources | ForEach-Object { "'" + $_ + "'" }) -join ","
    $ps = "foreach (`$s in @($srcList)) { Copy-Item -LiteralPath `$s -Destination '$gameDir' -Force }"
    try { Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop }
    catch { Write-Warn "The elevated copy was declined or failed." }
}

# The three load-bearing files must be present. cotwvr.ini and
# cotwvr_launcher.cfg are otherwise created on the first run of the
# settings program, nvngx_dlss.dll only on NVIDIA cards.
$core = @("cotwvr.dll", "XINPUT9_1_0.dll", "openxr_loader.dll", $SETTINGS_EXE)
$missing = @($core | Where-Object { -not (Test-Path -LiteralPath (Join-Path $gameDir $_)) })

# BEFORE THE TEMP FOLDER GOES. A scanner usually sweeps a moment after
# the write, so the files can vanish right after this check passes - and
# the recovery needs the archive, which the cleanup below deletes.
if ($missing.Count -eq 0) {
    $avFilesOk = Confirm-PlacedFilesSurvive `
        -Paths @($core | ForEach-Object { Join-Path $gameDir $_ }) `
        -GameDir $gameDir `
        -ArchivePath $zip
    if (-not $avFilesOk) {
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Write-Fail "theHunter VR could not be restored after the antivirus check."
        Pause-User "Press Enter to exit, then run the installer again."
        exit 1
    }
}

try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if ($missing.Count -gt 0) {
    Write-Fail "These files did not arrive:"
    foreach ($m in $missing) { Write-Host "   $m" -ForegroundColor Yellow }
    Write-Host "  Copy every file from the zip by hand into:" -ForegroundColor White
    Write-Host "     $gameDir" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Files are in place."

# Marker for the Hub - into the INSTALLER folder, not the game.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
if (Test-IsTrackableInstalledVersion -Version $tag) {
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {}
}
# ALSO write the durable stamp next to the GAME (2026-08-20).
# The line above lands inside the Hub folder and is gone as
# soon as a new Hub build is dropped in; the scan then finds
# no marker and seeds the CURRENT online tag, swallowing a
# pending update. The game-side stamp survives that.
Save-InstalledStamp -GameDir $gameDir -Version $tag

# ---- 4. The mod's settings program ----------------------------
Write-Step 5 5 "Setting it up"
Write-Host ""
Write-Host "  The mod brings its own settings program, and it has to run" -ForegroundColor White
Write-Host "  once - the copied files alone do not configure anything." -ForegroundColor White
Write-Host ""
Write-Host "  Set these options:" -ForegroundColor White
Write-Host "   a) Field of View > Field of View given to the game: " -NoNewline -ForegroundColor White
Write-Host " 90 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " (the game's maximum)" -ForegroundColor White
Write-Host ""
Write-Host "   b) Picture > Anti-aliasing: you can set it to " -NoNewline -ForegroundColor White
Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "      Other settings can cause a black screen." -ForegroundColor Yellow
Write-Host ""
Write-Host "   c) Head tracking mode: " -NoNewline -ForegroundColor White
Write-Host " 6-DoF " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "      That is the one that lets you lean and step around." -ForegroundColor White
Write-Host ""
Write-Host "   d) Then click " -NoNewline -ForegroundColor White
Write-Host " Save " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " and accept the notice regarding the config file." -ForegroundColor White
Write-Host "      Afterwards close the launcher and press Enter." -ForegroundColor White
Write-Host ""
$settingsPath = Join-Path $gameDir $SETTINGS_EXE
if (Read-YesNo "  Open the settings program now?") {
    try { Start-Process -FilePath $settingsPath -WorkingDirectory $gameDir }
    catch { Write-Warn "Could not start it: $($_.Exception.Message)" }
    # THE GATE SITS HERE SO THE FIVE POINTS ABOVE STAY ON SCREEN for
    # as long as the user needs them. Only after the Enter does the
    # rest of the text follow - otherwise the instructions scroll away
    # while they are still working through them.
    Pause-User "Launcher closed? Press Enter to continue..." | Out-Null
} else {
    Write-Info "You can open it any time - Start in VR in the Hub opens it too."
}

Write-Host ""
Write-Host "  From now on, Start in VR in the Hub opens this program so" -ForegroundColor Gray
Write-Host "  you can change options." -ForegroundColor Gray

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host "  STARTING AND PLAYING" -ForegroundColor Cyan
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Start the game the way you always do - and PUT THE HEADSET" -ForegroundColor White
Write-Host "  ON BEFORE IT FINISHES LOADING." -ForegroundColor Yellow
Write-Host ""
Write-Host "   Insert        open the settings panel in the headset" -ForegroundColor White
Write-Host "   Pause         recentre - use it whenever forward stops" -ForegroundColor White
Write-Host "                 being forward" -ForegroundColor White
Write-Host "   Delete        show the flat game screen, for menus and map" -ForegroundColor White
Write-Host "   Alt (held)    free look - the view turns, the weapon stays" -ForegroundColor White
Write-Host ""
Write-Host "  Everything is rebindable in the panel, and the panel works" -ForegroundColor Gray
Write-Host "  with a gamepad. A gamepad plays better than mouse and" -ForegroundColor Gray
Write-Host "  keyboard here." -ForegroundColor Gray
Write-Host ""
Write-Host "  BLACK IN THE HEADSET, GAME FINE ON THE MONITOR?" -ForegroundColor Yellow
Write-Host "   1. In the mod settings: Picture > Anti-aliasing > Off" -ForegroundColor White
Write-Host "   2. Turn HDR off in Windows: press Win+Alt+B" -ForegroundColor White
Write-Host "      Windows 11: Settings > System > Display > Use HDR" -ForegroundColor Cyan
Write-Host "      Windows 10: Settings > System > Display > Windows HD Color" -ForegroundColor Cyan
Write-Host "  Still black? Check the log:" -ForegroundColor Gray
Write-Host "     %LOCALAPPDATA%\theHunterCotWVR\cotwvr.log" -ForegroundColor Cyan
Write-Host ""
Write-Host "  A bad shot in VR still counts. The elk knows." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

# =============================================================
#  F.E.A.R. VR - thefreemike's build (GOG Platinum Collection)
# =============================================================
# THE SECOND MOD ON THIS TILE. DR-89's build targets the Steam Ultimate
# Shooter Edition; this one targets the GOG F.E.A.R. Platinum Collection
# and is the author's only supported edition.
#
# !!! DISTRIBUTED THROUGH DISCORD ONLY. thefreemike hands the build out
# in his server - there is no direct link, and the file NAME changes with
# every release candidate. So this cannot download anything: the user
# joins, downloads, and drags the ZIP in here, exactly like the AstienVR
# mods.
#
# !!! IT BRINGS ITS OWN INSTALLER. The archive carries
# "Install F.E.A.R. VR.cmd" plus its own uninstaller and four launchers.
# We unpack and hand over rather than copying files ourselves - the
# author's script does the work and knows what it is doing.
#
# Read from the RC4.1 archive, not guessed: 39 entries, 8,619,694 bytes,
# payload\fearvr_bridge.dll is the file no other F.E.A.R. mod ships and
# therefore the Hub's marker for this half of the tile.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME     = "F.E.A.R. VR"
$MOD_AUTHOR   = "thefreemike"
$DISCORD_URL  = "https://discord.com/invite/m5Mju9Kp4"
$ANNOUNCE_URL = "https://discord.com/channels/1537050261208436737/1537050848968839289/1543354834923683871"
$GAME_EXE     = "FEAR.exe"
$MOD_MARKER   = "fearvr_bridge.dll"
$MOD_INSTALL  = "Install F.E.A.R. VR.cmd"
$MOD_UNINST   = "FEAR-VR-Install\Uninstall F.E.A.R. VR.cmd"

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x  " -ForegroundColor Black -BackgroundColor Cyan; Write-Host "" }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-DroppedFile {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Warn "File not found: $p"; continue }
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected: $($Exts -join ', ')."
            continue
        }
        return $p
    }
}

# ---- Find the GOG copy ---------------------------------------
function Get-FearGogFolder {
    foreach ($root in @("C:\GOG Games", "D:\GOG Games", "E:\GOG Games",
                        "C:\Program Files (x86)\GOG Galaxy\Games",
                        "C:\Program Files\GOG Galaxy\Games")) {
        foreach ($folder in @("F.E.A.R. Platinum Collection", "FEAR Platinum Collection",
                              "F.E.A.R. Platinum", "FEAR")) {
            # Concatenate, never Join-Path: a drive that is not there
            # would make Join-Path resolve it and throw.
            $cand = $root.TrimEnd([char[]]"\/") + "\" + $folder
            if (Test-Path -LiteralPath ($cand + "\" + $GAME_EXE)) { return $cand }
        }
    }
    return $null
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " F.E.A.R. VR  -  thefreemike's build (GOG)" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Body inventory with working holsters, physical pickups and" -ForegroundColor White
Write-Host "  weapon swapping, two-handed props, ladder climbing, and a" -ForegroundColor White
Write-Host "  contextual tutorial." -ForegroundColor White
Write-Host ""
Write-Host "  GOG F.E.A.R. PLATINUM COLLECTION ONLY. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The author supports no other edition. For the Steam Ultimate" -ForegroundColor Gray
Write-Host "  Shooter Edition, close this and pick DR-89's build instead." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice

# ---- 1. The game ---------------------------------------------
Write-Step 1 3 "Finding your GOG copy"

$gameDir = Get-FearGogFolder
if (-not $gameDir) {
    Write-Warn "No GOG F.E.A.R. Platinum Collection found automatically."
    Write-Host "  It usually sits in C:\GOG Games\F.E.A.R. Platinum Collection" -ForegroundColor Gray
    Write-Host ""
    $manual = (Read-Host "  Paste the folder that holds FEAR.exe (or Enter to exit)").Trim().Trim('"')
    if (-not $manual -or -not (Test-Path -LiteralPath ($manual.TrimEnd([char[]]"\/") + "\" + $GAME_EXE))) {
        Write-Fail "No usable game folder - nothing was changed."
        Pause-User "Press Enter to exit."
        exit 1
    }
    $gameDir = $manual.TrimEnd([char[]]"\/")
}
Write-OK "Game folder: $gameDir"

# ---- 2. The archive ------------------------------------------
Write-Step 2 3 "Getting the build"

Write-Host "  This build is handed out in thefreemike's Discord, and only" -ForegroundColor White
Write-Host "  there. Join, open the announcements channel, scroll to the" -ForegroundColor White
Write-Host "  bottom for the newest release candidate, and download it." -ForegroundColor White
Write-Host ""
Write-Host "  There is no direct link and nothing to automate here - the" -ForegroundColor Gray
Write-Host "  author shares it personally and asks that it stays in the" -ForegroundColor Gray
Write-Host "  server." -ForegroundColor Gray
Write-Host ""

# !!! NO SEARCH IN DOWNLOADS. The file name carries a build stamp that
# changes every release, so nothing here can identify it reliably -
# and offering a wrong archive would install an old build over a new
# one. Drag-and-drop only, which is what the author's own instructions
# say anyway.
# !!! TWO STEPS, NOT ONE. The invite only gets you into the server - the
# file is in the announcements channel, and finding it by hand means
# scrolling past two weeks of release notes. So: invite first, then a
# direct link to the channel once the user is a member.
Pause-User "Press Enter to open the Discord invite..."
try { Start-Process $DISCORD_URL } catch { Write-Warn "Open manually: $DISCORD_URL" }
Write-Host ""
Write-Host "  Accept the invite and come back here." -ForegroundColor White
Write-Host ""
Pause-User "Done? Press Enter to jump straight to the announcements channel..."
try { Start-Process $ANNOUNCE_URL } catch { Write-Warn "Open manually: $ANNOUNCE_URL" }
Write-Host ""
Write-Host "  Scroll all the way DOWN - the newest release candidate is the" -ForegroundColor White
Write-Host "  last thing posted." -ForegroundColor White
Write-Host ""
Write-Do "Download it, then drag the ZIP in below."
$zip = Get-DroppedFile -Label "the F.E.A.R. VR ZIP" -Exts @(".zip")
if (-not $zip) {
    Write-Info "Nothing was changed."
    Pause-User "Press Enter to exit."
    exit 0
}
Write-OK "Archive: $zip"

# ---- 3. Unpack and hand over ---------------------------------
Write-Step 3 3 "Installing"

$tmp = Join-PathLexical $env:TEMP ("FearVRGog_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$ex = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label "$MOD_NAME ($MOD_AUTHOR)"
if ([string]$ex -eq "quit") {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The installer sits at the archive root, but a re-zip can nest it.
$probe = Get-ChildItem -LiteralPath $tmp -Filter $MOD_INSTALL -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $probe) {
    Write-Fail "'$MOD_INSTALL' was not in that archive - is it the right download?"
    Write-Info "Expected a F.E.A.R. VR release candidate from the Discord."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$srcRoot = Split-Path -Parent $probe.FullName
Write-OK "Found the author's installer."

# !!! UPDATING MEANS UNINSTALLING FIRST. The author says so in every
# release note: run his uninstaller before laying a new RC down, or the
# two builds mix. Saves and profile survive it.
$existing = Join-PathLexical $gameDir $MOD_UNINST
if (Test-Path -LiteralPath $existing) {
    Write-Host ""
    Write-Warn "An older F.E.A.R. VR build is already installed here."
    Write-Host "  The author asks for the old one to be removed before a new" -ForegroundColor White
    Write-Host "  RC goes down. Your campaign saves and player profile stay." -ForegroundColor White
    Write-Host ""
    $un = ""
    for ($k = 1; $k -le 20; $k++) {
        $un = ("" + (Read-Host "  Run his uninstaller now? [y/n]")).Trim().ToLower()
        if ($un -in @("y","n","yes","no")) { break }
        Write-Host "  Please answer y or n." -ForegroundColor Yellow
    }
    if ($un -in @("y","yes")) {
        try {
            Start-Process -FilePath $existing -WorkingDirectory (Split-Path -Parent $existing) -Wait
            Write-OK "Old build removed."
        } catch { Write-Warn "Could not run it: $($_.Exception.Message)" }
    } else {
        Write-Warn "Carrying on without removing it - the author does not recommend this."
    }
}

Write-Host ""
Write-Info "Handing over to the author's installer..."
Write-Host "  It asks for your game folder - give it:" -ForegroundColor White
Write-Host "    $gameDir" -ForegroundColor Cyan
Write-Host ""
try {
    Start-Process -FilePath (Join-PathLexical $srcRoot $MOD_INSTALL) -WorkingDirectory $srcRoot -Wait
} catch {
    Write-Fail "Could not start his installer: $($_.Exception.Message)"
    Write-Do "Run it by hand: $srcRoot\$MOD_INSTALL"
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- Did it land? --------------------------------------------
$markerPath = Join-PathLexical $gameDir $MOD_MARKER
if (Test-Path -LiteralPath $markerPath) {
    Write-OK "$MOD_MARKER is in place - the mod is installed."
    try {
        Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force
        Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path_gog") -Value $gameDir -Encoding UTF8 -Force
    } catch {}
    [void](Confirm-PlacedFilesSurvive -Paths @($markerPath) -GameDir $gameDir -ArchivePath $zip)
} else {
    Write-Warn "$MOD_MARKER was not found in $gameDir"
    Write-Host "  His installer may have targeted a different folder, or it" -ForegroundColor Gray
    Write-Host "  was cancelled. Run it again and point it at the folder above." -ForegroundColor Gray
}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- What now ------------------------------------------------
Write-Host ""
Write-Host "  LAUNCHING " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "  The mod brings its own launchers into the game folder:" -ForegroundColor White
Write-Host "    Launch F.E.A.R. VR - SteamVR.cmd" -ForegroundColor Cyan
Write-Host "    Launch F.E.A.R. VR - Meta Link.cmd" -ForegroundColor Cyan
Write-Host "    Launch F.E.A.R. VR - Menu.cmd" -ForegroundColor Gray
Write-Host ""
Write-Host "  SteamVR needs the BETA, 2.17.2 or newer, for its 32-bit" -ForegroundColor White
Write-Host "  OpenXR runtime. Quest 3 is the author's validation device;" -ForegroundColor White
Write-Host "  other headsets may work but are untested." -ForegroundColor White
Write-Host ""
Write-Host "  Private beta - report problems in his Discord, not to us." -ForegroundColor DarkGray
Write-Host ""
Write-OK "$MOD_NAME ($MOD_AUTHOR) done."
Write-Host ""
Pause-User "Press Enter to exit"

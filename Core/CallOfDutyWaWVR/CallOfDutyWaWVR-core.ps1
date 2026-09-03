# ============================================================
#  Call of Duty: World at War VR - World War VR by RyanCraighead
# ------------------------------------------------------------
#  SPECIAL CASE: the mod puts NOTHING in the game folder. It is a
#  STANDALONE PROGRAM with its own setup (Inno, evidenced by
#  unins000.exe in the target folder) and installs to
#     %LOCALAPPDATA%\Programs\World War VR\
#  From there its own launcher starts the game. The game folder is
#  only SEARCHED for, never modified - hence VrInstallRoot in the
#  catalog instead of a ModFile in the game folder, and LaunchExe
#  points at WorldWarVR.exe (the lesson from theHunter: when a mod
#  brings its own launcher, THAT belongs in LaunchExe).
#
#  TWO THINGS THE AUTHOR EXPLICITLY REQUIRES:
#   1. The launcher needs ADMIN RIGHTS.
#   2. The game is started THROUGH THE LAUNCHER, never directly.
#
#  The asset is called the same in EVERY release
#  (WorldWarVR-Setup.exe) and is an EXE - Select-PayloadAsset only
#  looks for .zip and does NOT find it. So the asset is picked out of
#  the API by hand here. All releases are prereleases, so the query
#  has to include them.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Call of Duty World at War VR Installer"
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
    # COUNTED, NOT CONDITIONAL, and ("" + ...) catches $null: with no
    # console Read-Host returns $null, .Trim() on it throws, and a
    # while($true) prompt spins forever. Both reproduced on real
    # PowerShell 7.4.
    for ($i = 0; $i -lt 20; $i++) {
        Write-Host ""
        $a = ("" + (Read-Host " $Prompt [Y/N]")).Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
    Write-Warn "No usable answer - assuming No."
    return $false
}

$GAME_NAME   = "Call of Duty: World at War"
$APP_ID      = "10090"
$GAME_EXE    = "CoDWaW.exe"
$MOD_NAME    = "World War VR"
$MOD_AUTHOR  = "RyanCraighead"
$REPO        = "RyanCraighead/WorldWarVR-Releases"
$RELEASES    = "https://github.com/$REPO/releases"
$ASSET       = "WorldWarVR-Setup.exe"
$MOD_ROOT    = Join-Path $env:LOCALAPPDATA "Programs\World War VR"
$MOD_EXE     = Join-Path $MOD_ROOT "WorldWarVR.exe"
$GAME_EXE_MP = "CoDWaWmp.exe"

# ============================================================
#  BUILD DETECTION - international uncut vs German censored
# ============================================================
#  WHY THIS IS NEEDED: the German edition is censored, has NO
#  zombies mode - the very mode the VR author fully supports - and
#  its executables are DIFFERENT files. The launcher only knows the
#  international ones and rejects these with "The game executables
#  are from an unsupported build". That looks like a broken game and
#  is not one.
#
#  DETECTION IS BY SHA-256, NOT BY VERSION NUMBER: both editions
#  report 1.7x and even carry the same compile timestamp
#  (2009-10-29 23:03:34). Only the content differs - the German
#  single-player exe is 7,310,304 bytes, the international one
#  5,902,336.
# ============================================================
$HASH_UNCUT_SP = "732900d158982c33e3121f0b86d22230be79839bbcbfe3bdfc1238f408a7d64d"
$HASH_UNCUT_MP = "7d0b518a4bd267ffdb6d0203ad8f3721603b172ac13ba2abcdb32584f759d36c"
$HASH_CUT_SP   = "f751d06799ed27f30c61d157ed292aa3adce73fbf9c30b92a5657b29624e8b31"
$HASH_CUT_MP   = "b0e265592901cd248b7358e8b37c8c1b5c85c6b24fb3cb378f62d601378e4fae"

$UCP_PAGE       = "https://steamcommunity.com/sharedfiles/filedetails/?id=570024548"
$UCP_SETUP      = "CallOfDutyWaW_UCPV4.exe"
$DEPOT_APPID    = "10090"
$DEPOT_DEPOTID  = "10091"
$DEPOT_MANIFEST = "5566849738478017518"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

function Get-Sha256 { param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch { return $null }
}

# Returns: "uncut", "cut", "unknown" or "missing"
function Get-WaWEdition { param([string]$Dir)
    $sp = Get-Sha256 (Join-Path $Dir $GAME_EXE)
    $mp = Get-Sha256 (Join-Path $Dir $GAME_EXE_MP)
    if (-not $sp) { return "missing" }
    if ($sp -eq $HASH_UNCUT_SP) { return "uncut" }
    if ($sp -eq $HASH_CUT_SP)   { return "cut" }
    # The single-player exe decides; the multiplayer one is only
    # consulted when the first yields nothing known.
    if ($mp -eq $HASH_UNCUT_MP) { return "uncut" }
    if ($mp -eq $HASH_CUT_MP)   { return "cut" }
    return "unknown"
}


# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Call of Duty: World at War VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Stereo OpenXR rendering, 6DOF head tracking and motion" -ForegroundColor White
Write-Host "  controllers: the right hand aims the weapon you can see," -ForegroundColor White
Write-Host "  grenades are cooked in your fist, and a fast outward swing" -ForegroundColor White
Write-Host "  is a melee. Menus float on a panel you point at." -ForegroundColor White
Write-Host ""
Write-Host "  ZOMBIES IS THE MODE TO PLAY. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  It is the author's primary supported mode. Campaign and" -ForegroundColor White
Write-Host "  local multiplayer are experimental - the campaign can stall" -ForegroundColor White
Write-Host "  around the second mission. Online multiplayer is not" -ForegroundColor White
Write-Host "  supported at all." -ForegroundColor White
Write-Host ""
Write-Host "  This mod does not touch your game folder. It installs as its" -ForegroundColor Gray
Write-Host "  own program and launches the game for you." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
# Only searched for, never touched - the launcher asks for it itself,
# and we can name the path if it cannot find it.
Write-Step 1 4 "Locating $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID `
             -SteamFolderNames @("Call of Duty World at War") -ProbeExe $GAME_EXE
if (-not $gameDir) {
    foreach ($c in @("C:\Program Files (x86)\Activision\Call of Duty - World at War",
                     "C:\Program Files\Activision\Call of Duty - World at War")) {
        if (Test-LiteralPathSafe -Path (Join-PathLexical $c $GAME_EXE) -PathType Leaf) { $gameDir = $c; break }
    }
}
if ($gameDir) {
    Write-OK "Game folder: $gameDir"
    Write-Info "Nothing is written there - the launcher only reads it."
} else {
    Write-Warn "Could not find the game automatically."
    Write-Host "  That is not a problem: the launcher has a Browse button and" -ForegroundColor White
    Write-Host "  asks for the folder itself. It is the one holding $GAME_EXE." -ForegroundColor White
}

# ---- 2. Which edition of the game is this? --------------------
Write-Step 2 4 "Checking which edition of the game you have"

$edition = "unknown"
if ($gameDir) { $edition = Get-WaWEdition -Dir $gameDir }

switch ($edition) {
    "uncut" {
        Write-OK "International uncut version - this is the one the mod expects."
        Write-Info "Zombies is present. Nothing to do here."
    }
    "cut" {
        Write-Warn "German cut version detected - ZOMBIES MODE IS MISSING."
        Write-Host "  This edition was censored for the German market. It is a" -ForegroundColor White
        Write-Host "  different build with different executables, and the VR" -ForegroundColor White
        Write-Host "  launcher rejects it with 'unsupported build'." -ForegroundColor White
        Write-Host "  It also has no Zombies - the one mode the VR author fully" -ForegroundColor White
        Write-Host "  supports." -ForegroundColor White
    }
    "missing" {
        Write-Warn "Could not read $GAME_EXE, so the edition is unknown."
    }
    default {
        Write-Warn "Unknown build - neither the international nor the German one."
        Write-Info "Modded or patched executables look like this too."
    }
}

if ($edition -eq "cut") {
    Write-Host ""
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  THERE IS A LEGAL WAY TO GET THE UNCUT VERSION" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Two steps, and you already own everything involved:" -ForegroundColor White
    Write-Host "    1. A community uncut patch restores the cut content." -ForegroundColor White
    Write-Host "    2. Steam hands you the original executables from a depot" -ForegroundColor White
    Write-Host "       of the game you already bought." -ForegroundColor White
    Write-Host ""
    Write-Host "  Afterwards the VR mod accepts the game and Zombies works." -ForegroundColor White
    Write-Host ""

    if (Read-YesNo "Walk me through it now?") {

        # --- 2a) uncut patch: too involved for the installer ------
        # 17 RAR parts that have to be extracted, then a setup of its
        # own. We do NOT automate that - we give the instructions and
        # open the page.
        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host "   PART 1 OF 2 - the uncut patch" -ForegroundColor Yellow
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  The page opens in your browser. There:" -ForegroundColor White
        Write-Host "    1. Download all 17 .rar parts into ONE folder" -ForegroundColor White
        Write-Host "    2. Right-click the FIRST part and extract with WinRAR" -ForegroundColor White
        Write-Host "       or 7-Zip - the other 16 are pulled in automatically" -ForegroundColor White
        Write-Host "    3. Run " -NoNewline -ForegroundColor White
        Write-Host $UCP_SETUP -NoNewline -ForegroundColor Yellow
        Write-Host " from the extracted folder" -ForegroundColor White
        Write-Host "    4. It finds your game folder by itself and installs" -ForegroundColor White
        Write-Host "       the uncut files" -ForegroundColor White
        Write-Host ""
        Write-Host "  This takes a while. Come back here when it is done -" -ForegroundColor Gray
        Write-Host "  this window will wait." -ForegroundColor Gray
        Write-Host ""
        Pause-User "Press Enter to open the patch page..."
        try { Start-Process $UCP_PAGE } catch { Write-Warn "Could not open the browser. The address is: $UCP_PAGE" }
        Write-Host ""
        Pause-User "Press Enter once the uncut patch is installed..."

        # --- 2b) original executables from the Steam depot --------
        # The proven route from PEAK and Bendy: command on the
        # clipboard, open the Steam console, the user pastes.
        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host "   PART 2 OF 2 - the original executables" -ForegroundColor Yellow
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Steam can hand you the international build of a game you" -ForegroundColor White
        Write-Host "  already own. The command is copied to your clipboard:" -ForegroundColor White
        Write-Host ""
        Write-Host "    $DEPOT_COMMAND" -ForegroundColor Yellow
        Write-Host ""
        $clip = $false
        try { Set-Clipboard -Value $DEPOT_COMMAND; $clip = $true } catch {}
        if ($clip) { Write-OK "Command copied to your clipboard." }
        else       { Write-Warn "Clipboard not available - type the command by hand." }
        Write-Host ""
        Write-Host "  In the Steam Console: click the input field, paste with" -ForegroundColor White
        Write-Host "  Ctrl+V, press Enter, and wait for the download to finish." -ForegroundColor White
        Write-Host ""
        if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
            Write-Host "  (i) Virtual Desktop users: the console may not open from" -ForegroundColor DarkGray
            Write-Host "      inside a streaming session. Open it by hand instead:" -ForegroundColor DarkGray
            Write-Host "      Steam menu bar - View - Console." -ForegroundColor DarkGray
            Write-Host ""
        }
        # !!! LOOK BEFORE ASKING (2026-08-29). Steam keeps a finished
        # depot under steamapps\content, so a second run - or a run after
        # a crash - already has the files. Asking first and probing only
        # afterwards means telling the user to download it all again.
        $script:PreFoundDepot = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE
        if ($script:PreFoundDepot) {
            Write-OK "The depot is already downloaded: $script:PreFoundDepot"
            Write-Info "Skipping the download."
        }
        if (-not $script:PreFoundDepot) {
        Pause-User "Press Enter to open the Steam Console..."
        # Both protocol addresses: depending on the Steam build only
        # one works.
        foreach ($cu in @("steam://open/console", "steam://nav/console")) {
            try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
        }
        Write-Host ""
        Pause-User "Press Enter once the depot download has finished..."
        }

        # --- 2c) copy the depot content into the game -------------
        # THIS we take on, because we know the path and it would
        # otherwise be the most common point of failure.
        Write-Host ""
        Write-Info "Looking for the downloaded depot ..."
        $depotDir = $null
        if ($script:PreFoundDepot) { $depotDir = $script:PreFoundDepot }
        if (-not $depotDir) { $depotDir = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE }
        if (-not $depotDir) {
            Write-Warn "The depot folder was not where it usually is."
            Write-Host "  It should be here:" -ForegroundColor White
            Write-Host "    <Steam>\steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID" -ForegroundColor Gray
            Write-Host "  Drag that folder in here, or leave empty to skip." -ForegroundColor White
            $raw = ("" + (Read-Host "  Depot folder")).Trim().Trim('"').TrimEnd('\')
            if ($raw -and (Test-Path -LiteralPath (Join-PathLexical $raw $GAME_EXE))) { $depotDir = $raw }
        }

        if ($depotDir -and $gameDir) {
            Write-Info "Copying the depot files over your game folder ..."
            try {
                Copy-Item -Path (Join-Path $depotDir "*") -Destination $gameDir -Recurse -Force -ErrorAction Stop
                Write-OK "Copied."
            } catch {
                Write-Fail "Copying failed: $($_.Exception.Message)"
                Write-Host "  Copy the CONTENTS of the depot folder into your game" -ForegroundColor White
                Write-Host "  folder by hand, overwriting when asked." -ForegroundColor White
            }
            # --- Cross-check: did it take effect? ----------------
            $edition = Get-WaWEdition -Dir $gameDir
            Write-Host ""
            if ($edition -eq "uncut") {
                Write-OK "Verified: the game is now the international uncut version."
                Write-Info "Zombies is available and the VR launcher will accept it."
            } else {
                Write-Warn "The executables still do not match the international build."
                Write-Host "  The VR launcher will most likely still refuse. Check that" -ForegroundColor White
                Write-Host "  the depot download really finished and that you copied" -ForegroundColor White
                Write-Host "  into the right folder." -ForegroundColor White
            }
        } elseif (-not $gameDir) {
            Write-Warn "Without a known game folder the files cannot be copied here."
        }
    } else {
        Write-Info "Skipped. The VR launcher will refuse this build - come back"
        Write-Info "and run this installer again when you want to do it."
    }
}

# ---- 2. Fetch the setup and run it ----------------------------
Write-Step 3 4 "Downloading and running the $MOD_NAME setup"
Write-Host "  About 60 MB. It brings its own installer and Start Menu entry." -ForegroundColor Gray

$tmp = Join-Path $env:TEMP ("wwvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$exe = Join-Path $tmp $ASSET

# All releases are prereleases, so query the list and take the newest
# - /releases/latest returns nothing when there are only prereleases.
$url = $null; $tag = "latest"
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
    $pick = @($rel) | Where-Object { -not $_.draft } | Select-Object -First 1
    if ($pick) {
        $a = @($pick.assets) | Where-Object { $_.name -ieq $ASSET } | Select-Object -First 1
        if ($a -and $a.browser_download_url) {
            $url = [string]$a.browser_download_url
            $tag = [string]$pick.tag_name
            # Remember name AND size of the CURRENT release - so an
            # older file in the downloads folder no longer gets through.
            $assetName = [string]$a.name; $assetSize = [long]$a.size
        }
    }
    if ($url) { Write-OK "Release: $tag" }
} catch { Write-Warn "GitHub could not be reached - trying the direct link." }
if (-not $url) { $url = "https://github.com/$REPO/releases/latest/download/$ASSET" }

$have = Find-PredownloadedFile -Patterns @("WorldWarVR-Setup*.exe") -Label "the World War VR setup" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $exe = $have
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $exe -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download $ASSET from the releases page, save it as '$exe', then choose Retry."
}
if (-not (Test-Path -LiteralPath $exe)) {
    Write-Fail "No setup file - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

Write-Host ""
Write-Host "  The setup is not code-signed, so Windows may show a" -ForegroundColor White
Write-Host "  SmartScreen warning - choose More info, then Run anyway." -ForegroundColor White
Pause-User "Press Enter to run the setup - UAC required..." | Out-Null
try { Start-Process -FilePath $exe -Wait -Verb RunAs -ErrorAction Stop }
catch { Write-Warn "The setup was declined or could not start: $($_.Exception.Message)" }
try { if ($exe -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

if (-not (Test-Path -LiteralPath $MOD_EXE)) {
    Write-Fail "WorldWarVR.exe is not in $MOD_ROOT - the setup did not finish."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Installed: $MOD_ROOT"

# Marker for the Hub - into the INSTALLER folder.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $MOD_ROOT -Encoding UTF8 -Force } catch {}
if (Test-IsTrackableInstalledVersion -Version $tag) {
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {}
}
# ALSO write the durable stamp next to the GAME (2026-08-20).
# The line above lands inside the Hub folder and is gone as
# soon as a new Hub build is dropped in; the scan then finds
# no marker and seeds the CURRENT online tag, swallowing a
# pending update. The game-side stamp survives that.
Save-InstalledStamp -GameDir @($MOD_ROOT, $gameDir) -Version $tag

# ---- 3. Playing -----------------------------------------------
Write-Step 4 4 "Playing"
Write-Host ""
Write-Host "  ALWAYS START THROUGH THE LAUNCHER, NOT THE GAME." -ForegroundColor Yellow
Write-Host "  Start in VR in the Hub opens it, and so does the Start Menu" -ForegroundColor White
Write-Host "  entry. It needs " -NoNewline -ForegroundColor White
Write-Host " Run as administrator " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " every time." -ForegroundColor White
Write-Host ""
Write-Host "  In the launcher: pick the launch target (Zombies is the one" -ForegroundColor White
Write-Host "  that works), pick a quality preset, then Launch in VR. Your" -ForegroundColor White
Write-Host "  choices are remembered, so this is a one-time setup." -ForegroundColor White
Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " QUEST OVER AIR LINK NEEDS ONE EXTRA SWITCH" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Virtual Desktop works out of the box on Quest 2 and 3, and is" -ForegroundColor White
Write-Host "  the author's recommendation. Over Air Link instead, turn on" -ForegroundColor White
Write-Host "  the SteamVR compatibility option in the launcher - and Steam" -ForegroundColor White
Write-Host "  has to be on the SteamVR Beta branch. Steam Link does not" -ForegroundColor White
Write-Host "  work at all." -ForegroundColor White
Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " CONTROLS" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "   Right controller   aims the weapon you can see" -ForegroundColor White
Write-Host "   Right trigger      fire        Left trigger   reload" -ForegroundColor White
Write-Host "   Right grip hold    cook a frag grenade, release to throw" -ForegroundColor White
Write-Host "   Left grip hold     cook the tactical grenade" -ForegroundColor White
Write-Host "   Left stick         move   (click: sprint)" -ForegroundColor White
Write-Host "   Right stick L/R    snap turn" -ForegroundColor White
Write-Host "   A jump   B crouch   X use   Y next weapon" -ForegroundColor White
Write-Host "   Right stick click  melee - or swing the controller outward" -ForegroundColor White
Write-Host "   Left menu button   pause  (hold 1s: recentre)" -ForegroundColor White
Write-Host ""
Write-Host "  There is no crosshair on purpose - aim along the barrel." -ForegroundColor Gray
Write-Host ""
Write-Host "  The war is loud in here. Duck anyway." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

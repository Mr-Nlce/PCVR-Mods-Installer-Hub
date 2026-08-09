# ============================================================
#  World of Warcraft VR Mod Installer
# ============================================================
#  WoVR by Marulu (the XIVR / WoVR dev) is distributed only on
#  the Flat2VR Discord. The mod ships in three flavours:
#
#    1. VR UI    - the dedicated VR interface (recommended)
#    2. Flat UI  - the classic flat UI, for AMD users etc.
#    3. KB & M   - keyboard + mouse mode, no motion controls
#
#  The user picks one, drops the .7z onto this window, and the
#  installer cleans the game folder, extracts the chosen build,
#  and (optionally) runs the 4 GB RAM patch.
#
#  Target client: 3.3.5a build 12340 (WotLK 2010), US/EU.
# ============================================================

$Host.UI.RawUI.WindowTitle = "World of Warcraft VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME = "World of Warcraft"
$GAME_EXE  = "Wow.exe"

# Flat2VR Discord (server id 747967102895390741). The invite is
# also used by GTFO VR / other Flat2VR mods on the same server.
$DISCORD_INVITE_URL   = "https://discord.gg/uAeQkYBM4n"
$DISCORD_TOGGLE_URL   = "https://discord.com/channels/747967102895390741/1228183999650730065/1228193071804452938"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/747967102895390741/1232269928287961151/1245333806559531018"

# 4 GB patch by NTCore - raises Wow.exe from 2 GB to 4 GB user
# address space. Helps with the "half the world is black" symptom.
$PATCH_4GB_URL = "https://ntcore.com/files/4gb_patch.zip"

# -------------------------------------------------------
#  Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "   World of Warcraft - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   WoVR by Marulu (Flat2VR)" -ForegroundColor Gray
    Write-Host "   Target client: 3.3.5a build 12340 (WotLK)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
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

function Find-7Zip {
    foreach ($c in @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )) { if (Test-Path $c) { return $c } }
    return $null
}

# WoW 3.3.5a is not a Steam game - it's an old Blizzard install
# that typically lives in Program Files (x86) or directly under
# C:\Games / C:\. We probe the common locations; if none match
# the user types the path by hand.
function Find-WoWFolder {
    $candidates = @(
        "C:\Program Files (x86)\World of Warcraft",
        "C:\Program Files\World of Warcraft",
        "C:\World of Warcraft",
        "C:\Games\World of Warcraft",
        "D:\World of Warcraft",
        "D:\Games\World of Warcraft",
        "E:\World of Warcraft",
        "E:\Games\World of Warcraft"
    )
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c $GAME_EXE)) { return $c }
    }
    return $null
}

# -------------------------------------------------------
#  Pre-flight: 7-Zip required
# -------------------------------------------------------
Write-Header

$sevenZip = Find-7Zip
if (-not $sevenZip) {
    Write-Fail "7-Zip not installed."
    Write-Host ""
    Write-Host "  This installer needs 7-Zip's command-line tool to extract" -ForegroundColor Yellow
    Write-Host "  the WoVR .7z archives. Install it from:" -ForegroundColor Yellow
    Write-Host "    https://www.7-zip.org" -ForegroundColor White
    Pause-User "Press Enter to exit..."
    exit 1
}
Write-OK "7-Zip detected: $sevenZip"

# -------------------------------------------------------
#  Mode select: Full Install vs Update / Switch UI
# -------------------------------------------------------
Write-Host ""
Write-Host "  This installer sets up World of Warcraft VR (WoVR) by Marulu," -ForegroundColor White
Write-Host "  a VR mod for the 3.3.5a (WotLK) WoW client." -ForegroundColor Gray
Write-Host ""
Write-Host "  Choose what to do:" -ForegroundColor White
Write-Host ""
Write-Host "    [1] Full Install    - clean the WoW folder, install WoVR," -ForegroundColor White
Write-Host "                          optionally apply the 4 GB RAM patch" -ForegroundColor Gray
Write-Host "    [2] Update / Switch - drop a newer .7z or switch UI mode" -ForegroundColor White
Write-Host "                          (skips the cleaner and the patch)" -ForegroundColor Gray
Write-Host ""

$modeChoice = ""
while ($modeChoice -notin @("1","2")) {
    $modeChoice = (Read-Host "  Your choice (1/2)").Trim()
}
$updateOnly = ($modeChoice -eq "2")
if ($updateOnly) {
    $totalSteps = 3
    Write-OK "Update mode - cleaner + 4 GB patch skipped."
} else {
    $totalSteps = 6
}

# -------------------------------------------------------
#  STEP 1: Locate WoW 3.3.5a install
# -------------------------------------------------------
Write-Step 1 $totalSteps "Locating World of Warcraft"

$gamePath = Find-WoWFolder
if (-not $gamePath) {
    Write-Warn "World of Warcraft was not found in the usual locations."
    Write-Host "  Enter the path to your WoW 3.3.5a folder manually." -ForegroundColor White
    Write-Host "  This is the folder that contains Wow.exe." -ForegroundColor Gray
    Write-Host "  Example: C:\Program Files (x86)\World of Warcraft" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  WoW path").Trim().Trim('"')
        if (Test-Path (Join-Path $rawInput $GAME_EXE)) {
            $gamePath = $rawInput
            Write-OK "WoW path set: $gamePath"
        } else {
            Write-Fail "Wow.exe not found in: $rawInput"
        }
    }
} else {
    Write-OK "World of Warcraft found: $gamePath"
}

# Sanity check the client build via the version file if present.
# This is informational only - the cleaner / extract steps run
# regardless, so a missing or differently-named build file does
# not block the install.
$buildInfo = Join-Path $gamePath ".build.info"
if (Test-Path $buildInfo) {
    Write-Info "A .build.info was found - this looks like a modern retail"
    Write-Info "client, NOT the 3.3.5a WotLK build the mod requires."
    Write-Warn "WoVR only supports 3.3.5a build 12340 (the 2010 client)."
    Write-Host ""
    Write-Host "  Continue anyway? The installer will run but the mod" -ForegroundColor Yellow
    Write-Host "  almost certainly will not work on this client." -ForegroundColor Yellow
    $cont = (Read-Host "  Continue? (Y/N)").Trim()
    if ($cont -notin @("y","Y")) {
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# ============================================================
#  FULL INSTALL: cleaner first
# ============================================================
if (-not $updateOnly) {
    Write-Step 2 $totalSteps "Cleaning the WoW folder"

    Write-Host "  WoVR requires a clean WoW folder. The Hub-bundled cleaner" -ForegroundColor White
    Write-Host "  deletes the launcher / patcher / cache / AddOns etc., so" -ForegroundColor White
    Write-Host "  only the bare game files remain." -ForegroundColor White
    Write-Host ""
    Write-Host "  This is destructive: existing addons and saved variables" -ForegroundColor Yellow
    Write-Host "  in Interface\AddOns and WTF will be deleted." -ForegroundColor Yellow
    Write-Host ""
    $confirmClean = (Read-Host "  Run the cleaner now? (Y/N)").Trim()
    if ($confirmClean -notin @("y","Y")) {
        Write-Warn "Cleaner skipped - the mod may not work properly without it."
    } else {
        $cleanerSrc = Join-Path $PSScriptRoot "WoVR-Cleaner.bat"
        $cleanerDst = Join-Path $gamePath "WoVR-Cleaner.bat"
        try {
            Copy-Item -Path $cleanerSrc -Destination $cleanerDst -Force
            Write-OK "Cleaner copied into the WoW folder."
        } catch {
            Write-Fail "Could not copy cleaner: $_"
            Pause-User "Press Enter to exit..."
            exit 1
        }
        # The cleaner is interactive (waits for a key press) and
        # ends by self-deleting. Run it inside its own cmd window
        # in the WoW folder, then wait for it to finish.
        Write-Host ""
        Write-Host "  Running WoVR-Cleaner.bat in the WoW folder ..." -ForegroundColor White
        Write-Host "  A console window will open - press any key when it" -ForegroundColor Gray
        Write-Host "  asks, then wait for it to close." -ForegroundColor Gray
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cleanerDst`"" -WorkingDirectory $gamePath -Wait
            Write-OK "Cleaner finished."
        } catch {
            Write-Warn "Cleaner could not be launched automatically: $_"
            Write-Info "Run it manually from: $cleanerDst"
            Pause-User "Press Enter once the cleaner is done..."
        }
    }
}

# ============================================================
#  Pick the UI variant + download
# ============================================================
$installStep = if ($updateOnly) { 2 } else { 3 }
Write-Step $installStep $totalSteps "Choosing the WoVR UI variant"

Write-Host "  WoVR ships in three flavours. Pick the one you want:" -ForegroundColor White
Write-Host ""
Write-Host "    [1] VR UI    - dedicated VR interface (recommended)" -ForegroundColor White
Write-Host "                   NOT compatible with AMD graphics cards" -ForegroundColor Gray
Write-Host "    [2] Flat UI  - classic flat UI in VR (use this on AMD)" -ForegroundColor White
Write-Host "    [3] KB & M   - keyboard + mouse mode, no motion controls" -ForegroundColor White
Write-Host "                   No head-tracked locomotion in this mode" -ForegroundColor Gray
Write-Host ""

$uiChoice = ""
while ($uiChoice -notin @("1","2","3")) {
    $uiChoice = (Read-Host "  Your choice (1/2/3)").Trim()
}
switch ($uiChoice) {
    "1" { $uiLabel = "VR UI";   $uiFile = "wovr-v7-vrui.7z" }
    "2" { $uiLabel = "Flat UI"; $uiFile = "wovr-v7-flatui.7z" }
    "3" { $uiLabel = "KB & M";  $uiFile = "wovr-v7-mkb.7z" }
}
Write-OK "Variant: $uiLabel  ($uiFile)"

# Discord walkthrough. The Flat2VR Discord locks the mod channel
# behind a Toggle-Channels step on the announcements post, so we
# open that first, then the download post itself. The user has
# to grab the archive in their browser - we cannot fetch it from
# Discord without an auth token.
Write-Host ""
Write-Host "  WoVR is only distributed on the Flat2VR Discord." -ForegroundColor White
Write-Host ""
Write-Host "  [S] Show a short walkthrough of what happens first, or just press Enter to start." -ForegroundColor DarkGray
$wt = (Read-Host "  Choice (S = walkthrough, Enter = start)").Trim()
if ($wt -in @("s","S")) {
  Write-Host ""
  Write-Host "  Short walkthrough - what the installer does WITH you:" -ForegroundColor White
  Write-Host "    1. Opens the Flat2VR Discord invite       - you click Accept Invite" -ForegroundColor Gray
  Write-Host "    2. Opens the WoVR announcement post       - you click Toggle Channels" -ForegroundColor Gray
  Write-Host "    3. Opens the mod download post            - you download $uiFile" -ForegroundColor Gray
  Write-Host "    4. You drag the .7z into this window - the installer does the rest." -ForegroundColor Gray
}
Write-Host ""
Write-Host "  HOW THIS WORKS: at each step press Enter - the installer opens the page for you." -ForegroundColor White
Write-Host "  Do ONLY the highlighted action on that page, then come back here and press Enter for the next step." -ForegroundColor White
Write-Host ""

Write-Host "  [Step 1/3] Discord server invite   " -ForegroundColor Cyan -NoNewline
Write-Host "Click: Accept Invite" -ForegroundColor Yellow
Write-Host "     (auto-opens: $DISCORD_INVITE_URL)" -ForegroundColor DarkGray
Pause-User "Press Enter to open the invite..."
try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open browser." }

Write-Host ""
Write-Host "  [Step 2/3] WoVR announcement post   " -ForegroundColor Cyan -NoNewline
Write-Host "Click: Toggle Channels" -ForegroundColor Yellow
Write-Host "     (unlocks the mod download channel)" -ForegroundColor DarkGray
Write-Host "     (auto-opens: $DISCORD_TOGGLE_URL)" -ForegroundColor DarkGray
Pause-User "Press Enter to open the announcement post..."
try { Start-Process $DISCORD_TOGGLE_URL } catch {}

Write-Host ""
Write-Host "  [Step 3/3] Mod download post   " -ForegroundColor Cyan -NoNewline
Write-Host "Download: $uiFile" -ForegroundColor Yellow
Write-Host "     (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
Pause-User "Press Enter to open the download post..."
try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}

# -------------------------------------------------------
#  Get the .7z from the user (drag-and-drop)
# -------------------------------------------------------
$dropStep = if ($updateOnly) { 3 } else { 4 }
Write-Step $dropStep $totalSteps "Drop the WoVR .7z onto this window"

$mod7z = $null
while (-not $mod7z) {
    Write-Host "  Drag-and-drop the downloaded $uiFile into this window," -ForegroundColor Yellow
    Write-Host "  or paste/type its full path, then press Enter:" -ForegroundColor White
    $r = (Read-Host "  .7z path").Trim().Trim('"')
    if (-not $r) { continue }
    if (Test-Path $r) {
        if ($r -match '\.7z$|\.zip$') {
            $mod7z = $r
            Write-OK "Archive located: $mod7z"
            $fname = [System.IO.Path]::GetFileName($r)
            if ($fname -ne $uiFile) {
                Write-Warn "File name '$fname' does not match the expected"
                Write-Warn "name '$uiFile' - if you picked the wrong variant"
                Write-Warn "the wrong UI will be installed. Continuing anyway."
            }
        } else {
            Write-Fail "Path is not a .7z or .zip archive: $r"
        }
    } else {
        Write-Fail "File not found: $r"
    }
}

# -------------------------------------------------------
#  Extract into the WoW folder
# -------------------------------------------------------
Write-Host ""
Write-Host "  Extracting $uiLabel into the WoW folder ... " -NoNewline -ForegroundColor White
try {
    # 7z x      -> extract with full paths
    # -o<dir>   -> output directory
    # -y        -> assume Yes on all queries (overwrite)
    # The archives contain Interface/, vr/, WTF/ at the root,
    # which merge cleanly with the WoW folder layout.
    & $sevenZip x "$mod7z" "-o$gamePath" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip exit code $LASTEXITCODE" }
    Write-Host "OK" -ForegroundColor Green
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Fail "Extraction failed: $_"
    Pause-User "Press Enter to exit..."
    exit 1
}

# ============================================================
#  FULL INSTALL: optional 4 GB patch
# ============================================================
if (-not $updateOnly) {
    Write-Step 5 $totalSteps "Optional: 4 GB RAM patch"

    Write-Host "  WoW 3.3.5a is a 32-bit process and is limited to 2 GB of" -ForegroundColor White
    Write-Host "  user address space by default. With the WoVR mod loaded" -ForegroundColor White
    Write-Host "  this can be hit, showing as 'half the world is black' or" -ForegroundColor White
    Write-Host "  similar artefacts." -ForegroundColor White
    Write-Host ""
    Write-Host "  The NTCore 4GB patch flips the LAA flag in Wow.exe to" -ForegroundColor White
    Write-Host "  unlock 4 GB. Safe and reversible." -ForegroundColor White
    Write-Host ""
    $patchChoice = (Read-Host "  Apply the 4 GB patch now? (Y/N)").Trim()
    if ($patchChoice -in @("y","Y")) {
        $tempDir = Join-Path $env:TEMP "WoVRInstaller_$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $patchZip = Join-Path $tempDir "4gb_patch.zip"
        $patchExe = Join-Path $tempDir "4gb_patch.exe"

        Write-Host "  Downloading 4 GB patch ... " -NoNewline -ForegroundColor White
        $patchOk = $false
        $r = Invoke-DownloadOrFallback -Url $PATCH_4GB_URL -Destination $patchZip `
                -Label "NTCore 4GB Patch v1.0.0.1" `
                -ManualUrl "https://ntcore.com/?page_id=371" `
                -Instructions "Download '4gb_patch.zip' from the NTCore page that just opened. Place it at '$patchZip' and choose Retry." `
                -SkipMessage "Skipped - 4GB Patch not applied; WoW.exe will be limited to 2GB address space (high impact)."
        if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        if ($r -eq $true -and (Test-Path $patchZip)) {
            $efb = Expand-ArchiveOrFallback -ArchivePath $patchZip -DestinationFolder $tempDir -Label "4 GB patch" `
                    -SkipMessage "Skipped - patch was not extracted; the 4 GB patch will not be applied."
            if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
            if (Test-Path $patchExe) {
                $patchOk = $true
            } else {
                Write-Warn "4gb_patch.exe was not in the downloaded archive."
            }
        }

        if ($patchOk) {
            $wowExePath = Join-Path $gamePath $GAME_EXE
            Write-Host ""
            Write-Host "  Launching 4gb_patch.exe - it will open a file" -ForegroundColor White
            Write-Host "  picker. Select your Wow.exe:" -ForegroundColor White
            Write-Host "    $wowExePath" -ForegroundColor Yellow
            try { Set-Clipboard -Value $wowExePath } catch {}
            Write-Info "Path above has been copied to the clipboard."
            Write-Host ""
            Pause-User "Press Enter to launch the patcher..."
            try {
                Start-Process -FilePath $patchExe -Wait
                Write-OK "4 GB patcher closed."
            } catch {
                Write-Warn "Could not launch 4gb_patch.exe: $_"
                Write-Info "Run it manually from: $patchExe"
                Pause-User "Press Enter once you have run the patcher..."
            }
        }

        try { Remove-Item $tempDir -Recurse -Force } catch {}
    } else {
        Write-Info "4 GB patch skipped. You can re-run this installer in"
        Write-Info "Update mode and apply it later, or grab it manually"
        Write-Info "from $PATCH_4GB_URL"
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
#  Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation Complete" -ForegroundColor White
Write-Host ""
Write-Host "    [x] WoVR ($uiLabel) extracted into the WoW folder" -ForegroundColor Green
if (-not $updateOnly) {
    Write-Host "    [x] WoW folder cleaned by WoVR-Cleaner.bat" -ForegroundColor Green
}
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- How to Play ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Launch SteamVR (or your headset's runtime) first." -ForegroundColor White
Write-Host "  2. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or Wow.exe from" -ForegroundColor White
Write-Host "     the WoW folder." -ForegroundColor White
Write-Host "  3. Log into a character. The first time, the UI and controls" -ForegroundColor White
Write-Host "     will look wrong - press Y on the left controller (or Esc)" -ForegroundColor White
Write-Host "     to open the menu and Exit Game." -ForegroundColor White
Write-Host "  4. The next login will be fully set up. Enjoy!" -ForegroundColor White
Write-Host ""
Write-Host "--- Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Do NOT change the in-game resolution when using the VR UI" -ForegroundColor Gray
Write-Host "  - VR UI is NOT compatible with AMD graphics - use Flat UI" -ForegroundColor Gray
Write-Host "  - Configure mounts / snap turning in: $gamePath\vr\config.txt" -ForegroundColor Gray
Write-Host "  - The floating keyboard needs admin rights and does not" -ForegroundColor Gray
Write-Host "    work on Windows 11" -ForegroundColor Gray
Write-Host ""
Write-Host "  By the Light - safe travels through Azeroth, hero!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit..."

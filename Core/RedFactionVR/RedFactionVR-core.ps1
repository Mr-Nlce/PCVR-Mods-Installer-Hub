# ============================================================
#  Red Faction VR - Alpine Faction VR by CactusVRStudios
# ------------------------------------------------------------
#  The mod is NOT a proxy and NOT an overlay: it is a game launch of
#  its own - AlpineFactionVR.exe - built on Alpine Faction, the
#  maintained rebuild of the Red Faction base (itself a descendant of
#  Dash Faction). VR runs over OpenXR on the Direct3D 11 path.
#
#  THE AUTHOR EXPLICITLY RECOMMENDS THE SETUP, not the ZIP: the setup
#  finds Red Faction itself, brings a supported game build up to
#  date, creates the folders needed and does it all in one pass. The
#  ZIP is the route for people who already prepared Alpine Faction.
#  We take the setup.
#
#  CHECKSUM: for EVERY build the author writes the SHA-256 of both
#  files into the release note. Confirm-ReleaseChecksum
#  (InstallerSafety.ps1) reads it from there and recomputes it - so
#  this keeps working on future builds without any value being
#  hard-coded here.
#
#  ALL RELEASES ARE PRERELEASES -> GithubPrerelease = $true in the
#  catalog, and query the release LIST here instead of /latest.
#
#  WHY WE STILL SEARCH FOR THE GAME even though the setup can do it:
#  the Hub needs the path for .installed_path, for VR-ready detection
#  and for "Start in VR". WE change nothing there.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Red Faction VR Installer"
$ErrorActionPreference = "Stop"

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

$GAME_NAME  = "Red Faction"
$APP_ID     = "20530"
$GAME_EXE   = "RF.exe"
$GAME_EXE2  = "RedFaction.exe"
$MOD_NAME   = "Alpine Faction VR"
$MOD_AUTHOR = "CactusVRStudios"
$REPO       = "CactusVRStudios/alpinefactionVR"
$RELEASES   = "https://github.com/$REPO/releases"
$MOD_EXE    = "AlpineFactionVR.exe"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Red Faction VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Red Faction (2001) in the headset: stereoscopic rendering," -ForegroundColor White
Write-Host "  6DOF head tracking and motion-controlled weapons, with" -ForegroundColor White
Write-Host "  two-handed grips, a laser sight, room-scale movement that" -ForegroundColor White
Write-Host "  collides with real walls, VR ladders and swimming, and turret" -ForegroundColor White
Write-Host "  and vehicle support. Oculus Touch and Index Knuckles are both" -ForegroundColor White
Write-Host "  mapped. Geo-Mod still tears the level apart." -ForegroundColor White
Write-Host ""
Write-Host "  THIS IS AN EARLY ALPHA. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The author says it plainly: expect bugs, crashes, unfinished" -ForegroundColor White
Write-Host "  features and systems it simply does not work on. Known right" -ForegroundColor White
Write-Host "  now: open mesh issues on some guns, and two-handed grips are" -ForegroundColor White
Write-Host "  buggy. Back up your saves before you try it." -ForegroundColor White
Write-Host ""
Write-Host "  You need Red Faction installed and an OpenXR runtime running." -ForegroundColor Gray
Write-Host "  Singleplayer is the target; multiplayer is best-effort and" -ForegroundColor Gray
Write-Host "  unsupported." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 4 "Locating $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("red faction","Red Faction") -ProbeExe $GAME_EXE
if (-not $gameDir) {
    # String concatenation instead of Join-Path: Join-Path throws on a
    # drive that does not exist (hub-wide rule).
    foreach ($c in @("C:\GOG Games\Red Faction",
                     "C:\Program Files (x86)\GOG Galaxy\Games\Red Faction",
                     "C:\games\RedFaction",
                     "C:\Program Files (x86)\Red Faction",
                     "D:\GOG Games\Red Faction",
                     "E:\GOG Games\Red Faction")) {
        if ((Test-Path -LiteralPath "$c\$GAME_EXE") -or (Test-Path -LiteralPath "$c\$GAME_EXE2")) { $gameDir = $c; break }
    }
}
while (-not $gameDir) {
    Write-Warn "Could not find $GAME_NAME automatically."
    Write-Host "  Drag the Red Faction folder into this window (the one" -ForegroundColor White
    Write-Host "  holding $GAME_EXE), or paste its path, then press Enter." -ForegroundColor White
    Write-Host "  Leave it empty to stop - nothing has been changed yet." -ForegroundColor Gray
    $raw = (Read-Host "  Game folder").Trim().Trim('"')
    if (-not $raw) { Write-Info "Stopped. Nothing was changed."; Pause-User "Press Enter to exit."; exit 1 }
    if ((Test-Path -LiteralPath "$raw\$GAME_EXE") -or (Test-Path -LiteralPath "$raw\$GAME_EXE2")) { $gameDir = $raw }
    else { Write-Fail "That folder contains neither $GAME_EXE nor $GAME_EXE2." }
}
Write-OK "Found $GAME_NAME`: $gameDir"
Write-Info "The setup asks for this folder itself - have it ready."
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameDir -RelModFile $MOD_EXE -Label "Red Faction VR"

# ---- 2. Fetch the setup ---------------------------------------
Write-Step 2 4 "Downloading the $MOD_NAME setup"

# All builds are prereleases -> query the list, /latest is empty.
# The asset is named differently per build (version number in the
# name), so match by pattern and do NOT insist on a fixed name.
$url = $null; $tag = ""; $assetName = ""; $body = ""
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    $pick = @($rel) | Where-Object { -not $_.draft } | Select-Object -First 1
    if ($pick) {
        # THE SETUP FIRST, THEN any exe. With -or inside ONE filter the
        # first exe in the list would simply have won - including one
        # that is not the recommended setup at all.
        $exes = @($pick.assets) | Where-Object { $_.name -match '(?i)\.exe$' }
        $a = $exes | Where-Object { $_.name -match '(?i)setup' } | Select-Object -First 1
        if (-not $a) { $a = $exes | Select-Object -First 1 }
        if ($a -and $a.browser_download_url) {
            $url = [string]$a.browser_download_url
            $assetName = [string]$a.name
            $assetSize = [long]$a.size
            $tag = [string]$pick.tag_name
            $body = [string]$pick.body
        }
    }
    if ($url) { Write-OK "Release: $tag  ($assetName)" }
} catch { Write-Warn "GitHub could not be reached - you can fetch the setup by hand." }

$tmp = Join-Path $env:TEMP ("rfvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
if (-not $assetName) { $assetName = "AlpineFactionVR-setup.exe" }
$exe = Join-Path $tmp $assetName

$have = Find-PredownloadedFile -Patterns @("AlpineFactionVR*setup*.exe") -Label "the Alpine Faction VR setup" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $exe = $have
    $assetName = Split-Path $have -Leaf
    Write-Info "Using the copy you already downloaded."
} else {
    if (-not $url) { $url = $RELEASES }
    Invoke-SafeDownload -Urls @($url) -Destination $exe -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download the setup .exe from the releases page, save it as '$exe', then choose Retry."
}
if (-not (Test-Path -LiteralPath $exe)) {
    Write-Fail "No setup file - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# CHECKSUM. The value comes from this build's release note, not from
# us - so it keeps working on the next one too.
$sum = Confirm-ReleaseChecksum -FilePath $exe -AssetName $assetName -ReleaseBody $body -ReportTo "CactusVRStudios"
if ($sum -eq "mismatch") {
    try { if ($exe -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    Write-Fail "Stopped on purpose. Your game was not touched."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 3. Run the setup -----------------------------------------
Write-Step 3 4 "Running the setup"
Write-Host "  It finds Red Faction, brings a supported version up to date," -ForegroundColor White
Write-Host "  creates the folders it needs and installs the VR build - all" -ForegroundColor White
Write-Host "  in one pass. Read its screens; they are the author's own." -ForegroundColor White
Write-Host ""
Write-Host "  It is not code-signed, so Windows may show a SmartScreen" -ForegroundColor Gray
Write-Host "  warning - choose More info, then Run anyway." -ForegroundColor Gray
Pause-User "Press Enter to run the setup - UAC required..." | Out-Null
try { Start-Process -FilePath $exe -Wait -Verb RunAs -ErrorAction Stop }
catch { Write-Warn "The setup was declined or could not start: $($_.Exception.Message)" }
try { if ($exe -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

# WHERE THE SETUP PUTS IT WAS A MISTAKE ON MY PART: Alpine Faction VR
# installs into a folder OF ITS OWN, by default
#     C:\Program Files (x86)\Alpine Faction VR
# and NOT into the Red Faction folder. Look there first, then in the
# game folder, then ask - and when asking, also accept a path pointing
# at the EXE ITSELF: whoever drags an exe into the window gets exactly
# that, and "<exe>\AlpineFactionVR.exe" obviously does not exist.
$modDir = $null
$probe  = New-Object System.Collections.Generic.List[string]
$pf86 = ${env:ProgramFiles(x86)}
if ($pf86)    { [void]$probe.Add("$pf86\Alpine Faction VR") }
if ($env:ProgramFiles) { [void]$probe.Add("$($env:ProgramFiles)\Alpine Faction VR") }
[void]$probe.Add("C:\Program Files (x86)\Alpine Faction VR")
if ($gameDir) { [void]$probe.Add($gameDir) }
foreach ($c in $probe) {
    if ($c -and (Test-Path -LiteralPath "$c\$MOD_EXE")) { $modDir = $c; break }
}
if (-not $modDir) {
    Write-Warn "The Hub could not find where the setup installed the VR build."
    Write-Host "  If you pointed the setup at your own folder, drag it - or" -ForegroundColor White
    Write-Host "  $MOD_EXE inside it - in here. Then Start in VR works." -ForegroundColor White
    Write-Host "  Leave empty to skip: the game is installed either way, the" -ForegroundColor Gray
    Write-Host "  Hub just will not be able to start it for you." -ForegroundColor Gray
    $raw = (Read-Host "  Folder or exe").Trim().Trim('"').TrimEnd('\')
    if ($raw) {
        # Pointed at the exe? Then take the folder above it.
        if ($raw -match '(?i)\.exe$') { $raw = Split-Path -LiteralPath $raw -Parent }
        if ($raw -and (Test-Path -LiteralPath "$raw\$MOD_EXE")) { $modDir = $raw }
        else { Write-Fail "$MOD_EXE is not in that folder either." }
    }
}
if ($modDir) {
    Write-OK "Installed - Start in VR will open it from now on."
    Write-Info "Location: $modDir"
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $modDir -Encoding UTF8 -Force } catch {}
    if ($tag) { try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {} }
}

# ---- 4. Playing -----------------------------------------------
Write-Step 4 4 "Turning VR on"
Write-Host ""
Write-Host "  VR IS OFF UNTIL YOU SWITCH IT ON. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Hit " -NoNewline -ForegroundColor White
Write-Host "Start in VR" -NoNewline -ForegroundColor Cyan
Write-Host " on this game's page in the Hub, then open" -ForegroundColor White
Write-Host "  " -NoNewline
Write-Host "Options" -NoNewline -ForegroundColor Cyan
Write-Host ", enable " -NoNewline -ForegroundColor White
Write-Host "VR / OpenXR" -NoNewline -ForegroundColor Cyan
Write-Host " and pick your turn mode -" -ForegroundColor White
Write-Host "  snap or smooth. Then make sure your headset's OpenXR runtime is" -ForegroundColor White
Write-Host "  running and start the game from there." -ForegroundColor White
Write-Host ""
Write-Host "  You only do this once - the choice is remembered. VR mode runs" -ForegroundColor Gray
Write-Host "  on the Direct3D 11 renderer." -ForegroundColor Gray
Write-Host ""
Write-Host "  The controller map for Touch and Index is on this game's page in" -ForegroundColor Gray
Write-Host "  the Hub, with the layout picture next to it." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> Mars is ours. Now swing the sledgehammer with your own arm." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0

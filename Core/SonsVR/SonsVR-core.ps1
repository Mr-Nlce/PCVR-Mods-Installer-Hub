# ============================================================
#  SONS OF THE FOREST VR - SonsVR_Mod by Anthony (iPowerTech)
# ============================================================
#  A MelonLoader mod. The author ships a ONE-CLICK INSTALLER
#  (SONS_VR_v<version>_oneclick.exe) that asks for the game
#  folder and lays everything down itself. We fetch it and
#  start it - there is nothing sensible for us to unpack by
#  hand, and his installer refuses any folder without
#  SonsOfTheForest.exe, which is exactly the check we would
#  otherwise write ourselves.
#
#  !!! THE FIRST GAME START TAKES SEVERAL MINUTES AND LOOKS
#  !!! LIKE A HANG. That is MelonLoader, not a fault: it
#  downloads its tools and then GENERATES the IL2CPP
#  assemblies from the copy of the game on THIS machine.
#  Neither can be shipped - both belong to one install and one
#  game version. Later starts are quick. This is the single
#  most important thing to say before someone kills the
#  process and reports a broken mod.
#
#  ALL RELEASES ARE PRERELEASES -> the list is queried, never
#  /releases/latest, which is empty for this repo.
#
#  NOTHING OF THE GAME IS REPLACED: the mod lives in Mods\ and
#  MelonLoader\, saves and other mods keep working. Removing it
#  means deleting those folders.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Sons of the Forest VR Installer"
$ErrorActionPreference = "Stop"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x" -ForegroundColor Cyan; Write-Host "  ----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$GAME_NAME  = "Sons of the Forest"
$APP_ID     = "1326470"
$GAME_EXE   = "SonsOfTheForest.exe"
$MOD_NAME   = "SonsVR_Mod"
$MOD_AUTHOR = "Anthony (iPowerTech)"
$REPO       = "iPowerTech/SonsVR_Mod"
$RELEASES   = "https://github.com/$REPO/releases"
# Read from the tagged source, not guessed: ModInfo.cs declares
# Name = "SonsVR_Mod", so MelonLoader loads Mods\SonsVR_Mod.dll.
$REL_MOD    = "Mods\SonsVR_Mod.dll"

# !!! THE AUTHOR'S ONE-CLICK INSTALLER DOES NOT PLACE THESE, and
# without the first one NOTHING is clickable in VR (2026-08-20, found
# in a real log). SteamVR then reports:
#   [ERROR] [SteamVR] Could not find actions file at:
#   ...\SonsOfTheForest_Data\StreamingAssets\SteamVR\actions.json
# The 31 actions exist but are bound to nothing, so no trigger ever
# arrives - while the pointer still moves and highlights, because the
# beam comes from the head and hand poses and needs no action at all.
# That combination reads exactly like a broken mod.
# The files live in the mod's own source tree, so they are fetched
# from the tag that was installed and written straight into place.
$SVR_SUB    = "SonsOfTheForest_Data\StreamingAssets\SteamVR"
$SVR_RAW    = "https://raw.githubusercontent.com/iPowerTech/SonsVR_Mod"
$SVR_FILES  = @("actions.json", "bindings_oculus_touch.json", "bindings_rift.json")

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Sons of the Forest - VR" -ForegroundColor Cyan
Write-Host " $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Full VR through SteamVR for a game that has no VR mode:" -ForegroundColor White
Write-Host "  stereo rendering, 6DoF head tracking, and your arms driven" -ForegroundColor White
Write-Host "  through the IK rig the game already carries. Menus, the" -ForegroundColor White
Write-Host "  inventory and the HUD are placed on panels in the room." -ForegroundColor White
Write-Host ""
Write-Host "  ALPHA - expect rough edges " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Held items are not aligned to your hands yet, and the game" -ForegroundColor Gray
Write-Host "  draws two full render passes per frame." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 3 "Finding $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID `
             -SteamFolderNames @("Sons Of The Forest", "Sons of the Forest", "SonsOfTheForest") `
             -ProbeExe $GAME_EXE
if (-not $gameDir) { $gameDir = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE }
if (-not $gameDir -or -not (Test-Path -LiteralPath "$gameDir\$GAME_EXE")) {
    Write-Fail "Could not find $GAME_EXE - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameDir"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameDir -RelModFile $REL_MOD -Label "Sons of the Forest VR"

# ---- 2. Fetch the one-click installer -------------------------
Write-Step 2 3 "Downloading the installer"

# Every release of this project is a prerelease, so /releases/latest
# returns nothing - the list has to be queried and the newest entry
# carrying a package taken.
$url = $null; $tag = ""; $assetName = ""; $assetSize = 0
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
                -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    foreach ($r in @($rels)) {
        # The asset format changed between releases (.7z earlier, .zip
        # now), so match on "oneclick" rather than on the extension.
        $a = @($r.assets) | Where-Object { $_.name -match '(?i)oneclick' } | Select-Object -First 1
        if (-not $a) { $a = @($r.assets) | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1 }
        if ($a) {
            $url = [string]$a.browser_download_url; $tag = [string]$r.tag_name
            $assetName = [string]$a.name; $assetSize = [long]$a.size; break
        }
    }
} catch { Write-Warn "GitHub could not be reached - falling back to the releases page." }
if ($url) { Write-OK "Release: $tag  ($assetName)" } else { $url = $RELEASES }

$tmp = Join-Path $env:TEMP ("sonsvr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$pkg = Join-Path $tmp "SonsVR.zip"

# A copy already on disk is only used when name AND size match the
# current release - otherwise an older download would install itself.
$have = Find-PredownloadedFile -Patterns @("SONS_VR_*oneclick*.zip") -Label "the Sons of the Forest VR installer" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $pkg = $have
    Write-Info "Using the copy you already downloaded."
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $pkg -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download the one-click installer from the releases page, save it as '$pkg', then choose Retry."
}
if (-not (Test-Path -LiteralPath $pkg)) {
    Write-Fail "No package - the game was not touched."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The zip holds exactly one file: the one-click exe.
$setup = $null
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    [System.IO.Compression.ZipFile]::ExtractToDirectory($pkg, (Join-Path $tmp "x"))
    $setup = (Get-ChildItem -LiteralPath (Join-Path $tmp "x") -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue |
              Sort-Object Length -Descending | Select-Object -First 1).FullName
} catch { Write-Warn "The package could not be unpacked: $($_.Exception.Message)" }
if (-not $setup) {
    Write-Fail "No installer executable inside the package."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Installer ready: $(Split-Path $setup -Leaf)"

# ---- 3. Run it, then verify -----------------------------------
Write-Step 3 3 "Running the author's installer"
Write-Host ""
Write-Host "  His installer asks for the game folder. Yours is:" -ForegroundColor White
Write-Host "    $gameDir" -ForegroundColor Cyan
try { Set-Clipboard -Value $gameDir; Write-Host "  (copied to your clipboard - paste it with Ctrl+V)" -ForegroundColor DarkGray } catch {}
Write-Host ""
Write-Host "  It refuses any folder without $GAME_EXE, so a wrong pick" -ForegroundColor Gray
Write-Host "  cannot install into the wrong place." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start the installer..." | Out-Null

try {
    $proc = Start-Process -FilePath $setup -PassThru -Wait
    Write-Info "Installer closed (exit code $($proc.ExitCode))."
} catch {
    Write-Fail "Could not start it: $($_.Exception.Message)"
}

# Verify by the RESULT on disk, not by the exit code: the user may
# have cancelled, or pointed it at a different copy of the game.
Write-Host ""
# Checked against a real before/after listing of the game folder, not
# against a guess: the install adds 172 files and changes none.
#   Mods\SonsVR_Mod.dll      159,232  the mod itself - the one that
#                                     proves THIS mod rather than any
#                                     other MelonLoader mod
#   Mods\Libs\openvr_api.dll 605,984
#   UserLibs\SonsSteamVR_IL2CPP.dll   the IL2CPP SteamVR binding
#   version.dll                       the MelonLoader loader itself
# UserData\MelonPreferences.cfg is NOT here yet - it is written on the
# first game start, so checking for it now would always fail.
$missing = @()
foreach ($f in @($REL_MOD, "Mods\Libs\openvr_api.dll", "UserLibs\SonsSteamVR_IL2CPP.dll", "MelonLoader", "version.dll")) {
    if (-not (Test-Path -LiteralPath "$gameDir\$f")) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Warn ("Not found in the game folder yet: " + ($missing -join ", "))
    Write-Host "  If you pointed the installer at a different copy of the" -ForegroundColor White
    Write-Host "  game, that one has it instead - the Hub only checks this one." -ForegroundColor White
} else {
    Write-OK "Installed and verified: $gameDir"
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
    if ($tag) { try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {} }
}
# ---- Repair: the SteamVR action files ------------------------
# Runs on every pass, so an installation that already went wrong is
# put right without reinstalling anything.
$svrDir = "$gameDir\$SVR_SUB"
$svrNeed = @()
foreach ($f in $SVR_FILES) {
    $fp = "$svrDir\$f"
    # PRESENT IS NOT ENOUGH - a zero-byte file passes Test-Path and
    # still leaves SteamVR without bindings.
    $ok = $false
    try {
        if (Test-Path -LiteralPath $fp) { $ok = ((Get-Item -LiteralPath $fp).Length -gt 0) }
    } catch {}
    if (-not $ok) { $svrNeed += $f }
}

if ($svrNeed.Count -eq 0) {
    Write-OK "SteamVR action files are in place."
} else {
    Write-Warn ("The mod installer left these out: " + ($svrNeed -join ", "))
    Write-Info "Without them SteamVR has no bindings and no trigger reaches the game."
    $svrTag = if ($tag) { $tag } else { "master" }
    try { New-Item -ItemType Directory -Path $svrDir -Force -ErrorAction Stop | Out-Null } catch {}
    $svrDone = 0
    foreach ($f in $svrNeed) {
        $rel = ($SVR_SUB -replace '\\\\', '/')
        $url = "$SVR_RAW/$svrTag/SonsVR_Mod/$rel/$f"
        $dst = "$svrDir\$f"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop
            # Verify what landed: non-empty AND valid JSON. An error page
            # from a proxy would otherwise be written as a binding file.
            $len = (Get-Item -LiteralPath $dst).Length
            $null = (Get-Content -LiteralPath $dst -Raw) | ConvertFrom-Json
            if ($len -gt 0) { $svrDone++; Write-OK "Restored $f ($len bytes)" }
        } catch {
            Write-Warn "Could not restore ${f}: $($_.Exception.Message)"
            try { if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Force } } catch {}
        }
    }
    if ($svrDone -eq $svrNeed.Count) {
        Write-OK "SteamVR action files restored - menus and triggers will work."
    } else {
        Write-Warn "Some action files are still missing. Menus will highlight but not click."
    }
}

try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   THE FIRST START TAKES SEVERAL MINUTES - DO NOT KILL IT" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  The window will look like it is doing nothing. It is not:" -ForegroundColor White
Write-Host "  MelonLoader is downloading its tools and then generating" -ForegroundColor White
Write-Host "  its assemblies FROM YOUR COPY of the game. Neither can ship" -ForegroundColor White
Write-Host "  with the mod - both belong to one install and one version." -ForegroundColor White
Write-Host "  You need an internet connection for that first run." -ForegroundColor White
Write-Host "  Every later start is quick." -ForegroundColor White
Write-Host ""
Write-Host "  START STEAMVR FIRST, then the game. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "  Around thirty settings live on a panel inside the headset." -ForegroundColor Gray
Write-Host "  Everything, including what is not on the panel, is in" -ForegroundColor Gray
Write-Host "  UserData\MelonPreferences.cfg under [SonsVR], each entry" -ForegroundColor Gray
Write-Host "  with a description. If the picture is too soft or the frame" -ForegroundColor Gray
Write-Host "  rate too low, RenderScale is the first thing to change." -ForegroundColor Gray
Write-Host ""
Write-Host "  The full control map is on this game's page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> No VR mode was ever shipped for this island." -ForegroundColor Magenta
Write-Host "      Someone built one anyway." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0

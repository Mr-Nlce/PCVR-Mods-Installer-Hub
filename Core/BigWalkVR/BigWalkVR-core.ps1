# ============================================================
# Big Walk VR - Installer
# ============================================================
# Big Walk VR by CircuitLord: multiplayer-compatible SteamVR
# support for Big Walk (House House), 6DOF motion controls,
# grabbing and throwing.
#
# THIS ENTRY IS DIFFERENT FROM EVERY OTHER ONE IN THE HUB:
# the mod is not shipped as an archive. CircuitLord publishes a
# small companion app, BigWalkVRInstaller.exe, that
#   - finds Big Walk through Steam,
#   - sets up MelonLoader,
#   - downloads the mod and the optional add-ons,
#   - keeps all of it up to date,
#   - and launches the game, in VR or flat.
#
# So this installer does exactly one thing: it puts that app
# into the game folder and hands over. Everything the Hub would
# normally do itself is the app's job here - which is also why
# this entry has no GithubRepo: the app updates itself, and an
# update badge on the tile would only ever be noise.
#
# All facts below are read from the project's own manifest.json
# (raw.githubusercontent.com/CircuitLord/BigWalkVRInstaller) and
# from the core mod package BigWalkVR-0.1.10.zip, which was
# downloaded and listed - not from the readme:
#   Mods\BigWalkVR.dll                     <- the VR Ready anchor
#   Mods\BigWalkVR.ItemOffsets.json
#   Big Walk_Data\Plugins\x86_64\openvr_api.dll
#   Big Walk_Data\Plugins\x86_64\XRSDKOpenVR.dll
#   Big Walk_Data\StreamingAssets\SteamVR\OpenVRSettings.asset
#   Big Walk_Data\UnitySubsystems\XRSDKOpenVR\...
#   BigWalkVR.Native.dll, phonon.dll, openvr_api.dll,
#   bigwalkvr.vrmanifest, bigwalkvr_actions.json, bindings_*.json
# plus MelonLoader 0.7.3. The app writes the exact file list it
# installed to <game>\UserData\BigWalkVRInstaller\<id>.json.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Big Walk VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME     = "Big Walk"
$GAME_EXE      = "Big Walk.exe"
$STEAM_APP     = "1478500"
$SHORTCUT_NAME = "Big Walk VR"

$APP_EXE       = "BigWalkVRInstaller.exe"
$MANIFEST_URL  = "https://raw.githubusercontent.com/CircuitLord/BigWalkVRInstaller/main/manifest.json"
$LATEST_URL    = "https://github.com/CircuitLord/BigWalkVRInstaller/releases/latest/download/BigWalkVRInstaller.exe"
$PROJECT_PAGE  = "https://github.com/CircuitLord/BigWalkVRInstaller"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
# Read-Host swallowed on purpose: this runs inside value-returning
# functions elsewhere in the Hub and would otherwise leak.
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }

Clear-Host
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Big Walk VR - Installer" -ForegroundColor Cyan
Write-Host " Big Walk VR by CircuitLord | motion controls, multiplayer" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Full SteamVR support for Big Walk, and it stays multiplayer-" -ForegroundColor White
Write-Host "  compatible: flat players see your tracked movement." -ForegroundColor White
Write-Host ""
Write-Host "  The mod ships with its own companion app. This installer puts" -ForegroundColor White
Write-Host "  that app into your game folder; the app then downloads the mod," -ForegroundColor White
Write-Host "  sets up MelonLoader, keeps everything current and launches the" -ForegroundColor White
Write-Host "  game - in VR or flat." -ForegroundColor White
Write-Host ""
Write-Host "  Needed: Big Walk on Steam and SteamVR." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..."

# ---- [1/3] locate the game -----------------------------------
Write-Step 1 3 "Finding Big Walk"

$gameRoot = $null
try {
    $gameRoot = Find-SteamGameFolder -AppId $STEAM_APP `
                    -SteamFolderNames @("Big Walk") -ProbeExe $GAME_EXE
} catch { $gameRoot = $null }
if (-not $gameRoot) { $gameRoot = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE }
if (-not $gameRoot -or -not (Test-Path -LiteralPath (Join-Path $gameRoot $GAME_EXE))) {
    Write-Fail "Could not find $GAME_EXE - nothing was installed."
    Pause-User "Press Enter to exit."
    return
}
Write-OK "Game folder: $gameRoot"

$appPath   = Join-Path $gameRoot $APP_EXE
$hadApp    = Test-Path -LiteralPath $appPath
$appBefore = $null
if ($hadApp) {
    try { $appBefore = (Get-Item -LiteralPath $appPath).Length } catch {}
    Write-Info "The app is already here - this run replaces it with the current build."
}

# ---- [2/3] fetch the app -------------------------------------
Write-Step 2 3 "Downloading the Big Walk VR app"

# The project's manifest.json carries the current installer build
# WITH its SHA-256, so the download can be proven instead of hoped.
# If the manifest is unreachable we fall back to the release's
# stable /latest/download URL and say that it went unverified.
$dlUrl = $LATEST_URL
$want  = ""
try {
    $mf = Invoke-RestMethod -Uri $MANIFEST_URL -Headers @{ "User-Agent" = "PCVRModsHub" } -TimeoutSec 20
    if ($mf.installer.url)    { $dlUrl = [string]$mf.installer.url }
    if ($mf.installer.sha256) { $want  = ([string]$mf.installer.sha256).ToLower() }
    if ($mf.installer.version) { Write-Info "Current app build: $($mf.installer.version)" }
} catch {
    Write-Warn "Could not read the project manifest - using the latest release link."
}

$tmp = Join-Path $env:TEMP ("bigwalkvr_" + [Guid]::NewGuid().ToString("N") + ".exe")
$got = Invoke-SafeDownload -Urls @($dlUrl) -Destination $tmp -Label "Big Walk VR app" `
           -ManualUrl $PROJECT_PAGE `
           -Instructions "Download BigWalkVRInstaller.exe from the releases page and drop it into your Big Walk folder."
if (-not $got -or -not (Test-Path -LiteralPath $tmp)) {
    Write-Fail "Download failed - nothing was changed."
    Write-Info "You can fetch it yourself: $LATEST_URL"
    Write-Info "Put $APP_EXE into: $gameRoot"
    Pause-User "Press Enter to exit."
    return
}

if ($want) {
    $have = ""
    try { $have = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLower() } catch {}
    if ($have -and $have -ne $want) {
        Write-Fail "The downloaded file does not match the checksum from the project manifest."
        Write-Info "expected $want"
        Write-Info "got      $have"
        try { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        return
    }
    if ($have) { Write-OK "Checksum verified against the project manifest." }
} else {
    Write-Info "No checksum available - the file was not verified."
}

# ---- [3/3] put it in place -----------------------------------
Write-Step 3 3 "Placing the app and finishing up"

try {
    Copy-Item -LiteralPath $tmp -Destination $appPath -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not write to the game folder: $($_.Exception.Message)"
    Write-Info "Copy $APP_EXE there yourself: $gameRoot"
    Pause-User "Press Enter to exit."
    return
}
try { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } catch {}

# Proof that something arrived, not that something was already there.
$placed = $false
if (Test-Path -LiteralPath $appPath) {
    if (-not $hadApp) { $placed = $true }
    else {
        $now = $null
        try { $now = (Get-Item -LiteralPath $appPath).Length } catch {}
        $placed = $true   # the copy above threw on failure, so it landed
        if ($now -and $appBefore -and $now -eq $appBefore) { Write-Info "Same build as before - nothing changed." }
    }
}
if (-not $placed) {
    Write-Fail "$APP_EXE is not in the game folder - the install did not take."
    Pause-User "Press Enter to exit."
    return
}
Write-OK "$APP_EXE is in $gameRoot"

# State markers only now, after the file is verified in place.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
try {
    $sc = New-DesktopShortcut -ShortcutName $SHORTCUT_NAME -TargetPath $appPath `
              -WorkingDir $gameRoot -IconPath $appPath -Description "Big Walk VR"
    if ($sc) { Write-OK "Desktop shortcut '$SHORTCUT_NAME' created." }
} catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }

Write-Host ""
# Every one of these is a button the USER has to press, so each one is
# marked the same way the rest of the Hub marks a user action: black on
# yellow. Step 3 is called "Big Walk VR" in the app, not "the mod".
Write-Host "  The app does the rest - three presses:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1. Find Big Walk" -NoNewline -ForegroundColor White; Write-Host "  - usually already filled in." -ForegroundColor Gray
Write-Host "      If not, press " -NoNewline -ForegroundColor Gray; Write-Host " Change " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " and pick the folder." -ForegroundColor Gray
Write-Host "   2. Set up MelonLoader" -NoNewline -ForegroundColor White; Write-Host "  - press " -NoNewline -ForegroundColor Gray; Write-Host " Install " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   3. Big Walk VR" -NoNewline -ForegroundColor White; Write-Host "  - press " -NoNewline -ForegroundColor Gray; Write-Host " Install " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "   Optional: Solo Launch" -NoNewline -ForegroundColor White; Write-Host "  - press its " -NoNewline -ForegroundColor Gray; Write-Host " Install " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " as well" -ForegroundColor Gray
Write-Host "             if you want to play without other players." -ForegroundColor Gray
Write-Host ""
Write-Host "  The Launch buttons stay greyed out until 1-3 are done." -ForegroundColor Gray
Pause-User "Press Enter to open the app..."

try { Start-Process -FilePath $appPath -WorkingDirectory $gameRoot | Out-Null }
catch { Write-Warn "Could not start it: $($_.Exception.Message)"; Write-Info "Run it yourself: $appPath" }

Pause-User "Press Enter once those three steps are done..."

# Now the mod itself should be on disk - check it instead of claiming
# success. Mods\BigWalkVR.dll is the core mod's own file, verified
# against the project's package listing.
$modFile = Join-Path $gameRoot "Mods\BigWalkVR.dll"
Write-Host ""
if (Test-Path -LiteralPath $modFile) {
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Big Walk VR is installed!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Magenta
} else {
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " The app is ready - the mod is not installed yet" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Mods\BigWalkVR.dll is not in your game folder, so step 3 has" -ForegroundColor Yellow
    Write-Host "  not run yet. Open the app again and finish it - everything" -ForegroundColor Yellow
    Write-Host "  below applies once you have." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  START: " -NoNewline -ForegroundColor Cyan; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub opens the app, or use the" -ForegroundColor Cyan
Write-Host "  desktop shortcut, then press " -NoNewline -ForegroundColor Cyan; Write-Host " Launch in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " there." -ForegroundColor Cyan
Write-Host "  Start SteamVR first." -ForegroundColor Cyan
Write-Host ""
Write-Host "  The first start takes longer than usual - the mod is being" -ForegroundColor Gray
Write-Host "  prepared. Give it time, it is not stuck." -ForegroundColor Gray
Write-Host ""
Write-Host "  Launching Big Walk from Steam, or pressing Launch in Non-VR," -ForegroundColor Gray
Write-Host "  starts the game flat with the mod still installed - flat and VR" -ForegroundColor Gray
Write-Host "  players can play together." -ForegroundColor Gray
Write-Host ""
Write-Host "  The app keeps itself and the mod up to date, so there is no" -ForegroundColor Gray
Write-Host "  update to chase here." -ForegroundColor Gray
Write-Host ""
Write-Host "  Two lads, one long walk, and now you are actually in it." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

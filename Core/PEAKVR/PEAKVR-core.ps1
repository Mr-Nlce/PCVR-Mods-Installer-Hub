# ============================================================
#  PEAK VR Installer (PEAK_VR by AstienVR)
# ============================================================
#
#  PEAK gets updated frequently and the VR mod stopped being
#  compatible with versions past 1.44.a. We pin the game to the
#  last known compatible Steam manifest using Steam Console's
#  download_depot command, then move the depot out of Steam's
#  reach into a stable folder so a future Steam update can't
#  blow the VR setup away.
#
#  Flow:
#    1) 7-Zip pre-flight + Steam Console download_depot for manifest
#       1663614006819171465 of App 3527290 / Depot 3527291 - that's
#       PEAK v1.44.a or the last known compatible build
#    2) Auto-detect the depot folder under steamapps\content\
#       and move it to C:\Games\PEAK VR (default, user can change)
#    3) Drop steam_appid.txt so the EXE can be launched directly
#    4) Auto-download PEAK_VR.zip from GitHub release v1.0.0
#       and extract into the pinned game folder
#    5) Drop kirigiri's PeakVersionBypass.dll into BepInEx\plugins\
#       so PEAK doesn't bail at the version check on launch
#    6) Run ViGEmBus_1.22.0_x64_x86_arm64.exe interactively -
#       Windows driver, requires UAC, can't be silent without
#       admin elevation
#    7) Desktop shortcut on PEAK.exe in the pinned folder
# ============================================================

$Host.UI.RawUI.WindowTitle = "PEAK VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# -------------------------------------------------------
#  Configuration
# -------------------------------------------------------
$MOD_NAME       = "PEAK_VR v1.0.0 (by AstienVR)"
$MOD_URL        = "https://github.com/AstienVR/PEAK_VR/releases/download/1.0.0/PEAK_VR.zip"
$GITHUB_URL     = "https://github.com/AstienVR/PEAK_VR"

# kirigiri's PeakVersionBypass: disables PEAK's online version check
# so the game can actually launch when pinned to an older manifest.
# Without this, PEAK refuses to enter the main menu, displays a
# "version outdated" prompt and locks you out of offline play.
# Hosted on Thunderstore; small DLL that goes into BepInEx\plugins.
$BYPASS_NAME    = "PeakVersionBypass v1.0.2 (by kirigiri)"
$BYPASS_URL     = "https://thunderstore.io/package/download/kirigiri/PeakVersionBypass/1.0.2/"
$BYPASS_PAGE    = "https://thunderstore.io/package/kirigiri/PeakVersionBypass/"
$BYPASS_DLL     = "PeakVersionBypass.dll"

# PEAK pinned to last mod-compatible manifest (game 1.44.a)
$DEPOT_APPID    = "3527290"
$DEPOT_DEPOTID  = "3527291"
$DEPOT_MANIFEST = "1663614006819171465"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Game executable inside the depot
$GAME_EXE       = "PEAK.exe"

# Target install folder
$DEFAULT_PATH   = "C:\Games\PEAK VR"

# ViGEmBus driver location after mod extract (the mod ships with it)
$VIGEM_REL_PATH = "BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe"

# -------------------------------------------------------
#  Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   PEAK VR - Mod Installer" -ForegroundColor Cyan
    Write-Host "   Installs: $MOD_NAME" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}
function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Find-7Zip {
    foreach ($c in @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )) { if (Test-Path $c) { return $c } }
    return $null
}

# -------------------------------------------------------
#  Pre-flight
# -------------------------------------------------------
Write-Header

$sevenZip = Find-7Zip
if (-not $sevenZip) {
    Write-Fail "7-Zip not installed."
    Write-Host ""
    Write-Host "  This installer needs 7-Zip's command-line tool. Install it:" -ForegroundColor Yellow
    Write-Host "    https://www.7-zip.org" -ForegroundColor White
    Pause-User "Press Enter to exit..."
    exit 1
}
Write-OK "7-Zip detected: $sevenZip"

Write-Host ""
Write-Host "  PEAK has been updated past version 1.44.a, which broke the VR mod." -ForegroundColor White
Write-Host "  This installer pins the game to the last mod-compatible Steam" -ForegroundColor White
Write-Host "  manifest in a separate folder so your normal Steam install isn't" -ForegroundColor White
Write-Host "  touched." -ForegroundColor White
Write-Host ""
Write-Host "  You'll need:" -ForegroundColor White
Write-Host "    - PEAK owned on Steam (App $DEPOT_APPID)" -ForegroundColor Gray
Write-Host "    - Steam running and logged in" -ForegroundColor Gray
Write-Host "    - About 4 GB free disk space" -ForegroundColor Gray
Write-Host "    - Admin rights for the ViGEmBus driver install (UAC prompt)" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
#  STEP 1: Steam Console download_depot
# -------------------------------------------------------
Write-Step 1 7 "Download PEAK v1.44.a via Steam Console"

Write-Host "  Steam Console will be opened. The depot command is already" -ForegroundColor White
Write-Host "  copied to your clipboard - just paste (Ctrl+V) into the console" -ForegroundColor White
Write-Host "  input field and press Enter." -ForegroundColor White
Write-Host ""
Write-Host "  Command:" -ForegroundColor Gray
Write-Host "    $DEPOT_COMMAND" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Manifest $DEPOT_MANIFEST is PEAK v1.44.a (the last mod-compatible build)." -ForegroundColor Gray
Write-Host "  About 4 GB to download." -ForegroundColor Gray
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Depot command copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Press Enter to open the Steam Console..." -ForegroundColor Yellow
Write-Host "  Then click the input field, paste (Ctrl+V) and hit Enter." -ForegroundColor Yellow
Write-Host ""
Write-Host ""
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
    Write-Host "  (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
    Write-Host "      automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
    Write-Host "      doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
    Write-Host "      then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
    Write-Host "      next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
    Write-Host ""
}
Pause-User "Press Enter to open the Steam Console..."
Start-Process "steam://nav/console"
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
#  STEP 2: Locate + move depot to stable folder
# -------------------------------------------------------
Write-Step 2 7 "Locate depot and move to stable folder"

Write-Host "  Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
foreach ($reg in @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$depotPath = $null

if ($steamInstallPath) {
    $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
    Write-Info "Expected depot path: $autoPath"
    if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) {
        $depotPath = $autoPath
        Write-OK "Depot folder found automatically!"
    } else {
        Write-Warn "Depot folder not found at expected location."
        Write-Host "  This usually means the download isn't finished yet," -ForegroundColor Gray
        Write-Host "  or Steam used a different path." -ForegroundColor Gray
    }
} else {
    Write-Warn "Could not find Steam installation in registry."
}

if (-not $depotPath) {
    $probePaths = @()
    if ($steamInstallPath) {
        $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID")
    }
    $depotPath = Resolve-DepotPath -GameName "PEAK" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# Sanity check: depot should contain the game exe
$depotExe = Join-Path $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
    Write-Warn "'$GAME_EXE' not found inside depot."
    Write-Host "  Expected: $depotExe" -ForegroundColor Gray
    Write-Host "  This usually means the download is incomplete or the wrong" -ForegroundColor Gray
    Write-Host "  manifest was downloaded. Install anyway?" -ForegroundColor White
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Continue? (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..."
        exit 0
    }
} else {
    Write-OK "$GAME_EXE confirmed in depot."
}

# Pick target folder and move there
$parentOfDepot = Split-Path $depotPath -Parent  # ...\app_3527290

Write-Host ""
Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use default, or type a different full path").Trim().Trim('"')
if (-not $userInput) {
    $targetPath = $DEFAULT_PATH
} else {
    $targetPath = $userInput
}

$targetParent = Split-Path $targetPath -Parent
if ($targetParent -and -not (Test-Path $targetParent)) {
    try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
    catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
}

Write-Host ""
Write-Host "  Current location:  $depotPath" -ForegroundColor Gray
Write-Host "  Moving to:         $targetPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Why? Steam may overwrite the app_$DEPOT_APPID folder during" -ForegroundColor Gray
Write-Host "  future depot downloads. Moving to a stable name keeps the" -ForegroundColor Gray
Write-Host "  VR install safe and separate from your retail PEAK." -ForegroundColor Gray
Write-Host ""

if (Test-Path $targetPath) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Host "    [Y] Delete and proceed" -ForegroundColor White
    Write-Host "    [N] Keep it, abort install" -ForegroundColor Gray
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Your choice (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..."
        exit 0
    }
    try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
    catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
}

try {
    Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
    Write-OK "Game moved to: $targetPath"
} catch {
    Write-Fail "Move failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Pause-User "Press Enter to exit..."
    exit 1
}

# Clean up empty app_<id> folder
try {
    if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Item $parentOfDepot -Force
    }
} catch {}

$gamePath    = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
#  STEP 3: steam_appid.txt
# -------------------------------------------------------
Write-Step 3 7 "Drop steam_appid.txt"

# Without this, Steam may try to re-install or update PEAK whenever
# the user launches the EXE while Steam is running.
try {
    $steamAppIdFile = Join-Path $gamePath "steam_appid.txt"
    Set-Content -Path $steamAppIdFile -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
    Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
} catch {
    Write-Warn "Could not create steam_appid.txt: $_"
    Write-Host "  Create a file called 'steam_appid.txt' next to PEAK.exe," -ForegroundColor Gray
    Write-Host "  containing only the number $DEPOT_APPID." -ForegroundColor Gray
}

# -------------------------------------------------------
#  STEP 4: Download + extract PEAK_VR mod
# -------------------------------------------------------
Write-Step 4 7 "Download PEAK_VR mod and apply"

$modTmp = Join-Path $env:TEMP "PEAKVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $modTmp | Out-Null
$modZip = Join-Path $modTmp "PEAK_VR.zip"

$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "PEAK VR mod v1.0.0" `
        -ManualUrl "https://github.com/AstienVR/PEAK_VR/releases/tag/1.0.0" `
        -Instructions "Download 'PEAK_VR.zip' from the GitHub releases page. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - PEAK VR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without the VR mod. Press Enter to exit..."; exit 1 }

Write-Info "Extracting mod into $gamePath..."
$efb = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $gamePath -Label "PEAK_VR" `
        -SkipMessage "Skipped - PEAK_VR was not extracted; the VR mod will NOT load."
if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$efb -ne "ok" -and [string]$efb -ne "manual") {
    Pause-User "Mod extraction skipped/failed. Install incomplete. Press Enter to exit..."
    exit 1
}
Write-OK "Mod files extracted."

# Sanity check
$missing = @()
foreach ($f in @("winhttp.dll", $VIGEM_REL_PATH)) {
    if (-not (Test-Path (Join-Path $gamePath $f))) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Warn "Some expected mod files are missing: $($missing -join ', ')"
    Write-Warn "The mod may not function. Inspect $gamePath manually."
} else {
    Write-OK "Mod files in place (winhttp.dll, ViGEmBus installer present)."
}

try { Remove-Item -Path $modTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
#  STEP 5: Install PeakVersionBypass (kirigiri)
# -------------------------------------------------------
# PEAK refuses to enter the main menu when its client version doesn't
# match Steam's expected current version. Since we deliberately pinned
# to manifest 1.44.a, PEAK on launch shows an "update required" prompt
# and never reaches gameplay - not even offline. kirigiri's
# PeakVersionBypass is a tiny BepInEx plugin that silences that check.
Write-Step 5 7 "Install PeakVersionBypass (version-check bypass)"

$bypassTmp = Join-Path $env:TEMP "PeakVersionBypass_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $bypassTmp | Out-Null
$bypassZip = Join-Path $bypassTmp "PeakVersionBypass.zip"

Write-Info "Downloading $BYPASS_NAME ..."
$r = Invoke-DownloadOrFallback -Url $BYPASS_URL -Destination $bypassZip `
        -Label "PEAK Version Bypass" `
        -ManualUrl "$BYPASS_PAGE" `
        -Instructions "Download the latest PeakVersionBypass ZIP from the Thunderstore page. Place it at '$bypassZip' and choose Retry. Alternatively, extract '$BYPASS_DLL' into '$gamePath\BepInEx\plugins\' yourself and choose Skip." `
        -SkipMessage "Skipped - PEAK Version Bypass missing; PEAK will block at the version check (high impact)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) {
    Write-Warn "Bypass auto-download skipped. PEAK may block at version check."
    Pause-User "Press Enter once you've handled the bypass manually (or to continue without it)..."
}

# Extract only the DLL we need into the existing BepInEx\plugins folder
if (Test-Path $bypassZip) {
    $bypassExtract = Join-Path $bypassTmp "extract"
    try {
        $proc = Start-Process -FilePath $sevenZip -ArgumentList @(
            "x", "-y", "`"$bypassZip`"", "-o`"$bypassExtract`""
        ) -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -ne 0) { throw "7-Zip exit code $($proc.ExitCode)" }

        $bypassSrc = Join-Path $bypassExtract "BepInEx\plugins\$BYPASS_DLL"
        if (-not (Test-Path $bypassSrc)) {
            Write-Warn "$BYPASS_DLL not found in bypass ZIP after extract."
            Write-Warn "Skipping bypass install. PEAK will block at version check."
        } else {
            $bypassDst = Join-Path $gamePath "BepInEx\plugins\$BYPASS_DLL"
            $pluginsDir = Split-Path $bypassDst -Parent
            if (-not (Test-Path $pluginsDir)) {
                New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
            }
            Copy-Item -Path $bypassSrc -Destination $bypassDst -Force
            Write-OK "$BYPASS_DLL copied into BepInEx\plugins\."
        }
    } catch {
        Write-Warn "Bypass extract / copy failed: $_"
        Write-Warn "PEAK may block at the version check on launch."
    }
}

try { Remove-Item -Path $bypassTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
#  STEP 6: Install ViGEmBus driver
# -------------------------------------------------------
Write-Step 6 7 "Install ViGEmBus driver (gamepad emulation)"

$vigemExe = Join-Path $gamePath $VIGEM_REL_PATH
if (-not (Test-Path $vigemExe)) {
    Write-Warn "ViGEmBus installer not found at expected path:"
    Write-Warn "  $vigemExe"
    Write-Warn "Skipping driver install. You will need to install it manually."
    Write-Info "Download: https://github.com/nefarius/ViGEmBus/releases"
} else {
    # Detect an existing ViGEmBus install so users who already have it
    # (very common - it ships with many VR mods, Virtual Desktop,
    # DS4Windows, etc.) can just press Enter. Re-installing stays
    # available via V.
    $vigemPresent = $false
    try { $vigemPresent = Test-ViGEmBusInstalled } catch { $vigemPresent = $false }

    if ($vigemPresent) {
        Write-OK "ViGEmBus already detected on this PC."
        Write-Host ""
        Write-Host "  Press ENTER to continue to the next step (recommended)." -ForegroundColor White
        Write-Host "  If your VR controllers give you trouble, you can (re)install" -ForegroundColor Gray
        Write-Host "  it: type V then Enter." -ForegroundColor Gray
        $reinst = (Read-Host "  [Enter] skip / [V] reinstall").Trim()
        if ($reinst -in @("v","V")) {
            Write-Info "Launching ViGEmBus installer..."
            try {
                Start-Process -FilePath $vigemExe -Wait
                Write-OK "ViGEmBus setup finished."
            } catch {
                Write-Warn "ViGEmBus install threw: $_"
                Write-Warn "Run it manually from: $vigemExe"
            }
        } else {
            Write-Info "Keeping the existing ViGEmBus install."
        }
    } else {
        Write-Host "  PEAK_VR uses ViGEmBus to emulate an Xbox controller from your VR" -ForegroundColor White
        Write-Host "  controllers. The driver needs admin rights (UAC prompt)." -ForegroundColor White
        Write-Host ""
        Write-Host "  If ViGEmBus is ALREADY installed on your system, just close the" -ForegroundColor Cyan
        Write-Host "  setup window when it appears - no re-install needed." -ForegroundColor Cyan
        Write-Host ""
        $skip = (Read-Host "  Run ViGEmBus installer now? (Y/N)").Trim()
        if ($skip -in @("y","Y","")) {
            Write-Info "Launching ViGEmBus installer..."
            try {
                Start-Process -FilePath $vigemExe -Wait
                Write-OK "ViGEmBus setup finished."
                Write-Info "When PEAK launches you should hear a Windows 'device connected' sound -"
                Write-Info "that confirms the ViGEmBus driver is active."
            } catch {
                Write-Warn "ViGEmBus install threw: $_"
                Write-Warn "Run it manually from: $vigemExe"
            }
        } else {
            Write-Info "Skipped. Run later from: $vigemExe"
        }
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
#  STEP 7: Desktop shortcut
# -------------------------------------------------------
Write-Step 7 7 "Create desktop shortcut"

try {
    $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\PEAK VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0" -Arguments "-force-vulkan"
    Write-OK "Desktop shortcut 'PEAK VR' created (with -force-vulkan)."
} catch {
    Write-Warn "Could not create desktop shortcut: $_"
    Write-Host "  Launch manually from:" -ForegroundColor Gray
    Write-Host "  $gameExePath -force-vulkan" -ForegroundColor Yellow
}

# -------------------------------------------------------
#  Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Done. Before launching:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  1. Steam client must be running (PEAK still needs Steam auth)" -ForegroundColor White
Write-Host "  2. Start SteamVR" -ForegroundColor White
Write-Host "  3. Launch with 'Start in VR' in the Hub, or the" -ForegroundColor White
Write-Host "     'PEAK VR' desktop shortcut" -ForegroundColor White
Write-Host ""
Write-Host "  The shortcut launches PEAK with -force-vulkan, which is the" -ForegroundColor Cyan
Write-Host "  author's recommended VR API combo (OpenVR + Vulkan). VR renders" -ForegroundColor Cyan
Write-Host "  to the headset; the flatscreen window may not show an image -" -ForegroundColor Cyan
Write-Host "  that's normal and not a bug." -ForegroundColor Cyan
Write-Host ""
Write-Host "  If VR doesn't render with -force-vulkan, the only other combo" -ForegroundColor Gray
Write-Host "  that works for some setups is OpenXR + D3D12:" -ForegroundColor Gray
Write-Host "    1) Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor Gray
Write-Host "    2) Change 'vrApi = OpenVR' to 'vrApi = OpenXR'" -ForegroundColor Gray
Write-Host "    3) Edit the shortcut: replace -force-vulkan with -force-d3d12" -ForegroundColor Gray
Write-Host ""
Write-Host "  Quick controls:" -ForegroundColor Cyan
Write-Host "    - VR controllers map as an Xbox gamepad" -ForegroundColor White
Write-Host "    - Click BOTH thumbsticks to recenter VR view" -ForegroundColor White
Write-Host "    - Hold left hand near your head: hotkey gesture mode" -ForegroundColor White
Write-Host "    - White laser = interact / pick / throw" -ForegroundColor White
Write-Host "    - Red laser   = aim (shootable items)" -ForegroundColor White
Write-Host ""
Write-Host "  Virtual Desktop users: in the headset's VD input settings," -ForegroundColor Yellow
Write-Host "  make sure NO gamepad emulation is checked (Gamepad / Dpad off)." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Full config guide, troubleshooting and known issues are on the" -ForegroundColor Gray
Write-Host "  PEAK VR description page in the Hub, and in README_PEAKVR.md" -ForegroundColor Gray
Write-Host "  (in this installer folder)." -ForegroundColor Gray
Write-Host ""
Write-Host "  Reach the summit. Try not to fall. See you up top, Scout." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0

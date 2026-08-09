# ============================================================
# Assassin's Creed Valhalla VR - Installer (AnvilEngine2VR)
# ============================================================
# AnvilEngine2VR by mutars (same modder as Starfield VR in this
# Hub): a VR mod for AnvilNext-2.0 Assassin's Creed games. Full
# 6DOF head tracking, head aim, HUD scale adjustment. Works with
# EVERY store version of the game.
#
# Two runtime builds exist and this installer lets the user pick:
#   OpenXR (recommended) - dxgi.dll only; runs on any conformant
#                          runtime (SteamVR, VDXR, Meta, Pimax)
#   OpenVR               - dxgi.dll + openvr_api.dll; classic
#                          SteamVR path if OpenXR misbehaves
# Both install the same way: files go into the GAME folder next to
# the exe (DXGI hooking - the game itself loads the mod).
#
# Update badge: the Hub compares the GitHub latest tag (GithubRepo)
# against .installed_version, written VERBATIM from tag_name here.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Assassin's Creed Valhalla VR Installer"
$ErrorActionPreference = "Stop"

$STEAM_APPID       = "2208920"
$GAME_STEAM_FOLDER = "Assassin's Creed Valhalla"
$GAME_EXE          = "ACValhalla.exe"
# Ubisoft+ / PC Game Pass installs ship a different exe name in the
# same Ubisoft folder - detect and launch whichever is present.
$GAME_EXE_PLUS     = "ACValhalla_Plus.exe"
$GITHUB_API_LATEST = "https://api.github.com/repos/mutars/anvilengine2vr/releases/latest"
$GITHUB_RELEASES   = "https://github.com/mutars/anvilengine2vr/releases/latest"
$PINNED_TAG        = "v2.0.0.Public"
$PINNED_URL_XR     = "https://github.com/mutars/anvilengine2vr/releases/download/v2.0.0.Public/Valhalla-vr-openxr-v2.0.0.Public.zip"
$PINNED_URL_VR     = "https://github.com/mutars/anvilengine2vr/releases/download/v2.0.0.Public/Valhalla-vr-openvr-v2.0.0.Public.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Assassin's Creed Valhalla VR - Installer" -ForegroundColor Cyan
 Write-Host " AnvilEngine2VR by mutars | all store versions supported" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-ValhallaRoot {
 param([string]$Root)
 if (-not $Root) { return $false }
 $ok = $false
 try {
  $ok = (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $GAME_EXE))) -or `
        (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $GAME_EXE_PLUS)))
 } catch {}
 return $ok
}

Write-Header

# -------------------------------------------------------
# STEP 1: Locate the game (any store)
# -------------------------------------------------------
Write-Host " AnvilEngine2VR by mutars brings Assassin's Creed Valhalla into 6DOF VR." -ForegroundColor White
Write-Host " Gamepad controls. Works with Steam, Ubisoft+ and Game Pass copies." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 5 "Locating Assassin's Creed Valhalla"

$gamePath = $null

# Steam
if (Get-Command Try-FindSteamGame -ErrorAction SilentlyContinue) {
 $gamePath = Try-FindSteamGame -Folder $GAME_STEAM_FOLDER -Title "Assassin's Creed Valhalla" -AppID $STEAM_APPID -ExeName $GAME_EXE
}
if (-not $gamePath -and (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue)) {
 $gamePath = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($GAME_STEAM_FOLDER) -ProbeExe $GAME_EXE `
   -EpicNames @("AssassinsCreedValhalla", "Assassin's Creed Valhalla")
}
# Ubisoft Connect / Ubisoft+ / Game Pass and Epic default folders.
# [IO.Path]::Combine + guarded Test-Path (never Join-Path on literal
# drive roots - it throws on machines without that drive).
if (-not $gamePath) {
 $candidates = @(
  "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Assassin's Creed Valhalla",
  "C:\Program Files\Epic Games\AssassinsCreedValhalla",
  "D:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Assassin's Creed Valhalla",
  "E:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Assassin's Creed Valhalla"
 )
 foreach ($cand in $candidates) {
  if (Test-ValhallaRoot -Root $cand) { $gamePath = $cand; break }
 }
}
# Previously recorded install
if (-not $gamePath) {
 $rec = $null
 try { $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
 if ($rec) { $rec = $rec.Trim() }
 if (Test-ValhallaRoot -Root $rec) { $gamePath = $rec }
}
# Manual fallback (typed or drag & dropped folder)
while (-not $gamePath) {
 Write-Warn "Could not find the game automatically."
 Write-Host " Drag & drop your Valhalla GAME FOLDER onto this window (the one" -ForegroundColor White
 Write-Host " containing $GAME_EXE or $GAME_EXE_PLUS), then press Enter." -ForegroundColor White
 Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
 $raw = (Read-Host " Game folder").Trim().Trim('"')
 if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit."; exit 1 }
 if (Test-ValhallaRoot -Root $raw) { $gamePath = $raw }
 else { Write-Fail "That folder does not contain $GAME_EXE / $GAME_EXE_PLUS." }
}

# Which exe is it? (Ubisoft+ / Game Pass ships ACValhalla_Plus.exe)
$exeName = $GAME_EXE
if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $GAME_EXE)))) { $exeName = $GAME_EXE_PLUS }
Write-OK "Found: $gamePath"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile "dxgi.dll" -Label "AnvilEngine2VR"
Write-Info "Game executable: $exeName"

# -------------------------------------------------------
# STEP 2: In-game settings FIRST - before the mod goes in
# -------------------------------------------------------
Write-Step 2 5 "In-game settings - set these BEFORE the mod is installed"

# Ordering is deliberate: once dxgi.dll is in the game folder the game
# boots straight into VR, and the settings menu can FREEZE in the
# headset. Right now the mod is NOT installed yet, so the game still
# starts flat on the monitor and the menu works normally. Front-
# loading the manual step costs a minute here and saves a frozen-menu
# session later.
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - set these in-game settings NOW" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Why now? Once the mod is installed the game boots straight" -ForegroundColor White
Write-Host " into VR - and the settings menu can FREEZE in the headset." -ForegroundColor White
Write-Host " At this point the mod is not in yet, so the game still starts" -ForegroundColor White
Write-Host " flat on your monitor and the menu works normally." -ForegroundColor White
Write-Host ""
Write-Host " In Options -> Display / Graphics set:" -ForegroundColor White
Write-Host ""
# The VALUES are what the user has to act on, so they get green while
# the label stays white and the reason drops to gray. Green reads as
# "set it to this" for ON and OFF alike. Built from -NoNewline
# segments; the padding keeps the "<-" arrows aligned in one column.
Write-Host "   Windowed Mode  : " -NoNewline -ForegroundColor White
Write-Host "ON " -NoNewline -ForegroundColor Green
Write-Host "    <- required, VR will not display" -ForegroundColor Gray
Write-Host "                             correctly in fullscreen" -ForegroundColor Gray
Write-Host "   Vsync          : " -NoNewline -ForegroundColor White
Write-Host "OFF" -NoNewline -ForegroundColor Green
Write-Host "    <- adds latency and judder" -ForegroundColor Gray
Write-Host "   Frame Cap      : " -NoNewline -ForegroundColor White
Write-Host "OFF" -NoNewline -ForegroundColor Green
Write-Host "    <- caps below headset refresh rate" -ForegroundColor Gray
Write-Host "   HDR            : " -NoNewline -ForegroundColor White
Write-Host "OFF" -NoNewline -ForegroundColor Green
Write-Host "    <- washes out / breaks the image" -ForegroundColor Gray
Write-Host "   Depth of Field : " -NoNewline -ForegroundColor White
Write-Host "OFF" -NoNewline -ForegroundColor Green
Write-Host "    <- blurs the world at eye distance" -ForegroundColor Gray
Write-Host ""
Write-Host " [1] Start the game now (flat) so I can set these" -ForegroundColor White
Write-Host " [2] Already set on an earlier run - skip" -ForegroundColor White
Write-Host ""
$sg = ""
while ($sg -notin @("1","2")) { $sg = (Read-Host " Enter 1 or 2").Trim() }
if ($sg -eq "1") {
 # A rerun may already have dxgi.dll in place - then the game WOULD
 # boot in VR. Warn instead of silently launching into the freeze.
 if (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, "dxgi.dll"))) {
  Write-Warn "A dxgi.dll from an earlier install is already in the game"
  Write-Warn "folder, so the game will start IN VR. If the menu freezes:"
  Write-Warn "close the game, delete dxgi.dll from the game folder, set"
  Write-Warn "the settings flat, then rerun this installer."
 }
 try {
  Start-Process -FilePath ([System.IO.Path]::Combine($gamePath, $exeName)) -WorkingDirectory $gamePath
  Write-OK "Game starting... (if nothing happens, launch it from your store instead)"
 } catch {
  Write-Warn "Could not start the game directly: $_"
  Write-Warn "Launch it from Steam / Ubisoft Connect / Epic instead."
 }
 Write-Host ""
 Write-Host " Set the settings listed above, save, then QUIT the game" -ForegroundColor White
 Write-Host " completely - the installation continues only after that." -ForegroundColor White
 Pause-User "Press Enter AFTER the settings are saved and the game is CLOSED..."
} else {
 Write-OK "Skipping - settings already in place."
}

# -------------------------------------------------------
# STEP 2: Pick the runtime build
# -------------------------------------------------------
Write-Step 3 5 "Choosing the runtime build"

Write-Host " [1] OpenXR (recommended) - native OpenXR, runs on any runtime" -ForegroundColor White
Write-Host "     (SteamVR, Virtual Desktop VDXR, Meta, Pimax)" -ForegroundColor Gray
Write-Host " [2] OpenVR - classic SteamVR path; try this if OpenXR" -ForegroundColor White
Write-Host "     misbehaves on your setup" -ForegroundColor Gray
Write-Host ""
$rt = ""
while ($rt -notin @("1","2")) { $rt = (Read-Host " Enter 1 or 2").Trim() }
$useXR = ($rt -eq "1")
if ($useXR) { Write-OK "OpenXR build." } else { Write-OK "OpenVR build." }

# -------------------------------------------------------
# STEP 3: Download the latest release
# -------------------------------------------------------
Write-Step 4 5 "Downloading the latest release"

$variant = if ($useXR) { "openxr" } else { "openvr" }
$dlUrl = $null
$relTag = $null
try {
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 $rel = Invoke-RestMethod -Uri $GITHUB_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
 # The repo covers several AC games; releases may mix assets. Take the
 # Valhalla asset for the chosen runtime, skipping the -symbols build
 # (debug symbols for crash reports - players do not need them).
 $asset = $rel.assets | Where-Object { $_.name -like "Valhalla-vr-$variant*.zip" -and $_.name -notlike "*symbols*" } | Select-Object -First 1
 if ($asset) {
  $dlUrl = $asset.browser_download_url
  $relTag = [string]$rel.tag_name
  Write-Info "Latest release: $relTag"
 } else {
  Write-Warn "The latest release has no Valhalla $variant build (it may be"
  Write-Warn "for another AC game). Using the pinned $PINNED_TAG build."
 }
} catch {
 Write-Warn "Could not query GitHub for the latest release (rate limit / offline)."
 Write-Warn "Falling back to the pinned $PINNED_TAG build."
}
if (-not $dlUrl) {
 $dlUrl = if ($useXR) { $PINNED_URL_XR } else { $PINNED_URL_VR }
 $relTag = $PINNED_TAG
}

$zipPath = Join-Path $env:TEMP ("ACVVR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
if (-not (Invoke-DownloadOrFallback -Url $dlUrl -Destination $zipPath -Label "AnvilEngine2VR ($variant)" `
   -ManualUrl $GITHUB_RELEASES `
   -Instructions "Download Valhalla-vr-$variant-...zip (NOT the -symbols one) from the Releases page, drop it into your Downloads folder and retry.")) {
 $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter "Valhalla-vr-$variant*.zip" -ErrorAction SilentlyContinue |
   Where-Object { $_.Name -notlike "*symbols*" } |
   Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($manualZip) {
  Write-OK "Found a manual download: $($manualZip.Name)"
  $zipPath = $manualZip.FullName
 } else {
  Write-Fail "No AnvilEngine2VR bundle available - cannot continue."
  Pause-User "Press Enter to exit."; exit 1
 }
}

# -------------------------------------------------------
# STEP 4: Install into the game folder
# -------------------------------------------------------
Write-Step 5 5 "Installing into the game folder"

# The zips are flat: dxgi.dll (+ openvr_api.dll for OpenVR) at the
# root, extracted straight into the game folder next to the exe.
# DXGI hooking means the game loads the mod on its own - no launcher.
# Payload-verified extract (pulled from releases/LATEST - layout can
# change any day): temp-extract, resolve real payload root via the known
# mod file, merge into game folder, verify dxgi.dll arrived.
$exRes = Expand-ArchiveToTarget -ArchivePath $zipPath -TargetDir $gamePath -RelModFile "dxgi.dll" -Label "AnvilEngine2VR"
if (-not $exRes) {
 Write-Fail "Extraction failed."
 Pause-User "Press Enter to exit."; exit 1
}
if (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, "dxgi.dll"))) {
 Write-OK "Mod files in place (dxgi.dll in the game root)."
} else {
 Write-Fail "dxgi.dll missing after extraction - the bundle layout may have changed."
 Pause-User "Press Enter to exit."; exit 1
}
# Switching OpenVR -> OpenXR leaves an old openvr_api.dll behind;
# that is harmless (dxgi.dll decides the runtime), so it stays.
if ($zipPath -like (Join-Path $env:TEMP "*")) { try { Remove-Item -LiteralPath $zipPath -Force } catch {} }

# Hub markers: install path + EXACT release tag for the update badge,
# and .launch_exe so "Start in VR" opens the right exe (Ubisoft+ /
# Game Pass installs use ACValhalla_Plus.exe).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value ([System.IO.Path]::Combine($gamePath, $exeName)) -Encoding UTF8 -Force } catch {}


# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""
Write-Host " HOW TO PLAY:" -ForegroundColor Yellow
Write-Host "  1. Start your OpenXR runtime (SteamVR, Virtual Desktop, Meta," -ForegroundColor White
Write-Host "     Pimax) - for the OpenVR build, start SteamVR." -ForegroundColor White
Write-Host "  2. Launch the game normally (any store) or" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in" -ForegroundColor White
Write-Host "     the Hub - the mod loads with the game via DXGI." -ForegroundColor White
Write-Host "  !! In-game settings (done in step 2): Windowed " -NoNewline -ForegroundColor Yellow
Write-Host "ON" -NoNewline -ForegroundColor Green
Write-Host ", Vsync /" -ForegroundColor Yellow
Write-Host "     Frame Cap / HDR / Depth of Field " -NoNewline -ForegroundColor Yellow
Write-Host "OFF" -NoNewline -ForegroundColor Green
Write-Host ". A game update or a" -ForegroundColor Yellow
Write-Host "     settings reset can undo them - recheck if VR acts up later." -ForegroundColor Yellow
Write-Host "  3. Full 6DOF head tracking and head aim are active; HUD" -ForegroundColor White
Write-Host "     scale is adjustable in the mod settings." -ForegroundColor White
Write-Host ""
Write-Host " KNOWN LIMITATIONS (mod is in active development):" -ForegroundColor Yellow
Write-Host "  - Dialogs render in stereo but display letterboxed" -ForegroundColor Gray
Write-Host "  - Water and some effects vanish when looking opposite to" -ForegroundColor Gray
Write-Host "    the character" -ForegroundColor Gray
Write-Host ""
Write-Host " Skol! Raid England the way Odin intended." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

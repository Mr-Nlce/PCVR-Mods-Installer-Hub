# ============================================================
# Warhammer 40,000: Rogue Trader - VR Mod Installer (RTVR)
# ============================================================
# RTVR by SolemnScribe: true stereo 3D, UI on a floating panel,
# seated KB&M / gamepad play (no motion controllers).
#
# Rogue Trader ships with Owlcat's BUILT-IN Unity Mod Manager,
# which loads mods ONLY from the user profile:
#   %USERPROFILE%\AppData\LocalLow\Owlcat Games\
#       Warhammer 40000 Rogue Trader\UnityModManager\<ModId>\
# So unlike most Hub games the mod payload does NOT go into the
# game folder - there is no alternative location. Hub bookkeeping
# markers (.installed_path/.installed_version) stay in the Hub
# folder as always.
#
# Mods installed (all via guided Nexus download - Nexus requires
# a login, automatic download is not possible):
#   1. WASD Movement          (required)   zip has files at ROOT
#   2. Toy Box                (required)   zip has files at ROOT
#   3. RTVR                   (the mod)    zip brings RTVR\ folder
#   4. Servo-Skull Camera     (OPTIONAL)   zip brings its folder
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Warhammer 40K: Rogue Trader VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_STEAM_FOLDER = "Warhammer 40,000 Rogue Trader"
$GAME_EXE  = "WH40KRT.exe"
$STEAM_APPID = "2186680"
$DOWNLOAD_DIR = Join-Path $env:USERPROFILE "Downloads"

# Owlcat's built-in Unity Mod Manager folder (the ONLY place the
# game loads mods from). Note: folder name has NO comma.
$OWLCAT_DIR = Join-Path $env:USERPROFILE "AppData\LocalLow\Owlcat Games\Warhammer 40000 Rogue Trader"
$UMM_DIR    = Join-Path $OWLCAT_DIR "UnityModManager"

# Nexus pages (files tab = straight to downloads)
$NEXUS_RTVR  = "https://www.nexusmods.com/warhammer40kroguetrader/mods/518?tab=files"
$NEXUS_WASD  = "https://www.nexusmods.com/warhammer40kroguetrader/mods/334?tab=files"
$NEXUS_TOYBOX = "https://www.nexusmods.com/warhammer40kroguetrader/mods/1?tab=files"
$NEXUS_SERVO = "https://www.nexusmods.com/warhammer40kroguetrader/mods/457?tab=files"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Warhammer 40,000: Rogue Trader - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " RTVR by SolemnScribe" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}

function Write-Step {
 param($num, $total, $text)
 Write-Host ""
 Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
 Write-Host ""
}

function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraries {
 param($steamPath)
 $libraries = @($steamPath)
 $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdfPath) {
 $content = Get-Content $vdfPath -Raw
 $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
 foreach ($m in $found) {
 $lib = $m.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $lib) { $libraries += $lib }
 }
 }
 return $libraries
}

# -------------------------------------------------------
# Reusable: guided Nexus download + install into the UMM folder.
# One function drives all four mods so required, optional and
# reinstall paths can never drift apart.
#   -TargetSubfolder : create this folder and put the zip's ROOT
#                      files into it (WASD / Toy Box style zips).
#                      Omit when the zip already brings its own
#                      top-level mod folder (RTVR / Servo-Skull).
#   -VerifyFile      : path relative to the UMM folder that must
#                      exist afterwards for the install to count.
# Returns $true on success.
# -------------------------------------------------------
function Install-UmmMod {
 param(
  [string]$Label,
  [string]$NexusUrl,
  [string]$ZipPattern,
  [string]$TargetSubfolder = "",
  [string]$VerifyFile,
  [string]$Purpose = ""
 )

 Write-Host " $Label" -ForegroundColor White
 if ($Purpose) { Write-Host " $Purpose" -ForegroundColor Gray }
 Write-Host " Nexus: $NexusUrl" -ForegroundColor Gray
 Write-Host ""

 $askedForNexus = $false

 # Find an existing download first
 $zip = Get-ChildItem -Path $DOWNLOAD_DIR -Filter $ZipPattern -ErrorAction SilentlyContinue |
   Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($zip) {
  Write-OK "Found existing download: $($zip.Name)"
  Write-Host " [1] Use this file" -ForegroundColor White
  Write-Host " [2] Open Nexus and download fresh" -ForegroundColor White
  $c = ""
  while ($c -notin @("1","2")) { $c = (Read-Host " Enter 1 or 2").Trim() }
  if ($c -eq "2") { $zip = $null; $askedForNexus = $true }
 }

 if (-not $zip) {
  # Gate BEFORE the browser opens. Start-Process yanks the browser to
  # the foreground, so without this the page appeared before the user
  # could read what this mod even is. Skipped when they just chose
  # "[2] Open Nexus" - they asked for it one keypress ago.
  if (-not $askedForNexus) {
   Write-Host " Nexus Mods blocks automated downloads, so this part is manual:" -ForegroundColor White
   Write-Host " the mod page opens in your browser and you grab the file." -ForegroundColor White
   Pause-User "Press Enter to open the Nexus page for: $Label"
  }
  Start-Process $NexusUrl
  Write-Host ""
  Write-Host " Nexus Mods is now open in your browser." -ForegroundColor Cyan
  Write-Host " - Log in if needed" -ForegroundColor Gray
  Write-Host " - On the Files tab, click MANUAL DOWNLOAD on the latest file" -ForegroundColor Gray
  Write-Host " - Nexus then shows a REQUIREMENTS page listing other mods." -ForegroundColor Yellow
  Write-Host "   Nothing is wrong and nothing is missing - this installer" -ForegroundColor Yellow
  Write-Host "   sets those up for you; that is what its other steps are." -ForegroundColor Yellow
  Write-Host "   Click MANUAL DOWNLOAD a SECOND time to start the download." -ForegroundColor Yellow
  Write-Host " - Save it to your Downloads folder, OR drag & drop the" -ForegroundColor Gray
  Write-Host "   downloaded zip into THIS window" -ForegroundColor Gray
  Write-Host ""
  # Dragging a file onto the console pastes its path onto the input
  # line, so one prompt covers both flows: plain Enter = look in
  # Downloads; a dropped/typed path = use that file directly.
  Write-Host " >>> Drag & drop the zip here, or just press Enter when the download is done " -ForegroundColor Black -BackgroundColor Yellow
  $dropped = (Read-Host).Trim().Trim('"')
  if ($dropped -and (Test-Path -LiteralPath $dropped)) {
   $zip = Get-Item -LiteralPath $dropped
  } else {
   if ($dropped) { Write-Warn "Not a valid file path - checking your Downloads folder instead." }
   $zip = Get-ChildItem -Path $DOWNLOAD_DIR -Filter $ZipPattern -ErrorAction SilentlyContinue |
     Sort-Object LastWriteTime -Descending | Select-Object -First 1
  }
  while (-not $zip) {
   Write-Warn "No file matching '$ZipPattern' found in $DOWNLOAD_DIR"
   Write-Host " [1] Try again (after finishing the download)" -ForegroundColor White
   Write-Host " [2] Drag & drop the zip into this window (or type its path)" -ForegroundColor White
   $c = ""
   while ($c -notin @("1","2")) { $c = (Read-Host " Enter 1 or 2").Trim() }
   if ($c -eq "1") {
    $zip = Get-ChildItem -Path $DOWNLOAD_DIR -Filter $ZipPattern -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
   } else {
    $rawInput = (Read-Host " Drop the file here (or type the full path)").Trim().Trim('"')
    if (Test-Path -LiteralPath $rawInput) { $zip = Get-Item -LiteralPath $rawInput } else { Write-Fail "File not found: $rawInput" }
   }
  }
 }
 Write-OK "Using: $($zip.Name)"

 # Extract to temp, then place into the UMM folder
 $tempDir = Join-Path $env:TEMP ("RTVRInstaller_" + [System.IO.Path]::GetRandomFileName())
 New-Item -ItemType Directory -Path $tempDir | Out-Null
 try {
  Write-Host " Extracting ... " -NoNewline -ForegroundColor White
  Expand-Archive -LiteralPath $zip.FullName -DestinationPath $tempDir -Force
  Write-Host "OK" -ForegroundColor Green

  # Where do the mod files live inside the zip? Two layouts exist:
  #  a) files at the zip ROOT (Info.json directly)  -> needs $TargetSubfolder
  #  b) one top-level mod folder containing Info.json -> copy folder as-is
  # We detect instead of assuming, so a re-packaged future zip
  # still installs correctly either way.
  $rootInfo = Join-Path $tempDir "Info.json"
  if (Test-Path $rootInfo) {
   if (-not $TargetSubfolder) {
    # Zip unexpectedly flat and we have no folder name: derive it
    # from Info.json's Id so the game's mod manager finds it.
    try {
     $info = Get-Content $rootInfo -Raw | ConvertFrom-Json
     $TargetSubfolder = [string]$info.Id
    } catch {}
    if (-not $TargetSubfolder) { throw "Zip is flat and mod Id could not be read from Info.json." }
   }
   $dest = Join-Path $UMM_DIR $TargetSubfolder
   New-Item -ItemType Directory -Path $dest -Force | Out-Null
   Get-ChildItem -Path $tempDir | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
   }
  } else {
   # Copy every top-level folder that carries an Info.json (in
   # practice exactly one: RTVR\ or ServoSkullCameraControls\).
   $copied = $false
   Get-ChildItem -Path $tempDir -Directory | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName "Info.json")) {
     Copy-Item -Path $_.FullName -Destination $UMM_DIR -Recurse -Force
     $copied = $true
    }
   }
   if (-not $copied) { throw "No mod folder with Info.json found inside the zip." }
  }

  # Verify
  $probe = Join-Path $UMM_DIR $VerifyFile
  if (Test-Path $probe) {
   Write-OK "$Label installed."
   # Remember the zip that was actually used (drag & drop can come
   # from anywhere, not just Downloads) - the version marker below
   # parses this instead of guessing from the Downloads folder.
   $script:LastInstalledZipName = $zip.Name
   return $true
  } else {
   Write-Fail "$Label - expected file missing after install: $VerifyFile"
   return $false
  }
 } catch {
  Write-Host "FAILED" -ForegroundColor Red
  Write-Host " $_" -ForegroundColor Gray
  return $false
 } finally {
  try { Remove-Item $tempDir -Recurse -Force } catch {}
 }
}

# -------------------------------------------------------
# STEP 1: Locate the game (info only - mods do NOT go there)
# -------------------------------------------------------
Write-Header
Write-Step 1 7 "Locating Warhammer 40,000: Rogue Trader"

Write-Info "The game itself can live anywhere (Steam, GOG, Epic, Xbox)."
Write-Info "Mods install into Owlcat's built-in mod manager folder in your"
Write-Info "user profile, so the game folder is only checked for information."
Write-Host ""

$gamePath = $null
# Steam via detection library, then legacy lookup
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
  . $__utilsPath
  $gamePath = Try-FindSteamGame -Folder $GAME_STEAM_FOLDER -Title "Warhammer 40,000: Rogue Trader" -AppID $STEAM_APPID -ExeName $GAME_EXE
 }
} catch {}
if (-not $gamePath) {
 $steamPath = Get-SteamPath
 if ($steamPath) {
  foreach ($lib in (Get-SteamLibraries $steamPath)) {
   $candidate = Join-Path $lib "steamapps\common\$GAME_STEAM_FOLDER"
   if (Test-Path (Join-Path $candidate $GAME_EXE)) { $gamePath = $candidate; break }
  }
 }
}
if (-not $gamePath -and (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue)) {
 $gamePath = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($GAME_STEAM_FOLDER) -ProbeExe $GAME_EXE `
   -GogNames @("Warhammer 40,000 Rogue Trader") -EpicNames @("Warhammer40000RogueTrader")
}
# GOG / Epic / Xbox default locations
if (-not $gamePath) {
 foreach ($cand in @(
  "C:\GOG Games\Warhammer 40,000 Rogue Trader",
  "C:\Program Files\Epic Games\Warhammer40000RogueTrader",
  "C:\XboxGames\Warhammer 40,000 Rogue Trader\Content"
 )) {
  if (Test-Path (Join-Path $cand $GAME_EXE)) { $gamePath = $cand; break }
 }
}

if ($gamePath) {
 Write-OK "Game found: $gamePath"
} else {
 Write-Warn "Game folder not found automatically (Steam/GOG/Epic/Xbox defaults)."
 Write-Host " That is fine - the mods do not install there. If the game IS" -ForegroundColor Gray
 Write-Host " installed and has been run once, everything will still work." -ForegroundColor Gray
}

# -------------------------------------------------------
# STEP 2: Verify the game has been run once (UMM folder)
# -------------------------------------------------------
Write-Step 2 7 "Checking Owlcat's mod manager folder"

Write-Info "Rogue Trader has a BUILT-IN Unity Mod Manager. It loads mods from:"
Write-Host " $UMM_DIR" -ForegroundColor Gray
Write-Host ""

while (-not (Test-Path $OWLCAT_DIR)) {
 Write-Warn "The game's profile folder does not exist yet:"
 Write-Host " $OWLCAT_DIR" -ForegroundColor Gray
 Write-Host ""
 Write-Host " The game must be launched at least ONCE to create it." -ForegroundColor White
 Write-Host " Start the game now, reach the main menu, then quit." -ForegroundColor White
 Pause-User "Press Enter after you have launched the game once..."
}
if (-not (Test-Path $UMM_DIR)) {
 New-Item -ItemType Directory -Path $UMM_DIR -Force | Out-Null
 Write-OK "Created the UnityModManager folder."
} else {
 Write-OK "Mod manager folder found."
}

# -------------------------------------------------------
# Already installed? Offer Update vs Reinstall
# -------------------------------------------------------
$updateMode = $false
if (Test-Path (Join-Path $UMM_DIR "RTVR\RTVR.dll")) {
 Write-Host ""
 Write-Host " RTVR is already installed." -ForegroundColor Cyan
 Write-Host " [U] Update    - grab the newest RTVR from Nexus; required mods are" -ForegroundColor White
 Write-Host "                 only reinstalled if they are missing" -ForegroundColor White
 Write-Host " [R] Reinstall - set everything up again from scratch" -ForegroundColor White
 Write-Host ""
 $uAns = ""
 while ($uAns -notin @("U","R")) { $uAns = (Read-Host " Enter U or R").Trim().ToUpper() }
 if ($uAns -eq "U") { $updateMode = $true; Write-OK "Update mode - settings and saves stay; mods are refreshed." }
 else { Write-Info "Reinstalling from scratch." }
}

$failed = @()

# -------------------------------------------------------
# STEP 3: WASD Movement (required)
# -------------------------------------------------------
Write-Step 3 7 "Installing WASD Movement (required)"

$wasdPresent = Test-Path (Join-Path $UMM_DIR "WASDMovement\Info.json")
if ($updateMode -and $wasdPresent) {
 Write-OK "WASD Movement already installed - keeping it."
} else {
 if (-not (Install-UmmMod -Label "WASD Movement (moves selected characters with WASD)" `
   -NexusUrl $NEXUS_WASD -ZipPattern "WASDMovement*.zip" `
  -Purpose "REQUIRED by RTVR. Adds WASD character movement." `
   -TargetSubfolder "WASDMovement" -VerifyFile "WASDMovement\WASDMovement.dll")) {
  $failed += "WASD Movement"
 }
}

# -------------------------------------------------------
# STEP 4: Toy Box (required)
# -------------------------------------------------------
Write-Step 4 7 "Installing Toy Box (required)"

$toyPresent = Test-Path (Join-Path $UMM_DIR "0ToyBox0\Info.json")
if ($updateMode -and $toyPresent) {
 Write-OK "Toy Box already installed - keeping it."
} else {
 if (-not (Install-UmmMod -Label "Toy Box (cheats/tweaks toolbox; RTVR builds on it)" `
   -NexusUrl $NEXUS_TOYBOX -ZipPattern "ToyBox*.zip" `
  -Purpose "REQUIRED by RTVR." `
   -TargetSubfolder "0ToyBox0" -VerifyFile "0ToyBox0\ToyBox.dll")) {
  $failed += "Toy Box"
 }
}

# -------------------------------------------------------
# STEP 5: RTVR itself
# -------------------------------------------------------
Write-Step 5 7 "Installing RTVR (the VR mod)"

$rtvrOk = Install-UmmMod -Label "RTVR (Rogue Trader VR by SolemnScribe)" `
  -NexusUrl $NEXUS_RTVR -ZipPattern "RTVR*.zip" `
  -Purpose "The VR mod itself - this is the one that makes the game VR." `
  -VerifyFile "RTVR\RTVR.dll"
if ($rtvrOk) { $rtvrZipName = $script:LastInstalledZipName } else { $failed += "RTVR"; $rtvrZipName = $null }

# -------------------------------------------------------
# STEP 6: Servo-Skull Camera Controls (OPTIONAL)
# -------------------------------------------------------
Write-Step 6 7 "Optional: Servo-Skull Camera Controls"

Write-Host " Servo-Skull adds a third-person, over-the-shoulder camera with" -ForegroundColor White
Write-Host " mouselook and saveable views. RTVR is built on its camera work" -ForegroundColor White
Write-Host " and it pairs well with VR, but it is NOT required." -ForegroundColor White
Write-Host ""
$servoPresent = Test-Path (Join-Path $UMM_DIR "ServoSkullCameraControls\Info.json")
if ($servoPresent) {
 Write-OK "Servo-Skull is already installed - keeping it."
} else {
 Write-Host " Install Servo-Skull Camera Controls? [Y/N]" -ForegroundColor Yellow
 $sAns = ""
 while ($sAns -notin @("Y","N")) { $sAns = (Read-Host " Enter Y or N").Trim().ToUpper() }
 if ($sAns -eq "Y") {
  if (-not (Install-UmmMod -Label "Servo-Skull Camera Controls (3rd-person camera)" `
    -NexusUrl $NEXUS_SERVO -ZipPattern "ServoSkullCameraControls*.zip" `
  -Purpose "Optional. 3rd-person over-the-shoulder camera; RTVR builds on its camera work." `
    -VerifyFile "ServoSkullCameraControls\ServoSkullCameraControls.dll")) {
   $failed += "Servo-Skull (optional)"
  }
 } else {
  Write-Info "Skipping Servo-Skull. You can rerun this installer later to add it."
 }
}

# -------------------------------------------------------
# STEP 7: Required key rebinds + wrap-up
# -------------------------------------------------------
Write-Step 7 7 "Required in-game key rebinds"

Write-Host " RTVR needs FOUR keys rebound in the game's own Controls menu" -ForegroundColor Yellow
Write-Host " (Settings -> Controls), one time:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Rotate camera left   ->  A" -ForegroundColor White
Write-Host "   Rotate camera right  ->  D" -ForegroundColor White
Write-Host "   Pan camera left      ->  Q" -ForegroundColor White
Write-Host "   Pan camera right     ->  E" -ForegroundColor White
Write-Host ""
Write-Host " (WASD Movement drives your character; these rebinds stop the" -ForegroundColor Gray
Write-Host " camera from fighting it.)" -ForegroundColor Gray
Pause-User "Press Enter to confirm you will rebind these on first launch..."

# Record install path + version for the Hub's VR-Ready refresh.
# The recorded path is the UMM folder (where RTVR\RTVR.dll lives).
if ("RTVR" -notin $failed) {
 try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $UMM_DIR -Encoding UTF8 -Force } catch {}
 # Version: parse from the Nexus zip name (RTVR_518_0_6_151_...),
 # falling back to the pinned release this installer shipped for.
 # Parse the version from the zip we actually installed (works for
 # drag & drop too); fall back to the pinned release.
 $rtvrVer = "0.6.151"
 try {
  if ($rtvrZipName -and $rtvrZipName -match 'RTVR[_-]\d+[_-](\d+)[_-](\d+)[_-](\d+)') {
   $rtvrVer = "$($matches[1]).$($matches[2]).$($matches[3])"
  }
 } catch {}
 try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $rtvrVer -Encoding UTF8 -Force } catch {}
}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor White
Write-Host ""
if ("WASD Movement" -notin $failed) { Write-Host " [x] WASD Movement (required)" -ForegroundColor Green } else { Write-Host " [ ] WASD Movement -- FAILED" -ForegroundColor Red }
if ("Toy Box" -notin $failed) { Write-Host " [x] Toy Box (required)" -ForegroundColor Green } else { Write-Host " [ ] Toy Box -- FAILED" -ForegroundColor Red }
if ("RTVR" -notin $failed) { Write-Host " [x] RTVR" -ForegroundColor Green } else { Write-Host " [ ] RTVR -- FAILED" -ForegroundColor Red }
if (Test-Path (Join-Path $UMM_DIR "ServoSkullCameraControls\Info.json")) { Write-Host " [x] Servo-Skull Camera Controls (optional)" -ForegroundColor Green } else { Write-Host " [-] Servo-Skull Camera Controls (optional, skipped)" -ForegroundColor Gray }
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- How to play ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " 1. Rebind the four camera keys (see above) in Settings -> Controls." -ForegroundColor White
Write-Host " 2. Start SteamVR, then launch the game normally." -ForegroundColor White
Write-Host " 3. Load into a save - VR starts automatically." -ForegroundColor White
Write-Host "    Ctrl+Alt+V starts/stops VR manually." -ForegroundColor Gray
Write-Host " 4. Ctrl+F10 opens the mod settings overlay (NOT Shift+F10)." -ForegroundColor White
Write-Host "    Hold Left-Shift to unlock your cursor." -ForegroundColor Gray
Write-Host ""
Write-Host "--- VR graphics settings worth changing (in-game options) ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " - Depth of field: OFF (disorienting in a headset)" -ForegroundColor White
Write-Host " - Camera shake: OFF (comfort)" -ForegroundColor White
Write-Host " - SSR (screen-space reflections): Low or Off (big perf win)" -ForegroundColor White
Write-Host " - FSR: OFF in VR (use RTVR's render scale instead)" -ForegroundColor White
Write-Host " - Anti-aliasing: SMAA over TAA (less smearing)" -ForegroundColor White
Write-Host ""
Write-Host " RTVR's render scale ships at 0.75 - raise it toward 1.0 if your" -ForegroundColor Gray
Write-Host " GPU has headroom. Ctrl+Alt+C recenters the view any time." -ForegroundColor Gray
Write-Host ""
Write-Host " The Emperor protects. The Warp... does not." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

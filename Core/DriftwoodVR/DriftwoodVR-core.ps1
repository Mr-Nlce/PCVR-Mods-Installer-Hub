# -------------------------------------------------------
# Driftwood VR Mod Installer
# by Astienth - distributed via GitHub
#
# Walks the user through:
# 1. Auto-download mod ZIP from GitHub release + locate
# Driftwood install folder
# 2. Extract mod files in place
#
# GitHub-distributed (public release URL), so the installer
# fetches the ZIP itself via Invoke-WebRequest. A failed download
# offers retry or a manually downloaded ZIP.
#
# This is a motion-controls mod with full body-lean gameplay:
# - Lean left/right in real life to steer
# - Lean forward to accelerate
# - Raise BOTH hands above your head for air break
# The left joystick (steering) ALWAYS prevails over the
# motion gaming movements - lean-to-turn is additive.
#
# VR-controller input goes directly through OpenVR/SteamVR -
# no virtual gamepad layer, so no ViGEmBus step needed.
#
# bHaptics support (vest + arms) bundled in.
#
# Naming pitfall: the GitHub ZIP filename has a typo -
# "Drifwood" (one 'f'), not "Driftwood". The repo name uses
# capital W ("DriftWood_VR_bHaptics"). The game itself, the
# install folder, and the DLL all use the correct two-'f'
# spelling. Don't second-guess - the URL is right.
# -------------------------------------------------------


# Shared archive, recovery and transaction helpers.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "Driftwood_VR"
$MOD_VERSION = "1.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2223700"
$GAME_NAME = "Driftwood"
$GAME_EXE = "Driftwood.exe"

# GitHub URLs - direct, no login required.
# Note: ZIP filename has the "Drifwood" typo (one 'f') and the
# repo name capitalises the W. Both are intentional - that's
# how Astienth published the release.
$GITHUB_REPO_URL = "https://github.com/Astienth/DriftWood_VR_bHaptics"
$GITHUB_DOWNLOAD_URL = "https://github.com/Astienth/DriftWood_VR_bHaptics/releases/download/1.0/Drifwood_VRMod_bHaptics.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Driftwood VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}

function Write-Step {
 param([int]$Step, [int]$Total, [string]$Title)
 Write-Host ""
 Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
 Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @(
 "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
 "HKLM:\SOFTWARE\Valve\Steam",
 "HKCU:\SOFTWARE\Valve\Steam"
 )) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraries {
 param($SteamPath)
 $libs = @()
 if (-not $SteamPath) { return $libs }
 $libs += $SteamPath
 $vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
 $l = $_.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $l) { $libs += $l }
 }
 }
 return ($libs | Select-Object -Unique)
}

function Find-DriftwoodGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Driftwood" (single word, no spaces).
 # The Unity data folder mirrors that as "Driftwood_Data".
 # Demo (during early-access period) used the same naming
 # but with " Demo" suffix; we try that as a last resort.
 foreach ($folder in @("Driftwood", "Driftwood Demo")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Driftwood_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Driftwood VR is distributed as a public GitHub release." -ForegroundColor White
Write-Host " The installer fetches the ZIP directly and extracts it." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a MOTION CONTROLS mod with full body lean:" -ForegroundColor White
Write-Host " - Lean left / right to steer" -ForegroundColor White
Write-Host " - Lean forward to accelerate" -ForegroundColor White
Write-Host " - Raise BOTH hands above your head for air break" -ForegroundColor White
Write-Host " The left joystick (steering) always overrides motion" -ForegroundColor White
Write-Host " gaming - they're additive, joystick wins." -ForegroundColor White
Write-Host ""
Write-Host " Stand-up VR play is recommended for the lean motions to" -ForegroundColor White
Write-Host " feel right." -ForegroundColor White
Write-Host ""
Write-Host " No ViGEmBus needed - VR controllers wire directly through" -ForegroundColor White
Write-Host " OpenVR/SteamVR." -ForegroundColor White
Write-Host ""
Write-Host " bHaptics support is bundled in (vest + arms). If you have" -ForegroundColor White
Write-Host " bHaptics gear, launch the bHaptics Player and turn the" -ForegroundColor White
Write-Host " devices on BEFORE launching the game." -ForegroundColor White
Write-Host ""
Write-Host " Source repo (info, README, support):" -ForegroundColor Gray
Write-Host " $GITHUB_REPO_URL" -ForegroundColor DarkGray
Write-Host ""
Show-AntivirusNotice -Compact
Pause-User "Press Enter to start the install..."

# -------------------------------------------------------
# STEP 1: Locate Driftwood + download mod
# -------------------------------------------------------
Write-Step 1 2 "Locating Driftwood + downloading mod"

$gamePath = Find-DriftwoodGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2223700" -SteamFolderNames @("Driftwood") }
if ($gamePath -and ((-not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE) -PathType Leaf)) -or
    (-not (Test-Path -LiteralPath (Join-Path $gamePath 'Driftwood_Data\globalgamemanagers') -PathType Leaf)))) {
 Write-Warn "Found a folder without the Driftwood executable and Unity game data: $gamePath"
 $gamePath = $null
}
if ($gamePath) {
 Write-OK "Found Driftwood at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Driftwood in any Steam library."
 Write-Host " Please paste the path to your Driftwood folder" -ForegroundColor White
 Write-Host " (the folder containing Driftwood.exe and Driftwood_Data)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $answer = Read-Host " Driftwood folder or Q to quit"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if ((Test-Path -LiteralPath (Join-Path $r $GAME_EXE) -PathType Leaf) -and
     (Test-Path -LiteralPath (Join-Path $r 'Driftwood_Data\globalgamemanagers') -PathType Leaf)) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Complete Driftwood game files not found in: $r"
 }
 }
}

# Download from GitHub. A failed transfer or wrong archive stays recoverable.
$modZip = Join-Path $env:TEMP "DriftwoodVR_$([System.IO.Path]::GetRandomFileName()).zip"
$anchors = @('(?i)(?:^|\\)winhttp\.dll$',
             '(?i)(?:^|\\)BepInEx\\plugins\\Driftwood_VR\.dll$',
             '(?i)(?:^|\\)BepInEx\\core\\BepInEx\.Preloader\.dll$',
             '(?i)(?:^|\\)BepInEx\\config\\UnityVR_Bepinex\.cfg$')
$archiveReady = $false
while (-not $archiveReady) {
 if (-not (Test-Path -LiteralPath $modZip -PathType Leaf)) {
  Write-Host " Downloading mod ZIP from GitHub..." -ForegroundColor Gray
  Write-Host " $GITHUB_DOWNLOAD_URL" -ForegroundColor DarkGray
  try {
   [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
   Invoke-PCVRWebRequest -Uri $GITHUB_DOWNLOAD_URL -OutFile $modZip -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
  } catch { Write-Fail "Download failed: $_" }
 }
 if ((Test-DownloadedPayload -Path $modZip -IntendedPath 'Drifwood_VRMod_bHaptics.zip') -and
     (Test-ZipPayloadAnchors -Path $modZip -AnchorPatterns $anchors -MinimumMatches $anchors.Count)) {
  $archiveReady = $true
  Write-OK 'Readable Driftwood VR runtime found.'
  break
 }
 if (Test-Path -LiteralPath $modZip -PathType Leaf) {
  Write-Fail 'The downloaded ZIP is unreadable, unsafe, or missing the Driftwood VR runtime.'
  Remove-Item -LiteralPath $modZip -Force -ErrorAction SilentlyContinue
 }
 Write-Host " [R] Retry GitHub  [P] Use a downloaded ZIP  [Q] Quit" -ForegroundColor Yellow
 $answer = Read-Host ' Recovery choice'
 if ($null -eq $answer -or $answer.Trim() -ieq 'Q') { exit 1 }
 if ($answer.Trim() -ieq 'P') {
  $pathAnswer = Read-Host ' Complete ZIP path or Q'
  if ($null -eq $pathAnswer -or $pathAnswer.Trim() -ieq 'Q') { exit 1 }
  $manual = $pathAnswer.Trim().Trim('"')
  if (-not (Test-Path -LiteralPath $manual -PathType Leaf) -or $manual -notmatch '(?i)\.zip$') {
   Write-Fail 'Choose an existing ZIP file.'
   continue
  }
  try { Copy-Item -LiteralPath $manual -Destination $modZip -Force -ErrorAction Stop }
  catch { Write-Fail "Cannot use that ZIP: $_" }
 } elseif ($answer.Trim() -ine 'R') { Write-Fail 'Choose R, P or Q.' }
}

# -------------------------------------------------------
# STEP 2: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 2 2 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "DriftwoodVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null
$extractResult = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract -Label 'Driftwood VR' -AllowSkip $false
if ([string]$extractResult -notin @('ok','manual','retry')) {
 Write-Fail 'The VR archive was not extracted. The game was not changed.'
 Pause-User 'Press Enter to exit...'
 exit 1
}

$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 if ($rootEntries[0].Name -ne "BepInEx") { $srcRoot = $rootEntries[0].FullName }
}

$requiredModFiles = @('winhttp.dll', 'doorstop_config.ini',
 'BepInEx\core\BepInEx.Preloader.dll', 'BepInEx\core\BepInEx.dll',
 'BepInEx\plugins\Driftwood_VR.dll', 'BepInEx\plugins\Bhaptics.Tact.dll',
 'BepInEx\config\UnityVR_Bepinex.cfg', 'Driftwood_Data\Assets\hands',
 'Driftwood_Data\Managed\SteamVR.dll')
try { $payloadHashes = Get-PCVRDropInSourceHashes -SourceRoot $srcRoot -RequiredFiles $requiredModFiles }
catch { Write-Fail "The extracted VR package is incomplete: $_"; Pause-User 'Press Enter to exit...'; exit 1 }

Write-Host " Copying files into: $gamePath" -ForegroundColor Gray
$contract = New-PCVRInstallerContract -Id 'driftwood-vr' -GameName 'Driftwood VR' -Acquisition GitHub -ReleasePageUrl "$GITHUB_REPO_URL/releases" -AntivirusNotice -RequiredInstalledFileGroups (@($GAME_EXE, 'Driftwood_Data\globalgamemanagers', 'winhttp.dll|winhttp_bak.dll') + @($requiredModFiles | Where-Object { $_ -ne 'winhttp.dll' }))
$keepConfigs = @('BepInEx\config\BepInEx.cfg', 'BepInEx\config\UnityVR_Bepinex.cfg')
$activeProxy = Join-Path $gamePath 'winhttp.dll'
$parkedProxy = Join-Path $gamePath 'winhttp_bak.dll'
$wasFlat = (Test-Path -LiteralPath $parkedProxy -PathType Leaf) -and -not (Test-Path -LiteralPath $activeProxy -PathType Leaf)
$oldParkedBytes = if ($wasFlat) { [IO.File]::ReadAllBytes($parkedProxy) } else { $null }
$preservedConfigs = @($keepConfigs | Where-Object { Test-Path -LiteralPath (Join-Path $gamePath $_) -PathType Leaf })
$installed = $false
while (-not $installed) {
 $copyTransaction = $null
 try {
  $copyTransaction = Install-PCVRDropInCopy -SourceRoot $srcRoot -GameRoot $gamePath -SourceHashes $payloadHashes -KeepExistingFiles $keepConfigs
  Assert-PCVRDropInCopiedFiles -GameRoot $gamePath -SourceHashes $payloadHashes -PreservedExistingFiles $preservedConfigs
  if ($wasFlat) {
   Copy-Item -LiteralPath $activeProxy -Destination $parkedProxy -Force -ErrorAction Stop
   Remove-Item -LiteralPath $activeProxy -Force -ErrorAction Stop
  }
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gamePath -Version $MOD_VERSION -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
  $installed = $true
 } catch {
  $failure = $_
  if ($copyTransaction) {
   try { Undo-PCVRDropInCopy -Transaction $copyTransaction }
   catch { throw "Driftwood install failed and rollback failed: $failure; $_" }
  }
  if ($wasFlat) { [IO.File]::WriteAllBytes($parkedProxy,[byte[]]$oldParkedBytes) }
  Write-Fail "Installation failed; previous files were restored: $failure"
  Write-Host ' Correct the file or permission problem, then choose [R] to retry.' -ForegroundColor Yellow
  $retry = Read-Host ' [R] Retry / [Q] Quit'
  if ($null -eq $retry -or $retry.Trim() -notmatch '^(?i:r)$') { exit 1 }
 }
}
try { Complete-PCVRDropInCopy -Transaction $copyTransaction }
catch { Write-Warn "Temporary rollback snapshot could not be removed: $_" }
Write-OK 'VR runtime and version verified; existing configuration kept.'
try { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}
try { Remove-Item -LiteralPath $modZip -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " BEFORE LAUNCHING:" -ForegroundColor Yellow
Write-Host " If you have bHaptics devices, launch the bHaptics Player" -ForegroundColor White
Write-Host " and turn the devices on. The mod detects them at startup." -ForegroundColor White
Write-Host ""
Write-Host " Launch Driftwood normally via Steam, the desktop shortcut," -ForegroundColor White
Write-Host " or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Controls:" -ForegroundColor White
Write-Host " Left stick -> Steering / accelerate / air brake / UI" -ForegroundColor Gray
Write-Host " up = accelerate, down = air brake," -ForegroundColor Gray
Write-Host " left/right = steer" -ForegroundColor Gray
Write-Host " Right stick -> Look around (click = pause menu)" -ForegroundColor Gray
Write-Host " A button -> Confirm / Push skate" -ForegroundColor Gray
Write-Host " B button -> Cancel / Back" -ForegroundColor Gray
Write-Host " Y button -> Map" -ForegroundColor Gray
Write-Host " X button -> Hold to restart track / UI function" -ForegroundColor Gray
Write-Host " Left trigger -> Hand brake (left)" -ForegroundColor Gray
Write-Host " Right trigger -> Hand brake (right)" -ForegroundColor Gray
Write-Host " Right grip -> HotKey modifier (see combos below)" -ForegroundColor Gray
Write-Host ""
Write-Host " Hotkey combos (hold Right Grip + ...):" -ForegroundColor Cyan
Write-Host " L stick click + R stick click -> Recenter view" -ForegroundColor Gray
Write-Host " RG + L stick click -> Toggle 1st/3rd person" -ForegroundColor Gray
Write-Host " RG + L stick up / down -> Switch wheels" -ForegroundColor Gray
Write-Host " RG + L stick left / right -> Switch board" -ForegroundColor Gray
Write-Host " RG + Y -> Skip song" -ForegroundColor Gray
Write-Host ""
Write-Host " MOTION GAMING:" -ForegroundColor Cyan
Write-Host " Lean left / right -> Steer (joystick still wins)" -ForegroundColor Gray
Write-Host " Lean forward -> Accelerate" -ForegroundColor Gray
Write-Host " BOTH hands above head -> Air break" -ForegroundColor Gray
Write-Host ""
Write-Host " A picture of these controls is bundled with the mod at:" -ForegroundColor Gray
Write-Host " $gamePath\VRControls.jpg" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Features:" -ForegroundColor Gray
Write-Host " - Full body-lean motion controls" -ForegroundColor Gray
Write-Host " - bHaptics support (vest + arms)" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host " Renaming back to winhttp.dll re-activates it." -ForegroundColor Gray
Write-Host ""
Write-Host " Catch the ramp. Catch the line. Catch some air." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

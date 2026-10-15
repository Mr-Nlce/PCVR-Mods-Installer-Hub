# -------------------------------------------------------
# StreetDog BMX VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate StreetDog BMX install folder
# 5. Extract mod files in place
#
# No VR controllers - gamepad required - so no ViGEmBus
# setup step like Slyders/Moto Rush.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "StreetDogBMX_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2707870"
$GAME_NAME = "StreetDog BMX"
$GAME_EXE = "StreetDogBMX.exe"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1481693413479944417/1482793255279005757"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1481693413479944417/1481693511601357072"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " StreetDog BMX VR Mod Installer" -ForegroundColor Cyan
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

function Find-StreetDogGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # The Steam installdir is "Street Dog BMX" (with space)
 # per SteamDB - the shop title is "Streetdog BMX" but
 # the folder name has a space. Demo and renamed installs
 # may use other variants, so try several.
 foreach ($folder in @(
 "Street Dog BMX",
 "StreetDog BMX",
 "StreetDogBMX",
 "Streetdog BMX",
 "Street Dog BMX Demo"
 )) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " StreetDog BMX VR is distributed by Astienth via Discord." -ForegroundColor White
Write-Host " Are you already a member of the FarmerTrueVR" -ForegroundColor White
Write-Host " Discord server (with rules accepted)?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [Y] Yes, skip straight to the download link" -ForegroundColor Yellow
Write-Host " >>> [N] No, walk me through joining + accepting rules" -ForegroundColor Yellow
Write-Host "     [S] Show a short walkthrough of what happens first" -ForegroundColor DarkGray
Write-Host ""
$alreadyMember = ""
while ($alreadyMember -notin @("y","Y","n","N")) {
 $alreadyMember = (Read-Host " Your choice (Y/N/S)").Trim()
 if ($alreadyMember -in @("s","S")) {
  Write-Host ""
  Write-Host " Short walkthrough - what the installer does WITH you:" -ForegroundColor White
 Write-Host " 1. Join the FarmerTrueVR Discord server" -ForegroundColor Gray
 Write-Host " 2. Read the rules and click the AK-47 emoji to confirm" -ForegroundColor Gray
 Write-Host " 3. Download StreetDogBMX_VR.zip from the mod channel" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

if (-not $skipJoin) {
 Write-Host " HOW THIS WORKS: at each step press Enter - the installer opens the page for you." -ForegroundColor White
 Write-Host " Do ONLY the highlighted action on that page, then come back here and press Enter for the next step." -ForegroundColor White
 Write-Host ""
 Write-Host " This installer opens each link in your browser one at a time." -ForegroundColor Gray
 Write-Host ""

 Write-Host " [Step 1/3] Discord server invite   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: Accept Invite" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_INVITE_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the invite in your browser..."
 try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open browser. Visit the URL above manually." }

 Write-Host ""
 Write-Host " [Step 2/3] Rules channel - read the rules, then   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: the AK-47 emoji under the rules post" -ForegroundColor Yellow
 Write-Host "   (this unlocks the rest of the server)" -ForegroundColor DarkGray
 Write-Host "   (auto-opens: $DISCORD_RULES_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the rules channel..."
 try { Start-Process $DISCORD_RULES_URL } catch {}

 Write-Host ""
 Write-Host " [Step 3/3] Mod download post   " -ForegroundColor Cyan -NoNewline
 Write-Host "Download: the mod ZIP" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
 Write-Host " Background info: $DISCORD_INFO_URL" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the download post..."
 try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}
} else {
 Write-Host " Great. Opening the mod download post directly." -ForegroundColor Gray
 Write-Host "   (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
 Write-Host " Background info: $DISCORD_INFO_URL" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the download post..."
 try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}
}

# -------------------------------------------------------
# STEP 2: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 4 "Locate the downloaded ZIP"
Write-Host " Once StreetDogBMX_VR.zip is on your disk, drop it here." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter after the Discord ZIP download is complete..."

$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $answer = Read-Host " ZIP path or Q"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (-not (Test-Path -LiteralPath $r -PathType Leaf)) { Write-Fail "File not found: $r"; continue }
 if ($r -notmatch '(?i)\.zip$') { Write-Fail 'Choose the complete StreetDog BMX VR ZIP from the Discord post.'; continue }
 $anchors = @('(?i)(?:^|\\)winhttp\.dll$',
              '(?i)(?:^|\\)BepInEx\\plugins\\StreetDogBMX_VR\.dll$',
              '(?i)(?:^|\\)BepInEx\\core\\BepInEx\.Preloader\.Core\.dll$',
              '(?i)(?:^|\\)BepInEx\\config\\UnityVR_Bepinex_IL2CPP\.cfg$')
 if (-not (Test-ZipPayloadAnchors -Path $r -AnchorPatterns $anchors -MinimumMatches $anchors.Count)) {
  Write-Fail 'The ZIP is unreadable, unsafe, or missing the StreetDog BMX VR runtime. Select another ZIP or Q.'
  continue
 }
 $modZip = $r
 Write-OK "VR archive located and checked: $modZip"
}

# -------------------------------------------------------
# STEP 3: Locate the StreetDog BMX install
# -------------------------------------------------------
Write-Step 2 4 "Locating StreetDog BMX"

$gamePath = Find-StreetDogGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2707870" -SteamFolderNames @("Street Dog BMX") }
if ($gamePath -and -not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE) -PathType Leaf)) {
 Write-Warn "Found a folder without ${GAME_EXE}: $gamePath"
 $gamePath = $null
}
if ($gamePath) {
 Write-OK "Found StreetDog BMX at: $gamePath"
} else {
 Write-Warn "Could not auto-locate StreetDog BMX in any Steam library."
 Write-Host " The mod also works with the demo. Please paste the path" -ForegroundColor White
 Write-Host " to your StreetDog BMX folder (full version OR demo)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $answer = Read-Host " StreetDog BMX folder or Q to quit"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (Test-Path -LiteralPath (Join-Path $r $GAME_EXE) -PathType Leaf) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "$GAME_EXE not found in: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 4: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 3 4 "Installing mod files"

# Extract to a temp folder first, then copy contents into place.
# The mod ships with a BepInEx folder + winhttp.dll at root.
$tempExtract = Join-Path $env:TEMP "StreetDogBMXVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null
$extractResult = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract -Label 'StreetDog BMX VR' -AllowSkip $false
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
 'BepInEx\core\BepInEx.Preloader.Core.dll', 'BepInEx\core\BepInEx.Unity.IL2CPP.dll',
 'BepInEx\plugins\StreetDogBMX_VR.dll', 'BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg',
 'BepInEx\plugins\OpenXR.dll', 'BepInEx\plugins\Nefarius.ViGEm.Client.dll',
 'streetdogbmx_Data\Assets\hands', 'streetdogbmx_Data\StreamingAssets\vrshaders')
try { $payloadHashes = Get-PCVRDropInSourceHashes -SourceRoot $srcRoot -RequiredFiles $requiredModFiles }
catch { Write-Fail "The extracted VR package is incomplete: $_"; Pause-User 'Press Enter to exit...'; exit 1 }

Write-Host " Copying files into: $gamePath" -ForegroundColor Gray
$contract = New-PCVRInstallerContract -Id 'streetdog-bmx-vr' -GameName 'StreetDog BMX VR' -Acquisition Discord -DiscordInviteUrl $DISCORD_INVITE_URL -DiscordDownloadUrl $DISCORD_DOWNLOAD_URL -RequiredInstalledFileGroups (@($GAME_EXE, 'streetdogbmx_Data\globalgamemanagers', 'winhttp.dll|winhttp_bak.dll') + @($requiredModFiles | Where-Object { $_ -ne 'winhttp.dll' }))
$keepConfigs = @('BepInEx\config\BepInEx.cfg', 'BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg')
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
   catch { throw "StreetDog BMX install failed and rollback failed: $failure; $_" }
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

# -------------------------------------------------------
# STEP 4 (cont): finish
# -------------------------------------------------------
Write-Step 4 4 "Done"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Launch StreetDog BMX normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host " The first launch with the mod takes a bit longer than usual." -ForegroundColor Gray
Write-Host ""
Write-Host " Quick controls reference:" -ForegroundColor White
Write-Host " - This mod has NO VR-controller support." -ForegroundColor Gray
Write-Host " - A gamepad is REQUIRED (keyboard alone won't work well)." -ForegroundColor Gray
Write-Host " - HOLD START to recenter the view (do this often!)." -ForegroundColor Gray
Write-Host " - DOUBLE-PRESS START to toggle 1st / 3rd person view." -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues (modder's notes):" -ForegroundColor Yellow
Write-Host " - On launch, if you see a sky instead of the title screen," -ForegroundColor Gray
Write-Host " pick Play and the first level - the view will fix itself." -ForegroundColor Gray
Write-Host " The demo always has this issue." -ForegroundColor Gray
Write-Host " - If you get a black screen in VR, press F1 (left eye)" -ForegroundColor Gray
Write-Host " and F2 (right eye) repeatedly to cycle textures until" -ForegroundColor Gray
Write-Host " both eyes show the correct image." -ForegroundColor Gray
Write-Host ""
Write-Host " Config file: BepInEx\config\Streetdog_BMX.cfg" -ForegroundColor Gray
Write-Host " - firstPersonWorldScale (default 2.2) - adjust 1st-person scale" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Pegs grinding, board flipping. The street's your park now." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

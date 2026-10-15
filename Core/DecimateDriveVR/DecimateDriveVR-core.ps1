# -------------------------------------------------------
# Decimate Drive VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Decimate Drive install folder
# 5. Extract mod files into the release\ subfolder
# 6. Optional ViGEmBus install for VR controllers
#
# IMPORTANT: this mod targets <GameRoot>\release\ (where
# DecimateDrive.exe lives), NOT the Steam folder root.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "DecimateDrive_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2427950"
$GAME_NAME = "Decimate Drive"
$GAME_EXE = "DecimateDrive.exe"

# The mod is installed inside the release\ subfolder, where the
# game exe actually lives.
$RELEASE_SUBFOLDER = "release"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1442488939050176583/1442490463352524901"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1442488939050176583/1442488939050176583"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Decimate Drive VR Mod Installer" -ForegroundColor Cyan
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

function Find-DecimateGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # The game uses a release\ subfolder containing the exe,
 # so the strongest signal is the presence of release\
 # next to the Steam folder root.
 $candidate = Join-Path $lib "steamapps\common\Decimate Drive"
 if (Test-Path -LiteralPath "$candidate\release") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Decimate Drive VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download DecimateDrive_VR.zip from the mod channel" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warning - this mod is OpenXR ONLY.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod supports OpenXR ONLY (no OpenVR). Make sure" -ForegroundColor White
Write-Host " SteamVR (or whatever OpenXR runtime you use) is set" -ForegroundColor White
Write-Host " as the default OpenXR runtime in its settings." -ForegroundColor White
Write-Host ""
Show-AntivirusNotice -Compact

if (-not $skipJoin) {
 Write-Host " HOW THIS WORKS: at each step press Enter - the installer opens the page for you." -ForegroundColor White
 Write-Host " Do ONLY the highlighted action on that page, then come back here and press Enter for the next step." -ForegroundColor White
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
Write-Host " Once DecimateDrive_VR.zip is on your disk, drop it here." -ForegroundColor Gray
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
 if ($r -notmatch '(?i)\.zip$') { Write-Fail 'Choose the complete Decimate Drive VR ZIP.'; continue }
 $anchors = @('(?i)(?:^|\\)winhttp\.dll$',
              '(?i)(?:^|\\)BepInEx\\plugins\\DecimateDrive_VR\.dll$',
              '(?i)(?:^|\\)BepInEx\\core\\BepInEx\.Preloader\.Core\.dll$',
              '(?i)(?:^|\\)BepInEx\\config\\UnityVR_Bepinex_IL2CPP\.cfg$')
 if (-not (Test-ZipPayloadAnchors -Path $r -AnchorPatterns $anchors -MinimumMatches $anchors.Count)) {
  Write-Fail 'The ZIP is unreadable, unsafe, or missing the VR runtime. Choose another ZIP or Q.'
  continue
 }
 $modZip = $r
 Write-OK "VR archive located and checked: $modZip"
}

# -------------------------------------------------------
# STEP 3: Locate the Decimate Drive install AND its release\
# -------------------------------------------------------
Write-Step 2 4 "Locating Decimate Drive"

$gamePath = Find-DecimateGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2427950" -SteamFolderNames @("Decimate Drive") }
if ($gamePath -and -not (Test-Path -LiteralPath (Join-Path $gamePath 'release\DecimateDrive.exe') -PathType Leaf)) {
 Write-Warn "Found a folder without release\DecimateDrive.exe: $gamePath"
 $gamePath = $null
}
if ($gamePath) {
 Write-OK "Found Decimate Drive at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Decimate Drive in any Steam library."
 Write-Host " Please paste the path to your Decimate Drive folder" -ForegroundColor White
 Write-Host " (the folder containing release\DecimateDrive.exe)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $answer = Read-Host " Decimate Drive folder or Q to quit"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (Test-Path -LiteralPath (Join-Path $r 'release\DecimateDrive.exe') -PathType Leaf) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "release\DecimateDrive.exe not found in: $r"
 }
 }
}

# Install beside the actual game executable inside release\.
$releasePath = Join-Path $gamePath $RELEASE_SUBFOLDER
Write-OK "release\ folder found at: $releasePath"

# -------------------------------------------------------
# STEP 4: Extract mod files into the release\ subfolder
# -------------------------------------------------------
Write-Step 3 4 "Installing mod files into release\"

$tempExtract = Join-Path $env:TEMP "DecimateDriveVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

$extractResult = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract -Label 'Decimate Drive VR' -AllowSkip $false
if ([string]$extractResult -notin @('ok','manual','retry')) {
 Write-Fail 'The VR archive was not extracted. The game was not changed.'
 Pause-User 'Press Enter to exit...'
 exit 1
}

$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 if ($rootEntries[0].Name -ne "BepInEx") {
 $srcRoot = $rootEntries[0].FullName
 }
}

Write-Host " Copying files into: $releasePath" -ForegroundColor Gray
$requiredModFiles = @('winhttp.dll', 'doorstop_config.ini',
 'BepInEx\core\BepInEx.Preloader.Core.dll', 'BepInEx\core\BepInEx.Unity.IL2CPP.dll',
 'BepInEx\plugins\DecimateDrive_VR.dll', 'BepInEx\plugins\OpenXR.dll',
 'BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg')
$redistPath = Join-Path $srcRoot 'BepInEx\redist'
$redistExe = @(Get-ChildItem -LiteralPath $redistPath -Filter 'ViGEmBus_*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($redistExe.Count -eq 0) { Write-Fail 'The VR package is missing the ViGEmBus installer.'; Pause-User 'Press Enter to exit...'; exit 1 }
$requiredModFiles += "BepInEx\redist\$($redistExe[0].Name)"
try { $payloadHashes = Get-PCVRDropInSourceHashes -SourceRoot $srcRoot -RequiredFiles $requiredModFiles }
catch { Write-Fail "The extracted VR package is incomplete: $_"; Pause-User 'Press Enter to exit...'; exit 1 }

$installedGroups = @('release\DecimateDrive.exe', 'release\winhttp.dll|release\winhttp_bak.dll')
$installedGroups += @($requiredModFiles | Where-Object { $_ -ne 'winhttp.dll' } | ForEach-Object { "release\$_" })
$contract = New-PCVRInstallerContract -Id 'decimate-drive-vr' -GameName 'Decimate Drive VR' -Acquisition Discord `
 -DiscordInviteUrl $DISCORD_INVITE_URL -DiscordDownloadUrl $DISCORD_DOWNLOAD_URL `
 -AntivirusNotice -RequiredInstalledFileGroups $installedGroups
$keepConfigs = @('BepInEx\config\BepInEx.cfg', 'BepInEx\config\DecimateDrive_VR.cfg', 'BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg')
$activeProxy = Join-Path $releasePath 'winhttp.dll'
$parkedProxy = Join-Path $releasePath 'winhttp_bak.dll'
$wasFlat = (Test-Path -LiteralPath $parkedProxy -PathType Leaf) -and -not (Test-Path -LiteralPath $activeProxy -PathType Leaf)
$oldParkedBytes = if ($wasFlat) { [IO.File]::ReadAllBytes($parkedProxy) } else { $null }
$preservedConfigs = @($keepConfigs | Where-Object { Test-Path -LiteralPath (Join-Path $releasePath $_) -PathType Leaf })
$installed = $false
while (-not $installed) {
 $copyTransaction = $null
 try {
  $copyTransaction = Install-PCVRDropInCopy -SourceRoot $srcRoot -GameRoot $releasePath -SourceHashes $payloadHashes -KeepExistingFiles $keepConfigs
  Assert-PCVRDropInCopiedFiles -GameRoot $releasePath -SourceHashes $payloadHashes -PreservedExistingFiles $preservedConfigs
  if ($wasFlat) {
   Copy-Item -LiteralPath $activeProxy -Destination $parkedProxy -Force -ErrorAction Stop
   Remove-Item -LiteralPath $activeProxy -Force -ErrorAction Stop
  }
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gamePath -Version $MOD_VERSION `
   -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
  $installed = $true
 } catch {
  $failure = $_
  if ($copyTransaction) {
   try { Undo-PCVRDropInCopy -Transaction $copyTransaction }
   catch { throw "Decimate Drive install failed and rollback failed: $failure; $_" }
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
# STEP 5: ViGEmBus driver (mandatory for VR controllers)
# -------------------------------------------------------
Write-Step 4 4 "ViGEmBus driver (for VR motion controllers)"

Write-Host " VR motion controllers in this mod work by emulating an" -ForegroundColor Gray
Write-Host " Xbox controller through the ViGEmBus driver." -ForegroundColor Gray
Write-Host ""
Write-Host " If you have NEVER installed ViGEmBus before, you must run" -ForegroundColor White
Write-Host " the installer once. Already installed? Skip." -ForegroundColor White
Write-Host ""

$vigemExe = Get-ChildItem -Path (Join-Path $releasePath "BepInEx\redist") -Filter "ViGEmBus_*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

# Detect an existing ViGEmBus install so users who already have it
# (very common - it ships with many VR mods, Virtual Desktop, DS4Windows,
# etc.) can just press Enter. Re-installing stays available via V.
$vigemPresent = $false
try { $vigemPresent = Test-ViGEmBusInstalled } catch { $vigemPresent = $false }

if ($vigemExe -and $vigemPresent) {
 Write-OK "ViGEmBus already detected on this PC."
 Write-Host ""
 Write-Host " Press ENTER to continue to the next step (recommended)." -ForegroundColor White
 Write-Host " If your VR controllers give you trouble, you can (re)install" -ForegroundColor Gray
 Write-Host " it: type V then Enter." -ForegroundColor Gray
 $reinst = (Read-Host " [Enter] skip / [V] reinstall").Trim()
 if ($reinst -in @("v","V")) {
 Write-Host ""
 Write-Host " Running ViGEmBus setup - approve the Windows admin prompt..." -ForegroundColor Gray
 $attempts = @(
 @{ VArgs = "/quiet /norestart"; Label = "silent" },
 @{ VArgs = "/passive /norestart"; Label = "with progress bar" },
 @{ VArgs = ""; Label = "interactive" }
 )
 $vigemDone = $false
 foreach ($attempt in $attempts) {
 try {
 if ($attempt.VArgs) {
 $proc = Start-Process -FilePath $vigemExe.FullName -ArgumentList $attempt.VArgs -Wait -PassThru -ErrorAction Stop
 } else {
 $proc = Start-Process -FilePath $vigemExe.FullName -Wait -PassThru -ErrorAction Stop
 }
 if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
 Write-OK "ViGEmBus installed ($($attempt.Label))."
 $vigemDone = $true
 break
 } elseif ($proc.ExitCode -eq 1602) {
 Write-Info "ViGEmBus setup cancelled by user."
 $vigemDone = $true
 break
 } else {
 Write-Host " Tried $($attempt.Label) mode - exit $($proc.ExitCode), trying next..." -ForegroundColor DarkGray
 }
 } catch {
 Write-Host " Tried $($attempt.Label) mode - threw error, trying next..." -ForegroundColor DarkGray
 }
 }
 if (-not $vigemDone) {
 Write-Warn "ViGEmBus setup didn't complete cleanly. You can run it manually:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
 } else {
 Write-Info "Keeping the existing ViGEmBus install."
 }
}
elseif ($vigemExe) {
 Write-Host " The mod ZIP includes the ViGEmBus setup file." -ForegroundColor White
 Write-Host " File: $($vigemExe.Name)" -ForegroundColor DarkGray
 Write-Host ""
 Write-Host " Want to install it now? Pick N if you've already" -ForegroundColor White
 Write-Host " installed ViGEmBus before (e.g. for another VR mod)." -ForegroundColor White
 Write-Host ""
 Write-Host " >>> [Y] Install now (Windows will ask for admin)" -ForegroundColor Yellow
 Write-Host " >>> [N] Skip - I already have it" -ForegroundColor Gray
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Your choice (Y/N)").Trim() }
 if ($choice -in @("y","Y")) {
 Write-Host ""
 Write-Host " Running ViGEmBus setup - approve the Windows admin prompt..." -ForegroundColor Gray
 $attempts = @(
 @{ VArgs = "/quiet /norestart"; Label = "silent" },
 @{ VArgs = "/passive /norestart"; Label = "with progress bar" },
 @{ VArgs = ""; Label = "interactive" }
 )
 $vigemDone = $false
 foreach ($attempt in $attempts) {
 try {
 if ($attempt.VArgs) {
 $proc = Start-Process -FilePath $vigemExe.FullName -ArgumentList $attempt.VArgs -Wait -PassThru -ErrorAction Stop
 } else {
 $proc = Start-Process -FilePath $vigemExe.FullName -Wait -PassThru -ErrorAction Stop
 }
 if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
 Write-OK "ViGEmBus installed ($($attempt.Label))."
 $vigemDone = $true
 break
 } elseif ($proc.ExitCode -eq 1602) {
 Write-Info "ViGEmBus setup cancelled by user."
 $vigemDone = $true
 break
 } else {
 Write-Host " Tried $($attempt.Label) mode - exit $($proc.ExitCode), trying next..." -ForegroundColor DarkGray
 }
 } catch {
 Write-Host " Tried $($attempt.Label) mode - threw error, trying next..." -ForegroundColor DarkGray
 }
 }
 if (-not $vigemDone) {
 Write-Warn "ViGEmBus setup didn't complete cleanly. You can run it manually:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
 } else {
 Write-Info "ViGEmBus skipped. Path if you change your mind:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
} else {
 Write-Warn "ViGEmBus installer not found in $releasePath\BepInEx\redist"
 Write-Info "If VR controllers don't work in-game, look for ViGEmBus_*.exe inside the mod folder."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Launch Decimate Drive normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT recenter behaviour:" -ForegroundColor Yellow
Write-Host " - Press LEFT controller Y button to recenter the view." -ForegroundColor White
Write-Host " - When recentering, LOOK FORWARD - whatever direction" -ForegroundColor White
Write-Host " you are looking at when you press Y becomes the" -ForegroundColor White
Write-Host " game's forward direction." -ForegroundColor White
Write-Host " - Recenter after each loading screen (known issue)." -ForegroundColor White
Write-Host ""
Write-Host " Controls (motion controllers):" -ForegroundColor White
Write-Host " Left controller:" -ForegroundColor Gray
Write-Host " - Stick = Move" -ForegroundColor Gray
Write-Host " - Y = Recenter" -ForegroundColor Gray
Write-Host " - X = Menu / Pause" -ForegroundColor Gray
Write-Host " Right controller:" -ForegroundColor Gray
Write-Host " - Stick = Rotate" -ForegroundColor Gray
Write-Host " - Stick L/R = adjust slider while held in options" -ForegroundColor Gray
Write-Host " - A = Jump" -ForegroundColor Gray
Write-Host " - B = Toggle sprint" -ForegroundColor Gray
Write-Host " - Trigger = Dash / Select in menus" -ForegroundColor Gray
Write-Host " - Grip = Toggle crouch (or R3 if swapCrouchInput)" -ForegroundColor Gray
Write-Host ""
Write-Host " Features: bHaptics vest support" -ForegroundColor Gray
Write-Host " Launch the bHaptics player + turn devices on BEFORE the game." -ForegroundColor Gray
Write-Host ""
Write-Host " Config file: release\BepInEx\config\DecimateDrive_VR.cfg" -ForegroundColor Gray
Write-Host " leftHanded = false (true for left-hand mode -" -ForegroundColor Gray
Write-Host " left trigger validates in menus)" -ForegroundColor Gray
Write-Host " swapCrouchInput = false (true = crouch on R3 instead of grip)" -ForegroundColor Gray
Write-Host " worldScale = 1 (<1 = bigger world, >1 = smaller;" -ForegroundColor Gray
Write-Host " modder suggests trying 0.8)" -ForegroundColor Gray
Write-Host " gunHaptics = true (false to disable shooting bHaptics" -ForegroundColor Gray
Write-Host " effect if too repetitive)" -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues (per the modder):" -ForegroundColor Yellow
Write-Host " - Options menu can be tricky: hold-and-release for" -ForegroundColor Gray
Write-Host " selects, hold-and-move-stick for sliders." -ForegroundColor Gray
Write-Host " - Objects between you and the VRUI (like a car after" -ForegroundColor Gray
Write-Host " a death) can block clicks - move your hand closer." -ForegroundColor Gray
Write-Host " - Recenter after every loading screen." -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " release\ folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Hands at ten and two. The cars are alive." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

# -------------------------------------------------------
# Rogue Flight VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Rogue Flight install folder
# 5. Extract mod files in place
# 6. Optional ViGEmBus install (only for users without
# a real gamepad who want VR-controller emulation)
#
# This is a gamepad-first mod. The native game is gamepad-
# oriented, so the VR mod just renders in VR while the
# game still expects a gamepad. Users with a real gamepad
# can skip the ViGEm step entirely.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "RogueFlight_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2784620"
$GAME_NAME = "Rogue Flight"
$GAME_EXE = "RogueFlight.exe"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1443945389454528634/1443945903336460330"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1443945389454528634/1443945389454528634"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Rogue Flight VR Mod Installer" -ForegroundColor Cyan
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

function Test-RogueFlightSupportedGamePath {
 param([string]$Path)
 if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
 # The author expects the separate demo build not to work with this mod.
 if ([IO.Path]::GetFileName($Path.TrimEnd('\','/')) -match '(?i)demo') { return $false }
 return ((Test-Path -LiteralPath (Join-Path $Path 'RogueFlight.exe') -PathType Leaf) -and
         (Test-Path -LiteralPath (Join-Path $Path 'RogueFlight_Data') -PathType Container))
}

function Find-RogueFlightGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Folder name uncertain: Unity data folder is RogueFlight_Data
 # (no space) but Steam installdir conventions vary. Try the
 # most likely variants in order; the _Data folder presence is
 # the strongest signal we found the right install.
 foreach ($folder in @("Rogue Flight", "RogueFlight", "ROGUE FLIGHT", "ROGUE_FLIGHT")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-RogueFlightSupportedGamePath $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Rogue Flight VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download RogueFlight_VR.zip from the mod channel" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warnings
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " The author expects the Steam demo to be incompatible." -ForegroundColor White
Write-Host " Select the full game for this VR mod." -ForegroundColor White
Write-Host ""
Write-Host " This mod supports OpenXR ONLY (no OpenVR). Make sure" -ForegroundColor White
Write-Host " your OpenXR runtime is set up correctly." -ForegroundColor White
Write-Host ""
Write-Host " This is a GAMEPAD game. A real gamepad is highly" -ForegroundColor White
Write-Host " recommended. If you don't have one, the installer can" -ForegroundColor White
Write-Host " optionally install ViGEmBus to emulate a gamepad with" -ForegroundColor White
Write-Host " your VR controllers (or use Virtual Desktop's built-in" -ForegroundColor White
Write-Host " gamepad emulation if you use that)." -ForegroundColor White
Write-Host ""

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
Write-Host " Once RogueFlight_VR.zip is on your disk, drop it here." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter after the Discord ZIP download is complete..."

$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP, type its path, or Q to quit:" -ForegroundColor Yellow
 $answer = Read-Host " ZIP path or Q"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (-not (Test-Path -LiteralPath $r -PathType Leaf)) { Write-Fail "File not found: $r"; continue }
 if ($r -notmatch '(?i)\.zip$') { Write-Fail 'Choose the complete RogueFlight_VR ZIP from the Discord post.'; continue }
 $anchors = @('(?i)(?:^|\\)winhttp\.dll$', '(?i)(?:^|\\)BepInEx\\plugins\\RogueFlight_VR\.dll$',
              '(?i)(?:^|\\)BepInEx\\core\\BepInEx\.Preloader\.Core\.dll$',
              '(?i)(?:^|\\)BepInEx\\config\\UnityVR_Bepinex_IL2CPP\.cfg$')
 if (-not (Test-ZipPayloadAnchors -Path $r -AnchorPatterns $anchors -MinimumMatches $anchors.Count)) {
  Write-Fail 'The ZIP is unreadable, unsafe, or missing the Rogue Flight VR runtime. Select another ZIP or Q.'
  continue
 }
 $modZip = $r
 Write-OK "VR archive located and checked: $modZip"
}

# -------------------------------------------------------
# STEP 3: Locate the Rogue Flight install
# -------------------------------------------------------
Write-Step 2 4 "Locating Rogue Flight"

$gamePath = Find-RogueFlightGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2784620" -SteamFolderNames @("Rogue Flight") }
if ($gamePath -and -not (Test-RogueFlightSupportedGamePath $gamePath)) {
 Write-Warn "Found an incomplete or demo folder: $gamePath"
 $gamePath = $null
}
if ($gamePath) {
 Write-OK "Found Rogue Flight at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Rogue Flight in any Steam library."
 Write-Host " Please paste the path to your Rogue Flight folder" -ForegroundColor White
 Write-Host " (the folder that contains 'RogueFlight_Data')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $answer = Read-Host " Rogue Flight folder or Q to quit"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (Test-RogueFlightSupportedGamePath $r) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Choose the full game's folder with $GAME_EXE and RogueFlight_Data; the demo is not supported."
 }
 }
}

# -------------------------------------------------------
# STEP 4: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 3 4 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "RogueFlightVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

$extractResult = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract `
 -Label 'Rogue Flight VR' -AllowSkip $false
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

$requiredModFiles = @('winhttp.dll', 'BepInEx\core\BepInEx.Preloader.Core.dll',
 'BepInEx\plugins\RogueFlight_VR.dll', 'BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg')
try { $payloadHashes = Get-PCVRDropInSourceHashes -SourceRoot $srcRoot -RequiredFiles $requiredModFiles }
catch { Write-Fail "The extracted VR package is incomplete: $_"; Pause-User 'Press Enter to exit...'; exit 1 }

Write-Host " Copying files into: $gamePath" -ForegroundColor Gray
$contract = New-PCVRInstallerContract -Id 'rogue-flight-vr' -GameName 'Rogue Flight VR' -Acquisition Discord `
 -DiscordInviteUrl $DISCORD_INVITE_URL -DiscordDownloadUrl $DISCORD_DOWNLOAD_URL `
 -RequiredInstalledFileGroups (@($GAME_EXE, 'winhttp.dll|winhttp_bak.dll') + @($requiredModFiles | Where-Object { $_ -ne 'winhttp.dll' }))
$keepConfigs = @('BepInEx\config\RogueFlight_VR.cfg', 'BepInEx\config\BepInEx.cfg', 'BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg')
$activeProxy = Join-Path $gamePath 'winhttp.dll'
$parkedProxy = Join-Path $gamePath 'winhttp_bak.dll'
$wasFlat = (Test-Path -LiteralPath $parkedProxy -PathType Leaf) -and -not (Test-Path -LiteralPath $activeProxy -PathType Leaf)
$oldParkedBytes = if ($wasFlat) { [IO.File]::ReadAllBytes($parkedProxy) } else { $null }
$preservedConfigs = @($keepConfigs | Where-Object { Test-Path -LiteralPath (Join-Path $gamePath $_) -PathType Leaf })
$installed = $false
while (-not $installed) {
 $copyTransaction = $null
 try {
  $copyTransaction = Install-PCVRDropInCopy -SourceRoot $srcRoot -GameRoot $gamePath `
   -SourceHashes $payloadHashes -KeepExistingFiles $keepConfigs
  Assert-PCVRDropInCopiedFiles -GameRoot $gamePath -SourceHashes $payloadHashes -PreservedExistingFiles $preservedConfigs
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
   catch { throw "Rogue Flight install failed and rollback failed: $failure; $_" }
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
# STEP 5: Optional ViGEmBus (only for users without a gamepad)
# -------------------------------------------------------
Write-Step 4 4 "ViGEmBus driver (optional - only if no real gamepad)"

Write-Host " Rogue Flight is a GAMEPAD game. If you have a real" -ForegroundColor Gray
Write-Host " gamepad plugged in, you don't need ViGEmBus - skip this." -ForegroundColor Gray
Write-Host ""
Write-Host " ViGEmBus is only needed if BOTH apply:" -ForegroundColor White
Write-Host " - You have NO real gamepad" -ForegroundColor White
Write-Host " - You're NOT using Virtual Desktop's gamepad emulation" -ForegroundColor White
Write-Host ""
Write-Host " When ViGEmBus is installed AND vrControllersSupport is" -ForegroundColor Gray
Write-Host " set to true in the config, your VR controllers emulate" -ForegroundColor Gray
Write-Host " an Xbox gamepad. The layout is on this game's page in the Hub." -ForegroundColor Gray
Write-Host ""

$vigemExe = Get-ChildItem -Path (Join-Path $gamePath "BepInEx\redist") -Filter "ViGEmBus_*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

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
 Write-Host " >>> [Y] Install ViGEmBus + enable VR-controller emulation" -ForegroundColor Yellow
 Write-Host " >>> [N] Skip - I have a real gamepad (or VD gamepad emu)" -ForegroundColor Gray
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

 # Now flip vrControllersSupport=true in the IL2CPP config so
 # the VR controllers actually act as a virtual Xbox pad.
 # Default in the shipped config is false.
 $cfg = Join-Path $gamePath "BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg"
 if (Test-Path $cfg) {
 try {
 $text = Get-Content $cfg -Raw -Encoding UTF8
 $newText = $text -replace 'vrControllersSupport\s*=\s*false', 'vrControllersSupport = true'
 if ($newText -ne $text) {
 Set-Content -Path $cfg -Value $newText -Encoding UTF8 -NoNewline
 Write-OK "Enabled vrControllersSupport = true in UnityVR_Bepinex_IL2CPP.cfg"
 } else {
 Write-Info "vrControllersSupport was already enabled (or not found in config)."
 }
 } catch {
 Write-Warn "Could not edit UnityVR_Bepinex_IL2CPP.cfg - you may need to set"
 Write-Warn "vrControllersSupport = true manually in BepInEx\config\."
 }
 }
 } else {
 Write-Info "ViGEmBus skipped. Plug in your gamepad and launch the game."
 Write-Info "If you change your mind, ViGEmBus setup is at:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
} else {
 Write-Warn "ViGEmBus installer not found in BepInEx\redist - the mod ZIP may be a different version."
 Write-Info "If you need VR-controller gamepad emulation, look for ViGEmBus_*.exe inside the mod folder."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Launch Rogue Flight normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Controls:" -ForegroundColor White
Write-Host " - This is a GAMEPAD game. Use a real gamepad," -ForegroundColor Gray
Write-Host " Virtual Desktop's gamepad emulation, or VR-" -ForegroundColor Gray
Write-Host " controller emulation via ViGEmBus." -ForegroundColor Gray
Write-Host " - Recenter view: click both joysticks at the same time." -ForegroundColor Gray
Write-Host " Recentering may be required after loading scenes." -ForegroundColor Gray
Write-Host ""
Write-Host " If using ViGEmBus + VR-controller emulation, the" -ForegroundColor Gray
Write-Host " HOTKEY GESTURE applies: hold left controller close" -ForegroundColor Gray
Write-Host " to your head - it vibrates while active. While vibrating:" -ForegroundColor Gray
Write-Host " * Left stick = D-Pad" -ForegroundColor Gray
Write-Host " * Left stick click = Back / View button" -ForegroundColor Gray
Write-Host " * Right stick click = Start / Menu button" -ForegroundColor Gray
Write-Host ""
Write-Host " Features: bHaptics vest support" -ForegroundColor Gray
Write-Host " Launch the bHaptics player + turn vest on BEFORE the game." -ForegroundColor Gray
Write-Host ""
Write-Host " Config files:" -ForegroundColor Gray
Write-Host " BepInEx\config\RogueFlight_VR.cfg" -ForegroundColor DarkGray
Write-Host " gunHaptics = true (false to disable shooting bHaptics" -ForegroundColor Gray
Write-Host " effect - it triggers a lot)" -ForegroundColor Gray
Write-Host " BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg" -ForegroundColor DarkGray
Write-Host " vrControllersSupport = true / false" -ForegroundColor Gray
Write-Host " (already set by this installer if you picked Y above)" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Gun the engine. Burn the sky. Anime never dies." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

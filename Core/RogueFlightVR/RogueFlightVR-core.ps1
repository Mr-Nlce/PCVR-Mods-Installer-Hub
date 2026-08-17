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
 if (Test-Path -LiteralPath "$candidate\RogueFlight_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
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

$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " ZIP path").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 if ($r -match '\.zip$|\.7z$|\.rar$') {
 $modZip = $r
 Write-OK "Archive located: $modZip"
 } else {
 Write-Fail "Path is not a ZIP/7z/RAR archive: $r"
 }
 } else {
 Write-Fail "File not found: $r"
 }
}

# -------------------------------------------------------
# STEP 3: Locate the Rogue Flight install
# -------------------------------------------------------
Write-Step 2 4 "Locating Rogue Flight"

$gamePath = Find-RogueFlightGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2784620" -SteamFolderNames @("Rogue Flight") }
if ($gamePath) {
 Write-OK "Found Rogue Flight at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Rogue Flight in any Steam library."
 Write-Host " Please paste the path to your Rogue Flight folder" -ForegroundColor White
 Write-Host " (the folder that contains 'RogueFlight_Data')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Rogue Flight folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 4: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 3 4 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "RogueFlightVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

try {
 Write-Host " Extracting archive..." -ForegroundColor Gray
 Expand-Archive -Path $modZip -DestinationPath $tempExtract -Force
} catch {
 Write-Fail "Extract failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$tempExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$tempExtract" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # User claims they extracted manually. Re-run extract logic
 # by exiting and forcing re-run (we don't know which archive
 # variable this catch belongs to without context).
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 if ($rootEntries[0].Name -ne "BepInEx") {
 $srcRoot = $rootEntries[0].FullName
 }
}

Write-Host " Copying files into: $gamePath" -ForegroundColor Gray
try {
 Get-ChildItem -Path $srcRoot | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 Write-OK "Mod files installed."
} catch {
 Write-Fail "Copy failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open the archive in the temp folder (path printed by the installer just above) with 7-Zip, and extract its contents into '$gamePath'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -DestFolder "$gamePath" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # User claims they extracted manually. Re-run extract logic
 # by exiting and forcing re-run (we don't know which archive
 # variable this catch belongs to without context).
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

try { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Sanity check
$bepinexDir = Join-Path $gamePath "BepInEx"
$modDll = Join-Path $gamePath "BepInEx\plugins\RogueFlight_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but RogueFlight_VR.dll is missing."
} else {
 Write-OK "BepInEx + RogueFlight_VR.dll present."
}

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
# Record install path so the Hub can mark VR Ready
# -------------------------------------------------------
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
} catch {}

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

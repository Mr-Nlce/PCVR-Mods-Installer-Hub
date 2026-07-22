# -------------------------------------------------------
# Unmourned VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Unmourned install folder
# 5. Extract mod files in place
# 6. Optional ViGEmBus install for VR controllers
#
# Uses motion controls via ViGEmBus xbox-controller emulation,
# so the ViGEm step is mandatory for VR controllers to work
# (same as Slyders/Moto Rush).
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "Unmourned_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "3528970"
$GAME_NAME = "Unmourned"
$GAME_EXE = "Unmourned.exe"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1462781954570059990/1462782593450901584"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1462781954570059990/1462781954570059990"
$DISCORD_LAYOUT_URL = "https://discord.com/channels/1001138422972432597/1462781954570059990/1462782122740682894"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Unmourned VR Mod Installer" -ForegroundColor Cyan
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

function Find-UnmournedGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = Join-Path $lib "steamapps\common\Unmourned"
 if (Test-Path -LiteralPath "$candidate\Unmourned_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Unmourned VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download UnmournedVR.zip from the mod channel" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warning - the user MUST launch the game
# once in flat mode first to set the language.
Write-Host " IMPORTANT FIRST-LAUNCH NOTE:" -ForegroundColor Yellow
Write-Host " -----------------------------" -ForegroundColor Yellow
Write-Host " Before installing this mod, launch Unmourned ONCE in" -ForegroundColor White
Write-Host " flat mode and pick your language. The mod can't show" -ForegroundColor White
Write-Host " the language picker properly in VR." -ForegroundColor White
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
Write-Host " Once UnmournedVR.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Unmourned install
# -------------------------------------------------------
Write-Step 2 4 "Locating Unmourned"

$gamePath = Find-UnmournedGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "3528970" -SteamFolderNames @("Unmourned") -ProbeExe "Unmourned.exe" }
if ($gamePath) {
 Write-OK "Found Unmourned at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Unmourned in any Steam library."
 Write-Host " Please paste the path to your Unmourned install folder" -ForegroundColor White
 Write-Host " (the folder that contains Unmourned_Data/)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Unmourned folder").Trim().Trim('"')
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

$tempExtract = Join-Path $env:TEMP "UnmournedVR_$([System.IO.Path]::GetRandomFileName())"
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

# Sanity check that BepInEx + the mod DLL landed
$bepinexDir = Join-Path $gamePath "BepInEx"
$modDll = Join-Path $gamePath "BepInEx\plugins\Unmourned_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but Unmourned_VR.dll is missing."
} else {
 Write-OK "BepInEx + Unmourned_VR.dll present."
}

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
 # ViGEmBus ships a WiX bootstrapper. Try /quiet first, fall
 # back to /passive (visible progress), then to interactive.
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
 Write-Warn "ViGEmBus installer not found in BepInEx\redist - the mod ZIP may be a different version."
 Write-Info "If VR controllers don't work in-game, look for ViGEmBus_*.exe inside the mod folder."
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
Write-Host " IMPORTANT first-launch steps:" -ForegroundColor Yellow
Write-Host " 1. If you haven't already done this BEFORE installing the" -ForegroundColor White
Write-Host " mod: launch Unmourned once in flat mode and pick a" -ForegroundColor White
Write-Host " language. The mod can't show the language picker." -ForegroundColor White
Write-Host " 2. The mod requires OpenXR - make sure SteamVR or your" -ForegroundColor White
Write-Host " OpenXR runtime is set as the default OpenXR runtime." -ForegroundColor White
Write-Host " 3. After launching with the mod, wait a few seconds on" -ForegroundColor White
Write-Host " the title screen - the option menu opens by itself" -ForegroundColor White
Write-Host " briefly. This is intentional, don't worry." -ForegroundColor White
Write-Host " 4. The intro cinematic starts UPSIDE DOWN. Click both" -ForegroundColor White
Write-Host " joysticks to recenter the moment you see text." -ForegroundColor White
Write-Host ""
Write-Host " Controls (motion controllers, mapped as Xbox gamepad):" -ForegroundColor White
Write-Host " - Recenter view: click both joysticks at once." -ForegroundColor Gray
Write-Host " - HOTKEY GESTURE: hold left controller close to your" -ForegroundColor Gray
Write-Host " head (real life) - it vibrates while the hotkey is" -ForegroundColor Gray
Write-Host " active. While vibrating:" -ForegroundColor Gray
Write-Host " * Left stick = D-Pad" -ForegroundColor Gray
Write-Host " * Left stick click = Back button" -ForegroundColor Gray
Write-Host " * Right stick click = Start button" -ForegroundColor Gray
Write-Host " - Use D-Pad (= hotkey + left stick) to navigate menus." -ForegroundColor Gray
Write-Host ""
Write-Host " Controller layout image:" -ForegroundColor Gray
Write-Host " $DISCORD_LAYOUT_URL" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Features: bHaptics vest support is included." -ForegroundColor Gray
Write-Host ""
Write-Host " Config file: BepInEx\config\UnmournedVR.cfg" -ForegroundColor Gray
Write-Host " handRotationOffsetX = 40 (aiming offset; tune per controller)" -ForegroundColor Gray
Write-Host " leftHanded = false (set true for left-hand mode)" -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues (per the modder):" -ForegroundColor Yellow
Write-Host " - Decoupled-pitch makes the intro upside down (recenter)" -ForegroundColor Gray
Write-Host " - Drawers can be tricky depending on hand orientation" -ForegroundColor Gray
Write-Host " - The Load Save menu is invisible (it works, but you" -ForegroundColor Gray
Write-Host " can't see which save you're picking yet)" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Some doors should stay shut. Yours just opened." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

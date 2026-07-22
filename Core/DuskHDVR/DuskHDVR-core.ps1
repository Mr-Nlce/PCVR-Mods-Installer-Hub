# -------------------------------------------------------
# Dusk HD (DLC) VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Dusk install folder
# 5. Extract mod files into the DUSK HD DLC subfolder
# 6. Optional ViGEmBus install for VR controllers
#
# CRITICAL: this mod is for the DUSK HD DLC, NOT classic
# DUSK. The mod files must end up in
# <GameRoot>\DLC\DUSK HD\, not in the game root itself.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "Dusk_HD_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "519860"
$GAME_NAME = "Dusk"
$GAME_EXE = "Dusk.exe"

# DUSK HD subfolder under the game root
$DLC_SUBFOLDER = "DLC\DUSK HD"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1449484957671227555/1450254147768287233"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1449484957671227555/1449484957671227555"
$DISCORD_ROOMSCALE_URL = "https://discord.com/channels/1001138422972432597/1449484957671227555/1449729394322182266"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Dusk HD (DLC) VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
 Write-Host " IMPORTANT: this mod is for the DUSK HD DLC, NOT" -ForegroundColor Yellow
 Write-Host " classic DUSK. Make sure you own the DUSK HD DLC" -ForegroundColor Yellow
 Write-Host " before continuing." -ForegroundColor Yellow
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

function Find-DuskGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = Join-Path $lib "steamapps\common\DUSK"
 if (Test-Path (Join-Path $candidate $DLC_SUBFOLDER)) { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Dusk HD (DLC) VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download Dusk_HD_VR.zip from the mod channel" -ForegroundColor Gray
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
Write-Host " Once Dusk_HD_VR.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Dusk install AND its DUSK HD DLC folder
# -------------------------------------------------------
Write-Step 2 4 "Locating Dusk + DUSK HD DLC"

$gamePath = Find-DuskGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "519860" -SteamFolderNames @("DUSK") -ProbeExe "Dusk.exe" -GogNames @("DUSK") }
if ($gamePath) {
 Write-OK "Found Dusk at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Dusk in any Steam library."
 Write-Host " Please paste the path to your Dusk root folder" -ForegroundColor White
 Write-Host " (the folder that contains DLC\DUSK HD\)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Dusk folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# Now confirm the DUSK HD DLC subfolder actually exists.
$dlcPath = Join-Path $gamePath $DLC_SUBFOLDER
if (-not (Test-Path $dlcPath)) {
 Write-Fail "DUSK HD DLC folder not found at:"
 Write-Host " $dlcPath" -ForegroundColor DarkGray
 Write-Warn "This mod requires the DUSK HD DLC. Make sure:"
 Write-Host " - You own the DUSK HD DLC on Steam" -ForegroundColor Gray
 Write-Host " - The DLC is installed (Steam library: right-click" -ForegroundColor Gray
 Write-Host " Dusk -> Properties -> DLC tab -> tick 'DUSK HD')" -ForegroundColor Gray
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$gamePath' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
 -SkipMessage "Skipped - no install folder; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Retry folder create
 try {
 if (-not (Test-Path $gameDir)) {
 New-Item -ItemType Directory -Path $gameDir -Force -ErrorAction Stop | Out-Null
 }
 Write-OK "Folder ready: $gameDir"
 } catch {
 Pause-User "Still cannot create folder. Choose a different path then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}
Write-OK "DUSK HD DLC folder found at: $dlcPath"

# -------------------------------------------------------
# STEP 4: Extract mod files into the DLC subfolder
# -------------------------------------------------------
Write-Step 3 4 "Installing mod files into DLC\DUSK HD"

$tempExtract = Join-Path $env:TEMP "DuskHDVR_$([System.IO.Path]::GetRandomFileName())"
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

Write-Host " Copying files into: $dlcPath" -ForegroundColor Gray
try {
 Get-ChildItem -Path $srcRoot | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $dlcPath -Recurse -Force
 }
 Write-OK "Mod files installed into the DUSK HD DLC folder."
} catch {
 Write-Fail "Copy failed: $_"
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files from '$srcRoot' into '$dlcPath' (the DUSK HD DLC folder of your DUSK install). Watch for UAC permission prompts. Then choose Skip to continue." `
 -SkipMessage "Skipped - mod files were NOT copied; the DLC will not be enabled." `
 -SourceFolder "$srcRoot" `
 -DestFolder "$dlcPath" `
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
$bepinexDir = Join-Path $dlcPath "BepInEx"
$modDll = Join-Path $dlcPath "BepInEx\plugins\UnityVR_DuskHD.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $dlcPath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but UnityVR_DuskHD.dll is missing."
} else {
 Write-OK "BepInEx + UnityVR_DuskHD.dll present in DLC folder."
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

$vigemExe = Get-ChildItem -Path (Join-Path $dlcPath "BepInEx\redist") -Filter "ViGEmBus_*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

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
 Write-Warn "ViGEmBus installer not found in $dlcPath\BepInEx\redist"
 Write-Info "If VR controllers don't work in-game, look for ViGEmBus_*.exe inside the mod folder."
}

# -------------------------------------------------------
# Optional: Roomscale Enabler add-on
# -------------------------------------------------------
Write-Host ""
Write-Host " Optional: Roomscale Enabler add-on" -ForegroundColor Cyan
Write-Host " ----------------------------------" -ForegroundColor DarkGray
Write-Host " Astienth has a separate optional plugin that lets you" -ForegroundColor White
Write-Host " tweak roomscale behaviour (with a PDF guide in its ZIP)." -ForegroundColor White
Write-Host " Most players don't need it - skip if you're unsure." -ForegroundColor Gray
Write-Host ""
Write-Host "   (auto-opens: $DISCORD_ROOMSCALE_URL)" -ForegroundColor DarkGray
Write-Host ""
Write-Host " >>> [Y] Open the Roomscale download post in browser" -ForegroundColor Yellow
Write-Host " >>> [N] Skip (recommended for first-time install)" -ForegroundColor Gray
$rs = ""
while ($rs -notin @("y","Y","n","N")) { $rs = (Read-Host " Your choice (Y/N)").Trim() }
if ($rs -in @("y","Y")) {
 try { Start-Process $DISCORD_ROOMSCALE_URL } catch {}
 Write-Info "Browser opened. After downloading, extract the ZIP into:"
 Write-Host " $dlcPath" -ForegroundColor DarkGray
 Write-Info "Read the included PDF for usage instructions."
}

# -------------------------------------------------------
# Record install path so the Hub can mark VR Ready
# -------------------------------------------------------
# We record the Steam game root (NOT the DLC subfolder) because
# the Hub joins ModFile relative to the recorded path. ModFile
# in the Hub entry already includes the "DLC\DUSK HD\" prefix,
# so the joined path resolves correctly. Recording the DLC
# subfolder here would double up the path.
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
 # LAUNCH: plain Dusk.exe (root) OR steam://rungameid start classic DUSK
 # without the HD DLC - which the VR mod does NOT patch, so VR never
 # engages. The HD build lives in its own DLC subfolder; point the Hub's
 # "Start in VR" straight at it via .launch_exe (takes priority over
 # steam://). Path is verified by Read-LaunchOverride before use.
 $hdExe = Join-Path (Join-Path $gamePath $DLC_SUBFOLDER) $GAME_EXE
 if (Test-Path -LiteralPath $hdExe) {
  Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $hdExe -Encoding UTF8 -Force
 }
} catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " CRITICAL launching steps - read carefully:" -ForegroundColor Yellow
Write-Host " -------------------------------------------" -ForegroundColor Yellow
Write-Host " 1. Game window MUST stay focused while playing -" -ForegroundColor White
Write-Host " controls won't work otherwise." -ForegroundColor White
Write-Host " 2. Enable 'allow gamepads' in the in-game options." -ForegroundColor White
Write-Host " 3. UNPLUG any other input devices (extra gamepad," -ForegroundColor White
Write-Host " racing wheel, flight stick, etc.) - they will" -ForegroundColor White
Write-Host " interfere with your VR controllers." -ForegroundColor White
Write-Host " 4. After launch, on the title screen, listen for the" -ForegroundColor White
Write-Host " Windows USB sound - that means the virtual gamepad" -ForegroundColor White
Write-Host " was recognised. WAIT a few more seconds before" -ForegroundColor White
Write-Host " trying to navigate the menus." -ForegroundColor White
Write-Host ""
Write-Host " Controls (mapped as Xbox gamepad with these exceptions):" -ForegroundColor White
Write-Host " - VR left grip = Xbox RB (= weapon wheel)" -ForegroundColor Gray
Write-Host " - VR right grip = Xbox R3 (= run if autorun off)" -ForegroundColor Gray
Write-Host " - VR right stick click = Xbox LB" -ForegroundColor Gray
Write-Host " - Aim with your dominant hand: shoot, interact, doors" -ForegroundColor Gray
Write-Host " - Dual wielding: weapons separated, one per hand" -ForegroundColor Gray
Write-Host ""
Write-Host " HOTKEY GESTURE: hold left controller close to your" -ForegroundColor Gray
Write-Host " head (real life) - vibrates while active. While vibrating:" -ForegroundColor Gray
Write-Host " * Left stick = D-Pad" -ForegroundColor Gray
Write-Host " * Left stick click = Back / View button" -ForegroundColor Gray
Write-Host " * Right stick click = Start / Menu button" -ForegroundColor Gray
Write-Host ""
Write-Host " Features: bHaptics (vest, arms, visor) + ProTube/ForceTube" -ForegroundColor Gray
Write-Host " - bHaptics: launch bHaptics player + devices BEFORE game" -ForegroundColor Gray
Write-Host " - ProTube: launch game first, then turn devices on one" -ForegroundColor Gray
Write-Host " by one. First = pistol1 (right), Second = pistol2 (left)" -ForegroundColor Gray
Write-Host ""
Write-Host " Config file: BepInEx\config\UnityVR_DuskHD.cfg" -ForegroundColor Gray
Write-Host " handRotationOffsetX = 40 (weapon angle; tune per controller)" -ForegroundColor Gray
Write-Host " leftHanded = false (true for left-hand mode)" -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues (per the modder):" -ForegroundColor Yellow
Write-Host " - No weapon zoom" -ForegroundColor Gray
Write-Host " - No backflip (decoupled pitch)" -ForegroundColor Gray
Write-Host " - Custom maps may not follow the naming pattern" -ForegroundColor Gray
Write-Host " - Not tested with other mods" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " DLC\DUSK HD folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " The cult is hungry. Feed them lead." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

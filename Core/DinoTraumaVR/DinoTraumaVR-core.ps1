# -------------------------------------------------------
# Dino Trauma VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Dino Trauma install folder
# 5. Extract mod files in place
# 6. ViGEmBus install (REQUIRED for VR controllers)
# 7. Optional left-handed config swap
#
# This is a motion-controls mod - VR controllers map to a
# virtual Xbox pad via ViGEmBus. Weapons attach to your
# right hand by default; flashlight + kick to your left.
# ViGEm step is required for VR controller users.
#
# Special: the mod itself does NOT create a per-mod
# config with a left-handed toggle (the author confirmed
# this in Discord). Instead, the left-handed mode is
# done by replacing the bundled UnityVR_Bepinex.cfg with
# a pre-baked variant where the right/left hand attach-
# objects are swapped. We bundle that variant alongside
# the installer and offer it as an opt-in at the end.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "DinoTrauma_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2149420"
$GAME_NAME = "Dino Trauma"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1362075882042167377/1362079563756208429"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1362075882042167377/1362075882042167377"
$DISCORD_LEFTHAND_URL = "https://discord.com/channels/1001138422972432597/1362075882042167377/1374444537102995456"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Dino Trauma VR Mod Installer" -ForegroundColor Cyan
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

function Find-DinoTraumaGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Unity data folder is "Dino Trauma_Data" (with space).
 # Steam installdir mirrors that. Presence of the _Data
 # folder is the strongest signal we found the right install.
 foreach ($folder in @("Dino Trauma", "DinoTrauma", "Dino Trauma Demo")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Dino Trauma_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Dino Trauma VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download DinoTrauma_VR.zip from the mod channel" -ForegroundColor Gray
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
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a MOTION CONTROLS mod with weapons attached to" -ForegroundColor White
Write-Host " your right hand and flashlight + kick on your left hand." -ForegroundColor White
Write-Host " To use VR controllers you MUST install ViGEmBus (the" -ForegroundColor White
Write-Host " installer can do it for you)." -ForegroundColor White
Write-Host ""
Write-Host " Features included: bHaptics support." -ForegroundColor White
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
Write-Step 1 5 "Locate the downloaded ZIP"
Write-Host " Once DinoTrauma_VR.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Dino Trauma install
# -------------------------------------------------------
Write-Step 2 5 "Locating Dino Trauma"

$gamePath = Find-DinoTraumaGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2149420" -SteamFolderNames @("Dino Trauma") }
if ($gamePath) {
 Write-OK "Found Dino Trauma at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Dino Trauma in any Steam library."
 Write-Host " Please paste the path to your Dino Trauma folder" -ForegroundColor White
 Write-Host " (the folder that contains 'Dino Trauma_Data')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Dino Trauma folder").Trim().Trim('"')
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
Write-Step 3 5 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "DinoTraumaVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\DinoTrauma_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but DinoTrauma_VR.dll is missing."
} else {
 Write-OK "BepInEx + DinoTrauma_VR.dll present."
}

# -------------------------------------------------------
# STEP 5: ViGEmBus driver (REQUIRED for VR controllers)
# -------------------------------------------------------
Write-Step 4 5 "ViGEmBus driver (REQUIRED for VR controllers)"

Write-Host " Dino Trauma VR maps your VR controllers to a virtual" -ForegroundColor Gray
Write-Host " Xbox gamepad through ViGEmBus. Without this driver" -ForegroundColor Gray
Write-Host " installed, the game won't accept your VR controller" -ForegroundColor Gray
Write-Host " input." -ForegroundColor Gray
Write-Host ""
Write-Host " If you've already installed ViGEmBus (e.g. for another" -ForegroundColor White
Write-Host " Astienth mod, Virtual Desktop, or any controller-emulation" -ForegroundColor White
Write-Host " software), you can safely skip this." -ForegroundColor White
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
 Write-Host " >>> [Y] Install ViGEmBus now (required for VR controllers)" -ForegroundColor Yellow
 Write-Host " >>> [N] Skip - already installed, or I'll use a real gamepad" -ForegroundColor Gray
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
 Write-Info "ViGEmBus skipped. If your VR controllers don't work in-game,"
 Write-Info "come back and run the setup manually:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
} else {
 Write-Warn "ViGEmBus installer not found in BepInEx\redist - the mod ZIP may be a different version."
 Write-Info "If your VR controllers don't work in-game, look for ViGEmBus_*.exe inside the mod folder."
}

# -------------------------------------------------------
# STEP 6: Optional left-handed config swap
# -------------------------------------------------------
Write-Step 5 5 "Left-handed mode (optional)"

Write-Host " The Dino Trauma VR mod doesn't have its own left-handed" -ForegroundColor Gray
Write-Host " toggle in code. The author published a swapped" -ForegroundColor Gray
Write-Host " UnityVR_Bepinex.cfg where the right/left hand attach" -ForegroundColor Gray
Write-Host " objects are flipped, so weapons go to your left hand and" -ForegroundColor Gray
Write-Host " the flashlight + kick to your right." -ForegroundColor Gray
Write-Host ""
Write-Host " This Hub bundles that variant alongside the standard mod." -ForegroundColor Gray
Write-Host ""
Write-Host " Source post:" -ForegroundColor DarkGray
Write-Host " $DISCORD_LEFTHAND_URL" -ForegroundColor DarkGray
Write-Host ""
Write-Host " >>> [Y] Use left-handed mode (replaces UnityVR_Bepinex.cfg)" -ForegroundColor Yellow
Write-Host " >>> [N] Standard right-handed mode (default)" -ForegroundColor Gray
$lhChoice = ""
while ($lhChoice -notin @("y","Y","n","N")) { $lhChoice = (Read-Host " Your choice (Y/N)").Trim() }
if ($lhChoice -in @("y","Y")) {
 $lhSrc = Join-Path $PSScriptRoot "UnityVR_Bepinex_LeftHanded.cfg"
 $targetCfg = Join-Path $gamePath "BepInEx\config\UnityVR_Bepinex.cfg"
 if (-not (Test-Path $lhSrc)) {
 Write-Warn "Left-handed config not found in the installer folder."
 Write-Host " Expected: $lhSrc" -ForegroundColor DarkGray
 Write-Host " The standard right-handed config stays in place." -ForegroundColor Gray
 } else {
 try {
 # Backup the standard config alongside the new one so the
 # user can roll back without redownloading the mod ZIP.
 $backupCfg = Join-Path $gamePath "BepInEx\config\UnityVR_Bepinex.cfg.righthanded.bak"
 if ((Test-Path $targetCfg) -and (-not (Test-Path $backupCfg))) {
 Copy-Item -Path $targetCfg -Destination $backupCfg -Force
 Write-OK "Backed up right-handed config to: UnityVR_Bepinex.cfg.righthanded.bak"
 }
 Copy-Item -Path $lhSrc -Destination $targetCfg -Force
 Write-OK "Left-handed config installed. Weapons now go to your left hand."
 } catch {
 Write-Warn "Could not swap to left-handed config: $_"
 Write-Host " The standard config stays in place. You can swap manually later" -ForegroundColor Gray
 Write-Host " by replacing $targetCfg with the left-handed version." -ForegroundColor Gray
 }
 }
} else {
 Write-Info "Standard right-handed mode kept. The left-handed config is bundled in:"
 Write-Host " $PSScriptRoot\UnityVR_Bepinex_LeftHanded.cfg" -ForegroundColor DarkGray
 Write-Host " Copy it over BepInEx\config\UnityVR_Bepinex.cfg later if you" -ForegroundColor Gray
 Write-Host " change your mind." -ForegroundColor Gray
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
Write-Host " Launch Dino Trauma normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Controls:" -ForegroundColor White
Write-Host " - VR controllers map as an Xbox controller" -ForegroundColor Gray
Write-Host " (ABXY = same buttons, grips = LB/RB, triggers = LT/RT)" -ForegroundColor Gray
if ($lhChoice -in @("y","Y")) {
 Write-Host " - Weapons attached to your LEFT hand (left-handed mode)" -ForegroundColor Gray
 Write-Host " - Flashlight + kick on your RIGHT hand" -ForegroundColor Gray
 Write-Host " - Aim at objects, doors, items with your LEFT hand to interact" -ForegroundColor Gray
} else {
 Write-Host " - Weapons attached to your RIGHT hand" -ForegroundColor Gray
 Write-Host " - Flashlight + kick on your LEFT hand" -ForegroundColor Gray
 Write-Host " - Aim at objects, doors, items with your RIGHT hand to interact" -ForegroundColor Gray
}
Write-Host ""
Write-Host " GAME-SPECIFIC HOTKEYS:" -ForegroundColor Cyan
Write-Host " Both stick clicks -> Recenter VR view" -ForegroundColor Gray
Write-Host " Right stick click + A -> Force-reattach weapons /" -ForegroundColor Gray
Write-Host " flashlight / kick" -ForegroundColor Gray
Write-Host " Look up/down + left stick -> Climb ladders / swim" -ForegroundColor Gray
Write-Host " (ladders can be tricky," -ForegroundColor Gray
Write-Host " may need a few tries)" -ForegroundColor Gray
Write-Host ""
Write-Host " HOTKEY GESTURE: hold left controller close to the left" -ForegroundColor Gray
Write-Host " side of your head - it vibrates while active. While" -ForegroundColor Gray
Write-Host " vibrating:" -ForegroundColor Gray
Write-Host " * Left stick = D-Pad" -ForegroundColor Gray
Write-Host " * Left stick click = Back / View button" -ForegroundColor Gray
Write-Host " * Right stick click = Start / Menu button" -ForegroundColor Gray
Write-Host ""
Write-Host " Features:" -ForegroundColor Gray
Write-Host " - bHaptics support" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues:" -ForegroundColor Gray
Write-Host " - Flashlight doesn't always attach properly: use" -ForegroundColor Gray
Write-Host " right stick click + A to force-reattach." -ForegroundColor Gray
Write-Host " - Camera/player orientation can occasionally be off:" -ForegroundColor Gray
Write-Host " recenter with both stick clicks to fix." -ForegroundColor Gray
Write-Host " - In-game menus with a scrollable list don't work yet" -ForegroundColor Gray
Write-Host " (mod author is working on it)." -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Sixty-five million years and they still want to eat you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

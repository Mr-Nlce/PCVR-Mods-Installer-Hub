# -------------------------------------------------------
# Hollow Knight VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download (linked from the Discord post)
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Hollow Knight install folder
# 5. OPTIONAL: create a flat-screen-safe copy of the
# game folder (the mod makes the original folder
# unable to launch in flat-screen mode)
# 6. Extract mod files in place (or in the copy)
#
# Hollow Knight VR is a depth-enhancement mod for the 2D
# game - it spaces the sprite layers apart in 3D space so
# your VR headset perceives depth, but the game stays 2D.
# No motion controls. ViGEmBus is not needed.
#
# IMPORTANT: installing this mod into a game folder makes
# THAT folder VR-only - the game can no longer be launched
# in flat-screen from the same folder. The mod author
# strongly recommends copying the game folder first so the
# original stays flat-playable. Same workflow as Sayonara
# Wild Hearts.
#
# This is the ORIGINAL Hollow Knight (Team Cherry, App ID
# 367520) - NOT Silksong (App ID 1030300, separate hub
# entry with its own installer).
#
# Recenter view: hold gamepad UP + LEFT SHOULDER + START
# simultaneously, OR use SteamVR's own recenter.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "HollowKnight_VREnhanced"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "367520"
$GAME_NAME = "Hollow Knight"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; this game's mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1254790696502693888/1254790696502693888"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1254790696502693888/1423987649785364562"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Hollow Knight VR Mod Installer" -ForegroundColor Cyan
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

function Find-HollowKnightGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Hollow Knight" (with space). The
 # Unity data folder is "hollow_knight_Data" (lowercase
 # snake_case - reflects the older Unity build naming).
 # We also probe the no-space form in case some setup ended
 # up that way.
 foreach ($folder in @("Hollow Knight", "HollowKnight")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\hollow_knight_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Hollow Knight VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download the Hollow Knight VR ZIP from the mod post" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Heads-up about the depth-enhancement nature + flat-screen warning.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " Hollow Knight VR is a DEPTH-ENHANCEMENT mod for the 2D" -ForegroundColor White
Write-Host " game. It spaces the sprite layers apart in 3D space so" -ForegroundColor White
Write-Host " your VR headset perceives depth - but the game itself" -ForegroundColor White
Write-Host " stays 2D. NO motion controls. Use GAMEPAD or KEYBOARD." -ForegroundColor White
Write-Host " ViGEmBus is not needed." -ForegroundColor White
Write-Host ""
Write-Host " Seated experience recommended. Recenter by holding the" -ForegroundColor White
Write-Host " UP, QUICKMAP and PAUSE buttons together (gamepad: up +" -ForegroundColor White
Write-Host " left shoulder + start), or via SteamVR's own recenter." -ForegroundColor White
Write-Host ""
Write-Host " This is the ORIGINAL Hollow Knight (Team Cherry, App" -ForegroundColor White
Write-Host " ID 367520). For Silksong VR, use the separate Silksong" -ForegroundColor White
Write-Host " entry in the Hub - they're distinct mods for distinct" -ForegroundColor White
Write-Host " games." -ForegroundColor White
Write-Host ""
Write-Host " CRITICAL HEADS-UP:" -ForegroundColor Yellow
Write-Host " Installing this mod into a game folder makes that folder" -ForegroundColor White
Write-Host " VR-ONLY - flat-screen mode will no longer work from the" -ForegroundColor White
Write-Host " same folder. The author strongly recommends copying the" -ForegroundColor White
Write-Host " game folder first so the original stays flat-playable." -ForegroundColor White
Write-Host " The installer will offer to make the copy for you in" -ForegroundColor White
Write-Host " step 4." -ForegroundColor White
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
}

Write-Host ""
 Write-Host " [Step 3/3] Mod download post   " -ForegroundColor Cyan -NoNewline
 Write-Host "Download: the mod ZIP" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
Write-Host " Background info: $DISCORD_INFO_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the download post..."
try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}

# -------------------------------------------------------
# STEP 2: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 4 "Locate the downloaded ZIP"
Write-Host " Once the Hollow Knight VR mod ZIP is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Hollow Knight install
# -------------------------------------------------------
Write-Step 2 4 "Locating Hollow Knight"

$originalGamePath = Find-HollowKnightGamePath
if (-not $originalGamePath) { $originalGamePath = Find-SteamGameFolder -AppId "367520" -SteamFolderNames @("Hollow Knight") -GogNames @("Hollow Knight") }
if ($originalGamePath) {
 Write-OK "Found Hollow Knight at: $originalGamePath"
} else {
 Write-Warn "Could not auto-locate Hollow Knight in any Steam library."
 Write-Host " Looking for a folder containing 'hollow_knight_Data'." -ForegroundColor Gray
 Write-Host " Please paste the path to your Hollow Knight folder." -ForegroundColor White
 Write-Host ""
 while (-not $originalGamePath) {
 $r = (Read-Host " Hollow Knight folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $originalGamePath = $r
 Write-OK "Game folder set: $originalGamePath"
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 4: Optional copy of the game folder (flat-screen-safe)
# -------------------------------------------------------
Write-Step 3 4 "Make a flat-screen-safe copy?"

Write-Host " The mod author strongly recommends copying the game folder" -ForegroundColor White
Write-Host " before installing the VR mod, because the modded folder" -ForegroundColor White
Write-Host " cannot be launched in flat-screen mode." -ForegroundColor White
Write-Host ""
Write-Host " Original folder:" -ForegroundColor Gray
Write-Host " $originalGamePath" -ForegroundColor Cyan
Write-Host ""
Write-Host " [Y] Make a copy and install the mod into the COPY" -ForegroundColor Yellow
Write-Host " (recommended - flat-screen play stays available" -ForegroundColor Gray
Write-Host " from the original Steam folder)" -ForegroundColor Gray
Write-Host " [N] Install the mod directly into the original folder" -ForegroundColor Yellow
Write-Host " (you will only be able to play in VR from this" -ForegroundColor Gray
Write-Host " folder afterwards - Steam will keep launching" -ForegroundColor Gray
Write-Host " the modded VR build)" -ForegroundColor Gray
Write-Host ""
$wantCopy = ""
while ($wantCopy -notin @("y","Y","n","N")) {
 $wantCopy = (Read-Host " Your choice (Y/N)").Trim()
}

if ($wantCopy -in @("y","Y")) {
 # Default copy location: sibling folder named "Hollow Knight VR".
 # User can override.
 $parentDir = Split-Path -Parent $originalGamePath
 $defaultCopy = Join-Path $parentDir "Hollow Knight VR"

 Write-Host ""
 Write-Host " Default copy location:" -ForegroundColor Gray
 Write-Host " $defaultCopy" -ForegroundColor Cyan
 Write-Host ""
 Write-Host " [Y] Use the default location" -ForegroundColor Yellow
 Write-Host " [N] Pick a different folder" -ForegroundColor Yellow
 $useDefault = ""
 while ($useDefault -notin @("y","Y","n","N")) { $useDefault = (Read-Host " Your choice (Y/N)").Trim() }

 if ($useDefault -in @("y","Y")) {
 $copyTarget = $defaultCopy
 } else {
 $copyTarget = $null
 while (-not $copyTarget) {
 $r = (Read-Host " Full path for the copy (must NOT exist yet)").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 Write-Fail "Path already exists: $r"
 continue
 }
 $copyTarget = $r
 }
 }

 if (Test-Path $copyTarget) {
 Write-Warn "Copy target already exists: $copyTarget"
 Write-Host " Skipping the copy and using the existing folder. If" -ForegroundColor Gray
 Write-Host " this is wrong, abort with Ctrl+C and rerun." -ForegroundColor Gray
 } else {
 Write-Host ""
 Write-Host " Copying game folder (this may take a minute)..." -ForegroundColor Gray
 Write-Host " From: $originalGamePath" -ForegroundColor DarkGray
 Write-Host " To: $copyTarget" -ForegroundColor DarkGray
 try {
 New-Item -ItemType Directory -Path $copyTarget -Force | Out-Null
 Copy-Item -Path (Join-Path $originalGamePath '*') -Destination $copyTarget -Recurse -Force -ErrorAction Stop
 Write-OK "Copy complete."
 } catch {
 Write-Fail "Copy failed: $_"
 Write-Host " Falling back to installing into the ORIGINAL folder." -ForegroundColor Yellow
 Write-Host " Flat-screen play will not be available from this folder." -ForegroundColor Yellow
 Pause-User "Press Enter to acknowledge and continue..."
 $copyTarget = $originalGamePath
 }
 }
 $gamePath = $copyTarget
} else {
 Write-Warn "Installing into the ORIGINAL folder. Flat-screen play"
 Write-Warn "will not be available from this folder afterwards."
 $gamePath = $originalGamePath
}

# -------------------------------------------------------
# STEP 5: Extract mod files into the (chosen) game folder
# -------------------------------------------------------
Write-Step 4 4 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "HollowKnightVR_$([System.IO.Path]::GetRandomFileName())"
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

# Sanity check.
$bepinexDir = Join-Path $gamePath "BepInEx"
$modDll = Join-Path $gamePath "BepInEx\plugins\HollowKnight_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but HollowKnight_VR.dll is missing."
} else {
 Write-OK "BepInEx + HollowKnight_VR.dll present."
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
if ($gamePath -eq $originalGamePath) {
 Write-Host " Mod installed into the ORIGINAL Steam folder:" -ForegroundColor White
 Write-Host " $gamePath" -ForegroundColor Cyan
 Write-Host " Steam will now launch the VR build. To go back to" -ForegroundColor Yellow
 Write-Host " flat-screen, rename winhttp.dll in this folder." -ForegroundColor Yellow
} else {
 Write-Host " Mod installed into the COPY:" -ForegroundColor White
 Write-Host " $gamePath" -ForegroundColor Cyan
 Write-Host " Original folder is untouched - flat-screen play still" -ForegroundColor Gray
 Write-Host " works via Steam." -ForegroundColor Gray
 Write-Host ""
 Write-Host " Launch the VR build with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host " .exe inside the copy:" -ForegroundColor White
 Write-Host " $gamePath\hollow_knight.exe" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host " Use a GAMEPAD or KEYBOARD - no VR controller support." -ForegroundColor Yellow
Write-Host " Game controls are unchanged." -ForegroundColor Gray
Write-Host ""
Write-Host " Recenter view:" -ForegroundColor Gray
Write-Host " Hold UP + QUICKMAP + PAUSE simultaneously" -ForegroundColor Gray
Write-Host " (gamepad: up + left shoulder + start), OR" -ForegroundColor Gray
Write-Host " Use SteamVR's own recenter function" -ForegroundColor Gray
Write-Host ""
Write-Host " Seated experience recommended." -ForegroundColor Gray
Write-Host ""
Write-Host " ---- Depth tuning (optional) ---------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host " After the FIRST launch with the mod, a config file" -ForegroundColor White
Write-Host " appears here:" -ForegroundColor White
Write-Host " BepInEx\config\HollowKnight_VR.cfg" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Tunable values (defaults shown):" -ForegroundColor Gray
Write-Host " spaceBetweenMultiplier = 1.65" -ForegroundColor Gray
Write-Host " Distance between sprite layers - this is what" -ForegroundColor Gray
Write-Host " produces the depth effect. Higher = more depth." -ForegroundColor Gray
Write-Host " VRCamDistance = 0,0,10" -ForegroundColor Gray
Write-Host " Headset distance from the scene (X,Y,Z). If you're" -ForegroundColor Gray
Write-Host " not sure, only change Z. INCREASE Z to get CLOSER." -ForegroundColor Gray
Write-Host " worldScale = 1" -ForegroundColor Gray
Write-Host " Relative scale of the world." -ForegroundColor Gray
Write-Host " UIScale = 1" -ForegroundColor Gray
Write-Host " Relative scale of the UI." -ForegroundColor Gray
Write-Host ""
Write-Host " Plus in BepInEx\config\UnityVR_Bepinex.cfg:" -ForegroundColor Gray
Write-Host " canvasOffset = 0.0,0.0,1.4" -ForegroundColor Gray
Write-Host " UI offset relative to headset (X,Y,Z). Smaller Z =" -ForegroundColor Gray
Write-Host " closer UI, larger Z = further away." -ForegroundColor Gray
Write-Host ""
Write-Host " World-scale recipe from the mod author:" -ForegroundColor Gray
Write-Host " Increasing worldScale changes the perceived size of" -ForegroundColor Gray
Write-Host " the world but reduces the camera's 6DoF freedom. If" -ForegroundColor Gray
Write-Host " you want to try a bigger-feeling world, the author" -ForegroundColor Gray
Write-Host " suggests:" -ForegroundColor Gray
Write-Host " worldScale = 20" -ForegroundColor Gray
Write-Host " UIScale = 10" -ForegroundColor Gray
Write-Host " canvasOffset = 0.0,0.0,12" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " modded game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host ""
Write-Host " Ring the bell. Take up the nail. Hallownest waits." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

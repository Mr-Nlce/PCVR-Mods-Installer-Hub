# -------------------------------------------------------
# Hollow Knight Silksong VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Pre-install requirement check (launch game once first)
# 4. Drag-and-drop ZIP into this window
# 5. Auto-locate Hollow Knight Silksong install folder
# 6. Extract mod files in place
#
# This is a 2D depth-enhancing mod - it adds parallax-style
# depth between sprite layers to give a sense of dimension
# in VR. No motion-controller support; gamepad or keyboard
# is required, just like the base game. No ViGEmBus needed.
#
# Important: the user MUST launch the game at least once
# before installing the mod, so the initial settings/save
# files exist. The installer prompts for confirmation.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "HollowKnightSilksong_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1030300"
$GAME_NAME = "Hollow Knight Silksong"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1414940597579419679/1440826936698998785"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Hollow Knight Silksong VR Mod Installer" -ForegroundColor Cyan
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

function Find-SilksongGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Unity data folder is "Hollow Knight Silksong_Data" (with
 # spaces). Steam installdir mirrors that. Presence of the
 # _Data folder is the strongest signal we found the right
 # install. Try the no-space variants too in case of edge
 # cases.
 foreach ($folder in @("Hollow Knight Silksong", "HollowKnightSilksong", "Silksong")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Hollow Knight Silksong_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Hollow Knight Silksong VR is distributed by Astienth" -ForegroundColor White
Write-Host " via Discord. Are you already a member of the FarmerTrueVR" -ForegroundColor White
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
 Write-Host " 3. Download HollowKnightSilksong_VR.zip from the mod channel" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warnings - distinct from other Astienth mods
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " Silksong is a 2D game. This mod ONLY adds depth between" -ForegroundColor White
Write-Host " sprite layers to create a 3D feel - it does NOT add" -ForegroundColor White
Write-Host " motion-controller support. You will play with a gamepad" -ForegroundColor White
Write-Host " or keyboard, exactly like the base game." -ForegroundColor White
Write-Host ""
Write-Host " >>> Launch Hollow Knight Silksong at least ONCE before" -ForegroundColor Yellow
Write-Host " >>> installing this mod, and get past the initial settings." -ForegroundColor Yellow
Write-Host " >>> The mod expects the game's first-run files to exist." -ForegroundColor Yellow
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
# STEP 2: First-run requirement gate
# -------------------------------------------------------
Write-Step 1 4 "Pre-install: launch game once"
Write-Host " Have you launched Hollow Knight Silksong at least once" -ForegroundColor White
Write-Host " and gotten past the initial settings?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [Y] Yes, I've already launched the game" -ForegroundColor Yellow
Write-Host " >>> [N] No - I'll launch it now and come back" -ForegroundColor Yellow
Write-Host ""
$firstRun = ""
while ($firstRun -notin @("y","Y","n","N")) {
 $firstRun = (Read-Host " Your choice (Y/N)").Trim()
}
if ($firstRun -in @("n","N")) {
 Write-Host ""
 Write-Host " No worries. Launch Silksong via Steam, get past the" -ForegroundColor Gray
 Write-Host " initial settings, then close the game. Once you're" -ForegroundColor Gray
 Write-Host " done, come back here and re-run this installer." -ForegroundColor Gray
 Write-Host ""
 Pause-User "Press Enter to exit."
 exit 0
}

# -------------------------------------------------------
# STEP 3: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 2 4 "Locate the downloaded ZIP"
Write-Host " Once HollowKnightSilksong_VR.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 4: Locate the Hollow Knight Silksong install
# -------------------------------------------------------
Write-Step 3 4 "Locating Hollow Knight Silksong"

$gamePath = Find-SilksongGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1030300" -SteamFolderNames @("Hollow Knight Silksong") -GogNames @("Hollow Knight Silksong") }
if ($gamePath) {
 Write-OK "Found Hollow Knight Silksong at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Hollow Knight Silksong in any Steam library."
 Write-Host " Please paste the path to your Hollow Knight Silksong folder" -ForegroundColor White
 Write-Host " (the folder that contains 'Hollow Knight Silksong_Data')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Hollow Knight Silksong folder").Trim().Trim('"')
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
# STEP 5: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 4 4 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "HollowKnightSilksongVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\HollowKnightSilksong_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but HollowKnightSilksong_VR.dll is missing."
} else {
 Write-OK "BepInEx + HollowKnightSilksong_VR.dll present."
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
Write-Host " Launch Hollow Knight Silksong normally via Steam, the" -ForegroundColor White
Write-Host " desktop shortcut, or the 'Start in VR' button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " This is a depth-enhancement mod, NOT a motion-control" -ForegroundColor Yellow
Write-Host " conversion. Use a gamepad or keyboard to play." -ForegroundColor Yellow
Write-Host ""
Write-Host " Controls (game controls are unchanged):" -ForegroundColor White
Write-Host " - Recenter view: SteamVR recenter, OR" -ForegroundColor Gray
Write-Host " hold Up + QuickMap + Pause buttons together" -ForegroundColor Gray
Write-Host " (gamepad: Up + LB + Start)" -ForegroundColor Gray
Write-Host " - Toggle vignette on/off: hold the Start button" -ForegroundColor Gray
Write-Host " (some areas have a strong vignette - this lets you" -ForegroundColor Gray
Write-Host " remove it on-the-fly while playing)" -ForegroundColor Gray
Write-Host ""
Write-Host " Configuration files:" -ForegroundColor Gray
Write-Host " BepInEx\config\HollowKnightSilksong_VR.cfg" -ForegroundColor DarkGray
Write-Host " spaceBetweenMultiplier = 1.65 (depth between sprite" -ForegroundColor Gray
Write-Host " layers; the depth effect)" -ForegroundColor Gray
Write-Host " VRCamDistance = 0,0,10 (headset distance from" -ForegroundColor Gray
Write-Host " scene; only change Z)" -ForegroundColor Gray
Write-Host " worldScale = 1 (relative world scale)" -ForegroundColor Gray
Write-Host " UIScale = 1 (UI scale)" -ForegroundColor Gray
Write-Host ""
Write-Host " BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " canvasOffset = 0.0,0.0,1.4 (UI distance to headset" -ForegroundColor Gray
Write-Host " smaller = closer)" -ForegroundColor Gray
Write-Host ""
Write-Host " Increased-world-scale config that the mod author tested:" -ForegroundColor Gray
Write-Host " worldScale = 20" -ForegroundColor Gray
Write-Host " UIScale = 10" -ForegroundColor Gray
Write-Host " canvasOffset = 0.0,0.0,12" -ForegroundColor Gray
Write-Host " Note: increasing worldScale can lose VR camera 6DoF -" -ForegroundColor Gray
Write-Host " if anything breaks, restore the defaults." -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues:" -ForegroundColor Gray
Write-Host " - Inventory map zoomed in may have visual issues" -ForegroundColor Gray
Write-Host " - Map pin placement is offset (pin appears bottom-right" -ForegroundColor Gray
Write-Host " of cursor, not on cursor)" -ForegroundColor Gray
Write-Host ""
Write-Host " Compatible with other BepInEx mods (no guarantee against" -ForegroundColor Gray
Write-Host " conflicts though)." -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Climb high, Hornet. The Citadel waits." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

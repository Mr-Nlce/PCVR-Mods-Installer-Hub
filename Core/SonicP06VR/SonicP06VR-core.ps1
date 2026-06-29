# -------------------------------------------------------
# Sonic P-06 VR Mod Installer
# by Astienth - distributed via Discord (mod)
# Game by ChaosX (Project 06 fan-remake)
#
# Walks the user through:
# 1. Fan-game download from Google Drive
# (auto-download attempt; falls back to drag-drop)
# 2. Game extraction to C:\Games\Sonic P-06 VR
# (or a custom path)
# 3. Discord server join + rules acknowledgement
# 4. Variant pick (standard vs upside-down-bug fix)
# 5. Mod ZIP drag-drop
# 6. Mod extract on top of the game folder
# 7. Auto-run VRPatch\Apply Patch.bat (xdelta3 binary
# patch on data.unity3d - one-time, the mod's own
# installer step)
#
# This is a SPECIAL case among the Astienth mods:
# - The base game is a free fan-game, NOT on Steam.
# Project 06 by ChaosX, distributed via Google Drive.
# - The mod requires a binary patch step run via the mod
# author's own Apply Patch.bat (xdelta3 vcdiff).
# - Two mod variants exist: standard, and a "fixupsidedownbug"
# variant for users who hit the upside-down-world bug.
#
# Gamepad/keyboard controls only - no VR controller support.
# ViGEmBus is not needed.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "Sonic_P-06_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"
$GAME_NAME = "Sonic P-06"

# Default install location matches the user's house standard.
$DEFAULT_GAME_DIR = "C:\Games\Sonic P-06 VR"

# Google Drive direct-download URL for the fan-game ZIP.
# Public file ID; large file (>100MB) so Drive shows a virus-scan
# confirm page on the first GET. The installer follows that
# token round-trip below.
$GAME_DRIVE_FILE_ID = "1klUEs43gzyqgnsDT9tlTyxy0WYPzLGde"
$GAME_DRIVE_VIEW_URL = "https://drive.google.com/file/d/$GAME_DRIVE_FILE_ID/view"

# Discord URLs (mod is Discord-gated even though the game isn't).
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1267088216456953907/1316306250354524221"
$DISCORD_DOWNLOAD_STD_URL = "https://discord.com/channels/1001138422972432597/1267088216456953907/1271091116195844199"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Sonic P-06 VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host " Game: Project 06 (free fan-remake by ChaosX)" -ForegroundColor Gray
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

# Try to download a public Google-Drive file. For files larger
# than ~100MB, Drive intercepts the first GET with a virus-scan
# confirm page; we need to extract the confirm token from the
# HTML response and follow up with that token. Returns $true on
# success, $false otherwise.
function Get-GoogleDriveFile {
 param(
 [string]$FileId,
 [string]$OutFile
 )
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

 # Use a session so we can carry cookies across redirects.
 $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
 $base = "https://drive.google.com/uc?export=download&id=$FileId"

 try {
 $first = Invoke-WebRequest -Uri $base -WebSession $session -UseBasicParsing -ErrorAction Stop
 } catch {
 return $false
 }

 # If the response is a binary stream (huge content-length, no
 # HTML) - we got the file directly. This is rare for >100MB
 # but possible. We then write the bytes and bail.
 $ct = ""
 try { $ct = $first.Headers['Content-Type'] } catch {}
 if ($ct -and ($ct -notmatch "text/html")) {
 try {
 [System.IO.File]::WriteAllBytes($OutFile, $first.Content)
 return $true
 } catch { return $false }
 }

 # Otherwise we got the HTML confirm page. Pull the token out
 # of any of the common formats Drive has used over the years.
 $html = ""
 try { $html = $first.Content } catch { return $false }

 $token = $null
 $m = [regex]::Match($html, 'confirm=([0-9A-Za-z_\-]+)')
 if ($m.Success) { $token = $m.Groups[1].Value }
 if (-not $token) {
 $m = [regex]::Match($html, 'name="confirm"\s+value="([^"]+)"')
 if ($m.Success) { $token = $m.Groups[1].Value }
 }
 if (-not $token) {
 # Newer Drive uses a form POST to drive.usercontent.google.com.
 # Pull all the hidden form fields and re-submit them.
 $action = $null
 $am = [regex]::Match($html, 'action="([^"]+)"')
 if ($am.Success) { $action = $am.Groups[1].Value -replace '&amp;', '&' }
 if ($action) {
 $fields = @{}
 foreach ($fm in [regex]::Matches($html, 'name="([^"]+)"\s+value="([^"]*)"')) {
 $fields[$fm.Groups[1].Value] = $fm.Groups[2].Value
 }
 try {
 Invoke-WebRequest -Uri $action -Body $fields -Method GET -WebSession $session -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
 if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 1MB)) { return $true }
 } catch {}
 }
 return $false
 }

 # Token-style URL (older Drive flow).
 $tokenUrl = "$base&confirm=$token"
 try {
 Invoke-WebRequest -Uri $tokenUrl -WebSession $session -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
 if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 1MB)) { return $true }
 } catch {}
 return $false
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Sonic P-06 VR is special compared to the other Astienth" -ForegroundColor White
Write-Host " mods - this is a FREE FAN-GAME (Project 06 by ChaosX)," -ForegroundColor White
Write-Host " not a Steam game. The base game is downloaded from Google" -ForegroundColor White
Write-Host " Drive, and the VR mod itself comes from Discord." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " Default install location for this Hub:" -ForegroundColor White
Write-Host " $DEFAULT_GAME_DIR" -ForegroundColor Cyan
Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor Gray
Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor Gray
Write-Host " You can change this in step 2 if you want." -ForegroundColor Gray
Write-Host ""
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " Gamepad / keyboard only - no VR controller support." -ForegroundColor White
Write-Host " ViGEmBus is not needed." -ForegroundColor White
Write-Host ""
Write-Host " Two mod variants exist on Discord:" -ForegroundColor White
Write-Host " * Standard - works for most users" -ForegroundColor White
Write-Host " * Upside-down-bug fix - use this if your world appears" -ForegroundColor White
Write-Host " flipped upside down with the standard variant" -ForegroundColor White
Write-Host " The installer will let you pick later." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: Get the fan-game from Google Drive
# -------------------------------------------------------
Write-Step 1 6 "Fan-game ZIP (Google Drive)"

Write-Host " Project 06 is hosted on Google Drive (no login needed)." -ForegroundColor Gray
Write-Host " The installer will try to download it automatically. If" -ForegroundColor Gray
Write-Host " Google's virus-scan confirm page blocks the auto-download," -ForegroundColor Gray
Write-Host " the installer falls back to opening the page in your" -ForegroundColor Gray
Write-Host " browser so you can grab the ZIP yourself, then drop it" -ForegroundColor Gray
Write-Host " back here." -ForegroundColor Gray
Write-Host ""

# Check if the user already has the game ZIP on hand and wants to
# skip the download attempt. Saves time on rerun / repair.
Write-Host " Do you already have the Project 06 ZIP downloaded?" -ForegroundColor White
Write-Host " [Y] Yes, I'll point the installer at the existing file" -ForegroundColor Yellow
Write-Host " [N] No, please try to download it" -ForegroundColor Yellow
$haveGame = ""
while ($haveGame -notin @("y","Y","n","N")) { $haveGame = (Read-Host " Your choice (Y/N)").Trim() }

$gameZip = $null

if ($haveGame -in @("n","N")) {
 Write-Host ""
 Write-Host " Attempting Google Drive auto-download..." -ForegroundColor Gray
 Write-Host " File: Project 06 - Silver Release (Patch v1.4).zip" -ForegroundColor DarkGray
 Write-Host " Source: $GAME_DRIVE_VIEW_URL" -ForegroundColor DarkGray
 Write-Host " This is a large file (a few hundred MB) - it may take" -ForegroundColor Gray
 Write-Host " several minutes." -ForegroundColor Gray
 Write-Host ""
 $candidate = Join-Path $env:TEMP "ProjectP06_$([System.IO.Path]::GetRandomFileName()).zip"
 $autoOk = $false
 try {
 $autoOk = Get-GoogleDriveFile -FileId $GAME_DRIVE_FILE_ID -OutFile $candidate
 } catch { $autoOk = $false }
 if ($autoOk -and (Test-Path $candidate) -and ((Get-Item $candidate).Length -gt 50MB)) {
 $gameZip = $candidate
 Write-OK "Downloaded: $gameZip ($([math]::Round((Get-Item $gameZip).Length/1MB)) MB)"
 } else {
 Write-Warn "Auto-download didn't complete (Google Drive confirm page or rate limit)."
 Write-Host " Falling back to manual download. Opening the Drive page..." -ForegroundColor Gray
 try { Start-Process $GAME_DRIVE_VIEW_URL } catch {
 Write-Host " Couldn't open browser. Visit this URL manually:" -ForegroundColor Yellow
 Write-Host " $GAME_DRIVE_VIEW_URL" -ForegroundColor DarkGray
 }
 try { Remove-Item $candidate -Force -ErrorAction SilentlyContinue } catch {}
 }
}

# Manual fallback / user-already-has-it path: drag-drop ZIP.
while (-not $gameZip) {
 Write-Host ""
 Write-Host " Drag-and-drop the Project 06 ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " Game ZIP path").Trim().Trim('"')
 if (-not $r) { continue }
 if (-not (Test-Path $r)) { Write-Fail "File not found: $r"; continue }
 if ($r -notmatch '\.zip$|\.7z$|\.rar$') { Write-Fail "Not a ZIP/7z/RAR archive: $r"; continue }
 $gameZip = $r
 Write-OK "Game archive located: $gameZip"
}

# -------------------------------------------------------
# STEP 2: Pick where the game goes + extract it
# -------------------------------------------------------
Write-Step 2 6 "Game install location"

Write-Host " Default location:" -ForegroundColor Gray
Write-Host " $DEFAULT_GAME_DIR" -ForegroundColor Cyan
Write-Host ""
Write-Host " [Y] Use the default" -ForegroundColor Yellow
Write-Host " [N] Pick a different folder" -ForegroundColor Yellow
$useDefault = ""
while ($useDefault -notin @("y","Y","n","N")) { $useDefault = (Read-Host " Your choice (Y/N)").Trim() }

if ($useDefault -in @("y","Y")) {
 $gamePath = $DEFAULT_GAME_DIR
} else {
 $gamePath = $null
 while (-not $gamePath) {
 $r = (Read-Host " Full path for the game folder").Trim().Trim('"')
 if (-not $r) { continue }
 $gamePath = $r
 }
}

# Make sure the parent path exists. If the leaf folder doesn't
# exist yet, that's fine - we'll create it.
try {
 if (-not (Test-Path $gamePath)) {
 New-Item -ItemType Directory -Path $gamePath -Force | Out-Null
 }
 Write-OK "Game folder: $gamePath"
} catch {
 Write-Fail "Could not create folder: $_"
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

Write-Host ""
Write-Host " Extracting game files..." -ForegroundColor Gray
$gameTempExtract = Join-Path $env:TEMP "SonicP06_game_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $gameTempExtract | Out-Null
try {
 Expand-Archive -Path $gameZip -DestinationPath $gameTempExtract -Force
} catch {
 Write-Fail "Game extract failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$gameZip' with 7-Zip or Windows Explorer, and extract its contents into '$gameTempExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$gameZip" -Parent) `
 -DestFolder "$gameTempExtract" `
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

# Project 06 ZIPs typically have a single top-level folder. Unwrap
# it so the contents land directly inside our $gamePath, not
# nested another level deep.
$gameRoot = $gameTempExtract
$gameRootEntries = Get-ChildItem -Path $gameTempExtract
if ($gameRootEntries.Count -eq 1 -and $gameRootEntries[0].PSIsContainer) {
 $gameRoot = $gameRootEntries[0].FullName
}

try {
 Get-ChildItem -Path $gameRoot | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 Write-OK "Game files installed into: $gamePath"
} catch {
 Write-Fail "Game copy failed: $_"
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
try { Remove-Item $gameTempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Verify the game executable landed.
$gameExe = Join-Path $gamePath "Sonic the Hedgehog.exe"
if (-not (Test-Path $gameExe)) {
 Write-Warn "Could not find 'Sonic the Hedgehog.exe' in $gamePath"
 Write-Host " The game ZIP may have a different layout. Check that" -ForegroundColor Gray
 Write-Host " the EXE is present before continuing - the mod won't" -ForegroundColor Gray
 Write-Host " install correctly without it." -ForegroundColor Gray
 Pause-User "Press Enter once you've checked, or Ctrl+C to abort."
} else {
 Write-OK "Game EXE confirmed at: $gameExe"
}

# -------------------------------------------------------
# STEP 3: Discord onboarding for the VR mod
# -------------------------------------------------------
Write-Step 3 6 "Discord onboarding for the VR mod"

Write-Host " The VR mod itself is distributed by Astienth via Discord." -ForegroundColor White
Write-Host " Are you already a member of the FarmerTrueVR Discord" -ForegroundColor White
Write-Host " server (with rules accepted)?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [Y] Yes, skip straight to the download link" -ForegroundColor Yellow
Write-Host " >>> [N] No, walk me through joining + accepting rules" -ForegroundColor Yellow
Write-Host ""
$alreadyMember = ""
while ($alreadyMember -notin @("y","Y","n","N")) {
 $alreadyMember = (Read-Host " Your choice (Y/N)").Trim()
}
$skipJoin = ($alreadyMember -in @("y","Y"))

if (-not $skipJoin) {
 Write-Host ""
 Write-Host " [Substep 1/2] Discord server invite" -ForegroundColor Cyan
 Write-Host " -> $DISCORD_INVITE_URL" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the invite in your browser..."
 try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open browser." }

 Write-Host ""
 Write-Host " [Substep 2/2] Rules channel - READ the rules, then click the AK-47 emoji under the rules post (this is required to unlock the rest of the server)" -ForegroundColor Cyan
 Write-Host " -> $DISCORD_RULES_URL" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the rules channel..."
 try { Start-Process $DISCORD_RULES_URL } catch {}
}

# -------------------------------------------------------
# STEP 4: Variant pick (standard vs upside-down-bug fix)
# -------------------------------------------------------
Write-Step 4 6 "Pick mod variant"

Write-Host " Two mod variants exist on the Discord post:" -ForegroundColor White
Write-Host ""
Write-Host " [S] Standard mod (Sonic_P-06_VR.zip)" -ForegroundColor Yellow
Write-Host " Try this one first." -ForegroundColor Gray
Write-Host ""
Write-Host " [U] Upside-down-bug fix (sonic_p-06_vr_fixupsidedownbug_*.zip)" -ForegroundColor Yellow
Write-Host " Use this only if your world appears flipped upside" -ForegroundColor Gray
Write-Host " down with the standard mod." -ForegroundColor Gray
Write-Host ""
$variantPick = ""
while ($variantPick -notin @("s","S","u","U")) {
 $variantPick = (Read-Host " Your choice (S/U)").Trim()
}
$isUpsideDownFix = ($variantPick -in @("u","U"))
if ($isUpsideDownFix) {
 $expectedZipKeyword = "fixupsidedownbug"
 $variantLabel = "Upside-down-bug fix"
} else {
 $expectedZipKeyword = "Sonic_P-06_VR"
 $variantLabel = "Standard"
}

# Both variants live in the same Discord post (single mod channel,
# multiple files attached on the same message + later messages).
# Direct deep-links to specific attachments aren't reliable, so we
# point the user at the parent info post and let them grab the
# variant they picked.
Write-Host ""
Write-Host " Opening the mod info post (both variants are linked there)..." -ForegroundColor Gray
Write-Host " -> $DISCORD_DOWNLOAD_STD_URL" -ForegroundColor DarkGray
Write-Host " Mod-channel info post: $DISCORD_INFO_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the mod post..."
try { Start-Process $DISCORD_DOWNLOAD_STD_URL } catch {}

# -------------------------------------------------------
# STEP 5: Drag-drop the chosen mod variant
# -------------------------------------------------------
Write-Step 5 6 "Locate the downloaded mod ZIP"

Write-Host " You picked: $variantLabel" -ForegroundColor Gray
Write-Host ""
$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the $variantLabel mod ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " Mod ZIP path").Trim().Trim('"')
 if (-not $r) { continue }
 if (-not (Test-Path $r)) { Write-Fail "File not found: $r"; continue }
 if ($r -notmatch '\.zip$|\.7z$|\.rar$') { Write-Fail "Not a ZIP/7z/RAR archive: $r"; continue }
 $modZip = $r
 Write-OK "Mod archive located: $modZip"
 # Soft-warn on filename mismatch.
 $zipName = [System.IO.Path]::GetFileName($r)
 if ($zipName -notmatch [regex]::Escape($expectedZipKeyword)) {
 Write-Warn "Filename '$zipName' doesn't contain '$expectedZipKeyword' - this might be the other variant."
 Write-Host " You picked $variantLabel but this ZIP doesn't look like it." -ForegroundColor Yellow
 Write-Host " [Y] Continue anyway [N] Pick a different file" -ForegroundColor Gray
 $cont = ""
 while ($cont -notin @("y","Y","n","N")) { $cont = (Read-Host " Your choice (Y/N)").Trim() }
 if ($cont -in @("n","N")) { $modZip = $null }
 }
}

# -------------------------------------------------------
# STEP 6a: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 6 6 "Installing mod files + applying patch"

$modTempExtract = Join-Path $env:TEMP "SonicP06_mod_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $modTempExtract | Out-Null

try {
 Write-Host " Extracting mod archive..." -ForegroundColor Gray
 Expand-Archive -Path $modZip -DestinationPath $modTempExtract -Force
} catch {
 Write-Fail "Mod extract failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$modTempExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$modTempExtract" `
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

$modRootEntries = Get-ChildItem -Path $modTempExtract
$modSrcRoot = $modTempExtract
if ($modRootEntries.Count -eq 1 -and $modRootEntries[0].PSIsContainer) {
 if ($modRootEntries[0].Name -ne "BepInEx") {
 $modSrcRoot = $modRootEntries[0].FullName
 }
}

try {
 Write-Host " Copying mod files into: $gamePath" -ForegroundColor Gray
 Get-ChildItem -Path $modSrcRoot | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 Write-OK "Mod files installed."
} catch {
 Write-Fail "Mod copy failed: $_"
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
try { Remove-Item $modTempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 6b: Run VRPatch\Apply Patch.bat (one-time xdelta3 patch)
# -------------------------------------------------------
$patchBat = Join-Path $gamePath "VRPatch\Apply Patch.bat"
if (-not (Test-Path $patchBat)) {
 Write-Warn "VRPatch\Apply Patch.bat not found - the mod ZIP may have"
 Write-Warn "a different layout. Skipping patch step."
} else {
 Write-Host ""
 Write-Host " Applying the binary patch (xdelta3 vcdiff on data.unity3d)..." -ForegroundColor Gray
 Write-Host " This is a one-time setup that the mod author scripted. A" -ForegroundColor Gray
 Write-Host " command window will open and run for a minute or so. Wait" -ForegroundColor Gray
 Write-Host " for it to finish and press a key when prompted." -ForegroundColor Gray
 Write-Host ""

 # The mod author's BAT uses RELATIVE paths (..\Sonic the
 # Hedgehog_Data\...) so we MUST set the working directory to
 # the VRPatch folder, not just call the BAT from anywhere.
 $patchDir = Join-Path $gamePath "VRPatch"
 try {
 $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c","`"$patchBat`"" -WorkingDirectory $patchDir -Wait -PassThru -ErrorAction Stop
 if ($proc.ExitCode -eq 0) {
 Write-OK "Patch applied (exit 0)."
 } else {
 Write-Warn "Patch BAT exited with code $($proc.ExitCode). The patch may"
 Write-Warn "not have completed. Re-run VRPatch\Apply Patch.bat manually if needed."
 }
 } catch {
 Write-Warn "Could not launch the patch BAT automatically: $_"
 Write-Host " Run it yourself: $patchBat" -ForegroundColor Gray
 }

 # Sanity check: after a successful patch, an "old" folder
 # appears in VRPatch with the un-patched data.unity3d in it.
 $oldFolder = Join-Path $patchDir "old"
 if (Test-Path $oldFolder) {
 Write-Info "Backup of pre-patch data.unity3d at: $oldFolder"
 }
}

# Sanity check on the mod itself.
$modDll = Join-Path $gamePath "BepInEx\plugins\UnityVRPlugin.dll"
if (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx\plugins\UnityVRPlugin.dll missing after install."
} else {
 Write-OK "BepInEx + UnityVRPlugin.dll present."
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
Write-Host " Launch the game:" -ForegroundColor White
Write-Host " $gamePath\Sonic the Hedgehog.exe" -ForegroundColor Cyan
Write-Host " SteamVR will start automatically. The 'Start in VR'" -ForegroundColor Gray
Write-Host " button in the Hub also launches the EXE directly." -ForegroundColor Gray
Write-Host ""
Write-Host " Controls (gamepad or keyboard, NO VR controllers):" -ForegroundColor White
Write-Host " F1 / double-press START -> Toggle first-person view" -ForegroundColor Gray
Write-Host " F2 / hold START -> Recenter view" -ForegroundColor Gray
Write-Host ""
Write-Host " Heads-up notes from the mod author:" -ForegroundColor Gray
Write-Host " - Some in-game graphics settings introduce bugs - try" -ForegroundColor Gray
Write-Host " and error to find what works on your rig." -ForegroundColor Gray
Write-Host " - Reflections render slightly differently per eye -" -ForegroundColor Gray
Write-Host " consider turning reflections OFF in the graphics menu." -ForegroundColor Gray
Write-Host " - For performance, lower in-game settings first; if" -ForegroundColor Gray
Write-Host " that's not enough, drop SteamVR resolution. Headset" -ForegroundColor Gray
Write-Host " resolution is set by SteamVR, not by the in-game" -ForegroundColor Gray
Write-Host " resolution setting." -ForegroundColor Gray
Write-Host " - First-person view is experimental - tank movement," -ForegroundColor Gray
Write-Host " left stick rotates / forward = accelerate. MOTION" -ForegroundColor Gray
Write-Host " SICKNESS warning. Use at your own risk." -ForegroundColor Gray
Write-Host ""
Write-Host " If the world appears upside down, re-run this installer" -ForegroundColor Gray
Write-Host " and pick the [U] Upside-down-bug fix variant in step 4." -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to anything else." -ForegroundColor Gray
Write-Host ""
Write-Host " Built by fans, polished with love. Now go fast." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

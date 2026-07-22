# -------------------------------------------------------
# Another Crab's Treasure VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download (linked from the Discord post)
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Another Crab's Treasure install folder
# 5. Extract mod files in place
#
# Another Crab's Treasure VR is a depth-only mod - it makes
# the game playable in stereoscopic 3D but doesn't add motion
# controls. The base game is gamepad-or-KB&M; in VR a gamepad
# is recommended. ViGEmBus is not needed.
#
# Naming pitfall worth noting:
# Game title: "Another Crab's Treasure" (apostrophe + spaces)
# Steam folder: "Another Crab's Treasure" (apostrophe preserved
# because Steam allows it in installdir names)
# Unity data: "AnotherCrabsTreasure_Data" (no apostrophe, no
# spaces - Unity normalised it)
# Mod DLL: "UnityVR_AnotherCrabTreasure.dll" (note the
# SINGULAR "Crab" in the DLL name, not "Crabs" -
# Astienth dropped the 's' for the asset name)
# We probe several folder-name variants in case the Steam folder
# itself ended up apostrophe-less on some installs.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "AnotherCrabsTreasureVRMOD"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1887840"
$GAME_NAME = "Another Crab's Treasure"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; this game's mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1262749418981949483/1262749418981949483"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1262749418981949483/1271091506446598154"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Another Crab's Treasure VR Mod Installer" -ForegroundColor Cyan
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

function Find-AnotherCrabsTreasureGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Probe several folder-name variants. The Steam installdir
 # most likely keeps the apostrophe ("Another Crab's Treasure")
 # but some setups end up with the apostrophe-stripped form.
 # The Unity data folder inside is always
 # "AnotherCrabsTreasure_Data" (no apostrophe, no spaces).
 foreach ($folder in @(
 "Another Crab's Treasure",
 "Another Crabs Treasure",
 "AnotherCrabsTreasure"
 )) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\AnotherCrabsTreasure_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Another Crab's Treasure VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download the Another Crab's Treasure VR ZIP from the mod post" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Heads-up about the depth-only nature of the mod.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " Another Crab's Treasure VR is a DEPTH-ONLY mod - it" -ForegroundColor White
Write-Host " adds stereoscopic 3D to the game but no motion controls." -ForegroundColor White
Write-Host " Controls remain GAMEPAD or KEYBOARD+MOUSE. A gamepad is" -ForegroundColor White
Write-Host " recommended in VR for comfort. ViGEmBus is not needed." -ForegroundColor White
Write-Host ""
Write-Host " This is a Souls-like - expect challenging combat with" -ForegroundColor White
Write-Host " precise dodge timing. If your VR rig has noticeable" -ForegroundColor White
Write-Host " motion-to-photon latency, that may add to the difficulty." -ForegroundColor White
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
Write-Step 1 3 "Locate the downloaded ZIP"
Write-Host " Once the Another Crab's Treasure VR mod ZIP is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Another Crab's Treasure install
# -------------------------------------------------------
Write-Step 2 3 "Locating Another Crab's Treasure"

$gamePath = Find-AnotherCrabsTreasureGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1887840" -SteamFolderNames @("Another Crab's Treasure") }
if ($gamePath) {
 Write-OK "Found Another Crab's Treasure at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Another Crab's Treasure in any Steam library."
 Write-Host " Looking for a folder containing 'AnotherCrabsTreasure_Data'." -ForegroundColor Gray
 Write-Host " Please paste the path to your Another Crab's Treasure folder." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Another Crab's Treasure folder").Trim().Trim('"')
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
Write-Step 3 3 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "AnotherCrabsTreasureVR_$([System.IO.Path]::GetRandomFileName())"
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

# Sanity check - DLL is named UnityVR_AnotherCrabTreasure.dll
# (singular "Crab" in the DLL despite the game title using
# "Crab's").
$bepinexDir = Join-Path $gamePath "BepInEx"
$modDll = Join-Path $gamePath "BepInEx\plugins\UnityVR_AnotherCrabTreasure.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but UnityVR_AnotherCrabTreasure.dll is missing."
} else {
 Write-OK "BepInEx + UnityVR_AnotherCrabTreasure.dll present."
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
Write-Host " Launch Another Crab's Treasure normally via Steam, the" -ForegroundColor White
Write-Host " desktop shortcut, or the 'Start in VR' button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Use a GAMEPAD (recommended for VR) or KEYBOARD+MOUSE." -ForegroundColor Yellow
Write-Host " Game controls are unchanged - this is a depth-only mod." -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host ""
Write-Host " Snail your way home, Kril. The shell is calling." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

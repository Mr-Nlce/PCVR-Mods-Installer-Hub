# -------------------------------------------------------
# Skate Story VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Skate Story install folder
# 5. Extract mod files in place
#
# No VR controllers - gamepad only - so no ViGEmBus step.
# Note: this mod uses its own Doorstop-based loader (NOT
# BepInEx) so the mod DLL ends up in <gameRoot>\VRMod\
# rather than BepInEx\plugins\.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "SkateStory_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1263240"
$GAME_NAME = "Skate Story"
$GAME_EXE = "SkateStory.exe"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1454427736327065655/1469461911765516299"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1454427736327065655/1454427809203359774"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Skate Story VR Mod Installer" -ForegroundColor Cyan
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

function Get-GogRoots {
 $roots = @()
 foreach ($reg in @(
 "HKLM:\SOFTWARE\WOW6432Node\GOG.com\GalaxyClient\paths",
 "HKLM:\SOFTWARE\GOG.com\GalaxyClient\paths"
 )) {
 try {
 $p = (Get-ItemProperty -Path $reg -EA Stop).client
 if ($p) {
 $g = Join-Path $p "Games"
 if (Test-Path $g) { $roots += $g }
 }
 } catch {}
 }
 foreach ($root in @(
 "C:\GOG Games",
 "C:\Program Files (x86)\GOG Galaxy\Games",
 "C:\Program Files (x86)\GalaxyClient\Games",
 "${env:ProgramFiles}\GOG Galaxy\Games",
 "${env:ProgramFiles(x86)}\GOG Galaxy\Games",
 "D:\GOG Games",
 "E:\GOG Games"
 )) {
 if ($root -and (Test-Path $root) -and ($roots -notcontains $root)) {
 $roots += $root
 }
 }
 return $roots
}

function Find-SkateStoryGamePath {
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # The Steam installdir is "Skate Story" (with space) per
 # SteamDB. The Unity data folder is SkateStory_Data
 # (without space) - that's how Unity built it. Try the
 # real Steam name first, then the no-space variant in
 # case some users have the demo or a renamed install.
 foreach ($folder in @("Skate Story", "SkateStory")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\SkateStory_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 }
 # Fall back to GOG: this game has an official GOG release.
 foreach ($root in (Get-GogRoots)) {
 foreach ($folder in @("Skate Story", "SkateStory")) {
 $candidate = Join-Path $root $folder
 if (Test-Path -LiteralPath "$candidate\SkateStory_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Skate Story VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download SkateStory_VR.zip from the mod channel" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warning - this mod is OpenVR ONLY.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod supports OpenVR ONLY (not OpenXR). You'll" -ForegroundColor White
Write-Host " need SteamVR installed and running. If you have an" -ForegroundColor White
Write-Host " Oculus/Meta-only setup, install SteamVR first." -ForegroundColor White
Write-Host ""
Write-Host " Epilepsy warning: there are slight flashes on each" -ForegroundColor Yellow
Write-Host " scene load and in a few areas." -ForegroundColor Yellow
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
Write-Host " Once SkateStory_VR.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Skate Story install
# -------------------------------------------------------
Write-Step 2 4 "Locating Skate Story"

$gamePath = Find-SkateStoryGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1263240" -SteamFolderNames @("Skate Story") -GogNames @("Skate Story") }
if ($gamePath) {
 Write-OK "Found Skate Story at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Skate Story in any Steam library."
 Write-Host " Please paste the path to your Skate Story folder" -ForegroundColor White
 Write-Host " (the folder that contains SkateStory_Data/)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Skate Story folder").Trim().Trim('"')
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

# Extract to a temp folder first, then copy contents into place.
# This mod ships winhttp.dll + a VRMod\ folder + extra DLLs that
# overlay SkateStory_Data\Managed and SkateStory_Data\Plugins.
$tempExtract = Join-Path $env:TEMP "SkateStoryVR_$([System.IO.Path]::GetRandomFileName())"
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

# Some ZIPs have a single wrapper folder, others have the
# winhttp.dll directly at the root. Detect which.
$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 # Wrapper folder - the typical signal of "this is the root"
 # is the presence of winhttp.dll + a VRMod folder.
 $inner = $rootEntries[0].FullName
 if ((Test-Path -LiteralPath "$inner\winhttp.dll") -or (Test-Path -LiteralPath "$inner\VRMod")) {
 $srcRoot = $inner
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

# Sanity check: this mod's loader is winhttp.dll + VRMod\ folder,
# NOT BepInEx. Verify the right files landed.
$winhttp = Join-Path $gamePath "winhttp.dll"
$modDll = Join-Path $gamePath "VRMod\SkateStoryVR.dll"
if (-not (Test-Path $winhttp)) {
 Write-Warn "winhttp.dll not found in game folder after copy."
 Write-Warn "ZIP contents might have a layout we don't recognise."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "winhttp.dll is there but VRMod\SkateStoryVR.dll is missing."
 Write-Warn "Check the VRMod folder inside your game folder."
} else {
 Write-OK "winhttp.dll + VRMod\SkateStoryVR.dll present."
}

# -------------------------------------------------------
# STEP 4 (cont): finish
# -------------------------------------------------------
Write-Step 4 4 "Done"

# Record install path so the Hub can mark VR Ready
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Launch Skate Story normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the 'Start in VR' button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Quick controls reference:" -ForegroundColor White
Write-Host " - This mod has NO VR-controller support - gamepad only." -ForegroundColor Gray
Write-Host " - Recenter view: press both joysticks at the same time." -ForegroundColor Gray
Write-Host " (Try a few times if it doesn't catch right away.)" -ForegroundColor Gray
Write-Host " - Toggle 1st / 3rd person: double-tap Start / Options." -ForegroundColor Gray
Write-Host ""
Write-Host " IMPORTANT first-launch settings:" -ForegroundColor Yellow
Write-Host " - In-game options 'color bleeding' has been reported to" -ForegroundColor White
Write-Host " cause memory issues - turn it OFF if you hit problems." -ForegroundColor White
Write-Host " - This mod is OpenVR ONLY (needs SteamVR running)." -ForegroundColor White
Write-Host ""
Write-Host " Config file (created on first launch):" -ForegroundColor Gray
Write-Host " VRMod\VRMod.cfg" -ForegroundColor DarkGray
Write-Host " - writeLogsEnabled = False" -ForegroundColor Gray
Write-Host " - disableEffects = DepthOfField (comma-separated)" -ForegroundColor Gray
Write-Host " Available: VHSPro, AmbientOcclusion, AutoExposure," -ForegroundColor Gray
Write-Host " Bloom, ChromaticAberration, ColorGrading," -ForegroundColor Gray
Write-Host " ComputeBloom, DepthOfField, Grain," -ForegroundColor Gray
Write-Host " LensDistortion, MotionBlur," -ForegroundColor Gray
Write-Host " ScreenSpaceReflections, Vignette" -ForegroundColor Gray
Write-Host ""
Write-Host " Heads up: the mod uses decoupled-pitch, so some camera" -ForegroundColor Gray
Write-Host " angles may feel wrong. Look around in VR - that's part" -ForegroundColor Gray
Write-Host " of the experience." -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Heaven needs a half-pipe. You're the only one who can build it." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

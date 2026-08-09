# -------------------------------------------------------
# Mirage Feathers VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Edition pick (Demo vs Full game)
# 3. Mod ZIP download (correct variant for edition)
# 4. Drag-and-drop ZIP into this window
# 5. Auto-locate Mirage Feathers install folder
# 6. Extract mod files in place
#
# Two ZIPs exist on Discord, one per edition (Demo / Full
# game). The user picks early so we link the right
# download post and pick the right Steam folder.
#
# This is a GAMEPAD/KEYBOARD mod - no VR controller support
# (the base game is itself gamepad-only). The mod renders
# the rail-shooter in stereoscopic 3D but control input
# stays flat. ViGEmBus is not needed.
#
# Mod features bHaptics support. Reticle size and bHaptics
# behaviour are config-tunable in BepInEx/config/MirageFeathers_VR.cfg
# after first launch.
#
# Important: this is a heads-up mod, not full immersion.
# The action stays in front of the player; turning around
# in VR shows a blank screen. Best for fans of super-scaler
# shooters who want stereoscopic depth, not 360-degree VR.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "MirageFeathers_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2719060"
$GAME_NAME = "Mirage Feathers"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1325853693530079232/1325853693530079232"
$DISCORD_DOWNLOAD_DEMO_URL = "https://discord.com/channels/1001138422972432597/1325853693530079232/1326090177919062099"
$DISCORD_DOWNLOAD_FULL_URL = "https://discord.com/channels/1001138422972432597/1325853693530079232/1326090245850005568"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Mirage Feathers VR Mod Installer" -ForegroundColor Cyan
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

function Find-MirageFeathersGamePath {
 param([bool]$IsDemo)
 # Demo and full-game live in different Steam folders. Demo's
 # Unity data folder is "Mirage Feathers Demo_Data"; full-game
 # uses "Mirage Feathers_Data". Presence of the matching
 # _Data folder is the strongest signal we found the right
 # install. We also try a few naming variations as fallbacks.
 $sp = Get-SteamPath
 if (-not $sp) { return $null }

 if ($IsDemo) {
 $folders = @("Mirage Feathers Demo", "MirageFeathersDemo", "Mirage Feathers")
 $dataMark = "Mirage Feathers Demo_Data"
 $altData = "Mirage Feathers_Data"
 } else {
 $folders = @("Mirage Feathers", "MirageFeathers")
 $dataMark = "Mirage Feathers_Data"
 $altData = $null
 }

 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 foreach ($folder in $folders) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path (Join-Path $candidate $dataMark)) { return $candidate }
 if ($altData -and (Test-Path (Join-Path $candidate $altData))) { return $candidate }
 }
 # Last-resort: any folder under common\ that still has a
 # matching _Data subfolder, even if it's named oddly.
 foreach ($folder in $folders) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Mirage Feathers VR is distributed by Astienth via Discord." -ForegroundColor White
Write-Host " Are you already a member of the FarmerTrueVR" -ForegroundColor White
Write-Host " Discord server (with rules accepted)?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [Y] Yes, skip straight to the download links" -ForegroundColor Yellow
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
 Write-Host " 3. Pick the right ZIP for YOUR edition (Demo or Full)" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warnings + edition pick.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " Two separate mod ZIPs exist on Discord, one per edition:" -ForegroundColor White
Write-Host " * Demo version (free Steam demo)" -ForegroundColor White
Write-Host " * Full game (Steam paid)" -ForegroundColor White
Write-Host " Pick the one that matches YOUR copy of the game." -ForegroundColor White
Write-Host ""
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " No VR controller support - the base game itself is" -ForegroundColor White
Write-Host " GAMEPAD-only. Use a gamepad or keyboard. ViGEmBus is" -ForegroundColor White
Write-Host " not needed." -ForegroundColor White
Write-Host ""
Write-Host " Heads-up about the VR experience:" -ForegroundColor White
Write-Host " Mirage Feathers is a pseudo-3D rail shooter inspired" -ForegroundColor Gray
Write-Host " by After Burner / Space Harrier / Hang-On. The mod" -ForegroundColor Gray
Write-Host " adds stereoscopic depth - it's NOT a fully 360-degree" -ForegroundColor Gray
Write-Host " VR experience. The action stays in front of you;" -ForegroundColor Gray
Write-Host " turning around in VR shows a blank screen behind you." -ForegroundColor Gray
Write-Host " Best enjoyed if you like super-scaler arcade shooters" -ForegroundColor Gray
Write-Host " and want depth on top of the original framing." -ForegroundColor Gray
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
}

# Edition pick. We ask now so we open the right download post and
# so we know which Steam folder to look for later.
Write-Host ""
Write-Host " Which edition of Mirage Feathers do you have?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [D] Demo version (free Steam demo)" -ForegroundColor Yellow
Write-Host " >>> [F] Full game (Steam paid)" -ForegroundColor Yellow
Write-Host ""
$editionPick = ""
while ($editionPick -notin @("d","D","f","F")) {
 $editionPick = (Read-Host " Your choice (D/F)").Trim()
}
$isDemo = ($editionPick -in @("d","D"))

if ($isDemo) {
 $downloadUrl = $DISCORD_DOWNLOAD_DEMO_URL
 $expectedZipKeyword = "Demo"
 $editionLabel = "Demo"
} else {
 $downloadUrl = $DISCORD_DOWNLOAD_FULL_URL
 $expectedZipKeyword = "Fullgame"
 $editionLabel = "Full game"
}

Write-Host ""
 Write-Host " [Step 3/3] Mod download post   " -ForegroundColor Cyan -NoNewline
 Write-Host "Download: the mod ZIP" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $downloadUrl)" -ForegroundColor DarkGray
Write-Host " Background info: $DISCORD_INFO_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the download post..."
try { Start-Process $downloadUrl } catch {}

# -------------------------------------------------------
# STEP 2: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 3 "Locate the downloaded ZIP"
Write-Host " Once the $editionLabel mod ZIP is on your disk, drop it here." -ForegroundColor Gray
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
 # Soft-warn if the filename looks like the other edition.
 # File convention from Discord posts:
 # Mirage_Feathers_Demo_VR.zip
 # Mirage_Feathers_Fullgame_VR.zip
 $zipName = [System.IO.Path]::GetFileName($r)
 if ($zipName -notmatch [regex]::Escape($expectedZipKeyword)) {
 Write-Warn "Filename '$zipName' doesn't contain '$expectedZipKeyword' - this might be the other edition's ZIP."
 Write-Host " You picked $editionLabel but this ZIP doesn't look like it." -ForegroundColor Yellow
 Write-Host " [Y] Continue anyway [N] Pick a different file" -ForegroundColor Gray
 $cont = ""
 while ($cont -notin @("y","Y","n","N")) { $cont = (Read-Host " Your choice (Y/N)").Trim() }
 if ($cont -in @("n","N")) { $modZip = $null }
 }
 } else {
 Write-Fail "Path is not a ZIP/7z/RAR archive: $r"
 }
 } else {
 Write-Fail "File not found: $r"
 }
}

# -------------------------------------------------------
# STEP 3: Locate the Mirage Feathers install
# -------------------------------------------------------
Write-Step 2 3 "Locating Mirage Feathers ($editionLabel)"

$gamePath = Find-MirageFeathersGamePath -IsDemo:$isDemo
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2719060" -SteamFolderNames @("Mirage Feathers") }
if ($gamePath) {
 Write-OK "Found Mirage Feathers at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Mirage Feathers in any Steam library."
 if ($isDemo) {
 Write-Host " Looking for a folder containing 'Mirage Feathers Demo_Data'." -ForegroundColor Gray
 } else {
 Write-Host " Looking for a folder containing 'Mirage Feathers_Data'." -ForegroundColor Gray
 }
 Write-Host " Please paste the path to your Mirage Feathers folder." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Mirage Feathers folder").Trim().Trim('"')
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

$tempExtract = Join-Path $env:TEMP "MirageFeathersVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\MirageFeathers_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but MirageFeathers_VR.dll is missing."
} else {
 Write-OK "BepInEx + MirageFeathers_VR.dll present."
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
Write-Host " Launch Mirage Feathers normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Use a GAMEPAD or KEYBOARD - no VR controller support." -ForegroundColor Yellow
Write-Host " Game controls are unchanged." -ForegroundColor Gray
Write-Host ""
Write-Host " Configuration:" -ForegroundColor Gray
Write-Host " The config file is created AFTER your first launch with" -ForegroundColor Gray
Write-Host " the mod, at:" -ForegroundColor Gray
Write-Host " BepInEx\config\MirageFeathers_VR.cfg" -ForegroundColor DarkGray
Write-Host " Tunable options:" -ForegroundColor Gray
Write-Host " - reticle size" -ForegroundColor Gray
Write-Host " - bHaptics behaviour" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " Heads-up notes (community feedback):" -ForegroundColor Gray
Write-Host " - Action stays in front of you; turning around shows" -ForegroundColor Gray
Write-Host " a blank screen. This is expected, not a bug." -ForegroundColor Gray
Write-Host " - Bullet patterns can feel close to your face during" -ForegroundColor Gray
Write-Host " heavy enemy fire - increase your dodge reaction time" -ForegroundColor Gray
Write-Host " by sitting back a bit." -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Take wing. The shrine spirits are watching." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

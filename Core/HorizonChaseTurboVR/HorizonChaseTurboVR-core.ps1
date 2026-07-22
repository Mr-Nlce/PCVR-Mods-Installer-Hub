# -------------------------------------------------------
# Horizon Chase Turbo VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Store version selection (Steam x86 vs Epic Store x64)
# 3. Mod ZIP download (correct variant for store)
# 4. Drag-and-drop ZIP into this window
# 5. Auto-locate Horizon Chase Turbo install folder
# 6. Extract mod files in place
#
# Two ZIPs exist on Discord, one per store. The user picks
# early so we link the right download post and validate
# the chosen ZIP at extraction time.
#
# This is a GAMEPAD/KEYBOARD mod - no VR controller support.
# Uses a Doorstop loader (not the usual winhttp.dll proxy),
# so deactivation works differently from the other Astienth
# mods - delete or rename the BepInEx folder + doorstop_config.ini
# rather than renaming winhttp.dll.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "HorizonChaseTurboVR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "389140"
$GAME_NAME = "Horizon Chase Turbo"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1362072336827814020/1362072336827814020"
$DISCORD_DOWNLOAD_STEAM_URL = "https://discord.com/channels/1001138422972432597/1362072336827814020/1362073388008472717"
$DISCORD_DOWNLOAD_EPIC_URL = "https://discord.com/channels/1001138422972432597/1362072336827814020/1362073443733864508"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Horizon Chase Turbo VR Mod Installer" -ForegroundColor Cyan
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

function Find-HorizonChaseTurboGamePath_Steam {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Horizon Chase Turbo" (with spaces)
 # but the Unity data folder is "HorizonChase_Data" (no
 # "Turbo", no space). Presence of HorizonChase_Data is
 # the strongest signal we found the right install.
 foreach ($folder in @("Horizon Chase Turbo", "HorizonChaseTurbo", "Horizon Chase Turbo Demo")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\HorizonChase_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

function Find-HorizonChaseTurboGamePath_Epic {
 # Epic Games doesn't have a registry-based library scanner as
 # convenient as Steam's. Try the typical default install root
 # plus the LauncherInstalled.dat manifest if present.
 $candidates = @()
 foreach ($base in @(
 "${env:ProgramFiles}\Epic Games",
 "${env:ProgramFiles(x86)}\Epic Games",
 "C:\Program Files\Epic Games",
 "C:\Program Files (x86)\Epic Games"
 )) {
 if ($base -and (Test-Path $base)) {
 foreach ($folder in @("HorizonChaseTurbo", "Horizon Chase Turbo", "HorizonChase")) {
 $candidates += (Join-Path $base $folder)
 }
 }
 }
 # Parse the Epic LauncherInstalled.dat for any HorizonChase install
 $manifest = "$env:ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat"
 if (Test-Path $manifest) {
 try {
 $data = Get-Content $manifest -Raw | ConvertFrom-Json
 foreach ($entry in $data.InstallationList) {
 if ($entry.AppName -match "HorizonChase" -or $entry.InstallLocation -match "HorizonChase") {
 $candidates += $entry.InstallLocation
 }
 }
 } catch {}
 }
 foreach ($c in $candidates) {
 if (-not $c) { continue }
 if (Test-Path -LiteralPath "$c\HorizonChase_Data") { return $c }
 }
 foreach ($c in $candidates) {
 if (-not $c) { continue }
 if (Test-Path $c) { return $c }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding + store selection
# -------------------------------------------------------
Write-Header

Write-Host " Horizon Chase Turbo VR is distributed by Astienth via" -ForegroundColor White
Write-Host " Discord. Are you already a member of the FarmerTrueVR" -ForegroundColor White
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
 Write-Host " 3. Pick the right ZIP for YOUR store version" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Important pre-install warnings + store-version disambiguation.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " Two separate mod ZIPs exist on Discord, one per store:" -ForegroundColor White
Write-Host " * Steam version (x86)" -ForegroundColor White
Write-Host " * Epic Store version (x64)" -ForegroundColor White
Write-Host " Pick the one that matches YOUR copy of the game." -ForegroundColor White
Write-Host ""
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " No VR controller support - use a GAMEPAD or KEYBOARD." -ForegroundColor White
Write-Host " The mod renders the racing game in VR with stereoscopic" -ForegroundColor White
Write-Host " 3D, but control input stays flat. ViGEmBus is not needed." -ForegroundColor White
Write-Host ""
Write-Host " Heads-up: there are some menu UI glitches but the game" -ForegroundColor White
Write-Host " is fully playable." -ForegroundColor White
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

# Store-version pick. We ask now so we open the right download post
# and so we know which install path heuristic to use later.
Write-Host ""
Write-Host " Which store did you buy Horizon Chase Turbo on?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [S] Steam version (x86 mod ZIP)" -ForegroundColor Yellow
Write-Host " >>> [E] Epic Store version (x64 mod ZIP)" -ForegroundColor Yellow
Write-Host ""
$storePick = ""
while ($storePick -notin @("s","S","e","E")) {
 $storePick = (Read-Host " Your choice (S/E)").Trim()
}
$isEpic = ($storePick -in @("e","E"))

if ($isEpic) {
 $downloadUrl = $DISCORD_DOWNLOAD_EPIC_URL
 $expectedZipKeyword = "x64"
 $storeLabel = "Epic Store (x64)"
} else {
 $downloadUrl = $DISCORD_DOWNLOAD_STEAM_URL
 $expectedZipKeyword = "x86"
 $storeLabel = "Steam (x86)"
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
Write-Host " Once the $storeLabel mod ZIP is on your disk, drop it here." -ForegroundColor Gray
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
 # Soft-warn if the filename obviously belongs to the
 # other store version. The filename convention used in
 # Discord posts: HorizonChaseTurbo_VR_x86_Steam_.zip /
 # HorizonChaseTurbo_VR_x64_EpicStore_.zip.
 $zipName = [System.IO.Path]::GetFileName($r)
 if ($zipName -notmatch [regex]::Escape($expectedZipKeyword)) {
 Write-Warn "Filename '$zipName' doesn't contain '$expectedZipKeyword' - this might be the other store's variant."
 Write-Host " You picked $storeLabel but this ZIP doesn't look like it." -ForegroundColor Yellow
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
# STEP 3: Locate the Horizon Chase Turbo install
# -------------------------------------------------------
Write-Step 2 3 "Locating Horizon Chase Turbo"

if ($isEpic) {
 $gamePath = Find-HorizonChaseTurboGamePath_Epic
 if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "389140" -SteamFolderNames @("Horizon Chase Turbo") }
} else {
 $gamePath = Find-HorizonChaseTurboGamePath_Steam
}

if ($gamePath) {
 Write-OK "Found Horizon Chase Turbo at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Horizon Chase Turbo."
 if ($isEpic) {
 Write-Host " Epic Games typically installs to:" -ForegroundColor Gray
 Write-Host " C:\Program Files\Epic Games\HorizonChaseTurbo" -ForegroundColor DarkGray
 } else {
 Write-Host " Steam typically installs to:" -ForegroundColor Gray
 Write-Host " <SteamLib>\steamapps\common\Horizon Chase Turbo" -ForegroundColor DarkGray
 }
 Write-Host " Please paste the path to your game folder" -ForegroundColor White
 Write-Host " (the folder that contains 'HorizonChase_Data')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Game folder").Trim().Trim('"')
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

$tempExtract = Join-Path $env:TEMP "HCTVR_$([System.IO.Path]::GetRandomFileName())"
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

# Sanity check - this mod uses Doorstop, so we look for both BepInEx
# and doorstop_config.ini in the game root (different from the
# winhttp.dll-based Astienth mods).
$bepinexDir = Join-Path $gamePath "BepInEx"
$modDll = Join-Path $gamePath "BepInEx\plugins\HorizonChaseTurboVR.dll"
$doorstopFile = Join-Path $gamePath "doorstop_config.ini"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but HorizonChaseTurboVR.dll is missing."
} elseif (-not (Test-Path $doorstopFile)) {
 Write-Warn "BepInEx + DLL present, but doorstop_config.ini is missing - the loader won't kick in."
} else {
 Write-OK "BepInEx + HorizonChaseTurboVR.dll + doorstop_config.ini present."
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
Write-Host " Launch Horizon Chase Turbo normally via $storeLabel," -ForegroundColor White
Write-Host " the desktop shortcut, or the 'Start in VR' button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Use a GAMEPAD or KEYBOARD - no VR controller support." -ForegroundColor Yellow
Write-Host " Game controls are unchanged." -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " Known issues:" -ForegroundColor Gray
Write-Host " - Some menu UI glitches. The game itself stays playable." -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later:" -ForegroundColor Gray
Write-Host " This mod uses Doorstop (NOT the usual winhttp.dll" -ForegroundColor Gray
Write-Host " proxy). To disable, rename or delete:" -ForegroundColor Gray
Write-Host " $gamePath\doorstop_config.ini" -ForegroundColor DarkGray
Write-Host " The mod stops loading. The BepInEx folder can stay" -ForegroundColor Gray
Write-Host " on disk; renaming the doorstop config is enough." -ForegroundColor Gray
Write-Host ""
Write-Host " Synthwave on the speakers. Horizon on the dash." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

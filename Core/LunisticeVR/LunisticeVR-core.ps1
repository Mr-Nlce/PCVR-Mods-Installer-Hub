# -------------------------------------------------------
# Lunistice VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Lunistice install folder
# 5. Extract mod files in place
#
# No VR controllers - gamepad or keyboard - so no ViGEmBus
# setup step like Slyders/Moto Rush.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "Lunistice_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1701800"
$GAME_NAME = "Lunistice"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; different mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1465598630382669916/1466848780409245922"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1465598630382669916/1465598630382669916"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Lunistice VR Mod Installer" -ForegroundColor Cyan
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

function Find-LunisticeGamePath {
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # The mod requires a Lunistice_Data folder next to the
 # game exe. Check for that as the strongest signal that
 # we found the right folder.
 $candidate = Join-Path $lib "steamapps\common\Lunistice"
 if (Test-Path -LiteralPath "$candidate\Lunistice_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 # Fall back to GOG: this game has an official GOG release.
 foreach ($root in (Get-GogRoots)) {
 $candidate = Join-Path $root "Lunistice"
 if (Test-Path -LiteralPath "$candidate\Lunistice_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Lunistice VR is distributed by Astienth via Discord." -ForegroundColor White
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
 Write-Host " 3. Download Lunistice_VR.zip from the mod channel" -ForegroundColor Gray
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
 Write-Host " Note: this mod is NOT compatible with the demo - get the" -ForegroundColor Yellow
 Write-Host " full version of Lunistice on Steam first." -ForegroundColor Yellow
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
Write-Host " Once Lunistice_VR.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the Lunistice install
# -------------------------------------------------------
Write-Step 2 4 "Locating Lunistice"

$gamePath = Find-LunisticeGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1701800" -SteamFolderNames @("Lunistice") -GogNames @("Lunistice") }
if ($gamePath) {
 Write-OK "Found Lunistice at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Lunistice in any Steam library."
 Write-Host " Note: this mod does not work with the demo." -ForegroundColor Yellow
 Write-Host " Please paste the path to your Lunistice folder" -ForegroundColor White
 Write-Host " (the folder that contains Lunistice_Data/)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Lunistice folder").Trim().Trim('"')
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

$tempExtract = Join-Path $env:TEMP "LunisticeVR_$([System.IO.Path]::GetRandomFileName())"
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

# Some ZIPs have a single wrapper folder, others have BepInEx/
# directly at the root. Detect which.
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
$modDll = Join-Path $gamePath "BepInEx\plugins\Lunistice_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
 Write-Warn "ZIP contents might have a layout we don't recognise."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but Lunistice_VR.dll is missing."
 Write-Warn "Check BepInEx\plugins\ inside your game folder."
} else {
 Write-OK "BepInEx + Lunistice_VR.dll present."
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
Write-Host " Launch Lunistice normally via Steam, or the 'Start in VR'" -ForegroundColor White
Write-Host " button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Quick controls reference:" -ForegroundColor White
Write-Host " - This mod has NO VR-controller support." -ForegroundColor Gray
Write-Host " - Play with a gamepad or keyboard." -ForegroundColor Gray
Write-Host " - Press F1 to recenter the view at any time." -ForegroundColor Gray
Write-Host ""
Write-Host " Config file: BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg" -ForegroundColor Gray
Write-Host " Two settings worth tweaking if scale feels off:" -ForegroundColor Gray
Write-Host " VRCamScale = 1,1,1 (lower than 1 = world bigger;" -ForegroundColor Gray
Write-Host " higher than 1 = world smaller)" -ForegroundColor Gray
Write-Host " VRUI scale = 2 (UI scaling)" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Hop the moon. Float the stars. Land like a feather." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

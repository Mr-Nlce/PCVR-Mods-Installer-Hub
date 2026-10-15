# -------------------------------------------------------
# GTFO VR Mod Installer
# by DSprtn - mod distributed via flat2VRmods Discord
#
# Walks the user through:
# 1. flat2VRmods Discord onboarding (3 channel steps:
# join, toggle visibility, click warn icon for
# beta access, then grab the mod ZIP)
# 2. Drag-and-drop the GTFO_VR_Release ZIP into the
# installer window
# 3. Auto-locate GTFO Steam install
# 4. Download + extract BepInEx 6.0.0b670 IL2CPP-x64
# (the VR mod ZIP does NOT include BepInEx itself,
# it only contains the GTFO_VR plugin files)
# 5. Extract the user-supplied mod ZIP on top
# 6. Sanity check + done
#
# This mod uses BepInEx 6 (not 5), specifically build
# 6.0.0b670 for IL2CPP Unity x64. Newer or older
# BepInEx 6 builds may not be compatible.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "GTFO_VR"
$MOD_VERSION = "1.4.0 beta"
$MOD_AUTHOR = "DSprtn"

$GAME_APPID = "493520"
$GAME_NAME = "GTFO"
$GAME_EXE = "GTFO.exe"

$BEPINEX_URL = "https://builds.bepinex.dev/projects/bepinex_be/670/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.670%2B42a6727.zip"

# Discord URLs the installer hands the user, in the order they appear
# in the welcome flow. Same flat2VRmods server as other entries that
# reference it (server id 747967102895390741).
$DISCORD_INVITE_URL = "https://discord.gg/uAeQkYBM4n"
$DISCORD_JOIN_URL = "https://discord.com/channels/747967102895390741/978019455449858149"
$DISCORD_BETA_OPTIN_URL = "https://discord.com/channels/747967102895390741/832354057103343626/833777903308242944"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/747967102895390741/833777990486720512/1218902177574031361"
$REQUIRED_GTFO_VR_FILES = @(
 'GTFO.exe', 'GTFO_Data\globalgamemanagers', 'winhttp.dll', 'doorstop_config.ini',
 'BepInEx\core\BepInEx.Unity.IL2CPP.dll', 'BepInEx\plugins\GTFO_VR.dll',
 'BepInEx\plugins\SteamVR_Standalone_IL2CPP.dll',
 'GTFO_Data\Plugins\openvr_api.dll',
 'GTFO_Data\StreamingAssets\SteamVR_Standalone\actions.json'
)
$GTFO_CONTRACT = New-PCVRInstallerContract -Id 'gtfo-vr' -GameName 'GTFO VR' -Acquisition Discord `
 -DiscordInviteUrl $DISCORD_INVITE_URL -DiscordDownloadUrl $DISCORD_DOWNLOAD_URL `
 -AntivirusNotice -RequiredInstalledFileGroups $REQUIRED_GTFO_VR_FILES

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " GTFO VR Mod Installer" -ForegroundColor Cyan
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

function Find-GTFOGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = Join-Path $lib "steamapps\common\GTFO"
 # Presence of GTFO.exe is the strongest signal we found the
 # right install. Folder existence alone is not enough since
 # users sometimes have orphan folders from earlier installs.
 if (Test-Path (Join-Path $candidate $GAME_EXE)) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " GTFO VR is distributed by DSprtn via the flat2VRmods" -ForegroundColor White
Write-Host " Discord server. The current build (1.4.0) is a beta," -ForegroundColor White
Write-Host " only available to users who opt into beta access." -ForegroundColor White
Write-Host ""
Write-Host " Are you already a flat2VRmods member with beta access" -ForegroundColor White
Write-Host " enabled (GTFO beta channels visible)?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [Y] Yes, skip straight to the download link" -ForegroundColor Yellow
Write-Host " >>> [N] No, walk me through joining + beta opt-in" -ForegroundColor Yellow
Write-Host "     [S] Show a short walkthrough of what happens first" -ForegroundColor DarkGray
Write-Host ""
$alreadyMember = ""
while ($alreadyMember -notin @("y","Y","n","N")) {
 $alreadyMember = (Read-Host " Your choice (Y/N/S)").Trim()
 if ($alreadyMember -in @("s","S")) {
  Write-Host ""
  Write-Host " Short walkthrough - what the installer does WITH you:" -ForegroundColor White
  Write-Host "   1. Opens the flat2VRmods Discord invite   - you click Accept Invite" -ForegroundColor Gray
  Write-Host "   2. Opens the GTFO join channel            - you click Toggle Visibility" -ForegroundColor Gray
  Write-Host "   3. Opens the beta opt-in message          - you click the warning icon" -ForegroundColor Gray
  Write-Host "   4. Opens the mod download post            - you download the ZIP" -ForegroundColor Gray
  Write-Host "   5. You drag the ZIP into this window - the installer does the rest." -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""
Write-Host " HOW THIS WORKS: at each step press Enter - the installer opens the page for you." -ForegroundColor White
Write-Host " Do ONLY the highlighted action on that page, then come back here and press Enter for the next step." -ForegroundColor White
Write-Host ""

if (-not $skipJoin) {

 Write-Host " [Step 1/4] Discord server invite   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: Accept Invite" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_INVITE_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the invite in your browser..."
 try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open browser. Visit the URL above manually." }

 Write-Host ""
 Write-Host " [Step 2/4] GTFO join channel   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: Toggle Visibility" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_JOIN_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the join channel..."
 try { Start-Process $DISCORD_JOIN_URL } catch {}

 Write-Host ""
 Write-Host " [Step 3/4] Beta opt-in   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: the warning icon under the message" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_BETA_OPTIN_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the beta opt-in message..."
 try { Start-Process $DISCORD_BETA_OPTIN_URL } catch {}

 Write-Host ""
 Write-Host " [Step 4/4] Mod download post   " -ForegroundColor Cyan -NoNewline
 Write-Host "Download: GTFO_VR_Release_1_4_0.zip" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the download post..."
 try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}
} else {
 Write-Host " [Step 1/1] Mod download post   " -ForegroundColor Cyan -NoNewline
 Write-Host "Download: GTFO_VR_Release_1_4_0.zip" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the download post..."
 try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}
}

# -------------------------------------------------------
# STEP 2: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 5 "Locate the downloaded GTFO VR mod ZIP"
Write-Host " Once GTFO_VR_Release_1_4_0.zip is on your disk, drop it here." -ForegroundColor Gray
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
# STEP 3: Locate the GTFO install
# -------------------------------------------------------
Write-Step 2 5 "Locating GTFO"

$gamePath = Find-GTFOGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "493520" -SteamFolderNames @("GTFO") -ProbeExe "GTFO.exe" }
if ($gamePath) {
 Write-OK "Found GTFO at: $gamePath"
} else {
 Write-Warn "Could not auto-locate GTFO in any Steam library."
 Write-Host " Please paste the path to your GTFO folder" -ForegroundColor White
 Write-Host " (the folder that contains 'GTFO.exe')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " GTFO folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 if (Test-Path (Join-Path $r $GAME_EXE)) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Folder exists but $GAME_EXE not found inside: $r"
 }
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 4: Download + extract BepInEx 6.0.0b670 IL2CPP-x64
# -------------------------------------------------------
Write-Step 3 5 "Installing BepInEx 6.0.0b670 (IL2CPP x64)"
Write-Host " The VR mod requires BepInEx 6 IL2CPP specifically (NOT BepInEx 5)," -ForegroundColor Gray
Write-Host " bleeding-edge build 670. Downloading from builds.bepinex.dev..." -ForegroundColor Gray
Write-Host ""

$tempBep = Join-Path $env:TEMP "GTFOVR_bep_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempBep | Out-Null
$bepZip = Join-Path $tempBep "BepInEx.zip"

# Multi-source download. builds.bepinex.dev is the official upstream
# but specific build numbers can become unavailable if pruned. The
# BepInEx team's GitHub releases hold stable preview builds, and
# the Thunderstore community CDN re-hosts known-good IL2CPP packs.
$bepSources = @(
    $BEPINEX_URL,
    "https://builds.bepinex.dev/projects/bepinex_be/670/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.670%2B42a6727.zip"
)
$dlResult = Invoke-SafeDownload -Urls $bepSources -Destination $bepZip `
    -Label "BepInEx 6.0.0-be.670 (IL2CPP win-x64)" `
    -ManualUrl "https://builds.bepinex.dev/projects/bepinex_be" `
    -Instructions "GTFOVR needs BepInEx 6 IL2CPP bleeding-edge build 670 specifically (NOT BepInEx 5, and NOT a newer build - the mod is pinned to 670). Open the builds page in your browser, scroll to build 670, download 'BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.670' .zip, and place it at '$bepZip'. Then choose Retry." `
    -SkipMessage "BepInEx is required; setup cannot complete without it." -AllowSkip $false
if ([string]$dlResult -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$dlResult -eq "skip") {
    Write-Fail 'BepInEx is required. Nothing was marked complete.'
    Pause-User 'Press Enter to exit...'; exit 1
} elseif ([string]$dlResult -eq "retry") {
    if (-not (Test-Path $bepZip)) { Pause-User "Still no BepInEx zip at $bepZip. Press Enter to exit..."; exit 1 }
}

if (Test-Path -LiteralPath $bepZip -PathType Leaf) {
    Write-OK "BepInEx downloaded: $((Get-Item $bepZip).Length) bytes"
    $bepExtract = Join-Path $tempBep 'extracted'
    try {
        $bepResult = Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $bepExtract `
            -Label 'BepInEx 6 IL2CPP' -AllowSkip $false
        if ([string]$bepResult -notin @('ok','manual','retry')) { throw 'BepInEx extraction did not complete.' }
        foreach ($relative in @('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.Unity.IL2CPP.dll')) {
            if (-not (Test-Path -LiteralPath (Join-Path $bepExtract $relative) -PathType Leaf)) { throw "BepInEx is missing $relative." }
        }
        Write-OK 'BepInEx staged and checked before changing GTFO.'
    } catch {
        Write-Fail "BepInEx staging failed: $_"
        Pause-User 'Press Enter to exit without changing GTFO.'; exit 1
    }
} else {
    Write-Fail 'No usable BepInEx archive was found. Nothing was marked complete.'
    Pause-User 'Press Enter to exit...'; exit 1
}

# -------------------------------------------------------
# STEP 5: Extract the user-supplied mod ZIP on top
# -------------------------------------------------------
Write-Step 4 5 "Installing GTFO VR mod files"

$tempExtract = Join-Path $env:TEMP "GTFOVR_mod_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

try {
 Write-Host " Extracting mod archive..." -ForegroundColor Gray
 $modResult = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract `
  -Label 'GTFO VR mod archive' -AllowSkip $false
 if ([string]$modResult -notin @('ok','manual','retry')) { throw 'The GTFO VR mod archive was not extracted.' }
} catch {
 Write-Fail "Mod extract failed: $_"
 Pause-User 'Press Enter to exit without changing GTFO.'; exit 1
}

# The ZIP typically extracts as BepInEx/ + GTFO_Data/ + a couple of
# top-level docs (Changelog.txt, README.MD). Some user-rebundled
# variants may wrap everything in a single subfolder; detect that
# and unwrap one level if needed.
$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 $inner = Get-ChildItem -Path $rootEntries[0].FullName
 if ($inner | Where-Object { $_.Name -in @("BepInEx", "GTFO_Data") }) {
 $srcRoot = $rootEntries[0].FullName
 }
}

Write-Step 5 5 'Verifying and installing both packages'
$stage = Join-Path $tempBep 'merged'
$requiredPayloadFiles = @($REQUIRED_GTFO_VR_FILES | Where-Object { $_ -notin @('GTFO.exe','GTFO_Data\globalgamemanagers') })
try {
 [void](Merge-DirectoryTreeVerified -Source $bepExtract -Destination $stage -Label 'BepInEx stage')
 [void](Merge-DirectoryTreeVerified -Source $srcRoot -Destination $stage -Label 'GTFO VR mod stage')
 $sourceHashes = Get-PCVRDropInSourceHashes -SourceRoot $stage -RequiredFiles $requiredPayloadFiles
 [void](Invoke-PCVRDropInInstall -SourceRoot $stage -GameRoot $gamePath -SourceHashes $sourceHashes `
  -KeepExistingFiles @('BepInEx\config\BepInEx.cfg','BepInEx\config\com.Spartan.GTFO_VR_Plugin.cfg') `
  -Contract $GTFO_CONTRACT -Version '1.4.0' `
  -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
 Write-OK 'BepInEx, GTFO VR, bindings and version receipt verified.'
} catch {
 Write-Fail "GTFO VR setup did not complete: $($_.Exception.Message)"
 Write-Host '  Game files were restored if copying had begun; use recovery to retry.' -ForegroundColor Yellow
 Pause-User 'Press Enter to exit without marking this attempt complete.'; exit 1
}
try { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}
try { Remove-Item -LiteralPath $tempBep -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Launch GTFO normally via Steam, the desktop shortcut," -ForegroundColor White
Write-Host " or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " First-run reminders:" -ForegroundColor White
Write-Host " - SteamVR must be running before you launch GTFO." -ForegroundColor Gray
Write-Host " - Endless loading void on launch? Disable SteamVR Home in" -ForegroundColor Gray
Write-Host "   SteamVR Settings - it frees the resources GTFO needs." -ForegroundColor Gray
Write-Host " - The main menu shows on your desktop monitor. The" -ForegroundColor Gray
Write-Host " game switches to VR once you start a rundown." -ForegroundColor Gray
Write-Host " - Disable 'Present non-VR Applications on Theater" -ForegroundColor Gray
Write-Host " screen upon Launch' in SteamVR settings." -ForegroundColor Gray
Write-Host " - Lower texture / fog / render resolution to avoid" -ForegroundColor Gray
Write-Host " VRAM crashes on bigger maps." -ForegroundColor Gray
Write-Host ""
Write-Host " Configuration:" -ForegroundColor White
Write-Host " - In-game: Settings -> VR Settings" -ForegroundColor Gray
Write-Host " - Config file: BepInEx\config\com.Spartan.GTFO_VR_Plugin.cfg" -ForegroundColor Gray
Write-Host " - SteamVR bindings: SteamVR -> Settings -> Controllers ->" -ForegroundColor Gray
Write-Host " Manage Controller Bindings -> GTFO VR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " The Warden has new orders. Get to the rendezvous." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

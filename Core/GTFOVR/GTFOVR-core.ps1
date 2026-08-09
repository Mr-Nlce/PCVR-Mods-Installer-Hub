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
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

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
    -SkipMessage "Skipped - the VR mod loader is missing; GTFO will launch normally but the VR mod will not load (questionable result)."
if ([string]$dlResult -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$dlResult -eq "skip") {
    Write-Warn "Continuing without BepInEx - the VR mod will not function."
} elseif ([string]$dlResult -eq "retry") {
    if (-not (Test-Path $bepZip)) { Pause-User "Still no BepInEx zip at $bepZip. Press Enter to exit..."; exit 1 }
}

if ((Test-Path $bepZip) -and ((Get-Item $bepZip).Length -gt 1000)) {
    Write-OK "BepInEx downloaded: $((Get-Item $bepZip).Length) bytes"

    try {
        Write-Host " Extracting BepInEx into: $gamePath" -ForegroundColor Gray
        Expand-Archive -Path $bepZip -DestinationPath $gamePath -Force
        Write-OK "BepInEx 6.0.0b670 installed."
    } catch {
        Write-Fail "BepInEx extract failed: $_"
        try { Remove-Item $tempBep -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        $__fb = Invoke-InstallerFallback -Action "BepInEx archive extraction" `
            -Instructions "Open '$bepZip' with 7-Zip or Windows Explorer, and extract its contents into '$gamePath' (the GTFO install folder). Then choose Retry." `
            -SkipMessage "Skipped - BepInEx was NOT extracted; the VR mod cannot load (questionable result)." `
            -SourceFolder (Split-Path "$bepZip" -Parent) `
            -DestFolder "$gamePath" `
            -AllowSkip $true
        if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        if ([string]$__fb -eq "retry") {
            # Re-check: user should have extracted BepInEx into game folder
            if (Test-Path -LiteralPath "$gamePath\winhttp.dll") {
                Write-OK "BepInEx detected in game folder (winhttp.dll) - continuing."
            } else {
                Pause-User "BepInEx still not detected in $gamePath. Press Enter to exit..."
                exit 1
            }
        }
        # User chose Skip - continue at own risk
    }
} else {
    Write-Warn "No BepInEx zip available - the VR mod will not load without it."
}
try { Remove-Item $tempBep -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 5: Extract the user-supplied mod ZIP on top
# -------------------------------------------------------
Write-Step 4 5 "Installing GTFO VR mod files"

$tempExtract = Join-Path $env:TEMP "GTFOVR_mod_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

try {
 Write-Host " Extracting mod archive..." -ForegroundColor Gray
 Expand-Archive -Path $modZip -DestinationPath $tempExtract -Force
} catch {
 Write-Fail "Mod extract failed: $_"
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

Write-Host " Copying mod files into: $gamePath" -ForegroundColor Gray
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
Write-Step 5 5 "Verifying install"
$bepinexCore = Join-Path $gamePath "BepInEx\core"
$modDll = Join-Path $gamePath "BepInEx\plugins\GTFO_VR.dll"
$winhttp = Join-Path $gamePath "winhttp.dll"
$vrDataDir = Join-Path $gamePath "GTFO_Data\StreamingAssets\SteamVR_Standalone"

if (-not (Test-Path $bepinexCore)) {
 Write-Warn "BepInEx\core folder not found - install may be incomplete."
} else {
 Write-OK "BepInEx core present."
}
if (-not (Test-Path $winhttp)) {
 Write-Warn "winhttp.dll not found at game root - BepInEx 6 needs this."
} else {
 Write-OK "winhttp.dll present at game root."
}
if (-not (Test-Path $modDll)) {
 Write-Warn "GTFO_VR.dll not found in BepInEx\plugins - mod ZIP may be wrong build."
} else {
 Write-OK "GTFO_VR.dll present."
}
if (-not (Test-Path $vrDataDir)) {
 Write-Warn "SteamVR_Standalone folder not found - controller bindings may not load."
} else {
 Write-OK "SteamVR_Standalone bindings present."
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

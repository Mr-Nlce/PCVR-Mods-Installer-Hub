# ============================================================
# Garry's Mod - VRMod x64 Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Garry's Mod VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_APPID = "4000"
$GAME_NAME = "GarrysMod"
$GAME_EXE = "gmod.exe"

# VRMod x64 modules (native DLLs for the x64 branch of GMod)
$MODULES_API = "https://api.github.com/repos/Abyss-c0re/vrmod-module-master/releases/latest"
$MODULES_FALLBACK_URL = "https://github.com/Abyss-c0re/vrmod-module-master/releases/download/170625/modules.zip"
$MODULES_PAGE         = "https://github.com/Abyss-c0re/vrmod-module-master/releases"

# Workshop addon (the Lua half of the mod)
$WORKSHOP_ID = "3442302711"
$WORKSHOP_URL = "steam://url/CommunityFilePage/$WORKSHOP_ID"
$WORKSHOP_WEBURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=$WORKSHOP_ID"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host " Garry's Mod - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " VRMod x64: Ultimate Edition by Abyss-c0re / Doom Slayer" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host ""
}

function Write-Step {
 param($num, $total, $text)
 Write-Host ""
 Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
 Write-Host ""
}

function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraries {
 param($steamPath)
 $libraries = @($steamPath)
 $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdfPath) {
 $content = Get-Content $vdfPath -Raw
 $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
 foreach ($m in $found) {
 $lib = $m.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $lib) { $libraries += $lib }
 }
 }
 return $libraries
}

function Find-GamePath {
 param($libraries)
 foreach ($lib in $libraries) {
 $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Locate Garry's Mod
# -------------------------------------------------------
Write-Header
Write-Host " VRMod x64 Ultimate Edition (Abyss-c0re, fork of Catse's VRMod) adds" -ForegroundColor White
Write-Host " motion-controlled VR to Garry's Mod." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 7 "Locating Garry's Mod"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Garry's Mod"
 }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
if (-not $steamPath) {
 Write-Warn "Could not find Steam installation in registry."
 Write-Host " Please enter your Steam installation path manually:" -ForegroundColor White
 while (-not $steamPath) {
 $rawInput = (Read-Host " Steam path").Trim().Trim('"')
 if (Test-Path $rawInput) { $steamPath = $rawInput; Write-OK "Steam path set: $steamPath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "4000" -SteamFolderNames @("GarrysMod") }

if (-not $gamePath) {
 Write-Warn "Garry's Mod not found in Steam libraries automatically."
 Write-Host " Please enter the GarrysMod folder path manually:" -ForegroundColor White
 while (-not $gamePath) {
 $rawInput = (Read-Host " GarrysMod path").Trim().Trim('"')
 if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "GarrysMod path set: $gamePath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
} else {
 Write-OK "Garry's Mod found: $gamePath"
}

# -------------------------------------------------------
# STEP 2: Verify x64 branch
# -------------------------------------------------------
Write-Step 2 7 "Checking GMod x64 Branch"

$win64Dir = Join-Path $gamePath "bin\win64"
if (Test-Path $win64Dir) {
 Write-OK "GMod x64 branch detected (bin\win64 present)."
} else {
 Write-Fail "GMod x64 branch is NOT active!"
 Write-Host ""
 Write-Host " This mod REQUIRES the GMod x64 branch. To switch:" -ForegroundColor White
 Write-Host " 1. Press Enter to open Garry's Mod properties in Steam" -ForegroundColor Gray
 Write-Host " 2. Go to the 'Betas' tab" -ForegroundColor Gray
 Write-Host " 3. Under 'Beta Participation', select: x86-64" -ForegroundColor Yellow
 Write-Host " 4. Wait for Steam to finish updating GMod" -ForegroundColor Gray
 Write-Host " 5. Close Properties, then re-run this installer" -ForegroundColor Gray
 Write-Host ""
 Pause-User "Press Enter to open Garry's Mod properties in Steam..."
 Start-Process "steam://gameproperties/$GAME_APPID"
 Pause-User "Press Enter to exit the installer so you can re-run it after the x64 branch finishes downloading..."
 exit 0
}

# -------------------------------------------------------
# STEP 3: Optional clean slate for users upgrading from another VR mod
# -------------------------------------------------------
Write-Step 3 7 "Clean Slate (optional)"

$vrmodDataDir = Join-Path $gamePath "garrysmod\data\vrmod"
$cfgDir = Join-Path $gamePath "garrysmod\cfg"

$hasStaleData = (Test-Path $vrmodDataDir)
if ($hasStaleData) {
 Write-Info "Existing VRMod data detected and retained at:"
 Write-Host " $vrmodDataDir" -ForegroundColor Gray
 Write-Warn "If an incompatible old VRMod configuration causes trouble, back it up and remove it manually."
} else {
 Write-OK "No stale VRMod data found - skipping."
}

# -------------------------------------------------------
# STEP 4: Download & install modules
# -------------------------------------------------------
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile "garrysmod\lua\bin\gmcl_vrmod_win64.dll" -Label "VRMod"
Write-Step 4 7 "Installing VRMod modules"

# TLS is negotiated by the shared download helper.

# Resolve latest release URL - fall back to the pinned known-good one if API fails
$downloadUrl = $null
Write-Host " Looking up latest modules release ... " -NoNewline -ForegroundColor White
try {
 $release = Invoke-RestMethod -Uri $MODULES_API `
 -Headers @{ "User-Agent" = "PCVR-Mods-Hub-Installer" } `
 -TimeoutSec 10 -ErrorAction Stop
 $zipAsset = $release.assets | Where-Object { $_.name -like "modules*.zip" -or $_.name -eq "modules.zip" } | Select-Object -First 1
 if ($zipAsset) {
 $downloadUrl = $zipAsset.browser_download_url
 Write-Host "OK ($($release.tag_name))" -ForegroundColor Green
 } else {
 Write-Host "no zip asset found" -ForegroundColor Yellow
 }
} catch {
 Write-Host "API unreachable" -ForegroundColor Yellow
}
if (-not $downloadUrl) {
 Write-Info "Using fallback release URL."
 $downloadUrl = $MODULES_FALLBACK_URL
}

$tempDir = Join-Path $env:TEMP "GModVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$zipPath = Join-Path $tempDir "modules.zip"
$extractDir = Join-Path $tempDir "extract"

Write-Host " Downloading modules ... " -NoNewline -ForegroundColor White
try {
 Invoke-SafeDownload -Urls @($downloadUrl, $MODULES_FALLBACK_URL) -Destination $zipPath -Label "GMod VR modules" -ManualUrl "https://github.com/Abyss-c0re/vrmod-module-master/releases" -Instructions "Download 'modules.zip' from the releases page, save it as '$zipPath', then choose Retry." -SkipMessage "" | Out-Null
 if (-not (Test-Path -LiteralPath $zipPath)) { throw "modules.zip was not downloaded" }
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download error: $_"
 $__fb = Invoke-InstallerFallback -Action ".NET runtime download" `
 -Url "https://dotnet.microsoft.com/download/dotnet/7.0" `
 -Instructions "Install .NET 7 Desktop Runtime manually from https://dotnet.microsoft.com/download/dotnet/7.0 (x64 build)." `
 -SkipMessage "Skipped - the tool that needs .NET will not run; you can install .NET later and re-run." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-detect .NET 7 Desktop Runtime
 if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime detected."
 } else {
 Pause-User "Still no .NET 7. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

Write-Host " Extracting ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Extract error: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$zipPath' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder "$zipPath" `
 -DestFolder "$extractDir" `
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

# The zip contains: install/GarrysMod/{bin,garrysmod/lua/bin}/...
# We need to merge the contents of install/GarrysMod into $gamePath
$payloadRoot = Get-ChildItem -Path $extractDir -Directory -Recurse |
 Where-Object { $_.Name -eq "GarrysMod" -and (Test-Path (Join-Path $_.FullName "bin")) } |
 Select-Object -First 1
if (-not $payloadRoot) {
 Write-Fail "Could not locate GarrysMod folder inside the archive."
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$zipPath' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder "$zipPath" `
 -DestFolder "$extractDir" `
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

Write-Host " Copying module files into game folder ... " -NoNewline -ForegroundColor White
try {
 # Robocopy merges into existing tree without nuking files we want to keep
 $rc = @($payloadRoot.FullName, $gamePath, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/R:2", "/W:1")
 & robocopy @rc | Out-Null
 if ($LASTEXITCODE -ge 8) { throw "robocopy exit code $LASTEXITCODE" }
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Copy error: $_"
 $__fb = Invoke-InstallerFallback -Action "copy mod modules into Garry's Mod" `
 -Instructions "Open '$extractDir' (the extracted GMod VR modules) and merge its contents into '$gamePath' (your Garry's Mod install). Watch for UAC permission prompts. Then choose Skip to continue." `
 -SkipMessage "Skipped - VR modules were NOT copied; GMod will launch normally but VR will not load." `
 -DestFolder "$gamePath" `
 -AllowSkip $true
 -Instructions "Read the messages above for what failed. Try to address it manually then choose Retry, or Skip to continue without it." `
 -SkipMessage "Skipped - some functionality may not work." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

# ---- SAFEGUARD: did the right thing actually arrive? ----
# robocopy only reports its own exit code. An empty, wrong or partially
# extracted archive used to pass as "Modules installed." and GMod would
# simply have started flat. The check is at the DESTINATION, against the
# files the module package MUST bring - read from the real archive: the
# Lua binary module GMod loads, and the OpenVR library in both bitness
# variants of the bin folder.
$MOD_MUST_HAVE = @(
    "garrysmod\lua\bin\gmcl_vrmod_win64.dll",
    "bin\win64\openvr_api.dll",
    "bin\openvr_api.dll"
)
$missing = @()
foreach ($n in $MOD_MUST_HAVE) {
    if (-not (Test-Path -LiteralPath (Join-Path $gamePath $n))) { $missing += $n }
}
if ($missing.Count -eq 0) {
    Write-OK "Modules installed and verified ($($MOD_MUST_HAVE.Count) checks)."
} else {
    Write-Fail "The modules did not arrive completely - missing in the game folder:"
    foreach ($n in $missing) { Write-Host "   $n" -ForegroundColor Yellow }
    Write-Host "  Folder checked: $gamePath" -ForegroundColor Gray
    Write-Host "  The archive must be modules.zip from the vrmod module page;" -ForegroundColor White
    Write-Host "  inside it the files sit under install\GarrysMod\." -ForegroundColor White
    $__fbv = Invoke-InstallerFallback -Action "install the VR modules" `
        -Subject "the vrmod module archive" `
        -Url $MODULES_PAGE `
        -Instructions "Open modules.zip, go into install\GarrysMod\ and copy its CONTENTS (bin\ and garrysmod\) into '$gamePath'. Then choose Retry." `
        -DestFolder "$gamePath" `
        -AllowSkip $true
    if ([string]$__fbv -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    $missing2 = @()
    foreach ($n in $MOD_MUST_HAVE) { if (-not (Test-Path -LiteralPath (Join-Path $gamePath $n))) { $missing2 += $n } }
    if ($missing2.Count -eq 0) { Write-OK "Now verified ($($MOD_MUST_HAVE.Count) checks)." }
    else { Write-Warn "Still missing: $($missing2 -join ', ') - VR will not load in GMod." }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 5: Write autoexec.cfg with sensible defaults
# -------------------------------------------------------
Write-Step 5 7 "Writing autoexec.cfg"

$cfgPath = Join-Path $gamePath "garrysmod\cfg"
if (-not (Test-Path $cfgPath)) { New-Item -ItemType Directory -Path $cfgPath -Force | Out-Null }
$autoexecPath = Join-Path $cfgPath "autoexec.cfg"

# Notes:
# - The x64 branch does NOT execute autoexec.cfg automatically; we force it
# via the "+exec autoexec.cfg" launch option in the next step.
# - F2 is bound to open the VRMod menu so you don't have to dig into the
# console every single time.
# - gmod_mcore_test 1 and mat_queue_mode 2 are the standard performance
# tweaks recommended by both Catse and Abyss-c0re.
$autoexecContent = @"
// Auto-generated by PCVR Mods Installer Hub for Garry's Mod VR.
// Safe to edit; re-running the installer will overwrite this file.

// Performance (multi-core rendering / queued material system).
gmod_mcore_test 1
mat_queue_mode 2

// Bind F2 to open the VRMod menu in-game (works once a map is loaded).
bind "F2" "vrmod"
"@

$wasExisting = Test-Path $autoexecPath
if ($wasExisting) {
 $backupPath = "$autoexecPath.bak"
 try {
 Copy-Item -Path $autoexecPath -Destination $backupPath -Force
 Write-Info "Existing autoexec.cfg backed up to autoexec.cfg.bak"
 } catch {}
}
try {
 $utf8NoBom = New-Object System.Text.UTF8Encoding $false
 [System.IO.File]::WriteAllText($autoexecPath, $autoexecContent, $utf8NoBom)
 Write-OK "autoexec.cfg written: $autoexecPath"
} catch {
 Write-Fail "Could not write autoexec.cfg: $_"
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files into '$backupPath'. Watch for UAC permission prompts. Then choose Skip below to continue with downstream installer steps." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -DestFolder "$backupPath" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

# -------------------------------------------------------
# STEP 6: Subscribe to the Workshop addon (or a collection)
# -------------------------------------------------------
Write-Step 6 7 "Subscribe to the Workshop Addon"

Write-Host " The modules are the native half of the mod." -ForegroundColor White
Write-Host " You also need the Lua half from the Workshop." -ForegroundColor White
Write-Host " Three options - pick ONE:" -ForegroundColor White
Write-Host ""
Write-Host " A) Just VRMod x64 (solo, most minimal)" -ForegroundColor Yellow
Write-Host " $WORKSHOP_WEBURL" -ForegroundColor Gray
Write-Host ""
Write-Host " B) VRmodx64_minimalistic collection (28 items, recommended)" -ForegroundColor Yellow
Write-Host " VRMod + curated must-have VR tools and addons." -ForegroundColor Gray
Write-Host ""
Write-Host " C) VRmodx64 collection (172 items, full experience)" -ForegroundColor Yellow
Write-Host " Everything VR-related Doom Slayer curates. Heavy." -ForegroundColor Gray
Write-Host ""
Write-Host " For option B) and C), on the Workshop page directly under" -ForegroundColor White
Write-Host " the title you will see 'In 2 collections by Doom Slayer'" -ForegroundColor White
Write-Host " with both collection names. Click a collection, then" -ForegroundColor White
Write-Host " 'Subscribe to all'." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to open the Workshop page..."

Start-Process $WORKSHOP_URL
# steam:// handler can fail if Steam isn't configured as default - fall back to browser
Start-Sleep -Seconds 1
Start-Process $WORKSHOP_WEBURL

Pause-User "Press Enter once you have subscribed (or confirmed you already are)..."

# -------------------------------------------------------
# STEP 7: Set Launch Options in Steam
# -------------------------------------------------------
Write-Step 7 7 "Set Launch Options in Steam"

$launchOptions = "+exec autoexec.cfg"

try { Set-Clipboard -Value $launchOptions } catch {}

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Steam Launch Option" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host " (+exec autoexec.cfg | required for x64 branch)" -ForegroundColor Gray
Write-Host ""
Write-Host " Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
Write-Host " Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Garry's Mod properties in Steam..."
Start-Process "steam://gameproperties/$GAME_APPID"
try { Set-Clipboard -Value $launchOptions } catch {}
Pause-User "Press Enter once you have pasted the launch options and closed Properties..."

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " [x] VRMod x64 modules installed" -ForegroundColor Green
Write-Host " [x] autoexec.cfg written (F2 -> VRMod menu)" -ForegroundColor Green
Write-Host " [x] Workshop addon page opened for subscribe" -ForegroundColor Green
Write-Host " [x] Steam launch options set (if you pasted them)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Yellow

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " FIRST LAUNCH - ONE-TIME SETUP INSIDE GMOD" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " 1. Start SteamVR" -ForegroundColor White
Write-Host " 2. Launch Garry's Mod from Steam" -ForegroundColor White
Write-Host " First time only: Steam asks which version to launch." -ForegroundColor Gray
Write-Host " Pick the 64-bit one." -ForegroundColor Yellow
Write-Host " 3. Start a new game on any map" -ForegroundColor White
Write-Host " 4. Once you spawn in, press F2 to open the VRMod menu" -ForegroundColor White
Write-Host " 5. ON THE FIRST PAGE, ENABLE:" -ForegroundColor White
Write-Host " 'Automatically start VR after map opened'" -ForegroundColor Yellow
Write-Host " From now on VR starts automatically on every map load." -ForegroundColor Gray
Write-Host " 6. Press 'Start' at the bottom. Height calibration runs." -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Yellow

Write-Host ""
Write-Host " After this first-time setup, the flow is simply:" -ForegroundColor Green
Write-Host " Start SteamVR -> Launch GMod -> Load a map -> VR starts" -ForegroundColor Green

Write-Host ""
Write-Host "--- Tips ---" -ForegroundColor Cyan
Write-Host " - Incompatible: GShaderLibrary, ReShade, animation or" -ForegroundColor Gray
Write-Host " collision-modifying addons, non-standard player models." -ForegroundColor Gray

Write-Host ""
Write-Host "--- SteamVR Theatre Mode ---" -ForegroundColor Cyan
Write-Host " If GMod opens on a flat theatre screen: SteamVR menu ->" -ForegroundColor White
Write-Host " VR Settings -> Dashboard -> 'Present Non-VR Applications" -ForegroundColor Gray
Write-Host " on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you read the above..."

Write-Host ""
Write-Host " Props, ragdolls, and terrible ideas. Have at it." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the GarrysMod folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

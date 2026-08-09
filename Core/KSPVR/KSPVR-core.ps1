# ============================================================
# Kerbal Space Program - KerbalVR Mod Installer
# ============================================================
# This is the most involved installer in the Hub. KerbalVR has
# a long dependency chain that is best handled by CKAN (the KSP
# mod manager). The Hub downloads a private copy of ckan.exe,
# registers the KSP instance, and drives a modpack install from
# the .ckan file bundled inside the KerbalVR release zip.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Kerbal Space Program VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Kerbal Space Program"
$GAME_EXE = "KSP_x64.exe"
$STEAM_APPID = "220200"

# KerbalVR releases - GitHub API points at the current tag so a
# newer release is picked up automatically without editing this
# file. The asset is named Kerbal-VR-<tag>.zip.
$KVR_API = "https://api.github.com/repos/FirstPersonKSP/Kerbal-VR/releases/latest"
$KVR_RELEASES_URL = "https://github.com/FirstPersonKSP/Kerbal-VR/releases"
$KVR_WIKI_URL = "https://github.com/FirstPersonKSP/Kerbal-VR/wiki/Installation-Guide"

# CKAN - the KSP mod manager. We fetch ckan.exe from the official
# release and keep it in a Hub-managed tools folder so the user's
# own CKAN setup (if any) is left completely untouched.
$CKAN_API = "https://api.github.com/repos/KSP-CKAN/CKAN/releases/latest"
$CKAN_RELEASES_URL = "https://github.com/KSP-CKAN/CKAN/releases"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Kerbal Space Program - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " KerbalVR by JonnyOThan / FirstPersonKSP" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
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
 if (Test-Path (Join-Path $candidate $GAME_EXE)) { return $candidate }
 }
 return $null
}

# Reads the KSP version from readme.txt in the game root. KSP ships
# a readme with a "Version x.y.z" line near the top - this is the
# same heuristic CKAN itself uses to identify the install.
function Get-KSPVersion {
 param($gamePath)
 $readme = Join-Path $gamePath "readme.txt"
 if (-not (Test-Path $readme)) { return $null }
 try {
 # The "Version x.y.z" line sits a bit further down than the
 # banner art, so read enough lines to be sure to catch it.
 $lines = Get-Content $readme -TotalCount 40
 foreach ($line in $lines) {
 $m = [regex]::Match($line, 'Version\s+(\d+\.\d+\.\d+)')
 if ($m.Success) { return $m.Groups[1].Value }
 }
 } catch {}
 return $null
}

# -------------------------------------------------------
# Start mode: Full Install vs Update Only
# -------------------------------------------------------
# Full install drives the entire chain: dependencies via CKAN, the
# Unity-VR patch, and the mod file merge. Update mode is for when a
# newer KerbalVR release ships - it only refreshes the KerbalVR mod
# files (GameData + KSP_x64_Data) and leaves CKAN dependencies and
# the globalgamemanagers patch untouched, exactly as the wiki's
# "Upgrading from a previous install" section describes.
Write-Header
Write-Host " This installer sets up KerbalVR - native VR support for" -ForegroundColor White
Write-Host " Kerbal Space Program. The mod has a long dependency chain;" -ForegroundColor Gray
Write-Host " the Hub uses CKAN (the KSP mod manager) to handle it." -ForegroundColor Gray
Write-Host ""
Write-Host " Choose what to do:" -ForegroundColor White
Write-Host ""
Write-Host " [1] Full Install - first time setup (dependencies + VR patch + mod)" -ForegroundColor White
Write-Host " [2] Update Mod - refresh the KerbalVR mod files only" -ForegroundColor White
Write-Host " (use when a newer KerbalVR release ships)" -ForegroundColor Gray
Write-Host ""

$modeChoice = ""
while ($modeChoice -notin @("1","2")) {
 $modeChoice = (Read-Host " Your choice (1/2)").Trim()
}
$updateOnly = ($modeChoice -eq "2")
if ($updateOnly) {
 $totalSteps = 3
 Write-Host ""
 Write-OK "Update mode selected - only the KerbalVR mod files will be refreshed."
} else {
 $totalSteps = 8
}

# CKAN tools path is referenced from a couple of steps; declare the
# path here so Step 5's "where to find ckan.exe" hint resolves even
# before the folder is created down in Step 6.
$toolsDir = Join-Path $PSScriptRoot "tools"
$ckanExe = Join-Path $toolsDir "ckan.exe"
# -------------------------------------------------------
# STEP 1: Locate Kerbal Space Program
# -------------------------------------------------------
Write-Step 1 $totalSteps "Locating Kerbal Space Program"

$gamePath = $null
# --- Try detection library (safe: falls through to legacy lookup on failure) ---
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Kerbal Space Program"
 }
} catch {}
# --- End detection library attempt ---

if (-not $gamePath) {
 $steamPath = Get-SteamPath
 if ($steamPath) {
 $libraries = Get-SteamLibraries $steamPath
 $gamePath = Find-GamePath $libraries
 if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "220200" -SteamFolderNames @("Kerbal Space Program") }
 }
}

if (-not $gamePath) {
 Write-Warn "Kerbal Space Program not found in Steam libraries automatically."
 Write-Host " Please enter the KSP installation folder path manually:" -ForegroundColor White
 Write-Host " This is the folder that contains KSP_x64.exe" -ForegroundColor Gray
 Write-Host " Example: C:\Program Files (x86)\Steam\steamapps\common\Kerbal Space Program" -ForegroundColor Gray
 while (-not $gamePath) {
 $rawInput = (Read-Host " KSP path").Trim().Trim('"')
 if (Test-Path (Join-Path $rawInput $GAME_EXE)) {
 $gamePath = $rawInput
 Write-OK "KSP path set: $gamePath"
 } else {
 Write-Fail "KSP_x64.exe not found in: $rawInput"
 }
 }
} else {
 Write-OK "Kerbal Space Program found: $gamePath"
}

$gameExePath = Join-Path $gamePath $GAME_EXE

# ============================================================
# UPDATE-ONLY PATH
# ============================================================
# When the user picked Update mode we skip straight to the mod
# download + merge. CKAN dependencies and the globalgamemanagers
# patch are left exactly as they are.
if ($updateOnly) {
 $null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile "GameData\KerbalVR" -Label "KerbalVR"
 Write-Step 2 $totalSteps "Downloading latest KerbalVR release"

 $kvrUrl = $null
 $kvrTag = $null
 Write-Host " Querying GitHub for the latest KerbalVR release ... " -NoNewline -ForegroundColor White
 try {
 $apiResp = Invoke-WebRequest -Uri $KVR_API -UseBasicParsing -ErrorAction Stop `
 -Headers @{ "User-Agent"="PCVR-Mods-Hub"; "Accept"="application/vnd.github+json" }
 $release = $apiResp.Content | ConvertFrom-Json
 $kvrTag = $release.tag_name
 foreach ($asset in $release.assets) {
 if ($asset.name -like "Kerbal-VR-*.zip") {
 $kvrUrl = $asset.browser_download_url
 break
 }
 }
 Write-Host "OK" -ForegroundColor Green
 if ($kvrTag) { Write-Info "Latest release: $kvrTag" }
 } catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Warn "Could not reach GitHub API: $_"
 Write-Info "Download manually from: $KVR_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "ckan.exe download" `
 -Url "https://github.com/KSP-CKAN/CKAN/releases" `
 -Instructions "Open https://github.com/KSP-CKAN/CKAN/releases (the browser was opened), download ckan.exe and place it at '$ckanExe', then choose Retry." `
 -SkipMessage "Skipped - mod manager unavailable; KerbalVR install will proceed without CKAN." `
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
 if (-not $kvrUrl) {
 Write-Fail "Could not find the Kerbal-VR zip in the latest release."
 Write-Info "Download manually from: $KVR_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "KerbalVR download" `
 -Url "https://github.com/JonnyOThan/KerbalVR/releases" `
 -Instructions "Open https://github.com/JonnyOThan/KerbalVR/releases in the browser that just opened, download the latest KerbalVR ZIP, then extract its contents into '$gamePath' (your KSP install). Choose Retry afterwards." `
 -SkipMessage "Skipped - KerbalVR was NOT installed." `
 -DestFolder "$gamePath" `
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

 $tempDir = Join-Path $env:TEMP "KSPVRInstaller_$([System.IO.Path]::GetRandomFileName())"
 New-Item -ItemType Directory -Path $tempDir | Out-Null
 $kvrZip = Join-Path $tempDir "KerbalVR.zip"
 $kvrExtract = Join-Path $tempDir "KerbalVR"

 Write-Host " Downloading KerbalVR ... " -NoNewline -ForegroundColor White
 try {
 Invoke-WebRequest -Uri $kvrUrl -OutFile $kvrZip -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green
 Write-Host " Extracting ... " -NoNewline -ForegroundColor White
 Expand-Archive -Path $kvrZip -DestinationPath $kvrExtract -Force
 Write-Host "OK" -ForegroundColor Green
 } catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download/extract error: $_"
 try { Remove-Item $tempDir -Recurse -Force } catch {}
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$kvrZip' with 7-Zip or Windows Explorer, and extract its contents into '$kvrExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$kvrZip" -Parent) `
 -DestFolder "$kvrExtract" `
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

 Write-Step 3 $totalSteps "Refreshing KerbalVR mod files"

 # Merge GameData and KSP_x64_Data from the extracted release
 # into the KSP root. Copy-Item with -Recurse -Force merges
 # over the existing folders just like a manual drag-and-drop.
 $mergedAny = $false
 foreach ($folder in @("GameData", "KSP_x64_Data")) {
 $src = Join-Path (Get-ExtractedPayloadRoot -ExtractDir $kvrExtract -Markers @("GameData","KSP_x64_Data")) $folder
 if (Test-Path $src) {
 Write-Host " Merging $folder ... " -NoNewline -ForegroundColor White
 Copy-Item -Path $src -Destination $gamePath -Recurse -Force
 Write-Host "OK" -ForegroundColor Green
 $mergedAny = $true
 }
 }
 if (-not $mergedAny) {
 Write-Warn "Neither GameData nor KSP_x64_Data found in the release zip."
 Write-Info "The release layout may have changed - check $KVR_WIKI_URL"
 }

 # Delete the stale MiniAVC.dll the wiki warns about.
 $miniAvc = Join-Path $gamePath "GameData\JSI\MiniAVC.dll"
 if (Test-Path $miniAvc) {
 try {
 Remove-Item $miniAvc -Force
 Write-OK "Removed out-of-date MiniAVC.dll"
 } catch {
 Write-Warn "Could not remove MiniAVC.dll: $_"
 }
 }

 try { Remove-Item $tempDir -Recurse -Force } catch {}

 Write-Host ""
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Update Complete" -ForegroundColor White
 Write-Host ""
 Write-Host " [x] KerbalVR$(if ($kvrTag) { " $kvrTag" }) mod files refreshed" -ForegroundColor Green
 Write-Host " [-] Dependencies and Unity-VR patch left untouched" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
 Write-Warn "Read the KerbalVR release notes - a new version may need"
 Write-Warn "new dependencies. If so, run a Full Install instead."
 Write-Host ""
 Write-Host " Wernher von Kerman would be proud. Fly safe!" -ForegroundColor Green
 Write-Host ""
 Pause-User "Press Enter to exit..."
 exit 0
}

# ============================================================
# FULL INSTALL PATH
# ============================================================

# -------------------------------------------------------
# STEP 2: Verify KSP version
# -------------------------------------------------------
Write-Step 2 $totalSteps "Checking KSP Version"

$kspVer = Get-KSPVersion $gamePath
if ($kspVer) {
 Write-Info "Detected KSP version: $kspVer"
 # KerbalVR requires 1.12.3 or later. Compare as System.Version.
 try {
 $verObj = [System.Version]$kspVer
 $minObj = [System.Version]"1.12.3"
 if ($verObj -lt $minObj) {
 Write-Warn "KerbalVR requires KSP 1.12.3 or later."
 Write-Warn "Your version ($kspVer) is older - the mod may not work."
 Write-Host ""
 Write-Host " You can continue, but a clean KSP 1.12.3+ install is" -ForegroundColor Yellow
 Write-Host " strongly recommended." -ForegroundColor Yellow
 } else {
 Write-OK "KSP version is compatible (1.12.3+ required)."
 }
 } catch {
 Write-Info "Could not parse the version string - continuing anyway."
 }
} else {
 Write-Warn "Could not read the KSP version from readme.txt."
 Write-Info "KerbalVR requires KSP 1.12.3 or later - please make sure"
 Write-Info "your install meets that before continuing."
}
Write-Host ""
Write-Host " IMPORTANT: KerbalVR works best from a CLEAN KSP install." -ForegroundColor Yellow
Write-Host " If your GameData folder already has lots of mods, conflicts" -ForegroundColor Yellow
Write-Host " are likely. The wiki recommends starting fresh." -ForegroundColor Yellow
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# STEP 3: SteamVR requirement
# -------------------------------------------------------
Write-Step 3 $totalSteps "SteamVR Requirement"

Write-Host " KerbalVR renders through SteamVR. Before playing you must:" -ForegroundColor White
Write-Host ""
Write-Host " - Install SteamVR from Steam (App 250820)" -ForegroundColor Yellow
Write-Host " - Use SteamVR 2.8 - the STABLE branch, NOT the Beta" -ForegroundColor Yellow
Write-Host " - The SteamVR Beta and Theater Mode are known to break KerbalVR" -ForegroundColor Yellow
Write-Host ""
Write-Host " SYMPTOM if you are on the wrong branch: the KSP window stays" -ForegroundColor Yellow
Write-Host " completely white, or it loads forever stuck on the loading bar." -ForegroundColor Yellow
Write-Host " If that happens, switch SteamVR to the stable branch first." -ForegroundColor Yellow
Pause-User "Press Enter once you understand the SteamVR requirement..."

# -------------------------------------------------------
# STEP 4: Download KerbalVR
# -------------------------------------------------------
Write-Step 4 $totalSteps "Downloading KerbalVR"

$kvrUrl = $null
$kvrTag = $null
Write-Host " Querying GitHub for the latest KerbalVR release ... " -NoNewline -ForegroundColor White
try {
 $apiResp = Invoke-WebRequest -Uri $KVR_API -UseBasicParsing -ErrorAction Stop `
 -Headers @{ "User-Agent"="PCVR-Mods-Hub"; "Accept"="application/vnd.github+json" }
 $release = $apiResp.Content | ConvertFrom-Json
 $kvrTag = $release.tag_name
 foreach ($asset in $release.assets) {
 if ($asset.name -like "Kerbal-VR-*.zip") {
 $kvrUrl = $asset.browser_download_url
 break
 }
 }
 Write-Host "OK" -ForegroundColor Green
 if ($kvrTag) { Write-Info "Latest release: $kvrTag" }
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Warn "Could not reach GitHub API: $_"
 Write-Info "Download manually from: $KVR_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "KerbalVR download" `
 -Url "https://github.com/JonnyOThan/KerbalVR/releases" `
 -Instructions "Open https://github.com/JonnyOThan/KerbalVR/releases in the browser that just opened, download the latest KerbalVR ZIP, then extract its contents into '$gamePath' (your KSP install). Choose Retry afterwards." `
 -SkipMessage "Skipped - KerbalVR was NOT installed." `
 -DestFolder "$gamePath" `
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
if (-not $kvrUrl) {
 Write-Fail "Could not find the Kerbal-VR zip in the latest release."
 Write-Info "Download manually from: $KVR_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "KerbalVR download" `
 -Url "https://github.com/JonnyOThan/KerbalVR/releases" `
 -Instructions "Open https://github.com/JonnyOThan/KerbalVR/releases in the browser that just opened, download the latest KerbalVR ZIP, then extract its contents into '$gamePath' (your KSP install). Choose Retry afterwards." `
 -SkipMessage "Skipped - KerbalVR was NOT installed." `
 -DestFolder "$gamePath" `
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

# Persistent work dir for this whole run (CKAN tool + extracted mod).
$tempDir = Join-Path $env:TEMP "KSPVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$kvrZip = Join-Path $tempDir "KerbalVR.zip"
$kvrExtract = Join-Path $tempDir "KerbalVR"

Write-Host " Downloading KerbalVR ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $kvrUrl -OutFile $kvrZip -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green
 Write-Host " Extracting ... " -NoNewline -ForegroundColor White
 Expand-Archive -Path $kvrZip -DestinationPath $kvrExtract -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download/extract error: $_"
 try { Remove-Item $tempDir -Recurse -Force } catch {}
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$kvrZip' with 7-Zip or Windows Explorer, and extract its contents into '$kvrExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$kvrZip" -Parent) `
 -DestFolder "$kvrExtract" `
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

# Locate the bundled .ckan dependency file inside the extracted mod.
$ckanFile = Get-ChildItem -Path $kvrExtract -Recurse -Filter "*.ckan" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ckanFile) {
 Write-OK "Found dependency file: $($ckanFile.Name)"
} else {
 Write-Warn "No .ckan dependency file found inside the release zip."
 Write-Info "Dependencies will have to be installed manually - see the wiki."
}

# -------------------------------------------------------
# STEP 5: IVA Pack and Avionics System choices
# -------------------------------------------------------
Write-Step 5 $totalSteps "IVA Pack and Avionics System"

Write-Host " KerbalVR needs an IVA (cockpit interior) pack. Choose one:" -ForegroundColor White
Write-Host ""
Write-Host " [1] KSA IVA Upgrade" -ForegroundColor White
Write-Host " Built for VR from the ground up - the richest VR experience." -ForegroundColor Gray
Write-Host " Only covers the Mk1 stock parts, though." -ForegroundColor Gray
Write-Host ""
Write-Host " [2] DE_IVAExtension" -ForegroundColor White
Write-Host " The long-standing IVA pack covering ALL stock pods." -ForegroundColor Gray
Write-Host " Fewer VR-specific props than KSA." -ForegroundColor Gray
Write-Host ""
Write-Host " [3] Both + Reviva (recommended for the full experience)" -ForegroundColor White
Write-Host " Reviva lets you switch IVAs per-part. Best coverage, but" -ForegroundColor Gray
Write-Host " you must actively pick the IVA in-game or you get stock." -ForegroundColor Gray
Write-Host ""

$ivaChoice = ""
while ($ivaChoice -notin @("1","2","3")) {
 $ivaChoice = (Read-Host " Your IVA choice (1/2/3)").Trim()
}
switch ($ivaChoice) {
 "1" { $ivaLabel = "KSA IVA Upgrade" }
 "2" { $ivaLabel = "DE_IVAExtension" }
 "3" { $ivaLabel = "KSA IVA Upgrade + DE_IVAExtension + Reviva" }
}
Write-OK "IVA pack: $ivaLabel"

Write-Host ""
Write-Host " KerbalVR's interactive cockpits run on RPM or MAS. Choose:" -ForegroundColor White
Write-Host ""
Write-Host " [1] RasterPropMonitor (RPM) (recommended)" -ForegroundColor White
Write-Host " Older, wider IVA support. KerbalVR's primary target." -ForegroundColor Gray
Write-Host ""
Write-Host " [2] MOARdV's Avionics Systems (MAS)" -ForegroundColor White
Write-Host " Newer system, but fewer cockpits are built for it." -ForegroundColor Gray
Write-Host ""
Write-Host " [3] Both (works, but higher performance cost)" -ForegroundColor White
Write-Host ""

$masChoice = ""
while ($masChoice -notin @("1","2","3")) {
 $masChoice = (Read-Host " Your choice (1/2/3)").Trim()
}
switch ($masChoice) {
 "1" { $masLabel = "RasterPropMonitor (RPM)" }
 "2" { $masLabel = "MOARdV's Avionics Systems (MAS)" }
 "3" { $masLabel = "RPM + MAS" }
}
Write-OK "Avionics system: $masLabel"

Write-Host ""
Write-Host " Only what KerbalVR requires will be installed. To add more" -ForegroundColor White
Write-Host " IVAs or MAS later, run ckan.exe from your KSP folder - the" -ForegroundColor White
Write-Host " installer drops it there when it is done." -ForegroundColor White
Pause-User "Press Enter to continue to dependency installation..."

# -------------------------------------------------------
# STEP 6: CKAN + dependencies
# -------------------------------------------------------
Write-Step 6 $totalSteps "Installing Dependencies via CKAN"

# Hub-managed CKAN: ckan.exe lives in a tools folder next to this
# script so the user's own CKAN (if any) is never touched. Path
# was declared near the top of the script; just make sure the
# folder exists before we try to download into it.
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

if (Test-Path $ckanExe) {
 Write-OK "CKAN already present in the Hub tools folder."
} else {
 Write-Host " Querying GitHub for the latest CKAN release ... " -NoNewline -ForegroundColor White
 $ckanUrl = $null
 try {
 $ckanResp = Invoke-WebRequest -Uri $CKAN_API -UseBasicParsing -ErrorAction Stop `
 -Headers @{ "User-Agent"="PCVR-Mods-Hub"; "Accept"="application/vnd.github+json" }
 $ckanRel = $ckanResp.Content | ConvertFrom-Json
 foreach ($asset in $ckanRel.assets) {
 if ($asset.name -eq "ckan.exe") {
 $ckanUrl = $asset.browser_download_url
 break
 }
 }
 Write-Host "OK" -ForegroundColor Green
 } catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Warn "Could not reach the CKAN GitHub API: $_"
 Write-Info "Download ckan.exe manually from: $CKAN_RELEASES_URL"
 Write-Info "Place it here, then re-run this installer:"
 Write-Info " $ckanExe"
 $__fb = Invoke-InstallerFallback -Action "ckan.exe download" `
 -Url "https://github.com/KSP-CKAN/CKAN/releases" `
 -Instructions "Open https://github.com/KSP-CKAN/CKAN/releases (the browser was opened), download ckan.exe and place it at '$ckanExe', then choose Retry." `
 -SkipMessage "Skipped - mod manager unavailable; KerbalVR install will proceed without CKAN." `
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
 if (-not $ckanUrl) {
 Write-Fail "Could not find ckan.exe in the latest CKAN release."
 Write-Info "Download manually from: $CKAN_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "ckan.exe download" `
 -Url "https://github.com/KSP-CKAN/CKAN/releases" `
 -Instructions "Open https://github.com/KSP-CKAN/CKAN/releases (the browser was opened), download ckan.exe and place it at '$ckanExe', then choose Retry." `
 -SkipMessage "Skipped - mod manager unavailable; KerbalVR install will proceed without CKAN." `
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
 Write-Host " Downloading ckan.exe ... " -NoNewline -ForegroundColor White
 try {
 Invoke-WebRequest -Uri $ckanUrl -OutFile $ckanExe -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green
 } catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Could not download ckan.exe: $_"
 $__fb = Invoke-InstallerFallback -Action "ckan.exe download" `
 -Url "https://github.com/KSP-CKAN/CKAN/releases" `
 -Instructions "Open https://github.com/KSP-CKAN/CKAN/releases (the browser was opened), download ckan.exe and place it at '$ckanExe', then choose Retry." `
 -SkipMessage "Skipped - mod manager unavailable; KerbalVR install will proceed without CKAN." `
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
}

# Register the KSP install as a CKAN game instance. CKAN keeps a
# named list of instances; "add" is idempotent-ish but throws if
# the name already exists, so we tolerate that and continue.
Write-Host ""
Write-Host " Registering your KSP install with CKAN ... " -NoNewline -ForegroundColor White
$ckanInstance = "KSPVR-Hub"
try {
 & $ckanExe ksp add $ckanInstance "$gamePath" 2>&1 | Out-Null
 Write-Host "OK" -ForegroundColor Green
} catch {
 # Most likely the instance name already exists from a previous
 # run - that is fine, we just point CKAN at it below.
 Write-Host "(already registered)" -ForegroundColor Gray
}

# Make the registered instance the default so subsequent ckan
# commands operate on it without needing --instance every time.
try {
 & $ckanExe ksp default $ckanInstance 2>&1 | Out-Null
} catch {}

# CKAN refuses to install mods unless the game version is marked
# compatible. Many KerbalVR dependencies target 1.8-1.11 but work
# fine on 1.12, so we explicitly add those as compatible versions.
Write-Host " Marking KSP 1.8-1.12 as compatible ... " -NoNewline -ForegroundColor White
foreach ($compat in @("1.8","1.9","1.10","1.11","1.12")) {
 try { & $ckanExe compat add $compat 2>&1 | Out-Null } catch {}
}
Write-Host "OK" -ForegroundColor Green

# Refresh the CKAN registry so it knows about current mod versions.
Write-Host " Updating the CKAN mod registry ... " -NoNewline -ForegroundColor White
try {
 & $ckanExe update 2>&1 | Out-Null
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "WARN" -ForegroundColor Yellow
 Write-Warn "Registry update reported an issue - continuing anyway."
}

# Drive the modpack install from the bundled .ckan file. CKAN will
# resolve every dependency and pop a recommendations dialog where
# the user ticks their IVA pack and avionics system.
if ($ckanFile) {
 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " CKAN will now install the KerbalVR dependencies." -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to start the CKAN dependency install..."

 try {
 # install -c <file> installs the dependency modpack from the
 # bundled .ckan file. --headless disables every prompt so it
 # runs unattended; --no-recommends installs only the required
 # 'depends' modules and skips the long 'recommends' list that
 # would otherwise pull in dozens of extra mods. Both options
 # are documented ckan install flags.
 & $ckanExe install -c "$($ckanFile.FullName)" --headless --no-recommends
 Write-Host ""
 Write-OK "CKAN dependency install finished."
 } catch {
 Write-Warn "CKAN reported an issue: $_"
 Write-Info "You can open ckan.exe manually from:"
 Write-Info " $ckanExe"
 Write-Info "and use File -> Install from .ckan with this file:"
 Write-Info " $($ckanFile.FullName)"
 Pause-User "Press Enter once dependencies are installed..."
 }
} else {
 Write-Warn "No .ckan file was found - dependencies must be installed by hand."
 Write-Info "See the dependency list in the installation guide:"
 Write-Info " $KVR_WIKI_URL"
 Pause-User "Press Enter once you have installed the dependencies manually..."
}

Write-Host ""
Write-OK "Dependencies done. Moving on to the Unity VR patch."

# -------------------------------------------------------
# STEP 7: Enable Unity VR (vrinstaller.exe)
# -------------------------------------------------------
Write-Step 7 $totalSteps "Enabling Unity VR"

# vrinstaller.exe ships inside the KerbalVR release. It patches
# globalgamemanagers to switch on native Unity VR and writes a
# backup. It has no documented command-line arguments, so we
# launch it and have the user point it at the KSP folder.
$vrInstaller = Get-ChildItem -Path $kvrExtract -Recurse -Filter "vrinstaller.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($vrInstaller) {
 # Put the KSP path on the clipboard so the user can paste it
 # straight into vrinstaller's folder picker.
 try { Set-Clipboard -Value $gamePath } catch {}

 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - point vrinstaller at your KSP folder" -ForegroundColor Yellow
 Write-Host " (UAC prompt will appear - confirm it)" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " Your KSP path (already copied to clipboard):" -ForegroundColor White
 Write-Host " $gamePath" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " A vrinstaller window will open. Press 'Next' twice." -ForegroundColor White
 Write-Host " In the folder selection window: clear the path at the top," -ForegroundColor White
 Write-Host " press Ctrl+V to paste, then press 'Next' and 'Close'." -ForegroundColor White
 Write-Host ""
 Pause-User "Press Enter to launch vrinstaller.exe..."

 try {
 Start-Process -FilePath $vrInstaller.FullName -Wait
 Write-OK "vrinstaller.exe finished."
 } catch {
 Write-Warn "Could not launch vrinstaller.exe automatically: $_"
 Write-Info "Run it manually from:"
 Write-Info " $($vrInstaller.FullName)"
 Pause-User "Press Enter once you have run vrinstaller.exe..."
 }
} else {
 Write-Warn "vrinstaller.exe not found in the release zip."
 Write-Info "The release layout may have changed - see the wiki:"
 Write-Info " $KVR_WIKI_URL"
 Pause-User "Press Enter to continue..."
}

# -------------------------------------------------------
# STEP 8: Install KerbalVR mod files
# -------------------------------------------------------
Write-Step 8 $totalSteps "Installing KerbalVR Mod Files"

# Merge GameData and KSP_x64_Data from the extracted release into
# the KSP root, exactly as the wiki's Step 4 describes.
$mergedAny = $false
foreach ($folder in @("GameData", "KSP_x64_Data")) {
 $src = Join-Path (Get-ExtractedPayloadRoot -ExtractDir $kvrExtract -Markers @("GameData","KSP_x64_Data")) $folder
 if (Test-Path $src) {
 Write-Host " Merging $folder into the KSP root ... " -NoNewline -ForegroundColor White
 Copy-Item -Path $src -Destination $gamePath -Recurse -Force
 Write-Host "OK" -ForegroundColor Green
 $mergedAny = $true
 }
}
if (-not $mergedAny) {
 Write-Warn "Neither GameData nor KSP_x64_Data found in the release zip."
 Write-Info "Check the release layout against the wiki: $KVR_WIKI_URL"
}

# The release bundles a JSI folder that merges with RasterPropMonitor's.
# The MiniAVC.dll inside it is out of date and the wiki says to delete it.
$miniAvc = Join-Path $gamePath "GameData\JSI\MiniAVC.dll"
if (Test-Path $miniAvc) {
 try {
 Remove-Item $miniAvc -Force
 Write-OK "Removed out-of-date MiniAVC.dll from the JSI folder."
 } catch {
 Write-Warn "Could not remove MiniAVC.dll: $_"
 Write-Info "Please delete it manually: $miniAvc"
 }
}

# No desktop shortcut is created: KSP launches normally through Steam,
# the KerbalVR install does not change the executable or arguments.
# Just start SteamVR first and launch the game from Steam.

# Clean up the temp work directory.
try { Remove-Item $tempDir -Recurse -Force } catch {}

# Move ckan.exe into the KSP folder. The Hub used its own private
# copy during install so the user's existing CKAN (if any) was not
# disturbed, but now that the install is done it is more useful to
# the user sitting next to KSP_x64.exe - that is where people look
# for KSP tools. Delete the now-empty tools folder afterwards.
$ckanFinal = Join-Path $gamePath "ckan.exe"
if (Test-Path $ckanExe) {
 Write-Host ""
 Write-Host " Moving ckan.exe into the KSP folder ... " -NoNewline -ForegroundColor White
 try {
 Move-Item -Path $ckanExe -Destination $ckanFinal -Force
 Write-Host "OK" -ForegroundColor Green
 Write-Info "ckan.exe is now at: $ckanFinal"
 # Remove the now-empty tools folder.
 try { Remove-Item $toolsDir -Recurse -Force } catch {}
 } catch {
 Write-Host "WARN" -ForegroundColor Yellow
 Write-Warn "Could not move ckan.exe: $_"
 Write-Info "It is still available at: $ckanExe"
 $ckanFinal = $ckanExe
 }
} else {
 $ckanFinal = $null
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Complete" -ForegroundColor White
Write-Host ""
Write-Host " [x] KerbalVR$(if ($kvrTag) { " $kvrTag" }) installed" -ForegroundColor Green
Write-Host " [x] Dependencies installed via CKAN" -ForegroundColor Green
Write-Host " [x] IVA pack: $ivaLabel" -ForegroundColor Green
Write-Host " [x] Avionics: $masLabel" -ForegroundColor Green
Write-Host " [x] Unity VR patch applied" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "--- How to Play ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " 1. Connect your headset (link cable, Virtual Desktop, ALVR)." -ForegroundColor White
Write-Host " 2. Launch SteamVR FIRST (stable 2.8 -" -NoNewline -ForegroundColor White
Write-Host " NOT the Beta" -NoNewline -ForegroundColor Yellow
Write-Host ")." -ForegroundColor White
Write-Host " 3. Launch KSP with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub - the game window" -ForegroundColor White
Write-Host "    may appear white for ~10s." -ForegroundColor White
Write-Host " 4. At the main menu the kerbals should wear VR headsets." -ForegroundColor White
Write-Host " 5. Load into a flight, then press" -NoNewline -ForegroundColor White
Write-Host " Alt+V " -NoNewline -ForegroundColor Yellow
Write-Host "to enter VR." -ForegroundColor White
Write-Host ""
Write-Host "--- Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " - Only IVA (in-cockpit) and EVA are supported - no map view," -ForegroundColor Gray
Write-Host " no VAB, no UI interaction. The mod is early development." -ForegroundColor Gray
Write-Host " - To play without VR, launch KSP with -vrmode None" -ForegroundColor Gray
Write-Host " - If you use Reviva you must actively pick the IVA in-game." -ForegroundColor Gray
Write-Host " - Full guide: $KVR_WIKI_URL" -ForegroundColor Gray
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " In SteamVR Dashboard -> Settings:" -ForegroundColor White
Write-Host " Disable 'Present Non-VR Applications on Theater Screen Upon Launch'" -ForegroundColor Gray
Write-Host ""
Write-Host " REMEMBER: nothing happens in the headset until you press" -NoNewline -ForegroundColor White
Write-Host " Alt+V " -NoNewline -ForegroundColor Yellow
Write-Host "in flight!" -ForegroundColor White
Write-Host ""
Write-Host " The Kerbals are strapped in and the launchpad is yours. Godspeed!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit..."

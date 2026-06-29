# ============================================================
# Techtonica VR Mod Installer
# ============================================================
# Mod by 3_141 (Xenira). Distributed via Thunderstore.
#
# Versions are pinned. The mod hasn't seen recent activity
# and an auto-pull from Thunderstore could pick up a re-upload
# that breaks the layout assumptions below. If a new release
# drops we'll update the pins manually and re-test.
#
# Stack (in install order):
# 1. BepInEx 5.4.2305 winhttp.dll bootstrap
# 2. PiVRLoader 0.1.1 VR camera + controller setup
# 3. TTIK 0.2.2 Inverse Kinematics for VR body
# 4. PiUtils 0.4.0 Shared helpers used by VR mod
# 5. UnityAudio 2.0.3 Tobey's audio patcher (for
# teleport/snap-turn cues - the
# manifest lists it as a hard
# dependency)
# 6. TechtonicaVR 2.0.0 The actual VR mod
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Techtonica VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Techtonica"
$GAME_EXE = "Techtonica.exe"
$STEAM_APP = "1457320"

# Pinned download URLs - direct asset links on thunderstore.io
$URLS = @{
 BepInEx = "https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2305/"
 PiVRLoader = "https://thunderstore.io/package/download/3_141/PiVRLoader/0.1.1/"
 TTIK = "https://thunderstore.io/package/download/3_141/TTIK/0.2.2/"
 PiUtils = "https://thunderstore.io/package/download/3_141/PiUtils/0.4.0/"
 UnityAudio = "https://thunderstore.io/package/download/Tobey/UnityAudio/2.0.3/"
 TechtonicaVR= "https://thunderstore.io/package/download/3_141/TechtonicaVR/2.0.0/"
}

# Files we strip from every Thunderstore package before copying
# into the game folder - these are package metadata, not mod
# content, and they would clutter the install root.
$TS_META_FILES = @("manifest.json", "icon.png", "README.md", "README.adoc", "CHANGELOG.md", "LICENSE")

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Techtonica - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " TechtonicaVR v2.0.0 by 3_141 (Xenira) | via Thunderstore" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }
 return $null
}
function Get-SteamLibraries {
 param($sp); $libs=@($sp); $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object {
 $l=$_.Groups[1].Value -replace '\\\\','\'
 if (Test-Path $l) { $libs+=$l }
 }
 }
 return $libs
}

function Get-Zip {
 param($name, $url, $dest)
 $sources = @($url, "https://web.archive.org/web/0/$url")
 foreach ($u in $sources) {
   Write-Host " Downloading $name from $u ... " -NoNewline -ForegroundColor White
   try {
     $progressPreference = 'SilentlyContinue'
     Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing -EA Stop
     $progressPreference = 'Continue'
     Write-Host "OK" -ForegroundColor Green
     return $true
   } catch {
     Write-Host "FAILED" -ForegroundColor Red
     Write-Warn "Source error: $_"
   }
 }
 # All auto-sources failed - interactive fallback
 $r = Invoke-InstallerFallback `
        -Action "$name download" `
        -Url $url `
        -Instructions "Open the page above, download '$name' manually, place it at '$dest', then choose Retry." `
        -SkipMessage "Skipped - $name was not downloaded; install may be incomplete (questionable result)." `
        -DestFolder (Split-Path "$dest" -Parent) `
        -AllowSkip $true
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 return ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 0))
}

function Expand-To {
 param($zip, $dir)
 if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
 New-Item -ItemType Directory -Path $dir -Force | Out-Null
 Expand-Archive -Path $zip -DestinationPath $dir -Force
}

# Drop every non-metadata top-level item from the package into
# the game folder. Works for the standard Thunderstore layout
# where the ZIP root contains BepInEx/, plus metadata files.
function Copy-PackagePayload {
 param($extractedDir, $gamePath)
 Get-ChildItem -Path $extractedDir | Where-Object { $_.Name -notin $TS_META_FILES } | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
}

# -------------------------------------------------------
# STEP 1: Locate game
# -------------------------------------------------------
Write-Header
Write-Step 1 3 "Locating Techtonica"

$gamePath = $null

# Try utility detection lib first if present (other installers
# share a small helper - we use it if available, otherwise
# fall back to direct Steam-library walk).
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Techtonica"
 }
} catch {}

if (-not $gamePath) {
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; break }
 }
 }
}

if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1457320" -SteamFolderNames @("Techtonica") }
if ($gamePath) {
 Write-OK "Found: $gamePath"
} else {
 Write-Warn "Techtonica not found automatically."
 Write-Host " Enter the game folder (containing $GAME_EXE):" -ForegroundColor White
 Write-Host " Example: C:\Program Files (x86)\Steam\steamapps\common\Techtonica" -ForegroundColor Gray
 while (-not $gamePath) {
 $r = (Read-Host " Path").Trim().Trim('"')
 if (Test-Path (Join-Path $r $GAME_EXE)) {
 $gamePath = $r
 Write-OK "Path set: $gamePath"
 } else {
 Write-Fail "Not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 2: Download and install all packages
# -------------------------------------------------------
Write-Step 2 3 "Downloading and installing 6 Thunderstore packages"

$tmp = Join-Path $env:TEMP "TechtonicaVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null

$failed = @()

# ---- BepInEx ----
# Special layout: ZIP root contains a "BepInExPack/" folder
# whose contents are the actual install payload. Detect by
# walking until we find winhttp.dll.
Write-Host ""
if (Get-Zip "BepInEx 5.4.2305" $URLS.BepInEx "$tmp\bep.zip") {
 Expand-To "$tmp\bep.zip" "$tmp\bep"
 $bepRoot = Get-ChildItem -Path "$tmp\bep" -Directory -Recurse |
 Where-Object { Test-Path (Join-Path $_.FullName "winhttp.dll") } |
 Select-Object -First 1
 $src = if ($bepRoot) { $bepRoot.FullName } else { "$tmp\bep" }
 Get-ChildItem -Path $src | Where-Object { $_.Name -notin $TS_META_FILES } | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 if (Test-Path (Join-Path $gamePath "winhttp.dll")) {
 Write-OK "BepInEx 5.4.2305 installed."
 } else {
 Write-Fail "BepInEx copy failed - winhttp.dll not in game folder."
 $failed += "BepInEx"
 }
} else {
 $failed += "BepInEx"
}

# ---- Standard Pi-mod packages and UnityAudio ----
# All follow the same layout: ZIP root has BepInEx/ + metadata.
# Just merge BepInEx/ into the game folder.
$standardPackages = @(
 @{ Key="PiVRLoader"; Url=$URLS.PiVRLoader; Friendly="PiVRLoader 0.1.1" }
 @{ Key="TTIK"; Url=$URLS.TTIK; Friendly="TTIK 0.2.2" }
 @{ Key="PiUtils"; Url=$URLS.PiUtils; Friendly="PiUtils 0.4.0" }
 @{ Key="UnityAudio"; Url=$URLS.UnityAudio; Friendly="UnityAudio 2.0.3" }
 @{ Key="TechtonicaVR"; Url=$URLS.TechtonicaVR; Friendly="TechtonicaVR 2.0.0" }
)

foreach ($pkg in $standardPackages) {
 $zip = "$tmp\$($pkg.Key).zip"
 $ext = "$tmp\$($pkg.Key)"
 if (Get-Zip $pkg.Friendly $pkg.Url $zip) {
 try {
 Expand-To $zip $ext
 Copy-PackagePayload -extractedDir $ext -gamePath $gamePath
 Write-OK "$($pkg.Friendly) installed."
 } catch {
 Write-Fail "Install error for $($pkg.Friendly): $_"
 $failed += $pkg.Key
 }
 } else {
 $failed += $pkg.Key
 }
}

# Cleanup temp regardless of outcome
try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# Sanity-check that the core mod DLL ended up where we expect
$modDll = Join-Path $gamePath "BepInEx\plugins\techtonica_vr\techtonica_vr.dll"
$modOk = Test-Path $modDll

# -------------------------------------------------------
# STEP 3: Summary + first launch instructions
# -------------------------------------------------------
Write-Step 3 3 "Done"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
if ($failed.Count -eq 0 -and $modOk) {
    # Record install path for the post-install VR-Ready refresh (no full scan needed).
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
 Write-Host " Techtonica VR Mod installed successfully" -ForegroundColor Green
} elseif ($modOk) {
 Write-Host " Mod installed but some packages failed:" -ForegroundColor Yellow
 foreach ($f in $failed) { Write-Host " - $f" -ForegroundColor Yellow }
 Write-Host " The game may still launch in VR but features could be missing." -ForegroundColor Yellow
} else {
 Write-Host " Install incomplete:" -ForegroundColor Red
 foreach ($f in $failed) { Write-Host " - $f" -ForegroundColor Red }
 Write-Host " techtonica_vr.dll is missing - VR will not load." -ForegroundColor Red
}
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- First Launch ---" -ForegroundColor Cyan
Write-Host " Start SteamVR BEFORE launching Techtonica." -ForegroundColor White
Write-Host " Launch the game from Steam as normal - BepInEx loads the mod." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT: After installing, restart the game once. Let it load to" -ForegroundColor Yellow
Write-Host " the main menu, then close and relaunch. The mod won't activate" -ForegroundColor Yellow
Write-Host " on the very first run - this is documented behavior." -ForegroundColor Yellow

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host " In SteamVR: Settings -> Dashboard:" -ForegroundColor White
Write-Host " 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray

Write-Host ""
Write-Host "--- Controls ---" -ForegroundColor Cyan
Write-Host " Open SteamVR Dashboard -> Controller Bindings -> 'Techtonica VR'" -ForegroundColor White
Write-Host " Default bindings exist for Index Knuckles and Oculus Touch." -ForegroundColor Gray
Write-Host " Quest 3 controllers map to the Touch bindings." -ForegroundColor Gray

Write-Host ""
Write-Host "--- Disabling/Re-enabling the Mod ---" -ForegroundColor Cyan
Write-Host " Edit BepInEx\config\de.xenira.techtonicavr.cfg:" -ForegroundColor White
Write-Host " set 'Enabled = false' under [General] to play flat without uninstall." -ForegroundColor Gray

Write-Host ""
Write-Host " Dig deep. Automate everything. Atropos has secrets." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Techtonica folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

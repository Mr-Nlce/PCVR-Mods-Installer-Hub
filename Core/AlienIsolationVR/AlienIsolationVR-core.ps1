# ============================================================
# Alien: Isolation - MotherVR + GRAND VR Mod Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Alien: Isolation VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Alien Isolation"
$GAME_EXE = "AI.exe"
$MOTHERVR_REPO = "Nibre/MotherVR"
$MOTHERVR_URL = "https://github.com/Nibre/MotherVR/releases/download/0.8.1/MotherVR.0.8.1.zip"
$MOTHERVR_VERSION = "0.8.1"
$MOTHERVR_ASSET = "MotherVR.0.8.1.zip"
$GRAND_URL = "https://alienisolationvr.com/downloads/click.php?id=GRAND-Release.zip"
$GRAND_VERSION = ''

function Get-GrandVersionFromText {
 param([string]$Text)
 if (-not $Text) { return '' }
 if ($Text -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { return ('v' + $matches[1]) }
 if ($Text -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { return ('v' + $matches[1]) }
 if ($Text -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { return ('v' + $matches[1]) }
 return ''
}

function Get-GrandPublishedVersion {
 try {
  $page = Invoke-WebRequest -Uri 'https://www.alienisolationvr.com/' -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
  return (Get-GrandVersionFromText -Text ([string]$page.Content))
 } catch { return '' }
}

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host " Alien: Isolation - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " MotherVR + GRAND (latest)" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries { param($sp)
 $libs=@($sp); $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object {
 $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}
function Test-IsAdmin {
 $id = [Security.Principal.WindowsIdentity]::GetCurrent()
 return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Test-IsWindows11 { return ([System.Environment]::OSVersion.Version.Build -ge 22000) }

# Admin check
Write-Header
if (-not (Test-IsAdmin)) {
 Write-Warn "This installer needs to run as Administrator to apply the Windows 11 registry fix."
 Write-Host " Right-click START_INSTALLER.bat -> Run as administrator" -ForegroundColor Yellow
 Pause-User "Press Enter to exit."; exit 1
}
Write-OK "Running as Administrator."

# STEP 1: Locate game
Write-Step 1 4 "Locating Alien: Isolation"
$gamePath = $null
$sp = Get-SteamPath
if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; Write-OK "Found: $gamePath"; break }
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "214490" -SteamFolderNames @("Alien Isolation") }
if (-not $gamePath) {
 Write-Warn "Not found automatically. Enter the game folder (must contain AI.exe):"
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path(Join-Path $r $GAME_EXE)){$gamePath=$r;Write-OK "Path set: $gamePath"}else{Write-Fail "AI.exe not found: $r"}
 }
}

# STEP 2: Download
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gamePath -ModFile "dxgi.dll"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 4 "Downloading"
$GRAND_VERSION = Get-GrandPublishedVersion
$tmp = Join-Path $env:TEMP "AIVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null
$mvrZip = Join-Path $tmp "MotherVR.zip"
$grandZip = Join-Path $tmp "GRAND.zip"
$failed = @()

# MotherVR's newest public build is currently a prerelease. Resolve the
# newest release asset live so this installer cannot remain pinned if Nibre
# publishes another build; the reviewed 0.8.1 URL remains the offline/API
# fallback. GRAND's publisher URL already resolves its current package.
$motherRelease = Resolve-GitHubReleaseAsset -Repo $MOTHERVR_REPO -IncludePrerelease $true `
    -AssetPatterns @('(?i)^MotherVR.*\.zip$') -FallbackUrl $MOTHERVR_URL `
    -FallbackTag $MOTHERVR_VERSION -FallbackAssetName $MOTHERVR_ASSET
$MOTHERVR_URL = [string]$motherRelease.Url
$MOTHERVR_VERSION = [string]$motherRelease.Tag
$MOTHERVR_ASSET = [string]$motherRelease.AssetName
if ($motherRelease.Resolved) { Write-Info "GitHub resolved MotherVR $MOTHERVR_VERSION ($MOTHERVR_ASSET)." }
elseif ($motherRelease.ReleaseFound) { Write-Warn $motherRelease.Error }
else { Write-Warn "MotherVR live release lookup unavailable; using reviewed $MOTHERVR_VERSION fallback." }

$r = Invoke-DownloadOrFallback -Url $MOTHERVR_URL -Destination $mvrZip `
        -Label "MotherVR $MOTHERVR_VERSION" `
        -ManualUrl $motherRelease.PageUrl `
        -Instructions "Download '$MOTHERVR_ASSET' from the current GitHub release. Place it at '$mvrZip' and choose Retry." `
        -SkipMessage "Skipped - MotherVR is missing; VR mode will NOT work (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "MotherVR" }

$r = Invoke-DownloadOrFallback -Url $GRAND_URL -Destination $grandZip `
        -Label "GRAND-MotherVR (latest)" `
        -ManualUrl "https://www.alienisolationvr.com/" `
        -Instructions "Download 'GRAND-Release.zip' from the alienisolationvr.com page that just opened. Place it at '$grandZip' and choose Retry." `
        -SkipMessage "Skipped - GRAND hands/QoL overhaul not installed (MotherVR alone will still work, just without hands)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "GRAND" }

# STEP 3: Install
Write-Step 3 4 "Installing"

# MotherVR releases may wrap their payload in one version-named root folder.
if ("MotherVR" -notin $failed) {
 try {
 $mvrExtract = Join-Path $tmp "MotherVR"
 Expand-Archive -Path $mvrZip -DestinationPath $mvrExtract -Force
 # Unwrap a single release root folder when present.
 $root = Get-ChildItem -Path $mvrExtract -Directory | Select-Object -First 1
 $payload = if ($root) { $root.FullName } else { $mvrExtract }
 # Copy only DLL files into game root
 Get-ChildItem -Path $payload -File -Filter "*.dll" | ForEach-Object {
 Copy-Item $_.FullName (Join-Path $gamePath $_.Name) -Force
 Write-Info "Installed: $($_.Name)"
 }
 if (Test-Path -LiteralPath "$gamePath\dxgi.dll") { Write-OK "MotherVR: dxgi.dll OK." }
 else { Write-Fail "dxgi.dll missing after install!"; $failed += "MotherVR" }
 } catch { Write-Fail "MotherVR error: $_"; $failed += "MotherVR" }
}

# GRAND: ZIP structure is flat - AIWin11Fix.reg, grand.ini, XINPUT1_3.dll, readme.txt
# All files except readme go directly into the game folder
if ("GRAND" -notin $failed) {
 try {
 $grandExtract = Join-Path $tmp "GRAND"
 Expand-Archive -Path $grandZip -DestinationPath $grandExtract -Force
 if (-not $GRAND_VERSION) {
  $grandReadme = Get-ChildItem -LiteralPath $grandExtract -File -Filter 'readme*' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($grandReadme) { $GRAND_VERSION = Get-GrandVersionFromText -Text (Get-Content -LiteralPath $grandReadme.FullName -Raw -ErrorAction SilentlyContinue) }
 }
 # Copy every file (except readme.txt) directly into game folder
 Get-ChildItem -Path $grandExtract -File | Where-Object { $_.Name -ne "readme.txt" } | ForEach-Object {
 Copy-Item $_.FullName (Join-Path $gamePath $_.Name) -Force
 Write-Info "Installed: $($_.Name)"
 }
 if (Test-Path -LiteralPath "$gamePath\XINPUT1_3.dll") { Write-OK "GRAND: XINPUT1_3.dll OK." }
 else { Write-Fail "XINPUT1_3.dll missing after install!"; $failed += "GRAND" }
 } catch { Write-Fail "GRAND error: $_"; $failed += "GRAND" }
}

# STEP 4: Windows 11 registry fix (uses AIWin11Fix.reg already in game folder from GRAND)
Write-Step 4 4 "Windows 11 Fix"
$isWin11 = Test-IsWindows11
$win11FixDone = $false
if (-not $isWin11) {
 Write-Info "Windows 10 detected - skipping."
} else {
 $regFile = Join-Path $gamePath "AIWin11Fix.reg"
 if (Test-Path $regFile) {
 $result = Start-Process "regedit.exe" -ArgumentList "/s `"$regFile`"" -Wait -PassThru
 if ($result.ExitCode -eq 0) { Write-OK "Registry fix applied."; $win11FixDone = $true }
 else { Write-Warn "regedit exit code: $($result.ExitCode)" }
 } else { Write-Fail "AIWin11Fix.reg not found (GRAND install may have failed)." }
}

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("MotherVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }
if (("GRAND" -notin $failed) -and $GRAND_VERSION) {
 Save-InstalledStamp -GameDir $gamePath -Version $GRAND_VERSION -HubDir $PSScriptRoot
}

# Summary
Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
if ("MotherVR" -notin $failed) { Write-Host " [x] MotherVR $MOTHERVR_VERSION (dxgi.dll)" -ForegroundColor Green }
else { Write-Host " [ ] MotherVR $MOTHERVR_VERSION -- FAILED" -ForegroundColor Red }
if ("GRAND" -notin $failed) { Write-Host " [x] GRAND (XINPUT1_3.dll + grand.ini)" -ForegroundColor Green }
else { Write-Host " [ ] GRAND -- FAILED" -ForegroundColor Red }
if ($isWin11) {
 if ($win11FixDone) { Write-Host " [x] Windows 11 Registry Fix (AIWin11Fix.reg)" -ForegroundColor Green }
 else { Write-Host " [ ] Windows 11 Registry Fix -- FAILED" -ForegroundColor Red }
}
Write-Host ""
Pause-User "Press Enter to continue..."

Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Before You Play" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " THEATRE MODE - must be OFF:" -ForegroundColor White
Write-Host " SteamVR -> Settings -> Dashboard" -ForegroundColor Gray
Write-Host " -> 'Present Non-VR Applications on Theater Screen' -> OFF" -ForegroundColor Gray
Write-Host ""
Write-Host " CONTROLS:" -ForegroundColor White
Write-Host " Recenter Left Grip + Right Grip" -ForegroundColor Gray
Write-Host " Flashlight Right controller near head + Interact" -ForegroundColor Gray
Write-Host " D-pad (minigames) Left Grip + Left Joystick" -ForegroundColor Gray
Write-Host " More info: https://www.alienisolationvr.com" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Launch Alien: Isolation via Steam" -ForegroundColor White
Write-Host " 2) A message appears regarding MotherVR - confirm it" -ForegroundColor White
Write-Host " 3) In main menu: Options -> MotherVR -> VR Runtime" -ForegroundColor White
Write-Host " Choose 'Oculus' or 'SteamVR' depending on your headset" -ForegroundColor Gray
Write-Host " 4) If SteamVR selected: start SteamVR, then restart the game" -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Don't run. Don't breathe. It hunts by sound." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Alien: Isolation folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

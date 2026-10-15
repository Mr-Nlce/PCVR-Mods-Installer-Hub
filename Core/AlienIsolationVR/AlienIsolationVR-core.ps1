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
 if ($Text -match '(?i)Test Build\s+v?(\d+\.\d+\.\d+)') { return ('v' + $matches[1]) }
 # The publisher README contains the entire version history. An earlier
 # pattern matched a stray GRAND mention near v0.5.2 before the later v0.6.1
 # entry, so a new install was permanently recorded as an older release.
 $history=[regex]::Matches($Text,'(?im)^\s*-\s*v(\d+\.\d+\.\d+)\s*:')
 if($history.Count){
  $newest=$null
  foreach($item in $history){$candidate=[version]$item.Groups[1].Value;if($null -eq $newest -or $candidate -gt $newest){$newest=$candidate}}
  return ('v'+$newest.ToString())
 }
 if ($Text -match '(?im)\bGRAND[^\r\n<]{0,60}\bv?(\d+\.\d+\.\d+)') { return ('v' + $matches[1]) }
 return ''
}

function Get-GrandPublishedVersion {
 try {
  $page = Invoke-WebRequest -Uri 'https://www.alienisolationvr.com/' -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
  return (Get-GrandVersionFromText -Text ([string]$page.Content))
 } catch { return '' }
}

function Get-InstalledFileSha256 {
 param([string]$Path)
 $stream = [IO.File]::OpenRead($Path)
 try {
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') }
  finally { $sha.Dispose() }
 } finally { $stream.Dispose() }
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
if ($failed.Count -gt 0) {
 Write-Fail "Both advertised VR components are required. No installation was marked complete."
 Pause-User "Press Enter to exit and retry the missing download..."
 exit 1
}

# STEP 3: Install
Write-Step 3 4 "Installing"
$changed = New-Object 'System.Collections.Generic.List[object]'
try {
 # Verify both selected archives and their functional payloads before the
 # first game file is changed. A prior install's DLL is not proof that the
 # newly selected archive installed successfully.
 $mvrExtract = Join-Path $tmp 'MotherVR'
 $grandExtract = Join-Path $tmp 'GRAND'
 foreach ($archive in @(@($mvrZip,$mvrExtract),@($grandZip,$grandExtract))) {
  $safety = Test-ZipArchiveEntrySafety -ArchivePath $archive[0] -DestinationFolder $archive[1]
  if (-not $safety.Inspectable -or -not $safety.Safe -or $safety.EntryCount -eq 0) { throw "Unsafe or unreadable VR archive: $($archive[0])" }
  Expand-Archive -LiteralPath $archive[0] -DestinationPath $archive[1] -Force -ErrorAction Stop
 }
 $motherHook = Get-ChildItem -LiteralPath $mvrExtract -Recurse -File -Filter 'dxgi.dll' -ErrorAction Stop | Select-Object -First 1
 if (-not $motherHook) { throw 'MotherVR archive does not contain dxgi.dll.' }
 $motherFiles = @(Get-ChildItem -LiteralPath $motherHook.DirectoryName -File -Filter '*.dll' -ErrorAction Stop)
 $grandFiles = @(Get-ChildItem -LiteralPath $grandExtract -File -ErrorAction Stop | Where-Object { $_.Name -ine 'readme.txt' })
 foreach ($required in @('XINPUT1_3.dll','grand.ini')) {
  if (-not @($grandFiles | Where-Object { $_.Name -ieq $required }).Count) { throw "GRAND archive does not contain $required." }
 }
 $grandReadme = Get-ChildItem -LiteralPath $grandExtract -File -Filter 'readme*' -ErrorAction SilentlyContinue | Select-Object -First 1
 if ($grandReadme) {
  $archiveVersion = Get-GrandVersionFromText -Text (Get-Content -LiteralPath $grandReadme.FullName -Raw -ErrorAction Stop)
  if ($archiveVersion) { $GRAND_VERSION = $archiveVersion }
 }
 if (-not $GRAND_VERSION) { throw 'The selected GRAND package has no trackable version.' }
 $assets = @($motherFiles) + @($grandFiles)
 if (@($assets | Group-Object Name | Where-Object Count -gt 1).Count) { throw 'The selected VR packages contain conflicting destination filenames.' }
 $index = 0
 foreach ($asset in $assets) {
  $dest = Join-Path $gamePath $asset.Name
  $backup = Join-Path $tmp ("original-$index-$($asset.Name)")
  $existed = Test-Path -LiteralPath $dest -PathType Leaf
  if ($existed) { Copy-Item -LiteralPath $dest -Destination $backup -Force -ErrorAction Stop }
  $changed.Add([pscustomobject]@{ Source=$asset.FullName; Destination=$dest; Backup=$backup; Existed=$existed }) | Out-Null
  $index++
 }
 foreach ($item in $changed) {
  Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force -ErrorAction Stop
  if ((Get-InstalledFileSha256 -Path $item.Source) -ne
      (Get-InstalledFileSha256 -Path $item.Destination)) {
   throw "Installed file differs from the selected archive: $($item.Destination)"
  }
  Write-Info "Installed: $(Split-Path -Leaf $item.Destination)"
 }
 Write-OK 'MotherVR and GRAND publisher files verified in the game folder.'
} catch {
 Write-Fail "VR file installation failed: $_"
 $rollbackFailed = $false
 foreach ($item in $changed) {
  try {
   if ($item.Existed) { Copy-Item -LiteralPath $item.Backup -Destination $item.Destination -Force -ErrorAction Stop }
   elseif (Test-Path -LiteralPath $item.Destination) { Remove-Item -LiteralPath $item.Destination -Force -ErrorAction Stop }
  } catch { $rollbackFailed = $true; Write-Fail "Could not restore $($item.Destination): $_" }
 }
 if ($rollbackFailed) { Write-Warn 'Inspect the game folder before retrying; some original files could not be restored.' }
 Pause-User 'Press Enter to exit without marking installation complete.'
 exit 1
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
if ($isWin11 -and -not $win11FixDone) {
 Write-Fail 'The required Windows 11 registry step failed. No installation was marked complete.'
 Pause-User 'Press Enter to exit and retry after checking the installer log.'
 exit 1
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
Start-Sleep -Milliseconds 500
$changedAfterCopy = @($changed | Where-Object {
 -not (Test-Path -LiteralPath $_.Destination -PathType Leaf) -or
 (Get-InstalledFileSha256 -Path $_.Source) -ne (Get-InstalledFileSha256 -Path $_.Destination)
})
if ($changedAfterCopy.Count -gt 0 -or
    -not (Test-Path -LiteralPath (Join-Path $gamePath 'dxgi.dll') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $gamePath 'XINPUT1_3.dll') -PathType Leaf) -or
    -not $GRAND_VERSION) {
 Write-Fail 'A required VR file changed or disappeared after copy. No installation was marked complete.'
 foreach ($item in $changed) {
  try {
   if ($item.Existed) { Copy-Item -LiteralPath $item.Backup -Destination $item.Destination -Force -ErrorAction Stop }
   elseif (Test-Path -LiteralPath $item.Destination) { Remove-Item -LiteralPath $item.Destination -Force -ErrorAction Stop }
  } catch { Write-Fail "Could not restore $($item.Destination): $_" }
 }
 Pause-User 'Press Enter to exit and retry setup.'
 exit 1
}
$grandEvidence = Join-Path $gamePath '.pcvrhub_grand_version_evidence'
$grandHash = Get-InstalledFileSha256 -Path (Join-Path $gamePath 'XINPUT1_3.dll')
[IO.File]::WriteAllText($grandEvidence,($GRAND_VERSION+"`n"+$grandHash),[Text.UTF8Encoding]::new($false))
Save-InstalledStamp -GameDir $gamePath -Version $GRAND_VERSION -HubDir $PSScriptRoot
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

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

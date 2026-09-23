# ============================================================
# Scrap Mechanic - Native VR Installer
# ============================================================
# Three install paths:
# 1. CURRENT: latest stable GitHub release against the live Steam game.
# 2. CONFIRMED: the newest pairing verified during an update round, frozen
#    as a complete separate depot so a later game update cannot break it.
# 3. LEGACY: the original pre-1.0 build and v1.17.0 fallback, unchanged.
# All routes have separate game roots, path records and launchers.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Scrap Mechanic VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME     = "Scrap Mechanic"
$GAME_EXE      = "Release\ScrapMechanic.exe"
$GAME_EXE_LEAF = "ScrapMechanic.exe"
$MOD_FILE      = "Release\scrap_native_vr.addon64"
$CURRENT_MOD_FILE = "Release\smvr_native_vr_v1.addon64"
$LAUNCH_PS1    = "NativeVR\Start-NativeVR.ps1"
$LAUNCH_BAT    = "NativeVR\Start Scrap Mechanic VR.bat"

$REPO                  = "21Suspect/Scrap-Mechanic-Native-VR"
$INFO_URL              = "https://github.com/$REPO"
$CURRENT_RELEASES_API  = "https://api.github.com/repos/$REPO/releases/latest"
$CURRENT_INSTALLER     = "ScrapMechanicVR-Installer.exe"
$CURRENT_FALLBACK_TAG  = "v1.4.8"
$CURRENT_FALLBACK_ASSET = "ScrapMechanicVR-Installer-1.4.8.exe"
$CURRENT_FALLBACK_URL  = "https://github.com/$REPO/releases/download/$CURRENT_FALLBACK_TAG/$CURRENT_FALLBACK_ASSET"
$CONFIRMED_GAME_VERSION = "1.0.5"
$CONFIRMED_GAME_BUILD   = "24529696"
$CONFIRMED_MOD_VERSION  = "v1.4.8"
$CONFIRMED_ASSET_NAME   = "ScrapMechanicVR-Installer-1.4.8.exe"
$CONFIRMED_ASSET_URL    = "https://github.com/$REPO/releases/download/v1.4.8/$CONFIRMED_ASSET_NAME"
$LEGACY_MOD_VERSION     = "v1.17.0"
# Source archive - contains payload\ (the VR files) which mirrors the
# game folder tree. We copy payload\* into the game root.
$SOURCE_URL  = "https://github.com/$REPO/archive/refs/tags/$LEGACY_MOD_VERSION.zip"

# Steam depot - EXACTLY THE BUILD THE MOD SUPPORTS. Depot 387993 is
# the content depot holding the exe; 387992 is data only (no exe).
#
# THIS IS WHERE THE FAULT WAS: the manifest of the NEWEST content
# build used to stand here. But the mod v1.17.0 states in its release
# notes that it "supports Scrap Mechanic Steam build 22163681 only" -
# its binaries are built against that build's exe. On any other build
# it does not run, and because our installer copies the payload by
# hand, the patcher's own build check is bypassed: it looks installed
# and still does not work.
#
# Timeline, checked on SteamDB: build 22163681 is "Hotfix 0.7.4" from
# 2 March 2026 and was the LIVE build until 24 July 2026. The mod came
# out on 23 July - one day before "Drilling Thunder" replaced the
# build. So anyone who set the mod up before 24 July, or who owns the
# matching build, is fine; on today's Steam state it is not.
#
# !!! THE BUILD CONSISTS OF TWO DEPOTS, BOTH ARE REQUIRED !!!
# Previously only 387993 was downloaded - the Win64 depot with the
# exe, around 2 GB. The game data (Data\, Survival\, Challenges\ ...)
# lives in the second depot 387992. Result: a folder of ~2 GB instead
# of ~5 GB, exe present, and the game aborts with "Failed to find game
# data directory".
# On SteamDB, build 22163681 lists EXACTLY THESE TWO depots under
# "Changed files in this update", with these manifests.
$DEPOT_APPID = "387990"
$CONFIRMED_DEPOTS = @(
    @{ Id = "387992"; Manifest = "3609790474044595719"; Label = "Scrap Mechanic Data" },
    @{ Id = "387993"; Manifest = "8377913301090149728"; Label = "Windows 64-bit (with the exe)" }
)
$LEGACY_SUPPORTED_BUILD = "22163681"
# Order: data first, then the exe depot - so the folder is complete
# after the last step and the exe check runs on the finished tree.
$LEGACY_DEPOTS = @(
    @{ Id = "387992"; Manifest = "4615519036154398529"; Label = "Scrap Mechanic Data" },
    @{ Id = "387993"; Manifest = "1969835134401920665"; Label = "Windows 64-bit (with the exe)" }
)
foreach ($d in $CONFIRMED_DEPOTS) { $d.Command = "download_depot $DEPOT_APPID $($d.Id) $($d.Manifest)" }
foreach ($d in $LEGACY_DEPOTS) { $d.Command = "download_depot $DEPOT_APPID $($d.Id) $($d.Manifest)" }

$DEFAULT_PARENT = "C:\Games"
$CONFIRMED_DEFAULT_PATH = Join-PathLexical $DEFAULT_PARENT "Scrap Mechanic $CONFIRMED_GAME_VERSION VR"
$LEGACY_DEFAULT_PATH    = Join-PathLexical $DEFAULT_PARENT "Scrap Mechanic VR"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host "  Scrap Mechanic - Native VR Installer" -ForegroundColor Cyan
 Write-Host "  by 21Suspect | native OpenXR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
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
 param($sp)
 $libs = New-Object System.Collections.Generic.List[string]
 if (-not $sp) { return $libs }
 $libs.Add($sp)
 $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
  try {
   foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s*"([^"]+)"')) {
    $p = $m.Groups[1].Value -replace '\\\\','\'
    if ($p -and (Test-Path -LiteralPath $p)) { $libs.Add($p) }
   }
  } catch {}
 }
 return $libs
}

function Find-GamePath {
 $remembered = Get-PCVRRememberedGameFolder -ProbeFiles @($GAME_EXE) -StateNames @('installed_path_current','user_located')
 if ($remembered) { return $remembered }
 foreach ($lib in (Get-SteamLibraries (Get-SteamPath))) {
  $cand = "$lib\steamapps\common\$GAME_NAME"
  # Lexical: $cand is built from a library path that may be on a drive
  # that no longer exists.
  try { if (Test-Path -LiteralPath (Join-PathLexical $cand $GAME_EXE)) { return $cand } } catch {}
 }
 return $null
}

# Resolve the exact stable release asset the author's Hub entry tracks. An
# Current follows the author's moving stable release. A changed digest or file
# size never blocks it; the author installer's own completed marker is the
# proof used before the Hub records success. Frozen depot routes opt into their
# exact pinned package separately.
function Get-CurrentRelease {
 try {
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
  $headers = @{ "User-Agent" = "PCVR-Mods-Hub"; "Accept" = "application/vnd.github+json" }
  $rel = Invoke-RestMethod -Uri $CURRENT_RELEASES_API -Headers $headers -TimeoutSec 25 -ErrorAction Stop
  # The author changed from a stable filename to versioned assets in v1.4.8.
  # Accept both forms, but never an unrelated executable from the release.
  $asset = @($rel.assets | Where-Object { [string]$_.name -match '(?i)^ScrapMechanicVR-Installer(?:-[0-9][0-9A-Za-z.\-]*)?\.exe$' } | Select-Object -First 1)[0]
  if ($asset -and $asset.browser_download_url) {
    return [pscustomobject]@{ Tag=[string]$rel.tag_name; Url=[string]$asset.browser_download_url; AssetName=[string]$asset.name }
  }
  Write-Warn "The latest release did not contain the author installer."
 } catch {
  Write-Warn "The latest release could not be checked: $($_.Exception.Message)"
 }
 return [pscustomobject]@{ Tag=$CURRENT_FALLBACK_TAG; Url=$CURRENT_FALLBACK_URL; AssetName=$CURRENT_FALLBACK_ASSET }
}

function Write-CurrentLauncher {
 param([string]$gamePath)
 $nativeDir = Join-Path $gamePath "NativeVR"
 try { New-Item -ItemType Directory -Path $nativeDir -Force | Out-Null } catch { return $null }
 $ps1Path = Join-Path $nativeDir "Start-HubVR.ps1"
 $ps1Body = @'
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manager = Join-Path $gameRoot 'ScrapMechanicVR-Installer.exe'
if (-not (Test-Path -LiteralPath $manager -PathType Leaf)) {
    [void][Windows.Forms.MessageBox]::Show('The Scrap Mechanic VR manager is missing. Run the Hub installer again.','Scrap Mechanic VR')
    [void](Read-Host 'Press Enter to close')
    exit 1
}
$stateRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ScrapMechanicVR-Chapter2'
New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $stateRoot 'installed-game.txt'), $gameRoot, (New-Object Text.UTF8Encoding $false))
Start-Process -FilePath $manager -ArgumentList '--start' -WorkingDirectory $gameRoot
'@
 try {
  [IO.File]::WriteAllText($ps1Path, $ps1Body, (New-Object Text.UTF8Encoding $false))
  $managePs1Path = Join-Path $nativeDir 'Manage-HubVR.ps1'
  $managePs1Body = $ps1Body.Replace("Start-Process -FilePath `$manager -ArgumentList '--start' -WorkingDirectory `$gameRoot", "Start-Process -FilePath `$manager -WorkingDirectory `$gameRoot")
  [IO.File]::WriteAllText($managePs1Path, $managePs1Body, (New-Object Text.UTF8Encoding $false))
 } catch { return $null }
 $batPath = Join-Path $gamePath $LAUNCH_BAT
 $batBody = @(
  '@echo off',
  'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-HubVR.ps1"'
 ) -join "`r`n"
 try {
  Set-Content -LiteralPath $batPath -Value $batBody -Encoding ASCII -Force
  $manageBat = Join-Path $nativeDir 'Manage-HubVR.bat'
  Set-Content -LiteralPath $manageBat -Value "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Manage-HubVR.ps1`"" -Encoding ASCII -Force
  return $batPath
 } catch { return $null }
}

function Set-ManagedGameSelection {
 param([string]$gamePath)
 try {
  $stateRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ScrapMechanicVR-Chapter2'
  New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $stateRoot 'installed-game.txt'), $gamePath, (New-Object Text.UTF8Encoding $false))
  return $true
 } catch { return $false }
}

function Save-CurrentHubState {
 param([string]$gamePath, [string]$batPath, [string]$version, [string]$PathFile = '.installed_path', [string]$VersionFile = '.installed_version')
 try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot $PathFile), $gamePath, (New-Object Text.UTF8Encoding $false)) } catch {}
 # .launch_exe remains the current-Steam compatibility handoff. Depot launch
 # routes are resolved from their own roots and catalog fields.
 if ($PathFile -eq '.installed_path' -and $batPath -and (Test-Path -LiteralPath $batPath)) {
  try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.launch_exe'), $batPath, (New-Object Text.UTF8Encoding $false)) } catch {}
 }
 try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot $VersionFile), $version, (New-Object Text.UTF8Encoding $false)) } catch {}
 $stateName = switch ($PathFile) {
  '.installed_path_depot' { 'installed_path_depot' }
  '.installed_path_legacy_depot' { 'installed_path_legacy_depot' }
  default { 'installed_path_current' }
 }
 [void](Save-HubRememberedGameFolder -GameId 'scrap-mechanic-vr' -Title $GAME_NAME -GameDir $gamePath -StateName $stateName)
 Save-InstalledStamp -GameDir $gamePath -Version $version
}

function Get-CurrentManagedPatchVersion {
 param([string]$gamePath)
 try {
  $normalized = [IO.Path]::GetFullPath($gamePath).TrimEnd([char[]]@('\','/')).ToLowerInvariant()
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $keyBytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized)) }
  finally { $sha.Dispose() }
  $key = ([BitConverter]::ToString($keyBytes)).Replace('-','').Substring(0,16)
  $stateRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ScrapMechanicVR-Chapter2'
  $statePath = Join-Path $stateRoot ("install-state-$key.json")
  if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) { return $null }
  $state = Get-Content -LiteralPath $statePath -Raw -ErrorAction Stop | ConvertFrom-Json
  if ($state.patchVersion) { return [string]$state.patchVersion }
 } catch {}
 return $null
}

function Remove-CurrentStaging {
 param([string]$tempDir)
 try { if ($tempDir -and (Test-Path -LiteralPath $tempDir)) { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
}

function Install-ManagedVersion {
 param(
  [string]$GamePath,
  $Release,
  [switch]$LocateCurrent,
  [string]$PathFile = '.installed_path',
  [string]$VersionFile = '.installed_version',
  [string]$ShortcutName = 'Scrap Mechanic VR',
  [string]$RouteLabel = 'Current Steam version',
  [int]$DownloadStep = 2,
  [int]$TotalSteps = 3
 )
 if ($LocateCurrent) {
  Write-Step 1 $TotalSteps "Locating the current Steam version"
  $GamePath = Find-GamePath
 }
 if (-not $GamePath) {
  Write-Warn "The current Steam installation was not found."
  try { Start-Process "steam://install/$DEPOT_APPID" } catch {}
  Pause-User "Install Scrap Mechanic through Steam, then press Enter to check again..."
  $GamePath = Find-GamePath
 }
 while (-not $GamePath) {
  Write-Host " Enter the Scrap Mechanic folder that contains Release\ScrapMechanic.exe:" -ForegroundColor White
  $manual = (Read-Host " Path").Trim().Trim('"')
  if ($manual -and (Test-Path -LiteralPath (Join-PathLexical $manual $GAME_EXE))) { $GamePath = $manual }
  else { Write-Fail "Release\ScrapMechanic.exe was not found there." }
 }
 Write-OK "$RouteLabel found: $GamePath"

 Write-Step $DownloadStep $TotalSteps "Downloading the current author installer"
 if (-not $Release) { $Release = Get-CurrentRelease }
 $tempDir = Join-Path $env:TEMP ("ScrapVRCurrent_" + [System.IO.Path]::GetRandomFileName())
 New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
 $assetName = if ($Release.AssetName) { [string]$Release.AssetName } else { $CURRENT_INSTALLER }
 $downloaded = Join-Path $tempDir $assetName
 $downloadArgs = @{
  Urls=@($Release.Url); Destination=$downloaded; Label='Scrap Mechanic VR author installer'
  ManualUrl="$INFO_URL/releases"
  Instructions="Download $assetName from the stable release and place it in the opened folder, then choose Retry."
  SkipMessage='Skipped - the VR mod was not installed.'
 }
 # Current and depot packages are accepted from their publisher URLs without
 # a stored fingerprint gate. The depot route stays pinned by its exact tag.
 $null = Invoke-SafeDownload @downloadArgs
 if (-not (Test-Path -LiteralPath $downloaded)) {
  Remove-CurrentStaging -tempDir $tempDir
  Write-Fail "No installer was downloaded."
  return $false
 }
 $manager = Join-Path $GamePath $CURRENT_INSTALLER
 Write-OK "Author installer is ready."
 Write-Host ""
 Write-Host " The author's installer opens next. Click " -NoNewline -ForegroundColor White
 Write-Host " Install VR Mod " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
 Write-Host "and approve its Windows prompt." -ForegroundColor White
 Write-Host " Close that window after it reports a verified installation; this setup" -ForegroundColor Gray
 Write-Host " then connects the result to the Hub." -ForegroundColor Gray
 if (-not (Set-ManagedGameSelection -gamePath $GamePath)) {
  Write-Fail "The selected game path could not be handed to the author installer. Nothing was started."
  Remove-CurrentStaging -tempDir $tempDir
  return $false
 }
 Pause-User "Press Enter to open the author installer..."
 # Run from staging first. Only after the author confirms that THIS release
 # is actually installed do we replace the persistent manager in the game
 # root. Cancelling an update therefore cannot replace a working older
 # launcher with a newer launcher that rejects the older payload hashes.
 try { $null = Start-Process -FilePath $downloaded -WorkingDirectory $tempDir -Wait -PassThru -ErrorAction Stop }
 catch { Write-Fail "The author installer could not be started: $_"; Remove-CurrentStaging -tempDir $tempDir; return $false }

 Write-Step ($DownloadStep + 1) $TotalSteps "Connecting this version to the Hub"
 if (-not (Test-Path -LiteralPath (Join-Path $GamePath $CURRENT_MOD_FILE))) {
  Write-Warn "The current VR marker was not found. The author installer may have been closed without installing."
  Write-Info "No VR Ready state was written. Run this setup again when you want to continue."
  Remove-CurrentStaging -tempDir $tempDir
  return $false
 }
 $managedPatch = Get-CurrentManagedPatchVersion -gamePath $GamePath
 $managedNumber = if ($managedPatch) { [regex]::Match($managedPatch, '\d+(?:\.\d+)+').Value } else { '' }
 $releaseNumber = [regex]::Match([string]$Release.Tag, '\d+(?:\.\d+)+').Value
 if (-not $managedNumber) {
  Write-Warn "The VR marker exists, but the author's managed install-state is missing."
  Write-Info "The Hub will not replace the launcher or claim a verified version. Use Install VR Mod in the author manager."
  Remove-CurrentStaging -tempDir $tempDir
  return $false
 }
 if ($managedNumber -ne $releaseNumber) {
  Write-Warn "The author manager still reports version $managedNumber; $($Release.Tag) was not installed."
  Write-Info "The existing version and its launcher were left untouched."
  Remove-CurrentStaging -tempDir $tempDir
  return $false
 }
 try { Copy-Item -LiteralPath $downloaded -Destination $manager -Force -ErrorAction Stop }
 catch { Write-Fail "The verified author installer could not be saved in the game folder: $_"; Remove-CurrentStaging -tempDir $tempDir; return $false }
 Write-OK "Verified author manager saved beside the current game."
 $batPath = Write-CurrentLauncher -gamePath $GamePath
 if (-not $batPath) { Write-Fail "The Hub launch route could not be written."; Remove-CurrentStaging -tempDir $tempDir; return $false }
 Save-CurrentHubState -gamePath $GamePath -batPath $batPath -version $Release.Tag -PathFile $PathFile -VersionFile $VersionFile
 Make-Shortcut -gamePath $GamePath -batPath $batPath -ShortcutName $ShortcutName
 Write-OK "$RouteLabel is installed and will be detected as VR Ready."
 Remove-CurrentStaging -tempDir $tempDir
 return $true
}

# ============================================================
# Manual mod install: download the source archive, copy its
# payload\ tree (which mirrors the game folder) into $gamePath,
# and write our own launch bat. Returns the bat path, or $null.
# ============================================================
function Install-ManualMod {
 param([string]$gamePath)

 if (-not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE))) {
  Write-Fail "'$GAME_EXE' not found in $gamePath - cannot install the VR files here."
  return $null
 }

 $tempDir = Join-Path $env:TEMP ("ScrapVR_" + [System.IO.Path]::GetRandomFileName())
 New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
 $zipPath = Join-Path $tempDir "source.zip"

 Write-Host " Downloading the VR files ($LEGACY_MOD_VERSION source) ..." -ForegroundColor White
 $haveZip = $false
 try {
  Invoke-WebRequest -Uri $SOURCE_URL -OutFile $zipPath -UseBasicParsing -EA Stop
  $haveZip = Test-Path -LiteralPath $zipPath
 } catch { Write-Warn "Automatic download failed: $($_.Exception.Message)" }
 if (-not $haveZip) {
  $fb = Invoke-InstallerFallback `
        -Action "VR source archive download" `
        -Url "$INFO_URL/releases/tag/$LEGACY_MOD_VERSION" `
        -Instructions "Download the $LEGACY_MOD_VERSION source zip from the page that opened, place it at '$zipPath', then choose Retry." `
        -SkipMessage "Skipped - without the VR files nothing can be installed." `
        -DestFile $zipPath -AllowSkip $true
  if ([string]$fb -eq "quit") { return $null }
  $haveZip = Test-Path -LiteralPath $zipPath
 }
 if (-not $haveZip) { Write-Fail "No source archive available - stopping."; return $null }

 # Extract and locate payload\
 $exDir = Join-Path $tempDir "extract"
 try {
  Expand-Archive -LiteralPath $zipPath -DestinationPath $exDir -Force
 } catch {
  Write-Fail "Could not extract the archive: $($_.Exception.Message)"
  return $null
 }
 $payload = Get-ChildItem -LiteralPath $exDir -Recurse -Directory -Filter "payload" -EA SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "Release\scrap_native_vr.addon64") } |
            Select-Object -First 1
 if (-not $payload) {
  Write-Fail "The archive did not contain the expected payload\ folder."
  return $null
 }
 Write-OK "VR files located: $($payload.FullName)"

 # Copy payload\* into the game root (merge over existing folders).
 Write-Host " Copying VR files into: $gamePath" -ForegroundColor White
 $rc = Start-Process -FilePath "robocopy.exe" `
        -ArgumentList @("`"$($payload.FullName)`"", "`"$gamePath`"", "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NP") `
        -Wait -PassThru -WindowStyle Hidden
 if ($rc.ExitCode -ge 8) {
  Write-Warn "robocopy reported issues (code $($rc.ExitCode)); falling back to Copy-Item."
  try { Copy-Item -Path (Join-Path $payload.FullName '*') -Destination $gamePath -Recurse -Force -EA Stop }
  catch { Write-Fail "Copy failed: $($_.Exception.Message)"; return $null }
 }

 # Verify the key files landed
 if (-not (Test-Path -LiteralPath (Join-Path $gamePath $MOD_FILE))) {
  Write-Fail "The VR add-on is not in place: $MOD_FILE"
  return $null
 }
 if (-not (Test-Path -LiteralPath (Join-Path $gamePath $LAUNCH_PS1))) {
  Write-Fail "The launch script is missing: $LAUNCH_PS1"
  return $null
 }
 Write-OK "VR files installed."

 # A scanner often sweeps a moment after the write; the archive is still
 # in the temp folder here, so recovery can unpack it again inside the
 # game folder.
 $avFilesOk = Confirm-PlacedFilesSurvive `
     -Paths @((Join-Path $gamePath $MOD_FILE), (Join-Path $gamePath $LAUNCH_PS1)) `
     -GameDir $gamePath `
     -ArchivePath $zipPath
 if (-not $avFilesOk) {
  Write-Fail "Scrap Mechanic VR could not be restored after the antivirus check."
  Pause-User "Press Enter to exit, then run the installer again."
  return $null
 }

 # Write our own launch bat next to Start-NativeVR.ps1. Start-Process
 # cannot run a .ps1 directly, and the script sets $env:SteamAppId and
 # starts the OpenXR runtime before launching the exe - which is what
 # avoids "SteamAPI Init failed".
 $batPath = Join-Path $gamePath $LAUNCH_BAT
 $batBody = @(
  '@echo off',
  'title Scrap Mechanic VR',
  'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-NativeVR.ps1"'
 ) -join "`r`n"
 try {
  Set-Content -LiteralPath $batPath -Value $batBody -Encoding ASCII -Force
  Write-OK "Launch script created."
 } catch {
  Write-Warn "Could not create the launch bat: $($_.Exception.Message)"
  return $null
 }

 # Clean up temp
 try { Remove-Item -LiteralPath $tempDir -Recurse -Force -EA SilentlyContinue } catch {}
 return $batPath
}

# Record markers the Hub reads. Start in VR runs the launch bat (which
# runs Start-NativeVR.ps1) via .launch_exe - it sets the Steam context
# and starts the OpenXR runtime, then launches the game.
function Write-Markers {
 param([string]$gamePath, [string]$batPath, [string]$PathFile = '.installed_path_legacy_depot')
 try { Set-Content -LiteralPath (Join-Path $PSScriptRoot $PathFile) -Value $gamePath -Encoding UTF8 -Force } catch {}
 try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version_legacy_depot") -Value $LEGACY_MOD_VERSION -Encoding UTF8 -Force } catch {}
 [void](Save-HubRememberedGameFolder -GameId 'scrap-mechanic-vr' -Title $GAME_NAME -GameDir $gamePath -StateName 'installed_path_legacy_depot')
 # ALSO write the durable stamp next to the GAME (2026-08-20).
 # The line above lands inside the Hub folder and is gone as
 # soon as a new Hub build is dropped in; the scan then finds
 # no marker and seeds the CURRENT online tag, swallowing a
 # pending update. The game-side stamp survives that.
 Save-InstalledStamp -GameDir $gamePath -Version $LEGACY_MOD_VERSION
}

# Our own desktop shortcut pointing at the launch bat.
function Make-Shortcut {
 param([string]$gamePath, [string]$batPath, [string]$ShortcutName = 'Scrap Mechanic VR')
 if (-not ($batPath -and (Test-Path -LiteralPath $batPath))) { return }
 $iconExe = Join-Path $gamePath $GAME_EXE
 $workDir = Split-Path -Parent $batPath
 try {
  [void](New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\$ShortcutName.lnk" -TargetPath $batPath -WorkingDir $workDir -IconPath "$iconExe,0")
  Write-OK "Desktop shortcut '$ShortcutName' created."
 } catch {}
}

# Shared end-screen notes.
function Write-EndNotes {
 param([ValidateSet("Current","Confirmed","Legacy")][string]$Mode)
 Write-Host ""
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host "  Setup complete." -ForegroundColor Green
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
 Write-Host "  +======================================================+" -ForegroundColor Yellow
 Write-Host "  |            SET THESE OUTSIDE THE GAME                |" -ForegroundColor Yellow
 Write-Host "  +======================================================+" -ForegroundColor Yellow
 Write-Host ""
 Write-Host "   Active OpenXR runtime   " -NoNewline -ForegroundColor White; Write-Host " Meta Link, VDXR or SteamVR " -ForegroundColor Black -BackgroundColor Yellow
 Write-Host ""
 if ($Mode -eq "Current") {
  Write-Host "  Use" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub. The author's start route checks" -ForegroundColor Gray
  Write-Host "  the active runtime and a connected headset before Steam opens." -ForegroundColor Gray
  Write-Host "  The author's desktop shortcut is an equivalent second route." -ForegroundColor Gray
 } elseif ($Mode -eq "Confirmed") {
  Write-Host "  Use" -NoNewline -ForegroundColor Gray; Write-Host " Start 1.0.5 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the Scrap Mechanic 1.0.5 VR" -ForegroundColor Gray
  Write-Host "  desktop shortcut. This confirmed copy remains separate from Steam updates." -ForegroundColor Gray
 } else {
  Write-Host "  Use" -NoNewline -ForegroundColor Gray; Write-Host " Start Legacy " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the Scrap Mechanic Legacy VR" -ForegroundColor Gray
  Write-Host "  desktop shortcut. Do not launch the legacy copy from Steam:" -ForegroundColor Gray
  Write-Host "  Steam starts the separate current game instead." -ForegroundColor Gray
 }
 Write-Host ""
 Write-Host "  Build it, then climb inside and grab the wrench yourself." -ForegroundColor Magenta
 Write-Host ""
}

# ============================================================
# MENU
# ============================================================
Write-Header
Write-Host " Choose the game version you want to prepare for VR." -ForegroundColor White
Write-Host " All three versions can be installed side by side." -ForegroundColor Gray
Write-Host ""

$currentGame = Find-GamePath
$currentStatus = if ($currentGame -and (Test-Path -LiteralPath (Join-Path $currentGame $CURRENT_MOD_FILE))) { "installed" }
                 elseif ($currentGame) { "game found, VR not installed" }
                 else { "game not found" }
$confirmedStatus = if (Test-Path -LiteralPath (Join-Path $CONFIRMED_DEFAULT_PATH $CURRENT_MOD_FILE) -PathType Leaf) { "installed at $CONFIRMED_DEFAULT_PATH" } else { "not yet installed" }
$legacyStatus = if (Test-Path -LiteralPath (Join-Path $LEGACY_DEFAULT_PATH $MOD_FILE) -PathType Leaf) { "installed at $LEGACY_DEFAULT_PATH" } else { "not yet installed" }

Write-Host "  [1] Current Steam version" -ForegroundColor Cyan
Write-Host "      Latest stable VR release; author-managed install and restore." -ForegroundColor Gray
Write-Host "      Status: $currentStatus" -ForegroundColor $(if ($currentStatus -eq "installed") { "Green" } else { "Gray" })
Write-Host ""
Write-Host "  [2] Last confirmed working version - recommended fallback" -ForegroundColor Cyan
Write-Host "      Scrap Mechanic $CONFIRMED_GAME_VERSION / build $CONFIRMED_GAME_BUILD / Native VR $CONFIRMED_MOD_VERSION." -ForegroundColor Gray
Write-Host "      Status: $confirmedStatus" -ForegroundColor $(if ($confirmedStatus -like 'installed*') { 'Green' } else { 'Gray' })
Write-Host ""
Write-Host "  [3] Original legacy depot" -ForegroundColor Cyan
Write-Host "      Pre-1.0 build $LEGACY_SUPPORTED_BUILD with Native VR $LEGACY_MOD_VERSION." -ForegroundColor Gray
Write-Host "      Status: $legacyStatus" -ForegroundColor $(if ($legacyStatus -like 'installed*') { 'Green' } else { 'Gray' })
Write-Host ""
Write-Host "  [Q] Cancel" -ForegroundColor DarkGray
Write-Host ""
$choice = ""
while ($choice -notin @("1","2","3","q","Q")) { $choice = (Read-Host " Choice").Trim() }
if ($choice -in @("q","Q")) { Write-Info "Cancelled."; exit 0 }
Show-AntivirusNotice
if ($choice -eq "1") {
 if (Install-ManagedVersion -LocateCurrent -ShortcutName 'Scrap Mechanic VR' -RouteLabel 'Current Steam version') {
  Write-EndNotes -Mode Current
 }
 Pause-User "Press Enter to exit."
 exit 0
}

# ============================================================
# DEPOT ROUTES
# ============================================================
$routeKind = if ($choice -eq '2') { 'Confirmed' } else { 'Legacy' }
if ($routeKind -eq 'Confirmed') {
 $DEPOTS = $CONFIRMED_DEPOTS
 $SUPPORTED_BUILD = $CONFIRMED_GAME_BUILD
 $DEFAULT_PATH = $CONFIRMED_DEFAULT_PATH
 $routeModVersion = $CONFIRMED_MOD_VERSION
} else {
 $DEPOTS = $LEGACY_DEPOTS
 $SUPPORTED_BUILD = $LEGACY_SUPPORTED_BUILD
 $DEFAULT_PATH = $LEGACY_DEFAULT_PATH
 $routeModVersion = $LEGACY_MOD_VERSION
}
 Write-Step 1 4 "Steam Depot Download"

 Write-Host " We'll download a separate game copy via Steam Console. Your" -ForegroundColor White
 Write-Host " retail install stays untouched." -ForegroundColor White
 Write-Host ""
 Write-Host " Here's what's about to happen:" -ForegroundColor Cyan
 Write-Host " The game comes in TWO depots and BOTH are needed:" -ForegroundColor White
 foreach ($d in $DEPOTS) { Write-Host "   - $($d.Label)" -ForegroundColor Gray }
 Write-Host " Together about 5 GB. Only the Win64 depot has the exe; the data" -ForegroundColor White
 Write-Host " depot has everything the game loads at startup. With just one of" -ForegroundColor White
 Write-Host " them the game stops at 'Failed to find game data directory'." -ForegroundColor White
 Write-Host ""
 Write-Host " You paste TWO commands into the Steam Console, one after the" -ForegroundColor White
 Write-Host " other - this installer hands you each in turn and brings the" -ForegroundColor White
 Write-Host " console to the front for both." -ForegroundColor White
 Write-Host ""
 if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
  Write-Host " (i) Virtual Desktop users: if the Console doesn't open, open it" -ForegroundColor DarkGray
  Write-Host "     manually (Steam menu bar - View - Console) and paste there." -ForegroundColor DarkGray
  Write-Host ""
 }

 # ---- Both depots, one after the other ----
 # THE CONSOLE IS BROUGHT TO THE FRONT AGAIN IN EVERY PASS.
 # It used to be opened ONCE before the loop. After the first download
 # this window is in the foreground, though, and the second pass began
 # straight at "paste with Ctrl+V" - without ever making the console
 # visible. Anyone pressing Enter to bring it forward would actually be
 # confirming "download finished". So pass 2 now walks step by step
 # exactly like pass 1.
 $steamInstallPath = Get-SteamPath
 $depotDirs = @()
 $step = 0
 foreach ($d in $DEPOTS) {
  $step++
  Write-Host ""
  Write-Host " ============================================================" -ForegroundColor Yellow
  Write-Host " DOWNLOAD $step OF $($DEPOTS.Count) - $($d.Label)" -ForegroundColor Yellow
  Write-Host " ============================================================" -ForegroundColor Yellow
  $clipOk = $false
  try { Set-Clipboard -Value $d.Command -DeferManualFallback; $clipOk = $true } catch {}
  Write-Host ""
# !!! LOOK BEFORE ASKING. Steam keeps a finished depot in
# steamapps\content, so a second run - or a run after a crash - already
# has the files. Prompting first and probing only afterwards sends the
# user to fetch gigabytes that are already on disk. Find-SteamDepotPath
# is cheap and touches nothing.
 $depotProbeLeaf = if ($d.Id -eq '387993') { $GAME_EXE_LEAF } else { '' }
 $script:PreFoundDepot = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $d.Id -GameExe $depotProbeLeaf
if ($script:PreFoundDepot) {
    Write-OK "The depot is already downloaded: $script:PreFoundDepot"
    Write-Info "Skipping the download - nothing to fetch again."
    $depotDirs += $script:PreFoundDepot
    continue
}

  if ($step -eq 1) { Pause-User "Press Enter to open the Steam Console..." }
  else            { Pause-User "Press Enter to bring the Steam Console back to the front..." }
  # Both protocol addresses: depending on the Steam version only one
  # works.
  foreach ($cu in @("steam://open/console", "steam://nav/console")) {
      try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
  }
  Show-PCVRClipboardManualFallback -Text $d.Command
  Write-OK "Steam Console in front."
  Write-Host ""
  if ($clipOk) {
   Write-Host " The command is on your clipboard - click into the console," -ForegroundColor White
   Write-Host " paste with " -NoNewline -ForegroundColor White
   Write-Host " Ctrl+V " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
   Write-Host " and press " -NoNewline -ForegroundColor White
   Write-Host " Enter " -ForegroundColor Black -BackgroundColor Yellow
  } else {
   Write-Warn "Could not copy to the clipboard - type the line below."
  }
  Write-Host ""
  Write-Host " Steam finishes with this line - then come back here:" -ForegroundColor White
  Write-Host "   Depot download complete : ...\depot_$($d.Id) " -ForegroundColor Black -BackgroundColor Yellow
  Write-Host ""
  Write-Host " If the clipboard did not work, the command reads:" -ForegroundColor DarkGray
  Write-Host "   $($d.Command)" -ForegroundColor DarkGray
  Write-Host ""
  Pause-User "Press Enter once THIS download has finished..."

  $probe = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $d.Id -AdditionalSteamRoots @($steamInstallPath))
  $found = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $d.Id -GameExe $depotProbeLeaf -AdditionalSteamRoots @($steamInstallPath)
  if ($found) { Write-OK "Found: $found" }
  else { Write-Warn "Depot not found yet in any Steam library." }
  if (-not $found) {
   $found = Resolve-DepotPath -GameName "$GAME_NAME ($($d.Label))" -DepotCommand $d.Command -GameExe $depotProbeLeaf -ProbePaths $probe -AppId $DEPOT_APPID -DepotId $d.Id -Manifest $d.Manifest
  }
  if (-not $found) { Write-Fail "Depot $($d.Id) not found - cannot continue."; Pause-User "Press Enter to exit..."; exit 1 }
  $depotDirs += $found
 }

 # The exe depot is the base that the data depot is merged into.
 $depotBase = $depotDirs[-1]
 for ($k = 0; $k -lt ($depotDirs.Count - 1); $k++) {
  Write-Host ""
  Write-Host " Merging $($DEPOTS[$k].Label) into the game folder..." -ForegroundColor White
  $rc = Start-Process -FilePath "robocopy.exe" `
        -ArgumentList @("`"$($depotDirs[$k])`"", "`"$depotBase`"", "/E", "/MOVE", "/NFL", "/NDL", "/NJH", "/NJS", "/NP") `
        -NoNewWindow -Wait -PassThru
  if ($rc.ExitCode -ge 8) {
   Write-Warn "robocopy reported code $($rc.ExitCode) - falling back to Copy-Item."
   try { Copy-Item -Path (Join-Path $depotDirs[$k] '*') -Destination $depotBase -Recurse -Force -ErrorAction Stop }
   catch { Write-Fail "Could not merge $($depotDirs[$k]): $_"; Pause-User "Press Enter to exit..."; exit 1 }
  }
  Write-OK "Merged."
 }

 $exeHit = Get-ChildItem -LiteralPath $depotBase -Recurse -Filter $GAME_EXE_LEAF -File -ErrorAction SilentlyContinue | Select-Object -First 1
 if (-not $exeHit) {
  Write-Warn "'$GAME_EXE_LEAF' was not found inside the depot at:"
  Write-Host "   $depotBase" -ForegroundColor Gray
  Write-Host " The download may be incomplete, the manifest wrong, or the" -ForegroundColor Gray
  Write-Host " depot may not contain the executable. Verify on SteamDB." -ForegroundColor Gray
  $c = ""; while ($c -notin @("y","Y","n","N")) { $c = (Read-Host " Move the depot folder as-is anyway? (Y/N)").Trim() }
  if ($c -in @("n","N")) { Write-Info "Aborted by user."; Pause-User "Press Enter to exit..."; exit 0 }
  $depotPath = $depotBase
 } else {
  $exeDir = $exeHit.Directory
  if ($exeDir.Name -ieq "Release") { $depotPath = $exeDir.Parent.FullName }
  else { $depotPath = $exeDir.FullName }
  Write-OK "Game files found: $($exeHit.FullName)"
 }

 # Move to stable folder
 Write-Step 2 4 "Moving game to stable folder"
 $parentOfDepot = Get-PathParentLexical $depotPath
 Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
 Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
 Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
 Write-Host ""
 $routeStateName = if ($routeKind -eq 'Confirmed') { 'installed_path_depot' } else { 'installed_path_legacy_depot' }
 $rememberedTarget = Get-PCVRRememberedGameFolder -ProbeFiles @($GAME_EXE) -StateNames @($routeStateName)
 $userInput = if ($rememberedTarget) { $rememberedTarget } else { (Read-Host " Press Enter to use default, or type a different full path").Trim().Trim('"') }
 if ($rememberedTarget) { Write-OK "Using remembered $routeKind depot location: $rememberedTarget" }
 if (-not $userInput) { $targetPath = $DEFAULT_PATH } else { $targetPath = $userInput }

 $targetParent = Get-PathParentLexical $targetPath
 if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) {
  Write-Fail "The target folder is not writable: $targetParent"
  Pause-User "Press Enter to exit..."; exit 1
 }

 if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
  Write-Warn "A folder already exists at $targetPath"
  Write-Info "Merging the pinned build; saves, NativeVR files, mods and other additional files are preserved."
 }

 try {
  $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "Scrap Mechanic depot build"
  Write-OK "Game installed at: $targetPath"
 } catch {
  Write-Fail "Merge failed: $_"
  Write-Info "The game files are still at: $depotPath"
  $fb = Invoke-InstallerFallback -Action "merge depot files into the install folder" `
      -Instructions "Copy the contents of '$depotPath' into '$targetPath' without deleting additional destination files. Then choose Retry." `
      -SkipMessage "Skipped - game files are still in the depot folder." `
      -DestFolder "$targetPath" -AllowSkip $true
  if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
  if ([string]$fb -eq "retry") { Pause-User "Please re-run the installer once resolved. Press Enter to exit..."; exit 1 }
 }

 try {
  if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) { Remove-Item $parentOfDepot -Force }
 } catch {}

 $gamePath = $targetPath

 # Every independent depot must identify its owning Steam app when the
 # generated launcher starts it outside steamapps\common.
 try {
  [IO.File]::WriteAllText((Join-PathLexical $gamePath 'steam_appid.txt'), $DEPOT_APPID, [Text.Encoding]::ASCII)
  Write-OK "steam_appid.txt created ($DEPOT_APPID)."
 } catch {
  Write-Fail "Could not create steam_appid.txt: $_"
  Pause-User "Press Enter to exit..."; exit 1
 }

 if ($routeKind -eq 'Confirmed') {
  $confirmedRelease = [pscustomobject]@{ Tag=$CONFIRMED_MOD_VERSION; Url=$CONFIRMED_ASSET_URL; AssetName=$CONFIRMED_ASSET_NAME }
  $managed = Install-ManagedVersion -GamePath $gamePath -Release $confirmedRelease `
      -PathFile '.installed_path_depot' -VersionFile '.installed_version_depot' `
      -ShortcutName "Scrap Mechanic $CONFIRMED_GAME_VERSION VR" -RouteLabel "Confirmed $CONFIRMED_GAME_VERSION depot" `
      -DownloadStep 3 -TotalSteps 4
  if (-not $managed) { Pause-User "Press Enter to exit."; exit 1 }
 } else {
  Write-Step 3 4 "Installing the legacy VR files"
  $batPath = Install-ManualMod -gamePath $gamePath
  if (-not $batPath) { Pause-User "Press Enter to exit."; exit 1 }
  Write-Markers -gamePath $gamePath -batPath $batPath
  Make-Shortcut -gamePath $gamePath -batPath $batPath -ShortcutName 'Scrap Mechanic Legacy VR'
 }

 Write-Step 4 4 "All Done!"
 Write-Host " $routeKind depot ready at: $gamePath" -ForegroundColor Yellow
 Write-EndNotes -Mode $routeKind
 Pause-User "Press Enter to exit."
 exit 0

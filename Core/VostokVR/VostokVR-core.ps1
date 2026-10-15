# ============================================================
# Road to Vostok - VR Mod Installer
# ============================================================
#
# Installs the Road to Vostok VR Mod by Blah64.
# Requires Metro Mod Loader to be installed first.
# Downloads vr-mod-full.zip and extracts into the game folder.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Road to Vostok VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Road to Vostok"
$GAME_EXE = "RTV.exe"
$STEAM_APP = "1963610"
$MOD_API = "https://api.github.com/repos/Blah64/Vostok-VR-Mod/releases/latest"
$MOD_FALLBACK_URL = "https://github.com/Blah64/Vostok-VR-Mod/releases/download/v1.4.0/vr-mod-full.zip"
$MOD_FALLBACK_TAG = "v1.4.0"
$MOD_NAME = "Road to Vostok VR Mod"
$INFO_URL = "https://github.com/Blah64/Vostok-VR-Mod"
$MML_VERSION = "3.4.1"
$MML_RELEASE = "https://github.com/ametrocavich/vostok-mod-loader/releases/tag/v3.4.1"
$MML_FILES = @(
 @{ Name="modloader.gd"; Url="https://github.com/ametrocavich/vostok-mod-loader/releases/download/v3.4.1/modloader.gd" },
 @{ Name="override.cfg"; Url="https://github.com/ametrocavich/vostok-mod-loader/releases/download/v3.4.1/override.cfg" }
)

function Test-VostokLoaderSource {
 param([string]$Path,[string]$Name)
 if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return $false}
 try { $content=Get-Content -LiteralPath $Path -Raw -ErrorAction Stop } catch { return $false }
 if($content -match '(?i)^\s*<(html|!doctype)' -or $content -match '(?i)<title>.*(sign in|login)'){return $false}
 if($Name -eq 'modloader.gd'){
  return [bool]($content -match 'Metro Mod Loader' -and $content -match '(?m)^const MODLOADER_VERSION := "3\.4\.1"')
 }
 if($Name -eq 'override.cfg'){
  return [bool]($content -match '(?m)^\[autoload_prepend\]' -and $content -match '(?m)^ModLoader="\*res://modloader\.gd"')
 }
 return $false
}
function Install-VostokLoaderPair {
 param([string]$GamePath,[string]$StagePath,[string]$BackupPath)
 foreach($name in @('modloader.gd','override.cfg')){
  if(-not(Test-VostokLoaderSource -Path (Join-Path $StagePath $name) -Name $name)){return $false}
 }
 [void][IO.Directory]::CreateDirectory($BackupPath)
 $prior=@{}
 foreach($name in @('modloader.gd','override.cfg')){
  $target=Join-Path $GamePath $name
  $prior[$name]=Test-Path -LiteralPath $target -PathType Leaf
  if($prior[$name]){Copy-Item -LiteralPath $target -Destination (Join-Path $BackupPath $name) -Force -ErrorAction Stop}
 }
 [IO.File]::WriteAllText((Join-Path $BackupPath 'prior.json'),($prior | ConvertTo-Json -Compress))
 try {
  foreach($name in @('modloader.gd','override.cfg')){
   Copy-Item -LiteralPath (Join-Path $StagePath $name) -Destination (Join-Path $GamePath $name) -Force -ErrorAction Stop
   if(-not(Test-VostokLoaderSource -Path (Join-Path $GamePath $name) -Name $name)){throw "Loader file did not survive copying: $name"}
  }
  return $true
 } catch {
  foreach($name in @('modloader.gd','override.cfg')){
   $target=Join-Path $GamePath $name
   if($prior[$name]){Copy-Item -LiteralPath (Join-Path $BackupPath $name) -Destination $target -Force -ErrorAction Stop}
   elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
  }
  return $false
 }
}
function Restore-VostokLoaderPair {
 param([string]$GamePath,[string]$BackupPath)
 $marker=Join-Path $BackupPath 'prior.json'
 if(-not(Test-Path -LiteralPath $marker -PathType Leaf)){throw 'The loader rollback record is missing.'}
 $prior=Get-Content -LiteralPath $marker -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
 foreach($name in @('modloader.gd','override.cfg')){
  $target=Join-Path $GamePath $name
  if($prior.$name){Copy-Item -LiteralPath (Join-Path $BackupPath $name) -Destination $target -Force -ErrorAction Stop}
  elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
 }
}
function Restore-VostokVrOverlay {
 param([object[]]$Plan)
 foreach($entry in @($Plan)){
  if($entry.Existed){Copy-Item -LiteralPath $entry.Backup -Destination $entry.Target -Force -ErrorAction Stop}
  elseif(Test-Path -LiteralPath $entry.Target -PathType Leaf){Remove-Item -LiteralPath $entry.Target -Force -ErrorAction Stop}
 }
}
function Install-VostokVrOverlay {
 param([string]$StagePath,[string]$GamePath,[string]$BackupPath)
 $root=[IO.Path]::GetFullPath($StagePath).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
 $game=[IO.Path]::GetFullPath($GamePath).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
 $sources=@(Get-ChildItem -LiteralPath $StagePath -File -Recurse -ErrorAction Stop)
 $override=Join-Path $StagePath 'VR Mod\resources\override.cfg'
 foreach($needed in @('mods\vr-mod.vmz','launch_vr.bat','VR Mod\bin\rtv_vr_injector.exe','rtv_vr_bootstrap.dll','librtv_vr_mod.windows.x86_64.dll')){
  if(-not(Test-Path -LiteralPath (Join-Path $StagePath $needed) -PathType Leaf)){throw "The VR package is missing $needed."}
 }
 if(-not(Test-Path -LiteralPath $override -PathType Leaf)){throw 'The VR package is missing its override.cfg.'}
 $items=New-Object System.Collections.Generic.List[object]
 foreach($source in $sources){
  if(-not $source.FullName.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'The staged payload has an unsafe path.'}
  $relative=$source.FullName.Substring($root.Length)
  if($relative -match '(^|[\\/])\.\.([\\/]|$)' -or [IO.Path]::IsPathRooted($relative)){throw 'The staged payload has an unsafe path.'}
  $items.Add([pscustomobject]@{Source=$source.FullName;Relative=$relative})
 }
 # The publisher's launch script needs this copy at the game root as well.
 $items.Add([pscustomobject]@{Source=$override;Relative='override.cfg'})
 [void][IO.Directory]::CreateDirectory($BackupPath)
 $plan=New-Object System.Collections.Generic.List[object]
 foreach($item in $items){
  $target=[IO.Path]::GetFullPath((Join-Path $GamePath $item.Relative))
  if(-not $target.StartsWith($game,[StringComparison]::OrdinalIgnoreCase)){throw 'A VR target escapes the game folder.'}
  if(Test-Path -LiteralPath $target -PathType Container){throw "A VR file target is a directory: $target"}
  $existing=Test-Path -LiteralPath $target -PathType Leaf
  $backup=Join-Path $BackupPath ([string]$plan.Count)
  if($existing){Copy-Item -LiteralPath $target -Destination $backup -Force -ErrorAction Stop}
  $plan.Add([pscustomobject]@{Source=$item.Source;Target=$target;Existed=$existing;Backup=$backup})
 }
 $copied=0
 try {
  foreach($entry in $plan){
   [void][IO.Directory]::CreateDirectory((Split-Path -Parent $entry.Target))
   Copy-Item -LiteralPath $entry.Source -Destination $entry.Target -Force -ErrorAction Stop
   $copied++
   if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VOSTOK_TEST_FAIL_AFTER_COPY -eq [string]$copied){throw 'Simulated overlay copy failure.'}
   if((Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ine (Get-FileHash -LiteralPath $entry.Source -Algorithm SHA256).Hash){throw "A copied VR file changed: $($entry.Target)"}
  }
  return ,$plan.ToArray()
 } catch {
  Restore-VostokVrOverlay -Plan $plan.ToArray()
  throw
 }
}

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Road to Vostok - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " $MOD_NAME by Blah64" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
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

# The catalog marks this mod as auto-update. Resolve the release and its
# exact vr-mod-full.zip asset at install time; the pinned URL is only the
# last-known fallback when GitHub's API is temporarily unavailable.
function Get-LatestVostokVrRelease {
 try {
  $rel = Invoke-RestMethod -Uri $MOD_API -Headers @{ "User-Agent"="PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
  $asset = $rel.assets | Where-Object { $_.name -ieq "vr-mod-full.zip" } | Select-Object -First 1
  if ($asset -and $asset.browser_download_url -and $rel.tag_name) {
   return @{ Url=[string]$asset.browser_download_url; Tag=[string]$rel.tag_name }
  }
 } catch { }
 return $null
}
function Get-VostokPayloadVersion {
 param([string]$VmzPath)
 if(-not(Test-Path -LiteralPath $VmzPath -PathType Leaf)){return $null}
 Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
 $archive=$null;$reader=$null
 try {
  $archive=[IO.Compression.ZipFile]::OpenRead($VmzPath)
  $entry=$archive.GetEntry('mod.txt')
  if(-not $entry){return $null}
  $reader=New-Object IO.StreamReader($entry.Open())
  $manifest=$reader.ReadToEnd()
  $match=[regex]::Match($manifest,'(?m)^version\s*=\s*"(\d+\.\d+\.\d+)"')
  if($match.Success){return 'v'+$match.Groups[1].Value}
 } catch {return $null}
 finally {if($reader){$reader.Dispose()};if($archive){$archive.Dispose()}}
 return $null
}

# -------------------------------------------------------
# STEP 1: Check Metro Mod Loader
# -------------------------------------------------------
Write-Header
Write-Host " Road to Vostok VR by Blah64 - full VR with motion controls, physical" -ForegroundColor White
Write-Host " weapon handling and a holster system. Requires the game on Steam." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 3 "Checking Requirements"

Write-Host " Road to Vostok VR requires Metro Mod Loader (MML)." -ForegroundColor White
Write-Host " MML must be installed before the VR mod will work." -ForegroundColor White
Write-Host ""

# Check for MML in common game folder locations
$sp = Get-SteamPath
$gamePath = $null
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VOSTOK_TEST_GAME_ROOT){
 $candidate=[IO.Path]::GetFullPath($env:PCVR_VOSTOK_TEST_GAME_ROOT)
 if(-not(Test-Path -LiteralPath (Join-Path $candidate 'vostok-fixture.txt') -PathType Leaf) -or
    -not(Test-Path -LiteralPath (Join-Path $candidate $GAME_EXE) -PathType Leaf)){throw 'Road fixture is incomplete.'}
 $gamePath=$candidate
}
if (-not $gamePath -and $sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; Write-Info "Game found: $gamePath"; break }
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1963610" -SteamFolderNames @("Road to Vostok") -ProbeExe $GAME_EXE -HubGameId 'road-to-vostok-vr' }
if (-not $gamePath) {
 Write-Warn "Road to Vostok not found automatically."
 Write-Host " Enter the game folder:" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if($r -and (Test-Path -LiteralPath (Join-Path $r $GAME_EXE) -PathType Leaf)){$gamePath=$r;Write-Info "Path set: $gamePath"}else{Write-Fail "Not found: $r"}
 }
}

# Let the user cancel before downloading or replacing either loader file.
# The base-game executable makes this a repair choice even on a clean VR install.
$InstallMode = Read-UpdateOrInstall -GameFolder $gamePath -ModFile "mods\vr-mod.vmz"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

$tmp = Join-Path $env:TEMP "VostokVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null

$mmlCurrent = (Test-VostokLoaderSource -Path (Join-Path $gamePath 'modloader.gd') -Name 'modloader.gd') -and
              (Test-Path -LiteralPath (Join-Path $gamePath 'override.cfg') -PathType Leaf)

if ($mmlCurrent) {
 Write-Info "Metro Mod Loader v$MML_VERSION already installed."
} else {
 Write-Host " Installing or updating Metro Mod Loader v$MML_VERSION..." -ForegroundColor White
 Write-Host " The current release is two individual files, not a ZIP." -ForegroundColor Gray
 Write-Host ""
 $mmlOk = $true
 foreach ($file in $MML_FILES) {
  $download = Join-Path $tmp $file.Name
  if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VOSTOK_TEST_MML_ROOT){
   Copy-Item -LiteralPath (Join-Path $env:PCVR_VOSTOK_TEST_MML_ROOT $file.Name) -Destination $download -ErrorAction Stop
   $r=$true
  }else{
   $r = Invoke-SafeDownload -Urls @($file.Url) -Destination $download `
         -Label "Metro Mod Loader v$MML_VERSION - $($file.Name)" `
         -ManualUrl $MML_RELEASE `
         -Instructions "Download '$($file.Name)' from the v$MML_VERSION release and drop that file onto this window." `
         -SkipMessage "Skipped - $($file.Name) is required; the VR mod cannot load without it."
  }
  if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
  if (-not (Test-VostokLoaderSource -Path $download -Name $file.Name)) {
   Write-Fail "$($file.Name) is missing or is not a usable v$MML_VERSION loader file."
   $mmlOk = $false
   continue
  }
  Write-OK "$($file.Name) downloaded and checked."
 }
 if (-not $mmlOk) {
  Pause-User "Metro Mod Loader is incomplete. Press Enter to exit without installing the VR mod."
  exit 1
 }
 Write-Info "Metro Mod Loader v$MML_VERSION is ready; the game files change only after the VR package is ready."
}


# -------------------------------------------------------
# STEP 2: Download and install VR mod
# -------------------------------------------------------
Write-Step 2 3 "Downloading the latest $MOD_NAME"
$modZip = Join-Path $tmp "vr-mod-full.zip"
$modRelease = if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VOSTOK_TEST_MOD_ARCHIVE){
 @{Url=$env:PCVR_VOSTOK_TEST_MOD_ARCHIVE;Tag=$MOD_FALLBACK_TAG}
}else{Get-LatestVostokVrRelease}
$modVersion = $MOD_FALLBACK_TAG
$modUrls = New-Object System.Collections.Generic.List[string]
if ($modRelease) {
 $modVersion = [string]$modRelease.Tag
 [void]$modUrls.Add([string]$modRelease.Url)
 Write-Info "Latest release: $modVersion"
} else {
 Write-Warn "GitHub release lookup failed - using the last-known release."
}
if (-not $modRelease -or ([string]$modRelease.Url -ne $MOD_FALLBACK_URL)) { [void]$modUrls.Add($MOD_FALLBACK_URL) }

$downloadInfo = @{}
$r=$null
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VOSTOK_TEST_MOD_ARCHIVE){
 Copy-Item -LiteralPath $env:PCVR_VOSTOK_TEST_MOD_ARCHIVE -Destination $modZip -ErrorAction Stop
 $r=$true
}else{
 $r = Invoke-SafeDownload -Urls @($modUrls) -Destination $modZip `
       -Label "$MOD_NAME $modVersion" `
       -ManualUrl "$INFO_URL/releases" `
       -Instructions "Download the newest 'vr-mod-full.zip' and drop it onto this window." `
       -SkipMessage "Skipped - the VR mod archive was not downloaded; nothing can be installed." `
       -DownloadInfo $downloadInfo
}
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not (Test-Path -LiteralPath $modZip -PathType Leaf)) {
 Pause-User "The VR mod archive is missing. Press Enter to exit..."
 exit 1
}
# The version is read from the installed VMZ manifest after extraction. A
# manually selected archive may contain a different release than the URL.

Write-Step 3 3 "Installing"

while($true){
 Write-Host " Extracting VR mod files ... " -NoNewline -ForegroundColor White
 $mmlApplied=$false
 $releaseOverlay=$null
 try {
 $modExtract = Join-Path $tmp "vostok_mod"
 if(Test-Path -LiteralPath $modExtract){Remove-Item -LiteralPath $modExtract -Recurse -Force -ErrorAction Stop}
 $safe=Test-ZipArchiveEntrySafety -ArchivePath $modZip -DestinationFolder $modExtract
 if(-not $safe.Safe){throw 'The VR ZIP is unreadable or contains unsafe paths.'}
 $expanded=Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $modExtract -Label $MOD_NAME -AllowSkip $false
 if([string]$expanded -notin @('ok','manual','retry')){throw 'The VR ZIP was not extracted.'}
 $payloadVersion=Get-VostokPayloadVersion -VmzPath (Join-Path $modExtract 'mods\vr-mod.vmz')
 if(-not(Test-IsTrackableInstalledVersion $payloadVersion)){throw 'The VR mod payload has no trackable version in mod.txt.'}
 $modVersion=$payloadVersion
 if(-not $mmlCurrent){
  if(-not(Install-VostokLoaderPair -GamePath $gamePath -StagePath $tmp -BackupPath (Join-Path $tmp 'loader-backup'))){throw 'Metro Mod Loader copy failed; the original pair was restored.'}
  $mmlApplied=$true
 }
 $releaseOverlay=Install-VostokVrOverlay -StagePath $modExtract -GamePath $gamePath -BackupPath (Join-Path $tmp 'vr-backup')
 if((Get-VostokPayloadVersion -VmzPath (Join-Path $gamePath 'mods\vr-mod.vmz')) -ne $modVersion){throw 'The copied VR mod version did not match the staged package.'}
 Write-Host "OK" -ForegroundColor Green
  break
 } catch {
 if($releaseOverlay){try{Restore-VostokVrOverlay -Plan $releaseOverlay}catch{Write-Fail "VR rollback failed: $_"}}
 if($mmlApplied){try{Restore-VostokLoaderPair -GamePath $gamePath -BackupPath (Join-Path $tmp 'loader-backup')}catch{Write-Fail "Loader rollback failed: $_"}}
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "VR package install failed: $_"
 $__fb = Invoke-InstallerFallback -Action "VR package extraction or copy" `
 -Instructions "Fix the reported file or target-folder problem, then choose Retry. You can also supply a fresh VR ZIP." `
 -SkipMessage "Skipped - the VR mod was not installed; the previous files were restored." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$gamePath" `
 -DestFile "$modZip" `
 -FileValidator {param($candidate) $s=Test-ZipArchiveEntrySafety -ArchivePath $candidate -DestinationFolder (Join-Path $tmp 'zip-check'); return [bool]$s.Safe} `
 -AllowSkip $true
 if ([string]$__fb -eq 'retry') { continue }
 Pause-User 'The VR mod was not installed. Press Enter to close without marking success.'
 exit 1
 }
}

# Verify key files
$launchBat = Join-Path $gamePath "launch_vr.bat"
$vmzFile = Join-Path $gamePath "mods\vr-mod.vmz"
$allGood = (Test-Path -LiteralPath $launchBat -PathType Leaf) -and (Test-Path -LiteralPath $vmzFile -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $gamePath 'modloader.gd') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $gamePath 'VR Mod\bin\rtv_vr_injector.exe') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $gamePath 'rtv_vr_bootstrap.dll') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $gamePath 'librtv_vr_mod.windows.x86_64.dll') -PathType Leaf) -and
           ((Get-VostokPayloadVersion -VmzPath $vmzFile) -eq $modVersion)
if(-not $allGood){
 if($releaseOverlay){try{Restore-VostokVrOverlay -Plan $releaseOverlay}catch{Write-Fail "VR rollback failed: $_"}}
 if($mmlApplied){try{Restore-VostokLoaderPair -GamePath $gamePath -BackupPath (Join-Path $tmp 'loader-backup')}catch{Write-Fail "Loader rollback failed: $_"}}
 Write-Fail 'Required VR files, loader or the release version are missing after copy.'
 Pause-User 'Press Enter to close without marking this run complete.'
 exit 1
}

# Record install path and only an exact release tag after both proof files exist.
if ($allGood) {
 $receiptRoot=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VOSTOK_TEST_GAME_ROOT){$gamePath}else{$PSScriptRoot}
 try { Set-Content -Path (Join-Path $receiptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
 if (Test-IsTrackableInstalledVersion $modVersion) {
  try { Set-Content -Path (Join-Path $receiptRoot ".installed_version") -Value $modVersion -Encoding UTF8 -Force } catch {}
  Save-InstalledStamp -GameDir $gamePath -Version $modVersion
 }
}
try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# Desktop shortcut
$shortcutCreated = $false
if ((Test-Path -LiteralPath $launchBat -PathType Leaf) -and $env:PCVR_HUB_TEST_MODE -ne '1') {
 try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Road to Vostok VR.lnk" -TargetPath $launchBat -WorkingDir $gamePath -IconPath "$(Join-Path $gamePath 'RTV.exe'),0"
 $shortcutCreated = $true
 } catch {}
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
if (Test-Path $launchBat) { Write-Host " [x] launch_vr.bat" -ForegroundColor Green }
else { Write-Host " [ ] launch_vr.bat -- MISSING" -ForegroundColor Red }
if (Test-Path $vmzFile) { Write-Host " [x] mods\vr-mod.vmz" -ForegroundColor Green }
else { Write-Host " [ ] mods\vr-mod.vmz -- MISSING" -ForegroundColor Red }
if ($shortcutCreated) { Write-Host " [x] Desktop shortcut 'Road to Vostok VR' created." -ForegroundColor Green }
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " 1) Start SteamVR before launching the game" -ForegroundColor White
Write-Host " 2) Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host "    'Road to Vostok VR' desktop shortcut" -ForegroundColor White
Write-Host " Do NOT use Steam's Play button directly" -ForegroundColor Gray
Write-Host " 3) It starts with a black screen in headset, switch to desktop viewer" -ForegroundColor White
Write-Host " and press 'Launch with mods (Restart)'" -ForegroundColor White
Write-Host "===================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tip: F8 in-game opens VR settings (weapon grip, watch HUD, etc.)" -ForegroundColor Gray
Write-Host "" -ForegroundColor Green
Write-Host "Dead reckoning never felt this real." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
if($env:PCVR_HUB_TEST_MODE -ne '1'){try { Start-Process explorer.exe "`"$gamePath`"" } catch {}}

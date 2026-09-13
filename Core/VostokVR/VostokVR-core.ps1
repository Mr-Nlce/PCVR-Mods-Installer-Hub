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
$MML_RELEASE = "https://github.com/ametrocavich/vostok-mod-loader/releases/tag/v3.2.1"
$MML_FILES = @(
 @{ Name="modloader.gd"; Url="https://github.com/ametrocavich/vostok-mod-loader/releases/download/v3.2.1/modloader.gd"; Size=637690; Sha256="60fcf7feec0a47c6472e3b7a190b46987b374618ae3d149c081b222542bc6135" },
 @{ Name="override.cfg"; Url="https://github.com/ametrocavich/vostok-mod-loader/releases/download/v3.2.1/override.cfg"; Size=63; Sha256="9750a66fcf0cb1d9bf84284271f52e064f455cdd5a1cdc4981a007e4011a684b" }
)

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Road to Vostok - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " $MOD_NAME by Blah64" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
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
if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; Write-Info "Game found: $gamePath"; break }
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1963610" -SteamFolderNames @("Road to Vostok") -ProbeExe "launch_vr.bat" }
if (-not $gamePath) {
 Write-Warn "Road to Vostok not found automatically."
 Write-Host " Enter the game folder:" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path(Join-Path $r $GAME_EXE)){$gamePath=$r;Write-Info "Path set: $gamePath"}else{Write-Fail "Not found: $r"}
 }
}

$tmp = Join-Path $env:TEMP "VostokVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null

$mmlCurrent = $true
foreach ($file in $MML_FILES) {
 $installedFile = Join-Path $gamePath $file.Name
 if (-not (Test-Path -LiteralPath $installedFile -PathType Leaf)) { $mmlCurrent = $false; break }
 # The VR package deliberately replaces the loader's 63-byte override.cfg
 # with its own extension configuration. Presence is the right proof there;
 # modloader.gd itself must still match the current loader release exactly.
 if ($file.Name -ieq "override.cfg") { continue }
 try {
  $installedHash = (Get-FileHash -LiteralPath $installedFile -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
  if ($installedHash -ne $file.Sha256) { $mmlCurrent = $false; break }
 } catch { $mmlCurrent = $false; break }
}

if ($mmlCurrent) {
 Write-Info "Metro Mod Loader v3.2.1 already installed."
} else {
 Write-Host " Installing or updating Metro Mod Loader v3.2.1..." -ForegroundColor White
 Write-Host " The current release is two individual files, not a ZIP." -ForegroundColor Gray
 Write-Host ""
 $mmlOk = $true
 foreach ($file in $MML_FILES) {
  $download = Join-Path $tmp $file.Name
  $r = Invoke-SafeDownload -Urls @($file.Url) -Destination $download `
         -Label "Metro Mod Loader v3.2.1 - $($file.Name)" `
         -ManualUrl $MML_RELEASE `
         -Instructions "Download '$($file.Name)' from the v3.2.1 release and drop that file onto this window." `
         -SkipMessage "Skipped - $($file.Name) is required; the VR mod cannot load without it."
  if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
  if (-not (Test-Path -LiteralPath $download -PathType Leaf)) { $mmlOk = $false; continue }

  $valid = $true
  try {
   $actualSize = (Get-Item -LiteralPath $download -ErrorAction Stop).Length
   $actualHash = (Get-FileHash -LiteralPath $download -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
   if ($actualSize -ne [long]$file.Size -or $actualHash -ne $file.Sha256) { $valid = $false }
  } catch { $valid = $false }
  if (-not $valid) {
   Write-Fail "$($file.Name) does not match the official v3.2.1 release."
   $mmlOk = $false
   continue
  }
  Copy-Item -LiteralPath $download -Destination (Join-Path $gamePath $file.Name) -Force
  Write-OK "$($file.Name) installed and checksum verified."
 }

 if (-not $mmlOk -or -not (Test-Path -LiteralPath "$gamePath\modloader.gd") -or -not (Test-Path -LiteralPath "$gamePath\override.cfg")) {
  Pause-User "Metro Mod Loader is incomplete. Press Enter to exit without installing the VR mod."
  exit 1
 }
 New-Item -ItemType Directory -Path (Join-Path $gamePath "mods") -Force | Out-Null
 Write-Info "Metro Mod Loader v3.2.1 installed."
}


# -------------------------------------------------------
# STEP 2: Download and install VR mod
# -------------------------------------------------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gamePath -ModFile "mods\vr-mod.vmz"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 3 "Downloading the latest $MOD_NAME"
$modZip = Join-Path $tmp "vr-mod-full.zip"
$modRelease = Get-LatestVostokVrRelease
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
$r = Invoke-SafeDownload -Urls @($modUrls) -Destination $modZip `
       -Label "$MOD_NAME $modVersion" `
       -ManualUrl "$INFO_URL/releases" `
       -Instructions "Download the newest 'vr-mod-full.zip' and drop it onto this window." `
       -SkipMessage "Skipped - the VR mod archive was not downloaded; nothing can be installed." `
       -DownloadInfo $downloadInfo
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not (Test-Path -LiteralPath $modZip -PathType Leaf)) {
 Pause-User "The VR mod archive is missing. Press Enter to exit..."
 exit 1
}
# A manual drop cannot prove which release tag it contains. Do not invent a
# version marker; the next Hub scan will query the current tag itself.
if (-not ($r -is [bool] -and $r)) { $modVersion = $null }
elseif ($downloadInfo.Url -and ([string]$downloadInfo.Url -like "*$MOD_FALLBACK_URL*")) { $modVersion = $MOD_FALLBACK_TAG }

Write-Step 3 3 "Installing"

Write-Host " Extracting VR mod files ... " -NoNewline -ForegroundColor White
try {
 $modExtract = Join-Path $tmp "vostok_mod"
 Expand-Archive -Path $modZip -DestinationPath $modExtract -Force

 # Copy everything directly to game folder preserving structure
 # launch_vr.bat expects: VR Mod\bin\rtv_vr_injector.exe, mods\vr-mod.vmz,
 # rtv_vr_bootstrap.dll and librtv_vr_mod.windows.x86_64.dll in root
 Get-ChildItem -Path $modExtract | ForEach-Object {
 Copy-Item $_.FullName $gamePath -Recurse -Force
 }

 # override.cfg from VR Mod\resources must go into game root (not subfolder)
 $vrOverride = Join-Path $modExtract "VR Mod" | Join-Path -ChildPath "resources" | Join-Path -ChildPath "override.cfg"
 if (Test-Path $vrOverride) { Copy-Item $vrOverride $gamePath -Force }
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Extraction failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$modExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$modExtract" `
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

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# Verify key files
$launchBat = Join-Path $gamePath "launch_vr.bat"
$vmzFile = Join-Path $gamePath "mods\vr-mod.vmz"
$allGood = (Test-Path $launchBat) -and (Test-Path $vmzFile)

# Record install path and only an exact release tag after both proof files exist.
if ($allGood) {
 try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
 if (Test-IsTrackableInstalledVersion $modVersion) {
  try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $modVersion -Encoding UTF8 -Force } catch {}
  Save-InstalledStamp -GameDir $gamePath -Version $modVersion
 }
}

# Desktop shortcut
$shortcutCreated = $false
if (Test-Path $launchBat) {
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
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

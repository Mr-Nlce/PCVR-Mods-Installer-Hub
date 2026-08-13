# ============================================================
# Mage Arena - MA VR Mod Installer
# ============================================================
#
# MA VR by J_axon, distributed via Thunderstore. The mod is a
# BepInEx 5 plugin PLUS a preloader patcher, so it needs the
# BepInEx 5 pack specifically - BepInEx 6 is a different
# architecture and will not load the patcher.
#
# Both packages are pulled from Thunderstore at their latest
# version, so re-running this installer updates in place. The
# installed version of each package is recorded in
# BepInEx\.ts_versions\ - the Hub reads that file to decide
# whether the tile shows an Update badge.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Mage Arena VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME    = "Mage Arena"
$GAME_EXE     = "MageArena.exe"
$STEAM_APP    = "3716600"
$TS_COMMUNITY = "mage-arena"

# Order matters: BepInEx has to be on disk before the mod that
# plugs into it. FriendlyName is what the user sees.
$PACKAGES = @(
 @{ Author="BepInEx"; Name="BepInExPack"; FriendlyName="BepInEx 5" },
 @{ Author="J_axon";  Name="MAVR";        FriendlyName="MA VR" }
)

# Used only if the Thunderstore API cannot be reached, so the
# install still completes with a known-good pinned build.
$PINNED_URLS = @{
 "BepInExPack" = "https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2305/"
 "MAVR"        = "https://thunderstore.io/package/download/J_axon/MAVR/1.0.0/"
}
$PINNED_VERSIONS = @{
 "BepInExPack" = "5.4.2305"
 "MAVR"        = "1.0.0"
}

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host "  Mage Arena - MA VR Mod Installer" -ForegroundColor Cyan
 Write-Host "  by J_axon | via Thunderstore" -ForegroundColor Gray
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
    # String-concat instead of Join-Path: a library entry can point
    # at a drive that is no longer attached, and Join-Path throws
    # DriveNotFoundException on a dead drive.
    if ($p -and (Test-Path -LiteralPath $p)) { $libs.Add($p) }
   }
  } catch {}
 }
 return $libs
}

function Find-GamePath {
 $sp = Get-SteamPath
 foreach ($lib in (Get-SteamLibraries $sp)) {
  $cand = "$lib\steamapps\common\$GAME_NAME"
  try {
   if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { return $cand }
  } catch {}
 }
 return $null
}

function Get-InstalledVersion {
 param($packageName,$gamePath)
 $f = Join-Path $gamePath "BepInEx\.ts_versions\$packageName"
 if (Test-Path -LiteralPath $f) { return (Get-Content $f -Raw).Trim() }
 return $null
}

function Set-InstalledVersion {
 param($packageName,$version,$gamePath)
 $d = Join-Path $gamePath "BepInEx\.ts_versions"
 if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
 Set-Content -LiteralPath (Join-Path $d $packageName) -Value $version -Encoding UTF8
}

function Get-TSPackageInfo {
 param($author,$name)
 $apiUrls = @(
  "https://thunderstore.io/api/experimental/package/$author/$name/",
  "https://web.archive.org/web/0/https://thunderstore.io/api/experimental/package/$author/$name/"
 )
 foreach ($u in $apiUrls) {
  try {
   $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15 -EA Stop
   $d = $r.Content | ConvertFrom-Json
   return @{ Version=$d.latest.version_number; DownloadUrl=$d.latest.download_url; Deprecated=$d.is_deprecated }
  } catch {}
 }
 return $null
}

function Get-Zip {
 param($name,$url,$dest)
 foreach ($u in @($url, "https://web.archive.org/web/0/$url")) {
  Write-Host "  Downloading $name ... " -NoNewline -ForegroundColor White
  try {
   Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing -EA Stop
   Write-Host "OK" -ForegroundColor Green
   return $true
  } catch {
   Write-Host "FAILED" -ForegroundColor Red
  }
 }
 $r = Invoke-InstallerFallback `
        -Action "$name download" `
        -Url "https://thunderstore.io/c/$TS_COMMUNITY/" `
        -Instructions "Find '$name' on the Thunderstore page that just opened, download the ZIP, place it at '$dest', then choose Retry." `
        -SkipMessage "Skipped - $name was not downloaded; the install will be incomplete." `
        -DestFolder (Split-Path "$dest" -Parent) `
        -AllowSkip $true
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 return ((Test-Path -LiteralPath $dest) -and ((Get-Item -LiteralPath $dest).Length -gt 0))
}

function Install-Pkg {
 param($zip,$dest,$gamePath)
 # Thunderstore packages are inconsistent: some put BepInEx\ at the
 # zip root (MAVR does), others wrap everything in a single folder
 # (BepInExPack does). Detect which and merge the right level into
 # the game root either way.
 Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force
 $skip = @("manifest.json","icon.png","README.md","CHANGELOG.md","LICENSE","LICENSE.txt")
 $top = @(Get-ChildItem -LiteralPath $dest | Where-Object { $_.Name -notin $skip })
 $payload = if ($top.Count -eq 1 -and $top[0].PSIsContainer -and $top[0].Name -ne "BepInEx") { $top[0].FullName } else { $dest }
 Get-ChildItem -LiteralPath $payload | Where-Object { $_.Name -notin $skip } | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $gamePath -Recurse -Force
 }
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header
Write-Host "  MA VR by J_axon is a full room-scale VR mod for Mage Arena:" -ForegroundColor White
Write-Host "  head and hand tracking, a real body you can look down at, and" -ForegroundColor White
Write-Host "  motion controls. It is client-side, so flatscreen friends can" -ForegroundColor White
Write-Host "  play in the same lobby without the mod." -ForegroundColor White
Write-Host ""
Write-Host "  It renders through OpenVR, so SteamVR has to be running before" -ForegroundColor White
Write-Host "  you start the game. This installer places BepInEx 5 and the mod" -ForegroundColor White
Write-Host "  into your Steam copy of Mage Arena." -ForegroundColor White
Write-Host ""
try {
    # Abhaengigkeiten der Abhaengigkeiten pruefen - siehe PEAK.
    $tsMissing = @(Test-ThunderstoreDependencies -PackageUrls @($PINNED_URLS.Values))
    Show-ThunderstoreDependencyWarning -Missing $tsMissing
} catch {}

Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: Locate the game
# -------------------------------------------------------
Write-Header
Write-Step 1 3 "Locating Mage Arena"

$gamePath = Find-GamePath
if ($gamePath) {
 Write-OK "Found: $gamePath"
} else {
 Write-Warn "Could not find Mage Arena automatically."
 Write-Host ""
 Write-Host "  Steam library > right-click Mage Arena > Manage >" -ForegroundColor Gray
 Write-Host "  Browse local files, then drag that folder onto this window." -ForegroundColor Gray
 Write-Host ""
 while (-not $gamePath) {
  $typed = (Read-Host "  Mage Arena folder").Trim().Trim('"')
  if (-not $typed) { continue }
  if (Test-Path -LiteralPath (Join-Path $typed $GAME_EXE)) {
   $gamePath = $typed
   Write-OK "Using: $gamePath"
  } else {
   Write-Fail "That folder does not contain $GAME_EXE."
  }
 }
}

# -------------------------------------------------------
# STEP 2: Download and install the packages
# -------------------------------------------------------
Write-Step 2 3 "Installing BepInEx 5 and MA VR"

$tmp = Join-Path $env:TEMP ("MageArenaVR_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$failed = @()
foreach ($pkg in $PACKAGES) {
 $name = $pkg.Name
 $info = Get-TSPackageInfo -author $pkg.Author -name $name

 if ($info -and $info.DownloadUrl) {
  $url = $info.DownloadUrl
  $ver = $info.Version
 } else {
  $url = $PINNED_URLS[$name]
  $ver = $PINNED_VERSIONS[$name]
  Write-Warn "Thunderstore did not answer for $($pkg.FriendlyName) - using pinned $ver."
 }

 $have = Get-InstalledVersion -packageName $name -gamePath $gamePath
 if ($have -and $have -eq $ver) {
  Write-OK "$($pkg.FriendlyName) $ver already installed."
  continue
 }
 if ($have) { Write-Info "$($pkg.FriendlyName): $have -> $ver" }

 $zip = Join-Path $tmp "$name.zip"
 if (-not (Get-Zip -name $pkg.FriendlyName -url $url -dest $zip)) { $failed += $pkg.FriendlyName; continue }

 $ex = Join-Path $tmp $name
 try {
  Install-Pkg -zip $zip -dest $ex -gamePath $gamePath
  Set-InstalledVersion -packageName $name -version $ver -gamePath $gamePath
  Write-OK "$($pkg.FriendlyName) $ver installed."
 } catch {
  Write-Fail "$($pkg.FriendlyName) could not be unpacked: $($_.Exception.Message)"
  $failed += $pkg.FriendlyName
 }
}

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

# -------------------------------------------------------
# STEP 3: Verify
# -------------------------------------------------------
Write-Step 3 3 "Verifying"

$modDll  = Join-Path $gamePath "BepInEx\plugins\MageArenaVR\MageArenaVR.dll"
$preload = Join-Path $gamePath "BepInEx\patchers\MageArenaVR\MageArenaVR.Preload.dll"
$winhttp = Join-Path $gamePath "winhttp.dll"

if (Test-Path -LiteralPath $winhttp) { Write-OK "BepInEx present." } else { Write-Fail "BepInEx missing (winhttp.dll)."; $failed += "BepInEx" }
if (Test-Path -LiteralPath $modDll)  { Write-OK "MA VR plugin present." } else { Write-Fail "MA VR plugin missing."; $failed += "MA VR plugin" }
if (Test-Path -LiteralPath $preload) { Write-OK "MA VR preloader present." } else { Write-Fail "MA VR preloader missing."; $failed += "MA VR preloader" }

if ($failed.Count -gt 0) {
 Write-Host ""
 Write-Warn ("Incomplete: " + (($failed | Select-Object -Unique) -join ", "))
 Write-Host "  Re-run this installer, or install the missing package by hand from" -ForegroundColor Gray
 Write-Host "  https://thunderstore.io/c/$TS_COMMUNITY/" -ForegroundColor Gray
 Write-Host ""
 Pause-User "Press Enter to exit."
 exit 1
}

# !!! DER MARKER GEHOERT IN DEN INSTALLERORDNER, NICHT IN DEN SPIELORDNER !!!
# Der Hub sucht .installed_path ueber Get-InstalledPathFile, und das setzt
# den Pfad aus dem Bat-Ordner des Eintrags zusammen (hier MageArenaVR\) -
# NICHT aus dem Spielordner. Frueher landete er in $gamePath und wurde
# deshalb nie gefunden: nach der Installation konnte die Kachel falsch
# bleiben, besonders bei einem ungewoehnlichen Spielpfad, den die
# FallbackPaths nicht erraten.
# $PSScriptRoot ist genau dieser Installerordner.
try {
    Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
} catch {
    Write-Warn "Could not record the install path - the Hub may need 'Locate install'."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Setup complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |             START STEAMVR FIRST                      |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   SteamVR running before launch  " -NoNewline -ForegroundColor White; Write-Host " REQUIRED " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The mod renders through OpenVR and the OpenVR compositor IS" -ForegroundColor Gray
Write-Host "  SteamVR. Start it first or the mod has nowhere to send frames" -ForegroundColor Gray
Write-Host "  and simply leaves you on the desktop." -ForegroundColor Gray
Write-Host ""
Write-Host "  ON EVERY LAUNCH:" -ForegroundColor Cyan
Write-Host "    A dialog asks VR or Flatscreen before the game draws." -ForegroundColor Gray
Write-Host "    Yes = VR, No = flatscreen companion mode. Set ForcedMode" -ForegroundColor Gray
Write-Host "    in the config to skip it." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or start Mage Arena" -ForegroundColor Gray
Write-Host "    from Steam as usual." -ForegroundColor Gray
Write-Host ""
Write-Host "  See the README for controls, the F1 settings panel and the" -ForegroundColor DarkGray
Write-Host "  performance options." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Robes on, wand up - the arena is a lot closer from in here." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

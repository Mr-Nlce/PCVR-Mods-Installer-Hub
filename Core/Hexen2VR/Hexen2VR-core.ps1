# ============================================================
# Hexen II - VHexen2 VR Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Hexen II VR Installer"
$ErrorActionPreference = "Stop"

$MOD_URL = "https://www.moddb.com/mods/hexen-ii-vr/downloads/hexen-2-vr-015-pc-alpha"
$MOD_NAME = "VHexen2 v0.1.5-pc-alpha"
$MOD_AUTHOR = "alexdnax"
$INFO_URL = "https://www.moddb.com/mods/hexen-ii-vr/downloads"
$GAME_FOLDER = "Hexen II VR"
$GAME_EXE = "vhexen2-desktop.exe"
$STEAM_FOLDER = "Hexen 2"
# Hub convention: games with their own folder (separate EXE, not
# Steam-launched) install to C:\Games\<Title> VR. First writable wins.
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
# GOG: scan every registered GOG game and test each install path for
# data1\pak0.pak rather than hard-coding a (possibly wrong) game ID.
$GOG_ROOTS = @(
 "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
 "HKLM:\SOFTWARE\GOG.com\Games"
)

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host " Hexen II - VHexen2 VR Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries {
 param($sp); $libs=@($sp)
 $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}
function Test-WritableRoot {
 param([string]$Root)
 if (-not $Root) { return $false }
 try {
  if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
  $probe = Join-Path $Root ".pcvrhub_write_probe"
  Set-Content -Path $probe -Value "ok" -ErrorAction Stop
  Remove-Item $probe -Force -ErrorAction SilentlyContinue
  return $true
 } catch { return $false }
}

# -------------------------------------------------------
# STEP 1: Locate Hexen II game data
# -------------------------------------------------------
Write-Header
Write-Host " VHexen2 by alexdnax - Hexen II: Hammer of Thyrion with full OpenXR VR." -ForegroundColor White
Write-Host " Motion controllers in VR, or keyboard/mouse in flat mode." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Locating Hexen II"

$sourceData1 = $null

$steamPath = Get-SteamPath
if ($steamPath) {
 foreach ($lib in (Get-SteamLibraries $steamPath)) {
 $candidate = Join-Path $lib "steamapps\common\$STEAM_FOLDER\data1"
 if (Test-Path -LiteralPath "$candidate\pak0.pak") {
 $sourceData1 = $candidate
 Write-Info "Hexen II found via Steam: $sourceData1"
 break
 }
 }
}

if (-not $sourceData1) {
 foreach ($root in $GOG_ROOTS) {
  try {
   Get-ChildItem -Path $root -ErrorAction Stop | ForEach-Object {
    if ($sourceData1) { return }
    try {
     $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
     if ($gogPath) {
      $candidate = Join-Path $gogPath "data1"
      if (Test-Path -LiteralPath "$candidate\pak0.pak") {
       $sourceData1 = $candidate
       Write-Info "Hexen II found via GOG: $sourceData1"
      }
     }
    } catch {}
   }
  } catch {}
  if ($sourceData1) { break }
 }
}

if (-not $sourceData1) {
 Write-Warn "Hexen II not found automatically."
 Write-Host " Enter the path to your Hexen II data1 folder:" -ForegroundColor White
 Write-Host " Steam: C:\Program Files (x86)\Steam\steamapps\common\Hexen 2\data1" -ForegroundColor Gray
 Write-Host " GOG: C:\GOG Games\Hexen II\data1" -ForegroundColor Gray
 while (-not $sourceData1) {
 $r = (Read-Host " Path").Trim().Trim('"')
 if (Test-Path -LiteralPath "$r\pak0.pak") { $sourceData1 = $r; Write-Info "Path set: $sourceData1" }
 else { Write-Fail "pak0.pak not found at: $r" }
 }
}

# -------------------------------------------------------
# STEP 2: Download VHexen2
# -------------------------------------------------------
Write-Step 2 4 "Downloading $MOD_NAME"

$downloadsFolder = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
$zipPattern = "vhexen2-*-pc-alpha.zip"
$modZip = $null

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Download VHexen2" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " The download page will open in your browser." -ForegroundColor White
Write-Host " Download the ZIP and come back - the installer continues automatically." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to open the download page..."
Start-Process $MOD_URL

$timeout = 300
$elapsed = 0
while (-not $modZip -and $elapsed -lt $timeout) {
 $found = Get-ChildItem -Path $downloadsFolder -Filter $zipPattern -ErrorAction SilentlyContinue |
 Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($found) {
 $partial = Get-ChildItem -Path $downloadsFolder -Filter "$($found.BaseName)*" |
 Where-Object { $_.Extension -in @(".crdownload", ".part") }
 if (-not $partial) { $modZip = $found.FullName }
 }
 if (-not $modZip) { Start-Sleep -Seconds 2; $elapsed += 2 }
}

if (-not $modZip) {
 Write-Warn "ZIP not detected automatically."
 Write-Host " Enter the full path to the downloaded ZIP:" -ForegroundColor White
 while (-not $modZip) {
 $r = (Read-Host " Path").Trim().Trim('"')
 if (Test-Path $r) { $modZip = $r }
 else { Write-Fail "Not found: $r" }
 }
}

# -------------------------------------------------------
# STEP 3: Extract and install
# -------------------------------------------------------
Write-Step 3 4 "Installing"

$tempDir = Join-Path $env:TEMP "Hexen2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
$modExtract = Join-Path $tempDir "vhexen2"
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Pick install root by Hub convention: first writable C:\Games (then
# D:, E:), with a manual fallback. The game lands in <root>\Hexen II VR
# - self-contained, NOT inside the Steam library (VHexen2 ships its own
# vhexen2-desktop.exe and is not launched through Steam).
$installParent = $null
foreach ($r in $DEFAULT_ROOTS) {
 if (Test-WritableRoot -Root $r) { $installParent = [string]$r; break }
}
if (-not $installParent) {
 Write-Warn "None of the default roots (C:\Games, D:\Games, E:\Games) is writable."
 Write-Host " Enter a folder to install into (will create '$GAME_FOLDER' inside)." -ForegroundColor White
 Write-Host " Avoid Program Files / Users - pick e.g. C:\Games" -ForegroundColor Gray
 while (-not $installParent) {
  $r = (Read-Host " Install root").Trim().Trim('"')
  if (-not $r) { continue }
  if (Test-WritableRoot -Root $r) { $installParent = [string]$r }
  else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
 }
}
Write-Info "Install root: $installParent"
$installRoot = Join-Path $installParent $GAME_FOLDER

if (Test-Path $installRoot) {
 Write-Info "Existing installation found. VHexen2 files will be merged; additional files are preserved."
}
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

Write-Host " Extracting ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $modZip -DestinationPath $modExtract -Force
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

$modChildren = @(Get-ChildItem -Path $modExtract)
$modPayload = if ($modChildren.Count -eq 1 -and $modChildren[0].PSIsContainer) { $modChildren[0].FullName } else { $modExtract }

Write-Host " Copying VHexen2 files ... " -NoNewline -ForegroundColor White
try {
 Get-ChildItem -Path $modPayload | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force
 }
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Copy failed: $_"; Pause-User "Press Enter to exit..."; exit 1
}

$destData1 = Join-Path $installRoot "data1"
if (-not (Test-Path $destData1)) { New-Item -ItemType Directory -Path $destData1 | Out-Null }

$failed = @()
foreach ($pak in @("pak0.pak","pak1.pak")) {
 $src = Join-Path $sourceData1 $pak
 Write-Host " Copying $pak ... " -NoNewline -ForegroundColor White
 if (Test-Path $src) {
 try { Copy-Item -Path $src -Destination $destData1 -Force; Write-Host "OK" -ForegroundColor Green }
 catch { Write-Host "FAILED" -ForegroundColor Red; $failed += $pak }
 } else {
 Write-Host "NOT FOUND" -ForegroundColor Red; $failed += $pak
 }
}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($failed.Count -eq 0) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# STEP 4: Summary + Desktop Shortcut
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

$gameExePath = Join-Path $installRoot $GAME_EXE

Write-Host " Installation folder: $installRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " [x] VHexen2 v0.1.5-pc-alpha" -ForegroundColor Green
if ($failed.Count -eq 0) {
 Write-Host " [x] pak0.pak + pak1.pak copied" -ForegroundColor Green
} else {
 Write-Host " [ ] pak files missing: $($failed -join ', ')" -ForegroundColor Red
 Write-Host " Copy manually into: $destData1" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Launch SteamVR before the game to avoid it potentially starting" -ForegroundColor White
Write-Host " sometimes out of focus." -ForegroundColor White
Write-Host " Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the desktop shortcut." -ForegroundColor White
Write-Host " The game starts in VR automatically if SteamVR is running." -ForegroundColor Gray
Write-Host ""
Write-Host " SteamVR Theatre Mode must be OFF:" -ForegroundColor Gray
Write-Host " SteamVR -> Settings -> Dashboard -> 'Present Non-VR Applications...' -> OFF" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

if (Test-Path $gameExePath) {
 try {
 $glh2Icon = Join-Path (Split-Path $sourceData1 -Parent) "glh2.exe"
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Hexen II VR.lnk" -TargetPath $gameExePath -WorkingDir $installRoot -IconPath $(if (Test-Path $glh2Icon) { "$glh2Icon,0" } else { "" })
 Write-Info "Desktop shortcut 'Hexen II VR' created."
 } catch {
 Write-Warn "Could not create shortcut: $_"
 Write-Host " Launch manually from: $gameExePath" -ForegroundColor Gray
 }
}

Write-Host ""
Write-Host " The realms are broken. The old magic is waking." -ForegroundColor Green
Write-Host " Step through the portal." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$installRoot`"" } catch {}

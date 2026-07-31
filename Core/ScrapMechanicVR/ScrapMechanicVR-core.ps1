# ============================================================
# Scrap Mechanic - Native VR Installer (manual, no exe patcher)
# ============================================================
# The upstream mod ships a guarded one-file patcher that only
# accepts Steam build 22163681 - and the live Steam build has
# moved past it. So we install the VR files OURSELVES from the
# source archive's payload folder (which mirrors the game tree)
# and launch through the mod's own Start-NativeVR.ps1, which sets
# $env:SteamAppId and starts the OpenXR runtime. No patcher, no
# %LOCALAPPDATA% manager - we make our own desktop shortcut.
#
# Two install paths:
#   Option [1] Current game version: copy the VR files onto your
#     existing Steam copy.
#   Option [2] Depot version: Steam Console download of the newest
#     content build into C:\Games\Scrap Mechanic VR, then copy the
#     VR files onto that. Retail Steam copy stays untouched. This
#     is a tinkering build - VR may need fiddling on a build the
#     mod wasn't cut against.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Scrap Mechanic VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME     = "Scrap Mechanic"
$GAME_EXE      = "Release\ScrapMechanic.exe"
$GAME_EXE_LEAF = "ScrapMechanic.exe"
$MOD_FILE      = "Release\scrap_native_vr.addon64"
$LAUNCH_PS1    = "NativeVR\Start-NativeVR.ps1"
$LAUNCH_BAT    = "NativeVR\Start Scrap Mechanic VR.bat"

$REPO        = "21Suspect/Scrap-Mechanic-Native-VR"
$MOD_VERSION = "v1.17.0"
# Source archive - contains payload\ (the VR files) which mirrors the
# game folder tree. We copy payload\* into the game root.
$SOURCE_URL  = "https://github.com/$REPO/archive/refs/tags/$MOD_VERSION.zip"
$INFO_URL    = "https://github.com/$REPO"

# Steam depot - NEWEST content build (has the executable). Depot 387993
# is the content depot; 387992 is data-only (no exe). Manifest from Martin.
$DEPOT_APPID    = "387990"
$DEPOT_DEPOTID  = "387993"
$DEPOT_MANIFEST = "2120585736818737513"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME    = "Scrap Mechanic VR"
$DEFAULT_PATH   = Join-Path $DEFAULT_PARENT $TARGET_NAME

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host "  Scrap Mechanic - Native VR Installer" -ForegroundColor Cyan
 Write-Host "  by 21Suspect | native OpenXR (manual install)" -ForegroundColor Gray
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
 foreach ($lib in (Get-SteamLibraries (Get-SteamPath))) {
  $cand = "$lib\steamapps\common\$GAME_NAME"
  try { if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { return $cand } } catch {}
 }
 return $null
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

 Write-Host " Downloading the VR files ($MOD_VERSION source) ..." -ForegroundColor White
 $haveZip = $false
 try {
  Invoke-WebRequest -Uri $SOURCE_URL -OutFile $zipPath -UseBasicParsing -EA Stop
  $haveZip = Test-Path -LiteralPath $zipPath
 } catch { Write-Warn "Automatic download failed: $($_.Exception.Message)" }
 if (-not $haveZip) {
  $fb = Invoke-InstallerFallback `
        -Action "VR source archive download" `
        -Url "$INFO_URL/releases/tag/$MOD_VERSION" `
        -Instructions "Download the $MOD_VERSION source zip from the page that opened, place it at '$zipPath', then choose Retry." `
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
 param([string]$gamePath, [string]$batPath)
 try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
 if ($batPath -and (Test-Path -LiteralPath $batPath)) {
  try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".launch_exe") -Value $batPath -Encoding UTF8 -Force } catch {}
 }
 try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $MOD_VERSION -Encoding UTF8 -Force } catch {}
}

# Our own desktop shortcut pointing at the launch bat.
function Make-Shortcut {
 param([string]$gamePath, [string]$batPath)
 if (-not ($batPath -and (Test-Path -LiteralPath $batPath))) { return }
 $iconExe = Join-Path $gamePath $GAME_EXE
 $workDir = Split-Path -Parent $batPath
 try {
  [void](New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Scrap Mechanic VR.lnk" -TargetPath $batPath -WorkingDir $workDir -IconPath "$iconExe,0")
  Write-OK "Desktop shortcut 'Scrap Mechanic VR' created."
 } catch {}
}

# Shared end-screen notes.
function Write-EndNotes {
 Write-Host ""
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host "  Setup complete." -ForegroundColor Green
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
 Write-Host "  +======================================================+" -ForegroundColor Yellow
 Write-Host "  |            SET THESE OUTSIDE THE GAME                |" -ForegroundColor Yellow
 Write-Host "  +======================================================+" -ForegroundColor Yellow
 Write-Host ""
 Write-Host "   Active OpenXR runtime   " -NoNewline -ForegroundColor White; Write-Host " Meta Quest Link or SteamVR " -ForegroundColor Black -BackgroundColor Yellow
 Write-Host ""
 Write-Host "  The launch script checks the active OpenXR runtime and starts" -ForegroundColor Gray
 Write-Host "  it (Quest Link or SteamVR) for you. Set your runtime in Meta" -ForegroundColor Gray
 Write-Host "  Horizon Link (Settings > General) or via SteamVR." -ForegroundColor Gray
 Write-Host ""
 Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
 Write-Host "    Use 'Start in VR' on the Hub tile, or the 'Scrap Mechanic VR'" -ForegroundColor Gray
 Write-Host "    desktop shortcut. Both run the VR launch script. Never start" -ForegroundColor Gray
 Write-Host "    from Steam - that runs the flat game." -ForegroundColor Gray
 Write-Host ""
 Write-Host "  This is a manual install on a build the mod wasn't cut against," -ForegroundColor DarkGray
 Write-Host "  so VR may need fiddling. See the README for details." -ForegroundColor DarkGray
 Write-Host ""
 Write-Host "  Build it, then climb inside and grab the wrench yourself." -ForegroundColor Magenta
 Write-Host ""
}

# ============================================================
# MENU
# ============================================================
Write-Header
Write-Host " The upstream patcher only accepts Steam build 22163681, which the" -ForegroundColor White
Write-Host " live game has moved past. This installer copies the VR files in" -ForegroundColor White
Write-Host " manually instead. Choose how to install:" -ForegroundColor White
Write-Host ""

$depotInstalledStatus = $null
$depotInstalledColor  = "Gray"
try {
 if (Test-Path -LiteralPath (Join-Path $DEFAULT_PATH $GAME_EXE)) {
  $depotInstalledStatus = " [installed at $DEFAULT_PATH]"; $depotInstalledColor = "Green"
 } else {
  $depotInstalledStatus = " [not yet installed]"; $depotInstalledColor = "Gray"
 }
} catch {}

Write-Host "  [1] Current game version" -ForegroundColor Green
Write-Host "      Copies the VR files onto your existing Steam copy." -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] Depot version (newest content build)" -ForegroundColor Yellow
if ($depotInstalledStatus) { Write-Host "     $depotInstalledStatus" -ForegroundColor $depotInstalledColor }
Write-Host "      Downloads a separate copy via Steam Console into" -ForegroundColor Gray
Write-Host "      $DEFAULT_PATH, then copies the VR files onto it." -ForegroundColor Gray
Write-Host "      Your retail Steam copy stays untouched (tinkering build)." -ForegroundColor Gray
Write-Host ""
$mode = ""
while ($mode -notin @("1","2")) { $mode = (Read-Host " Enter 1 or 2").Trim() }

# ============================================================
# OPTION 2 - DEPOT (newest content build)
# ============================================================
if ($mode -eq "2") {
 Pause-User "Press Enter to start..."
 Write-Step 1 4 "Steam Depot Download"

 Write-Host " We'll download a separate game copy via Steam Console. Your" -ForegroundColor White
 Write-Host " retail install stays untouched." -ForegroundColor White
 Write-Host ""
 Write-Host " Here's what's about to happen:" -ForegroundColor Cyan
 Write-Host " 1) The Steam Console will open" -ForegroundColor White
 Write-Host " 2) The download command is already on your clipboard" -ForegroundColor White
 Write-Host " 3) Paste with Ctrl+V into the Console and hit Enter" -ForegroundColor Yellow
 Write-Host " 4) Wait for Steam to finish, then come back here" -ForegroundColor White
 Write-Host ""
 Write-Host " When Steam finishes it will show:" -ForegroundColor Gray
 Write-Host "   Depot download complete : ...\depot_$DEPOT_DEPOTID" -ForegroundColor Yellow
 Write-Host ""

 try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " [OK] Depot command copied to clipboard." -ForegroundColor Yellow
 Write-Host " Command: $DEPOT_COMMAND" -ForegroundColor Gray
 Write-Host ""
 if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
  Write-Host " (i) Virtual Desktop users: if the Console doesn't open, open it" -ForegroundColor DarkGray
  Write-Host "     manually (Steam menu bar - View - Console) and paste there." -ForegroundColor DarkGray
  Write-Host ""
 }
 Pause-User "Press Enter to open the Steam Console..."
 Start-Process "steam://nav/console"
 Write-OK "Steam Console opening..."
 Write-Host ""
 Pause-User "Press Enter once the Steam depot download is complete..."

 # Locate depot (layout-agnostic: search recursively for the exe by name)
 Write-Host ""
 Write-Host " Looking for Steam installation..." -ForegroundColor White
 $steamInstallPath = Get-SteamPath
 $depotBase = $null
 if ($steamInstallPath) {
  $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
  Write-Info "Expected depot path: $autoPath"
  if (Test-Path $autoPath) { $depotBase = $autoPath; Write-OK "Depot folder found." }
  else { Write-Warn "Depot folder not found yet at the expected location." }
 } else {
  Write-Warn "Could not find Steam installation in registry."
 }
 if (-not $depotBase) {
  $probePaths = @()
  if ($steamInstallPath) { $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID") }
  $depotBase = Resolve-DepotPath -GameName $GAME_NAME -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE_LEAF -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
  if (-not $depotBase) { Write-Fail "No depot folder provided."; Pause-User "Press Enter to exit..."; exit 1 }
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
 $parentOfDepot = Split-Path $depotPath -Parent
 Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
 Write-Host " (C:\Games keeps the install off the Steam library and away from" -ForegroundColor DarkGray
 Write-Host "  any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
 Write-Host ""
 $userInput = (Read-Host " Press Enter to use default, or type a different full path").Trim().Trim('"')
 if (-not $userInput) { $targetPath = $DEFAULT_PATH } else { $targetPath = $userInput }

 $targetParent = Split-Path $targetPath -Parent
 if ($targetParent -and -not (Test-Path $targetParent)) {
  try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
  catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
 }

 if (Test-Path $targetPath) {
  Write-Warn "A folder already exists at $targetPath"
  Write-Host " [Y] Delete existing folder and proceed" -ForegroundColor White
  Write-Host " [N] Keep it, abort install" -ForegroundColor Gray
  $c = ""; while ($c -notin @("y","Y","n","N")) { $c = (Read-Host " Your choice (Y/N)").Trim() }
  if ($c -in @("n","N")) { Write-Info "Aborted by user."; Pause-User "Press Enter to exit..."; exit 0 }
  try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
  catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
 }

 try {
  Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
  Write-OK "Game moved to: $targetPath"
 } catch {
  Write-Fail "Move failed: $_"
  Write-Info "The game files are still at: $depotPath"
  $fb = Invoke-InstallerFallback -Action "move depot files to install folder" `
      -Instructions "The game files are still at '$depotPath'. Manually move them to '$targetPath'. Then choose Retry." `
      -SkipMessage "Skipped - game files are still in the depot folder." `
      -DestFolder "$targetPath" -AllowSkip $true
  if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
  if ([string]$fb -eq "retry") { Pause-User "Please re-run the installer once resolved. Press Enter to exit..."; exit 1 }
 }

 try {
  if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) { Remove-Item $parentOfDepot -Force }
 } catch {}

 $gamePath = $targetPath

 Write-Step 3 4 "Installing the VR files"
 $batPath = Install-ManualMod -gamePath $gamePath
 if (-not $batPath) { Pause-User "Press Enter to exit."; exit 1 }

 Write-Markers -gamePath $gamePath -batPath $batPath
 Make-Shortcut -gamePath $gamePath -batPath $batPath

 Write-Step 4 4 "All Done!"
 Write-Host " Depot install ready at: $gamePath" -ForegroundColor Yellow
 Write-EndNotes
 Pause-User "Press Enter to exit."
 exit 0
}

# ============================================================
# OPTION 1 - CURRENT GAME VERSION
# ============================================================
Write-Step 1 3 "Locating $GAME_NAME"
Write-Host " [!] Copying the VR files onto your current Steam copy. If VR" -ForegroundColor Yellow
Write-Host "     doesn't initialise, the live build may differ too much from" -ForegroundColor Yellow
Write-Host "     the mod - re-run and pick option 2 (depot)." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue..."

$gamePath = Find-GamePath
if ($gamePath) {
 Write-OK "Game found: $gamePath"
} else {
 Write-Warn "Scrap Mechanic not found automatically."
 Write-Host " Enter the game folder (the one containing Release\ScrapMechanic.exe):" -ForegroundColor White
 while (-not $gamePath) {
  $r = (Read-Host " Path").Trim().Trim('"')
  if ($r -and (Test-Path -LiteralPath (Join-Path $r $GAME_EXE))) { $gamePath = $r; Write-OK "Path set: $gamePath" }
  elseif ($r) { Write-Fail "That folder does not contain $GAME_EXE." }
 }
}

Write-Step 2 3 "Installing the VR files"
$batPath = Install-ManualMod -gamePath $gamePath
if (-not $batPath) { Pause-User "Press Enter to exit."; exit 1 }

Write-Markers -gamePath $gamePath -batPath $batPath
Make-Shortcut -gamePath $gamePath -batPath $batPath

Write-Step 3 3 "Final notes"
Write-EndNotes
Pause-User "Press Enter to exit."

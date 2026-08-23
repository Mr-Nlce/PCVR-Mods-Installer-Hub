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
# THERE IS ONLY ONE ROUTE, and that is deliberate: a Steam console
# download of EXACTLY build 22163681 into C:\Games\Scrap Mechanic VR
# (path selectable), then the VR files on top. The retail copy stays
# untouched and may keep updating.
# The option once offered - "copy onto your own Steam copy" - is GONE:
# it assumed that copy is still build 22163681, which stopped being
# the live state on 24 July 2026. It was the wrong choice for
# practically everyone.
# NO AUTO-UPDATE: the mod is tied to this one build. v1.17.0 is
# pinned; a future version will very likely need a different build and
# therefore a new manifest - the two get changed together, not the mod
# alone.
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
$DEPOT_APPID    = "387990"
$SUPPORTED_BUILD = "22163681"
# Order: data first, then the exe depot - so the folder is complete
# after the last step and the exe check runs on the finished tree.
$DEPOTS = @(
    @{ Id = "387992"; Manifest = "4615519036154398529"; Label = "Scrap Mechanic Data" },
    @{ Id = "387993"; Manifest = "1969835134401920665"; Label = "Windows 64-bit (with the exe)" }
)
foreach ($d in $DEPOTS) { $d.Command = "download_depot $DEPOT_APPID $($d.Id) $($d.Manifest)" }
# For messages and the fallback: the exe depot.
$DEPOT_DEPOTID  = $DEPOTS[1].Id
$DEPOT_MANIFEST = $DEPOTS[1].Manifest
$DEPOT_COMMAND  = $DEPOTS[1].Command

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
 # ALSO write the durable stamp next to the GAME (2026-08-20).
 # The line above lands inside the Hub folder and is gone as
 # soon as a new Hub build is dropped in; the scan then finds
 # no marker and seeds the CURRENT online tag, swallowing a
 # pending update. The game-side stamp survives that.
 Save-InstalledStamp -GameDir $gamePath -Version $MOD_VERSION
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
 Write-Host "    Use" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "on the Hub tile, or the 'Scrap Mechanic VR'" -ForegroundColor Gray
 Write-Host "    desktop shortcut. Both run the VR launch script. Never start" -ForegroundColor Gray
 Write-Host "    from Steam - that runs the flat game." -ForegroundColor Gray
 Write-Host ""
 Write-Host "  This is a manual install on a build the mod wasn't cut against," -ForegroundColor DarkGray
 Write-Host "  so VR may need fiddling. Details are on this game's page in" -ForegroundColor DarkGray
 Write-Host "  the Hub." -ForegroundColor DarkGray
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

# THE DEPOT ROUTE ONLY. The option "copy onto your own Steam copy" is
# GONE (decided after the successful test): it only works on build
# 22163681, which stopped being the live state on 24 July 2026 - so it
# was the wrong choice for practically everyone and only caused
# confusion.
Write-Host "  This mod needs Steam build $SUPPORTED_BUILD - and that is not" -ForegroundColor White
Write-Host "  what Steam installs today. So the Hub fetches that exact build" -ForegroundColor White
Write-Host "  as a SEPARATE copy and puts the VR files on it." -ForegroundColor White
if ($depotInstalledStatus) { Write-Host "   $depotInstalledStatus" -ForegroundColor $depotInstalledColor }
Write-Host ""
Write-Host "  Lands in $DEFAULT_PATH or a folder of your choice." -ForegroundColor Gray
Write-Host "  Your retail Steam copy stays untouched and keeps updating." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..."

# ============================================================
# THE ONLY ROUTE: DEPOT (build 22163681, the one the mod supports)
# ============================================================
 Pause-User "Press Enter to start..."
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
  try { Set-Clipboard -Value $d.Command; $clipOk = $true } catch {}
  Write-Host ""
  if ($step -eq 1) { Pause-User "Press Enter to open the Steam Console..." }
  else            { Pause-User "Press Enter to bring the Steam Console back to the front..." }
  # Both protocol addresses: depending on the Steam version only one
 # works.
  foreach ($cu in @("steam://open/console", "steam://nav/console")) {
      try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
  }
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

  $found = $null
  if ($steamInstallPath) {
   $auto = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$($d.Id)"
   if (Test-Path $auto) { $found = $auto; Write-OK "Found: $auto" }
   else { Write-Warn "Not at the expected place: $auto" }
  }
  if (-not $found) {
   $probe = @()
   if ($steamInstallPath) { $probe += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$($d.Id)") }
   $found = Resolve-DepotPath -GameName "$GAME_NAME ($($d.Label))" -DepotCommand $d.Command -GameExe $GAME_EXE_LEAF -ProbePaths $probe -AppId $DEPOT_APPID -DepotId $d.Id -Manifest $d.Manifest
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
 $parentOfDepot = Split-Path $depotPath -Parent
 Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
 Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
 Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
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

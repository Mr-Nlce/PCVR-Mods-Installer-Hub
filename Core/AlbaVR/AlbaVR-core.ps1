# ============================================================
# Alba: A Wildlife Adventure - AlbaVR Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "AlbaVR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Alba - A Wildlife Adventure"
$GAME_EXE = "Alba.exe"
$BEPINEX_URL = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.21/BepInEx_x64_5.4.21.0.zip"
$MOD_URL = "https://github.com/wouterpleizier/AlbaVR/releases/download/v1.0.0/AlbaVR_1.0.0.zip"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host " Alba: A Wildlife Adventure - AlbaVR Installer" -ForegroundColor Magenta; Write-Host " BepInEx 5.4.21 + AlbaVR v1.0.0 by wouterpleizier" -ForegroundColor Gray; Write-Host " Note: Gamepad controls, no motion controls" -ForegroundColor Yellow; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
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

Write-Header

# STEP 1: Locate Alba
Write-Host " AlbaVR brings the cozy island wildlife adventure into VR - play the" -ForegroundColor White
Write-Host " whole game seated. Gamepad controls, no motion controls." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Locating Alba: A Wildlife Adventure"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Alba VR"
 }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
$gamePath = $null
if ($steamPath) {
 foreach ($lib in (Get-SteamLibraries $steamPath)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $c) { $gamePath = $c; break }
 }
}
# Also check common Epic Games install locations
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1337010" -SteamFolderNames @("Alba - A Wildlife Adventure") -GogNames @("ALBA A Wildlife Adventure","Alba A Wildlife Adventure") -EpicNames @("Alba","Alba - A Wildlife Adventure") }
if (-not $gamePath) {
 $epicRoots = @(
 "C:\Program Files\Epic Games",
 "C:\Program Files (x86)\Epic Games",
 (Join-Path $env:USERPROFILE "Epic Games")
 )
 foreach ($root in $epicRoots) {
 $candidate = Join-Path $root $GAME_NAME
 if (Test-Path (Join-Path $candidate $GAME_EXE)) {
 $gamePath = $candidate
 Write-Info "Alba found via Epic Games: $gamePath"
 break
 }
 }
}

if ($gamePath) {
 Write-Info "Game found: $gamePath"
} else {
 Write-Warn "Alba not found automatically."
 Write-Host " Please enter the game installation folder:" -ForegroundColor White
 Write-Host " Steam: C:\Program Files (x86)\Steam\steamapps\common\Alba - A Wildlife Adventure" -ForegroundColor Gray
 Write-Host " Epic: C:\Program Files\Epic Games\Alba - A Wildlife Adventure" -ForegroundColor Gray
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path $r){$gamePath=$r; Write-Info "Path set: $gamePath"} else{Write-Fail "Not found: $r"}
 }
}

$gameExe = Join-Path $gamePath $GAME_EXE
if (Test-Path $gameExe) { Write-OK "EXE verified: $GAME_EXE" }
else { Write-Warn "$GAME_EXE not found - path may still be correct." }

# STEP 2: Select VR platform
Write-Step 2 4 "Select VR Platform"

Write-Host " Which VR platform are you using?" -ForegroundColor White
Write-Host ""
Write-Host " [1] SteamVR (Meta Quest via Link/Air Link, Valve Index, etc.)" -ForegroundColor White
Write-Host " [2] Oculus (Meta Quest via Oculus PC app / native link)" -ForegroundColor White
Write-Host ""
$vrMode = ""
while ($vrMode -notin @("1","2")) { $vrMode = (Read-Host " Enter 1 or 2").Trim() }
$vrModeText = if ($vrMode -eq "1") { "SteamVR" } else { "Oculus" }
Write-OK "VR platform selected: $vrModeText"

# STEP 3: Download and install
Write-Step 3 4 "Downloading and Installing"

$tempDir = Join-Path $env:TEMP "AlbaVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Download BepInEx
$bepZip = Join-Path $tempDir "BepInEx.zip"
$r = Invoke-DownloadOrFallback -Url $BEPINEX_URL -Destination $bepZip `
        -Label "BepInEx 5.4.21" `
        -ManualUrl "https://github.com/BepInEx/BepInEx/releases/tag/v5.4.21" `
        -Instructions "Download 'BepInEx_x64_5.4.21.0.zip' from the GitHub releases page that just opened in your browser. Place it at '$bepZip' and choose Retry." `
        -SkipMessage "Skipped - BepInEx mod loader is missing; the VR mod will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }

# Download AlbaVR mod
$modZip = Join-Path $tempDir "AlbaVR.zip"
$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "AlbaVR v1.0.0" `
        -ManualUrl "https://github.com/wouterpleizier/AlbaVR/releases/tag/v1.0.0" `
        -Instructions "Download 'AlbaVR_1.0.0.zip' from the GitHub releases page that just opened. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - AlbaVR mod files are missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }

# Extract BepInEx into game folder
if (Test-Path $bepZip) {
    $r = Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $gamePath -Label "BepInEx 5.4.21" `
            -SkipMessage "Skipped - BepInEx was NOT extracted; the VR mod will NOT load."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "BepInEx installed." }
}

# Extract AlbaVR mod into game folder (zip contains BepInEx\ tree)
if (Test-Path $modZip) {
    $r = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $gamePath -Label "AlbaVR mod" `
            -SkipMessage "Skipped - AlbaVR mod files were NOT extracted."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "AlbaVR mod installed." }
}

# Write VRMODE.txt
$vrModeTxt = Join-Path $gamePath "VRMODE.txt"
Set-Content -Path $vrModeTxt -Value $vrModeText -Encoding ASCII -NoNewline
Write-OK "VRMODE.txt written: $vrModeText"

# Verify
$dllCheck = Join-Path $gamePath "BepInEx\plugins\AlbaVR\AlbaVR.dll"
if (Test-Path $dllCheck) { Write-OK "AlbaVR.dll verified." }
else { Write-Warn "AlbaVR.dll not found - check $gamePath\BepInEx\plugins\AlbaVR\ manually." }

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# STEP 4: Desktop shortcut
Write-Step 4 4 "Creating Desktop Shortcut"

try {
  $shortcut = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Alba VR.lnk" -TargetPath $gameExe -WorkingDir $gamePath -IconPath "$gameExe,0" -Description "Alba VR ($vrModeText)"
 Write-OK "Desktop shortcut 'Alba VR' created with game icon."
} catch {
 Write-Warn "Could not create shortcut: $_"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host " Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'Alba VR'" -ForegroundColor White
Write-Host " shortcut on your Desktop." -ForegroundColor White
Write-Host " Platform: $vrModeText" -ForegroundColor Cyan
Write-Host ""
Write-Host " To switch platform later, edit VRMODE.txt in the game folder." -ForegroundColor Gray
Write-Host " Write exactly: SteamVR or Oculus" -ForegroundColor Gray
Write-Host ""
Write-Host " Note: Gamepad controls only - no motion controls." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Camera ready. The island is full of life worth saving." -ForegroundColor Magenta
Write-Host ""
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
Pause-User "Press Enter to exit."

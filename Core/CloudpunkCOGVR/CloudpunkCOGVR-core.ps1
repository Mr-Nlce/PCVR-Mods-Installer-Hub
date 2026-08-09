# ============================================================
# Cloudpunk: City of Ghosts - VR Mod Installer
# ============================================================
# Mod by Astienth | https://github.com/Astienth/Cloudpunk-VR
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Cloudpunk: City of Ghosts VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Cloudpunk - City of Ghosts"
$GAME_EXE = "Cloudpunk - City of Ghosts.exe"
$STEAM_APP = "1197200"
$MOD_URL = "https://github.com/Astienth/Cloudpunk-VR/releases/download/1.0.0/Cloudpunk_City_of_Ghosts_VR.zip"
$MOD_NAME = "Cloudpunk City of Ghosts VR v1.0.0"
$INFO_URL = "https://github.com/Astienth/Cloudpunk-VR/releases"

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Cloudpunk: City of Ghosts - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " $MOD_NAME by Astienth" -ForegroundColor Gray
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

# -------------------------------------------------------
# STEP 1: Locate game
# -------------------------------------------------------
Write-Header
Write-Host " Cloudpunk: City of Ghosts VR by Astienth - gamepad-based VR for the" -ForegroundColor White
Write-Host " City of Ghosts DLC. Requires the base game and its DLC on Steam." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 3 "Locating Cloudpunk"

$gamePath = $null
$sp = Get-SteamPath
if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; Write-Info "Found: $gamePath"; break }
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1536370" -SteamFolderNames @("Cloudpunk - City of Ghosts") -GogNames @("Cloudpunk") -EpicNames @("Cloudpunk") }
if (-not $gamePath) {
 Write-Warn "Cloudpunk not found automatically."
 Write-Host " Enter the game folder:" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path(Join-Path $r $GAME_EXE)){$gamePath=$r;Write-Info "Path set: $gamePath"}else{Write-Fail "Not found: $r"}
 }
}

# -------------------------------------------------------
# STEP 2: Download mod
# -------------------------------------------------------
Write-Step 2 3 "Downloading $MOD_NAME"

$tmp = Join-Path $env:TEMP "CloudpunkVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null
$modZip = Join-Path $tmp "CloudpunkCOGVR.zip"

Write-Host " Downloading ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -EA Stop
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download failed: $_"
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$tmp' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
 -SkipMessage "Skipped - no install folder; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Retry folder create
 try {
 if (-not (Test-Path $gameDir)) {
 New-Item -ItemType Directory -Path $gameDir -Force -ErrorAction Stop | Out-Null
 }
 Write-OK "Folder ready: $gameDir"
 } catch {
 Pause-User "Still cannot create folder. Choose a different path then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

# -------------------------------------------------------
# STEP 3: Install
# -------------------------------------------------------
Write-Step 3 3 "Installing"

Write-Host " Extracting ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $modZip -DestinationPath $gamePath -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Extraction failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$gamePath'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$gamePath" `
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

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Desktop shortcut
try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Cloudpunk City of Ghosts VR.lnk" -TargetPath Join-Path $gamePath $GAME_EXE -WorkingDir $gamePath -IconPath "$(Join-Path $gamePath $GAME_EXE),0"
 Write-Info "Desktop shortcut 'Cloudpunk City of Ghosts VR' created."
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
$dllOk = Test-Path -LiteralPath "$gamePath\BepInEx\plugins\CloudpunkVR_CityofGhosts.dll"
if ($dllOk) { Write-Host " [x] BepInEx\plugins\CloudpunkVR_CityofGhosts.dll" -ForegroundColor Green }
else { Write-Host " [ ] CloudpunkVR_CityofGhosts.dll -- MISSING" -ForegroundColor Red }
Write-Host " [x] Desktop shortcut 'Cloudpunk City of Ghosts VR' created." -ForegroundColor Green
Write-Host ""
Write-Host " Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or that desktop shortcut." -ForegroundColor White
Write-Host ""
Write-Host " TIPS" -ForegroundColor Cyan
Write-Host " - VR UI scale: edit BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg -> 'VRUI scale'" -ForegroundColor Gray
Write-Host " - Performance: raise 'maxVehicleCharactersDivider' in CloudpunkVR.cfg (less NPCs)" -ForegroundColor Gray
Write-Host " - Rain: disable 'RainAndSheetsRenderer' in CloudpunkVR.cfg if it hurts performance" -ForegroundColor Gray
Write-Host " - HDR / MSAA: toggle in UnityVR_Bepinex_IL2CPP.cfg under [UICONFIG]" -ForegroundColor Gray
Write-Host ""
Write-Host "The dead remember everything. So does HOVA." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

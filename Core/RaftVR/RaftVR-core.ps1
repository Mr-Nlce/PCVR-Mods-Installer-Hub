# ============================================================
# Raft - RaftVR 1.1.0 Installer
# Mod by DrBibop | https://www.raftmodding.com/mods/raftvr
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "RaftVR Installer"
$ErrorActionPreference = "Stop"

$MODLOADER_URL = "https://www.raftmodding.com/launcher/2.8.10/download"
$RAFTVR_URL = "https://www.raftmodding.com/mods/raftvr/1.1.0/RaftVR.rmod?ignoreVirusScan=true"
$EXTRASETTINGS_URL = "https://www.raftmodding.com/mods/extra-settings-api/1.10.4/ExtraSettingsAPI.rmod?ignoreVirusScan=true"
$GAME_NAME = "Raft"
$STEAM_APP_ID = "648800"
$REQUIRED_BRANCH = "1.09_precrossplayupdate"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host " Raft - RaftVR 1.1.0 Installer" -ForegroundColor Magenta; Write-Host " Mod by DrBibop | raftmodding.com" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries { param($sp)
 $libs=@($sp)
 $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}
function Find-GamePath { param($libs)
 foreach($lib in $libs){ $c=Join-Path $lib "steamapps\common\$GAME_NAME"; if(Test-Path -LiteralPath "$c\Raft.exe"){return $c} }; return $null
}
function Get-File { param($name,$url,$dest)
 # Try direct URL, then web archive mirror, then interactive fallback
 $sources = @($url, "https://web.archive.org/web/0/$url")
 foreach ($u in $sources) {
   Write-Host " Downloading $name from $u ... " -NoNewline -ForegroundColor White
   try {
     Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing -EA Stop
     if((Get-Item $dest).Length -lt 1000){ throw "File too small" }
     Write-Host "OK" -ForegroundColor Green; return $true
   } catch { Write-Host "FAILED - $_" -ForegroundColor Red }
 }
 $r = Invoke-InstallerFallback `
        -Action "$name download" `
        -Url $url `
        -Instructions "Open the page above, download '$name' manually, place it at '$dest', then choose Retry." `
        -SkipMessage "Skipped - $name was not downloaded; install may be incomplete (questionable result)." `
        -DestFolder (Split-Path "$dest" -Parent) `
        -AllowSkip $true
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 return ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 1000))
}
function Find-RaftModLoader {
 $candidates = @(
 (Join-Path $env:LOCALAPPDATA "RaftModLoader\current\RaftModLoader.exe"),
 (Join-Path $env:LOCALAPPDATA "RaftModLoader\RaftModLoader.exe"),
 (Join-Path $env:PROGRAMFILES "RaftModLoader\RaftModLoader.exe"),
 "${env:ProgramFiles(x86)}\RaftModLoader\RaftModLoader.exe"
 )
 foreach($c in $candidates){ if(Test-Path $c){ return $c } }
 $found = Get-ChildItem "$env:LOCALAPPDATA\RaftModLoader" -Filter "RaftModLoader.exe" -Recurse -EA SilentlyContinue | Select-Object -First 1
 if($found){ return $found.FullName }
 return $null
}

Write-Header

# STEP 1: Find Raft
Write-Host " RaftVR by DrBibop adds VR to Raft, via the RaftModLoader launcher." -ForegroundColor White
Write-Host " Motion controls." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Locating Raft"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Raft"
 }
} catch {}
# --- End detection library attempt ---

$sp = Get-SteamPath
if(-not $sp){
 Write-Warn "Steam not found in registry. Please enter Steam path manually:"
 while(-not $sp){ $r=(Read-Host " Path").Trim().Trim('"'); if(Test-Path $r){$sp=$r}else{Write-Fail "Not found: $r"} }
}
$gp = Find-GamePath (Get-SteamLibraries $sp)
if (-not $gp) { $gp = Find-SteamGameFolder -AppId "648800" -SteamFolderNames @("Raft") -ProbeExe "RaftModLoader.exe" -EpicNames @("Raft") }
if(-not $gp){
 Write-Warn "Raft not found automatically."
 Write-Host " Enter the Raft folder path (containing Raft.exe):" -ForegroundColor White
 while(-not $gp){ $r=(Read-Host " Path").Trim().Trim('"'); if(Test-Path -LiteralPath "$r\Raft.exe"){$gp=$r}else{Write-Fail "Raft.exe not found in: $r"} }
} else { Write-OK "Found: $gp" }

$modsDir = Join-Path $gp "mods"
New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
Write-OK "Mods folder: $modsDir"

# STEP 2: Steam branch switch
Write-Step 2 4 "Switch to Required Game Version"

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Switch Steam Branch" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " RaftVR requires a specific older Raft version." -ForegroundColor White
Write-Host ""
Write-Host " 1) Go to the Betas tab" -ForegroundColor White
Write-Host " 2) Select branch: $REQUIRED_BRANCH" -ForegroundColor Yellow
Write-Host " 3) Close Properties and wait for Steam to finish updating" -ForegroundColor White
Write-Host ""
Write-Host " Press Enter to open Raft properties in Steam..." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Raft properties in Steam..."
Start-Process "steam://gameproperties/$STEAM_APP_ID"
Pause-User "Press Enter once the branch is set and Steam has finished updating..."

# STEP 3: RaftModLoader
Write-Step 3 4 "RaftModLoader"

$modLoaderExe = Find-RaftModLoader

if($modLoaderExe){
 Write-OK "RaftModLoader already found: $modLoaderExe"
} else {
 $mlDest = Join-Path $gp "RMLLauncher.exe"
 if(Get-File "RaftModLoader 2.8.10 (RMLLauncher.exe)" $MODLOADER_URL $mlDest){
 $modLoaderExe = $mlDest
 Write-OK "RMLLauncher.exe saved to Raft folder."
 } else {
 Write-Fail "Download failed. Please download RMLLauncher.exe manually from raftmodding.com"
 }
}

# Desktop shortcut named "Raft VR"
if($modLoaderExe -and (Test-Path $modLoaderExe)){
 try {
 $desktop = [Environment]::GetFolderPath("Desktop")
 $lnk = Join-Path $desktop "Raft VR.lnk"
  $raftExe = Join-Path $gp "Raft.exe"
  $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $modLoaderExe -IconPath "$raftExe,0"
 Write-OK "Desktop shortcut created: 'Raft VR'"
 } catch { Write-Warn "Could not create desktop shortcut: $_" }
}

# STEP 4: Download mods
Write-Step 4 4 "Downloading Mods"

$ok = $true

$esaDest = Join-Path $modsDir "ExtraSettingsAPI.rmod"
if(-not (Get-File "ExtraSettingsAPI v1.10.4" $EXTRASETTINGS_URL $esaDest)){ $ok=$false }
else { Write-OK "ExtraSettingsAPI.rmod installed." }

$vrDest = Join-Path $modsDir "RaftVR.rmod"
if(-not (Get-File "RaftVR v1.1.0" $RAFTVR_URL $vrDest)){ $ok=$false }
else { Write-OK "RaftVR.rmod installed." }

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation complete!" -ForegroundColor Green
Write-Host ""
if($ok){
 Write-OK "ExtraSettingsAPI.rmod"
 Write-OK "RaftVR.rmod"
 Write-Host ""
 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " IMPORTANT - Do NOT launch Raft via Steam!" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host "--- How to play in VR ---" -ForegroundColor Cyan
 Write-Host ""
 Write-Host " 1. Launch with 'Start in VR' in the Hub, or the" -ForegroundColor White
Write-Host "    'Raft VR' desktop shortcut" -ForegroundColor White
 Write-Host " or via RMLLauncher.exe in the Raft game folder." -ForegroundColor White
 Write-Host ""
 Write-Host " 2. In the mod menu, open the Mod Manager tab." -ForegroundColor White
 Write-Host ""
 Write-Host " 3. Find ExtraSettingsAPI and click 'Load Mod' to activate it." -ForegroundColor White
 Write-Host " (RaftVR should already show as active automatically.)" -ForegroundColor Gray
 Write-Host ""
 Write-Host " 4. A VR setup dialog will appear." -ForegroundColor White
 Write-Host " Configure your VR runtime (SteamVR or Oculus) and preferences." -ForegroundColor Gray
 Write-Host ""
 Write-Host " 5. The dialog will offer to restart the game." -ForegroundColor White
 Write-Host " Confirm the restart - from now on Raft launches in VR." -ForegroundColor Gray
 Write-Host ""
 Write-Host " 6. On the next launch, start SteamVR first, then open Raft VR." -ForegroundColor White
} else {
 Write-Warn "Some downloads failed. Check your internet connection and try again."
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host " Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host " (You can only do this while SteamVR is running with your headset on.)" -ForegroundColor Gray
Write-Host ""
Write-Host " Build a sail. Watch the sharks. VR awaits!" -ForegroundColor Magenta
 Write-Host ""
 Pause-User "Press Enter to open the Raft game folder and exit."
try { Start-Process explorer.exe "`"$gp`"" } catch {}

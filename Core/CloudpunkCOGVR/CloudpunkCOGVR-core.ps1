# ============================================================
# Cloudpunk: City of Ghosts - VR Mod Installer
# ============================================================
# Mod by Astienth | https://github.com/Astienth/Cloudpunk-VR
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$Host.UI.RawUI.WindowTitle = "Cloudpunk: City of Ghosts VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Cloudpunk - City of Ghosts"
$GAME_EXE = "Cloudpunk - City of Ghosts.exe"
$STEAM_APP = "746850"
$MOD_URL = "https://github.com/Astienth/Cloudpunk-VR/releases/download/1.0.0/Cloudpunk_City_of_Ghosts_VR.zip"
$MOD_NAME = "Cloudpunk City of Ghosts VR v1.0.0"
$MOD_VERSION = 'v1.0.0'
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
 if ($PSVersionTable.PSEdition -eq 'Core' -and $IsLinux -and $env:PCVR_STEAM_ROOT -and (Test-Path -LiteralPath $env:PCVR_STEAM_ROOT)) { return $env:PCVR_STEAM_ROOT } # Linux Hub only
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
Show-AntivirusNotice -Compact
Pause-User "Press Enter to start..."
Write-Step 1 3 "Locating Cloudpunk"

$gamePath = Find-SteamGameFolder -AppId $STEAM_APP -SteamFolderNames @('Cloudpunk') `
 -Subdir 'City of Ghosts' -ProbeExe $GAME_EXE -HubGameId 'cloudpunk-city-of-ghosts-vr'
if (-not $gamePath) {
 Write-Info 'Choose the City of Ghosts folder or its game EXE.'
 $gamePath = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE
}
if (-not $gamePath -or -not (Test-PCVRGameInstallProof -GameId 'cloudpunk-city-of-ghosts-vr' -Root $gamePath)) {
 throw 'The City of Ghosts game EXE and original game data were not found. Select the complete expansion folder.'
}
Write-Info "Game folder: $gamePath"

# -------------------------------------------------------
# STEP 2: Download mod
# -------------------------------------------------------
Write-Step 2 3 "Downloading $MOD_NAME"

$tmp = Join-Path $env:TEMP "CloudpunkVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null
$modZip = Join-Path $tmp "CloudpunkCOGVR.zip"

Write-Host " Downloading ... " -NoNewline -ForegroundColor White
try {
 Invoke-PCVRWebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -EA Stop
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download failed: $_"
 $__fb = Invoke-InstallerFallback -Action 'mod download' -Url $INFO_URL -DestFile $modZip `
  -Instructions 'Download the mod ZIP from the release page and drop it here, then choose Retry.' `
  -RetryCheck { Test-Path -LiteralPath $modZip -PathType Leaf } -AllowSkip $false
 if ([string]$__fb -ne 'retry') { exit 1 }
}
try { Assert-PCVRDropInPreflight -GameRoot $gamePath -GameExe $GAME_EXE -GameDataFolder 'Cloudpunk - City of Ghosts_Data' -ArchivePath $modZip }
catch { Write-Fail $_; Pause-User 'Press Enter to exit...'; exit 1 }

# -------------------------------------------------------
# STEP 3: Install
# -------------------------------------------------------
Write-Step 3 3 "Installing"

Write-Host " Extracting ... " -NoNewline -ForegroundColor White
$extract=Join-Path $tmp 'extract'
try {
 if ((Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $extract -Label $MOD_NAME -AllowSkip $false) -notin @('ok','manual')) { throw 'Extraction was not completed.' }
 $required=@('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.Unity.IL2CPP.dll','BepInEx\plugins\CloudpunkVR_CityofGhosts.dll')
 $hashes=Get-PCVRDropInSourceHashes -SourceRoot $extract -RequiredFiles $required
 $contract=New-PCVRInstallerContract -Id 'cloudpunk-city-of-ghosts-vr' -GameName $GAME_NAME -Acquisition GitHub `
  -ReleasePageUrl $INFO_URL -AntivirusNotice -RequiredInstalledFileGroups $required
 [void](Invoke-PCVRDropInInstall -SourceRoot $extract -GameRoot $gamePath -SourceHashes $hashes `
  -KeepExistingFiles @('BepInEx\config\BepInEx.cfg','BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg','BepInEx\config\CloudpunkVR.cfg') `
  -Contract $contract -Version $MOD_VERSION -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
 Write-Host "OK - files verified" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Installation failed; previous files were restored: $_"
 Pause-User 'Press Enter to exit...'; exit 1
}

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# Desktop shortcut
$shortcutCreated=$false
try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Cloudpunk City of Ghosts VR.lnk" -TargetPath (Join-Path $gamePath $GAME_EXE) -WorkingDir $gamePath -IconPath "$(Join-Path $gamePath $GAME_EXE),0"
 $shortcutCreated=[bool]$sc
 if($shortcutCreated){Write-Info "Desktop shortcut 'Cloudpunk City of Ghosts VR' created."}
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
$dllOk = Test-Path -LiteralPath "$gamePath\BepInEx\plugins\CloudpunkVR_CityofGhosts.dll"
if ($dllOk) { Write-Host " [x] BepInEx\plugins\CloudpunkVR_CityofGhosts.dll" -ForegroundColor Green }
else { Write-Host " [ ] CloudpunkVR_CityofGhosts.dll -- MISSING" -ForegroundColor Red }
if($shortcutCreated){Write-Host " [x] Desktop shortcut 'Cloudpunk City of Ghosts VR' created." -ForegroundColor Green}
else{Write-Host " [ ] Desktop shortcut was not created; use Start in VR in the Hub." -ForegroundColor Yellow}
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


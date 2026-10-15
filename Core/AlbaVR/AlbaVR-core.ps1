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
$MOD_VERSION = 'v1.0.0'
$BEPINEX_URL = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.21/BepInEx_x64_5.4.21.0.zip"
$MOD_URL = "https://github.com/wouterpleizier/AlbaVR/releases/download/v1.0.0/AlbaVR_1.0.0.zip"
$REQUIRED_LOADER = @('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.Preloader.dll')
$REQUIRED_MOD = @('BepInEx\plugins\AlbaVR\AlbaVR.dll','BepInEx\patchers\VRPatcher\VRPatcher.dll','Play with SteamVR.bat','Play with Oculus.bat')

function Get-AlbaFileSha256([string]$Path) {
 $stream=[IO.File]::OpenRead($Path)
 try { $sha=[Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') } finally { $sha.Dispose() } }
 finally { $stream.Dispose() }
}

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
if($gamePath -and -not(Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE) -PathType Leaf)){$gamePath=$null}
if (-not $gamePath -and $steamPath) {
 foreach ($lib in (Get-SteamLibraries $steamPath)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path -LiteralPath (Join-Path $c $GAME_EXE) -PathType Leaf) { $gamePath = $c; break }
 }
}
# Also check common Epic Games install locations
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1337010" -SteamFolderNames @("Alba - A Wildlife Adventure") -GogNames @("ALBA A Wildlife Adventure","Alba A Wildlife Adventure") -EpicNames @("Alba","Alba - A Wildlife Adventure") }
if($gamePath -and -not(Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE) -PathType Leaf)){$gamePath=$null}
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
 Write-Host " Type Q to cancel without changing game files." -ForegroundColor Gray
 Write-Host " Steam: C:\Program Files (x86)\Steam\steamapps\common\Alba - A Wildlife Adventure" -ForegroundColor Gray
 Write-Host " Epic: C:\Program Files\Epic Games\Alba - A Wildlife Adventure" -ForegroundColor Gray
 while (-not $gamePath) {
 $r=([string](Read-Host " Path")).Trim().Trim('"')
 if($r -match '^(?i:q|quit|exit)$'){throw 'Setup cancelled before changing game files.'}
 if(Test-Path -LiteralPath (Join-Path $r $GAME_EXE) -PathType Leaf){$gamePath=$r; Write-Info "Path set: $gamePath"} else{Write-Fail "Alba.exe not found in: $r"}
 }
}

$gameExe = Join-Path $gamePath $GAME_EXE
if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { throw "Alba.exe is missing from the selected game folder." }
if (Get-Process -Name 'Alba' -ErrorAction SilentlyContinue) { throw 'Close Alba before installing the VR mod.' }
if (-not (Test-InstallerTargetWritable -TargetPath $gamePath)) { throw 'The game folder is not writable.' }
Write-OK "EXE verified: $GAME_EXE"

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
$changes=New-Object 'System.Collections.Generic.List[object]'
$copied=$false
$keepWork=$false
try {
    # A skipped or incomplete download is never a successful setup. Extract
    # away from the game and inspect the actual publisher layout first.
    $bepZip=Join-Path $tempDir 'BepInEx.zip'
    $r=Invoke-DownloadOrFallback -Url $BEPINEX_URL -Destination $bepZip `
        -Label 'BepInEx 5.4.21' -ManualUrl 'https://github.com/BepInEx/BepInEx/releases/tag/v5.4.21' `
        -Instructions "Download BepInEx_x64_5.4.21.0.zip. Place it at '$bepZip' and choose Retry."
    if([string]$r -eq 'quit' -or -not(Test-Path -LiteralPath $bepZip -PathType Leaf)){throw 'The BepInEx download was not completed.'}
    $modZip=Join-Path $tempDir 'AlbaVR.zip'
    $r=Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label 'AlbaVR v1.0.0' -ManualUrl 'https://github.com/wouterpleizier/AlbaVR/releases/tag/v1.0.0' `
        -Instructions "Download AlbaVR_1.0.0.zip. Place it at '$modZip' and choose Retry."
    if([string]$r -eq 'quit' -or -not(Test-Path -LiteralPath $modZip -PathType Leaf)){throw 'The AlbaVR download was not completed.'}
    $sources=@(
        [pscustomobject]@{Archive=$bepZip;Folder=(Join-Path $tempDir 'BepInEx-stage');Label='BepInEx 5.4.21';Required=$REQUIRED_LOADER},
        [pscustomobject]@{Archive=$modZip;Folder=(Join-Path $tempDir 'AlbaVR-stage');Label='AlbaVR v1.0.0';Required=$REQUIRED_MOD}
    )
    foreach($source in $sources){
        $safe=Test-ZipArchiveEntrySafety -ArchivePath $source.Archive -DestinationFolder $source.Folder
        if(-not $safe.Inspectable -or -not $safe.Safe -or $safe.EntryCount -eq 0){throw "Unsafe or unreadable $($source.Label) archive."}
        $result=Expand-ArchiveOrFallback -ArchivePath $source.Archive -DestinationFolder $source.Folder -Label $source.Label -AllowSkip $false -QuietProgress
        if([string]$result -notin @('ok','manual','retry')){throw "$($source.Label) archive could not be extracted."}
        foreach($relative in $source.Required){
            if(-not(Test-Path -LiteralPath (Join-Path $source.Folder $relative) -PathType Leaf)){throw "$($source.Label) archive is missing $relative."}
        }
    }
    $payload=Join-Path $tempDir 'verified-payload'
    [void][IO.Directory]::CreateDirectory($payload)
    foreach($source in $sources){
        foreach($file in @(Get-ChildItem -LiteralPath $source.Folder -Recurse -File -ErrorAction Stop)){
            $relative=$file.FullName.Substring($source.Folder.TrimEnd('\').Length+1)
            if($relative -ieq $GAME_EXE){throw 'An archive tries to replace the base-game executable.'}
            $target=Join-Path $payload $relative
            if(Test-Path -LiteralPath $target){throw "The two archives contain a conflicting file: $relative"}
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath $file.FullName -Destination $target -ErrorAction Stop
        }
    }
    $launcherText=@'
@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PCVR_ALBA_MODE=SteamVR"
if exist "%~dp0.pcvrhub_alba_mode" for /f "usebackq delims=" %%M in ("%~dp0.pcvrhub_alba_mode") do set "PCVR_ALBA_MODE=%%M"
if /I not "%PCVR_ALBA_MODE%"=="Oculus" set "PCVR_ALBA_MODE=SteamVR"
> "%~dp0VRMODE.txt" echo %PCVR_ALBA_MODE%
start "" /d "%~dp0" "%~dp0Alba.exe"
exit /b 0
'@
    [IO.File]::WriteAllText((Join-Path $payload 'PCVRHub Start Alba VR.bat'),$launcherText,[Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $payload '.pcvrhub_alba_mode'),$vrModeText,[Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $payload 'VRMODE.txt'),$vrModeText,[Text.Encoding]::ASCII)
    $files=@(Get-ChildItem -LiteralPath $payload -Recurse -File -ErrorAction Stop)
    $backupRoot=Join-Path $tempDir 'rollback'
    [void][IO.Directory]::CreateDirectory($backupRoot)
    $paths=@($files | ForEach-Object { Join-Path $gamePath $_.FullName.Substring($payload.TrimEnd('\').Length+1) }) +
        @((Join-Path $gamePath '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))
    $statusPath=[string]$env:PCVR_HUB_INSTALL_STATUS_PATH
    if($statusPath -and (Split-Path -Leaf $statusPath) -like 'install_*.json' -and (Split-Path -Leaf (Split-Path -Parent $statusPath)) -eq 'Transactions'){$paths+= $statusPath}
    $index=0
    foreach($path in @($paths|Select-Object -Unique)){
        if(Test-Path -LiteralPath $path -PathType Container){throw "A folder blocks the installation file: $path"}
        $existed=Test-Path -LiteralPath $path -PathType Leaf
        $backup=Join-Path $backupRoot ("file-$index")
        if($existed){Copy-Item -LiteralPath $path -Destination $backup -Force -ErrorAction Stop}
        [void]$changes.Add([pscustomobject]@{Path=$path;Existed=$existed;Backup=$backup})
        $index++
    }
    $copied=$true
    foreach($file in $files){
        $relative=$file.FullName.Substring($payload.TrimEnd('\').Length+1)
        $target=Join-Path $gamePath $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
        if((Get-AlbaFileSha256 $file.FullName) -ne (Get-AlbaFileSha256 $target)){throw "Copied file differs from the archive: $relative"}
    }
    $proof=@($REQUIRED_LOADER+$REQUIRED_MOD+@('PCVRHub Start Alba VR.bat','.pcvrhub_alba_mode','VRMODE.txt'))
    foreach($relative in $proof){if(-not(Test-Path -LiteralPath (Join-Path $gamePath $relative) -PathType Leaf)){throw "Required Alba VR file is missing: $relative"}}
    Start-Sleep -Milliseconds 500
    foreach($file in $files){
        $relative=$file.FullName.Substring($payload.TrimEnd('\').Length+1)
        $target=Join-Path $gamePath $relative
        if(-not(Test-Path -LiteralPath $target -PathType Leaf) -or (Get-AlbaFileSha256 $file.FullName) -ne (Get-AlbaFileSha256 $target)){throw "Installed file changed or disappeared: $relative"}
    }
    Save-InstalledStamp -GameDir $gamePath -Version $MOD_VERSION -HubDir $PSScriptRoot
    $stamp=Join-Path $gamePath '.pcvrhub_version'
    if(-not(Test-Path -LiteralPath $stamp -PathType Leaf) -or ([IO.File]::ReadAllText($stamp)).Trim() -ne $MOD_VERSION){throw 'The AlbaVR version receipt was not written.'}
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$gamePath,[Text.UTF8Encoding]::new($false))
    $copied=$false
    Write-OK "BepInEx and AlbaVR files verified; $MOD_VERSION recorded."
}catch{
    if($copied){
        $rollbackFailed=$false
        foreach($item in $changes){
            try{
                if($item.Existed){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $item.Path));Copy-Item -LiteralPath $item.Backup -Destination $item.Path -Force -ErrorAction Stop}
                elseif(Test-Path -LiteralPath $item.Path -PathType Leaf){Remove-Item -LiteralPath $item.Path -Force -ErrorAction Stop}
            }catch{$rollbackFailed=$true;Write-Fail "Could not restore $($item.Path): $_"}
        }
        if($rollbackFailed){$keepWork=$true;Write-Warn "Recovery copies remain in $backupRoot"}
    }
    throw
}finally{
    if(-not $keepWork -and (Test-Path -LiteralPath $tempDir -PathType Container)){
        $tempFull=[IO.Path]::GetFullPath($env:TEMP).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
        $workFull=[IO.Path]::GetFullPath($tempDir)
        if($workFull.StartsWith($tempFull,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $workFull) -like 'AlbaVRInstaller_*'){
            Remove-Item -LiteralPath $workFull -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# STEP 4: Desktop shortcut
Write-Step 4 4 "Creating Desktop Shortcut"

try {
  $shortcut = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Alba VR.lnk" -TargetPath (Join-Path $gamePath 'PCVRHub Start Alba VR.bat') -WorkingDir $gamePath -IconPath "$gameExe,0" -Description "Alba VR ($vrModeText)"
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

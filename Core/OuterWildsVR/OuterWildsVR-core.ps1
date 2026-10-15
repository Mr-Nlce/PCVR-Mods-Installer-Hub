# ============================================================
#  Outer Wilds - NomaiVR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "NomaiVR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")
. (Join-Path $PSScriptRoot "..\Modules\OwnedModFiles.ps1")

$GAME_FOLDER  = "Outer Wilds"
$GAME_EXE     = "OuterWilds.exe"
$OWML_URL     = "https://github.com/ow-mods/owml/releases/download/2.16.3/OWML.zip"
$MOD_URL      = "https://github.com/Raicuparta/nomai-vr/releases/download/2.10.0/Raicuparta.NomaiVR.zip"
$INFO_URL     = "https://outerwildsmods.com/mods/nomaivr/"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host "   Outer Wilds - NomaiVR Installer" -ForegroundColor Yellow; Write-Host "   OWML 2.16.3  +  NomaiVR 2.10.0 by Raicuparta" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host "" }
function Write-Step   { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK     { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Warn   { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail   { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-Info   { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
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

# STEP 1: Locate Outer Wilds
Write-Host " NomaiVR by Raicuparta & artumino - the whole of Outer Wilds playable" -ForegroundColor White
Write-Host " in VR with 6DOF tracking and motion controls." -ForegroundColor White
Write-Host ""
Write-Host " Unsigned mod files can trigger antivirus warnings. If a required file" -ForegroundColor Gray
Write-Host " is missing, review the installer log and use its retry/manual recovery." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Locating Outer Wilds"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = Get-PCVRRememberedGameFolder -GameId 'outer-wilds-vr' -ProbeFiles @($GAME_EXE)
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        if (-not $gamePath) { $gamePath = Try-FindSteamGame -Folder $GAME_FOLDER -Title "Outer Wilds" -ExeName $GAME_EXE }
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath

if (-not $gamePath -and $steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $c = Join-Path $lib "steamapps\common\$GAME_FOLDER"
        if (Test-Path (Join-Path $c $GAME_EXE) -PathType Leaf) { $gamePath = $c; break }
    }
}

if ($gamePath -and -not (Test-Path (Join-Path $gamePath $GAME_EXE) -PathType Leaf)) { $gamePath=$null }
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "753640" -SteamFolderNames @("Outer Wilds") -ProbeExe $GAME_EXE -EpicNames @("Outer Wilds","OuterWilds") -HubGameId 'outer-wilds-vr' }
if ($gamePath) {
    Write-OK "Outer Wilds found: $gamePath"
} else {
    Write-Warn "Outer Wilds not found in Steam libraries automatically."
    Write-Host ""
    Write-Host "  Xbox / Game Pass users: please follow the manual setup guide first." -ForegroundColor Yellow
    Write-Host "  Guide: $INFO_URL" -ForegroundColor Cyan
    Write-Host ""
    $openGuide = Read-Host "  Open the Xbox/GamePass guide in browser? [Y/N]"
    if ($openGuide -match "^[yY]") { Start-Process $INFO_URL }
    Write-Host ""
    Write-Host "  Enter your Outer Wilds installation folder:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Outer Wilds" -ForegroundColor Gray
    while (-not $gamePath) {
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (-not $r -or $r -match '^(?i:q|quit)$') { throw 'No verified Outer Wilds game folder was selected. Nothing was installed.' }
        if ((Test-Path -LiteralPath $r -PathType Leaf) -and (Split-Path -Leaf $r) -ieq $GAME_EXE) { $r=Split-Path -Parent $r }
        if (Test-Path (Join-Path $r $GAME_EXE) -PathType Leaf) { $gamePath = $r; Write-OK "Path set: $gamePath" }
        else { Write-Fail "$GAME_EXE not found in: $r" }
    }
}
if (-not (Test-Path (Join-Path $gamePath $GAME_EXE) -PathType Leaf)) { throw "The selected folder does not contain $GAME_EXE." }
if (@(Get-Process -Name 'OuterWilds' -ErrorAction SilentlyContinue).Count) { throw 'Close Outer Wilds before installing or updating NomaiVR.' }

# STEP 2: Download
Write-Step 2 4 "Downloading OWML + NomaiVR"

$tempDir = Join-Path $env:TEMP "OuterWildsVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "  Downloading OWML 2.16.3 ... " -NoNewline -ForegroundColor White
$owmlZip = Join-Path $tempDir "OWML.zip"
$r = Invoke-DownloadOrFallback -Url $OWML_URL -Destination $owmlZip `
        -Label "OWML v2.16.3" `
        -ManualUrl "https://github.com/ow-mods/owml/releases/tag/2.16.3" `
        -Instructions "Download 'OWML.zip' from the GitHub releases page. Place it at '$owmlZip' and choose Retry." `
        -SkipMessage "Skipped - OWML mod loader missing; NomaiVR will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without OWML. Press Enter to exit..."; exit 1 }

Write-Host "  Downloading NomaiVR 2.10.0 ... " -NoNewline -ForegroundColor White
$modZip = Join-Path $tempDir "NomaiVR.zip"
$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "NomaiVR v2.10.0" `
        -ManualUrl "https://github.com/Raicuparta/nomai-vr/releases/tag/2.10.0" `
        -Instructions "Download 'Raicuparta.NomaiVR.zip' from the GitHub releases page. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - NomaiVR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without NomaiVR. Press Enter to exit..."; exit 1 }

# STEP 3: stage both archives away from the live game, then verify them.
Write-Step 3 4 "Checking OWML and NomaiVR packages"
$owmlStage = Join-Path $tempDir 'owml-stage'
$nomaiStage = Join-Path $tempDir 'nomai-stage'
foreach ($item in @(@($owmlZip,$owmlStage,'OWML'),@($modZip,$nomaiStage,'NomaiVR'))) {
    $safe = Test-ZipArchiveEntrySafety -ArchivePath $item[0] -DestinationFolder $item[1]
    if (-not $safe.Inspectable -or -not $safe.Safe) { throw "$($item[2]) ZIP is unreadable or has unsafe paths. The game was not changed." }
    $result = Expand-ArchiveOrFallback -ArchivePath $item[0] -DestinationFolder $item[1] -Label $item[2] -AllowSkip $false
    if ([string]$result -notin @('ok','manual','retry')) { throw "$($item[2]) extraction did not complete. The game was not changed." }
}
$owmlRequired = @('OWML.Launcher.exe','OWML.ModLoader.dll','OWML.DefaultConfig.json','0Harmony.dll')
$nomaiRequired = @('manifest.json','NomaiVR.dll','patcher\NomaiVRPatcher.dll')
foreach ($relative in $owmlRequired) {
    $file=Join-Path $owmlStage $relative
    if (-not (Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -le 0) { throw "OWML package lacks $relative. The game was not changed." }
}
foreach ($relative in $nomaiRequired) {
    $file=Join-Path $nomaiStage $relative
    if (-not (Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -le 0) { throw "NomaiVR package lacks $relative. The game was not changed." }
}
$publisherManifest=Get-Content -LiteralPath (Join-Path $nomaiStage 'manifest.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
if ($publisherManifest.uniqueName -ne 'Raicuparta.NomaiVR' -or -not (Test-IsTrackableInstalledVersion -Version ([string]$publisherManifest.version))) {
    throw 'NomaiVR manifest has the wrong mod identity or no usable version. The game was not changed.'
}
$modVersion=[string]$publisherManifest.version
$owmlPath=Join-Path $gamePath 'OWML'
$modTargetPath=Join-Path $owmlPath 'Mods\Raicuparta.NomaiVR'
$legacyManifest=Join-Path $modTargetPath 'manifest.json'
$ownedManifest=Join-Path $modTargetPath '.pcvrhub_nomaivr_ownership.csv'
$legacyFolder=$null
$legacyBackup=$null
if ((Test-Path -LiteralPath $legacyManifest -PathType Leaf) -and -not (Test-Path -LiteralPath $ownedManifest -PathType Leaf)) {
    $legacy=Get-Content -LiteralPath $legacyManifest -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($legacy.uniqueName -ne 'Raicuparta.NomaiVR') { throw 'An unrelated mod occupies the NomaiVR folder. No files were changed.' }
    $legacyFolder=$modTargetPath
    $legacyBackup=Join-Path (Split-Path -Parent $modTargetPath) ('.pcvrhub_NomaiVR_legacy_'+[guid]::NewGuid().ToString('N').Substring(0,8))
    Write-Info "An earlier NomaiVR folder will be preserved at $legacyBackup before replacement."
}
$configFile=Join-Path $owmlPath 'OWML.Config.json'
$configSource=if (Test-Path -LiteralPath $configFile -PathType Leaf) { $configFile } else { Join-Path $owmlStage 'OWML.DefaultConfig.json' }
$cfg=Get-Content -LiteralPath $configSource -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
$cfg.gamePath=$gamePath.Replace('\','/')
$cfg | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $owmlStage 'OWML.Config.json') -Encoding UTF8 -ErrorAction Stop
$writableProbe=Join-Path $gamePath ('.pcvrhub_probe_'+[guid]::NewGuid().ToString('N'))
try { [IO.File]::WriteAllText($writableProbe,'ok'); Remove-Item -LiteralPath $writableProbe -Force -ErrorAction Stop }
catch { throw "The game folder is not writable: $gamePath" }

# STEP 4: snapshot only files these two packages can change, including the
# ownership records and prior receipts. This leaves other OWML mods and saves alone.
Write-Step 4 4 "Installing verified files"
$packages=@(
    [pscustomobject]@{Stage=$owmlStage;Root=$owmlPath;Identity='outerwilds_owml'},
    [pscustomobject]@{Stage=$nomaiStage;Root=$modTargetPath;Identity='nomaivr'}
)
$snapshot=Join-Path $tempDir 'rollback'
New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
$tracked=New-Object System.Collections.Generic.List[object]
$backupStates=New-Object System.Collections.Generic.List[object]
foreach ($pkg in $packages) {
    $pkgFiles=@(Get-ChildItem -LiteralPath $pkg.Stage -Recurse -File -ErrorAction Stop | ForEach-Object { Assert-PCVROwnedRelativePath -Relative ($_.FullName.Substring($pkg.Stage.Length+1)) })
    $manifest=Join-Path $pkg.Root ('.pcvrhub_'+$pkg.Identity+'_ownership.csv')
    $prior=@()
    if (Test-Path -LiteralPath $manifest -PathType Leaf) { $prior=@(Import-Csv -LiteralPath $manifest -ErrorAction Stop | ForEach-Object { Assert-PCVROwnedRelativePath -Relative ([string]$_.RelativePath) }) }
    foreach ($relative in @(($pkgFiles+$prior) | Select-Object -Unique)) { [void]$tracked.Add((Join-Path $pkg.Root $relative)) }
    [void]$tracked.Add($manifest)
    $backup=Join-Path $pkg.Root ('.pcvrhub_'+$pkg.Identity+'_backup')
    $backupCopy=Join-Path $snapshot ($pkg.Identity+'_backup')
    $hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if ($hadBackup) { Copy-Item -LiteralPath $backup -Destination $backupCopy -Recurse -Force -ErrorAction Stop }
    [void]$backupStates.Add([pscustomobject]@{Live=$backup;Copy=$backupCopy;Existed=$hadBackup})
}
[void]$tracked.Add((Join-Path $gamePath '.pcvrhub_version'))
[void]$tracked.Add((Join-Path $PSScriptRoot '.installed_path'))
$fileStates=New-Object System.Collections.Generic.List[object]
$i=0
foreach ($live in @($tracked | Select-Object -Unique)) {
    $copy=Join-Path $snapshot ("file-$i")
    $existed=Test-Path -LiteralPath $live -PathType Leaf
    if ($existed) { Copy-Item -LiteralPath $live -Destination $copy -Force -ErrorAction Stop }
    [void]$fileStates.Add([pscustomobject]@{Live=$live;Copy=$copy;Existed=$existed})
    $i++
}
$contract=New-PCVRInstallerContract -Id 'outer-wilds-vr' -GameName 'Outer Wilds' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl 'https://github.com/Raicuparta/nomai-vr/releases' `
    -RequiredInstalledFileGroups @('OuterWilds.exe','OWML\OWML.Launcher.exe','OWML\OWML.ModLoader.dll','OWML\0Harmony.dll',
        'OWML\Mods\Raicuparta.NomaiVR\manifest.json','OWML\Mods\Raicuparta.NomaiVR\NomaiVR.dll',
        'OWML\Mods\Raicuparta.NomaiVR\patcher\NomaiVRPatcher.dll',
        'OWML\.pcvrhub_outerwilds_owml_ownership.csv','OWML\Mods\Raicuparta.NomaiVR\.pcvrhub_nomaivr_ownership.csv')
try {
    if ($legacyFolder) { Move-Item -LiteralPath $legacyFolder -Destination $legacyBackup -ErrorAction Stop }
    [void](Install-OwnedModPayload -SourceRoot $owmlStage -GameRoot $owmlPath -Identity 'outerwilds_owml' `
        -AdoptIdenticalExisting -ReplaceChangedOwnedRelativePaths @('OWML.Config.json'))
    [void](Install-OwnedModPayload -SourceRoot $nomaiStage -GameRoot $modTargetPath -Identity 'nomaivr' -AdoptIdenticalExisting)
    foreach ($pkg in $packages) {
        foreach ($file in @(Get-ChildItem -LiteralPath $pkg.Stage -Recurse -File -ErrorAction Stop)) {
            $relative=$file.FullName.Substring($pkg.Stage.Length+1)
            $target=Join-Path $pkg.Root $relative
            if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or
                (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
                throw "Copied file missing or changed: $relative"
            }
        }
    }
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gamePath -Version $modVersion `
        -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
    Write-OK "OWML and NomaiVR $modVersion verified. Other OWML mods and saves are untouched."
} catch {
    $failure=$_
    foreach ($state in $fileStates) {
        if ($state.Existed) {
            $parent=Split-Path -Parent $state.Live
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $state.Copy -Destination $state.Live -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $state.Live -PathType Leaf) { Remove-Item -LiteralPath $state.Live -Force -ErrorAction Stop }
    }
    foreach ($state in $backupStates) {
        if (Test-Path -LiteralPath $state.Live -PathType Container) { Remove-Item -LiteralPath $state.Live -Recurse -Force -ErrorAction Stop }
        if ($state.Existed) { Copy-Item -LiteralPath $state.Copy -Destination $state.Live -Recurse -Force -ErrorAction Stop }
    }
    if ($legacyFolder -and (Test-Path -LiteralPath $legacyBackup -PathType Container)) {
        if (Test-Path -LiteralPath $legacyFolder -PathType Container) { Remove-Item -LiteralPath $legacyFolder -Recurse -Force -ErrorAction Stop }
        Move-Item -LiteralPath $legacyBackup -Destination $legacyFolder -ErrorAction Stop
    }
    throw $failure
}

# Create Desktop shortcut to OWML.Launcher.exe
$owmlLauncher = Join-Path $owmlPath "OWML.Launcher.exe"
if (Test-Path $owmlLauncher) {
    try {
         $gameExePath = Join-Path $gamePath "OuterWilds.exe"
         $shortcut = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Outer Wilds VR.lnk" -TargetPath $owmlLauncher -WorkingDir $owmlPath -IconPath "$gameExePath,0" -Description "Outer Wilds VR (NomaiVR via OWML)"
        Write-OK "Desktop shortcut created: 'Outer Wilds VR'"
    } catch {
        Write-Warn "Could not create desktop shortcut: $_"
        Write-Info "Launch manually: $owmlLauncher"
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Done
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Launch with" -NoNewline -ForegroundColor Green; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the desktop" -ForegroundColor Green
Write-Host "  shortcut 'Outer Wilds VR'" -ForegroundColor Green
Write-Host "  or directly from:" -ForegroundColor White
Write-Host "  $owmlLauncher" -ForegroundColor Gray
Write-Host ""
Write-Host "  After an install or update, start with OWML.Launcher.exe once." -ForegroundColor Yellow
Write-Host "  Later Steam/Epic starts may work if the store login is connected." -ForegroundColor Gray
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "  Full motion controls supported!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  The Hatchling sets out. Twenty-two minutes is plenty of time." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."

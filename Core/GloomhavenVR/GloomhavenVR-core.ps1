# Gloomhaven VR - governed Current / pinned Steam-depot installer.
# Current follows official stable GitHub releases. Depot keeps game build
# 20286313, Gloomhaven 1.1.8307.0, GloomhavenVR v1.0.1 and BepInEx 5.4.23.5.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Gloomhaven VR Installer'
$APP_ID = '780290'
$DEPOT_ID = '780291'
$DEPOT_MANIFEST = '7912725515517904339'
$PINNED_BUILD = '20286313'
$PINNED_GAME_VERSION = '1.1.8307.0'
$PINNED_MOD_TAG = 'v1.0.1'
$PINNED_MOD_NAME = 'GloomhavenVR-1.0.1.zip'
$PINNED_MOD_URL = 'https://github.com/McFredward/GloomhavenVR/releases/download/v1.0.1/GloomhavenVR-1.0.1.zip'
$CURRENT_FALLBACK_TAG = 'v1.0.7'
$CURRENT_FALLBACK_NAME = 'GloomhavenVR-1.0.7.zip'
$CURRENT_FALLBACK_URL = 'https://github.com/McFredward/GloomhavenVR/releases/download/v1.0.7/GloomhavenVR-1.0.7.zip'
$BEPINEX_VERSION = '5.4.23.5'
$BEPINEX_NAME = 'BepInEx_win_x64_5.4.23.5.zip'
$BEPINEX_URL = 'https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.5/BepInEx_win_x64_5.4.23.5.zip'
$REPO = 'McFredward/GloomhavenVR'
$RELEASES_URL = "https://github.com/$REPO/releases"
$GAME_EXE = 'GH.exe'
$IDENTITY = 'gloomhavenvr'
$DEPOT_DEFAULT_PATH = 'C:\Games\Gloomhaven VR 20286313'
$DEPOT_MARKER = '.pcvrhub_gloomhaven_depot_20286313'
$DEPOT_LAUNCHER = 'Start Gloomhaven VR Depot.bat'
$QUIP = 'The cards are finally in your hands. Try not to exhaust them all at once.'
$PINNED_GAME_HASHES = @{
    'GH.exe' = 'A2A1BACE9F3AE2C9F1AE66918B461D9DC11E7F3FC7D4E1E2A413A3AF36D3381B'
    'UnityPlayer.dll' = 'EE6C7F727297FB9BF9F32D7017C9FFB77AAEC2FAC88BA01175EA25B55DA5CBD1'
    'GH_Data\globalgamemanagers' = 'C34DE6B98E6A80912CDC2C485D9D6112AD9A1B357F9F13F717533A5C584D3CAB'
}
$REQUIRED_MOD_FILES = @(
    'BepInEx\plugins\GloomhavenVR\GloomhavenVR.dll',
    'BepInEx\plugins\GloomhavenVR\gloomhavenvr.bundle',
    'BepInEx\plugins\GloomhavenVR\RuntimeDeps\Unity.XR.OpenXR.dll',
    'BepInEx\plugins\GloomhavenVR\RuntimeDeps\Unity.XR.Management.dll',
    'BepInEx\plugins\GloomhavenVR\RuntimeDeps\Unity.XR.CoreUtils.dll',
    'BepInEx\patchers\GloomhavenVR\GloomhavenVR.Preload.dll',
    'BepInEx\patchers\GloomhavenVR\Natives\UnityOpenXR.dll',
    'BepInEx\patchers\GloomhavenVR\Natives\openxr_loader.dll'
)
$REQUIRED_LOADER_FILES = @('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll')

$currentContract = New-PCVRInstallerContract -Id 'gloomhaven-vr' -GameName 'Gloomhaven VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES_URL `
    -RequiredInstalledFileGroups @(@('winhttp.dll|winhttp.dll.pcvrhub_off') + $REQUIRED_LOADER_FILES[1..($REQUIRED_LOADER_FILES.Count-1)] + $REQUIRED_MOD_FILES + ".pcvrhub_${IDENTITY}_ownership.csv")
$depotContract = New-PCVRInstallerContract -Id 'gloomhaven-vr' -GameName 'Gloomhaven VR' `
    -Acquisition SteamDepot -PinnedDepot -AntivirusNotice -ReleasePageUrl "$RELEASES_URL/tag/$PINNED_MOD_TAG" `
    -Routes @("Depot-$PINNED_BUILD") `
    -RequiredInstalledFileGroups @(@('winhttp.dll|winhttp.dll.pcvrhub_off') + $REQUIRED_LOADER_FILES[1..($REQUIRED_LOADER_FILES.Count-1)] + $REQUIRED_MOD_FILES + @(
        ".pcvrhub_${IDENTITY}_ownership.csv",$DEPOT_MARKER,'steam_appid.txt',$DEPOT_LAUNCHER
    ))

function Write-GloomStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-GloomOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-GloomInfo([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }
function Write-GloomWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Read-GloomChoice([string[]]$Allowed,[string]$Prompt) {
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $choice=('' + (Read-Host $Prompt)).Trim().ToUpperInvariant()
        if ($choice -in $Allowed) { return $choice }
        Write-GloomWarn "Choose $($Allowed -join ', ')."
    }
    throw 'No valid setup option was selected after 10 attempts.'
}

function Test-GloomRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue))
}

function Get-GloomRelease([ValidateSet('Current','Depot')][string]$InstallMode='Current') {
    if ($InstallMode -eq 'Depot') {
        return [pscustomobject]@{ Tag=$PINNED_MOD_TAG; Url=$PINNED_MOD_URL; Name=$PINNED_MOD_NAME; PageUrl="$RELEASES_URL/tag/$PINNED_MOD_TAG"; Pinned=$true }
    }
    $release=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^GloomhavenVR-[0-9].*\.zip$') `
        -FallbackUrl $CURRENT_FALLBACK_URL -FallbackTag $CURRENT_FALLBACK_TAG -FallbackAssetName $CURRENT_FALLBACK_NAME
    return [pscustomobject]@{ Tag=[string]$release.Tag; Url=[string]$release.Url; Name=[string]$release.AssetName; PageUrl=[string]$release.PageUrl; Pinned=$false }
}

function Get-GloomPayloadVersion([string]$Root) {
    $dll=Join-Path $Root 'BepInEx\plugins\GloomhavenVR\GloomhavenVR.dll'
    if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) { return $null }
    try {
        $version=[Reflection.AssemblyName]::GetAssemblyName($dll).Version
        if (-not $version) { return $null }
        return ('v{0}.{1}.{2}' -f $version.Major,$version.Minor,$version.Build)
    } catch { return $null }
}

function Test-GloomPayload([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
    foreach ($relative in $REQUIRED_MOD_FILES) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    return [bool](Get-GloomPayloadVersion $Root)
}

function Test-GloomLoaderPayload([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
    foreach ($relative in $REQUIRED_LOADER_FILES) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    try {
        $version=[Reflection.AssemblyName]::GetAssemblyName((Join-Path $Root 'BepInEx\core\BepInEx.dll')).Version
        return [bool]($version -and ("$($version.Major).$($version.Minor).$($version.Build)" -eq '5.4.23'))
    } catch { return $false }
}

function New-GloomStage([string]$BepInExRoot,[string]$ModRoot,[string]$Stage,[switch]$Depot) {
    if (-not (Test-GloomLoaderPayload $BepInExRoot)) { throw "The BepInEx archive is not the required x64 $BEPINEX_VERSION payload." }
    if (-not (Test-GloomPayload $ModRoot)) { throw 'The GloomhavenVR archive is missing a required plugin, patcher, native OpenXR file or asset bundle.' }
    [void][IO.Directory]::CreateDirectory($Stage)
    foreach ($file in @(Get-ChildItem -LiteralPath $BepInExRoot -Recurse -File -ErrorAction Stop)) {
        $relative=$file.FullName.Substring(([IO.Path]::GetFullPath($BepInExRoot).TrimEnd('\','/')).Length+1)
        $target=Join-Path $Stage $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
    foreach ($prefix in @('BepInEx\plugins\GloomhavenVR','BepInEx\patchers\GloomhavenVR')) {
        $source=Join-Path $ModRoot $prefix
        if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Release payload is missing $prefix." }
        $target=Join-Path $Stage $prefix
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
    }
    if ($Depot) { Write-GloomDepotStageFiles -Stage $Stage }
    if (-not (Test-GloomLoaderPayload $Stage) -or -not (Test-GloomPayload $Stage)) { throw 'The combined install stage failed its functional payload check.' }
    return $Stage
}

function Get-GloomDepotMarkerText {
    return (@(
        "AppId=$APP_ID","DepotId=$DEPOT_ID","Manifest=$DEPOT_MANIFEST","BuildId=$PINNED_BUILD",
        "GameVersion=$PINNED_GAME_VERSION","GloomhavenVR=$PINNED_MOD_TAG","BepInEx=$BEPINEX_VERSION"
    ) -join "`r`n")
}

function Write-GloomDepotStageFiles([string]$Stage) {
    [IO.File]::WriteAllText((Join-Path $Stage 'steam_appid.txt'),$APP_ID,[Text.Encoding]::ASCII)
    $launcher=@(
        '@echo off','setlocal','cd /d "%~dp0"','start "" "%~dp0GH.exe"','exit /b 0'
    ) -join "`r`n"
    [IO.File]::WriteAllText((Join-Path $Stage $DEPOT_LAUNCHER),$launcher,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $Stage $DEPOT_MARKER),(Get-GloomDepotMarkerText),(New-Object Text.UTF8Encoding $false))
}

function Test-GloomDepotMarker([string]$Path) {
    if (-not $Path) { return $false }
    $marker=Join-Path $Path $DEPOT_MARKER
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { return $false }
    try {
        $text=[IO.File]::ReadAllText($marker)
        foreach ($line in @((Get-GloomDepotMarkerText) -split '\r?\n')) {
            if ($text -notmatch ('(?m)^'+[regex]::Escape($line)+'\s*$')) { return $false }
        }
        return $true
    } catch { return $false }
}

function Test-GloomPinnedFiles([string]$Path,[hashtable]$ExpectedHashes=$PINNED_GAME_HASHES) {
    if (-not (Test-GloomRoot $Path)) { return $false }
    foreach ($pair in $ExpectedHashes.GetEnumerator()) {
        $file=Join-Path $Path ([string]$pair.Key)
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $false }
        try { if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne [string]$pair.Value) { return $false } }
        catch { return $false }
    }
    return $true
}

function Test-GloomSteamPinnedManifest([string]$GameRoot) {
    if (-not (Test-GloomPinnedFiles $GameRoot)) { return $false }
    try {
        $common=Split-Path -Parent ([IO.Path]::GetFullPath($GameRoot))
        if ((Split-Path -Leaf $common) -ine 'common') { return $false }
        $manifest=Join-Path (Split-Path -Parent $common) "appmanifest_$APP_ID.acf"
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { return $false }
        $text=[IO.File]::ReadAllText($manifest)
        return [bool]($text -match ('(?i)"buildid"\s*"'+$PINNED_BUILD+'"') -and
            $text -match ('(?is)"'+$DEPOT_ID+'"\s*\{[^{}]*"manifest"\s*"'+$DEPOT_MANIFEST+'"'))
    } catch { return $false }
}

function Test-GloomPinnedRoot([string]$Path) {
    return [bool]((Test-GloomPinnedFiles $Path) -and (Test-GloomDepotMarker $Path) -and
        (Test-Path -LiteralPath (Join-Path $Path 'steam_appid.txt') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path $DEPOT_LAUNCHER) -PathType Leaf))
}

function Get-GloomCurrentRoot {
    $path=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Gloomhaven') -ProbeExe $GAME_EXE `
        -GogNames @('Gloomhaven') -EpicNames @('Gloomhaven') -HubGameId 'gloomhaven-vr'
    if (-not (Test-GloomRoot $path)) {
        foreach ($candidate in @(
            'C:\Program Files\Epic Games\Gloomhaven',
            'C:\Program Files (x86)\GOG Galaxy\Games\Gloomhaven',
            'C:\GOG Games\Gloomhaven'
        )) { if (Test-GloomRoot $candidate) { $path=$candidate; break } }
    }
    if (-not (Test-GloomRoot $path)) {
        $path=Get-GameFolderInteractive -GameName 'Gloomhaven' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/780290/'
    }
    if ($path -in @('quit','skip',$null) -or -not (Test-GloomRoot $path)) { return $null }
    return (Get-Item -LiteralPath $path).FullName
}

function Install-GloomPinnedDepot {
    if (Test-GloomPinnedRoot $DEPOT_DEFAULT_PATH) { Write-GloomOK "Found complete pinned route: $DEPOT_DEFAULT_PATH"; return $DEPOT_DEFAULT_PATH }
    if ((Test-Path -LiteralPath $DEPOT_DEFAULT_PATH) -and @(Get-ChildItem -LiteralPath $DEPOT_DEFAULT_PATH -Force -ErrorAction SilentlyContinue).Count) {
        throw "$DEPOT_DEFAULT_PATH already exists but is not the complete Hub-managed build $PINNED_BUILD. Rename or remove that folder before retrying."
    }
    $current=Get-GloomCurrentRoot
    $cloneAllowed=Test-GloomSteamPinnedManifest $current
    if ($cloneAllowed) {
        Write-GloomOK "The installed Steam copy is still exact build $PINNED_BUILD."
        Write-Host '  [C] Clone it into the independent compatibility folder (recommended)' -ForegroundColor Cyan
        Write-Host '  [D] Download the exact depot through Steam Console' -ForegroundColor Cyan
        Write-Host '  [Q] Quit' -ForegroundColor Gray
        $sourceChoice=Read-GloomChoice -Allowed @('C','D','Q') -Prompt 'Choose depot source'
        if ($sourceChoice -eq 'Q') { throw 'Setup cancelled before creating the depot.' }
        if ($sourceChoice -eq 'C') {
            [void](Wait-PCVRExplicitEnter -Message "Press Enter to copy build $PINNED_BUILD to $DEPOT_DEFAULT_PATH...")
            [void](Copy-DirectoryTreeVerified -Source $current -Destination $DEPOT_DEFAULT_PATH)
            if (-not (Test-GloomPinnedFiles $DEPOT_DEFAULT_PATH)) { throw 'The cloned game build failed its pinned file proof.' }
            Write-GloomOK "Created independent build $PINNED_BUILD from the verified local Steam files."
            return $DEPOT_DEFAULT_PATH
        }
    }
    $command="download_depot $APP_ID $DEPOT_ID $DEPOT_MANIFEST"
    Write-Host '  Steam Console will download the complete compatible Windows build.' -ForegroundColor White
    Write-Host '  It is intended for solo play. A historical client may not remain' -ForegroundColor Yellow
    Write-Host '  compatible with current online multiplayer services.' -ForegroundColor Yellow
    Write-Host ''; Write-Host "  $command" -ForegroundColor DarkGray
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy the exact command and open Steam Console...')
    try { Set-Clipboard -Value $command -DeferManualFallback } catch {}
    foreach ($uri in @('steam://open/console','steam://nav/console')) { try { Start-Process $uri; Start-Sleep -Milliseconds 700 } catch {} }
    Show-PCVRClipboardManualFallback -Text $command
    Write-Host '  Paste with Ctrl+V in Steam Console and wait for the download to finish.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter here only after the exact depot has finished...')
    $steamRoot=Get-SteamPath
    $source=Find-SteamDepotPath -AppId $APP_ID -DepotId $DEPOT_ID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamRoot)
    if (-not $source) {
        $source=Resolve-DepotPath -GameName "Gloomhaven build $PINNED_BUILD" -DepotCommand $command -GameExe $GAME_EXE `
            -ProbePaths @(Get-SteamDepotProbePaths -AppId $APP_ID -DepotId $DEPOT_ID -AdditionalSteamRoots @($steamRoot)) `
            -AppId $APP_ID -DepotId $DEPOT_ID -Manifest $DEPOT_MANIFEST
    }
    if (-not (Test-GloomPinnedFiles $source)) { throw 'The selected Steam content is not the pinned compatible Gloomhaven build.' }
    [void](Merge-DirectoryTreeVerified -Source $source -Destination $DEPOT_DEFAULT_PATH -RemoveSource -Label "Gloomhaven build $PINNED_BUILD")
    if (-not (Test-GloomPinnedFiles $DEPOT_DEFAULT_PATH)) { throw 'The assembled depot failed its pinned file proof.' }
    Write-GloomOK "Steam build $PINNED_BUILD assembled at: $DEPOT_DEFAULT_PATH"
    return $DEPOT_DEFAULT_PATH
}

function Save-GloomSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $relatives=[Collections.Generic.List[string]]::new()
    $base=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)) { $relatives.Add($file.FullName.Substring($base.Length+1).Replace('/','\')) }
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $relatives.Add([string]$row.RelativePath) } } } catch {}
    }
    foreach ($extra in @(".pcvrhub_${IDENTITY}_ownership.csv",".pcvrhub_${IDENTITY}_ownership.csv.new",'.pcvrhub_version','winhttp.dll.pcvrhub_off')) { $relatives.Add($extra) }
    $records=@()
    foreach ($relative in @($relatives | Select-Object -Unique)) {
        $source=Join-Path $GameRoot $relative; $exists=Test-Path -LiteralPath $source -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists; Key=$key }
        if ($exists) { Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot $key) -Force }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"; $backupExists=Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force }
    return [pscustomobject]@{ Records=$records; BackupExists=$backupExists; SnapshotRoot=$SnapshotRoot }
}

function Restore-GloomSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target=Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot ([string]$record.Key)) -Destination $target -Force
        }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force }
}

function global:Invoke-GloomhavenVRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $changesStarted=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Gloomhaven VR - Installer' -ForegroundColor Cyan
        Write-Host '  Room-scale tabletop VR by McFredward' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Motion controls, physical cards and miniatures, two VR' -ForegroundColor White
        Write-Host '  environments, mixed reality and VR/flat cross-play.' -ForegroundColor White
        Write-Host '  All VR players in one session need the same mod version.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  [1] Current game with the newest stable GloomhavenVR release' -ForegroundColor Cyan
        Write-Host '      Steam, Epic and GOG are supported. This route auto-updates.' -ForegroundColor Gray
        Write-Host "  [2] Steam build $PINNED_BUILD with GloomhavenVR $PINNED_MOD_TAG" -ForegroundColor Cyan
        Write-Host "      Separate $DEPOT_DEFAULT_PATH copy for solo compatibility." -ForegroundColor Gray
        Write-Host '      The normal Steam installation remains untouched.' -ForegroundColor Gray
        Write-Host '  [Q] Quit' -ForegroundColor Gray
        Write-Host ''
        $choice=Read-GloomChoice -Allowed @('1','2','Q') -Prompt 'Select setup option'
        if ($choice -eq 'Q') { Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''; [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...'); return }
        $installMode=if ($choice -eq '2') { 'Depot' } else { 'Current' }
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        Write-GloomStep 1 5 $(if ($installMode -eq 'Depot') { "Preparing pinned Steam build $PINNED_BUILD" } else { 'Locating Gloomhaven' })
        $game=if ($installMode -eq 'Depot') { Install-GloomPinnedDepot } else { Get-GloomCurrentRoot }
        if (-not (Test-GloomRoot $game)) { throw 'Setup cancelled before any game file was changed.' }
        if (Get-Process -Name 'GH' -ErrorAction SilentlyContinue) { throw 'Gloomhaven is running. Close it completely and run setup again.' }
        if (-not (Test-InstallerTargetWritable -TargetPath $game)) { throw 'The game folder is not writable. Run this installer as administrator, then try again.' }
        Write-GloomOK "Found: $game"

        Write-GloomStep 2 5 $(if ($installMode -eq 'Depot') { "Getting pinned GloomhavenVR $PINNED_MOD_TAG and BepInEx $BEPINEX_VERSION" } else { "Getting the newest stable GloomhavenVR release and BepInEx $BEPINEX_VERSION" })
        $release=Get-GloomRelease $installMode
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_gloomhaven_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $modArchive=Join-Path $work 'GloomhavenVR.zip'; $loaderArchive=Join-Path $work 'BepInEx.zip'
        $gotMod=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $modArchive -Label "GloomhavenVR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($gotMod -eq $true -or [string]$gotMod -in @('retry','manual'))) { throw 'The GloomhavenVR release was not downloaded.' }
        $gotLoader=Invoke-SafeDownload -Urls @($BEPINEX_URL) -Destination $loaderArchive -Label "BepInEx $BEPINEX_VERSION x64" -ManualUrl 'https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.5' -AllowSkip $false
        if (-not ($gotLoader -eq $true -or [string]$gotLoader -in @('retry','manual'))) { throw 'The required BepInEx release was not downloaded.' }
        $modExtract=Join-Path $work 'mod'; $loaderExtract=Join-Path $work 'loader'
        if ([string](Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modExtract -Label 'GloomhavenVR release' -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')) { throw 'The GloomhavenVR archive could not be extracted.' }
        if ([string](Expand-ArchiveOrFallback -ArchivePath $loaderArchive -DestinationFolder $loaderExtract -Label 'BepInEx release' -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')) { throw 'The BepInEx archive could not be extracted.' }
        $stage=New-GloomStage -BepInExRoot $loaderExtract -ModRoot $modExtract -Stage (Join-Path $work 'stage') -Depot:($installMode -eq 'Depot')
        $actualVersion=Get-GloomPayloadVersion $stage
        if (-not (Test-IsTrackableInstalledVersion $actualVersion)) { throw 'The downloaded package has no readable installed mod version.' }
        if ($installMode -eq 'Depot' -and $actualVersion -ne $PINNED_MOD_TAG) { throw "The depot package reports $actualVersion instead of pinned $PINNED_MOD_TAG." }
        Write-GloomOK "Verified functional payload version $actualVersion."

        Write-GloomStep 3 5 'Preparing a recoverable BepInEx and mod transaction'
        $snapshot=Save-GloomSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'snapshot')
        $changesStarted=$true
        $wasFlat=(Test-Path -LiteralPath (Join-Path $game 'winhttp.dll.pcvrhub_off') -PathType Leaf) -and -not (Test-Path -LiteralPath (Join-Path $game 'winhttp.dll') -PathType Leaf)
        if ($wasFlat) { Move-Item -LiteralPath (Join-Path $game 'winhttp.dll.pcvrhub_off') -Destination (Join-Path $game 'winhttp.dll') -Force }

        Write-GloomStep 4 5 'Installing and verifying GloomhavenVR'
        $publisherOwned=@(Get-ChildItem -LiteralPath $stage -Recurse -File | ForEach-Object {
            $_.FullName.Substring(([IO.Path]::GetFullPath($stage).TrimEnd('\','/')).Length+1).Replace('/','\')
        } | Where-Object { $_ -like 'BepInEx\plugins\GloomhavenVR\*' -or $_ -like 'BepInEx\patchers\GloomhavenVR\*' })
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY `
            -ReplaceChangedOwnedRelativePaths $publisherOwned -AdoptIdenticalExisting)
        if ($wasFlat -and (Test-Path -LiteralPath (Join-Path $game 'winhttp.dll') -PathType Leaf)) {
            Move-Item -LiteralPath (Join-Path $game 'winhttp.dll') -Destination (Join-Path $game 'winhttp.dll.pcvrhub_off') -Force
        }
        $watch=@($REQUIRED_LOADER_FILES + $REQUIRED_MOD_FILES + ".pcvrhub_${IDENTITY}_ownership.csv") | ForEach-Object {
            if ($wasFlat -and $_ -eq 'winhttp.dll') { Join-Path $game 'winhttp.dll.pcvrhub_off' } else { Join-Path $game $_ }
        }
        if ($installMode -eq 'Depot') { $watch += @($DEPOT_MARKER,'steam_appid.txt',$DEPOT_LAUNCHER) | ForEach-Object { Join-Path $game $_ } }
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)) { throw 'The required GloomhavenVR files did not survive the post-copy check.' }
        $installedVersion=Get-GloomPayloadVersion $game
        if ($installedVersion -ne $actualVersion) { throw "Installed plugin reports $installedVersion instead of $actualVersion." }
        Write-GloomOK 'BepInEx, plugin, patcher, OpenXR runtime and asset bundle verified.'

        Write-GloomStep 5 5 'Committing route, version and launch state'
        if ($installMode -eq 'Depot' -and -not (Test-GloomPinnedRoot $game)) { throw 'The completed depot route failed its build, manifest-marker or launch-file proof.' }
        $receipt=Join-Path $PSScriptRoot $(if ($installMode -eq 'Depot') { '.installed_path_depot' } else { '.installed_path' })
        $contract=if ($installMode -eq 'Depot') { $depotContract } else { $currentContract }
        $route=if ($installMode -eq 'Depot') { "Depot-$PINNED_BUILD" } else { 'Current' }
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $actualVersion -InstalledPathReceiptPaths @($receipt) -Route $route)
        $changesStarted=$false
        if ($installMode -eq 'Depot') {
            try {
                [void](New-DesktopShortcut -ShortcutName "Gloomhaven VR $PINNED_BUILD" -TargetPath (Join-Path $game $DEPOT_LAUNCHER) `
                    -WorkingDir $game -IconPath ((Join-Path $game $GAME_EXE)+',0') -Description "Launch pinned Gloomhaven VR build $PINNED_BUILD")
                Write-GloomOK 'Desktop shortcut created for the pinned depot route.'
            } catch { Write-GloomWarn 'The depot is complete, but its optional desktop shortcut could not be created.' }
        } else {
            if ($game -match '(?i)steamapps\common|\\Steam\\') { Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.launch_exe') -Force -ErrorAction SilentlyContinue }
            else { [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.launch_exe'),(Join-Path $game $GAME_EXE),(New-Object Text.UTF8Encoding $false)) }
        }

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Gloomhaven VR is ready' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        if ($installMode -eq 'Depot') {
            Write-Host "  Route: Steam build $PINNED_BUILD / game $PINNED_GAME_VERSION / mod $actualVersion" -ForegroundColor White
            Write-Host '  Start it from the new desktop shortcut. This route is intended' -ForegroundColor White
            Write-Host '  for solo play; use Current for online multiplayer.' -ForegroundColor Yellow
        } else {
            Write-Host "  Installed: GloomhavenVR $actualVersion with BepInEx $BEPINEX_VERSION" -ForegroundColor White
            Write-Host '  Start the game normally through Steam, Epic or GOG.' -ForegroundColor White
        }
        Write-Host '  Set your OpenXR runtime before launch. The first start can take' -ForegroundColor Yellow
        Write-Host '  longer while BepInEx initializes, and the game may restart once' -ForegroundColor Yellow
        Write-Host '  while the mod applies its rendering settings; this is expected.' -ForegroundColor Yellow
        Write-Host '  Play the first tutorial for the VR interactions and controls.' -ForegroundColor Gray
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot) {
            try { Restore-GloomSnapshot -GameRoot $game -Snapshot $snapshot; Write-GloomWarn 'The previous Gloomhaven folder state was restored.' }
            catch { Write-GloomWarn ('Rollback also needs attention: '+$_.Exception.Message) }
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_GLOOMHAVEN_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-GloomhavenVRInstaller }

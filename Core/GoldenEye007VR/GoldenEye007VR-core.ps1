# GoldenEye 007 VR - governed standalone OpenXR installer.
# The official GEVR package never contains a commercial ROM. On first launch,
# its own ROM starter asks the user for a legally owned USA ROM and keeps that
# path, generated cache and saves below LocalAppData.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'GoldenEye 007 VR Installer'
$REPO = 'no6969el/GEVR'
$FALLBACK_TAG = 'vr444.1'
$FALLBACK_ASSET = 'GEVR-Beta-vr444.1-win64.zip'
$FALLBACK_URL = 'https://github.com/no6969el/GEVR/releases/download/vr444.1/GEVR-Beta-vr444.1-win64.zip'
$RELEASES_URL = "https://github.com/$REPO/releases"
$DEFAULT_TARGET = 'C:\Games\GoldenEye 007 VR'
$IDENTITY = 'goldeneye007vr'
$READY_MARKER = '.pcvrhub_ready'
$HUB_LAUNCHER = 'Start-GEVR-Hub.bat'
$ICON_NAME = 'GoldenEye007VR.ico'
$QUIP = 'For England, James? No. For the headset.'
$REQUIRED_RUNTIME = @(
    'Clear-GEVR-cache.bat','EXPECTED-ROM.txt','filelist.gevr-images.csv','gevr_prepare.exe','GevrRomStarter.exe',
    'glew32.dll','goldeneye.exe','libgcc_s_seh-1.dll','libstdc++-6.dll',
    'libwinpthread-1.dll','openxr_loader.dll','Play-on-monitor.bat',
    'RELEASE-NOTES.txt','SDL2.dll','Start-GEVR.bat'
)

$contract = New-PCVRInstallerContract -Id 'goldeneye-007-vr' -GameName 'GoldenEye 007 VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES_URL -Routes @('Standalone') `
    -RequiredInstalledFileGroups @($REQUIRED_RUNTIME + @($ICON_NAME,$READY_MARKER,$HUB_LAUNCHER,".pcvrhub_${IDENTITY}_ownership.csv"))

function Write-GoldenEyeStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-GoldenEyeOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-GoldenEyeWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Get-GoldenEyeRememberedTarget {
    $durable=Get-PCVRRememberedGameFolder -ProbeFiles @($READY_MARKER)
    if ($durable) { return $durable }
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $value=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
            if ($value -and (Test-Path -LiteralPath (Join-Path $value 'Start-GEVR.bat') -PathType Leaf)) {
                return [IO.Path]::GetFullPath($value)
            }
        } catch {}
    }
    return $DEFAULT_TARGET
}

function Test-GoldenEyeTargetWritable([string]$Path) {
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) { [void][IO.Directory]::CreateDirectory($Path) }
        return [bool](Test-InstallerTargetWritable -TargetPath $Path)
    } catch { return $false }
}

function Select-GoldenEyeInstallFolder([scriptblock]$ReadInput=$null,[scriptblock]$WritableProbe=$null) {
    $suggested=Get-GoldenEyeRememberedTarget
    Write-Host "  Default: $suggested" -ForegroundColor White
    Write-Host '  Press Enter to use it, or type/paste another full folder path.' -ForegroundColor Gray
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $raw=if ($ReadInput) { & $ReadInput $suggested } else { Read-Host '  GoldenEye 007 VR install folder' }
        $value=(''+$raw).Trim().Trim('"').Trim("'")
        if (-not $value) { $value=$suggested }
        if ($value -ieq 'Q') { return $null }
        try {
            $target=[IO.Path]::GetFullPath($value).TrimEnd('\','/')
            if ($target -eq [IO.Path]::GetPathRoot($target).TrimEnd('\','/')) { throw 'A drive root is not an install folder.' }
            $writable=if ($WritableProbe) { [bool](& $WritableProbe $target) } else { Test-GoldenEyeTargetWritable $target }
            if (-not $writable) { throw 'The selected folder is not writable.' }
            return $target
        } catch { Write-GoldenEyeWarn $_.Exception.Message }
    }
    throw 'No writable GoldenEye 007 VR folder was selected after 10 attempts.'
}

function Get-GoldenEyePayloadRoot([string]$ExtractRoot) {
    $candidates=@((Get-Item -LiteralPath $ExtractRoot)) + @(Get-ChildItem -LiteralPath $ExtractRoot -Directory -Recurse -ErrorAction SilentlyContinue)
    foreach ($candidate in $candidates) {
        $root=$candidate.FullName; $valid=$true
        foreach ($relative in $REQUIRED_RUNTIME) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { $valid=$false; break }
        }
        if ($valid) { return $root }
    }
    return $null
}

function Test-GoldenEyePayloadHasNoRom([string]$PayloadRoot) {
    return @(Get-ChildItem -LiteralPath $PayloadRoot -Recurse -File -ErrorAction Stop |
        Where-Object Extension -match '(?i)^\.(z64|v64|n64)$').Count -eq 0
}

function New-GoldenEyeStage([string]$PayloadRoot,[string]$StageRoot,[string]$Version) {
    if (-not (Test-GoldenEyePayloadHasNoRom $PayloadRoot)) { throw 'The publisher package unexpectedly contains a ROM; installation stopped.' }
    [void][IO.Directory]::CreateDirectory($StageRoot)
    foreach ($relative in $REQUIRED_RUNTIME) {
        $source=Join-Path $PayloadRoot $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Required publisher file is missing: $relative" }
        $destination=Join-Path $StageRoot $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
    $boot=@(Get-ChildItem -LiteralPath $PayloadRoot -File -Filter 'gevr-*-boot.cmd' -ErrorAction Stop)
    if ($boot.Count -ne 1) { throw 'The publisher package must contain exactly one versioned GEVR boot script.' }
    Copy-Item -LiteralPath $boot[0].FullName -Destination (Join-Path $StageRoot $boot[0].Name) -Force
    $iconSource=Join-Path $PSScriptRoot $ICON_NAME
    if (-not (Test-Path -LiteralPath $iconSource -PathType Leaf)) { throw "Bundled shortcut icon is missing: $ICON_NAME" }
    Copy-Item -LiteralPath $iconSource -Destination (Join-Path $StageRoot $ICON_NAME) -Force
    [IO.File]::WriteAllText((Join-Path $StageRoot $READY_MARKER),$Version,(New-Object Text.UTF8Encoding $false))
    # Run the complete publisher boot before making one narrow compatibility
    # compatibility safeguard. Older publisher boots could pin GETV_FPS=90
    # after selecting runtime timing. Current builds already leave it unset;
    # clearing it once more is harmless and keeps old/future package fallback
    # behavior aligned with the active OpenXR refresh rate.
    $bootName=$boot[0].Name
    $launcher=@(
        '@echo off',
        'setlocal',
        'cd /d "%~dp0"',
        "if not exist `"%~dp0$bootName`" (",
        "  echo FATAL: $bootName missing. Re-run the Hub installer.",
        '  exit /b 1',
        ')',
        'if not exist "%~dp0GevrRomStarter.exe" (',
        '  echo FATAL: GevrRomStarter.exe missing. Re-run the Hub installer.',
        '  exit /b 1',
        ')',
        "call `"%~dp0$bootName`"",
        'set "GETV_FPS="',
        'set "GETV_SIMHZ=query"',
        'echo [PCVR Hub] GEVR timing follows the active OpenXR runtime.',
        '"%~dp0GevrRomStarter.exe"',
        'exit /b %ERRORLEVEL%'
    ) -join "`r`n"
    [IO.File]::WriteAllText((Join-Path $StageRoot $HUB_LAUNCHER),($launcher+"`r`n"),(New-Object Text.ASCIIEncoding))
    return $boot[0].Name
}

function Save-GoldenEyeSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $relatives=[Collections.Generic.List[string]]::new()
    $stageBase=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)) {
        $relatives.Add($file.FullName.Substring($stageBase.Length+1).Replace('/','\'))
    }
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $relatives.Add([string]$row.RelativePath) } } } catch {}
    }
    foreach ($extra in @(".pcvrhub_${IDENTITY}_ownership.csv",".pcvrhub_${IDENTITY}_ownership.csv.new",'.pcvrhub_version')) { $relatives.Add($extra) }
    $records=@()
    foreach ($relative in @($relatives | Select-Object -Unique)) {
        $source=Join-Path $GameRoot $relative; $exists=Test-Path -LiteralPath $source -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists;Key=$key}
        if ($exists) { Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot $key) -Force }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    $backupExists=Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force }
    return [pscustomobject]@{Records=$records;BackupExists=$backupExists;Root=$SnapshotRoot}
}

function Restore-GoldenEyeSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target=Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path $Snapshot.Root ([string]$record.Key)) -Destination $target -Force
        }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force }
}

function Install-GoldenEyeOwnedPayload {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$InstalledPathReceipt
    )
    $stageFiles=@(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -ErrorAction Stop)
    $stageBase=[IO.Path]::GetFullPath($SourceRoot).TrimEnd('\','/')
    $replace=@($stageFiles | ForEach-Object { $_.FullName.Substring($stageBase.Length+1).Replace('/','\') })
    foreach ($relative in @($REQUIRED_RUNTIME + @($ICON_NAME,$READY_MARKER,$HUB_LAUNCHER))) {
        if (-not (Test-Path -LiteralPath (Join-Path $SourceRoot $relative) -PathType Leaf)) { throw "Install stage is incomplete: $relative" }
    }
    $bootFiles=@(Get-ChildItem -LiteralPath $SourceRoot -File -Filter 'gevr-*-boot.cmd' -ErrorAction Stop)
    if ($bootFiles.Count -ne 1) { throw 'The install stage must contain exactly one versioned GEVR boot script.' }
    if (@($stageFiles | Where-Object Extension -match '(?i)^\.(z64|v64|n64)$').Count -gt 0) { throw 'The install stage contains a ROM and was rejected.' }
    [void](Install-OwnedModPayload -SourceRoot $SourceRoot -GameRoot $GameRoot -Identity $IDENTITY `
        -ReplaceChangedOwnedRelativePaths $replace -AdoptIdenticalExisting)
    $watch=@($replace + ".pcvrhub_${IDENTITY}_ownership.csv") | ForEach-Object { Join-Path $GameRoot $_ }
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $GameRoot -NoClear)) { throw 'Required GoldenEye 007 VR files are missing after installation.' }
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version `
        -InstalledPathReceiptPaths @($InstalledPathReceipt) -Route 'Standalone')
}

function global:Invoke-GoldenEye007VRInstaller {
    $work=$null; $target=$null; $snapshot=$null; $changesStarted=$false; $targetExisted=$true
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  GoldenEye 007 VR - Installer' -ForegroundColor Cyan
        Write-Host '  Standalone OpenXR beta by no6969el' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  This installs the official PCVR runtime. No commercial game data' -ForegroundColor White
        Write-Host '  or ROM is included, copied or downloaded by the Hub.' -ForegroundColor White
        Write-Host '  On first launch, the publisher starter asks for your legally owned' -ForegroundColor Yellow
        Write-Host '  USA GoldenEye 007 ROM (.z64, .v64 or .n64).' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start setup...')

        Write-GoldenEyeStep 1 4 'Choosing the standalone GoldenEye 007 VR folder'
        $target=Select-GoldenEyeInstallFolder
        if (-not $target) { throw 'Setup cancelled before any file was changed.' }
        $targetExisted=Test-Path -LiteralPath $target -PathType Container
        if (-not $targetExisted) { [void][IO.Directory]::CreateDirectory($target) }
        if (-not (Test-InstallerTargetWritable -TargetPath $target)) { throw 'The selected folder is not writable.' }
        if (Get-Process -Name 'goldeneye','GevrRomStarter','gevr_prepare' -ErrorAction SilentlyContinue) { throw 'GoldenEye 007 VR is running. Close it completely and run setup again.' }
        Write-GoldenEyeOK "Standalone folder: $target"
        Write-GoldenEyeOK 'Publisher VR boot retained with the runtime-rate compatibility safeguard.'

        Write-GoldenEyeStep 2 4 'Downloading and validating the newest stable PCVR release'
        $release=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^GEVR-Beta-vr[0-9]+(?:\.[0-9]+)*-win64\.zip$') `
            -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET -SkipReleasesWithoutMatchingAsset
        $version=[string]$release.Tag
        if (-not (Test-IsTrackableInstalledVersion $version)) { throw 'The publisher release did not provide a trackable version tag.' }
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_goldeneye_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work ([string]$release.AssetName)
        $got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "GEVR $version" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The official GEVR archive was not downloaded.' }
        $extract=Join-Path $work 'extract'
        $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'official GEVR release' -AllowSkip $false -QuietProgress
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The GEVR archive could not be extracted.' }
        $payload=Get-GoldenEyePayloadRoot $extract
        if (-not $payload) { throw 'The release is missing the launcher, ROM starter, OpenXR runtime or another required publisher file.' }
        $stage=Join-Path $work 'stage'
        $bootName=New-GoldenEyeStage -PayloadRoot $payload -StageRoot $stage -Version $version
        Write-GoldenEyeOK "Official $version runtime verified; no ROM is present in the package."

        Write-GoldenEyeStep 3 4 'Installing the runtime recoverably'
        $snapshot=Save-GoldenEyeSnapshot -GameRoot $target -Stage $stage -SnapshotRoot (Join-Path $work 'snapshot')
        $changesStarted=$true
        Install-GoldenEyeOwnedPayload -GameRoot $target -SourceRoot $stage -Version $version -InstalledPathReceipt (Join-Path $PSScriptRoot '.installed_path')
        Write-GoldenEyeOK "Runtime, $bootName, OpenXR loader and launcher verified."

        Write-GoldenEyeStep 4 4 'Creating the launch shortcut'
        try {
            [void](New-DesktopShortcut -ShortcutName 'GoldenEye 007 VR' -TargetPath (Join-Path $target $HUB_LAUNCHER) `
                -WorkingDir $target -IconPath (Join-Path $target $ICON_NAME) -Description 'Launch GoldenEye 007 in OpenXR VR')
            Write-GoldenEyeOK 'Desktop shortcut created.'
        } catch { Write-GoldenEyeWarn 'The installation is complete, but its optional desktop shortcut could not be created.' }
        $changesStarted=$false

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  GoldenEye 007 VR is ready' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host "  Installed: GEVR $version" -ForegroundColor White
        Write-Host "  Folder:    $target" -ForegroundColor White
        Write-Host '  VR timing: follows the active OpenXR runtime (72 / 80 / 90 Hz).' -ForegroundColor White
        Write-Host '  First start: choose your legally owned USA ROM when prompted.' -ForegroundColor Yellow
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Yellow
        Write-Host '  2. Or use the GoldenEye 007 VR desktop shortcut.' -ForegroundColor Yellow
        Write-Host '  Start-GEVR-Hub.bat is the manual fallback; never launch goldeneye.exe directly.' -ForegroundColor Gray
        Write-Host '  The first cache build can take a moment; later starts reuse it.' -ForegroundColor Gray
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $target -and $snapshot) {
            try { Restore-GoldenEyeSnapshot -GameRoot $target -Snapshot $snapshot; Write-GoldenEyeWarn 'The previous GoldenEye 007 VR folder state was restored.' }
            catch { Write-GoldenEyeWarn ('Rollback also needs attention: '+$_.Exception.Message) }
        }
        if (-not $targetExisted -and $target -and (Test-Path -LiteralPath $target -PathType Container)) {
            try { if (@(Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $target -Force } } catch {}
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if (((''+$env:PCVR_GOLDENEYE007_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-GoldenEye007VRInstaller }

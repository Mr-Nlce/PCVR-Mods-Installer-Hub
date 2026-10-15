$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Flower VR Installer'
$script:FlowerId = 'flower-vr'
$script:FlowerIdentity = 'flower_vr'
$script:FlowerRepo = 'jeffMeador/flower_vr'
$script:FlowerReleases = "https://github.com/$script:FlowerRepo/releases"
$script:FlowerFallbackUrl = 'https://github.com/jeffMeador/flower_vr/releases/download/v1.1/d3d11.dll'
$script:FlowerContract = New-PCVRInstallerContract -Id $script:FlowerId -GameName 'Flower VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:FlowerReleases `
    -RequiredInstalledFileGroups @('d3d11.dll','d3d11_orig.dll','.pcvrhub_flower_vr_ownership.csv')

function Write-FlowerStep([int]$Number,[string]$Text) {
    Write-Host ''
    Write-Host "--- [$Number/5] $Text ---" -ForegroundColor Cyan
    Write-Host ''
}

function Test-FlowerGameRoot([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Flower.exe') -PathType Leaf))
}

function Test-FlowerPe64([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $stream = $null
    $reader = $null
    try {
        $stream = [IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        if ($stream.Length -lt 128) { return $false }
        $reader = [IO.BinaryReader]::new($stream)
        if ($reader.ReadUInt16() -ne 0x5A4D) { return $false }
        $stream.Position = 0x3C
        $offset = $reader.ReadInt32()
        if ($offset -lt 64 -or $offset + 6 -gt $stream.Length) { return $false }
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x00004550) { return $false }
        return ($reader.ReadUInt16() -eq 0x8664)
    } catch { return $false }
    finally {
        if ($reader) { $reader.Dispose() }
        elseif ($stream) { $stream.Dispose() }
    }
}

function Get-FlowerGameRoot {
    $testRoot = ('' + $env:PCVR_FLOWER_TEST_GAME).Trim()
    if ($testRoot) {
        if (Test-FlowerGameRoot $testRoot) { return (Get-Item -LiteralPath $testRoot).FullName }
        throw 'The selected Flower test game folder is missing Flower.exe.'
    }
    $found = Find-SteamGameFolder -AppId '966330' -SteamFolderNames @('Flower') `
        -GogNames @('Flower') -ProbeExe 'Flower.exe' -HubGameId $script:FlowerId
    if (Test-FlowerGameRoot $found) { return (Get-Item -LiteralPath $found).FullName }
    foreach ($candidate in @(
        'C:\Program Files (x86)\Steam\steamapps\common\Flower',
        'C:\Program Files\Epic Games\Flower',
        'C:\Program Files (x86)\GOG Galaxy\Games\Flower',
        'C:\GOG Games\Flower')) {
        if (Test-FlowerGameRoot $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    $manual = Get-GameFolderInteractive -GameName 'Flower' -ProbeFile 'Flower.exe' `
        -ManualUrl 'https://github.com/jeffMeador/flower_vr#install'
    if ($manual -and $manual -notin @('quit','skip') -and (Test-FlowerGameRoot $manual)) {
        return (Get-Item -LiteralPath $manual).FullName
    }
    return $null
}

function Get-FlowerRelease {
    $testFile = ('' + $env:PCVR_FLOWER_TEST_RELEASE_DLL).Trim()
    if ($testFile) {
        return [pscustomobject]@{Tag='v1.1'; Url=$testFile; Name='d3d11.dll'; PageUrl='https://github.com/jeffMeador/flower_vr/releases/tag/v1.1'; IsLocal=$true}
    }
    $release = Resolve-GitHubReleaseAsset -Repo $script:FlowerRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^d3d11\.dll$') -FallbackUrl $script:FlowerFallbackUrl `
        -FallbackTag 'v1.1' -FallbackAssetName 'd3d11.dll' -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Tag=[string]$release.Tag; Url=[string]$release.Url; Name=[string]$release.AssetName; PageUrl=[string]$release.PageUrl; IsLocal=$false}
}

function Save-FlowerSnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($relative in @('d3d11.dll','d3d11_orig.dll','.pcvrhub_flower_vr_ownership.csv','.pcvrhub_flower_vr_ownership.csv.new','.pcvrhub_version')) {
        $paths.Add($relative)
    }
    $manifest = Join-Path $GameRoot '.pcvrhub_flower_vr_ownership.csv'
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)) {
            $paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))
        }
    }
    $records = @()
    foreach ($relative in @($paths | Select-Object -Unique)) {
        $target = Join-OwnedRelativePath -Root $GameRoot -Relative $relative
        $key = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $exists = Test-Path -LiteralPath $target -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Key=$key;Exists=$exists}
        if ($exists) { Copy-Item -LiteralPath $target -Destination (Join-Path $SnapshotRoot $key) -Force -ErrorAction Stop }
    }
    $backup = Join-Path $GameRoot '.pcvrhub_flower_vr_backup'
    $backupExists = Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{Root=$SnapshotRoot;Records=$records;BackupExists=$backupExists}
}

function Restore-FlowerSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target = Join-OwnedRelativePath -Root $GameRoot -Relative ([string]$record.Relative)
        if ($record.Exists) {
            Copy-Item -LiteralPath (Join-Path $Snapshot.Root ([string]$record.Key)) -Destination $target -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot '.pcvrhub_flower_vr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}

function Invoke-FlowerInstaller {
    $work = $null
    $snapshot = $null
    $changed = $false
    $game = $null
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Flower VR - Installer' -ForegroundColor Cyan
        Write-Host '  Steam or GOG; SteamVR/OpenXR; motion-controller steering' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  You need an owned PC copy of Flower and a connected SteamVR headset.' -ForegroundColor White
        Write-Host '  Setup adds the publisher proxy and a copy of your own Windows Direct3D DLL.' -ForegroundColor White
        Write-Host '  Existing files with those names are backed up; saves and settings stay untouched.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Flower...')

        Write-FlowerStep 1 'Locating and checking Flower'
        $game = Get-FlowerGameRoot
        if (-not $game) { throw 'Setup stopped before the Flower folder was changed.' }
        if (Get-Process -Name 'Flower' -ErrorAction SilentlyContinue) { throw 'Flower is running. Close it before installing or updating the mod.' }
        if (-not (Test-InstallerTargetWritable $game)) { throw 'The Flower folder is not writable. Choose a writable location or run setup with the required permission.' }
        $systemDll = ('' + $env:PCVR_FLOWER_TEST_SYSTEM_DLL).Trim()
        if (-not $systemDll) { $systemDll = Join-Path $env:WINDIR 'System32\d3d11.dll' }
        if (-not (Test-FlowerPe64 $systemDll)) { throw 'The 64-bit Windows Direct3D DLL was not found or is not usable. Repair Windows before retrying.' }
        Write-Host "  [OK] Game and Windows Direct3D found: $game" -ForegroundColor Green

        Write-FlowerStep 2 'Getting the current publisher release'
        $release = Get-FlowerRelease
        if (-not (Test-IsTrackableInstalledVersion $release.Tag)) { throw 'GitHub supplied no trackable Flower VR version.' }
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_flower_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $stage = Join-Path $work 'stage'
        [void][IO.Directory]::CreateDirectory($stage)
        $publisherDll = Join-Path $stage 'd3d11.dll'
        if ($release.IsLocal) { Copy-Item -LiteralPath $release.Url -Destination $publisherDll -Force -ErrorAction Stop }
        else { [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $publisherDll -Label "Flower VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl $release.PageUrl -AllowSkip $false) }
        if (-not (Test-FlowerPe64 $publisherDll)) { throw 'The downloaded Flower VR proxy is not a usable 64-bit Windows DLL.' }
        Copy-Item -LiteralPath $systemDll -Destination (Join-Path $stage 'd3d11_orig.dll') -Force -ErrorAction Stop
        if (-not (Test-FlowerPe64 (Join-Path $stage 'd3d11_orig.dll'))) { throw 'The staged Windows Direct3D copy is incomplete.' }
        Write-Host "  [OK] Both functional DLLs staged for $($release.Tag)." -ForegroundColor Green

        Write-FlowerStep 3 'Preparing the recoverable file plan'
        $snapshot = Save-FlowerSnapshot -GameRoot $game -SnapshotRoot (Join-Path $work 'rollback')
        Write-Host '  [OK] Existing matching files and the previous ownership record are protected.' -ForegroundColor Green

        Write-FlowerStep 4 'Installing and checking the VR runtime'
        $changed = $true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:FlowerIdentity -AdoptIdenticalExisting)
        $required = @('d3d11.dll','d3d11_orig.dll','.pcvrhub_flower_vr_ownership.csv') | ForEach-Object { Join-Path $game $_ }
        if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)) { throw 'The Flower VR runtime is incomplete after copying.' }
        $receipt = ('' + $env:PCVR_FLOWER_TEST_RECEIPT).Trim()
        if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:FlowerContract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route 'Current')
        $changed = $false

        Write-FlowerStep 5 'Setup complete'
        Write-Host "  [OK] Flower VR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  Start SteamVR with your headset, then launch Flower.' -ForegroundColor White
        Write-Host '  Virtual Desktop: Set the VD runtime to SteamVR. On the' -ForegroundColor Yellow
        Write-Host '  first start, click "Switch to VR" once in the VD menu.' -ForegroundColor Yellow
        Write-Host '  After that, Flower starts in VR automatically.' -ForegroundColor Yellow
        Write-Host '  On first launch, the mod creates its own VR settings files.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  Stop and smell the flowers. Then become the wind.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-FlowerSnapshot -GameRoot $game -Snapshot $snapshot; Write-Host '  [!!] The previous Flower state was restored.' -ForegroundColor Yellow }
            catch { Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_FLOWER_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-FlowerInstaller }

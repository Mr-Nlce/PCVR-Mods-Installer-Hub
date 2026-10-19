$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Journey VR Installer'
$script:JourneyId = 'journey-vr'
$script:JourneyIdentity = 'journey_vr'
$script:JourneyRepo = 'jeffMeador/flower_vr'
$script:JourneyReleases = "https://github.com/$script:JourneyRepo/releases"
$script:JourneyContract = New-PCVRInstallerContract -Id $script:JourneyId -GameName 'Journey VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:JourneyReleases `
    -RequiredInstalledFileGroups @('d3d11.dll','d3d11_orig.dll','.pcvrhub_journey_vr_ownership.csv')

function Write-JourneyStep([int]$Number,[string]$Text) {
    Write-Host ''
    Write-Host "--- [$Number/5] $Text ---" -ForegroundColor Cyan
    Write-Host ''
}

function Test-JourneyGameRoot([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Journey.exe') -PathType Leaf))
}

function Test-JourneyPe64([string]$Path) {
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

function Get-JourneyGameRoot {
    $testRoot = ('' + $env:PCVR_JOURNEY_TEST_GAME).Trim()
    if ($testRoot) {
        if (Test-JourneyGameRoot $testRoot) { return (Get-Item -LiteralPath $testRoot).FullName }
        throw 'The selected Journey test game folder is missing Journey.exe.'
    }
    $found = $null
    try { $found = Find-SteamGameFolder -AppId '638230' -SteamFolderNames @('Journey') `
        -ProbeExe 'Journey.exe' -HubGameId $script:JourneyId } catch { }
    if (Test-JourneyGameRoot $found) { return (Get-Item -LiteralPath $found).FullName }
    foreach ($candidate in @(
        'C:\Program Files (x86)\Steam\steamapps\common\Journey')) {
        if (Test-JourneyGameRoot $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    $epic = 'C:\Program Files\Epic Games\Journey'
    if (Test-JourneyGameRoot $epic) {
        Write-Host '  Only an Epic Journey installation was found.' -ForegroundColor Yellow
        Write-Host '  The publisher has documented and tested Steam only; Epic VR support is unconfirmed.' -ForegroundColor Yellow
        if ((Read-Host '  Try this Epic installation? Y/N').Trim() -match '^(?i)y(?:es)?$') {
            return (Get-Item -LiteralPath $epic).FullName
        }
    }
    $manual = Get-GameFolderInteractive -GameName 'Journey' -ProbeFile 'Journey.exe' `
        -ManualUrl 'https://github.com/jeffMeador/flower_vr#journey-alpha'
    if ($manual -and $manual -notin @('quit','skip') -and (Test-JourneyGameRoot $manual)) {
        return (Get-Item -LiteralPath $manual).FullName
    }
    return $null
}

function Get-JourneyRelease {
    $testFile = ('' + $env:PCVR_JOURNEY_TEST_RELEASE_DLL).Trim()
    if ($testFile) {
        return [pscustomobject]@{Tag='v1.2.1'; Url=$testFile; Name='d3d11.dll'; PageUrl='https://github.com/jeffMeador/flower_vr/releases/tag/v1.2.1'; IsLocal=$true}
    }
    $release = Resolve-GitHubReleaseAsset -Repo $script:JourneyRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^d3d11\.dll$') -SkipReleasesWithoutMatchingAsset
    if (-not $release.Resolved -or [string]$release.Tag -notmatch '^v?(?<version>\d+\.\d+(?:\.\d+)?)$' -or
        [version]$Matches.version -lt [version]'1.2') {
        Write-Host '  [!!] The current publisher release could not be checked on GitHub.' -ForegroundColor Yellow
        if ($release.ReleaseFound) {
            Write-Host '  GitHub returned a release with a different asset layout. Choose its DLL on the release page.' -ForegroundColor Yellow
            return [pscustomobject]@{Tag='';Url='';Name='d3d11.dll';PageUrl=$script:JourneyReleases;IsLocal=$false;Manual=$true}
        }
        Write-Host '  The last reviewed compatible release is v1.2.1 (15 October 2026).' -ForegroundColor Yellow
        Write-Host '  A newer release may exist. You can use v1.2.1 or select its current DLL on the release page.' -ForegroundColor White
        if ((Read-Host '  Download the reviewed v1.2.1 DLL? Y/N').Trim() -match '^(?i)y(?:es)?$') {
            return [pscustomobject]@{Tag='v1.2.1';Url='https://github.com/jeffMeador/flower_vr/releases/download/v1.2.1/d3d11.dll';Name='d3d11.dll';PageUrl=$script:JourneyReleases;IsLocal=$false;Manual=$false}
        }
        return [pscustomobject]@{Tag='';Url='';Name='d3d11.dll';PageUrl=$script:JourneyReleases;IsLocal=$false;Manual=$true}
    }
    return [pscustomobject]@{Tag=[string]$release.Tag; Url=[string]$release.Url; Name=[string]$release.AssetName; PageUrl=[string]$release.PageUrl; IsLocal=$false}
}

function Save-JourneySnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($relative in @('d3d11.dll','d3d11_orig.dll','.pcvrhub_journey_vr_ownership.csv','.pcvrhub_journey_vr_ownership.csv.new','.pcvrhub_version')) {
        $paths.Add($relative)
    }
    $manifest = Join-Path $GameRoot '.pcvrhub_journey_vr_ownership.csv'
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
    $backup = Join-Path $GameRoot '.pcvrhub_journey_vr_backup'
    $backupExists = Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{Root=$SnapshotRoot;Records=$records;BackupExists=$backupExists}
}

function Restore-JourneySnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target = Join-OwnedRelativePath -Root $GameRoot -Relative ([string]$record.Relative)
        if ($record.Exists) {
            Copy-Item -LiteralPath (Join-Path $Snapshot.Root ([string]$record.Key)) -Destination $target -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot '.pcvrhub_journey_vr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}

function Invoke-JourneyInstaller {
    $work = $null
    $snapshot = $null
    $changed = $false
    $game = $null
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Journey VR - Installer' -ForegroundColor Cyan
        Write-Host '  Steam; SteamVR/OpenXR; Journey support is alpha' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  You need the Steam PC version of Journey and SteamVR as OpenXR runtime.' -ForegroundColor White
        Write-Host '  Setup adds the publisher proxy and a copy of your own Windows Direct3D DLL.' -ForegroundColor White
        Write-Host '  Existing files with those names are backed up; saves and settings stay untouched.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Journey...')

        Write-JourneyStep 1 'Locating and checking Journey'
        $game = Get-JourneyGameRoot
        if (-not $game) { throw 'Setup stopped before the Journey folder was changed.' }
        if ($game -match '(?i)\\Epic Games\\Journey(?:\\|$)') {
            Write-Host '  [!!] Epic route is experimental and has not been verified by the publisher.' -ForegroundColor Yellow
        }
        if (Get-Process -Name 'Journey' -ErrorAction SilentlyContinue) { throw 'Journey is running. Close it before installing or updating the mod.' }
        if (-not (Test-InstallerTargetWritable $game)) { throw 'The Journey folder is not writable. Choose a writable location or run setup with the required permission.' }
        $systemDll = ('' + $env:PCVR_JOURNEY_TEST_SYSTEM_DLL).Trim()
        if (-not $systemDll) { $systemDll = Join-Path $env:WINDIR 'System32\d3d11.dll' }
        if (-not (Test-JourneyPe64 $systemDll)) { throw 'The 64-bit Windows Direct3D DLL was not found or is not usable. Repair Windows before retrying.' }
        Write-Host "  [OK] Game and Windows Direct3D found: $game" -ForegroundColor Green

        Write-JourneyStep 2 'Getting the current publisher release'
        $release = Get-JourneyRelease
        if (-not $release.Manual -and -not (Test-IsTrackableInstalledVersion $release.Tag)) { throw 'GitHub supplied no trackable Journey VR version.' }
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_journey_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $stage = Join-Path $work 'stage'
        [void][IO.Directory]::CreateDirectory($stage)
        $publisherDll = Join-Path $stage 'd3d11.dll'
        if ($release.IsLocal) { Copy-Item -LiteralPath $release.Url -Destination $publisherDll -Force -ErrorAction Stop }
        elseif ($release.Manual) {
            [void](Invoke-SafeDownload -Urls @() -Destination $publisherDll -Label 'Journey VR publisher DLL' -ManualUrl $release.PageUrl -AllowSkip $false)
            $manualTag = (Read-Host '  Enter the release tag shown on the official page (for example v1.2.1)').Trim()
            if ($manualTag -notmatch '^v?(?<version>\d+\.\d+(?:\.\d+)?)$' -or [version]$Matches.version -lt [version]'1.2') {
                throw 'A Journey-compatible publisher release version was not confirmed. No game files were changed.'
            }
            $release.Tag = 'v' + $Matches.version
            Write-Host "  Selected publisher release: $($release.Tag)." -ForegroundColor Yellow
            if ((Read-Host '  Use this DLL and version? Y/N').Trim() -notmatch '^(?i)y(?:es)?$') {
                throw 'Publisher version was not confirmed. No game files were changed.'
            }
        }
        else { [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $publisherDll -Label "Journey VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl $release.PageUrl -AllowSkip $false) }
        if (-not (Test-JourneyPe64 $publisherDll)) { throw 'The downloaded Journey VR proxy is not a usable 64-bit Windows DLL.' }
        Copy-Item -LiteralPath $systemDll -Destination (Join-Path $stage 'd3d11_orig.dll') -Force -ErrorAction Stop
        if (-not (Test-JourneyPe64 (Join-Path $stage 'd3d11_orig.dll'))) { throw 'The staged Windows Direct3D copy is incomplete.' }
        Write-Host "  [OK] Both functional DLLs staged for $($release.Tag)." -ForegroundColor Green

        Write-JourneyStep 3 'Preparing the recoverable file plan'
        $snapshot = Save-JourneySnapshot -GameRoot $game -SnapshotRoot (Join-Path $work 'rollback')
        Write-Host '  [OK] Existing matching files and the previous ownership record are protected.' -ForegroundColor Green

        Write-JourneyStep 4 'Installing and checking the VR runtime'
        $changed = $true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:JourneyIdentity -AdoptIdenticalExisting)
        $required = @('d3d11.dll','d3d11_orig.dll','.pcvrhub_journey_vr_ownership.csv') | ForEach-Object { Join-Path $game $_ }
        if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)) { throw 'The Journey VR runtime is incomplete after copying.' }
        $receipt = ('' + $env:PCVR_JOURNEY_TEST_RECEIPT).Trim()
        if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:JourneyContract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route 'Current')
        $changed = $false

        Write-JourneyStep 5 'Setup complete'
        Write-Host "  [OK] Journey VR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  Use Start in VR in the Hub with SteamVR and the headset connected.' -ForegroundColor White
        Write-Host '  Steam Frame: connect Steam Link VR first; otherwise the game' -ForegroundColor Yellow
        Write-Host '  waits on a black screen.' -ForegroundColor Yellow
        Write-Host '  First launch creates vrmod.ini and vrmod_Journey.cfg.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  Every journey begins with a single step.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-JourneySnapshot -GameRoot $game -Snapshot $snapshot; Write-Host '  [!!] The previous Journey state was restored.' -ForegroundColor Yellow }
            catch { Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_JOURNEY_LIBRARY_ONLY).Trim()) -ne '1') {
    while ($true) {
        try { Invoke-JourneyInstaller; break }
        catch {
            $message = "Journey VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$Host.UI.RawUI.WindowTitle = 'Alan Wake VR Installer'
$script:AwId = 'alan-wake-vr'
$script:AwRepo = 'fholger/alanwake_vr'
$script:AwPage = 'https://github.com/fholger/alanwake_vr/releases'
$script:AwDownloadPage = 'https://alanwake.vrmods.eu/'
$script:AwFiles = @('AlanWake.exe','d3d9.dll','Uninstall_AlanWakeVR.exe','AWVR_README.md','AWVR_ThirdParty.txt','awvr_laa_patcher.exe')
$script:AwManifestName = '.pcvrhub_alanwakevr_ownership.json'
$script:AwBackupName = '.pcvrhub_alanwakevr_backup'
$script:AwContract = New-PCVRInstallerContract -Id $script:AwId -GameName 'Alan Wake VR' -Acquisition GitHub `
    -ReleasePageUrl $script:AwPage -AntivirusNotice -Routes @('Steam','GOG','Epic') `
    -RequiredInstalledFileGroups @('AlanWake.exe','d3d9.dll','Uninstall_AlanWakeVR.exe','.pcvrhub_alanwakevr_ownership.json')

function Assert-AwFixture([string]$Root) {
    $full = [IO.Path]::GetFullPath($Root)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath (Join-Path $full 'alanwake-fixture.txt') -PathType Leaf)) {
        throw 'Alan Wake test game must be an isolated temporary fixture.'
    }
    return $full
}
function Test-AwGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'AlanWake.exe') -PathType Leaf) -and
        -not ($Root -match '(?i)Alan\s*Wake\s*Remastered'))
}
function Get-AwGame {
    if ($env:PCVR_ALANWAKE_TEST_GAME) {
        $test = Assert-AwFixture $env:PCVR_ALANWAKE_TEST_GAME
        if (-not (Test-AwGame $test)) { throw 'The Alan Wake test game folder is incomplete.' }
        return $test
    }
    $paths = @()
    $saved = Get-PCVRRememberedGameFolder -GameId $script:AwId -StateNames @('installed_path','user_located') -ProbeFiles @('AlanWake.exe')
    if ($saved) { $paths += $saved }
    try {
        $steam = Find-SteamGameFolder -AppId '108710' -SteamFolderNames @('Alan Wake') -ProbeExe 'AlanWake.exe' -HubGameId $script:AwId
        if ($steam) { $paths += $steam }
    } catch { }
    $paths += @('C:\Program Files (x86)\Steam\steamapps\common\Alan Wake',
        'C:\Program Files\Epic Games\AlanWake',
        'C:\Program Files (x86)\GOG Galaxy\Games\Alan Wake',
        'C:\GOG Games\Alan Wake')
    foreach ($path in @($paths | Select-Object -Unique)) {
        if (Test-AwGame $path) { return [IO.Path]::GetFullPath($path) }
    }
    $picked = Get-GameFolderInteractive -GameName 'Alan Wake (Steam, GOG or Epic; not Remastered)' `
        -ProbeFile 'AlanWake.exe' -ManualUrl 'https://store.steampowered.com/app/108710/Alan_Wake/'
    if (Test-AwGame $picked) {
        [void](Save-HubRememberedGameFolder -GameId $script:AwId -Title 'Alan Wake' -GameDir $picked -ProbeFiles @('AlanWake.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose the original Alan Wake folder from Steam, GOG or Epic, containing AlanWake.exe. Remastered is not supported.'
}
function Get-AwRoute([string]$Root) {
    if ($env:PCVR_ALANWAKE_TEST_ROUTE) { return [string]$env:PCVR_ALANWAKE_TEST_ROUTE }
    if ($Root -match '(?i)[\\/]XboxGames[\\/]|[\\/]Remedy Entertainment[\\/]') {
        throw 'This game folder is from an unsupported Xbox or DVD edition. Use Steam, GOG or Epic Alan Wake.'
    }
    if ($Root -match '(?i)[\\/]steamapps[\\/]common[\\/]') { return 'Steam' }
    if ($Root -match '(?i)[\\/]Epic Games[\\/]') { return 'Epic' }
    if ($Root -match '(?i)[\\/]GOG Games[\\/]|[\\/]GOG Galaxy[\\/]') { return 'GOG' }
    Write-Host '  The selected folder is outside the usual Steam, GOG and Epic locations.' -ForegroundColor Yellow
    Write-Host '  The publisher supports these three editions of original Alan Wake.' -ForegroundColor White
    do { $choice = (Read-Host '  Which edition is this? S=Steam, G=GOG, E=Epic, Q=cancel').Trim().ToUpperInvariant() }
    while ($choice -notin @('S','G','E','Q'))
    if ($choice -eq 'Q') { throw 'No supported game edition was confirmed.' }
    return @{S='Steam';G='GOG';E='Epic'}[$choice]
}
function Get-AwRelease {
    try {
        $args = @{Repo=$script:AwRepo;IncludePrerelease=$false;
            AssetPatterns=@('(?i)^alanwake-vr-[0-9]+(?:\.[0-9]+){2}\.exe$');SkipReleasesWithoutMatchingAsset=$true}
        if ($env:PCVR_ALANWAKE_TEST_RELEASE_JSON) {
            $args.ReleaseData = Get-Content -LiteralPath $env:PCVR_ALANWAKE_TEST_RELEASE_JSON -Raw | ConvertFrom-Json
        }
        $asset = Resolve-GitHubReleaseAsset @args
    } catch { $asset = [pscustomobject]@{Resolved=$false;ReleaseFound=$false} }
    if (-not $asset.Resolved -or -not (Test-IsTrackableInstalledVersion ([string]$asset.Tag))) {
        Write-Host '  [!!] The current Alan Wake VR release could not be checked on GitHub.' -ForegroundColor Yellow
        if (-not $asset.ReleaseFound) {
            Write-Host '  The publisher website currently lists v1.0.0. A newer release may exist.' -ForegroundColor Yellow
            if ((Read-Host '  Download the reviewed v1.0.0 Setup? Y/N').Trim() -match '^(?i:y|yes)$') {
                return [pscustomobject]@{Tag='v1.0.0';Url='https://github.com/fholger/alanwake_vr/releases/download/v1.0.0/alanwake-vr-1.0.0.exe';Name='alanwake-vr-1.0.0.exe';Page=$script:AwPage;Manual=$false}
            }
        }
        Write-Host '  Open the official release page and select its publisher Setup EXE.' -ForegroundColor White
        return [pscustomobject]@{Tag='';Url='';Name='alanwake-vr-setup.exe';Page=$script:AwDownloadPage;Manual=$true}
    }
    return [pscustomobject]@{Tag=[string]$asset.Tag;Url=[string]$asset.Url;Name=[string]$asset.AssetName;Page=[string]$asset.PageUrl;Manual=$false}
}
function Get-AwManualSetup([string]$Destination) {
    $declined = ''
    $opened = $false
    while ($true) {
        $candidate = Find-PCVRDownloadedCandidate -Patterns @('alanwake-vr-*.exe')
        if ($candidate -and $candidate -eq $declined) { $candidate = $null }
        if ($candidate -and -not (Test-DownloadedPayload -Path $candidate -IntendedPath $Destination)) { $candidate = $null }
        if ($candidate) {
            Write-Host "  Found in Downloads: $candidate" -ForegroundColor Cyan
            $answer = (Read-Host '  Use this Setup? Y/N').Trim()
            if ($answer -match '^(?i:y|yes)$') {
                Copy-Item -LiteralPath $candidate -Destination $Destination -Force -ErrorAction Stop
                return $candidate
            }
            $declined = $candidate
        }
        if (-not $opened) {
            Write-Host '  Download the current Alan Wake VR Setup from the publisher page.' -ForegroundColor White
            [void](Open-PCVRPageAfterEnter -Url $script:AwDownloadPage -Message 'Press Enter to open the Alan Wake VR download page...')
            $opened = $true
        }
        [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
        $candidate = Find-PCVRDownloadedCandidate -Patterns @('alanwake-vr-*.exe')
        if ($candidate -and $candidate -ne $declined) { continue }
        $raw = (Read-Host '  Drag the downloaded Setup here, or press Enter to open the page again').Trim().Trim('"').Trim("'")
        if ($raw -and (Test-Path -LiteralPath $raw -PathType Leaf)) {
            if (Test-DownloadedPayload -Path $raw -IntendedPath $Destination) {
                Write-Host "  Selected Setup: $raw" -ForegroundColor Cyan
                if ((Read-Host '  Use this Setup? Y/N').Trim() -match '^(?i:y|yes)$') {
                    Copy-Item -LiteralPath $raw -Destination $Destination -Force -ErrorAction Stop
                    return $raw
                }
            } else { Write-Host '  This is not a usable Setup EXE.' -ForegroundColor Yellow }
        } else {
            Start-Process $script:AwDownloadPage -ErrorAction Stop | Out-Null
        }
    }
}
function Get-AwHash([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Test-AwPublisherInstalled([string]$Root) {
    foreach ($name in @('AlanWake.exe','d3d9.dll','Uninstall_AlanWakeVR.exe')) {
        $path = Join-Path $Root $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -lt 1024) { return $false }
    }
    $dll = Join-Path $Root 'd3d9.dll'
    $bytes = [IO.File]::ReadAllBytes($dll)
    return ($bytes.Length -ge 2 -and $bytes[0] -eq 0x4d -and $bytes[1] -eq 0x5a)
}
function Save-AwRollback([string]$Game,[string]$Work) {
    $snapshot = Join-Path $Work 'before'
    [void][IO.Directory]::CreateDirectory($snapshot)
    $present = @{}
    foreach ($name in @($script:AwFiles + $script:AwManifestName + '.pcvrhub_version')) {
        $source = Join-Path $Game $name
        $present[$name] = Test-Path -LiteralPath $source -PathType Leaf
        if ($present[$name]) { Copy-Item -LiteralPath $source -Destination (Join-Path $snapshot $name) -Force -ErrorAction Stop }
    }
    $backup = Join-Path $Game $script:AwBackupName
    $hadBackup = Test-Path -LiteralPath $backup -PathType Container
    if ($hadBackup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $Work 'original-backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{Path=$snapshot;Present=$present;HadBackup=$hadBackup;Work=$Work}
}
function Restore-AwRollback([string]$Game,$Snapshot) {
    foreach ($name in @($Snapshot.Present.Keys)) {
        $target = Join-Path $Game $name
        if ($Snapshot.Present[$name]) { Copy-Item -LiteralPath (Join-Path $Snapshot.Path $name) -Destination $target -Force -ErrorAction Stop }
        elseif (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
    }
    $backup = Join-Path $Game $script:AwBackupName
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    if ($Snapshot.HadBackup) { Copy-Item -LiteralPath (Join-Path $Snapshot.Work 'original-backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}
function Assert-AwExistingOwnership([string]$Game) {
    $manifestPath = Join-Path $Game $script:AwManifestName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        foreach ($name in @($script:AwFiles | Where-Object { $_ -ne 'AlanWake.exe' })) {
            if (Test-Path -LiteralPath (Join-Path $Game $name) -PathType Leaf) {
                throw "$name already exists without a Hub ownership record. Remove or back up that other installation before retrying."
            }
        }
        return $null
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.Identity -ne 'alanwakevr' -or -not (Test-Path -LiteralPath (Join-Path $Game $script:AwBackupName) -PathType Container)) {
        throw 'The recorded Alan Wake VR ownership is incomplete. Repair its backup before updating.'
    }
    foreach ($row in @($manifest.Files)) {
        if ($row.Name -notin $script:AwFiles) { throw 'The Alan Wake VR ownership record contains an unexpected path.' }
        if ($row.HadBefore -and -not (Test-Path -LiteralPath (Join-Path (Join-Path $Game $script:AwBackupName) $row.Name) -PathType Leaf)) {
            throw "The original $($row.Name) backup is missing. Repair it before updating."
        }
        if ((Get-AwHash (Join-Path $Game $row.Name)) -ne [string]$row.AfterHash) {
            throw "$($row.Name) changed since the Hub installation. Review it before updating."
        }
    }
    return $manifest
}
function Write-AwOwnership([string]$Game,$Before,$Previous,[string]$Version,[string]$Route) {
    $backup = Join-Path $Game $script:AwBackupName
    if (-not $Previous) {
        [void][IO.Directory]::CreateDirectory($backup)
        foreach ($name in $script:AwFiles) {
            if ($Before.Present[$name]) { Copy-Item -LiteralPath (Join-Path $Before.Path $name) -Destination (Join-Path $backup $name) -Force -ErrorAction Stop }
        }
    }
    $rows = @()
    foreach ($name in $script:AwFiles) {
        $after = Get-AwHash (Join-Path $Game $name)
        if ($after) {
            $hadBefore = Test-Path -LiteralPath (Join-Path $backup $name) -PathType Leaf
            $rows += [pscustomobject]@{Name=$name;HadBefore=$hadBefore;AfterHash=$after}
        }
    }
    $record = [pscustomobject]@{Identity='alanwakevr';Version=$Version;Route=$Route;Files=$rows}
    $path = Join-Path $Game $script:AwManifestName
    $tmp = $path + '.new'
    [IO.File]::WriteAllText($tmp,($record | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tmp -Destination $path -Force -ErrorAction Stop
}
function Invoke-AwPublisher([string]$Setup,[string]$Game) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        [void](Assert-AwFixture $Game)
        $process = Start-Process -FilePath $Setup -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher Setup ended with exit code $($process.ExitCode)." }
        return
    }
    Write-Host '  The publisher Setup may request Windows administrator approval.' -ForegroundColor Yellow
    Write-Host "  In Setup, select this Alan Wake game folder: $Game" -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open Alan Wake VR publisher Setup...')
    $process = Start-Process -FilePath $Setup -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher Setup ended with exit code $($process.ExitCode)." }
}
function Invoke-AwInstaller {
    $work = $null; $game = $null; $snapshot = $null; $changed = $false; $keep = $false
    try {
        if ($env:PCVR_HUB_TEST_MODE -ne '1') { Clear-Host }
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Alan Wake VR - Installer' -ForegroundColor Cyan
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Original Alan Wake: Steam, GOG or Epic. Remastered is unsupported.' -ForegroundColor White
        Write-Host '  Seated third-person VR, gamepad or keyboard and mouse.' -ForegroundColor White
        Write-Host '  Set an active OpenXR runtime. Quest: use Steam Link or Virtual Desktop;' -ForegroundColor Yellow
        Write-Host '  Meta Horizon Link does not currently work with this mod.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Alan Wake...')
        Write-Host '  Checking saved and installed game locations; this may take a few seconds.' -ForegroundColor Gray
        $game = Get-AwGame
        if ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'AlanWake' -ErrorAction SilentlyContinue)) { throw 'Close Alan Wake before installation or update.' }
        if (-not (Test-InstallerTargetWritable -TargetPath $game)) { throw 'The Alan Wake folder is not writable. Run Setup with the required permission, then retry.' }
        $route = Get-AwRoute $game
        $previous = Assert-AwExistingOwnership $game
        Write-Host "  [OK] Game ($route): $game" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest Alan Wake VR release...')
        Write-Host '  Checking stable GitHub releases; this may take a few seconds.' -ForegroundColor Gray
        $release = Get-AwRelease
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $setup = Join-Path $work $release.Name
        if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ALANWAKE_TEST_SETUP) {
            Copy-Item -LiteralPath $env:PCVR_ALANWAKE_TEST_SETUP -Destination $setup -Force -ErrorAction Stop
        } elseif ($release.Manual) {
            $selected = Get-AwManualSetup -Destination $setup
            $tag = (Read-Host '  Enter the release tag shown on the official page (for example v1.0.0)').Trim()
            if ($tag -notmatch '^v?[0-9]+(?:\.[0-9]+){2}$') { throw 'A trackable Alan Wake VR version was not confirmed. No game files were changed.' }
            $release.Tag = if ($tag.StartsWith('v')) { $tag } else { 'v'+$tag }
            Write-Host "  Selected publisher release: $($release.Tag) ($selected)." -ForegroundColor Yellow
            if ((Read-Host '  Use this Setup and version? Y/N').Trim() -notmatch '^(?i:y|yes)$') {
                throw 'Publisher version was not confirmed. No game files were changed.'
            }
        } else {
            $local = Find-PCVRDownloadedCandidate -Patterns @([IO.Path]::GetFileName(([uri]$release.Url).AbsolutePath))
            $useLocal = $false
            if ($local -and (Test-DownloadedPayload -Path $local -IntendedPath $setup)) {
                Write-Host "  Found in Downloads: $local" -ForegroundColor Cyan
                $useLocal = ((Read-Host "  Use this $($release.Tag) Setup? Y/N").Trim() -match '^(?i:y|yes)$')
            }
            if ($useLocal) { Copy-Item -LiteralPath $local -Destination $setup -Force -ErrorAction Stop }
            else { [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $setup -Label "Alan Wake VR $($release.Tag)" `
                -ManualUrl $script:AwDownloadPage -ExpectedReleaseTag $release.Tag -AllowSkip:$false) }
        }
        if (-not (Test-DownloadedPayload -Path $setup -IntendedPath $setup)) { throw 'The publisher Setup EXE is not usable.' }
        $snapshot = Save-AwRollback -Game $game -Work $work
        $changed = $true
        Invoke-AwPublisher -Setup $setup -Game $game
        if (-not (Test-AwPublisherInstalled $game)) { throw 'Publisher Setup did not leave a complete Alan Wake VR installation. Nothing was marked complete.' }
        Write-AwOwnership -Game $game -Before $snapshot -Previous $previous -Version $release.Tag -Route $route
        $required = @('AlanWake.exe','d3d9.dll','Uninstall_AlanWakeVR.exe',$script:AwManifestName) | ForEach-Object { Join-Path $game $_ }
        if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)) { throw 'Required Alan Wake VR files did not survive the post-install check.' }
        $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ALANWAKE_TEST_RECEIPT) { $env:PCVR_ALANWAKE_TEST_RECEIPT } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:AwContract -GameDir $game -Version $release.Tag -Route $route -InstalledPathReceiptPaths @($receipt))
        $changed = $false
        Write-Host "  [OK] Alan Wake VR $($release.Tag) installed." -ForegroundColor Green
        Write-Host '  Connect your headset, set its OpenXR runtime, then choose Start in VR in the Hub.' -ForegroundColor White
        Write-Host ''
        Write-Host '  The darkness has a new dimension.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-AwRollback -Game $game -Snapshot $snapshot }
            catch { $keep=$true; Write-Host "  Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red }
        }
        $message = "Alan Wake VR setup did not complete: $($_.Exception.Message)"
        Write-Host $message -ForegroundColor Red
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    } finally {
        if ($work -and -not $keep) { try { Remove-PCVRInstallerTempSession -Path $work } catch { } }
    }
}
if ($env:PCVR_ALANWAKE_LIBRARY_ONLY -ne '1') { Invoke-AwInstaller }

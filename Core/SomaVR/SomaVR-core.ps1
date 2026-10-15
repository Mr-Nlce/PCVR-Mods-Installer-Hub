$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle = 'SOMA VR Installer'
$script:SomaId = 'soma-vr'
$script:SomaRepo = 'Bateau01/SOMA-VR'
$script:SomaPage = 'https://github.com/Bateau01/SOMA-VR/releases'
$script:SomaRequired = @('Soma.exe','LAUNCH-SOMA-VR.cmd','hpl3vr.dll','hpl3vr_inject.exe','openxr_loader.dll')

function Test-SomaGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Soma.exe') -PathType Leaf))
}
function Test-SomaInstalled([string]$Root) {
    if (-not (Test-SomaGame $Root)) { return $false }
    foreach ($relative in $script:SomaRequired) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    return $true
}
function Get-SomaRuntimeFingerprint([string]$Root) {
    if (-not (Test-SomaInstalled $Root)) { return $null }
    $parts = foreach ($relative in @($script:SomaRequired | Where-Object { $_ -ne 'Soma.exe' })) {
        $hash = (Get-FileHash -LiteralPath (Join-Path $Root $relative) -Algorithm SHA256 -ErrorAction Stop).Hash
        "$relative=$hash"
    }
    return ($parts -join ';')
}
function Get-SomaRoot {
    $fixture = ('' + $env:PCVR_SOMA_TEST_GAME_ROOT).Trim()
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture) {
        $full = [IO.Path]::GetFullPath($fixture)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path $full 'soma-fixture.txt') -PathType Leaf)) {
            throw 'SOMA test data must stay in an isolated temporary game fixture.'
        }
        return $full
    }
    $saved = Get-PCVRRememberedGameFolder -GameId $script:SomaId -StateNames @('installed_path','user_located') -ProbeFiles @('Soma.exe')
    if (Test-SomaGame $saved) { return (Get-Item -LiteralPath $saved).FullName }
    $found = Find-SteamGameFolder -AppId '282140' -SteamFolderNames @('SOMA','Soma') -ProbeExe 'Soma.exe' -HubGameId $script:SomaId
    if (Test-SomaGame $found) { return (Get-Item -LiteralPath $found).FullName }
    foreach ($candidate in @('C:\GOG Games\SOMA','C:\Program Files (x86)\GOG Galaxy\Games\SOMA',
            'C:\Program Files\Epic Games\SOMA','C:\Program Files (x86)\Frictional Games\SOMA',
            'C:\Program Files (x86)\Twitch\Games Library\4d4aa4d3-cc66-4067-b959-446e4d34512f')) {
        if (Test-SomaGame $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    $manual = Get-GameFolderInteractive -GameName 'SOMA' -ProbeFile 'Soma.exe' -ManualUrl 'https://store.steampowered.com/app/282140/SOMA/'
    if (Test-SomaGame $manual) { return (Get-Item -LiteralPath $manual).FullName }
    return $null
}
function Confirm-SomaFirstFlatLaunch {
    Write-Host ''
    Write-Host '  SOMA must have run flat at least once so user_settings.cfg exists.' -ForegroundColor White
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SOMA_TEST_FLAT_READY -eq '1'){
        Write-Host '  [OK] Isolated fixture confirms first-run preparation.' -ForegroundColor Green
        return
    }
    while($true){
        $answer=(''+(Read-Host '  Already started flat? [Y] Yes / [L] Launch game / [Q] Cancel')).Trim().ToUpperInvariant()
        if($answer -eq 'Y'){return}
        if($answer -eq 'Q'){throw 'Setup cancelled before the required flat first launch.'}
        if($answer -ne 'L'){Write-Host '  Choose Y, L or Q.' -ForegroundColor Yellow;continue}
        Write-Host '  SOMA will open flat. Reach its menu, then exit the game.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to launch SOMA flat...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'A fixture cannot launch the real game.'}
        Start-Process -FilePath (Join-Path $script:SomaSelectedRoot 'Soma.exe') -WorkingDirectory $script:SomaSelectedRoot -ErrorAction Stop
        [void](Wait-PCVRExplicitEnter -Message 'After exiting SOMA, press Enter to return to setup...')
        if(Get-Process -Name Soma -ErrorAction SilentlyContinue){Write-Host '  Close SOMA before continuing.' -ForegroundColor Yellow;continue}
    }
}
function Get-SomaRelease {
    $fixture = ('' + $env:PCVR_SOMA_TEST_ARCHIVE).Trim()
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture) {
        if (-not (Test-Path -LiteralPath $fixture -PathType Leaf)) { throw 'The SOMA release fixture is missing.' }
        $tag = if ($env:PCVR_SOMA_TEST_RELEASE_TAG) { [string]$env:PCVR_SOMA_TEST_RELEASE_TAG } else { 'v1.0.6' }
        return [pscustomobject]@{ Url=$fixture; Tag=$tag; PageUrl=$script:SomaPage; Local=$true }
    }
    $asset = Resolve-GitHubReleaseAsset -Repo $script:SomaRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^SOMA-VR-[0-9].*-Installer\.zip$') `
        -FallbackUrl 'https://github.com/Bateau01/SOMA-VR/releases/download/v1.07.1/SOMA-VR-1.07-S26GH-Installer.zip' `
        -FallbackTag 'v1.07.1' -FallbackAssetName 'SOMA-VR-1.07-S26GH-Installer.zip' -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{ Url=[string]$asset.Url; Tag=[string]$asset.Tag; PageUrl=[string]$asset.PageUrl; Local=$false }
}
function Get-SomaSetup([string]$Extracted) {
    $items = @(Get-ChildItem -LiteralPath $Extracted -Recurse -File -Filter '*-Setup.exe' | Where-Object { $_.Name -match '^SOMA-VR-[0-9].*-Setup\.exe$' })
    if ($items.Count -ne 1) { throw 'The publisher archive must contain exactly one SOMA VR Setup EXE.' }
    $file = [IO.File]::OpenRead($items[0].FullName)
    try { if ($file.Length -lt 1024 -or $file.ReadByte() -ne 77 -or $file.ReadByte() -ne 90) { throw 'The Setup is not a usable Windows EXE.' } }
    finally { $file.Dispose() }
    return $items[0].FullName
}
function Assert-SomaNoDowngrade([string]$Root,[string]$Tag) {
    $receipt = Join-Path $Root '.pcvrhub_version'
    if (-not (Test-SomaInstalled $Root) -or -not (Test-Path -LiteralPath $receipt -PathType Leaf)) { return }
    $saved = ([IO.File]::ReadAllText($receipt)).Trim()
    if ($saved -eq 'v1.04.1') { $saved = 'v1.0.4.1' }
    if ($saved -match '^v(\d+(?:\.\d+){2,3})$' -and $Tag -match '^v(\d+(?:\.\d+){2,3})$') {
        $installed = [version]$saved.Substring(1)
        $selected = [version]$Tag.Substring(1)
        if ($installed -gt $selected) { throw "SOMA VR $installed is already installed. Retry the current download; the fallback cannot downgrade it." }
    }
}
function Invoke-SomaInstaller {
    $work = $null
    try {
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  SOMA VR - Installer' -ForegroundColor Cyan
        Write-Host '  Native OpenXR and motion controls by Bateau01' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Start SOMA once in flat mode before installing; this creates' -ForegroundColor White
        Write-Host '  the user_settings.cfg files needed by publisher Setup.' -ForegroundColor White
        Write-Host '  Publisher Setup installs, updates or repairs its own files.' -ForegroundColor White
        Write-Host '  Existing VR settings and hand calibration are preserved.' -ForegroundColor White
        Write-Host '  Close SOMA before continuing. Setup may ask for UAC approval.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to find SOMA...')
        $root = Get-SomaRoot
        if (-not $root) { throw 'A SOMA folder with Soma.exe was not selected.' }
        $script:SomaSelectedRoot = $root
        Confirm-SomaFirstFlatLaunch
        if ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name Soma -ErrorAction SilentlyContinue)) { throw 'Close SOMA before installing or updating.' }
        Write-Host "  [OK] Game: $root" -ForegroundColor Green
        Write-Host '  Publisher Setup must detect both this game folder and the' -ForegroundColor White
        Write-Host '  folder containing your user_settings.cfg file.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to resolve the current stable release...')
        $release = Get-SomaRelease
        if (-not $release.Tag -or -not $release.Url) { throw 'No SOMA VR installer release could be resolved.' }
        Assert-SomaNoDowngrade -Root $root -Tag ([string]$release.Tag)
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr-soma-' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $zip = Join-Path $work 'publisher.zip'
        Write-Host "  Selected: $($release.Tag)" -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the publisher archive...')
        if ($release.Local) { Copy-Item -LiteralPath $release.Url -Destination $zip -Force -ErrorAction Stop }
        else {
            $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $zip -Label "SOMA VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl $release.PageUrl -AllowSkip:$false
            if (-not $ok) { throw 'The SOMA VR release could not be downloaded.' }
        }
        $extract = Join-Path $work 'release'
        $result = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $extract -Label 'SOMA VR publisher archive' -AllowSkip:$false -QuietProgress
        if ([string]$result -notin @('ok','manual','retry')) { throw 'The SOMA VR archive could not be extracted.' }
        $setup = Get-SomaSetup $extract
        $before = Get-SomaRuntimeFingerprint $root
        Write-Host ''
        Write-Host '  In publisher Setup, confirm the game and settings paths.' -ForegroundColor White
        Write-Host '  Choose Install, Update or Repair, then finish Setup.' -ForegroundColor White
        Write-Host '  This Hub window checks the launch script and runtime files.' -ForegroundColor White
        Write-Host '  Windows may request administrator approval (UAC) for Setup.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
        if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SOMA_TEST_PUBLISHER_OUTPUT) {
            $mock = [IO.Path]::GetFullPath($env:PCVR_SOMA_TEST_PUBLISHER_OUTPUT)
            $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
            if (-not $mock.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath (Join-Path $mock 'soma-publisher-fixture.txt'))) { throw 'Publisher output fixture is invalid.' }
            foreach ($item in @(Get-ChildItem -LiteralPath $mock -File | Where-Object { $_.Name -in $script:SomaRequired })) { Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $root $item.Name) -Force }
        } else {
            $process = Start-Process -FilePath $setup -Wait -PassThru -ErrorAction Stop
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher Setup ended with exit code $($process.ExitCode)." }
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter after publisher Setup has finished...')
        if (-not (Test-SomaInstalled $root)) { throw 'Publisher Setup closed without the required SOMA VR runtime files.' }
        $after = Get-SomaRuntimeFingerprint $root
        if ($before -and $after -eq $before) { throw 'Setup did not change the previous VR runtime; no new update was recorded.' }
        $contract = New-PCVRInstallerContract -Id $script:SomaId -GameName 'SOMA VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:SomaPage -RequiredInstalledFileGroups $script:SomaRequired
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $release.Tag -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        Write-Host "  [OK] SOMA VR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  Start in VR opens LAUNCH-SOMA-VR.cmd as the publisher directs.' -ForegroundColor White
        Write-Host ''
        Write-Host '  The ocean is deep. The existential questions are deeper.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        $message = "SOMA VR setup did not complete: $($_.Exception.Message)"
        Write-Host "  $message" -ForegroundColor Red
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    } finally {
        if ($work -and (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
if ($env:PCVR_SOMA_LIBRARY_ONLY -ne '1') { Invoke-SomaInstaller }

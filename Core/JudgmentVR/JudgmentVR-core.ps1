$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle = 'Judgment VR Installer'
$id = 'judgment-vr'
$repo = 'Tensai30/judgmentvr_1.1'
$page = "https://github.com/$repo/releases"
$required = @('runtime\media\startup.exe','runtime\media\xinput9_1_0.dll',
    'runtime\media\openvr_api.dll','runtime\media\JudgmentVRProbe.ini')
$contract = New-PCVRInstallerContract -Id $id -GameName 'Judgment VR' -Acquisition External `
    -ReleasePageUrl $page -AntivirusNotice -RequiredInstalledFileGroups $required

function Test-JudgmentGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'runtime\media\startup.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'runtime\media\Judgment.exe') -PathType Leaf))
}
function Get-JudgmentRoot {
    $fixture = ('' + $env:PCVR_JUDGMENT_TEST_GAME_ROOT).Trim()
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture) {
        $full = [IO.Path]::GetFullPath($fixture)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path $full 'judgment-fixture.txt') -PathType Leaf)) {
            throw 'Judgment fixture must stay in an isolated temporary game folder.'
        }
        return $full
    }
    $saved = Get-PCVRRememberedGameFolder -GameId $id -StateNames @('installed_path','user_located') -ProbeFiles @('runtime\media\startup.exe')
    if (Test-JudgmentGame $saved) { return (Get-Item -LiteralPath $saved).FullName }
    $steam = Find-SteamGameFolder -AppId '2058180' -SteamFolderNames @('Judgment') -ProbeExe 'runtime\media\startup.exe' -HubGameId $id
    if (Test-JudgmentGame $steam) { return (Get-Item -LiteralPath $steam).FullName }
    $default = 'C:\Program Files (x86)\Steam\steamapps\common\Judgment'
    if (Test-JudgmentGame $default) { return (Get-Item -LiteralPath $default).FullName }
    $picked = Get-GameFolderInteractive -GameName 'Judgment' -ProbeFile 'runtime\media\startup.exe' -ManualUrl 'https://store.steampowered.com/app/2058180/'
    if (Test-JudgmentGame $picked) {
        [void](Save-HubRememberedGameFolder -GameId $id -Title 'Judgment VR' -GameDir $picked -ProbeFiles @('runtime\media\startup.exe','runtime\media\Judgment.exe') -UserSelected)
        return (Get-Item -LiteralPath $picked).FullName
    }
    return $null
}
function Get-JudgmentPublisherRelease([object]$Releases=$null) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_RELEASE_404 -eq '1'){
        Write-Host '  GitHub release lookup is unavailable. Use the publisher Setup from Downloads.' -ForegroundColor Yellow
        return $null
    }
    if ($null -eq $Releases -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_RELEASE_JSON) {
        $mock = [IO.Path]::GetFullPath($env:PCVR_JUDGMENT_TEST_RELEASE_JSON)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
        if (-not $mock.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $mock) 'judgment-fixture.txt'))) {
            throw 'Judgment release fixture must stay in an isolated temporary folder.'
        }
        $Releases = @(Get-Content -LiteralPath $mock -Raw -ErrorAction Stop | ConvertFrom-Json)
    }
    if ($null -eq $Releases) {
        try {
            $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases?per_page=15" `
                -Headers @{ 'User-Agent'='PCVR-Mods-Hub' } -TimeoutSec 20 -ErrorAction Stop
        } catch {
            Write-Host '  GitHub release lookup is unavailable. Use the publisher Setup from Downloads.' -ForegroundColor Yellow
            return $null
        }
    }
    foreach ($release in @($Releases)) {
        if ($release.draft -or -not $release.tag_name) { continue }
        if([string]$release.tag_name -notmatch '(?i)^v?([0-9]+(?:\.[0-9]+){1,3})$'){continue}
        $version=$Matches[1]
        $url = $null
        foreach ($asset in @($release.assets)) {
            $candidate=[string]$asset.browser_download_url
            if($candidate -match '(?i)^https://github\.com/Tensai30/judgmentvr_1\.1/releases/download/[^\s/]+/JudgmentVR-Setup-([0-9]+(?:\.[0-9]+){1,3})\.exe$'){
                if($Matches[1] -ne $version){continue}
                $url=$candidate;break
            }
        }
        if (-not $url) { continue }
        if (-not (Test-IsTrackableInstalledVersion $version)) { continue }
        return [pscustomobject]@{ Tag=[string]$release.tag_name; Version=$version; Url=$url }
    }
    return $null
}
function Get-JudgmentManualRelease {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_LOCAL_SETUP){
        $fixture=[IO.Path]::GetFullPath($env:PCVR_JUDGMENT_TEST_LOCAL_SETUP)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $fixture.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $fixture) 'judgment-fixture.txt'))){throw 'Judgment manual Setup fixture must stay in an isolated folder.'}
        $candidate=Get-Item -LiteralPath $fixture -ErrorAction Stop
        if($candidate.Name -notmatch '(?i)^JudgmentVR-Setup-([0-9]+(?:\.[0-9]+){1,3})\.exe$'){throw 'Judgment manual Setup filename has no version.'}
        $version=$Matches[1]
        $actual=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_LOCAL_VERSION){$env:PCVR_JUDGMENT_TEST_LOCAL_VERSION}else{([string]$candidate.VersionInfo.ProductVersion).Trim()}
        if($actual -ne $version){throw 'Judgment manual Setup product version disagrees with its filename.'}
        return [pscustomobject]@{Tag="local $version";Version=$version;Url=$candidate.FullName;Local=$true}
    }
    $downloads=Get-PCVRDownloadsFolder
    $opened=$false
    $declined=$null
    while($true){
        $handover=Get-PCVRRecoveryInput -PathType Leaf
        $candidate=if($handover -and [IO.Path]::GetExtension($handover) -ieq '.exe'){Get-Item -LiteralPath $handover -ErrorAction SilentlyContinue}else{$null}
        if(-not $candidate -and $downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
            $candidate=Get-ChildItem -LiteralPath $downloads -Filter 'JudgmentVR-Setup*.exe' -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -ne $declined } |
                Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        }
        if($candidate){
            Write-Host "  Found in your Downloads folder: $($candidate.FullName)" -ForegroundColor Cyan
            $choice=(''+(Read-Host '  Use this Setup? [Y/N]')).Trim().ToUpperInvariant()
            if($choice -in @('Y','YES')){
                $file=$candidate.FullName
            }elseif($choice -in @('N','NO')){$declined=$candidate.FullName;$file=$null}
            else{Write-Host '  Please answer Y or N.' -ForegroundColor Yellow;continue}
        }else{$file=$null}
        if(-not $file){
            if(-not $opened){
                Write-Host '  Download the current JudgmentVR-Setup EXE from the publisher releases page.' -ForegroundColor White
                [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to open the Judgment VR releases page...')
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter after the Setup download is complete...')
                $opened=$true
                $downloads=Get-PCVRDownloadsFolder
                if($downloads -and (Get-ChildItem -LiteralPath $downloads -Filter 'JudgmentVR-Setup*.exe' -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $declined })){continue}
            }
            $file=(''+(Read-Host '  Drag the downloaded Setup here or paste its full path (empty cancels)')).Trim().Trim('"').Trim("'")
            if(-not $file){throw 'Judgment VR download was cancelled. No files were changed.'}
        }
        if(-not(Test-Path -LiteralPath $file -PathType Leaf) -or -not(Test-DownloadedPayload -Path $file -IntendedPath 'JudgmentVR-Setup.exe')){
            Write-Host '  This is not a usable publisher Setup EXE.' -ForegroundColor Yellow;continue
        }
        $name=[IO.Path]::GetFileName($file)
        $actual=([string](Get-Item -LiteralPath $file).VersionInfo.ProductVersion).Trim()
        if(-not(Test-IsTrackableInstalledVersion $actual)){throw 'Publisher Setup has no trackable product version. No installation was started.'}
        if($name -match '(?i)^JudgmentVR-Setup-([0-9]+(?:\.[0-9]+){1,3})\.exe$' -and $Matches[1] -ne $actual){throw "Setup filename says $($Matches[1]) but its product version says $actual. No installation was started."}
        $version=$actual
        return [pscustomobject]@{Tag="local $version";Version=$version;Url=(Get-Item -LiteralPath $file).FullName;Local=$true}
    }
}
function Get-JudgmentInstalledVersion([string]$Root) {
    if (-not (Test-JudgmentGame $Root)) { return $null }
    foreach ($relative in @($required | Where-Object { $_ -ne 'runtime\media\startup.exe' })) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $null }
    }
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_INSTALLED_VERSION) {
        return $env:PCVR_JUDGMENT_TEST_INSTALLED_VERSION
    }
    foreach ($hive in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')) {
        foreach ($entry in @(Get-ChildItem -Path $hive -ErrorAction SilentlyContinue)) {
            $value = Get-ItemProperty -LiteralPath $entry.PSPath -ErrorAction SilentlyContinue
            if ($value.DisplayName -notmatch '^Judgment VR mod\b' -or $value.DisplayVersion -notmatch '^\d+(?:\.\d+){1,3}$') { continue }
            return [string]$value.DisplayVersion
        }
    }
    return $null
}
if ($env:PCVR_JUDGMENT_LIBRARY_ONLY -eq '1') { return }

while ($true) {
    $setup=$null
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Judgment VR Installer' -ForegroundColor Cyan
        Write-Host '  Judgment VR mod by Tensai37' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Steam Judgment is required. Close the game and remove other' -ForegroundColor White
        Write-Host '  mods before using the publisher Setup.' -ForegroundColor White
        Write-Host '  The publisher Setup may request administrator approval (UAC).' -ForegroundColor Yellow
        Write-Host '  If required files disappear, check the actual cause and log.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Judgment...')
        $root = Get-JudgmentRoot
        if (-not $root) { throw 'Judgment was not found. No mod files were changed.' }
        if (Get-Process -Name 'Judgment','startup' -ErrorAction SilentlyContinue) { throw 'Close Judgment before installing or updating.' }
        Write-Host "  Game: $root" -ForegroundColor Green
        Write-Host '  Checking GitHub releases, including prereleases. This may take a few seconds.' -ForegroundColor Cyan
        $release = Get-JudgmentPublisherRelease
        if (-not $release) { $release=Get-JudgmentManualRelease }
        Write-Host "  Publisher Setup: $($release.Tag)" -ForegroundColor Green
        $before = Get-JudgmentInstalledVersion $root
        if ($before -eq $release.Version -and -not($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_FORCE_INSTALL -eq '1')) { Write-Host '  This release is already installed.' -ForegroundColor Green; exit 0 }
        if(-not $release.Local){[void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the publisher Setup...')}
        $setup = Join-Path ([IO.Path]::GetTempPath()) ('JudgmentVR-Setup-' + $release.Version + '-' + [Guid]::NewGuid().ToString('N') + '.exe')
        if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_SETUP) {
            $fixtureSetup = [IO.Path]::GetFullPath($env:PCVR_JUDGMENT_TEST_SETUP)
            $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
            if (-not $fixtureSetup.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $fixtureSetup) 'judgment-fixture.txt'))) {
                throw 'Judgment Setup fixture must stay in an isolated temporary folder.'
            }
            $setup = $fixtureSetup
            $ok = $true
        } elseif($release.Local) {
            Copy-Item -LiteralPath $release.Url -Destination $setup -Force -ErrorAction Stop
            $ok=$true
        } else {
            $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $setup -Label "Judgment VR $($release.Version) Setup" -ManualUrl $page -AllowSkip:$false
        }
        if (-not $ok -or -not (Test-DownloadedPayload -Path $setup -IntendedPath 'JudgmentVR-Setup.exe')) { throw 'Publisher Setup was not downloaded as a usable EXE.' }
        $actual = ([string](Get-Item -LiteralPath $setup).VersionInfo.ProductVersion).Trim()
        if (-not($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_SETUP) -and
            $actual -ne $release.Version) { throw "Publisher Setup version $actual does not match selected release $($release.Version)." }
        Write-Host '  Publisher Setup will install or update Judgment VR.' -ForegroundColor White
        Write-Host '  Check the game path in Setup and finish its own wizard.' -ForegroundColor White
        Write-Host '  Windows may request administrator approval (UAC).' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
        if ($env:PCVR_HUB_TEST_MODE -eq '1') {
            if ($env:PCVR_JUDGMENT_TEST_EXIT_CODE -and [int]$env:PCVR_JUDGMENT_TEST_EXIT_CODE -ne 0) {
                throw "Publisher Setup ended with exit code $env:PCVR_JUDGMENT_TEST_EXIT_CODE."
            }
            $output = [IO.Path]::GetFullPath($env:PCVR_JUDGMENT_TEST_PUBLISHER_OUTPUT)
            $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
            if (-not $output.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath (Join-Path $output 'judgment-fixture.txt'))) {
                throw 'Judgment publisher output fixture is invalid.'
            }
            foreach ($relative in @($required | Where-Object { $_ -ne 'runtime\media\startup.exe' })) {
                $source = Join-Path $output $relative
                if (Test-Path -LiteralPath $source -PathType Leaf) {
                    $target = Join-Path $root $relative
                    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
                    Copy-Item -LiteralPath $source -Destination $target -Force
                }
            }
        } else {
            $process = Start-Process -FilePath $setup -Wait -PassThru -ErrorAction Stop
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher Setup ended with exit code $($process.ExitCode)." }
        }
        $installed = Get-JudgmentInstalledVersion $root
        if ($installed -ne $release.Version) { throw 'Setup closed without a matching installed version and required mod files.' }
        $receipt=Join-Path $PSScriptRoot '.installed_path'
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_JUDGMENT_TEST_SETUP){$receipt=Join-Path (Split-Path -Parent $env:PCVR_JUDGMENT_TEST_SETUP) 'installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $installed -Route Current `
            -InstalledPathReceiptPaths @($receipt))
        Write-Host ''
        Write-Host '  Start Judgment through Steam with the VR runtime ready.' -ForegroundColor Green
        Write-Host ''
        Write-Host '  MANUAL STEP - required game graphics settings:' -ForegroundColor Yellow
        Write-Host "  Open Judgment's graphics settings after Setup." -ForegroundColor White
        Write-Host '  Set VSync OFF, Motion Blur OFF and FPS Limit UNLIMITED.' -ForegroundColor White
        Write-Host '  Check these settings before your first VR play session.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Every clue looks different when you can walk around it.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
        exit 0
    } catch {
        $message = "Judgment VR setup did not complete: $($_.Exception.Message)"
        Write-Host "  $message" -ForegroundColor Red
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    } finally {
        if($setup -and $env:PCVR_HUB_TEST_MODE -ne '1' -and (Test-Path -LiteralPath $setup -PathType Leaf)){
            Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue
        }
    }
}

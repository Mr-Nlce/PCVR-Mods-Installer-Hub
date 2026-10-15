$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$Host.UI.RawUI.WindowTitle = 'The House of the Dead 2 VR Installer'
$script:HotDId = 'house-of-the-dead-2-original-vr'
$script:HotDRepo = 'Icedomega13/HouseOfTheDead2VROG'
$script:HotDPage = "https://github.com/$script:HotDRepo/releases"
$script:HotDRequired = @('HotD2VR.exe','install.json','build\pcvr\ddraw.dll',
    'build\pcvr\openxr_loader.dll','pcvr\run-probe.ps1',
    'working\pcvr\game\Hod2.exe','working\pcvr\game\ddraw.dll',
    'working\pcvr\game\openxr_loader.dll')
$script:HotDContract = New-PCVRInstallerContract -Id $script:HotDId -GameName 'The House of the Dead 2 VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:HotDPage -Routes @('Standalone') `
    -RequiredInstalledFileGroups $script:HotDRequired

function Assert-HotDFixtureRoot([string]$Path,[string]$Marker='hotd-fixture.txt') {
    $full = [IO.Path]::GetFullPath($Path)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath (Join-Path $full $Marker) -PathType Leaf)) {
        throw 'HotD2VR test paths must stay inside an isolated temporary fixture.'
    }
    return $full
}

function Get-HotDRelease([object]$ReleaseData=$null) {
    if ($null -eq $ReleaseData -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_RELEASE_JSON) {
        $fixture = [IO.Path]::GetFullPath($env:PCVR_HOTD_TEST_RELEASE_JSON)
        [void](Assert-HotDFixtureRoot -Path (Split-Path -Parent $fixture))
        $ReleaseData = Get-Content -LiteralPath $fixture -Raw -ErrorAction Stop | ConvertFrom-Json
    }
    $args = @{ Repo=$script:HotDRepo; IncludePrerelease=$true;
        AssetPatterns=@('(?i)^HotD2VR-Setup-\d+(?:\.\d+){2}(?:-(?:alpha|beta|rc)\.\d+)?\.exe$');
        SkipReleasesWithoutMatchingAsset=$true }
    if ($null -ne $ReleaseData) { $args.ReleaseData = $ReleaseData }
    $release = Resolve-GitHubReleaseAsset @args
    if (-not $release.Resolved -or -not $release.Url -or $release.Url -notmatch '\.exe$') {
        throw "No unambiguous HotD2VR publisher Setup is available: $($release.Error)"
    }
    $match = [regex]::Match([string]$release.AssetName,
        '(?i)^HotD2VR-Setup-(?<version>\d+(?:\.\d+){2}(?:-(?:alpha|beta|rc)\.\d+)?)\.exe$')
    if (-not $match.Success) { throw 'The publisher Setup has no trackable version.' }
    return [pscustomobject]@{ Version=$match.Groups['version'].Value; Tag=[string]$release.Tag;
        Url=[string]$release.Url; PageUrl=[string]$release.PageUrl; Name=[string]$release.AssetName }
}

function Get-HotDRegistryRoot {
    foreach ($hive in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\HotD2VR',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\HotD2VR')) {
        try {
            $entry = Get-ItemProperty -LiteralPath $hive -ErrorAction Stop
            if ($entry.DisplayName -eq 'HotD2VR Alpha' -and $entry.InstallLocation) {
                return [string]$entry.InstallLocation
            }
        } catch {}
    }
    return $null
}

function Get-HotDInstalled([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    foreach ($relative in $script:HotDRequired) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $null }
    }
    try {
        $manifest = Get-Content -LiteralPath (Join-Path $Root 'install.json') -Raw -ErrorAction Stop | ConvertFrom-Json
        if ($manifest.product -ne 'HotD2VR' -or
            $manifest.release -notmatch '^\d+(?:\.\d+){2}(?:-(?:alpha|beta|rc)\.\d+)?$' -or
            -not $manifest.root -or
            [IO.Path]::GetFullPath([string]$manifest.root).TrimEnd('\') -ine
                [IO.Path]::GetFullPath($Root).TrimEnd('\')) { return $null }
        $exeVersion = ([string](Get-Item -LiteralPath (Join-Path $Root 'HotD2VR.exe')).VersionInfo.ProductVersion).Trim()
        if ($exeVersion -and $exeVersion -ne [string]$manifest.release) { return $null }
        return [pscustomobject]@{ Root=[IO.Path]::GetFullPath($Root); Version=[string]$manifest.release;
            Stamp=(Get-Item -LiteralPath (Join-Path $Root 'install.json')).LastWriteTimeUtc.Ticks }
    } catch { return $null }
}

function Find-HotDInstalled {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_INSTALL_ROOT) {
        $root = Assert-HotDFixtureRoot -Path $env:PCVR_HOTD_TEST_INSTALL_ROOT
        return Get-HotDInstalled $root
    }
    $roots = New-Object 'System.Collections.Generic.List[string]'
    $registered = Get-HotDRegistryRoot
    if ($registered) { $roots.Add($registered) }
    try {
        $remembered = Get-PCVRRememberedGameFolder -GameId $script:HotDId -StateNames @('installed_path') `
            -ProbeFiles @('install.json','HotD2VR.exe')
        if ($remembered) { $roots.Add($remembered) }
    } catch {}
    $receipt = Join-Path $PSScriptRoot '.installed_path'
    try { if (Test-Path -LiteralPath $receipt -PathType Leaf) { $roots.Add((Get-Content -LiteralPath $receipt -Raw).Trim()) } } catch {}
    $roots.Add((Join-Path $env:LOCALAPPDATA 'HotD2VR'))
    foreach ($root in @($roots | Where-Object { $_ } | Select-Object -Unique)) {
        $installed = Get-HotDInstalled $root
        if ($installed) { return $installed }
    }
    return $null
}

function Set-HotDShortcutIcon([string]$Root) {
    $icon = Join-Path $PSScriptRoot 'HotD2VR.ico'
    $link = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Play HotD2VR.lnk'
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_DESKTOP) {
        $desktop = Assert-HotDFixtureRoot -Path $env:PCVR_HOTD_TEST_DESKTOP
        $link = Join-Path $desktop 'Play HotD2VR.lnk'
    }
    if (-not (Test-Path -LiteralPath $icon -PathType Leaf) -or
        -not (Test-Path -LiteralPath $link -PathType Leaf)) { return $false }
    try {
        $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($link)
        $exe = Join-Path $Root 'HotD2VR.exe'
        if ($shortcut.TargetPath -ine $exe -or $shortcut.Arguments.Trim() -ine '/play') { return $false }
        $shortcut.IconLocation = $icon
        $shortcut.Save()
        return $true
    } catch { return $false }
}

function Invoke-HotDPublisherFixture([string]$Root,[string]$Version) {
    $source = Assert-HotDFixtureRoot -Path $env:PCVR_HOTD_TEST_PUBLISHER_OUTPUT
    [void](Assert-HotDFixtureRoot -Path $Root)
    if ($env:PCVR_HOTD_TEST_EXIT_CODE -and [int]$env:PCVR_HOTD_TEST_EXIT_CODE -ne 0) {
        throw "Publisher Setup ended with exit code $env:PCVR_HOTD_TEST_EXIT_CODE."
    }
    foreach ($item in @(Get-ChildItem -LiteralPath $source -File -Recurse -Force |
            Where-Object Name -ne 'hotd-fixture.txt')) {
        $relative = $item.FullName.Substring($source.TrimEnd([char[]]'\/').Length + 1)
        $target = Join-Path $Root $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $item.FullName -Destination $target -Force -ErrorAction Stop
    }
    $manifest = Get-Content -LiteralPath (Join-Path $Root 'install.json') -Raw | ConvertFrom-Json
    $manifest.root = $Root
    $manifest.release = $Version
    $manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Root 'install.json') -Encoding UTF8
}

function Invoke-HotDInstaller {
    $work = $null
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  The House of the Dead 2 - Original PC game in VR' -ForegroundColor Cyan
        Write-Host '  HotD2VR by Icedomega13' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  This is the original Windows PC game, not either Remake.' -ForegroundColor White
        Write-Host '  Bring your own original game: a disc-image ZIP, IMG, ISO or' -ForegroundColor White
        Write-Host '  installed folder. Modified repacks may not work.' -ForegroundColor White
        Write-Host '  Publisher Setup creates a separate VR copy; it does not' -ForegroundColor White
        Write-Host '  change the original game folder or source media.' -ForegroundColor White
        Write-Host '  Choose a destination with at least 3 GB free. Its dependency' -ForegroundColor White
        Write-Host '  downloads and disc preparation can take several minutes.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check HotD2VR releases...')

        Write-Host ''; Write-Host '--- [1/4] Resolve the current publisher release, including prereleases ---' -ForegroundColor Cyan
        $manualSetup = Get-PCVRRecoveryInput -PathType Leaf
        if ($manualSetup -and [IO.Path]::GetExtension($manualSetup) -ine '.exe') {
            throw 'The recovery file must be a HotD2VR publisher Setup EXE.'
        }
        try { $release = Get-HotDRelease }
        catch {
            if (-not $manualSetup) { throw }
            $localVersion = ([string](Get-Item -LiteralPath $manualSetup).VersionInfo.ProductVersion).Trim()
            if ($localVersion -notmatch '^\d+(?:\.\d+){2}(?:-(?:alpha|beta|rc)\.\d+)?$') { throw }
            Write-Host '  [..] Online release lookup is unavailable; using the selected publisher Setup.' -ForegroundColor Yellow
            $release = [pscustomobject]@{ Version=$localVersion; Tag=$localVersion; Url='';
                PageUrl=$script:HotDPage; Name=[IO.Path]::GetFileName($manualSetup) }
        }
        Write-Host "  [OK] $($release.Tag) - $($release.Name)" -ForegroundColor Green
        $before = Find-HotDInstalled
        if ($before) { Write-Host "  Existing VR copy: $($before.Version) at $($before.Root)" -ForegroundColor Gray }
        Write-Host ''
        Write-Host '  Setup is unsigned. Windows or antivirus may ask you to review it.' -ForegroundColor Yellow
        Write-Host '  Verify the publisher and any actual protection event before' -ForegroundColor White
        Write-Host '  deciding how to proceed; missing files alone prove no cause.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the publisher Setup...')

        Write-Host ''; Write-Host '--- [2/4] Download and check the publisher EXE ---' -ForegroundColor Cyan
        $tempChoice = Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) `
            -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes 104857600L
        if (-not $tempChoice.BasePath) { throw 'No writable temporary location has enough free space.' }
        $work = New-PCVRInstallerTempSession -BasePath $tempChoice.BasePath
        $setup = Join-Path $work $release.Name
        if ($manualSetup) {
            Copy-Item -LiteralPath $manualSetup -Destination $setup -Force -ErrorAction Stop
            $ok = $true
        } elseif ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_SETUP) {
            $source = [IO.Path]::GetFullPath($env:PCVR_HOTD_TEST_SETUP)
            [void](Assert-HotDFixtureRoot -Path (Split-Path -Parent $source))
            Copy-Item -LiteralPath $source -Destination $setup -Force -ErrorAction Stop
            $ok = $true
        } else {
            $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $setup `
                -Label "HotD2VR $($release.Version) publisher Setup" -ManualUrl $release.PageUrl -AllowSkip:$false
        }
        if (-not $ok -or -not (Test-DownloadedPayload -Path $setup -IntendedPath $release.Name)) {
            throw 'Publisher Setup was not downloaded as a usable EXE.'
        }
        $productVersion = ([string](Get-Item -LiteralPath $setup).VersionInfo.ProductVersion).Trim()
        if ($productVersion -and $productVersion -ne $release.Version) {
            throw "Selected Setup reports $productVersion, but the chosen release is $($release.Version)."
        }
        Write-Host '  [OK] Publisher EXE is ready. The game is not included.' -ForegroundColor Green

        Write-Host ''; Write-Host '--- [3/4] Run publisher Setup ---' -ForegroundColor Cyan
        Write-Host '  In Setup, select your original Windows PC disc-image ZIP,' -ForegroundColor White
        Write-Host '  IMG/ISO, or Use an installed game folder instead.' -ForegroundColor White
        Write-Host '  For an installed folder, choose the one with Hod2.exe.' -ForegroundColor White
        Write-Host '  Default: C:\Program Files (x86)\SEGA\THE HOUSE OF THE DEAD 2' -ForegroundColor Yellow
        Write-Host '  Check the VR destination and click Install / update.' -ForegroundColor White
        Write-Host '  Windows administrator approval (UAC) may be required,' -ForegroundColor Yellow
        Write-Host '  especially for disc mounting. Setup may take several minutes.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
        if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_PUBLISHER_OUTPUT) {
            $fixtureRoot = Assert-HotDFixtureRoot -Path $env:PCVR_HOTD_TEST_INSTALL_ROOT
            Invoke-HotDPublisherFixture -Root $fixtureRoot -Version $release.Version
        } else {
            $process = Start-Process -FilePath $setup -Wait -PassThru -ErrorAction Stop
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) {
                throw "Publisher Setup ended with exit code $($process.ExitCode)."
            }
        }

        Write-Host ''; Write-Host '--- [4/4] Verify the installed VR copy ---' -ForegroundColor Cyan
        $after = Find-HotDInstalled
        if (-not $after -or $after.Version -ne $release.Version) {
            throw 'Setup closed without a complete matching HotD2VR installation. No success was recorded.'
        }
        if ($before -and $before.Root -ieq $after.Root -and $before.Version -eq $after.Version -and
            $before.Stamp -eq $after.Stamp) {
            throw 'Setup made no detectable change. The previous installation remains; no new completion was recorded.'
        }
        $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_RECEIPT) {
            [IO.Path]::GetFullPath($env:PCVR_HOTD_TEST_RECEIPT)
        } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:HotDContract -GameDir $after.Root `
            -Version $after.Version -Route Standalone -InstalledPathReceiptPaths @($receipt))
        if (Set-HotDShortcutIcon -Root $after.Root) {
            Write-Host '  [OK] Play HotD2VR desktop shortcut now has the supplied icon.' -ForegroundColor Green
        } else {
            Write-Host '  [..] No matching publisher desktop shortcut to update.' -ForegroundColor Gray
        }
        Write-Host "  [OK] HotD2VR $($after.Version) is installed at $($after.Root)." -ForegroundColor Green
        Write-Host '  Connect your headset, select a 32-bit OpenXR runtime, then' -ForegroundColor White
        Write-Host '  use Start in VR or the Play HotD2VR desktop shortcut.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Reload one gun at a time; the dead will not wait for both.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {
        if ($work) { try { Remove-PCVRInstallerTempSession -Path $work } catch {} }
    }
}

if ($env:PCVR_HOTD_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-HotDInstaller; break }
        catch {
            $message = "HotD2VR setup did not complete: $($_.Exception.Message)"
            Write-Host "  $message" -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}

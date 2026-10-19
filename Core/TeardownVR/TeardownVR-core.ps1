$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle = 'Teardown VR Installer'
$script:TeardownId = 'teardown-vr'
$script:TeardownRepo = 'Pluventi/teardown-vr'
$script:TeardownPage = 'https://github.com/Pluventi/teardown-vr/releases'
$script:TeardownFiles = @('dsound.dll','mods\teardownvr\info.txt','mods\teardownvr\main.lua','mods\teardownvr\proxy.vox')
$script:TeardownContract = New-PCVRInstallerContract -Id $script:TeardownId -GameName 'Teardown VR' -Acquisition GitHub `
    -ReleasePageUrl $script:TeardownPage -AntivirusNotice -Routes @('Steam') -RequiredInstalledFileGroups $script:TeardownFiles

function Assert-TeardownFixture([string]$Root) {
    $full = [IO.Path]::GetFullPath($Root)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath (Join-Path $full 'teardown-fixture.txt') -PathType Leaf)) {
        throw 'Teardown test game must be an isolated temporary fixture.'
    }
    return $full
}

function Get-TeardownRoot {
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        if (-not $env:PCVR_TEARDOWN_TEST_GAME) { throw 'Teardown test game path is missing.' }
        $root = Assert-TeardownFixture $env:PCVR_TEARDOWN_TEST_GAME
        if (-not (Test-Path -LiteralPath (Join-Path $root 'teardown.exe') -PathType Leaf)) { throw 'Fixture has no teardown.exe.' }
        return $root
    }
    $remembered = Get-PCVRRememberedGameFolder -GameId $script:TeardownId -StateNames @('installed_path','user_located') -ProbeFiles @('teardown.exe')
    if ($remembered) { return $remembered }
    $found = Find-SteamGameFolder -AppId '1167630' -SteamFolderNames @('Teardown') -ProbeExe 'teardown.exe' -HubGameId $script:TeardownId
    if ($found) { return $found }
    $picked = Get-GameFolderInteractive -GameName 'Teardown' -ProbeFile 'teardown.exe' -ManualUrl 'https://store.steampowered.com/app/1167630/Teardown/'
    if ($picked) {
        [void](Save-HubRememberedGameFolder -GameId $script:TeardownId -Title 'Teardown' -GameDir $picked -ProbeFiles @('teardown.exe') -UserSelected)
        return $picked
    }
    throw 'A Steam Teardown game folder was not selected.'
}

function Get-TeardownRelease([object]$ReleaseData=$null) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_RELEASE_JSON) {
        $path = [IO.Path]::GetFullPath($env:PCVR_TEARDOWN_TEST_RELEASE_JSON)
        [void](Assert-TeardownFixture (Split-Path -Parent $path))
        $ReleaseData = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    }
    $args = @{ Repo=$script:TeardownRepo; IncludePrerelease=$false; SkipReleasesWithoutMatchingAsset=$true;
        AssetPatterns=@('(?i)^Teardown-VR-Installer\.exe$') }
    if ($null -ne $ReleaseData) { $args.ReleaseData = $ReleaseData }
    $asset = Resolve-GitHubReleaseAsset @args
    if (-not $asset.Resolved -or -not $asset.Url -or [string]$asset.AssetName -ine 'Teardown-VR-Installer.exe' -or
        [string]$asset.Tag -notmatch '^v?(?<version>\d+(?:\.\d+){1,3})$') {
        Write-Host '  [!!] The current Teardown VR publisher release could not be checked on GitHub.' -ForegroundColor Yellow
        if ($asset.ReleaseFound) {
            Write-Host '  GitHub returned a release with a different asset layout. Choose its Setup on the release page.' -ForegroundColor Yellow
            return [pscustomobject]@{Version='';Tag='';Url='';PageUrl=$script:TeardownPage;Manual=$true}
        }
        Write-Host '  The last reviewed stable release is v1.0.0 (15 October 2026).' -ForegroundColor Yellow
        Write-Host '  A newer release may exist. You can use v1.0.0 or select its current Setup on the release page.' -ForegroundColor White
        if ((Read-Host '  Download the reviewed v1.0.0 Setup? Y/N').Trim() -match '^(?i)y(?:es)?$') {
            return [pscustomobject]@{Version='1.0.0';Tag='v1.0.0';Url='https://github.com/Pluventi/teardown-vr/releases/download/v1.0.0/Teardown-VR-Installer.exe';PageUrl=$script:TeardownPage;Manual=$false}
        }
        return [pscustomobject]@{Version='';Tag='';Url='';PageUrl=$script:TeardownPage;Manual=$true}
    }
    return [pscustomobject]@{Version=$Matches.version;Tag=[string]$asset.Tag;Url=[string]$asset.Url;PageUrl=[string]$asset.PageUrl}
}

function Test-TeardownInstalled([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root 'teardown.exe') -PathType Leaf)) { return $false }
    foreach ($relative in $script:TeardownFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    # The publisher identifies its own dsound proxy with this bridge marker.
    $dll = Join-Path $Root 'dsound.dll'
    $bytes = [IO.File]::ReadAllBytes($dll)
    $marker = [Text.Encoding]::ASCII.GetBytes('TDVR1')
    $found = $false
    for ($i=0; $i -le $bytes.Length-$marker.Length; $i++) {
        if ($bytes[$i] -ne $marker[0]) { continue }
        $same = $true
        for ($j=1; $j -lt $marker.Length; $j++) { if ($bytes[$i+$j] -ne $marker[$j]) { $same=$false; break } }
        if ($same) { $found=$true; break }
    }
    return $found
}

function Get-TeardownSetupCache([string]$Version) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        $root = Assert-TeardownFixture $env:PCVR_TEARDOWN_TEST_GAME
        return (Join-Path $root ('teardown-publisher-'+$Version+'.exe'))
    }
    $base = Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\PublisherSetup\teardown-vr'
    return (Join-Path $base ('Teardown-VR-Installer-'+$Version+'.exe'))
}
function Get-TeardownManualSetup([string]$Destination) {
    $declined = ''
    $opened = $false
    while ($true) {
        $candidate = Find-PCVRDownloadedCandidate -Patterns @('Teardown-VR-Installer.exe')
        if ($candidate -and $candidate -eq $declined) { $candidate = $null }
        if ($candidate -and -not (Test-DownloadedPayload -Path $candidate -IntendedPath $Destination)) { $candidate = $null }
        if ($candidate) {
            Write-Host "  Found in Downloads: $candidate" -ForegroundColor Cyan
            if ((Read-Host '  Use this Setup? Y/N').Trim() -match '^(?i:y|yes)$') {
                Copy-Item -LiteralPath $candidate -Destination $Destination -Force -ErrorAction Stop
                return $candidate
            }
            $declined = $candidate
        }
        if (-not $opened) {
            Write-Host '  Download the current Teardown VR Setup from the publisher releases page.' -ForegroundColor White
            [void](Open-PCVRPageAfterEnter -Url $script:TeardownPage -Message 'Press Enter to open the Teardown VR releases page...')
            $opened = $true
        }
        [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
        $candidate = Find-PCVRDownloadedCandidate -Patterns @('Teardown-VR-Installer.exe')
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
            Start-Process $script:TeardownPage -ErrorAction Stop | Out-Null
        }
    }
}

function Save-TeardownBeforeState([string]$Root,[string]$Work) {
    $relativePaths = @($script:TeardownFiles) + @('dsound.dll.original','TeardownVR.ini')
    $state = @{}
    foreach ($relative in $relativePaths) {
        $source = Join-Path $Root $relative
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            $backup = Join-Path $Work ('before\'+$relative)
            New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $backup -Force -ErrorAction Stop
            $state[$relative] = $backup
        } else { $state[$relative] = $null }
    }
    return $state
}

function Restore-TeardownBeforeState([string]$Root,[hashtable]$State) {
    $errors = @()
    foreach ($relative in @($State.Keys)) {
        $target = Join-Path $Root $relative
        try {
            if ($State[$relative]) {
                New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
                Copy-Item -LiteralPath $State[$relative] -Destination $target -Force -ErrorAction Stop
            } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
                Remove-Item -LiteralPath $target -Force -ErrorAction Stop
            }
        } catch { $errors += "$relative`: $($_.Exception.Message)" }
    }
    if ($errors.Count) { throw ('Could not fully restore the previous Teardown files: ' + ($errors -join '; ')) }
}

function Invoke-TeardownPublisher([string]$Setup,[string]$GameDir,[ValidateSet('install','uninstall')][string]$Action) {
    $args = '/'+$Action+' /silent /gamedir "'+$GameDir+'"'
    Write-Host "  [..] Publisher Setup is working on Teardown VR ($Action)." -ForegroundColor Cyan
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        [void](Assert-TeardownFixture $GameDir)
        $proc = Start-Process -FilePath $Setup -ArgumentList $args -PassThru -Wait -WindowStyle Hidden -ErrorAction Stop
    } else {
        $proc = Start-Process -FilePath $Setup -ArgumentList $args -PassThru -Wait -Verb RunAs -ErrorAction Stop
    }
    if ($null -eq $proc.ExitCode -or $proc.ExitCode -ne 0) {
        throw "Publisher Setup $Action ended with exit code $($proc.ExitCode). The game was not marked complete."
    }
}

function Invoke-TeardownInstaller {
    $work = $null
    try {
        if ($env:PCVR_HUB_TEST_MODE -ne '1') { Clear-Host }
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Teardown VR - Installer' -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Requires Steam Teardown 2.0.1, Windows x64 and OpenXR.' -ForegroundColor White
        Write-Host '  The GitHub build has no stereo-particle fix or VR anti-aliasing.' -ForegroundColor Yellow
        Write-Host '  Publisher Setup installs both the DLL and the Lua mod.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate Teardown...')
        $root = Get-TeardownRoot
        Write-Host "  Game: $root" -ForegroundColor Green
        if (Get-Process -Name 'teardown' -ErrorAction SilentlyContinue) { throw 'Close Teardown before installing or updating the VR mod.' }
        $firstInstall = -not (Test-TeardownInstalled $root)
        $release = Get-TeardownRelease
        if (-not $release.Manual) { Write-Host "  Selected publisher release: $($release.Tag)" -ForegroundColor Green }
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $setup = Join-Path $work 'Teardown-VR-Installer.exe'
        $testSetup = if ($env:PCVR_HUB_TEST_MODE -eq '1') { [string]$env:PCVR_TEARDOWN_TEST_SETUP } else { '' }
        if ($testSetup) {
            if (-not (Test-DownloadedPayload -Path $testSetup -IntendedPath $setup)) { throw 'The Teardown test publisher Setup is not a usable EXE.' }
            Copy-Item -LiteralPath $testSetup -Destination $setup -Force -ErrorAction Stop
            Unblock-File -LiteralPath $setup -ErrorAction SilentlyContinue
        } else {
            if ($release.Manual) {
                $selected = Get-TeardownManualSetup -Destination $setup
                $ok = [bool]$selected
                $manualTag = (Read-Host '  Enter the release tag shown on the official page (for example v1.0.0)').Trim()
                if ($manualTag -notmatch '^v?(?<version>\d+(?:\.\d+){1,3})$') {
                    throw 'A trackable publisher release version was not confirmed. No game files were changed.'
                }
                $release.Version = $Matches.version
                $release.Tag = 'v' + $Matches.version
                Write-Host "  Selected publisher release: $($release.Tag)." -ForegroundColor Yellow
                if ((Read-Host '  Use this Setup and version? Y/N').Trim() -notmatch '^(?i)y(?:es)?$') {
                    throw 'Publisher version was not confirmed. No game files were changed.'
                }
            } else {
                $local = if ($release.Tag -eq 'v1.0.0') { Find-PCVRDownloadedCandidate -Patterns @('Teardown-VR-Installer.exe') } else { $null }
                $useLocal = $false
                if ($local -and (Test-DownloadedPayload -Path $local -IntendedPath $setup)) {
                    Write-Host "  Found in Downloads: $local" -ForegroundColor Cyan
                    Write-Host '  The Setup filename has no version; confirm it came from the v1.0.0 publisher release.' -ForegroundColor Yellow
                    $useLocal = ((Read-Host '  Use this v1.0.0 Setup? Y/N').Trim() -match '^(?i:y|yes)$')
                }
                if ($useLocal) { Copy-Item -LiteralPath $local -Destination $setup -Force -ErrorAction Stop; $ok=$true }
                else {
                    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the selected publisher installer...')
                    $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $setup -Label "Teardown VR $($release.Version)" `
                        -ManualUrl $script:TeardownPage -ExpectedReleaseTag $release.Tag -DisableGitHubAssetReresolution -AllowSkip:$false
                }
            }
            if (-not $ok -or -not (Test-DownloadedPayload -Path $setup -IntendedPath $setup)) { throw 'The publisher Setup is not ready.' }
        }
        Write-Host '  Windows may request administrator approval to write in the Steam game folder.' -ForegroundColor Yellow
        Write-Host '  Start in VR uses Steam after the one-time in-game mod enablement.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Teardown VR...')
        $before = Save-TeardownBeforeState -Root $root -Work $work
        try {
            Invoke-TeardownPublisher -Setup $setup -GameDir $root -Action install
            if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_REMOVE_AFTER_PUBLISHER) {
                $missing = [string]$env:PCVR_TEARDOWN_TEST_REMOVE_AFTER_PUBLISHER
                if ($missing -notin $script:TeardownFiles) { throw 'Invalid Teardown missing-file fixture.' }
                Remove-Item -LiteralPath (Join-Path $root $missing) -Force -ErrorAction Stop
            }
            if (-not (Test-TeardownInstalled $root)) { throw 'Publisher Setup returned without the DLL and complete Lua mod; no success was recorded.' }
            $cachedSetup = Get-TeardownSetupCache $release.Version
            New-Item -ItemType Directory -Path (Split-Path -Parent $cachedSetup) -Force | Out-Null
            Copy-Item -LiteralPath $setup -Destination $cachedSetup -Force -ErrorAction Stop
            if (-not (Test-DownloadedPayload -Path $cachedSetup -IntendedPath 'Teardown-VR-Installer.exe')) {
                throw 'The publisher Setup could not be retained for uninstall.'
            }
            $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_RECEIPT) {
                [IO.Path]::GetFullPath($env:PCVR_TEARDOWN_TEST_RECEIPT)
            } else { Join-Path $PSScriptRoot '.installed_path' }
            [void](Complete-PCVRInstallTransaction -Contract $script:TeardownContract -GameDir $root -Version $release.Version `
                -Route Steam -InstalledPathReceiptPaths @($receipt))
        } catch {
            $failure = $_.Exception.Message
            try { Restore-TeardownBeforeState -Root $root -State $before }
            catch { throw "$failure Rollback needs attention: $($_.Exception.Message)" }
            throw $failure
        }
        Write-Host '  [OK] Teardown VR is installed.' -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Yellow
        Write-Host '  Alternative: start Teardown from Steam.' -ForegroundColor White
        if ($firstInstall) {
            Write-Host ''
            Write-Host '  FIRST START - ACTIVATE TEARDOWN VR ONCE' -ForegroundColor Yellow
            Write-Host '  Connect your headset and set your OpenXR runtime before launching.' -ForegroundColor White
            Write-Host '  The menu appears on a virtual screen IN THE HEADSET.' -ForegroundColor Yellow
            Write-Host '  The desktop view may not be usable for this step.' -ForegroundColor Yellow
            Write-Host '  In the game: Play > Mod-Manager.' -ForegroundColor Green
            Write-Host '  Scroll down to Teardown VR and select it.' -ForegroundColor Green
            Write-Host '  Click Deactivated to switch it to Activated.' -ForegroundColor Green
            Write-Host '  This is needed only once; later updates keep the enabled mod.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start Teardown through Steam for the first-time VR setup...')
            if ($env:PCVR_HUB_TEST_MODE -eq '1') {
                if ($env:PCVR_TEARDOWN_TEST_ACTIONS) {
                    [void](Assert-TeardownFixture (Split-Path -Parent $env:PCVR_TEARDOWN_TEST_ACTIONS))
                    Add-Content -LiteralPath $env:PCVR_TEARDOWN_TEST_ACTIONS -Value 'open:steam://rungameid/1167630'
                }
            } else {
                try { Start-Process 'steam://rungameid/1167630' -ErrorAction Stop | Out-Null }
                catch { Write-Host '  Steam did not open. Use Start in VR in the Hub or start Teardown from Steam.' -ForegroundColor Yellow }
            }
        }
        Write-Host ''
        Write-Host '  The next wall is merely a suggestion.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {
        if ($work) { try { Remove-PCVRInstallerTempSession -Path $work } catch {} }
    }
}

if ($env:PCVR_TEARDOWN_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-TeardownInstaller; break }
        catch {
            $message = "Teardown VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}

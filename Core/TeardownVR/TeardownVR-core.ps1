param([Alias('InstallerChoice')][ValidateSet('','legacy','markos')][string]$Mod='')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'TeardownVR-Modes.ps1')
$Host.UI.RawUI.WindowTitle = 'Teardown VR Installer'
$script:TeardownId = 'teardown-vr'
$script:TeardownVersion = '1.1.0'
$script:TeardownPage = 'https://www.patreon.com/VRGamesForAll/posts/teardown-vr-v1-1-172191906'
$script:TeardownFiles = @('dsound.dll','mods\teardownvr\info.txt','mods\teardownvr\main.lua','mods\teardownvr\proxy.vox')
$script:TeardownContract = New-PCVRInstallerContract -Id $script:TeardownId -GameName 'Teardown VR' -Acquisition External `
    -ReleasePageUrl $script:TeardownPage -AntivirusNotice -Routes @('Steam') -RequiredInstalledFileGroups (@('dsound.dll|dsound.dll.pcvrhub_teardown_legacy')+@($script:TeardownFiles|Where-Object {$_ -ne 'dsound.dll'}))

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

function Get-TeardownRelease {
    return [pscustomobject]@{
        Version = $script:TeardownVersion
        Tag = 'v' + $script:TeardownVersion
        Url = 'https://www.patreon.com/file?h=172191906&m=773303902'
        PageUrl = $script:TeardownPage
    }
}

function Get-TeardownPublisherSetup([string]$Destination) {
    $testSetup = if ($env:PCVR_HUB_TEST_MODE -eq '1') { $env:PCVR_TEARDOWN_TEST_SETUP } else { '' }
    if ($testSetup) {
        if (-not (Test-DownloadedPayload -Path $testSetup -IntendedPath $Destination)) { throw 'The test publisher Setup is not a usable EXE.' }
        Copy-Item -LiteralPath $testSetup -Destination $Destination -Force -ErrorAction Stop
        return
    }

    $release = Get-TeardownRelease
    $download = @{
        Urls = @($release.Url)
        Destination = $Destination
        Label = "Teardown VR $($release.Tag) Setup"
        ManualUrl = $release.PageUrl
        Instructions = 'Download the Windows Setup attached to this post, then drag the EXE here or paste its full path.'
        FunctionalPayloadOnly = $true
        AllowSkip = $false
        Validator = { param($path) (Get-Item -LiteralPath $path -ErrorAction Stop).VersionInfo.ProductName -eq 'Teardown VR' }
    }
    $result = Invoke-SafeDownload @download
    if (($result -ne $true -and $result -ne 'retry') -or -not [IO.File]::Exists($Destination)) {
        throw 'The Teardown VR publisher Setup is not ready.'
    }
}

function Test-TeardownInstalled([string]$Root,[switch]$RequireCurrentProtocol) {
    if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root 'teardown.exe') -PathType Leaf)) { return $false }
    foreach ($relative in $script:TeardownFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    $proxy = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes((Join-Path $Root 'dsound.dll')))
    if ($RequireCurrentProtocol) {
        $lua = [IO.File]::ReadAllText((Join-Path $Root 'mods\teardownvr\main.lua'))
        return ($proxy.Contains('TDVR2') -and $lua -match '(?m)^\s*local\s+PROTO\s*=\s*"TDVR2"')
    }
    return $proxy.Contains('TDVR1')
}

function Get-TeardownSetupCache([string]$Version) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        $root = Assert-TeardownFixture $env:PCVR_TEARDOWN_TEST_GAME
        return (Join-Path $root ('teardown-publisher-'+$Version+'.exe'))
    }
    $base = Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\PublisherSetup\teardown-vr'
    return (Join-Path $base ('Teardown-VR-Installer-'+$Version+'.exe'))
}
function Save-TeardownBeforeState([string]$Root,[string]$Work) {
    $relativePaths = @($script:TeardownFiles) + @('dsound.dll.original','TeardownVR.ini','dsound.dll.pcvrhub_teardown_legacy','.pcvrhub_teardown_active')
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
    $keepWork = $false
    try {
        if ($env:PCVR_HUB_TEST_MODE -ne '1') { Clear-Host }
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Teardown VR - Installer' -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Requires Steam Teardown 2.0.x, Windows x64 and OpenXR.' -ForegroundColor White
        Write-Host '  VR Games For All publishes this Windows Setup on Patreon.' -ForegroundColor Yellow
        Write-Host '  Publisher Setup installs both the DLL and the Lua mod.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate Teardown...')
        $root = Get-TeardownRoot
        Write-Host "  Game: $root" -ForegroundColor Green
        if (Get-Process -Name 'teardown' -ErrorAction SilentlyContinue) { throw 'Close Teardown before installing or updating the VR mod.' }
        $firstInstall = -not (Test-PCVRTeardownProfile -GameRoot $root -Slot A)
        $activeFile=Join-Path $root '.pcvrhub_teardown_active'
        $keepMarkosActive=[IO.File]::Exists($activeFile) -and [IO.File]::ReadAllText($activeFile).Trim() -eq 'markos'
        $release = Get-TeardownRelease
        Write-Host "  Selected publisher release: $($release.Tag) (Patreon, public download)" -ForegroundColor Green
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $setup = Join-Path $work 'Installer Teardown VR.exe'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the publisher installer...')
        Get-TeardownPublisherSetup -Destination $setup
        Write-Host '  Windows may request administrator approval to write in the Steam game folder.' -ForegroundColor Yellow
        Write-Host '  Start in VR uses Steam after the one-time in-game mod enablement.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Teardown VR...')
        $before = Save-TeardownBeforeState -Root $root -Work $work
        $cachedSetup=Get-TeardownSetupCache $release.Version
        if([IO.Directory]::Exists($cachedSetup)){throw 'The publisher recovery cache target is a directory. No game files were changed.'}
        $cacheStage=Join-Path $work 'cache-stage';[void][IO.Directory]::CreateDirectory($cacheStage)
        Copy-Item -LiteralPath $setup -Destination (Join-Path $cacheStage ([IO.Path]::GetFileName($cachedSetup)))
        $cacheSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot (Split-Path -Parent $cachedSetup) -Stage $cacheStage -Identity teardownpublishercache -SnapshotRoot (Join-Path $work 'snapshot-cache')
        try {
            Invoke-TeardownPublisher -Setup $setup -GameDir $root -Action install
            if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_REMOVE_AFTER_PUBLISHER) {
                $missing = [string]$env:PCVR_TEARDOWN_TEST_REMOVE_AFTER_PUBLISHER
                if ($missing -notin $script:TeardownFiles) { throw 'Invalid Teardown missing-file fixture.' }
                Remove-Item -LiteralPath (Join-Path $root $missing) -Force -ErrorAction Stop
            }
            if (-not (Test-TeardownInstalled $root -RequireCurrentProtocol)) { throw 'Publisher Setup did not leave the current TDVR2 proxy and Lua mod; no success was recorded.' }
            New-Item -ItemType Directory -Path (Split-Path -Parent $cachedSetup) -Force | Out-Null
            Copy-Item -LiteralPath $setup -Destination $cachedSetup -Force -ErrorAction Stop
            if (-not (Test-DownloadedPayload -Path $cachedSetup -IntendedPath 'Teardown-VR-Installer.exe')) {
                throw 'The publisher Setup could not be retained for uninstall.'
            }
            if($keepMarkosActive){
                Move-Item -LiteralPath (Join-Path $root 'dsound.dll') -Destination (Join-Path $root 'dsound.dll.pcvrhub_teardown_legacy') -Force
            }
            $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_RECEIPT) {
                [IO.Path]::GetFullPath($env:PCVR_TEARDOWN_TEST_RECEIPT)
            } else { Join-Path $PSScriptRoot '.installed_path' }
            [void](Complete-PCVRInstallTransaction -Contract $script:TeardownContract -GameDir $root -Version $release.Version `
                -Route Steam -InstalledPathReceiptPaths @($receipt))
        } catch {
            $failure = $_.Exception.Message
            $rollbackErrors=@()
            try { Restore-TeardownBeforeState -Root $root -State $before }catch{$rollbackErrors+=$_.Exception.Message}
            try { Restore-PCVRPublisherZipSnapshot -GameRoot (Split-Path -Parent $cachedSetup) -Snapshot $cacheSnapshot }catch{$rollbackErrors+=$_.Exception.Message}
            if($rollbackErrors.Count){$keepWork=$true;throw ($failure+' Rollback needs attention: '+($rollbackErrors -join '; ')+' Recovery copy: '+$work)}
            throw $failure
        }
        Write-Host '  [OK] Teardown VR is installed.' -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Yellow
        Write-Host '  Alternative: start Teardown from Steam.' -ForegroundColor White
        if ($firstInstall -and -not $keepMarkosActive) {
            Write-Host ''
            Write-Host '  FIRST START - ACTIVATE TEARDOWN VR ONCE' -ForegroundColor Yellow
            Write-Host '  Connect your headset and set your OpenXR runtime before launching.' -ForegroundColor White
            Write-Host '  The menu appears on a virtual screen IN THE HEADSET.' -ForegroundColor Yellow
            Write-Host '  The desktop view may not be usable for this step.' -ForegroundColor Yellow
            Write-Host '  In the game: Play > Mod manager > Built-in.' -ForegroundColor Green
            Write-Host '  Scroll down to Teardown VR and select it.' -ForegroundColor Green
            Write-Host '  Click Disabled to enable it.' -ForegroundColor Green
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
        $global:LASTEXITCODE=0
    } finally {
        if ($work -and -not $keepWork) { try { Remove-PCVRInstallerTempSession -Path $work } catch {} }
    }
}

if ($env:PCVR_TEARDOWN_LIBRARY_ONLY -ne '1') {
    if(-not $Mod){
        Write-Host 'Teardown VR - choose your mod' -ForegroundColor Cyan
        Write-Host '[1] VR Games For All (Patreon; Steam 2.0.x)' -ForegroundColor Gray
        Write-Host '[2] Markos - current Steam game; experimental, SteamVR/OpenXR' -ForegroundColor White
        Write-Host 'Install/update keeps the active choice. Start in VR selects it.'
        do{$pick=Read-Host 'Choose 1 or 2 (Enter = VR Games For All, Q = cancel)';if($null -eq $pick){throw 'Input closed before a mod was selected.'};$pick=$pick.Trim().ToUpperInvariant()}while($pick -notin @('','1','2','Q'))
        if($pick -eq 'Q'){return}
        $Mod=if($pick -eq '2'){'markos'}else{'legacy'}
    }
    if($Mod -eq 'markos'){& (Join-Path $PSScriptRoot 'TeardownMarkos-core.ps1');return}
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

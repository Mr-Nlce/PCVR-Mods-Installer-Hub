# Titanfall 2 VR: hand off to CircuitLord's maintained companion installer.
# The publisher owns the TF2VR profile and its versioned file manifest.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle = 'Titanfall 2 VR Installer'

$script:TfRepo = 'CircuitLord/CircuitLordVRModInstaller'
$script:TfPage = 'https://github.com/CircuitLord/CircuitLordVRModInstaller/releases'
$script:TfLatest = 'https://github.com/CircuitLord/CircuitLordVRModInstaller/releases/latest/download/CircuitLordVRModInstaller.exe'
$script:TfCompanion = 'CircuitLordVRModInstaller.exe'
$script:TfRequired = @(
    'Titanfall2.exe',
    'Titanfall2VRLauncher.exe',
    'TF2VR\Northstar.dll',
    'TF2VR\plugins\Titanfall2VR.dll',
    'TF2VR\tools\xr_probe.exe',
    'TF2VR\tools\crash_monitor.exe',
    'TF2VR\tools\launch.json',
    '.circuitlord-vr-mods\Titanfall2VR.json'
)
$script:TfContract = New-PCVRInstallerContract -Id 'titanfall-2-vr' -GameName 'Titanfall 2 VR' `
    -Acquisition GitHub -ReleasePageUrl $script:TfPage -AntivirusNotice `
    -RequiredInstalledFileGroups $script:TfRequired

function Test-TitanfallGameRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'Titanfall2.exe') -PathType Leaf))
}

function Get-TitanfallIsolatedFixture {
    if ($env:PCVR_HUB_TEST_MODE -ne '1') { return $null }
    $root = ('' + $env:PCVR_TF2_TEST_GAME_ROOT).Trim()
    $asset = ('' + $env:PCVR_TF2_TEST_COMPANION_PATH).Trim()
    if (-not $root -or -not $asset) { return $null }
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    $fullRoot = [IO.Path]::GetFullPath($root)
    $fullAsset = [IO.Path]::GetFullPath($asset)
    if (-not $fullRoot.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or
        -not $fullAsset.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath (Join-Path $fullRoot 'titanfall-fixture.txt') -PathType Leaf)) {
        throw 'The Titanfall test fixture must stay under the temporary directory.'
    }
    return [pscustomobject]@{ Root=$fullRoot; Asset=$fullAsset }
}

function Get-TitanfallGameRoot {
    $fixture = Get-TitanfallIsolatedFixture
    if ($fixture) {
        if (-not (Test-TitanfallGameRoot $fixture.Root)) { throw 'The Titanfall test game is incomplete.' }
        return $fixture.Root
    }
    $game = $null
    try {
        $game = Get-PCVRRememberedGameFolder -GameId 'titanfall-2-vr' `
            -StateNames @('installed_path','user_located') -ProbeFiles @('Titanfall2.exe')
    } catch {}
    if (-not (Test-TitanfallGameRoot $game)) {
        $game = Find-SteamGameFolder -AppId '1237970' -SteamFolderNames @('Titanfall2') `
            -ProbeExe 'Titanfall2.exe' -HubGameId 'titanfall-2-vr'
    }
    if (-not (Test-TitanfallGameRoot $game)) {
        foreach ($candidate in @('C:\Program Files\EA Games\Titanfall2',
                'C:\Program Files (x86)\Origin Games\Titanfall2')) {
            if (Test-TitanfallGameRoot $candidate) { $game = $candidate; break }
        }
    }
    if (-not (Test-TitanfallGameRoot $game)) {
        $game = Get-GameFolderInteractive -GameName 'Titanfall 2' -ProbeFile 'Titanfall2.exe' `
            -ManualUrl 'https://store.steampowered.com/app/1237970/'
    }
    if (-not (Test-TitanfallGameRoot $game)) { return $null }
    return (Get-Item -LiteralPath $game).FullName
}

function Get-TitanfallPublisherInstall([string]$GameRoot) {
    if (-not (Test-TitanfallGameRoot $GameRoot)) { return $null }
    foreach ($relative in $script:TfRequired) {
        if (-not (Test-Path -LiteralPath (Join-Path $GameRoot $relative) -PathType Leaf)) { return $null }
    }
    try {
        $receipt = Get-Content -LiteralPath (Join-Path $GameRoot '.circuitlord-vr-mods\Titanfall2VR.json') `
            -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $version = ('' + $receipt.version).Trim()
        if ($receipt.id -cne 'Titanfall2VR' -or -not (Test-IsTrackableInstalledVersion -Version $version)) {
            return $null
        }
        if (-not $receipt.files -or @($receipt.files).Count -eq 0) { return $null }
        return [pscustomobject]@{ Version = $version; Root = $GameRoot }
    } catch { return $null }
}

function Test-TitanfallCompanion([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $file = [IO.File]::OpenRead($Path)
        try { return ($file.Length -gt 1024 -and $file.ReadByte() -eq 77 -and $file.ReadByte() -eq 90) }
        finally { $file.Dispose() }
    } catch { return $false }
}

function Install-TitanfallCompanion([string]$GameRoot,[string]$DownloadedPath) {
    if (-not (Test-TitanfallGameRoot $GameRoot)) { throw 'Titanfall2.exe was not found in the selected folder.' }
    if (-not (Test-TitanfallCompanion $DownloadedPath)) { throw 'The download is not a usable Windows installer EXE.' }
    $target = Join-Path $GameRoot $script:TfCompanion
    $backup = Join-Path $GameRoot '.pcvrhub_circuitlord_companion_previous.exe'
    $hadTarget = Test-Path -LiteralPath $target -PathType Leaf
    if ($hadTarget) { Copy-Item -LiteralPath $target -Destination $backup -Force -ErrorAction Stop }
    try {
        Copy-Item -LiteralPath $DownloadedPath -Destination $target -Force -ErrorAction Stop
        if (-not (Test-TitanfallCompanion $target)) { throw 'The companion EXE was not readable after copying.' }
    } catch {
        if ($hadTarget -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
            Copy-Item -LiteralPath $backup -Destination $target -Force -ErrorAction SilentlyContinue
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        }
        throw
    }
    return $target
}

function Remove-TitanfallHubAlpha([string]$GameRoot) {
    $owned = Join-Path $GameRoot '.pcvrhub_titanfall2vr_ownership.csv'
    if (-not (Test-Path -LiteralPath $owned -PathType Leaf)) { return }
    try {
        $result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'titanfall2vr'
        Write-Host "  [OK] Old Hub alpha removed: $($result.Removed) owned files." -ForegroundColor Green
        if ($result.Preserved -gt 0) {
            Write-Host "  [!!] $($result.Preserved) changed legacy files were preserved for review." -ForegroundColor Yellow
        }
    } catch {
        Write-Host '  [!!] The new TF2VR profile is installed, but the old Hub alpha needs manual review.' -ForegroundColor Yellow
        Write-Host "       $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function global:Invoke-Titanfall2VRInstaller {
    $temp = $null
    try {
        $fixture = Get-TitanfallIsolatedFixture
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Titanfall 2 VR - Installer' -ForegroundColor Cyan
        Write-Host '  CircuitLord VR Mod Installer | campaign motion controls' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  The publisher app installs Northstar into a separate TF2VR' -ForegroundColor White
        Write-Host '  profile, builds required assets from your own game and keeps' -ForegroundColor White
        Write-Host '  the VR mod updated. Normal Titanfall 2 stays unmodded.' -ForegroundColor White
        Write-Host '  The app checks separate VR saves in LocalAppData\Respawn\Titanfall2_VR.' -ForegroundColor White
        Write-Host '  EA App sign-in and an OpenXR runtime are required to play.' -ForegroundColor Yellow
        Write-Host '  An old Hub-installed alpha is removed only after the new' -ForegroundColor Gray
        Write-Host '  publisher installation is verified. Its settings stay in place.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to find Titanfall 2...')

        Write-Host ''; Write-Host '--- [1/3] Finding Titanfall 2 ---' -ForegroundColor Cyan
        $game = Get-TitanfallGameRoot
        if (-not $game) { throw 'No Titanfall 2 folder with Titanfall2.exe was selected.' }
        if (-not $fixture -and (Get-Process -Name Titanfall2,Titanfall2VRLauncher,NorthstarLauncher -ErrorAction SilentlyContinue)) {
            throw 'Close Titanfall 2 and Northstar before installing or updating.'
        }
        Write-Host "  [OK] $game" -ForegroundColor Green

        Write-Host ''; Write-Host '--- [2/3] Getting the maintained publisher app ---' -ForegroundColor Cyan
        Write-Host "  Source: $script:TfPage" -ForegroundColor Gray
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the current publisher app...')
        $temp = Join-Path ([IO.Path]::GetTempPath()) ('pcvr-circuitlord-' + [Guid]::NewGuid().ToString('N') + '.exe')
        if ($fixture) {
            Copy-Item -LiteralPath $fixture.Asset -Destination $temp -Force -ErrorAction Stop
            $got = $true
        } else {
            $got = Invoke-SafeDownload -Urls @($script:TfLatest) -Destination $temp `
                -Label 'CircuitLord VR Mod Installer' -ManualUrl $script:TfPage -AllowSkip:$false
        }
        if (-not $got -or -not (Test-TitanfallCompanion $temp)) {
            throw 'No usable publisher app was downloaded. Use download recovery or select the EXE manually.'
        }
        $app = Install-TitanfallCompanion -GameRoot $game -DownloadedPath $temp
        Write-Host "  [OK] Publisher app ready: $app" -ForegroundColor Green

        Write-Host ''; Write-Host '--- [3/3] Installing and verifying the VR profile ---' -ForegroundColor Cyan
        Write-Host '  In the app, select Titanfall 2. Choose the detected game folder,' -ForegroundColor White
        Write-Host '  sign into EA App if prompted, then press Install or Update.' -ForegroundColor White
        Write-Host '  The first installation may build game-derived assets for a while.' -ForegroundColor Gray
        Write-Host '  This Hub window will check the publisher record and VR files' -ForegroundColor White
        Write-Host '  before marking the game VR Ready.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher app...')
        if (-not $fixture) { Start-Process -FilePath $app -WorkingDirectory $game -ErrorAction Stop | Out-Null }
        $installed = $null
        while (-not $installed) {
            [void](Wait-PCVRExplicitEnter -Message 'After Titanfall 2 VR shows Installed, press Enter to verify...')
            $installed = Get-TitanfallPublisherInstall $game
            if ($installed) { break }
            Write-Host '  TF2VR is not complete yet. No Hub success was recorded.' -ForegroundColor Yellow
            Write-Host '  [O] Open the publisher app again   [R] Recheck   [Q] Quit without success' -ForegroundColor Cyan
            $choice = ('' + (Read-Host '  Choice')).Trim().ToUpperInvariant()
            if ($choice -eq 'Q') { return }
            if ($choice -eq 'O' -and -not $fixture) { Start-Process -FilePath $app -WorkingDirectory $game -ErrorAction Stop | Out-Null }
        }
        Remove-TitanfallHubAlpha $game
        $pathReceipt = if ($fixture) { Join-Path $game '.pcvrhub_test_installed_path' } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:TfContract -GameDir $game `
            -Version $installed.Version -InstalledPathReceiptPaths @($pathReceipt))
        Write-Host '  Start in VR opens the publisher app; use Launch in VR there.' -ForegroundColor White
        Write-Host '  Use its Uninstall action to remove the TF2VR profile.' -ForegroundColor White
        Write-Host ''; Write-Host '  Protocol 3: protect the pilot, then request a Titan.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red
        throw
    } finally {
        if ($temp -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($env:PCVR_TITANFALL2VR_LIBRARY_ONLY -ne '1') { Invoke-Titanfall2VRInstaller }

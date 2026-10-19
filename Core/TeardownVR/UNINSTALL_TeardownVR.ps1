param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference = 'Stop'
$env:PCVR_TEARDOWN_LIBRARY_ONLY = '1'
. (Join-Path $PSScriptRoot 'TeardownVR-core.ps1')
Remove-Item Env:PCVR_TEARDOWN_LIBRARY_ONLY -ErrorAction SilentlyContinue

function Finish-TeardownRemoval([int]$Code) {
    if (-not $NoPause) { Write-Host ''; [void](Read-Host 'Press Enter to close') }
    exit $Code
}

try {
    $root = Get-TeardownRoot
    if (-not (Test-TeardownInstalled $root)) {
        Write-Host 'No complete Teardown VR installation was found.' -ForegroundColor Yellow
        Finish-TeardownRemoval 0
    }
    if (Get-Process -Name teardown -ErrorAction SilentlyContinue) { throw 'Close Teardown before removing its VR mod.' }
    if (-not $HubConfirmed) {
        $answer = ([string](Read-Host "Remove the Teardown VR mod from '$root'? Type REMOVE")).Trim()
        if ($answer -cne 'REMOVE') { Finish-TeardownRemoval 0 }
    }
    $versionFile = Join-Path $root '.pcvrhub_version'
    $version = if (Test-Path -LiteralPath $versionFile -PathType Leaf) {
        ([string](Get-Content -LiteralPath $versionFile -TotalCount 1)).Trim()
    } else { '' }
    if (-not (Test-IsTrackableInstalledVersion $version)) {
        throw 'The Hub has no recorded release version for this installation. Run the installer first to adopt or repair it.'
    }
    $setup = Get-TeardownSetupCache $version
    $work = $null
    if (-not (Test-DownloadedPayload -Path $setup -IntendedPath 'Teardown-VR-Installer.exe')) {
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $setup = Join-Path $work 'Teardown-VR-Installer.exe'
        Write-Host '  The matching publisher Setup is not cached; it will be downloaded.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to get the publisher uninstaller...')
        $url = "https://github.com/$script:TeardownRepo/releases/download/v$version/Teardown-VR-Installer.exe"
        $ok = Invoke-SafeDownload -Urls @($url) -Destination $setup -Label "Teardown VR $version" `
            -ManualUrl $script:TeardownPage -ExpectedReleaseTag "v$version" -DisableGitHubAssetReresolution -AllowSkip:$false
        if (-not $ok) { throw 'The matching publisher Setup is unavailable.' }
    }
    Write-Host '  Publisher Setup removes its DLL and Lua files, and restores a saved prior dsound.dll.' -ForegroundColor White
    Write-Host '  Teardown, saves and TeardownVR.ini remain.' -ForegroundColor White
    Write-Host '  Windows may request administrator approval.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove Teardown VR...')
    Invoke-TeardownPublisher -Setup $setup -GameDir $root -Action uninstall
    if (Test-TeardownInstalled $root) { throw 'Publisher Setup left a complete VR installation; Hub state was kept.' }
    if (Test-Path -LiteralPath (Join-Path $root 'mods\teardownvr\main.lua') -PathType Leaf) {
        throw 'The publisher left the Lua mod behind; Hub state was kept for review.'
    }
    $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_RECEIPT) {
        [IO.Path]::GetFullPath($env:PCVR_TEARDOWN_TEST_RECEIPT)
    } else { Join-Path $PSScriptRoot '.installed_path' }
    foreach ($marker in @($versionFile,$receipt)) {
        if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop }
    }
    Write-Host '  [OK] Teardown VR was removed; game and settings remain.' -ForegroundColor Green
    if ($work) { Remove-PCVRInstallerTempSession -Path $work }
    Finish-TeardownRemoval 0
} catch {
    Write-Host "Removal did not complete: $($_.Exception.Message)" -ForegroundColor Red
    Finish-TeardownRemoval 1
}

param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference = 'Stop'
$env:PCVR_TEARDOWN_LIBRARY_ONLY = '1'
. (Join-Path $PSScriptRoot 'TeardownVR-core.ps1')
Remove-Item Env:PCVR_TEARDOWN_LIBRARY_ONLY -ErrorAction SilentlyContinue

function Finish-TeardownRemoval([int]$Code) {
    if (-not $NoPause) { Write-Host ''; [void](Read-Host 'Press Enter to close') }
    exit $Code
}

$work = $null
$keepWork = $false
try {
    $root = Get-TeardownRoot
    if (-not (Test-PCVRTeardownProfile -GameRoot $root -Slot A)) {
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
    if (-not (Test-DownloadedPayload -Path $setup -IntendedPath 'Teardown-VR-Installer.exe')) {
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $setup = Join-Path $work 'Installer Teardown VR.exe'
        Write-Host '  No cached Setup was found. The current publisher Setup can remove the VR Games For All profile.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to get the publisher uninstaller...')
        Get-TeardownPublisherSetup -Destination $setup
    }
    Write-Host '  Publisher Setup removes its DLL and Lua files, and restores a saved prior dsound.dll.' -ForegroundColor White
    Write-Host '  Teardown, saves and TeardownVR.ini remain.' -ForegroundColor White
    Write-Host '  Windows may request administrator approval.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove Teardown VR...')
    $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_TEST_RECEIPT) {
        [IO.Path]::GetFullPath($env:PCVR_TEARDOWN_TEST_RECEIPT)
    } else { Join-Path $PSScriptRoot '.installed_path' }
    if(-not $work){$work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())}
    $before=Save-TeardownBeforeState -Root $root -Work $work
    $markers=@(foreach($file in @($versionFile,$receipt,(Join-Path $PSScriptRoot '.installed_version'))){@{Path=$file;Bytes=$(if([IO.File]::Exists($file)){[IO.File]::ReadAllBytes($file)}else{$null})}})
    try{
        $parked=Join-Path $root 'dsound.dll.pcvrhub_teardown_legacy'
        $sound=Join-Path $root 'dsound.dll'
        if([IO.File]::Exists($parked)){
            if([IO.File]::Exists($sound)){throw 'An existing dsound.dll prevents removing the parked legacy proxy safely.'}
            Move-Item -LiteralPath $parked -Destination $sound
        }
        Invoke-TeardownPublisher -Setup $setup -GameDir $root -Action uninstall
        if (Test-TeardownInstalled $root) { throw 'Publisher Setup left a complete VR installation; Hub state was kept.' }
        if (Test-Path -LiteralPath (Join-Path $root 'mods\teardownvr\main.lua') -PathType Leaf) {
            throw 'The publisher left the Lua mod behind; Hub state was kept for review.'
        }
        foreach ($marker in $markers) {if([IO.File]::Exists($marker.Path)){Remove-Item -LiteralPath $marker.Path -Force}}
    }catch{
        $problem=$_.Exception.Message
        try{
            Restore-TeardownBeforeState -Root $root -State $before
            foreach($marker in $markers){if($null -ne $marker.Bytes){[IO.File]::WriteAllBytes($marker.Path,$marker.Bytes)}elseif([IO.File]::Exists($marker.Path)){Remove-Item -LiteralPath $marker.Path -Force}}
        }catch{$keepWork=$true;throw ($problem+' Rollback needs attention: '+$_.Exception.Message+' Recovery copy: '+$work)}
        throw $problem
    }
    . (Join-Path $PSScriptRoot '..\Modules\HubState.ps1')
    Reset-PersistentGameStateValue -Game @{Id='teardown-vr';Title='Teardown VR'} -Name 'installed_version'
    Write-Host '  [OK] Teardown VR was removed; game and settings remain.' -ForegroundColor Green
    Finish-TeardownRemoval 0
} catch {
    Write-Host "Removal did not complete: $($_.Exception.Message)" -ForegroundColor Red
    Finish-TeardownRemoval 1
} finally {
    if ($work -and -not $keepWork) { Remove-PCVRInstallerTempSession -Path $work }
}

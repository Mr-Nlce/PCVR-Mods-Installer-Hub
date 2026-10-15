param([ValidateSet('','evil','betotron')][string]$Mod='')
$ErrorActionPreference='Stop'
Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'MaxPayne2VR-Dual.ps1')
. (Join-Path $PSScriptRoot 'MaxPayne2VR-Stage.ps1')
$Host.UI.RawUI.WindowTitle='Max Payne 2 VR Installer'

function Write-MP2Header {
    Clear-Host
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  Max Payne 2 VR Installer' -ForegroundColor Cyan
    Write-Host '  Two independent VR mods for one game' -ForegroundColor Gray
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host ''
}
function Find-MP2Game {
    if ($env:PCVR_MP2_SELECTED_GAME -and (Test-Path -LiteralPath (Join-Path $env:PCVR_MP2_SELECTED_GAME 'maxpayne2.exe') -PathType Leaf)) {
        return [IO.Path]::GetFullPath($env:PCVR_MP2_SELECTED_GAME)
    }
    $root=Find-SteamGameFolder -AppId '12150' -SteamFolderNames @('Max Payne 2 The Fall of Max Payne','Max Payne 2') -ProbeExe 'MaxPayne2.exe' -GogNames @('Max Payne 2','Max Payne 2 The Fall of Max Payne') -HubGameId 'max-payne-2-vr'
    if (-not $root) { $root=Get-GameFolderInteractive -GameName 'Max Payne 2' -ProbeFile 'MaxPayne2.exe' -ManualUrl 'https://store.steampowered.com/app/12150/' }
    if ($root -in @('quit','skip',$null)) { throw 'No Max Payne 2 game folder was selected.' }
    return $root
}

Write-MP2Header
Write-Host '  [1] MP2VR by evilSheep - recommended; SteamVR motion controls' -ForegroundColor White
Write-Host '  [2] MaxPayne2VR by betotron - Virtual Desktop / OpenXR' -ForegroundColor White
Write-Host ''
Write-Host '  Both mods may stay installed. Setup only prepares the selected mod.' -ForegroundColor Gray
Write-Host '  The Hub Play buttons select the active loader when you play.' -ForegroundColor Gray
Write-Host '  Close Max Payne 2 before installing or selecting another Play mode.' -ForegroundColor Gray
Write-Host '  For MP2VR, start your own game flat once and close it first.' -ForegroundColor Gray
Show-AntivirusNotice -Compact
if (-not $Mod) {
    do { $choice=(Read-Host 'Choose 1, 2 or Q to quit').Trim().ToLowerInvariant() } while ($choice -notin @('1','2','q'))
    if ($choice -eq 'q') { exit 0 }
    $Mod=if($choice -eq '1'){'evil'}else{'betotron'}
} else { [void](Wait-PCVRExplicitEnter -Message ("Press Enter to install or update " + $Mod + '...')) }

$game=Find-MP2Game
Assert-MP2GameClosed
$slot=if($Mod -eq 'evil'){'A'}else{'B'}
$identity=if($slot -eq 'A'){'mp2evilruntime'}else{'mp2betotronruntime'}
$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_maxpayne2_'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($work)
$snapshot=@()
$committed=$false
try {
    Write-Host '';Write-Host '--- [1/4] Resolving the publisher release ---' -ForegroundColor Cyan
    $fixtureArchive=$null
    if($Mod -eq 'evil') {
        $repo='evilSheep/max-payne-2-vr'
        $fallbackName='max-payne-2-vr-v0.1.0-rc.67.zip'
        $fallbackUrl='https://github.com/evilSheep/max-payne-2-vr/releases/download/v0.1.0-rc.67/max-payne-2-vr-v0.1.0-rc.67.zip'
        if($env:PCVR_MP2_SELECTED_GAME -and $env:PCVR_MP2_TEST_ARCHIVE -and $env:PCVR_MP2_TEST_TAG -and
           (Test-Path -LiteralPath $env:PCVR_MP2_TEST_ARCHIVE -PathType Leaf)) {
            $fixtureArchive=[IO.Path]::GetFullPath($env:PCVR_MP2_TEST_ARCHIVE)
            $release=[pscustomobject]@{Tag=$env:PCVR_MP2_TEST_TAG;Url='';PageUrl='https://github.com/evilSheep/max-payne-2-vr/releases'}
        } else {
            $release=Resolve-GitHubReleaseAsset -Repo $repo -AssetPatterns @('(?i)^max-payne-2-vr-v.+\.zip$') -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -FallbackUrl $fallbackUrl -FallbackTag 'v0.1.0-rc.67' -FallbackAssetName $fallbackName
        }
        $version=([string]$release.Tag).TrimStart('v')
    } else {
        $repo='betotron/MaxPayne2VR-release'
        $fallbackName='MaxPayne2VR-v1.2.zip'
        $fallbackUrl='https://github.com/betotron/MaxPayne2VR-release/releases/download/v1.2/MaxPayne2VR-v1.2.zip'
        if($env:PCVR_MP2_SELECTED_GAME -and $env:PCVR_MP2_TEST_B_ARCHIVE -and $env:PCVR_MP2_TEST_B_TAG -and
           (Test-Path -LiteralPath $env:PCVR_MP2_TEST_B_ARCHIVE -PathType Leaf)) {
            $fixtureArchive=[IO.Path]::GetFullPath($env:PCVR_MP2_TEST_B_ARCHIVE)
            $release=[pscustomobject]@{Tag=$env:PCVR_MP2_TEST_B_TAG;Url='';PageUrl='https://github.com/betotron/MaxPayne2VR-release/releases'}
        } else {
            $release=Resolve-GitHubReleaseAsset -Repo $repo -AssetPatterns @('(?i)^MaxPayne2VR-v.+\.zip$') -FallbackUrl $fallbackUrl -FallbackTag 'v1.2' -FallbackAssetName $fallbackName
        }
        $version=[string]$release.Tag
    }
    if(-not(Test-IsTrackableInstalledVersion -Version $version)) { throw 'The publisher release has no trackable version.' }
    Write-Host "  Release: $version" -ForegroundColor Green
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the publisher ZIP...')
    $zip=Join-Path $work 'mod.zip'
    if($fixtureArchive) { Copy-Item -LiteralPath $fixtureArchive -Destination $zip -ErrorAction Stop }
    elseif(-not(Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $zip -Label "$repo $version" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false)) {
        throw 'The publisher archive was not obtained.'
    }

    Write-Host '';Write-Host '--- [2/4] Extracting and preparing the mod ---' -ForegroundColor Cyan
    $out=Join-Path $work 'extract'
    if((Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $out -Label $repo -AllowSkip $false) -notin @('ok','manual')) {
        throw 'The publisher archive could not be extracted.'
    }
    $prepared=Join-Path $work 'prepared'
    if($Mod -eq 'evil') {
        $package=Get-ChildItem -LiteralPath $out -Directory -Recurse | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName 'setup-files\tools\release_install.py') -PathType Leaf
        } | Select-Object -First 1 -ExpandProperty FullName
        if(-not $package -and (Test-Path -LiteralPath (Join-Path $out 'setup-files\tools\release_install.py') -PathType Leaf)) { $package=$out }
        if(-not $package) { throw 'The publisher setup tools are missing from the ZIP.' }
        [void](New-MP2EvilStage -Game $game -Package $package -Stage $prepared)
        $content=Join-Path $work 'content'
        [void](New-MP2EvilContentStage -Prepared $prepared -Content $content)
    } else {
        [void](New-MP2BetotronStage -Extract $out -Stage $prepared)
    }
    $runtime=Join-Path $work 'runtime'
    [void][IO.Directory]::CreateDirectory($runtime)
    foreach($name in $script:MP2SlotFiles[$slot]) {
        Copy-Item -LiteralPath (Join-Path $prepared $name) -Destination (Join-Path $runtime $name) -ErrorAction Stop
    }

    Write-Host '';Write-Host '--- [3/4] Storing this mod independently ---' -ForegroundColor Cyan
    Assert-MP2GameClosed
    $profile=Join-Path (Get-MP2ProfileRoot $game) $slot
    $stamp=Join-Path $game $(if($slot -eq 'A'){'.pcvrhub_maxpayne2_evil_version'}else{'.pcvrhub_maxpayne2_betotron_version'})
    $paths=@($profile,$stamp,(Join-Path $game $(if($slot -eq 'A'){'.pcvrhub_version_b'}else{'.pcvrhub_version'})))
    if($Mod -eq 'evil') {
        $contentManifest=Join-Path $game '.pcvrhub_mp2evilcontent_ownership.csv'
        $paths+=@($contentManifest,(Join-Path $game '.pcvrhub_mp2evilcontent_backup'))
        $paths+=@(Get-ChildItem -LiteralPath $content -File | ForEach-Object { Join-Path $game $_.Name })
        if(Test-Path -LiteralPath $contentManifest -PathType Leaf) {
            $paths+=@(Import-Csv -LiteralPath $contentManifest | ForEach-Object { Join-Path $game ([string]$_.RelativePath) })
        } else {
            $oldReceipt=Get-MP2Receipt $game
            if($oldReceipt -and $oldReceipt.status -eq 'installed') {
                $paths+=@($oldReceipt.files.PSObject.Properties | ForEach-Object { Join-Path $game ([string]$_.Name) })
            }
        }
        $paths+=@(Get-ChildItem -LiteralPath $prepared -File | Where-Object { Test-MP2PersonalSetting $_.Name } | ForEach-Object { Join-Path $game $_.Name })
    } else {
        $paths+=@(Join-Path $game 'MaxPayne2VR.ini')
    }
    $snapshot=Save-MP2InstallSnapshot -Game $game -Paths $paths -Destination (Join-Path $work 'before')
    [void][IO.Directory]::CreateDirectory($profile)
    [void](Install-OwnedModPayload -SourceRoot $runtime -GameRoot $profile -Identity $identity)
    if($Mod -eq 'evil') {
        Initialize-MP2EvilContentOwnership -Game $game
        [void](Install-OwnedModPayload -SourceRoot $content -GameRoot $game -Identity 'mp2evilcontent')
        foreach($file in @(Get-ChildItem -LiteralPath $prepared -File | Where-Object { Test-MP2PersonalSetting $_.Name })) {
            $setting=Join-Path $game $file.Name
            if(-not(Test-Path -LiteralPath $setting -PathType Leaf)) {
                Copy-Item -LiteralPath $file.FullName -Destination $setting -ErrorAction Stop
            }
        }
    } else {
        $config=Join-Path $game 'MaxPayne2VR.ini'
        if(-not(Test-Path -LiteralPath $config -PathType Leaf)) {
            Copy-Item -LiteralPath (Join-Path $prepared 'MaxPayne2VR.ini') -Destination $config -ErrorAction Stop
        }
    }
    Write-PCVRAtomicText -Path (Join-Path $profile 'version.txt') -Value $version
    Write-PCVRAtomicText -Path $stamp -Value $version
    if(-not(Test-MP2V2Slot -Game $game -Slot $slot -Parked)) { throw 'The stored profile failed its ownership and file checks.' }
    $watch=@($script:MP2SlotFiles[$slot] | ForEach-Object { Join-Path $profile $_ })
    if($Mod -eq 'evil') { $watch+=@(Join-Path $game 'maxpayne2vr_assets.bin') }
    if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -ArchivePath $zip -NoClear)) {
        throw 'Required VR files are missing after copying.'
    }

    Write-Host '';Write-Host '--- [4/4] Saving the verified route ---' -ForegroundColor Cyan
    $required=@('maxpayne2.exe',".pcvrhub_maxpayne2_profiles\$slot\version.txt", ".pcvrhub_maxpayne2_profiles\$slot\.pcvrhub_${identity}_ownership.csv")
    $required+=@($script:MP2SlotFiles[$slot] | ForEach-Object { ".pcvrhub_maxpayne2_profiles\$slot\$_" })
    if($Mod -eq 'evil') { $required+=@('.pcvrhub_mp2evilcontent_ownership.csv','maxpayne2vr_assets.bin','MP2VR_FirstPerson.mp2m') }
    $contract=New-PCVRInstallerContract -Id "max-payne-2-$Mod-vr" -GameName 'Max Payne 2 VR' -Acquisition GitHub -AntivirusNotice -Routes @($Mod) -RequiredInstalledFileGroups $required
    $pathReceipt=if($fixtureArchive){Join-Path $game '.pcvrhub_test_installed_path'}else{Join-Path $PSScriptRoot '.installed_path'}
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -VersionSlot $(if($slot -eq 'A'){'Secondary'}else{'Primary'}) -Route $Mod -InstalledPathReceiptPaths @($pathReceipt) -AdditionalVersionReceiptPaths @($stamp))
    $committed=$true
    Write-Host '';Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  Setup complete.' -ForegroundColor Green
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  Choose the matching Play button in the Hub to activate this mod.' -ForegroundColor White
    Write-Host '';Write-Host '  Time to dive back into the night, Max.' -ForegroundColor Magenta
    try { [void](Wait-PCVRExplicitEnter -Message 'Press Enter to exit') } catch { }
} catch {
    $failure=$_
    if($snapshot.Count -and -not $committed) {
        try { Restore-MP2InstallSnapshot -Game $game -Entries $snapshot }
        catch { Write-Warning ('Max Payne 2 rollback needs repair: '+$_.Exception.Message) }
    }
    throw $failure
} finally {
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if([IO.Path]::GetFullPath($work).StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -and
       (Test-Path -LiteralPath $work -PathType Container)) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='Killing Floor 2 VR Installer'
$script:KF2Id='killing-floor-2-vr'
$script:KF2Repo='Kvasir94/Killing-Floor-2-VR'
$script:KF2Page="https://github.com/$script:KF2Repo/releases"
$script:KF2Workshop='https://steamcommunity.com/sharedfiles/filedetails/?id=3817663661'
$script:KF2Required=@('Start KF2-VR.cmd','app\release.json','app\runtime\pythonw.exe',
    'app\tools\multiplayer\launcher_gui.py','app\Native\dinput8.dll','app\Packages\KF2VR.u',
    'app\Packages\KF2VRNet.u')
$script:KF2Contract=New-PCVRInstallerContract -Id $script:KF2Id -GameName 'Killing Floor 2 VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:KF2Page -Routes @('GitHub','Workshop') `
    -RequiredInstalledFileGroups @('Start KF2VR.cmd','.pcvrhub_kf2vr_route','.pcvrhub_kf2vr_ownership.csv',
        'current\Start KF2-VR.cmd','current\app\release.json','current\app\runtime\pythonw.exe',
        'current\app\tools\multiplayer\launcher_gui.py','current\app\Native\dinput8.dll',
        'current\app\Packages\KF2VR.u','current\app\Packages\KF2VRNet.u')

function Assert-KF2Fixture([string]$Path){
    $full=[IO.Path]::GetFullPath($Path)
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
        -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'kf2-fixture.txt') -PathType Leaf)){
        throw 'KF2 test paths must stay in an isolated temporary fixture.'
    }
    return $full
}
function Test-KF2Game([string]$Root){
    if(-not $Root){return $false}
    foreach($file in @('Binaries\Win64\KFGame.exe','KFGame\BrewedPC\Core.u','KFGame\BrewedPC\KFGame.u')){
        if(-not(Test-Path -LiteralPath (Join-Path $Root $file) -PathType Leaf)){return $false}
    }
    return $true
}
function Get-KF2Game {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KF2_TEST_GAME){
        $root=Assert-KF2Fixture $env:PCVR_KF2_TEST_GAME
        if(-not(Test-KF2Game $root)){throw 'The isolated KF2 game fixture is incomplete.'}
        return $root
    }
    $paths=[Collections.Generic.List[string]]::new()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:KF2Id -StateNames @('base_game_path','user_located') -ProbeFiles @('Binaries\Win64\KFGame.exe')
    if($saved){$paths.Add($saved)}
    try{$steam=Find-SteamGameFolder -AppId '232090' -SteamFolderNames @('killingfloor2','Killing Floor 2') `
        -ProbeExe 'Binaries\Win64\KFGame.exe' -HubGameId $script:KF2Id;if($steam){$paths.Add($steam)}}catch{}
    foreach($path in @('C:\Program Files (x86)\Steam\steamapps\common\killingfloor2',
        'C:\Program Files\Epic Games\KillingFloor2')){$paths.Add($path)}
    foreach($path in @($paths|Select-Object -Unique)){if(Test-KF2Game $path){return [IO.Path]::GetFullPath($path)}}
    $picked=Get-GameFolderInteractive -GameName 'Killing Floor 2' -ProbeFile 'Binaries\Win64\KFGame.exe' `
        -ManualUrl 'https://store.steampowered.com/app/232090/'
    if(Test-KF2Game $picked){return [IO.Path]::GetFullPath($picked)}
    throw 'Choose the original Killing Floor 2 folder with KFGame.exe and the BrewedPC game data.'
}
function Get-KF2Root {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KF2_TEST_ROOT){return (Assert-KF2Fixture $env:PCVR_KF2_TEST_ROOT)}
    return (Join-Path $env:LOCALAPPDATA 'KF2VR')
}
function Get-KF2Receipt {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KF2_TEST_RECEIPT){
        return (Assert-KF2Fixture $env:PCVR_KF2_TEST_RECEIPT)
    }
    return (Join-Path $PSScriptRoot '.installed_path')
}
function Get-KF2Release {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KF2_TEST_ARCHIVE){
        $archive=Assert-KF2Fixture $env:PCVR_KF2_TEST_ARCHIVE
        return [pscustomobject]@{Tag='';Url=$archive;Local=$true}
    }
    $release=Resolve-GitHubReleaseAsset -Repo $script:KF2Repo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^KF2VR-Multiplayer-v[0-9].*(?<!-Epic-Desktop-Pack)\.zip$') -SkipReleasesWithoutMatchingAsset
    if($release.Resolved -and [string]$release.AssetName -match '(?i)^KF2VR-Multiplayer-v[0-9].*\.zip$' -and
        [string]$release.AssetName -notmatch '(?i)-Epic-Desktop-Pack\.zip$'){
        return [pscustomobject]@{Tag=[string]$release.Tag;Url=[string]$release.Url;Local=$false}
    }
    Write-Host '  The current GitHub release could not be checked. The official ZIP can still be selected.' -ForegroundColor Yellow
    return [pscustomobject]@{Tag='';Url='';Local=$false}
}
function Get-KF2Payload([string]$Archive,[string]$Stage,[string]$ReleaseTag){
    Write-Host '  [..] Extracting the complete KF2VR package; this can take several minutes.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $Stage -Label 'KF2VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The KF2VR ZIP could not be opened.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $Stage -RelModFile 'Start KF2-VR.cmd'
    if(-not $payload){throw 'Choose the full KF2VR Multiplayer ZIP. The Epic Desktop Pack has no VR launcher.'}
    foreach($file in $script:KF2Required){
        if(-not(Test-Path -LiteralPath (Join-Path $payload $file) -PathType Leaf)){
            throw "The full KF2VR package is missing $file. The Epic Desktop Pack is not the VR release."
        }
    }
    $meta=Get-Content -LiteralPath (Join-Path $payload 'app\release.json') -Raw | ConvertFrom-Json
    if(-not $meta.public_release -or [string]$meta.schema -ne 'kf2vr/friend-release/1' -or
        [string]$meta.store_support.steam -ne 'solo-host-join' -or -not $meta.build_id){
        throw 'This package does not identify itself as the current playable KF2VR release.'
    }
    $version=Get-KF2PackageVersion -Metadata $meta -ReleaseTag $ReleaseTag
    if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The publisher package has no trackable release version.'}
    if($ReleaseTag -and -not $version.StartsWith(([string]$meta.version),[StringComparison]::OrdinalIgnoreCase)){
        throw 'The downloaded release tag and package version disagree.'
    }
    return [pscustomobject]@{Root=$payload;Version=$version;Build=[string]$meta.build_id;GameHashes=@($meta.supported_game_sha256)}
}
function Get-KF2PackageVersion {
    param($Metadata,[string]$ReleaseTag)
    if($ReleaseTag){return $ReleaseTag.TrimStart('v')}
    if(-not $Metadata.created_utc){throw 'The publisher package has no UTC build timestamp.'}
    $utc=([DateTimeOffset]$Metadata.created_utc).ToUniversalTime()
    return ([string]$Metadata.version+'.'+$utc.ToString('yyyyMMdd',[Globalization.CultureInfo]::InvariantCulture))
}
function Write-KF2Manifest([string]$Root){
    $rows=@(Get-ChildItem -LiteralPath (Join-Path $Root 'current') -Recurse -File | ForEach-Object {
        [pscustomobject]@{RelativePath=('current\'+$_.FullName.Substring((Join-Path $Root 'current').Length+1));
            HadOriginal=$false;InstalledSha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
    $rows | Export-Csv -LiteralPath (Join-Path $Root '.pcvrhub_kf2vr_ownership.csv') -NoTypeInformation -Encoding UTF8
}
function Install-KF2GitHub([string]$Game){
    $root=Get-KF2Root
    if(-not(Test-InstallerTargetWritable -TargetPath $root)){throw "The KF2VR folder is not writable: $root"}
    if((Get-PCVRInstallerVolumeFreeBytes $root) -lt 2500000000L){throw 'The KF2VR drive needs at least 2.5 GB free for extraction and rollback.'}
    if(Get-Process -Name 'KFGame','pythonw' -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -eq 'KFGame'}){
        throw 'Close Killing Floor 2 before installing or updating KF2VR.'
    }
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the full KF2VR release...')
    $release=Get-KF2Release
    $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
    $previous='';$switched=$false
    $rootReceipts=@{}
    try {
        $archive=Join-Path $work 'KF2VR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -ErrorAction Stop}
        else {
            $urls=if($release.Url){@($release.Url)}else{@()}
            $download=Invoke-SafeDownload -Urls $urls -Destination $archive -Label 'Killing Floor 2 VR full release' `
                -ExpectedReleaseTag $release.Tag -ManualUrl $script:KF2Page -AllowSkip $false
            if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'The KF2VR download did not complete.'}
        }
        $payload=Get-KF2Payload -Archive $archive -Stage (Join-Path $work 'expanded') -ReleaseTag $release.Tag
        $exe=Join-Path $Game 'Binaries\Win64\KFGame.exe'
        $gameHash=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
        if(@($payload.GameHashes).Count -gt 0 -and $gameHash -notin @($payload.GameHashes)){
            throw 'This KFGame.exe build is outside the versions supported by the selected publisher release. No game files were changed.'
        }
        [void][IO.Directory]::CreateDirectory($root)
        foreach($name in @('Start KF2VR.cmd','.pcvrhub_kf2vr_route','.pcvrhub_kf2vr_ownership.csv','.pcvrhub_version')){
            $path=Join-Path $root $name
            $rootReceipts[$name]=if(Test-Path -LiteralPath $path -PathType Leaf){[IO.File]::ReadAllBytes($path)}else{$null}
        }
        $current=Join-Path $root 'current'
        if(Test-Path -LiteralPath $current){
            if(-not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_kf2vr_ownership.csv') -PathType Leaf)){
                throw 'An unowned KF2VR current folder exists. Choose a clean location or remove it manually; it was not overwritten.'
            }
            $previous=Join-Path $root ('previous-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
            if(Test-Path -LiteralPath $previous){throw 'The KF2VR rollback folder already exists; retry after a second.'}
            Move-Item -LiteralPath $current -Destination $previous -ErrorAction Stop
        }
        Write-Host '  [..] Placing the verified publisher launcher; this may take a minute.' -ForegroundColor Cyan
        Move-Item -LiteralPath $payload.Root -Destination $current -ErrorAction Stop
        $switched=$true
        if($previous -and (Test-Path -LiteralPath (Join-Path $previous 'app\settings.json') -PathType Leaf) -and
            -not(Test-Path -LiteralPath (Join-Path $current 'app\settings.json') -PathType Leaf)){
            Copy-Item -LiteralPath (Join-Path $previous 'app\settings.json') -Destination (Join-Path $current 'app\settings.json')
        }
        foreach($file in $script:KF2Required){if(-not(Test-Path -LiteralPath (Join-Path $current $file) -PathType Leaf)){throw "Installed KF2VR file is missing: $file"}}
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Start KF2VR.cmd') -Destination (Join-Path $root 'Start KF2VR.cmd') -Force
        Write-PCVRAtomicText -Path (Join-Path $root '.pcvrhub_kf2vr_route') -Value 'github'
        Write-KF2Manifest $root
        if(-not(Save-HubRememberedGameFolder -GameId $script:KF2Id -Title 'Killing Floor 2 VR' -GameDir $Game `
            -ProbeFiles @('Binaries\Win64\KFGame.exe','KFGame\BrewedPC\Core.u') -StateName 'base_game_path')){
            throw 'The original game location could not be saved.'
        }
        [void](Complete-PCVRInstallTransaction -Contract $script:KF2Contract -GameDir $root -Version $payload.Version `
            -InstalledPathReceiptPaths @((Get-KF2Receipt)) -Route GitHub)
        Write-Host "  [OK] KF2VR $($payload.Version) installed; build $($payload.Build)." -ForegroundColor Green
        if($previous){Write-Host "  Previous release kept for rollback: $previous" -ForegroundColor Yellow}
        Write-Host '  Start in VR opens KF2VR. Choose Solo, Host or Join there; Epic supports Solo only.' -ForegroundColor Yellow
    } catch {
        if($switched){
            $failed=Join-Path $root ('failed-'+[Guid]::NewGuid().ToString('N'))
            if(Test-Path -LiteralPath (Join-Path $root 'current')){Move-Item -LiteralPath (Join-Path $root 'current') -Destination $failed -ErrorAction Stop}
            if($previous -and (Test-Path -LiteralPath $previous -PathType Container)){
                Move-Item -LiteralPath $previous -Destination (Join-Path $root 'current') -ErrorAction Stop
            }
        } elseif($previous -and (Test-Path -LiteralPath $previous -PathType Container) -and
            -not(Test-Path -LiteralPath (Join-Path $root 'current'))){
            Move-Item -LiteralPath $previous -Destination (Join-Path $root 'current') -ErrorAction Stop
        }
        foreach($name in $rootReceipts.Keys){
            $path=Join-Path $root $name
            if($null -eq $rootReceipts[$name]){Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
            else{[IO.File]::WriteAllBytes($path,[byte[]]$rootReceipts[$name])}
        }
        throw
    } finally {
        if(Test-Path -LiteralPath $work -PathType Container){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
function Invoke-KF2Workshop([string]$Game){
    if($Game -notmatch '(?i)^(.*[\\/]steamapps)[\\/]common[\\/][^\\/]+$'){
        throw 'The Workshop route requires the Steam version. Use the GitHub ZIP for Epic.'
    }
    $steamApps=$Matches[1]
    $workshop=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KF2_TEST_WORKSHOP){
        Assert-KF2Fixture $env:PCVR_KF2_TEST_WORKSHOP
    }else{Join-Path $steamApps 'workshop\content\232090\3817663661'}
    Write-Host '  Subscribe on Steam, run the normal game once, then run Setup KF2VR in the Workshop folder.' -ForegroundColor White
    Write-Host '  Publisher Setup restarts Steam; choose Play in VR afterward.' -ForegroundColor White
    Write-Host '  Steam updates Workshop files. Do not combine this route with a GitHub installation.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the Steam Workshop page...')
    if($env:PCVR_HUB_TEST_MODE -ne '1'){Start-Process $script:KF2Workshop}
    while($true){
        [void](Wait-PCVRExplicitEnter -Message 'After Steam finishes the download, press Enter to check the Workshop folder...')
        $play=Join-Path $workshop 'Play.cmd'
        $setup=Get-ChildItem -LiteralPath $workshop -File -ErrorAction SilentlyContinue | Where-Object {$_.BaseName -ieq 'Setup KF2VR'} | Select-Object -First 1
        if((Test-Path -LiteralPath $play -PathType Leaf) -and $setup){break}
        Write-Host "  Workshop files are not complete yet: $workshop" -ForegroundColor Yellow
        $answer=(''+(Read-Host 'Press Enter to check again, O to reopen the page, or Q to cancel')).Trim()
        if($answer -ieq 'Q'){throw 'Workshop download is still incomplete; no install was marked complete.'}
        if($answer -ieq 'O'){
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to reopen the Steam Workshop page...')
            if($env:PCVR_HUB_TEST_MODE -ne '1'){Start-Process $script:KF2Workshop}
        }
    }
    Write-Host "  Workshop files: $workshop" -ForegroundColor Green
    Write-Host '  Run Setup KF2VR there, then choose Play in VR in Steam.' -ForegroundColor Yellow
    Write-Host '  The Hub does not mark this guided route VR Ready until its start path has been verified.' -ForegroundColor Yellow
}
function Invoke-KF2Installer {
    Clear-Host
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  Killing Floor 2 VR - Installer' -ForegroundColor Cyan
    Write-Host '  KF2VR by Kvasir94' -ForegroundColor Gray
    Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
    Write-Host '  One complete GitHub ZIP supports Steam Solo, Host and Join.' -ForegroundColor White
    Write-Host '  Epic VR is experimental Solo only. The Epic Desktop Pack is not a VR mode.' -ForegroundColor Yellow
    Write-Host '  Steam Workshop is a separate route updated by Steam.' -ForegroundColor White
    Write-Host '  Use only VAC-off or private compatible multiplayer servers.' -ForegroundColor Yellow
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Killing Floor 2...')
    $game=Get-KF2Game
    Write-Host "  Game: $game" -ForegroundColor Green
    Write-Host '  [1] GitHub ZIP - Hub installs the complete launcher (Steam or Epic)' -ForegroundColor Green
    Write-Host '  [2] Steam Workshop - subscribe and run publisher Setup (Steam only)' -ForegroundColor White
    $route=''
    while($route -notin @('1','2')){
        $route=(''+(Read-Host 'Choose 1 or 2 (Enter: GitHub ZIP)')).Trim()
        if(-not $route){$route='1'}
        if($route -notin @('1','2')){Write-Host '  Choose 1 or 2.' -ForegroundColor Yellow}
    }
    if($route -eq '1'){Install-KF2GitHub $game}
    else {Invoke-KF2Workshop $game}
    Write-Host ''
    Write-Host '  The next wave is yours. Keep your squad together.' -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
}
if($env:PCVR_KF2_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-KF2Installer;break}catch{$msg="Killing Floor 2 VR setup did not complete: $($_.Exception.Message)";
        Write-Host $msg -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $msg -InstallerFolder $PSScriptRoot)}}
}

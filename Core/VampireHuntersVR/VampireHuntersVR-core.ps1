$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
$Host.UI.RawUI.WindowTitle='Vampire Hunters VR Installer'
$script:VHId='vampire-hunters-vr'
$script:VHRepo='segadreamcat/VampireHuntersVR'
$script:VHPage='https://github.com/segadreamcat/VampireHuntersVR/releases'
$script:VHLoaderPage='https://builds.bepinex.dev/projects/bepinex_be/788/'
$script:VHLoaderUrl='https://builds.bepinex.dev/projects/bepinex_be/788/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.788%2B5b766a3.zip'
$script:VHRequired=@('Vampire Hunters.exe','UnityPlayer.dll','GameAssembly.dll',
    'winhttp.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll',
    'BepInEx\plugins\VampireHuntersVR\VampireHuntersVR.dll',
    'BepInEx\plugins\VampireHuntersVR\openvr_api.dll',
    '.pcvrhub_vampirehuntersvr_ownership.csv')
$script:VHContract=New-PCVRInstallerContract -Id $script:VHId -GameName 'Vampire Hunters VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:VHPage -Routes @('Steam') `
    -RequiredInstalledFileGroups $script:VHRequired

function Test-VHGame([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Vampire Hunters.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'UnityPlayer.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'GameAssembly.dll') -PathType Leaf))
}
function Get-VHGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VH_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_VH_TEST_GAME)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
           -not(Test-Path -LiteralPath (Join-Path $root 'vh-fixture.txt') -PathType Leaf) -or
           -not(Test-VHGame $root)){throw 'Vampire Hunters test game must be an isolated complete fixture.'}
        return $root
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:VHId -StateNames @('installed_path','user_located') -ProbeFiles @('Vampire Hunters.exe','UnityPlayer.dll','GameAssembly.dll')
    if(Test-VHGame $saved){return [IO.Path]::GetFullPath($saved)}
    try{$steam=Find-SteamGameFolder -AppId '2206270' -SteamFolderNames @('Vampire Hunters') -ProbeExe 'Vampire Hunters.exe' -HubGameId $script:VHId;if(Test-VHGame $steam){return [IO.Path]::GetFullPath($steam)}}catch{}
    $default='C:\Program Files (x86)\Steam\steamapps\common\Vampire Hunters'
    if(Test-VHGame $default){return $default}
    $picked=Get-GameFolderInteractive -GameName 'Vampire Hunters (Steam)' -ProbeFile 'Vampire Hunters.exe'
    if(Test-VHGame $picked){
        [void](Save-HubRememberedGameFolder -GameId $script:VHId -Title 'Vampire Hunters VR' -GameDir $picked -ProbeFiles @('Vampire Hunters.exe','UnityPlayer.dll','GameAssembly.dll') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose a complete Steam Vampire Hunters folder. Xbox App compatibility is not confirmed by the publisher.'
}
function Test-VHLoader([string]$Game){
    return [bool]((Test-Path -LiteralPath (Join-Path $Game 'winhttp.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Game 'BepInEx\core\BepInEx.Unity.IL2CPP.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Game 'dotnet\coreclr.dll') -PathType Leaf))
}
function Test-VHLoaderArchive([string]$Path){
    try{
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try{foreach($name in @('winhttp.dll','doorstop_config.ini','BepInEx/core/BepInEx.Unity.IL2CPP.dll','dotnet/coreclr.dll')){
            if(-not $zip.GetEntry($name)){return $false}
        };return $true}finally{$zip.Dispose()}
    }catch{return $false}
}
function Get-VHLoaderArchive([string]$Destination){
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VH_TEST_LOADER){
        Copy-Item -LiteralPath $env:PCVR_VH_TEST_LOADER -Destination $Destination -Force -ErrorAction Stop
    }else{
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download BepInEx 6 IL2CPP x64 build 788...')
        [void](Invoke-SafeDownload -Urls @($script:VHLoaderUrl) -Destination $Destination -Label 'BepInEx 6 IL2CPP x64 be.788' `
            -ManualUrl $script:VHLoaderPage -AllowSkip:$false -Validator {param($p) Test-VHLoaderArchive $p})
    }
    if(-not(Test-VHLoaderArchive $Destination)){throw 'The BepInEx dependency is not a complete Unity IL2CPP win-x64 package.'}
}
function Test-VHModArchive([string]$Path){
    try{
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try{foreach($name in @('BepInEx/plugins/VampireHuntersVR/VampireHuntersVR.dll',
            'BepInEx/plugins/VampireHuntersVR/openvr_api.dll')){
            if(-not $zip.GetEntry($name)){return $false}
        };return $true}finally{$zip.Dispose()}
    }catch{return $false}
}
function Get-VHModArchive([string]$Destination){
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VH_TEST_ARCHIVE){
        Copy-Item -LiteralPath $env:PCVR_VH_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop
        if(-not(Test-VHModArchive $Destination)){throw 'Vampire Hunters fixture lacks the plugin and OpenVR runtime.'}
        return 'v0.6.1'
    }
    $release=Resolve-GitHubReleaseAsset -Repo $script:VHRepo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^VampireHuntersVR-v[0-9]+(?:\.[0-9]+)+\.zip$') -SkipReleasesWithoutMatchingAsset $true
    if(-not $release.Resolved -or -not $release.Url -or -not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){
        throw 'The current Vampire Hunters VR release could not be resolved. Use recovery to open the official release and hand over its ZIP.'
    }
    [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label 'Vampire Hunters VR ZIP' `
        -ManualUrl $script:VHPage -AllowSkip:$false -Validator {param($p) Test-VHModArchive $p})
    if(-not(Test-VHModArchive $Destination)){throw 'The publisher ZIP lacks its plugin or OpenVR runtime.'}
    return [string]$release.Tag
}
function Test-VHInterop([string]$Game){
    $folder=Join-Path $Game 'BepInEx\interop'
    return [bool]((Test-Path -LiteralPath $folder -PathType Container) -and
        @(Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue).Count -gt 0)
}
function Invoke-VHFlatFirstRun([string]$Game){
    if(Test-VHInterop $Game){return}
    Write-Host ''
    Write-Host '  REQUIRED FIRST RUN: BepInEx must generate game interop before the VR plugin is copied.' -ForegroundColor Yellow
    Write-Host '  Start the normal Steam game, wait for its flat main menu, then close it.' -ForegroundColor White
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if($env:PCVR_VH_TEST_FLAT_RUN -ne '1'){throw 'Fixture skipped the required flat BepInEx first run.'}
        $interop=Join-Path $Game 'BepInEx\interop';[void][IO.Directory]::CreateDirectory($interop)
        [IO.File]::WriteAllText((Join-Path $interop 'Assembly-CSharp.dll'),'fixture interop')
    }else{
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start Vampire Hunters flat through Steam...')
        Start-Process 'steam://rungameid/2206270'
        [void](Wait-PCVRExplicitEnter -Message 'After reaching the flat main menu and closing the game, press Enter to check BepInEx...')
    }
    if(-not(Test-VHInterop $Game)){throw 'BepInEx interop was not generated. Start the flat game once to its menu, close it, then Retry.'}
}
function Invoke-VHInstaller {
    $work=$null;$modSnapshot=$null;$loaderSnapshot=$null;$game=$null;$modChanged=$false;$loaderChanged=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Vampire Hunters VR - Installer' -ForegroundColor Cyan
        Write-Host '  Steam only; BepInEx 6 IL2CPP plus publisher plugin' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  First run BepInEx flat to the main menu before adding the VR plugin.' -ForegroundColor White
        Write-Host '  Existing compatible BepInEx files and personal settings are retained.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Vampire Hunters...')
        $game=Get-VHGame
        Write-Host "  Game: $game" -ForegroundColor Green
        if(Get-Process -Name 'Vampire Hunters' -ErrorAction SilentlyContinue){throw 'Close Vampire Hunters before installing or updating VR.'}
        if(-not(Test-InstallerTargetWritable $game)){throw 'The Vampire Hunters folder is not writable.'}
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $modArchive=Join-Path $work 'VampireHuntersVR.zip'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Vampire Hunters VR ZIP...')
        $version=Get-VHModArchive $modArchive
        $modStage=Join-Path $work 'mod'
        if((Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modStage -Label 'Vampire Hunters VR' -AllowSkip:$false) -ne 'ok'){
            throw 'The publisher mod ZIP could not be extracted.'
        }
        if(-not(Test-VHLoader $game)){
            $partial=@('winhttp.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll','dotnet\coreclr.dll')|Where-Object{Test-Path -LiteralPath (Join-Path $game $_) -PathType Leaf}
            if(@($partial).Count -gt 0){throw 'An incomplete BepInEx installation is present. Repair it before installing Vampire Hunters VR.'}
            $loaderArchive=Join-Path $work 'BepInEx-IL2CPP.zip'
            Get-VHLoaderArchive $loaderArchive
            $loaderStage=Join-Path $work 'loader'
            if((Expand-ArchiveOrFallback -ArchivePath $loaderArchive -DestinationFolder $loaderStage -Label 'BepInEx IL2CPP' -AllowSkip:$false) -ne 'ok'){
                throw 'The BepInEx ZIP could not be extracted.'
            }
            foreach($name in @('winhttp.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll','dotnet\coreclr.dll')){
                if(-not(Test-Path -LiteralPath (Join-Path $loaderStage $name) -PathType Leaf)){throw "BepInEx archive lacks $name."}
            }
            $loaderSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $loaderStage -Identity 'vhbepinex' -SnapshotRoot (Join-Path $work 'loader-rollback')
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the tested BepInEx loader...')
            $loaderChanged=$true
            [void](Install-OwnedModPayload -SourceRoot $loaderStage -GameRoot $game -Identity 'vhbepinex' -AdoptIdenticalExisting)
            if(-not(Test-VHLoader $game)){throw 'BepInEx loader files did not survive installation.'}
        }
        Invoke-VHFlatFirstRun $game
        if(Get-Process -Name 'Vampire Hunters' -ErrorAction SilentlyContinue){throw 'Close Vampire Hunters after the flat first run before installing its VR plugin.'}
        $modSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $modStage -Identity 'vampirehuntersvr' -SnapshotRoot (Join-Path $work 'mod-rollback')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update the Vampire Hunters VR plugin...')
        $modChanged=$true
        [void](Install-OwnedModPayload -SourceRoot $modStage -GameRoot $game -Identity 'vampirehuntersvr' -AdoptIdenticalExisting)
        $required=@('winhttp.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll',
            'BepInEx\plugins\VampireHuntersVR\VampireHuntersVR.dll',
            'BepInEx\plugins\VampireHuntersVR\openvr_api.dll',
            '.pcvrhub_vampirehuntersvr_ownership.csv')|ForEach-Object{Join-Path $game $_}
        if(-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)){throw 'Vampire Hunters VR files did not survive installation.'}
        $receipt=if($env:PCVR_VH_TEST_RECEIPT){$env:PCVR_VH_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:VHContract -GameDir $game -Version $version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $modChanged=$false;$loaderChanged=$false
        Write-Host "  [OK] Vampire Hunters VR $version is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub with SteamVR running.' -ForegroundColor White
        Write-Host '  Alternatively, start Vampire Hunters from Steam.' -ForegroundColor White
        Write-Host '  If the headset stays black, set Steam Launch Options to -force-d3d11.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Tonight, the hunters bring two hands to a gunfight.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($modChanged -and $modSnapshot -and $game){try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $modSnapshot}catch{Write-Host "  [!!] Plugin rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}}
        if($loaderChanged -and $loaderSnapshot -and $game){try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $loaderSnapshot}catch{Write-Host "  [!!] Loader rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}}
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_VH_LIBRARY_ONLY -ne '1'){
    while($true){
        try{Invoke-VHInstaller;break}
        catch{
            $message="Vampire Hunters VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}

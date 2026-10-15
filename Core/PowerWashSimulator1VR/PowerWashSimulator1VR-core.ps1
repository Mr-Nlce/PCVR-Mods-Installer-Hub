$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='PowerWash Simulator VR Installer'
$APP_ID='1290000';$GAME_EXE='PowerWashSimulator.exe';$IDENTITY='wetrealitypws1'
$REPO='onetin84/Wet-Reality-XR-PWS1';$RELEASES_URL="https://github.com/$REPO/releases"
$MELON_URL='https://github.com/LavaGang/MelonLoader/releases/download/v0.7.3/MelonLoader.x64.zip'
$DOTNET_URL='https://builds.dotnet.microsoft.com/dotnet/Runtime/6.0.36/dotnet-runtime-6.0.36-win-x64.zip'
$OPENXR_FILES=@('PowerWashSimulator_Data\Plugins\x86_64\openxr_loader.dll',
    'PowerWashSimulator_Data\Plugins\x86_64\UnityOpenXR.dll',
    'PowerWashSimulator_Data\UnitySubsystems\UnityOpenXR\UnitySubsystemsManifest.json')
$required=@('Mods\WetReality.XRStart.dll','MelonLoader\net6\MelonLoader.dll','version.dll',
    'dotnet\host\fxr\6.0.36\hostfxr.dll',".pcvrhub_${IDENTITY}_ownership.csv") + $OPENXR_FILES
$contract=New-PCVRInstallerContract -Id 'powerwash-simulator-vr' -GameName 'PowerWash Simulator VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES_URL -RequiredInstalledFileGroups $required

function Test-WRGameRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path 'GameAssembly.dll') -PathType Leaf))
}
function Get-WRGameRoot {
    $fixture=(''+$env:PCVR_PWS1_TEST_GAME_ROOT).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){
        $full=[IO.Path]::GetFullPath($fixture);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'pws1-fixture.txt'))){throw 'PWS1 fixture must stay in an isolated temporary game folder.'}
        return $full
    }
    $saved=Get-PCVRRememberedGameFolder -GameId 'powerwash-simulator-vr' -StateNames @('installed_path','user_located') -ProbeFiles @($GAME_EXE,'GameAssembly.dll')
    if(Test-WRGameRoot $saved){return (Get-Item -LiteralPath $saved).FullName}
    $steam=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('PowerWash Simulator') -ProbeExe $GAME_EXE -HubGameId 'powerwash-simulator-vr'
    if(Test-WRGameRoot $steam){return (Get-Item -LiteralPath $steam).FullName}
    foreach($path in @('C:\Program Files (x86)\Steam\steamapps\common\PowerWash Simulator','C:\XboxGames\PowerWash Simulator\Content')){
        if(Test-WRGameRoot $path){return (Get-Item -LiteralPath $path).FullName}
    }
    $picked=Get-GameFolderInteractive -GameName 'PowerWash Simulator' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/1290000/'
    if(Test-WRGameRoot $picked){
        [void](Save-HubRememberedGameFolder -GameId 'powerwash-simulator-vr' -Title 'PowerWash Simulator VR' -GameDir $picked -ProbeFiles @($GAME_EXE,'GameAssembly.dll') -UserSelected)
        return (Get-Item -LiteralPath $picked).FullName
    }
    return $null
}
function Get-WRRelease([object]$ReleaseData=$null) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PWS1_TEST_SOURCE_ROOT){
        $source=[IO.Path]::GetFullPath($env:PCVR_PWS1_TEST_SOURCE_ROOT);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $source.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $source 'pws1-fixture.txt'))){throw 'PWS1 downloads fixture must stay in an isolated temporary folder.'}
        $tag=(''+$env:PCVR_PWS1_TEST_VERSION).Trim();if(-not(Test-IsTrackableInstalledVersion $tag)){throw 'PWS1 fixture version is not trackable.'}
        return [pscustomobject]@{Resolved=$true;Tag=$tag;Url='fixture://wet-reality-pws1'}
    }
    $args=@{Repo=$REPO;IncludePrerelease=$true;AssetPatterns=@('(?i)^WetReality-XRMod-PWS1-[0-9].*\.zip$');SkipReleasesWithoutMatchingAsset=$true}
    if($null -ne $ReleaseData){$args.ReleaseData=$ReleaseData}
    $r=Resolve-GitHubReleaseAsset @args
    if(-not $r.Resolved -or -not(Test-IsTrackableInstalledVersion $r.Tag)){throw 'No installable prerelease was found on GitHub.'}
    return $r
}
function Test-WRPublisherPayload([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'mod\WetReality.XRStart.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'Configurator.cmd') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'configurator\WetReality-Config.ps1') -PathType Leaf))
}
function Set-WRConfigValue([Collections.Generic.List[string]]$Lines,[string]$Section,[string]$Key,[string]$Value){
    $sectionLine=-1;$nextSection=$Lines.Count
    for($i=0;$i -lt $Lines.Count;$i++){if($Lines[$i] -match '^\s*\[(.+)\]\s*$'){if($Matches[1] -ieq $Section){$sectionLine=$i;$nextSection=$Lines.Count;continue};if($sectionLine -ge 0){$nextSection=$i;break}}}
    if($sectionLine -lt 0){if($Lines.Count -and $Lines[$Lines.Count-1]){$Lines.Add('')};$Lines.Add("[$Section]");$Lines.Add("$Key = $Value");return}
    for($i=$sectionLine+1;$i -lt $nextSection;$i++){if($Lines[$i] -match ('^\s*'+[regex]::Escape($Key)+'\s*=')){$Lines[$i]="$Key = $Value";return}}
    $Lines.Insert($nextSection,"$Key = $Value")
}
function New-WRInstallStage([string]$PublisherRoot,[string]$MelonArchive,[string]$DotnetArchive,[string]$GameRoot,[string]$Stage,[string]$Scratch){
    if(-not(Test-WRPublisherPayload $PublisherRoot)){throw 'Publisher ZIP lacks the mod DLL or configurator.'}
    [void][IO.Directory]::CreateDirectory((Join-Path $Stage 'Mods'))
    Copy-Item -LiteralPath (Join-Path $PublisherRoot 'mod\WetReality.XRStart.dll') -Destination (Join-Path $Stage 'Mods\WetReality.XRStart.dll') -Force
    $tools=Join-Path $Stage 'WetRealityXR-PWS1';[void][IO.Directory]::CreateDirectory($tools)
    foreach($name in @('Configurator.cmd','README.txt','LIESMICH.txt')){if(Test-Path -LiteralPath (Join-Path $PublisherRoot $name)){Copy-Item -LiteralPath (Join-Path $PublisherRoot $name) -Destination (Join-Path $tools $name) -Force}}
    Copy-Item -LiteralPath (Join-Path $PublisherRoot 'configurator') -Destination $tools -Recurse -Force
    $ownership=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv";$owned=@()
    if(Test-Path -LiteralPath $ownership -PathType Leaf){$owned=@(Import-Csv -LiteralPath $ownership | ForEach-Object {[string]$_.RelativePath})}
    $melon=Join-Path $Scratch 'melon';Expand-Archive -LiteralPath $MelonArchive -DestinationPath $melon -Force
    foreach($file in @('version.dll','MelonLoader\net6\MelonLoader.dll')){if(-not(Test-Path -LiteralPath (Join-Path $melon $file) -PathType Leaf)){throw "MelonLoader archive lacks $file"}}
    if(-not(Test-Path -LiteralPath (Join-Path $GameRoot 'MelonLoader') -PathType Container) -or @($owned | Where-Object {$_ -like 'MelonLoader\*'}).Count){Copy-Item -LiteralPath (Join-Path $melon 'MelonLoader') -Destination $Stage -Recurse -Force}
    elseif(-not(Test-Path -LiteralPath (Join-Path $GameRoot 'MelonLoader\net6\MelonLoader.dll'))){throw 'Existing MelonLoader is incomplete; repair it before retrying.'}
    if(-not(Test-Path -LiteralPath (Join-Path $GameRoot 'version.dll') -PathType Leaf) -or $owned -contains 'version.dll'){Copy-Item -LiteralPath (Join-Path $melon 'version.dll') -Destination (Join-Path $Stage 'version.dll') -Force}
    $hostfxr='dotnet\host\fxr\6.0.36\hostfxr.dll'
    if(-not(Test-Path -LiteralPath (Join-Path $GameRoot $hostfxr) -PathType Leaf) -or $owned -contains $hostfxr){
        $dotnet=Join-Path $Stage 'dotnet';[void][IO.Directory]::CreateDirectory($dotnet);Expand-Archive -LiteralPath $DotnetArchive -DestinationPath $dotnet -Force
        foreach($file in @('dotnet.exe','host\fxr\6.0.36\hostfxr.dll','shared\Microsoft.NETCore.App\6.0.36\System.Private.CoreLib.dll')){if(-not(Test-Path -LiteralPath (Join-Path $dotnet $file) -PathType Leaf)){throw "Portable .NET archive lacks $file"}}
    }
    $cfgSource=Join-Path $GameRoot 'UserData\Loader.cfg';$lines=[Collections.Generic.List[string]]::new()
    if(Test-Path -LiteralPath $cfgSource -PathType Leaf){foreach($line in [IO.File]::ReadAllLines($cfgSource)){$lines.Add($line)}}
    Set-WRConfigValue -Lines $lines -Section 'loader' -Key 'hostfxr_path_override' -Value ('"'+(Join-Path $GameRoot $hostfxr).Replace('\','\\')+'"')
    Set-WRConfigValue -Lines $lines -Section 'console' -Key 'hide_console' -Value 'true'
    $cfgStage=Join-Path $Stage 'UserData\Loader.cfg';[void][IO.Directory]::CreateDirectory((Split-Path -Parent $cfgStage));[IO.File]::WriteAllLines($cfgStage,$lines,(New-Object Text.UTF8Encoding $false))
    return $Stage
}

function Save-WRSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot);$filesRoot=Join-Path $SnapshotRoot 'files';$relatives=[Collections.Generic.List[string]]::new();$base=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$relatives.Add($file.FullName.Substring($base.Length+1))}
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv";if(Test-Path -LiteralPath $manifest -PathType Leaf){try{foreach($row in @(Import-Csv $manifest)){if($row.RelativePath){$relatives.Add([string]$row.RelativePath)}}}catch{}}
    foreach($extra in @(".pcvrhub_${IDENTITY}_ownership.csv",".pcvrhub_${IDENTITY}_ownership.csv.new",'.pcvrhub_version')){$relatives.Add($extra)}
    $records=@();foreach($rel in @($relatives|Select-Object -Unique)){$src=Join-Path $GameRoot $rel;$exists=Test-Path -LiteralPath $src -PathType Leaf;$records+=[pscustomobject]@{Relative=$rel;Exists=$exists};if($exists){$copy=Join-Path $filesRoot $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $src -Destination $copy -Force}}
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup";$backupExists=Test-Path -LiteralPath $backup -PathType Container;if($backupExists){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force}
    return [pscustomobject]@{Records=$records;BackupExists=$backupExists;SnapshotRoot=$SnapshotRoot}
}
function Restore-WRSnapshot([string]$GameRoot,$Snapshot){
    foreach($record in @($Snapshot.Records)){$target=Join-Path $GameRoot ([string]$record.Relative);if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force};if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.SnapshotRoot 'files') ([string]$record.Relative)) -Destination $target -Force}}
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup";if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force};if($Snapshot.BackupExists){Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force}
}

function global:Invoke-PowerWashSimulator1VRInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changesStarted=$false
    try {
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  PowerWash Simulator VR - Installer' -ForegroundColor Cyan
        Write-Host '  Wet Reality XR: motion controls and roomscale OpenXR' -ForegroundColor Gray;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  This is PowerWash Simulator 1. The publisher tested Steam' -ForegroundColor White
        Write-Host '  game version 1.11.0 build 1394. Xbox files can be located,' -ForegroundColor White
        Write-Host '  but that store build is not publisher-verified.' -ForegroundColor Yellow
        Write-Host '  The game already contains Unity OpenXR. Setup adds the mod,' -ForegroundColor White
        Write-Host '  MelonLoader 0.7.3 and portable .NET 6 with owned-file backups.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to begin...')
        Write-Host '  [1/5] Locating the game' -ForegroundColor Cyan
        $game=Get-WRGameRoot;if(-not $game){throw 'PowerWash Simulator was not found. No files were changed.'}
        if(Get-Process -Name 'PowerWashSimulator' -ErrorAction SilentlyContinue){throw 'Close PowerWash Simulator before installing.'}
        foreach($relative in $OPENXR_FILES){if(-not(Test-Path -LiteralPath (Join-Path $game $relative) -PathType Leaf)){throw "Game OpenXR file missing: $relative. Verify the game in your store."}}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Run setup as administrator and retry.'}
        Write-Host "  [OK] $game" -ForegroundColor Green
        Write-Host '  [2/5] Resolving publisher prerelease and runtimes' -ForegroundColor Cyan
        Write-Host '  Checking GitHub can take a few seconds.' -ForegroundColor Gray
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current files...')
        $release=Get-WRRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_pws1_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $downloads=@(@('mod.zip',$release.Url,"Wet Reality $($release.Tag)",$RELEASES_URL),
            @('melon.zip',$MELON_URL,'MelonLoader 0.7.3','https://github.com/LavaGang/MelonLoader/releases/tag/v0.7.3'),
            @('dotnet.zip',$DOTNET_URL,'portable .NET 6.0.36','https://dotnet.microsoft.com/download/dotnet/6.0'))
        $modDownloadVerified=$false
        foreach($item in $downloads){
            if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PWS1_TEST_SOURCE_ROOT){
                $source=Join-Path $env:PCVR_PWS1_TEST_SOURCE_ROOT $item[0]
                if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw "Fixture archive missing: $($item[0])"}
                Copy-Item -LiteralPath $source -Destination (Join-Path $work $item[0]) -Force;$ok=$true
                if($item[0] -eq 'mod.zip'){$modDownloadVerified=$true}
            }else{
                $downloadInfo=@{}
                $ok=Invoke-SafeDownload -Urls @($item[1]) -Destination (Join-Path $work $item[0]) -Label $item[2] -ManualUrl $item[3] -AllowSkip:$false -DownloadInfo $downloadInfo
                if($item[0] -eq 'mod.zip'){$modDownloadVerified=($ok -eq $true -and [string]$downloadInfo.Url -eq [string]$release.Url)}
            }
            if(-not($ok -eq $true -or [string]$ok -in @('retry','manual'))){throw "$($item[2]) was not downloaded."}
        }
        $extract=Join-Path $work 'publisher';$result=Expand-ArchiveOrFallback -ArchivePath (Join-Path $work 'mod.zip') -DestinationFolder $extract -Label 'Wet Reality release' -AllowSkip:$false -QuietProgress
        if([string]$result -notin @('ok','manual','retry')){throw 'The Wet Reality release could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'mod\WetReality.XRStart.dll'
        $payloadVersion=[string][Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $payload 'mod\WetReality.XRStart.dll')).FileVersion
        $releaseNumeric=[regex]::Match([string]$release.Tag,'\d+(?:\.\d+){1,3}').Value
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PWS1_TEST_SOURCE_ROOT){$payloadVersion=$releaseNumeric}
        if(-not $payloadVersion -or $payloadVersion -ne $releaseNumeric){throw "Wet Reality package version $payloadVersion does not match selected release $($release.Tag). No game files were changed."}
        $receiptVersion=if($modDownloadVerified){[string]$release.Tag}else{'v'+$payloadVersion}
        $stage=New-WRInstallStage -PublisherRoot $payload -MelonArchive (Join-Path $work 'melon.zip') -DotnetArchive (Join-Path $work 'dotnet.zip') -GameRoot $game -Stage (Join-Path $work 'stage') -Scratch $work
        Write-Host '  [3/5] Saving prior game-folder files for rollback' -ForegroundColor Cyan
        $snapshot=Save-WRSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback');$changesStarted=$true
        Write-Host '  [4/5] Installing and verifying files; this can take several minutes.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting -ProgressLabel 'Installing Wet Reality XR')
        foreach($relative in $required){if(-not(Test-Path -LiteralPath (Join-Path $game $relative) -PathType Leaf)){throw "Installed file missing: $relative"}}
        Write-Host '  Copy complete. Checking that files stay present...' -ForegroundColor Gray
        $watch=@($required|ForEach-Object{Join-Path $game $_});if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required files disappeared after installation.'}
        $receipt=Join-Path $PSScriptRoot '.installed_path'
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PWS1_TEST_SOURCE_ROOT){$receipt=Join-Path $env:PCVR_PWS1_TEST_SOURCE_ROOT 'installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $receiptVersion -Route Current -InstalledPathReceiptPaths @($receipt))
        $changesStarted=$false
        Write-Host '  [5/5] PowerWash Simulator VR is ready.' -ForegroundColor Green
        Write-Host '  Start your headset runtime, then use Start in VR in the Hub.' -ForegroundColor White
        Write-Host '  First MelonLoader launch can take a while without game progress.' -ForegroundColor Yellow
        Write-Host '  Set VSync off and uncap the frame rate in game options.' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  The grime never stood a chance against your reach.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if($changesStarted -and $game -and $snapshot){try{Restore-WRSnapshot -GameRoot $game -Snapshot $snapshot;Write-Host '  Previous game-folder files restored.' -ForegroundColor Yellow}catch{Write-Host "  Rollback needs attention: $($_.Exception.Message)" -ForegroundColor Red}}
        throw
    } finally {if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_PWS1_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-PowerWashSimulator1VRInstaller}

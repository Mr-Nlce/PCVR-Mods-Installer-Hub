# PowerWash Simulator 2 - Wet Reality XR governed prerelease installer.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='PowerWash Simulator 2 VR Installer'
$APP_ID='2968420'
$GAME_EXE='PowerWash Simulator 2.exe'
$REPO='onetin84/Wet-Reality-XR-Mod'
$RELEASES_URL="https://github.com/$REPO/releases"
$FALLBACK_TAG='v1.86.0-beta'
$FALLBACK_ASSET='WetReality-XRMod-1.86.0-beta.zip'
$FALLBACK_URL='https://github.com/onetin84/Wet-Reality-XR-Mod/releases/download/v1.86.0-beta/WetReality-XRMod-1.86.0-beta.zip'
$MELON_URL='https://github.com/LavaGang/MelonLoader/releases/download/v0.7.3/MelonLoader.x64.zip'
$DOTNET_URL='https://builds.dotnet.microsoft.com/dotnet/Runtime/6.0.36/dotnet-runtime-6.0.36-win-x64.zip'
$OPENXR_URL='https://download.packages.unity.com/com.unity.xr.openxr/-/com.unity.xr.openxr-1.18.0.tgz'
$IDENTITY='wetrealityxr'
$QUIP='Every stubborn stain is now within arm''s reach.'
$required=@(
    'Mods\WetReality.Pose.dll','Mods\WetReality.XRBoot.dll','MelonLoader\net6\MelonLoader.dll','version.dll',
    'dotnet\host\fxr\6.0.36\hostfxr.dll','PowerWash Simulator 2_Data\Plugins\x86_64\openxr_loader.dll',
    'PowerWash Simulator 2_Data\Plugins\x86_64\UnityOpenXR.dll','PowerWash Simulator 2_Data\UnitySubsystems\UnityOpenXR\UnitySubsystemsManifest.json',
    ".pcvrhub_${IDENTITY}_ownership.csv"
)
$contract=New-PCVRInstallerContract -Id 'powerwash-simulator-2-vr' -GameName 'PowerWash Simulator 2 VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES_URL -RequiredInstalledFileGroups $required

function Write-WRStep([int]$Number,[int]$Total,[string]$Text){Write-Host '';Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan;Write-Host ''}
function Write-WROK([string]$Text){Write-Host "  [OK] $Text" -ForegroundColor Green}
function Write-WRWarn([string]$Text){Write-Host "  [!!] $Text" -ForegroundColor Yellow}
function Write-WRInfo([string]$Text){Write-Host "  $Text" -ForegroundColor Gray}

function Test-WRGameRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath (Join-Path $Path 'PowerWash Simulator 2_Data') -PathType Container -ErrorAction SilentlyContinue))}
function Get-WRDefaultStoreRoots {
    return @(
        'C:\Program Files (x86)\Steam\steamapps\common\PowerWash Simulator 2',
        'C:\Program Files\Epic Games\PowerWashSimulator2',
        'C:\XboxGames\PowerWash Simulator 2\Content'
    )
}
function Find-WRWindowsAppsRoot {
    $windowsApps='C:\Program Files\WindowsApps'
    if(-not(Test-Path -LiteralPath $windowsApps -PathType Container -ErrorAction SilentlyContinue)){return $null}
    try{
        foreach($folder in @(Get-ChildItem -LiteralPath $windowsApps -Directory -Filter '*PowerWash*Simulator*2*' -ErrorAction Stop)){
            if(Test-WRGameRoot $folder.FullName){return (Get-Item -LiteralPath $folder.FullName).FullName}
        }
    }catch{}
    return $null
}
function Get-WRGameRoot {
    $game=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('PowerWash Simulator 2') -ProbeExe $GAME_EXE -HubGameId 'powerwash-simulator-2-vr'
    if(Test-WRGameRoot $game){return (Get-Item -LiteralPath $game).FullName}
    foreach($fallback in @(Get-WRDefaultStoreRoots)){
        if(Test-WRGameRoot $fallback){return (Get-Item -LiteralPath $fallback).FullName}
    }
    $windowsAppsRoot=Find-WRWindowsAppsRoot
    if(Test-WRGameRoot $windowsAppsRoot){return $windowsAppsRoot}
    $picked=Get-GameFolderInteractive -GameName 'PowerWash Simulator 2' -ProbeFile $GAME_EXE -ManualUrl $RELEASES_URL
    if($picked -in @('quit','skip',$null) -or -not(Test-WRGameRoot $picked)){return $null}
    return (Get-Item -LiteralPath $picked).FullName
}
function Get-WRRelease {
    $r=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -AssetPatterns @('(?i)^WetReality-XRMod-.*\.zip$') `
        -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Name=[string]$r.AssetName;PageUrl=[string]$r.PageUrl}
}
function Test-WRPublisherPayload([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'mod\WetReality.Pose.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'mod\WetReality.XRBoot.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'Configurator.cmd') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'configurator\WetReality-Config.ps1') -PathType Leaf))
}

function ConvertTo-WRNativeArgument([string]$Value){if($Value -notmatch '[\s"]'){return $Value};return '"'+($Value -replace '(\\*)"','$1$1\"' -replace '(\\+)$','$1$1')+'"'}
function Invoke-WRNative([string]$FilePath,[string[]]$Arguments){
    $psi=New-Object Diagnostics.ProcessStartInfo
    $nativeArguments=@($Arguments|ForEach-Object{ConvertTo-WRNativeArgument ([string]$_)})
    $psi.FileName=$FilePath;$psi.Arguments=($nativeArguments -join ' ')
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $p=New-Object Diagnostics.Process;$p.StartInfo=$psi
    if(-not $p.Start()){throw "Could not start native tool: $FilePath"}
    $stdout=$p.StandardOutput.ReadToEnd();$stderr=$p.StandardError.ReadToEnd();$p.WaitForExit()
    $result=[pscustomobject]@{ExitCode=$p.ExitCode;StdOut=$stdout;StdErr=$stderr}
    if($p.ExitCode -ne 0){throw "Native tool failed with exit code $($p.ExitCode): $stderr $stdout"}
    return $result
}

function Set-WRConfigValue([Collections.Generic.List[string]]$Lines,[string]$Section,[string]$Key,[string]$Value){
    $sectionLine=-1;$nextSection=$Lines.Count
    for($i=0;$i -lt $Lines.Count;$i++){if($Lines[$i] -match '^\s*\[(.+)\]\s*$'){if($Matches[1] -ieq $Section){$sectionLine=$i;$nextSection=$Lines.Count;continue};if($sectionLine -ge 0){$nextSection=$i;break}}}
    if($sectionLine -lt 0){if($Lines.Count -and $Lines[$Lines.Count-1]){$Lines.Add('')};$Lines.Add("[$Section]");$Lines.Add("$Key = $Value");return}
    for($i=$sectionLine+1;$i -lt $nextSection;$i++){if($Lines[$i] -match ('^\s*'+[regex]::Escape($Key)+'\s*=')){$Lines[$i]="$Key = $Value";return}}
    $Lines.Insert($nextSection,"$Key = $Value")
}

function New-WRInstallStage {
    param([string]$PublisherRoot,[string]$MelonArchive,[string]$DotnetArchive,[string]$OpenXrArchive,[string]$GameRoot,[string]$Stage,[string]$Scratch)
    if(-not(Test-WRPublisherPayload $PublisherRoot)){throw 'The release lacks its mod assemblies or configurator.'}
    [void][IO.Directory]::CreateDirectory($Stage)
    [void][IO.Directory]::CreateDirectory((Join-Path $Stage 'Mods'))
    Copy-Item -LiteralPath (Join-Path $PublisherRoot 'mod\WetReality.Pose.dll') -Destination (Join-Path $Stage 'Mods\WetReality.Pose.dll') -Force
    Copy-Item -LiteralPath (Join-Path $PublisherRoot 'mod\WetReality.XRBoot.dll') -Destination (Join-Path $Stage 'Mods\WetReality.XRBoot.dll') -Force
    $tools=Join-Path $Stage 'WetRealityXR';[void][IO.Directory]::CreateDirectory($tools)
    foreach($name in @('Configurator.cmd','README.txt','LIESMICH.txt')){if(Test-Path -LiteralPath (Join-Path $PublisherRoot $name)){Copy-Item -LiteralPath (Join-Path $PublisherRoot $name) -Destination (Join-Path $tools $name) -Force}}
    Copy-Item -LiteralPath (Join-Path $PublisherRoot 'configurator') -Destination $tools -Recurse -Force

    $melonExtract=Join-Path $Scratch 'melonloader';Expand-Archive -LiteralPath $MelonArchive -DestinationPath $melonExtract -Force
    if(-not(Test-Path -LiteralPath (Join-Path $melonExtract 'MelonLoader\net6\MelonLoader.dll') -PathType Leaf) -or -not(Test-Path -LiteralPath (Join-Path $melonExtract 'version.dll') -PathType Leaf)){throw 'The MelonLoader archive lacks its functional files.'}
    if(-not(Test-Path -LiteralPath (Join-Path $GameRoot 'MelonLoader') -PathType Container)){
        Copy-Item -Path (Join-Path $melonExtract '*') -Destination $Stage -Recurse -Force
    } elseif(-not(Test-Path -LiteralPath (Join-Path $GameRoot 'MelonLoader\net6\MelonLoader.dll') -PathType Leaf)){
        throw 'An incomplete existing MelonLoader folder was found. Repair or remove it before retrying.'
    } elseif(-not(Test-Path -LiteralPath (Join-Path $GameRoot 'version.dll') -PathType Leaf)){
        Copy-Item -LiteralPath (Join-Path $melonExtract 'version.dll') -Destination (Join-Path $Stage 'version.dll') -Force
    }
    $dotnet=Join-Path $Stage 'dotnet';[void][IO.Directory]::CreateDirectory($dotnet);Expand-Archive -LiteralPath $DotnetArchive -DestinationPath $dotnet -Force

    $openRoot=Join-Path $Scratch 'openxr';[void][IO.Directory]::CreateDirectory($openRoot)
    $members=@('package/RuntimeLoaders/windows/x64/openxr_loader.dll','package/Runtime/windows/x64/UnityOpenXR.dll','package/Runtime/UnitySubsystemsManifest.json')
    $tar=Join-Path $env:SystemRoot 'System32\tar.exe';if(-not(Test-Path -LiteralPath $tar -PathType Leaf)){throw 'Windows tar.exe is required to unpack Unity OpenXR.'}
    [void](Invoke-WRNative -FilePath $tar -Arguments (@('-xzf',$OpenXrArchive,'-C',$openRoot)+$members))
    $maps=@(
        @('package\RuntimeLoaders\windows\x64\openxr_loader.dll','PowerWash Simulator 2_Data\Plugins\x86_64\openxr_loader.dll',2373632),
        @('package\Runtime\windows\x64\UnityOpenXR.dll','PowerWash Simulator 2_Data\Plugins\x86_64\UnityOpenXR.dll',919040),
        @('package\Runtime\UnitySubsystemsManifest.json','PowerWash Simulator 2_Data\UnitySubsystems\UnityOpenXR\UnitySubsystemsManifest.json',250)
    )
    foreach($map in $maps){$src=Join-Path $openRoot $map[0];if(-not(Test-Path -LiteralPath $src -PathType Leaf) -or (Get-Item -LiteralPath $src).Length -ne [int64]$map[2]){throw "Unity OpenXR functional file is missing or invalid: $($map[0])"};$dst=Join-Path $Stage $map[1];[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dst));Copy-Item -LiteralPath $src -Destination $dst -Force}

    foreach($proof in @('Mods\WetReality.Pose.dll','Mods\WetReality.XRBoot.dll','dotnet\dotnet.exe','dotnet\host\fxr\6.0.36\hostfxr.dll','dotnet\shared\Microsoft.NETCore.App\6.0.36\System.Private.CoreLib.dll')){if(-not(Test-Path -LiteralPath (Join-Path $Stage $proof) -PathType Leaf)){throw "Install stage is missing $proof"}}
    $cfgSource=Join-Path $GameRoot 'UserData\Loader.cfg';$lines=[Collections.Generic.List[string]]::new()
    if(Test-Path -LiteralPath $cfgSource -PathType Leaf){foreach($line in [IO.File]::ReadAllLines($cfgSource)){$lines.Add($line)}}
    Set-WRConfigValue -Lines $lines -Section 'loader' -Key 'hostfxr_path_override' -Value ('"'+(Join-Path $GameRoot 'dotnet\host\fxr\6.0.36\hostfxr.dll').Replace('\','\\')+'"')
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
function Install-WROwnedPayload([string]$GameRoot,[string]$Stage,[string]$Version,[string]$Receipt){
    if(-not(Test-WRGameRoot $GameRoot)){throw 'The selected folder is not PowerWash Simulator 2.'}
    [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $GameRoot -Identity $IDENTITY -AdoptIdenticalExisting -ProgressLabel 'Installing Wet Reality XR runtime')
    Write-WRInfo 'Copy complete. Verifying the installed runtime files now...'
    foreach($proof in $required){if(-not(Test-Path -LiteralPath (Join-Path $GameRoot $proof) -PathType Leaf)){throw "Installed payload proof is missing: $proof"}}
    Write-WRInfo 'Files verified. Running the short post-copy survival check...'
    $watch=@($required|ForEach-Object{Join-Path $GameRoot $_});if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $GameRoot -NoClear)){throw 'Required Wet Reality XR files are missing after installation.'}
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version -InstalledPathReceiptPaths @($Receipt) -Route 'Current')
}

function global:Invoke-PowerWashSimulator2VRInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changesStarted=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  PowerWash Simulator 2 VR - Installer' -ForegroundColor Cyan;Write-Host '  Wet Reality XR: motion controls and roomscale OpenXR' -ForegroundColor Gray;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  The publisher tests the Steam release of PowerWash Simulator 2.' -ForegroundColor White
        Write-Host '  Epic and Xbox / Microsoft Store folders can be detected, but' -ForegroundColor Yellow
        Write-Host '  those builds remain publisher-unverified. The first game is unsupported.' -ForegroundColor Yellow
        Write-Host '  Setup adds MelonLoader, portable .NET 6 and Unity OpenXR' -ForegroundColor White
        Write-Host '  through a recoverable ownership transaction.' -ForegroundColor White;Write-Host ''
        Write-Host '  Antivirus software may inspect runtime DLLs. Setup verifies' -ForegroundColor Yellow
        Write-Host '  required files after copying and reports missing files without' -ForegroundColor Yellow
        Write-Host '  assuming the cause.' -ForegroundColor Yellow;Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this information, press Enter to proceed...')

        Write-WRStep 1 5 'Locating PowerWash Simulator 2'
        $game=Get-WRGameRoot;if(-not $game){throw 'Setup cancelled before any game file was changed.'}
        if(Get-Process -Name 'PowerWash Simulator 2' -ErrorAction SilentlyContinue){throw 'PowerWash Simulator 2 is running. Close it completely and retry.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Run setup as administrator, then retry.'}
        Write-WROK "Found: $game"

        Write-WRStep 2 5 'Getting Wet Reality and its publisher-pinned runtimes'
        $release=Get-WRRelease;if(-not(Test-IsTrackableInstalledVersion $release.Tag)){throw 'GitHub did not provide a trackable prerelease version.'}
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_wetreality_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $downloads=@(
            @('WetReality.zip',$release.Url,"Wet Reality $($release.Tag)",$release.PageUrl),
            @('MelonLoader.zip',$MELON_URL,'MelonLoader 0.7.3','https://github.com/LavaGang/MelonLoader/releases/tag/v0.7.3'),
            @('dotnet.zip',$DOTNET_URL,'portable .NET 6.0.36','https://dotnet.microsoft.com/download/dotnet/6.0'),
            @('openxr.tgz',$OPENXR_URL,'Unity OpenXR 1.18.0','https://docs.unity3d.com/Packages/com.unity.xr.openxr@1.18/manual/index.html')
        )
        foreach($item in $downloads){$dest=Join-Path $work $item[0];$ok=Invoke-SafeDownload -Urls @($item[1]) -Destination $dest -Label $item[2] -ManualUrl $item[3] -AllowSkip $false;if(-not($ok -eq $true -or [string]$ok -in @('retry','manual'))){throw "$($item[2]) was not downloaded."}}
        $extract=Join-Path $work 'publisher';if([string](Expand-ArchiveOrFallback -ArchivePath (Join-Path $work 'WetReality.zip') -DestinationFolder $extract -Label 'Wet Reality release' -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')){throw 'The Wet Reality release could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'mod\WetReality.Pose.dll'
        $stage=New-WRInstallStage -PublisherRoot $payload -MelonArchive (Join-Path $work 'MelonLoader.zip') -DotnetArchive (Join-Path $work 'dotnet.zip') -OpenXrArchive (Join-Path $work 'openxr.tgz') -GameRoot $game -Stage (Join-Path $work 'stage') -Scratch $work
        Write-WROK "Wet Reality $($release.Tag) and complete runtime stage verified."

        Write-WRStep 3 5 'Preparing a recoverable game-folder transaction'
        $snapshot=Save-WRSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback');$changesStarted=$true
        Write-WROK 'Existing files and earlier Hub ownership are recoverable.'

        Write-WRStep 4 5 'Installing and checking Wet Reality XR'
        Write-WRInfo 'This can take a few minutes while the portable runtime is copied.'
        Write-WRInfo 'The live file counter below means setup is still actively working.'
        Install-WROwnedPayload -GameRoot $game -Stage $stage -Version $release.Tag -Receipt (Join-Path $PSScriptRoot '.installed_path');$changesStarted=$false
        Write-WROK 'Motion-control mod and runtime files survived the post-copy check.'

        Write-WRStep 5 5 'Finishing setup'
        Write-WROK "Wet Reality $($release.Tag) is installed and tracked.";Write-Host ''
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor White
        Write-Host '  2. If needed, use the normal launcher for your game store.' -ForegroundColor White
        Write-Host '  Keep your OpenXR headset software running before launch.' -ForegroundColor Gray
        Write-Host '  First launch can remain quiet for about 30 seconds.' -ForegroundColor Yellow
        Write-Host '  Remove UnityExplorer from Mods; it prevents menu selection.' -ForegroundColor Yellow
        Write-Host '  Settings and quick guide: WetRealityXR\Configurator.cmd' -ForegroundColor Gray;Write-Host ''
        Write-Host "  $QUIP" -ForegroundColor Magenta;Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changesStarted -and $game -and $snapshot){try{Restore-WRSnapshot -GameRoot $game -Snapshot $snapshot;Write-WRWarn 'The previous PowerWash Simulator 2 folder state was restored.'}catch{Write-WRWarn ('Rollback also needs attention: '+$_.Exception.Message)}}
        throw
    }finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}

if(((''+$env:PCVR_WR_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-PowerWashSimulator2VRInstaller}

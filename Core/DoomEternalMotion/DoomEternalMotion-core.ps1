param([Alias('InstallerChoice')][ValidateSet('','argent','eternal')][string]$Mod='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='DOOM Eternal Motion VR Installer'
$script:GameId='doom-eternal-motion-vr'
$script:GameTitle='DOOM Eternal VR - Motion'
$script:Quip='Rip and tear. The chainsaw finally has a reach of its own.'
$script:Slots=@{
    argent=@{Name='KHARVOX: ARGENT';Repo='CactusVRStudios/KHARVOX-ARGENT';Pattern='(?i)^ARGENT-[0-9].*\.zip$';Tag='v1.01a';Folder='ARGENT';Launcher='ArgentLauncher.exe';Identity='doomargent';Receipt='.installed_path_a';State='mod_a_path';VersionSlot='Primary';Required=@('ArgentLauncher.exe','ArgentLayer.dll','ArgentLayer.json','openxr_loader.dll','build-info.json')}
    eternal=@{Name='EternalVR';Repo='ArcadaLabs-Jason/EternalVR';Pattern='(?i)^EternalVR-alpha-[0-9].*\.zip$';Tag='v0.1.62';Folder='EternalVR';Launcher='EternalVR.Launcher.exe';Identity='doometernalvr';Receipt='.installed_path_b';State='mod_b_path';VersionSlot='Secondary';Required=@('EternalVR.Launcher.exe','EternalVR.Launcher.Core.dll','BUILD-INFO.txt','layer\EternalVR.dll','layer\openxr_loader.dll','layer\VK_LAYER_ETERNALVR.json')}
}

function Test-DoomEternalGame([string]$Root){return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'DOOMEternalx64vk.exe') -PathType Leaf))}
function Get-DoomEternalGame {
    $test=(''+$env:PCVR_DOOMETERNAL_TEST_GAME).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){if(Test-DoomEternalGame $test){return (Get-Item -LiteralPath $test).FullName};throw 'The isolated DOOM Eternal test game is incomplete.'}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @('base_game_path','user_located') -ProbeFiles @('DOOMEternalx64vk.exe')
    if(Test-DoomEternalGame $saved){return (Get-Item -LiteralPath $saved).FullName}
    $found=Find-SteamGameFolder -AppId '782330' -SteamFolderNames @('DOOMEternal') -ProbeExe 'DOOMEternalx64vk.exe' -HubGameId $script:GameId
    if(Test-DoomEternalGame $found){return (Get-Item -LiteralPath $found).FullName}
    foreach($candidate in @('C:\XboxGames\Doom Eternal - PC\Content','C:\XboxGames\DOOM Eternal\Content','C:\Program Files\WindowsApps\BethesdaSoftworks.DOOMEternal-PC')){if(Test-DoomEternalGame $candidate){return (Get-Item -LiteralPath $candidate).FullName}}
    $manual=Get-GameFolderInteractive -GameName 'DOOM Eternal' -ProbeFile 'DOOMEternalx64vk.exe' -ManualUrl 'https://store.steampowered.com/app/782330/'
    if(Test-DoomEternalGame $manual){return (Get-Item -LiteralPath $manual).FullName}
    return $null
}
function Assert-DoomSlotTarget([string]$Path,[hashtable]$Slot){
    $full=[IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
    if((Split-Path -Leaf $full) -cne [string]$Slot.Folder -or (Split-Path -Leaf (Split-Path -Parent $full)) -cne 'DOOM Eternal VR'){throw 'The selected VR slot must be inside a DOOM Eternal VR folder.'}
    if(Test-Path -LiteralPath $full){$item=Get-Item -LiteralPath $full -Force;if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'A linked VR slot folder cannot be changed safely.'}}
    return $full
}
function Get-DoomSlotTarget([hashtable]$Slot){
    $test=(''+$env:PCVR_DOOMETERNAL_TEST_TARGET).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){return (Assert-DoomSlotTarget -Path (Join-Path $test ([string]$Slot.Folder)) -Slot $Slot)}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @([string]$Slot.State) -ProbeFiles @()
    if($saved){try{return (Assert-DoomSlotTarget -Path $saved -Slot $Slot)}catch{}}
    foreach($base in @('C:\Games','D:\Games','E:\Games')){
        try{
            [void][IO.Directory]::CreateDirectory($base)
            $probe=Join-Path $base ('.pcvr-doom-write-'+[Guid]::NewGuid().ToString('N'))
            [IO.File]::WriteAllText($probe,'ok');Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
            return (Assert-DoomSlotTarget -Path (Join-Path (Join-Path $base 'DOOM Eternal VR') ([string]$Slot.Folder)) -Slot $Slot)
        }catch{}
    }
    throw 'No standard Games folder is writable. Create a writable C:\Games, D:\Games or E:\Games folder and retry.'
}
function Get-DoomRelease([string]$Key,[hashtable]$Slot){
    $local=if($Key -eq 'argent'){(''+$env:PCVR_DOOMETERNAL_TEST_ARGENT_ARCHIVE).Trim()}else{(''+$env:PCVR_DOOMETERNAL_TEST_ETERNAL_ARCHIVE).Trim()}
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $local){$testTag=(''+$env:PCVR_DOOMETERNAL_TEST_EXPECTED_TAG).Trim();return [pscustomobject]@{Tag=$(if($testTag){$testTag}else{[string]$Slot.Tag});Url=$local;PageUrl=('https://github.com/'+$Slot.Repo+'/releases');Local=$true}}
    $args=@{Repo=[string]$Slot.Repo;IncludePrerelease=($Key -eq 'eternal');AssetPatterns=@([string]$Slot.Pattern);SkipReleasesWithoutMatchingAsset=$true}
    if($env:PCVR_DOOMETERNAL_TEST_RELEASE_JSON){$args.ReleaseData=Get-Content -LiteralPath $env:PCVR_DOOMETERNAL_TEST_RELEASE_JSON -Raw|ConvertFrom-Json}
    $release=Resolve-GitHubReleaseAsset @args
    if(-not $release.Resolved -or -not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){
        Write-Host "  [!!] The current $($Slot.Name) release could not be checked on GitHub." -ForegroundColor Yellow
        return [pscustomobject]@{Tag='';Url='';PageUrl=('https://github.com/'+$Slot.Repo+'/releases');Local=$false;Manual=$true}
    }
    return [pscustomobject]@{Tag=[string]$release.Tag;Url=[string]$release.Url;PageUrl=[string]$release.PageUrl;Local=$false;Manual=$false}
}
function Get-DoomManualArchive([string]$Key,[hashtable]$Slot,[string]$Destination){
    $page='https://github.com/'+$Slot.Repo+'/releases';$pattern=if($Key -eq 'eternal'){'EternalVR-alpha-*.zip'}else{'ARGENT-*.zip'}
    $declined='';$opened=$false
    while($true){
        $folders=if($env:PCVR_DOOMETERNAL_TEST_DOWNLOADS){@($env:PCVR_DOOMETERNAL_TEST_DOWNLOADS)}else{@()}
        $file=Find-PCVRDownloadedCandidate -Patterns @($pattern) -Folders $folders
        if($file -and $file -ne $declined -and (Test-DownloadedPayload -Path $file -IntendedPath $Destination)){
            $leaf=[IO.Path]::GetFileName($file)
            $match=if($Key -eq 'eternal'){[regex]::Match($leaf,'(?i)^EternalVR-alpha-(\d+(?:\.\d+)+)-[a-f0-9]+\.zip$')}else{[regex]::Match($leaf,'(?i)^ARGENT-(\d+(?:\.\d+)*[a-z]?)\.zip$')}
            if($match.Success){
                $tag='v'+$match.Groups[1].Value;Write-Host "  Found in Downloads: $file" -ForegroundColor Cyan
                Write-Host "  GitHub could not confirm the newest release. This ZIP is $tag; a newer one may exist." -ForegroundColor Yellow
                if((Read-Host '  Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $file -Destination $Destination -Force;return [pscustomobject]@{Tag=$tag;Url=$file;PageUrl=$page;Local=$true}}
                $declined=$file
            }
        }
        if(-not $opened){Write-Host "  Download the current $($Slot.Name) ZIP from the official release page." -ForegroundColor White;[void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to open the publisher releases page...');$opened=$true}
        [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
        $file=Find-PCVRDownloadedCandidate -Patterns @($pattern) -Folders $folders
        if($file -and $file -ne $declined){continue}
        $raw=(Read-Host '  Drag the ZIP here, or press Enter to reopen the page').Trim().Trim('"').Trim("'")
        if($raw -and (Test-Path -LiteralPath $raw -PathType Leaf)){
            $leaf=[IO.Path]::GetFileName($raw)
            $match=if($Key -eq 'eternal'){[regex]::Match($leaf,'(?i)^EternalVR-alpha-(\d+(?:\.\d+)+)-[a-f0-9]+\.zip$')}else{[regex]::Match($leaf,'(?i)^ARGENT-(\d+(?:\.\d+)*[a-z]?)\.zip$')}
            if($match.Success -and (Test-DownloadedPayload -Path $raw -IntendedPath $Destination)){
                $tag='v'+$match.Groups[1].Value;Write-Host "  Selected: $raw" -ForegroundColor Cyan
                if((Read-Host '  Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $raw -Destination $Destination -Force;return [pscustomobject]@{Tag=$tag;Url=$raw;PageUrl=$page;Local=$true}}
                $declined=$raw
            }else{Write-Host '  Choose the official versioned publisher ZIP.' -ForegroundColor Yellow}
        }else{Start-Process $page -ErrorAction Stop|Out-Null}
    }
}
function Get-DoomPayload([string]$Archive,[string]$Work,[hashtable]$Slot){
    $extract=Join-Path $Work 'release'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $extract -Label ([string]$Slot.Name) -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The publisher ZIP could not be extracted.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile ([string]$Slot.Launcher)
    if(-not $payload){throw 'The ZIP contains no supported Windows launcher.'}
    foreach($relative in @($Slot.Required)){if(-not(Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)){throw "The publisher ZIP is missing $relative."}}
    return $payload
}
function Assert-DoomPayloadVersion([string]$Payload,[string]$Key,[string]$ReleaseTag,[string]$Target){
    $selected=$ReleaseTag.TrimStart([char[]]'vV')
    if($Key -eq 'eternal'){
        $info=Get-Content -LiteralPath (Join-Path $Payload 'BUILD-INFO.txt') -Raw -ErrorAction Stop
        $match=[regex]::Match($info,'(?im)^EternalVR alpha ([0-9]+(?:\.[0-9]+)+)\s*$')
        $actual=if($match.Success){$match.Groups[1].Value}else{''}
        if(-not $actual -or $actual -ne $selected){throw "EternalVR package version $actual does not match selected release $ReleaseTag. No VR files were changed."}
        $installed=Join-Path $Target 'BUILD-INFO.txt'
        if(Test-Path -LiteralPath $installed -PathType Leaf){
            $prior=[regex]::Match((Get-Content -LiteralPath $installed -Raw -ErrorAction Stop),'(?im)^EternalVR alpha ([0-9]+(?:\.[0-9]+)+)\s*$')
            if($prior.Success -and [version]$prior.Groups[1].Value -gt [version]$actual){throw "EternalVR $($prior.Groups[1].Value) is already installed. The older $ReleaseTag package cannot replace it."}
        }
    }else{
        $info=Get-Content -LiteralPath (Join-Path $Payload 'build-info.json') -Raw -ErrorAction Stop | ConvertFrom-Json
        $actual=[string]$info.release
        if($actual -cne ('ARGENT-'+$selected)){throw "ARGENT package version $actual does not match selected release $ReleaseTag. No VR files were changed."}
    }
}
function Save-DoomSlotSnapshot([string]$Target,[string]$Snapshot){
    [void][IO.Directory]::CreateDirectory($Snapshot)
    $exists=Test-Path -LiteralPath $Target -PathType Container
    if($exists){foreach($item in @(Get-ChildItem -LiteralPath $Target -Force -ErrorAction Stop)){Copy-Item -LiteralPath $item.FullName -Destination $Snapshot -Recurse -Force -ErrorAction Stop}}
    return [pscustomobject]@{Exists=$exists;Root=$Snapshot}
}
function Restore-DoomSlotSnapshot([string]$Target,[hashtable]$Slot,$Snapshot){
    $full=Assert-DoomSlotTarget -Path $Target -Slot $Slot
    if(Test-Path -LiteralPath $full -PathType Container){Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop}
    if($Snapshot.Exists){[void][IO.Directory]::CreateDirectory($full);foreach($item in @(Get-ChildItem -LiteralPath $Snapshot.Root -Force -ErrorAction Stop)){Copy-Item -LiteralPath $item.FullName -Destination $full -Recurse -Force -ErrorAction Stop}}
}
function Invoke-DoomEternalMotionInstaller {
    $work=$null;$target=$null;$slot=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' DOOM Eternal VR - Motion - Installer' -ForegroundColor Cyan
        Write-Host ' Two separate OpenXR launchers for one licensed retail game' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' [1] KHARVOX: ARGENT - roomscale and separate hands' -ForegroundColor Green
        Write-Host ' [2] EternalVR - roomscale and joined arms (alpha)' -ForegroundColor White
        Write-Host ' Both can remain installed. The chosen Hub Play button opens' -ForegroundColor Gray
        Write-Host ' only its launcher; setup does not switch active mods.' -ForegroundColor Gray
        Write-Host ' Run DOOM Eternal flat and sign in before the first VR launch.' -ForegroundColor Yellow
        Write-Host ' Close the retail game and both launchers before installing.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        while(-not $Mod){$choice=(''+(Read-Host 'Choose 1, 2 or Q')).Trim().ToLowerInvariant();if($choice -eq '1'){$Mod='argent'}elseif($choice -eq '2'){$Mod='eternal'}elseif($choice -in @('q','quit')){return}else{Write-Host ' Choose [1], [2] or [Q].' -ForegroundColor Yellow}}
        $slot=$script:Slots[$Mod]
        Write-Host ''
        Write-Host " Selected: $($slot.Name). The publisher package stays outside the retail game." -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate DOOM Eternal and download the selected release...')
        $game=Get-DoomEternalGame
        if(-not(Test-DoomEternalGame $game)){throw 'A licensed DOOM Eternal folder with DOOMEternalx64vk.exe is required.'}
        if(Get-Process -Name @('DOOMEternalx64vk','ArgentLauncher','EternalVR.Launcher') -ErrorAction SilentlyContinue){throw 'Close DOOM Eternal and both VR launchers before setup.'}
        Write-Host "  [OK] Retail game: $game" -ForegroundColor Green
        $target=Get-DoomSlotTarget -Slot $slot
        Write-Host "  [..] Separate $($slot.Name) folder: $target" -ForegroundColor Gray
        $release=Get-DoomRelease -Key $Mod -Slot $slot
        $handover=Get-PCVRRecoveryInput -PathType Leaf
        if($handover){
            $leaf=[IO.Path]::GetFileName($handover)
            $match=if($Mod -eq 'eternal'){[regex]::Match($leaf,'(?i)^EternalVR-alpha-(\d+(?:\.\d+)+)-[a-f0-9]+\.zip$')}else{[regex]::Match($leaf,'(?i)^ARGENT-(\d+(?:\.\d+)*[a-z]?)\.zip$')}
            if(-not $match.Success){throw "Choose the official versioned $($slot.Name) ZIP."}
            $version='v'+$match.Groups[1].Value
            if(-not $release.Manual -and $version -ine [string]$release.Tag){throw "The selected ZIP is $version; GitHub reports $($release.Tag). Download that version instead."}
            Write-Host "  Selected publisher ZIP: $handover ($version)" -ForegroundColor Cyan
            if($release.Manual -and (Read-Host '  GitHub version unavailable. Use this ZIP? Y/N').Trim() -notmatch '^(?i:y|yes)$'){throw 'Publisher version was not confirmed.'}
            $release=[pscustomobject]@{Tag=$version;Url=$handover;Local=$true;Manual=$false}
        }
        $env:PCVR_HUB_RECOVERY_PAGE='https://github.com/'+$slot.Repo+'/releases'
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_doom_motion_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'publisher.zip'
        if($release.Manual){$release=Get-DoomManualArchive -Key $Mod -Slot $slot -Destination $archive}
        elseif($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{
            $download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "$($slot.Name) $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
            if(-not($download -eq $true -or [string]$download -in @('retry','manual'))){throw 'The selected publisher release was not downloaded.'}
        }
        $payload=Get-DoomPayload -Archive $archive -Work $work -Slot $slot
        Assert-DoomPayloadVersion -Payload $payload -Key $Mod -ReleaseTag ([string]$release.Tag) -Target $target
        $snapshot=Save-DoomSlotSnapshot -Target $target -Snapshot (Join-Path $work 'rollback')
        [void][IO.Directory]::CreateDirectory($target)
        $changed=$true
        $keep=if($Mod -eq 'argent'){@('hand_models.cfg','hand_pose_calibration_default.cfg','weapon_pose_calibration_default.cfg')}else{@()}
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity ([string]$slot.Identity) -AdoptIdenticalExisting -KeepExistingRelativePaths $keep -ReplaceChangedOwnedRelativePaths @('ArgentLayer.json'))
        $watch=@($slot.Required | ForEach-Object {Join-Path $target $_})
        $recopy={ [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity ([string]$slot.Identity) -AdoptIdenticalExisting -KeepExistingRelativePaths $keep -ReplaceChangedOwnedRelativePaths @('ArgentLayer.json')) }.GetNewClosure()
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $target -Recopy $recopy)){throw 'The required launcher files did not survive the post-copy check.'}
        $required=@($slot.Required)+@('.pcvrhub_'+$slot.Identity+'_ownership.csv')
        $contract=New-PCVRInstallerContract -Id ($script:GameId+'-'+$Mod) -GameName ([string]$slot.Name) -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ([string]$release.PageUrl) -RequiredInstalledFileGroups $required
        if(-not(Save-HubRememberedGameFolder -GameId $script:GameId -Title $script:GameTitle -GameDir $game -ProbeFiles @('DOOMEternalx64vk.exe') -StateName 'base_game_path')){throw 'The proven retail game path could not be remembered.'}
        if(-not(Save-HubRememberedGameFolder -GameId $script:GameId -Title $script:GameTitle -GameDir $target -ProbeFiles @([string]$slot.Launcher) -StateName ([string]$slot.State))){throw 'The selected launcher path could not be remembered.'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version ([string]$release.Tag) -VersionSlot ([string]$slot.VersionSlot) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot ([string]$slot.Receipt))) -Route Current)
        $changed=$false
        Write-Host "  [OK] $($slot.Name) $($release.Tag) is installed and tracked." -ForegroundColor Green
        Write-Host '  Start the OpenXR runtime first, then use the matching Hub Play button.' -ForegroundColor White
        Write-Host '  The publisher launcher checks the supported game build and handles its own settings.' -ForegroundColor Gray
        Write-Host ''
        Write-Host "  $script:Quip" -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $target -and $snapshot){try{Restore-DoomSlotSnapshot -Target $target -Slot $slot -Snapshot $snapshot;Write-Host '  [!!] The previous selected VR slot was restored.' -ForegroundColor Yellow}catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}}
        Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red
        throw
    }finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_DOOMETERNAL_LIBRARY_ONLY -ne '1'){Invoke-DoomEternalMotionInstaller}

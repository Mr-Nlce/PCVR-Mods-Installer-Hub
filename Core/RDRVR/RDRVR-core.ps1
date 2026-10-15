$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Red Dead Redemption VR Installer'
$script:RdrId='red-dead-redemption-vr'
$script:RdrReleasePage='https://github.com/Disonomouss/RDRVR/releases'
$script:RdrHookPage='https://www.nexusmods.com/reddeadredemption/mods/192?tab=files'
$script:RdrFiles=@('dinput8.dll','RDRVR.Gameplay.red','RDRVR.ini','RDRVR_click_revolver.wav','RDRVR_click_rifle.wav','RDRVR_click_shotgun.wav')
$script:RdrProof=@($script:RdrFiles + @('RedHook.dll','winmm.dll','RedHook.ini','.pcvrhub_rdrvr_ownership.csv'))
$script:RdrContract=New-PCVRInstallerContract -Id $script:RdrId -GameName 'Red Dead Redemption VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:RdrReleasePage -RequiredInstalledFileGroups $script:RdrProof

function Assert-RdrFixture([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path)
    if($env:PCVR_HUB_TEST_MODE -eq '1') {
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'rdrvr-fixture.txt') -PathType Leaf)) {
            throw 'RDRVR test paths must stay in an isolated temporary fixture.'
        }
    }
    return $full
}
function Test-RdrGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'RDR.exe') -PathType Leaf))
}
function Get-RdrGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_GAME) {
        $test=Assert-RdrFixture $env:PCVR_RDR_TEST_GAME
        if(-not(Test-RdrGame $test)){throw 'The RDRVR fixture lacks RDR.exe.'}
        return $test
    }
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        $old=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
        if(Test-RdrGame $old){return ([IO.Path]::GetFullPath($old))}
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:RdrId -StateNames @('installed_path','base_game_path','user_located') -ProbeFiles @('RDR.exe')
    if(Test-RdrGame $saved){return ([IO.Path]::GetFullPath($saved))}
    $steam=Find-SteamGameFolder -AppId '2668510' -SteamFolderNames @('Red Dead Redemption') -ProbeExe 'RDR.exe' -HubGameId $script:RdrId
    if(Test-RdrGame $steam){return ([IO.Path]::GetFullPath($steam))}
    foreach($path in @('C:\Program Files\Rockstar Games\Red Dead Redemption','C:\Program Files (x86)\Rockstar Games\Red Dead Redemption')){
        if(Test-RdrGame $path){return $path}
    }
    $picked=Get-GameFolderInteractive -GameName 'Red Dead Redemption (Steam or Rockstar Games Launcher)' -ProbeFile 'RDR.exe' `
        -ManualUrl 'https://store.steampowered.com/app/2668510/'
    if(Test-RdrGame $picked){return ([IO.Path]::GetFullPath($picked))}
    return $null
}
function Get-RdrRelease([object]$ReleaseData=$null) {
    if($null -eq $ReleaseData -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_RELEASE_JSON){
        $ReleaseData=Get-Content -LiteralPath (Assert-RdrFixture $env:PCVR_RDR_TEST_RELEASE_JSON) -Raw | ConvertFrom-Json
    }
    $args=@{Repo='Disonomouss/RDRVR';IncludePrerelease=$true;AssetPatterns=@('(?i)^RDRVR-\d+(?:\.\d+){2}\.zip$');SkipReleasesWithoutMatchingAsset=$true}
    if($null -ne $ReleaseData){$args.ReleaseData=$ReleaseData}
    $result=Resolve-GitHubReleaseAsset @args
    if(-not $result.Resolved -or [string]$result.AssetName -notmatch '(?i)^RDRVR-(\d+(?:\.\d+){2})\.zip$'){
        throw "No usable RDRVR Windows release was found: $($result.Error)"
    }
    return [pscustomobject]@{Version=$Matches[1];Name=[string]$result.AssetName;Url=[string]$result.Url;PageUrl=[string]$result.PageUrl;Local=$false}
}
function Get-RdrLocalRelease([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path.Trim().Trim('"'))
    if(-not(Test-Path -LiteralPath $full -PathType Leaf)){throw 'The chosen RDRVR ZIP does not exist.'}
    $name=[IO.Path]::GetFileName($full)
    if($name -notmatch '(?i)^RDRVR-(\d+(?:\.\d+){2})(?:-publisher)?\.zip$'){
        throw 'Select the versioned RDRVR publisher ZIP.'
    }
    return [pscustomobject]@{Version=$Matches[1];Name=$name;Url=$full;PageUrl=$script:RdrReleasePage;Local=$true}
}
function Test-RdrHookConfig([string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return $false}
    $inSection=$false;$setting=$null
    foreach($line in [IO.File]::ReadAllLines($Path)){
        if($line -match '^\s*\[([^]]+)\]'){$inSection=$Matches[1] -ieq 'DirectXHook';continue}
        if($inSection -and $line -match '^\s*Disabled\s*=\s*(true|false)\s*(?:[;#].*)?$'){
            $setting=($Matches[1] -ieq 'true')
        }
    }
    return [bool]$setting
}
function Get-RdrHookStage([string]$Archive,[string]$Work) {
    $full=[IO.Path]::GetFullPath($Archive.Trim().Trim('"'))
    if(-not(Test-Path -LiteralPath $full -PathType Leaf)){throw 'The selected RedHook archive does not exist.'}
    if(-not(Test-DownloadedPayload -Path $full -IntendedPath 'RedHook.zip')){throw 'The selected RedHook file is not a usable archive.'}
    $expanded=Join-Path $Work 'redhook-expanded'
    Write-Host '  [..] Opening RedHook; this may take a few seconds.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $full -DestinationFolder $expanded -Label 'RedHook' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'RedHook could not be extracted.'}
    $root=Get-ExtractedPayloadRoot -ExtractDir $expanded -RelModFile 'RedHook.dll'
    if(-not $root){throw 'RedHook.dll is missing from the selected archive.'}
    foreach($name in @('RedHook.dll','winmm.dll','RedHook.ini')){
        if(-not(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)){throw "RedHook archive lacks $name."}
    }
    $stage=Join-Path $Work 'redhook-stage';[void][IO.Directory]::CreateDirectory($stage)
    foreach($name in @('RedHook.dll','winmm.dll','RedHook.ini')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $stage $name) -Force}
    $ini=Join-Path $stage 'RedHook.ini'
    $lines=[IO.File]::ReadAllLines($ini);$inSection=$false;$found=$false
    for($index=0;$index -lt $lines.Length;$index++){
        if($lines[$index] -match '^\s*\[([^]]+)\]'){$inSection=$Matches[1] -ieq 'DirectXHook';continue}
        if($inSection -and $lines[$index] -match '^(\s*Disabled\s*=\s*)(true|false)(\s*(?:[;#].*)?)$'){
            $lines[$index]=$Matches[1]+'true'+$Matches[3];$found=$true;break
        }
    }
    if(-not $found){throw 'RedHook.ini lacks the expected DirectXHook setting.'}
    [IO.File]::WriteAllLines($ini,$lines)
    if(-not(Test-RdrHookConfig $ini)){throw 'RedHook DirectXHook must be disabled for RDRVR.'}
    return $stage
}
function Get-RdrHookArchive([scriptblock]$ReadInput=$null,[scriptblock]$OpenPage=$null) {
    $fixture=(''+$env:PCVR_RDR_TEST_REDHOOK).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){
        if(-not(Test-Path -LiteralPath $fixture -PathType Leaf)){throw 'The RedHook test archive is missing.'}
        return (Get-Item -LiteralPath $fixture).FullName
    }
    $downloads=Get-PCVRDownloadsFolder
    $offerFound=$true
    while($true){
        $candidate=$null
        if($offerFound -and $downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
            $candidate=Get-ChildItem -LiteralPath $downloads -Filter '*RedHook*.zip' -File -ErrorAction SilentlyContinue |
                Where-Object { Test-DownloadedPayload -Path $_.FullName -IntendedPath 'RedHook.zip' } |
                Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        }
        if($candidate){
            Write-Host ''
            Write-Host " Found in your registered Downloads folder: $($candidate.FullName)" -ForegroundColor Cyan
            while($true){
                $raw=if($ReadInput){& $ReadInput 'Use this archive? [Y/N]'}else{Read-Host 'Use this archive? [Y/N]'}
                if($null -eq $raw){return $null}
                $answer=(''+$raw).Trim().ToUpperInvariant()
                if($answer -in @('Y','YES')){return $candidate.FullName}
                if($answer -in @('N','NO')){$offerFound=$false;break}
                Write-Host ' Please answer Y or N.' -ForegroundColor Yellow
            }
        }
        Write-Host ''
        if($offerFound){Write-Host ' RedHook v0.8: download the main ZIP from Nexus.' -ForegroundColor White}
        Write-Host ' Drag the RedHook ZIP here or paste its full path.' -ForegroundColor White
        $raw=if($ReadInput){& $ReadInput 'ZIP path (Enter: open Nexus, Q: cancel)'}else{Read-Host 'ZIP path (Enter: open Nexus, Q: cancel)'}
        if($null -eq $raw){return $null}
        $answer=(''+$raw).Trim().Trim('"').Trim("'")
        if($answer -ieq 'Q'){return $null}
        if(-not $answer){
            Write-Host ' On Nexus, choose the v0.8 main file and click Manual download.' -ForegroundColor White
            Write-Host " Nexus Files: $script:RdrHookPage" -ForegroundColor Gray
            if($OpenPage){& $OpenPage $script:RdrHookPage | Out-Null}
            elseif($env:PCVR_HUB_TEST_MODE -ne '1'){
                try{Start-Process $script:RdrHookPage -ErrorAction Stop | Out-Null}
                catch{Write-Host ' Browser could not open. Use the Nexus Files link above.' -ForegroundColor Yellow}
            }
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter after the RedHook ZIP download is complete...' -ReadInput $ReadInput)
            $offerFound=$true
            continue
        }
        if(-not(Test-Path -LiteralPath $answer -PathType Leaf)){
            Write-Host ' This file does not exist. Drag the ZIP here or paste its full path.' -ForegroundColor Yellow
            continue
        }
        if([IO.Path]::GetExtension($answer) -ine '.zip' -or
            -not(Test-DownloadedPayload -Path $answer -IntendedPath 'RedHook.zip')){
            Write-Host ' This is not a usable ZIP. Choose the RedHook main file.' -ForegroundColor Yellow
            continue
        }
        return (Get-Item -LiteralPath $answer).FullName
    }
}
function Get-RdrModStage([string]$Archive,[string]$Work,[string]$ExpectedVersion) {
    if(-not(Test-DownloadedPayload -Path $Archive -IntendedPath 'RDRVR.zip')){throw 'The RDRVR download is not a usable ZIP.'}
    $expanded=Join-Path $Work 'rdrvr-expanded'
    Write-Host '  [..] Opening the RDRVR package; this may take a few seconds.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'RDRVR' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'RDRVR could not be extracted.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $expanded -RelModFile 'payload\RDRVR.Gameplay.red'
    if(-not $payload){throw 'The package has no RDRVR gameplay payload.'}
    $source=Join-Path $payload 'payload'
    foreach($name in $script:RdrFiles){if(-not(Test-Path -LiteralPath (Join-Path $source $name) -PathType Leaf)){throw "RDRVR package lacks $name."}}
    $versionFile=Join-Path $source 'RDRVR_version.txt'
    if(-not(Test-Path -LiteralPath $versionFile -PathType Leaf)){throw 'The publisher package lacks a version file.'}
    $version=([IO.File]::ReadAllText($versionFile)).Trim()
    if($version -match '^v?(\d+(?:\.\d+){2})$'){$version=$Matches[1]}
    if(-not(Test-IsTrackableInstalledVersion $version) -or $version -ne $ExpectedVersion){throw 'The RDRVR package version does not match its selected release.'}
    $stage=Join-Path $Work 'rdrvr-stage';[void][IO.Directory]::CreateDirectory($stage)
    foreach($name in $script:RdrFiles){Copy-Item -LiteralPath (Join-Path $source $name) -Destination (Join-Path $stage $name) -Force}
    return $stage
}
function Save-RdrSnapshot([string]$Game,[string[]]$StageFiles,[string]$Backup) {
    [void][IO.Directory]::CreateDirectory($Backup)
    $names=[Collections.Generic.List[string]]::new()
    foreach($name in @($StageFiles)+@('.pcvrhub_rdrvr_ownership.csv','.pcvrhub_rdrvr_ownership.csv.new','.pcvrhub_rdrvrredhook_ownership.csv','.pcvrhub_rdrvrredhook_ownership.csv.new','.pcvrhub_version')){$names.Add($name)}
    foreach($identity in @('rdrvr','rdrvrredhook')){
        $manifest=Join-Path $Game ".pcvrhub_${identity}_ownership.csv"
        if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$names.Add((Assert-PCVROwnedRelativePath $row.RelativePath))}}}
    }
    $records=@()
    foreach($name in @($names|Select-Object -Unique)){
        $src=Join-OwnedRelativePath $Game $name;$exists=Test-Path -LiteralPath $src -PathType Leaf
        $records += [pscustomobject]@{Relative=$name;Exists=$exists}
        if($exists){$dest=Join-OwnedRelativePath (Join-Path $Backup 'files') $name;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath $src -Destination $dest -Force}
    }
    $backupDirs=@{}
    foreach($identity in @('rdrvr','rdrvrredhook')){
        $path=Join-Path $Game ".pcvrhub_${identity}_backup";$had=Test-Path -LiteralPath $path -PathType Container
        $backupDirs[$identity]=$had
        if($had){Copy-Item -LiteralPath $path -Destination (Join-Path $Backup "backup-$identity") -Recurse -Force}
    }
    return [pscustomobject]@{Root=$Backup;Records=$records;BackupDirs=$backupDirs}
}
function Restore-RdrSnapshot([string]$Game,$Snapshot) {
    foreach($record in @($Snapshot.Records)){
        $dest=Join-OwnedRelativePath $Game ([string]$record.Relative)
        if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath (Join-OwnedRelativePath (Join-Path $Snapshot.Root 'files') ([string]$record.Relative)) -Destination $dest -Force}
        elseif(Test-Path -LiteralPath $dest -PathType Leaf){Remove-Item -LiteralPath $dest -Force}
    }
    foreach($identity in @('rdrvr','rdrvrredhook')){
        $dest=Join-Path $Game ".pcvrhub_${identity}_backup"
        if(Test-Path -LiteralPath $dest){Remove-Item -LiteralPath $dest -Recurse -Force}
        if($Snapshot.BackupDirs[$identity]){Copy-Item -LiteralPath (Join-Path $Snapshot.Root "backup-$identity") -Destination $dest -Recurse -Force}
    }
}
function Invoke-RdrInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Red Dead Redemption VR - RDRVR' -ForegroundColor Cyan
        Write-Host ' Steam / Rockstar PC game + RedHook v0.8' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' Close the game first. Steam and Rockstar PC versions are supported.' -ForegroundColor White
        Write-Host ' RedHook v0.8 is a separate Nexus download; sign-in may be required.' -ForegroundColor Yellow
        Write-Host ' Existing RedHook settings are never silently replaced.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate the game...')
        Write-Host '  [..] Checking saved, Steam and Rockstar game locations; this may take a few seconds.' -ForegroundColor Cyan
        $game=Get-RdrGame
        if(-not(Test-RdrGame $game)){
            Write-Host '  A Steam or Rockstar game folder with RDR.exe is required. No files were changed.' -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'A Steam or Rockstar game folder with RDR.exe is required.'}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        if(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_rdrvr_preserved.csv') -PathType Leaf){
            $message='Previously changed RDRVR files were preserved here. Review them before reinstalling.'
            Write-Host "  $message" -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        if(($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_PROCESS_RUNNING -eq '1') -or
            ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'RDR' -ErrorAction SilentlyContinue))){
            Write-Host '  Close Red Dead Redemption before setup. No files were changed.' -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'Close Red Dead Redemption before setup.'}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){
            $message='The game folder is not writable. Restart the Hub as administrator for this game, then retry.'
            Write-Host "  $message" -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        $hookPresent=@('RedHook.dll','winmm.dll','RedHook.ini')|Where-Object{Test-Path -LiteralPath (Join-Path $game $_) -PathType Leaf}
        $needsHook=$hookPresent.Count -eq 0
        if($hookPresent.Count -gt 0 -and $hookPresent.Count -ne 3){
            $message='RedHook is incomplete. Repair it from the Nexus main file before installing RDRVR.'
            Write-Host "  $message" -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        $existingIni=Join-Path $game 'RedHook.ini'
        while(-not $needsHook -and -not(Test-RdrHookConfig $existingIni)){
            Write-Host '  Existing RedHook.ini needs [DirectXHook] Disabled=true.' -ForegroundColor Yellow
            Write-Host "  File: $existingIni" -ForegroundColor White
            Write-Host '  The Hub will not change your existing RedHook settings.' -ForegroundColor White
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'Set [DirectXHook] Disabled=true in the existing RedHook.ini, then retry. Your existing settings were not changed.'}
            $raw=Read-Host 'After editing press Enter to recheck, O to open the file, or Q to quit'
            if($null -eq $raw -or (''+$raw).Trim().ToUpperInvariant() -eq 'Q'){return}
            if((''+$raw).Trim().ToUpperInvariant() -eq 'O'){
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open RedHook.ini in Notepad...')
                Start-Process -FilePath 'notepad.exe' -ArgumentList ('"'+$existingIni+'"') -ErrorAction Stop
            }
        }
        $hookArchive=$null
        if($needsHook){$hookArchive=Get-RdrHookArchive;if(-not $hookArchive){return}}
        $tempChoice=Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes 33554432L
        if(-not $tempChoice.BasePath){throw 'No writable temporary location has enough free space.'}
        $work=New-PCVRInstallerTempSession -BasePath $tempChoice.BasePath
        $hookStage=$null
        if($needsHook){$hookStage=Get-RdrHookStage -Archive $hookArchive -Work $work}
        Write-Host ''
        Write-Host ' The Hub checks the latest RDRVR GitHub release, including prereleases.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to choose the RDRVR package...')
        $handover=Get-PCVRRecoveryInput -PathType Leaf
        $choice=if($handover){'L'}else{(''+(Read-Host 'Press Enter for GitHub, L for your downloaded ZIP, or Q to quit')).Trim().ToUpperInvariant()}
        if($choice -eq 'Q'){return}
        if($choice -eq 'L'){
            if(-not $handover){$handover=(''+(Read-Host 'Paste the full path of your downloaded RDRVR ZIP')).Trim()}
            $release=Get-RdrLocalRelease $handover
        }elseif($choice -eq ''){
            Write-Host '  [..] Checking GitHub releases; this may take a few seconds.' -ForegroundColor Cyan
            $release=Get-RdrRelease
        }else{throw 'Choose Enter, L or Q.'}
        $archive=Join-Path $work $release.Name
        Write-Host '  [..] Preparing the publisher ZIP; download may take a little time.' -ForegroundColor Cyan
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force}
        else{
            $download=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "RDRVR $($release.Version)" -ManualUrl $release.PageUrl -AllowSkip $false
            if(-not($download -eq $true -or [string]$download -in @('retry','manual'))){throw 'RDRVR was not downloaded.'}
        }
        $stage=Get-RdrModStage -Archive $archive -Work $work -ExpectedVersion $release.Version
        $stageFiles=@($script:RdrFiles)+@('RedHook.dll','winmm.dll','RedHook.ini')
        $snapshot=Save-RdrSnapshot -Game $game -StageFiles $stageFiles -Backup (Join-Path $work 'rollback')
        $changed=$true
        if($needsHook){
            Write-Host '  [..] Installing RedHook v0.8; this may take a few seconds.' -ForegroundColor Cyan
            [void](Install-OwnedModPayload -SourceRoot $hookStage -GameRoot $game -Identity 'rdrvrredhook' -ProgressLabel 'Installing RedHook')
        }
        Write-Host '  [..] Installing RDRVR; this may take a few seconds.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'rdrvr' -ProgressLabel 'Installing RDRVR')
        $watch=@($script:RdrProof|ForEach-Object{Join-Path $game $_})
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game)){throw 'Required RDRVR files did not survive the post-copy check.'}
        if(-not(Test-RdrHookConfig (Join-Path $game 'RedHook.ini'))){throw 'RedHook DirectXHook is not disabled.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_RECEIPT){Assert-RdrFixture $env:PCVR_RDR_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        if($env:PCVR_HUB_TEST_MODE -ne '1'){
            if(-not(Save-HubRememberedGameFolder -GameId $script:RdrId -Title 'Red Dead Redemption VR' -GameDir $game -ProbeFiles @('RDR.exe') -StateName 'base_game_path')){throw 'The proven game folder could not be saved.'}
        }
        [void](Complete-PCVRInstallTransaction -Contract $script:RdrContract -GameDir $game -Version $release.Version -Route Current -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host "  [OK] RDRVR $($release.Version) installed." -ForegroundColor Green
        Write-Host '  Start your OpenXR runtime, then launch the game.' -ForegroundColor White
        Write-Host '  RedHook stays installed if you later remove RDRVR.' -ForegroundColor White
        Write-Host ''
        Write-Host '  MANUAL STEP - in the game graphics settings:' -ForegroundColor Yellow
        Write-Host '  Set Depth of Field to OFF before playing in VR.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  The frontier is waiting. Ride into it.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{Restore-RdrSnapshot -Game $game -Snapshot $snapshot;Write-Host '  [..] Previous game files restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host "  [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}
        }
        $message="RDRVR setup did not complete: $($_.Exception.Message)"
        Write-Host "  [X] $message" -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{
        if($work -and -not $keepWork -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
if($env:PCVR_RDR_LIBRARY_ONLY -ne '1'){Invoke-RdrInstaller}

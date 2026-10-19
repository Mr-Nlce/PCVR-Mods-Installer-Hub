$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$script:Id='beyond-two-souls-vr';$script:Repo='adore11s/Beyond-Two-Souls-VR-Mod';$script:Page='https://github.com/adore11s/Beyond-Two-Souls-VR-Mod/releases'
$env:PCVR_HUB_RECOVERY_PAGE=$script:Page
$script:Proof=@('BigFile_PC.dat','dinput8.dll','b2svr.ini','B2S_VR_MOD\files\dinput8.dll','B2S_VR_MOD\files\BUILD.txt','B2S_VR_MOD\tools\b2svr_setup.ps1','B2S_VR_MOD\Play Beyond Two Souls in VR.cmd','.pcvrhub_b2svr_ownership.csv')
$script:Contract=New-PCVRInstallerContract -Id $script:Id -GameName 'Beyond: Two Souls VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:Page -RequiredInstalledFileGroups (@('BeyondTwoSouls_Steam.exe|BeyondTwoSouls.exe')+$script:Proof)
function Test-B2SGame([string]$Root){return [bool]($Root -and ((Test-Path -LiteralPath (Join-Path $Root 'BeyondTwoSouls_Steam.exe') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $Root 'BeyondTwoSouls.exe') -PathType Leaf)) -and (Test-Path -LiteralPath (Join-Path $Root 'BigFile_PC.dat') -PathType Leaf))}
function Assert-B2SFixture([string]$Path){$full=[IO.Path]::GetFullPath($Path);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\';if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'b2s-test-fixture.txt') -PathType Leaf)){throw 'Beyond test game must stay in an isolated temporary fixture.'};return $full}
function Get-B2SGame {
    if($env:PCVR_B2S_TEST_GAME){$test=Assert-B2SFixture $env:PCVR_B2S_TEST_GAME;if(Test-B2SGame $test){return $test};throw 'The Beyond test game folder is incomplete.'}
    $paths=@();$saved=Get-PCVRRememberedGameFolder -GameId $script:Id -StateNames @('installed_path','user_located') -ProbeFiles @('BigFile_PC.dat');if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '960990' -SteamFolderNames @('BEYOND Two Souls') -ProbeExe 'BeyondTwoSouls_Steam.exe' -HubGameId $script:Id;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\BEYOND Two Souls','C:\Program Files\Epic Games\BeyondTwoSouls','C:\Program Files (x86)\GOG Galaxy\Games\BEYOND Two Souls','C:\GOG Games\BEYOND Two Souls')
    foreach($p in @($paths|Select-Object -Unique)){if(Test-B2SGame $p){return [IO.Path]::GetFullPath($p)}}
    $p=Get-GameFolderInteractive -GameName 'Beyond: Two Souls' -ProbeFile 'BigFile_PC.dat' -ManualUrl 'https://store.steampowered.com/app/960990/'
    if(Test-B2SGame $p){return [IO.Path]::GetFullPath($p)}
    throw 'Choose the game folder containing BeyondTwoSouls_Steam.exe or BeyondTwoSouls.exe and BigFile_PC.dat.'
}
function Get-B2SRelease {
    if($env:PCVR_B2S_TEST_ARCHIVE){return [pscustomobject]@{Tag='v0.17.14';Url=$env:PCVR_B2S_TEST_ARCHIVE;Local=$true}}
    try{
        $args=@{Repo=$script:Repo;IncludePrerelease=$false;AssetPatterns=@('(?i)^B2S_VR_MOD_v\d+(?:\.\d+)+\.zip$');SkipReleasesWithoutMatchingAsset=$true}
        if($env:PCVR_B2S_TEST_RELEASE_JSON){$args.ReleaseData=Get-Content -LiteralPath $env:PCVR_B2S_TEST_RELEASE_JSON -Raw|ConvertFrom-Json}
        $r=Resolve-GitHubReleaseAsset @args
    }catch{$r=[pscustomobject]@{Resolved=$false}}
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    if($handover){
        $leaf=[IO.Path]::GetFileName($handover)
        if($leaf -notmatch '(?i)^B2S_VR_MOD_(v[0-9]+(?:\.[0-9]+)+)\.zip$'){throw 'Choose an official versioned B2S_VR_MOD ZIP.'}
        $version=$Matches[1]
        if($r.Resolved -and $version -ine [string]$r.Tag){throw "That ZIP is $version; the current GitHub release is $($r.Tag). Download the current ZIP instead."}
        if(-not $r.Resolved){Write-Host " Publisher version could not be checked online. Selected: $leaf ($version)." -ForegroundColor Yellow;if((Read-Host ' Use this version? Y/N') -notmatch '^(?i:y|yes)$'){throw 'Publisher version was not confirmed.'}}
        return [pscustomobject]@{Tag=$version;Url=$handover;Local=$true}
    }
    if(-not $r.Resolved -or -not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){
        Write-Host ' [!!] The current Beyond VR release could not be checked on GitHub.' -ForegroundColor Yellow
        Write-Host ' Select its current official ZIP on the release page; the version will be shown before installation.' -ForegroundColor White
        return [pscustomobject]@{Tag='';Url='';Local=$false;Manual=$true}
    }
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false}
}
function Get-B2SManualArchive([string]$Destination){
    $declined='';$opened=$false
    while($true){
        $folders=if($env:PCVR_B2S_TEST_DOWNLOADS){@($env:PCVR_B2S_TEST_DOWNLOADS)}else{@()}
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('B2S_VR_MOD_v*.zip') -Folders $folders
        if($candidate -and $candidate -ne $declined -and (Test-DownloadedPayload -Path $candidate -IntendedPath $Destination)){
            $leaf=[IO.Path]::GetFileName($candidate)
            if($leaf -match '(?i)^B2S_VR_MOD_(v[0-9]+(?:\.[0-9]+)+)\.zip$'){
                $version=$Matches[1]
                Write-Host " Found in Downloads: $candidate" -ForegroundColor Cyan
                Write-Host " GitHub could not confirm the newest version. This file is $version; a newer release may exist." -ForegroundColor Yellow
                if((Read-Host ' Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){
                    Copy-Item -LiteralPath $candidate -Destination $Destination -Force -ErrorAction Stop
                    return [pscustomobject]@{Tag=$version;Url=$candidate;Local=$true}
                }
                $declined=$candidate
            }
        }
        if(-not $opened){
            Write-Host ' Download the current B2S_VR_MOD ZIP from the official release page.' -ForegroundColor White
            [void](Open-PCVRPageAfterEnter -Url $script:Page -Message 'Press Enter to open the Beyond VR releases page...')
            $opened=$true
        }
        [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('B2S_VR_MOD_v*.zip') -Folders $folders
        if($candidate -and $candidate -ne $declined){continue}
        $raw=(Read-Host ' Drag the downloaded ZIP here, or press Enter to open the page again').Trim().Trim('"').Trim("'")
        if($raw -and (Test-Path -LiteralPath $raw -PathType Leaf)){
            if((Test-DownloadedPayload -Path $raw -IntendedPath $Destination) -and ([IO.Path]::GetFileName($raw) -match '(?i)^B2S_VR_MOD_v[0-9]+(?:\.[0-9]+)+\.zip$')){
                Write-Host " Selected ZIP: $raw" -ForegroundColor Cyan
                Write-Host ' GitHub could not confirm whether this is the newest release.' -ForegroundColor Yellow
                if((Read-Host ' Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){
                    Copy-Item -LiteralPath $raw -Destination $Destination -Force -ErrorAction Stop
                    $version=[regex]::Match([IO.Path]::GetFileName($raw),'(?i)_(v[0-9]+(?:\.[0-9]+)+)\.zip$').Groups[1].Value
                    return [pscustomobject]@{Tag=$version;Url=$raw;Local=$true}
                }
                $declined=$raw
            }else{Write-Host ' This is not an official versioned B2S_VR_MOD ZIP.' -ForegroundColor Yellow}
        }else{Start-Process $script:Page -ErrorAction Stop|Out-Null}
    }
}
function New-B2SStage([string]$Archive,[string]$Work,[string]$ExpectedVersion){
    $expanded=Join-Path $Work 'publisher';$status=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'Beyond VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$status -notin @('ok','manual','retry')){throw 'The Beyond VR ZIP could not be opened.'}
    $root=Join-Path $expanded 'B2S_VR_MOD'
    foreach($name in @('files\dinput8.dll','files\b2svr.ini','files\BUILD.txt','tools\b2svr_setup.ps1','Play Beyond Two Souls in VR.cmd')){if(-not(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)){throw "The publisher package lacks $name."}}
    $build=Get-Content -LiteralPath (Join-Path $root 'files\BUILD.txt') -Raw
    $version=[regex]::Match($build,'(?im)^version:\s*([0-9]+(?:\.[0-9]+)+)\s*$').Groups[1].Value
    if(-not $version -or ('v'+$version) -ne $ExpectedVersion){throw 'The selected publisher ZIP version does not match its release; no game files were changed.'}
    $stage=Join-Path $Work 'stage';$sub=Join-Path $stage 'B2S_VR_MOD';[void][IO.Directory]::CreateDirectory((Join-Path $sub 'files'));[void][IO.Directory]::CreateDirectory((Join-Path $sub 'tools'))
    foreach($name in @('files\dinput8.dll','files\b2svr.ini','files\BUILD.txt','tools\b2svr_setup.ps1','Play Beyond Two Souls in VR.cmd')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $sub $name) -Force}
    foreach($name in @('tools\release_files.txt','Uninstall VR mod.cmd')){if(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf){Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $sub $name) -Force}}
    Copy-Item -LiteralPath (Join-Path $root 'files\dinput8.dll') -Destination (Join-Path $stage 'dinput8.dll') -Force
    Copy-Item -LiteralPath (Join-Path $root 'files\b2svr.ini') -Destination (Join-Path $stage 'b2svr.ini') -Force
    return $stage
}
function Save-B2SSnapshot([string]$Game,[string]$Stage,[string]$Backup){
    [void][IO.Directory]::CreateDirectory($Backup);$paths=[Collections.Generic.List[string]]::new()
    foreach($f in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$paths.Add($f.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Game '.pcvrhub_b2svr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($r in @(Import-Csv -LiteralPath $manifest)){if($r.RelativePath){$paths.Add((Assert-PCVROwnedRelativePath $r.RelativePath))}}}
    foreach($n in @('.pcvrhub_b2svr_ownership.csv','.pcvrhub_b2svr_ownership.csv.new','.pcvrhub_version')){$paths.Add($n)}
    $rows=@();foreach($rel in @($paths|Select-Object -Unique)){$src=Join-OwnedRelativePath $Game $rel;$had=Test-Path -LiteralPath $src -PathType Leaf;$rows+=[pscustomobject]@{Relative=$rel;Had=$had};if($had){$dst=Join-OwnedRelativePath (Join-Path $Backup 'files') $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dst));Copy-Item -LiteralPath $src -Destination $dst -Force}}
    $old=Join-Path $Game '.pcvrhub_b2svr_backup';$hadBackup=Test-Path -LiteralPath $old -PathType Container;if($hadBackup){Copy-Item -LiteralPath $old -Destination (Join-Path $Backup 'ownership') -Recurse -Force}
    return [pscustomobject]@{Root=$Backup;Rows=$rows;HadBackup=$hadBackup}
}
function Restore-B2SSnapshot([string]$Game,$S){
    foreach($r in @($S.Rows)){$p=Join-OwnedRelativePath $Game $r.Relative;if($r.Had){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $p));Copy-Item -LiteralPath (Join-OwnedRelativePath (Join-Path $S.Root 'files') $r.Relative) -Destination $p -Force}else{if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}}}
    $b=Join-Path $Game '.pcvrhub_b2svr_backup';if(Test-Path -LiteralPath $b){Remove-Item -LiteralPath $b -Recurse -Force};if($S.HadBackup){Copy-Item -LiteralPath (Join-Path $S.Root 'ownership') -Destination $b -Recurse -Force}
}
function Invoke-B2SInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keep=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ' Beyond: Two Souls VR - Installer' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Close the game. Use Windowed mode; disable Motion blur and Depth of field.' -ForegroundColor White
        Write-Host ' Steam is verified by the author; other PC builds use signature scanning.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Beyond: Two Souls...')
        Write-Host ' [..] Checking saved and installed game locations; this may take a few seconds.' -ForegroundColor Cyan
        $game=Get-B2SGame;if(Get-Process -Name 'BeyondTwoSouls','BeyondTwoSouls_Steam' -ErrorAction SilentlyContinue){throw 'Close Beyond: Two Souls before setup.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Restart the Hub as administrator, then retry.'}
        if((Test-Path -LiteralPath (Join-Path $game 'dinput8.dll') -PathType Leaf) -and -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_b2svr_ownership.csv') -PathType Leaf)){throw 'An existing dinput8.dll is not Hub-owned. Review it before installing Beyond VR.'}
        Write-Host " [OK] Game: $game" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest Beyond VR release...')
        Write-Host ' [..] Checking stable GitHub releases; this may take a few seconds.' -ForegroundColor Cyan
        $release=Get-B2SRelease;$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_b2s_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'BeyondVR.zip';if($release.Manual){$release=Get-B2SManualArchive -Destination $archive}elseif($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force}else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Beyond VR $($release.Tag)" -ManualUrl $script:Page -AllowSkip $false)}
        Write-Host ' [..] Inspecting and staging the publisher package; this may take a few seconds.' -ForegroundColor Cyan
        $stage=New-B2SStage -Archive $archive -Work $work -ExpectedVersion $release.Tag
        $snapshot=Save-B2SSnapshot -Game $game -Stage $stage -Backup (Join-Path $work 'rollback')
        $changed=$true;Write-Host ' [..] Installing Beyond VR and checking copied files; this may take a few seconds.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'b2svr' -AdoptIdenticalExisting -KeepExistingRelativePaths @('b2svr.ini'))
        $watch=@($script:Proof|Where-Object{$_ -ne 'BigFile_PC.dat'}|ForEach-Object{Join-Path $game $_})
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required Beyond VR files did not survive the copy check.'}
        $receipt=if($env:PCVR_B2S_TEST_RECEIPT){$env:PCVR_B2S_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:Contract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false;Write-Host " [OK] Beyond VR $($release.Tag) installed." -ForegroundColor Green
        Write-Host ' Start SteamVR, then choose Start in VR in the Hub.' -ForegroundColor White
        Write-Host '';Write-Host ' Two souls. One new point of view.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){try{Restore-B2SSnapshot -Game $game -S $snapshot}catch{$keep=$true;Write-Host " Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}}
        $message="Beyond: Two Souls VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{if($work -and -not $keep -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_B2S_LIBRARY_ONLY -ne '1'){Invoke-B2SInstaller}

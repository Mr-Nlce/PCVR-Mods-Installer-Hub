$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$script:Id='fallout-new-vegas-vr'
$script:Repo='df4l/FNVVR'
$script:Page='https://github.com/df4l/FNVVR/releases'
$env:PCVR_HUB_RECOVERY_PAGE=$script:Page
$script:Required=@('FalloutNV.exe','Data\FalloutNV.esm','d3d9.dll','openvr_api.dll','dxvk.conf','fnvvr\actions.json','fnvvr\bindings_oculus_touch.json','.pcvrhub_fnvvr_ownership.csv')
$script:Contract=New-PCVRInstallerContract -Id $script:Id -GameName 'Fallout: New Vegas VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:Page -RequiredInstalledFileGroups $script:Required
function Test-FNVGame([string]$Root){return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'FalloutNV.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Root 'Data\FalloutNV.esm') -PathType Leaf))}
function Assert-FNVFixture([string]$Path){$full=[IO.Path]::GetFullPath($Path);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\';if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'fnvvr-test-fixture.txt') -PathType Leaf)){throw 'FNVVR test game must stay in an isolated temporary fixture.'};return $full}
function Get-FNVGame {
    if($env:PCVR_FNV_TEST_GAME){$test=Assert-FNVFixture $env:PCVR_FNV_TEST_GAME;if(Test-FNVGame $test){return $test};throw 'The test game lacks FalloutNV.exe or Data\FalloutNV.esm.'}
    $c=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:Id -StateNames @('installed_path','user_located') -ProbeFiles @('FalloutNV.exe','Data\FalloutNV.esm');if($saved){$c+= $saved}
    try{$steam=Find-SteamGameFolder -AppId '22380' -SteamFolderNames @('Fallout New Vegas') -ProbeExe 'FalloutNV.exe' -HubGameId $script:Id;if($steam){$c+=$steam}}catch{}
    $c+=@('C:\Program Files (x86)\Steam\steamapps\common\Fallout New Vegas','C:\Program Files\Epic Games\FalloutNewVegas\Fallout New Vegas English','C:\Program Files (x86)\GOG Galaxy\Games\Fallout New Vegas','C:\GOG Games\Fallout New Vegas','C:\XboxGames\Fallout- New Vegas Ultimate Edition (PC)\Content\Fallout New Vegas English')
    foreach($p in @($c|Select-Object -Unique)){if(Test-FNVGame $p){return [IO.Path]::GetFullPath($p)}}
    $p=Get-GameFolderInteractive -GameName 'Fallout: New Vegas' -ProbeFile 'FalloutNV.exe' -ManualUrl 'https://store.steampowered.com/app/22380/'
    if(Test-FNVGame $p){return [IO.Path]::GetFullPath($p)}
    throw 'Choose the installed game folder containing FalloutNV.exe and Data\FalloutNV.esm.'
}
function Get-FNVRelease {
    if($env:PCVR_FNV_TEST_ARCHIVE){return [pscustomobject]@{Tag='v0.6.0';Url=$env:PCVR_FNV_TEST_ARCHIVE;Local=$true;PageUrl=$script:Page}}
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:Repo -IncludePrerelease $true -AssetPatterns @('(?i)^FNVVR-Reborn-v[0-9]+(?:\.[0-9]+)+(?:[-.][A-Za-z0-9.]+)?\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=[pscustomobject]@{Resolved=$false}}
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    if($handover){
        $leaf=[IO.Path]::GetFileName($handover)
        if($leaf -notmatch '(?i)^FNVVR-Reborn-(v[0-9]+(?:\.[0-9]+)+(?:[-.][A-Za-z0-9.]+)?)\.zip$'){throw 'Choose an official versioned FNVVR-Reborn ZIP.'}
        $version=$Matches[1]
        if($r.Resolved -and $version -ine [string]$r.Tag){throw "That ZIP is $version; the current GitHub release is $($r.Tag). Download the current ZIP instead."}
        if(-not $r.Resolved){Write-Host " Publisher version could not be checked online. Selected: $leaf ($version)." -ForegroundColor Yellow;if((Read-Host ' Use this version? Y/N') -notmatch '^(?i:y|yes)$'){throw 'Publisher version was not confirmed.'}}
        return [pscustomobject]@{Tag=$version;Url=$handover;Local=$true;PageUrl=$script:Page}
    }
    if(-not $r.Resolved -or -not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){throw 'The current FNVVR release could not be resolved; retry or use the official ZIP in installer recovery.'}
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false;PageUrl=$script:Page}
}
function New-FNVStage([string]$Archive,[string]$Work,[string]$Game,[string]$ExpectedVersion){
    $expanded=Join-Path $Work 'publisher';$status=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'FNVVR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$status -notin @('ok','manual','retry')){throw 'The FNVVR ZIP could not be opened.'}
    $source=Get-ChildItem -LiteralPath $expanded -Directory -Recurse|Where-Object{(Test-Path -LiteralPath (Join-Path $_.FullName 'd3d9.dll') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'fnvvr\actions.json') -PathType Leaf)}|Select-Object -First 1 -ExpandProperty FullName
    if(-not $source){throw 'The ZIP is missing the FNVVR runtime.'}
    if((Split-Path -Leaf $source) -ine ('FNVVR-Reborn-'+$ExpectedVersion)){throw 'The FNVVR payload version differs from the selected release.'}
    $stage=Join-Path $Work 'stage';[void][IO.Directory]::CreateDirectory((Join-Path $stage 'fnvvr'))
    foreach($name in @('d3d9.dll','openvr_api.dll','fnvvr\actions.json','fnvvr\bindings_oculus_touch.json')){
        $from=Join-Path $source $name;if(-not(Test-Path -LiteralPath $from -PathType Leaf)){throw "The publisher ZIP lacks $name."}
        $to=Join-Path $stage $name;Copy-Item -LiteralPath $from -Destination $to -Force -ErrorAction Stop
    }
    $published=Get-Content -LiteralPath (Join-Path $source 'dxvk.conf') -Raw -ErrorAction Stop
    $existing=Join-Path $Game 'dxvk.conf'
    if(Test-Path -LiteralPath $existing -PathType Leaf){
        $current=Get-Content -LiteralPath $existing -Raw -ErrorAction Stop
        $globalSection=($current -split '(?m)^[ \t]*\[',2)[0]
        $backend=[regex]::Match($globalSection,'(?im)^[ \t]*d3d9\.vrBackend[ \t]*=[ \t]*([^\r\n#]+)').Groups[1].Value.Trim()
        if($backend -and $backend -ine 'openvr'){throw 'Your existing dxvk.conf chooses a different VR backend. Review it before installing FNVVR.'}
        if(-not $backend){$current="d3d9.vrBackend = openvr`r`n"+$current}
        if($current -notmatch '(?im)^[ \t]*dxvk\.logLevel[ \t]*='){$current="dxvk.logLevel = info`r`n"+$current}
        if($current -notmatch '(?im)^[ \t]*\[FalloutNVLauncher\.exe\]'){$current+="`r`n[FalloutNVLauncher.exe]`r`nd3d9.vrBackend = off`r`n"}
        $published=$current
    }
    [IO.File]::WriteAllText((Join-Path $stage 'dxvk.conf'),$published,[Text.UTF8Encoding]::new($false))
    return $stage
}
function Save-FNVSnapshot([string]$Game,[string]$Stage,[string]$Backup){
    [void][IO.Directory]::CreateDirectory($Backup);$paths=[Collections.Generic.List[string]]::new()
    foreach($f in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$paths.Add($f.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Game '.pcvrhub_fnvvr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($r in @(Import-Csv -LiteralPath $manifest)){if($r.RelativePath){$paths.Add((Assert-PCVROwnedRelativePath $r.RelativePath))}}}
    foreach($n in @('.pcvrhub_fnvvr_ownership.csv','.pcvrhub_fnvvr_ownership.csv.new','.pcvrhub_version')){$paths.Add($n)}
    $rows=@();foreach($rel in @($paths|Select-Object -Unique)){
        $src=Join-OwnedRelativePath $Game $rel;$had=Test-Path -LiteralPath $src -PathType Leaf;$rows+=[pscustomobject]@{Relative=$rel;Had=$had}
        if($had){$dst=Join-OwnedRelativePath (Join-Path $Backup 'files') $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dst));Copy-Item -LiteralPath $src -Destination $dst -Force}
    }
    $oldBackup=Join-Path $Game '.pcvrhub_fnvvr_backup';$hadBackup=Test-Path -LiteralPath $oldBackup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $oldBackup -Destination (Join-Path $Backup 'ownership') -Recurse -Force}
    return [pscustomobject]@{Root=$Backup;Rows=$rows;HadBackup=$hadBackup}
}
function Restore-FNVSnapshot([string]$Game,$Snapshot){
    foreach($r in @($Snapshot.Rows)){$p=Join-OwnedRelativePath $Game $r.Relative;if($r.Had){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $p));Copy-Item -LiteralPath (Join-OwnedRelativePath (Join-Path $Snapshot.Root 'files') $r.Relative) -Destination $p -Force}else{if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}}}
    $b=Join-Path $Game '.pcvrhub_fnvvr_backup';if(Test-Path -LiteralPath $b){Remove-Item -LiteralPath $b -Recurse -Force};if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership') -Destination $b -Recurse -Force}
}
function Invoke-FNVInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keep=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ' Fallout: New Vegas VR - Installer' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Close the game. SteamVR and a Vulkan-capable GPU are required.' -ForegroundColor White
        Write-Host ' Existing game files and settings are backed up or preserved.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Fallout: New Vegas...')
        Write-Host ' [..] Checking saved and installed game locations; this may take a few seconds.' -ForegroundColor Cyan
        $game=Get-FNVGame;if(Get-Process -Name 'FalloutNV' -ErrorAction SilentlyContinue){throw 'Close Fallout: New Vegas before setup.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Restart the Hub as administrator, then retry.'}
        Write-Host " [OK] Game: $game" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest FNVVR release...')
        Write-Host ' [..] Checking GitHub prereleases; this may take a few seconds.' -ForegroundColor Cyan
        $release=Get-FNVRelease;$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_fnv_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'FNVVR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force}else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "FNVVR $($release.Tag)" -ManualUrl $script:Page -AllowSkip $false)}
        Write-Host ' [..] Inspecting and staging publisher files; this may take a few seconds.' -ForegroundColor Cyan
        $stage=New-FNVStage -Archive $archive -Work $work -Game $game -ExpectedVersion $release.Tag
        $snapshot=Save-FNVSnapshot -Game $game -Stage $stage -Backup (Join-Path $work 'rollback')
        $changed=$true;Write-Host ' [..] Installing FNVVR and checking copied files; this may take a few seconds.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'fnvvr' -AdoptIdenticalExisting -KeepExistingRelativePaths @('fnvvr\vr_options.ini'))
        $watch=@($script:Required|Where-Object{$_ -ne 'FalloutNV.exe' -and $_ -ne 'Data\FalloutNV.esm'}|ForEach-Object{Join-Path $game $_})
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'FNVVR files did not survive the copy check.'}
        $receipt=if($env:PCVR_FNV_TEST_RECEIPT){$env:PCVR_FNV_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:Contract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false;Write-Host " [OK] FNVVR $($release.Tag) installed." -ForegroundColor Green
        Write-Host ' Start SteamVR, then choose Start in VR in the Hub.' -ForegroundColor White
        Write-Host '';Write-Host ' The Mojave looks different from inside the wasteland.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){try{Restore-FNVSnapshot -Game $game -Snapshot $snapshot}catch{$keep=$true;Write-Host " Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}}
        $message="Fallout: New Vegas VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{if($work -and -not $keep -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_FNV_LIBRARY_ONLY -ne '1'){Invoke-FNVInstaller}

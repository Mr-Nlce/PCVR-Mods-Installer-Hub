param([ValidateSet('','relith','gameordie')][string]$Mod='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='No One Lives Forever VR Installer'
$script:GameId='no-one-lives-forever-vr'
$script:GameTitle='No One Lives Forever VR'
$script:Slots=@{
    relith=@{Name='ReLith';Folder='ReLith';Repo='alex-nax/relith';Pattern='(?i)^relith-nolf-windows-vr-[0-9].*\.zip$';Tag='v0.4.1';File='relith-nolf-windows-vr-0.4.1.zip';Launcher='relith-nolf-vr.exe';Identity='nolfrelith';Receipt='.installed_path_a';State='mod_a_path';VersionSlot='Primary';Required=@('relith-nolf-vr.exe','relith.rez','MODERNIZER.REZ','SDL2.dll','NOLF.REZ','NOLF2.REZ','nolfu003.rez','nolfu003cres.rez')}
    gameordie=@{Name='NOLF VR by GameOrDie007';Folder='GameOrDie';Repo='GameOrDie007/No-One-Lives-Forever-VR';Pattern='(?i)^No-One-Lives-Forever-VR-[0-9].*PCVR\.zip$';Tag='v1.2';File='No-One-Lives-Forever-VR-1.2-PCVR.zip';Launcher='Play No One Lives Forever VR.bat';Identity='nolfgameordie';Receipt='.installed_path_b';State='mod_b_path';VersionSlot='Secondary';Required=@('Play No One Lives Forever VR.bat','host\nolfvr.exe','host\openxr_loader.dll','game\DINPUT.dll','game\d3dstub.ren','game\NOLF.REZ','game\NOLF2.REZ','game\NOLFGOTY.REZ','game\lithtech.exe')}
}
function Test-NolfSource([string]$Root,[bool]$Goty){
    if(-not $Root -or -not(Test-Path -LiteralPath $Root -PathType Container)){return $false}
    foreach($name in @('lithtech.exe','NOLF.REZ','NOLF2.REZ','nolfu003.rez')){if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)){return $false}}
    if($Goty -and -not(Test-Path -LiteralPath (Join-Path $Root 'NOLFGOTY.REZ') -PathType Leaf)){return $false}
    return $true
}
function Get-NolfSource([bool]$Goty){
    $test=(''+$env:PCVR_NOLF1_TEST_GAME).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){if(Test-NolfSource $test $Goty){return [IO.Path]::GetFullPath($test)};throw 'The isolated NOLF game fixture is incomplete.'}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @('base_game_path','user_located') -ProbeFiles @('lithtech.exe','NOLF.REZ','NOLF2.REZ')
    if(Test-NolfSource $saved $Goty){return [IO.Path]::GetFullPath($saved)}
    foreach($path in @('C:\Games\No One Lives Forever','C:\GOG Games\No One Lives Forever','C:\Program Files (x86)\Fox\No One Lives Forever','C:\Program Files (x86)\Monolith Productions\No One Lives Forever','C:\Program Files (x86)\Monolith Productions\No One Lives Forever\English','C:\Program Files (x86)\GOG Galaxy\Games\No One Lives Forever')){if(Test-NolfSource $path $Goty){return [IO.Path]::GetFullPath($path)}}
    while($true){
        Write-Host '  Enter the folder containing lithtech.exe and your original NOLF archives.' -ForegroundColor Yellow
        $entry=(''+(Read-Host 'Game folder, or Q to cancel')).Trim().Trim('"')
        if($entry -in @('q','Q','quit')){return $null}
        if(Test-NolfSource $entry $Goty){return [IO.Path]::GetFullPath($entry)}
        Write-Host '  Required original files were not found here. This route needs NOLF GOTY 1.004.' -ForegroundColor Yellow
    }
}
function Assert-NolfSlotTarget([string]$Path,[hashtable]$Slot){
    $full=[IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
    if((Split-Path -Leaf $full) -cne [string]$Slot.Folder -or (Split-Path -Leaf (Split-Path -Parent $full)) -cne 'No One Lives Forever VR'){throw 'The selected VR slot must be inside a No One Lives Forever VR folder.'}
    if(Test-Path -LiteralPath $full){$item=Get-Item -LiteralPath $full -Force;if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'A linked VR slot folder cannot be changed safely.'}}
    return $full
}
function Get-NolfSlotTarget([hashtable]$Slot){
    $test=(''+$env:PCVR_NOLF1_TEST_TARGET).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){return (Assert-NolfSlotTarget -Path (Join-Path $test ([string]$Slot.Folder)) -Slot $Slot)}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @([string]$Slot.State) -ProbeFiles @()
    if($saved){try{return (Assert-NolfSlotTarget -Path $saved -Slot $Slot)}catch{}}
    foreach($base in @('C:\Games','D:\Games','E:\Games')){
        try{[void][IO.Directory]::CreateDirectory($base);$probe=Join-Path $base ('.pcvr-nolf-write-'+[Guid]::NewGuid().ToString('N'));[IO.File]::WriteAllText($probe,'ok');Remove-Item -LiteralPath $probe -Force -ErrorAction Stop;return (Assert-NolfSlotTarget -Path (Join-Path (Join-Path $base 'No One Lives Forever VR') ([string]$Slot.Folder)) -Slot $Slot)}catch{}
    }
    throw 'No standard Games folder is writable. Create C:\Games, D:\Games or E:\Games and retry.'
}
function Get-NolfRelease([string]$Key,[hashtable]$Slot){
    $local=if($Key -eq 'relith'){(''+$env:PCVR_NOLF1_TEST_RELITH_ARCHIVE).Trim()}else{(''+$env:PCVR_NOLF1_TEST_GAMEORDIE_ARCHIVE).Trim()}
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $local){return [pscustomobject]@{Tag=[string]$Slot.Tag;Url=$local;PageUrl=('https://github.com/'+$Slot.Repo+'/releases');Local=$true}}
    # 1.3.1 switched from the installable 1.2 package to a nested files/ +
    # Setup.bat layout without the version and launch files this route owns.
    # Keep the verified package until that publisher setup has its own route.
    if($Key -eq 'gameordie'){
        return [pscustomobject]@{Tag=[string]$Slot.Tag;Url=('https://github.com/'+$Slot.Repo+'/releases/download/'+$Slot.Tag+'/'+$Slot.File);PageUrl=('https://github.com/'+$Slot.Repo+'/releases');Local=$false}
    }
    $asset=Resolve-GitHubReleaseAsset -Repo ([string]$Slot.Repo) -AssetPatterns @([string]$Slot.Pattern) -FallbackUrl ('https://github.com/'+$Slot.Repo+'/releases/download/'+$Slot.Tag+'/'+$Slot.File) -FallbackTag ([string]$Slot.Tag) -FallbackAssetName ([string]$Slot.File) -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Tag=[string]$asset.Tag;Url=[string]$asset.Url;PageUrl=[string]$asset.PageUrl;Local=$false}
}
function Get-NolfPayload([string]$Archive,[string]$Work,[hashtable]$Slot,[string]$ReleaseTag){
    $extract=Join-Path $Work 'release';$result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $extract -Label ([string]$Slot.Name) -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The publisher ZIP could not be extracted.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile ([string]$Slot.Launcher)
    if(-not $payload){throw 'The publisher ZIP lacks its Windows launcher.'}
    $publisherRequired=if($Slot.Folder -eq 'ReLith'){@('relith-nolf-vr.exe','relith.rez','MODERNIZER.REZ','SDL2.dll')}else{@('Setup.bat','tools\setup.ps1','Play No One Lives Forever VR.bat','host\nolfvr.exe','host\openxr_loader.dll','game\DINPUT.dll','game\d3dstub.ren')}
    foreach($name in $publisherRequired){if(-not(Test-Path -LiteralPath (Join-Path $payload $name) -PathType Leaf)){throw "The publisher ZIP is missing $name."}}
    if($Slot.Folder -eq 'GameOrDie'){
        $versionFile=Join-Path $payload 'version.txt'
        if(-not(Test-Path -LiteralPath $versionFile -PathType Leaf)){throw 'The publisher ZIP has no version.txt. No game files were changed.'}
        $published=([IO.File]::ReadAllText($versionFile)).Trim()
        if($ReleaseTag -notmatch '^v\d+(?:\.\d+){1,3}$' -or
            -not [string]::Equals($published,('No One Lives Forever VR '+$ReleaseTag.Substring(1)),[StringComparison]::OrdinalIgnoreCase)){
            throw "The NOLF VR package version does not match the selected release ($ReleaseTag). No game files were changed."
        }
    }
    return $payload
}
function Assert-NolfNoDowngrade([string]$Target,[hashtable]$Slot,[string]$ReleaseTag){
    if($Slot.Folder -ne 'GameOrDie' -or $ReleaseTag -notmatch '^v(\d+(?:\.\d+){1,3})$'){return}
    foreach($name in @($Slot.Required)){if(-not(Test-Path -LiteralPath (Join-Path $Target $name) -PathType Leaf)){return}}
    $receipt=Join-Path $Target '.pcvrhub_version_b'
    if(-not(Test-Path -LiteralPath $receipt -PathType Leaf)){return}
    $saved=([IO.File]::ReadAllText($receipt)).Trim()
    if($saved -match '^v(\d+(?:\.\d+){1,3})$' -and [version]$Matches[1] -gt [version]$ReleaseTag.Substring(1)){
        throw "A newer NOLF VR version ($saved) is already installed. Retry the current release download; this fallback cannot downgrade it."
    }
}
function Save-NolfSnapshot([string]$Target,[string]$Snapshot){
    [void][IO.Directory]::CreateDirectory($Snapshot);$exists=Test-Path -LiteralPath $Target -PathType Container
    if($exists){foreach($item in @(Get-ChildItem -LiteralPath $Target -Force -ErrorAction Stop)){Copy-Item -LiteralPath $item.FullName -Destination $Snapshot -Recurse -Force -ErrorAction Stop}}
    return [pscustomobject]@{Exists=$exists;Root=$Snapshot}
}
function Restore-NolfSnapshot([string]$Target,[hashtable]$Slot,$Snapshot){
    $full=Assert-NolfSlotTarget -Path $Target -Slot $Slot
    if(Test-Path -LiteralPath $full -PathType Container){Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop}
    if($Snapshot.Exists){[void][IO.Directory]::CreateDirectory($full);foreach($item in @(Get-ChildItem -LiteralPath $Snapshot.Root -Force -ErrorAction Stop)){Copy-Item -LiteralPath $item.FullName -Destination $full -Recurse -Force -ErrorAction Stop}}
}
function Copy-NolfOriginalData([string]$Source,[string]$Target){
    foreach($name in @('NOLF.REZ','NOLF2.REZ','nolfu003.rez','nolfu003cres.rez','nolf003cres.rez','NOLFGOTY.REZ','FontData.fnt')){
        $from=Join-Path $Source $name;$to=Join-Path $Target $name
        if((Test-Path -LiteralPath $from -PathType Leaf) -and -not(Test-Path -LiteralPath $to -PathType Leaf)){Copy-Item -LiteralPath $from -Destination $to -ErrorAction Stop}
    }
    if(-not(Test-Path -LiteralPath (Join-Path $Target 'nolfu003cres.rez') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Target 'nolf003cres.rez') -PathType Leaf)){Copy-Item -LiteralPath (Join-Path $Target 'nolf003cres.rez') -Destination (Join-Path $Target 'nolfu003cres.rez') -ErrorAction Stop}
    $movies=Join-Path $Source 'Movies';$destMovies=Join-Path $Target 'Movies'
    if((Test-Path -LiteralPath $movies -PathType Container) -and -not(Test-Path -LiteralPath $destMovies)){Copy-Item -LiteralPath $movies -Destination $destMovies -Recurse -ErrorAction Stop}
}
function Invoke-NolfPublisherSetup([string]$Target,[string]$Source){
    $setup=Join-Path $Target 'tools\setup.ps1'
    $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName='powershell.exe';$psi.Arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "'+$setup+'" -Install "'+$Source+'"';$psi.WorkingDirectory=$Target
    $psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $process=[Diagnostics.Process]::new();$process.StartInfo=$psi;[void]$process.Start()
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$process.WaitForExit()
    $output=($stdout.Result+"`n"+$stderr.Result).Trim()
    if($output){Write-Host $output}
    if($process.ExitCode -ne 0){throw "Publisher setup failed with exit code $($process.ExitCode). See setup.log in the selected VR folder."}
}
function Invoke-NolfInstaller {
    $work=$null;$target=$null;$slot=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' No One Lives Forever VR - Installer' -ForegroundColor Cyan
        Write-Host ' Two independent VR ports for your own NOLF game data' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' [1] ReLith - recommended new OpenXR engine; NOLF 1.003 data' -ForegroundColor Green
        Write-Host ' [2] GameOrDie007 - classic NOLF GOTY 1.004 VR port' -ForegroundColor White
        Write-Host ' Both can stay installed in separate folders. The Hub Play choice' -ForegroundColor Gray
        Write-Host ' selects the port for that session; setup does not switch mods.' -ForegroundColor Gray
        Write-Host ' Your original game installation is not modified.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        while(-not $Mod){$choice=(''+(Read-Host 'Choose 1, 2 or Q')).Trim().ToLowerInvariant();if($choice -eq '1'){$Mod='relith'}elseif($choice -eq '2'){$Mod='gameordie'}elseif($choice -in @('q','quit')){return}else{Write-Host ' Choose [1], [2] or [Q].' -ForegroundColor Yellow}}
        $slot=$script:Slots[$Mod]
        Write-Host ''
        Write-Host " Selected: $($slot.Name). Close the game and both VR ports before continuing." -ForegroundColor Cyan
        if($Mod -eq 'gameordie'){Write-Host ' The publisher setup may briefly start a copy of the flat game to build its font cache.' -ForegroundColor Yellow}
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to find your original game and download this port...')
        $source=Get-NolfSource -Goty:($Mod -eq 'gameordie')
        if(-not $source){return}
        if(Get-Process -Name @('lithtech','relith-nolf-vr','nolfvr') -ErrorAction SilentlyContinue){throw 'Close NOLF and both VR ports before setup.'}
        $target=Get-NolfSlotTarget -Slot $slot
        Write-Host "  [OK] Original game: $source" -ForegroundColor Green
        Write-Host "  [..] Separate VR folder: $target" -ForegroundColor Gray
        $release=Get-NolfRelease -Key $Mod -Slot $slot
        Assert-NolfNoDowngrade -Target $target -Slot $slot -ReleaseTag ([string]$release.Tag)
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_nolf1_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'publisher.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{$download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "$($slot.Name) $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false;if(-not($download -eq $true -or [string]$download -in @('retry','manual'))){throw 'The selected publisher release was not downloaded.'}}
        $payload=Get-NolfPayload -Archive $archive -Work $work -Slot $slot -ReleaseTag ([string]$release.Tag)
        $snapshot=Save-NolfSnapshot -Target $target -Snapshot (Join-Path $work 'rollback')
        [void][IO.Directory]::CreateDirectory($target);$changed=$true
        $keep=if($Mod -eq 'relith'){@('relith_env.cfg')}else{@('game\vrtune.cfg','game\vrweapons.cfg')}
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity ([string]$slot.Identity) -AdoptIdenticalExisting -KeepExistingRelativePaths $keep)
        if($Mod -eq 'relith'){Copy-NolfOriginalData -Source $source -Target $target}
        else{Invoke-NolfPublisherSetup -Target $target -Source $source}
        foreach($name in @($slot.Required)){if(-not(Test-Path -LiteralPath (Join-Path $target $name) -PathType Leaf)){throw "Required installed file is missing: $name"}}
        $contract=New-PCVRInstallerContract -Id ($script:GameId+'-'+$Mod) -GameName ([string]$slot.Name) -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ([string]$release.PageUrl) -RequiredInstalledFileGroups (@($slot.Required)+@('.pcvrhub_'+$slot.Identity+'_ownership.csv'))
        if(-not(Save-HubRememberedGameFolder -GameId $script:GameId -Title $script:GameTitle -GameDir $source -ProbeFiles @('lithtech.exe','NOLF.REZ','NOLF2.REZ') -StateName 'base_game_path')){throw 'The original game path could not be remembered.'}
        if(-not(Save-HubRememberedGameFolder -GameId $script:GameId -Title $script:GameTitle -GameDir $target -ProbeFiles @([string]$slot.Launcher) -StateName ([string]$slot.State))){throw 'The selected VR folder could not be remembered.'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version ([string]$release.Tag) -VersionSlot ([string]$slot.VersionSlot) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot ([string]$slot.Receipt))) -Route Current)
        $changed=$false
        Write-Host "  [OK] $($slot.Name) $($release.Tag) is installed and tracked." -ForegroundColor Green
        Write-Host '  Start your OpenXR runtime, then use the matching Hub Play button.' -ForegroundColor White
        Write-Host ''
        Write-Host '  H.A.R.M. will have a hard time filing this mission report.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $target -and $snapshot){try{Restore-NolfSnapshot -Target $target -Slot $slot -Snapshot $snapshot;Write-Host '  [!!] The previous selected VR port was restored.' -ForegroundColor Yellow}catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}}
        Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red;throw
    }finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_NOLF1_LIBRARY_ONLY -ne '1'){Invoke-NolfInstaller}

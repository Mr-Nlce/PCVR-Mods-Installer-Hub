$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='MiSide VR Installer'
$script:MiSideId='miside-vr'
$script:MiSideRepo='Glitchtest51/MiSide_VR'
$script:MiSideReleases="https://github.com/$script:MiSideRepo/releases"
$script:MiSideFallback='https://github.com/Glitchtest51/MiSide_VR/releases/download/0.9.0/MiSide_VR-0.9.0.zip'
$script:MiSideBepUrl='https://github.com/BepInEx/BepInEx/releases/download/v6.0.0-pre.2/BepInEx-Unity.IL2CPP-win-x64-6.0.0-pre.2.zip'
$script:MiSideBepProof=@('BepInEx\core\BepInEx.Unity.IL2CPP.dll','BepInEx\core\BepInEx.Core.dll','dotnet\hostpolicy.dll','winhttp.dll','doorstop_config.ini')
$script:MiSideModProof=@('BepInEx\plugins\MiSide_VR\MiSide_VR.dll','MiSideFull_Data\Plugins\x86_64\openvr_api.dll',
    'MiSideFull_Data\Plugins\x86_64\XRSDKOpenVR.dll','MiSideFull_Data\StreamingAssets\SteamVR\actions.json',
    'MiSideFull_Data\UnitySubsystems\XRSDKOpenVR\UnitySubsystemsManifest.json')
$script:MiSideContract=New-PCVRInstallerContract -Id $script:MiSideId -GameName 'MiSide VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $script:MiSideReleases `
    -RequiredInstalledFileGroups @($script:MiSideBepProof + $script:MiSideModProof + '.pcvrhub_misidevr_ownership.csv')

function Test-MiSideGame([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'MiSideFull.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'MiSideFull_Data\globalgamemanagers') -PathType Leaf))
}
function Get-MiSideGameRoot{
    $test=(''+$env:PCVR_MISIDE_TEST_GAME).Trim()
    if($test){if(Test-MiSideGame $test){return (Get-Item -LiteralPath $test).FullName};throw 'MiSide test folder lacks the base game.'}
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){$prior=([IO.File]::ReadAllText($receipt)).Trim().Trim('"');if(Test-MiSideGame $prior){return (Get-Item -LiteralPath $prior).FullName}}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:MiSideId -StateNames @('installed_path','user_located') -ProbeFiles @('MiSideFull.exe')
    if(Test-MiSideGame $saved){return (Get-Item -LiteralPath $saved).FullName}
    $found=Find-SteamGameFolder -AppId '2527500' -SteamFolderNames @('MiSide') -ProbeExe 'MiSideFull.exe' -HubGameId $script:MiSideId
    if(Test-MiSideGame $found){return (Get-Item -LiteralPath $found).FullName}
    $manual=Get-GameFolderInteractive -GameName 'MiSide' -ProbeFile 'MiSideFull.exe' -ManualUrl $script:MiSideReleases
    if($manual -and $manual -notin @('quit','skip') -and (Test-MiSideGame $manual)){return (Get-Item -LiteralPath $manual).FullName}
    return $null
}
function Get-MiSideRelease{
    $test=(''+$env:PCVR_MISIDE_TEST_MOD_ARCHIVE).Trim()
    if($test){return [pscustomobject]@{Tag='0.9.0';Url=$test;PageUrl=$script:MiSideReleases;IsLocal=$true}}
    $r=Resolve-GitHubReleaseAsset -Repo $script:MiSideRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^MiSide_VR-[0-9].*\.zip$') -FallbackUrl $script:MiSideFallback `
        -FallbackTag '0.9.0' -FallbackAssetName 'MiSide_VR-0.9.0.zip' -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;PageUrl=[string]$r.PageUrl;IsLocal=$false}
}
function New-MiSideStage([string]$Archive,[string]$Work,[string]$Name,[string]$Proof,[string[]]$Required){
    $outer=Join-Path $Work ('publisher-'+$Name)
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label "$Name publisher ZIP" -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw "$Name ZIP could not be opened."}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $outer -RelModFile $Proof
    if(-not $payload){throw "$Name ZIP has no expected payload."}
    foreach($relative in $Required){if(-not(Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)){throw "$Name ZIP is missing $relative"}}
    $stage=Join-Path $Work ('stage-'+$Name);[void][IO.Directory]::CreateDirectory($stage)
    foreach($file in @(Get-ChildItem -LiteralPath $payload -Recurse -File -Force -ErrorAction Stop)){
        $relative=$file.FullName.Substring($payload.Length+1)
        if($relative -match '^(?i:BepInEx[\\/]cache[\\/]|BepInEx[\\/]LogOutput\.log$)'){continue}
        $target=Join-OwnedRelativePath -Root $stage -Relative $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
    }
    return $stage
}
function Save-MiSideSnapshot([string]$Game,[string[]]$Stages,[string]$Root){
    [void][IO.Directory]::CreateDirectory($Root)
    $paths=[Collections.Generic.List[string]]::new()
    foreach($stage in $Stages){foreach($file in @(Get-ChildItem -LiteralPath $stage -Recurse -File)){[void]$paths.Add($file.FullName.Substring($stage.Length+1))}}
    foreach($identity in @('miside_bep','misidevr')){
        $manifest=Join-Path $Game ('.pcvrhub_'+$identity+'_ownership.csv')
        if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)){
            if($row.RelativePath){[void]$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}
        }}
        foreach($name in @(('.pcvrhub_'+$identity+'_ownership.csv'),('.pcvrhub_'+$identity+'_ownership.csv.new'))){[void]$paths.Add($name)}
    }
    [void]$paths.Add('.pcvrhub_version')
    $records=@()
    foreach($relative in @($paths|Select-Object -Unique)){
        $source=Join-OwnedRelativePath -Root $Game -Relative $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-OwnedRelativePath -Root (Join-Path $Root 'files') -Relative $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop}
    }
    $backups=@{}
    foreach($identity in @('miside_bep','misidevr')){
        $backup=Join-Path $Game ('.pcvrhub_'+$identity+'_backup')
        $backups[$identity]=Test-Path -LiteralPath $backup -PathType Container
        if($backups[$identity]){Copy-Item -LiteralPath $backup -Destination (Join-Path $Root ('backup-'+$identity)) -Recurse -Force -ErrorAction Stop}
    }
    return [pscustomobject]@{Root=$Root;Records=$records;Backups=$backups}
}
function Restore-MiSideSnapshot([string]$Game,$Snapshot){
    foreach($row in @($Snapshot.Records)){
        $target=Join-OwnedRelativePath -Root $Game -Relative ([string]$row.Relative)
        if($row.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$row.Relative)) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    foreach($identity in @('miside_bep','misidevr')){
        $backup=Join-Path $Game ('.pcvrhub_'+$identity+'_backup')
        if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
        if($Snapshot.Backups[$identity]){Copy-Item -LiteralPath (Join-Path $Snapshot.Root ('backup-'+$identity)) -Destination $backup -Recurse -Force -ErrorAction Stop}
    }
}
function Write-MiSideProofCheckpoint([string]$Label,[string]$Game){
    foreach($relative in @($script:MiSideBepProof+$script:MiSideModProof)){
        Write-Host ("  [{0}] {1}: {2}" -f $Label,$relative,[bool](Test-Path -LiteralPath (Join-Path $Game $relative) -PathType Leaf)) -ForegroundColor DarkGray
    }
}
function Test-MiSideLoaderStageIdentical([string]$Game,[string]$Stage){
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -Force)){
        $relative=$file.FullName.Substring($Stage.Length+1)
        $installed=Join-OwnedRelativePath -Root $Game -Relative $relative
        if(-not(Test-Path -LiteralPath $installed -PathType Leaf)){return $false}
        $left=[Security.Cryptography.SHA256]::Create();$right=[Security.Cryptography.SHA256]::Create()
        try{
            $a=[IO.File]::OpenRead($file.FullName);try{$sourceHash=$left.ComputeHash($a)}finally{$a.Dispose()}
            $b=[IO.File]::OpenRead($installed);try{$installedHash=$right.ComputeHash($b)}finally{$b.Dispose()}
            if([Convert]::ToBase64String($sourceHash) -cne [Convert]::ToBase64String($installedHash)){return $false}
        }finally{$left.Dispose();$right.Dispose()}
    }
    return $true
}
function Test-MiSideLoaderInitialized([string]$Game){
    $config=Join-Path $Game 'BepInEx\config\BepInEx.cfg'
    $log=Join-Path $Game 'BepInEx\LogOutput.log'
    if(-not((Test-Path -LiteralPath $config -PathType Leaf) -and (Test-Path -LiteralPath $log -PathType Leaf))){return $false}
    return [bool]([IO.File]::ReadAllText($log) -match '(?i)BepInEx|Chainloader')
}
function Wait-MiSideFirstFlatLaunch([string]$Game){
    if(Test-MiSideLoaderInitialized $Game){Write-Host '  [OK] BepInEx first-launch files already exist.' -ForegroundColor Green;return}
    Write-Host '  MiSide must run flat once after BepInEx installation.' -ForegroundColor White
    Write-Host '  This creates the loader files required before the VR mod is copied.' -ForegroundColor White
    while($true){
        Write-Host ''
        Write-Host '  [Enter] Open MiSide flat through Steam (recommended).' -ForegroundColor Yellow
        Write-Host '  [S] I already ran it flat after BepInEx was installed; check files.' -ForegroundColor White
        Write-Host '  [Q] Cancel setup.' -ForegroundColor White
        $raw=(''+(Read-Host '  Choose Enter, S or Q')).Trim().ToUpperInvariant()
        if($raw -eq 'Q'){throw 'Setup cancelled before the VR mod was copied.'}
        if($raw -eq 'S'){
            if(Test-MiSideLoaderInitialized $Game){return}
            Write-Host '  BepInEx config or startup log is missing. Run MiSide flat before continuing.' -ForegroundColor Yellow
            continue
        }
        if($raw -ne ''){Write-Host '  Choose Enter, S or Q.' -ForegroundColor Yellow;continue}
        Write-Host '  Opening MiSide flat through Steam now. Close it before returning here.' -ForegroundColor White
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            if($env:PCVR_MISIDE_TEST_SIMULATE_FLAT -ne '1'){throw 'A fixture cannot launch the real Steam game.'}
            $config=Join-Path $Game 'BepInEx\config\BepInEx.cfg';[void][IO.Directory]::CreateDirectory((Split-Path -Parent $config))
            [IO.File]::WriteAllText($config,'fixture loader configuration')
            [IO.File]::WriteAllText((Join-Path $Game 'BepInEx\LogOutput.log'),'BepInEx Chainloader startup complete - fixture only')
        }else{Start-Process 'steam://rungameid/2527500' -ErrorAction Stop}
        [void](Wait-PCVRExplicitEnter -Message 'After closing MiSide, press Enter to check BepInEx...')
        if(Get-Process -Name 'MiSideFull' -ErrorAction SilentlyContinue){Write-Host '  Close MiSide before continuing.' -ForegroundColor Yellow;continue}
        if(Test-MiSideLoaderInitialized $Game){return}
        Write-Host '  BepInEx config or startup log is still missing. Try the flat launch again.' -ForegroundColor Yellow
    }
}
function Invoke-MiSideInstaller{
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  MiSide VR - Installer' -ForegroundColor Cyan
        Write-Host '  Steam; SteamVR; 6DoF motion controls' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Requires the Steam MiSide game and SteamVR.' -ForegroundColor White
        Write-Host '  Setup installs the author-required BepInEx IL2CPP 6.0.0-pre.2 first.' -ForegroundColor White
        Write-Host '  The game must then run flat once to initialize BepInEx before VR files.' -ForegroundColor White
        Write-Host '  Saves, existing config and unrelated plugins are preserved.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to find MiSide...')

        Write-Host '';Write-Host '--- [1/6] Find and check the Steam game ---' -ForegroundColor Cyan
        $game=Get-MiSideGameRoot;if(-not $game){throw 'Setup stopped before changing the game folder.'}
        if(Get-Process -Name 'MiSideFull' -ErrorAction SilentlyContinue){throw 'Close MiSide before installing or updating.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable.'}
        if(-not $env:PCVR_MISIDE_TEST_GAME){if(-not(Save-HubRememberedGameFolder -GameId $script:MiSideId -Title 'MiSide VR' -GameDir $game -ProbeFiles @('MiSideFull.exe') -UserSelected)){throw 'The selected game location could not be saved.'}}
        Write-Host "  [OK] Base game found: $game" -ForegroundColor Green

        Write-Host '';Write-Host '--- [2/6] Get the pinned loader and current VR release ---' -ForegroundColor Cyan
        Write-Host '  Next: official BepInEx 6.0.0-pre.2 and the stable MiSide VR GitHub ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download both packages...')
        $release=Get-MiSideRelease
        if(-not(Test-IsTrackableInstalledVersion $release.Tag)){throw 'GitHub supplied no trackable MiSide VR version.'}
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_miside_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $bepArchive=Join-Path $work 'BepInEx-Unity.IL2CPP-win-x64.zip'
        $testBep=(''+$env:PCVR_MISIDE_TEST_BEP_ARCHIVE).Trim()
        if($testBep){Copy-Item -LiteralPath $testBep -Destination $bepArchive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($script:MiSideBepUrl) -Destination $bepArchive -Label 'BepInEx Unity IL2CPP 6.0.0-pre.2' -ManualUrl 'https://github.com/BepInEx/BepInEx/releases/tag/v6.0.0-pre.2' -AllowSkip $false)}
        $modArchive=Join-Path $work 'MiSide_VR.zip'
        if($release.IsLocal){Copy-Item -LiteralPath $release.Url -Destination $modArchive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $modArchive -Label "MiSide VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl $release.PageUrl -AllowSkip $false)}
        $bepStage=New-MiSideStage -Archive $bepArchive -Work $work -Name 'bep' -Proof 'BepInEx\core\BepInEx.Unity.IL2CPP.dll' -Required $script:MiSideBepProof
        $modStage=New-MiSideStage -Archive $modArchive -Work $work -Name 'mod' -Proof 'BepInEx\plugins\MiSide_VR\MiSide_VR.dll' -Required $script:MiSideModProof
        Write-Host '  [OK] Loader and VR payload staged; no game data in either ZIP.' -ForegroundColor Green
        $otherPlugins=@(Get-ChildItem -LiteralPath (Join-Path $game 'BepInEx\plugins') -Recurse -File -Filter '*.dll' -ErrorAction SilentlyContinue |
            Where-Object {$_.FullName -notmatch '(?i)[\\/]MiSide_VR[\\/]MiSide_VR\.dll$'})
        $sharedLoader=($otherPlugins.Count -gt 0)
        if($sharedLoader -and -not(Test-MiSideLoaderStageIdentical -Game $game -Stage $bepStage)){
            throw 'Other BepInEx plugins use a different loader. Use a clean MiSide copy; setup did not change this shared runtime.'
        }

        Write-Host '';Write-Host '--- [3/6] Protect existing files ---' -ForegroundColor Cyan
        Write-MiSideProofCheckpoint -Label before-copy -Game $game
        $snapshot=Save-MiSideSnapshot -Game $game -Stages @($bepStage,$modStage) -Root (Join-Path $work 'rollback')
        Write-Host '  [OK] Existing collisions and ownership protected.' -ForegroundColor Green

        Write-Host '';Write-Host '--- [4/6] Install BepInEx and initialize it ---' -ForegroundColor Cyan
        $changed=$true
        if($sharedLoader){Write-Host '  [OK] Existing shared loader matches the publisher-pinned package; it stays untouched.' -ForegroundColor Green}
        else{[void](Install-OwnedModPayload -SourceRoot $bepStage -GameRoot $game -Identity 'miside_bep' -KeepExistingRelativePaths @('BepInEx\config\BepInEx.cfg'))}
        foreach($relative in $script:MiSideBepProof){if(-not(Test-Path -LiteralPath (Join-Path $game $relative) -PathType Leaf)){throw "BepInEx file missing after copy: $relative"}}
        Wait-MiSideFirstFlatLaunch -Game $game

        Write-Host '';Write-Host '--- [5/6] Install and verify MiSide VR ---' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $modStage -GameRoot $game -Identity 'misidevr')
        Write-MiSideProofCheckpoint -Label after-copy -Game $game
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and (''+$env:PCVR_MISIDE_TEST_REMOVE_AFTER_COPY).Trim()){
            $relative=Assert-PCVROwnedRelativePath -Relative ([string]$env:PCVR_MISIDE_TEST_REMOVE_AFTER_COPY)
            if($relative -notin $script:MiSideModProof){throw 'Invalid MiSide test fault injection target.'}
            Remove-Item -LiteralPath (Join-Path $game $relative) -Force -ErrorAction Stop
        }
        $watch=@(($script:MiSideBepProof+$script:MiSideModProof)|ForEach-Object{Join-Path $game $_})+@(Join-Path $game '.pcvrhub_misidevr_ownership.csv')
        if(-not $sharedLoader){$watch+=Join-Path $game '.pcvrhub_miside_bep_ownership.csv'}
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required MiSide VR files are missing after installation.'}
        Write-MiSideProofCheckpoint -Label after-observation -Game $game
        $receipt=(''+$env:PCVR_MISIDE_TEST_RECEIPT).Trim();if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:MiSideContract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false

        Write-Host '';Write-Host '--- [6/6] Setup complete ---' -ForegroundColor Cyan
        Write-Host "  [OK] MiSide VR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  Start SteamVR before launching MiSide from Steam.' -ForegroundColor White
        Write-Host '  Settings: BepInEx\config\com.Glitchtest51.MiSide_VR.cfg' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  Mita has new ways to keep you from leaving.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            Write-MiSideProofCheckpoint -Label before-rollback -Game $game
            try{Restore-MiSideSnapshot -Game $game -Snapshot $snapshot;Write-MiSideProofCheckpoint -Label after-rollback -Game $game;Write-Host '  [!!] Previous MiSide files restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host "  [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}
        }
        throw
    }finally{if($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_MISIDE_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-MiSideInstaller}

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='High Entropy: Challenges VR Installer'
$script:HecId='high-entropy-challenges-vr'
$script:HecIdentity='hecvr'
$script:HecRepo='King-EJ/High-Entropy-Challenges-VR'
$script:HecReleases="https://github.com/$script:HecRepo/releases"
$script:HecFallback='https://github.com/King-EJ/High-Entropy-Challenges-VR/releases/download/HighEntropyChallengesVR/HighEntropyChallengesVR.zip'
$script:HecProof=@('BepInEx\plugins\HECVR\HECVR.dll','BepInEx\plugins\HECVR\OpenXR.dll',
    'BepInEx\core\BepInEx.dll','doorstop_config.ini','winhttp.dll')
$script:HecContract=New-PCVRInstallerContract -Id $script:HecId -GameName 'High Entropy: Challenges VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:HecReleases `
    -RequiredInstalledFileGroups @($script:HecProof + '.pcvrhub_hecvr_ownership.csv')

function Test-HecGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'HighEntropy.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'HighEntropy_Data\globalgamemanagers') -PathType Leaf))
}
function Confirm-HecInputDevice {
    Write-Host ''
    Write-Host '  In High Entropy: Options > Controls > Input device must be' -ForegroundColor White
    Write-Host '  Automatic or Gamepad for VR controller input.' -ForegroundColor White
    Write-Host '  Keyboard and mouse cannot navigate the VR main menu in this mode.' -ForegroundColor Yellow
    Write-Host '  Virtual Desktop Gamepad mode lets you open the menu and switch' -ForegroundColor White
    Write-Host '  Input device from Keyboard/Mouse to Gamepad.' -ForegroundColor White
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HEC_TEST_INPUT_READY -eq '1'){
        Write-Host '  [OK] Isolated fixture confirms the input setting.' -ForegroundColor Green
        return
    }
    while($true){
        $answer=(''+(Read-Host '  Already set? [Y] Yes / [L] Launch flat game / [Q] Cancel')).Trim().ToUpperInvariant()
        if($answer -eq 'Y'){return}
        if($answer -eq 'Q'){throw 'Setup cancelled before checking the required input setting.'}
        if($answer -ne 'L'){Write-Host '  Choose Y, L or Q.' -ForegroundColor Yellow;continue}
        Write-Host '  Steam will open High Entropy flat. Set Input device to' -ForegroundColor White
        Write-Host '  Automatic or Gamepad, save it, then close the game.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to launch the flat game from Steam...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'A fixture cannot launch the real Steam game.'}
        Start-Process 'steam://rungameid/1389630' -ErrorAction Stop
        [void](Wait-PCVRExplicitEnter -Message 'After changing the setting and closing the game, press Enter...')
        if(Get-Process -Name 'HighEntropy' -ErrorAction SilentlyContinue){
            Write-Host '  Close High Entropy before returning to setup.' -ForegroundColor Yellow
            continue
        }
    }
}
function Get-HecGameRoot {
    $test=(''+$env:PCVR_HEC_TEST_GAME).Trim()
    if($test){if(Test-HecGame $test){return (Get-Item -LiteralPath $test).FullName};throw 'The selected High Entropy test folder lacks its base game.'}
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        $prior=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
        if(Test-HecGame $prior){return (Get-Item -LiteralPath $prior).FullName}
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:HecId -StateNames @('installed_path','user_located') -ProbeFiles @('HighEntropy.exe')
    if(Test-HecGame $saved){return (Get-Item -LiteralPath $saved).FullName}
    $found=Find-SteamGameFolder -AppId '1389630' -SteamFolderNames @('High Entropy Challenges') `
        -ProbeExe 'HighEntropy.exe' -HubGameId $script:HecId
    if(Test-HecGame $found){return (Get-Item -LiteralPath $found).FullName}
    $manual=Get-GameFolderInteractive -GameName 'High Entropy: Challenges' -ProbeFile 'HighEntropy.exe' -ManualUrl $script:HecReleases
    if($manual -and $manual -notin @('quit','skip') -and (Test-HecGame $manual)){return (Get-Item -LiteralPath $manual).FullName}
    return $null
}
function Get-HecRelease {
    $test=(''+$env:PCVR_HEC_TEST_ARCHIVE).Trim()
    if($test){return [pscustomobject]@{Url=$test;Name='HighEntropyChallengesVR.zip';PageUrl=$script:HecReleases;IsLocal=$true}}
    $r=Resolve-GitHubReleaseAsset -Repo $script:HecRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^HighEntropyChallengesVR\.zip$') -FallbackUrl $script:HecFallback `
        -FallbackTag 'HighEntropyChallengesVR' -FallbackAssetName 'HighEntropyChallengesVR.zip' -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Url=[string]$r.Url;Name=[string]$r.AssetName;PageUrl=[string]$r.PageUrl;IsLocal=$false}
}
function New-HecStage([string]$Archive,[string]$Work) {
    $outer=Join-Path $Work 'publisher'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'HECVR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The HECVR ZIP could not be opened.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $outer -RelModFile 'BepInEx\plugins\HECVR\HECVR.dll'
    if(-not $payload){throw 'The publisher ZIP has no HECVR plugin.'}
    foreach($relative in $script:HecProof){if(-not(Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)){throw "Publisher ZIP is missing $relative"}}
    $readme=Join-Path $payload 'README_HEC_VR.txt'
    if(-not(Test-Path -LiteralPath $readme -PathType Leaf)){throw 'Publisher ZIP has no versioned README.'}
    $match=[regex]::Match([IO.File]::ReadAllText($readme),'(?im)^Version\s+([0-9]+(?:\.[0-9]+)+)\b')
    if(-not $match.Success -or -not(Test-IsTrackableInstalledVersion $match.Groups[1].Value)){throw 'Publisher ZIP has no trackable HECVR version.'}
    $stage=Join-Path $Work 'stage';[void][IO.Directory]::CreateDirectory($stage)
    foreach($file in @(Get-ChildItem -LiteralPath $payload -Recurse -File -Force -ErrorAction Stop)){
        $relative=$file.FullName.Substring($payload.Length+1)
        if($relative -match '^(?i:BepInEx[\\/]cache[\\/]|BepInEx[\\/]LogOutput\.log$)'){continue}
        $target=Join-OwnedRelativePath -Root $stage -Relative $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
    }
    return [pscustomobject]@{Root=$stage;Version=$match.Groups[1].Value}
}
function Save-HecSnapshot([string]$Game,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){[void]$paths.Add($file.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Game '.pcvrhub_hecvr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){
        foreach($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)){
            if($row.RelativePath){[void]$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}
        }
    }
    foreach($name in @('.pcvrhub_hecvr_ownership.csv','.pcvrhub_hecvr_ownership.csv.new','.pcvrhub_version')){[void]$paths.Add($name)}
    $records=@()
    foreach($relative in @($paths|Select-Object -Unique)){
        $source=Join-OwnedRelativePath -Root $Game -Relative $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-OwnedRelativePath -Root (Join-Path $SnapshotRoot 'files') -Relative $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_hecvr_backup'
    $hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Root=$SnapshotRoot;Records=$records;HadBackup=$hadBackup}
}
function Restore-HecSnapshot([string]$Game,$Snapshot) {
    foreach($row in @($Snapshot.Records)){
        $target=Join-OwnedRelativePath -Root $Game -Relative ([string]$row.Relative)
        if($row.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$row.Relative)) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_hecvr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Invoke-HecInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try {
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  High Entropy: Challenges VR - Installer' -ForegroundColor Cyan
        Write-Host '  OpenXR motion controls and bundled BepInEx' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Install the free Steam game and start it flat once before adding VR.' -ForegroundColor White
        Write-Host '  The complete publisher package goes beside HighEntropy.exe.' -ForegroundColor White
        Write-Host '  Saves and existing configuration are kept; name collisions are backed up.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to find the game...')

        Write-Host '';Write-Host '--- [1/5] Locate and check the Steam game ---' -ForegroundColor Cyan
        $game=Get-HecGameRoot
        if(-not $game){throw 'Setup stopped before changing the game folder.'}
        if(Get-Process -Name 'HighEntropy' -ErrorAction SilentlyContinue){throw 'Close High Entropy before installing or updating.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable.'}
        if(-not $env:PCVR_HEC_TEST_GAME){
            if(-not(Save-HubRememberedGameFolder -GameId $script:HecId -Title 'High Entropy: Challenges VR' `
                -GameDir $game -ProbeFiles @('HighEntropy.exe') -UserSelected)){
                throw 'The selected game location could not be saved for the next run.'
            }
        }
        Write-Host "  [OK] Base game found: $game" -ForegroundColor Green
        Confirm-HecInputDevice

        Write-Host '';Write-Host '--- [2/5] Get and inspect the publisher package ---' -ForegroundColor Cyan
        Write-Host '  The next step checks the publisher GitHub release and gets its ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download HECVR...')
        $release=Get-HecRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_hec_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'HighEntropyChallengesVR.zip'
        if($release.IsLocal){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label 'HECVR' -ManualUrl $release.PageUrl -AllowSkip $false)}
        $stage=New-HecStage -Archive $archive -Work $work
        Write-Host "  [OK] Complete publisher runtime staged: $($stage.Version)." -ForegroundColor Green

        Write-Host '';Write-Host '--- [3/5] Protect existing files ---' -ForegroundColor Cyan
        $snapshot=Save-HecSnapshot -Game $game -Stage $stage.Root -SnapshotRoot (Join-Path $work 'rollback')
        Write-Host '  [OK] Previous files and ownership protected.' -ForegroundColor Green

        Write-Host '';Write-Host '--- [4/5] Install and verify VR ---' -ForegroundColor Cyan
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage.Root -GameRoot $game -Identity $script:HecIdentity `
            -KeepExistingRelativePaths @('BepInEx\config\BepInEx.cfg','BepInEx\config\hec.vr.cfg','doorstop_config.ini'))
        $watch=@($script:HecProof|ForEach-Object{Join-Path $game $_})+@(Join-Path $game '.pcvrhub_hecvr_ownership.csv')
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required HECVR files are missing after installation.'}
        $receipt=(''+$env:PCVR_HEC_TEST_RECEIPT).Trim()
        if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:HecContract -GameDir $game -Version $stage.Version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false

        Write-Host '';Write-Host '--- [5/5] Setup complete ---' -ForegroundColor Cyan
        Write-Host "  [OK] HECVR $($stage.Version) is installed." -ForegroundColor Green
        Write-Host '  Start your OpenXR runtime, then launch High Entropy from Steam.' -ForegroundColor White
        Write-Host '  Set the game input device to Automatic or Gamepad.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  When the doors will not open, the right answer is often a terminal.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if($changed -and $snapshot -and $game){
            try{Restore-HecSnapshot -Game $game -Snapshot $snapshot;Write-Host '  [!!] Previous HECVR files were restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host "  [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}
        }
        throw
    } finally {
        if($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
if(((''+$env:PCVR_HEC_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-HecInstaller}

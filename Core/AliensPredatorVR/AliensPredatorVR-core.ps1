$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='Aliens versus Predator VR Installer'
$script:AvpId='aliens-versus-predator-vr'
$script:AvpIdentity='avpvr'
$script:AvpRepo='Bassquake/Aliens-Versus-Predator-VR'
$script:AvpReleases="https://github.com/$script:AvpRepo/releases"
$script:AvpFallback='https://github.com/Bassquake/Aliens-Versus-Predator-VR/releases/download/1.2/avpvr-1.2-windows-x64-vr.zip'
$script:AvpProof=@('avpvr_x64.exe','openxr_loader.dll','OpenAL32.dll','SDL3.dll',
    'avcodec-62.dll','avdevice-62.dll','avfilter-11.dll','avformat-62.dll','avutil-60.dll',
    'swresample-6.dll','swscale-9.dll')
$script:AvpContract=New-PCVRInstallerContract -Id $script:AvpId -GameName 'Aliens versus Predator VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:AvpReleases `
    -RequiredInstalledFileGroups @($script:AvpProof + '.pcvrhub_avpvr_ownership.csv')

function Get-AvpBaseExecutable([string]$Root){
    if(-not $Root){return $null}
    foreach($relative in @('AvP.exe','AvP_Classic.exe','bin\AvP_Classic.exe','bin\_Crossplay\AvP_Classic.exe')){
        if(Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf){return $relative}
    }
    return $null
}
function Test-AvpGame([string]$Root){
    if(-not $Root){return $false}
    if(-not(Get-AvpBaseExecutable $Root)){return $false}
    foreach($name in @('AvP_Rifs','fastfile','FMVs')){
        if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Container)){return $false}
        if(-not @(Get-ChildItem -LiteralPath (Join-Path $Root $name) -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).Count){return $false}
    }
    return [bool](Test-Path -LiteralPath (Join-Path $Root 'language.txt') -PathType Leaf)
}
function Get-AvpGameRoot{
    $test=(''+$env:PCVR_AVP_TEST_GAME).Trim()
    if($test){if(Test-AvpGame $test){return (Get-Item -LiteralPath $test).FullName};throw 'The AvP fixture lacks the original game EXE or required assets.'}
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        $prior=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
        if(Test-AvpGame $prior){return (Get-Item -LiteralPath $prior).FullName}
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:AvpId -StateNames @('installed_path','user_located') -ProbeFiles @()
    if(Test-AvpGame $saved){return (Get-Item -LiteralPath $saved).FullName}
    $found=Find-SteamGameFolder -AppId '3730' -SteamFolderNames @('Aliens versus Predator Classic','Aliens versus Predator Classic 2000') `
        -GogNames @('Aliens versus Predator Classic 2000','Aliens versus Predator Gold') -ProbeExe 'AvP.exe' -HubGameId $script:AvpId
    if(Test-AvpGame $found){return (Get-Item -LiteralPath $found).FullName}
    foreach($candidate in @('C:\Program Files (x86)\Steam\steamapps\common\Aliens versus Predator Classic 2000',
            'C:\Program Files (x86)\Steam\steamapps\common\Aliens versus Predator Classic',
            'C:\Program Files (x86)\GOG Galaxy\Games\AvP Classic','C:\GOG Games\AvP Classic',
            'C:\Program Files (x86)\Fox\Aliens versus Predator')){
        if(Test-AvpGame $candidate){return (Get-Item -LiteralPath $candidate).FullName}
    }
    $manual=Get-GameFolderInteractive -GameName 'Aliens versus Predator Gold Edition' -ManualUrl $script:AvpReleases
    if($manual -and $manual -notin @('quit','skip') -and (Test-AvpGame $manual)){return (Get-Item -LiteralPath $manual).FullName}
    return $null
}
function Get-AvpRelease{
    $test=(''+$env:PCVR_AVP_TEST_ARCHIVE).Trim()
    if($test){$tag=if($env:PCVR_AVP_TEST_RELEASE_TAG){[string]$env:PCVR_AVP_TEST_RELEASE_TAG}else{'1.1'};return [pscustomobject]@{Tag=$tag;Url=$test;PageUrl=$script:AvpReleases;IsLocal=$true}}
    $r=Resolve-GitHubReleaseAsset -Repo $script:AvpRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^avpvr-[0-9][^-]*-windows-x64-vr\.zip$') -FallbackUrl $script:AvpFallback `
        -FallbackTag '1.2' -FallbackAssetName 'avpvr-1.2-windows-x64-vr.zip' -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;PageUrl=[string]$r.PageUrl;IsLocal=$false}
}
function New-AvpStage([string]$Archive,[string]$Work,[string]$ReleaseTag){
    $outer=Join-Path $Work 'publisher'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'AvP PCVR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The AvP Windows x64 PCVR ZIP could not be opened.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $outer -RelModFile 'avpvr_x64.exe'
    if(-not $payload){throw 'The publisher ZIP has no PCVR executable.'}
    foreach($relative in $script:AvpProof){if(-not(Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)){throw "Publisher ZIP is missing $relative"}}
    if($ReleaseTag -notmatch '^\d+(?:\.\d+){1,3}$'){throw 'The selected AvP VR release has no comparable version.'}
    $parts=@($ReleaseTag.Split('.'));while($parts.Count -lt 4){$parts+=@('0')}
    $expected=[version]($parts -join '.')
    $actual=[Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $payload 'avpvr_x64.exe')).ProductVersion
    if(-not $actual -or $actual -notmatch '^\d+(?:\.\d+){1,3}$' -or [version]$actual -ne $expected){
        throw "The AvP VR executable version does not match the selected release ($ReleaseTag). No game files were changed."
    }
    $stage=Join-Path $Work 'stage';[void][IO.Directory]::CreateDirectory($stage)
    foreach($item in @(Get-ChildItem -LiteralPath $payload -Force)){
        Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse -Force -ErrorAction Stop
    }
    return $stage
}
function Assert-AvpNoDowngrade([string]$Game,[string]$ReleaseTag){
    $receipt=Join-Path $Game '.pcvrhub_version'
    if(-not(Test-Path -LiteralPath $receipt -PathType Leaf) -or $ReleaseTag -notmatch '^\d+(?:\.\d+){1,3}$'){return}
    foreach($relative in $script:AvpProof){if(-not(Test-Path -LiteralPath (Join-Path $Game $relative) -PathType Leaf)){return}}
    $saved=([IO.File]::ReadAllText($receipt)).Trim()
    if($saved -match '^\d+(?:\.\d+){1,3}$' -and [version]$saved -gt [version]$ReleaseTag){
        throw "AvP VR $saved is already installed. Retry the current release download; the fallback cannot downgrade it."
    }
}
function Save-AvpSnapshot([string]$Game,[string]$Stage,[string]$Root){
    [void][IO.Directory]::CreateDirectory($Root)
    $paths=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -File)){[void]$paths.Add($file.Name)}
    $manifest=Join-Path $Game '.pcvrhub_avpvr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)){
        if($row.RelativePath){[void]$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}
    }}
    foreach($name in @('.pcvrhub_avpvr_ownership.csv','.pcvrhub_avpvr_ownership.csv.new','.pcvrhub_version')){[void]$paths.Add($name)}
    $records=@()
    foreach($relative in @($paths|Select-Object -Unique)){
        $source=Join-OwnedRelativePath -Root $Game -Relative $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-OwnedRelativePath -Root (Join-Path $Root 'files') -Relative $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_avpvr_backup'
    $hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Root 'ownership-backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Root=$Root;Records=$records;HadBackup=$hadBackup}
}
function Restore-AvpSnapshot([string]$Game,$Snapshot){
    foreach($row in @($Snapshot.Records)){
        $target=Join-OwnedRelativePath -Root $Game -Relative ([string]$row.Relative)
        if($row.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$row.Relative)) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_avpvr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Write-AvpProofCheckpoint([string]$Label,[string]$Game){
    $files=if($script:AvpActiveProof){$script:AvpActiveProof}else{$script:AvpProof}
    foreach($relative in $files){
        Write-Host ("  [{0}] {1}: {2}" -f $Label,$relative,[bool](Test-Path -LiteralPath (Join-Path $Game $relative) -PathType Leaf)) -ForegroundColor DarkGray
    }
}
function Invoke-AvpInstaller{
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Aliens versus Predator VR - Installer' -ForegroundColor Cyan
        Write-Host '  Windows x64 PCVR; owned Gold Edition game assets required' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  This package contains only the VR runtime. Your licensed Gold Edition' -ForegroundColor White
        Write-Host '  game EXE and data must already be installed, including Gold language.txt.' -ForegroundColor White
        Write-Host '  Setup cannot prove the language file edition by its filename alone.' -ForegroundColor Yellow
        Write-Host '  Existing same-name files are backed up; game data and saves stay in place.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to find the game...')

        Write-Host '';Write-Host '--- [1/5] Find and check licensed game data ---' -ForegroundColor Cyan
        $game=Get-AvpGameRoot
        if(-not $game){throw 'Setup stopped before changing the game folder.'}
        if(Get-Process -Name 'AvP','avpvr_x64' -ErrorAction SilentlyContinue){throw 'Close Aliens versus Predator before installing or updating.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable.'}
        if(-not $env:PCVR_AVP_TEST_GAME){if(-not(Save-HubRememberedGameFolder -GameId $script:AvpId -Title 'Aliens versus Predator VR' -GameDir $game -ProbeFiles @((Get-AvpBaseExecutable $game)) -UserSelected)){throw 'The selected game location could not be saved.'}}
        Write-Host "  [OK] Base game and assets found: $game" -ForegroundColor Green

        Write-Host '';Write-Host '--- [2/5] Get the Windows x64 PCVR release ---' -ForegroundColor Cyan
        Write-Host '  The next step checks the publisher GitHub release and gets its PCVR ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download AvP VR...')
        $release=Get-AvpRelease
        if(-not(Test-IsTrackableInstalledVersion $release.Tag)){throw 'GitHub supplied no trackable AvP VR version.'}
        Assert-AvpNoDowngrade -Game $game -ReleaseTag ([string]$release.Tag)
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_avp_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'avpvr-windows-x64-vr.zip'
        if($release.IsLocal){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "AvP VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl $release.PageUrl -AllowSkip $false)}
        $stage=New-AvpStage -Archive $archive -Work $work -ReleaseTag ([string]$release.Tag)
        $script:AvpActiveProof=@(Get-ChildItem -LiteralPath $stage -Recurse -File -Force|ForEach-Object {$_.FullName.Substring($stage.Length+1)})
        $script:AvpContract=New-PCVRInstallerContract -Id $script:AvpId -GameName 'Aliens versus Predator VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:AvpReleases -RequiredInstalledFileGroups @($script:AvpActiveProof + '.pcvrhub_avpvr_ownership.csv')
        Write-Host '  [OK] PCVR executable and all native runtime libraries staged.' -ForegroundColor Green

        Write-Host '';Write-Host '--- [3/5] Protect existing files ---' -ForegroundColor Cyan
        Write-AvpProofCheckpoint -Label before-copy -Game $game
        $snapshot=Save-AvpSnapshot -Game $game -Stage $stage -Root (Join-Path $work 'rollback')
        Write-Host '  [OK] Previous files and ownership protected.' -ForegroundColor Green

        Write-Host '';Write-Host '--- [4/5] Install and verify the VR runtime ---' -ForegroundColor Cyan
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:AvpIdentity)
        Write-AvpProofCheckpoint -Label after-copy -Game $game
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and (''+$env:PCVR_AVP_TEST_REMOVE_AFTER_COPY).Trim()){
            $relative=Assert-PCVROwnedRelativePath -Relative ([string]$env:PCVR_AVP_TEST_REMOVE_AFTER_COPY)
            if($relative -notin $script:AvpActiveProof){throw 'Invalid AvP test fault injection target.'}
            Remove-Item -LiteralPath (Join-Path $game $relative) -Force -ErrorAction Stop
        }
        $watch=@($script:AvpActiveProof|ForEach-Object{Join-Path $game $_})+@(Join-Path $game '.pcvrhub_avpvr_ownership.csv')
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required AvP VR files are missing after installation.'}
        Write-AvpProofCheckpoint -Label after-observation -Game $game
        $receipt=(''+$env:PCVR_AVP_TEST_RECEIPT).Trim();if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:AvpContract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false

        Write-Host '';Write-Host '--- [5/5] Setup complete ---' -ForegroundColor Cyan
        Write-Host "  [OK] Aliens versus Predator VR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  Start SteamVR, then use Start in VR or add avpvr_x64.exe to Steam as a non-Steam VR game.' -ForegroundColor White
        Write-Host '  If the game crashes while reading data, confirm Gold Edition language.txt.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  In space, no one can hear your motion sickness. Watch those walls.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            Write-AvpProofCheckpoint -Label before-rollback -Game $game
            try{Restore-AvpSnapshot -Game $game -Snapshot $snapshot;Write-AvpProofCheckpoint -Label after-rollback -Game $game;Write-Host '  [!!] Previous AvP VR files restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host "  [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}
        }
        throw
    }finally{if($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_AVP_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-AvpInstaller}

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Super Mario 3D World VR Installer'
$script:GameId='super-mario-3d-world-vr'
$script:GameTitle='Super Mario 3D World VR'
$script:Required=@('Start-VR.cmd','Start-VR.ps1','layer\cemuvr_layer.dll','layer\VK_LAYER_CEMUVR_core.json','graphicPacks\Mario3DWorld_VR\rules.txt','graphicPacks\Mario3DWorld_VR\patch_vr.asm','graphicPacks\Mario3DWorld_FPS\rules.txt')
function Test-MarioGame([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root 'code\RedCarpet.rpx') -PathType Leaf)){return $false}
    $meta=Join-Path $Root 'meta\meta.xml'
    if(-not(Test-Path -LiteralPath $meta -PathType Leaf)){return $false}
    try{return [bool]([IO.File]::ReadAllText($meta) -match '(?i)0005000010145(?:D00|C00)')}catch{return $false}
}
function Get-MarioGame {
    $test=(''+$env:PCVR_SM3DW_TEST_GAME).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){if(Test-MarioGame $test){return [IO.Path]::GetFullPath($test)};throw 'The isolated Wii U game fixture lacks its supported title ID or RPX.'}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @('base_game_path','user_located') -ProbeFiles @('code\RedCarpet.rpx','meta\meta.xml')
    if(Test-MarioGame $saved){return [IO.Path]::GetFullPath($saved)}
    while($true){
        Write-Host '  Select your extracted, legally obtained Wii U game folder (code/content/meta).' -ForegroundColor Yellow
        Write-Host '  Supported: European v0 or USA v1. Run the game flat in Cemu 2.6 first.' -ForegroundColor Yellow
        $choice=(''+(Read-Host 'Game folder, or Q to cancel')).Trim().Trim('"')
        if($choice -in @('q','Q','quit')){return $null}
        if(Test-MarioGame $choice){return [IO.Path]::GetFullPath($choice)}
        Write-Host '  The RedCarpet RPX and supported title ID were not found together.' -ForegroundColor Yellow
    }
}
function Test-MarioCemu([string]$Root){return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Cemu.exe') -PathType Leaf))}
function Get-MarioCemu {
    $test=(''+$env:PCVR_SM3DW_TEST_CEMU).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){if(Test-MarioCemu $test){return [IO.Path]::GetFullPath($test)};throw 'The isolated Cemu fixture has no Cemu.exe.'}
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @('cemu_path') -ProbeFiles @('Cemu.exe')
    if(Test-MarioCemu $saved){return [IO.Path]::GetFullPath($saved)}
    foreach($path in @('C:\Games\Cemu','C:\Games\Breath of the Wild VR','D:\Games\Cemu','E:\Games\Cemu')){if(Test-MarioCemu $path){return [IO.Path]::GetFullPath($path)}}
    while($true){
        Write-Host '  Select your writable Cemu 2.6 folder containing Cemu.exe.' -ForegroundColor Yellow
        $choice=(''+(Read-Host 'Cemu folder, or Q to cancel')).Trim().Trim('"')
        if($choice -in @('q','Q','quit')){return $null}
        if(Test-MarioCemu $choice){return [IO.Path]::GetFullPath($choice)}
        Write-Host '  Cemu.exe was not found in that folder.' -ForegroundColor Yellow
    }
}
function Assert-MarioTarget([string]$Cemu){
    $full=[IO.Path]::GetFullPath($Cemu).TrimEnd([char[]]'\/')
    if(-not(Test-MarioCemu $full)){throw 'Cemu.exe was not found at the chosen destination.'}
    $target=Join-Path $full 'Mario3DWorld-VR'
    if(Test-Path -LiteralPath $target){$item=Get-Item -LiteralPath $target -Force;if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'A linked VR folder cannot be changed safely.'}}
    $probe=Join-Path $full ('.pcvr-mario-write-'+[Guid]::NewGuid().ToString('N'))
    try{[IO.File]::WriteAllText($probe,'ok');Remove-Item -LiteralPath $probe -Force -ErrorAction Stop}catch{throw 'Cemu must be in a writable folder outside Program Files.'}
    return $target
}
function Save-MarioSnapshot([string]$Target,[string]$Snapshot){
    [void][IO.Directory]::CreateDirectory($Snapshot);$exists=Test-Path -LiteralPath $Target -PathType Container
    if($exists){foreach($item in @(Get-ChildItem -LiteralPath $Target -Force -ErrorAction Stop)){Copy-Item -LiteralPath $item.FullName -Destination $Snapshot -Recurse -Force -ErrorAction Stop}}
    return [pscustomobject]@{Exists=$exists;Root=$Snapshot}
}
function Restore-MarioSnapshot([string]$Target,$Snapshot){
    $full=[IO.Path]::GetFullPath($Target).TrimEnd([char[]]'\/')
    if((Split-Path -Leaf $full) -cne 'Mario3DWorld-VR' -or -not(Test-MarioCemu (Split-Path -Parent $full))){throw 'Rollback target is not a proven Cemu VR folder.'}
    if(Test-Path -LiteralPath $full -PathType Container){Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop}
    if($Snapshot.Exists){[void][IO.Directory]::CreateDirectory($full);foreach($item in @(Get-ChildItem -LiteralPath $Snapshot.Root -Force -ErrorAction Stop)){Copy-Item -LiteralPath $item.FullName -Destination $full -Recurse -Force -ErrorAction Stop}}
}
function Get-MarioComparableVersion([string]$Tag){
    if($Tag -notmatch '^alpha-(\d+(?:\.\d+){1,3})([a-z]?)$'){return $null}
    if($Tag -eq 'alpha-1.41'){return [version]'1.4.1'}
    $numeric=$Matches[1];$suffix=$Matches[2]
    if(-not $suffix){return [version]$numeric}
    $parts=@($numeric.Split('.'))
    if($parts.Count -gt 3){return $null}
    while($parts.Count -lt 3){$parts+=@('0')}
    $suffixNumber=([int][char]$suffix.ToLowerInvariant())-([int][char]'a')+1
    return [version](($parts -join '.')+'.'+$suffixNumber)
}
function Assert-MarioNoDowngrade([string]$Target,[string]$ReleaseTag){
    $receipt=Join-Path $Target '.pcvrhub_version'
    if(-not(Test-Path -LiteralPath $receipt -PathType Leaf)){return}
    foreach($relative in $script:Required){if(-not(Test-Path -LiteralPath (Join-Path $Target $relative) -PathType Leaf)){return}}
    $installed=Get-MarioComparableVersion (([IO.File]::ReadAllText($receipt)).Trim())
    $selected=Get-MarioComparableVersion $ReleaseTag
    if($installed -and $selected -and $installed -gt $selected){throw "A newer Mario 3D World VR version is already installed. Retry the current download; this fallback cannot downgrade it."}
}
function Assert-MarioPublisherVersion([string]$Payload,[string]$ReleaseTag){
    $versionFile=Join-Path $Payload 'VERSION'
    if(-not(Test-Path -LiteralPath $versionFile -PathType Leaf)){throw 'The publisher install ZIP has no VERSION file. No Cemu files were changed.'}
    if($ReleaseTag -notmatch '^alpha-(\d+(?:\.\d+){1,3}[a-z]?)$'){throw 'The selected Mario VR release has no comparable version.'}
    $expected='Alpha '+$Matches[1]
    $actual=([IO.File]::ReadAllText($versionFile)).Trim()
    if(-not [string]::Equals($actual,$expected,[StringComparison]::OrdinalIgnoreCase)){
        throw "The Mario VR package version does not match the selected release ($ReleaseTag). No Cemu files were changed."
    }
}
function Invoke-MarioInstaller {
    $work=$null;$target=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Super Mario 3D World VR - Installer' -ForegroundColor Cyan
        Write-Host ' Cemu 2.6 + your own Wii U game, OpenXR alpha' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' This setup adds the complete VR folder beside Cemu.exe.' -ForegroundColor White
        Write-Host ' It does not copy or modify your Wii U game, Cemu saves or keys.' -ForegroundColor White
        Write-Host ' Run the game flat in Cemu first; close Cemu before installing.' -ForegroundColor Yellow
        Write-Host ' Supported builds: European v0 or USA v1 only.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to select the game and Cemu folders, then download the VR release...')
        $game=Get-MarioGame;if(-not $game){return}
        $cemu=Get-MarioCemu;if(-not $cemu){return}
        if(Get-Process -Name @('Cemu','cemu') -ErrorAction SilentlyContinue){throw 'Close Cemu before setup.'}
        $target=Assert-MarioTarget -Cemu $cemu
        Write-Host "  [OK] Wii U game: $game" -ForegroundColor Green
        Write-Host "  [OK] Cemu: $cemu" -ForegroundColor Green
        $local=(''+$env:PCVR_SM3DW_TEST_ARCHIVE).Trim()
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $local){$tag=if($env:PCVR_SM3DW_TEST_RELEASE_TAG){[string]$env:PCVR_SM3DW_TEST_RELEASE_TAG}else{'alpha-1.6'};$release=[pscustomobject]@{Tag=$tag;Url=$local;PageUrl='https://github.com/Destroyjevski/SuperMario3DWorld-VR/releases';Local=$true}}
        else{
            $asset=Resolve-GitHubReleaseAsset -Repo 'Destroyjevski/SuperMario3DWorld-VR' -IncludePrerelease $true -AssetPatterns @('(?i)^SuperMario3DWorld-VR-Alpha-[0-9.]+[a-z]?-install\.zip$') -FallbackUrl 'https://github.com/Destroyjevski/SuperMario3DWorld-VR/releases/download/alpha-1.6b/SuperMario3DWorld-VR-Alpha-1.6b-install.zip' -FallbackTag 'alpha-1.6b' -FallbackAssetName 'SuperMario3DWorld-VR-Alpha-1.6b-install.zip' -SkipReleasesWithoutMatchingAsset
            $release=[pscustomobject]@{Tag=[string]$asset.Tag;Url=[string]$asset.Url;PageUrl=[string]$asset.PageUrl;Local=$false}
        }
        Assert-MarioNoDowngrade -Target $target -ReleaseTag ([string]$release.Tag)
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_sm3dw_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'publisher.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{$download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "Super Mario 3D World VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false;if(-not($download -eq $true -or [string]$download -in @('retry','manual'))){throw 'The publisher release was not downloaded.'}}
        $extract=Join-Path $work 'release';$result=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Super Mario 3D World VR' -AllowSkip $false -QuietProgress
        if([string]$result -notin @('ok','manual','retry')){throw 'The publisher ZIP could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'Start-VR.cmd'
        if(-not $payload){throw 'The installation ZIP contains no Start-VR.cmd.'}
        foreach($name in $script:Required){if(-not(Test-Path -LiteralPath (Join-Path $payload $name) -PathType Leaf)){throw "The publisher ZIP is missing $name."}}
        Assert-MarioPublisherVersion -Payload $payload -ReleaseTag ([string]$release.Tag)
        $snapshot=Save-MarioSnapshot -Target $target -Snapshot (Join-Path $work 'rollback')
        [void][IO.Directory]::CreateDirectory($target);$changed=$true
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity 'sm3dwvr' -AdoptIdenticalExisting)
        $watch=@($script:Required|ForEach-Object{Join-Path $target $_})
        $recopy={ [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity 'sm3dwvr' -AdoptIdenticalExisting) }.GetNewClosure()
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $target -Recopy $recopy)){throw 'Required VR files did not survive the post-copy check.'}
        $contract=New-PCVRInstallerContract -Id $script:GameId -GameName $script:GameTitle -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ([string]$release.PageUrl) -RequiredInstalledFileGroups (@($script:Required)+@('.pcvrhub_sm3dwvr_ownership.csv'))
        if(-not(Save-HubRememberedGameFolder -GameId $script:GameId -Title $script:GameTitle -GameDir $game -ProbeFiles @('code\RedCarpet.rpx','meta\meta.xml') -StateName 'base_game_path')){throw 'The owned game path could not be remembered.'}
        if(-not(Save-HubRememberedGameFolder -GameId $script:GameId -Title $script:GameTitle -GameDir $cemu -ProbeFiles @('Cemu.exe') -StateName 'cemu_path')){throw 'The Cemu folder could not be remembered.'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $changed=$false
        Write-Host "  [OK] Super Mario 3D World VR $($release.Tag) is installed and tracked." -ForegroundColor Green
        Write-Host '  Use Hub Play, then launch your own game from Cemu. R3 cycles camera modes.' -ForegroundColor White
        Write-Host ''
        Write-Host '  One more stamp, one more star, and now the whole level has depth.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $target -and $snapshot){try{Restore-MarioSnapshot -Target $target -Snapshot $snapshot;Write-Host '  [!!] The previous VR folder was restored.' -ForegroundColor Yellow}catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}}
        Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red;throw
    }finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_SM3DW_LIBRARY_ONLY -ne '1'){Invoke-MarioInstaller}

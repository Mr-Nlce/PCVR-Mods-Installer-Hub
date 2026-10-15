# Turok VR: Steam KEX4 edition; OpenXR/Vulkan; GitHub release asset.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$APP_ID='405820';$GAME_EXE='sobek_Shipping_Steam_x64.exe';$REPO='VinceCrusty/TurokVR'
$RELEASES="https://github.com/$REPO/releases";$FALLBACK_TAG='0.93.5-beta'
$FALLBACK_ASSET='TurokVR_v0.93.5.zip'
$FALLBACK_URL='https://github.com/VinceCrusty/TurokVR/releases/download/0.93.5-beta/TurokVR_v0.93.5.zip'
$IDENTITY='turokvr'
$REQUIRED=@('vulkan-1.dll','turok.assets','steam_appid.txt','openxr_loader.dll',
    'mods\zzzz_VR_Assets.kpf',
    'ControllerGuides\Turok_Right_Handed.png','.pcvrhub_turokvr_ownership.csv')
$CONTRACT=New-PCVRInstallerContract -Id 'turok-vr' -GameName 'Turok VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups $REQUIRED

function Test-TurokGame([string]$Path){return [bool]($Path -and
    (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $Path 'game.kpf') -PathType Leaf))}
function Get-TurokGameRoot {
    $path=$null
    try{$recorded=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"');if(Test-TurokGame $recorded){$path=$recorded}}catch{}
    if(-not $path){$found=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Turok') -ProbeExe $GAME_EXE -HubGameId 'turok-vr';if(Test-TurokGame $found){$path=$found}}
    if(-not $path){$found=Get-GameFolderInteractive -GameName 'Turok' -ProbeFile $GAME_EXE -ManualUrl "https://store.steampowered.com/app/$APP_ID/";if(Test-TurokGame $found){$path=$found;[void](Save-HubRememberedGameFolder -GameId 'turok-vr' -Title 'Turok VR' -GameDir $path -ProbeFiles @($GAME_EXE,'game.kpf') -UserSelected)}}
    if(-not $path){throw 'A complete current Turok KEX4 Steam game folder was not found.'}
    return (Get-Item -LiteralPath $path).FullName
}
function Get-TurokRelease {
    $r=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^TurokVR_v[0-9].*\.zip$') `
        -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -FallbackUrl $FALLBACK_URL `
        -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET
    if(-not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){throw 'GitHub did not return a trackable Turok VR release.'}
    return $r
}
function New-TurokStage([string]$Archive,[string]$Work){
    $outer=Join-Path $Work 'outer';$nested=Join-Path $Work 'nested';$stage=Join-Path $Work 'stage'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'Turok VR publisher archive' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The publisher ZIP could not be opened.'}
    foreach($name in @('turok.assets','vulkan-1.dll','steam_appid.txt')){if(-not(Test-Path -LiteralPath (Join-Path $outer $name) -PathType Leaf)){throw "Publisher ZIP is missing $name"}}
    $nestedZip=Join-Path $Work 'turok-assets.zip';Copy-Item -LiteralPath (Join-Path $outer 'turok.assets') -Destination $nestedZip -Force
    $result=Expand-ArchiveOrFallback -ArchivePath $nestedZip -DestinationFolder $nested -Label 'Turok VR embedded assets' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The embedded Turok assets could not be opened.'}
    foreach($name in @('openxr_loader.dll','mods\zzzz_VR_Assets.kpf','ControllerGuides\Turok_Right_Handed.png')){if(-not(Test-Path -LiteralPath (Join-Path $nested $name) -PathType Leaf)){throw "Embedded publisher assets are missing $name"}}
    [void][IO.Directory]::CreateDirectory($stage)
    foreach($name in @('turok.assets','vulkan-1.dll','steam_appid.txt')){Copy-Item -LiteralPath (Join-Path $outer $name) -Destination (Join-Path $stage $name) -Force}
    foreach($file in @(Get-ChildItem -LiteralPath $nested -Recurse -File)){
        $relative=$file.FullName.Substring($nested.Length+1)
        if($relative -eq 'TurokVRUser.ini'){continue} # Publisher says this is personal configuration.
        $target=Join-Path $stage $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
    return $stage
}
function Save-TurokSnapshot([string]$Game,[string]$Stage,[string]$Destination){
    [void][IO.Directory]::CreateDirectory($Destination);$paths=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$paths.Add($file.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Game ".pcvrhub_${IDENTITY}_ownership.csv"
    if(Test-Path -LiteralPath $manifest){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}}}
    foreach($name in @(".pcvrhub_${IDENTITY}_ownership.csv",'.pcvrhub_version')){$paths.Add($name)}
    $records=@();foreach($rel in @($paths|Select-Object -Unique)){$source=Join-Path $Game $rel;$exists=Test-Path -LiteralPath $source -PathType Leaf;$records+=[pscustomobject]@{Relative=$rel;Exists=$exists};if($exists){$copy=Join-Path (Join-Path $Destination 'files') $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force}}
    $backup=Join-Path $Game ".pcvrhub_${IDENTITY}_backup";$hasBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hasBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Destination 'ownership-backup') -Recurse -Force}
    return [pscustomobject]@{Records=$records;HasBackup=$hasBackup;Folder=$Destination}
}
function Restore-TurokSnapshot([string]$Game,$Snapshot){
    foreach($record in @($Snapshot.Records)){$target=Join-Path $Game ([string]$record.Relative);if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force};if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.Folder 'files') ([string]$record.Relative)) -Destination $target -Force}}
    $backup=Join-Path $Game ".pcvrhub_${IDENTITY}_backup";if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force};if($Snapshot.HasBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'ownership-backup') -Destination $backup -Recurse -Force}
}
function global:Invoke-TurokVRInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host;Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Turok VR Installer' -ForegroundColor Cyan
        Write-Host '  Steam KEX4 edition by VinceCrusty' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Turok VR needs Vulkan and an active SteamVR or VDXR OpenXR runtime.' -ForegroundColor Yellow
        Write-Host '  First Steam launch confirms publisher setup and closes once;' -ForegroundColor White
        Write-Host '  start from Steam a second time for VR. Your TurokVRUser.ini is kept.' -ForegroundColor White
        Write-Host '  Hub setup installs the complete publisher asset set and records its files.' -ForegroundColor White
        Write-Host '  GOG and legacy copies can be detected as games, but this VR release' -ForegroundColor Yellow
        Write-Host '  is documented for Steam KEX4; select that installation for setup.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to continue...')
        Write-Host '  [1/4] Find your Steam Turok installation' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $game=Get-TurokGameRoot
        if(Get-Process -Name 'sobek_Shipping_Steam_x64' -ErrorAction SilentlyContinue){throw 'Close Turok before installing.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The Turok folder is not writable.'}
        Write-Host "  Game: $game" -ForegroundColor Green
        Write-Host '  [2/4] Download and inspect the publisher release' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        Write-Host '  The next step checks the official GitHub release and downloads its ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download Turok VR...')
        $release=Get-TurokRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_turok_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'TurokVR.zip'
        $download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "Turok VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'Turok VR download was not completed.'}
        $stage=New-TurokStage -Archive $archive -Work $work
        Write-Host '  [3/4] Install the VR files and preserve your settings' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $snapshot=Save-TurokSnapshot -Game $game -Stage $stage -Destination (Join-Path $work 'rollback');$changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting -ProgressLabel 'Installing Turok VR files')
        foreach($proof in $REQUIRED){if(-not(Test-Path -LiteralPath (Join-Path $game $proof) -PathType Leaf)){throw "Installed Turok VR file is missing: $proof"}}
        if(-not(Confirm-PlacedFilesSurvive -Paths @($REQUIRED|ForEach-Object{Join-Path $game $_}) -GameDir $game -NoClear)){throw 'Required Turok VR files did not survive installation.'}
        [void](Complete-PCVRInstallTransaction -Contract $CONTRACT -GameDir $game -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $changed=$false
        Write-Host '  [4/4] Finish and start through Steam' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        Write-Host "  [OK] Publisher files for $($release.Tag) installed." -ForegroundColor Green
        Write-Host '  Start once through Steam, confirm the game prompt, then start again.' -ForegroundColor Yellow
        Write-Host '  VR gameplay and headset image require your own game/headset check.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  The Lost Land is much closer when the dinosaurs look back.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{if($changed -and $game -and $snapshot){try{Restore-TurokSnapshot -Game $game -Snapshot $snapshot;Write-Host '  Previous files restored.' -ForegroundColor Yellow}catch{Write-Host ('  Rollback needs attention: '+$_.Exception.Message) -ForegroundColor Red}};throw}
    finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_TUROK_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-TurokVRInstaller}

# White Knuckle VR: current Steam build or independent pinned compatibility depot.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$APP_ID='3195790';$DEPOT_ID='3195791';$DEPOT_MANIFEST='8160399169790817040';$DEPOT_BUILD='25612096'
$DEPOT_ROOT='C:\Games\White Knuckle VR 25612096';$DEPOT_MARKER='.pcvrhub_whiteknuckle_depot_25612096'
$GAME_EXE='White Knuckle.exe';$REPO='kyanite-rock/White_Knuckle_VR';$RELEASES="https://github.com/$REPO/releases"
$PINNED_MOD='v1.2.0';$PINNED_ASSET='WhiteKnuckleVR_v1.2.0.zip'
$PINNED_URL='https://github.com/kyanite-rock/White_Knuckle_VR/releases/download/v1.2.0/WhiteKnuckleVR_v1.2.0.zip'
$CURRENT_FALLBACK_MOD='v1.2.0';$CURRENT_FALLBACK_ASSET='WhiteKnuckleVR_v1.2.0.zip'
$CURRENT_FALLBACK_URL='https://github.com/kyanite-rock/White_Knuckle_VR/releases/download/v1.2.0/WhiteKnuckleVR_v1.2.0.zip'
$BEPINEX_URL='https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.2/BepInEx_win_x64_5.4.23.2.zip'
$IDENTITY='whiteknucklevr';$LEGACY_MOD='BepInEx\plugins\WhiteKnuckleVRMod.dll'
$MOD_FILES=@('BepInEx\plugins\WhiteKnuckleVRMod\WhiteKnuckleVRMod.dll',
    'BepInEx\plugins\WhiteKnuckleVRMod\Managed\Unity.XR.OpenXR.dll',
    'BepInEx\plugins\WhiteKnuckleVRMod\Managed\Unity.XR.Management.dll',
    'BepInEx\plugins\WhiteKnuckleVRMod\x86_64\openxr_loader.dll',
    'BepInEx\plugins\WhiteKnuckleVRMod\x86_64\UnityOpenXR.dll')
$LOADER_FILES=@('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll')
$PINNED_GAME_HASHES=@{
    'White Knuckle.exe'='C2C349E8147B73EE27070ADC4F59F3311F20C1D822DB52D6BC62F88374308264'
    'UnityPlayer.dll'='0391DF1B36E6B9EDD3E9A5E5F67A5A3D92FA34057A22C7F9A37D827D7594EF78'
    'White Knuckle_Data\globalgamemanagers'='E40187C78FFAF49EFED6D57C43A3F000117F783D43168DF23D96E577E421AB3F'
}
$CURRENT_CONTRACT=New-PCVRInstallerContract -Id 'white-knuckle-vr' -GameName 'White Knuckle VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @($MOD_FILES+$LOADER_FILES+@(".pcvrhub_${IDENTITY}_ownership.csv"))
$DEPOT_CONTRACT=New-PCVRInstallerContract -Id 'white-knuckle-vr' -GameName 'White Knuckle VR' -Acquisition SteamDepot `
    -PinnedDepot -AntivirusNotice -Routes @("Depot-$DEPOT_BUILD") -ReleasePageUrl "$RELEASES/tag/$PINNED_MOD" `
    -RequiredInstalledFileGroups @($MOD_FILES+$LOADER_FILES+@(".pcvrhub_${IDENTITY}_ownership.csv",$DEPOT_MARKER,'steam_appid.txt'))

function Write-WKStep([int]$N,[string]$Text){Write-Host '';Write-Host "--- [$N/5] $Text ---" -ForegroundColor Cyan}
function Test-WKGame([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Path 'UnityPlayer.dll') -PathType Leaf))}
function Test-WKFiles([string]$Path,[string[]]$Files){foreach($rel in $Files){if(-not(Test-Path -LiteralPath (Join-Path $Path $rel) -PathType Leaf)){return $false}};return $true}
function Test-WKOwnedLoader([string]$GameRoot){
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)){return $false}
    foreach($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)){
        $relative=([string]$row.RelativePath).Replace('/','\')
        if($relative -match '^(?i:BepInEx\\core\\)' -or $relative -in @('winhttp.dll','doorstop_config.ini','.doorstop_version','changelog.txt')){return $true}
    }
    return $false
}
function Test-WKPinnedLoader([string]$Path){
    $hashes=@{'BepInEx\core\BepInEx.dll'='C65B42034BC8FFB9F0B336E416DC3884E3F99FC5A5A89EB1F2FF7868412322CD';'winhttp.dll'='D3B62F4C9C3E2196EF82603C52D6B98C043A0D6C125C081FD33D7CA3798B41B8';'doorstop_config.ini'='4D5C6DFA0F771C6A5B1B0C559ACA0BD0ECE7D08B08FFF894708DC3B73CE73CFC'}
    foreach($item in $hashes.GetEnumerator()){$file=Join-Path $Path ([string]$item.Key);if(-not(Test-Path -LiteralPath $file -PathType Leaf)){return $false};try{if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne [string]$item.Value){return $false}}catch{return $false}}
    return $true
}
function Test-WKPinnedGame([string]$Path){
    if(-not(Test-WKGame $Path)){return $false}
    foreach($item in $PINNED_GAME_HASHES.GetEnumerator()){
        $file=Join-Path $Path ([string]$item.Key)
        if(-not(Test-Path -LiteralPath $file -PathType Leaf)){return $false}
        try{if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne [string]$item.Value){return $false}}catch{return $false}
    }
    return $true
}
function Test-WKSteamPinnedManifest([string]$Path){
    if(-not(Test-WKPinnedGame $Path)){return $false}
    try{
        $common=Split-Path -Parent ([IO.Path]::GetFullPath($Path));if((Split-Path -Leaf $common) -ine 'common'){return $false}
        $text=[IO.File]::ReadAllText((Join-Path (Split-Path -Parent $common) "appmanifest_$APP_ID.acf"))
        return [bool]($text -match ('(?i)"buildid"\s*"'+$DEPOT_BUILD+'"') -and
            $text -match ('(?is)"'+$DEPOT_ID+'"\s*\{[^{}]*"manifest"\s*"'+$DEPOT_MANIFEST+'"'))
    }catch{return $false}
}
function Get-WKDepotMarkerText{return "AppId=$APP_ID`nDepotId=$DEPOT_ID`nManifest=$DEPOT_MANIFEST`nBuildId=$DEPOT_BUILD`nMod=$PINNED_MOD"}
function Get-WKCurrentRoot{
    $path=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('White Knuckle','WhiteKnuckle') -ProbeExe $GAME_EXE -HubGameId 'white-knuckle-vr'
    if(-not(Test-WKGame $path)){$path=Get-GameFolderInteractive -GameName 'White Knuckle' -ProbeFile $GAME_EXE -ManualUrl "https://store.steampowered.com/app/$APP_ID/";if(Test-WKGame $path){[void](Save-HubRememberedGameFolder -GameId 'white-knuckle-vr' -Title 'White Knuckle VR' -GameDir $path -ProbeFiles @($GAME_EXE,'UnityPlayer.dll') -UserSelected)}}
    if($path -in @('quit','skip',$null) -or -not(Test-WKGame $path)){return $null}
    return (Get-Item -LiteralPath $path).FullName
}
function Get-WKDepotRoot{
    if(Test-WKPinnedGame $DEPOT_ROOT){Write-Host "  Found pinned game build at $DEPOT_ROOT" -ForegroundColor Green;return $DEPOT_ROOT}
    if((Test-Path -LiteralPath $DEPOT_ROOT) -and @(Get-ChildItem -LiteralPath $DEPOT_ROOT -Force -ErrorAction SilentlyContinue).Count){throw "$DEPOT_ROOT exists but does not match the pinned build. Move it aside before retrying."}
    $steamGame=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('White Knuckle') -ProbeExe $GAME_EXE
    if(Test-WKSteamPinnedManifest $steamGame){
        Write-Host "  [C] Copy installed Steam build $DEPOT_BUILD into the independent folder" -ForegroundColor Cyan
        Write-Host '  [D] Download the exact depot through Steam Console' -ForegroundColor Cyan
        Write-Host '  [Q] Cancel' -ForegroundColor Gray
        do{$sourceChoice=([string](Read-Host '  Choose C, D or Q')).Trim().ToUpperInvariant()}while($sourceChoice -notin @('C','D','Q'))
        if($sourceChoice -eq 'Q'){throw 'Depot setup cancelled before copying game files.'}
        if($sourceChoice -eq 'C'){
            [void](Wait-PCVRExplicitEnter -Message "Press Enter to copy the verified build to $DEPOT_ROOT...")
            [void](Copy-DirectoryTreeVerified -Source $steamGame -Destination $DEPOT_ROOT)
            if(-not(Test-WKPinnedGame $DEPOT_ROOT)){throw 'Copied White Knuckle build failed the pinned file proof.'}
            return $DEPOT_ROOT
        }
    }
    $command="download_depot $APP_ID $DEPOT_ID $DEPOT_MANIFEST"
    Write-Host "  Exact Steam command: $command" -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy this command and open Steam Console...')
    try{Set-Clipboard -Value $command -DeferManualFallback}catch{}
    Start-Process 'steam://open/console' -ErrorAction Stop | Out-Null
    Show-PCVRClipboardManualFallback -Text $command
    [void](Wait-PCVRExplicitEnter -Message 'When Steam reports the depot download complete, press Enter to locate it...')
    $steamRoot=Get-SteamPath
    $source=Find-SteamDepotPath -AppId $APP_ID -DepotId $DEPOT_ID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamRoot)
    if(-not $source){$source=Resolve-DepotPath -GameName "White Knuckle build $DEPOT_BUILD" -DepotCommand $command -GameExe $GAME_EXE `
        -ProbePaths @(Get-SteamDepotProbePaths -AppId $APP_ID -DepotId $DEPOT_ID -AdditionalSteamRoots @($steamRoot)) `
        -AppId $APP_ID -DepotId $DEPOT_ID -Manifest $DEPOT_MANIFEST}
    if(-not(Test-WKPinnedGame $source)){throw 'The selected Steam content does not match the pinned White Knuckle build.'}
    [void](Copy-DirectoryTreeVerified -Source $source -Destination $DEPOT_ROOT)
    if(-not(Test-WKPinnedGame $DEPOT_ROOT)){throw 'The assembled depot failed its pinned file proof.'}
    return $DEPOT_ROOT
}
function Get-WKRelease([ValidateSet('Current','Depot')][string]$Mode='Current'){
    if($Mode -eq 'Depot'){return [pscustomobject]@{Tag=$PINNED_MOD;Url=$PINNED_URL;Name=$PINNED_ASSET;PageUrl="$RELEASES/tag/$PINNED_MOD"}}
    $r=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^WhiteKnuckleVR_v[0-9].*\.zip$') `
        -FallbackUrl $CURRENT_FALLBACK_URL -FallbackTag $CURRENT_FALLBACK_MOD -FallbackAssetName $CURRENT_FALLBACK_ASSET -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Name=[string]$r.AssetName;PageUrl=[string]$r.PageUrl}
}
function New-WKStage([string]$ModArchive,[string]$LoaderArchive,[string]$GameRoot,[string]$Stage,[switch]$Depot){
    if([string](Expand-ArchiveOrFallback -ArchivePath $ModArchive -DestinationFolder $Stage -Label 'White Knuckle VR mod' -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')){throw 'The White Knuckle release could not be extracted.'}
    if(-not(Test-WKFiles -Path $Stage -Files $MOD_FILES)){throw 'The release lacks its VR plug-in or OpenXR runtime files.'}
    if($LoaderArchive){
        if([string](Expand-ArchiveOrFallback -ArchivePath $LoaderArchive -DestinationFolder $Stage -Label 'BepInEx 5 x64' -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')){throw 'The x64 loader could not be extracted.'}
        if(-not(Test-WKFiles -Path $Stage -Files $LOADER_FILES)){throw 'The x64 loader package is incomplete.'}
    }elseif(-not(Test-WKFiles -Path $GameRoot -Files $LOADER_FILES)){throw 'The existing BepInEx loader is incomplete.'}
    if($Depot){
        [IO.File]::WriteAllText((Join-Path $Stage 'steam_appid.txt'),$APP_ID,[Text.Encoding]::ASCII)
        [IO.File]::WriteAllText((Join-Path $Stage $DEPOT_MARKER),(Get-WKDepotMarkerText),(New-Object Text.UTF8Encoding $false))
    }
    return $Stage
}
function Save-WKSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot);$filesRoot=Join-Path $SnapshotRoot 'files'
    $base=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/');$relatives=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$relatives.Add($file.FullName.Substring($base.Length+1))}
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if(Test-Path -LiteralPath $manifest){try{foreach($row in @(Import-Csv $manifest)){if($row.RelativePath){$relatives.Add([string]$row.RelativePath)}}}catch{}}
    foreach($extra in @(".pcvrhub_${IDENTITY}_ownership.csv",".pcvrhub_${IDENTITY}_ownership.csv.new",'.pcvrhub_version',$LEGACY_MOD,($LEGACY_MOD+'.pcvrhub-legacy-off'))){$relatives.Add($extra)}
    $records=@();foreach($rel in @($relatives|Select-Object -Unique)){$src=Join-Path $GameRoot $rel;$exists=Test-Path -LiteralPath $src -PathType Leaf;$records+=[pscustomobject]@{Relative=$rel;Exists=$exists};if($exists){$copy=Join-Path $filesRoot $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $src -Destination $copy -Force}}
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup";$backupExists=Test-Path -LiteralPath $backup -PathType Container;if($backupExists){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force}
    return [pscustomobject]@{Records=$records;BackupExists=$backupExists;SnapshotRoot=$SnapshotRoot}
}
function Restore-WKSnapshot([string]$GameRoot,$Snapshot){
    foreach($record in @($Snapshot.Records)){$target=Join-Path $GameRoot ([string]$record.Relative);if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force};if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.SnapshotRoot 'files') ([string]$record.Relative)) -Destination $target -Force}}
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup";if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force};if($Snapshot.BackupExists){Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force}
}
function global:Invoke-WhiteKnuckleVRInstaller{
    $work=$null;$game=$null;$snapshot=$null;$changesStarted=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  White Knuckle VR - Installer' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  [1] Current Steam build + newest stable WhiteKnuckleVR release' -ForegroundColor Cyan
        Write-Host "  [2] Independent build $DEPOT_BUILD + pinned WhiteKnuckleVR $PINNED_MOD" -ForegroundColor Cyan
        Write-Host '      The normal Steam installation stays separate.' -ForegroundColor Gray
        Write-Host '  BepInEx 5 x64 is required. The first mod launch is flat; the' -ForegroundColor Yellow
        Write-Host '  second launch uses VR. The game must be closed during setup.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter after reading the route and first-launch instructions...')
        do{$choice=([string](Read-Host '  Choose 1 or 2 [1]')).Trim()}while($choice -notin @('','1','2'))
        $mode=if($choice -eq '2'){'Depot'}else{'Current'};$route=if($mode -eq 'Depot'){"Depot-$DEPOT_BUILD"}else{'Current'}
        Write-WKStep 1 'Finding the correct game route'
        $game=if($mode -eq 'Depot'){Get-WKDepotRoot}else{Get-WKCurrentRoot}
        if(-not(Test-WKGame $game)){throw 'No complete White Knuckle game folder was selected.'}
        if(Get-Process -Name 'White Knuckle' -ErrorAction SilentlyContinue){throw 'Close White Knuckle before installing VR files.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The selected game folder is not writable.'}
        Write-Host "  $game" -ForegroundColor Green
        Write-WKStep 2 'Downloading the selected VR mod and x64 loader'
        Write-Host '  The selected route checks its publisher release and downloads the VR mod.' -ForegroundColor White
        Write-Host '  BepInEx 5 x64 is downloaded only when the correct loader is missing.' -ForegroundColor Gray
        Write-Host '  Download and extraction may take a few minutes.' -ForegroundColor Gray
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download White Knuckle VR...')
        $release=Get-WKRelease -Mode $mode;if(-not(Test-IsTrackableInstalledVersion $release.Tag)){throw 'No trackable VR mod release version was resolved.'}
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_wk_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $modArchive=Join-Path $work 'WhiteKnuckleVR.zip'
        $modDownload=Invoke-SafeDownload -Urls @($release.Url) -Destination $modArchive -Label "WhiteKnuckleVR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl $release.PageUrl -AllowSkip $false
        if($modDownload -ne $true -and [string]$modDownload -notin @('retry','manual')){throw 'The White Knuckle VR release was not downloaded.'}
        $loaderArchive=$null
        if(-not(Test-WKFiles -Path $game -Files $LOADER_FILES) -or ($mode -eq 'Depot' -and -not(Test-WKPinnedLoader $game)) -or (Test-WKOwnedLoader $game)){
            $loaderArchive=Join-Path $work 'BepInEx5x64.zip'
            $loaderDownload=Invoke-SafeDownload -Urls @($BEPINEX_URL) -Destination $loaderArchive -Label 'BepInEx 5.4.23.2 x64' -ManualUrl 'https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.2' -AllowSkip $false
            if($loaderDownload -ne $true -and [string]$loaderDownload -notin @('retry','manual')){throw 'The x64 BepInEx loader was not downloaded.'}
        }
        $stage=New-WKStage -ModArchive $modArchive -LoaderArchive $loaderArchive -GameRoot $game -Stage (Join-Path $work 'stage') -Depot:($mode -eq 'Depot')
        Write-WKStep 3 'Backing up files that may be replaced'
        $snapshot=Save-WKSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback');$changesStarted=$true
        Write-WKStep 4 'Installing and checking VR files'
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting)
        $legacy=Join-Path $game $LEGACY_MOD
        if(Test-Path -LiteralPath $legacy -PathType Leaf){$parked=$legacy+'.pcvrhub-legacy-off';if(Test-Path -LiteralPath $parked){throw 'A parked legacy VR plug-in already exists; move it aside before retrying.'};Move-Item -LiteralPath $legacy -Destination $parked -ErrorAction Stop}
        $proof=@($MOD_FILES+$LOADER_FILES+@(".pcvrhub_${IDENTITY}_ownership.csv"))
        if($mode -eq 'Depot'){$proof+=@($DEPOT_MARKER,'steam_appid.txt')}
        if(-not(Test-WKFiles -Path $game -Files $proof)){throw 'Required White Knuckle VR runtime files are missing after installation.'}
        if(-not(Confirm-PlacedFilesSurvive -Paths @($proof|ForEach-Object{Join-Path $game $_}) -GameDir $game -NoClear)){throw 'Required VR files did not survive the post-copy check.'}
        $receipt=Join-Path $PSScriptRoot $(if($mode -eq 'Depot'){'.installed_path_depot'}else{'.installed_path'})
        $selectedContract=if($mode -eq 'Depot'){$DEPOT_CONTRACT}else{$CURRENT_CONTRACT}
        [void](Complete-PCVRInstallTransaction -Contract $selectedContract -GameDir $game -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route $route)
        $changesStarted=$false
        Write-WKStep 5 'First and second launch'
        Write-Host '  Start once through Steam or the selected depot route and wait' -ForegroundColor White
        Write-Host '  for the main menu. This first run is flat and writes VR config.' -ForegroundColor White
        Write-Host '  Close it, start your OpenXR runtime, then launch again for VR.' -ForegroundColor White
        Write-Host "  $mode route installed: $game" -ForegroundColor Green
        Write-Host ''
        Write-Host '  Your hands are the only thing between you and the drop.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changesStarted -and $game -and $snapshot){try{Restore-WKSnapshot -GameRoot $game -Snapshot $snapshot;Write-Host '  Previous files restored.' -ForegroundColor Yellow}catch{Write-Host ('  Rollback needs attention: '+$_.Exception.Message) -ForegroundColor Red}}
        throw
    }finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_WK_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-WhiteKnuckleVRInstaller}

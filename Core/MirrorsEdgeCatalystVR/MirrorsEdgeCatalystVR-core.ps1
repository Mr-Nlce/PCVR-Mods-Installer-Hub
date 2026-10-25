$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle="Mirror's Edge Catalyst VR Installer"
$script:MecId='mirrors-edge-catalyst-vr'
$script:MecRepo='sqofer/Mirror-s-Edge-Catalyst-VR'
$script:MecPage='https://github.com/sqofer/Mirror-s-Edge-Catalyst-VR/releases'
$script:MecReviewed='https://github.com/sqofer/Mirror-s-Edge-Catalyst-VR/releases/download/0.5/Mirror.s.Edge.Catalyst.VR-Setup.zip'
$script:MecContract=New-PCVRInstallerContract -Id $script:MecId -GameName "Mirror's Edge Catalyst VR" -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $script:MecPage -Routes @('Steam','EA','Origin') `
    -RequiredInstalledFileGroups @('MirrorsEdgeCatalyst.exe','mecxr_launcher.exe','mecxr_live.dll')
function Assert-MecFixture([string]$Root){
    $full=[IO.Path]::GetFullPath($Root);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'mec-fixture.txt') -PathType Leaf)){
        throw 'Catalyst test game must be an isolated temporary fixture.'
    }
    return $full
}
function Get-MecGame{
    if($env:PCVR_MEC_TEST_GAME){$p=Assert-MecFixture $env:PCVR_MEC_TEST_GAME;if(Test-Path -LiteralPath (Join-Path $p 'MirrorsEdgeCatalyst.exe') -PathType Leaf){return $p};throw 'Catalyst fixture game is missing.'}
    $paths=@();$saved=Get-PCVRRememberedGameFolder -GameId $script:MecId -StateNames @('base_game_path','user_located','installed_path') -ProbeFiles @('MirrorsEdgeCatalyst.exe');if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '1233570' -SteamFolderNames @('Mirrors Edge Catalyst') -ProbeExe 'MirrorsEdgeCatalyst.exe' -HubGameId $script:MecId;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Mirrors Edge Catalyst',"C:\Program Files\EA Games\Mirror's Edge Catalyst",
        "C:\Program Files (x86)\Origin Games\Mirror's Edge Catalyst")
    foreach($p in @($paths|Where-Object{$_}|Select-Object -Unique)){if(Test-Path -LiteralPath (Join-Path $p 'MirrorsEdgeCatalyst.exe') -PathType Leaf){return [IO.Path]::GetFullPath($p)}}
    $picked=Get-GameFolderInteractive -GameName "Mirror's Edge Catalyst" -ProbeFile 'MirrorsEdgeCatalyst.exe' -ManualUrl 'https://store.steampowered.com/app/1233570/'
    if($picked -and (Test-Path -LiteralPath (Join-Path $picked 'MirrorsEdgeCatalyst.exe') -PathType Leaf)){
        [void](Save-HubRememberedGameFolder -GameId $script:MecId -Title "Mirror's Edge Catalyst VR" -GameDir $picked -ProbeFiles @('MirrorsEdgeCatalyst.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw "Choose the original Mirror's Edge Catalyst folder containing MirrorsEdgeCatalyst.exe."
}
function Get-MecRoute([string]$Game){
    if($env:PCVR_MEC_TEST_ROUTE){return $env:PCVR_MEC_TEST_ROUTE}
    if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
    if($Game -match '(?i)[\\/]EA Games[\\/]'){return 'EA'}
    if($Game -match '(?i)[\\/]Origin Games[\\/]'){return 'Origin'}
    throw 'The selected folder is outside the confirmed Steam, EA App and Origin routes.'
}
function Get-MecRelease{
    if($env:PCVR_MEC_TEST_ARCHIVE){return [pscustomobject]@{Version='0.5';Url=$env:PCVR_MEC_TEST_ARCHIVE;Local=$true}}
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:MecRepo -IncludePrerelease $false -AssetPatterns @('(?i)^Mirror.s.Edge.Catalyst.VR-Setup\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=$null}
    if($r -and $r.Resolved -and (Test-IsTrackableInstalledVersion ([string]$r.Tag))){return [pscustomobject]@{Version=[string]$r.Tag;Url=[string]$r.Url;Local=$false}}
    Write-Host '  GitHub release lookup is unavailable; the last reviewed publisher Setup is 0.5. A newer release may exist.' -ForegroundColor Yellow
    return [pscustomobject]@{Version='0.5';Url=$script:MecReviewed;Local=$false}
}
function Get-MecArchive($Release,[string]$Destination){
    if($Release.Local){[void](Assert-MecFixture (Split-Path $Release.Url -Parent));Copy-Item -LiteralPath $Release.Url -Destination $Destination -Force;return}
    [void](Invoke-SafeDownload -Urls @($Release.Url) -Destination $Destination -Label "Catalyst VR $($Release.Version)" -ManualUrl $script:MecPage -ExpectedReleaseTag $Release.Version -AllowSkip:$false)
}
function Get-MecSetup([string]$Archive,[string]$Stage){
    $safe=Test-ZipArchiveEntrySafety -ArchivePath $Archive -DestinationFolder $Stage
    if(-not $safe.Safe -or -not $safe.Inspectable){throw 'Publisher ZIP is unreadable or contains unsafe paths.'}
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($Archive,$Stage)
    $files=@(Get-ChildItem -LiteralPath $Stage -Recurse -File -Filter '*.exe')
    if($files.Count -ne 1 -or $files[0].Name -notmatch '(?i)Catalyst.*Setup'){throw 'The ZIP does not contain the single Catalyst publisher Setup.'}
    return $files[0].FullName
}
function Assert-MecGameBuild([string]$Game){
    if($env:PCVR_MEC_TEST_GAME){return}
    $exe=Join-Path $Game 'MirrorsEdgeCatalyst.exe';$actual=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    if($actual -ine 'E9D76463766973964A97CD63BD64C1191A317EC6ED6753D82B36F4BA0DA45136'){
        throw 'Publisher Setup supports the original game build 1.0.3.47248 only. This EXE differs; no game files were changed.'
    }
}
function Test-MecInstalled([string]$Game){
    foreach($name in @('MirrorsEdgeCatalyst.exe','mecxr_launcher.exe','mecxr_live.dll')){
        $p=Join-Path $Game $name;if(-not(Test-Path -LiteralPath $p -PathType Leaf) -or (Get-Item -LiteralPath $p).Length -eq 0){return $false}
    }
    return $true
}
function Save-MecSnapshot([string]$Game,[string]$Work){
    $folder=Join-Path $Work 'before';[void][IO.Directory]::CreateDirectory($folder);$rows=@()
    foreach($name in @('mecxr_launcher.exe','mecxr_live.dll','mecxr_attach.exe','mecxr.ini','openxr_loader.dll','.pcvrhub_version')){
        $path=Join-Path $Game $name;$exists=Test-Path -LiteralPath $path -PathType Leaf;$rows+=[pscustomobject]@{Name=$name;Exists=$exists}
        if($exists){Copy-Item -LiteralPath $path -Destination (Join-Path $folder $name) -Force -ErrorAction Stop}
    }
    return [pscustomobject]@{Folder=$folder;Rows=$rows}
}
function Restore-MecSnapshot([string]$Game,$Snapshot){
    foreach($row in $Snapshot.Rows){$path=Join-Path $Game $row.Name;if($row.Exists){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Name) -Destination $path -Force -ErrorAction Stop}elseif(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force -ErrorAction Stop}}
}
function Invoke-MecInstaller{
    $work=$null;$game=$null;$snapshot=$null;$changed=$false
    try{
        Write-Host "Mirror's Edge Catalyst VR - Installer" -ForegroundColor Cyan
        Write-Host 'Original Catalyst only. The publisher Setup requires game build 1.0.3.47248.' -ForegroundColor White
        Write-Host 'Seated/gamepad VR. Configure resolution and path in the publisher launcher.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message "After reading this, press Enter to locate Mirror's Edge Catalyst...")
        $game=Get-MecGame;$route=Get-MecRoute $game;Write-Host "  Game ($route): $game" -ForegroundColor Green
        Assert-MecGameBuild $game
        if(Get-Process -Name MirrorsEdgeCatalyst -ErrorAction SilentlyContinue){throw 'Close Catalyst before setup.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable.'}
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Catalyst VR Setup...')
        $release=Get-MecRelease;$work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'CatalystVR.zip';Get-MecArchive $release $archive
        $stage=Join-Path $work 'package';[void][IO.Directory]::CreateDirectory($stage);$setup=Get-MecSetup $archive $stage
        if($env:PCVR_HUB_TEST_MODE -ne '1'){
            $cache=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\PublisherCache\Catalyst'
            [void][IO.Directory]::CreateDirectory($cache)
            Copy-Item -LiteralPath $setup -Destination (Join-Path $cache 'Publisher-Setup.exe') -Force -ErrorAction Stop
        }
        $snapshot=Save-MecSnapshot -Game $game -Work $work
        Write-Host '  In publisher Setup select this game folder and Install / Update.' -ForegroundColor White
        Write-Host "  Game: $game" -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher Setup...')
        $changed=$true
        $p=Start-Process -FilePath $setup -Wait -PassThru -ErrorAction Stop
        if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "Publisher Setup exited with code $($p.ExitCode)."}
        if(-not(Test-MecInstalled $game)){throw 'Publisher Setup did not leave a complete Catalyst VR runtime. Reopen it and choose Install / Update.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MEC_TEST_RECEIPT){$env:PCVR_MEC_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:MecContract -GameDir $game -Version $release.Version -Route $route -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host '  If this game has never been started, use normal Steam Play or EA App Play' -ForegroundColor Yellow
        Write-Host '  to launch it flat once. Reach its menu and close it before opening the VR launcher.' -ForegroundColor Yellow
        Write-Host '  You can do that now, after installing the VR mod.' -ForegroundColor White
        Write-Host '  1. Start in VR from the Hub. The publisher launcher opens.' -ForegroundColor Green
        Write-Host '  In it, choose Open Mod, set the game path/resolution, Save, then Launch game.' -ForegroundColor White
        Write-Host '  F8 recenters; F9 toggles the VR view during gameplay.' -ForegroundColor White
        Write-Host ''
        Write-Host 'Faith, the rooftops still lack guardrails.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{if($changed -and $snapshot -and $game){Restore-MecSnapshot -Game $game -Snapshot $snapshot};throw}
    finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_MEC_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-MecInstaller;break}catch{$message="Catalyst VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)}}
}

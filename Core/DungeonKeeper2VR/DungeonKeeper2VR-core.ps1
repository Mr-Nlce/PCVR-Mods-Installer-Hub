$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle = 'Dungeon Keeper 2 VR Installer'
$script:DkId='dungeon-keeper-2-vr'
$script:DkRepo='lovemakerz/Dungeon-Keeper-2-VR-MOD'
$script:DkPage='https://github.com/lovemakerz/Dungeon-Keeper-2-VR-MOD/releases'
$script:DkFiles=@('DKII_VR.cmd','DK2VR\payload\DK2VR.dll','DK2VR\DK2VRHost.exe','DK2VR\openxr_loader.dll','DK2VR\Run-VR.ps1','.pcvrhub_dk2vr_ownership.csv')
$script:DkContract=New-PCVRInstallerContract -Id $script:DkId -GameName 'Dungeon Keeper 2 VR' -Acquisition GitHub `
    -ReleasePageUrl $script:DkPage -AntivirusNotice -Routes @('Steam','EA','Origin','GOG','Retail') -RequiredInstalledFileGroups $script:DkFiles

function Assert-DkFixture([string]$Root) {
    $full=[IO.Path]::GetFullPath($Root);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'dk2-fixture.txt') -PathType Leaf)) {
        throw 'Dungeon Keeper 2 test path must be an isolated temporary fixture.'
    }
    return $full
}
function Get-DkGame {
    if($env:PCVR_DK2_TEST_GAME){$root=Assert-DkFixture $env:PCVR_DK2_TEST_GAME;if(Test-Path -LiteralPath (Join-Path $root 'DKII-DX.exe') -PathType Leaf){return $root};throw 'Fixture game EXE is missing.'}
    $paths=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:DkId -StateNames @('base_game_path','user_located','installed_path') -ProbeFiles @('DKII-DX.exe')
    if($saved){$paths+=$saved}
    try{$found=Find-SteamGameFolder -AppId '2616460' -SteamFolderNames @('Dungeon Keeper 2') -ProbeExe 'DKII-DX.exe' -HubGameId $script:DkId;if($found){$paths+=$found}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Dungeon Keeper 2','C:\Program Files\EA Games\Dungeon Keeper 2',
        'C:\Program Files (x86)\Origin Games\Dungeon Keeper 2','C:\Program Files (x86)\GOG Galaxy\Games\Dungeon Keeper 2',
        'C:\GOG Games\Dungeon Keeper 2','C:\Program Files (x86)\Bullfrog\Dungeon Keeper 2')
    foreach($path in @($paths|Where-Object{$_}|Select-Object -Unique)) {if(Test-Path -LiteralPath (Join-Path $path 'DKII-DX.exe') -PathType Leaf){return [IO.Path]::GetFullPath($path)}}
    $picked=Get-GameFolderInteractive -GameName 'Dungeon Keeper 2 (version 1.70)' -ProbeFile 'DKII-DX.exe' -ManualUrl 'https://store.steampowered.com/app/2616460/'
    if($picked -and (Test-Path -LiteralPath (Join-Path $picked 'DKII-DX.exe') -PathType Leaf)){
        [void](Save-HubRememberedGameFolder -GameId $script:DkId -Title 'Dungeon Keeper 2 VR' -GameDir $picked -ProbeFiles @('DKII-DX.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose a Dungeon Keeper 2 folder containing DKII-DX.exe. DKII.exe alone is not the supported VR launcher.'
}
function Get-DkPackageVersion([string]$ZipPath) {
    $safety=Test-ZipArchiveEntrySafety -ArchivePath $ZipPath -DestinationFolder (Join-Path ([IO.Path]::GetTempPath()) 'pcvr-dk2-safety')
    if(-not $safety.Inspectable -or -not $safety.Safe){throw 'The publisher ZIP is unreadable or has an unsafe archive path.'}
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach($required in @('DKII_VR.cmd','DK2VR/payload/DK2VR.dll','DK2VR/DK2VRHost.exe','DK2VR/openxr_loader.dll','DK2VR/Run-VR.ps1')){
            if(-not @($zip.Entries|Where-Object{$_.FullName.Replace('\','/') -ieq $required}).Count){throw "The publisher package is missing $required."}
        }
        $readme=@($zip.Entries|Where-Object{$_.FullName -ieq 'README.txt'})|Select-Object -First 1
        if(-not $readme){throw 'The publisher README is missing.'}
        $reader=[IO.StreamReader]::new($readme.Open());try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
        if($text -notmatch '(?i)DK2VR\s+([0-9]+(?:\.[0-9]+){3})\s*\(PUBLIC\)'){throw 'The publisher package version could not be read.'}
        return $Matches[1]
    } finally {$zip.Dispose()}
}
function Get-DkRelease {
    if($env:PCVR_DK2_TEST_ARCHIVE){$p=Assert-DkFixture (Split-Path $env:PCVR_DK2_TEST_ARCHIVE -Parent);$v=Get-DkPackageVersion $env:PCVR_DK2_TEST_ARCHIVE;return [pscustomobject]@{Version=$v;Url=$env:PCVR_DK2_TEST_ARCHIVE;Local=$true}}
    try{$asset=Resolve-GitHubReleaseAsset -Repo $script:DkRepo -IncludePrerelease $false -AssetPatterns @('(?i)^DK2VR_?V?\d+(?:\.\d+){3}_PUBLIC\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$asset=$null}
    if($asset -and $asset.Resolved -and $asset.Url){return [pscustomobject]@{Version='';Url=[string]$asset.Url;Local=$false}}
    Write-Host '  The current publisher release could not be resolved. You can use its official ZIP from Downloads.' -ForegroundColor Yellow
    return [pscustomobject]@{Version='';Url='';Local=$false}
}
function Get-DkArchive($Release,[string]$Destination) {
    if($Release.Local){Copy-Item -LiteralPath $Release.Url -Destination $Destination -Force;return}
    if($Release.Url){[void](Invoke-SafeDownload -Urls @($Release.Url) -Destination $Destination -Label 'Dungeon Keeper 2 VR' -ManualUrl $script:DkPage -AllowSkip:$false);return}
    $opened=$false
    while($true){
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('DK2VR*PUBLIC.zip')
        if($candidate){Write-Host "  Found in Downloads: $candidate" -ForegroundColor Cyan;if((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $candidate -Destination $Destination -Force;return}}
        if(-not $opened){Write-Host '  Download the current Dungeon Keeper 2 VR ZIP from the publisher release page.' -ForegroundColor White;[void](Open-PCVRPageAfterEnter -Url $script:DkPage -Message 'Press Enter to open the download page...');$opened=$true}
        [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('DK2VR*PUBLIC.zip')
        if($candidate){Write-Host "  Found in Downloads: $candidate" -ForegroundColor Cyan;if((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $candidate -Destination $Destination -Force;return}}
        $raw=(Read-Host '  Drag the ZIP here, or press Enter to open the page again').Trim().Trim('"').Trim("'")
        if($raw -and (Test-Path -LiteralPath $raw -PathType Leaf)){Copy-Item -LiteralPath $raw -Destination $Destination -Force;return}
        [void](Open-PCVRPageAfterEnter -Url $script:DkPage -Message 'Press Enter to open the download page again...')
    }
}
function Assert-DkGameVersion([string]$Game,[string]$PackageRoot) {
    $scriptFile=Join-Path $PackageRoot 'DK2VR\Run-VR.ps1'
    $scriptText=Get-Content -LiteralPath $scriptFile -Raw -ErrorAction Stop
    if($scriptText -notmatch '(?i)\$expected\s*=\s*''([0-9a-f]{64})'''){throw 'The publisher game-build check is missing.'}
    if($env:PCVR_DK2_TEST_GAME){return}
    $expected=$Matches[1];$actual=(Get-FileHash -LiteralPath (Join-Path $Game 'DKII-DX.exe') -Algorithm SHA256).Hash
    if($actual -ine $expected){throw 'This publisher mod requires Dungeon Keeper 2 version 1.70. Your DKII-DX.exe is a different build; no files were changed.'}
}
function Get-DkRoute([string]$Game) {
    if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
    if($Game -match '(?i)[\\/]EA Games[\\/]'){return 'EA'}
    if($Game -match '(?i)[\\/]Origin Games[\\/]'){return 'Origin'}
    if($Game -match '(?i)[\\/]GOG Galaxy[\\/]|[\\/]GOG Games[\\/]'){return 'GOG'}
    return 'Retail'
}
function Save-DkSnapshot([string]$Game,[string]$Stage,[string]$Work) {
    $folder=Join-Path $Work 'rollback';[void][IO.Directory]::CreateDirectory($folder)
    $paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $Stage 'DK2VR') -File -Recurse)){
        [void]$paths.Add($file.FullName.Substring($Stage.TrimEnd([char[]]'\/').Length+1))
    }
    [void]$paths.Add('DKII_VR.cmd');[void]$paths.Add('.pcvrhub_dk2vr_ownership.csv');[void]$paths.Add('.pcvrhub_version')
    $manifest=Join-Path $Game '.pcvrhub_dk2vr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){[void]$paths.Add((Assert-PCVROwnedRelativePath $row.RelativePath))}}
    $rows=@();$index=0
    foreach($relative in $paths){
        $target=Join-OwnedRelativePath $Game $relative;$exists=Test-Path -LiteralPath $target -PathType Leaf;$key=[string]$index;$index++
        $rows+=[pscustomobject]@{Relative=$relative;Exists=$exists;Key=$key}
        if($exists){Copy-Item -LiteralPath $target -Destination (Join-Path $folder $key) -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_dk2vr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $folder 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Folder=$folder;Rows=$rows;HadBackup=$hadBackup}
}
function Restore-DkSnapshot([string]$Game,$Snapshot) {
    foreach($row in $Snapshot.Rows){
        $target=Join-OwnedRelativePath $Game $row.Relative
        if($row.Exists){
            $parent=Split-Path -Parent $target;if(-not(Test-Path -LiteralPath $parent -PathType Container)){[void][IO.Directory]::CreateDirectory($parent)}
            Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $target -Force -ErrorAction Stop
        }elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_dk2vr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Invoke-DkInstaller {
    $game=$null;$snapshot=$null;$changed=$false;$work=$null
    try {
    if($env:PCVR_HUB_TEST_MODE -ne '1'){Clear-Host}
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Dungeon Keeper 2 VR - Installer' -ForegroundColor Cyan
    Write-Host '  DK2VR by LoVeMaKeRz' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
    Write-Host 'Requires the original 1.70 game build and an active OpenXR runtime.' -ForegroundColor White
    Write-Host 'Unsigned VR files may trigger antivirus warnings. Setup checks the copied files and offers recovery if any are missing.' -ForegroundColor Gray
    [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Dungeon Keeper 2...')
    $game=Get-DkGame;Write-Host "  Game: $game" -ForegroundColor Green
    if(Get-Process -Name 'DKII-DX','DKII','DK2VRHost' -ErrorAction SilentlyContinue){throw 'Close Dungeon Keeper 2 and its VR host before installing.'}
    if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Run this setup with the required permission, then retry.'}
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest Dungeon Keeper 2 VR release...')
    $release=Get-DkRelease
    $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-dk2-'+[guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force|Out-Null
    try {
        $zip=Join-Path $work 'publisher.zip';Get-DkArchive $release $zip
        $version=Get-DkPackageVersion $zip
        $unpack=Join-Path $work 'package';New-Item -ItemType Directory -Path $unpack -Force|Out-Null
        [IO.Compression.ZipFile]::ExtractToDirectory($zip,$unpack)
        Assert-DkGameVersion -Game $game -PackageRoot $unpack
        $snapshot=Save-DkSnapshot -Game $game -Stage $unpack -Work $work
        Write-Host "  [OK] Publisher package $version inspected; original saves and settings remain." -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the complete VR package...')
        $changed=$true
        $manifest=Install-OwnedModPayload -SourceRoot $unpack -GameRoot $game -Identity 'dk2vr' `
            -IncludeRelativePrefixes @('DK2VR','DKII_VR.cmd') -KeepExistingRelativePaths @('DK2VR\DK2VR.ini') `
            -AdoptIdenticalExisting -ProgressLabel 'Installing Dungeon Keeper 2 VR'
        if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)){throw 'The VR ownership manifest was not created.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DK2_TEST_RECEIPT){$env:PCVR_DK2_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:DkContract -GameDir $game -Version $version -Route (Get-DkRoute $game) `
            -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host '  1. Start in VR from the Hub.' -ForegroundColor Green
        Write-Host '  2. Or run DKII_VR.cmd in the game folder.' -ForegroundColor White
        Write-Host '  If you change the game resolution, restart the game before using VR again.' -ForegroundColor White
        Write-Host ''
        Write-Host 'It is good to be bad. The imps have filed a complaint.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally { }
    } catch {
        if($changed -and $snapshot -and $game){Restore-DkSnapshot -Game $game -Snapshot $snapshot}
        throw
    } finally {
        if($work -and (Test-Path -LiteralPath $work -PathType Container)){$full=[IO.Path]::GetFullPath($work);$allowed=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\';if($full.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue}}
    }
}
if($env:PCVR_DK2_LIBRARY_ONLY -ne '1'){
    while($true){
        try{Invoke-DkInstaller;break}catch{
            $message="Dungeon Keeper 2 VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}

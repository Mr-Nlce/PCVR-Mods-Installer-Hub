$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Dishonored 2 VR Installer'
$script:D2Id='dishonored-2-vr'
$script:D2Repo='thecosmictangerine-cloud/dishonored-2-vr'
$script:D2Page="https://github.com/$script:D2Repo/releases"
$script:D2Files=@('Dishonored2.exe','dinput8.dll','DishonoredVR.dll','DishonoredVR.ini','.pcvrhub_dishonored2vr_ownership.csv')
$script:D2Contract=New-PCVRInstallerContract -Id $script:D2Id -GameName 'Dishonored 2 VR' -Acquisition GitHub -Routes @('Steam') -ReleasePageUrl $script:D2Page -AntivirusNotice -RequiredInstalledFileGroups $script:D2Files

function Test-D2SteamRoot([string]$Root) {
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root 'Dishonored2.exe') -PathType Leaf)){return $false}
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $full=[IO.Path]::GetFullPath($Root);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        return ($full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath (Join-Path $full 'dishonored2-fixture.txt') -PathType Leaf))
    }
    $full=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')
    if($full -notmatch '(?i)\\steamapps\\common\\Dishonored2$'){return $false}
    $manifest=Join-Path (Split-Path -Parent (Split-Path -Parent $full)) 'appmanifest_403640.acf'
    return (Test-Path -LiteralPath $manifest -PathType Leaf)
}
function Get-D2Game {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if(Test-D2SteamRoot $env:PCVR_D2_TEST_GAME){return [IO.Path]::GetFullPath($env:PCVR_D2_TEST_GAME)}
        throw 'Dishonored 2 test game must be an isolated Steam fixture.'
    }
    $c=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:D2Id -StateNames @('installed_path','user_located') -ProbeFiles @('Dishonored2.exe');if($saved){$c+=$saved}
    try{$found=Find-SteamGameFolder -AppId '403640' -SteamFolderNames @('Dishonored2') -ProbeExe 'Dishonored2.exe' -HubGameId $script:D2Id;if($found){$c+=$found}}catch{}
    $c+='C:\Program Files (x86)\Steam\steamapps\common\Dishonored2'
    foreach($p in @($c|Select-Object -Unique)){if(Test-D2SteamRoot $p){return [IO.Path]::GetFullPath($p)}}
    $picked=Get-GameFolderInteractive -GameName 'Dishonored 2 (Steam)' -ProbeFile 'Dishonored2.exe' -ManualUrl 'https://store.steampowered.com/app/403640/'
    if(Test-D2SteamRoot $picked){
        [void](Save-HubRememberedGameFolder -GameId $script:D2Id -Title 'Dishonored 2 VR' -GameDir $picked -ProbeFiles @('Dishonored2.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose the current Steam installation of Dishonored 2; its game EXE and Steam app manifest must exist. Other store builds are unsupported.'
}
function Get-D2Release {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2_TEST_ARCHIVE){
        $tag=if($env:PCVR_D2_TEST_VERSION){$env:PCVR_D2_TEST_VERSION}else{'v1.0.0'}
        return [pscustomobject]@{Tag=$tag;Url=$env:PCVR_D2_TEST_ARCHIVE;Local=$true;Manual=$false}
    }
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:D2Repo -IncludePrerelease $false -AssetPatterns @('(?i)^DishonoredVR-[0-9]+\.[0-9]+\.[0-9]+\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=$null}
    if($r -and $r.Resolved -and (Test-IsTrackableInstalledVersion ([string]$r.Tag))){return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false;Manual=$false}}
    Write-Host ' [!!] Current stable GitHub release could not be resolved. Use the official release page and hand over its ZIP.' -ForegroundColor Yellow
    return [pscustomobject]@{Tag='';Url='';Local=$false;Manual=$true}
}
function Get-D2ManualArchive([string]$Destination) {
    [void](Open-PCVRPageAfterEnter -Url $script:D2Page -Message 'Press Enter to open the official Dishonored 2 VR releases...')
    while($true){
        [void](Wait-PCVRExplicitEnter -Message 'After downloading the publisher ZIP, press Enter to check Downloads...')
        $found=Find-PCVRDownloadedCandidate -Patterns @('DishonoredVR-*.zip')
        if($found){
            Write-Host "  Found: $found" -ForegroundColor Cyan
            if((Read-Host '  Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){
                Copy-Item -LiteralPath $found -Destination $Destination -Force -ErrorAction Stop
                return
            }
        }
        $path=(Read-Host '  Drag/paste the ZIP path, or press Enter to reopen the release page').Trim().Trim('"').Trim("'")
        if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){
            Copy-Item -LiteralPath $path -Destination $Destination -Force -ErrorAction Stop
            return
        }
        [void](Open-PCVRPageAfterEnter -Url $script:D2Page -Message 'Press Enter to reopen the official releases...')
    }
}
function Save-D2Snapshot([string]$Root,[string]$Folder) {
    [void][IO.Directory]::CreateDirectory($Folder)
    $names=[Collections.Generic.List[string]]::new()
    foreach($name in @('dinput8.dll','DishonoredVR.dll','DishonoredVR.ini','.pcvrhub_dishonored2vr_ownership.csv','.pcvrhub_dishonored2vr_ownership.csv.new')){$names.Add($name)}
    $manifest=Join-Path $Root '.pcvrhub_dishonored2vr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){$names.Add((Assert-PCVROwnedRelativePath $row.RelativePath))}}
    $rows=@();foreach($name in @($names|Select-Object -Unique)){
        $path=Join-OwnedRelativePath $Root $name;$exists=Test-Path -LiteralPath $path -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($name)).Replace('/','_')
        $rows+=[pscustomobject]@{Relative=$name;Key=$key;Exists=$exists}
        if($exists){Copy-Item -LiteralPath $path -Destination (Join-Path $Folder $key) -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Root '.pcvrhub_dishonored2vr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Folder 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Rows=$rows;Folder=$Folder;HadBackup=$hadBackup}
}
function Restore-D2Snapshot([string]$Root,$Snapshot) {
    foreach($row in @($Snapshot.Rows)){
        $path=Join-OwnedRelativePath $Root $row.Relative
        if($row.Exists){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $path -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Root '.pcvrhub_dishonored2vr_backup'
    if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Invoke-D2Installer {
    $work=$null;$root=$null;$snapshot=$null;$changed=$false;$keep=$false
    try {
        if($env:PCVR_HUB_TEST_MODE -ne '1'){Clear-Host}
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Dishonored 2 VR - Installer' -ForegroundColor Cyan
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Current Steam build only. GOG, Epic, Xbox and other game builds are not supported by this mod.' -ForegroundColor Yellow
        Write-Host ' Use an active OpenXR runtime; set Options > Visuals > Display mode to Windowed.' -ForegroundColor White
        Write-Host ' Publisher INI enables unlock-all and infinite mana by default; saves can retain those changes.' -ForegroundColor Yellow
        Write-Host ' For a new Hub install these two settings are set to 0. Your existing INI is preserved on updates.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Dishonored 2...')
        Write-Host ' Checking saved and Steam game locations; this may take a few seconds.' -ForegroundColor Cyan
        $root=Get-D2Game
        if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'Dishonored2' -ErrorAction SilentlyContinue)){throw 'Close Dishonored 2 before installation.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $root)){throw 'The Steam game folder is not writable. Restart the Hub as administrator, then retry.'}
        Write-Host " [OK] Steam game: $root" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Dishonored 2 VR ZIP...')
        $release=Get-D2Release
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_dishonored2_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'DishonoredVR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        elseif($release.Manual){
            Get-D2ManualArchive -Destination $archive
            $tag=(Read-Host ' Release tag shown on the official page (for example v1.0.0)').Trim()
            if(-not(Test-IsTrackableInstalledVersion $tag)){throw 'A release version was not confirmed; no game files were changed.'}
            if((Read-Host " Use this official ZIP as $tag? Y/N").Trim() -notmatch '^(?i:y|yes)$'){throw 'Publisher version was not confirmed.'}
            $release.Tag=$tag
        }else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Dishonored 2 VR $($release.Tag)" -ManualUrl $script:D2Page -ExpectedReleaseTag $release.Tag -AllowSkip $false)}
        $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder (Join-Path $work 'publisher')
        if(-not $safe.Safe -or -not $safe.Inspectable){throw 'Publisher ZIP is unreadable or contains unsafe paths.'}
        $expanded=Join-Path $work 'publisher'
        $status=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $expanded -Label 'Dishonored 2 VR publisher ZIP' -AllowSkip $false -QuietProgress
        if([string]$status -notin @('ok','manual','retry')){throw 'The publisher ZIP could not be opened.'}
        $source=@($expanded)+@(Get-ChildItem -LiteralPath $expanded -Directory -Recurse|Select-Object -ExpandProperty FullName)|Where-Object{
            (Test-Path -LiteralPath (Join-Path $_ 'dinput8.dll') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $_ 'DishonoredVR.dll') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $_ 'DishonoredVR.ini') -PathType Leaf)
        }|Select-Object -First 1
        if(-not $source){throw 'The selected ZIP lacks dinput8.dll, DishonoredVR.dll or DishonoredVR.ini. Select the complete publisher ZIP.'}
        $stage=Join-Path $work 'stage';[void][IO.Directory]::CreateDirectory($stage)
        foreach($name in @('dinput8.dll','DishonoredVR.dll','DishonoredVR.ini')){Copy-Item -LiteralPath (Join-Path $source $name) -Destination (Join-Path $stage $name) -Force -ErrorAction Stop}
        $ini=Join-Path $stage 'DishonoredVR.ini';$cfg=[IO.File]::ReadAllText($ini)
        foreach($setting in @('UnlockEverything','InfiniteMana')){
            if($cfg -notmatch "(?im)^\s*$setting\s*=\s*[01]\s*$"){throw "Publisher INI no longer exposes $setting; review save-changing defaults before installing."}
            $cfg=[regex]::Replace($cfg,"(?im)^(\s*$setting\s*=\s*)[01](\s*)$",'${1}0${2}')
        }
        [IO.File]::WriteAllText($ini,$cfg,[Text.UTF8Encoding]::new($false))
        Write-Host ' Protecting existing files and installing the complete VR mod; this may take a few seconds.' -ForegroundColor Cyan
        $snapshot=Save-D2Snapshot -Root $root -Folder (Join-Path $work 'rollback');$changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $root -Identity 'dishonored2vr' -KeepExistingRelativePaths @('DishonoredVR.ini'))
        $required=@('dinput8.dll','DishonoredVR.dll','DishonoredVR.ini','.pcvrhub_dishonored2vr_ownership.csv')|ForEach-Object{Join-Path $root $_}
        if(-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $root -NoClear)){throw 'The VR runtime is incomplete after copying.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2_TEST_RECEIPT){$env:PCVR_D2_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:D2Contract -GameDir $root -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route Steam)
        $changed=$false
        Write-Host " [OK] Dishonored 2 VR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host ' Set the active OpenXR runtime for your headset and use Windowed display mode.' -ForegroundColor White
        Write-Host ' 1. Use Start in VR on the Dishonored 2 VR tile in the Hub.' -ForegroundColor Green
        Write-Host ' Alternative: start Dishonored 2 from your Steam Library.' -ForegroundColor White
        Write-Host ' Click the game window on the PC once if your controllers do not respond.' -ForegroundColor White
        Write-Host ''
        Write-Host ' The Outsider did not mention the motion controllers.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $root){try{Restore-D2Snapshot -Root $root -Snapshot $snapshot;Write-Host ' [!!] Earlier files were restored.' -ForegroundColor Yellow}catch{$keep=$true;Write-Host " [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}}
        $message="Dishonored 2 VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{if($work -and -not $keep -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_D2_LIBRARY_ONLY -ne '1'){Invoke-D2Installer}

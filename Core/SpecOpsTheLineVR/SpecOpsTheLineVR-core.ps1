$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Spec Ops: The Line VR Installer'
$script:SpecId='spec-ops-the-line-vr'
$script:SpecPage='https://github.com/Mavic-Pro/SpecOpsTheLineVR/releases'
$script:SpecRepo='Mavic-Pro/SpecOpsTheLineVR'
$script:SpecFiles=@('Binaries\Win32\SpecOpsTheLine.exe','Binaries\Win32\d3d9.dll','Binaries\Win32\openvr_api.dll','Binaries\Win32\specopsvr.ini','Binaries\Win32\.pcvrhub_specopsvr_ownership.csv')
$script:SpecContract=New-PCVRInstallerContract -Id $script:SpecId -GameName 'Spec Ops: The Line VR' -Acquisition GitHub -Routes @('Steam') -ReleasePageUrl $script:SpecPage -AntivirusNotice -RequiredInstalledFileGroups $script:SpecFiles

function Assert-SpecFixture([string]$Root) {
    $full=[IO.Path]::GetFullPath($Root)
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'specops-fixture.txt') -PathType Leaf)){throw 'Spec Ops test game must be an isolated temporary fixture.'}
    return $full
}
function Test-SpecSteamRoot([string]$Root) {
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root 'Binaries\Win32\SpecOpsTheLine.exe') -PathType Leaf)){return $false}
    if($env:PCVR_HUB_TEST_MODE -eq '1'){return [bool](Test-Path -LiteralPath (Join-Path $Root 'specops-fixture.txt') -PathType Leaf)}
    $full=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')
    if($full -notmatch '(?i)\\steamapps\\common\\SpecOps_TheLine$'){return $false}
    $manifest=Join-Path (Split-Path -Parent (Split-Path -Parent $full)) 'appmanifest_50300.acf'
    return (Test-Path -LiteralPath $manifest -PathType Leaf)
}
function Get-SpecGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $root=Assert-SpecFixture $env:PCVR_SPECOPS_TEST_GAME
        if(Test-SpecSteamRoot $root){return $root};throw 'The Spec Ops test fixture lacks Binaries\Win32\SpecOpsTheLine.exe.'
    }
    $c=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:SpecId -StateNames @('installed_path','user_located') -ProbeFiles @('Binaries\Win32\SpecOpsTheLine.exe');if($saved){$c+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '50300' -SteamFolderNames @('SpecOps_TheLine') -ProbeExe 'Binaries\Win32\SpecOpsTheLine.exe' -HubGameId $script:SpecId;if($steam){$c+=$steam}}catch{}
    $c+='C:\Program Files (x86)\Steam\steamapps\common\SpecOps_TheLine'
    foreach($p in @($c|Select-Object -Unique)){if(Test-SpecSteamRoot $p){return [IO.Path]::GetFullPath($p)}}
    $picked=Get-GameFolderInteractive -GameName 'Spec Ops: The Line (Steam)' -ProbeFile 'Binaries\Win32\SpecOpsTheLine.exe' -ManualUrl 'https://store.steampowered.com/app/50300/'
    if(Test-SpecSteamRoot $picked){
        [void](Save-HubRememberedGameFolder -GameId $script:SpecId -Title 'Spec Ops: The Line' -GameDir $picked -ProbeFiles @('Binaries\Win32\SpecOpsTheLine.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose the Steam installation of Spec Ops: The Line; the Steam app manifest and game EXE must both exist.'
}
function Get-SpecExeFingerprint([string]$Path) {
    $stream=$null;$reader=$null
    try{
        $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        if($stream.Length -lt 256){return $null}
        $reader=[IO.BinaryReader]::new($stream)
        if($reader.ReadUInt16() -ne 0x5A4D){return $null}
        $stream.Position=0x3c;$offset=$reader.ReadInt32()
        if($offset -lt 64 -or $offset+84 -gt $stream.Length){return $null}
        $stream.Position=$offset
        if($reader.ReadUInt32() -ne 0x00004550 -or $reader.ReadUInt16() -ne 0x14c){return $null}
        $stream.Position=$offset+8;$stamp=$reader.ReadUInt32()
        $stream.Position=$offset+80;$size=$reader.ReadUInt32()
        return [pscustomobject]@{TimeDateStamp=$stamp;SizeOfImage=$size}
    }catch{return $null}finally{if($reader){$reader.Dispose()}elseif($stream){$stream.Dispose()}}
}
function Get-SpecRelease {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPECOPS_TEST_ARCHIVE){
        return [pscustomobject]@{Tag='v0.9.5';Url=$env:PCVR_SPECOPS_TEST_ARCHIVE;Local=$true;Manual=$false;PageUrl=$script:SpecPage}
    }
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:SpecRepo -IncludePrerelease $false -AssetPatterns @('(?i)^SpecOpsTheLineVR\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=[pscustomobject]@{Resolved=$false}}
    if($r.Resolved -and (Test-IsTrackableInstalledVersion ([string]$r.Tag))){return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false;Manual=$false;PageUrl=[string]$r.PageUrl}}
    Write-Host ' [!!] GitHub could not resolve the current complete SpecOpsTheLineVR ZIP.' -ForegroundColor Yellow
    return [pscustomobject]@{Tag='';Url='';Local=$false;Manual=$true;PageUrl=$script:SpecPage}
}
function Save-SpecSnapshot([string]$Runtime,[string]$Folder) {
    [void][IO.Directory]::CreateDirectory($Folder)
    $paths=[Collections.Generic.List[string]]::new()
    foreach($p in @('d3d9.dll','openvr_api.dll','specopsvr.ini','.pcvrhub_specopsvr_ownership.csv','.pcvrhub_specopsvr_ownership.csv.new')){$paths.Add($p)}
    $manifest=Join-Path $Runtime '.pcvrhub_specopsvr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){$paths.Add((Assert-PCVROwnedRelativePath $row.RelativePath))}}
    $rows=@();foreach($relative in @($paths|Select-Object -Unique)){
        $src=Join-OwnedRelativePath $Runtime $relative;$exists=Test-Path -LiteralPath $src -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $rows+=[pscustomobject]@{Relative=$relative;Key=$key;Exists=$exists}
        if($exists){Copy-Item -LiteralPath $src -Destination (Join-Path $Folder $key) -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Runtime '.pcvrhub_specopsvr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Folder 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Root=$Folder;Rows=$rows;HadBackup=$hadBackup}
}
function Restore-SpecSnapshot([string]$Runtime,$Snapshot) {
    foreach($row in @($Snapshot.Rows)){
        $p=Join-OwnedRelativePath $Runtime $row.Relative
        if($row.Exists){Copy-Item -LiteralPath (Join-Path $Snapshot.Root $row.Key) -Destination $p -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Runtime '.pcvrhub_specopsvr_backup'
    if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Invoke-SpecInstaller {
    $work=$null;$root=$null;$runtime=$null;$snapshot=$null;$changed=$false;$keep=$false
    try{
        if($env:PCVR_HUB_TEST_MODE -ne '1'){Clear-Host}
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Spec Ops: The Line VR - Installer' -ForegroundColor Cyan
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Steam version only. SteamVR and motion controllers are required.' -ForegroundColor White
        Write-Host ' The mod is a beta. The Steam game EXE must match its supported build.' -ForegroundColor Yellow
        Write-Host ' Steam launch options after install: -windowed ResX=2400 ResY=2500' -ForegroundColor Cyan
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Spec Ops: The Line...')
        Write-Host ' [..] Checking saved and Steam game locations; this may take a few seconds.' -ForegroundColor Cyan
        $root=Get-SpecGame;$runtime=Join-Path $root 'Binaries\Win32'
        if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'SpecOpsTheLine' -ErrorAction SilentlyContinue)){throw 'Close Spec Ops: The Line before setup.'}
        $fingerprint=Get-SpecExeFingerprint (Join-Path $runtime 'SpecOpsTheLine.exe')
        if(-not $fingerprint -or $fingerprint.TimeDateStamp -ne 0x50041F0C -or $fingerprint.SizeOfImage -ne 0x012C7000){throw 'This Steam game EXE is not the supported 2012 build. The publisher mod would stay flat; no game files were changed.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $runtime)){throw 'The Steam game folder is not writable. Restart the Hub as administrator, then retry.'}
        Write-Host " [OK] Supported Steam game: $root" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the complete VR mod ZIP...')
        Write-Host ' [..] Checking the current GitHub release; this may take a few seconds.' -ForegroundColor Cyan
        $release=Get-SpecRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_specops_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'SpecOpsTheLineVR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        elseif($release.Manual){
            [void](Invoke-SafeDownload -Urls @() -Destination $archive -Label 'SpecOpsTheLineVR complete ZIP' -ManualUrl $script:SpecPage -AllowSkip $false)
            $tag=(Read-Host ' Release tag shown on the official page (for example v0.9.0)').Trim()
            if(-not(Test-IsTrackableInstalledVersion $tag)){throw 'A release version was not confirmed; no game files were changed.'}
            if((Read-Host " Use this official ZIP as $tag? Y/N").Trim() -notmatch '^(?i:y|yes)$'){throw 'Publisher version was not confirmed.'}
            $release.Tag=$tag
        }else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "SpecOpsTheLineVR $($release.Tag)" -ManualUrl $script:SpecPage -ExpectedReleaseTag $release.Tag -AllowSkip $false)}
        $expanded=Join-Path $work 'publisher'
        $status=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $expanded -Label 'SpecOpsTheLineVR publisher ZIP' -AllowSkip $false -QuietProgress
        if([string]$status -notin @('ok','manual','retry')){throw 'The complete publisher ZIP could not be opened.'}
        $source=Get-ChildItem -LiteralPath $expanded -Directory -Recurse|Where-Object{(Test-Path -LiteralPath (Join-Path $_.FullName 'd3d9.dll') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'openvr_api.dll') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'specopsvr.ini') -PathType Leaf)}|Select-Object -First 1 -ExpandProperty FullName
        if(-not $source){throw 'The selected ZIP lacks the VR proxy, OpenVR runtime, or configuration. Choose the complete publisher ZIP.'}
        $stage=Join-Path $work 'stage';[void][IO.Directory]::CreateDirectory($stage)
        foreach($name in @('d3d9.dll','openvr_api.dll','specopsvr.ini')){Copy-Item -LiteralPath (Join-Path $source $name) -Destination (Join-Path $stage $name) -Force -ErrorAction Stop}
        $ini=Join-Path $stage 'specopsvr.ini'
        $config=[IO.File]::ReadAllText($ini)
        if($config -notmatch '(?im)^\s*autoupdate\s+on\s*$'){throw 'The publisher configuration layout changed; review its update setting before installing.'}
        $config=[regex]::Replace($config,'(?im)^\s*autoupdate\s+on\s*$','autoupdate off')
        [IO.File]::WriteAllText($ini,$config,[Text.UTF8Encoding]::new($false))
        Write-Host ' [..] Protecting existing VR files and installing the publisher runtime.' -ForegroundColor Cyan
        $snapshot=Save-SpecSnapshot -Runtime $runtime -Folder (Join-Path $work 'rollback')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $runtime -Identity 'specopsvr' -AdoptIdenticalExisting -KeepExistingRelativePaths @('specopsvr.ini'))
        $required=@('d3d9.dll','openvr_api.dll','specopsvr.ini','.pcvrhub_specopsvr_ownership.csv')|ForEach-Object{Join-Path $runtime $_}
        if(-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $runtime -NoClear)){throw 'The Spec Ops VR runtime is incomplete after copying.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPECOPS_TEST_RECEIPT){$env:PCVR_SPECOPS_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:SpecContract -GameDir $root -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route Steam)
        $changed=$false
        Write-Host " [OK] SpecOpsTheLineVR $($release.Tag) is installed." -ForegroundColor Green
        $launchOptions='-windowed ResX=2400 ResY=2500'
        Write-Host ''
        Write-Host ' REQUIRED STEAM LAUNCH OPTIONS' -ForegroundColor Yellow
        Write-Host "   $launchOptions" -ForegroundColor Cyan
        $copied=$false
        if($env:PCVR_HUB_TEST_MODE -eq '1'){$copied=$true}
        else{try{Set-Clipboard -Value $launchOptions -DeferManualFallback -ErrorAction Stop;$copied=[bool]$global:PCVRLastClipboardWriteSucceeded}catch{}}
        if($copied){Write-Host ' The launch options are copied to your clipboard.' -ForegroundColor Green}
        else{Write-Host ' Copy the exact line above manually; the clipboard was unavailable.' -ForegroundColor Yellow}
        Write-Host ' In Steam > Spec Ops: The Line > Properties, click Launch Options.' -ForegroundColor White
        Write-Host ' Click its input field and press Ctrl+V (or paste the line above).' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the Steam properties for Spec Ops: The Line...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            if($env:PCVR_SPECOPS_TEST_ACTIONS){Add-Content -LiteralPath $env:PCVR_SPECOPS_TEST_ACTIONS -Value 'open:steam://gameproperties/50300'}
        }else{try{Start-Process 'steam://gameproperties/50300' -ErrorAction Stop|Out-Null}catch{Write-Host ' Open Spec Ops: The Line > Properties in your Steam library.' -ForegroundColor Yellow}}
        Show-PCVRClipboardManualFallback -Text $launchOptions
        [void](Wait-PCVRExplicitEnter -Message 'After pasting the launch options, press Enter to continue...')
        Write-Host ' This near-square desktop window improves clarity in the headset.' -ForegroundColor Gray
        Write-Host ' 1. Start SteamVR, then use Start in VR in the Hub.' -ForegroundColor White
        Write-Host ' Alternative: start Spec Ops: The Line from your Steam Library with SteamVR running.' -ForegroundColor White
        Write-Host ' The Hub-installed default disables the publisher self-updater so Hub updates and removal stay trackable. Existing custom INI files are preserved.' -ForegroundColor Gray
        Write-Host ''
        Write-Host ' The line is crossed one step at a time.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $runtime){try{Restore-SpecSnapshot -Runtime $runtime -Snapshot $snapshot;Write-Host ' [!!] The previous VR files were restored.' -ForegroundColor Yellow}catch{$keep=$true;Write-Host " [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}}
        $message="Spec Ops VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{if($work -and -not $keep -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_SPECOPS_LIBRARY_ONLY -ne '1'){Invoke-SpecInstaller}

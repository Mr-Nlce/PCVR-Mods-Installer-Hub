param([Alias('InstallerChoice')][ValidateSet('','main','fork')][string]$Mod='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
. (Join-Path $PSScriptRoot 'RDRVR-Profiles.ps1')
$script:RdrSelectedMod=if($Mod){$Mod}else{'main'}
$script:RdrShaderPackage='convert'
$Host.UI.RawUI.WindowTitle='Red Dead Redemption VR Installer'
$script:RdrId='red-dead-redemption-vr'
$script:RdrReleasePage='https://github.com/Disonomouss/RDRVR/releases'
$script:RdrHookPage='https://www.nexusmods.com/reddeadredemption/mods/192?tab=files'
$script:RdrFiles=@('dinput8.dll','RDRVR.Gameplay.red','RDRVR.ini','RDRVR_click_revolver.wav','RDRVR_click_rifle.wav','RDRVR_click_shotgun.wav')
$script:RdrProof=@($script:RdrFiles + @('RedHook.dll','winmm.dll','RedHook.ini','.pcvrhub_rdrvr_ownership.csv'))
$script:RdrContract=New-PCVRInstallerContract -Id $script:RdrId -GameName 'Red Dead Redemption VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:RdrReleasePage -RequiredInstalledFileGroups $script:RdrProof

function Assert-RdrFixture([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path)
    if($env:PCVR_HUB_TEST_MODE -eq '1') {
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'rdrvr-fixture.txt') -PathType Leaf)) {
            throw 'RDRVR test paths must stay in an isolated temporary fixture.'
        }
    }
    return $full
}
function Test-RdrGame([string]$Root) {
    if (-not (Test-PCVRGameInstallProof -GameId 'red-dead-redemption-vr' -Root $Root)) { return $false }

    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'RDR.exe') -PathType Leaf))
}
function Get-RdrGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_GAME) {
        $test=Assert-RdrFixture $env:PCVR_RDR_TEST_GAME
        if(-not(Test-RdrGame $test)){throw 'The RDRVR fixture lacks RDR.exe.'}
        return $test
    }
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        $old=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
        if(Test-RdrGame $old){return ([IO.Path]::GetFullPath($old))}
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:RdrId -StateNames @('installed_path','base_game_path','user_located') -ProbeFiles @('RDR.exe')
    if(Test-RdrGame $saved){return ([IO.Path]::GetFullPath($saved))}
    $steam=Find-SteamGameFolder -AppId '2668510' -SteamFolderNames @('Red Dead Redemption') -ProbeExe 'RDR.exe' -HubGameId $script:RdrId
    if(Test-RdrGame $steam){return ([IO.Path]::GetFullPath($steam))}
    foreach($path in @('C:\Program Files\Rockstar Games\Red Dead Redemption','C:\Program Files (x86)\Rockstar Games\Red Dead Redemption')){
        if(Test-RdrGame $path){return $path}
    }
    $picked=Get-GameFolderInteractive -GameName 'Red Dead Redemption (Steam or Rockstar Games Launcher)' -ProbeFile 'RDR.exe' `
        -ManualUrl 'https://store.steampowered.com/app/2668510/'
    if(Test-RdrGame $picked){return ([IO.Path]::GetFullPath($picked))}
    return $null
}
function Get-RdrRelease([object]$ReleaseData=$null) {
    if($null -eq $ReleaseData -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_RELEASE_JSON){
        $ReleaseData=Get-Content -LiteralPath (Assert-RdrFixture $env:PCVR_RDR_TEST_RELEASE_JSON) -Raw | ConvertFrom-Json
    }
    $fork=$script:RdrSelectedMod -eq 'fork'
    if($fork -and $null -eq $ReleaseData){throw 'This online fork source is retired. Select a local publisher ZIP for legacy recovery, or install current RDRVR by Disonomouss.'}
    $pattern=if($fork){if($script:RdrShaderPackage -eq 'shaders'){'(?i)^RDRVR-\d+(?:\.\d+){3}-shaders\.zip$'}else{'(?i)^RDRVR-\d+(?:\.\d+){3}\.zip$'}}else{'(?i)^RDRVR-\d+(?:\.\d+){2,3}\.zip$'}
    $args=@{Repo=$(if($fork){'optimumbox/RDRVR'}else{'Disonomouss/RDRVR'});IncludePrerelease=(-not $fork);AssetPatterns=@($pattern);SkipReleasesWithoutMatchingAsset=$true}
    if($null -ne $ReleaseData){$args.ReleaseData=$ReleaseData}
    $result=Resolve-GitHubReleaseAsset @args
    if(-not $result.Resolved -or [string]$result.AssetName -notmatch '(?i)^RDRVR-(\d+(?:\.\d+){2,3})(?:-shaders)?\.zip$'){
        throw "No usable RDRVR Windows release was found: $($result.Error)"
    }
    return [pscustomobject]@{Version=$Matches[1];Name=[string]$result.AssetName;Url=[string]$result.Url;PageUrl=[string]$result.PageUrl;Local=$false}
}
function Get-RdrLocalRelease([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path.Trim().Trim('"'))
    if(-not(Test-DownloadedPayload -Path $full -IntendedPath 'RDRVR.zip')){throw 'Choose a readable RDRVR release ZIP.'}
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($full)
    try{
        $entry=@($zip.Entries|Where-Object {$_.FullName.Replace('\','/').TrimStart('/') -match '^(?:[^/]+/)?payload/RDRVR_version\.txt$|^RDRVR_version\.txt$'})
        if($entry.Count -ne 1){throw 'The selected ZIP has no unambiguous RDRVR version file.'}
        $reader=[IO.StreamReader]::new($entry[0].Open())
        try{$version=$reader.ReadToEnd().Trim()}finally{$reader.Dispose()}
        if($version -notmatch '^v?(\d+(?:\.\d+){2,3})$'){throw 'The selected RDRVR ZIP has no trackable publisher version.'}
        $version=$Matches[1]
    }finally{$zip.Dispose()}
    return [pscustomobject]@{Version=$version;Name=('RDRVR-'+$version+'.zip');Url=$full;PageUrl=$script:RdrReleasePage;Local=$true}
}
function Get-RdrHookStage([string]$Archive,[string]$Work) {
    $full=[IO.Path]::GetFullPath($Archive.Trim().Trim('"'))
    if(-not(Test-Path -LiteralPath $full -PathType Leaf)){throw 'The selected RedHook archive does not exist.'}
    if(-not(Test-DownloadedPayload -Path $full -IntendedPath 'RedHook.zip')){throw 'The selected RedHook file is not a usable archive.'}
    $expanded=Join-Path $Work 'redhook-expanded'
    Write-Host '  Opening RedHook; this may take a few seconds.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $full -DestinationFolder $expanded -Label 'RedHook' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'RedHook could not be extracted.'}
    $root=Get-ExtractedPayloadRoot -ExtractDir $expanded -RelModFile 'RedHook.dll'
    if(-not $root){throw 'RedHook.dll is missing from the selected archive.'}
    foreach($name in @('RedHook.dll','winmm.dll','RedHook.ini')){
        if(-not(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)){throw "RedHook archive lacks $name."}
    }
    $stage=Join-Path $Work 'redhook-stage';[void][IO.Directory]::CreateDirectory($stage)
    foreach($name in @('RedHook.dll','winmm.dll','RedHook.ini')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $stage $name) -Force}
    $ini=Join-Path $stage 'RedHook.ini'
    $lines=[IO.File]::ReadAllLines($ini);$inSection=$false;$found=$false
    for($index=0;$index -lt $lines.Length;$index++){
        if($lines[$index] -match '^\s*\[([^]]+)\]'){$inSection=$Matches[1] -ieq 'DirectXHook';continue}
        if($inSection -and $lines[$index] -match '^(\s*Disabled\s*=\s*)(true|false)(\s*(?:[;#].*)?)$'){
            $lines[$index]=$Matches[1]+'true'+$Matches[3];$found=$true;break
        }
    }
    if(-not $found){throw 'RedHook.ini lacks the expected DirectXHook setting.'}
    [IO.File]::WriteAllLines($ini,$lines)
    if(-not(Test-RdrHookConfig $ini)){throw 'RedHook DirectXHook must be disabled for RDRVR.'}
    return $stage
}
function Get-RdrHookArchive([scriptblock]$ReadInput=$null,[scriptblock]$OpenPage=$null) {
    $fixture=(''+$env:PCVR_RDR_TEST_REDHOOK).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){
        if(-not(Test-Path -LiteralPath $fixture -PathType Leaf)){throw 'The RedHook test archive is missing.'}
        return (Get-Item -LiteralPath $fixture).FullName
    }
    $downloads=Get-PCVRDownloadsFolder
    $offerFound=$true
    while($true){
        $candidate=$null
        if($offerFound -and $downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
            $candidate=Get-ChildItem -LiteralPath $downloads -Filter '*RedHook*.zip' -File -ErrorAction SilentlyContinue |
                Where-Object { Test-DownloadedPayload -Path $_.FullName -IntendedPath 'RedHook.zip' } |
                Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        }
        if($candidate){
            Write-Host ''
            Write-Host " Found in your registered Downloads folder: $($candidate.FullName)" -ForegroundColor Cyan
            while($true){
                $raw=if($ReadInput){& $ReadInput 'Use this archive? [Y/N]'}else{Read-Host 'Use this archive? [Y/N]'}
                if($null -eq $raw){return $null}
                $answer=(''+$raw).Trim().ToUpperInvariant()
                if($answer -in @('Y','YES')){return $candidate.FullName}
                if($answer -in @('N','NO')){$offerFound=$false;break}
                Write-Host ' Please answer Y or N.' -ForegroundColor Yellow
            }
        }
        Write-Host ''
        if($offerFound){Write-Host ' RedHook v0.8: download the main ZIP from Nexus.' -ForegroundColor White}
        Write-Host ' Drag the RedHook ZIP here or paste its full path.' -ForegroundColor White
        $raw=if($ReadInput){& $ReadInput 'ZIP path (Enter: open Nexus, Q: cancel)'}else{Read-Host 'ZIP path (Enter: open Nexus, Q: cancel)'}
        if($null -eq $raw){return $null}
        $answer=(''+$raw).Trim().Trim('"').Trim("'")
        if($answer -ieq 'Q'){return $null}
        if(-not $answer){
            Write-Host ' On Nexus, choose the v0.8 main file and click Manual download.' -ForegroundColor White
            Write-Host " Nexus Files: $script:RdrHookPage" -ForegroundColor Gray
            if($OpenPage){& $OpenPage $script:RdrHookPage | Out-Null}
            elseif($env:PCVR_HUB_TEST_MODE -ne '1'){
                try{Start-Process $script:RdrHookPage -ErrorAction Stop | Out-Null}
                catch{Write-Host ' Browser could not open. Use the Nexus Files link above.' -ForegroundColor Yellow}
            }
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter after the RedHook ZIP download is complete...' -ReadInput $ReadInput)
            $offerFound=$true
            continue
        }
        if(-not(Test-Path -LiteralPath $answer -PathType Leaf)){
            Write-Host ' This file does not exist. Drag the ZIP here or paste its full path.' -ForegroundColor Yellow
            continue
        }
        if([IO.Path]::GetExtension($answer) -ine '.zip' -or
            -not(Test-DownloadedPayload -Path $answer -IntendedPath 'RedHook.zip')){
            Write-Host ' This is not a usable ZIP. Choose the RedHook main file.' -ForegroundColor Yellow
            continue
        }
        return (Get-Item -LiteralPath $answer).FullName
    }
}
function Get-RdrModStage([string]$Archive,[string]$Work) {
    if(-not(Test-DownloadedPayload -Path $Archive -IntendedPath 'RDRVR.zip')){throw 'The RDRVR download is not a usable ZIP.'}
    $expanded=Join-Path $Work 'rdrvr-expanded'
    Write-Host '  Opening the RDRVR package; this may take a few seconds.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'RDRVR' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'RDRVR could not be extracted.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $expanded -RelModFile 'payload\RDRVR.Gameplay.red'
    if(-not $payload){throw 'The package has no RDRVR gameplay payload.'}
    $source=Join-Path $payload 'payload'
    foreach($name in $script:RdrFiles){if(-not(Test-Path -LiteralPath (Join-Path $source $name) -PathType Leaf)){throw "RDRVR package lacks $name."}}
    $versionFile=Join-Path $source 'RDRVR_version.txt'
    if(-not(Test-Path -LiteralPath $versionFile -PathType Leaf)){throw 'The publisher package lacks a version file.'}
    $version=([IO.File]::ReadAllText($versionFile)).Trim()
    if($version -match '^v?(\d+(?:\.\d+){2,3})$'){$version=$Matches[1]}
    if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The RDRVR package does not provide a trackable installed version.'}
    $script:RdrPayloadVersion=$version
    $stage=Join-Path $Work 'rdrvr-stage';[void][IO.Directory]::CreateDirectory($stage)
    # The publisher installer maps these flat ZIP entries into their
    # runtime subfolders. Normalize them before checking and staging.
    $inventory=Join-Path $source 'RDRVR_files.txt'
    if($script:RdrSelectedMod -eq 'main' -and [IO.File]::Exists($inventory)){
        $listed=@([IO.File]::ReadAllLines($inventory) | ForEach-Object { $_.Trim().Replace('/','\') })
        foreach($relative in @('RDRVR_Launcher\RDRVR_Launcher.exe','RDRVR_Converter\rdrvr_vi_convert.exe','RDRVR_Converter\rdrvr_dxcompiler.dll')){
            $nested=Join-Path $source $relative
            $flat=Join-Path $source ([IO.Path]::GetFileName($relative))
            if($relative -in $listed -and -not [IO.File]::Exists($nested) -and [IO.File]::Exists($flat)){
                [void][IO.Directory]::CreateDirectory((Split-Path -Parent $nested))
                [IO.File]::Move($flat,$nested)
            }
        }
    }
    if(-not(Test-RdrProfilePayload $source $script:RdrSelectedMod)){throw 'The selected RDRVR package lacks required runtime files, gun models or shaders.'}
    foreach($name in @(Get-RdrProfileFiles $source)){Copy-RdrProfileFile (Join-OwnedRelativePath $source $name) (Join-OwnedRelativePath $stage $name)}
    # Version identity comes from the actual extracted payload, not a cached inventory.
    Copy-RdrProfileFile $versionFile (Join-Path $stage 'RDRVR_version.txt')
    foreach($notice in @('LICENSE.txt','THIRD-PARTY-NOTICES.txt')){
        $file=Join-Path $payload $notice
        if([IO.File]::Exists($file)){Copy-RdrProfileFile $file (Join-Path $stage ('RDRVR-'+$notice))}
    }
    return $stage
}
function global:Write-RdrCheckpoint([string[]]$Paths,[string]$Phase) {
    if(-not(Get-Variable PCVRInstallerFileCheckDiagnostics -Scope Global -ErrorAction SilentlyContinue)){$global:PCVRInstallerFileCheckDiagnostics=[Collections.Generic.List[string]]::new()}
    foreach($path in $Paths){
        $present=[IO.File]::Exists($path)
        $detail=('File check ['+$Phase+']: '+$path+' = '+$present)
        Write-Information -MessageData $detail -Tags 'PCVRFileCheck' -InformationAction SilentlyContinue
        $global:PCVRInstallerFileCheckDiagnostics.Add($detail)
        if(-not $present){$path}
    }
}
function Save-RdrSnapshot([string]$Game,[string[]]$StageFiles,[string]$Backup) {
    [void][IO.Directory]::CreateDirectory($Backup)
    $names=[Collections.Generic.List[string]]::new()
    foreach($name in @($StageFiles)+@('.pcvrhub_rdrvr_ownership.csv','.pcvrhub_rdrvr_ownership.csv.new','.pcvrhub_rdrvrredhook_ownership.csv','.pcvrhub_rdrvrredhook_ownership.csv.new','.pcvrhub_version','.pcvrhub_version_b','.pcvrhub_rdractive_ownership.csv','.pcvrhub_rdr_profiles\active.json')){$names.Add($name)}
    foreach($identity in @('rdrvr','rdrvrredhook','rdractive')){
        $manifest=Join-Path $Game ".pcvrhub_${identity}_ownership.csv"
        if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$names.Add((Assert-PCVROwnedRelativePath $row.RelativePath))}}}
    }
    $records=@()
    foreach($name in @($names|Select-Object -Unique)){
        $src=Join-OwnedRelativePath $Game $name;Assert-RdrPathAncestors $src;$exists=Test-Path -LiteralPath $src -PathType Leaf
        $records += [pscustomobject]@{Relative=$name;Exists=$exists}
        if($exists){$dest=Join-OwnedRelativePath (Join-Path $Backup 'files') $name;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath $src -Destination $dest -Force}
    }
    $backupDirs=@{}
    foreach($identity in @('rdrvr','rdrvrredhook','rdractive')){
        $path=Join-Path $Game ".pcvrhub_${identity}_backup";$had=Test-Path -LiteralPath $path -PathType Container
        if($had){Assert-RdrProfileTree $path}
        $backupDirs[$identity]=$had
        if($had){Copy-Item -LiteralPath $path -Destination (Join-Path $Backup "backup-$identity") -Recurse -Force}
    }
    return [pscustomobject]@{Root=$Backup;Records=$records;BackupDirs=$backupDirs}
}
function Restore-RdrSnapshot([string]$Game,$Snapshot) {
    foreach($record in @($Snapshot.Records)){
        $dest=Join-OwnedRelativePath $Game ([string]$record.Relative)
        if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath (Join-OwnedRelativePath (Join-Path $Snapshot.Root 'files') ([string]$record.Relative)) -Destination $dest -Force}
        elseif(Test-Path -LiteralPath $dest -PathType Leaf){Remove-Item -LiteralPath $dest -Force}
    }
    foreach($identity in @('rdrvr','rdrvrredhook','rdractive')){
        $dest=Join-Path $Game ".pcvrhub_${identity}_backup"
        if(Test-Path -LiteralPath $dest){Remove-Item -LiteralPath $dest -Recurse -Force}
        if($Snapshot.BackupDirs[$identity]){Copy-Item -LiteralPath (Join-Path $Snapshot.Root "backup-$identity") -Destination $dest -Recurse -Force}
    }
}
function Invoke-RdrInstaller {
    $work=$null;$game=$null;$snapshot=$null;$storeSnapshot=$null;$changed=$false;$keepWork=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Red Dead Redemption VR - choose your mod' -ForegroundColor Cyan
        Write-Host ' Steam / Rockstar PC game + RedHook v0.8' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' Close the game first. Steam and Rockstar PC versions are supported.' -ForegroundColor White
        Write-Host ' RedHook v0.8 is a separate Nexus download; sign-in may be required.' -ForegroundColor Yellow
        Write-Host ' Existing RedHook settings are never silently replaced.' -ForegroundColor White
        Write-Host ' Allow about 3 GB free for downloads and temporary verified backups.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        Write-Host ''
        Write-Host ' RDRVR by Disonomouss - current publisher releases.' -ForegroundColor Green
        Write-Host ' Existing historical profiles and headset preferences are preserved.' -ForegroundColor White
        if($script:RdrSelectedMod -eq 'fork'){
            $script:RdrReleasePage='https://github.com/optimumbox/RDRVR/releases'
            Write-Host ' Optimumbox shader package:' -ForegroundColor Cyan
            Write-Host ' [1] Convert on this PC: first title-screen wait about 30 seconds.' -ForegroundColor White
            Write-Host ' [2] Prepared shaders: try this if conversion hangs or crashes.' -ForegroundColor White
            do{$shader=(''+(Read-Host 'Choose 1 or 2 (Enter = 1, Q = cancel)')).Trim().ToUpperInvariant()}while($shader -notin @('','1','2','Q'))
            if($shader -eq 'Q'){return}
            $script:RdrShaderPackage=if($shader -eq '2'){'shaders'}else{'convert'}
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate the game...')
        Write-Host '  Checking saved, Steam and Rockstar game locations; this may take a few seconds.' -ForegroundColor Cyan
        $game=Get-RdrGame
        if(-not(Test-RdrGame $game)){
            Write-Host '  A Steam or Rockstar game folder with RDR.exe is required. No files were changed.' -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'A Steam or Rockstar game folder with RDR.exe is required.'}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        if(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_rdrvr_preserved.csv') -PathType Leaf){
            $message='Previously changed RDRVR files were preserved here. Review them before reinstalling.'
            Write-Host "  $message" -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        if(($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_PROCESS_RUNNING -eq '1') -or
            ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'RDR' -ErrorAction SilentlyContinue))){
            Write-Host '  Close Red Dead Redemption before setup. No files were changed.' -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'Close Red Dead Redemption before setup.'}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){
            $message='The game folder is not writable. Restart the Hub as administrator for this game, then retry.'
            Write-Host "  $message" -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        Assert-RdrPathAncestors $game
        Write-Host ('  [OK] Game folder: '+$game) -ForegroundColor Green
        $hookPresent=@('RedHook.dll','winmm.dll','RedHook.ini')|Where-Object{Test-Path -LiteralPath (Join-Path $game $_) -PathType Leaf}
        $needsHook=$hookPresent.Count -eq 0
        if($hookPresent.Count -gt 0 -and $hookPresent.Count -ne 3){
            $message='RedHook is incomplete. Repair it from the Nexus main file before installing RDRVR.'
            Write-Host "  $message" -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');return
        }
        $existingIni=Join-Path $game 'RedHook.ini'
        while(-not $needsHook -and -not(Test-RdrHookConfig $existingIni)){
            Write-Host '  Existing RedHook.ini needs [DirectXHook] Disabled=true.' -ForegroundColor Yellow
            Write-Host "  File: $existingIni" -ForegroundColor White
            Write-Host '  The Hub will not change your existing RedHook settings.' -ForegroundColor White
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'Set [DirectXHook] Disabled=true in the existing RedHook.ini, then retry. Your existing settings were not changed.'}
            $raw=Read-Host 'After editing press Enter to recheck, O to open the file, or Q to quit'
            if($null -eq $raw -or (''+$raw).Trim().ToUpperInvariant() -eq 'Q'){return}
            if((''+$raw).Trim().ToUpperInvariant() -eq 'O'){
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open RedHook.ini in Notepad...')
                Start-Process -FilePath 'notepad.exe' -ArgumentList ('"'+$existingIni+'"') -ErrorAction Stop
            }
        }
        $hookArchive=$null
        if($needsHook){$hookArchive=Get-RdrHookArchive;if(-not $hookArchive){return}}
        $tempChoice=Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes 3221225472L
        if(-not $tempChoice.BasePath){throw 'No writable temporary location has enough free space.'}
        $work=New-PCVRInstallerTempSession -BasePath $tempChoice.BasePath
        $hookStage=$null
        if($needsHook){$hookStage=Get-RdrHookStage -Archive $hookArchive -Work $work}
        Write-Host ''
        Write-Host ' The Hub checks the latest release for your selected RDRVR version.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to choose the RDRVR package...')
        $handover=Get-PCVRRecoveryInput -PathType Leaf
        $choice=if($handover){'L'}else{(''+(Read-Host 'Press Enter for GitHub, L for your downloaded ZIP, or Q to quit')).Trim().ToUpperInvariant()}
        if($choice -eq 'Q'){return}
        if($choice -eq 'L'){
            if(-not $handover){$handover=(''+(Read-Host 'Paste the full path of your downloaded RDRVR ZIP')).Trim()}
            $release=Get-RdrLocalRelease $handover
        }elseif($choice -eq ''){
            Write-Host '  Checking GitHub releases; this may take a few seconds.' -ForegroundColor Cyan
            $release=Get-RdrRelease
        }else{throw 'Choose Enter, L or Q.'}
        $archive=Join-Path $work $release.Name
        Write-Host '  Preparing the publisher ZIP; download may take a little time.' -ForegroundColor Cyan
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force}
        else{
            $download=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "RDRVR $($release.Version)" -ManualUrl $release.PageUrl -AllowSkip $false
            if(-not($download -eq $true -or [string]$download -in @('retry','manual'))){throw 'RDRVR was not downloaded.'}
        }
        $stage=Get-RdrModStage -Archive $archive -Work $work
        $release.Version=$script:RdrPayloadVersion
        $selected=$script:RdrSelectedMod
        $profile=Get-RdrProfileRoot $game $selected
        $storeFiles=@(Get-ChildItem -LiteralPath $stage -Recurse -File|ForEach-Object {$_.FullName.Substring($stage.Length+1)})
        $stageFiles=@('RedHook.dll','winmm.dll','RedHook.ini')
        foreach($slot in @('main','fork')){
            $slotRoot=Get-RdrProfileRoot $game $slot
            foreach($rel in @($storeFiles)+@(Get-RdrProfileFiles $game)+@('.pcvrhub_rdrstore_ownership.csv','.pcvrhub_version')){
                $stageFiles+=('.pcvrhub_rdr_profiles\'+$slot+'\'+$rel)
            }
            if([IO.Directory]::Exists($slotRoot)){
                $stageFiles+=@(Get-ChildItem -LiteralPath $slotRoot -Recurse -File -Force|ForEach-Object {$_.FullName.Substring($game.Length+1)})
            }
        }
        $snapshot=Save-RdrSnapshot -Game $game -StageFiles $stageFiles -Backup (Join-Path $work 'rollback')
        $storeSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $profile -Stage $stage -Identity rdrstore -SnapshotRoot (Join-Path $work 'store-rollback') -ExtraPaths @('.pcvrhub_version')
        $changed=$true
        if($needsHook){
            Write-Host '  Installing RedHook v0.8; this may take a few seconds.' -ForegroundColor Cyan
            [void](Install-OwnedModPayload -SourceRoot $hookStage -GameRoot $game -Identity 'rdrvrredhook' -ProgressLabel 'Installing RedHook')
        }
        Write-Host '  Installing the selected RDRVR profile; this may take a few seconds.' -ForegroundColor Cyan
        Install-RdrProfile -Game $game -Stage $stage -Mod $selected -Version $release.Version
        $required=@(Get-RdrProfileFiles $stage|ForEach-Object {'.pcvrhub_rdr_profiles\'+$selected+'\'+$_})+@('RedHook.dll','winmm.dll','RedHook.ini')
        $watch=@($required|ForEach-Object{Join-Path $game $_})
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_FAULT -eq 'copy'){Remove-Item -LiteralPath $watch[0] -Force}
        if(@(Write-RdrCheckpoint $watch 'immediately-after-copy').Count){throw 'Required files were not copied. Check the destination, permissions and installer log; no antivirus cause has been established.'}
        Write-Host '  Checking the installed files; this takes a few seconds.' -ForegroundColor Gray
        Start-Sleep -Seconds 3
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_FAULT -in @('vanish','retry')){Remove-Item -LiteralPath $watch[0] -Force}
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_FAULT -eq 'retry-hook'){Remove-Item -LiteralPath (Join-Path $game 'RedHook.dll') -Force}
        if(@(Write-RdrCheckpoint $watch 'after-observation').Count){
            $retry={
                [void](Write-RdrCheckpoint $watch 'before-retry')
                [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $profile -Identity rdrstore -KeepExistingRelativePaths @('RDRVR.ini'))
                if($needsHook){[void](Install-OwnedModPayload -SourceRoot $hookStage -GameRoot $game -Identity rdrvrredhook -KeepExistingRelativePaths @('RedHook.ini'))}
                else{
                    foreach($hookFile in @('RedHook.dll','winmm.dll','RedHook.ini')){
                        $target=Join-Path $game $hookFile;$original=Join-Path (Join-Path $snapshot.Root 'files') $hookFile
                        if(-not [IO.File]::Exists($target) -and [IO.File]::Exists($original)){Copy-Item -LiteralPath $original -Destination $target -Force -ErrorAction Stop}
                    }
                }
                [void](Write-RdrCheckpoint $watch 'after-retry')
            }.GetNewClosure()
            $recoveryInput=$null
            if($env:PCVR_HUB_TEST_MODE -eq '1'){
                $reads=@{Count=0};$retryRequested=$env:PCVR_RDR_TEST_FAULT -in @('retry','retry-hook')
                $recoveryInput={param($Message) $reads.Count++;if($retryRequested -and $reads.Count -eq 1){'R'}else{'Q'}}.GetNewClosure()
            }
            $antivirusProbe=$null
            if($env:PCVR_HUB_TEST_MODE -eq '1'){
                # The isolated failure fixture must not write the host clipboard
                # or query/open the user's actual antivirus interface.
                function global:Set-Clipboard {
                    [CmdletBinding()]param($Value,[switch]$DeferManualFallback)
                    $global:PCVRLastClipboardWriteSucceeded=$false
                }
                $antivirusProbe={@('Fixture antivirus')}
            }
            if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -WaitSeconds 3 -Recopy $retry -ReadInput $recoveryInput -GetAntivirusNames $antivirusProbe -NoClear)){throw 'Files disappeared after copying. The previous installation will be restored.'}
        }
        if(@(Write-RdrCheckpoint $watch 'before-commit').Count){throw 'The complete RDRVR runtime could not be confirmed.'}
        Write-Host ('  [OK] RDRVR files - verified ('+$watch.Count+' files).') -ForegroundColor Green
        if(-not(Test-RdrHookConfig (Join-Path $game 'RedHook.ini'))){throw 'RedHook DirectXHook is not disabled.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_RECEIPT){Assert-RdrFixture $env:PCVR_RDR_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        if($env:PCVR_HUB_TEST_MODE -ne '1'){
            if(-not(Save-HubRememberedGameFolder -GameId $script:RdrId -Title 'Red Dead Redemption VR' -GameDir $game -ProbeFiles @('RDR.exe') -StateName 'base_game_path')){throw 'The proven game folder could not be saved.'}
        }
        $contract=New-PCVRInstallerContract -Id $script:RdrId -GameName 'Red Dead Redemption VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:RdrReleasePage -RequiredInstalledFileGroups $required
        $versionSlot=if($selected -eq 'fork'){'Secondary'}else{'Primary'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $release.Version -Route Current -VersionSlot $versionSlot -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @((Join-Path $profile '.pcvrhub_version')))
        $changed=$false
        [void](Write-RdrCheckpoint $watch 'after-commit')
        Write-Host "  [OK] RDRVR $($release.Version) installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub. Choose Original or Optimumbox.'
        Write-Host '  Start your OpenXR runtime before playing.' -ForegroundColor White
        Write-Host '  RedHook stays installed if you later remove RDRVR.' -ForegroundColor White
        Write-Host ''
        Write-Host '  MANUAL STEP - in the game graphics settings:' -ForegroundColor Yellow
        Write-Host '  Set Depth of Field to OFF before playing in VR.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  The frontier is waiting. Ride into it.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{[void](Write-RdrCheckpoint $watch 'before-rollback');if($storeSnapshot){Restore-PCVRPublisherZipSnapshot -GameRoot $profile -Snapshot $storeSnapshot};Restore-RdrSnapshot -Game $game -Snapshot $snapshot;[void](Write-RdrCheckpoint $watch 'after-rollback');Write-Host '  Previous game files restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host "  [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}
        }
        $message="RDRVR setup did not complete: $($_.Exception.Message)"
        Write-Host "  [X] $message" -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{
        if($work -and -not $keepWork -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
if($env:PCVR_RDR_LIBRARY_ONLY -ne '1'){Invoke-RdrInstaller}

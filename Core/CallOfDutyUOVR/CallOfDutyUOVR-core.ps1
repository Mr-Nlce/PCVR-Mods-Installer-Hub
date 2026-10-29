$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Call of Duty: United Offensive VR Installer'
$script:CodUOId='call-of-duty-united-offensive-vr'
$script:CodUORepo='lambda-gab/cod1-vr'
$script:CodUOPage='https://github.com/lambda-gab/cod1-vr/releases'
$script:CodUOReviewed='https://github.com/lambda-gab/cod1-vr/releases/download/v1.7.1/cod-vr-manual-install.zip'
$script:CodUOPublisherFiles=@('opengl32.dll','openxr_loader.dll','cod_vr.ini','supporters.ini','CoD-VR-Launcher.exe')
$script:CodUOFiles=@($script:CodUOPublisherFiles)+@('Start CoD VR.ps1')
$script:CodUOManifest='.pcvrhub_cod1vr_ownership.csv'
$script:CodUOGroups=@($script:CodUOFiles|ForEach-Object{if($_ -eq 'opengl32.dll'){'opengl32.dll|opengl32.dll.pcvrhub_off'}else{$_}})
$script:CodUOContract=New-PCVRInstallerContract -Id $script:CodUOId -GameName 'Call of Duty: United Offensive VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:CodUOPage -Routes @('Steam','Retail','Custom') -RequiredInstalledFileGroups (@('CoDUOSP.exe','uo\pakuo00.pk3')+$script:CodUOGroups+@($script:CodUOManifest))

function Test-CodUOGame([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'CoDUOSP.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Root 'uo\pakuo00.pk3') -PathType Leaf))
}
function Resolve-CodUOGameInput([string]$Answer){
    $path=ConvertTo-PCVRCanonicalUserPath $Answer
    if(Test-Path -LiteralPath $path -PathType Leaf){
        if([IO.Path]::GetFileName($path) -notin @('CoDUOSP.exe','CoDUOMP.exe')){return $null}
        $path=Split-Path -Parent $path
    }
    if(Test-CodUOGame $path){return [IO.Path]::GetFullPath($path)}
    return $null
}
function Get-CodUOGame{
    if($env:PCVR_CODUO_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_CODUO_TEST_GAME)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'cod1-fixture.txt') -PathType Leaf) -or -not(Test-CodUOGame $root)){throw 'CODUO test game must be an isolated complete fixture.'}
        return $root
    }
    $handoff=Get-PCVRRecoveryInput
    if($handoff){
        $selected=Resolve-CodUOGameInput $handoff
        if($selected){
            if(-not(Save-HubRememberedGameFolder -GameId $script:CodUOId -Title $script:CodUOContract.GameName -GameDir $selected -ProbeFiles @('CoDUOSP.exe','uo\pakuo00.pk3') -UserSelected)){throw 'The selected recovery game folder could not be saved.'}
            [void](Set-PCVRRecoveryInput '');return $selected
        }
    }
    $paths=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:CodUOId -StateNames @('installed_path','user_located','base_game_path') -ProbeFiles @('CoDUOSP.exe','uo\pakuo00.pk3')
    if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '2640' -SteamFolderNames @('Call of Duty United Offensive') -ProbeExe 'CoDUOSP.exe' -HubGameId $script:CodUOId;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Call of Duty United Offensive','C:\Program Files (x86)\Activision\Call of Duty')
    foreach($path in @($paths|Where-Object{$_}|Select-Object -Unique)){if(Test-CodUOGame $path){return [IO.Path]::GetFullPath($path)}}
    Write-Host '  Call of Duty was not found in the Steam or retail folders.' -ForegroundColor Yellow
    Write-Host '  Drag CoDUOSP.exe or CoDUOMP.exe from your own game folder onto this window,' -ForegroundColor White
    Write-Host '  or paste either full EXE path or the game folder path.' -ForegroundColor White
    while($true){
        $answer=(''+(Read-Host '  Game EXE or folder')).Trim().Trim('"').Trim("'")
        if(-not $answer){Write-Host '  Choose a game EXE or folder to continue.' -ForegroundColor Yellow;continue}
        $path=Resolve-CodUOGameInput $answer
        if($path){
            [void](Save-HubRememberedGameFolder -GameId $script:CodUOId -Title 'Call of Duty: United Offensive VR' -GameDir $path -ProbeFiles @('CoDUOSP.exe','uo\pakuo00.pk3') -UserSelected)
            return $path
        }
        Write-Host '  This folder needs CoDUOSP.exe and uo\pakuo00.pk3. Multiplayer alone is not supported.' -ForegroundColor Yellow
    }
}
function Get-CodUORoute([string]$Game){
    if($env:PCVR_CODUO_TEST_ROUTE){return $env:PCVR_CODUO_TEST_ROUTE}
    if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
    if($Game -match '(?i)[\\/]Activision[\\/]Call of Duty$'){return 'Retail'}
    return 'Custom'
}
function Get-CodUOExecutableTimestamp([string]$File){
    $stream=[IO.File]::OpenRead($File);$reader=[IO.BinaryReader]::new($stream)
    try{
        if($stream.Length -lt 64 -or $reader.ReadUInt16() -ne 23117){throw 'The game EXE is not a readable Windows executable.'}
        $stream.Position=60;$pe=$reader.ReadInt32()
        if($pe -lt 64 -or $pe+12 -gt $stream.Length){throw 'The game EXE has an invalid PE header.'}
        $stream.Position=$pe
        if($reader.ReadUInt32() -ne 17744 -or $reader.ReadUInt16() -ne 332){throw 'This VR mod requires the 32-bit x86 game.'}
        $stream.Position=$pe+8;return $reader.ReadUInt32()
    }finally{$reader.Dispose();$stream.Dispose()}
}
function Assert-CodUOVersion([string]$Game){
    if($env:PCVR_CODUO_TEST_GAME){return}
    # This is the publisher's supported base-game build, not a mod-download
    # checksum/name gate. FileVersion 1.5 was an incorrect Hub assumption.
    if((Get-CodUOExecutableTimestamp (Join-Path $Game 'CoDUOSP.exe')) -ne 0x412653f0){throw 'The publisher supports CoDUOSP.exe 1.51 (publisher-supported build). Choose that single-player game EXE in recovery. No files were changed.'}
}

function Get-CodUORelease{
    if($env:PCVR_CODUO_TEST_ARCHIVE){return [pscustomobject]@{Version='v1.7.1';Url=$env:PCVR_CODUO_TEST_ARCHIVE;Local=$true}}
    $manual=Get-PCVRRecoveryInput -PathType Leaf
    if($manual){
        do{$version=(Read-Host '  Version shown on the official Call of Duty VR release page').Trim()}until(Test-IsTrackableInstalledVersion $version)
        [void](Set-PCVRRecoveryInput '')
        return [pscustomobject]@{Version=$version;Url=$manual;Local=$true}
    }
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:CodUORepo -IncludePrerelease $false -AssetPatterns @('(?i)^(?!.*(?:source|symbols|debug))(?:cod[-._ ]?vr|callofduty[-._ ]?vr).*\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=$null}
    if($r -and $r.Resolved -and $r.Url -and (Test-IsTrackableInstalledVersion ([string]$r.Tag))){return [pscustomobject]@{Version=[string]$r.Tag;Url=[string]$r.Url;Local=$false}}
    Write-Host '  Current GitHub release could not be confirmed. The reviewed v1.7.1 ZIP is available.' -ForegroundColor Yellow
    Write-Host '  A newer release may exist; the official release page is offered on download failure.' -ForegroundColor White
    if((Read-Host '  Download reviewed v1.7.1? Y/N').Trim() -notmatch '^(?i)y(?:es)?$'){throw 'Use recovery to open the official releases page and hand over the current ZIP.'}
    return [pscustomobject]@{Version='v1.7.1';Url=$script:CodUOReviewed;Local=$false}
}
function Save-CodUOSnapshot([string]$Game,[string]$Folder){
    [void][IO.Directory]::CreateDirectory($Folder)
    $rows=@()
    foreach($name in (@($script:CodUOFiles)+@($script:CodUOManifest,'.pcvrhub_version','opengl32.dll.pcvrhub_off'))){
        $source=Join-Path $Game $name;$exists=Test-Path -LiteralPath $source -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($name)).Replace('/','_')
        $rows+=[pscustomobject]@{Name=$name;Key=$key;Exists=$exists}
        if($exists){Copy-Item -LiteralPath $source -Destination (Join-Path $Folder $key) -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_cod1vr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Folder 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Rows=$rows;Folder=$Folder;HadBackup=$hadBackup}
}
function Restore-CodUOSnapshot([string]$Game,$Snapshot){
    foreach($row in $Snapshot.Rows){
        $target=Join-Path $Game $row.Name
        if($row.Exists){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_cod1vr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Get-CodUOShortcutPath{
    $desktop=if($env:PCVR_CODUO_TEST_DESKTOP){$env:PCVR_CODUO_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
    return (Join-Path $desktop 'Call of Duty United Offensive VR.lnk')
}
function Set-CodUOShortcut([string]$Game){
    $link=Get-CodUOShortcutPath;$launcher=Join-Path $Game 'CoD-VR-Launcher.exe';$controller=Join-Path $Game 'Start CoD VR.ps1'
    $shell=New-Object -ComObject WScript.Shell;$script:CodUOOldShortcut=$null
    if(Test-Path -LiteralPath $link -PathType Leaf){
        $existing=$shell.CreateShortcut($link)
        $legacy=([string]$existing.TargetPath).Equals($launcher,[StringComparison]::OrdinalIgnoreCase)
        $owned=([string]$existing.TargetPath -like '*\powershell.exe' -and $existing.Arguments.Contains($controller))
        if(-not $legacy -and -not $owned){throw 'The Call of Duty VR desktop shortcut belongs to another target. Rename it, then retry.'}
        $script:CodUOOldShortcut=[IO.File]::ReadAllBytes($link)
    }
    $shortcut=$shell.CreateShortcut($link)
    $shortcut.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $shortcut.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$controller+'" -Game UO'
    $shortcut.WorkingDirectory=$Game;$shortcut.IconLocation=$launcher+',0';$shortcut.Description='Start Call of Duty: United Offensive VR';$shortcut.Save()
    if(-not(Test-Path -LiteralPath $link -PathType Leaf)){throw 'The VR desktop shortcut could not be created.'}
    return $true
}

function Get-CodUOMissing([string]$Game,[string]$Phase){
    $missing=@();foreach($rel in $script:CodUOFiles){$path=Join-Path $Game $rel;$present=Test-Path -LiteralPath $path -PathType Leaf;if($rel -eq 'opengl32.dll' -and -not $present){$present=Test-Path -LiteralPath ($path+'.pcvrhub_off') -PathType Leaf};Write-PCVRFileCheckResult -Path $path -Present $present -Phase $Phase -DisplayName $rel;if(-not $present){$missing+=$path}};return $missing
}
function Invoke-CodUOInstaller{
    $work=$null;$snapshot=$null;$changed=$false;$game=$null;$shortcutMade=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Call of Duty: United Offensive VR - Installer' -ForegroundColor Cyan
        Write-Host '  Single player EXE 1.51; motion controls; 32-bit OpenXR' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  The Hub installs the complete official ZIP and a dedicated start shortcut.' -ForegroundColor White
        Write-Host '  Existing same-name files are protected; your saves remain untouched.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Call of Duty...')
        $game=Get-CodUOGame;$route=Get-CodUORoute $game
        Write-Host "  [OK] Game ($route): $game" -ForegroundColor Green
        Assert-CodUOVersion $game
        if(Get-Process -Name 'CoDSP','CoDUOSP','CoD-VR-Launcher' -ErrorAction SilentlyContinue){throw 'Close Call of Duty before installing VR.'}
        if(-not(Test-InstallerTargetWritable $game)){throw 'The game folder is not writable.'}
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Call of Duty VR ZIP...')
        $release=Get-CodUORelease
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'cod-vr-manual-install.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Call of Duty VR $($release.Version)" -ManualUrl $script:CodUOPage -AllowSkip:$false -PlainProgress)}
        $stage=Join-Path $work 'stage'
        $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $stage
        if(-not $safe.Safe -or -not $safe.Inspectable){throw 'The publisher ZIP is unreadable or has unsafe paths.'}
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Call of Duty VR' -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The publisher ZIP could not be extracted.'}
        foreach($name in $script:CodUOPublisherFiles){
            $file=Join-Path $stage $name
            if(-not(Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -eq 0){throw "Publisher package lacks $name."}
        }
        $payload=Join-Path $work 'payload';[void][IO.Directory]::CreateDirectory($payload)
        foreach($name in $script:CodUOPublisherFiles){Copy-Item -LiteralPath (Join-Path $stage $name) -Destination (Join-Path $payload $name) -ErrorAction Stop}
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\CallOfDuty2003VR\Start-CallOfDuty2003VR.ps1') -Destination (Join-Path $payload 'Start CoD VR.ps1') -ErrorAction Stop
        $parked=Test-Path -LiteralPath (Join-Path $game 'opengl32.dll.pcvrhub_off') -PathType Leaf
        if($parked -and (Test-Path -LiteralPath (Join-Path $game 'opengl32.dll'))){throw 'Both active and parked VR proxies exist. Resolve that conflict before Retry; neither was overwritten.'}
        $snapshot=Save-CodUOSnapshot -Game $game -Folder (Join-Path $work 'rollback')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the mod files and create the VR desktop shortcut...')
        $changed=$true
        if($parked){Move-Item -LiteralPath (Join-Path $game 'opengl32.dll.pcvrhub_off') -Destination (Join-Path $game 'opengl32.dll') -ErrorAction Stop}
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $game -Identity 'cod1vr' -KeepExistingRelativePaths @('cod_vr.ini') -AdoptIdenticalExisting -ProgressLabel 'Installing Call of Duty VR')
        if($parked){Move-Item -LiteralPath (Join-Path $game 'opengl32.dll') -Destination (Join-Path $game 'opengl32.dll.pcvrhub_off') -ErrorAction Stop}
        $missing=@(Get-CodUOMissing $game 'after-copy');if($missing.Count){throw 'Required files were not copied. Check the target path, permissions and log; no antivirus cause has been established.'}
        [void](Get-CodUOMissing $game 'after-mode-preservation')
        $required=@($script:CodUOFiles)+@($script:CodUOManifest)|ForEach-Object{if($_ -eq 'opengl32.dll' -and $parked){Join-Path $game 'opengl32.dll.pcvrhub_off'}else{Join-Path $game $_}}
        if(-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)){throw 'Required Call of Duty VR files are missing after copy.'}
        if(@(Get-CodUOMissing $game 'after-observation').Count){throw 'Required VR files are missing after observation.'}
        $shortcutMade=Set-CodUOShortcut $game
        $receipt=if($env:PCVR_CODUO_TEST_RECEIPT){$env:PCVR_CODUO_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:CodUOContract -GameDir $game -Version $release.Version -Route $route -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host "  [OK] Call of Duty VR $($release.Version) is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub. It opens the publisher launcher.' -ForegroundColor White
        Write-Host '  Alternatively, use the Call of Duty United Offensive VR desktop shortcut.' -ForegroundColor White
        Write-Host '  In the launcher, select United Offensive; with Steam, choose PLAY in the publisher launcher; it starts the Steam game.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Bastogne called. It is still not asking nicely.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{
                if($shortcutMade){$link=Get-CodUOShortcutPath;if($null -ne $script:CodUOOldShortcut){[IO.File]::WriteAllBytes($link,$script:CodUOOldShortcut)}elseif(Test-Path -LiteralPath $link -PathType Leaf){Remove-Item -LiteralPath $link -Force}}
                [void](Get-CodUOMissing $game 'before-rollback')
                Restore-CodUOSnapshot -Game $game -Snapshot $snapshot
                [void](Get-CodUOMissing $game 'after-rollback')
                Write-Host '  Previous Call of Duty files were restored.' -ForegroundColor Yellow
            }catch{Write-Host "  Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
        }
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_CODUO_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-CodUOInstaller;break}catch{
        $message="Call of Duty VR setup did not complete: $($_.Exception.Message)"
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId $script:CodUOId -InstallerFolder $PSScriptRoot -RecoveryPageUrl $script:CodUOPage)
    }}
}

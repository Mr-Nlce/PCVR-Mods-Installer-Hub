$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Call of Duty (2003) VR Installer'
$script:Cod1Id='call-of-duty-2003-vr'
$script:Cod1Repo='lambda-gab/cod1-vr'
$script:Cod1Page='https://github.com/lambda-gab/cod1-vr/releases'
$script:Cod1Reviewed='https://github.com/lambda-gab/cod1-vr/releases/download/v1.7.1/cod-vr-manual-install.zip'
$script:Cod1PublisherFiles=@('opengl32.dll','openxr_loader.dll','cod_vr.ini','supporters.ini','CoD-VR-Launcher.exe')
$script:Cod1Files=@($script:Cod1PublisherFiles)+@('Start CoD VR.ps1')
$script:Cod1Manifest='.pcvrhub_cod1vr_ownership.csv'
$script:Cod1Groups=@($script:Cod1Files|ForEach-Object{if($_ -eq 'opengl32.dll'){'opengl32.dll|opengl32.dll.pcvrhub_off'}else{$_}})
$script:Cod1Contract=New-PCVRInstallerContract -Id $script:Cod1Id -GameName 'Call of Duty (2003) VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:Cod1Page -Routes @('Steam','Retail','Custom') -RequiredInstalledFileGroups (@('CoDSP.exe','main\pak0.pk3')+$script:Cod1Groups+@($script:Cod1Manifest))

function Test-Cod1Game([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'CoDSP.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Root 'main\pak0.pk3') -PathType Leaf))
}
function Resolve-Cod1GameInput([string]$Answer){
    $path=ConvertTo-PCVRCanonicalUserPath $Answer
    if(Test-Path -LiteralPath $path -PathType Leaf){
        if([IO.Path]::GetFileName($path) -notin @('CoDSP.exe','CoDMP.exe')){return $null}
        $path=Split-Path -Parent $path
    }
    if(Test-Cod1Game $path){return [IO.Path]::GetFullPath($path)}
    return $null
}
function Get-Cod1Game{
    if($env:PCVR_COD1_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_COD1_TEST_GAME)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'cod1-fixture.txt') -PathType Leaf) -or -not(Test-Cod1Game $root)){throw 'COD1 test game must be an isolated complete fixture.'}
        return $root
    }
    $handoff=Get-PCVRRecoveryInput
    if($handoff){
        $selected=Resolve-Cod1GameInput $handoff
        if($selected){
            if(-not(Save-HubRememberedGameFolder -GameId $script:Cod1Id -Title $script:Cod1Contract.GameName -GameDir $selected -ProbeFiles @('CoDSP.exe','main\pak0.pk3') -UserSelected)){throw 'The selected recovery game folder could not be saved.'}
            [void](Set-PCVRRecoveryInput '');return $selected
        }
    }
    $paths=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:Cod1Id -GameTitle 'Call of Duty (2003) VR' -SteamId '2620' -StateNames @('installed_path','user_located','base_game_path') -ProbeFiles @('CoDSP.exe','main\pak0.pk3')
    if($saved){$paths+=$saved}
    if(-not $saved){
        $shared=Get-PCVRRememberedGameFolder -GameId 'call-of-duty-united-offensive-vr' -ProbeFiles @('CoDSP.exe','main\pak0.pk3')
        if($shared){
            if(-not(Save-HubRememberedGameFolder -GameId $script:Cod1Id -Title 'Call of Duty (2003) VR' -GameDir $shared -ProbeFiles @('CoDSP.exe','main\pak0.pk3'))){throw 'The recovered game folder could not be saved.'}
            $paths+=$shared
        }
    }
    try{$steam=Find-SteamGameFolder -AppId '2620' -SteamFolderNames @('Call of Duty') -ProbeExe 'CoDSP.exe' -HubGameId $script:Cod1Id;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Call of Duty','C:\Program Files (x86)\Activision\Call of Duty')
    foreach($path in @($paths|Where-Object{$_}|Select-Object -Unique)){if(Test-Cod1Game $path){return [IO.Path]::GetFullPath($path)}}
    Write-Host '  Call of Duty was not found in the Steam or retail folders.' -ForegroundColor Yellow
    Write-Host '  Drag CoDSP.exe or CoDMP.exe from your own game folder onto this window,' -ForegroundColor White
    Write-Host '  or paste either full EXE path or the game folder path.' -ForegroundColor White
    while($true){
        $answer=(''+(Read-Host '  Game EXE or folder')).Trim().Trim('"').Trim("'")
        if(-not $answer){Write-Host '  Choose a game EXE or folder to continue.' -ForegroundColor Yellow;continue}
        $path=Resolve-Cod1GameInput $answer
        if($path){
            if(-not(Save-HubRememberedGameFolder -GameId $script:Cod1Id -Title 'Call of Duty (2003) VR' -GameDir $path -ProbeFiles @('CoDSP.exe','main\pak0.pk3') -UserSelected)){throw 'The selected game folder could not be saved. Retry after checking access to Hub user data.'}
            return $path
        }
        Write-Host '  This folder needs CoDSP.exe and main\pak0.pk3. Multiplayer alone is not supported.' -ForegroundColor Yellow
    }
}
function Get-Cod1Route([string]$Game){
    if($env:PCVR_COD1_TEST_ROUTE){return $env:PCVR_COD1_TEST_ROUTE}
    if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
    if($Game -match '(?i)[\\/]Activision[\\/]Call of Duty$'){return 'Retail'}
    return 'Custom'
}
function Get-Cod1ExecutableTimestamp([string]$File){
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
function Assert-Cod1Version([string]$Game){
    if($env:PCVR_COD1_TEST_GAME){return}
    # This is the publisher's supported base-game build, not a mod-download
    # checksum/name gate. FileVersion 1.5 was an incorrect Hub assumption.
    if((Get-Cod1ExecutableTimestamp (Join-Path $Game 'CoDSP.exe')) -ne 0x40443fda){throw 'The publisher supports CoDSP.exe 1.3 (March 2004 build). Choose that single-player game EXE in recovery. No files were changed.'}
}

function Get-Cod1Release{
    if($env:PCVR_COD1_TEST_ARCHIVE){return [pscustomobject]@{Version='v1.7.1';Url=$env:PCVR_COD1_TEST_ARCHIVE;Local=$true}}
    $manual=Get-PCVRRecoveryInput -PathType Leaf
    if($manual){
        do{$version=(Read-Host '  Version shown on the official Call of Duty VR release page').Trim()}until(Test-IsTrackableInstalledVersion $version)
        [void](Set-PCVRRecoveryInput '')
        return [pscustomobject]@{Version=$version;Url=$manual;Local=$true}
    }
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:Cod1Repo -IncludePrerelease $false -AssetPatterns @('(?i)^(?!.*(?:source|symbols|debug))(?:cod[-._ ]?vr|callofduty[-._ ]?vr).*\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=$null}
    if($r -and $r.Resolved -and $r.Url -and (Test-IsTrackableInstalledVersion ([string]$r.Tag))){return [pscustomobject]@{Version=[string]$r.Tag;Url=[string]$r.Url;Local=$false}}
    Write-Host '  Current GitHub release could not be confirmed. The reviewed v1.7.1 ZIP is available.' -ForegroundColor Yellow
    Write-Host '  A newer release may exist; the official release page is offered on download failure.' -ForegroundColor White
    if((Read-Host '  Download reviewed v1.7.1? Y/N').Trim() -notmatch '^(?i)y(?:es)?$'){throw 'Use recovery to open the official releases page and hand over the current ZIP.'}
    return [pscustomobject]@{Version='v1.7.1';Url=$script:Cod1Reviewed;Local=$false}
}
function Save-Cod1Snapshot([string]$Game,[string]$Folder){
    [void][IO.Directory]::CreateDirectory($Folder)
    $rows=@()
    foreach($name in (@($script:Cod1Files)+@($script:Cod1Manifest,'.pcvrhub_version','opengl32.dll.pcvrhub_off'))){
        $source=Join-Path $Game $name;$exists=Test-Path -LiteralPath $source -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($name)).Replace('/','_')
        $rows+=[pscustomobject]@{Name=$name;Key=$key;Exists=$exists}
        if($exists){Copy-Item -LiteralPath $source -Destination (Join-Path $Folder $key) -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_cod1vr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Folder 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Rows=$rows;Folder=$Folder;HadBackup=$hadBackup}
}
function Restore-Cod1Snapshot([string]$Game,$Snapshot){
    foreach($row in $Snapshot.Rows){
        $target=Join-Path $Game $row.Name
        if($row.Exists){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_cod1vr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Get-Cod1ShortcutPath{
    $desktop=if($env:PCVR_COD1_TEST_DESKTOP){$env:PCVR_COD1_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
    return (Join-Path $desktop 'Call of Duty VR.lnk')
}
function Set-Cod1Shortcut([string]$Game){
    $link=Get-Cod1ShortcutPath;$launcher=Join-Path $Game 'CoD-VR-Launcher.exe';$controller=Join-Path $Game 'Start CoD VR.ps1'
    $shell=New-Object -ComObject WScript.Shell;$script:Cod1OldShortcut=$null
    if(Test-Path -LiteralPath $link -PathType Leaf){
        $existing=$shell.CreateShortcut($link)
        $legacy=([string]$existing.TargetPath).Equals($launcher,[StringComparison]::OrdinalIgnoreCase)
        $owned=([string]$existing.TargetPath -like '*\powershell.exe' -and $existing.Arguments.Contains($controller))
        if(-not $legacy -and -not $owned){throw 'The Call of Duty VR desktop shortcut belongs to another target. Rename it, then retry.'}
        $script:Cod1OldShortcut=[IO.File]::ReadAllBytes($link)
    }
    $shortcut=$shell.CreateShortcut($link)
    $shortcut.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $shortcut.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$controller+'" -Game SP'
    $shortcut.WorkingDirectory=$Game;$shortcut.IconLocation=$launcher+',0';$shortcut.Description='Start Call of Duty (2003) VR';$shortcut.Save()
    if(-not(Test-Path -LiteralPath $link -PathType Leaf)){throw 'The VR desktop shortcut could not be created.'}
    return $true
}

function Get-Cod1Missing([string]$Game,[string]$Phase){
    $missing=@();foreach($rel in $script:Cod1Files){$path=Join-Path $Game $rel;$present=Test-Path -LiteralPath $path -PathType Leaf;if($rel -eq 'opengl32.dll' -and -not $present){$present=Test-Path -LiteralPath ($path+'.pcvrhub_off') -PathType Leaf};Write-PCVRFileCheckResult -Path $path -Present $present -Phase $Phase -DisplayName $rel;if(-not $present){$missing+=$path}};return $missing
}
function Invoke-Cod1Installer{
    $work=$null;$snapshot=$null;$changed=$false;$game=$null;$shortcutMade=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Call of Duty (2003) VR - Installer' -ForegroundColor Cyan
        Write-Host '  Single player EXE 1.3; motion controls; 32-bit OpenXR' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  The Hub installs the complete official ZIP and a dedicated start shortcut.' -ForegroundColor White
        Write-Host '  Existing same-name files are protected; your saves remain untouched.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Call of Duty...')
        $game=Get-Cod1Game;$route=Get-Cod1Route $game
        Write-Host "  [OK] Game ($route): $game" -ForegroundColor Green
        Assert-Cod1Version $game
        if(Get-Process -Name 'CoDSP','CoDUOSP','CoD-VR-Launcher' -ErrorAction SilentlyContinue){throw 'Close Call of Duty before installing VR.'}
        if(-not(Test-InstallerTargetWritable $game)){throw 'The game folder is not writable.'}
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Call of Duty VR ZIP...')
        $release=Get-Cod1Release
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'cod-vr-manual-install.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Call of Duty VR $($release.Version)" -ManualUrl $script:Cod1Page -AllowSkip:$false -PlainProgress)}
        $stage=Join-Path $work 'stage'
        $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $stage
        if(-not $safe.Safe -or -not $safe.Inspectable){throw 'The publisher ZIP is unreadable or has unsafe paths.'}
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Call of Duty VR' -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The publisher ZIP could not be extracted.'}
        foreach($name in $script:Cod1PublisherFiles){
            $file=Join-Path $stage $name
            if(-not(Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -eq 0){throw "Publisher package lacks $name."}
        }
        $payload=Join-Path $work 'payload';[void][IO.Directory]::CreateDirectory($payload)
        foreach($name in $script:Cod1PublisherFiles){Copy-Item -LiteralPath (Join-Path $stage $name) -Destination (Join-Path $payload $name) -ErrorAction Stop}
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\CallOfDuty2003VR\Start-CallOfDuty2003VR.ps1') -Destination (Join-Path $payload 'Start CoD VR.ps1') -ErrorAction Stop
        $parked=Test-Path -LiteralPath (Join-Path $game 'opengl32.dll.pcvrhub_off') -PathType Leaf
        if($parked -and (Test-Path -LiteralPath (Join-Path $game 'opengl32.dll'))){throw 'Both active and parked VR proxies exist. Resolve that conflict before Retry; neither was overwritten.'}
        $snapshot=Save-Cod1Snapshot -Game $game -Folder (Join-Path $work 'rollback')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the mod files and create the VR desktop shortcut...')
        $changed=$true
        if($parked){Move-Item -LiteralPath (Join-Path $game 'opengl32.dll.pcvrhub_off') -Destination (Join-Path $game 'opengl32.dll') -ErrorAction Stop}
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $game -Identity 'cod1vr' -KeepExistingRelativePaths @('cod_vr.ini') -AdoptIdenticalExisting -ProgressLabel 'Installing Call of Duty VR')
        if($parked){Move-Item -LiteralPath (Join-Path $game 'opengl32.dll') -Destination (Join-Path $game 'opengl32.dll.pcvrhub_off') -ErrorAction Stop}
        $missing=@(Get-Cod1Missing $game 'after-copy');if($missing.Count){throw 'Required files were not copied. Check the target path, permissions and log; no antivirus cause has been established.'}
        [void](Get-Cod1Missing $game 'after-mode-preservation')
        $required=@($script:Cod1Files)+@($script:Cod1Manifest)|ForEach-Object{if($_ -eq 'opengl32.dll' -and $parked){Join-Path $game 'opengl32.dll.pcvrhub_off'}else{Join-Path $game $_}}
        if(-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)){throw 'Required Call of Duty VR files are missing after copy.'}
        if(@(Get-Cod1Missing $game 'after-observation').Count){throw 'Required VR files are missing after observation.'}
        $shortcutMade=Set-Cod1Shortcut $game
        $receipt=if($env:PCVR_COD1_TEST_RECEIPT){$env:PCVR_COD1_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:Cod1Contract -GameDir $game -Version $release.Version -Route $route -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host "  [OK] Call of Duty VR $($release.Version) is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub. It opens the publisher launcher.' -ForegroundColor White
        Write-Host '  Alternatively, use the Call of Duty VR desktop shortcut.' -ForegroundColor White
        Write-Host '  In the launcher, select Call of Duty; with Steam, choose PLAY in the publisher launcher; it starts the Steam game.' -ForegroundColor White
        Write-Host ''
        Write-Host '  One rifle for two men. Looks like you got the ammo, comrade.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{
                if($shortcutMade){$link=Get-Cod1ShortcutPath;if($null -ne $script:Cod1OldShortcut){[IO.File]::WriteAllBytes($link,$script:Cod1OldShortcut)}elseif(Test-Path -LiteralPath $link -PathType Leaf){Remove-Item -LiteralPath $link -Force}}
                [void](Get-Cod1Missing $game 'before-rollback')
                Restore-Cod1Snapshot -Game $game -Snapshot $snapshot
                [void](Get-Cod1Missing $game 'after-rollback')
                Write-Host '  Previous Call of Duty files were restored.' -ForegroundColor Yellow
            }catch{Write-Host "  Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
        }
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_COD1_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-Cod1Installer;break}catch{
        $message="Call of Duty VR setup did not complete: $($_.Exception.Message)"
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId $script:Cod1Id -InstallerFolder $PSScriptRoot -RecoveryPageUrl $script:Cod1Page)
    }}
}

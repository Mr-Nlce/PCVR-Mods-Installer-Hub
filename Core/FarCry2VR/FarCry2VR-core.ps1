$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')

$Host.UI.RawUI.WindowTitle='Far Cry 2 VR Installer'
$script:FC2Id='far-cry-2-vr'
$script:FC2Repo='Braxusx/FarCry2VR'
$script:FC2Page='https://github.com/Braxusx/FarCry2VR/releases'
$script:FC2Reviewed='https://github.com/Braxusx/FarCry2VR/releases/download/v1.0.2/FarCry2VR-Launcher_1.0.2.exe'
$script:FC2Identity='farcry2vr'
$script:FC2Files=@('dinput8.dll','fc2vr.ini','fc2vr_dlss_host64.exe','nvngx_dlss.dll','openxr_loader.dll')
$script:FC2Required=@('bin\FarCry2.exe','bin\dinput8.dll','bin\fc2vr_dlss\fc2vr_dlss_host64.exe|bin\fc2vr_dlss_host64.exe','bin\fc2vr_dlss\nvngx_dlss.dll|bin\nvngx_dlss.dll',
    'bin\openxr_loader.dll','FarCry2VR-Launcher.exe','.pcvrhub_farcry2vr_ownership.csv')
$script:FC2Contract=New-PCVRInstallerContract -Id $script:FC2Id -GameName 'Far Cry 2 VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $script:FC2Page -Routes @('Steam','GOG') -RequiredInstalledFileGroups $script:FC2Required

function Test-FC2Game([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'bin\FarCry2.exe') -PathType Leaf))
}
function Start-FC2FlatForDX10([string]$Game,[string]$Route) {
    Write-Host ''
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  REQUIRED BEFORE VR: SET DIRECTX 10 IN THE FLAT GAME' -ForegroundColor Yellow
    Write-Host '  Main Menu > Options > Display > DirectX version: 10.' -ForegroundColor Cyan
    Write-Host '  Save the setting, close Far Cry 2, then return here.' -ForegroundColor White
    if($Route -eq 'Steam'){Write-Host '  If Steam asks which edition to launch, choose DirectX 10.' -ForegroundColor White}
    Write-Host ('='*60) -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start Far Cry 2 normally and set DirectX 10...')
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if($env:PCVR_FC2_TEST_FLAT_CAPTURE){
            [pscustomobject]@{Route=$Route;Target=$(if($Route -eq 'Steam'){'steam://rungameid/19900'}else{Join-Path $Game 'bin\FarCry2.exe'})} |
                ConvertTo-Json -Compress | Set-Content -LiteralPath $env:PCVR_FC2_TEST_FLAT_CAPTURE -Encoding UTF8
        }
    }elseif($Route -eq 'Steam'){
        Start-Process -FilePath 'steam://rungameid/19900' -ErrorAction Stop | Out-Null
    }else{
        Start-Process -FilePath (Join-Path $Game 'bin\FarCry2.exe') -WorkingDirectory (Join-Path $Game 'bin') -ErrorAction Stop | Out-Null
    }
    do{
        [void](Wait-PCVRExplicitEnter -Message 'Close Far Cry 2 after saving DirectX 10, then press Enter to continue...')
        $running=($env:PCVR_HUB_TEST_MODE -ne '1' -and [bool](Get-Process -Name FarCry2 -ErrorAction SilentlyContinue))
        if($running){Write-Host '  Far Cry 2 is still running. Close it before the VR files are installed.' -ForegroundColor Yellow}
    }while($running)
}
function Get-FC2Game {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FC2_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_FC2_TEST_GAME)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path $root 'fc2-fixture.txt') -PathType Leaf) -or -not(Test-FC2Game $root)){
            throw 'Far Cry 2 test game must be an isolated complete fixture.'
        }
        $route=if($env:PCVR_FC2_TEST_ROUTE -eq 'GOG'){'GOG'}else{'Steam'}
        return [pscustomobject]@{Root=$root;Route=$route}
    }
    $paths=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:FC2Id -StateNames @('installed_path','user_located','base_game_path') -ProbeFiles @('bin\FarCry2.exe')
    if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '19900' -SteamFolderNames @('Far Cry 2') -ProbeExe 'bin\FarCry2.exe' -HubGameId $script:FC2Id;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Far Cry 2',
        'C:\Program Files (x86)\GOG Galaxy\Games\Far Cry 2','C:\GOG Games\Far Cry 2')
    foreach($path in @($paths|Where-Object{$_}|Select-Object -Unique)){
        if(-not(Test-FC2Game $path)){continue}
        $route=if($path -match '(?i)[\\/]steamapps[\\/]common[\\/]'){ 'Steam' }
            elseif($path -match '(?i)([\\/]GOG Galaxy[\\/]Games[\\/]|[\\/]GOG Games[\\/])'){'GOG'}else{''}
        if($route){return [pscustomobject]@{Root=[IO.Path]::GetFullPath($path);Route=$route}}
        if($saved -and [IO.Path]::GetFullPath($path).TrimEnd([char[]]'\/') -ieq [IO.Path]::GetFullPath($saved).TrimEnd([char[]]'\/')){
            Write-Host "  Saved Far Cry 2 folder: $path" -ForegroundColor Cyan
            $choice=(''+(Read-Host '  Confirm this saved copy is Steam or GOG (S/G, or Enter to choose again)')).Trim()
            $route=switch -Regex ($choice) { '^(?i)s$' {'Steam';break} '^(?i)g$' {'GOG';break} default {''} }
            if($route){return [pscustomobject]@{Root=[IO.Path]::GetFullPath($path);Route=$route}}
        }
    }
    Write-Host '  The publisher currently confirms Steam and GOG only.' -ForegroundColor Yellow
    Write-Host '  Ubisoft Connect and DVD builds must wait for publisher confirmation.' -ForegroundColor Yellow
    $picked=Get-GameFolderInteractive -GameName 'Far Cry 2 (Steam or GOG)' -ProbeFile 'bin\FarCry2.exe' -ManualUrl $script:FC2Page
    if(-not(Test-FC2Game $picked)){throw 'Choose a Steam or GOG Far Cry 2 folder containing bin\FarCry2.exe.'}
    $choice=(''+(Read-Host '  Confirm this is a Steam or GOG copy (S/G, or Enter to stop)')).Trim()
    $route=switch -Regex ($choice) { '^(?i)s$' {'Steam';break} '^(?i)g$' {'GOG';break} default {''} }
    if(-not $route){throw 'Only the publisher-confirmed Steam and GOG builds are supported. No game files were changed.'}
    [void](Save-HubRememberedGameFolder -GameId $script:FC2Id -Title 'Far Cry 2 VR' -GameDir $picked -ProbeFiles @('bin\FarCry2.exe') -UserSelected)
    return [pscustomobject]@{Root=[IO.Path]::GetFullPath($picked);Route=$route}
}
function Get-FC2ArchiveInfo([string]$Path) {
    try{
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try{
            $base=@($zip.Entries|Where-Object{$_.FullName.Replace('\','/') -match '^(?<root>.+/)manual_install/dinput8\.dll$'}|Select-Object -First 1)
            if($base.Count -ne 1){return $null}
            $root=[regex]::Match($base[0].FullName.Replace('\','/'),'^(.+/)manual_install/dinput8\.dll$').Groups[1].Value
            foreach($file in $script:FC2Files){
                $item=$zip.GetEntry($root+'manual_install/'+$file)
                if(-not $item -or $item.Length -le 0){return $null}
            }
            $launcher=@($zip.Entries|Where-Object{$_.FullName.Replace('\','/') -match ('^'+[regex]::Escape($root)+'FarCry2VR-Launcher(?:_[0-9.]+)?\.exe$') -and $_.Length -gt 0}|Select-Object -First 1)
            if($launcher.Count -ne 1){return $null}
            return [pscustomobject]@{Kind='Zip';Root=$root;Launcher=$launcher[0].FullName.Replace('\','/')}
        }finally{$zip.Dispose()}
    }catch{return $null}
}
function Get-FC2Archive([string]$Destination) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FC2_TEST_ARCHIVE){
        Copy-Item -LiteralPath $env:PCVR_FC2_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop
        $version=if($env:PCVR_FC2_TEST_VERSION){$env:PCVR_FC2_TEST_VERSION}else{'v1.0.0'}
        return [pscustomobject]@{Version=$version;Info=(Get-FC2PackageInfo $Destination)}
    }
    try{$release=Resolve-GitHubReleaseAsset -Repo $script:FC2Repo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^FarCry2VR-Launcher_[0-9]+(?:\.[0-9]+)+\.exe$','(?i)^FarCry2VR-[0-9]+(?:\.[0-9]+)+\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$release=$null}
    $url='';$version=''
    if($release -and $release.Resolved -and $release.Url -and (Test-IsTrackableInstalledVersion ([string]$release.Tag))){
        $url=[string]$release.Url;$version=[string]$release.Tag
    }else{
        Write-Host '  [!!] The current GitHub release could not be confirmed.' -ForegroundColor Yellow
        Write-Host '  The last reviewed publisher launcher is v1.0.2. A newer release may exist.' -ForegroundColor White
        if((Read-Host '  Download reviewed v1.0.2? Y/N').Trim() -notmatch '^(?i)y(?:es)?$'){
            throw 'Use recovery to open the official release page and hand over its current launcher or ZIP.'
        }
        $url=$script:FC2Reviewed;$version='v1.0.2'
    }
    [void](Invoke-SafeDownload -Urls @($url) -Destination $Destination -Label "Far Cry 2 VR $version" `
        -ManualUrl $script:FC2Page -AllowSkip:$false -Validator {param($p) [bool](Get-FC2PackageInfo $p)})
    return [pscustomobject]@{Version=$version;Info=(Get-FC2PackageInfo $Destination)}
}

function Get-FC2PackageInfo([string]$Path) {
    $zip=Get-FC2ArchiveInfo $Path
    if($zip){return $zip}
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return $null}
    $stream=[IO.File]::OpenRead($Path)
    try{if($stream.Length -ge 64 -and $stream.ReadByte() -eq 77 -and $stream.ReadByte() -eq 90){return [pscustomobject]@{Kind='EmbeddedExe'}}}
    finally{$stream.Dispose()}
    return $null
}

function Invoke-FC2UnpackTool([string]$Tool,[string]$Arguments,[string]$OutputFile='') {
    $psi=[Diagnostics.ProcessStartInfo]::new()
    $psi.FileName=$Tool;$psi.Arguments=$Arguments;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $process=[Diagnostics.Process]::new();$process.StartInfo=$psi;$output=$null
    try{
        if(-not $process.Start()){throw 'The package reader did not start.'}
        $errors=$process.StandardError.ReadToEndAsync()
        if($OutputFile){
            $output=[IO.File]::Create($OutputFile)
            $read=$process.StandardOutput.BaseStream.CopyToAsync($output)
        }else{$read=$process.StandardOutput.ReadToEndAsync()}
        $watch=[Diagnostics.Stopwatch]::StartNew()
        while(-not $process.WaitForExit(250)){
            Write-Progress -Activity 'Preparing Far Cry 2 VR runtime' -Status 'Reading the publisher package; please wait.'
            if($watch.Elapsed.TotalSeconds -gt 120){$process.Kill();throw 'The package reader timed out.'}
        }
        [void]$read.GetAwaiter().GetResult()
        $diagnostics=$errors.GetAwaiter().GetResult()
        # PowerShell 5.1 must not turn native stderr into a false failure.
        # Conversely, missing/nonzero exit codes can never mean success.
        if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "The package reader failed (exit $($process.ExitCode)). $diagnostics"}
        if($diagnostics){Write-Host $diagnostics.Trim() -ForegroundColor Gray}
    }finally{
        Write-Progress -Activity 'Preparing Far Cry 2 VR runtime' -Completed
        if($output){$output.Dispose()};$process.Dispose()
    }
}

function New-FC2EmbeddedStage([string]$Exe,[string]$Work) {
    # The publisher's launcher.rc and pack_payload.py define five LZMA-alone
    # RCDATA resources. Read them as data; never execute the launcher to stage
    # files (its installer writes preferences/logs to the real user profile).
    $seven=Get-SevenZip
    if(-not $seven){throw '7-Zip is needed to read the publisher launcher.'}
    $resources=Join-Path $Work 'embedded';[void][IO.Directory]::CreateDirectory($resources)
    $payload=Join-Path $Work 'payload';[void][IO.Directory]::CreateDirectory((Join-Path $payload 'bin\fc2vr_dlss'))
    Invoke-FC2UnpackTool -Tool $seven -Arguments ('e -y -bd -tPE -o"'+$resources+'" "'+$Exe+'" ".rsrc\RCDATA\101" ".rsrc\RCDATA\102" ".rsrc\RCDATA\103" ".rsrc\RCDATA\104" ".rsrc\RCDATA\105"')
    $map=@{101='bin\dinput8.dll';102='bin\openxr_loader.dll';103='bin\fc2vr_dlss\fc2vr_dlss_host64.exe';104='bin\fc2vr_dlss\nvngx_dlss.dll';105='bin\fc2vr.ini'}
    foreach($id in $map.Keys){
        $compressed=Join-Path $resources ([string]$id)
        if(-not(Test-Path -LiteralPath $compressed -PathType Leaf)){throw "Publisher launcher lacks required runtime resource $id."}
        $header=[IO.File]::ReadAllBytes($compressed)
        if($header.Length -lt 13 -or [BitConverter]::ToUInt64($header,5) -gt 512MB){throw "Invalid compressed runtime resource $id."}
        $dest=Join-Path $payload $map[$id]
        Invoke-FC2UnpackTool -Tool $seven -Arguments ('e -so -y -bd -tlzma "'+$compressed+'"') -OutputFile $dest
        if(-not(Test-Path -LiteralPath $dest -PathType Leaf) -or (Get-Item -LiteralPath $dest).Length -le 0){throw "Publisher runtime is missing $($map[$id])."}
    }
    Copy-Item -LiteralPath $Exe -Destination (Join-Path $payload 'FarCry2VR-Launcher.exe') -ErrorAction Stop
    return $payload
}
function Get-FC2ShortcutPath {
    $desktop=if($env:PCVR_FC2_TEST_DESKTOP){$env:PCVR_FC2_TEST_DESKTOP}else{[Environment]::GetFolderPath('DesktopDirectory')}
    return (Join-Path $desktop 'Far Cry 2 VR.lnk')
}
function Set-FC2Shortcut([string]$Game) {
    $link=Get-FC2ShortcutPath;$target=Join-Path $Game 'FarCry2VR-Launcher.exe'
    $shell=New-Object -ComObject WScript.Shell
    if(Test-Path -LiteralPath $link -PathType Leaf){
        $old=$shell.CreateShortcut($link)
        if([string]$old.TargetPath -ine $target){throw 'Far Cry 2 VR shortcut belongs to another target. Rename it, then retry.'}
        return $false
    }
    try{
        $shortcut=$shell.CreateShortcut($link)
        $shortcut.TargetPath=$target;$shortcut.WorkingDirectory=$Game;$shortcut.IconLocation=$target+',0'
        $shortcut.Description='Open the publisher Far Cry 2 VR launcher';$shortcut.Save()
        if(-not(Test-Path -LiteralPath $link -PathType Leaf)){throw 'The Far Cry 2 VR shortcut could not be created.'}
        [pscustomobject]@{Path=$link;Hash=(Get-FileHash -LiteralPath $link -Algorithm SHA256).Hash} |
            ConvertTo-Json -Compress | Set-Content -LiteralPath (Join-Path $Game '.pcvrhub_fc2_desktop_shortcut.json') -Encoding UTF8
    }catch{
        if(Test-Path -LiteralPath $link -PathType Leaf){Remove-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue}
        throw
    }
    return $true
}
function Invoke-FC2Installer {
    $game=$null;$work=$null;$snapshot=$null;$changed=$false;$shortcutMade=$false
    try{
        if($env:PCVR_HUB_TEST_MODE -ne '1'){Clear-Host}
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Far Cry 2 VR - Installer' -ForegroundColor Cyan
        Write-Host '  Braxus; Steam/GOG; OpenXR motion controls' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  REQUIRED: Far Cry 2 must run in DirectX 10 mode.' -ForegroundColor Yellow
        Write-Host '  In Steam choose DirectX 10 when starting; in GOG use the game video options.' -ForegroundColor White
        Write-Host '  Alternatively set Platform="d3d10a" in Documents\My Games\Far Cry 2\GamerProfile.xml.' -ForegroundColor White
        Write-Host '  DirectX 9 may show the game on the monitor but nothing in the headset.' -ForegroundColor Yellow
        Write-Host '  Keep the game closed during setup. Your saves and existing settings are preserved.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Far Cry 2...')
        $found=Get-FC2Game;$game=$found.Root
        Write-Host "  [OK] Game ($($found.Route)): $game" -ForegroundColor Green
        if(Get-Process -Name FarCry2,FarCry2VR -ErrorAction SilentlyContinue){throw 'Close Far Cry 2 before installing or updating VR.'}
        Start-FC2FlatForDX10 -Game $game -Route $found.Route
        if(-not(Test-InstallerTargetWritable $game)){throw 'The Far Cry 2 folder is not writable.'}
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Far Cry 2 VR release...')
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        # The publisher may supply either an embedded EXE or a ZIP. Let the
        # package validator determine its format before assigning an archive
        # extension; naming an EXE .zip makes the shared transport reject it.
        $archive=Join-Path $work 'FarCry2VR.payload'
        $release=Get-FC2Archive $archive
        if(-not $release.Info){throw 'The publisher package lacks the launcher or required VR files.'}
        if($release.Info.Kind -eq 'EmbeddedExe'){
            Write-Host '  Preparing the complete publisher runtime. This may take a few seconds.' -ForegroundColor Gray
            $payload=New-FC2EmbeddedStage -Exe $archive -Work $work
        }else{
        $zipPath=$archive+'.zip';Move-Item -LiteralPath $archive -Destination $zipPath -ErrorAction Stop;$archive=$zipPath
        $stage=Join-Path $work 'extracted'
        $safety=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $stage
        if(-not $safety.Inspectable -or -not $safety.Safe){throw 'The publisher ZIP is unreadable or contains an unsafe path.'}
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Far Cry 2 VR' -AllowSkip:$false) -ne 'ok'){
            throw 'The publisher ZIP could not be extracted.'
        }
        $package=Join-Path $stage ($release.Info.Root.Replace('/','\'))
        $payload=Join-Path $work 'payload';[void][IO.Directory]::CreateDirectory((Join-Path $payload 'bin'))
        foreach($file in $script:FC2Files){
            $source=Join-Path (Join-Path $package 'manual_install') $file
            if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw "Publisher ZIP lacks $file."}
            Copy-Item -LiteralPath $source -Destination (Join-Path $payload ('bin\'+$file)) -ErrorAction Stop
        }
        $publisherLauncher=Join-Path $stage ($release.Info.Launcher.Replace('/','\'))
        Copy-Item -LiteralPath $publisherLauncher -Destination (Join-Path $payload 'FarCry2VR-Launcher.exe') -ErrorAction Stop
        }
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $payload -Identity $script:FC2Identity -SnapshotRoot (Join-Path $work 'rollback') `
            -ExtraPaths @('.pcvrhub_fc2_desktop_shortcut.json')
        Write-Host '  The publisher files will go into the game bin folder.' -ForegroundColor White
        Write-Host '  An existing fc2vr.ini is kept. Same-name game files receive recoverable backups.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Far Cry 2 VR...')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $game -Identity $script:FC2Identity `
            -KeepExistingRelativePaths @('bin\fc2vr.ini') -AdoptIdenticalExisting -ProgressLabel 'Installing Far Cry 2 VR')
        $required=@(Get-ChildItem -LiteralPath $payload -Recurse -File|ForEach-Object{Join-Path $game $_.FullName.Substring($payload.Length+1)})
        $required+=Join-Path $game '.pcvrhub_farcry2vr_ownership.csv'
        if(-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)){
            throw 'Required Far Cry 2 VR files are missing after installation.'
        }
        $shortcutMade=Set-FC2Shortcut $game
        $receipt=if($env:PCVR_FC2_TEST_RECEIPT){$env:PCVR_FC2_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:FC2Contract -GameDir $game -Version $release.Version `
            -Route $found.Route -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host "  [OK] Far Cry 2 VR $($release.Version) installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub; the publisher launcher opens.' -ForegroundColor White
        Write-Host '  2. Or use the Far Cry 2 VR desktop shortcut, then press Play in the launcher.' -ForegroundColor White
        Write-Host '  Keep an OpenXR runtime active and confirm DirectX 10 before playing.' -ForegroundColor Yellow
        Write-Host '  If the launcher reports FarCryVR.exe missing, choose Reinstall/Repair once.' -ForegroundColor Yellow
        Write-Host '  The launcher Optional tab has additional VR features worth exploring.' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  The Jackal has not planned for you to arrive in person.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{
                if($shortcutMade){$link=Get-FC2ShortcutPath;if(Test-Path -LiteralPath $link -PathType Leaf){Remove-Item -LiteralPath $link -Force}}
                Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot
                Write-Host '  [!!] Previous Far Cry 2 files were restored.' -ForegroundColor Yellow
            }catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
        }
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_FC2_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-FC2Installer;break}catch{
        $message="Far Cry 2 VR setup did not complete: $($_.Exception.Message)"
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }}
}

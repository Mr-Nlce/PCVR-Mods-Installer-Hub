# Scoped installer support for Dead Space 2, Balatro, Blood West and Among the Sleep.
# Among the Sleep numeric update source:
# https://raw.githubusercontent.com/King-EJ/Among-the-Sleep-VR/main/README.md
# Blood West uses a fixed, nonnumeric release tag. The Hub's numeric online
# version source is https://raw.githubusercontent.com/King-EJ/Blood-West-VR/main/README.md
# while this installer records the actual delivered plugin version from its CFG.
. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')
$script:PublisherVRModules=$PSScriptRoot
function Get-PublisherVRProfile([string]$Key) {
    switch($Key) {
        # DS2DAT2 is German/Russian language data. DS2DAT6 is in the shared
        # content depot, also present with English and French installations.
        'DeadSpace2' { return @{Key=$Key;Id='dead-space-2-vr';Title='Dead Space 2 VR';Folder='Dead Space 2';Exe='deadspace2.exe';App='47780';Repo='chortdev/DeadSpace2VR';Identity='deadspace2vr';Base=@('deadspace2.exe','DS2DAT6.DAT');Required=@('d3d9.dll','openvr_api.dll','dxvk_d3d9.dll','ds2chest.bin','ds2reloadbuilder.bin','ds2hands.exe','ds2stereo.ini');Quip='Cut off their limbs. The rest is just paperwork.'} }
        'Balatro' { return @{Key=$Key;Id='balatro-vr';Title='Balatro VR';Folder='Balatro';Exe='Balatro.exe';App='2379780';Repo='alextreumer/BalatroVRMod';Identity='balatrovr';Base=@('Balatro.exe','love.dll');Required=@('winmm.dll');Quip='Surely the next Wheel of Fortune will hit.'} }
        'BloodWest' { return @{Key=$Key;Id='blood-west-vr';Title='Blood West VR';Folder='Blood West';Exe='Blood West.exe';App='1587130';Repo='King-EJ/Blood-West-VR';Identity='bloodwestvr';Base=@('Blood West.exe','UnityPlayer.dll','Blood West_Data\Managed\Assembly-CSharp.dll');Required=@('winhttp.dll','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll','BepInEx\plugins\BloodWestVR\BloodWestVR.dll','BepInEx\plugins\BloodWestVR\OpenXR.dll');Quip='Even death could not get you out of this shift.'} }
        'AmongSleep' { return @{Key=$Key;Id='among-the-sleep-vr';Title='Among the Sleep VR';Folder='Among the Sleep';Exe='Among the Sleep.exe';App='250620';Repo='King-EJ/Among-the-Sleep-VR';Identity='amongthesleepvr';Base=@('Among the Sleep.exe','Among the Sleep_Data\Managed\Assembly-CSharp.dll');Required=@('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll','BepInEx\plugins\ATSVR\ATSVR.dll','BepInEx\plugins\ATSVR\atsxr.dll','BepInEx\config\amongthesleep.vr.cfg');Quip='Teddy said he would keep you safe. He did not mention bedtime overtime.'} }
        default {throw 'Unknown publisher installer.'}
    }
}
function Get-PublisherVRTestContext {
    if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_PUBLISHER_VR_TEST){return $null}
    $path=[IO.Path]::GetFullPath($env:PCVR_PUBLISHER_VR_TEST)
    $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if(-not $path.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase)){throw 'Test input must be inside the isolated temporary fixture.'}
    $c=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $root=[IO.Path]::GetFullPath($c.Root).TrimEnd('\')+'\'
    if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_publisher_fixture'))){throw 'Missing publisher fixture sentinel.'}
    foreach($name in @('Game','Local','Roaming','Desktop','Receipt')) {
        if(-not ([IO.Path]::GetFullPath([string]$c.$name)).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Test path escaped the publisher fixture.'}
    }
    return $c
}
function Test-PublisherVRGame($Profile,[string]$Root) {
    if(-not $Root){return $false}
    foreach($name in $Profile.Base){if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)){return $false}}
    return $true
}
function Get-PublisherVRGame($Profile,$Test) {
    if($Test){if(-not(Test-PublisherVRGame $Profile $Test.Game)){throw 'The isolated base game is incomplete.'};return [string]$Test.Game}
    $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @('installed_path','user_located') -ProbeFiles $Profile.Base
    if(Test-PublisherVRGame $Profile $saved){return $saved}
    try{$steam=Find-SteamGameFolder -AppId $Profile.App -SteamFolderNames @($Profile.Folder) -ProbeExe $Profile.Exe -HubGameId $Profile.Id;if(Test-PublisherVRGame $Profile $steam){return $steam}}catch{}
    if($Profile.Key -eq 'DeadSpace2'){
        foreach($path in @('C:\Program Files\EA Games\Dead Space 2','C:\Program Files (x86)\Origin Games\Dead Space 2')){if(Test-PublisherVRGame $Profile $path){return $path}}
    }
    $picked=Get-GameFolderInteractive -GameName $Profile.Folder -ProbeFile $Profile.Exe
    if(-not(Test-PublisherVRGame $Profile $picked)){
        $missing=@($Profile.Base|Where-Object{-not $picked -or -not(Test-Path -LiteralPath (Join-Path $picked $_) -PathType Leaf -ErrorAction SilentlyContinue)})
        throw ("Required game files were not found: "+($missing -join ', ')+"`n  Checked folder: "+$picked+"`n  Choose the installed game folder containing "+$Profile.Exe+' and its game data.')
    }
    [void](Save-HubRememberedGameFolder -GameId $Profile.Id -Title $Profile.Title -GameDir $picked -ProbeFiles $Profile.Base -UserSelected)
    return $picked
}
function Get-PublisherVRRoute($Profile,[string]$Game,$Test) {
    if($Test){return [string]$Test.Route}
    if($Profile.Key -ne 'DeadSpace2'){return 'Steam'}
    if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
    if($Game -match '(?i)[\\/](EA Games|Origin Games)[\\/]'){return 'EA'}
    $saved=Join-Path $Game '.pcvrhub_deadspace2_store.txt'
    if(Test-Path -LiteralPath $saved){$route=[IO.File]::ReadAllText($saved).Trim();if($route -in @('Steam','EA')){return $route}}
    Write-Host '  Dead Space 2 has different Steam and EA app VR packages.' -ForegroundColor Yellow
    while($true){switch((Read-Host '  Your game store: 1 = Steam, 2 = EA app').Trim()){'1'{return 'Steam'}'2'{return 'EA'}}}
}
function Get-PublisherVRArchive([string]$Repo,[string[]]$Patterns,[string]$Label,[string]$Work,$Test,[string]$TestKey,[string]$FunctionalProbe='',[switch]$PlainProgress) {
    $dest=Join-Path $Work ($TestKey+'.zip');$page='https://github.com/'+$Repo+'/releases'
    $script:PublisherVRActiveReleasePage=$page
    if($Test){$a=$Test.Archives.$TestKey;if(-not $a){throw ('Missing isolated publisher input '+$TestKey)};Copy-Item -LiteralPath $a.Path -Destination $dest;return @{Path=$dest;Tag=[string]$a.Tag}}
    $handoff=Get-PCVRRecoveryInput -PathType Leaf
    if(-not $handoff -and $script:PublisherVRManualInputs -and $script:PublisherVRManualInputs.ContainsKey($Repo)){$handoff=$script:PublisherVRManualInputs[$Repo]}
    if($handoff -and [IO.Path]::GetExtension($handoff) -ieq '.zip'){
        # Match the component by functional contents, never a historical filename,
        # hash or byte size. A dependency ZIP must not replace the main mod ZIP.
        $components=@{'chortdev/DeadSpace2VR'='profile.json';'Wemino/MarkerPatch'='dinput8.dll';'ethangreen-dev/lovely-injector'='winmm.dll';'alextreumer/BalatroVRMod'='BalatroVRBridge.lua';'King-EJ/Blood-West-VR'='BloodWestVR.dll';'King-EJ/Among-the-Sleep-VR'='ATSVR.dll'}
        if($FunctionalProbe){$components[$Repo]=$FunctionalProbe}
        $probe=$components[$Repo]
        $matchesComponent=$false
        try{Add-Type -AssemblyName System.IO.Compression.FileSystem;$zip=[IO.Compression.ZipFile]::OpenRead($handoff);try{
            $matchesComponent=@($zip.Entries|Where-Object Name -eq $probe).Count -gt 0
            if(-not $matchesComponent){
                if(-not $script:PublisherVRManualInputs){$script:PublisherVRManualInputs=@{}}
                foreach($component in $components.Keys){if(@($zip.Entries|Where-Object Name -eq $components[$component]).Count){$script:PublisherVRManualInputs[$component]=$handoff}}
            }
        }finally{$zip.Dispose()}}catch{}
        [void](Set-PCVRRecoveryInput '')
        if($matchesComponent){
            Write-Host ('  Using the manually supplied '+$Label+' ZIP: '+$handoff) -ForegroundColor Cyan
            do{$tag=(Read-Host '  Version shown on its official release page').Trim()}until(Test-IsTrackableInstalledVersion $tag)
            Copy-Item -LiteralPath $handoff -Destination $dest
            if($script:PublisherVRManualInputs){$script:PublisherVRManualInputs.Remove($Repo)}
            return @{Path=$dest;Tag=$tag}
        }
    }
    Write-Host ('  Checking and downloading '+$Label+'; this may take a few seconds.') -ForegroundColor Cyan
    $r=Resolve-GitHubReleaseAsset -Repo $Repo -AssetPatterns $Patterns -SkipReleasesWithoutMatchingAsset
    if($r.Resolved -and $r.Url){
        [void](Invoke-SafeDownload -Urls @($r.Url) -Destination $dest -Label $Label -ManualUrl $page -AllowSkip $false -PlainProgress:$PlainProgress)
        return @{Path=$dest;Tag=[string]$r.Tag}
    }
    Write-Host ('  The current '+$Label+' could not be resolved. Download its official ZIP on the release page.') -ForegroundColor Yellow
    [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to open the official release page...')
    while($true){
        [void](Wait-PCVRExplicitEnter -Message 'After downloading the ZIP, press Enter to check Downloads...')
        $found=Find-PCVRDownloadedCandidate -Patterns @('*.zip')
        $chosen=''
        if($found){Write-Host ('  Found: '+$found) -ForegroundColor Cyan;if((Read-Host '  Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){$chosen=$found}}
        if(-not $chosen){$chosen=(Read-Host '  Drag/paste the ZIP path, or press Enter to reopen the release page').Trim().Trim('"').Trim("'")}
        if($chosen -and (Test-Path -LiteralPath $chosen -PathType Leaf)){
            $tag=(Read-Host '  Version shown on the official release page').Trim()
            if(Test-IsTrackableInstalledVersion $tag){Copy-Item -LiteralPath $chosen -Destination $dest;return @{Path=$dest;Tag=$tag}}
            Write-Host '  A publisher version is needed to track updates.' -ForegroundColor Yellow
        }
        [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to reopen the official release page...')
    }
}
function Expand-PublisherVRArchive($Archive,[string]$Destination) {
    $safe=Test-ZipArchiveEntrySafety -ArchivePath $Archive.Path -DestinationFolder $Destination
    if(-not $safe.Safe -or -not $safe.Inspectable){throw ('The ZIP cannot be safely extracted: '+$safe.Reason)}
    Write-Host '  Inspecting and extracting the publisher package; this may take a few seconds.' -ForegroundColor Cyan
    if((Expand-ArchiveOrFallback -ArchivePath $Archive.Path -DestinationFolder $Destination -Label 'Publisher package' -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The publisher ZIP could not be extracted.'}
    return $Destination
}
function Find-PublisherVRPayload([string]$Root,[string]$Required) {
    foreach($path in @($Root)+@(Get-ChildItem -LiteralPath $Root -Directory -Recurse|Select-Object -ExpandProperty FullName)){
        if(Test-Path -LiteralPath (Join-Path $path $Required) -PathType Leaf){return $path}
    }
    throw ('Publisher package is missing required file '+$Required)
}
function New-PublisherVRGroup([string]$Root,[string]$Stage,[string]$Identity,[string[]]$Required,[string[]]$Keep=@()) {
    return @{Root=$Root;Stage=$Stage;Identity=$Identity;Required=@($Required)+@(".pcvrhub_${Identity}_ownership.csv");Keep=$Keep;Snapshot=$null}
}
function Set-AmongSleepConfigUpdatePlan($Group,[string]$Version) {
    $configRoot=Join-Path $Group.Stage 'BepInEx\config'
    if(-not(Test-Path -LiteralPath $configRoot -PathType Container)){return}
    $manifest=Join-Path $Group.Root ('.pcvrhub_'+$Group.Identity+'_ownership.csv')
    $owned=@{}
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){$owned[[string]$row.RelativePath]=$row}}
    $Group.ReplaceChanged=@();$Group.SettingsBackups=@()
    foreach($file in @(Get-ChildItem -LiteralPath $configRoot -File -Recurse)){
        $relative=$file.FullName.Substring($Group.Stage.TrimEnd('\').Length+1)
        $target=Join-OwnedRelativePath $Group.Root $relative
        if(-not(Test-Path -LiteralPath $target -PathType Leaf)){continue}
        $currentHash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        $sourceHash=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        # Identical bytes need no decision, even with an older ownership hash.
        if($currentHash -eq $sourceHash){$Group.ReplaceChanged+=@($relative);continue}
        $prior=$owned[$relative]
        if($prior -and $prior.InstalledSha256 -eq $currentHash){continue}
        Write-Host ''
        Write-Host ('  Your settings differ: '+$relative) -ForegroundColor Yellow
        Write-Host ('  Y: use the settings included with VR mod '+$Version+'. Your current file is backed up first.')
        Write-Host '  N or Enter: keep your settings and continue the update.'
        do {
            $answer=([string](Read-Host '  Replace this settings file? Y/N (Enter = N)')).Trim()
            $valid=($answer -eq '' -or $answer -match '^(?i:y|yes|n|no)$')
            if(-not $valid){Write-Host '  Please choose Y or N, or press Enter to keep your settings.' -ForegroundColor Yellow}
        } while(-not $valid)
        if($answer -notmatch '^(?i:y|yes)$'){
            $Group.Keep=@($Group.Keep)+@($relative)
            Write-Host ('  [OK] Keeping '+$file.Name) -ForegroundColor Green
            continue
        }
        $backupRoot=Join-Path $Group.Root ('.pcvrhub_'+$Group.Identity+'_settings_backups\'+(Get-Date -Format 'yyyyMMdd-HHmmssfff')+'-'+[guid]::NewGuid().ToString('N'))
        $backup=Join-OwnedRelativePath $backupRoot $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $backup -Parent))
        Copy-Item -LiteralPath $target -Destination $backup -ErrorAction Stop
        if((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne $currentHash){throw ('The settings backup could not be verified: '+$relative)}
        $Group.SettingsBackups+=@($backup)
        $Group.ReplaceChanged+=@($relative)
        Write-Host ('  [OK] Settings backed up: '+$backup) -ForegroundColor Green
    }
}
function Set-PublisherVRMarkerSettings([string]$Ini) {
    $text=[IO.File]::ReadAllText($Ini)
    $newline=if($text.Contains("`r`n")){"`r`n"}else{"`n"}
    $lines=[Collections.Generic.List[string]]::new();foreach($line in ($text -split '\r?\n')){$lines.Add($line)}
    $off=@(@('Fixes','FixSuitChangeTiming'),@('Fixes','FixHazardSuitIcon'),@('Input','RawMouseInput'),@('Input','AutoHideMouseCursor'),@('Graphics','ImprovedAntiAliasingMode'),@('General','AchievementSupport'))
    foreach($pair in $off){
        $section=$pair[0];$key=$pair[1];$start=-1;$end=$lines.Count
        for($i=0;$i -lt $lines.Count;$i++){if($lines[$i] -match ('(?i)^\s*\['+[regex]::Escape($section)+'\]\s*(?:[;#].*)?$')){$start=$i;break}}
        if($start -lt 0){$lines.Add('');$lines.Add('['+$section+']');$lines.Add($key+' = 0');continue}
        for($i=$start+1;$i -lt $lines.Count;$i++){if($lines[$i] -match '^\s*\['){$end=$i;break}}
        $found=$false
        for($i=$start+1;$i -lt $end;$i++){if($lines[$i] -match ('(?i)^(\s*'+[regex]::Escape($key)+'\s*=)[^\r\n]*$')){$lines[$i]=$Matches[1]+' 0';$found=$true}}
        if(-not $found){$lines.Insert($start+1,$key+' = 0')}
    }
    $bytes=[IO.File]::ReadAllBytes($Ini);$bom=$bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
    [IO.File]::WriteAllText($Ini,($lines -join $newline),[Text.UTF8Encoding]::new($bom))
}
function global:Write-PublisherVRCheckpoint($Groups,[string]$Phase) {
    $missing=@()
    foreach($group in $Groups){foreach($file in $group.Required){$path=Join-Path $group.Root $file;$present=Test-Path -LiteralPath $path -PathType Leaf;Write-PCVRFileCheckResult -Path $path -Present $present -Phase $Phase -DisplayName $file;if(-not $present){$missing+=$path}}}
    return $missing
}
function global:Protect-PublisherVREditedIniOwnership($Group) {
    if(-not $Group.PreserveEditedIniHash){return}
    # Applying the six required VR settings must not turn the user's other
    # edits into disposable publisher content. Retain the earlier baseline so
    # the existing ownership uninstaller keeps that edited configuration.
    $manifest=Join-Path $Group.Root ('.pcvrhub_'+$Group.Identity+'_ownership.csv')
    $rows=@(Import-Csv -LiteralPath $manifest)
    foreach($row in $rows){if($row.RelativePath -eq 'MarkerPatch.ini'){$row.InstalledSha256=$Group.PreserveEditedIniHash}}
    $rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding UTF8
}
function Set-AmongSleepSteamOptions {
    $flags='-force-d3d11 -force-gfx-direct'
    Write-Host '  OPTIONAL: if VR stays flat, set these Steam Launch Options:' -ForegroundColor Yellow
    Write-Host ('  '+$flags) -ForegroundColor Cyan
    Write-Host '  Steam > Among the Sleep > Properties > General > Launch Options.' -ForegroundColor Yellow
    Write-Host '  Click the Launch Options field and press Ctrl+V. Keep any other options you need.'
    try { Set-Clipboard -Value $flags -DeferManualFallback } catch {}
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open Among the Sleep Steam Properties...')
    Start-Process 'steam://gameproperties/250620' -ErrorAction Stop
    Show-PCVRClipboardManualFallback -Text $flags
    [void](Wait-PCVRExplicitEnter -Message 'After setting the options, press Enter to return to setup...')
}
function Assert-AmongSleepArchitecture([string]$Exe) {
    $stream=[IO.File]::OpenRead($Exe);$reader=[IO.BinaryReader]::new($stream)
    try {
        if($stream.Length -lt 64 -or $reader.ReadUInt16() -ne 23117){throw 'The game EXE is not a readable Windows executable.'}
        $stream.Position=60;$pe=$reader.ReadInt32()
        if($pe -lt 64 -or $pe+6 -gt $stream.Length){throw 'The game EXE has an invalid PE header.'}
        $stream.Position=$pe
        if($reader.ReadUInt32() -ne 17744 -or $reader.ReadUInt16() -ne 332){throw 'Among the Sleep VR requires the 32-bit x86 game, not a 64-bit game build.'}
    } finally { $reader.Dispose();$stream.Dispose() }
}
function Invoke-PublisherVRSetup([string]$Key,[string]$InstallerFolder) {
    $ErrorActionPreference='Stop';$p=Get-PublisherVRProfile $Key;$test=Get-PublisherVRTestContext
    $work=$null;$groups=@();$changed=$false;$keepWork=$false;$shortcut='';$oldShortcut=$null;$shortcutChanged=$false
    $routes=if($Key -eq 'DeadSpace2'){@('Steam','EA')}else{@('Steam')}
    $contract=New-PCVRInstallerContract -Id $p.Id -GameName $p.Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$p.Repo+'/releases') -Routes $routes -RequiredInstalledFileGroups (@($p.Base)+@($p.Required)+@(".pcvrhub_$($p.Identity)_ownership.csv"))
    try {
        if(-not $test){Clear-Host};$Host.UI.RawUI.WindowTitle=$p.Title+' Installer'
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ('  '+$p.Title+' - Installer') -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Magenta
        if($Key -eq 'DeadSpace2'){Write-Host '  Steam or EA app. Start SteamVR before the game. Windows 11 also needs MarkerPatch.' -ForegroundColor Yellow;Write-Host '  WIP: CPU-limited frame rates can remain around 40-50 FPS even on strong PCs.' -ForegroundColor Yellow}
        elseif($Key -eq 'AmongSleep'){Write-Host '  Unity 5.6 Mono 32-bit game; included BepInEx x86; active 32-bit OpenXR runtime.' -ForegroundColor White;Write-Host '  Recenter at the main menu. Third-person view can reveal missing walls.' -ForegroundColor Yellow}
        elseif($Key -eq 'Balatro'){Write-Host '  Steam Windows game. Setup installs Lovely, Steamodded, the bridge and the separate VR client.' -ForegroundColor White;Write-Host '  Existing saves, other mods, layout and achievements are preserved.' -ForegroundColor White}
        else{Write-Host '  Mono x64 game, bundled BepInEx 5, and an active OpenXR runtime.' -ForegroundColor White;Write-Host '  WIP: menus use controller buttons, not a pointing laser.' -ForegroundColor Yellow}
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message ('After reading this, press Enter to locate '+$p.Folder+'...'))
        $game=Get-PublisherVRGame $p $test;$route=Get-PublisherVRRoute $p $game $test
        Write-Host ('  [OK] Game ('+$route+'): '+$game) -ForegroundColor Green
        if(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($p.Exe)) -ErrorAction SilentlyContinue){throw 'Close the game before installing or updating VR.'}
        if($Key -eq 'AmongSleep' -and -not $test){Assert-AmongSleepArchitecture (Join-Path $game $p.Exe)}
        if($Key -eq 'Balatro' -and (Get-Process -Name 'Balatro in VR' -ErrorAction SilentlyContinue)){throw 'Close Balatro in VR before installing or updating.'}
        if($Key -eq 'DeadSpace2' -and (Get-Process -Name 'vrserver' -ErrorAction SilentlyContinue)){throw 'Close SteamVR before installing Dead Space 2 VR, as requested by the publisher. Start it again before playing.'}
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        [void](Wait-PCVRExplicitEnter -Message ('Press Enter to check and download the current '+$p.Title+' package...'))
        $pattern=switch($Key){'DeadSpace2'{'(?i)^DS2PCVR-.+-'+$route.ToLowerInvariant()+'\.zip$'}'Balatro'{'(?i)^Balatro[- ]in[- ]VR.+\.zip$'}'BloodWest'{'(?i)^BloodWestVR\.zip$'}'AmongSleep'{'(?i)^AmongtheSleepVR.*\.zip$'}}
        $a=Get-PublisherVRArchive $p.Repo @($pattern) $p.Title $work $test 'Main'
        $expanded=Expand-PublisherVRArchive $a (Join-Path $work 'main');$version=$a.Tag
        if($Key -eq 'DeadSpace2'){
            $stage=Find-PublisherVRPayload $expanded 'd3d9.dll'
            $packageProfile=Get-Content -LiteralPath (Join-Path $stage 'profile.json') -Raw | ConvertFrom-Json
            if([string]$packageProfile.profile -ne $route.ToLowerInvariant()){throw 'The publisher package belongs to another store. Choose the matching Steam or EA ZIP; no game files were changed.'}
            [IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_deadspace2_store.txt'),$route)
            $groups+=New-PublisherVRGroup $game $stage $p.Identity (@($p.Required)+@('.pcvrhub_deadspace2_store.txt')) @('ds2stereo.ini','ds2calibration.ini','ds2twohand.ini','ds2scene.ini','ds2inertia.ini','ds2vr-settings.ini','ds2vr-controllers.ini','dxvk.conf')
            $windows11=if($test){[bool]$test.Windows11}else{[Environment]::OSVersion.Version.Build -ge 22000}
            $needsMarker=$windows11 -or (Test-Path -LiteralPath (Join-Path $game 'MarkerPatch.ini'))
            [IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_deadspace2_marker_required.txt'),$(if($needsMarker){'1'}else{'0'}))
            $groups[0].Required+=@('.pcvrhub_deadspace2_marker_required.txt')
            if($needsMarker){
                Write-Host '  MarkerPatch will be installed with the six VR compatibility options disabled; other existing options are kept.' -ForegroundColor Yellow
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download and configure MarkerPatch for VR...')
                $mp=Get-PublisherVRArchive 'Wemino/MarkerPatch' @('(?i)^MarkerPatch\.zip$') 'MarkerPatch' $work $test 'Marker'
                $mpStage=Find-PublisherVRPayload (Expand-PublisherVRArchive $mp (Join-Path $work 'marker')) 'dinput8.dll'
                $oldIni=Join-Path $game 'MarkerPatch.ini';if(Test-Path -LiteralPath $oldIni){Copy-Item -LiteralPath $oldIni -Destination (Join-Path $mpStage 'MarkerPatch.ini') -Force}
                Set-PublisherVRMarkerSettings (Join-Path $mpStage 'MarkerPatch.ini')
                $markerGroup=New-PublisherVRGroup $game $mpStage 'deadspace2marker' @('dinput8.dll','MarkerPatch.ini')
                $priorManifest=Join-Path $game '.pcvrhub_deadspace2marker_ownership.csv'
                if((Test-Path -LiteralPath $priorManifest -PathType Leaf) -and (Test-Path -LiteralPath $oldIni -PathType Leaf)){
                    $priorIni=@(Import-Csv -LiteralPath $priorManifest|Where-Object RelativePath -eq 'MarkerPatch.ini')|Select-Object -First 1
                    if($priorIni -and (Get-FileHash -LiteralPath $oldIni).Hash -ne $priorIni.InstalledSha256){$markerGroup.PreserveEditedIniHash=[string]$priorIni.InstalledSha256}
                }
                $groups+=$markerGroup
            }
        }elseif($Key -eq 'AmongSleep'){
            $stage=Find-PublisherVRPayload $expanded 'winhttp.dll'
            $cfg=[IO.File]::ReadAllText((Join-Path $stage 'BepInEx\config\amongthesleep.vr.cfg'))
            if($cfg -notmatch '(?im)^## Settings file was created by plugin Among the Sleep VR v(\d+(?:\.\d+)+)'){throw 'The publisher package does not identify its plugin version.'};$version='v'+$Matches[1]
            if(Test-Path -LiteralPath (Join-Path $game 'GameAssembly.dll')){throw 'This mod needs the 32-bit Mono game; IL2CPP is not supported.'}
            $groups+=New-PublisherVRGroup $game $stage $p.Identity $p.Required @('doorstop_config.ini')
        }elseif($Key -eq 'BloodWest'){
            $stage=Find-PublisherVRPayload $expanded 'winhttp.dll'
            $cfg=[IO.File]::ReadAllText((Join-Path $stage 'BepInEx\config\bloodwest.vr.cfg'))
            if($cfg -notmatch '(?im)^## Settings file was created by plugin Blood West VR v(\d+(?:\.\d+)+)'){throw 'The publisher package does not identify its plugin version.'};$version='v'+$Matches[1]
            $keep=@(Get-ChildItem -LiteralPath (Join-Path $stage 'BepInEx\config') -File -Recurse|ForEach-Object{$_.FullName.Substring($stage.Length+1)})
            if(Test-Path -LiteralPath (Join-Path $game 'BepInEx\core\BepInEx.Unity.IL2CPP.dll')){throw 'This Mono game needs BepInEx 5 x64. Resolve the existing IL2CPP loader before retrying.'}
            $loaderStage=Join-Path $work 'bloodwest-loader';Copy-Item -LiteralPath $stage -Destination $loaderStage -Recurse
            $pluginStage=Join-Path $work 'bloodwest-plugin';[void][IO.Directory]::CreateDirectory((Join-Path $pluginStage 'BepInEx\plugins'));[void][IO.Directory]::CreateDirectory((Join-Path $pluginStage 'BepInEx\config'))
            Copy-Item -LiteralPath (Join-Path $stage 'BepInEx\plugins\BloodWestVR') -Destination (Join-Path $pluginStage 'BepInEx\plugins') -Recurse
            Copy-Item -LiteralPath (Join-Path $stage 'BepInEx\config\bloodwest.vr.cfg') -Destination (Join-Path $pluginStage 'BepInEx\config')
            $removePlugin=[IO.Path]::GetFullPath((Join-Path $loaderStage 'BepInEx\plugins\BloodWestVR'))
            if(-not $removePlugin.StartsWith([IO.Path]::GetFullPath($work)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Staging path escaped installer temp.'}
            Remove-Item -LiteralPath $removePlugin -Recurse -Force;Remove-Item -LiteralPath (Join-Path $loaderStage 'BepInEx\config\bloodwest.vr.cfg')
            $groups+=New-PublisherVRGroup $game $loaderStage 'bloodwestloader' @('winhttp.dll','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll') @('BepInEx\config\BepInEx.cfg','doorstop_config.ini')
            $groups+=New-PublisherVRGroup $game $pluginStage $p.Identity @('BepInEx\plugins\BloodWestVR\BloodWestVR.dll','BepInEx\plugins\BloodWestVR\OpenXR.dll','BepInEx\config\bloodwest.vr.cfg') @('BepInEx\config\bloodwest.vr.cfg')
        }else{
            if(Test-Path -LiteralPath (Join-Path $game 'version.dll')){throw 'A version.dll loader is already installed. Lovely now uses winmm.dll. Resolve the older loader before retrying; no existing loader was removed.'}
            $local=if($test){$test.Local}else{$env:LOCALAPPDATA};$roaming=if($test){$test.Roaming}else{$env:APPDATA}
            if(-not $local -or -not $roaming){throw 'The Windows AppData folders could not be resolved.'}
            $client=Join-Path $local 'PCVR Mods Installer Hub\BalatroVR';$mods=Join-Path $roaming 'Balatro\Mods'
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download Lovely and the publisher-documented Steamodded library...')
            $lovely=Get-PublisherVRArchive 'ethangreen-dev/lovely-injector' @('(?i)^lovely-x86_64-pc-windows-msvc\.zip$') 'Lovely x64' $work $test 'Lovely'
            $lovelyStage=Find-PublisherVRPayload (Expand-PublisherVRArchive $lovely (Join-Path $work 'lovely')) 'winmm.dll'
            $smodsZip=Join-Path $work 'smods.zip'
            if($test){Copy-Item -LiteralPath $test.Archives.Smods.Path -Destination $smodsZip}else{[void](Invoke-SafeDownload -Urls @('https://github.com/Steamodded/smods/archive/refs/tags/26.1002.0.zip') -Destination $smodsZip -Label 'Steamodded 26.1002.0' -ManualUrl 'https://github.com/Steamodded/smods/releases/tag/26.1002.0' -AllowSkip $false)}
            $sm=Expand-PublisherVRArchive @{Path=$smodsZip} (Join-Path $work 'smods');$smSource=Find-PublisherVRPayload $sm 'version.lua'
            $smStage=Join-Path $work 'smods-stage';[void][IO.Directory]::CreateDirectory($smStage)
            $existing=@(Get-ChildItem -LiteralPath $mods -Directory -ErrorAction SilentlyContinue|Where-Object{(Test-Path -LiteralPath (Join-Path $_.FullName 'version.lua')) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'src\core.lua'))})
            if($existing.Count -gt 1){throw 'Multiple Steamodded folders were found. Keep one working library before retrying; no mod folder was removed.'}
            if($existing.Count -eq 0){Copy-Item -LiteralPath $smSource -Destination (Join-Path $smStage 'Steamodded') -Recurse; $groups+=New-PublisherVRGroup $mods $smStage 'balatrosmods' @('Steamodded\version.lua','Steamodded\src\core.lua')}
            else{
                $installedSmods=[IO.File]::ReadAllText((Join-Path $existing[0].FullName 'version.lua'))
                if($installedSmods -notmatch '(\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]'26.1002.0'){throw 'Existing Steamodded is older than 26.1002.0 or its version cannot be read. Update that library before retrying; your other mods were not changed.'}
                Write-Host ('  [OK] Keeping existing Steamodded: '+$existing[0].FullName) -ForegroundColor Green
            }
            $bridgeStage=Join-Path $expanded 'Mod';$clientStage=Join-Path $expanded 'Balatro in VR'
            if(-not(Test-Path -LiteralPath (Join-Path $bridgeStage 'BalatroVRBridge\BalatroVRBridge.lua'))){throw 'Publisher ZIP has no BalatroVRBridge mod.'}
            Copy-Item -LiteralPath (Join-Path $InstallerFolder 'Start-BalatroVR.ps1') -Destination $clientStage
            [IO.File]::WriteAllText((Join-Path $clientStage '.pcvrhub_balatro_game.txt'),$game)
            $groups+=New-PublisherVRGroup $game $lovelyStage $p.Identity @('winmm.dll')
            $groups+=New-PublisherVRGroup $mods $bridgeStage 'balatrobridge' @('BalatroVRBridge\BalatroVRBridge.lua')
            $groups+=New-PublisherVRGroup $client $clientStage 'balatroclient' @('Balatro in VR.exe','Balatro in VR.pck','Start-BalatroVR.ps1','.pcvrhub_balatro_game.txt')
        }
        if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The selected package has no trackable version; no game files were changed.'}
        foreach($g in $groups){foreach($name in $g.Required|Where-Object{$_ -notlike '.pcvrhub_*_ownership.csv'}){if(-not(Test-Path -LiteralPath (Join-Path $g.Stage $name))){throw ('Required publisher file is missing: '+$name)}};if(-not(Test-InstallerTargetWritable -TargetPath $g.Root)){throw ('The destination is not writable: '+$g.Root)}}
        if($Key -eq 'AmongSleep'){foreach($g in $groups){Set-AmongSleepConfigUpdatePlan $g $version}}
        $installPrompt=if($Key -eq 'AmongSleep'){'Press Enter to install the VR files using your settings choices...'}else{'Press Enter to install the VR files and preserve existing settings...'}
        [void](Wait-PCVRExplicitEnter -Message $installPrompt)
        Write-Host '  Preparing your file backup; this may take a few seconds.' -ForegroundColor Cyan
        foreach($g in $groups){$g.Snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $g.Root -Stage $g.Stage -Identity $g.Identity -SnapshotRoot (Join-Path $work ('rollback-'+$g.Identity))}
        $changed=$true
        foreach($g in $groups){
            $merge=@($g.ReplaceChanged)+@(if($g.Identity -eq 'deadspace2marker'){'MarkerPatch.ini'})
            [void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $g.Root -Identity $g.Identity -KeepExistingRelativePaths $g.Keep -ReplaceChangedOwnedRelativePaths $merge -ProgressLabel ('Installing '+$p.Title))
            Protect-PublisherVREditedIniOwnership $g
        }
        if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game $p.Required[0]) -Force}
        if(@(Write-PublisherVRCheckpoint $groups 'immediately-after-copy').Count){throw 'Required files were not copied. Check the destination, permissions and installer log; no antivirus cause has been established.'}
        if($test.Failure -eq 'vanish'){Remove-Item -LiteralPath (Join-Path $game $p.Required[0]) -Force}
        Write-Host '  Checking that the copied runtime remains available; this takes a few seconds.' -ForegroundColor Cyan;Start-Sleep -Seconds 3
        $missing=@(Write-PublisherVRCheckpoint $groups 'after-observation')
        if($missing.Count){
            $retry={ [void](Write-PublisherVRCheckpoint $groups 'before-retry');foreach($g in $groups){$merge=@($g.ReplaceChanged)+@(if($g.Identity -eq 'deadspace2marker'){'MarkerPatch.ini'});[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $g.Root -Identity $g.Identity -KeepExistingRelativePaths $g.Keep -ReplaceChangedOwnedRelativePaths $merge);Protect-PublisherVREditedIniOwnership $g};[void](Write-PublisherVRCheckpoint $groups 'after-retry') }.GetNewClosure()
            $inputReader=if($test){
                $recoveryReads=@{Count=0};$recoverWithRetry=$test.Recover -eq 'R'
                { $recoveryReads.Count++;if($recoverWithRetry -and $recoveryReads.Count -eq 1){'R'}else{'Q'} }.GetNewClosure()
            }else{$null}
            if(-not(Confirm-PlacedFilesSurvive -Paths @($groups|ForEach-Object{$g=$_;$g.Required|ForEach-Object{Join-Path $g.Root $_}}) -GameDir $game -WaitSeconds 0 -Recopy $retry -ReadInput $inputReader -NoClear)){throw 'Required files disappeared after copying. The earlier installation will be restored.'}
        }
        if($Key -eq 'Balatro'){
            $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$shortcut=Join-Path $desktop 'Balatro VR.lnk';[void][IO.Directory]::CreateDirectory($desktop)
            $ws=New-Object -ComObject WScript.Shell
            if(Test-Path -LiteralPath $shortcut){$link=$ws.CreateShortcut($shortcut);if($link.TargetPath -ne (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -or $link.Arguments -notlike ('*'+(Join-Path $client 'Start-BalatroVR.ps1')+'*')){throw 'A different Balatro VR desktop shortcut already exists. Rename it before retrying; it was not overwritten.'};$oldShortcut=[IO.File]::ReadAllBytes($shortcut)}
            $link=$ws.CreateShortcut($shortcut);$link.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe';$link.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+(Join-Path $client 'Start-BalatroVR.ps1')+'"';$link.WorkingDirectory=$client;$link.IconLocation=(Join-Path $game 'Balatro.exe')+',0';$link.Save();$shortcutChanged=$true
        }
        if(@(Write-PublisherVRCheckpoint $groups 'before-commit').Count){throw 'The complete multi-folder installation could not be confirmed.'}
        if($test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
        $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -InstalledPathReceiptPaths @($receipt) -Route $route)
        $changed=$false;$shortcutChanged=$false
        Write-Host ('  [OK] '+$p.Title+' '+$version+' is installed.') -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
        if($Key -eq 'DeadSpace2'){Write-Host ('  Start SteamVR first. Alternative: start Dead Space 2 through '+$route+'.') -ForegroundColor White;Write-Host '  In game: Settings > VR Settings. Keep your VR resolution reasonable; this mod is still CPU-limited.' -ForegroundColor Yellow}
        elseif($Key -eq 'Balatro'){Write-Host '  The Hub starts the VR client and Balatro through Steam. Alternative: use the Balatro VR desktop shortcut.' -ForegroundColor White;Write-Host '  If the client says Waiting for Balatro, open Mods in Balatro and enable Balatro in VR.' -ForegroundColor Yellow;Write-Host '  Low FPS: VR Menu > Performance Mode, or Background > Black.' -ForegroundColor White}
        elseif($Key -eq 'AmongSleep'){Write-Host '  Start your OpenXR runtime first. Alternative: launch Among the Sleep through Steam.' -ForegroundColor White;Write-Host '  At the main menu, hold right stick click to recenter at toddler height.' -ForegroundColor Cyan;Write-Host '  Hold Y + left stick click for VR settings. If VR stays flat, see the guided D3D11 launch-option step in Help.' -ForegroundColor Yellow}
        else{Write-Host '  Start your OpenXR runtime first. Alternative: launch Blood West through Steam.' -ForegroundColor White;Write-Host '  Hold both stick clicks for 1.2 seconds to open VR settings. Menus use controller buttons.' -ForegroundColor Cyan}
        if($Key -eq 'AmongSleep'){
            Write-Host ''
            Write-Host '  OPTIONAL: HELP IF THE GAME STARTS WITHOUT VR' -ForegroundColor Cyan
            Write-Host '  These Steam options force DirectX 11, the graphics mode used by this VR mod.' -ForegroundColor White
            Write-Host '  They also use single-threaded rendering as a compatibility workaround; performance may change.' -ForegroundColor White
            Write-Host '  The modder did not need them on his own PC. Try the game first; choose N if you are unsure.' -ForegroundColor White
            Write-Host '  If the game stays flat, choose Y to open the guided Steam step.' -ForegroundColor Yellow
            Write-Host '  The options and instructions are also listed under Help on the Hub game page.' -ForegroundColor White
            if((Read-Host '  Open the DirectX 11 setup guide now? Y/N (recommended first try: N)').Trim() -match '^(?i:y|yes)$'){Set-AmongSleepSteamOptions}
        }
        Write-Host '';Write-Host ('  '+$p.Quip) -ForegroundColor Magenta;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $failure=$_
        if($changed){
            [void](Write-PublisherVRCheckpoint $groups 'before-rollback')
            try{for($i=$groups.Count-1;$i -ge 0;$i--){Restore-PCVRPublisherZipSnapshot -GameRoot $groups[$i].Root -Snapshot $groups[$i].Snapshot};[void](Write-PublisherVRCheckpoint $groups 'after-rollback');Write-Host '  Previous files were restored.' -ForegroundColor Yellow}catch{$keepWork=$true;Write-Host ('  Rollback requires review. Recovery copy: '+$work) -ForegroundColor Red}
        }
        if($shortcutChanged){if($oldShortcut){[IO.File]::WriteAllBytes($shortcut,$oldShortcut)}elseif(Test-Path -LiteralPath $shortcut){Remove-Item -LiteralPath $shortcut -Force}}
        Write-Host ('  Setup did not complete: '+$failure.Exception.Message) -ForegroundColor Red;throw $failure
    }finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-PublisherVRUninstall([string]$Key,[string]$InstallerFolder,[switch]$HubConfirmed) {
    $ErrorActionPreference='Stop';$p=Get-PublisherVRProfile $Key;$test=Get-PublisherVRTestContext
    $game=Get-PublisherVRGame $p $test
    foreach($process in @([IO.Path]::GetFileNameWithoutExtension($p.Exe),$(if($Key -eq 'Balatro'){'Balatro in VR'}))|Where-Object {$_}){if(Get-Process -Name $process -ErrorAction SilentlyContinue){throw 'Close the game and its VR client before removal.'}}
    if(-not $HubConfirmed -and (Read-Host ('Remove '+$p.Title+'? Type REMOVE')) -cne 'REMOVE'){return}
    if($Key -eq 'Balatro'){
        $local=if($test){$test.Local}else{$env:LOCALAPPDATA};$roaming=if($test){$test.Roaming}else{$env:APPDATA};$desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')}
        $client=Join-Path $local 'PCVR Mods Installer Hub\BalatroVR';$mods=Join-Path $roaming 'Balatro\Mods'
        $linkPath=Join-Path $desktop 'Balatro VR.lnk'
        if(Test-Path -LiteralPath $linkPath){$ws=New-Object -ComObject WScript.Shell;$lnk=$ws.CreateShortcut($linkPath);if($lnk.TargetPath -eq (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -and $lnk.Arguments -like ('*'+(Join-Path $client 'Start-BalatroVR.ps1')+'*')){Remove-Item -LiteralPath $linkPath -Force}}
        [void](Uninstall-OwnedModPayload -GameRoot $mods -Identity 'balatrobridge')
        [void](Uninstall-OwnedModPayload -GameRoot $client -Identity 'balatroclient')
        $otherMods=@(Get-ChildItem -LiteralPath $mods -Directory -ErrorAction SilentlyContinue|Where-Object{$_.Name -notin @('Steamodded','BalatroVRBridge','lovely')})
        if(-not $otherMods.Count){[void](Uninstall-OwnedModPayload -GameRoot $mods -Identity 'balatrosmods');[void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.Identity)}
        else{Write-Host '  Lovely and Steamodded were kept for other installed mods.' -ForegroundColor Yellow}
    }else{
        [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.Identity)
        if($Key -eq 'DeadSpace2'){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'deadspace2marker')}
        if($Key -eq 'BloodWest'){
            $otherPlugins=@(Get-ChildItem -LiteralPath (Join-Path $game 'BepInEx\plugins') -Filter '*.dll' -Recurse -File -ErrorAction SilentlyContinue|Where-Object{$_.FullName -notmatch '[\\/]BloodWestVR[\\/]'})
            if(-not $otherPlugins.Count){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'bloodwestloader')}else{Write-Host '  BepInEx was kept for other installed plugins.' -ForegroundColor Yellow}
        }
    }
    foreach($file in @((Join-Path $game '.pcvrhub_version'),$(if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}))){if(Test-Path -LiteralPath $file){Remove-Item -LiteralPath $file -Force}}
    Write-Host '  [OK] Hub-owned VR files removed; earlier files restored where unchanged.' -ForegroundColor Green
    Write-Host '  Saves, changed settings, other mods and unrelated files remain.' -ForegroundColor White
}

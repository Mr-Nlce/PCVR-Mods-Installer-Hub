# Independent current and frozen game roots; downloaded identities are never gates.
. (Join-Path $PSScriptRoot 'CyberpunkCompatibility.ps1')
. (Join-Path $PSScriptRoot 'CyberpunkStartupCompatibility.ps1')

function Get-CyberpunkPortPreservedSettings {
    param([Parameter(Mandatory=$true)][string]$SourceRoot)
    # These are saved by the VR launcher/game, not immutable program files.
    # Keep exact configuration paths; Lua, DLLs and engine tweaks still update.
    @('bin\x64\vrport.ini',
      'bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_Stereo\vrcam.json',
      'bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_WristHud\wrist.cfg',
      'red4ext\plugins\CyberpunkVR_Stereo\UserSettings.json')
    $bin=Join-Path $SourceRoot 'bin\x64'
    if(Test-Path -LiteralPath $bin -PathType Container){
        Get-ChildItem -LiteralPath $bin -Filter 'CyberpunkVR_*Grip*.ini' -File |
            ForEach-Object {'bin\x64\'+$_.Name}
    }
}

function Get-CyberpunkModSettingsProfile {
    return @{Name='Mod Settings';Version='0.2.27';GameVersion='2.5';Repo='jackhumbert/mod_settings';Tag='v0.2.27';File='mod_settings_v0.2.27.zip';Marker='red4ext\plugins\mod_settings\mod_settings.dll';Identity='cyberpunk25_modsettings';Pinned='https://github.com/jackhumbert/mod_settings/releases/download/v0.2.27/mod_settings_v0.2.27.zip';Page='https://github.com/jackhumbert/mod_settings/releases/tag/v0.2.27';AssetPattern='(?i)^mod_settings[_-]v?\d[\d.]*\.zip$';RequiredFiles=@('red4ext\plugins\mod_settings\mod_settings.dll','red4ext\plugins\mod_settings\module.reds','red4ext\plugins\mod_settings\packed.reds','red4ext\plugins\mod_settings\ModSettings.archive','red4ext\plugins\mod_settings\ModSettings.archive.xl')}
}

function Resolve-CyberpunkModSettingsProfile {
    $c=Get-CyberpunkModSettingsProfile
    # The same release also publishes *_pdb.zip. It is a symbol package,
    # not a second installable runtime.
     $runtimePattern=$c.AssetPattern
    $release=Resolve-GitHubReleaseAsset -Repo $c.Repo -AssetPatterns @($runtimePattern) -IncludePrerelease $false
    if(-not $release.Resolved){throw 'The current Mod Settings download could not be checked on GitHub. Retry or use its official release ZIP.'}
    $v=([regex]::Match([string]$release.Tag,'\d+\.\d+\.\d+')).Value
    if(-not $v -or [version]$v -lt [version]$c.Version){throw 'The resolved Mod Settings release is too old for this Current setup.'}
    $c.Version=$v;$c.Tag=[string]$release.Tag;$c.File=[string]$release.AssetName;$c.Pinned=[string]$release.Url;$c.Page=[string]$release.PageUrl
    return $c
}

function Get-CyberpunkModSettingsWithRecovery {
    while($true){
        try{return Resolve-CyberpunkModSettingsProfile}catch{
            Write-Host ('  Mod Settings: '+$_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  [R] Check again  [K] Download the known compatible 0.2.27 release' -ForegroundColor White
            Write-Host '  [O] Open the official Mod Settings releases' -ForegroundColor Cyan
            $choice=(''+(Read-Host '  Choose R, K or O')).Trim().ToUpperInvariant()
            if($choice -eq 'K'){return Get-CyberpunkModSettingsProfile}
            if($choice -eq 'O'){[void](Open-PCVRPageAfterEnter -Url 'https://github.com/jackhumbert/mod_settings/releases' -Message 'Press Enter to open Mod Settings releases...')}
            if(-not $choice -and [Console]::IsInputRedirected){throw [IO.EndOfStreamException]::new('Mod Settings needs an interactive recovery choice. Nothing was marked complete.')}
        }
    }
}

function Get-CyberpunkInputLoaderProfile([string]$GameVersion){
    $v=if($GameVersion -eq '2.31'){'0.2.3'}else{'0.2.6'}
    $identity=if($GameVersion -eq '2.31'){'cyberpunk231_inputloader'}else{'cyberpunk25_inputloader'}
    return @{Name='Input Loader';Version=$v;GameVersion=$GameVersion;Repo='jackhumbert/cyberpunk2077-input-loader';Tag=('v'+$v);File=('input_loader_v'+$v+'.zip');Marker='red4ext\plugins\input_loader\input_loader.dll';Identity=$identity;Pinned=('https://github.com/jackhumbert/cyberpunk2077-input-loader/releases/download/v'+$v+'/input_loader_v'+$v+'.zip');Page=('https://github.com/jackhumbert/cyberpunk2077-input-loader/releases/tag/v'+$v);AssetPattern='(?i)^input_loader_v(?!.*pdb).*\.zip$';RequiredFiles=@('red4ext\plugins\input_loader\input_loader.dll','red4ext\plugins\input_loader\inputUserMappings.xml','r6\cache\inputContexts.xml','r6\cache\inputUserMappings.xml','engine\config\platform\pc\input_loader.ini')}
}

function Get-CyberpunkDepotProfile {
    $p=Get-CyberpunkCompatibilityProfile
    $p.InputLoader=Get-CyberpunkInputLoaderProfile '2.31'
    return $p
}

function Get-CyberpunkCurrentProfile {
    $profile=Get-CyberpunkCompatibilityProfile
    $profile.Id='cyberpunk-2.5-current';$profile.GameVersion='2.5';$profile.ModVersion='0.1.9'
    $profile.ModUrl='https://github.com/dariulone/cyberpunk-vr-port/releases/download/0.1.9/CyberpunkVRPort-0.1.9.zip'
    $profile.ModPage='https://github.com/dariulone/cyberpunk-vr-port/releases/tag/0.1.9'
    $versions=@('1.31.0','1.38.1','0.5.32','1.12.0','1.28.1','1.21.1')
    $patterns=@('(?i)^red4ext-(?!symbols).*\.zip$','(?i)^cet[_-].*\.zip$','(?i)^redscript-.*-windows\.zip$','(?i)^TweakXL-(?!.*pdb).*\.zip$','(?i)^ArchiveXL-(?!.*pdb).*\.zip$','(?i)^Codeware-(?!.*pdb).*\.zip$')
    for($i=0;$i -lt $profile.Components.Count;$i++){
        $c=$profile.Components[$i];$c.Version=$versions[$i];$c.GameVersion='2.5';$c.Identity=$c.Identity.Replace('cyberpunk231_','cyberpunk25_');$c.AssetPattern=$patterns[$i]
        $c.Tag='v'+$c.Version
        $c.File=switch($i){0{'red4ext-'+$c.Version+'.zip'}1{'cet_'+$c.Version.Replace('.','_')+'.zip'}2{'redscript-v'+$c.Version+'-windows.zip'}3{'TweakXL-'+$c.Version+'.zip'}4{'ArchiveXL-'+$c.Version+'.zip'}5{'Codeware-'+$c.Version+'.zip'}}
        $c.Pinned='https://github.com/'+$c.Repo+'/releases/download/'+$c.Tag+'/'+$c.File
        $c.Page='https://github.com/'+$c.Repo+'/releases/tag/'+$c.Tag
    }
    $profile.InputLoader=Get-CyberpunkInputLoaderProfile '2.5'
    $profile.ModSettings=Get-CyberpunkModSettingsProfile
    return $profile
}

function Resolve-CyberpunkCurrentProfile {
    # Reuse the website-first resolver used by the other GitHub installers.
    # A reachable release page must not depend on the separate REST API quota.
    if(-not(Get-Command Resolve-GitHubReleaseAsset -ErrorAction SilentlyContinue)){
        . (Join-Path $PSScriptRoot 'GitHubTransport.ps1')
    }
    $p=Get-CyberpunkCurrentProfile
    foreach($c in @($p.Components)+@($p.InputLoader)){
        $release=Resolve-GitHubReleaseAsset -Repo $c.Repo -AssetPatterns @($c.AssetPattern) -IncludePrerelease $false
        if(-not $release.Resolved){throw ($c.Name+': the current Windows download could not be checked on GitHub.')}
        $v=([regex]::Match([string]$release.Tag,'\d+\.\d+\.\d+')).Value
        if(-not $v -or [version]$v -lt [version]$c.Version){throw ($c.Name+': publisher release is below the 2.5 requirement.')}
        $c.Version=$v;$c.Tag=[string]$release.Tag;$c.File=[string]$release.AssetName;$c.Pinned=[string]$release.Url;$c.Page=[string]$release.PageUrl
    }
    $release=Resolve-GitHubReleaseAsset -Repo 'dariulone/cyberpunk-vr-port' -AssetPatterns @('(?i)^CyberpunkVRPort[-_].*\.zip$') -IncludePrerelease $false
    if(-not $release.Resolved){throw 'Cyberpunk VR: the current Windows download could not be checked on GitHub.'}
    $p.ModVersion=([string]$release.Tag).TrimStart('v','V');$p.ModUrl=[string]$release.Url;$p.ModPage=[string]$release.PageUrl
    if($p.ModVersion -notmatch '^\d+\.\d+\.\d+$' -or [version]$p.ModVersion -lt [version]'0.1.9'){throw 'The resolved VR release is too old for game 2.5. Retry or use manual recovery.'}
    return $p
}

function Get-CyberpunkRouteProfile {
    if($script:CyberpunkActiveProfile){return $script:CyberpunkActiveProfile}
    return Get-CyberpunkCompatibilityProfile
}

function Test-CyberpunkPinnedRoot([string]$Root){
    if(-not $Root){return $false}
    if(Test-Path -LiteralPath ([IO.Path]::Combine($Root,'.pcvrhub_cyberpunk_depot_231')) -PathType Leaf){return $true}
    $saved=Get-PCVRRememberedGameFolder -GameId 'cyberpunk-2077' -StateNames @('installed_path_depot') -ProbeFiles @('bin\x64\Cyberpunk2077.exe')
    return ($saved -and [IO.Path]::GetFullPath($saved).TrimEnd('\').Equals([IO.Path]::GetFullPath($Root).TrimEnd('\'),[StringComparison]::OrdinalIgnoreCase))
}

function Get-CyberpunkRememberedCurrentRoot {
    $recovery=Get-PCVRRecoveryInput
    if($recovery){
        $candidate=if(Test-Path -LiteralPath $recovery -PathType Leaf){Split-Path $recovery -Parent}else{$recovery}
        for($level=0;$level -lt 4 -and $candidate;$level++){
            if(Test-Path -LiteralPath ([IO.Path]::Combine($candidate,'bin\x64\Cyberpunk2077.exe')) -PathType Leaf){
                if(Test-CyberpunkPinnedRoot $candidate){throw 'That folder belongs to the separate Depot. Choose the normal game folder for Current; the Depot was not changed.'}
                return $candidate
            }
            $candidate=Split-Path $candidate -Parent
        }
    }
    foreach($state in @('user_located','installed_path_current','installed_path')){
        $candidate=Get-PCVRRememberedGameFolder -GameId 'cyberpunk-2077' -StateNames @($state) -ProbeFiles @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts')
        if($candidate -and -not(Test-CyberpunkPinnedRoot $candidate)){return $candidate}
    }
    return $null
}

function Get-CyberpunkCurrentProfileWithRecovery {
    while($true){
        try{return Resolve-CyberpunkCurrentProfile}catch{
            Write-Host ('  '+$_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  [R] Check the current downloads again' -ForegroundColor Green
            Write-Host '  [M] Use the known 2.5-compatible 0.1.9 setup; downloaded ZIPs can be handed over during download recovery' -ForegroundColor White
            Write-Host '  [O] Open the Current release page' -ForegroundColor Cyan
            $choice=(''+(Read-Host '  Choose R, M or O')).Trim().ToUpperInvariant()
            if($choice -eq 'M'){$known=Get-CyberpunkCurrentProfile;$known.UseKnownReleases=$true;return $known}
            if($choice -eq 'O'){[void](Open-PCVRPageAfterEnter -Url 'https://github.com/dariulone/cyberpunk-vr-port/releases' -Message 'Press Enter to open the Current releases...')}
            if(-not $choice -and [Console]::IsInputRedirected){throw [IO.EndOfStreamException]::new('Release lookup needs an interactive choice. Nothing was marked complete.')}
        }
    }
}

function Test-CyberpunkDepotBase([string]$Root){
    if(-not $Root){return $false}
    foreach($rel in @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts')){
        if(-not(Test-Path -LiteralPath ([IO.Path]::Combine($Root,$rel)) -PathType Leaf)){return $false}
    }
    # The EXE's FileVersion is an internal engine build (3.0.x), while
    # ProductVersion carries the actual game patch, for example "2.31".
    try{$v=[Diagnostics.FileVersionInfo]::GetVersionInfo(([IO.Path]::Combine($Root,'bin\x64\Cyberpunk2077.exe'))).ProductVersion}catch{return $false}
    return ([regex]::Match([string]$v,'^\d+\.\d+')).Value -eq '2.31'
}

function Resolve-CyberpunkDepotRoot {
    param([string]$HubFolder,[string]$DefaultPath='C:\Games\Cyberpunk 2077 VR 2.31')
    $default=$DefaultPath
    $saved=Join-Path $HubFolder '.installed_path_depot'
    $candidates=@($default)
    $remembered=Get-PCVRRememberedGameFolder -GameId 'cyberpunk-2077' -StateNames @('installed_path_depot') -ProbeFiles @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts')
    if($remembered){$candidates=@($remembered)+$candidates}
    if(Test-Path -LiteralPath $saved){$candidates=@((Get-Content -LiteralPath $saved -Raw).Trim())+$candidates}
    foreach($candidate in $candidates){
        if((Test-CyberpunkDepotBase $candidate) -and (Test-Path -LiteralPath ([IO.Path]::Combine($candidate,'.pcvrhub_cyberpunk_depot_231')))) {return $candidate}
    }
    Write-Host '  SEPARATE CYBERPUNK 2.31 DEPOT - your regular game is kept.' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host '  This needs about 62 GB, plus 23 GB if you add Phantom Liberty.' -ForegroundColor White
    Write-Host "  Steam's download cache needs roughly the same space again until you remove it." -ForegroundColor White
    Write-Host '  English voice is included. Other voices can be added from their pinned depot.' -ForegroundColor White
    Write-Host '  Current 2.5 saves must not be loaded by 2.31. The Hub keeps separate save profiles.' -ForegroundColor Yellow
    Write-Host ('  Choose an empty folder, or your existing separate 2.31 copy. Default: '+$default) -ForegroundColor White
    $raw=Read-Host '  Depot folder (Enter = default)'
    $target=if([string]::IsNullOrWhiteSpace($raw)){''}else{ConvertTo-PCVRCanonicalUserPath $raw}
    if(-not $target){$target=$default};$target=[IO.Path]::GetFullPath($target).TrimEnd('\')
    if($target -match '(?i)[\\/]steamapps[\\/]common[\\/]'){throw 'Choose a separate folder outside the regular Steam game library.'}
    if(-not(Test-InstallerTargetWritable -TargetPath ([IO.Path]::Combine($target,'.pcvrhub_write_target')))){throw 'The selected drive or depot folder is unavailable or not writable. Choose Retry and select another folder.'}
    $transfer=Join-Path $target '.pcvrhub_cyberpunk_depot_transfer'
    $resumable=(Test-Path -LiteralPath $transfer -PathType Leaf) -and ([IO.File]::ReadAllText($transfer) -eq '1091500/1091501/4104611899910011352')
    if((Test-Path -LiteralPath $target) -and -not(Test-CyberpunkDepotBase $target) -and -not $resumable -and @(Get-ChildItem -LiteralPath $target -Force).Count){throw 'The selected folder is not empty and is not a complete Cyberpunk 2.31 copy. Choose another folder in Retry.'}
    if(-not(Test-CyberpunkDepotBase $target)){
        $steam=Get-SteamPath
        if(-not $steam){throw 'Steam was not found. Open Steam, then choose Retry.'}
        $source=[IO.Path]::Combine($steam,'steamapps\content\app_1091500\depot_1091501')
        if(-not(Test-CyberpunkDepotBase $source)){
            $command='download_depot 1091500 1091501 4104611899910011352'
            Write-Host '  Paste this exact command in the Steam Console, then wait for completion:' -ForegroundColor Yellow
            Write-Host ('  '+$command) -ForegroundColor Black -BackgroundColor Yellow
            try{Set-Clipboard -Value $command -ErrorAction Stop;Write-Host '  The command is copied. Use Ctrl+V in the console.' -ForegroundColor White}catch{Write-Host '  Copy the displayed command manually.' -ForegroundColor White}
            [void](Open-PCVRPageAfterEnter -Url 'steam://open/console' -Message 'Press Enter to open the Steam Console...')
            do{
                [void](Wait-PCVRExplicitEnter -Message 'After Steam says Depot download complete, press Enter to check it...')
                if(Test-CyberpunkDepotBase $source){break}
                $raw=Read-Host '  Not complete yet. Enter its depot folder, or Enter to check again'
                $picked=if([string]::IsNullOrWhiteSpace($raw)){''}else{ConvertTo-PCVRCanonicalUserPath $raw}
                if($picked){$source=$picked}
            }while(-not(Test-CyberpunkDepotBase $source))
        }
        [void][IO.Directory]::CreateDirectory($target)
        [IO.File]::WriteAllText($transfer,'1091500/1091501/4104611899910011352')
        Write-Host '  Copying the separate game. This can take several minutes.' -ForegroundColor Yellow
        [void](Merge-DirectoryTreeVerified -Source $source -Destination $target -Label 'Cyberpunk 2.31 depot')
        if(-not(Test-CyberpunkDepotBase $target)){throw 'The copied depot is incomplete. Retry can reuse the downloaded files.'}
    }
    [IO.File]::WriteAllText([IO.Path]::Combine($target,'steam_appid.txt'),'1091500',[Text.Encoding]::ASCII)
    if(-not(Test-Path -LiteralPath (Join-Path $target '.pcvrhub_cyberpunk_depot_231'))){
        Install-CyberpunkDepotExtras -GameRoot $target -HubFolder $HubFolder
    }
    if(-not(Save-HubRememberedGameFolder -GameId 'cyberpunk-2077' -Title 'Cyberpunk 2077' -GameDir $target -StateName 'installed_path_depot' -ProbeFiles @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts'))){throw 'The separate depot path could not be remembered. Choose Retry; downloaded files are kept.'}
    return $target
}

function Get-CyberpunkDepotPackageFiles {
    param($Package)
    $codes=@{english='en';polish='pl';russian='ru';french='fr';italian='it';german='de';spanish='es-es';japanese='ja';schinese='zh-cn';koreana='ko';brazilian='pt'}
    $code=$codes[[string]$Package.Language]
    if(-not $code){throw 'The selected depot voice language is unknown.'}
    $folder=if($Package.Role -eq 'DLC'){'archive\pc\ep1'}else{'archive\pc\content'}
    $files=@($folder+'\lang_'+$code+'_voice.archive')
    if($Package.Role -eq 'DLC' -and $Package.Language -eq 'english'){$files+=@('archive\pc\ep1\ep1_2_gamedata.archive')}
    return $files
}

function Install-CyberpunkDepotExtras {
    param([string]$GameRoot,[string]$HubFolder)
    $pins=Get-Content -LiteralPath (Join-Path $HubFolder 'Depot231.json') -Raw|ConvertFrom-Json;$pins=@($pins)
    Write-Host '  Optional: other voice language, and Phantom Liberty if you own it.' -ForegroundColor Yellow
    $langs=@('english')+@($pins|Where-Object {$_.Role -eq 'Base' -and $_.Language -ne 'english'}|ForEach-Object Language)
    Write-Host ('  Voice languages: '+($langs -join ', ')) -ForegroundColor White
    do{$lang=(''+(Read-Host '  Voice language (Enter = english)')).Trim().ToLowerInvariant();if(-not $lang){$lang='english'}}while($lang -notin $langs)
    $dlc=(''+(Read-Host '  Add Phantom Liberty? Requires ownership [y/N]')).Trim() -match '^(?i)y(es)?$'
    $needed=@($pins|Where-Object {($_.Role -eq 'Base' -and $_.Language -eq $lang -and $lang -ne 'english') -or ($dlc -and $_.Role -eq 'DLC' -and $_.Language -in @('english',$lang))})
    $steam=Get-SteamPath
    foreach($pin in $needed){
        $requiredFiles=@(Get-CyberpunkDepotPackageFiles $pin)
        $source=[IO.Path]::Combine($steam,('steamapps\content\app_'+$pin.AppId+'\depot_'+$pin.DepotId))
        $command='download_depot '+$pin.AppId+' '+$pin.DepotId+' '+$pin.Manifest
        Write-Host ('  '+$pin.Role+' / '+$pin.Language+': '+$command) -ForegroundColor Black -BackgroundColor Yellow
        Write-Host '  Run this pinned command even if another version of the same depot was downloaded earlier.' -ForegroundColor White
        try{Set-Clipboard -Value $command -ErrorAction Stop}catch{}
        [void](Open-PCVRPageAfterEnter -Url 'steam://open/console' -Message 'Press Enter to open the Steam Console for this package...')
        [void](Wait-PCVRExplicitEnter -Message 'After this depot download completes, press Enter to copy it...')
        while(@($requiredFiles|Where-Object {-not(Test-Path -LiteralPath ([IO.Path]::Combine($source,$_)) -PathType Leaf)}).Count){
            $raw=Read-Host '  Depot not found yet. Paste its completed download folder, or Enter to check again'
            if(-not [string]::IsNullOrWhiteSpace($raw)){$source=ConvertTo-PCVRCanonicalUserPath $raw}
        }
        [void](Merge-DirectoryTreeVerified -Source $source -Destination $GameRoot -Label ($pin.Role+' '+$pin.Language))
        foreach($rel in $requiredFiles){if(-not(Test-Path -LiteralPath ([IO.Path]::Combine($GameRoot,$rel)) -PathType Leaf)){throw ('The selected '+$pin.Role+' / '+$pin.Language+' package is incomplete. Retry can reuse its downloaded files.')}}
    }
    # Durable local provenance describes the requested versions, not a download gate.
    @{Voice=$lang;PhantomLiberty=$dlc;Packages=$needed}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $GameRoot '.pcvrhub_cyberpunk_depot_extras.json') -Encoding UTF8
}

function Move-CyberpunkRetiredUi {
    param([string]$GameRoot)
    # Third-party HUDitor and Visible Bullets are optional user mods, not ours
    # to delete merely because the new port no longer requires them.
    $paths=@('r6\scripts\CyberpunkVRPort_LootUi','r6\scripts\CyberpunkVRPort_SettingsGuard','archive\pc\mod\vrport_menu_native.archive','archive\pc\mod\vrport_menu_panels.archive')
    foreach($rel in $paths){
        $path=Join-OwnedRelativePath $GameRoot $rel
        if(-not(Test-Path -LiteralPath $path)){continue}
        $dest=Join-OwnedRelativePath $GameRoot ('.pcvrhub_cyberpunk_retired\'+[guid]::NewGuid().ToString('N')+'\'+$rel)
        [void][IO.Directory]::CreateDirectory((Split-Path $dest -Parent))
        Move-Item -LiteralPath $path -Destination $dest -ErrorAction Stop
        Write-Host '  [OK] Older VR menu fix backed up and disabled.' -ForegroundColor Green
    }
    $thirdParty=@('r6\scripts\ContactMove','r6\scripts\ScannerUIMove','r6\scripts\TextsMove','r6\scripts\TooltipsMove','r6\scripts\TutorialMove','r6\scripts\HUDitor','bin\x64\plugins\cyber_engine_tweaks\mods\HUDitor','r6\input\HUDitor.xml')
    $found=@($thirdParty|Where-Object {Test-Path -LiteralPath (Join-OwnedRelativePath $GameRoot $_)})
    if($found.Count){
        Write-Host '  Older optional VR UI positioning mods were found. Current has its own VR menus.' -ForegroundColor Yellow
        Write-Host '  Back up and disable these old layouts? Their files are kept for manual restoration:' -ForegroundColor White
        foreach($rel in $found){Write-Host ('  '+$rel) -ForegroundColor Gray}
        $answer=(''+(Read-Host '  Back up and disable old UI layouts [Y/n]')).Trim()
        if($answer -notmatch '^(?i)n(o)?$'){
            foreach($rel in $found){
                $path=Join-OwnedRelativePath $GameRoot $rel
                $dest=Join-OwnedRelativePath $GameRoot ('.pcvrhub_cyberpunk_retired\ui-'+[guid]::NewGuid().ToString('N')+'\'+$rel)
                [void][IO.Directory]::CreateDirectory((Split-Path $dest -Parent))
                Move-Item -LiteralPath $path -Destination $dest -ErrorAction Stop
            }
            Write-Host '  [OK] Older UI layouts backed up and disabled.' -ForegroundColor Green
        }else{Write-Host '  Older UI layouts kept at your request; disable them if they conflict with the native menu.' -ForegroundColor Yellow}
    }
}

function global:Initialize-CyberpunkLegacyOwnership {
    param([string]$GameRoot,[string]$HubFolder)
    $manifest=Join-Path $GameRoot '.pcvrhub_cyberpunkvrport_ownership.csv'
    if(Test-Path -LiteralPath $manifest){return}
    $reference=Join-Path $HubFolder 'LegacyOwnership.csv'
    $rows=[Collections.Generic.List[object]]::new();$seen=@{}
    foreach($item in Import-Csv -LiteralPath $reference){
        $rel=Assert-PCVROwnedRelativePath ([string]$item.RelativePath)
        if($seen.ContainsKey($rel)){continue}
        $path=Join-OwnedRelativePath $GameRoot $rel
        if((Test-Path -LiteralPath $path -PathType Leaf) -and (Get-FileHash -LiteralPath $path).Hash -eq $item.Sha256){
            $rows.Add([pscustomobject]@{RelativePath=$rel;HadOriginal=$false;InstalledSha256=$item.Sha256});$seen[$rel]=$true
        }
    }
    if($rows.Count){$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding UTF8}
}

function Install-CyberpunkRouteLauncher {
    param([string]$GameRoot,[ValidateSet('Current','Depot')][string]$Route,[string]$HubFolder)
    $stage=Join-Path ([IO.Path]::GetTempPath()) ('CyberpunkLauncher-'+[guid]::NewGuid().ToString('N'))
    try{
        $folder=Join-Path $stage 'PCVR-Cyberpunk'
        [void][IO.Directory]::CreateDirectory($folder)
        Copy-Item -LiteralPath (Join-Path $HubFolder 'Start-CyberpunkVR.ps1') -Destination $folder -ErrorAction Stop
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'CyberpunkStartupCompatibility.ps1') -Destination $folder -ErrorAction Stop
        Copy-Item -LiteralPath (Join-Path $HubFolder 'UNINSTALL_CyberpunkVR.ps1') -Destination $folder -ErrorAction Stop
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'OwnedModFiles.ps1') -Destination $folder -ErrorAction Stop
        [IO.File]::WriteAllText((Join-Path $folder 'Uninstall VR.cmd'),"@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0UNINSTALL_CyberpunkVR.ps1`"`r`n",[Text.Encoding]::ASCII)
        $vbs=@'
Option Explicit
Dim shell, fso, here, script
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
script = fso.BuildPath(here, "Start-CyberpunkVR.ps1")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """", 0, False
'@
        [IO.File]::WriteAllText((Join-Path $folder 'Start VR.vbs'),$vbs,[Text.Encoding]::ASCII)
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $GameRoot -Identity 'cyberpunklauncher')
        $desktop=[Environment]::GetFolderPath('DesktopDirectory')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            $desktop=$env:PCVR_CYBERPUNK_TEST_DESKTOP
            if(-not $desktop -or -not [IO.Path]::GetFullPath($desktop).StartsWith([IO.Path]::GetTempPath(),[StringComparison]::OrdinalIgnoreCase)){throw 'An isolated test Desktop is required.'}
            [void][IO.Directory]::CreateDirectory($desktop)
        }
        $name=if($Route -eq 'Depot'){'Cyberpunk 2077 VR 2.31'}else{'Cyberpunk 2077 VR'}
        if($desktop){
            $link=Join-Path $desktop ($name+'.lnk');$target=Join-Path $GameRoot 'PCVR-Cyberpunk\Start VR.vbs'
            $shell=New-Object -ComObject WScript.Shell
            $shortcut=$shell.CreateShortcut($link)
            if((Test-Path -LiteralPath $link) -and $shortcut.Arguments -notlike ('*'+$target+'*')){throw 'A different desktop shortcut uses this name. Rename it, then Retry.'}
            $shortcut.TargetPath=Join-Path $env:WINDIR 'System32\wscript.exe';$shortcut.Arguments='"'+$target+'"'
            $shortcut.WorkingDirectory=$GameRoot;$shortcut.IconLocation=(Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe')+',0'
            $shortcut.Save()
        }
    }finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force}}
}

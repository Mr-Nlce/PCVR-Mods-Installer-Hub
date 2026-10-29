# Title-specific profiles using the same file ownership and rollback helpers
# as the established drop-in installers. Game files remain in their library.
function Get-GTA4Root([string]$Path){
    if([IO.File]::Exists($Path)){$Path=Split-Path $Path -Parent}
    foreach($p in @($Path,([IO.Path]::Combine($Path,'GTAIV')))){
        if([IO.File]::Exists([IO.Path]::Combine($p,'GTAIV.exe'))){return [IO.Path]::GetFullPath($p).TrimEnd('\')}
    }
    throw 'Choose the game folder containing GTAIV.exe, or drop GTAIV.exe here.'
}
function Get-GTA4Profile([string]$Mod){
    if($Mod -eq 'bordplate'){
        return @{Name='GTA4VR (bordplate)';Repo='bordplate/GTA4VR';Pattern='(?i)^GTA4VR\.zip$';Prerelease=$false;VersionFile='.pcvrhub_version';Required=@('vulkan.dll','d3d9.cfg','d3d9.dll','dinput8.dll','plugins\GTAIV.EFLC.FusionFix.asi','plugins\GTAIV.EFLC.FusionFix.ini','plugins\openxr_loader.dll','update\GTAIV.EFLC.FusionFix\GTAIV.EFLC.FusionFix.img')}
    }
    if($Mod -eq 'gamepad'){
        return @{Name='gtaiv-dxvk-vr (gamepad)';Repo='Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod';Pattern='(?i)^(?!.*(?:pdb|symbol|source)).*\.zip$';Prerelease=$false;VersionFile='.pcvrhub_version_b';Required=@('gtaiv_dxvk_vr.asi','d3d9.dll','dinput8.dll','openvr_api.dll','plugins\GTAIV.EFLC.FusionFix.asi')}
    }
    throw 'Unknown GTA IV VR mod.'
}
function Assert-GTA4Tree([string]$Root){
    $p=Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    if($p.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked GTA IV mod folders need manual handling.'}
    foreach($item in Get-ChildItem -LiteralPath $Root -Recurse -Force){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked GTA IV mod files need manual handling.'}}
}
function Assert-GTA4Payload([string]$Stage,[string]$Mod,[switch]$AllowParked){
    foreach($rel in (Get-GTA4Profile $Mod).Required){
        $file=[IO.Path]::Combine($Stage,$rel)
        if($AllowParked -and $Mod -eq 'gamepad' -and $rel -eq 'gtaiv_dxvk_vr.asi' -and -not [IO.File]::Exists($file)){foreach($suffix in @('.off','.pcvrhub_off')){if([IO.File]::Exists($file+$suffix)){$file+=$suffix;break}}}
        if(-not [IO.File]::Exists($file)){throw ('The '+$Mod+' package lacks '+$rel+'. No success was recorded.')}
        $item=Get-Item -LiteralPath $file -Force
        while($item -and $item.FullName.Length -ge [IO.Path]::GetFullPath($Stage).TrimEnd('\').Length){
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked GTA IV runtime files need manual handling.'}
            $item=if($item -is [IO.FileInfo]){$item.Directory}else{$item.Parent}
        }
    }
}
function Test-GTA4ProfilePresence([string]$Root,[string]$Mod){
    try{
        $game=Get-GTA4Root $Root;$store=Join-Path $game ('_vrmods\'+$Mod)
        if([IO.Directory]::Exists($store)){try{
            Assert-GTA4Payload $store $Mod
            # Real runtime files establish presence. A manually retained
            # profile need not have any Hub receipt or invented version.
            $receipt=$null
            if([IO.File]::Exists((Join-Path $store '.profile.json'))){try{$receipt=[IO.File]::ReadAllText((Join-Path $store '.profile.json'))|ConvertFrom-Json}catch{}}
            foreach($rel in @($receipt.Files)){
                if(-not $rel){continue}
                if([IO.Path]::IsPathRooted($rel) -or $rel -match '(^|[\\/])\.{1,2}([\\/]|$)|:'){return $false}
                if(-not [IO.File]::Exists([IO.Path]::Combine($store,[string]$rel))){return $false}
            }
            return $true
        }catch{if([IO.File]::Exists((Join-Path $store '.profile.json'))){return $false}}}
        $native=[IO.File]::Exists((Join-Path $game 'GTA4VR-notices\readme.md'))
        $old=[IO.File]::Exists((Join-Path $game 'gtaiv_dxvk_vr.asi'))
        $parked=[IO.File]::Exists((Join-Path $game 'gtaiv_dxvk_vr.asi.off')) -or [IO.File]::Exists((Join-Path $game 'gtaiv_dxvk_vr.asi.pcvrhub_off'))
        if(($Mod -eq 'bordplate' -and $native -and -not $old) -or ($Mod -eq 'gamepad' -and ($old -or $parked) -and -not $native)){Assert-GTA4Payload $game $Mod -AllowParked;return $true}
    }catch{}
    return $false
}
function Copy-GTA4Verified([string]$From,[string]$To){
    [void][IO.Directory]::CreateDirectory((Split-Path $To -Parent))
    Copy-Item -LiteralPath $From -Destination $To -Force -ErrorAction Stop
    if((Get-FileHash -LiteralPath $From).Hash -ne (Get-FileHash -LiteralPath $To).Hash){throw 'GTA IV file copy did not verify.'}
}
function Remove-GTA4Rollback([string]$Path){
    $full=[IO.Path]::GetFullPath($Path).TrimEnd('\')
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($full) -notmatch '^G4(Switch|Store)-[a-f0-9]{32}$'){throw 'Unsafe GTA IV rollback cleanup target.'}
    if(Test-Path -LiteralPath $full){Assert-GTA4Tree $full;Remove-Item -LiteralPath $full -Recurse -Force}
}
function Get-GTA4Active([string]$Game){
    $p=Join-Path $Game '_vrmods\active.json'
    if([IO.File]::Exists($p)){return ([IO.File]::ReadAllText($p)|ConvertFrom-Json).Mod}
    return ''
}
function Save-GTA4Active([string]$Game){
    if([IO.File]::Exists((Join-Path $Game 'gtaiv_dxvk_vr.asi')) -and [IO.File]::Exists((Join-Path $Game 'GTA4VR-notices\readme.md'))){throw 'Both VR mods are active in the same game folder. Back up and disable the loose gtaiv_dxvk_vr.asi before retrying. The retained profiles were not changed.'}
    $active=Get-GTA4Active $Game
    $manifest=Join-Path $Game '.pcvrhub_gta4active_ownership.csv'
    if(-not $active -or -not [IO.File]::Exists($manifest)){return}
    $rows=@(Import-Csv -LiteralPath $manifest)
    foreach($row in $rows){
        $rel=Assert-PCVROwnedRelativePath $row.RelativePath;$live=Join-OwnedRelativePath $Game $rel
        if([IO.File]::Exists($live)){
            Copy-GTA4Verified $live (Join-OwnedRelativePath (Join-Path $Game ('_vrmods\'+$active)) $rel)
            $row.InstalledSha256=(Get-FileHash -LiteralPath $live).Hash
        }
    }
    # Changed active files are first preserved in that mod's private profile.
    # Ownership may then safely retire them when another profile is activated.
    $rows|Export-Csv -LiteralPath ($manifest+'.new') -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath ($manifest+'.new') -Destination $manifest -Force
}
function Set-GTA4Active {
    param([string]$Game,[ValidateSet('bordplate','gamepad','flat')][string]$Mod,[switch]$SkipSave)
    $Game=Get-GTA4Root $Game
    if(Get-Process -Name GTAIV,PlayGTAIV,LaunchGTAIV -ErrorAction SilentlyContinue){throw 'Close GTA IV and its launcher before changing VR mods.'}
    $stores=Join-Path $Game '_vrmods';Assert-GTA4Tree $stores
    $stage=Join-Path $stores $Mod
    if($Mod -ne 'flat'){Assert-GTA4Payload $stage $Mod}else{[void][IO.Directory]::CreateDirectory($stage)}
    $rollback=Join-Path ([IO.Path]::GetTempPath()) ('G4Switch-'+[guid]::NewGuid().ToString('N'))
    $snap=Save-PCVRPublisherZipSnapshot -GameRoot $Game -Stage $stage -Identity gta4active -SnapshotRoot $rollback -ExtraPaths @('_vrmods\active.json')
    try{
        if(-not $SkipSave){Save-GTA4Active $Game}
        if($Mod -eq 'flat'){
            $result=Uninstall-OwnedModPayload -GameRoot $Game -Identity gta4active
            if($result.Preserved){throw 'Some changed GTA IV files could not be parked. Your profiles are kept.'}
        }else{
            $skip=@('.profile.json')+@(Get-ChildItem -LiteralPath $stage -Recurse -File|ForEach-Object {$_.FullName.Substring($stage.Length+1)}|Where-Object {$_ -match '^\.pcvrhub_'})
            [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $Game -Identity gta4active -SkipRelativePaths $skip)
            Assert-GTA4Payload $Game $Mod
        }
        @{Mod=$(if($Mod -eq 'flat'){''}else{$Mod})}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $stores 'active.json') -Encoding UTF8
    }catch{Restore-PCVRPublisherZipSnapshot -GameRoot $Game -Snapshot $snap;throw}
    finally{Remove-GTA4Rollback $rollback}
}
function Import-GTA4Gamepad([string]$Game){
    if(Get-GTA4Active $Game){return}
    $on=Join-Path $Game 'gtaiv_dxvk_vr.asi';$parked=''
    if(-not [IO.File]::Exists($on)){foreach($suffix in @('.off','.pcvrhub_off')){if([IO.File]::Exists($on+$suffix)){$parked=$on+$suffix;break}};if(-not $parked){return}}
    if([IO.File]::Exists((Join-Path $Game 'GTA4VR-notices\readme.md'))){if($parked){return};throw 'Both mods were merged into one folder without separate profiles. Back up and rename gtaiv_dxvk_vr.asi to gtaiv_dxvk_vr.asi.off, then Retry. The other mod can be installed separately afterwards.'}
    Assert-GTA4Payload $Game gamepad -AllowParked
    $store=Join-Path $Game '_vrmods\gamepad';[void][IO.Directory]::CreateDirectory($store)
    if($parked -and [IO.File]::Exists((Join-Path $store '.profile.json'))){try{Assert-GTA4Payload $store gamepad;return}catch{}}
    $files=@('aCompleteEditionHook.asi','d3d9.dll','d3d9.dll.stock-302','dinput8.dll','openvr_api.dll','FULL-RESTART.bat','gtaiv_dxvk_vr-FULL-RESTART.bat','QUICK-START.bat','commandline.txt.vr-square','plugins\GTAIV.EFLC.FusionFix.asi','plugins\GTAIV.EFLC.FusionFix.ini','plugins\GTAIV.EFLC.FusionFix.cfg','common\data\hud.dat','common\data\hud.dat.gtaiv-dxvk-vr.bak')
    $files+=@(Get-ChildItem -LiteralPath $Game -File -Filter 'gtaiv_dxvk_vr.*'|ForEach-Object Name)
    $folder=Join-Path $Game 'update\GTAIV.EFLC.FusionFix'
    if(Test-Path -LiteralPath $folder){$files+=@(Get-ChildItem -LiteralPath $folder -Recurse -File|ForEach-Object {$_.FullName.Substring($Game.Length+1)})}
    foreach($rel in $files|Sort-Object -Unique){$p=Join-OwnedRelativePath $Game $rel;if([IO.File]::Exists($p)){Copy-GTA4Verified $p (Join-OwnedRelativePath $store $rel)}}
    if($parked){
        Copy-GTA4Verified $parked (Join-Path $store 'gtaiv_dxvk_vr.asi')
        @{Mod='gamepad';Imported=$true;Version=''}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $store '.profile.json') -Encoding UTF8
        $mode=Join-Path $Game '_vrmods\mode.ini';if(-not [IO.File]::Exists($mode)){[IO.File]::WriteAllText($mode,"[Hub]`r`nMode=Flat`r`n")}
        return
    }
    # Adopt the existing mod, preserving the old installer's original backups.
    $skip=@('.profile.json')+@(Get-ChildItem -LiteralPath $store -Recurse -File|ForEach-Object {$_.FullName.Substring($store.Length+1)}|Where-Object {$_ -match '^\.pcvrhub_'})
    [void](Install-OwnedModPayload -SourceRoot $store -GameRoot $Game -Identity gta4active -AdoptIdenticalExisting -SkipRelativePaths $skip)
    $manifest=Join-Path $Game '.pcvrhub_gta4active_ownership.csv';$rows=@(Import-Csv -LiteralPath $manifest)
    foreach($row in $rows){$old=Join-OwnedRelativePath $Game ($row.RelativePath+'.vrbak');if([IO.File]::Exists($old)){Copy-GTA4Verified $old (Join-OwnedRelativePath (Join-Path $Game '.pcvrhub_gta4active_backup') $row.RelativePath);$row.HadOriginal='True'}}
    $rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding UTF8
    @{Mod='gamepad'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $Game '_vrmods\active.json') -Encoding UTF8
    $prior=Join-Path $Game '.pcvrhub_version'
    if([IO.File]::Exists($prior)){Copy-GTA4Verified $prior (Join-Path $Game '.pcvrhub_version_b');Copy-GTA4Verified $prior (Join-Path $store '.pcvrhub_version')}
    @{Mod='gamepad';Version=$(if([IO.File]::Exists($prior)){[IO.File]::ReadAllText($prior).Trim()}else{''});Imported=$true}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $store '.profile.json') -Encoding UTF8
}
function Import-GTA4Native([string]$Game){
    if(Get-GTA4Active $Game){return}
    if(-not [IO.File]::Exists((Join-Path $Game 'GTA4VR-notices\readme.md'))){return}
    if([IO.File]::Exists((Join-Path $Game 'gtaiv_dxvk_vr.asi'))){return}
    Assert-GTA4Payload $Game bordplate
    $store=Join-Path $Game '_vrmods\bordplate';[void][IO.Directory]::CreateDirectory($store)
    $files=@('d3d9.cfg','d3d9.dll','dinput8.dll','vulkan.dll','plugins\GTAIV.EFLC.FusionFix.asi','plugins\GTAIV.EFLC.FusionFix.ini','plugins\openxr_loader.dll','plugins\openxr_loader.LICENSE.txt')
    foreach($rel in @('GTA4VR-notices','plugins\VRWeapons','plugins\VRVehicles','update\GTAIV.EFLC.FusionFix')){
        $path=Join-Path $Game $rel
        if([IO.Directory]::Exists($path)){Assert-GTA4Tree $path;$files+=@(Get-ChildItem -LiteralPath $path -Recurse -File|ForEach-Object {$_.FullName.Substring($Game.Length+1)})}
    }
    foreach($rel in $files|Sort-Object -Unique){$p=Join-OwnedRelativePath $Game $rel;if([IO.File]::Exists($p)){Copy-GTA4Verified $p (Join-OwnedRelativePath $store $rel)}}
    $skip=@('.profile.json')+@(Get-ChildItem -LiteralPath $store -Recurse -File|ForEach-Object {$_.FullName.Substring($store.Length+1)}|Where-Object {$_ -match '^\.pcvrhub_'})
    [void](Install-OwnedModPayload -SourceRoot $store -GameRoot $Game -Identity gta4active -AdoptIdenticalExisting -SkipRelativePaths $skip)
    @{Mod='bordplate';Imported=$true;Version=''}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $store '.profile.json') -Encoding UTF8
    @{Mod='bordplate'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $Game '_vrmods\active.json') -Encoding UTF8
}
function Install-GTA4Profile {
    param([string]$Game,[string]$Stage,[string]$Mod,[string]$Version)
    $Game=Get-GTA4Root $Game;Assert-GTA4Payload $Stage $Mod
    $stores=Join-Path $Game '_vrmods';[void][IO.Directory]::CreateDirectory($stores);Assert-GTA4Tree $stores
    Import-GTA4Gamepad $Game
    Import-GTA4Native $Game
    $active=Get-GTA4Active $Game
    if($active -eq $Mod){Save-GTA4Active $Game}
    $store=Join-Path $stores $Mod;[void][IO.Directory]::CreateDirectory($store)
    $keep=@(Get-ChildItem -LiteralPath $Stage -Recurse -File|Where-Object {$_.Extension -in @('.ini','.cfg') -or $_.Name -match '^gtaiv_dxvk_vr\.' -and $_.Extension -ne '.asi'}|ForEach-Object {$_.FullName.Substring($Stage.TrimEnd('\').Length+1)})
    $rollback=Join-Path ([IO.Path]::GetTempPath()) ('G4Store-'+[guid]::NewGuid().ToString('N'))
    $snap=Save-PCVRPublisherZipSnapshot -GameRoot $store -Stage $Stage -Identity ('gta4store_'+$Mod) -SnapshotRoot $rollback -ExtraPaths @('.profile.json')
    try{
        [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $store -Identity ('gta4store_'+$Mod) -KeepExistingRelativePaths $keep)
        Assert-GTA4Payload $store $Mod
        @{Mod=$Mod;Version=$Version;Files=@(Get-ChildItem -LiteralPath $Stage -Recurse -File|ForEach-Object {$_.FullName.Substring($Stage.TrimEnd('\').Length+1)})}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $store '.profile.json') -Encoding UTF8
        $mode=Join-Path $Game '_vrmods\mode.ini'
        $flat=[IO.File]::Exists($mode) -and [IO.File]::ReadAllText($mode) -match '(?im)^\s*Mode\s*=\s*Flat\s*$'
        if((-not $active -and -not $flat) -or $active -eq $Mod){Set-GTA4Active -Game $Game -Mod $Mod -SkipSave}
    }catch{Restore-PCVRPublisherZipSnapshot -GameRoot $store -Snapshot $snap;throw}
    finally{Remove-GTA4Rollback $rollback}
}
function Get-GTA4LaunchPlan([string]$Game){
    $Game=Get-GTA4Root $Game
    if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return @{File='steam://rungameid/12210';Directory=$Game}}
    foreach($exe in @('PlayGTAIV.exe','LaunchGTAIV.exe','GTAIV.exe')){$p=Join-Path $Game $exe;if([IO.File]::Exists($p)){return @{File=$p;Directory=$Game}}}
}
function Get-GTA4OpenXRReadiness {
    param([string]$Manifest='')
    if(-not $Manifest){
        # GTA IV is x86. Its registry view may differ from the SteamVR UI or
        # from the 64-bit runtime used by other games.
        try{$key=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Registry32);try{$sub=$key.OpenSubKey('SOFTWARE\Khronos\OpenXR\1');if($sub){try{$Manifest=[string]$sub.GetValue('ActiveRuntime')}finally{$sub.Dispose()}}}finally{$key.Dispose()}}catch{}
    }
    if(-not $Manifest -or -not [IO.File]::Exists($Manifest)){return @{Ready=$false;Manifest=$Manifest}}
    $directory=Split-Path $Manifest -Parent
    while($directory){
        $bootstrap=Join-Path $directory 'bin\win32\openvr_api.dll'
        $steamManifest=Join-Path $directory 'steamxr_win32.json'
        if([IO.File]::Exists($bootstrap) -and [IO.File]::Exists($steamManifest)){return @{Ready=$true;Manifest=$Manifest;Bootstrap=$bootstrap}}
        $parent=Split-Path $directory -Parent;if($parent -eq $directory){break};$directory=$parent
    }
    return @{Ready=$false;Manifest=$Manifest}
}
function Set-GTA4OpenVRBootstrap {
    param([string]$Game,[string]$Bootstrap)
    if(-not $Bootstrap -or -not [IO.Path]::IsPathRooted($Bootstrap) -or -not [IO.File]::Exists($Bootstrap)){throw 'The SteamVR 32-bit bootstrap DLL is missing. Repair SteamVR before retrying.'}
    $ini=Join-Path (Get-GTA4Root $Game) 'plugins\GTAIV.EFLC.FusionFix.ini'
    if(-not [IO.File]::Exists($ini)){throw 'The selected bordplate configuration is missing.'}
    $text=[IO.File]::ReadAllText($ini)
    $match=[regex]::Match($text,'(?im)^\s*VulkanOpenVRBootstrap\s*=([^\r\n]*)')
    if($match.Success){
        $value=($match.Groups[1].Value -split '\s*//|\s*;',2)[0].Trim().Trim('"')
        if($value){if([IO.File]::Exists($value)){return};throw ('Your configured VulkanOpenVRBootstrap file is missing: '+$value+'. Restore that file or clear this setting and retry.')}
    }
    $line='VulkanOpenVRBootstrap = '+([IO.Path]::GetFullPath($Bootstrap).Replace('\','/'))
    if($match.Success){$next=$text.Substring(0,$match.Index)+$line+$text.Substring($match.Index+$match.Length)}
    elseif($text -match '(?im)^\[VR\]\s*$'){$next=[regex]::Replace($text,'(?im)^\[VR\]\s*$',('[VR]'+"`r`n"+$line))}
    else{$next=$text+"`r`n[VR]`r`n"+$line+"`r`n"}
    $backup=$ini+'.pcvrhub-bootstrap.bak'
    if(-not [IO.File]::Exists($backup)){[IO.File]::WriteAllBytes($backup,[IO.File]::ReadAllBytes($ini))}
    [IO.File]::WriteAllText($ini,$next,[Text.UTF8Encoding]::new($false))
}
function Remove-GTA4Profile([string]$Game,[string]$Mod,[string]$Desktop){
    $Game=Get-GTA4Root $Game;$active=Get-GTA4Active $Game
    if(Get-Process -Name GTAIV,PlayGTAIV,LaunchGTAIV -ErrorAction SilentlyContinue){throw 'Close GTA IV and its launcher before removal.'}
    if($active -eq $Mod){Set-GTA4Active -Game $Game -Mod flat}
    $store=Join-Path $Game ('_vrmods\'+$Mod)
    [void](Uninstall-OwnedModPayload -GameRoot $store -Identity ('gta4store_'+$Mod))
    foreach($p in @((Join-Path $store '.profile.json'),(Join-Path $store '.pcvrhub_version'),(Join-Path $Game (Get-GTA4Profile $Mod).VersionFile))){if([IO.File]::Exists($p)){Remove-Item -LiteralPath $p -Force}}
    if([IO.Directory]::Exists($store) -and @(Get-ChildItem -LiteralPath $store -Recurse -File).Count){
        $parent=[IO.Path]::GetFullPath((Join-Path $Game '_vrmods')).TrimEnd('\')+'\'
        $target=Join-Path $parent ('retained-'+$Mod+'-'+[guid]::NewGuid().ToString('N'))
        if(-not [IO.Path]::GetFullPath($store).StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -or -not [IO.Path]::GetFullPath($target).StartsWith($parent,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe GTA IV recovery folder.'}
        Assert-GTA4Tree $store
        Move-Item -LiteralPath $store -Destination $target -ErrorAction Stop
        Write-Host ('  Kept changed settings and recovery files: '+$target) -ForegroundColor Gray
    }
    if(-not $Desktop -and $env:PCVR_HUB_TEST_MODE -ne '1'){$Desktop=[Environment]::GetFolderPath('Desktop')}
    if($Desktop){
        $link=Join-Path $Desktop ('GTA IV VR ('+$Mod+').lnk')
        if([IO.File]::Exists($link)){
            $shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut($link)
            $expected='"'+(Join-Path $Game ('_vrmods\VRLaunch\Start GTA4 '+$Mod+'.vbs'))+'"'
            if($shortcut.TargetPath -ieq (Join-Path $env:WINDIR 'System32\wscript.exe') -and $shortcut.Arguments -ceq $expected){Remove-Item -LiteralPath $link -Force}
        }
    }
    if(-not(Test-GTA4ProfilePresence $Game bordplate) -and -not(Test-GTA4ProfilePresence $Game gamepad)){[void](Uninstall-OwnedModPayload -GameRoot $Game -Identity gta4controllers)}
    # Kept settings and imported files remain as recovery data but no longer
    # count as an installed profile without its version/ownership receipt.
}

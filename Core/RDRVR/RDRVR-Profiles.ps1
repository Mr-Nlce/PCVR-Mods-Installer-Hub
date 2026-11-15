# RDRVR's two publishers use the same runtime names. Retain each package
# separately; only Play deploys a selected profile into the licensed game.
if(-not(Get-Command Assert-PCVROwnedRelativePath -ErrorAction SilentlyContinue)){
    $owned=Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1'
    if([IO.File]::Exists($owned)){. $owned}
}
function Test-RdrHookConfig([string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return $false}
    $inSection=$false;$setting=$null
    foreach($line in [IO.File]::ReadAllLines($Path)){
        if($line -match '^\s*\[([^]]+)\]'){$inSection=$Matches[1] -ieq 'DirectXHook';continue}
        if($inSection -and $line -match '^\s*Disabled\s*=\s*(true|false)\s*(?:[;#].*)?$'){
            $setting=($Matches[1] -ieq 'true')
        }
    }
    return [bool]$setting
}
function Get-RdrProfileRoot([string]$Game,[string]$Mod) { Join-Path $Game ('.pcvrhub_rdr_profiles\'+$Mod) }
function Get-RdrProfileVersionFile([string]$Mod) { if($Mod -eq 'fork'){'.pcvrhub_version_b'}else{'.pcvrhub_version'} }
function Get-RdrProfileDeployment([string]$Store) {
    $manifest=Join-Path $Store '.pcvrhub_rdrstore_ownership.csv'
    if([IO.File]::Exists($manifest)){
        $ini=Join-Path $Store 'RDRVR.ini'
        $iniHash=if([IO.File]::Exists($ini)){(Get-FileHash -LiteralPath $ini -Algorithm SHA256).Hash}else{''}
        return ((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash+'|'+$iniHash)
    }
    return ''
}
function Get-RdrNativeReceipt([string]$Root) {
    $file=Join-Path $Root 'RDRVR_install.json'
    if([IO.File]::Exists($file)){try{return ([IO.File]::ReadAllText($file)|ConvertFrom-Json)}catch{}}
    return $null
}
function Get-RdrPayloadIdentity([string]$Root) {
    $versionFile=Join-Path $Root 'RDRVR_version.txt'
    if([IO.File]::Exists($versionFile)){return @{Version=[IO.File]::ReadAllText($versionFile).Trim().TrimStart('v');Source='PublisherVersion'}}
    $publisherVersion=[string](Get-RdrNativeReceipt $Root).version
    $stamp=Join-Path $Root '.pcvrhub_version';$hubVersion=if([IO.File]::Exists($stamp)){[IO.File]::ReadAllText($stamp).Trim().TrimStart('v')}else{''}
    if($publisherVersion -match '^v?\d+\.\d+\.\d+\.\d+$' -and $hubVersion -match '^\d+\.\d+\.\d+$'){
        # A native publisher receipt may predate a later Hub main install.
        # Only unchanged owned core files can give that main receipt priority.
        $owned=Join-Path $Root '.pcvrhub_rdrvr_ownership.csv'
        if([IO.File]::Exists($owned)){
            $rows=@(Import-Csv -LiteralPath $owned);$ownedMatches=$true
            foreach($name in @('dinput8.dll','RDRVR.Gameplay.red')){
                $row=@($rows|Where-Object RelativePath -eq $name)
                if($row.Count -ne 1 -or -not [IO.File]::Exists((Join-Path $Root $name)) -or (Get-FileHash -LiteralPath (Join-Path $Root $name)).Hash -ne $row[0].InstalledSha256){$ownedMatches=$false;break}
            }
            if($ownedMatches){return @{Version=$hubVersion;Source='HubOwned'}}
        }
    }
    if($publisherVersion){return @{Version=$publisherVersion.TrimStart('v');Source='PublisherReceipt'}}
    return @{Version=$hubVersion;Source='HubStamp'}
}
function Get-RdrPayloadVersion([string]$Root) {
    return [string](Get-RdrPayloadIdentity $Root).Version
}
function Get-RdrActive([string]$Game) {
    $file=Join-Path $Game '.pcvrhub_rdr_profiles\active.json'
    if([IO.File]::Exists($file)){
        $value=[IO.File]::ReadAllText($file)|ConvertFrom-Json
        if($value.Mod -notin @('main','fork','')){throw 'The saved RDRVR profile is invalid.'}
        return $value
    }
    return $null
}
function Assert-RdrClosed {
    if(($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_PROCESS_RUNNING -eq '1') -or
       ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process RDR -ErrorAction SilentlyContinue))){throw 'Close Red Dead Redemption before installing, switching or removing a VR mod.'}
}
function Assert-RdrPathAncestors([string]$Path) {
    $pathToCheck=[IO.Path]::GetFullPath($Path)
    while($pathToCheck){
        if([IO.File]::Exists($pathToCheck) -or [IO.Directory]::Exists($pathToCheck)){
            if([IO.File]::GetAttributes($pathToCheck) -band [IO.FileAttributes]::ReparsePoint){throw 'Linked RDRVR files or folders need manual handling. Select the real game folder.'}
        }
        $pathToCheck=[IO.Path]::GetDirectoryName($pathToCheck)
    }
}
function Assert-RdrProfileTree([string]$Root) {
    $item=Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    while($item){
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked RDRVR folders need manual handling.'}
        $item=if($item -is [IO.FileInfo]){$item.Directory}else{$item.Parent}
    }
    foreach($item in Get-ChildItem -LiteralPath $Root -Force -Recurse){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked RDRVR files need manual handling.'}}
}
function Get-RdrProfileFiles([string]$Root) {
    $result=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $nativeReceipt=Get-RdrNativeReceipt $Root
    $nativeVersion=[string]$nativeReceipt.version
    foreach($name in @('dinput8.dll','RDRVR.Gameplay.red','RDRVR.ini','RDRVR_click_revolver.wav','RDRVR_click_rifle.wav','RDRVR_click_shotgun.wav','RDRVR_version.txt','RDRVR_files.txt')){
        if([IO.File]::Exists((Join-Path $Root $name))){[void]$result.Add($name)}
    }
    # The publisher's current manifest supplies current functional files,
    # including newly added models and the optional converter or shaders.
    $list=Join-Path $Root 'RDRVR_files.txt';$lines=@()
    if([IO.File]::Exists($list)){
        $lines=[IO.File]::ReadAllLines($list)
    }elseif((Get-RdrPayloadIdentity $Root).Source -in @('HubOwned','HubStamp') -and [IO.File]::Exists((Join-Path $Root '.pcvrhub_rdrvr_ownership.csv'))){
        $lines=@(Import-Csv -LiteralPath (Join-Path $Root '.pcvrhub_rdrvr_ownership.csv')|ForEach-Object {[string]$_.RelativePath})
    }elseif($nativeVersion -and $nativeVersion.TrimStart('v') -eq (Get-RdrPayloadVersion $Root)){
        $lines=@($nativeReceipt.files|ForEach-Object {[string]$_.file})
    }elseif([IO.File]::Exists((Join-Path $Root '.pcvrhub_rdractive_ownership.csv'))){
        $lines=@(Import-Csv -LiteralPath (Join-Path $Root '.pcvrhub_rdractive_ownership.csv')|ForEach-Object {[string]$_.RelativePath})
    }elseif([IO.File]::Exists((Join-Path $Root '.pcvrhub_rdrvr_ownership.csv'))){
        $lines=@(Import-Csv -LiteralPath (Join-Path $Root '.pcvrhub_rdrvr_ownership.csv')|ForEach-Object {[string]$_.RelativePath})
    }elseif([IO.File]::Exists((Join-Path $Root '.pcvrhub_rdrstore_ownership.csv'))){
        $lines=@(Import-Csv -LiteralPath (Join-Path $Root '.pcvrhub_rdrstore_ownership.csv')|ForEach-Object {[string]$_.RelativePath})
    }
    if($lines.Count){
        foreach($line in $lines){
            if(-not $line.Trim()){continue}
            $rel=Assert-PCVROwnedRelativePath $line.Trim()
            if($rel -notmatch '^(?i:RDRVR[^\\/]*(?:[\\/].+)?|dinput8\.dll|nvngx_dlss\.dll)$'){throw "Unexpected RDRVR runtime path: $rel"}
            [void]$result.Add($rel)
        }
    }
    return @($result)
}
function Test-RdrProfilePayload([string]$Root,[string]$Mod) {
    try{
        foreach($rel in @('dinput8.dll','RDRVR.Gameplay.red','RDRVR.ini','RDRVR_click_revolver.wav','RDRVR_click_rifle.wav','RDRVR_click_shotgun.wav')){
            if(-not [IO.File]::Exists((Join-Path $Root $rel))){return $false}
        }
        $actualVersion=Get-RdrPayloadVersion $Root
        if($Mod -eq 'fork'){
            if($actualVersion -notmatch '^\d+\.\d+\.\d+\.\d+$'){return $false}
            if([version]$actualVersion -ge [version]'0.8.11.11'){
              foreach($name in @('boltaction','cattleman','highpower','mauser','schofield','springfield','winchester')){
                foreach($suffix in @('.mesh','_d.dds','_n.dds','_so.dds')){if(-not [IO.File]::Exists((Join-Path $Root ('RDRVR_models\'+$name+$suffix)))){return $false}}
              }
            }
            $converter=$true
            foreach($name in @('rdrvr_shaderconv.exe','rdrvr_dxcompiler.dll','rdrvr_dxil.dll')){if(-not [IO.File]::Exists((Join-Path $Root ('RDRVR_dxc\'+$name)))){$converter=$false}}
            $preconverted=[IO.File]::Exists((Join-Path $Root 'RDRVR_shaders\no_twin.txt')) -and
                [IO.Directory]::Exists((Join-Path $Root 'RDRVR_shaders')) -and @([IO.Directory]::EnumerateFiles((Join-Path $Root 'RDRVR_shaders'),'*.dxil')).Count -gt 0
            if(-not $converter -and -not $preconverted){return $false}
        }elseif($actualVersion -match '^\d+\.\d+\.\d+\.\d+$'){
            # Recent main-channel hotfixes also have four version parts.
            foreach($rel in @('RDRVR_Launcher\RDRVR_Launcher.exe','RDRVR_Converter\rdrvr_vi_convert.exe','RDRVR_Converter\rdrvr_dxcompiler.dll')){
                if(-not [IO.File]::Exists((Join-Path $Root $rel))){return $false}
            }
        }elseif($actualVersion -notmatch '^\d+\.\d+\.\d+$'){return $false}
        foreach($rel in @(Get-RdrProfileFiles $Root)){
            # Optional upscaling and publisher inventories are not VR runtime
            # evidence. They are copied and owned, never required for presence.
            if($rel -in @('nvngx_dlss.dll','RDRVR_files.txt','RDRVR-LICENSE.txt','RDRVR-THIRD-PARTY-NOTICES.txt')){continue}
            if(-not [IO.File]::Exists((Join-OwnedRelativePath $Root $rel))){return $false}
        }
        return $true
    }catch{return $false}
}
function Test-RdrProfilePresence([string]$Game,[string]$Mod) {
    foreach($rel in @('RedHook.dll','winmm.dll','RedHook.ini')){if(-not [IO.File]::Exists((Join-Path $Game $rel))){return $false}}
    if(-not(Test-RdrHookConfig (Join-Path $Game 'RedHook.ini'))){return $false}
    $store=Get-RdrProfileRoot $Game $Mod
    if(Test-RdrProfilePayload $store $Mod){return $true}
    $active=Get-RdrActive $Game
    if($active -and $active.Mod){return $false}
    if(-not(Test-RdrProfilePayload $Game $Mod)){return $false}
    # Old Hub installations predate the publisher version file. Its exact
    # main-route receipt distinguishes them from a loose, unidentified fork.
    return $true
}
function Get-RdrInstalledProfileVersion([string]$Game,[string]$Mod) {
    $store=Get-RdrProfileRoot $Game $Mod
    if(Test-RdrProfilePayload $store $Mod){return Get-RdrPayloadVersion $store}
    if(Test-RdrProfilePresence $Game $Mod){return Get-RdrPayloadVersion $Game}
    return $null
}
function Copy-RdrProfileFile([string]$From,[string]$To) {
    Assert-RdrPathAncestors $From;Assert-RdrPathAncestors $To
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $To))
    Copy-Item -LiteralPath $From -Destination $To -Force -ErrorAction Stop
    if((Get-FileHash -LiteralPath $From).Hash -ne (Get-FileHash -LiteralPath $To).Hash){throw 'An RDRVR file copy did not verify.'}
}
function Get-RdrRuntimeExtras([string]$Game) {
    $shader=Join-Path $Game 'RDRVR_shaders'
    if([IO.Directory]::Exists($shader)){
        Assert-RdrProfileTree $shader
        foreach($file in Get-ChildItem -LiteralPath $shader -Recurse -File -Force){'RDRVR_shaders\'+$file.FullName.Substring($shader.TrimEnd('\').Length+1)}
    }
    if([IO.File]::Exists((Join-Path $Game 'RDRVR_xr_runtime.txt'))){'RDRVR_xr_runtime.txt'}
}
function Park-RdrRuntimeExtras([string]$Game) {
    $original=Get-RdrProfileRoot $Game 'original-runtime-extras'
    foreach($relative in @(Get-RdrRuntimeExtras $Game)){
        $live=Join-OwnedRelativePath $Game $relative;$saved=Join-OwnedRelativePath $original $relative
        if([IO.File]::Exists($saved) -and (Get-FileHash -LiteralPath $saved).Hash -ne (Get-FileHash -LiteralPath $live).Hash){
            $saved=Join-OwnedRelativePath (Get-RdrProfileRoot $Game ('retained-runtime-'+[guid]::NewGuid().ToString('N'))) $relative
        }
        if(-not [IO.File]::Exists($saved)){Copy-RdrProfileFile $live $saved}
        Remove-Item -LiteralPath $live -Force
    }
}
function Import-RdrActive([string]$Game) {
    if(Get-RdrActive $Game){return}
    $mod=if(Test-RdrProfilePresence $Game fork){'fork'}elseif(Test-RdrProfilePresence $Game main){'main'}else{''}
    if(-not $mod){
        if(-not [IO.File]::Exists((Join-Path $Game 'RDRVR.Gameplay.red'))){return}
        $known=[IO.File]::Exists((Join-Path $Game '.pcvrhub_rdrvr_ownership.csv')) -or [bool](Get-RdrNativeReceipt $Game)
        $oldVersion=Get-RdrPayloadVersion $Game
        if($known -and $oldVersion -match '^\d+\.\d+\.\d+\.\d+$' -and [version]$oldVersion -le [version]'0.8.11.11'){$mod='fork'}
        elseif($known -and $oldVersion -match '^\d+\.\d+\.\d+$'){$mod='main'}
        else{throw 'An unidentified RDRVR installation is present. Back it up before replacing it. No files were changed.'}
    }
    $store=Get-RdrProfileRoot $Game $mod;[void][IO.Directory]::CreateDirectory($store)
    $rows=@();$oldManifest=Join-Path $Game '.pcvrhub_rdrvr_ownership.csv'
    $old=@{};if([IO.File]::Exists($oldManifest)){foreach($row in @(Import-Csv -LiteralPath $oldManifest)){$old[(Assert-PCVROwnedRelativePath $row.RelativePath)]=$row}}
    foreach($rel in @(Get-RdrProfileFiles $Game)){
        $live=Join-OwnedRelativePath $Game $rel
        $prior=$old[$rel]
        if(-not [IO.File]::Exists($live)){
            if($prior -and $prior.HadOriginal -eq 'True'){$rows+=$prior}
            continue
        }
        Copy-RdrProfileFile $live (Join-OwnedRelativePath $store $rel)
        $hadOriginal=if($prior){$prior.HadOriginal -eq 'True'}else{$true}
        if($hadOriginal -and -not $prior){Copy-RdrProfileFile $live (Join-OwnedRelativePath (Join-Path $Game '.pcvrhub_rdractive_backup') $rel)}
        $rows+=[pscustomobject]@{RelativePath=$rel;HadOriginal=$hadOriginal;InstalledSha256=(Get-FileHash -LiteralPath $live).Hash}
    }
    # Transfer old ownership and original backups without removing a live file.
    $backup=Join-Path $Game '.pcvrhub_rdrvr_backup'
    if([IO.Directory]::Exists($backup)){
        Assert-RdrProfileTree $backup
        foreach($file in Get-ChildItem -LiteralPath $backup -Recurse -File -Force){
            $relative=$file.FullName.Substring($backup.TrimEnd('\').Length+1)
            $target=Join-OwnedRelativePath (Join-Path $Game '.pcvrhub_rdractive_backup') $relative
            if([IO.File]::Exists($target)){
                if((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw ('Conflicting original RDRVR backups need review before switching: '+$relative)}
            }else{Copy-RdrProfileFile $file.FullName $target}
        }
    }
    $rows|Export-Csv -LiteralPath (Join-Path $Game '.pcvrhub_rdractive_ownership.csv') -NoTypeInformation -Encoding UTF8
    $versionFile=Join-Path $Game (Get-RdrProfileVersionFile $mod)
    $version=Get-RdrPayloadVersion $Game
    if(-not $version -and [IO.File]::Exists($versionFile)){$version=[IO.File]::ReadAllText($versionFile).Trim()}
    $storedRows=@($rows|ForEach-Object {[pscustomobject]@{RelativePath=$_.RelativePath;HadOriginal=$false;InstalledSha256=$_.InstalledSha256}})
    $originalIniSha=if($old.ContainsKey('RDRVR.ini')){[string]$old['RDRVR.ini'].InstalledSha256}else{''}
    if(-not $originalIniSha){$receipt=Get-RdrNativeReceipt $Game;$originalIniSha=[string](@($receipt.files|Where-Object file -eq 'RDRVR.ini'|Select-Object -First 1).sha256)}
    if($originalIniSha -match '^[a-fA-F0-9]{64}$'){foreach($row in $storedRows){if($row.RelativePath -eq 'RDRVR.ini'){$row.InstalledSha256=$originalIniSha}}}
    if($version -and -not [IO.File]::Exists((Join-Path $store 'RDRVR_version.txt'))){
        [IO.File]::WriteAllText((Join-Path $store 'RDRVR_version.txt'),$version)
        $storedRows+=[pscustomobject]@{RelativePath='RDRVR_version.txt';HadOriginal=$false;InstalledSha256=(Get-FileHash -LiteralPath (Join-Path $store 'RDRVR_version.txt')).Hash}
    }
    $storedRows|
        Export-Csv -LiteralPath (Join-Path $store '.pcvrhub_rdrstore_ownership.csv') -NoTypeInformation -Encoding UTF8
    if($version){[IO.File]::WriteAllText((Join-Path $store '.pcvrhub_version'),$version)}
    @{Mod=$mod;Version=$version;Deployment=(Get-RdrProfileDeployment $store)}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $Game '.pcvrhub_rdr_profiles\active.json') -Encoding UTF8
}
function Save-RdrActive([string]$Game) {
    $active=Get-RdrActive $Game
    if(-not $active -or -not $active.Mod){return}
    $manifest=Join-Path $Game '.pcvrhub_rdractive_ownership.csv'
    if(-not [IO.File]::Exists($manifest)){throw 'The active RDRVR ownership record is missing. No files were switched.'}
    $store=Get-RdrProfileRoot $Game $active.Mod
    $rows=@(Import-Csv -LiteralPath $manifest)
    foreach($row in $rows){
        $rel=Assert-PCVROwnedRelativePath $row.RelativePath;$file=Join-OwnedRelativePath $Game $rel
        if([IO.File]::Exists($file)){
            # An updated parked package must never be overwritten by the old
            # live binary. Only user-edited defaults follow that live profile.
            $hash=(Get-FileHash -LiteralPath $file).Hash
            if($rel -eq 'RDRVR.ini' -and $row.InstalledSha256 -ne $hash){Copy-RdrProfileFile $file (Join-OwnedRelativePath $store $rel)}
            elseif($row.InstalledSha256 -and $row.InstalledSha256 -ne $hash){
                Copy-RdrProfileFile $file (Join-OwnedRelativePath (Get-RdrProfileRoot $Game ('retained-live-'+$active.Mod+'-'+[guid]::NewGuid().ToString('N'))) $rel)
            }
            $row.InstalledSha256=$hash
        }
    }
    $rows|Export-Csv -LiteralPath ($manifest+'.new') -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath ($manifest+'.new') -Destination $manifest -Force
}
function Set-RdrActive([string]$Game,[ValidateSet('main','fork','flat')][string]$Mod) {
    Assert-RdrClosed
    # Do not recursively inspect the multi-gigabyte original game. Only the
    # owned profile tree participates in deployment and rollback.
    $profiles=Join-Path $Game '.pcvrhub_rdr_profiles'
    [void][IO.Directory]::CreateDirectory($profiles)
    Assert-RdrProfileTree $profiles
    Import-RdrActive $Game
    $store=Get-RdrProfileRoot $Game $Mod
    if($Mod -ne 'flat' -and -not(Test-RdrProfilePayload $store $Mod)){throw 'The selected RDRVR profile is incomplete. Use its install / update action to repair it.'}
    $current=Get-RdrActive $Game
    $version=if($Mod -ne 'flat' -and [IO.File]::Exists((Join-Path $store '.pcvrhub_version'))){[IO.File]::ReadAllText((Join-Path $store '.pcvrhub_version')).Trim()}else{''}
    $deployment=Get-RdrProfileDeployment $store
    $extras=@(Get-RdrRuntimeExtras $Game)
    $expected=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($rel in @(Get-RdrProfileFiles $store)){[void]$expected.Add($rel)}
    $obsolete=@($extras|Where-Object {-not $expected.Contains($_)})
    if($current -and $current.Mod -eq $Mod -and $current.Version -eq $version -and $current.Deployment -eq $deployment -and -not $obsolete.Count -and (Test-RdrProfilePayload $Game $Mod)){return}
    if(-not [IO.Directory]::Exists($store)){[void][IO.Directory]::CreateDirectory($store)}
    $work=Join-Path ([IO.Path]::GetTempPath()) ('RdrSwitch-'+[guid]::NewGuid().ToString('N'))
    $originalExtras=Get-RdrProfileRoot $Game 'original-runtime-extras'
    $restoreExtras=@()
    if([IO.Directory]::Exists($originalExtras)){
        foreach($file in Get-ChildItem -LiteralPath $originalExtras -Recurse -File -Force){$restoreExtras+=$file.FullName.Substring($originalExtras.TrimEnd('\').Length+1)}
    }
    $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $Game -Stage $store -Identity rdractive -SnapshotRoot $work -ExtraPaths (@('.pcvrhub_rdr_profiles\active.json')+$extras+$restoreExtras)
    try{
        Save-RdrActive $Game
        if($current -and $current.Mod){
            $removed=Uninstall-OwnedModPayload -GameRoot $Game -Identity rdractive
            if($removed.Preserved){throw 'The active RDRVR files could not be parked safely.'}
        }
        if($Mod -ne 'flat'){
            # The publisher retires old preconverted shaders and simulator
            # overrides. Park surviving extras rather than delete user files.
            Park-RdrRuntimeExtras $Game
            $skip=@(Get-ChildItem -LiteralPath $store -Recurse -File -Force|ForEach-Object {$_.FullName.Substring($store.Length+1)}|Where-Object {$_ -like '.pcvrhub*'})
            [void](Install-OwnedModPayload -SourceRoot $store -GameRoot $Game -Identity rdractive -SkipRelativePaths $skip)
            if(-not(Test-RdrProfilePayload $Game $Mod)){throw 'The selected RDRVR runtime was not completely placed.'}
        }else{
            foreach($rel in $restoreExtras){
                if($rel -notmatch '^RDRVR_shaders[\\/]|^RDRVR_xr_runtime\.txt$'){throw 'Unexpected retained RDRVR runtime path.'}
                $live=Join-OwnedRelativePath $Game $rel
                if(-not [IO.File]::Exists($live)){Copy-RdrProfileFile (Join-OwnedRelativePath $originalExtras $rel) $live}
            }
        }
        @{Mod=$(if($Mod -eq 'flat'){''}else{$Mod});Version=$version;Deployment=(Get-RdrProfileDeployment $store)}|ConvertTo-Json|
            Set-Content -LiteralPath (Join-Path $Game '.pcvrhub_rdr_profiles\active.json') -Encoding UTF8
    }catch{Restore-PCVRPublisherZipSnapshot -GameRoot $Game -Snapshot $snapshot;throw}
    finally{
        $safe=[IO.Path]::GetFullPath($work)
        if($safe.StartsWith([IO.Path]::GetTempPath(),[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($safe) -match '^RdrSwitch-[a-f0-9]{32}$'){Remove-Item -LiteralPath $safe -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
function Install-RdrProfile([string]$Game,[string]$Stage,[string]$Mod,[string]$Version) {
    Assert-RdrClosed;Assert-RdrPathAncestors $Game;Assert-RdrProfileTree $Stage
    if(-not(Test-RdrProfilePayload $Stage $Mod)){throw 'The selected RDRVR package is incomplete.'}
    Import-RdrActive $Game
    $store=Get-RdrProfileRoot $Game $Mod;[void][IO.Directory]::CreateDirectory($store)
    Assert-RdrProfileTree $store
    $keep=@();$ini=Join-Path $store 'RDRVR.ini';$owned=Join-Path $store '.pcvrhub_rdrstore_ownership.csv'
    if([IO.File]::Exists($ini)){
        $row=@()
        if([IO.File]::Exists($owned)){$row=@(Import-Csv -LiteralPath $owned|Where-Object RelativePath -eq 'RDRVR.ini')}
        if($row.Count -ne 1 -or $row[0].InstalledSha256 -ne (Get-FileHash -LiteralPath $ini).Hash){$keep=@('RDRVR.ini')}
    }
    [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $store -Identity rdrstore -KeepExistingRelativePaths $keep)
    if(-not(Test-RdrProfilePayload $store $Mod)){throw 'The RDRVR profile copy is incomplete.'}
    # A profile update is install-only. The matching Play action deploys it.
}

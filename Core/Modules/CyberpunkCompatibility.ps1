# Frozen game-specific runtime. Future game patches need a separate profile.
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')

function Get-CyberpunkCompatibilityProfile {
    $components=@(
        @{Name='RED4ext';Version='1.30.0';Repo='wopss/RED4ext';Tag='v1.30.0';File='red4ext-1.30.0.zip';Marker='red4ext\RED4ext.dll';Identity='cyberpunk231_red4ext'},
        @{Name='Cyber Engine Tweaks';Version='1.37.1';Repo='maximegmd/CyberEngineTweaks';Tag='v1.37.1';File='cet_1.37.1.zip';Marker='bin\x64\plugins\cyber_engine_tweaks.asi';Identity='cyberpunk231_cet'},
        @{Name='redscript';Version='0.5.31';Repo='jac3km4/redscript';Tag='v0.5.31';File='redscript-v0.5.31-windows.zip';Marker='engine\tools\scc.exe';Identity='cyberpunk231_redscript'},
        @{Name='TweakXL';Version='1.11.5';Repo='psiberx/cp2077-tweak-xl';Tag='v1.11.5';File='TweakXL-1.11.5.zip';Marker='red4ext\plugins\TweakXL\TweakXL.dll';Identity='cyberpunk231_tweakxl'},
        @{Name='ArchiveXL';Version='1.27.5';Repo='psiberx/cp2077-archive-xl';Tag='v1.27.5';File='ArchiveXL-1.27.5.zip';Marker='red4ext\plugins\ArchiveXL\ArchiveXL.dll';Identity='cyberpunk231_archivexl'},
        @{Name='Codeware';Version='1.20.6';Repo='psiberx/cp2077-codeware';Tag='v1.20.6';File='Codeware-1.20.6.zip';Marker='red4ext\plugins\Codeware\Codeware.dll';Identity='cyberpunk231_codeware'}
    )
    foreach($component in $components){
        $component.GameVersion='2.31'
        $component.Pinned='https://github.com/'+$component.Repo+'/releases/download/'+$component.Tag+'/'+$component.File
        $component.Page='https://github.com/'+$component.Repo+'/releases/tag/'+$component.Tag
        $component.RequiredFiles=switch($component.Name){
            'RED4ext' {@($component.Marker,'bin\x64\winmm.dll')}
            'Cyber Engine Tweaks' {@($component.Marker,'bin\x64\version.dll','bin\x64\plugins\cyber_engine_tweaks\scripts\json\json.lua')}
            'redscript' {@($component.Marker,'engine\tools\scc_lib.dll','engine\config\base\scripts.ini')}
            'TweakXL' {@($component.Marker,'red4ext\plugins\TweakXL\Data\ExtraFlats.dat','red4ext\plugins\TweakXL\Data\InheritanceMap.dat','red4ext\plugins\TweakXL\Scripts\TweakXL.Global.reds','red4ext\plugins\TweakXL\Scripts\TweakXL.reds')}
            'ArchiveXL' {@($component.Marker,'red4ext\plugins\ArchiveXL\Bundle\ArchiveXL.archive','red4ext\plugins\ArchiveXL\Scripts\ArchiveXL.DynamicAppearance.reds','red4ext\plugins\ArchiveXL\Scripts\ArchiveXL.Global.reds','red4ext\plugins\ArchiveXL\Scripts\ArchiveXL.reds')}
            'Codeware' {@($component.Marker,'red4ext\plugins\Codeware\Data\KnownHashes.txt','red4ext\plugins\Codeware\Scripts\Codeware.Global.reds','red4ext\plugins\Codeware\Scripts\Codeware.Localization.reds','red4ext\plugins\Codeware\Scripts\Codeware.reds','red4ext\plugins\Codeware\Scripts\Codeware.UI.reds','red4ext\plugins\Codeware\Scripts\Codeware.UI.TextInput.reds')}
        }
    }
    return @{Id='cyberpunk-2.31-port-0.1.8-r1';GameVersion='2.31';ModVersion='0.1.8';ModUrl='https://github.com/dariulone/cyberpunk-vr-port/releases/download/0.1.8/CyberpunkVRPort-0.1.8.zip';ModPage='https://github.com/dariulone/cyberpunk-vr-port/releases/tag/0.1.8';Components=$components}
}

function Get-CyberpunkBinaryVersion([string]$Path){
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    $info=[Diagnostics.FileVersionInfo]::GetVersionInfo($Path)
    foreach($candidate in @($info.ProductVersion,$info.FileVersion)){
        $match=[regex]::Match([string]$candidate,'\d+\.\d+\.\d+')
        if($match.Success){return $match.Value}
    }
    return ''
}

function Get-CyberpunkFixedComponentState {
    param([string]$GameRoot,[hashtable]$Component)
    $marker=Join-OwnedRelativePath $GameRoot $Component.Marker
    if(-not(Test-Path -LiteralPath $marker -PathType Leaf)){return 'missing'}
    $version=Get-CyberpunkBinaryVersion $marker
    $moving=($Component.GameVersion -eq '2.5')
    if($version -and ((-not $moving -and $version -ne $Component.Version) -or ($moving -and [version]$version -lt [version]$Component.Version))){return ('version '+$version+'; requires '+$Component.Version)}
    foreach($relative in $Component.RequiredFiles){
        if(-not(Test-Path -LiteralPath (Join-OwnedRelativePath $GameRoot $relative) -PathType Leaf)){return ('missing '+$relative)}
    }
    # Versionless redscript and secondary scripts need a local install proof.
    # These hashes describe installed ownership; they never gate a download.
    $manifest=Join-Path $GameRoot ('.pcvrhub_'+$Component.Identity+'_ownership.csv')
    $receipt=Join-Path $GameRoot ('.pcvrhub_'+$Component.Identity+'_version.json')
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf) -or -not(Test-Path -LiteralPath $receipt -PathType Leaf)){return 'not yet checked for 2.31'}
    try{
        $saved=Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop|ConvertFrom-Json
        if($saved.GameVersion -ne $Component.GameVersion){return 'different compatibility profile'}
        if((-not $moving -and $saved.Version -ne $Component.Version) -or ($moving -and [version]$saved.Version -lt [version]$Component.Version)){return 'different compatibility profile'}
        $rows=@(Import-Csv -LiteralPath $manifest -ErrorAction Stop)
        if(-not($rows|Where-Object {$_.RelativePath -eq $Component.Marker})){return 'runtime proof missing'}
        foreach($row in $rows){
            $path=Join-OwnedRelativePath $GameRoot $row.RelativePath
            if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return ('missing '+$row.RelativePath)}
            # Settings are user-owned even when initially supplied by us.
            if($row.RelativePath -match '(?i)\.(ini|json|ya?ml|toml)$'){continue}
            if((Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash -ne $row.InstalledSha256){return ('changed '+$row.RelativePath)}
        }
        if($moving){$Component.Version=[string]$saved.Version}
        return 'compatible'
    }catch{return 'runtime proof needs repair'}
}

function Install-CyberpunkFixedPayload {
    param([string]$SourceRoot,[string]$GameRoot,[hashtable]$Component)
    $marker=Join-OwnedRelativePath $SourceRoot $Component.Marker
    if(-not(Test-Path -LiteralPath $marker -PathType Leaf)){throw ($Component.Name+' package has no required runtime.')}
    $version=Get-CyberpunkBinaryVersion $marker
    if($version -and $version -ne $Component.Version){
        if($Component.GameVersion -eq '2.5' -and [version]$version -ge [version]$Component.Version){$Component.Version=$version}
        else{throw ($Component.Name+' '+$version+' does not match the required '+$Component.Version+' runtime for game '+$Component.GameVersion+'. Use the linked release; Retry remains available.')}
    }
    foreach($relative in $Component.RequiredFiles){
        if(-not(Test-Path -LiteralPath (Join-OwnedRelativePath $SourceRoot $relative) -PathType Leaf)){throw ($Component.Name+' package is missing required runtime file '+$relative+'. No game files were changed.')}
    }
    $source=[IO.Path]::GetFullPath($SourceRoot).TrimEnd('\')
    $files=@(Get-ChildItem -LiteralPath $source -File -Recurse -ErrorAction Stop)
    $paths=@($files|ForEach-Object {Assert-PCVROwnedRelativePath $_.FullName.Substring($source.Length+1)})
    $identity=$Component.Identity
    $manifest='.pcvrhub_'+$identity+'_ownership.csv'
    $receipt='.pcvrhub_'+$identity+'_version.json'
    $backup='.pcvrhub_'+$identity+'_backup'
    $keep=@($paths|Where-Object {$_ -match '(?i)\.(ini|json|ya?ml|toml)$' -and (Test-Path -LiteralPath (Join-OwnedRelativePath $GameRoot $_) -PathType Leaf)})
    # Save the exact pre-repair state, including manifests, before ANY writes.
    # Recovery stays outside loader paths and never includes unrelated mods.
    $recovery=Join-Path $GameRoot ('.pcvrhub_cyberpunk231_recovery\'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($recovery)
    $snapshots=[Collections.Generic.List[object]]::new()
    $priorPaths=@()
    $priorManifest=Join-Path $GameRoot $manifest
    if(Test-Path -LiteralPath $priorManifest -PathType Leaf){
        $priorPaths=@(Import-Csv -LiteralPath $priorManifest -ErrorAction Stop|ForEach-Object {Assert-PCVROwnedRelativePath $_.RelativePath})
    }
    $ownedPaths=@($paths)+@($priorPaths)
    $all=@($ownedPaths)+@($manifest,$receipt)+@($ownedPaths|ForEach-Object {$backup+'\'+$_})
    try{
        foreach($relative in $all|Select-Object -Unique){
            $target=Join-OwnedRelativePath $GameRoot $relative
            $exists=Test-Path -LiteralPath $target -PathType Leaf
            $saved=Join-OwnedRelativePath $recovery ('files\'+$relative)
            if($exists){[void][IO.Directory]::CreateDirectory((Split-Path $saved -Parent));[IO.File]::Copy($target,$saved,$false)}
            $snapshots.Add([pscustomobject]@{RelativePath=$relative;Existed=$exists})
        }
        $snapshots|Export-Csv -LiteralPath (Join-Path $recovery 'before.csv') -NoTypeInformation -Encoding UTF8
        [void](Install-OwnedModPayload -SourceRoot $SourceRoot -GameRoot $GameRoot -Identity $identity -KeepExistingRelativePaths $keep -ReplaceChangedOwnedRelativePaths $paths)
        $record=@{GameVersion=$Component.GameVersion;Version=$Component.Version;Source=$Component.Pinned}
        $record|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $GameRoot $receipt) -Encoding UTF8 -ErrorAction Stop
        $state=Get-CyberpunkFixedComponentState -GameRoot $GameRoot -Component $Component
        if($state -ne 'compatible'){throw ($Component.Name+' verification: '+$state)}
    }catch{
        $failure=$_
        foreach($snapshot in $snapshots){
            $target=Join-OwnedRelativePath $GameRoot $snapshot.RelativePath
            if($snapshot.Existed){
                [void][IO.Directory]::CreateDirectory((Split-Path $target -Parent))
                [IO.File]::Copy((Join-OwnedRelativePath $recovery ('files\'+$snapshot.RelativePath)),$target,$true)
            }elseif(Test-Path -LiteralPath $target -PathType Leaf){[IO.File]::Delete($target)}
        }
        throw $failure
    }
}

function Get-CyberpunkFixedRuntimeProblems([string]$GameRoot){
    foreach($component in (Get-CyberpunkRouteProfile).Components){
        if((Get-CyberpunkFixedComponentState -GameRoot $GameRoot -Component $component) -ne 'compatible'){Write-Output $component.Marker}
    }
}

function Save-CyberpunkCompatibilityReceipt([string]$GameRoot){
    $problems=@(Get-CyberpunkFixedRuntimeProblems $GameRoot)
    if($problems.Count){throw 'The fixed Cyberpunk 2.31 frameworks are incomplete. Repair them before marking installation complete.'}
    $profile=Get-CyberpunkRouteProfile
    $record=@{Profile=$profile.Id;GameVersion=$profile.GameVersion;VRModVersion=$profile.ModVersion;Dependencies=@($profile.Components|ForEach-Object {@{Name=$_.Name;Version=$_.Version}})}
    if($profile.InputLoader){
        if((Get-CyberpunkFixedComponentState -GameRoot $GameRoot -Component $profile.InputLoader) -ne 'compatible'){throw 'Input Loader needs repair before this route can be marked complete.'}
        $record.InputLoader=@{Version=$profile.InputLoader.Version;Manifest=('.pcvrhub_'+$profile.InputLoader.Identity+'_ownership.csv');RequiredFiles=$profile.InputLoader.RequiredFiles}
    }
    if($profile.GameVersion -eq '2.5' -and $profile.ModSettings -and (Test-Path -LiteralPath (Join-OwnedRelativePath $GameRoot $profile.ModSettings.Marker) -PathType Leaf)){
        if((Get-CyberpunkFixedComponentState -GameRoot $GameRoot -Component $profile.ModSettings) -ne 'compatible'){throw 'Mod Settings needs its game-2.5 update before marking this route complete.'}
        $record.ModSettings=@{Version=$profile.ModSettings.Version;Manifest=('.pcvrhub_'+$profile.ModSettings.Identity+'_ownership.csv');RequiredFiles=$profile.ModSettings.RequiredFiles}
    }
    $profileFile=if($profile.GameVersion -eq '2.5'){'.pcvrhub_cyberpunk_25_profile.json'}else{'.pcvrhub_cyberpunk_231_profile.json'}
    $path=Join-Path $GameRoot $profileFile
    $record|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($path+'.new') -Encoding UTF8 -ErrorAction Stop
    Move-Item -LiteralPath ($path+'.new') -Destination $path -Force -ErrorAction Stop
}

if(-not(Get-Command Get-CyberpunkRouteProfile -ErrorAction SilentlyContinue)){
 function Get-CyberpunkRouteProfile { if($script:CyberpunkActiveProfile){return $script:CyberpunkActiveProfile};Get-CyberpunkCompatibilityProfile }
}

# Dalamud owns the plugin directory; the Hub only reads its installed proof.
function global:Get-PCVRFfxivPluginProof {
    param([string[]]$ProfileBases=@($env:APPDATA,$env:LOCALAPPDATA))
    $candidates=@()
    foreach($base in @($ProfileBases|Where-Object {$_}|Select-Object -Unique)){
        $root=Join-Path $base 'XIVLauncher\installedPlugins'
        if(-not [IO.Directory]::Exists($root)){continue}
        foreach($dll in @(Get-ChildItem -LiteralPath $root -Filter 'FfxivVR.dll' -File -Recurse -ErrorAction SilentlyContinue)){
            try{
                $info=Get-Content -LiteralPath (Join-Path $dll.DirectoryName 'FfxivVR.json') -Raw -ErrorAction Stop|ConvertFrom-Json
                $version=[version]([string]$info.AssemblyVersion)
                $files=@('FfxivVR.dll','FfxivVR.json','FfxivVR.deps.json','ffxiv_vr_native.dll','openxr_loader.dll')|ForEach-Object {Join-Path $dll.DirectoryName $_}
                if($info.InternalName -ne 'FfxivVR' -or @($files|Where-Object {-not [IO.File]::Exists($_) -or ([IO.FileInfo]$_).Length -eq 0}).Count){continue}
                $candidates+=[pscustomobject]@{Dll=$dll;Version=$version;Files=@($files)}
            }catch{continue}
        }
    }
    return @($candidates|Sort-Object Version -Descending|Select-Object -First 1)
}

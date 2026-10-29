# Compatibility checks shared by installation and both Hub/Desktop launchers.
function Get-CyberpunkIncompatibleOccluderScripts {
    param([string]$GameRoot)
    $scripts=[IO.Path]::Combine($GameRoot,'r6\scripts')
    if(-not(Test-Path -LiteralPath $scripts -PathType Container)){return}
    if((Get-Item -LiteralPath $scripts).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'The linked script folder needs manual handling. No scripts were moved.'}
    foreach($file in Get-ChildItem -LiteralPath $scripts -Filter 'MoreOccluders.reds' -File -Recurse -ErrorAction Stop){
        $text=[IO.File]::ReadAllText($file.FullName)
        $text=[regex]::Replace($text,'(?s)/\*.*?\*/|(?m)//[^\r\n]*','')
        foreach($declaration in [regex]::Matches($text,'\blet\s+(\w+)\s*=\s*[^;\r\n]+\bas\s+worldInstancedMeshNode\b')){
            if($text -notmatch ('\b'+[regex]::Escape($declaration.Groups[1].Value)+'\s*\.\s*occluderType\b')){continue}
            $cursor=$file
            while($cursor -and $cursor.FullName.Length -ge $scripts.Length){
                if($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'A linked More Occluders script needs manual handling. No scripts were moved.'}
                $cursor=if($cursor -is [IO.FileInfo]){$cursor.Directory}else{$cursor.Parent}
            }
            [pscustomobject]@{Path=$file.FullName;RelativePath=$file.FullName.Substring([IO.Path]::GetFullPath($GameRoot).TrimEnd('\').Length+1);Reason='worldInstancedMeshNode.occluderType was removed in game 2.5'}
            break
        }
    }
}

function Move-CyberpunkIncompatibleOccluders {
    param([string]$GameRoot)
    $exe=[IO.Path]::Combine($GameRoot,'bin\x64\Cyberpunk2077.exe')
    if(-not [IO.File]::Exists($exe)){return}
    $version=[Diagnostics.FileVersionInfo]::GetVersionInfo($exe).ProductVersion
    if(([regex]::Match([string]$version,'^\d+\.\d+')).Value -ne '2.5'){return}
    $files=@(Get-CyberpunkIncompatibleOccluderScripts -GameRoot $GameRoot)
    if(-not $files.Count){return}
    if(Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue){throw 'Close Cyberpunk before updating incompatible scripts.'}
    $backup=[IO.Path]::Combine($GameRoot,'.pcvrhub_cyberpunk_retired','more-occluders-game25-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($backup)
    $moves=@($files|ForEach-Object {[pscustomobject]@{OriginalPath=$_.Path;BackupPath=[IO.Path]::Combine($backup,$_.RelativePath);Sha256=(Get-FileHash -LiteralPath $_.Path).Hash;Reason=$_.Reason}})
    $manifest=[IO.Path]::Combine($backup,'restore.json')
    $moves|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $manifest -Encoding UTF8 -ErrorAction Stop
    try{
        foreach($item in $moves){
            [void][IO.Directory]::CreateDirectory((Split-Path $item.BackupPath -Parent))
            Move-Item -LiteralPath $item.OriginalPath -Destination $item.BackupPath -ErrorAction Stop
            if((Get-FileHash -LiteralPath $item.BackupPath).Hash -ne $item.Sha256){throw 'The More Occluders backup did not verify.'}
        }
    }catch{
        foreach($item in $moves){if([IO.File]::Exists($item.BackupPath) -and -not [IO.File]::Exists($item.OriginalPath)){Move-Item -LiteralPath $item.BackupPath -Destination $item.OriginalPath -ErrorAction Stop}}
        throw
    }
    Write-Host '  [OK] Incompatible More Occluders script backed up and disabled for game 2.5.' -ForegroundColor Green
    return $moves
}

function Get-CyberpunkCurrentStartupProblems {
    param([string]$GameRoot,[string]$GameVersion)
    if($GameVersion -ne '2.5'){return}
    $modSettings=[IO.Path]::Combine($GameRoot,'red4ext\plugins\mod_settings\mod_settings.dll')
    if([IO.File]::Exists($modSettings)){
        $v=([regex]::Match([string][Diagnostics.FileVersionInfo]::GetVersionInfo($modSettings).FileVersion,'\d+\.\d+\.\d+')).Value
        if($v -and [version]$v -lt [version]'0.2.22'){Write-Output ('Mod Settings '+$v+' is incompatible with game 2.5. Run the Hub Current installer to update it; your settings and original files are kept.')}
    }
    if(@(Get-CyberpunkIncompatibleOccluderScripts -GameRoot $GameRoot).Count){Write-Output 'The installed More Occluders script cannot compile on game 2.5. Run the Hub Current installer to back it up and disable it. It remains supported by the separate 2.31 Depot.'}
}

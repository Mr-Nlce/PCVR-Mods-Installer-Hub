# Original game identity shared by scanning, Locate and installer discovery.
# This module only reads game files. It never loads the UI or changes state.
$global:PCVRGameProofDefinitionFile = Join-Path $PSScriptRoot 'GameInstallProofs.psd1'
$global:PCVRGameContainerProofSource = Join-Path $PSScriptRoot 'GameContainerProof.cs'

function global:Test-PCVRGameContainerProof {
    param([string]$Root, $Container, [switch]$QueueOnly)
    if (-not ('PCVRGameContainerProof' -as [type])) {
        Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
        if($PSVersionTable.PSEdition -eq 'Core'){
            Add-Type -Path $global:PCVRGameContainerProofSource -ErrorAction Stop
        }else{
            Add-Type -Path $global:PCVRGameContainerProofSource -ReferencedAssemblies @('System.dll','System.Core.dll','System.IO.Compression.dll','System.IO.Compression.FileSystem.dll') -ErrorAction Stop
        }
    }
    $entries=[string[]]@(foreach($n in @($Container.Entries)){if(-not [string]::IsNullOrWhiteSpace([string]$n)){[string]$n}})
    $excluded=[string[]]@(foreach($n in @($Container.Excluded)){if(-not [string]::IsNullOrWhiteSpace([string]$n)){[string]$n}})
    $maps=[string[]]@(foreach($n in @($Container.Maps)){if(-not [string]::IsNullOrWhiteSpace([string]$n)){[string]$n}})
    if (@($entries + $maps | Select-Object -Unique).Count -lt 2) { return $false }
    $paths=[Collections.Generic.List[string]]::new()
    foreach ($relative in (([string]$Container.File) -split '\|')) {
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)|[?*]') { continue }
        $paths.Add([IO.Path]::Combine($Root,$relative.Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar)))
    }
    # Publishers let users select their own ROM names. Search only explicitly
    # documented local directories/extensions, with no recursive disk scan.
    $folders=[Collections.Generic.List[string]]::new()
    foreach($directory in @($Container.Directories)){
        $relative=[string]$directory
        if(-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)|[?*]'){continue}
        $folder=[IO.Path]::Combine($Root,$relative.Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar))
        if(-not [IO.Directory]::Exists($folder)){continue}
        $folders.Add($folder)
    }
    # Minecraft launchers place client JARs one level below versions. Only
    # explicitly declared parents are inspected, never a recursive home scan.
    foreach($directory in @($Container.ChildDirectories)){
        $relative=[string]$directory
        if(-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)|[?*]'){continue}
        $parent=[IO.Path]::Combine($Root,$relative.Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar))
        if(-not [IO.Directory]::Exists($parent)){continue}
        $children=0
        try{foreach($child in [IO.Directory]::EnumerateDirectories($parent,'*',[IO.SearchOption]::TopDirectoryOnly)){
            if(++$children -gt 128){break}
            if(([IO.File]::GetAttributes($child) -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
            $folders.Add($child)
        }}catch{}
    }
    $inspected=0
    foreach($folder in $folders){
        foreach($pattern in @($Container.Patterns)){
            if([string]$pattern -notmatch '^\*\.[a-zA-Z0-9]{1,8}$'){continue}
            try{
                foreach($path in [IO.Directory]::EnumerateFiles($folder,[string]$pattern,[IO.SearchOption]::TopDirectoryOnly)){
                    $inspected++;if($inspected -gt 128){break}
                    $paths.Add($path)
                }
            }catch{}
            if($inspected -gt 128){break}
        }
        if($inspected -gt 128){break}
    }
    foreach($path in $paths){
        if($QueueOnly){
            if([IO.File]::Exists($path)){[PCVRGameContainerProof]::Warm($path,[string]$Container.Format,$entries,$excluded,$maps)}
            continue
        }
        if ([PCVRGameContainerProof]::Test($path, [string]$Container.Format, $entries, $excluded, $maps)) { return $true }
    }
    return $false
}

function global:Start-PCVRRecordedContainerWarm {
    param($Games,$Envelope,[string[]]$SteamLibraries=@())
    if(-not $Envelope -or -not $Envelope.Data.games){return}
    $queued=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($game in $Games){
        if(-not $game.Id -or -not $game.OriginalGameProofSets){continue}
        $record=$Envelope.Data.games[[string]$game.Id]
        $candidates=[Collections.Generic.List[string]]::new()
        if($record -and $record.values){foreach($key in @('installed_path','base_game_path','user_located')){$candidates.Add([string]$record.values[$key])}}
        if($game.SteamFolder){foreach($library in $SteamLibraries){$candidates.Add([IO.Path]::Combine($library,'steamapps','common',[string]$game.SteamFolder))}}
        foreach($root in $candidates){
            if(-not $root -or -not [IO.Directory]::Exists($root) -or -not $queued.Add(([string]$game.Id)+'|'+$root)){continue}
            foreach($set in $game.OriginalGameProofSets){
                foreach($container in @($set.Containers)){
                    if($container){[void](Test-PCVRGameContainerProof -Root $root -Container $container -QueueOnly)}
                }
            }
        }
    }
}

# A dragged executable or data file may sit below the original game root.
# Check only its own ancestors; never search unrelated disks or execute files.
function global:Resolve-PCVRGameInstallRoot {
    param([string]$GameId,[string]$Path,[switch]$AllMatches)
    if (-not (Get-PCVRGameInstallProof -GameId $GameId) -or [string]::IsNullOrWhiteSpace($Path)) { return $null }
    try {
        $candidate=[IO.Path]::GetFullPath($Path.Trim().Trim('"'))
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $candidate=[IO.Path]::GetDirectoryName($candidate) }
        for ($depth=0; $depth -lt 12 -and $candidate; $depth++) {
            if (Test-PCVRGameInstallProof -GameId $GameId -Root $candidate) {
                if ($AllMatches) { Write-Output $candidate } else { return $candidate }
            }
            $parent=[IO.Path]::GetDirectoryName($candidate.TrimEnd([char[]]'\/'))
            if (-not $parent -or $parent -eq $candidate) { break }
            $candidate=$parent
        }
    } catch {}
    return $null
}

# Runtime-only callers (for example a separate VR launcher) keep their own
# evidence. Only a probe naming an original file opts a remembered path into
# original-game validation; the store discovery entry point requires it itself.
function global:Test-PCVROriginalGameProbe {
    param([string]$GameId,[string[]]$ProbeFiles)
    $contract=Get-PCVRGameInstallProof -GameId $GameId
    if (-not $contract) { return $false }
    foreach ($group in @($ProbeFiles)) {
        foreach ($probe in ($group -split '\|')) {
            if (-not $probe) { continue }
            $leaf=($probe -split '[\\/]')[-1]
            foreach ($files in @($contract.Files)) {
                foreach ($file in ($files -split '\|')) {
                    if (($file -split '[\\/]')[-1] -ieq $leaf) { return $true }
                }
            }
        }
    }
    return $false
}

function global:Resolve-PCVRInstallerOriginalFolder {
    param([string]$GameId,[string]$Path,[string[]]$ProbeFiles=@(),[string]$Subdir='')
    foreach ($root in @(Resolve-PCVRGameInstallRoot -GameId $GameId -Path $Path -AllMatches)) {
    if (-not $root) { continue }
    $folders=[Collections.Generic.List[string]]::new()
    if ($Subdir) {
        $folders.Add([IO.Path]::Combine($root,$Subdir))
        # Store discovery may already return the executable subdirectory.
        # Still require both the complete original proof and caller probes.
        if (@($ProbeFiles | Where-Object { $_ }).Count) { $folders.Add($root) }
    }
    else {
        $folders.Add($root)
        # The caller's probe remains relative to its returned install folder.
        # Resolve known nested game EXEs without changing that public contract.
        $contract=Get-PCVRGameInstallProof -GameId $GameId
        foreach ($group in @($contract.Files)) {
            foreach ($relative in ($group -split '\|')) {
                foreach ($probeGroup in @($ProbeFiles)) {
                    foreach ($probe in ($probeGroup -split '\|')) {
                        $normalized=$relative.Replace('/','\');$suffix=$probe.Replace('/','\')
                        if ($suffix -and $normalized.EndsWith(('\'+$suffix),[StringComparison]::OrdinalIgnoreCase)) {
                            $prefix=$relative.Substring(0,$relative.Length-$probe.Length).TrimEnd([char[]]'\/')
                            $folders.Add([IO.Path]::Combine($root,$prefix))
                        }
                    }
                }
            }
        }
    }
    foreach ($folder in @($folders | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $complete=$true
        foreach ($group in @($ProbeFiles)) {
            if (-not $group) { continue }
            $found=$false
            foreach ($probe in ($group -split '\|')) {
                if (Test-Path -LiteralPath ([IO.Path]::Combine($folder,$probe)) -PathType Leaf) { $found=$true; break }
            }
            if (-not $found) { $complete=$false; break }
        }
        if ($complete) { return $folder }
    }
    }
    return $null
}

# Windows PowerShell 5 limits SafeGetValue over a complete large data table.
# Validate the single static root, then evaluate each game's literal table
# independently. SafeGetValue still rejects commands and dynamic expressions.
function global:Read-PCVRGameInstallProofDefinitions {
    param([Parameter(Mandatory=$true)][string]$Path)
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile([IO.Path]::GetFullPath($Path),[ref]$tokens,[ref]$errors)
    if($errors.Count){throw $errors[0]}
    $statements=@($ast.EndBlock.Statements)
    if($ast.ParamBlock -or $ast.BeginBlock -or $ast.ProcessBlock -or $statements.Count -ne 1 -or
       $statements[0] -isnot [Management.Automation.Language.PipelineAst] -or $statements[0].PipelineElements.Count -ne 1 -or
       $statements[0].PipelineElements[0] -isnot [Management.Automation.Language.CommandExpressionAst] -or $statements[0].PipelineElements[0].Redirections.Count -or
       $statements[0].PipelineElements[0].Expression -isnot [Management.Automation.Language.HashtableAst]){throw 'Game proofs must be a single static data table.'}
    $root=$statements[0].PipelineElements[0].Expression
    if($root.KeyValuePairs.Count -ne 1 -or $root.KeyValuePairs[0].Item1.SafeGetValue() -cne 'Games'){throw 'Game proofs require exactly the Games table.'}
    $value=$root.KeyValuePairs[0].Item2
    if($value -isnot [Management.Automation.Language.PipelineAst] -or $value.PipelineElements.Count -ne 1 -or
       $value.PipelineElements[0] -isnot [Management.Automation.Language.CommandExpressionAst] -or $value.PipelineElements[0].Redirections.Count -or
       $value.PipelineElements[0].Expression -isnot [Management.Automation.Language.HashtableAst]){throw 'Games must be a literal table.'}
    $games=@{}
    foreach($pair in $value.PipelineElements[0].Expression.KeyValuePairs){
        $id=$pair.Item1.SafeGetValue()
        if($id -isnot [string] -or $id -notmatch '^[a-z0-9][a-z0-9._-]*$' -or $games.ContainsKey($id)){throw 'Invalid or duplicate original-game identity.'}
        $definition=$pair.Item2.SafeGetValue()
        if($definition -isnot [hashtable]){throw 'Each game proof must be a literal table.'}
        $games[$id]=$definition
    }
    return @{Games=$games}
}

function global:Get-PCVRGameInstallProof {
    param([string]$GameId)
    if (-not $GameId) { return $null }
    if (-not $global:PCVRGameInstallProofDefinitions) {
        $global:PCVRGameInstallProofDefinitions = Read-PCVRGameInstallProofDefinitions -Path $global:PCVRGameProofDefinitionFile
    }
    return $global:PCVRGameInstallProofDefinitions.Games[$GameId]
}

# A standalone wrapper does not inherit the Hub's process environment. Use
# declared app IDs and the actual calling installer folder to select the same
# original-game contract. Ambiguous shared wrappers never guess a route.
function global:Resolve-PCVRInstallerGameId {
    param([string]$GameId='',[string]$AppId='',[string[]]$ProbeFiles=@(),[string[]]$CallerPaths=@())
    $explicit=if($GameId){$GameId.Trim()}else{(''+$env:PCVR_HUB_GAME_ID).Trim()}
    if($explicit){return $explicit}
    if(-not $global:PCVRGameInstallProofDefinitions){[void](Get-PCVRGameInstallProof -GameId '__load_definitions__')}
    if(-not $CallerPaths){$CallerPaths=@(Get-PSCallStack | ForEach-Object {$_.ScriptName} | Where-Object {$_})}
    $folders=@(foreach($path in $CallerPaths){try{[IO.Path]::GetFileName([IO.Path]::GetDirectoryName($path))}catch{}})
    $matching=@(foreach($id in $global:PCVRGameInstallProofDefinitions.Games.Keys){
        $contract=$global:PCVRGameInstallProofDefinitions.Games[$id]
        $appMatches=$AppId -and $AppId -in @($contract.AppIds)
        $callerMatches=@($contract.InstallerFolders | Where-Object {$_ -in $folders}).Count -gt 0
        if(-not $appMatches -and -not $callerMatches){continue}
        if($AppId -and -not $appMatches){continue}
        if($ProbeFiles.Count -and -not(Test-PCVROriginalGameProbe -GameId $id -ProbeFiles $ProbeFiles)){continue}
        $id
    })
    if($matching.Count -eq 1){return [string]$matching[0]}
    return $null
}

# Engine configuration is a location source only. A configured path must
# independently contain this title's complete original-data proof.
function global:Get-PCVRConfiguredOriginalGameRoot {
    param([string]$GameId,[string]$RuntimeRoot='')
    $contract=Get-PCVRGameInstallProof -GameId $GameId
    foreach ($source in @($contract.ConfiguredRoots)) {
        if (-not $source -or $source.Format -notin @('INI','JSON','Directory') -or $source.Root -notin @('UserProfile','AppData','LocalAppData','Runtime')) { continue }
        try {
            $relative=[string]$source.File
            if(-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)|[?*]'){continue}
            # A runtime-specific profile belongs only to its declared engine.
            # Without a runtime candidate this remains an original location
            # source, never evidence that either VR route is installed.
            if($RuntimeRoot -and $source.RuntimeFiles){
                $matchingRuntime=$true
                foreach($group in @($source.RuntimeFiles)){
                    $found=$false
                    foreach($name in ([string]$group -split '\|')){
                        if($name -and -not [IO.Path]::IsPathRooted($name) -and $name -notmatch '(^|[\\/])\.\.([\\/]|$)' -and [IO.File]::Exists([IO.Path]::Combine($RuntimeRoot,$name))){$found=$true;break}
                    }
                    if(-not $found){$matchingRuntime=$false;break}
                }
                if(-not $matchingRuntime){continue}
            }
            $profile=switch([string]$source.Root){
                'UserProfile' {if($env:USERPROFILE){$env:USERPROFILE}else{[Environment]::GetFolderPath('UserProfile')}}
                'AppData' {if($env:APPDATA){$env:APPDATA}else{[Environment]::GetFolderPath('ApplicationData')}}
                'LocalAppData' {if($env:LOCALAPPDATA){$env:LOCALAPPDATA}else{[Environment]::GetFolderPath('LocalApplicationData')}}
                'Runtime' {$RuntimeRoot}
            }
            if (-not $profile) { continue }
            $config=[IO.Path]::Combine($profile,$relative)
            if ($global:HubFileSystemLabRoot) {
                $boundary=[IO.Path]::GetFullPath($global:HubFileSystemLabRoot).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
                if (-not [IO.Path]::GetFullPath($config).StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)) { continue }
            }
            if($source.Format -eq 'Directory'){
                if(Test-PCVRGameInstallProof -GameId $GameId -Root $config){return $config}
                continue
            }
            $file=[IO.FileInfo]::new($config)
            if (-not $file.Exists -or $file.Length -gt 1048576) { continue }
            $lines=@()
            if($source.Format -eq 'JSON'){
                $settings=[IO.File]::ReadAllText($config)|ConvertFrom-Json -ErrorAction Stop
                # Exact publisher property only: a dotted property name is
                # not interpreted as code or a guessed traversal expression.
                $property=$settings.PSObject.Properties[[string]$source.Key]
                if(-not $property -or $property.Value -isnot [string]){continue}
                $lines=@(('['+[string]$source.Section+']'),([string]$source.Key+'='+[string]$property.Value))
            }else{$lines=[IO.File]::ReadAllLines($config)}
            $section=''
            foreach ($line in $lines) {
                if ($line -match '^\s*\[(?<section>[^\]]+)\]\s*$') { $section=$Matches.section.Trim(); continue }
                if ($section -ine [string]$source.Section -or $line -match '^\s*[;#]' -or $line -notmatch '^\s*(?<key>[^=]+?)\s*=\s*(?<value>.*?)\s*$') { continue }
                if ($Matches.key.Trim() -ine [string]$source.Key) { continue }
                $candidate=$Matches.value.Trim().Trim('"',"'")
                if($source.Escape -eq 'Backslash'){
                    $decoded=[Text.StringBuilder]::new()
                    for($i=0;$i -lt $candidate.Length;$i++){
                        $c=$candidate[$i]
                        if($c -eq '\' -and $i+1 -lt $candidate.Length){
                            $i++;$next=$candidate[$i]
                            switch($next){
                                'n' {[void]$decoded.Append("`n")}
                                'r' {[void]$decoded.Append("`r")}
                                '\' {[void]$decoded.Append('\')}
                                default {[void]$decoded.Append('\');[void]$decoded.Append($next)}
                            }
                        }else{[void]$decoded.Append($c)}
                    }
                    $candidate=$decoded.ToString()
                }
                if($candidate -match '[\x00\r\n]'){continue}
                if (-not [IO.Path]::IsPathRooted($candidate) -or $candidate -match '^[\\/]{2}') { continue }
                if ($global:HubFileSystemLabRoot -and -not [IO.Path]::GetFullPath($candidate).StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)) { continue }
                if($source.ValueType -eq 'File'){
                    if(-not [IO.File]::Exists($candidate)){continue}
                    $parent=[IO.Path]::GetDirectoryName($candidate);$exactFile=[IO.Path]::GetFileName($candidate);$selectedVerified=$false
                    foreach($set in @($contract.FileSets)){
                        foreach($container in @($set.Containers)){
                            if(-not $container){continue}
                            $selected=$container.Clone();$selected.File=$exactFile;$selected.Directories=@();$selected.Patterns=@()
                            if(Test-PCVRGameContainerProof -Root $parent -Container $selected){$selectedVerified=$true;break}
                        }
                        if($selectedVerified){break}
                    }
                    if(-not $selectedVerified){continue}
                    $candidate=$parent
                }
                if (Test-PCVRGameInstallProof -GameId $GameId -Root $candidate) { return $candidate }
            }
        } catch {}
    }
    return $null
}

# Some publishers version the names of their original data/index pairs.
# Match only a declared content family in its exact directory, never audio,
# arbitrary archives or a similarly named sibling game.
function global:Test-PCVROriginalArchivePair {
    param([string]$Root,$Pair)
    try {
        $relative=[string]$Pair.Directory
        $dataExtension=[string]$Pair.DataExtension
        $indexExtension=[string]$Pair.IndexExtension
        $pattern=[string]$Pair.StemPattern
        if(-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)|[?*]' -or
           $dataExtension -notmatch '^\.[a-z0-9]{1,8}$' -or $indexExtension -notmatch '^\.[a-z0-9]{1,8}$' -or
           $dataExtension -ieq $indexExtension -or -not $pattern -or $pattern.Length -gt 256){return $false}
        $folder=[IO.Path]::Combine($Root,$relative.Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar))
        if(-not [IO.Directory]::Exists($folder)){return $false}
        $regex=[regex]::new($pattern,([Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::CultureInvariant),[TimeSpan]::FromMilliseconds(50))
        $inspected=0
        foreach($path in [IO.Directory]::EnumerateFiles($folder,('*'+$dataExtension),[IO.SearchOption]::TopDirectoryOnly)){
            $inspected++;if($inspected -gt 256){return $false}
            $stem=[IO.Path]::GetFileNameWithoutExtension($path)
            if(-not $regex.IsMatch($stem)){continue}
            $index=[IO.Path]::ChangeExtension($path,$indexExtension)
            if([IO.File]::Exists($index) -and ([IO.FileInfo]::new($path)).Length -gt 0 -and ([IO.FileInfo]::new($index)).Length -gt 0){return $true}
        }
    } catch {}
    return $false
}

function global:Test-PCVROriginalXmlValue {
    param([string]$Root,$Assertion)
    try{
        $relative=[string]$Assertion.File
        if(-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)|[?*]'){return $false}
        if(-not $Assertion.XPath -or -not @($Assertion.Values).Count){return $false}
        $path=[IO.Path]::Combine($Root,$relative.Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar))
        $file=Get-Item -LiteralPath $path -ErrorAction Stop
        if($file.PSIsContainer -or $file.Length -le 0 -or $file.Length -gt 1048576){return $false}
        $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
        $reader=[Xml.XmlReader]::Create($path,$settings)
        try{
            $doc=[Xml.XmlDocument]::new();$doc.XmlResolver=$null;$doc.Load($reader)
            $nodes=$doc.SelectNodes([string]$Assertion.XPath)
            if($nodes.Count -ne 1){return $false}
            return ([string]$nodes[0].InnerText).Trim() -in @($Assertion.Values)
        }finally{$reader.Dispose()}
    }catch{return $false}
}

function global:Test-PCVRGameInstallProof {
    param(
        [string]$GameId,
        [string]$Root,
        $FileSets,
        [long]$MinimumBytes = 0
    )
    # Linux/pwsh only: installer-built roots carry Windows separators
    # ("$lib\steamapps\common\X"); .NET file APIs need '/'. Windows: no-op.
    if ([IO.Path]::DirectorySeparatorChar -eq '/' -and $Root) { $Root = $Root.Replace('\','/') }
    if (-not $FileSets -and $GameId) {
        $contract = Get-PCVRGameInstallProof -GameId $GameId
        if (-not $contract) { return $false }
        $FileSets = $contract.FileSets
    }
    if (-not $FileSets -or [string]::IsNullOrWhiteSpace($Root) -or
        -not [IO.Directory]::Exists($Root)) { return $false }
    foreach ($set in @($FileSets)) {
        if (-not @($set.Files).Count -and -not @($set.Containers | Where-Object { $_ -and ($_.File -or ($_.Directories -and $_.Patterns)) }).Count) { continue }
        $complete = $true
        [long]$bytes = 0
        $counted = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($group in @($set.Files)) {
            $matched = $false
            foreach ($relative in (([string]$group) -split '\|')) {
                $relative = $relative.Trim()
                if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or
                    $relative -match '(^|[\\/])\.\.([\\/]|$)') { continue }
                try {
                    $candidate = [IO.Path]::Combine($Root, $relative.Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar))
                    $file = [IO.FileInfo]::new($candidate)
                    if (-not $file.Exists) { continue }
                    if ([long]$file.Length -le 0) { continue }
                    if ($counted.Add([IO.Path]::GetFullPath($candidate))) { $bytes += [long]$file.Length }
                    $matched = $true
                    break
                } catch {}
            }
            if (-not $matched) { $complete = $false; break }
        }
        if($complete){
            foreach($assertion in @($set.XmlValues)){
                if($assertion -and -not(Test-PCVROriginalXmlValue -Root $Root -Assertion $assertion)){$complete=$false;break}
            }
        }
        if($complete -and $set.RejectIfAllFiles){
            # Edition discriminator only: it cannot establish a game by itself.
            if(Test-PCVRGameInstallProof -Root $Root -FileSets @(@{Files=@($set.RejectIfAllFiles)})){ $complete=$false }
        }
        if($complete){
            foreach($pair in @($set.ArchivePairs)){
                if($pair -and -not(Test-PCVROriginalArchivePair -Root $Root -Pair $pair)){$complete=$false;break}
            }
        }
        if ($complete) {
            foreach ($container in @($set.Containers)) {
                if ($container -and -not (Test-PCVRGameContainerProof -Root $Root -Container $container)) { $complete=$false; break }
            }
        }
        if ($complete -and ($MinimumBytes -le 0 -or $bytes -ge $MinimumBytes)) { return $true }
    }
    return $false
}

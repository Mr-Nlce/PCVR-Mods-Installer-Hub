# Read-only descriptions of the existing launch contract. Opening a detail page
# must never activate a profile, repair a launcher, migrate state or start a game.
if(-not(Get-Command Get-HubLaunchScriptInvocation -ErrorAction SilentlyContinue)){
    . (Join-Path $PSScriptRoot 'DetailView.Launch.ps1')
}
function global:Get-DetailVrLaunchRows {
    param($Game,$State,[string[]]$Roots)
    $rows=[Collections.Generic.List[object]]::new()
    $add={param($label,$target,$arguments,$root,$kind='File')
        if(-not $target){return}
        $path=''
        if($kind -eq 'File'){
            foreach($base in @(@($root)+@($Roots)|Where-Object {$_}|Select-Object -Unique)){
                try {
                    $candidate=if([IO.Path]::IsPathRooted($target)){[string]$target}else{Join-Path $base $target}
                    if(Test-Path -LiteralPath $candidate -PathType Leaf){$path=[IO.Path]::GetFullPath($candidate);break}
                }catch{}
            }
        }
        $rows.Add([pscustomobject]@{Label=[string]$label;Target=[string]$target;Arguments=[string]$arguments;Path=$path;Kind=$kind})
    }
    $gameRoot=if($State.GameDir){[string]$State.GameDir}else{@($Roots|Where-Object {$_}|Select-Object -First 1)[0]}
    if($Game.ExternalVrStartApp){
        $app=Get-ExternalVrStartApp -Game $Game
        if($app){& $add 'Start in VR (located start app)' $app '' (Split-Path $app -Parent)}
        else{& $add 'Start in VR' 'Choose Locate VR mod start app to select your installed VR launcher.' '' '' 'Text'}
        return $rows.ToArray()
    }
    $special=$null
    if($Game.Id -eq 'house-of-the-dead-2-original-vr'){$special=Get-HotD2VrLaunchTarget -Game $Game}
    elseif($Game.Id -in @('descent-vr','descent-2-vr')){$special=Get-DescentVrLaunchTarget -Game $Game}
    if($special){& $add 'Start in VR' $special.FilePath $special.Arguments $special.WorkingDirectory;return $rows.ToArray()}
    if($Game.TwoMods){
        foreach($definition in @(Get-AlternativeModDefinitions -Game $Game -State $State)){
            $root=if($definition.Root){[string]$definition.Root}else{$gameRoot}
            if($Game.Title -eq 'Quake VR' -and $definition.Mode -eq 'ModC'){
                $target=Get-QuakeUnleashedLaunchTarget -Game $Game -State $State
                if($target){& $add $definition.Name $target.FilePath $target.Arguments $target.WorkingDirectory}
                else{& $add $definition.Name 'ironwail.exe' '-basedir <Quake folder> -basedir <Unleashed folder> -game quakevr' $root}
                continue
            }
            if($Game.MaxPayne2DualLaunch -and $root -match '(?i)[\\/]steamapps[\\/]common[\\/]'){
                & $add $definition.Name ('steam://rungameid/'+$Game.SteamId) '' '' 'Steam';continue
            }
            if($Game.RogueTraderDualLaunch){
                if($definition.Mode -eq 'ModA'){
                    $profile=Resolve-VrInstallRoot $Game.VrInstallRoot
                    & $add $definition.Name 'RTMaquetaXR\W40KRT-VR-Launcher.exe' '' $profile
                }elseif($root -match '(?i)[\\/]steamapps[\\/]common[\\/]'){
                    & $add $definition.Name ('steam://rungameid/'+$Game.SteamId) '' '' 'Steam'
                }else{& $add $definition.Name 'WH40KRT.exe' '' $root}
                continue
            }
            if($Game.EldenRingDirectMotionLaunch){
                # Hotbite/ERVR activate their recorded profile before starting
                # the selected build. Do not invoke that mutating operation here.
                if($definition.Mode -eq 'ModB'){& $add ($definition.Name+' (selected Current / Depot build)') 'Game\eldenring.exe' '' $root}
                else{
                    $hotRoot=Resolve-VrInstallRoot $Game.VrInstallRoot
                    $gameExe=if($root){Join-Path $root 'Game\eldenring.exe'}else{'<selected build>\Game\eldenring.exe'}
                    $profile=Join-Path $hotRoot 'eldenring-vr.me3'
                    & $add ($definition.Name+' (selected Current / Depot build)') 'me3\bin\me3.exe' ('launch --game eldenring --exe "'+$gameExe+'" --profile "'+$profile+'"') $hotRoot
                }
                continue
            }
            $target=[string]$definition.Launch
            if($definition.Sub -and $definition.Sub -ne '.' -and -not $definition.RootLaunch){$target=Join-Path $definition.Sub $target}
            $scanTarget=if($definition.Dir -and $definition.Launch){Join-Path $definition.Dir $definition.Launch}else{''}
            if($scanTarget -and (Test-Path -LiteralPath $scanTarget -PathType Leaf)){$target=$scanTarget}
            elseif($definition.LaunchAlt -and $definition.Dir -and (Test-Path -LiteralPath (Join-Path $definition.Dir $definition.LaunchAlt) -PathType Leaf)){$target=Join-Path $definition.Dir $definition.LaunchAlt}
            & $add $definition.Name $target '' $root
        }
        return $rows.ToArray()
    }
    if($Game.DualMode){
        foreach($route in @('Current','Depot','LegacyDepot')){
            if($route -eq 'LegacyDepot' -and -not $Game.LegacyDepotLaunchExe){continue}
            $target=[string]$Game[($route+'LaunchExe')]
            $root=[string](Get-AlternativeModValue $State ($route+'Dir'))
            if(-not $root -and $route -eq 'Current'){$root=$gameRoot}
            if(-not $root -and $route -eq 'Depot'){$root=[string]$Game.DepotPath}
            if($target){& $add ($route+' Start in VR') $target $Game[($route+'LaunchArgs')] $root}
            elseif($route -eq 'Current' -and $Game.SteamId){& $add 'Current Start in VR' ('steam://rungameid/'+$Game.SteamId) '' '' 'Steam'}
        }
        return $rows.ToArray()
    }
    if((Get-Command Test-UseSteamBootstrapForInstall -ErrorAction SilentlyContinue) -and (Test-UseSteamBootstrapForInstall -Game $Game -GameRoot $gameRoot)){
        & $add 'Start in VR through Steam' ('steam://rungameid/'+$Game.SteamId) '' '' 'Steam'
        return $rows.ToArray()
    }
    if($Game.Title -eq 'Dishonored VR'){
        $galaxy=Get-DishonoredGogGalaxyLaunch -GameRoot $gameRoot
        if($galaxy){& $add 'Start in VR through GOG Galaxy' $galaxy.File $galaxy.Arguments (Split-Path $galaxy.File -Parent)}
        else{& $add 'Start in VR' 'GOG Galaxy (the publisher launcher supplies the installed game launch information).' '' '' 'Text'}
        return $rows.ToArray()
    }
    if($Game.HubLaunchScript){
        $invocation=Get-HubLaunchScriptInvocation -Game $Game -GameRoot $gameRoot
        if($invocation){& $add 'Hub Start in VR controller' $invocation.ScriptPath $invocation.Arguments (Split-Path $invocation.ScriptPath -Parent)}
        else{& $add 'Hub Start in VR controller' $Game.HubLaunchScript '' ''}
        & $add 'VR launcher used by the controller' $Game.HubStartFile $Game.LaunchArgs $gameRoot
        return $rows.ToArray()
    }
    if((Get-Command Test-AllowGenericLaunchOverride -ErrorAction SilentlyContinue) -and (Test-AllowGenericLaunchOverride -Game $Game)){
        if($Game.LaunchExeAlt -and $gameRoot -and (Test-Path -LiteralPath (Join-Path $gameRoot $Game.LaunchExeAlt) -PathType Leaf)){
            & $add 'Start in VR' $Game.LaunchExeAlt '' $gameRoot;return $rows.ToArray()
        }
        $saved=if(Get-Command Read-LaunchOverride -ErrorAction SilentlyContinue){Read-LaunchOverride -Game $Game}else{''}
        $recorded=if(Get-Command Read-InstalledPath -ErrorAction SilentlyContinue){Read-InstalledPath -Game $Game}else{''}
        $replacement=Get-ReplacementForObsoleteBaseLaunchOverride -Game $Game -InstalledRoot $recorded -LaunchOverride $saved
        if($replacement){$saved=$replacement}
        if($saved -and (Test-Path -LiteralPath $saved -PathType Leaf)){
            & $add 'Start in VR (located start app)' $saved $Game.LaunchArgs (Split-Path $saved -Parent);return $rows.ToArray()
        }
    }
    if($Game.LaunchExe){
        # Match the launcher's root priority without enumerating entire games.
        $recorded=if(Get-Command Read-InstalledPath -ErrorAction SilentlyContinue){Read-InstalledPath -Game $Game}else{''}
        $runtime=if($Game.VrInstallRoot){Resolve-VrInstallRoot $Game.VrInstallRoot}else{''}
        foreach($candidate in @($recorded,$runtime,$gameRoot)+@($Roots)){
            if($candidate -and (Test-Path -LiteralPath (Join-Path $candidate $Game.LaunchExe) -PathType Leaf)){$gameRoot=$candidate;break}
        }
        $arguments=[string]$Game.LaunchArgs
        # GZDoom keeps the same user-selected IWAD/add-ons as its shortcut.
        if($Game.VrInstallEvidence -and $gameRoot){
            $leaf=Split-Path ([string]@($Game.VrInstallEvidence)[0]) -Leaf
            if($leaf){$argFile=Join-Path $gameRoot ('.vrlaunchargs_'+($leaf -replace '[^A-Za-z0-9]','_'))
                if(Test-Path -LiteralPath $argFile -PathType Leaf){$value=[IO.File]::ReadAllText($argFile).Trim();if($value){$arguments=$value}}
            }
        }
        & $add 'Start in VR' $Game.LaunchExe $arguments $gameRoot
    }elseif($Game.SteamId){& $add 'Start in VR through Steam' ('steam://rungameid/'+$Game.SteamId) '' '' 'Steam'}
    else{& $add 'Start' 'Use the external installer / launcher described on this page. This entry has no configured Hub Start in VR action.' '' '' 'Text'}
    return $rows.ToArray()
}

function global:Get-DetailVrFilesBody {
    param($Game,$Files)
    if(@($Files.LaunchRows|Where-Object {$_.Kind -eq 'Text' -and $_.Label -eq 'Start'}).Count){
        return 'This entry uses its external installer or launcher. Follow the launch instructions on this page; no separate Hub Start in VR action is configured.'
    }
    $lines=[Collections.Generic.List[string]]::new()
    if($Files.Verified){
        foreach($root in @($Files.LinkRoots|Where-Object {$_}|Select-Object -Unique)){
            # The packaged controller is linked in its own launch row. Its
            # Hub source folder is not the installed publisher runtime folder.
            if($Files.HubControllerPath -and $root -ieq (Split-Path $Files.HubControllerPath -Parent) -and $root -ine $Files.Root){continue}
            if(Test-Path -LiteralPath $root -PathType Container){$lines.Add('VR files folder: ['+$root+'](<'+$root+'>)')}
        }
    }else{
        $lines.Add('The VR files folder and start app will appear here as links once the VR mod installation is complete.')
        $lines.Add('If the Hub does not find your game, you can choose Locate Game and select the folder containing its game EXE.')
        if($Files.Root -and $Files.Root -ne 'the located game folder'){$lines.Add('Expected VR folder: '+$Files.Root)}
    }
    foreach($route in @($Files.LaunchRows)){
        $destination=if($Files.Verified -and $route.Path){'['+$route.Path+'](<'+$route.Path+'>)'}else{$route.Target}
        if($route.Kind -eq 'Steam'){$destination='Steam (App '+$Game.SteamId+'): '+$route.Target}
        $line=$route.Label+': '+$destination
        if($route.Arguments){$line+=' — Arguments: '+$route.Arguments}
        $lines.Add($line)
    }
    if($Files.Verified){$lines.Add('File links show the file in Explorer. Use Start in VR in the Hub to launch the matching VR mod.')}
    return $lines -join "`n"
}

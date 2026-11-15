# Publisher-bundled Unity IL2CPP packages; Foundation owns recovery and commit.
# Numeric update sources for the publisher's rolling release tags:
# https://raw.githubusercontent.com/King-EJ/Agent-64-Spies-Never-Die-VR-Mod/main/README.md
# https://raw.githubusercontent.com/King-EJ/I-Hate-This-Place-VR-Mod/main/README.md
. (Join-Path $PSScriptRoot 'PublisherVRSetup.ps1')
$script:KingEJModules=$PSScriptRoot
function Get-KingEJVRProfile([string]$Key){
 $p=switch($Key){
  'Agent64' {@{Key=$Key;Id='agent-64-spies-never-die-vr';Title='Agent 64: Spies Never Die VR';Folder='Agent64VR';GameFolder='Agent 64';Exe='Agent 64 Spies Never Die.exe';App='1574480';Repo='King-EJ/Agent-64-Spies-Never-Die-VR-Mod';Pattern='(?i)^Agent64SpiesNeverDieVRMod.*\.zip$';Plugin='A64VR';Dll='A64VR.dll';Config='agent64.vr.cfg';VersionName='Agent 64 VR';Quip='For England? No, for stereoscopic depth.'}}
  'IHateThisPlace' {@{Key=$Key;Id='i-hate-this-place-vr';Title='I Hate This Place VR';Folder='IHateThisPlaceVR';GameFolder='I Hate This Place';Exe='I Hate This Place.exe';App='2604490';Repo='King-EJ/I-Hate-This-Place-VR-Mod';Pattern='(?i)^IHateThisPlaceVRMod.*\.zip$';Plugin='IHVR';Dll='IHVR.dll';Config='ihatethisplace.vr.cfg';VersionName='I Hate This Place VR';Quip='Now you can hate this place in every direction.'}}
  default {throw 'Unknown Unity VR package.'}
 }
 $p.Identity=$p.Key.ToLowerInvariant()+'vr'
 $p.LoaderIdentity=$p.Identity+'loader'
 $p.PluginFiles=@(('BepInEx\plugins\'+$p.Plugin+'\'+$p.Dll),('BepInEx\plugins\'+$p.Plugin+'\OpenXR.dll'),('BepInEx\config\'+$p.Config))
 $p.LoaderFiles=@('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.Core.dll','BepInEx\core\BepInEx.Preloader.Core.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll','BepInEx\core\Il2CppInterop.Runtime.dll','dotnet\coreclr.dll','dotnet\hostpolicy.dll')
 return $p
}
function Get-KingEJVRArchive($Profile,[string]$Work,$Test){
 if($Test){return @{Path=[string]$Test.Archives.Main.Path;Tag=[string]$Test.Archives.Main.Tag}}
 $manual=Get-PCVRRecoveryInput -PathType Leaf
 if($manual){
  if([IO.Path]::GetExtension($manual) -ine '.zip'){throw 'Choose the official VR ZIP. The original game EXE is not the mod package.'}
  [void](Set-PCVRRecoveryInput '')
  Write-Host ('  Using your downloaded VR ZIP: '+$manual) -ForegroundColor Cyan
  return @{Path=$manual;Tag=''}
 }
 Write-Host '  Checking the official VR release; downloads will follow. This may take a minute.' -ForegroundColor Cyan
 $r=Resolve-GitHubReleaseAsset -Repo $Profile.Repo -IncludePrerelease $false -AssetPatterns @($Profile.Pattern) -SkipReleasesWithoutMatchingAsset $true
 if(-not $r.Resolved -or -not $r.Url){throw 'The official VR ZIP could not be found. Retry or hand over the downloaded publisher ZIP.'}
 $dest=Join-Path $Work 'publisher.zip'
 [void](Invoke-SafeDownload -Urls @($r.Url) -Destination $dest -Label $Profile.Title -ManualUrl ('https://github.com/'+$Profile.Repo+'/releases') -AllowSkip $false -PlainProgress -FunctionalPayloadOnly)
 return @{Path=$dest;Tag=[string]$r.Tag}
}
function Get-KingEJVRGame($Profile,$Test){
 if($Test){if(-not(Test-PCVRGameInstallProof -GameId $Profile.Id -Root $Test.Game)){throw 'The original game is incomplete.'};return [string]$Test.Game}
 $manual=Get-PCVRRecoveryInput
 if($manual){$candidate=if(Test-Path -LiteralPath $manual -PathType Leaf){Split-Path $manual -Parent}else{$manual};if(((Test-Path -LiteralPath $manual -PathType Container) -or [IO.Path]::GetFileName($manual) -ieq $Profile.Exe) -and (Test-PCVRGameInstallProof -GameId $Profile.Id -Root $candidate)){[void](Set-PCVRRecoveryInput '');return $candidate}}
 $proof=(Get-PCVRGameInstallProof -GameId $Profile.Id).Files
 $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @('user_located','base_game_path','installed_path') -ProbeFiles $proof
 if($saved -and (Test-PCVRGameInstallProof -GameId $Profile.Id -Root $saved)){return $saved}
 try{$game=Find-SteamGameFolder -AppId $Profile.App -SteamFolderNames @($Profile.GameFolder) -ProbeExe $Profile.Exe -HubGameId $Profile.Id;if($game -and (Test-PCVRGameInstallProof -GameId $Profile.Id -Root $game)){return $game}}catch{}
 while($true){$picked=Get-GameFolderInteractive -GameName $Profile.GameFolder -ProbeFile $Profile.Exe;if(Test-PCVRGameInstallProof -GameId $Profile.Id -Root $picked){[void](Save-HubRememberedGameFolder -GameId $Profile.Id -Title $Profile.Title -GameDir $picked -ProbeFiles $proof -StateName 'base_game_path' -UserSelected);return $picked};Write-Host ('  Choose the full game folder containing '+$Profile.Exe+' and its game data.') -ForegroundColor Yellow}
}
function Invoke-KingEJVRSetup([string]$Key,[string]$InstallerFolder){
 $ErrorActionPreference='Stop';$p=Get-KingEJVRProfile $Key;$test=Get-PublisherVRTestContext;$work=$null;$groups=@();$changed=$false;$keepWork=$false
 try{
  Write-Host ('='*60) -ForegroundColor Cyan;Write-Host ('  '+$p.Title+' Installer') -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Cyan
  Write-Host '  Close the game. Setup includes the publisher-selected BepInEx loader and OpenXR files.'
  Write-Host '  Existing settings, saves and unrelated mods are kept.'
 if($Key -eq 'Agent64'){Write-Host '  Solo/offline VR. For the Steam edition, Start in VR selects Offline mode without EAC in Steam.' -ForegroundColor Yellow;Write-Host '  Publisher tested game v1004; later game updates may affect this test-build mod.' -ForegroundColor Yellow}
  else{Write-Host '  Switch between first-person and the original camera with right stick click.' -ForegroundColor Cyan}
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to find or choose the game folder...')
  $game=Get-KingEJVRGame $p $test
  Write-Host ('  Game folder: '+$game) -ForegroundColor Cyan
  if(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($p.Exe)) -ErrorAction SilentlyContinue){throw 'Close the game before installing or updating VR.'}
  if($game -match '(?i)[\\/](WindowsApps|XboxGames)[\\/]'){throw 'The publisher has not confirmed this Xbox build. Choose a supported Windows game installation.'}
  $route=if($test){[string]$test.Route}elseif($game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){'Steam'}else{'Direct'}
  if(-not(Test-InstallerTargetWritable $game)){throw 'The game folder is not writable. Correct its permissions, then Retry.'}
  $work=New-PCVRInstallerTempSession -BasePath $(if($test){[string]$test.Root}else{[IO.Path]::GetTempPath()})
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current official VR ZIP...')
  $a=Get-KingEJVRArchive $p $work $test
  $expanded=Expand-PublisherVRArchive $a (Join-Path $work 'expanded')
  $stage=Find-PublisherVRPayload $expanded ('BepInEx\plugins\'+$p.Plugin+'\'+$p.Dll)
  $cfg=[IO.File]::ReadAllText((Join-Path $stage ('BepInEx\config\'+$p.Config)))
  if($cfg -notmatch ('(?im)^## Settings file was created by plugin '+[regex]::Escape($p.VersionName)+' v(\d+(?:\.\d+)+)')){throw 'The publisher package does not identify its VR plugin version.'}
  $version='v'+$Matches[1]
  foreach($rel in @($p.PluginFiles+$p.LoaderFiles)){if(-not(Test-Path -LiteralPath (Join-Path $stage $rel) -PathType Leaf)){throw ('The publisher ZIP is missing '+$rel+'. No game files were changed.')}}
  # Split plugin and shared loader ownership, using the established Blood West plan.
  $loader=Join-Path $work 'loader';$plugin=Join-Path $work 'plugin'
  [void][IO.Directory]::CreateDirectory($loader);[void][IO.Directory]::CreateDirectory($plugin)
  foreach($file in @(Get-ChildItem -LiteralPath $stage -File -Recurse -Force)){
   $rel=$file.FullName.Substring($stage.TrimEnd('\').Length+1)
   if($rel -match '(?i)^(BepInEx[\\/]plugins[\\/]'+[regex]::Escape($p.Plugin)+'[\\/]|BepInEx[\\/]config[\\/]'+[regex]::Escape($p.Config)+'$)'){$dest=Join-OwnedRelativePath $plugin $rel}
   elseif($rel -match '(?i)^(BepInEx[\\/](core|config)[\\/]|dotnet[\\/]|winhttp\.dll$|doorstop_config\.ini$|\.doorstop_version$|README.*\.txt$|changelog\.txt$)'){$dest=Join-OwnedRelativePath $loader $rel}
   else{continue}
   [void][IO.Directory]::CreateDirectory((Split-Path $dest -Parent));Copy-Item -LiteralPath $file.FullName -Destination $dest
  }
  $launch=Join-Path $plugin 'PCVR-Launcher';[void][IO.Directory]::CreateDirectory($launch)
  Copy-Item -LiteralPath (Join-Path $script:KingEJModules 'KingEJUnityVRLaunch.ps1') -Destination (Join-Path $launch 'Start-VR.ps1')
  @{Key=$Key;Game=$game;Exe=$p.Exe;Store=$route;App=$p.App;Title=$p.Title;Required=@($p.PluginFiles+$p.LoaderFiles)}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $launch ($p.Key+'-launch.json')) -Encoding UTF8
  $keep=@('doorstop_config.ini')+@(Get-ChildItem -LiteralPath (Join-Path $loader 'BepInEx\config') -File -Recurse|ForEach-Object{$_.FullName.Substring($loader.Length+1)})
  $groups+=New-PublisherVRGroup $game $loader $p.LoaderIdentity $p.LoaderFiles $keep
  $groups+=New-PublisherVRGroup $game $plugin $p.Identity (@($p.PluginFiles)+@('PCVR-Launcher\Start-VR.ps1',('PCVR-Launcher\'+$p.Key+'-launch.json'))) @('BepInEx\config\'+$p.Config)
  $contract=New-PCVRInstallerContract -Id $p.Id -GameName $p.Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$p.Repo+'/releases') -RequiredInstalledFileGroups @($groups|ForEach-Object{$_.Required})
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the VR files and keep your existing settings...')
  Write-Host '  Preparing backups and installing VR; this may take a minute.' -ForegroundColor Cyan
  foreach($g in $groups){$g.Snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $g.Stage -Identity $g.Identity -SnapshotRoot (Join-Path $work ('rollback-'+$g.Identity))}
  $changed=$true
  foreach($g in $groups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $game -Identity $g.Identity -KeepExistingRelativePaths $g.Keep -ReplaceChangedOwnedRelativePaths @('PCVR-Launcher\'+$p.Key+'-launch.json') -ProgressLabel ('Installing '+$p.Title))}
  if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game $p.PluginFiles[0]) -Force}
  if(@(Write-PublisherVRCheckpoint $groups 'immediately-after-copy').Count){throw 'Required files were not copied. Check the target, permissions and log. No antivirus cause has been established.'}
  if($test.Failure -eq 'vanish'){Remove-Item -LiteralPath (Join-Path $game $p.PluginFiles[0]) -Force}
  Write-Host '  Checking the installed files; this takes a few seconds.' -ForegroundColor Cyan;Start-Sleep -Seconds 3
  $missing=@(Write-PublisherVRCheckpoint $groups 'after-observation')
  if($missing.Count){
   $retry={ [void](Write-PublisherVRCheckpoint $groups 'before-retry');foreach($g in $groups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $game -Identity $g.Identity -KeepExistingRelativePaths $g.Keep -ReplaceChangedOwnedRelativePaths @('PCVR-Launcher\'+$p.Key+'-launch.json'))};[void](Write-PublisherVRCheckpoint $groups 'after-retry') }.GetNewClosure()
   $read=if($test){{'Q'}}else{$null}
   if(-not(Confirm-PlacedFilesSurvive -Paths @($groups|ForEach-Object{$g=$_;$g.Required|ForEach-Object{Join-Path $game $_}}) -GameDir $game -WaitSeconds 0 -Recopy $retry -ReadInput $read -NoClear)){throw 'Required files disappeared after copying; restoring your previous installation.'}
  }
  if(@(Write-PublisherVRCheckpoint $groups 'before-commit').Count){throw 'The complete VR installation could not be confirmed.'}
  if($test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
  $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -InstalledPathReceiptPaths @($receipt) -Route $route)
  $changed=$false
  Write-Host ('  [OK] '+$p.Title+' '+$version+' installed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
  Write-Host '  Start your OpenXR runtime first. First launch can take longer while BepInEx prepares the game.'
  if($Key -eq 'Agent64'){Write-Host '  Alternative in Steam: choose Offline mode without EAC. Solo VR only.' -ForegroundColor Yellow}
  elseif($route -eq 'Steam'){Write-Host '  Alternative: start I Hate This Place through Steam.'}
  Write-Host ''
  Write-Host ('  '+$p.Quip) -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  $failure=$_
  if($changed){[void](Write-PublisherVRCheckpoint $groups 'before-rollback');try{for($i=$groups.Count-1;$i -ge 0;$i--){Restore-PCVRPublisherZipSnapshot -GameRoot $groups[$i].Root -Snapshot $groups[$i].Snapshot};[void](Write-PublisherVRCheckpoint $groups 'after-rollback')}catch{$keepWork=$true;Write-Host ('  Recovery copy: '+$work) -ForegroundColor Yellow}}
  throw $failure
 }finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-KingEJVRUninstall([string]$Key,[string]$InstallerFolder,[switch]$HubConfirmed){
 $ErrorActionPreference='Stop';$p=Get-KingEJVRProfile $Key;$test=Get-PublisherVRTestContext;$game=Get-KingEJVRGame $p $test
 if(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($p.Exe)) -ErrorAction SilentlyContinue){throw 'Close the game before removing VR.'}
 if(-not $HubConfirmed -and (Read-Host ('Remove '+$p.Title+'? Type REMOVE')) -cne 'REMOVE'){return}
 [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.Identity)
 $other=@(Get-ChildItem -LiteralPath (Join-Path $game 'BepInEx\plugins') -File -Filter '*.dll' -Recurse -ErrorAction SilentlyContinue|Where-Object{$_.FullName -notmatch ('[\\/]'+[regex]::Escape($p.Plugin)+'[\\/]')})
 if(-not $other.Count){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.LoaderIdentity)}else{Write-Host '  BepInEx kept for your other plugins.' -ForegroundColor Yellow}
 foreach($file in @((Join-Path $game '.pcvrhub_version'),$(if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}))){if(Test-Path -LiteralPath $file -PathType Leaf){Remove-Item -LiteralPath $file -Force}}
 Write-Host '  [OK] VR removed. Changed settings, saves and other mods were kept.' -ForegroundColor Green
}

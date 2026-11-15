# Complete publisher packages; native launchers retain their own game/runtime setup.
. (Join-Path $PSScriptRoot 'PublisherVRSetup.ps1')
$script:OctoberNativeModules=$PSScriptRoot
function Get-OctoberNativeProfile([string]$Key){
 $p=switch($Key){
  'RE5' {@{Key=$Key;Id='resident-evil-5-vr';Title='Resident Evil 5 VR';Folder='RE5VR';GameFolder='Resident Evil 5';Exe='re5dx9.exe';App='21690';Repo='SpreadTheBirb/ResidentEvil5VR';Pattern='(?i)^TrueFP-.*-VR\.zip$';Probe='d3d9.dll';Sub='';Required=@('d3d9.dll','d3d9_dgvoodoo.dll','dgVoodoo.conf','openxr_loader.dll','SampleAddon.dll');Keep=@('re5vr.ini');Hint='Start SteamVR or connect Virtual Desktop with VDXR first. Play in windowed mode.';Quip='Chris can punch boulders. Your controllers cannot.'}}
  'GearsEDay' {@{Key=$Key;Id='gears-of-war-e-day-vr';Title='Gears of War: E-Day VR';Folder='GearsEDayVR';GameFolder='GoWEDay';Exe='FairlightConcept\Binaries\Win64\GoWEDay-Steam.exe';App='3010850';Repo='paultaran00/GoWEDay-VR';Pattern='(?i)^GoWEDay-VR.*\.zip$';Probe='GoWEDay_VR.exe';Sub='PCVR-Launcher\GoWEDay';Required=@('GoWEDay_VR.exe','gameinput_vr\gameinput_vr.dll','profile\actions.json','profile\config.txt','profile\scripts\fp.lua','profile\scripts\arms.lua','profile\scripts\vrsettings.lua','UEVR\UEVRInjector.exe','UEVR\UEVRBackend.dll','UEVR\LuaVR.dll','UEVR\openxr_loader.dll');Keep=@('path.txt','profile\config.txt');Hint='Campaign only. Start in VR opens the publisher launcher: choose your game and press Start. At the title screen hold X to enter offline mode. SteamVR must be active OpenXR.';Quip='Emergence Day. Now slightly closer than planned.'}}
  'CodeVeronica' {@{Key=$Key;Id='resident-evil-code-veronica-x-vr';Title='Resident Evil Code: Veronica X VR';Folder='CodeVeronicaVR';GameFolder='Resident Evil Code Veronica X VR';Exe='recvx_vr.exe';App='';Repo='neto1495mn-sudo/recvx-enhanced-port-pcvr';Pattern='(?i)^RE-Code-Veronica-X-.*(?:PCVR|Port-VR).*windows\.zip$';Probe='recvx_vr.exe';Sub='';Required=@('recvx_vr.exe','PLAY_VR.bat','save\recvx.ini');Keep=@('save\recvx.ini');Hint='Start your OpenXR runtime. Start in VR opens the port launcher: press PLAY. Your own PS2 US SLUS-20184 ISO is read in place; game data is not included.';Quip='Welcome to Rockfort Island. The checkout is complicated.'}}
  default {throw 'Unknown publisher package.'}
 }
 if($Key -eq 'GearsEDay'){
  $p.Required+=@('profile\eday_grips.lua','profile\bindings_knuckles.json','profile\bindings_oculus_touch.json','profile\bindings_vive_controller.json','UEVR\UEVRPluginNullifier.dll')
  foreach($name in @('aa_assets','aa_xr','gestures','grenade','handles','menu','saw','scope','sprint','turret','weapon')){$p.Required+=@('profile\scripts\'+$name+'.lua')}
  $p.Keep=@('path.txt')
 }
 $p.Identity=$Key.ToLowerInvariant()+'vr';return $p
}
function Set-OctoberNativeConfigPlan($Group,[string]$Key,[string]$Version,$Test){
 $names=switch($Key){'RE5'{@('dgVoodoo.conf')}'GearsEDay'{@('PCVR-Launcher\GoWEDay\profile\config.txt','PCVR-Launcher\GoWEDay\profile\cameras.txt')}default{@()}}
 $Group.ReplaceChanged=@();$Group.PreserveConfigHashes=@{}
 $manifest=Join-Path $Group.Root ('.pcvrhub_'+$Group.Identity+'_ownership.csv');$owned=@{}
 if([IO.File]::Exists($manifest)){foreach($row in Import-Csv -LiteralPath $manifest){$owned[[string]$row.RelativePath]=$row}}
 foreach($rel in $names){$target=Join-OwnedRelativePath $Group.Root $rel;$source=Join-OwnedRelativePath $Group.Stage $rel;if(-not[IO.File]::Exists($target) -or -not[IO.File]::Exists($source)){continue}
  $hash=(Get-FileHash -LiteralPath $target).Hash;$prior=$owned[$rel]
  if($prior -and $prior.InstalledSha256 -eq $hash){continue}
  if((Get-FileHash -LiteralPath $source).Hash -eq $hash){$Group.ReplaceChanged+=@($rel);continue}
  Write-Host ('  Your settings differ: '+$rel) -ForegroundColor Yellow
  Write-Host ('  Y: use the defaults from VR mod '+$Version+'; your current file is backed up first.')
  Write-Host '  N or Enter: keep your settings and continue.'
  if($Test){$answer=[string]$Test.ConfigChoice}else{do{$answer=(Read-Host '  Replace this settings file? Y/N (Enter = N)').Trim()}while($answer -notmatch '^(?i:y|yes|n|no)?$')}
  if($answer -notmatch '^(?i:y|yes)$'){$Group.Keep+=@($rel);continue}
  $backup=Join-OwnedRelativePath (Join-Path $Group.Root ('.pcvrhub_'+$Group.Identity+'_settings_backups\'+[guid]::NewGuid().ToString('N'))) $rel
  [void][IO.Directory]::CreateDirectory((Split-Path $backup -Parent));Copy-Item -LiteralPath $target -Destination $backup
  if((Get-FileHash -LiteralPath $backup).Hash -ne $hash){throw ('The settings backup could not be verified: '+$rel)}
  $Group.ReplaceChanged+=@($rel);if($prior){$Group.PreserveConfigHashes[$rel]=[string]$prior.InstalledSha256}
  Write-Host ('  [OK] Settings backed up: '+$backup) -ForegroundColor Green
 }
}
function global:Protect-OctoberNativeConfigOwnership($Group){
 if(-not$Group.PreserveConfigHashes.Count){return};$file=Join-Path $Group.Root ('.pcvrhub_'+$Group.Identity+'_ownership.csv');$rows=@(Import-Csv -LiteralPath $file)
 foreach($row in $rows){if($Group.PreserveConfigHashes.ContainsKey([string]$row.RelativePath)){$row.InstalledSha256=$Group.PreserveConfigHashes[[string]$row.RelativePath]}}
 $rows|Export-Csv -LiteralPath $file -NoTypeInformation -Encoding UTF8
}
function Resolve-OctoberNativeGame($P,[string]$Path){
 if(-not $Path){return $null};$path=$Path.Trim().Trim('"').Trim("'")
 if([IO.File]::Exists($path)){$path=Split-Path $path -Parent}
 for($i=0;$i -lt 6 -and $path;$i++){
  if(Test-PCVRGameInstallProof -GameId $P.Id -Root $path){return [IO.Path]::GetFullPath($path)}
  $path=Split-Path $path -Parent
 };return $null
}
function Get-OctoberNativeGame($P,$Test){
 if($Test){if($P.Key -ne 'CodeVeronica' -and -not(Resolve-OctoberNativeGame $P $Test.Game)){throw 'The original game is incomplete.'};return [string]$Test.Game}
 if($P.Key -eq 'CodeVeronica'){
  $saved=Get-PCVRRememberedGameFolder -GameId $P.Id -StateNames @('installed_path','user_located') -ProbeFiles @('recvx_vr.exe')
  if($saved){return $saved}
  $default=Join-Path ($env:SystemDrive+'\Games') $P.GameFolder
  Write-Host ('  Install folder: '+$default) -ForegroundColor Cyan
  $value=(Read-Host '  Enter keeps this folder; otherwise paste a full installation folder').Trim().Trim('"')
  if(-not $value){$value=$default};if(-not[IO.Path]::IsPathRooted($value)){throw 'Enter a full folder path.'};return [IO.Path]::GetFullPath($value)
 }
 $manual=Get-PCVRRecoveryInput
 $root=Resolve-OctoberNativeGame $P $manual;if($root){[void](Set-PCVRRecoveryInput '');return $root}
 $saved=Get-PCVRRememberedGameFolder -GameId $P.Id -StateNames @('user_located','base_game_path','installed_path') -ProbeFiles @()
 $root=Resolve-OctoberNativeGame $P $saved;if($root){return $root}
 try{$root=Resolve-OctoberNativeGame $P (Find-SteamGameFolder -AppId $P.App -SteamFolderNames @($P.GameFolder) -ProbeExe $P.Exe -HubGameId $P.Id);if($root){return $root}}catch{}
 while($true){$path=Read-Host ('  Drag '+[IO.Path]::GetFileName($P.Exe)+' here or paste the game folder (Q cancels)');if($path -match '^(?i:q)$'){throw 'Selection cancelled.'};$root=Resolve-OctoberNativeGame $P $path;if($root){return $root};Write-Host '  Game EXE and its original game data were not found together.' -ForegroundColor Yellow}
}
function Get-CodeVeronicaIso($P,[string]$Game,$Test){
 $values=@();if($Test){$values+=@([string]$Test.Iso)}
 $ini=Join-Path $Game 'save\recvx.ini'
 if([IO.File]::Exists($ini)){foreach($line in [IO.File]::ReadAllLines($ini)){if($line -match '^\s*iso\s*=\s*(.+?)\s*$'){$values+=@($Matches[1].Trim('"'))}}}
 $manual=Get-PCVRRecoveryInput -PathType Leaf;if($manual -and [IO.Path]::GetExtension($manual) -ieq '.iso'){$values+=@($manual)}
 while($true){
  foreach($iso in $values){if($iso -and [IO.File]::Exists($iso)){
   if($Test -and -not([IO.Path]::GetFullPath($iso)).StartsWith(([IO.Path]::GetFullPath($Test.Root).TrimEnd('\')+'\'),[StringComparison]::OrdinalIgnoreCase)){throw 'The test ISO escaped its fixture.'}
   Write-Host '  Checking the selected disc image; this takes a few seconds.' -ForegroundColor Cyan
   $container=@{File=[IO.Path]::GetFileName($iso);Format='PSX_DISC';Entries=@('file/SLUS_201.84','file/RDX_LNK.AFS')}
   if(Test-PCVRGameContainerProof -Root (Split-Path $iso -Parent) -Container $container){return [IO.Path]::GetFullPath($iso)}
  }}
  if($Test){throw 'The selected image is not the supported PS2 US SLUS-20184 ISO.'}
  Write-Host '  Choose your own PS2 US Code Veronica X disc image: SLUS-20184, .iso.' -ForegroundColor Cyan
  Write-Host '  The image stays where it is. Other regions and Dreamcast images are unsupported.'
  $path=(Read-Host '  ISO path (drag and drop; Q cancels)').Trim().Trim('"');if($path -match '^(?i:q)$'){throw 'Disc selection cancelled.'};$values=@($path)
 }
}
function Invoke-OctoberNativeSetup([string]$Key,[string]$InstallerFolder){
 $ErrorActionPreference='Stop';$p=Get-OctoberNativeProfile $Key;$test=Get-PublisherVRTestContext;$work=$null;$snapshot=$null;$changed=$false;$keepWork=$false
 try{
  Write-Host ('='*60) -ForegroundColor Cyan;Write-Host ('  '+$p.Title+' Installer') -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Cyan
  Write-Host '  Close the game and VR launcher. Your saves and personal settings are kept.'
  Write-Host ('  '+$p.Hint) -ForegroundColor Yellow
  if($Key -eq 'RE5'){Write-Host '  Recommended: the 4GB patch for re5dx9.exe reduces memory stutter. The README links the publisher tool; setup leaves your game EXE unchanged.'}
  if($Key -eq 'GearsEDay'){Write-Host '  Steam campaign route. Xbox builds have not been confirmed by the modder.'}
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to choose the installation folder...')
  $game=Get-OctoberNativeGame $p $test
  Write-Host ('  Game folder: '+$game) -ForegroundColor Cyan
  if(Get-Process -Name @([IO.Path]::GetFileNameWithoutExtension($p.Exe),$(if($Key -eq 'GearsEDay'){'GoWEDay_VR'}else{'recvx_vr'})) -ErrorAction SilentlyContinue){throw 'Close the game and publisher launcher before continuing.'}
  if($game -match '(?i)[\\/](?:XboxGames|WindowsApps)[\\/]'){throw 'This publisher route has not been confirmed for the Xbox build. No Steam redirect was performed.'}
  $iso=if($Key -eq 'CodeVeronica'){Get-CodeVeronicaIso $p $game $test}else{''}
  if(-not(Test-InstallerTargetWritable $game)){throw 'The selected installation folder is not writable.'}
  $route=if($Key -eq 'CodeVeronica'){'ROM'}elseif($game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){'Steam'}else{'Direct'}
  $work=New-PCVRInstallerTempSession -BasePath $(if($test){$test.Root}else{[IO.Path]::GetTempPath()})
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current official VR ZIP...')
  $a=Get-PublisherVRArchive -Repo $p.Repo -Patterns @($p.Pattern) -Label $p.Title -Work $work -Test $test -TestKey Main -FunctionalProbe $p.Probe -PlainProgress -IncludePrerelease:($Key -eq 'GearsEDay')
  $expanded=Expand-PublisherVRArchive $a (Join-Path $work 'expanded');$payload=Find-PublisherVRPayload $expanded $p.Probe
  foreach($rel in $p.Required){if(-not[IO.File]::Exists((Join-Path $payload $rel))){throw ('The publisher ZIP is missing '+$rel+'. No installed files were changed.')}}
  $version=[string]$a.Tag;if(-not(Test-IsTrackableInstalledVersion $version)){
   if($test){throw 'The fixture has no release version.'}
   Write-Host '  Enter the version shown on the official release page for your downloaded ZIP.'
   $version=(Read-Host '  Release version').Trim();if(-not(Test-IsTrackableInstalledVersion $version)){throw 'A trackable publisher version is required.'}
  }
  $stage=Join-Path $work 'stage';[void][IO.Directory]::CreateDirectory($stage)
  $target=if($p.Sub){Join-Path $stage $p.Sub}else{$stage};[void][IO.Directory]::CreateDirectory($target)
  Get-ChildItem -LiteralPath $payload -Force|Copy-Item -Destination $target -Recurse -Force
  if($Key -eq 'RE5'){
   $settings = Join-Path $target 're5vr.ini'
   if(-not [IO.File]::Exists($settings)){
    [IO.File]::WriteAllLines($settings, @(
     '[Camera]', 'FirstPerson=1', '',
     '[Graphics]', 'SteadyHands=1', '',
     '[VR]', 'StartInVR=1'
    ), [Text.Encoding]::ASCII)
   }
  }
  # The native --vr ISO argument records its own disc choice on first start.
  # Keep the publisher defaults only for a fresh install; existing INI is user-owned.
  $launch=Join-Path $stage 'PCVR-Launcher';[void][IO.Directory]::CreateDirectory($launch)
  Copy-Item -LiteralPath (Join-Path $script:OctoberNativeModules 'OctoberNativeVRLaunch.ps1') -Destination (Join-Path $launch ($Key+'-Start.ps1'))
  @{Key=$Key;Store=$route;App=$p.App;Exe=$p.Exe;Sub=$p.Sub;Required=$p.Required;Iso=$iso}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $launch ($Key+'-launch.json')) -Encoding UTF8
  $required=@($p.Required|ForEach-Object{if($p.Sub){Join-Path $p.Sub $_}else{$_}})+@(('PCVR-Launcher\'+$Key+'-Start.ps1'),('PCVR-Launcher\'+$Key+'-launch.json'))
  if($Key -eq 'RE5'){$required+=@('re5vr.ini')}
  $keep=@($p.Keep|ForEach-Object{if($p.Sub){Join-Path $p.Sub $_}else{$_}})
  $replace=@('PCVR-Launcher\'+$Key+'-launch.json')
  $group=New-PublisherVRGroup $game $stage $p.Identity $required $keep
  Set-OctoberNativeConfigPlan $group $Key $version $test
  $keep=@($group.Keep);$replace+=@($group.ReplaceChanged)
  $contract=New-PCVRInstallerContract -Id $p.Id -GameName $p.Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$p.Repo+'/releases') -RequiredInstalledFileGroups @($group.Required)
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the VR package...')
  Write-Host '  Backing up and installing VR. This may take a minute.' -ForegroundColor Cyan
  $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity $p.Identity -SnapshotRoot (Join-Path $work 'rollback')
  $changed=$true
  [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $p.Identity -KeepExistingRelativePaths $keep -ReplaceChangedOwnedRelativePaths $replace -ProgressLabel 'Installing VR')
  Protect-OctoberNativeConfigOwnership $group
  if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game $required[0]) -Force}
  if(@(Write-PublisherVRCheckpoint @($group) 'immediately-after-copy').Count){throw 'Required files were not copied. Check the selected folder, permissions and log.'}
  if($test.Failure -eq 'vanish'){Remove-Item -LiteralPath (Join-Path $game $required[0]) -Force}
  Write-Host '  Checking the installed files; this takes a few seconds.';Start-Sleep -Seconds 3
  if(@(Write-PublisherVRCheckpoint @($group) 'after-observation').Count){
   $recopy={ [void](Write-PublisherVRCheckpoint @($group) 'before-retry');[void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $p.Identity -KeepExistingRelativePaths $keep -ReplaceChangedOwnedRelativePaths $replace);Protect-OctoberNativeConfigOwnership $group;[void](Write-PublisherVRCheckpoint @($group) 'after-retry') }.GetNewClosure()
   $read=if($test){{'Q'}}else{$null}
   if(-not(Confirm-PlacedFilesSurvive -Paths @($required|ForEach-Object{Join-Path $game $_}) -GameDir $game -WaitSeconds 0 -Recopy $recopy -ReadInput $read -NoClear)){throw 'Required files disappeared. Restoring the previous installation.'}
  }
  if(@(Write-PublisherVRCheckpoint @($group) 'before-commit').Count){throw 'The full VR package could not be confirmed.'}
  if($test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
  $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -InstalledPathReceiptPaths @($receipt) -Route $route)
  $changed=$false
  if($iso){[void](Save-HubRememberedGameFolder -GameId $p.Id -Title $p.Title -GameDir (Split-Path $iso -Parent) -ProbeFiles @([IO.Path]::GetFileName($iso)) -StateName 'base_game_path' -UserSelected)}
  Write-Host ('  [OK] '+$p.Title+' '+$version+' installed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green;Write-Host ('  '+$p.Hint)
  Write-Host ''
  Write-Host ('  '+$p.Quip) -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{$failure=$_;if($changed){[void](Write-PublisherVRCheckpoint @($group) 'before-rollback');try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot;[void](Write-PublisherVRCheckpoint @($group) 'after-rollback')}catch{$keepWork=$true;Write-Host ('  Recovery copy: '+$work) -ForegroundColor Yellow}};throw $failure}
 finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession $work}}
}
function Invoke-OctoberNativeUninstall([string]$Key,[string]$InstallerFolder,[switch]$HubConfirmed){
 $p=Get-OctoberNativeProfile $Key;$test=Get-PublisherVRTestContext;$game=Get-OctoberNativeGame $p $test
 if(Get-Process -Name @([IO.Path]::GetFileNameWithoutExtension($p.Exe),'GoWEDay_VR') -ErrorAction SilentlyContinue){throw 'Close the game and launcher before removing VR.'}
 if(-not $HubConfirmed -and (Read-Host 'Type REMOVE to remove the Hub-owned VR package') -cne 'REMOVE'){return}
 [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.Identity)
 foreach($f in @((Join-Path $game '.pcvrhub_version'),$(if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}))){if([IO.File]::Exists($f)){Remove-Item -LiteralPath $f -Force}}
 Write-Host '  [OK] Hub-owned VR files removed; prior files restored. Your saves, changed settings and disc images are kept.' -ForegroundColor Green
}

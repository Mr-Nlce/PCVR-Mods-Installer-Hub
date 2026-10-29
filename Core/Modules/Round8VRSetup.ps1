# Publisher-specific installs for the October 25 batch. External launchers and
# the licensed base game deliberately keep separate presence/version proofs.
# Dementium's fixed release tag is not a version number. Online notes:
# https://raw.githubusercontent.com/King-EJ/Dementium-II-HD-VR/main/README.md
# Installed version is read independently from the delivered D2VR DLL metadata.
. (Join-Path $PSScriptRoot 'PublisherVRSetup.ps1')
. (Join-Path $PSScriptRoot 'BlackWhitePreparation.ps1')
$script:Round8ModuleRoot=$PSScriptRoot
function Get-Round8VRProfile([string]$Key) {
 switch($Key){
  'BlackWhite' {return @{Key=$Key;Id='black-white-vr';Folder='BlackWhiteVR';Title='Black & White VR';Repo='BW1-VR/BW1-VR';Exe='runblack.exe';Game='Black & White';App='';Base=@('runblack.exe');Required=@('ddraw.dll','openxr_loader.dll','Black & White VR Mod.exe','dxwrapper\ddraw.dll','dxwrapper\dxwrapper.dll','dxwrapper\dxwrapper.ini','dxwrapper\ddraw.ini','Black & White VR Mod readme.txt','Black & White VR Mod notices.txt');Identity='blackwhitevr';Quip='Please do not teach the Creature to eat the villagers.'}}
  'Dementium' {return @{Key=$Key;Id='dementium-ii-hd-vr';Folder='DementiumIIHDVR';Title='Dementium II HD VR';Repo='King-EJ/Dementium-II-HD-VR';Exe='DII_Beta.exe';Game='Dementium 2';App='217100';Base=@('DII_Beta.exe','DII_Beta_Data\Managed\Assembly-CSharp.dll');Required=@('version.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll','BepInEx\plugins\D2VR\D2VR.dll','BepInEx\plugins\D2VR\d2xr.dll');Identity='dementiumvr';Quip='The hospital discharge paperwork may take a while.'}}
  'TombLegend' {return @{Key=$Key;Id='tomb-raider-legend-vr';Folder='TombRaiderLegendVR';Title='Tomb Raider: Legend VR';Repo='RototRobot/Tomb-Raider-Legend-VR-Port';Exe='trl.exe';Game='Tomb Raider Legend';App='7000';Base=@('trl.exe');Required=@('d3d9.dll','d3d9_dxvk.dll','openvr_api.dll','trlvr_launcher.exe','trlvr_actions.json','bindings_oculus_touch.json','bindings_knuckles.json','bindings_holographic_controller.json','bindings_hpmotioncontroller.json');Identity='trlvr';Quip='A grappling hook is cheaper than another plane ticket.'}}
  'FF7' {return @{Key=$Key;Id='ff7-remake-intergrade-vr';Folder='FF7RemakeVR';Title='Final Fantasy VII Remake Intergrade VR';Repo='Gilleece/ff7-remake-vr';Exe='End\Binaries\Win64\ff7remake_.exe';Game='FINAL FANTASY VII REMAKE';App='1462040';Base=@('End\Binaries\Win64\ff7remake_.exe|End\Binaries\WinGDK\ff7remake_.exe');Required=@('xinput1_3.dll','ff7vr.ini','ff7vr-launcher.ps1','ff7vr-stores.ps1','start-vr.cmd','restore.cmd','collect-diagnostics.cmd','VERSION.txt');Identity='ff7vr';Quip='This train has no brakes. Barret checked.'}}
  'HotD2PC2VR' {return @{Key=$Key;Id='house-of-the-dead-2-original-vr';Folder='HotD2PC2VR';Title='The House of the Dead 2 - PC2VR';Repo='fjdiazt/hotd2-pc2vr';Exe='Hod2.exe';Game='The House of the Dead 2';App='';Base=@('Hod2.exe','Config.exe');Required=@('vr\HOTD2VR.exe','vr\HOTD2Bridge.dll','vr\injector.exe','vr\openxr_loader.dll','vr\gun.obj','vr\gun.mtl','vr\gun.bmp','vr\start.bat');Identity='hotd2pc2vr';Quip='Suffer like G did. Preferably with both guns loaded.'}}
  default {throw 'Unknown VR publisher profile.'}
 }
}
function Get-Round8VRTest {
 if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_ROUND8_TEST){return $null}
 $path=[IO.Path]::GetFullPath($env:PCVR_ROUND8_TEST);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
 if(-not $path.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture configuration escaped Temp.'}
 $c=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json;$root=[IO.Path]::GetFullPath($c.Root).TrimEnd('\')+'\'
 if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_round8_fixture'))){throw 'Missing isolated fixture sentinel.'}
 foreach($name in @('Game','Local','Roaming','Desktop','Receipt')){if(-not ([IO.Path]::GetFullPath([string]$c.$name)).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture destination escaped its sentinel.'}}
 return $c
}
function Test-Round8Base($Profile,[string]$Root) {
 if(-not $Root){return $false}
 foreach($group in $Profile.Base){$found=$false;foreach($rel in ($group -split '\|')){if(Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf){$found=$true;break}};if(-not $found){return $false}}
 return $true
}
function Resolve-Round8GameRoot($Profile,[string]$Path) {
 if(-not $Path){return $null};$path=$Path.Trim().Trim('"').Trim("'")
 if(Test-Path -LiteralPath $path -PathType Leaf){$path=Split-Path -Parent $path}
 for($i=0;$i -lt 5 -and $path;$i++){if(Test-Round8Base $Profile $path){return [IO.Path]::GetFullPath($path)};$path=Split-Path -Parent $path}
 return $null
}
function Get-Round8Game($Profile,$Test) {
 if($Profile.Key -eq 'BlackWhite' -and $global:BlackWhiteSelectedGame){
  if(Test-Round8Base $Profile $global:BlackWhiteSelectedGame){return [string]$global:BlackWhiteSelectedGame}
  throw 'The selected Black & White game is no longer available.'
 }
 if($Test){if(-not(Test-Round8Base $Profile $Test.Game)){throw 'The base game is incomplete.'};return [string]$Test.Game}
 foreach($stateName in @('user_located','mod_b_path','installed_path')){
  $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @($stateName) -ProbeFiles @()
  $root=Resolve-Round8GameRoot $Profile $saved;if($root){return $root}
 }
 if($Profile.App){try{$root=Resolve-Round8GameRoot $Profile (Find-SteamGameFolder -AppId $Profile.App -SteamFolderNames @($Profile.Game) -ProbeExe $Profile.Exe -HubGameId $Profile.Id);if($root){return $root}}catch{}}
 $paths=switch($Profile.Key){
  'BlackWhite'{@('C:\Program Files (x86)\Lionhead Studios Ltd\Black & White','C:\Black & White')}
  'TombLegend'{@('C:\GOG Games\Tomb Raider Legend','C:\Program Files (x86)\GOG Galaxy\Games\Tomb Raider Legend')}
  'FF7'{@('C:\Program Files\Epic Games\FFVIIRemakeIntergrade','C:\XboxGames\FINAL FANTASY VII REMAKE INTERGRADE\Content')}
  'HotD2PC2VR'{@('C:\Program Files (x86)\SEGA\THE HOUSE OF THE DEAD 2','C:\Program Files\SEGA\THE HOUSE OF THE DEAD 2')}
  default{@()}
 }
 foreach($path in $paths){$root=Resolve-Round8GameRoot $Profile $path;if($root){return $root}}
 while($true){
  Write-Host '  Choose your own installed game. Drag its game EXE here, or paste its folder.' -ForegroundColor Cyan
  $picked=Read-Host '  Game EXE / folder (Q cancels)';if($picked -match '^(?i:q)$'){throw 'Game selection cancelled.'}
  $root=Resolve-Round8GameRoot $Profile $picked;if($root){
   $proofs=@();foreach($group in $Profile.Base){foreach($rel in ($group -split '\|')){if(Test-Path -LiteralPath (Join-Path $root $rel) -PathType Leaf){$proofs+=@($rel);break}}}
   if(-not(Save-HubRememberedGameFolder -GameId $Profile.Id -Title $Profile.Title -GameDir $root -ProbeFiles $proofs -UserSelected)){throw 'The selected game folder could not be saved. Retry after checking write access to Hub state.'}
   return $root
  }
  Write-Host '  That folder does not contain the complete expected base game. Please choose again.' -ForegroundColor Yellow
 }
}
function Get-Round8Store($Profile,[string]$Game,$Test) {
 if($Test){return [string]$Test.Store}
 if($Profile.Key -eq 'BlackWhite' -or $Profile.Key -eq 'HotD2PC2VR'){return 'Retail'}
 if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
 if($Profile.Key -eq 'Dementium'){return 'Steam'}
 if($Profile.Key -eq 'TombLegend'){$marker=Join-Path $Game '.pcvrhub_trl_store.txt';if(Test-Path -LiteralPath $marker){$savedStore=[IO.File]::ReadAllText($marker).Trim();if($savedStore -in @('Steam','GOG')){return $savedStore}};return 'GOG'}
 if($Game -match '(?i)[\\/](XboxGames|WinGDK)[\\/]' -or (Test-Path -LiteralPath (Join-Path $Game 'End\Binaries\WinGDK\ff7remake_.exe'))){return 'Xbox'}
 if($Game -match '(?i)[\\/]Epic Games[\\/]'){return 'Epic'}
 while($true){switch((Read-Host '  Store: 1 = Steam, 2 = Epic, 3 = Xbox').Trim()){'1'{return 'Steam'}'2'{return 'Epic'}'3'{return 'Xbox'}}}
}
function global:Invoke-Round8Native([string]$File,[string[]]$Arguments=@()) {
 # Start-Process does not turn stderr text into a terminating native command
 # error under PowerShell 5.1. Only the actual process exit code decides.
 $process=Start-Process -FilePath $File -ArgumentList $Arguments -Wait -PassThru -ErrorAction Stop
 if($null -eq $process -or $null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw ('Publisher program failed (exit '+$process.ExitCode+').')}
}
function Get-Round8PluginVersion([string]$Stage) {
 $cecil=Join-Path $Stage 'BepInEx\core\Mono.Cecil.dll'
 # Loading metadata support from bytes avoids locking the extracted DLL until
 # PowerShell exits, which would otherwise break successful temp cleanup.
 [void][Reflection.Assembly]::Load([IO.File]::ReadAllBytes($cecil))
 $assembly=[Mono.Cecil.AssemblyDefinition]::ReadAssembly((Join-Path $Stage 'BepInEx\plugins\D2VR\D2VR.dll'))
 try{foreach($type in $assembly.MainModule.Types){foreach($attribute in $type.CustomAttributes){if($attribute.AttributeType.Name -eq 'BepInPlugin' -and [string]$attribute.ConstructorArguments[0].Value -eq 'dementium2hd.vr'){return 'v'+[string]$attribute.ConstructorArguments[2].Value}}}}finally{$assembly.Dispose()}
 throw 'Dementium VR does not identify its plugin version.'
}
function Restore-Round8FF7Session([string]$Game,[string]$Runtime,$Test){
 $sessions=@('Win64','WinGDK'|ForEach-Object{Join-Path $Game ('End\Binaries\'+$_+'\ff7vr.session.json')}|Where-Object{Test-Path -LiteralPath $_ -PathType Leaf})
 if(-not $sessions.Count){return}
 if($Test){throw 'Restore the active publisher session before changing the VR installation.'}
 $launcher=Join-Path $Runtime 'ff7vr-launcher.ps1';if(-not(Test-Path -LiteralPath $launcher -PathType Leaf)){throw 'An unfinished VR session was found but its publisher launcher is missing. Restore the launcher package before changing the game.'}
 Write-Host '  An interrupted FF7 VR session must be restored before setup can continue.' -ForegroundColor Yellow
 Write-Host '  The existing publisher launcher will restore the normal game files and preserve session settings.' -ForegroundColor Yellow
 [void](Wait-PCVRExplicitEnter -Message 'Press Enter to restore the previous VR session...')
 Invoke-Round8Native -File (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -Arguments @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$launcher+'"'),'restore','-GameDir',('"'+$Game+'"'),'-NoPause')
 if(@($sessions|Where-Object{Test-Path -LiteralPath $_ -PathType Leaf}).Count){throw 'The publisher session could not be restored. Review restore.cmd and its session record before retrying.'}
}
function global:Get-Round8RequiredMissing($Groups,[string]$Phase){
 $missing=@();foreach($g in $Groups){foreach($group in $g.Required){$present=$false;foreach($rel in ($group -split '\|')){if(Test-Path -LiteralPath (Join-Path $g.Root $rel) -PathType Leaf){$present=$true;break}};Write-PCVRFileCheckResult -Path (Join-Path $g.Root $group) -Present $present -Phase $Phase -DisplayName $group;if(-not $present){$missing+=Join-Path $g.Root (($group -split '\|')[0])}}};return $missing
}
function global:Copy-Round8Groups($Groups,[string]$Key){
 $game=$Groups[0].Root
 $parked=$Key -eq 'TombLegend' -and (Test-Path -LiteralPath (Join-Path $game 'd3d9.dll.pcvrhub_off'))
 if($parked){if(Test-Path -LiteralPath (Join-Path $game 'd3d9.dll')){throw 'Both active and parked VR proxy files exist. Resolve that conflict before updating.'};Move-Item -LiteralPath (Join-Path $game 'd3d9.dll.pcvrhub_off') -Destination (Join-Path $game 'd3d9.dll')}
 foreach($g in $Groups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $g.Root -Identity $g.Identity -KeepExistingRelativePaths $g.Keep -ProgressLabel 'Installing the VR runtime')}
 if($parked){Move-Item -LiteralPath (Join-Path $game 'd3d9.dll') -Destination (Join-Path $game 'd3d9.dll.pcvrhub_off');$Groups[0].Required=@($Groups[0].Required|ForEach-Object{if($_ -eq 'd3d9.dll'){'d3d9.dll|d3d9.dll.pcvrhub_off'}else{$_}})}
}
function Get-Round8FirstEvidencePath($Group){
 foreach($relative in ([string]$Group.Required[0] -split '\|')){$path=Join-Path $Group.Root $relative;if(Test-Path -LiteralPath $path -PathType Leaf){return $path}}
 return Join-Path $Group.Root (([string]$Group.Required[0] -split '\|')[0])
}
function Get-Round8PublisherExe($Profile,[string]$Work,$Test) {
 if($Test){return @{Path=[string]$Test.Archives.Main.Path;Tag=[string]$Test.Archives.Main.Tag}}
 $page='https://github.com/'+$Profile.Repo+'/releases';$script:Round8RecoveryPage=$page
 $handed=Get-PCVRRecoveryInput -PathType Leaf
 if($handed -and [IO.Path]::GetExtension($handed) -ieq '.exe'){
  $stream=[IO.File]::OpenRead($handed);try{$usable=$stream.ReadByte() -eq 77 -and $stream.ReadByte() -eq 90}finally{$stream.Dispose()}
  if(-not $usable){throw 'The handed-over file is not a Windows Setup executable.'}
  do{$v=(Read-Host '  Version shown on the official release page for this Setup').Trim()}until(Test-IsTrackableInstalledVersion $v)
  [void](Set-PCVRRecoveryInput '');return @{Path=$handed;Tag=$v}
 }
 $r=Resolve-GitHubReleaseAsset -Repo $Profile.Repo -AssetPatterns @('(?i)^Black[. ]White[. ]VR[. ]Mod.+Setup\.exe$') -SkipReleasesWithoutMatchingAsset
 if($r.Resolved -and $r.Url){$dest=Join-Path $Work 'BlackWhiteVR-Setup.exe';[void](Invoke-SafeDownload -Urls @($r.Url) -Destination $dest -Label 'Black & White VR publisher Setup' -ManualUrl $page -AllowSkip $false -PlainProgress);return @{Path=$dest;Tag=$r.Tag}}
 [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to open the official release page and download its Setup EXE...')
 while($true){$path=Get-PCVRRecoveryInput -PathType Leaf;if(-not $path){$path=(Read-Host '  Drag/paste the downloaded publisher Setup EXE').Trim().Trim('"')};if($path -and (Test-Path -LiteralPath $path -PathType Leaf) -and [IO.Path]::GetExtension($path) -ieq '.exe'){do{$v=(Read-Host '  Version shown on that release page').Trim()}until(Test-IsTrackableInstalledVersion $v);return @{Path=$path;Tag=$v}}}
}
function Show-Round8Preparation($Profile,[string]$Game,[string]$Store,$Test) {
 if($Profile.Key -eq 'BlackWhite'){
  Write-Host '';Write-Host '  REQUIRED: ORIGINAL BLACK & WHITE + PATCH 1.42' -ForegroundColor Black -BackgroundColor Yellow
  Write-Host '  Install official patch 1.10, then 1.20, then unofficial patch 1.42.' -ForegroundColor Yellow
  Write-Host '  No patch 1.30, Creature Isle, changed EXE or other ddraw.dll wrapper.' -ForegroundColor Yellow
  Write-Host '  Start once in flat and quit before installing VR. Publisher Setup validates the game build.' -ForegroundColor Yellow
  if(-not(Test-Path -LiteralPath (Join-Path $Game 'readme-patch-v142.txt'))){
   if($Test -and -not $Test.Patches){throw 'Patch 1.42 is required before installing VR.'}
   Install-BlackWhitePatches -Game $Game -Test $Test
   if(-not(Test-Path -LiteralPath (Join-Path $Game 'readme-patch-v142.txt'))){throw 'Patch 1.42 is not present in the selected game folder. Install it there, then Retry.'}
  }
  if(-not $Test -and (Read-Host '  Has this patched game already reached its main menu in flat? Y/N').Trim() -notmatch '^(?i:y|yes)$'){
   $publisherLauncher=Join-Path $Game 'Black & White VR Mod.exe'
   if(Test-Path -LiteralPath $publisherLauncher){Write-Host '  In the publisher launcher choose Play, no VR. Reach the main menu, quit, then close the launcher.' -ForegroundColor Yellow;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher launcher for flat play...');Start-Process -FilePath $publisherLauncher -WorkingDirectory $Game -Wait}
   else{[void](Wait-PCVRExplicitEnter -Message 'Press Enter to start the patched game in flat. Reach its main menu, then quit...');Start-Process -FilePath (Join-Path $Game 'runblack.exe') -WorkingDirectory $Game -Wait}
  }
 }elseif($Profile.Key -eq 'TombLegend'){
  Write-Host '';Write-Host '  REQUIRED GAME SETUP: NEXT GENERATION CONTENT = OFF' -ForegroundColor Black -BackgroundColor Yellow
  Write-Host '  Run the game once in flat, open its Setup dialog, turn OFF Next Generation Content, then quit.' -ForegroundColor Yellow
  Write-Host '  That renderer otherwise produces a black scene in VR. Start SteamVR before playing.' -ForegroundColor Yellow
  if(-not $Test -and (Read-Host '  Is this already done? Y/N').Trim() -notmatch '^(?i:y|yes)$'){
   [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the normal game Setup...')
   if($Store -eq 'Steam'){Start-Process 'steam://rungameid/7000'}else{Start-Process -FilePath (Join-Path $Game 'trl.exe') -ArgumentList '-setup' -WorkingDirectory $Game}
   [void](Wait-PCVRExplicitEnter -Message 'After saving the setting and closing the game, press Enter to continue...')
  }
 }elseif($Profile.Key -eq 'FF7'){
  Write-Host '  WIP: game build 1.0.0.7 is known. Steam is tested by the publisher; Epic and Xbox remain experimental.' -ForegroundColor Yellow
  Write-Host '  The separate launcher temporarily installs VR and restores your normal graphics setup when the game exits.' -ForegroundColor White
  Write-Host '  Leave its window open while playing. It also waits between sessions to avoid the known slow-restart problem.' -ForegroundColor Yellow
  if($Store -ne 'Steam'){Write-Host '  EXPERIMENTAL STORE: a different EXE build will run without VR. Xbox folders must permit advanced management.' -ForegroundColor Yellow;if(-not $Test -and (Read-Host '  Continue with this experimental store? Y/N').Trim() -notmatch '^(?i:y|yes)$'){throw 'Experimental installation cancelled.'}}
 }
}
function Invoke-Round8VRSetup([string]$Key,[string]$InstallerFolder) {
 $ErrorActionPreference='Stop';$p=Get-Round8VRProfile $Key;$test=Get-Round8VRTest
 $work=$null;$groups=@();$changed=$false;$keepWork=$false;$shortcut=$null;$oldShortcut=$null;$shortcutChanged=$false;$previousHotdA=$null;$hotdStateBefore=$null;$hotdStateWritten=$false
 try{
  Write-Host '============================================================' -ForegroundColor Cyan;Write-Host ('  '+$p.Title+' setup') -ForegroundColor Cyan;Write-Host '============================================================' -ForegroundColor Cyan
  Write-Host '  Close the game before installation or updates. Your own complete PC game is required.' -ForegroundColor White
  if($Key -eq 'Dementium'){Write-Host '  32-bit OpenXR runtime with OpenGL support. VR needs -force-opengl; the Hub start controller supplies it.' -ForegroundColor Yellow}
  if($Key -eq 'HotD2PC2VR'){Write-Host '  Second independent mod for the ORIGINAL Windows game, not the Remake. Icedomega13 files are kept.' -ForegroundColor Yellow;Write-Host '  Only the original EXE build listed by the publisher is supported; its launcher checks the game.' -ForegroundColor Yellow}
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message ('After reading this, press Enter to locate '+$p.Game+'...'))
  $game=Get-Round8Game $p $test;$store=Get-Round8Store $p $game $test;Write-Host ('  [OK] Game ('+$store+'): '+$game) -ForegroundColor Green
  if($Key -eq 'HotD2PC2VR'){$previousHotdA=Get-PCVRRememberedGameFolder -GameId $p.Id -StateNames @('mod_a_path','installed_path') -ProbeFiles @('HotD2VR.exe','install.json','working\pcvr\game\Hod2.exe','working\pcvr\game\ddraw.dll','working\pcvr\game\openxr_loader.dll')}
  foreach($process in @([IO.Path]::GetFileNameWithoutExtension($p.Exe),$(if($Key -eq 'FF7'){'ff7remake_'}),$(if($Key -eq 'HotD2PC2VR'){'HOTD2VR'}))|Where-Object {$_}){if(Get-Process -Name $process -ErrorAction SilentlyContinue){throw 'Close the game and VR launcher before continuing.'}}
  if($Key -eq 'BlackWhite' -and -not $test){if(Invoke-BlackWhitePermissionHandoff -Game $game -InstallerFolder $InstallerFolder){return}}
  Show-Round8Preparation $p $game $store $test
  $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
  [void](Wait-PCVRExplicitEnter -Message ('Press Enter to check and download the current '+$p.Title+' package...'))
  $version='';$native=$Key -eq 'BlackWhite';$runtime=$game
  if($native){
   $a=Get-Round8PublisherExe $p $work $test;$version=$a.Tag
   $stage=Join-Path $work 'native-plan';[void][IO.Directory]::CreateDirectory($stage)
   foreach($name in $p.Required){$path=Join-Path $stage $name;[void][IO.Directory]::CreateDirectory((Split-Path $path -Parent));[IO.File]::WriteAllText($path,'native publisher plan')}
   $groups+=New-PublisherVRGroup $game $stage $p.Identity $p.Required
   # Native Setup owns its registry entry, original-ddraw backup and uninstaller.
   $groups[0].Required=@($p.Required)
  }else{
   $pattern=switch($Key){'Dementium'{'(?i)^Dementium.*VR.*\.zip$'}'TombLegend'{'(?i)^TRLVRmod[-_.].+\.zip$'}'HotD2PC2VR'{'(?i)^HOTD2-PC2VR-.+-windows-x64\.zip$'}'FF7'{'(?i)^ff7vr-(?!.*(?:dlss|dropin)).+\.zip$'}}
   if($Key -eq 'FF7'){
    $variantPath=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\FF7VR\.pcvrhub_ff7_variant.txt'
    $previousDlss=(Test-Path -LiteralPath $variantPath) -and [IO.File]::ReadAllText($variantPath).Trim() -eq 'DLSS'
    $dlss=if($test){[bool]$test.Dlss}else{Write-Host '  1. Standard launcher (recommended, all supported GPUs)' -ForegroundColor Green;Write-Host '  2. Experimental DLSS launcher (NVIDIA RTX only)' -ForegroundColor Yellow;$choice=(Read-Host ('  Choose 1 or 2 (Enter = '+$(if($previousDlss){'keep DLSS'}else{'standard'})+')')).Trim();if(-not $choice){$previousDlss}else{$choice -eq '2'}}
    if($dlss){$pattern='(?i)^ff7vr-(?!.*dropin).+-dlss\.zip$'}
   }
   $functionalProbe=switch($Key){'Dementium'{'D2VR.dll'}'TombLegend'{'trlvr_launcher.exe'}'FF7'{'ff7vr-launcher.ps1'}'HotD2PC2VR'{'HOTD2Bridge.dll'}}
   $a=Get-PublisherVRArchive $p.Repo @($pattern) $p.Title $work $test 'Main' $functionalProbe -PlainProgress;$version=$a.Tag
   $expanded=Expand-PublisherVRArchive $a (Join-Path $work 'main')
   if($Key -eq 'Dementium'){
    $stage=Find-PublisherVRPayload $expanded 'version.dll';$version=Get-Round8PluginVersion $stage
    if(Test-Path -LiteralPath (Join-Path $game 'BepInEx\core\BepInEx.Unity.IL2CPP.dll')){throw 'This game needs the bundled BepInEx 5 x86 Mono loader, not an IL2CPP loader.'}
    $loaderStage=Join-Path $work 'dementium-loader';$pluginStage=Join-Path $work 'dementium-plugin';[void][IO.Directory]::CreateDirectory($loaderStage);[void][IO.Directory]::CreateDirectory($pluginStage)
    $base=[IO.Path]::GetFullPath($stage).TrimEnd('\')
    foreach($file in Get-ChildItem -LiteralPath $stage -Recurse -File){$rel=$file.FullName.Substring($base.Length+1);$dst=if($rel -like 'BepInEx\plugins\D2VR\*' -or $rel -eq 'BepInEx\config\dementium2hd.vr.cfg'){$pluginStage}else{$loaderStage};$target=Join-Path $dst $rel;[void][IO.Directory]::CreateDirectory((Split-Path $target -Parent));Copy-Item -LiteralPath $file.FullName -Destination $target}
    $groups+=New-PublisherVRGroup $game $loaderStage 'dementiumloader' @('version.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll') @('doorstop_config.ini','BepInEx\config\BepInEx.cfg')
    $groups+=New-PublisherVRGroup $game $pluginStage $p.Identity @('BepInEx\plugins\D2VR\D2VR.dll','BepInEx\plugins\D2VR\d2xr.dll') @('BepInEx\config\dementium2hd.vr.cfg')
   }elseif($Key -eq 'TombLegend'){
    $payload=Find-PublisherVRPayload $expanded 'trlvr_launcher.exe';$stage=Join-Path $work 'legend-stage';Copy-Item -LiteralPath $payload -Destination $stage -Recurse
    [void][IO.Directory]::CreateDirectory((Join-Path $stage 'TRLVR docs'));foreach($f in @(Get-ChildItem -LiteralPath $expanded -File)){Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $stage 'TRLVR docs')}
    if(Test-Path -LiteralPath (Join-Path $expanded 'Licences')){Copy-Item -LiteralPath (Join-Path $expanded 'Licences') -Destination (Join-Path $stage 'TRLVR docs') -Recurse}
    [IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_trl_store.txt'),$store)
    $groups+=New-PublisherVRGroup $game $stage $p.Identity (@($p.Required)+@('.pcvrhub_trl_store.txt')) @('trlvr.ini')
   }elseif($Key -eq 'FF7'){
    $stage=Find-PublisherVRPayload $expanded 'ff7vr-launcher.ps1';$v=[IO.File]::ReadAllText((Join-Path $stage 'VERSION.txt'));if($v -notmatch '(?im)^ff7vr\s+(v?\d+(?:\.\d+)+)'){throw 'The launcher package has no readable publisher version.'};$version=$Matches[1]
    $local=if($test){$test.Local}else{$env:LOCALAPPDATA};$runtime=Join-Path $local 'PCVR Mods Installer Hub\FF7VR'
    Restore-Round8FF7Session $game $runtime $test
    Copy-Item -LiteralPath (Join-Path $InstallerFolder 'Start-FF7VR.ps1') -Destination $stage
    [IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_ff7_variant.txt'),$(if($dlss){'DLSS'}else{'Standard'}))
    [IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_ff7_game.txt'),$game);[IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_ff7_store.txt'),$store.ToLowerInvariant())
    $groups+=New-PublisherVRGroup $runtime $stage $p.Identity (@($p.Required)+@('Start-FF7VR.ps1','.pcvrhub_ff7_game.txt','.pcvrhub_ff7_store.txt','.pcvrhub_ff7_variant.txt')) @('ff7vr.ini')
    $modeStage=Join-Path $work 'mode';[void][IO.Directory]::CreateDirectory($modeStage);[IO.File]::WriteAllText((Join-Path $modeStage '.pcvrhub_ff7_mode.ini'),"[Hub]`r`nMode=VR`r`n")
    $groups+=New-PublisherVRGroup $game $modeStage 'ff7vrmode' @('.pcvrhub_ff7_mode.ini') @('.pcvrhub_ff7_mode.ini')
    if($dlss){
     $bin=if(Test-Path -LiteralPath (Join-Path $game 'End\Binaries\Win64\ff7remake_.exe')){Join-Path $game 'End\Binaries\Win64'}else{Join-Path $game 'End\Binaries\WinGDK'}
     if(-not(Test-Path -LiteralPath (Join-Path $bin 'nvngx_dlss.dll'))){
      $nv=Join-Path $work 'nvidia';[void][IO.Directory]::CreateDirectory($nv)
      Write-Host '  DLSS uses NVIDIA nvngx_dlss.dll from the official SDK; the NVIDIA licence applies.' -ForegroundColor Yellow
      [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the optional NVIDIA DLSS runtime...')
      if($test){Copy-Item -LiteralPath $test.Archives.Dlss.Path -Destination (Join-Path $nv 'nvngx_dlss.dll')}else{[void](Invoke-SafeDownload -Urls @('https://raw.githubusercontent.com/NVIDIA/DLSS/main/lib/Windows_x86_64/rel/nvngx_dlss.dll') -Destination (Join-Path $nv 'nvngx_dlss.dll') -Label 'NVIDIA DLSS runtime' -ManualUrl 'https://github.com/NVIDIA/DLSS/tree/main/lib/Windows_x86_64/rel' -AllowSkip $false -PlainProgress)}
      $groups+=New-PublisherVRGroup $bin $nv 'ff7vrdlss' @('nvngx_dlss.dll')
     }
    }
   }else{
    $stage=$expanded;$keep=@('vr\HOTD2VR.ini','vr\HOTD2VR.checkpoint.ini','vr\HOTD2VR.original.checkpoint.ini')
    Copy-Item -LiteralPath (Join-Path $InstallerFolder 'Start-PC2VR.ps1') -Destination (Join-Path $stage 'vr')
    Copy-Item -LiteralPath (Join-Path $InstallerFolder '..\HotD2VR\HotD2VR.ico') -Destination (Join-Path $stage 'vr\PC2VR.ico')
    [IO.File]::WriteAllText((Join-Path $stage 'vr\pcvrhub-mode.ini'),"[Hub]`r`nMode=VR`r`n")
    $groups+=New-PublisherVRGroup $game $stage $p.Identity (@($p.Required)+@('vr\Start-PC2VR.ps1','vr\pcvrhub-mode.ini','vr\PC2VR.ico')) (@($keep)+@('vr\pcvrhub-mode.ini'))
   }
  }
  if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The publisher package has no trackable version.'}
  foreach($g in $groups){if(-not(Test-InstallerTargetWritable -TargetPath $g.Root)){throw ('The target is not writable: '+$g.Root)};if(-not $native){foreach($name in $g.Required|Where-Object{$_ -notlike '.pcvrhub_*_ownership.csv'}){if(-not(Test-Path -LiteralPath (Join-Path $g.Stage $name))){throw ('Required publisher file is missing: '+$name)}}}}
  if($native){Write-Host ('  In publisher Setup, install into exactly: '+$game) -ForegroundColor Yellow}
  [void](Wait-PCVRExplicitEnter -Message $(if($native){'Press Enter to open publisher Setup (Windows will request UAC)...'}else{'Press Enter to install the complete VR package and keep existing settings...'}))
  Write-Host '  Preparing a recovery copy of affected files; this may take a few seconds.' -ForegroundColor Cyan
  foreach($g in $groups){$g.Snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $g.Root -Stage $g.Stage -Identity $g.Identity -SnapshotRoot (Join-Path $work ('rollback-'+$g.Identity)) -ExtraPaths @('.pcvrhub_version_b','d3d9.dll.pcvrhub_off')}
  $changed=$true
  if($native){
   if($test){Invoke-Round8Native -File $test.NativeFile -Arguments @($test.NativeArguments)}else{Invoke-Round8Native -File $a.Path -Arguments @('/NORESTART',('/DIR="'+$game+'"'))}
  }else{
   # A parked proxy remains parked across update/reinstall. The temporary
   # unpark occurs only inside the rollback-protected ownership transaction.
   Copy-Round8Groups $groups $Key
  }
  if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Get-Round8FirstEvidencePath $groups[0]) -Force}
  if(@(Get-Round8RequiredMissing $groups 'immediately-after-copy-or-publisher').Count){throw 'Required files are missing. Check the chosen folder, write permissions and installer log. No antivirus cause has been established.'}
  if($test.Failure -eq 'vanish'){Remove-Item -LiteralPath (Get-Round8FirstEvidencePath $groups[0]) -Force}
  Write-Host '  Checking that the complete runtime stays available; this takes a few seconds.' -ForegroundColor Cyan;Start-Sleep -Seconds 3
  $missing=@(Get-Round8RequiredMissing $groups 'after-observation')
  if($missing.Count){
   $recopy={
    [void](Get-Round8RequiredMissing $groups 'before-retry')
    if($native){if($test){Invoke-Round8Native -File $test.NativeFile -Arguments @($test.NativeArguments)}else{Invoke-Round8Native -File $a.Path -Arguments @('/NORESTART',('/DIR="'+$game+'"'))}}else{Copy-Round8Groups $groups $Key}
    [void](Get-Round8RequiredMissing $groups 'after-retry')
   }.GetNewClosure()
   $reader=if($test){$reads=@{Count=0};$recover=[string]$test.Recover;{$reads.Count++;if($reads.Count -eq 1 -and $recover -eq 'R'){'R'}else{'Q'}}.GetNewClosure()}else{$null}
   if(-not(Confirm-PlacedFilesSurvive -Paths $missing -GameDir $game -WaitSeconds 0 -Recopy $recopy -ReadInput $reader -NoClear)){throw 'Required files are unavailable after installation; the earlier files will be restored.'}
  }
  if($Key -in @('Dementium','TombLegend','FF7','HotD2PC2VR','BlackWhite')){
   $desktop=if($test){$test.Desktop}elseif($Key -eq 'BlackWhite' -and $global:BlackWhiteDesktopOverride){$global:BlackWhiteDesktopOverride}else{[Environment]::GetFolderPath('Desktop')};[void][IO.Directory]::CreateDirectory($desktop)
   $linkName=switch($Key){'BlackWhite'{'Black & White VR'}'Dementium'{'Dementium II HD VR'}'TombLegend'{'Tomb Raider Legend VR'}'FF7'{'Final Fantasy VII Remake VR'}'HotD2PC2VR'{'The House of the Dead 2 VR - PC2VR'}}
   $shortcut=Join-Path $desktop ($linkName+'.lnk');if(Test-Path -LiteralPath $shortcut){$oldShortcut=[IO.File]::ReadAllBytes($shortcut)}
   $ws=New-Object -ComObject WScript.Shell;$link=$ws.CreateShortcut($shortcut)
   if($Key -eq 'FF7'){$link.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe';$link.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $runtime 'Start-FF7VR.ps1')+'"';$link.WorkingDirectory=$runtime;$icon=Join-Path $game $p.Exe;if(-not(Test-Path -LiteralPath $icon)){$icon=Join-Path $game 'End\Binaries\WinGDK\ff7remake_.exe'};$link.IconLocation=$icon+',0'}
   elseif($Key -eq 'HotD2PC2VR'){$link.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe';$link.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $game 'vr\Start-PC2VR.ps1')+'"';$link.WorkingDirectory=Join-Path $game 'vr';$link.IconLocation=(Join-Path $game 'vr\PC2VR.ico')+',0'}
   elseif($Key -eq 'Dementium'){$link.TargetPath=Join-Path $game 'DII_Beta.exe';$link.Arguments='-force-opengl';$link.WorkingDirectory=$game;$link.IconLocation=$link.TargetPath+',0'}
   elseif($Key -eq 'TombLegend' -and $store -eq 'Steam'){$link.TargetPath=Join-Path $env:WINDIR 'explorer.exe';$link.Arguments='steam://rungameid/7000';$link.WorkingDirectory=$game;$link.IconLocation=(Join-Path $game 'trl.exe')+',0'}
   else{$link.TargetPath=Join-Path $game $(if($native){'Black & White VR Mod.exe'}else{'trlvr_launcher.exe'});$link.WorkingDirectory=$game;$link.IconLocation=$(if($native){$link.TargetPath}else{Join-Path $game 'trl.exe'})+',0'}
   if($oldShortcut){$previous=$ws.CreateShortcut($shortcut);$same=([string]$previous.TargetPath).Equals([string]$link.TargetPath,[StringComparison]::OrdinalIgnoreCase) -and ([string]$previous.Arguments).Equals([string]$link.Arguments,[StringComparison]::OrdinalIgnoreCase);$ownedTombRoute=$Key -eq 'TombLegend' -and ([string]$previous.WorkingDirectory).Equals($game,[StringComparison]::OrdinalIgnoreCase) -and (($previous.TargetPath -ieq (Join-Path $game 'trlvr_launcher.exe')) -or ($previous.TargetPath -ieq (Join-Path $env:WINDIR 'explorer.exe') -and $previous.Arguments -eq 'steam://rungameid/7000'));if(-not $same -and -not $ownedTombRoute){throw 'A different desktop shortcut already uses this name. Rename it before retrying; it has been kept.'}}
   $link.Save();$shortcutChanged=$true
  }
  if($Key -eq 'TombLegend' -and $store -eq 'Steam'){
   $options='"'+(Join-Path $game 'trlvr_launcher.exe')+'" %command%'
   Write-Host '';Write-Host '  REQUIRED STEAM LAUNCH OPTIONS' -ForegroundColor Black -BackgroundColor Yellow;Write-Host ('  '+$options) -ForegroundColor Yellow
   Write-Host '  Open the Launch Options field, press Ctrl+V, then close Properties.' -ForegroundColor Yellow
   if(-not $test){
    $copied=$false
    try{Set-Clipboard -Value $options -DeferManualFallback -ErrorAction Stop;$copied=[bool]$global:PCVRLastClipboardWriteSucceeded}catch{}
    if($copied){Write-Host '  The exact line is already on your clipboard.' -ForegroundColor Green}
    else{Write-Host '  Clipboard unavailable: copy the complete line above manually.' -ForegroundColor Yellow}
    [void](Open-PCVRPageAfterEnter -Url 'steam://gameproperties/7000' -Message 'Press Enter to open Tomb Raider Legend Steam Properties...')
    Show-PCVRClipboardManualFallback -Text $options
    [void](Wait-PCVRExplicitEnter -Message 'After pasting and saving the exact launch options, press Enter to confirm...')
   }
  }
  if(@(Get-Round8RequiredMissing $groups 'before-commit').Count){throw 'Runtime evidence is incomplete.'}
  if($test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
  $proof=if($Key -eq 'FF7'){@('.pcvrhub_ff7_mode.ini')}else{@($groups|ForEach-Object{if($_.Root -eq $game){$_.Required}})}
  $contract=New-PCVRInstallerContract -Id $p.Id -GameName $p.Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$p.Repo+'/releases') -RequiredInstalledFileGroups $proof -Routes @($store)
  $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
  if($Key -eq 'HotD2PC2VR'){
   . (Join-Path $script:Round8ModuleRoot 'HubState.ps1');$hotdStateGame=@{Id=$p.Id;Title='The House of the Dead 2'}
   $hotdStateBefore=@{mod_a_path=(Read-PersistentGameStateValue -Game $hotdStateGame -Name 'mod_a_path');mod_b_path=(Read-PersistentGameStateValue -Game $hotdStateGame -Name 'mod_b_path')};$hotdStateWritten=$true
   if($previousHotdA){if(-not(Save-HubRememberedGameFolder -GameId $p.Id -Title 'The House of the Dead 2' -GameDir $previousHotdA -ProbeFiles @('HotD2VR.exe','working\pcvr\game\Hod2.exe') -StateName 'mod_a_path')){throw 'The earlier Icedomega13 path could not be retained in Hub state.'}}
   if(-not(Save-HubRememberedGameFolder -GameId $p.Id -Title 'The House of the Dead 2' -GameDir $game -ProbeFiles @('Hod2.exe','Config.exe','vr\HOTD2Bridge.dll') -StateName 'mod_b_path')){throw 'The independent PC2VR path could not be saved in Hub state.'}
   if($test.Failure -eq 'state'){throw 'Isolated route-state failure before commit.'}
  }
  if($Key -eq 'HotD2PC2VR'){[void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -VersionSlot Secondary -InstalledPathReceiptPaths @($receipt) -Route PC2VR)}
  else{[void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -InstalledPathReceiptPaths @($receipt) -Route $store)}
  $changed=$false;$shortcutChanged=$false;$hotdStateWritten=$false
  Write-Host ('  [OK] '+$p.Title+' '+$version+' is installed.') -ForegroundColor Green;Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
  switch($Key){
   'BlackWhite'{Write-Host '  In the launcher choose Play in VR. For flat play choose Play, no VR.' -ForegroundColor Yellow;Write-Host '  Alternative: Black & White VR desktop shortcut. Skip straight to Creature select for a new VR game.' -ForegroundColor White}
   'Dementium'{Write-Host '  Start your 32-bit OpenXR runtime first. Alternative: Dementium II HD VR desktop shortcut.' -ForegroundColor White;Write-Host '  If starting through Steam yourself, set -force-opengl in its launch options first.' -ForegroundColor Yellow}
   'TombLegend'{Write-Host '  Start SteamVR first. Alternative: the Tomb Raider Legend VR shortcut; Steam works after the launch-options step.' -ForegroundColor White;Write-Host '  Next Generation Content must stay OFF. SteamVR per-game resolution controls image quality.' -ForegroundColor Yellow}
   'FF7'{Write-Host '  Alternative: Final Fantasy VII Remake VR desktop shortcut. Keep the publisher launcher window open while playing.' -ForegroundColor Yellow;Write-Host '  The launcher restores your normal files on exit. Epic/Xbox remain experimental.' -ForegroundColor White}
   'HotD2PC2VR'{Write-Host '  Select PC2VR in the Hub, or use its separate PC2VR desktop shortcut.' -ForegroundColor White;Write-Host '  Left stick click opens VR Settings. Right stick click recenters; each grip reloads its gun.' -ForegroundColor Cyan}
  }
  Write-Host '';Write-Host ('  '+$p.Quip) -ForegroundColor Magenta;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  $failure=$_
  if($hotdStateWritten){foreach($name in @('mod_a_path','mod_b_path')){if($hotdStateBefore[$name]){Write-PersistentGameStateValue -Game $hotdStateGame -Name $name -Value $hotdStateBefore[$name]}else{Reset-PersistentGameStateValue -Game $hotdStateGame -Name $name}}}
  if($changed){[void](Get-Round8RequiredMissing $groups 'before-rollback');try{for($i=$groups.Count-1;$i -ge 0;$i--){Restore-PCVRPublisherZipSnapshot -GameRoot $groups[$i].Root -Snapshot $groups[$i].Snapshot};[void](Get-Round8RequiredMissing $groups 'after-rollback');Write-Host '  Earlier game files were restored.' -ForegroundColor Yellow}catch{$keepWork=$true;Write-Host ('  Keep this recovery folder for review: '+$work) -ForegroundColor Red}}
  if($shortcutChanged){if($oldShortcut){[IO.File]::WriteAllBytes($shortcut,$oldShortcut)}elseif(Test-Path -LiteralPath $shortcut){Remove-Item -LiteralPath $shortcut -Force}}
  throw $failure
 }finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-Round8VRUninstall([string]$Key,[string]$InstallerFolder,[switch]$HubConfirmed){
 $ErrorActionPreference='Stop';$p=Get-Round8VRProfile $Key;$test=Get-Round8VRTest;$game=Get-Round8Game $p $test
 if(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($p.Exe)) -ErrorAction SilentlyContinue){throw 'Close the game before removal.'}
 if(-not $HubConfirmed -and (Read-Host ('Remove '+$p.Title+'? Type REMOVE')) -cne 'REMOVE'){return}
 if($Key -eq 'BlackWhite' -and -not $test){if(Invoke-BlackWhitePermissionHandoff -Game $game -InstallerFolder $InstallerFolder -Uninstall){return}}
 if($Key -eq 'BlackWhite'){
  if($test){Invoke-Round8Native -File $test.NativeUninstallFile -Arguments @($test.NativeUninstallArguments)}else{
   $uninstall=Get-Round8BlackWhiteUninstaller
   if(-not $uninstall){throw 'Publisher uninstaller not found. Open Windows Installed apps and choose Black & White VR Mod.'}
   [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Uninstall (UAC may be requested)...');Invoke-Round8Native -File $uninstall
  }
 }else{
  if($Key -eq 'FF7'){
   $local=if($test){$test.Local}else{$env:LOCALAPPDATA};$runtime=Join-Path $local 'PCVR Mods Installer Hub\FF7VR'
   Restore-Round8FF7Session $game $runtime $test
   foreach($platform in @('Win64','WinGDK')){[void](Uninstall-OwnedModPayload -GameRoot (Join-Path $game ('End\Binaries\'+$platform)) -Identity 'ff7vrdlss')}
   [void](Uninstall-OwnedModPayload -GameRoot $runtime -Identity $p.Identity);[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'ff7vrmode')
  }elseif($Key -eq 'Dementium'){
   $other=@(Get-ChildItem -LiteralPath (Join-Path $game 'BepInEx\plugins') -Filter '*.dll' -Recurse -File -ErrorAction SilentlyContinue|Where-Object{$_.FullName -notmatch '[\\/]D2VR[\\/]'})
   [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.Identity)
   if(-not $other.Count){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'dementiumloader')}
  }else{[void](Uninstall-OwnedModPayload -GameRoot $game -Identity $p.Identity -ParkedAlternates @{'d3d9.dll'='d3d9.dll.pcvrhub_off'})}
 }
 $desktop=if($test){$test.Desktop}elseif($Key -eq 'BlackWhite' -and $global:BlackWhiteDesktopOverride){$global:BlackWhiteDesktopOverride}else{[Environment]::GetFolderPath('Desktop')}
 $linkName=switch($Key){'BlackWhite'{'Black & White VR'}'Dementium'{'Dementium II HD VR'}'TombLegend'{'Tomb Raider Legend VR'}'FF7'{'Final Fantasy VII Remake VR'}'HotD2PC2VR'{'The House of the Dead 2 VR - PC2VR'}}
 $linkPath=Join-Path $desktop ($linkName+'.lnk');if(Test-Path -LiteralPath $linkPath){$s=(New-Object -ComObject WScript.Shell).CreateShortcut($linkPath);$owned=([string]$s.WorkingDirectory).Equals($game,[StringComparison]::OrdinalIgnoreCase) -or ($Key -eq 'HotD2PC2VR' -and $s.Arguments.Contains((Join-Path $game 'vr\Start-PC2VR.ps1'))) -or ($Key -eq 'FF7' -and $s.Arguments.Contains((Join-Path $runtime 'Start-FF7VR.ps1')));if($owned){Remove-Item -LiteralPath $linkPath -Force}}
 foreach($path in @($(if($Key -eq 'HotD2PC2VR'){Join-Path $game '.pcvrhub_version_b'}else{Join-Path $game '.pcvrhub_version'}),$(if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}))){if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}}
 Write-Host '  [OK] Selected VR mod removed. Saves, changed settings and unrelated mods are retained.' -ForegroundColor Green
}
function Get-Round8BlackWhiteUninstaller {
 # Inno uses autoappdata: elevated installs use ProgramData; per-user installs
 # use Roaming. Read the exact publisher AppId, never execute registry text.
 $paths=@()
 foreach($key in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{9B1A7467-358C-4346-94C3-64949C63BE08}_is1','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{9B1A7467-358C-4346-94C3-64949C63BE08}_is1','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{9B1A7467-358C-4346-94C3-64949C63BE08}_is1')){
  try{$command=[string](Get-ItemProperty -LiteralPath $key -Name UninstallString -ErrorAction Stop).UninstallString;if($command -match '^"([^"]+\\unins[0-9]+\.exe)"(?:\s|$)'){$paths+=$matches[1]}}catch{}
 }
 foreach($base in @($env:ProgramData,$env:APPDATA)|Where-Object {$_}){$paths+=Join-Path $base 'Black & White VR Mod\unins000.exe'}
 foreach($path in $paths){if(Test-Path -LiteralPath $path -PathType Leaf){return $path}}
 return $null
}

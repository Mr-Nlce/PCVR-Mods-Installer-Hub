# Publisher integration for Ratchet 1, Blur, Contracts and both Wreckfest mods.
. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')
$script:NewGameVRModules=$PSScriptRoot

function Get-NewGameVRProfile([string]$Key){
 switch($Key){
 'Ratchet1'{return @{Key=$Key;Id='ratchet-clank-1-vr';Title='Ratchet & Clank 1 VR';Folder='RatchetClank1VR';Repo='npiriou/Rerac-vr';Pattern='(?i)^RatchetVR[-_].*\.zip$';Pre=$false;App='';Exe='rerac.exe';Base=@('rerac.exe','data\extract-info.json');RuntimeFiles=@('RatchetVR.exe','rerac.exe','rerac-extract.exe','msvcp140.dll','vcruntime140.dll','vcruntime140_1.dll','assets\shaders\moby.wgsl');Quip='The R.Y.N.O. is still not covered by your warranty.'}}
 'Blur'{return @{Key=$Key;Id='blur-vr';Title='Blur VR';Folder='BlurVR';Repo='TwoAyEm/BlurVR';Pattern='(?i)^BlurVR[-_].*\.zip$';Pre=$false;App='42640';GameFolder='Blur';Exe='Blur.exe';Base=@('Blur.exe');RuntimeFiles=@('d3d9.dll','BlurVR\d3d9.dll','BlurVR\openvr_api.dll','BlurVR\openxr_loader.dll','BlurVR\BlurVR.ini');Paths=@('C:\Program Files (x86)\Activision\Blur(TM)');Untested=$true;Quip='Indicators are optional. Shunts are not.'}}
 'Contracts'{return @{Key=$Key;Id='hitman-contracts-vr';Title='Hitman: Contracts VR';Folder='HitmanContractsVR';Repo='andreystashev/hitman-contracts-vr-showcase';Pattern='(?i)^ContractsVR[-_].*Setup\.exe$';Pre=$true;App='247430';GameFolder='Hitman Contracts';Exe='HitmanContracts.exe';Base=@('HitmanContracts.exe');RuntimeFiles=@('ContractsVR.exe','ContractsVR.dll','ContractsVRAudio.dll','LaunchVR.exe','ContractsVRHost.exe','ContractsOpenXRHost.exe','openxr_loader.dll','launcher.ini','vr.ini','mod.ini','ContractsVRSetupCleanup.ps1','ContractsVRSetupGuard.exe','tools-read\contracts-renderer-trial.ps1','tools-read\contracts-renderer-trial.psm1','renderer-dxvk-x86\d3d8.dll','renderer-dxvk-x86\d3d9.dll','renderer-dxvk-x86\dxvk.conf','unins000.exe');Paths=@('C:\GOG Games\Hitman 3 - Contracts','C:\Program Files (x86)\Hitman Contracts','C:\Program Files (x86)\Eidos\Hitman Contracts');Quip='Another rainy night. Another suspiciously perfect disguise.'}}
 'Wreckfest'{return @{Key=$Key;Id='wreckfest-vr';Title='Wreckfest VR';Folder='WreckfestVR';Repo='sqofer/WREACKFEST-VR';Pattern='(?i)^WreckfestVRLauncher\.exe$';Pre=$false;App='228380';GameFolder='Wreckfest';Exe='Wreckfest_x64.exe';Base=@('Wreckfest_x64.exe');RuntimeFiles=@('WreckfestVRLauncher.exe');GameFiles=@('WreckfestNativeVR.asi|WreckfestNativeVR.asi.pcvrhub_off','version.dll','WreckfestNativeVR.ini');Untested=$true;Quip='The racing line is whichever barrier gives way first.'}}
 'Wreckfest2'{return @{Key=$Key;Id='wreckfest-2-vr';Title='Wreckfest 2 VR';Folder='Wreckfest2VR';Repo='MatsKarlsson/Wreckfest2VR';Pattern='(?i)^Wreckfest2VR\.exe$';Pre=$true;App='1203190';GameFolder='Wreckfest 2';Exe='Wreckfest2.exe';Base=@('Wreckfest2.exe');RuntimeFiles=@('Wreckfest2VR.exe');Untested=$true;Quip='Your insurance premium has entered early access.'}}
 default{throw 'Unknown game integration.'}
 }
}
function Get-NewGameVRTest {
 if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_NEWGAME_TEST){return $null}
 $path=[IO.Path]::GetFullPath($env:PCVR_NEWGAME_TEST);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
 if(-not $path.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture configuration must stay in Temp.'}
 $c=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json
 $root=[IO.Path]::GetFullPath($c.Root).TrimEnd('\')+'\'
 if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_newgame_fixture'))){throw 'Missing isolated fixture sentinel.'}
 foreach($name in @('Game','Runtime','Desktop','Receipt','Package','Native')){
  if($c.$name -and -not [IO.Path]::GetFullPath([string]$c.$name).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw ('Fixture '+$name+' escaped its root.')}
 }
 return $c
}
function Test-NewGameVRFiles([string]$Root,[string[]]$Files,[string]$Phase=''){
 $missing=@();foreach($group in $Files){$found=$false;foreach($rel in ($group -split '\|')){if(Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf){$found=$true;break}};if($Phase){Write-PCVRFileCheckResult -Path (Join-Path $Root $group) -Present $found -Phase $Phase -DisplayName $group};if(-not $found){$missing+=$group}};return $missing
}
function Get-NewGameVRGame($Profile,$Test){
 if($Test){if(@(Test-NewGameVRFiles $Test.Game $Profile.Base).Count -and $Profile.Key -ne 'Ratchet1'){throw 'The base game fixture is incomplete.'};return [string]$Test.Game}
 $handoff=Get-PCVRRecoveryInput
 if($handoff){
  $candidate=if(Test-Path -LiteralPath $handoff -PathType Leaf){Split-Path $handoff -Parent}else{$handoff}
  $expected=if($Profile.Key -eq 'Ratchet1'){@('RatchetVR.exe','rerac-extract.exe')}else{$Profile.Base}
  if((Test-Path -LiteralPath $candidate -PathType Container) -and -not @(Test-NewGameVRFiles $candidate $expected).Count -and
     ((Test-Path -LiteralPath $handoff -PathType Container) -or [IO.Path]::GetFileName($handoff) -ieq $Profile.Exe -or ($Profile.Key -eq 'Ratchet1' -and [IO.Path]::GetFileName($handoff) -ieq 'RatchetVR.exe'))){
   [void](Set-PCVRRecoveryInput '')
   [void](Save-HubRememberedGameFolder -GameId $Profile.Id -Title $Profile.Title -GameDir $candidate -ProbeFiles $expected -StateName $(if($Profile.Key -eq 'Ratchet1'){'installed_path'}else{'base_game_path'}) -UserSelected)
   return [IO.Path]::GetFullPath($candidate)
  }
 }
 if($Profile.Key -eq 'Ratchet1'){
  $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @('installed_path','user_located') -ProbeFiles @('RatchetVR.exe','rerac.exe')
  if($saved){return $saved}
  $default='C:\Games\Ratchet & Clank 1 VR'
  Write-Host ('  Default installation folder: '+$default) -ForegroundColor Cyan
  while($true){$picked=(Read-Host '  Destination (Enter = this folder)').Trim().Trim('"');if(-not $picked){$picked=$default};try{$picked=[IO.Path]::GetFullPath($picked);if(-not(Test-InstallerTargetWritable $picked)){throw 'This location is unavailable or not writable.'};if(Test-Path -LiteralPath (Join-Path $picked 'RatchetVR.exe')){if(-not(Test-Path -LiteralPath (Join-Path $picked 'rerac-extract.exe'))){throw 'This folder contains a different Ratchet program. Choose an empty folder or your existing Ratchet & Clank 1 VR installation.'}};return $picked}catch{Write-Host ('  '+$_.Exception.Message+' Choose another folder.') -ForegroundColor Yellow}}
 }
 $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @('base_game_path','user_located','installed_path') -ProbeFiles $Profile.Base
 if($saved -and -not @(Test-NewGameVRFiles $saved $Profile.Base).Count){return $saved}
 try{$found=Find-SteamGameFolder -AppId $Profile.App -SteamFolderNames @($Profile.GameFolder) -ProbeExe $Profile.Exe -HubGameId $Profile.Id;if($found -and -not @(Test-NewGameVRFiles $found $Profile.Base).Count){return $found}}catch{}
 foreach($path in $Profile.Paths){if(-not @(Test-NewGameVRFiles $path $Profile.Base).Count){return $path}}
 while($true){$picked=Get-GameFolderInteractive -GameName $Profile.GameFolder -ProbeFile $Profile.Exe;if(-not @(Test-NewGameVRFiles $picked $Profile.Base).Count){return $picked};Write-Host '  Choose the complete original game, not its launcher or an empty folder.' -ForegroundColor Yellow}
}
function Get-NewGameVRStore($Profile,[string]$Game,$Test){
 if($Test){return [string]$Test.Store}
 if($Profile.Key -eq 'Ratchet1'){return 'Standalone'}
 if($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
 if($Game -match '(?i)[\\/]XboxGames[\\/]|[\\/]WindowsApps[\\/]'){throw 'The publisher does not support the Xbox/Microsoft Store build. No files were changed.'}
 if($Profile.Key -in @('Wreckfest','Wreckfest2')){throw 'This VR mod requires the supported Steam game. Locate that copy; other stores are not supported.'}
 if($Game -notmatch '(?i)[\\/](?:GOG Games|GOG Galaxy|Activision|Eidos|Hitman Contracts)[\\/]'){
  Write-Host '  This custom location does not identify its store. Steam copies must start through Steam.' -ForegroundColor White
  do{$choice=(Read-Host '  Your copy: 1 = Steam, 2 = other PC / retail (Enter = other)').Trim()}while($choice -notin @('','1','2'))
  if($choice -eq '1'){return 'Steam'}
 }
 return 'Retail'
}
function Invoke-NewGameVRNative([string]$File,[string[]]$Arguments=@(),[switch]$Interactive){
 # Native stdout/stderr is diagnostic; only the actual process exit code decides.
 $quoted=@($Arguments|ForEach-Object{ '"'+([regex]::Replace(([regex]::Replace([string]$_,'(\\*)"','$1$1\"')),'(\\+)$','$1$1'))+'"' }) -join ' '
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$File;$psi.Arguments=$quoted;$psi.UseShellExecute=$false;$psi.WorkingDirectory=Split-Path $File -Parent
 $psi.CreateNoWindow=-not $Interactive;$psi.RedirectStandardOutput=-not $Interactive;$psi.RedirectStandardError=-not $Interactive
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;[void]$p.Start();$handle=$p.Handle
 if(-not $Interactive){$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync()}
 if($Interactive){$p.WaitForExit()}else{
  $clock=[Diagnostics.Stopwatch]::StartNew()
  while(-not $p.WaitForExit(200)){Write-Progress -Activity 'Preparing the publisher files' -Status ('Working; '+[int]$clock.Elapsed.TotalSeconds+' seconds elapsed. This may take several minutes.')}
  Write-Progress -Activity 'Preparing the publisher files' -Completed
 }
 $code=$p.ExitCode
 if(-not $Interactive){Write-Information -MessageData ($out.Result+$err.Result) -InformationAction SilentlyContinue}
 if($null -eq $code -or $code -ne 0){throw ('The publisher tool did not complete (exit '+$code+'). Retry or choose another input.')}
}
function Get-NewGameVRPackage($Profile,[string]$Work,$Test){
 if($Test){return @{Path=[string]$Test.Package;Tag=[string]$Test.Tag}}
 $manual=Get-PCVRRecoveryInput -PathType Leaf
 if($manual){
  [void](Set-PCVRRecoveryInput '')
  if($Profile.Key -eq 'Ratchet1' -and [IO.Path]::GetExtension($manual) -ieq '.iso'){$script:NewGameDiscHandoff=$manual}
  else{
   $extension=[IO.Path]::GetExtension($manual);$expected=if($Profile.Key -in @('Ratchet1','Blur')){'.zip'}else{'.exe'}
   if($extension -ine $expected){throw ('This step needs the official VR '+$expected+' package, not game data. Select the matching publisher download, then Retry.')}
   do{$tag=(Read-Host '  Version on the official release page for this downloaded package').Trim()}until(Test-IsTrackableInstalledVersion $tag);return @{Path=$manual;Tag=$tag}
  }
 }
 $release=Resolve-GitHubReleaseAsset -Repo $Profile.Repo -IncludePrerelease ([bool]$Profile.Pre) -AssetPatterns @($Profile.Pattern) -SkipReleasesWithoutMatchingAsset $true
 if(-not $release.Resolved -or -not $release.Url){throw 'The official Windows download could not be resolved. Retry or supply the downloaded publisher package.'}
 $ext=[IO.Path]::GetExtension(([uri]$release.Url).AbsolutePath);$path=Join-Path $Work ('publisher'+$ext)
 [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $path -Label $Profile.Title -ManualUrl ('https://github.com/'+$Profile.Repo+'/releases') -AllowSkip $false -PlainProgress -FunctionalPayloadOnly)
 return @{Path=$path;Tag=$release.Tag}
}
function Get-NewGameVRRuntime($Profile,[string]$Game,$Test){
 if($Test){return [string]$Test.Runtime}
 switch($Profile.Key){
 'Contracts'{
  $registered=Get-ContractsRegisteredRuntime
  if($registered){return $registered}
  $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @('installed_path') -ProbeFiles @('ContractsVR.exe')
  if($saved){return $saved};return [IO.Path]::Combine($env:LOCALAPPDATA,'ContractsVR')
 }
 'Wreckfest'{return $Game}
 'Wreckfest2'{return $Game}
 default{return $Game}
 }
}
function Get-ContractsRegisteredRuntime {
 # Exact per-user AppId from the opened publisher Inno Setup package.
 try{
  $entry=Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{A6D8D174-C751-4627-844A-27F06346130C}_is1' -ErrorAction Stop
  $path=[string]$entry.InstallLocation
  if($path -and (Test-Path -LiteralPath (Join-Path $path 'ContractsVR.exe')) -and (Test-Path -LiteralPath (Join-Path $path 'unins000.exe'))){return [IO.Path]::GetFullPath($path).TrimEnd('\')}
 }catch{}
 return $null
}
function Get-NewGameVRGroup([string]$Root,[string]$Stage,[string]$Identity,[string[]]$Required,[string[]]$Keep=@()){
 return @{Root=$Root;Stage=$Stage;Identity=$Identity;Required=$Required;Keep=$Keep;Snapshot=$null}
}
function Invoke-NewGameVRCheckpoint($Groups,[string]$Phase){
 $missing=@();foreach($g in $Groups){$missing+=@(Test-NewGameVRFiles $g.Root $g.Required $Phase)};return $missing
}
function New-NewGameVRShortcut($Profile,[string]$Runtime,[string]$Game,$Test){
 $desktop=if($Test){[string]$Test.Desktop}else{[Environment]::GetFolderPath('DesktopDirectory')}
 [void][IO.Directory]::CreateDirectory($desktop);$path=Join-Path $desktop (($Profile.Title -replace ':','')+'.lnk')
 $shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut($path)
 $target=Join-Path $env:WINDIR 'System32\wscript.exe';$args='"'+(Join-Path $Runtime 'PCVR-Launcher\Start VR.vbs')+'"'
 if((Test-Path -LiteralPath $path) -and ($link.TargetPath -ine $target -or $link.Arguments -cne $args)){throw 'An unrelated desktop shortcut has this name. Rename it before Retry; it was preserved.'}
 $link.TargetPath=$target;$link.Arguments=$args;$link.WorkingDirectory=$Runtime;$link.Description=$Profile.Title
 $icon=Join-Path $Runtime 'PCVR-Launcher\game.ico'
 $link.IconLocation=$icon+',0';$link.Save();$check=$shell.CreateShortcut($path)
 if($check.TargetPath -ine $target -or $check.Arguments -cne $args -or $check.WorkingDirectory -ine $Runtime -or $check.IconLocation -ine ($icon+',0')){throw 'Desktop shortcut verification failed.'}
 return $path
}
function Invoke-NewGameVRSetup([string]$Key,[string]$InstallerFolder){
 $ErrorActionPreference='Stop';$p=Get-NewGameVRProfile $Key;$test=Get-NewGameVRTest;$work=$null;$groups=@();$report=$null;$changed=$false;$committed=$false;$link=$null;$oldLink=$null;$linkChanged=$false
 $candidate=Test-PCVRUntestedInstaller -InstallerId $p.Id
 try{
  Write-Host ('='*60) -ForegroundColor Cyan;Write-Host ('  '+$p.Title+' Installer') -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Cyan
  Write-Host '  Close the game and its VR launcher before installation or updates.' -ForegroundColor White
  if($Key -eq 'Ratchet1'){Write-Host '  Bring your own original US Ratchet & Clank disc image (SCUS-97199).' -ForegroundColor Yellow;Write-Host '  The VR package already includes ReRAC. Disc extraction needs about 5 GB and several minutes.' -ForegroundColor White}
  if($Key -eq 'Contracts'){Write-Host '  Requires the original Steam 1.75 or supported legacy 1.74 game. Publisher Setup checks it.' -ForegroundColor Yellow;Write-Host '  Start the normal game once and choose your graphics resolution, then close it.' -ForegroundColor White}
  if($candidate){Write-Host '  UNTESTED INSTALLER - help confirm this on your own game.' -ForegroundColor Yellow}
  if($Key -eq 'Wreckfest'){Write-Host '  Steam x64 build 16986367 only. Other game builds/stores are rejected by the publisher.' -ForegroundColor Yellow}
  if($Key -eq 'Wreckfest2'){Write-Host '  Steam game build released 2026-10-22. Use offline cockpit races; VDXR is publisher-tested.' -ForegroundColor Yellow}
  Show-AntivirusNotice -Compact
  $folderPrompt=if($Key -eq 'Ratchet1'){'After reading this, press Enter to choose the installation folder...'}else{'After reading this, press Enter to find or choose the game folder...'}
  [void](Wait-PCVRExplicitEnter -Message $folderPrompt)
  $game=Get-NewGameVRGame $p $test
  Write-Host ''
  $folderLabel=if($Key -eq 'Ratchet1'){'Installation folder'}else{'Game folder'}
  Write-Host ('  '+$folderLabel+': '+$game) -ForegroundColor Cyan
  $store=Get-NewGameVRStore $p $game $test;$runtime=Get-NewGameVRRuntime $p $game $test
  if($runtime -ine $game){Write-Host ('  VR installation folder: '+$runtime) -ForegroundColor Cyan}
  foreach($name in @([IO.Path]::GetFileNameWithoutExtension($p.Exe),'ContractsVR','WreckfestVRLauncher','Wreckfest2VR','RatchetVR')|Select-Object -Unique){if(Get-Process -Name $name -ErrorAction SilentlyContinue){throw 'Close the game and VR launcher before Retry.'}}
  if($test -and $test.Failure -eq 'permissions'){throw 'The selected target is not writable.'}
  if(-not(Test-InstallerTargetWritable $runtime)){throw 'The selected target is not writable. Choose another folder or correct its permissions, then Retry.'}
  if($Key -eq 'Blur' -and -not(Test-InstallerTargetWritable $game)){throw 'The game folder is not writable. Correct its permissions and Retry.'}
  $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
  if($candidate){$report=Start-PCVRInstallerTestReport -InstallerId $p.Id -GameTitle $p.Title -ModName $p.Title -FileStem ($p.Id -replace '-vr$','') -InstallerFolder $InstallerFolder;Add-PCVRInstallerTestReportTarget -Session $report -Path $game -GameDir $game -Route $store;if($runtime -ine $game){Add-PCVRInstallerTestReportTarget -Session $report -Path $runtime -Role 'Publisher VR launcher'}}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current official VR package...')
  $a=Get-NewGameVRPackage $p $work $test;$version=[string]$a.Tag
  if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The package version could not be determined. Hand over the official package and its release version.'}
  $stage=Join-Path $work 'payload';[void][IO.Directory]::CreateDirectory($stage)
  if($Key -in @('Ratchet1','Blur')){
   $safe=Test-ZipArchiveEntrySafety -ArchivePath $a.Path -DestinationFolder (Join-Path $work 'expanded');if(-not $safe.Safe -or -not $safe.Inspectable){throw 'Choose a readable Windows ZIP without unsafe archive paths.'}
   if((Expand-ArchiveOrFallback -ArchivePath $a.Path -DestinationFolder (Join-Path $work 'expanded') -Label $p.Title -AllowSkip $false -QuietProgress) -ne 'ok'){throw 'The publisher ZIP could not be opened.'}
   $probe=if($Key -eq 'Ratchet1'){'RatchetVR.exe'}else{'d3d9.dll'};$found=@(Get-ChildItem -LiteralPath (Join-Path $work 'expanded') -File -Recurse|Where-Object Name -eq $probe)
   if($found.Count -ne 1){throw 'The archive does not contain one complete Windows runtime.'}
   $source=Split-Path $found[0].FullName -Parent
   if($Key -eq 'Ratchet1'){
    foreach($item in Get-ChildItem -LiteralPath $source -Force){if($item.Name -notin @('data','saves','config','user') -and $item.Name -notlike '.pcvrhub*'){Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse -Force}}
   }else{
    Copy-Item -LiteralPath $source -Destination (Join-Path $stage 'BlurVR') -Recurse;Copy-Item -LiteralPath (Join-Path $source 'd3d9.dll') -Destination $stage
   }
  }elseif($Key -ne 'Contracts'){
   $stream=[IO.File]::OpenRead($a.Path);try{if($stream.ReadByte() -ne 77 -or $stream.ReadByte() -ne 90){throw 'The download is not a Windows application.'}}finally{$stream.Dispose()}
   Copy-Item -LiteralPath $a.Path -Destination (Join-Path $stage $p.RuntimeFiles[0])
  }
  if($Key -eq 'Contracts'){
   Write-Host '';Write-Host '  REQUIRED PUBLISHER SETUP  ' -ForegroundColor Black -BackgroundColor Yellow
   Write-Host ('  1. Select HitmanContracts.exe in: '+$game) -ForegroundColor Yellow
   Write-Host ('  2. Keep the separate publisher VR folder: '+$runtime) -ForegroundColor Yellow
   Write-Host '  3. Finish Setup; select your connection later in Contracts VR Settings.' -ForegroundColor Yellow
   Write-Host '  Setup resets mod settings. Existing settings are backed up first; game saves remain.' -ForegroundColor White
   $settings=Join-Path $env:LOCALAPPDATA ('PCVR Mods Installer Hub\Backups\ContractsVR\'+[guid]::NewGuid().ToString('N'))
   foreach($f in @('launcher.ini','vr.ini','mod.ini')){if(Test-Path -LiteralPath (Join-Path $runtime $f)){[void][IO.Directory]::CreateDirectory($settings);Copy-Item -LiteralPath (Join-Path $runtime $f) -Destination $settings}}
   [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
   if($test){Invoke-NewGameVRNative -File $test.Native -Arguments @('prepare')}else{Invoke-NewGameVRNative -File $a.Path -Interactive}
   if(-not $test){$registered=Get-ContractsRegisteredRuntime;if($registered){$runtime=$registered}}
   while(@(Test-NewGameVRFiles $runtime $p.RuntimeFiles 'after-publisher').Count){if($test){throw 'Publisher Setup left an incomplete runtime.'};Write-Host '  Choose the VR folder where publisher Setup installed Contracts VR (not the game).' -ForegroundColor Yellow;$runtime=(Read-Host '  Drag/paste that folder, or press Enter to retry Setup').Trim().Trim('"');if(-not $runtime){$runtime=Get-NewGameVRRuntime $p $game $test;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to reopen publisher Setup...');Invoke-NewGameVRNative -File $a.Path -Interactive}}
   $selected=[regex]::Match([IO.File]::ReadAllText((Join-Path $runtime 'launcher.ini')),'(?im)^\s*GameExe\s*=\s*(.+?)\s*$')
   if(-not $selected.Success -or [IO.Path]::GetFullPath($selected.Groups[1].Value.Trim().Trim('"')) -ine [IO.Path]::GetFullPath((Join-Path $game $p.Exe))){throw 'Publisher Setup selected a different game. Reopen Setup and select the same HitmanContracts.exe shown above; no Hub success was recorded.'}
  }
  if($Key -eq 'Blur' -and @(Test-NewGameVRFiles $stage $p.RuntimeFiles).Count){throw 'BlurVR ZIP is missing a required proxy, runtime or settings file.'}
  if($Key -eq 'Ratchet1' -and @(Test-NewGameVRFiles $stage $p.RuntimeFiles).Count){throw 'RatchetVR ZIP is missing its launcher, extractor, runtime or shaders.'}
  $control=Join-Path $stage 'PCVR-Launcher';[void][IO.Directory]::CreateDirectory($control)
  Copy-Item -LiteralPath (Join-Path $InstallerFolder 'Start-VR.ps1') -Destination $control
  Copy-Item -LiteralPath (Join-Path $InstallerFolder 'Start VR.vbs') -Destination $control
  Copy-Item -LiteralPath (Join-Path $InstallerFolder 'Game.ico') -Destination (Join-Path $control 'game.ico')
  $mode=if($Key -eq 'Blur'){'BlurVR\BlurVR.ini'}elseif($Key -in @('Wreckfest','Wreckfest2')){'.pcvrhub_'+$Key.ToLowerInvariant()+'_mode.ini'}else{'PCVR-Launcher\mode.ini'}
  $config=@{Key=$Key;GameDirectory=$game;RuntimeRoot=$runtime;Store=$store;AppId=$p.App;Exe=$p.Exe;ModeFile=$mode;Title=$p.Title}
  $config|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $control 'launch.json') -Encoding UTF8
  if($Key -notin @('Blur','Wreckfest')){[void][IO.Directory]::CreateDirectory((Split-Path (Join-Path $stage $mode) -Parent));[IO.File]::WriteAllText((Join-Path $stage $mode),"[Hub]`r`nMode=VR`r`n")}
  $required=@($p.RuntimeFiles)+@('PCVR-Launcher\Start-VR.ps1','PCVR-Launcher\Start VR.vbs','PCVR-Launcher\launch.json','PCVR-Launcher\game.ico')
  if($Key -eq 'Contracts'){$required=@('PCVR-Launcher\Start-VR.ps1','PCVR-Launcher\Start VR.vbs','PCVR-Launcher\launch.json','PCVR-Launcher\game.ico')}
  $keep=if($Key -eq 'Blur'){@('BlurVR\BlurVR.ini')}elseif($Key -eq 'Wreckfest2'){@($mode)}else{@('PCVR-Launcher\mode.ini')}
  $groups+=Get-NewGameVRGroup $runtime $stage ($p.Id -replace '-','') $required $keep
  if($Key -eq 'Blur' -and (Test-Path -LiteralPath (Join-Path $game 'd3d9.dll.pcvrhub_off'))){throw 'The Blur proxy is parked by another installation. Restore it or use the Flat / VR setting before Retry.'}
  $index=0;foreach($g in $groups){$index++;[void][IO.Directory]::CreateDirectory($g.Root);$g.Snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $g.Root -Stage $g.Stage -Identity $g.Identity -SnapshotRoot (Join-Path $work ('rollback'+$index))}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the complete VR launcher and required files...')
  $changed=$true;foreach($g in $groups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $g.Root -Identity $g.Identity -KeepExistingRelativePaths $g.Keep -ProgressLabel 'Installing the VR files')}
  [void](Invoke-NewGameVRCheckpoint $groups 'immediately-after-copy')
  if($Key -eq 'Ratchet1' -and @(Test-NewGameVRFiles $game @('data\extract-info.json')).Count){
   Write-Host '  REQUIRED: ORIGINAL US DISC IMAGE (SCUS-97199)' -ForegroundColor Black -BackgroundColor Yellow
   Write-Host '  European/PAL discs are not supported. Select your own .iso; .7z must be extracted first.' -ForegroundColor Yellow
   Write-Host '  This copies game data only; it does not start the game. Allow several minutes and about 5 GB.' -ForegroundColor White
   if($test){Invoke-NewGameVRNative -File $test.Native -Arguments @('extract')}else{
    while($true){$iso=if($script:NewGameDiscHandoff){$provided=$script:NewGameDiscHandoff;$script:NewGameDiscHandoff='';$provided}else{(Read-Host '  Drag/paste your supported .iso, or Q for recovery').Trim().Trim('"')};if($iso -ieq 'Q'){throw 'Disc import cancelled. Your existing game data and saves were kept.'};if(-not(Test-Path -LiteralPath $iso -PathType Leaf) -or [IO.Path]::GetExtension($iso) -ine '.iso'){Write-Host '  Select the extracted .iso file.' -ForegroundColor Yellow;continue};[void](Wait-PCVRExplicitEnter -Message 'Press Enter to extract your disc into this installation...');try{Invoke-NewGameVRNative -File (Join-Path $runtime 'rerac-extract.exe') -Arguments @('extract','--iso',$iso,'--out',(Join-Path $game 'data'),'--ntsc-only');break}catch{Write-Host '  Extraction did not complete. Use the original US disc image or choose another readable ISO.' -ForegroundColor Yellow}}
   }
   if(@(Test-NewGameVRFiles $game @('data\extract-info.json')).Count){throw 'Disc extraction did not leave complete game data. No successful installation was recorded.'}
  }
  if($Key -eq 'Wreckfest'){
   $nativeStage=Join-Path $work 'native-game';[void][IO.Directory]::CreateDirectory($nativeStage)
   foreach($name in @('WreckfestNativeVR.asi','version.dll','WreckfestNativeVR.ini')){[IO.File]::WriteAllText((Join-Path $nativeStage $name),'publisher installation plan')}
   $nativeGroup=Get-NewGameVRGroup $game $nativeStage 'wreckfestnative' $p.GameFiles @('WreckfestNativeVR.ini');$nativeGroup.Snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $nativeStage -Identity $nativeGroup.Identity -SnapshotRoot (Join-Path $work 'native-rollback');$groups+=$nativeGroup
   Write-Host '  REQUIRED PUBLISHER PREPARATION' -ForegroundColor Black -BackgroundColor Yellow
   Write-Host '  Click Open Mod. Let the launcher find your supported Steam game and prepare VR.' -ForegroundColor Yellow
   Write-Host ('  If needed: Game & diagnostics > Locate game > '+(Join-Path $game 'Wreckfest_x64.exe')) -ForegroundColor White
   Write-Host '  Close the launcher after preparation, then return here. Do not start a race yet.' -ForegroundColor White
   [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the Wreckfest VR launcher...')
   if($test){Invoke-NewGameVRNative -File $test.Native -Arguments @('prepare')}else{[void](Start-Process -FilePath (Join-Path $runtime 'WreckfestVRLauncher.exe') -WorkingDirectory $runtime);[void](Wait-PCVRExplicitEnter -Message 'After preparation is complete and the launcher is closed, press Enter to verify...')}
   if(@(Test-NewGameVRFiles $game @('WreckfestNativeVR.asi','version.dll','WreckfestNativeVR.ini') 'after-publisher').Count){throw 'The publisher did not prepare this game. Check its supported build message, then Retry.'}
   foreach($name in @('WreckfestNativeVR.asi','version.dll','WreckfestNativeVR.ini')){Copy-Item -LiteralPath (Join-Path $game $name) -Destination (Join-Path $nativeStage $name) -Force}
   Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $nativeGroup.Snapshot
   [void](Install-OwnedModPayload -SourceRoot $nativeStage -GameRoot $game -Identity $nativeGroup.Identity -KeepExistingRelativePaths $nativeGroup.Keep)
  }
  if($test -and $test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $runtime $p.RuntimeFiles[0]) -Force -ErrorAction SilentlyContinue}
  if(-not $test){Write-Host '  Checking that the installed files remain available; this takes a few seconds.' -ForegroundColor Gray;Start-Sleep -Seconds 3}
  $missing=@(Invoke-NewGameVRCheckpoint $groups 'after-observation')
  if($missing.Count){
   Write-Host '  Required files are missing. A copy, path, permission or external-removal problem is possible.' -ForegroundColor Yellow
   $retry={foreach($g in $groups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $g.Root -Identity $g.Identity -KeepExistingRelativePaths $g.Keep)};[void](Invoke-NewGameVRCheckpoint $groups 'after-retry')}.GetNewClosure()
   [void](Invoke-NewGameVRCheckpoint $groups 'before-retry')
   $input=if($test){{'Q'}}else{$null}
   if(-not(Confirm-PlacedFilesSurvive -Paths @($groups|ForEach-Object{$g=$_;$g.Required|ForEach-Object{Join-Path $g.Root (($_ -split '\|')[0])}}) -GameDir $runtime -WaitSeconds 0 -Recopy $retry -ReadInput $input -NoClear)){throw 'Required files are missing; the earlier owned files will be restored.'}
  }
  $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('DesktopDirectory')};$link=Join-Path $desktop (($p.Title -replace ':','')+'.lnk');if(Test-Path -LiteralPath $link){$oldLink=[IO.File]::ReadAllBytes($link)}
  [void](New-NewGameVRShortcut $p $runtime $game $test);$linkChanged=$true
  if(@(Invoke-NewGameVRCheckpoint $groups 'before-commit').Count){throw 'The required runtime is incomplete.'}
  $contractFiles=@($p.RuntimeFiles)+@('PCVR-Launcher\Start-VR.ps1','PCVR-Launcher\launch.json','PCVR-Launcher\game.ico')
  if($Key -eq 'Ratchet1'){$contractFiles+=@('data\extract-info.json')}
  if($Key -eq 'Wreckfest'){$contractFiles+=@($p.GameFiles)}
  $contract=New-PCVRInstallerContract -Id $p.Id -GameName $p.Title -Acquisition GitHub -Routes @($store) -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$p.Repo+'/releases') -RequiredInstalledFileGroups $contractFiles
  if($test -and $test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
  $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $runtime -Version $version -Route $store -InstalledPathReceiptPaths @($receipt))
  if($Key -ne 'Ratchet1'){[void](Save-HubRememberedGameFolder -GameId $p.Id -Title $p.Title -GameDir $game -ProbeFiles $p.Base -StateName 'base_game_path')}
  $committed=$true
  Write-Host ('  [OK] '+$p.Title+' '+$version+' installed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
  switch($Key){
   'Ratchet1'{Write-Host '  Connect your headset and start SteamVR, set as the OpenXR runtime. Alternative: Ratchet & Clank 1 VR desktop shortcut.'}
   'Blur'{Write-Host '  Start SteamVR first. Alternative: the Blur VR desktop shortcut, or launch this same game normally.';Write-Host '  Choose Options > Graphics > Resolution to improve sharpness. VR starts when the first level loads.' -ForegroundColor Yellow}
   'Contracts'{Write-Host '  In Contracts VR Settings choose your headset connection, Check headset, then Save & play.' -ForegroundColor Yellow;Write-Host '  Alternative: Hitman Contracts VR desktop shortcut. Original renderer is recommended; DXVK can cause artifacts.'}
   'Wreckfest'{Write-Host '  Click Open Mod, connect your OpenXR headset, then Launch in VR. Alternative: Wreckfest VR desktop shortcut.'}
   'Wreckfest2'{Write-Host '  The Hub opens the VR app and your Steam game. Connect VDXR, load an offline race and enter the cockpit.' -ForegroundColor Yellow;Write-Host '  Keep automatic start enabled or click Start VR. F8 recenters. Alternative: Wreckfest 2 VR desktop shortcut.'}
  }
  if($report){$reportPath=Complete-PCVRInstallerTestReport -Session $report -Outcome Success -ModVersion $version;Show-PCVRInstallerTestReportResult -ReportPath $reportPath}
  Write-Host '';Write-Host ('  '+$p.Quip) -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  $failure=$_
  if($changed -and -not $committed){[void](Invoke-NewGameVRCheckpoint $groups 'before-rollback');for($i=$groups.Count-1;$i -ge 0;$i--){if($groups[$i].Snapshot){Restore-PCVRPublisherZipSnapshot -GameRoot $groups[$i].Root -Snapshot $groups[$i].Snapshot}};[void](Invoke-NewGameVRCheckpoint $groups 'after-rollback')}
  if($linkChanged -and -not $committed){if($oldLink){[IO.File]::WriteAllBytes($link,$oldLink)}elseif(Test-Path -LiteralPath $link){Remove-Item -LiteralPath $link -Force}}
  if($report -and -not $report.Completed){$reportPath=Complete-PCVRInstallerTestReport -Session $report -Outcome Failed -FailureMessage $failure.Exception.Message;Show-PCVRInstallerTestReportResult -ReportPath $reportPath}
  throw $failure
 }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-NewGameVRUninstall([string]$Key,[string]$InstallerFolder,[switch]$HubConfirmed){
 $ErrorActionPreference='Stop';$p=Get-NewGameVRProfile $Key;$test=Get-NewGameVRTest;$game=Get-NewGameVRGame $p $test;$runtime=Get-NewGameVRRuntime $p $game $test
 if(Get-Process -Name @([IO.Path]::GetFileNameWithoutExtension($p.Exe),'ContractsVR','WreckfestVRLauncher','Wreckfest2VR') -ErrorAction SilentlyContinue){throw 'Close the game and VR launcher before removal.'}
 if(-not(Test-Path -LiteralPath (Join-Path $runtime ('.pcvrhub_'+($p.Id -replace '-','')+'_ownership.csv')) -PathType Leaf)){throw 'No Hub ownership record exists for this VR folder. Repair the selected installation first; no unrelated publisher copy was removed.'}
 if(-not $HubConfirmed -and (Read-Host 'Remove this VR mod? Type REMOVE') -cne 'REMOVE'){return}
 if($Key -eq 'Contracts'){
  Write-Host '  Restore the previous game renderer first, then remove the separate publisher runtime. Saves remain.' -ForegroundColor Yellow
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to restore the renderer and open publisher Uninstall...')
  if($test){Invoke-NewGameVRNative -File $test.Native -Arguments @('uninstall')}else{
   Invoke-NewGameVRNative -File (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -Arguments @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $runtime 'tools-read\contracts-renderer-trial.ps1'),'-Action','Restore','-GameDirectory',$game,'-BundleDirectory',(Join-Path $runtime 'renderer-dxvk-x86'))
   Invoke-NewGameVRNative -File (Join-Path $runtime 'unins000.exe') -Interactive
  }
  if(Test-Path -LiteralPath (Join-Path $runtime 'ContractsVR.exe')){throw 'The publisher runtime is still installed. Its receipt was kept; Retry the removal.'}
 }
 if($Key -eq 'Wreckfest'){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'wreckfestnative' -ParkedAlternates @{'WreckfestNativeVR.asi'='WreckfestNativeVR.asi.pcvrhub_off'})}
 if($Key -eq 'Wreckfest2'){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'wreckfest2mode')}
 [void](Uninstall-OwnedModPayload -GameRoot $runtime -Identity ($p.Id -replace '-',''))
 $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('DesktopDirectory')};$link=Join-Path $desktop (($p.Title -replace ':','')+'.lnk')
 if(Test-Path -LiteralPath $link){$s=(New-Object -ComObject WScript.Shell).CreateShortcut($link);if($s.TargetPath -ieq (Join-Path $env:WINDIR 'System32\wscript.exe') -and $s.Arguments -ceq ('"'+(Join-Path $runtime 'PCVR-Launcher\Start VR.vbs')+'"')){Remove-Item -LiteralPath $link -Force}}
 $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
 foreach($path in @($receipt,(Join-Path $runtime '.pcvrhub_version'))){if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}}
 Write-Host '  [OK] Owned VR files removed; original files restored. Saves, settings and unrelated files remain.' -ForegroundColor Green
}

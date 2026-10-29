param([string]$GameDirectory='', [string]$RuntimeRoot='')
$ErrorActionPreference='Stop'
try {
 if(-not $RuntimeRoot){$RuntimeRoot=Split-Path $PSScriptRoot -Parent}
 $configPath=Join-Path $RuntimeRoot 'PCVR-Launcher\launch.json'
 if(Test-Path -LiteralPath $configPath){$c=Get-Content -LiteralPath $configPath -Raw|ConvertFrom-Json}
 else{
  # An existing publisher installation needs no Hub receipt/config. The Hub
  # supplies both validated roots; retain the same launch flow as an install.
  if(-not $GameDirectory -or -not $RuntimeRoot){throw 'Choose the complete game and VR folders with Locate Game.'}
  $key='Ratchet1'
  $exe=switch($key){'Ratchet1'{'rerac.exe'};'Blur'{'Blur.exe'};'Contracts'{'HitmanContracts.exe'};'Wreckfest'{'Wreckfest_x64.exe'};'Wreckfest2'{'Wreckfest2.exe'}}
  $app=switch($key){'Blur'{'42640'};'Contracts'{'247430'};'Wreckfest'{'228380'};'Wreckfest2'{'1203190'};default{''}}
  $store=if($GameDirectory -match '(?i)[\\/]steamapps[\\/]common[\\/]' -or $key -in @('Wreckfest','Wreckfest2')){'Steam'}else{'Retail'}
  $c=[pscustomobject]@{Key=$key;Exe=$exe;AppId=$app;Store=$store;GameDirectory=$GameDirectory;ModeFile=$(if($key -eq 'Blur'){'BlurVR\BlurVR.ini'}elseif($key -eq 'Wreckfest2'){'.pcvrhub_wreckfest2_mode.ini'}else{'PCVR-Launcher\mode.ini'})}
 }

 $game=[IO.Path]::GetFullPath([string]$c.GameDirectory);$runtime=[IO.Path]::GetFullPath($RuntimeRoot)
 if(-not(Test-Path -LiteralPath (Join-Path $game $c.Exe))){throw 'The original game could not be found. Use Locate Game, then repair this VR installation.'}
 $modeRoot=if($c.Key -in @('Ratchet1','Contracts')){$runtime}else{$game}
 $modePath=Join-Path $modeRoot $c.ModeFile
 $flat=$false
 if(Test-Path -LiteralPath $modePath){$text=[IO.File]::ReadAllText($modePath);$flat=if($c.Key -eq 'Blur'){$text -match '(?im)^\s*Stereo\s*=\s*0\s*$'}else{$text -match '(?im)^\s*Mode\s*=\s*Flat\s*$'}}
 $actions=@();$environment=@{}
 switch($c.Key){
  'Ratchet1'{
   foreach($rel in @('RatchetVR.exe','rerac.exe','rerac-extract.exe','data\extract-info.json')){if(-not(Test-Path -LiteralPath (Join-Path $runtime $rel))){throw 'RatchetVR or its extracted game data is incomplete. Repair it in the Hub.'}}
   $environment.RC_VR=if($flat){'0'}else{'1'}
   $environment.RC_SAVE_DIR=Join-Path $runtime 'saves\normal'
   $actions+=@{File=(Join-Path $runtime 'RatchetVR.exe');Args='';Directory=$runtime}
  }
  'Contracts'{
   if($flat){
    $restore=Join-Path $runtime 'tools-read\contracts-renderer-trial.ps1'
    if(-not(Test-Path -LiteralPath $restore)){throw 'The publisher renderer-restore tool is missing. Repair before launching flat.'}
    $actions+=@{File=(Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe');Args=('-NoProfile -ExecutionPolicy Bypass -File "'+$restore+'" -Action Restore -GameDirectory "'+$game.TrimEnd('\')+'" -BundleDirectory "'+(Join-Path $runtime 'renderer-dxvk-x86')+'"');Directory=$runtime;Wait=$true}
   }else{$actions+=@{File=(Join-Path $runtime 'ContractsVR.exe');Args='--settings';Directory=$runtime}}
  }
  'Wreckfest'{$actions+=@{File=(Join-Path $runtime 'WreckfestVRLauncher.exe');Args='';Directory=$runtime}}
  'Wreckfest2'{if(-not $flat){$actions+=@{File=(Join-Path $runtime 'Wreckfest2VR.exe');Args='';Directory=$runtime}}}
  'Blur'{}
  default{throw 'Unknown VR launcher profile. Repair in the Hub.'}
 }
 if($c.Key -in @('Blur','Wreckfest2') -or ($c.Key -eq 'Contracts' -and $flat)){
  if($c.Store -eq 'Steam'){$actions+=@{File=('steam://rungameid/'+$c.AppId);Args='';Directory=$game}}
  elseif($c.Key -in @('Blur','Contracts')){$actions+=@{File=(Join-Path $game $c.Exe);Args='';Directory=$game}}
  else{throw 'This VR mod does not support that store. No Steam redirection was performed.'}
 }
 foreach($action in $actions){if($action.File -notmatch '^steam://' -and -not(Test-Path -LiteralPath $action.File)){throw ('A required start app is missing: '+[IO.Path]::GetFileName($action.File)+'. Repair in the Hub.')}}
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_NEWGAME_LAUNCH_CAPTURE){
  $capture=[IO.Path]::GetFullPath($env:PCVR_NEWGAME_LAUNCH_CAPTURE);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
  if(-not $capture.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture must stay inside the fixture.'}
  @{Flat=$flat;Actions=$actions;Environment=$environment;Game=$game;Runtime=$runtime}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $capture -Encoding UTF8
  exit 0
 }
 if($c.Key -eq 'Wreckfest2' -and $flat -and (Get-Process -Name Wreckfest2VR -ErrorAction SilentlyContinue)){throw 'Close Wreckfest2VR or click Stop VR in its window before starting flat. The Hub will not stop your running game.'}
 $previous=@{};try{
  foreach($name in $environment.Keys){$previous[$name]=[Environment]::GetEnvironmentVariable($name);[Environment]::SetEnvironmentVariable($name,$environment[$name])}
  foreach($action in $actions){
   if($action.Wait){$p=Start-Process -FilePath $action.File -ArgumentList $action.Args -WorkingDirectory $action.Directory -WindowStyle Hidden -Wait -PassThru;if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw 'The publisher renderer could not be restored. Review its backup before retrying.'}}
   elseif($action.Args){[void](Start-Process -FilePath $action.File -ArgumentList $action.Args -WorkingDirectory $action.Directory)}
   else{[void](Start-Process -FilePath $action.File -WorkingDirectory $action.Directory)}
  }
 }finally{foreach($name in $previous.Keys){[Environment]::SetEnvironmentVariable($name,$previous[$name])}}
}catch{
 if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
 Add-Type -AssemblyName PresentationFramework
 [void][Windows.MessageBox]::Show($_.Exception.Message,'VR launch','OK','Warning')
 exit 1
}

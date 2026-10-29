param([string]$GameDirectory='', [string]$RuntimeRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
function Get-FF7HubLaunchPlan([string]$GameDirectory,[string]$RuntimeRoot){
 if(-not $GameDirectory){$record=Join-Path $RuntimeRoot '.pcvrhub_ff7_game.txt';if(Test-Path -LiteralPath $record){$GameDirectory=[IO.File]::ReadAllText($record).Trim()}}
 if(-not $GameDirectory){throw 'The saved FF7 game folder is missing. Locate the game and repair the VR installer.'}
 foreach($file in @('ff7vr-launcher.ps1','ff7vr-stores.ps1','xinput1_3.dll','ff7vr.ini')){if(-not(Test-Path -LiteralPath (Join-Path $RuntimeRoot $file) -PathType Leaf)){throw ('The FF7 VR launcher is incomplete: '+$file)}}
 $bin=Join-Path $GameDirectory 'End\Binaries\Win64';if(-not(Test-Path -LiteralPath (Join-Path $bin 'ff7remake_.exe'))){$bin=Join-Path $GameDirectory 'End\Binaries\WinGDK'}
 if(-not(Test-Path -LiteralPath (Join-Path $bin 'ff7remake_.exe'))){throw 'The original FF7 game executable is missing.'}
 $storeFile=Join-Path $RuntimeRoot '.pcvrhub_ff7_store.txt';$store=if(Test-Path -LiteralPath $storeFile){[IO.File]::ReadAllText($storeFile).Trim().ToLowerInvariant()}else{'steam'}
 if($store -notin @('steam','epic','xbox')){throw 'The recorded FF7 store is invalid. Run the installer again.'}
 $modeFile=Join-Path $GameDirectory '.pcvrhub_ff7_mode.ini';$flat=(Test-Path -LiteralPath $modeFile) -and [IO.File]::ReadAllText($modeFile) -match '(?im)^\s*Mode\s*=\s*Flat\s*$'
 return [pscustomobject]@{Game=$GameDirectory;Runtime=$RuntimeRoot;Bin=$bin;Store=$store;Flat=[bool]$flat;Publisher=Join-Path $RuntimeRoot 'ff7vr-launcher.ps1';RestoreRequired=(Test-Path -LiteralPath (Join-Path $bin 'ff7vr.session.json'))}
}
function Invoke-FF7HubPublisher($Plan,[string]$Action){
 $file=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $quotedGame=$Plan.Game -replace '(\\+)$','${1}${1}'
 $arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$Plan.Publisher+'" '+$Action+' -GameDir "'+$quotedGame+'" -Store '+$Plan.Store
 if($Action -eq 'restore'){$arguments+=' -NoPause'}
 $process=Start-Process -FilePath $file -ArgumentList $arguments -WorkingDirectory $Plan.Runtime -Wait -PassThru -ErrorAction Stop
 if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw ('FF7 publisher launcher did not complete (exit '+$process.ExitCode+').')}
}
try{
 $plan=Get-FF7HubLaunchPlan $GameDirectory $RuntimeRoot
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ROUND8_LAUNCH_CAPTURE){
 $capture=[IO.Path]::GetFullPath($env:PCVR_ROUND8_LAUNCH_CAPTURE)
 if(-not $env:PCVR_ROUND8_TEST){throw 'Launch capture requires an isolated fixture configuration.'}
 $testConfig=Get-Content -LiteralPath $env:PCVR_ROUND8_TEST -Raw|ConvertFrom-Json
 $captureRoot=[IO.Path]::GetFullPath([string]$testConfig.Root).TrimEnd('\')+'\'
 if(-not $captureRoot.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $captureRoot '.pcvrhub_round8_fixture')) -or -not $capture.StartsWith($captureRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped its isolated fixture.'}
$plan|ConvertTo-Json|Set-Content -LiteralPath $env:PCVR_ROUND8_LAUNCH_CAPTURE;exit 0}
 if(-not $plan.Flat){Invoke-FF7HubPublisher $plan 'start';exit 0}
 if(Get-Process -Name ff7remake_ -ErrorAction SilentlyContinue){throw 'Close the game before starting a flat session.'}
 if($plan.RestoreRequired){Invoke-FF7HubPublisher $plan 'restore'}
 if(Test-Path -LiteralPath (Join-Path $plan.Bin 'ff7vr.session.json')){throw 'The previous VR session still needs restoration. Open restore.cmd in the VR files folder.'}
 if($plan.Store -eq 'steam'){Start-Process 'steam://rungameid/1462040' -ErrorAction Stop}
 else{
  . (Join-Path $plan.Runtime 'ff7vr-stores.ps1')
  $resolved=Resolve-GameInstall $plan.Game $plan.Store;if(-not $resolved.Install){throw $resolved.Error}
  if($plan.Store -eq 'epic'){$target=Get-EpicLaunchUri $resolved.Install}else{$target=Get-XboxLaunchTarget $resolved.Install}
  if(-not $target){throw 'The store launch record was not found. Start this flat session from your store launcher.'}
  if($plan.Store -eq 'xbox'){Start-Process explorer.exe -ArgumentList $target -ErrorAction Stop}else{Start-Process $target -ErrorAction Stop}
 }
}catch{Write-Host $_.Exception.Message -ForegroundColor Red;try{Add-Type -AssemblyName System.Windows.Forms;[void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'FF7 VR launch')}catch{};exit 1}

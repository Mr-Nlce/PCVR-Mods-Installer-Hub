param([string]$GameDirectory='', [string]$RuntimeRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
function Get-PC2VRHubLaunchPlan([string]$GameDirectory,[string]$RuntimeRoot){
 if(-not $GameDirectory){$GameDirectory=Split-Path -Parent $RuntimeRoot}
 foreach($file in @('Hod2.exe','Config.exe')){if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $file) -PathType Leaf)){throw ('The original game is incomplete: '+$file)}}
 foreach($file in @('HOTD2VR.exe','HOTD2Bridge.dll','openxr_loader.dll','injector.exe','gun.obj','gun.mtl','gun.bmp')){if(-not(Test-Path -LiteralPath (Join-Path $RuntimeRoot $file) -PathType Leaf)){throw ('PC2VR runtime is incomplete: '+$file)}}
 $mode=Join-Path $RuntimeRoot 'pcvrhub-mode.ini';$flat=(Test-Path -LiteralPath $mode) -and [IO.File]::ReadAllText($mode) -match '(?im)^\s*Mode\s*=\s*Flat\s*$'
 if($flat){return [pscustomobject]@{File=Join-Path $GameDirectory 'Hod2.exe';Arguments='';WorkingDirectory=$GameDirectory;Flat=$true}}
 return [pscustomobject]@{File=Join-Path $RuntimeRoot 'HOTD2VR.exe';Arguments='--game-exe "'+(Join-Path $GameDirectory 'Hod2.exe')+'"';WorkingDirectory=$RuntimeRoot;Flat=$false}
}
try{
 $plan=Get-PC2VRHubLaunchPlan $GameDirectory $RuntimeRoot
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ROUND8_LAUNCH_CAPTURE){
 $capture=[IO.Path]::GetFullPath($env:PCVR_ROUND8_LAUNCH_CAPTURE)
 if(-not $env:PCVR_ROUND8_TEST){throw 'Launch capture requires an isolated fixture configuration.'}
 $testConfig=Get-Content -LiteralPath $env:PCVR_ROUND8_TEST -Raw|ConvertFrom-Json
 $captureRoot=[IO.Path]::GetFullPath([string]$testConfig.Root).TrimEnd('\')+'\'
 if(-not $captureRoot.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $captureRoot '.pcvrhub_round8_fixture')) -or -not $capture.StartsWith($captureRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped its isolated fixture.'}
$plan|ConvertTo-Json|Set-Content -LiteralPath $env:PCVR_ROUND8_LAUNCH_CAPTURE;exit 0}
 if(Get-Process -Name Hod2,HOTD2VR -ErrorAction SilentlyContinue){throw 'Close the game and the VR viewer before starting another session.'}
 if($plan.Arguments){Start-Process -FilePath $plan.File -ArgumentList $plan.Arguments -WorkingDirectory $plan.WorkingDirectory -ErrorAction Stop}else{Start-Process -FilePath $plan.File -WorkingDirectory $plan.WorkingDirectory -ErrorAction Stop}
}catch{Write-Host $_.Exception.Message -ForegroundColor Red;try{Add-Type -AssemblyName System.Windows.Forms;[void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'HOTD2 PC2VR launch')}catch{};exit 1}

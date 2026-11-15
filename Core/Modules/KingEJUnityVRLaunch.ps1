param([string]$RuntimeRoot,[string]$ConfigName)
$ErrorActionPreference='Stop'
try{
 if(-not $RuntimeRoot){$RuntimeRoot=Split-Path $PSScriptRoot -Parent}
 $RuntimeRoot=[IO.Path]::GetFullPath($RuntimeRoot).TrimEnd('\','/')
 if($ConfigName -notin @('Agent64-launch.json','IHateThisPlace-launch.json')){throw 'The VR launch profile is missing. Run the matching Hub installer again.'}
 $config=Join-Path $RuntimeRoot ('PCVR-Launcher\'+$ConfigName)
 if(Test-Path -LiteralPath $config -PathType Leaf){$c=Get-Content -LiteralPath $config -Raw|ConvertFrom-Json}
 else{
  # A complete publisher installation predating the Hub has no Hub receipt
  # or launch JSON. Read its actual runtime files without reinstalling it.
  $key=$ConfigName -replace '-launch\.json$',''
  $d=if($key -eq 'Agent64'){@{Exe='Agent 64 Spies Never Die.exe';App='1574480';Plugin='A64VR';Dll='A64VR.dll'}}else{@{Exe='I Hate This Place.exe';App='2604490';Plugin='IHVR';Dll='IHVR.dll'}}
  $c=@{Key=$key;Exe=$d.Exe;App=$d.App;Store=$(if($RuntimeRoot -match '(?i)[\\/]steamapps[\\/]common[\\/]'){'Steam'}else{'Direct'});Required=@('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.Core.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll','dotnet\coreclr.dll','dotnet\hostpolicy.dll',('BepInEx\plugins\'+$d.Plugin+'\'+$d.Dll),('BepInEx\plugins\'+$d.Plugin+'\OpenXR.dll'))}
 }
 # Locate Game may re-associate a moved installation. All payload paths stay
 # relative to the freshly supplied, verified runtime root.
 foreach($rel in @($c.Required)+@($c.Exe,([IO.Path]::GetFileNameWithoutExtension($c.Exe)+'_Data\globalgamemanagers'))){
  if(-not(Test-Path -LiteralPath (Join-Path $RuntimeRoot $rel) -PathType Leaf)){throw ('Required game or VR file missing: '+$rel+'. Use Update / Repair in the Hub.')}
 }
 $file=if($c.Store -eq 'Steam' -and $c.Key -eq 'Agent64'){
  # Steam supplies the application context for the game's offline option.
  'steam://launch/1574480/option2'
 }elseif($c.Store -eq 'Steam' -and $c.Key -eq 'IHateThisPlace'){
  'steam://rungameid/'+$c.App
 }else{Join-Path $RuntimeRoot $c.Exe}
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KINGEJ_LAUNCH_CAPTURE){
  $capture=[IO.Path]::GetFullPath($env:PCVR_KINGEJ_LAUNCH_CAPTURE)
  if(-not $capture.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped Temp.'}
  @{File=$file;WorkingDirectory=$RuntimeRoot;Arguments='';Key=$c.Key;Store=$c.Store}|ConvertTo-Json|Set-Content -LiteralPath $capture -Encoding UTF8
  return
 }
 if($file -like 'steam:*'){Start-Process -FilePath $file -ErrorAction Stop|Out-Null}
 else{Start-Process -FilePath $file -WorkingDirectory $RuntimeRoot -ErrorAction Stop|Out-Null}
}catch{
 if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
 Add-Type -AssemblyName PresentationFramework
 [void][Windows.MessageBox]::Show($_.Exception.Message,'VR start','OK','Warning')
 exit 1
}

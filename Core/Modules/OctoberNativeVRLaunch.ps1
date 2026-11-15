param([Parameter(Mandatory=$true)][string]$RuntimeRoot,[ValidateSet('RE5','GearsEDay','CodeVeronica')][string]$Key)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($RuntimeRoot).TrimEnd([char[]]'\/')
$config=Join-Path $root ('PCVR-Launcher\'+$Key+'-launch.json')
if([IO.File]::Exists($config)){$c=[IO.File]::ReadAllText($config)|ConvertFrom-Json}
else{
 # Publisher/manual installations predate Hub bookkeeping. Real runtime files,
 # not this optional JSON, establish whether their documented start is usable.
 $store=if($root -match '(?i)[\\/]steamapps[\\/]common[\\/]'){'Steam'}else{'Direct'}
 $c=switch($Key){
  'RE5' {@{Store=$store;Sub='';Required=@('d3d9.dll','d3d9_dgvoodoo.dll','dgVoodoo.conf','openxr_loader.dll','SampleAddon.dll')}}
  'GearsEDay' {@{Store=$store;Sub='PCVR-Launcher\GoWEDay';Required=@('GoWEDay_VR.exe','gameinput_vr\gameinput_vr.dll','UEVR\UEVRBackend.dll','UEVR\UEVRInjector.exe','UEVR\LuaVR.dll','profile\scripts\fp.lua','profile\scripts\arms.lua')}}
  'CodeVeronica' {@{Store='ROM';Sub='';Required=@('recvx_vr.exe','PLAY_VR.bat');Iso=''}}
 }
}
$folder=if($c.Sub){Join-Path $root $c.Sub}else{$root}
foreach($rel in $c.Required){if(-not[IO.File]::Exists((Join-Path $folder $rel))){throw ('Required VR file is missing: '+$rel)}}
$arguments='';$working=$root
switch($Key){
 'RE5' {if(-not[IO.File]::Exists((Join-Path $root 're5dx9.exe'))){throw 'Locate the original Resident Evil 5 game folder.'};if($c.Store -eq 'Steam'){$file='steam://rungameid/21690'}else{$file=Join-Path $root 're5dx9.exe'}}
 'GearsEDay' {$file=Join-Path $folder 'GoWEDay_VR.exe';$working=$folder}
 'CodeVeronica' {$file=Join-Path $folder 'recvx_vr.exe';$arguments='--vr';if($c.Iso){if(-not[IO.File]::Exists([string]$c.Iso)){throw 'The selected disc image moved. Run setup to select its new location.'};$arguments+=' "'+[string]$c.Iso+'"'}}
}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_OCTOBER_LAUNCH_CAPTURE){
 $capture=[IO.Path]::GetFullPath($env:PCVR_OCTOBER_LAUNCH_CAPTURE);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
 if(-not $capture.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped Temp.'}
 @{File=$file;Arguments=$arguments;WorkingDirectory=$working}|ConvertTo-Json|Set-Content -LiteralPath $capture -Encoding UTF8;return
}
if($arguments){Start-Process -FilePath $file -ArgumentList $arguments -WorkingDirectory $working -ErrorAction Stop}else{Start-Process -FilePath $file -WorkingDirectory $working -ErrorAction Stop}

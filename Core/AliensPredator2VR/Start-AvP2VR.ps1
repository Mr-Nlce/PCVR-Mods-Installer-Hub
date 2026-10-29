param([string]$GameDirectory,[string]$RuntimeRoot,[switch]$PlanOnly)
$ErrorActionPreference='Stop'
try {
 if(-not $GameDirectory){$GameDirectory=Split-Path $PSScriptRoot -Parent}
 if([IO.File]::Exists($GameDirectory)){$GameDirectory=Split-Path $GameDirectory -Parent}
 $game=[IO.Path]::GetFullPath($GameDirectory).TrimEnd('\')
 foreach($file in @('AVP2.exe','lithtech.exe','AVP2.rez')){if(-not [IO.File]::Exists((Join-Path $game $file))){throw ('Locate the complete game folder; missing '+$file)}}
 $flat=-not [IO.File]::Exists((Join-Path $game 'DDraw.dll')) -and [IO.File]::Exists((Join-Path $game 'DDraw.dll.pcvrhub_off'))
 if($flat){$plan=@{File=(Join-Path $game 'AVP2.exe');Arguments='';Directory=$game;Flat=$true;Runtime=''}}else{
  foreach($file in @('DDraw.dll','D3DImm.dll','d3d11.dll','openxr_loader.dll','xrres.exe','avp2xr.ini','vrrez\cshell.dll','vrrez\cres.dll','vrrez\sres.dll')){if(-not [IO.File]::Exists((Join-Path $game $file))){throw ('The VR runtime needs repair; missing '+$file)}}
  $runtime='';$candidates=@()
  $paths=Join-Path $env:LOCALAPPDATA 'openvr\openvrpaths.vrpath'
  if([IO.File]::Exists($paths)){try{$candidates+=@(([IO.File]::ReadAllText($paths)|ConvertFrom-Json).runtime)}catch{}}
  foreach($key in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKCU:\Software\Valve\Steam')){try{$steam=Get-ItemProperty -LiteralPath $key -ErrorAction Stop;foreach($root in @($steam.InstallPath,$steam.SteamPath)){if($root){$candidates+=Join-Path $root 'steamapps\common\SteamVR'}}}catch{}}
  foreach($root in $candidates){$json=Join-Path $root 'steamxr_win32.json';if([IO.File]::Exists($json)){$runtime=$json;break}}
  if(-not $runtime){throw 'Start SteamVR first. Its 32-bit OpenXR runtime could not be found.'}
  $virtual=Join-Path (Join-Path $env:LOCALAPPDATA 'VirtualStore') $game.Substring(3)
  $cmd='';foreach($f in @((Join-Path $virtual 'avp2cmds.txt'),(Join-Path $game 'avp2cmds.txt'))){if([IO.File]::Exists($f)){$cmd=([IO.File]::ReadAllText($f)).Trim();if($cmd){break}}}
  if(-not $cmd){$rez=@('AVP2.rez','sounds.rez','Alien.rez','Marine.rez','Predator.rez','Multi.rez','AVP2dll.rez','AVP2l.rez','custom','AVP2p.rez','AVP2p2.rez','AVP2P1.rez','AVP2P5.rez')|Where-Object {Test-Path -LiteralPath (Join-Path $game $_)};$cmd='-windowtitle "Aliens vs. Predator 2" '+(($rez|ForEach-Object {'-rez "'+$_+'"'}) -join ' ')+' +DisableMusic 0 +DisableSound 0 +DisableMovies 1 +EnableTripBuf 1 +DisableHardwareCursor 0'}
  $res=[regex]::Match([IO.File]::ReadAllText((Join-Path $game 'avp2xr.ini')),'(?im)^\s*GameResolution\s*=\s*(\d+)x(\d+)(?:x(\d+))?\s*$')
  $arguments=$cmd+' -rez vrrez'
  if($res.Success){$depth=if($res.Groups[3].Success){$res.Groups[3].Value}else{'32'};$arguments+=' +ScreenWidth '+$res.Groups[1].Value+' +ScreenHeight '+$res.Groups[2].Value+' +BitDepth '+$depth}
  $plan=@{File=(Join-Path $game 'lithtech.exe');Arguments=$arguments;Directory=$game;Flat=$false;Runtime=$runtime}
 }
 if($PlanOnly){return [pscustomobject]$plan}
 if(-not $flat){$env:XR_RUNTIME_JSON=$plan.Runtime;$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=Join-Path $game 'xrres.exe';$psi.WorkingDirectory=$game;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$p=[Diagnostics.Process]::Start($psi);$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$p.WaitForExit();Write-Information ($o.Result+$e.Result) -InformationAction SilentlyContinue;if($p.ExitCode -ne 0){throw ('VR resolution preparation failed (exit '+$p.ExitCode+'). Start SteamVR and retry.')}}
 if($plan.Arguments){Start-Process -FilePath $plan.File -ArgumentList $plan.Arguments -WorkingDirectory $game | Out-Null}else{Start-Process -FilePath $plan.File -WorkingDirectory $game | Out-Null}
}catch{if($PlanOnly){throw};Add-Type -AssemblyName PresentationFramework;[void][Windows.MessageBox]::Show($_.Exception.Message,'Aliens versus Predator 2 VR')}

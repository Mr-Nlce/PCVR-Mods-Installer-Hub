# Read-only, route-specific Teardown evidence used by scan and Play.
function Get-PCVRTeardownMarkosVersion {
 param([string]$Root)
 try{
  $file=Join-Path $Root 'dxgi.dll'
  if(-not [IO.File]::Exists($file)){return $null}
  $item=Get-Item -LiteralPath $file -ErrorAction Stop
  if($item.PSIsContainer -or $item.Length -lt 64 -or $item.Length -gt 32MB){return $null}
  $bytes=[IO.File]::ReadAllBytes($file)
  if($bytes[0] -ne 77 -or $bytes[1] -ne 90){return $null}
  $match=[regex]::Match([Text.Encoding]::ASCII.GetString($bytes),'TDVR_PROXY_MARKER Teardown VR (\d+\.\d+(?:\.\d+)?)')
  if($match.Success){return ('v'+$match.Groups[1].Value)}
 }catch{}
 return $null
}
function Test-PCVRTeardownProfile {
 param([string]$GameRoot,[ValidateSet('A','B')][string]$Slot)
 try{
  if($Slot -eq 'B'){
   $root=Join-Path $GameRoot '.pcvrhub_teardown_profiles\markos'
   $required=@('dxgi.dll','TeardownVR\main.lua','TeardownVR\info.txt','TeardownVR\hands_glove.vox','TeardownVR\hands_skin.vox','TeardownVR\hands_blocky.vox','.pcvrhub_version','.pcvrhub_teardownmarkosprofile_ownership.csv')
   foreach($rel in $required){$path=Join-Path $root $rel;if(-not [IO.File]::Exists($path)){return $false};$file=Get-Item -LiteralPath $path -ErrorAction Stop;if($file.PSIsContainer -or $file.Length -eq 0){return $false}}
   $version=Get-PCVRTeardownMarkosVersion -Root $root
   return [bool]($version -and $version -eq [IO.File]::ReadAllText((Join-Path $root '.pcvrhub_version')).Trim())
  }
  foreach($rel in @('mods\teardownvr\main.lua','mods\teardownvr\info.txt','mods\teardownvr\proxy.vox','.pcvrhub_version')){
   $path=Join-Path $GameRoot $rel;if(-not [IO.File]::Exists($path)){return $false};$file=Get-Item -LiteralPath $path -ErrorAction Stop;if($file.PSIsContainer -or $file.Length -eq 0){return $false}
  }
  $stamp=[IO.File]::ReadAllText((Join-Path $GameRoot '.pcvrhub_version')).Trim()
  if($stamp -notmatch '^v?\d+(?:\.\d+)+(?:[-+][0-9A-Za-z.-]+)?$'){return $false}
  foreach($rel in @('dsound.dll','dsound.dll.pcvrhub_teardown_legacy')){
   $path=Join-Path $GameRoot $rel
   if([IO.File]::Exists($path) -and (Get-Item -LiteralPath $path).Length -le 32MB -and [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($path)).Contains('TDVR1')){return $true}
  }
 }catch{}
 return $false
}

param([string]$GameDir,[string]$RuntimeDir)
$ErrorActionPreference='Stop'
$root=if($RuntimeDir){$RuntimeDir}elseif($GameDir){$GameDir}else{Join-Path $env:LOCALAPPDATA 'BloodMoneyVR'}
if(-not $RuntimeDir -and -not $GameDir -and -not(Test-Path -LiteralPath (Join-Path $root 'BloodMoneyVR.exe') -PathType Leaf)){
    $previousHubRoot=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\BloodMoneyVR'
    if(Test-Path -LiteralPath (Join-Path $previousHubRoot 'BloodMoneyVR.exe') -PathType Leaf){$root=$previousHubRoot}
}
$launcher=Join-Path $root 'BloodMoneyVR.exe'
if(-not(Test-Path -LiteralPath $launcher -PathType Leaf)){throw "Blood Money VR launcher is missing: $launcher"}
Start-Process -FilePath $launcher -WorkingDirectory $root -ErrorAction Stop

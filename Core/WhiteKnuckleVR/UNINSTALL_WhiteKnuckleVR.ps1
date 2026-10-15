param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$identity='whiteknucklevr'
function Finish-WKUninstall([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-WKOwnedRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'White Knuckle.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Path ".pcvrhub_${identity}_ownership.csv") -PathType Leaf))}
$selected=$null
if(Test-WKOwnedRoot $GameRoot){$isDepot=[bool]((Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_whiteknuckle_depot_25612096')) -or (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_whiteknuckle_depot_24318677')));$selected=[pscustomobject]@{Path=(Get-Item -LiteralPath $GameRoot).FullName;Receipt=(Join-Path $PSScriptRoot $(if($isDepot){'.installed_path_depot'}else{'.installed_path'}));Route=$(if($isDepot){'Depot'}else{'Current'})}}
else{
    $candidates=@(foreach($spec in @(@('.installed_path','Current'),@('.installed_path_depot','Depot'))){$path=Join-Path $PSScriptRoot $spec[0];if(Test-Path -LiteralPath $path -PathType Leaf){try{$root=([IO.File]::ReadAllText($path)).Trim().Trim('"');if(Test-WKOwnedRoot $root){[pscustomobject]@{Path=$root;Receipt=$path;Route=$spec[1]}}}catch{}}})
    if($candidates.Count -eq 0){Write-Host '  No Hub-owned WhiteKnuckleVR installation was found.' -ForegroundColor Yellow;Finish-WKUninstall 0}
    if($candidates.Count -eq 1){$selected=$candidates[0]}
    else{Write-Host '  Choose the independent VR route to remove:' -ForegroundColor Yellow;for($i=0;$i -lt $candidates.Count;$i++){Write-Host "  [$($i+1)] $($candidates[$i].Route): $($candidates[$i].Path)"};Write-Host '  [Q] Cancel';do{$choice=([string](Read-Host '  Choice')).Trim().ToUpperInvariant()}while($choice -notin @('1','2','Q'));if($choice -eq 'Q'){Finish-WKUninstall 0};$selected=$candidates[[int]$choice-1]}
}
$GameRoot=(Get-Item -LiteralPath $selected.Path).FullName
if(Get-Process -Name 'White Knuckle' -ErrorAction SilentlyContinue){Write-Host '  [XX] Close White Knuckle before removing VR mode.' -ForegroundColor Red;Finish-WKUninstall 1}
if(-not $HubConfirmed){$confirm=([string](Read-Host "Remove Hub-owned WhiteKnuckleVR files from '$GameRoot'? Type REMOVE")).Trim();if($confirm -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-WKUninstall 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $identity -ParkedAlternates @{'BepInEx\plugins\WhiteKnuckleVRMod\WhiteKnuckleVRMod.dll'='BepInEx\plugins\WhiteKnuckleVRMod\WhiteKnuckleVRMod.dll.off'}
if(-not $result.Found){throw 'The ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if(Test-Path -LiteralPath $selected.Receipt -PathType Leaf){try{$saved=([IO.File]::ReadAllText($selected.Receipt)).Trim();if([IO.Path]::GetFullPath($saved)-eq[IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $selected.Receipt -Force}}catch{}}
}
if($result.Preserved -gt 0){Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved." -ForegroundColor Yellow}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  White Knuckle and the independent depot game data remain. An older parked loose VR DLL remains available for manual recovery.' -ForegroundColor Gray
Finish-WKUninstall 0

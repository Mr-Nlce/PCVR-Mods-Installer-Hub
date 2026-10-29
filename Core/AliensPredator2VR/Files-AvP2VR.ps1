param([Parameter(Mandatory=$true)][string]$Request)
$ErrorActionPreference='Stop';$r=$null
try{
 $r=Get-Content -LiteralPath $Request -Raw|ConvertFrom-Json
 . (Join-Path $PSScriptRoot '..\Modules\AliensPredator2Setup.ps1')
 if($r.Action -notin @('install','restore','remove','commit')){throw 'Unknown file operation.'}
 $value=Invoke-Avp2FileAction $r.Action $r.Game $r.Stage $r.Snapshot
 @{Success=$true;Value=$value}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $r.Result -Encoding UTF8
 exit 0
}catch{if($r){@{Success=$false;Message=$_.Exception.Message}|ConvertTo-Json|Set-Content -LiteralPath $r.Result -Encoding UTF8};exit 1}

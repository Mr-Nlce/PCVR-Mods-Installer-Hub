param([ValidateSet('modern','legacy')][string]$Mod='modern',[switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Pragmata-Profiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
$test=Get-PublisherVRTestContext
$game=Get-OctoberNativeGame @{Id='pragmata-vr';GameFolder='PRAGMATA';Exe='PRAGMATA.exe';App='3357650';Key='Pragmata'} $test
Assert-PragmataClosed
if(-not $HubConfirmed -and (Read-Host ('Type REMOVE to remove '+$Mod)) -cne 'REMOVE'){return}
$active=Join-Path $game '_vrmods\pragmata\active.txt'
if([IO.File]::Exists($active) -and [IO.File]::ReadAllText($active) -eq $Mod){
 [void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'pragmataactive')
 $plugin=Join-Path $game 'PDAFWPlugin.dll';$pluginOff=$plugin+'.pcvrhub_off'
 if(-not[IO.File]::Exists($plugin) -and [IO.File]::Exists($pluginOff)){Move-Item -LiteralPath $pluginOff -Destination $plugin}
 foreach($name in Get-PragmataHudNames){$away=Join-Path $game ('reframework\autorun\pragmatavr_disabled\'+$name);$live=Join-Path $game ('reframework\autorun\'+$name);if([IO.File]::Exists($away) -and -not[IO.File]::Exists($live)){Move-Item -LiteralPath $away -Destination $live}}
 Remove-Item -LiteralPath $active -Force
}
[void](Uninstall-OwnedModPayload -GameRoot $game -Identity ('pragmata'+$Mod))
foreach($file in @((Join-Path (Get-PragmataStore $game $Mod) '.pcvrhub_version'),(Join-Path $game $(if($Mod -eq 'modern'){'.pcvrhub_version_b'}else{'.pcvrhub_version'})))){if([IO.File]::Exists($file)){Remove-Item -LiteralPath $file -Force}}
$other=if($Mod -eq 'modern'){'legacy'}else{'modern'}
if(-not(Test-PragmataProfile $game $other)){[void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'pragmatalinks')}
Write-Host '  [OK] Selected Hub VR package removed; prior files restored. Other VR profile, saves and settings are kept.' -ForegroundColor Green

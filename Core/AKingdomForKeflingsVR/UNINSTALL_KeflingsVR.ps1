param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$receipt=(''+$env:PCVR_KEFLINGS_TEST_RECEIPT).Trim();if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
function Finish-KeflingsRemoval([int]$Code){if(-not $NoPause){Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-KeflingsOwnedRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath $Path -PathType Container) -and (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_keflingsvr_ownership.csv') -PathType Leaf))}
if(-not(Test-KeflingsOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
if(-not(Test-KeflingsOwnedRoot $GameRoot)){Write-Host '  No Hub-owned Keflings VR install was found.' -ForegroundColor Yellow;Finish-KeflingsRemoval 0}
if(Get-Process -Name 'A Kingdom for Keflings' -ErrorAction SilentlyContinue){Write-Host '  [XX] Close A Kingdom for Keflings before removing VR.' -ForegroundColor Red;Finish-KeflingsRemoval 1}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Keflings VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE'){Finish-KeflingsRemoval 0}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'keflingsvr'
if(-not $result.Found){throw 'The Keflings VR ownership manifest disappeared before removal.'}
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Hub-owned files removed: $($result.Removed); originals restored: $($result.Restored); changed files kept: $($result.Preserved)." -ForegroundColor Green
Write-Host '  The licensed game, saves, personal VR settings and unrelated files remain.' -ForegroundColor Gray
Finish-KeflingsRemoval 0

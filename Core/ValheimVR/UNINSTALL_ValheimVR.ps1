param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
$old=$env:PCVR_VALHEIM_SETUP_LIBRARY_ONLY;$env:PCVR_VALHEIM_SETUP_LIBRARY_ONLY='1'
. (Join-Path $PSScriptRoot 'ValheimVR-core.ps1')
$env:PCVR_VALHEIM_SETUP_LIBRARY_ONLY=$old
$game=Get-ValheimGame
if(Get-Process -Name valheim -ErrorAction SilentlyContinue){throw 'Close Valheim before removing its VR files.'}
Write-Host '  Unchanged Hub-owned files will be removed; earlier same-name files restored.' -ForegroundColor White
Write-Host '  Saved worlds, characters, edited settings and unrelated mods stay.' -ForegroundColor White
if(-not $HubConfirmed){[void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove Valheim VR...')}
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'valheimvr'
$shortcut=Get-ValheimShortcutPath
if(Test-Path -LiteralPath $shortcut){
 $shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut($shortcut)
 $expected=Join-Path $game 'PCVR-Valheim\Start-ValheimVR.ps1'
 if($link.Arguments.Contains('"'+$expected+'"')){Remove-Item -LiteralPath $shortcut -Force}
}
Write-Host ('  [OK] Removed '+$result.Removed+' files; restored '+$result.Restored+' earlier files.') -ForegroundColor Green
Write-Host '';Write-Host '  The trees still have the highest kill count.' -ForegroundColor Magenta
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')

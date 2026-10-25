param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$game=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FC2_TEST_GAME){$env:PCVR_FC2_TEST_GAME}else{
    Get-PCVRRememberedGameFolder -GameId 'far-cry-2-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('bin\FarCry2.exe')
}
if(-not $game){$game=Find-SteamGameFolder -AppId '19900' -SteamFolderNames @('Far Cry 2') -ProbeExe 'bin\FarCry2.exe' -HubGameId 'far-cry-2-vr'}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_farcry2vr_ownership.csv') -PathType Leaf)){
    throw 'No Hub-owned Far Cry 2 VR installation was found.'
}
if(Get-Process -Name FarCry2,FarCry2VR -ErrorAction SilentlyContinue){throw 'Close Far Cry 2 before removing VR.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Far Cry 2 VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$link=Join-Path $(if($env:PCVR_FC2_TEST_DESKTOP){$env:PCVR_FC2_TEST_DESKTOP}else{[Environment]::GetFolderPath('DesktopDirectory')}) 'Far Cry 2 VR.lnk'
$target=Join-Path $game 'FarCry2VR-Launcher.exe'
$removeLink=$false
$shortcutMarker=Join-Path $game '.pcvrhub_fc2_desktop_shortcut.json'
if((Test-Path -LiteralPath $link -PathType Leaf) -and (Test-Path -LiteralPath $shortcutMarker -PathType Leaf)){
    $record=Get-Content -LiteralPath $shortcutMarker -Raw -Encoding UTF8|ConvertFrom-Json
    $shell=New-Object -ComObject WScript.Shell
    $shortcut=$shell.CreateShortcut($link)
    $removeLink=([string]$shortcut.TargetPath -ieq $target -and [string]$record.Path -ieq $link -and
        [string]$record.Hash -eq (Get-FileHash -LiteralPath $link -Algorithm SHA256).Hash)
}
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'farcry2vr'
if($removeLink -and (Test-Path -LiteralPath $link -PathType Leaf)){Remove-Item -LiteralPath $link -Force}
if(Test-Path -LiteralPath $shortcutMarker -PathType Leaf){Remove-Item -LiteralPath $shortcutMarker -Force}
if(-not(Test-Path -LiteralPath (Join-Path $game 'bin\dinput8.dll') -PathType Leaf)){
    foreach($p in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
        if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}
    }
}
Write-Host "  [OK] Far Cry 2 VR files removed: $($result.Removed); originals restored: $($result.Restored)." -ForegroundColor Green
if($result.Preserved -gt 0){Write-Host "  Locally changed files kept: $($result.Preserved)." -ForegroundColor Yellow}
Write-Host '  Your game, saves, profile and unrelated files remain.' -ForegroundColor Gray

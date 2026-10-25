param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$game=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLOODLINES_TEST_GAME){$env:PCVR_BLOODLINES_TEST_GAME}else{
    Get-PCVRRememberedGameFolder -GameId 'vampire-bloodlines-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('vampire.exe')
}
if(-not $game){$game=Find-SteamGameFolder -AppId '2600' -SteamFolderNames @('Vampire The Masquerade - Bloodlines') -ProbeExe 'vampire.exe' -HubGameId 'vampire-bloodlines-vr'}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_bloodlinesvr_ownership.csv') -PathType Leaf)){
    throw 'No Hub-owned Bloodlines VR installation was found.'
}
if(Get-Process -Name vampire -ErrorAction SilentlyContinue){throw 'Close Bloodlines before removing VR.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Bloodlines VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'bloodlinesvr'
if(-not(Test-Path -LiteralPath (Join-Path $game 'VR\SteamVRActionManifest\action_manifest.json') -PathType Leaf)){
    foreach($p in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
        if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}
    }
}
$desktop=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLOODLINES_TEST_DESKTOP){$env:PCVR_BLOODLINES_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
foreach($name in @('Bloodlines VR.lnk','Bloodlines VR (Hub).lnk')){
$link=Join-Path $desktop $name
if(Test-Path -LiteralPath $link -PathType Leaf){
    $shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut($link)
    if($shortcut.TargetPath -ieq (Join-Path $game 'vampire.exe') -and
       $shortcut.Arguments -in @('-game Unofficial_Patch -vr -novid -window -w 1920 -h 1080',
           '-game Unofficial_Patch -vr -console -novid -window -w 1920 -h 1080')){
        Remove-Item -LiteralPath $link -Force
    }
}
}
Write-Host "  [OK] Bloodlines VR files removed: $($result.Removed); earlier files restored: $($result.Restored)." -ForegroundColor Green
if($result.Preserved -gt 0){Write-Host "  Locally changed files kept: $($result.Preserved)." -ForegroundColor Yellow}
Write-Host '  Bloodlines, the Unofficial Patch, saves and unrelated files remain.' -ForegroundColor Gray

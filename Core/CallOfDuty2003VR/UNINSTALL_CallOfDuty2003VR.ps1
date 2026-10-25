param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$id='call-of-duty-2003-vr'
$game=if($env:PCVR_COD1_TEST_GAME){[IO.Path]::GetFullPath($env:PCVR_COD1_TEST_GAME)}else{
    Get-PCVRRememberedGameFolder -GameId $id -StateNames @('installed_path','user_located','base_game_path') -ProbeFiles @('CoDSP.exe','main\pak0.pk3')
}
if(-not $game){$game=Find-SteamGameFolder -AppId '2620' -SteamFolderNames @('Call of Duty') -ProbeExe 'CoDSP.exe' -HubGameId $id}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_cod1vr_ownership.csv') -PathType Leaf)){throw 'No Hub-owned Call of Duty VR installation was found.'}
if(Get-Process -Name CoDSP -ErrorAction SilentlyContinue){throw 'Close Call of Duty before uninstalling VR.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Call of Duty VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'cod1vr'
$manifest=Join-Path $game '.pcvrhub_cod1vr_ownership.csv'
if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)){
    foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
        if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}
    }
    $desktop=if($env:PCVR_COD1_TEST_DESKTOP){$env:PCVR_COD1_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
    $link=Join-Path $desktop 'Call of Duty VR.lnk'
    if(Test-Path -LiteralPath $link -PathType Leaf){
        $shell=New-Object -ComObject WScript.Shell
        $shortcut=$shell.CreateShortcut($link)
        if(([string]$shortcut.TargetPath).Equals((Join-Path $game 'CoD-VR-Launcher.exe'),[StringComparison]::OrdinalIgnoreCase)){
            Remove-Item -LiteralPath $link -Force
        }
    }
}
Write-Host "  [OK] Call of Duty VR files removed: $($result.Removed); originals restored: $($result.Restored)." -ForegroundColor Green
if($result.Preserved -gt 0){Write-Host "  Changed local files preserved: $($result.Preserved)." -ForegroundColor Yellow}
Write-Host '  Your game, saves and unrelated files remain.' -ForegroundColor Gray

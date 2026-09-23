param([string]$GameRoot='', [string]$StateRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$IDENTITY='saintsrowthirdvr';$GAME_EXE='SaintsRowTheThird_DX11.exe'
if(-not$StateRoot){$StateRoot=$PSScriptRoot}

function Finish-SR3([int]$Code){if(-not$NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-SR3Root([string]$Path){return [bool]($Path-and(Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))}
function Remove-KnownLegacyFile([string]$Relative,[string]$Sha){
    $path=Join-Path $GameRoot $Relative
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return 0}
    if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-ne$Sha){Write-Host " [KEEP] Changed or unknown file: $Relative" -ForegroundColor Yellow;return 0}
    Remove-Item -LiteralPath $path -Force -ErrorAction Stop;return 1
}

try{
    if(-not(Test-SR3Root $GameRoot)){try{$saved=([IO.File]::ReadAllText((Join-Path $StateRoot '.installed_path'))).Trim();if(Test-SR3Root $saved){$GameRoot=$saved}}catch{}}
    if(-not(Test-SR3Root $GameRoot)){$GameRoot=Find-SteamGameFolder -AppId '55230' -SteamFolderNames @('Saints Row the Third') -ProbeExe $GAME_EXE -GogNames @('Saints Row 3') -HubGameId 'saints-row-the-third-vr'}
    if(-not(Test-SR3Root $GameRoot)){Write-Host '[X] Saints Row: The Third was not found. No files were changed.' -ForegroundColor Red;Finish-SR3 1}
    if(-not$HubConfirmed){$answer=(''+(Read-Host "Remove the ZMenu VR package from '$GameRoot'? Type REMOVE")).Trim();if($answer-cne'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-SR3 0}}
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    $removed=0;$restored=0;$preserved=0
    if(Test-Path -LiteralPath $manifest -PathType Leaf){
        $result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY
        if(-not$result.Found){throw 'The ownership record disappeared before removal.'}
        $removed=[int]$result.Removed;$restored=[int]$result.Restored;$preserved=[int]$result.Preserved
    }else{
        # Pre-manifest Hub installations can be recognized only by the exact
        # reviewed package bytes. Generic dinput8.dll, bass.dll and the user
        # INI deliberately stay in place because their prior ownership is not
        # knowable after the old installer overwrote them.
        $known=[ordered]@{
            'ZMenuSR3.asi'='91182BC8FC9B4140052943306953D3FB498608D04320E9D0812644079450AC55'
            'zmods_twitch.dll'='65CADD966B0D98D75900B115402B57475E76CA70C762050152866D7350FB8601'
            'openvr_api.dll'='965D24D2B097880475FB825D7675C819E42DC392209C742DD0FBF23AD322E005'
            'vr_actions.json'='4F9A571E9ACC3739B64A396418F8FC2BB1B931F217D8A70D54427EC64465FCE2'
            'vr_actions_knuckles.json'='C5A4C3BD2C0AEDB9FAB8DC907E76F2C4A92F995E3D1BE0CEECBA9A24C564BDFB'
            'vr_actions_oculus_touch.json'='215D3949AF6CCFB3AA4AF6F87F9318A06350CA47BC250C64705378BBA51E6497'
            'vr_actions_vive_controller.json'='8BEAA26782C5EF2DFB0A4200BD51D86AAE725C78CA759A3F5C4DBF15BEF7268B'
        }
        foreach($item in $known.GetEnumerator()){$removed+=Remove-KnownLegacyFile -Relative $item.Key -Sha $item.Value}
        if($removed-eq0){throw 'No Hub ownership record or unchanged reviewed legacy VR file was found. Nothing was guessed.'}
    }
    if($preserved-eq0){
        foreach($name in @('.pcvrhub_version','.pcvrhub.install.json')){Remove-Item -LiteralPath (Join-Path $GameRoot $name) -Force -ErrorAction SilentlyContinue}
        foreach($name in @('.installed_path','.installed_version')){Remove-Item -LiteralPath (Join-Path $StateRoot $name) -Force -ErrorAction SilentlyContinue}
        try{$shortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Saints Row The Third VR.lnk';if(Test-Path -LiteralPath $shortcut){$shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut($shortcut);if([IO.Path]::GetFullPath($link.TargetPath)-eq[IO.Path]::GetFullPath((Join-Path $GameRoot $GAME_EXE))){Remove-Item -LiteralPath $shortcut -Force}}}catch{}
    }
    Write-Host " [OK] Removed $removed, restored $restored, preserved $preserved changed file(s)." -ForegroundColor Green
    Write-Host ' [KEEP] ZMenuSR3.ini, saves, generic loaders and unrelated mods were retained.' -ForegroundColor Gray
    Finish-SR3 0
}catch{Write-Host '[X] Saints Row VR could not be removed safely.' -ForegroundColor Red;Write-Host "    $($_.Exception.Message)" -ForegroundColor Yellow;Finish-SR3 1}

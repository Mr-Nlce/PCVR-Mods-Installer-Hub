# Older direct CMD launchers and newer delegated launchers have distinct dependencies.
function global:Get-PCVRSomaLauncherFiles {
    param([string]$Root)
    $required=@('LAUNCH-SOMA-VR.cmd')
    $cmd=Join-Path $Root 'LAUNCH-SOMA-VR.cmd'
    if([IO.File]::Exists($cmd)){
        $text=[IO.File]::ReadAllText($cmd)
        if($text -match '(?i)Launch-SOMA-VR\.ps1'){
            $required+='Launch-SOMA-VR.ps1'
            $script=Join-Path $Root 'Launch-SOMA-VR.ps1'
            if([IO.File]::Exists($script) -and [IO.File]::ReadAllText($script) -match '(?i)SOMA-VR-LaunchSupport\.dll'){
                $required+='SOMA-VR-LaunchSupport.dll'
            }
        }
    }
    return $required
}

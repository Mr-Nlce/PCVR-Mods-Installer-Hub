param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
foreach($relative in @('CoDSP.exe','main\pak0.pk3','opengl32.dll','openxr_loader.dll','CoD-VR-Launcher.exe','.pcvrhub_cod1vr_ownership.csv','.pcvrhub_version')){
    $path=Join-Path $GameDirectory $relative
    if(-not(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0){
        throw "Call of Duty VR is incomplete: $relative. Use Reinstall in the Hub."
    }
}
$launcher=Join-Path $GameDirectory 'CoD-VR-Launcher.exe'
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COD1_TEST_LAUNCH_CAPTURE){
    [pscustomobject]@{File=$launcher;WorkingDirectory=$GameDirectory} | ConvertTo-Json -Compress |
        Set-Content -LiteralPath $env:PCVR_COD1_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
Start-Process -FilePath $launcher -WorkingDirectory $GameDirectory -ErrorAction Stop | Out-Null

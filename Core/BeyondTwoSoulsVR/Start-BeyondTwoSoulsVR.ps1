param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
$scriptPath=Join-Path $GameDirectory 'B2S_VR_MOD\tools\b2svr_setup.ps1'
foreach($name in @('BeyondTwoSouls_Steam.exe|BeyondTwoSouls.exe','BigFile_PC.dat','dinput8.dll','B2S_VR_MOD\files\dinput8.dll','B2S_VR_MOD\files\BUILD.txt','B2S_VR_MOD\tools\b2svr_setup.ps1','.pcvrhub_version')){
    $choices=@($name -split '\|');$found=$false
    foreach($choice in $choices){if(Test-Path -LiteralPath (Join-Path $GameDirectory $choice) -PathType Leaf){$found=$true;break}}
    if(-not $found){throw "Beyond VR launch is incomplete: $name"}
}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_B2S_TEST_LAUNCH_CAPTURE){[IO.File]::WriteAllText($env:PCVR_B2S_TEST_LAUNCH_CAPTURE,$scriptPath);exit 0}
$p=Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "'+$scriptPath+'" -Mode Play -Unattended -GameDir "'+$GameDirectory+'"') -WorkingDirectory (Split-Path -Parent $scriptPath) -PassThru -Wait -ErrorAction Stop
if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "Beyond publisher Play launcher ended with exit code $($p.ExitCode)."}

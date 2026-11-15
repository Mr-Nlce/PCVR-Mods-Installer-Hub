param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
$scriptPath=Join-Path $GameDirectory 'B2S_VR_MOD\tools\b2svr_setup.ps1'
foreach($name in @('BeyondTwoSouls_Steam.exe|BeyondTwoSouls.exe','BigFile_PC.dat','dinput8.dll','B2S_VR_MOD\files\dinput8.dll','B2S_VR_MOD\files\BUILD.txt','B2S_VR_MOD\tools\b2svr_setup.ps1')){
    $choices=@($name -split '\|');$found=$false
    foreach($choice in $choices){if(Test-Path -LiteralPath (Join-Path $GameDirectory $choice) -PathType Leaf){$found=$true;break}}
    if(-not $found){throw "Beyond VR launch is incomplete: $name"}
}
$build = Get-Content -LiteralPath (Join-Path $GameDirectory 'B2S_VR_MOD\files\BUILD.txt') -Raw
$version = [regex]::Match($build,'(?im)^version:[ \t]*([0-9]+(?:\.[0-9]+)+)[ \t]*\r?$').Groups[1].Value
if (!$version) { throw 'Beyond VR could not determine the installed publisher build.' }
if ([version]$version -ge [version]'1.0') {
    $target = if ([IO.File]::Exists((Join-Path $GameDirectory 'BeyondTwoSouls_Steam.exe'))) {
        'steam://rungameid/960990'
    } else {
        Join-Path $GameDirectory 'BeyondTwoSouls.exe'
    }
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_B2S_TEST_LAUNCH_CAPTURE) {
        [IO.File]::WriteAllText($env:PCVR_B2S_TEST_LAUNCH_CAPTURE,$target)
        exit 0
    }
    Start-Process -FilePath $target -WorkingDirectory $GameDirectory -ErrorAction Stop
    exit 0
}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_B2S_TEST_LAUNCH_CAPTURE){[IO.File]::WriteAllText($env:PCVR_B2S_TEST_LAUNCH_CAPTURE,$scriptPath);exit 0}
$p=Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "'+$scriptPath+'" -Mode Play -Unattended -GameDir "'+$GameDirectory+'"') -WorkingDirectory (Split-Path -Parent $scriptPath) -PassThru -Wait -ErrorAction Stop
if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "Beyond publisher Play launcher ended with exit code $($p.ExitCode)."}

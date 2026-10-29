param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
foreach($name in @('vampire.exe','VTMBup-readme.txt','Loader.exe',
    'Unofficial_Patch\cfg\autoexec.cfg','Unofficial_Patch\vdata\system\rules.txt','d3d9.dll','openvr_api.dll',
    'openxr_loader.dll','VR\config.txt','VR\SteamVRActionManifest\action_manifest.json')){
    if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $name) -PathType Leaf)){
        throw "Bloodlines VR is incomplete: $name. Use Reinstall in the Hub."
    }
}
$patchReadme=[IO.File]::ReadAllText((Join-Path $GameDirectory 'VTMBup-readme.txt'))
$patchVersion=[regex]::Match($patchReadme,
    '(?m)^Version Changelog:\s*\r?\n-+\s*\r?\n\s*v(?<version>\d+(?:\.\d+)*)[ \t]+\d{2}\.\d{2}\.\d{4}')
if(-not $patchVersion.Success -or $patchVersion.Groups['version'].Value -ne '11.5'){
    throw 'Bloodlines VR requires a complete Unofficial Patch 11.5 installation. Use Reinstall in the Hub.'
}
$exe=Join-Path $GameDirectory 'vampire.exe'
$arguments='-game Unofficial_Patch -vr -novid -window -w 1920 -h 1080'
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLOODLINES_TEST_LAUNCH_CAPTURE){
    [pscustomobject]@{File=$exe;Arguments=$arguments;WorkingDirectory=$GameDirectory}|
        ConvertTo-Json -Compress|Set-Content -LiteralPath $env:PCVR_BLOODLINES_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
Start-Process -FilePath $exe -WorkingDirectory $GameDirectory -ArgumentList $arguments -ErrorAction Stop|Out-Null

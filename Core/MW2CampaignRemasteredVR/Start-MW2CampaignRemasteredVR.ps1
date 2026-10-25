param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
foreach($relative in @('MW2CR.exe','overlord.exe','openxr_loader.dll','overlord.vrmanifest','vr_input\actions.json','h2-mod\ui_scripts\branding\__init__.lua','.pcvrhub_mw2overlord_ownership.csv','.pcvrhub_version')){
    $file=Join-Path $GameDirectory $relative
    if(-not(Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -eq 0){throw "Overlord VR is incomplete: $relative. Choose Reinstall in the Hub."}
}
if(-not((Test-Path -LiteralPath (Join-Path $GameDirectory 'oo2core_5_win64.dll') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $GameDirectory 'oo2core_8_win64.dll') -PathType Leaf)) -or -not(Test-Path -LiteralPath (Join-Path $GameDirectory 'Data\data') -PathType Container)){
    throw 'The Battle.net game data is incomplete. Repair the game in Battle.net before starting VR.'
}
$launcher=Join-Path $GameDirectory 'overlord.exe'
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MW2_TEST_LAUNCH_CAPTURE){
    [pscustomobject]@{File=$launcher;WorkingDirectory=$GameDirectory;Arguments=''}|ConvertTo-Json -Compress|Set-Content -LiteralPath $env:PCVR_MW2_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
Start-Process -FilePath $launcher -WorkingDirectory $GameDirectory -ErrorAction Stop|Out-Null

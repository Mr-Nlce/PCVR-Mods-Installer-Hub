param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
foreach($relative in @('CoJ.exe','d3d9.dll','.cojvr-public-install.json','.cojvr-d3d9-stage.json','.pcvrhub_version')){
    if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $relative) -PathType Leaf)){
        throw "Call of Juarez VR is incomplete: $relative. Use Reinstall in the Hub."
    }
}
$version=(Get-Content -LiteralPath (Join-Path $GameDirectory '.pcvrhub_version') -Raw).Trim()
if($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$'){throw 'The installed CoJ VR version is not trackable. Reinstall from the Hub.'}
$cache=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_CACHE){Join-Path $env:PCVR_COJ_TEST_CACHE $version}else{Join-Path $env:LOCALAPPDATA ("PCVR Mods Installer Hub\PublisherCache\CallOfJuarezVR\$version")}
$script=Join-Path $cache 'cojvr.ps1'
if(-not(Test-Path -LiteralPath $script -PathType Leaf)){throw 'The publisher session tool is missing. Use Reinstall in the Hub.'}
if(Get-Process -Name CoJ -ErrorAction SilentlyContinue){throw 'Close Call of Juarez before preparing a new VR session.'}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_LAUNCH_CAPTURE){
    [pscustomobject]@{PublisherScript=$script;Action='PrepareSession';GameDirectory=$GameDirectory;Launch=(Join-Path $GameDirectory 'CoJ.exe')}|ConvertTo-Json -Compress|Set-Content -LiteralPath $env:PCVR_COJ_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
$args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$script+'"'),'-Action','PrepareSession','-GameDirectory',('"'+$GameDirectory+'"'))
$p=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -ErrorAction Stop
if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "VR session preparation failed (exit $($p.ExitCode)). Start SteamVR and retry."}
Start-Process -FilePath (Join-Path $GameDirectory 'CoJ.exe') -WorkingDirectory $GameDirectory -ErrorAction Stop|Out-Null

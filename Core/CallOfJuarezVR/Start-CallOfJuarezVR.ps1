param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
foreach($relative in @('CoJ.exe','d3d9.dll','.cojvr-public-install.json','.cojvr-d3d9-stage.json')){
    if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $relative) -PathType Leaf)){
        throw "Call of Juarez VR is incomplete: $relative. Use Reinstall in the Hub."
    }
}
$versionFile=Join-Path $GameDirectory '.pcvrhub_version'
$external=-not(Test-Path -LiteralPath $versionFile -PathType Leaf)
if($external){
    $installed=Get-Content -LiteralPath (Join-Path $GameDirectory '.cojvr-public-install.json') -Raw|ConvertFrom-Json
    if($installed.manifestType -ne 'cojvr-public-install' -or $installed.phase -ne 'installed'){throw 'The publisher has not completed this VR installation. Choose the complete installed game folder.'}
    $version=[string]$installed.version
}else{$version=(Get-Content -LiteralPath $versionFile -Raw).Trim()}
if($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$'){throw 'The installed CoJ VR version is not trackable. Reinstall from the Hub.'}
$cache=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_CACHE){Join-Path $env:PCVR_COJ_TEST_CACHE $version}else{Join-Path $env:LOCALAPPDATA ("PCVR Mods Installer Hub\PublisherCache\CallOfJuarezVR\$version")}
$script=Join-Path $cache 'cojvr.ps1'
if(-not(Test-Path -LiteralPath $script -PathType Leaf)){
    $localScript=Join-Path $GameDirectory 'cojvr.ps1'
    if(Test-Path -LiteralPath $localScript -PathType Leaf){$script=$localScript}
    elseif($external){
        # The publisher's installed proxy supports ordinary CoJ.exe launch.
        # Without its optional retained tool, preserve the existing session;
        # do not require a Hub cache or install just to generate a new report ID.
        if(Get-Process -Name CoJ -ErrorAction SilentlyContinue){throw 'Close Call of Juarez before starting another copy.'}
        $exe=Join-Path $GameDirectory 'CoJ.exe'
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_LAUNCH_CAPTURE){[pscustomobject]@{Launch=$exe;Action='NativeInstalledSession';WorkingDirectory=$GameDirectory}|ConvertTo-Json|Set-Content -LiteralPath $env:PCVR_COJ_TEST_LAUNCH_CAPTURE;exit 0}
        Start-Process -FilePath $exe -WorkingDirectory $GameDirectory -ErrorAction Stop|Out-Null
        return
    }else{throw 'The publisher session tool is missing. Choose its retained publisher starter through Locate Game, or repair this Hub installation.'}
}
if(Get-Process -Name CoJ -ErrorAction SilentlyContinue){throw 'Close Call of Juarez before preparing a new VR session.'}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_LAUNCH_CAPTURE){
    [pscustomobject]@{PublisherScript=$script;Action='PrepareSession';GameDirectory=$GameDirectory;Launch=(Join-Path $GameDirectory 'CoJ.exe')}|ConvertTo-Json -Compress|Set-Content -LiteralPath $env:PCVR_COJ_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
$args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$script+'"'),'-Action','PrepareSession','-GameDirectory',('"'+$GameDirectory+'"'))
$p=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -ErrorAction Stop
if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "VR session preparation failed (exit $($p.ExitCode)). Start SteamVR and retry."}
Start-Process -FilePath (Join-Path $GameDirectory 'CoJ.exe') -WorkingDirectory $GameDirectory -ErrorAction Stop|Out-Null

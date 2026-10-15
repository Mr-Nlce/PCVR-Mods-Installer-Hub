param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'RogueTraderVR-Mode.ps1')
$env:PCVR_ROGUE_LIBRARY_ONLY='1'
. (Join-Path $PSScriptRoot 'RogueTraderVR-Maqueta-core.ps1')
try {
    $profile=Get-RogueTraderProfileRoot
    $installed=Join-Path $profile 'RTMaquetaXR\portable-install.json'
    if(-not(Test-Path -LiteralPath $installed -PathType Leaf)){throw 'No publisher ownership receipt was found. No files were removed.'}
    if(Get-Process -Name WH40KRT -ErrorAction SilentlyContinue){throw 'Close Rogue Trader before uninstalling.'}
    if(-not $HubConfirmed){
        Write-Host 'This removes only W40KRT_VR using its matching publisher uninstaller.' -ForegroundColor Yellow
        Write-Host 'RTVR, user settings, logs and saves remain.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to continue, or close this window to cancel...')
    }
    $cache=Join-Path (Split-Path -Parent $profile) 'W40KRT_VR-package.zip'
    if(-not(Test-Path -LiteralPath $cache -PathType Leaf)){throw "The matching publisher archive is missing: $cache. Download the installed release and run its UNINSTALL.cmd."}
    $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_rogue_remove_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
    try {
        $package=Get-RogueMaquetaPackage -Archive $cache -Work $work
        $receipt=Get-Content -LiteralPath $installed -Raw | ConvertFrom-Json
        if([string]$receipt.Version -ne $package.Version){throw 'The saved publisher package does not match the installed release. No files were removed.'}
        $exe=(Get-Command powershell.exe -ErrorAction Stop).Source
        $args='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $package.Root 'scripts\Uninstall.ps1') + '"'
        $process=Start-Process -FilePath $exe -ArgumentList $args -Wait -PassThru -NoNewWindow
        if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher uninstaller failed (exit code $($process.ExitCode))."}
        if(Test-Path -LiteralPath (Join-Path $profile 'RTMaquetaXR\RTMaquetaXR.dll') -PathType Leaf){throw 'The mod DLL is still present after publisher uninstall. Hub status was not cleared.'}
        $params=Join-Path $profile 'Params.xml'
        if(Test-Path -LiteralPath $params -PathType Leaf){
            $xml=New-Object Xml.XmlDocument;$xml.XmlResolver=$null;$xml.Load($params)
            $node=$xml.SelectSingleNode("/Param/ModParams/Mod[@Id='RTMaquetaXR']")
            if($node){$node.SetAttribute('Enabled','false');$tmp=$params+'.pcvrhub.tmp';try{$xml.Save($tmp);Move-Item -LiteralPath $tmp -Destination $params -Force}finally{if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force}}}
        }
        $record=Join-Path $PSScriptRoot '.installed_path_maqueta'
        $game=if(Test-Path -LiteralPath $record){(''+(Get-Content -LiteralPath $record -Raw)).Trim()}else{''}
        if($game -and (Test-Path -LiteralPath (Join-Path $game 'WH40KRT.exe') -PathType Leaf)){
            foreach($name in @('.pcvrhub_rogue_maqueta_version','.pcvrhub_version_b')){
                $path=Join-Path $game $name;if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}
            }
        }
        if(Test-Path -LiteralPath $record){Remove-Item -LiteralPath $record -Force}
        Write-Host 'W40KRT_VR removed. RTVR and other Owlcat mods were kept.' -ForegroundColor Green
    } finally {if(Test-Path -LiteralPath $work){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
} catch {Write-Host ('Uninstall stopped: '+$_.Exception.Message) -ForegroundColor Red;if($NoPause){exit 1}}
if(-not $NoPause){Read-Host 'Press Enter to close'|Out-Null}

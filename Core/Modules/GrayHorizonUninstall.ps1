function Invoke-GrayHorizonUninstall([int]$Number,[string]$InstallerFolder,[switch]$HubConfirmed) {
    $ErrorActionPreference='Stop'
    . (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
    . (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
    $id="forza-horizon-$Number-grayhorizon-vr";$identity="grayhorizonfh$Number"
    $game=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_GH_TEST_GAME}else{Get-PCVRRememberedGameFolder -GameId $id -StateNames @('installed_path','user_located') -ProbeFiles @("ForzaHorizon$Number.exe")}
    if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game ".pcvrhub_$($identity)_ownership.csv") -PathType Leaf)){throw 'No Hub-owned GrayHorizon installation was found.'}
    if(Get-Process -Name "ForzaHorizon$Number" -ErrorAction SilentlyContinue){throw 'Close the game before removing GrayHorizon.'}
    if(-not $HubConfirmed -and (Read-Host 'Remove GrayHorizon? Type REMOVE') -cne 'REMOVE'){return}
    $desktop=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_TEST_REPORT_DIR}else{[Environment]::GetFolderPath('DesktopDirectory')}
    $gameLink=Join-Path $game 'Start GrayHorizon VR.lnk';$removeDesktop=$false
    $store=if($game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){'Steam'}else{'Xbox'}
    $link=Join-Path $desktop "Forza Horizon $Number - GrayHorizon VR ($store).lnk"
    if((Test-Path -LiteralPath $link -PathType Leaf) -and (Test-Path -LiteralPath $gameLink -PathType Leaf)){
        $shell=New-Object -ComObject WScript.Shell
        try{
            $a=$shell.CreateShortcut($link);$b=$shell.CreateShortcut($gameLink)
            $removeDesktop=($a.TargetPath -eq $b.TargetPath -and $a.Arguments -eq $b.Arguments -and $a.WorkingDirectory -eq $game)
        }finally{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)}
    }
    $versionPath=Join-Path $game '.pcvrhub_grayhorizon_version'
    $version=if(Test-Path -LiteralPath $versionPath){([IO.File]::ReadAllText($versionPath)).Trim()}else{''}
    $result=Uninstall-OwnedModPayload -GameRoot $game -Identity $identity
    if($removeDesktop -and -not(Test-Path -LiteralPath $gameLink)){Remove-Item -LiteralPath $link -Force}
    if(-not(Test-Path -LiteralPath (Join-Path $game 'GrayHorizon Settings.exe')) -or -not(Test-Path -LiteralPath $gameLink)){
        foreach($p in @($versionPath,(Join-Path $InstallerFolder '.installed_path'))){if(Test-Path -LiteralPath $p){Remove-Item -LiteralPath $p -Force}}
        $generic=Join-Path $game '.pcvrhub_version'
        if($version -and (Test-Path -LiteralPath $generic) -and ([IO.File]::ReadAllText($generic)).Trim() -eq $version){Remove-Item -LiteralPath $generic -Force}
    }
    Write-Host "  [OK] Removed $($result.Removed) GrayHorizon files; restored $($result.Restored) earlier files." -ForegroundColor Green
    Write-Host '  Saves, changed files, custom configuration, HUD/seat layouts and Documents\GrayHorizon remain.' -ForegroundColor White
}


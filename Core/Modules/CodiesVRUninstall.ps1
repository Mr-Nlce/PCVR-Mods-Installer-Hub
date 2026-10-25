function Invoke-CodiesVRUninstall([string]$Key,[string]$InstallerFolder,[switch]$HubConfirmed) {
    $ErrorActionPreference='Stop'
    . (Join-Path $PSScriptRoot 'CodiesVRInstaller.ps1')
    $p=Get-CodiesVRProfile $Key
    $root=if($env:PCVR_HUB_TEST_MODE -eq '1'){Assert-CodiesVRFixture $env:PCVR_CODIES_TEST_GAME}else{Get-PCVRRememberedGameFolder -GameId $p.Id -StateNames @('installed_path','base_game_path','user_located') -ProbeFiles @($p.Exe)}
    $manifest=".pcvrhub_$($p.Identity)_ownership.csv";$versionFile=".pcvrhub_$($p.Identity)_version"
    if(-not $root -or -not(Test-Path -LiteralPath (Join-Path $root $manifest) -PathType Leaf)){throw 'No Hub-owned CodiesVR installation was found. Locate the game folder first.'}
    $processNames=@([IO.Path]::GetFileNameWithoutExtension($p.Exe));if($Key -eq 'Grid2019'){$processNames+='Grid'}
    if(Get-Process -Name $processNames -ErrorAction SilentlyContinue){throw 'Close the game before removing CodiesVR.'}
    if(-not $HubConfirmed -and (Read-Host ('Remove '+$p.Title+'? Type REMOVE')) -cne 'REMOVE'){return}
    $versionPath=Join-Path $root $versionFile
    $version=if(Test-Path -LiteralPath $versionPath){[IO.File]::ReadAllText($versionPath).Trim()}else{''}
    $result=Uninstall-OwnedModPayload -GameRoot $root -Identity $p.Identity
    if(-not(Test-Path -LiteralPath (Join-Path $root $manifest))){
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_CODIES_TEST_RECEIPT}else{Join-Path $InstallerFolder '.installed_path'}
        foreach($path in @($versionPath,$receipt)){if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){Remove-Item -LiteralPath $path -Force}}
        $generic=Join-Path $root '.pcvrhub_version'
        if($version -and (Test-Path -LiteralPath $generic) -and [IO.File]::ReadAllText($generic).Trim() -eq $version){Remove-Item -LiteralPath $generic -Force}
    }
    Write-Host "  [OK] Removed $($result.Removed) CodiesVR files; restored $($result.Restored) earlier files." -ForegroundColor Green
    Write-Host '  Saves, user-modified files, mod INIs, recenter data and Documents graphics settings/backups are preserved.' -ForegroundColor White
}

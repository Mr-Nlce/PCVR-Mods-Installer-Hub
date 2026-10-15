param([Parameter(Mandatory=$true)][ValidateSet('d1','d2')][string]$Key,[switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'DescentVRShared.ps1')

function Invoke-DescentUninstall([string]$SelectedKey){
    $d=Get-DescentDefinition $SelectedKey
    Write-Host "Remove $($d.Title) from its own VR folder." -ForegroundColor Cyan
    Write-Host 'The original game, pilots, saves, settings and the other Descent title stay in place.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message "Press Enter to remove only $($d.Title)...")
    $base=Find-DescentBase $d
    $installed=Get-DescentRuntime $d $(if($base){$base.Root}else{''})
    if(-not $installed){Write-Host '  No complete selected VR runtime was found.' -ForegroundColor Yellow;return}
    $root=$installed.Root
    $owned=Join-Path $root '.pcvrhub_descent_owned.json'
    if(-not(Test-Path -LiteralPath $owned -PathType Leaf)){throw 'No Hub ownership record exists for this game. Use the publisher Uninstall only if you want to remove both Descent titles.'}
    $hashes=Get-Content -LiteralPath $owned -Raw -ErrorAction Stop|ConvertFrom-Json
    $manifest=Join-Path $root 'install-manifest.txt'
    $files=@(Get-Content -LiteralPath $manifest -ErrorAction Stop|Where-Object{$_ -and -not $_.StartsWith('#')})
    foreach($relative in $files){[void](Resolve-DescentOwnedFile -Runtime $root -Relative $relative)}
    $removed=0;$kept=0
    foreach($relative in $files){
        $target=Resolve-DescentOwnedFile -Runtime $root -Relative $relative
        if(-not(Test-Path -LiteralPath $target -PathType Leaf)){continue}
        $expected=[string]$hashes.$relative
        if(-not $expected -or (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $expected){$kept++;continue}
        Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        $removed++
    }
    Remove-Item -LiteralPath $owned -Force -ErrorAction Stop
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_RECEIPT){
        $testReceipt=[IO.Path]::GetFullPath($env:PCVR_DESCENT_TEST_RECEIPT)
        [void](Assert-DescentTestPath (Split-Path -Parent $testReceipt))
        $testReceipt
    }else{Join-Path (Join-Path $script:DescentCore $d.Folder) '.installed_path'}
    if(Test-Path -LiteralPath $receipt -PathType Leaf){Remove-Item -LiteralPath $receipt -Force}
    foreach($name in @('.pcvrhub_version')){
        $path=Join-Path $root $name
        if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}
    }
    $shortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) $d.Shortcut
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_DESKTOP){$shortcut=Join-Path (Assert-DescentTestPath $env:PCVR_DESCENT_TEST_DESKTOP) $d.Shortcut}
    if(Test-Path -LiteralPath $shortcut -PathType Leaf){
        try{$link=(New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
            if($link.TargetPath -ieq (Join-Path $root ('game\'+$d.Engine))){Remove-Item -LiteralPath $shortcut -Force}
        }catch{}
    }
    foreach($folder in @('game','tools')){
        $child=Join-Path $root $folder
        if((Test-Path -LiteralPath $child -PathType Container) -and -not(Get-ChildItem -LiteralPath $child -Force|Select-Object -First 1)){Remove-Item -LiteralPath $child -Force}
    }
    if((Test-Path -LiteralPath $root -PathType Container) -and -not(Get-ChildItem -LiteralPath $root -Force|Select-Object -First 1)){Remove-Item -LiteralPath $root -Force}
    Write-Host "  Removed $removed unchanged publisher files; preserved $kept modified files." -ForegroundColor Green
    Write-Host '  Original game and the other Descent VR installation were not touched.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close...')
}

try{Invoke-DescentUninstall $Key}catch{Write-Host "Descent removal stopped: $($_.Exception.Message)" -ForegroundColor Red;throw}

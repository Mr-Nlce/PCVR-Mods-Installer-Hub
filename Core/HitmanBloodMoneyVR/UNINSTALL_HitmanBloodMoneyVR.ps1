param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$publisherRoot=Join-Path $env:LOCALAPPDATA 'BloodMoneyVR'
$previousHubRoot=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\BloodMoneyVR'
$root=$null
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HBM_TEST_RUNTIME){$root=$env:PCVR_HBM_TEST_RUNTIME}
else{
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    $candidates=@()
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        $recorded=([string](Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop)).Trim()
        if($recorded -and @($publisherRoot,$previousHubRoot) -contains $recorded){$candidates+=$recorded}
    }
    $candidates+=@($publisherRoot,$previousHubRoot)
    foreach($candidate in @($candidates|Select-Object -Unique)){
        if((Test-Path -LiteralPath (Join-Path $candidate 'BloodMoneyVR.exe') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $candidate 'unins000.exe') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $candidate '.pcvrhub_version') -PathType Leaf)){$root=$candidate;break}
    }
}
if(-not $root){throw 'No complete Hub-installed Blood Money VR runtime was found.'}
if(-not(Test-Path -LiteralPath (Join-Path $root 'BloodMoneyVR.exe') -PathType Leaf)){throw 'No Blood Money VR launcher was found.'}
if(-not(Test-Path -LiteralPath (Join-Path $root 'unins000.exe') -PathType Leaf)){throw 'Publisher uninstaller is missing; no files were changed.'}
if(Get-Process -Name 'BloodMoneyVR','HitmanBloodMoney' -ErrorAction SilentlyContinue){throw 'Close Blood Money and its VR launcher first.'}
if(-not $HubConfirmed -and (Read-Host "Run the publisher uninstaller in '$root'? Type REMOVE") -cne 'REMOVE'){exit 0}
$uninstaller=Join-Path $root 'unins000.exe'
$shortcutMarker=Join-Path $root '.pcvrhub_hbm_shortcut.json'
$ownedShortcut=$null
if(Test-Path -LiteralPath $shortcutMarker -PathType Leaf){$ownedShortcut=Get-Content -LiteralPath $shortcutMarker -Raw -Encoding UTF8|ConvertFrom-Json}
if($env:PCVR_HUB_TEST_MODE -eq '1'){
    foreach($name in @('BloodMoneyVR.exe','vr.ini','Collect-Diagnostics.cmd','unins000.exe')){Remove-Item -LiteralPath (Join-Path $root $name) -Force -ErrorAction SilentlyContinue}
}else{
    $proc=Start-Process -FilePath $uninstaller -WorkingDirectory $root -Wait -PassThru -ErrorAction Stop
    if($null -eq $proc.ExitCode -or $proc.ExitCode -ne 0){throw "Publisher uninstaller failed (exit $($proc.ExitCode))."}
}
if(Test-Path -LiteralPath (Join-Path $root 'BloodMoneyVR.exe') -PathType Leaf){throw 'Publisher uninstaller left the VR launcher present; receipt retained.'}
foreach($path in @((Join-Path $root '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
    if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}
}
$desktop=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HBM_TEST_DESKTOP){$env:PCVR_HBM_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
$link=Join-Path $desktop 'Hitman Blood Money VR.lnk'
if($ownedShortcut -and $ownedShortcut.Path -ieq $link -and (Test-Path -LiteralPath $link -PathType Leaf)){
    if((Get-FileHash -LiteralPath $link -Algorithm SHA256).Hash -eq $ownedShortcut.Hash){
        $shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut($link)
        if($shortcut.TargetPath -ieq (Join-Path $root 'BloodMoneyVR.exe')){Remove-Item -LiteralPath $link -Force}
    }
}
$icon=Join-Path $root 'HitmanBloodMoneyVR.ico'
if($ownedShortcut -and $ownedShortcut.IconPath -ieq $icon -and (Test-Path -LiteralPath $icon -PathType Leaf)){
    if((Get-FileHash -LiteralPath $icon -Algorithm SHA256).Hash -eq $ownedShortcut.IconHash){Remove-Item -LiteralPath $icon -Force}
}
$legacy=Join-Path $desktop 'Blood Money VR (Hub).lnk'
if(Test-Path -LiteralPath $legacy -PathType Leaf){
    $shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut($legacy)
    if($shortcut.TargetPath -ieq (Join-Path $root 'BloodMoneyVR.exe') -and -not $shortcut.Arguments){Remove-Item -LiteralPath $legacy -Force}
}
if(Test-Path -LiteralPath $shortcutMarker -PathType Leaf){Remove-Item -LiteralPath $shortcutMarker -Force}
Write-Host '  [OK] Publisher VR runtime removed. The base game and personal files remain.' -ForegroundColor Green

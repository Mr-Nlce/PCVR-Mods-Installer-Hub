param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
$env:PCVR_XIII_LIBRARY_ONLY='1'
. (Join-Path $PSScriptRoot 'XIIIVR-core.ps1')
function Finish-XIII([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
if(-not(Test-XIIIBase $GameRoot)){
    try{$candidate=([IO.File]::ReadAllText((Get-XIIIReceiptPath))).Trim();if(Test-XIIIBase $candidate){$GameRoot=$candidate}}catch{}
}
if(-not(Test-XIIIBase $GameRoot)){Write-Host '  No XIII Remake game folder was found.' -ForegroundColor Yellow;Finish-XIII 0}
if(-not(Get-XIIIJournal $GameRoot)){Write-Host '  No installed XIII VR publisher restore point was found.' -ForegroundColor Yellow;Finish-XIII 0}
if(Get-Process -Name 'XIII' -ErrorAction SilentlyContinue){Write-Host '  Close XIII before restoring it.' -ForegroundColor Red;Finish-XIII 1}
if(-not $HubConfirmed){$answer=([string](Read-Host "Restore XIII in '$GameRoot' to its pre-VR files? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-XIII 0}}
$scriptPath=Join-Path (Get-XIIICacheRoot) 'Install-XIII-VR.ps1'
if(-not(Test-Path -LiteralPath $scriptPath -PathType Leaf)){$scriptPath=Join-Path $PSScriptRoot 'Publisher-Install-XIII-VR.ps1'}
if(-not(Test-Path -LiteralPath $scriptPath -PathType Leaf)){throw 'Publisher restore script is unavailable. Re-run the Hub installer or restore from the official ZIP.'}
$count=0
while($point=Get-XIIIJournal $GameRoot){
    if($count -ge 20){throw 'Too many XIII VR restore layers. Review XIII-VR-backups manually.'}
    Write-Host "  [..] Restoring publisher layer $($count+1); this may take several seconds." -ForegroundColor Cyan
    Invoke-XIIIPublisher -Script $scriptPath -Game $GameRoot -Uninstall
    $after=Get-Content -LiteralPath $point.Path -Raw | ConvertFrom-Json
    if($after.status -eq 'installed'){throw 'Publisher restore did not complete; the Hub kept its installed markers.'}
    $count++
}
$plugin=Join-Path $GameRoot 'BepInEx\plugins\XIII.XRBootstrap.dll'
if(Test-Path -LiteralPath $plugin -PathType Leaf){
    Write-Host '  A changed XIII VR plugin was preserved. Review it before removing it manually.' -ForegroundColor Yellow
}else{
    foreach($path in @((Join-Path $GameRoot '.pcvrhub_version'),(Get-XIIIReceiptPath))){
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  [OK] Publisher restore completed for $count layer(s). Original files and saves were kept." -ForegroundColor Green
Finish-XIII 0

param([string]$GameDirectory,[ValidateSet('main','fork')][string]$Mod='main',[switch]$PlanOnly)
$ErrorActionPreference='Stop'
try{
    $helpers=if(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')){$PSScriptRoot}else{Join-Path $PSScriptRoot '..\Modules'}
    . (Join-Path $helpers 'OwnedModFiles.ps1')
    . (Join-Path $helpers 'PublisherZipTransaction.ps1')
    . (Join-Path $helpers 'GameInstallProof.ps1')
    . (Join-Path $PSScriptRoot 'RDRVR-Profiles.ps1')
    if(-not $GameDirectory){throw 'Locate the Red Dead Redemption game folder first.'}
    $game=[IO.Path]::GetFullPath($GameDirectory).TrimEnd('\')
    if(-not(Test-PCVRGameInstallProof -GameId 'red-dead-redemption-vr' -Root $game)){throw 'The original Red Dead Redemption game files are incomplete. Locate the complete game installation.'}
    if(-not(Test-RdrProfilePresence $game $Mod)){throw 'The selected RDRVR mod is incomplete. Use its install / update action to repair it.'}
    $target=if($game -match '(?i)[\\/]steamapps[\\/]common[\\/]'){'steam://rungameid/2668510'}else{Join-Path $game 'RDR.exe'}
    if($PlanOnly){@{Mod=$Mod;File=$target;Directory=$game}|ConvertTo-Json -Compress;exit 0}
    Set-RdrActive -Game $game -Mod $Mod
    Start-Process -FilePath $target -WorkingDirectory $game -ErrorAction Stop
}catch{
    $message='Red Dead Redemption VR could not start: '+$_.Exception.Message
    if($PlanOnly -or $env:PCVR_HUB_TEST_MODE -eq '1'){throw $message}
    Add-Type -AssemblyName PresentationFramework
    [void][Windows.MessageBox]::Show($message,'Red Dead Redemption VR','OK','Error')
    exit 1
}

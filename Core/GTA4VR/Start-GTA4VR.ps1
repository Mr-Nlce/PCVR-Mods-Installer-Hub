param([string]$GameDirectory,[string]$RuntimeRoot,[ValidateSet('bordplate','gamepad')][string]$Mod='bordplate',[switch]$PlanOnly)
$ErrorActionPreference='Stop'
try{
    $helpers=if(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'GTA4VRProfiles.ps1')){$PSScriptRoot}else{Join-Path $PSScriptRoot '..\Modules'}
    foreach($name in @('OwnedModFiles.ps1','PublisherZipTransaction.ps1','GTA4VRProfiles.ps1')){. (Join-Path $helpers $name)}
    if(-not $GameDirectory){$GameDirectory=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))}
    $game=Get-GTA4Root $GameDirectory
    if(-not [IO.File]::Exists((Join-Path $game 'pc\models\cdimages\vehicles.img'))){throw 'The original GTA IV game data is missing from this folder. Locate the complete game installation.'}
    $store=Join-Path $game ('_vrmods\'+$Mod)
    $managed=$false;try{Assert-GTA4Payload $store $Mod;$managed=$true}catch{}
    if($managed){Assert-GTA4Payload $store $Mod}else{
        if(-not(Test-GTA4ProfilePresence $game $Mod)){throw 'The selected GTA IV VR runtime is incomplete or mixed with another mod. Locate the working installation or repair the selected profile.'}
        Assert-GTA4Payload $game $Mod -AllowParked
        if($Mod -eq 'bordplate' -and -not(Test-Path -LiteralPath (Join-Path $game 'GTA4VR-notices\readme.md'))){throw 'The installed FusionFix is not proven to be bordplate GTA4VR. Locate the VR installation or install the selected mod.'}
    }
    $plan=Get-GTA4LaunchPlan $game
    $mode=Join-Path $game '_vrmods\mode.ini'
    $flat=[IO.File]::Exists($mode) -and [IO.File]::ReadAllText($mode) -match '(?im)^\s*Mode\s*=\s*Flat\s*$'
    if($PlanOnly){return [pscustomobject]@{Mod=$Mod;File=$plan.File;Directory=$plan.Directory;Flat=$flat}}
    if(-not $flat -and $Mod -eq 'bordplate'){
        $runtime=Get-GTA4OpenXRReadiness
        if(-not $runtime.Ready){throw ('GTA4VR requires SteamVR as the active 32-bit OpenXR runtime. Open SteamVR > Settings > OpenXR > Set SteamVR as OpenXR Runtime, then retry Start in VR. Windows currently reports: '+$runtime.Manifest)}
    }
    if(-not $managed){
        if(Get-Process -Name GTAIV,PlayGTAIV,LaunchGTAIV -ErrorAction SilentlyContinue){throw 'Close GTA IV and its launcher before changing VR modes.'}
        Import-GTA4Gamepad $game
        Import-GTA4Native $game
        Assert-GTA4Payload $store $Mod
        # Import preserves an old parked install for installer updates. A
        # launch keeps the mode that was selected before that migration.
        if(-not $flat){[IO.File]::WriteAllText($mode,"[Hub]`r`nMode=VR`r`n")}
        $managed=$true
    }
    if($managed){Set-GTA4Active -Game $game -Mod $(if($flat){'flat'}else{$Mod})}
    if(-not $flat -and $Mod -eq 'bordplate'){Set-GTA4OpenVRBootstrap -Game $game -Bootstrap $runtime.Bootstrap}
    if($plan.File -like 'steam:*'){Start-Process -FilePath $plan.File}else{Start-Process -FilePath $plan.File -WorkingDirectory $plan.Directory}
}catch{
    if($PlanOnly){throw}
    Add-Type -AssemblyName PresentationFramework
    [void][Windows.MessageBox]::Show($_.Exception.Message,'GTA IV VR','OK','Error')
    exit 1
}

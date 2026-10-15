param([Alias('InstallerChoice')][ValidateSet('','maqueta','rtvr')][string]$Mod='')
$ErrorActionPreference='Stop'
$previousChoiceConfirmation = $env:PCVR_ROGUE_CHOICE_CONFIRMED
$choiceConfirmedHere = $false
if (-not $Mod) {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' Warhammer 40K: Rogue Trader VR - Installer' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
    Write-Host ' Choose the VR mod to install or update:' -ForegroundColor White
    Write-Host ' [1] W40KRT_VR - tabletop and motion controllers' -ForegroundColor Green
    Write-Host '     Steam build checked by publisher; DirectX 11 and OpenXR required.' -ForegroundColor Gray
    Write-Host ' [2] RTVR - seated gamepad or keyboard and mouse' -ForegroundColor White
    Write-Host '     Nexus login and manual downloads required.' -ForegroundColor Gray
    Write-Host ''
    Write-Host ' Close the game first. Both mods can remain installed; the chosen' -ForegroundColor Yellow
    Write-Host ' Play button activates only its own mod before each launch.' -ForegroundColor Yellow
    Write-Host ' Option [1] can change Maqueta settings after the publisher asks' -ForegroundColor Yellow
    Write-Host ' for a backup and reset; RTVR is disabled while Tabletop runs.' -ForegroundColor Yellow
    . (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
    Show-AntivirusNotice -Compact
    Write-Host ' Your selection confirms these notes and starts that installer.' -ForegroundColor Cyan
    while (-not $Mod) {
        $choice=(''+(Read-Host 'Choose 1, 2 or Q')).Trim().ToLowerInvariant()
        if ($choice -eq '1') { $Mod='maqueta'; break }
        if ($choice -eq '2') { $Mod='rtvr'; break }
        if ($choice -in @('q','quit','exit')) { exit 0 }
        Write-Host ' Choose [1], [2], or [Q].' -ForegroundColor Yellow
    }
    $env:PCVR_ROGUE_CHOICE_CONFIRMED='1'
    $choiceConfirmedHere = $true
}
try {
    if ($Mod -eq 'maqueta') { & (Join-Path $PSScriptRoot 'RogueTraderVR-Maqueta-core.ps1') }
    else { & (Join-Path $PSScriptRoot 'RogueTraderVR-core.ps1') }
} finally {
    if ($choiceConfirmedHere) { $env:PCVR_ROGUE_CHOICE_CONFIRMED = $previousChoiceConfirmation }
}


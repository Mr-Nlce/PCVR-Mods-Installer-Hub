# ============================================================
# Hexen VR - GZDoomVR Installer
# ============================================================
# Thin wrapper. All real logic lives in the shared engine
# installer at QuestZDoomShared\QuestZDoomShared.ps1 - this
# script just calls Install-QuestZDoomGame with the per-game
# parameters.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Hexen VR Installer"

# Resolve sibling shared library. This script lives at:
# <Hub>\Core\HexenVR\HexenVR-core.ps1
# the shared lib lives at:
# <Hub>\Core\QuestZDoomShared\QuestZDoomShared.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sharedLib = Join-Path (Split-Path $scriptDir -Parent) "QuestZDoomShared\QuestZDoomShared.ps1"

if (-not (Test-Path $sharedLib)) {
 Write-Host "ERROR: Shared library missing at $sharedLib" -ForegroundColor Red
 Write-Host "Reinstall the Hub - the QuestZDoomShared folder is required." -ForegroundColor Yellow
 Read-Host "Press Enter to exit"
 exit 1
}

. $sharedLib

Install-QuestZDoomGame `
 -GameTitle "Hexen VR" `
 -WadName "HEXEN.WAD" `
 -SteamFolders @("Hexen Beyond Heretic", "Heretic + Hexen", "Heretic Hexen", "Hexen") `
 -BatLabel "Start Hexen VR.bat" `
 -Flavor "Fighter, Cleric, Mage. Korax falls, or you do." -IconFile "Hexen_VR.ico"

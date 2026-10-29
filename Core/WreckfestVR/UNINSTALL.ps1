param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
Invoke-NewGameVRUninstall -Key 'Wreckfest' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed

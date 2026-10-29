param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
Invoke-PublisherVRUninstall -Key 'AmongSleep' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
Write-Host '';Write-Host '  Teddy said he would keep you safe. He did not mention bedtime overtime.' -ForegroundColor Magenta
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')

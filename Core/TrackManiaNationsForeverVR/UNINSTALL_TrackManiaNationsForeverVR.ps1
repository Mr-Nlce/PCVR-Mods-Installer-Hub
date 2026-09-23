param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
& (Join-Path $PSScriptRoot '..\TrackManiaForeverVRShared\Uninstall-TMFOXR-shared.ps1') -Edition Nations -GameRoot $GameRoot -HubConfirmed:$HubConfirmed -NoPause:$NoPause

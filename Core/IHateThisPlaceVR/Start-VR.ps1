param([string]$RuntimeRoot)
$ErrorActionPreference='Stop'
if(-not $RuntimeRoot){throw 'The Hub must supply the installed game folder.'}
& (Join-Path $PSScriptRoot '..\Modules\KingEJUnityVRLaunch.ps1') -RuntimeRoot $RuntimeRoot -ConfigName 'IHateThisPlace-launch.json'

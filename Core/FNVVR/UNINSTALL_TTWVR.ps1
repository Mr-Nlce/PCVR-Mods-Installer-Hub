param([Alias('GameRoot')][string]$GameDir,[switch]$HubConfirmed,[switch]$NoPause)
& (Join-Path $PSScriptRoot '..\TTWVR\UNINSTALL_TTWVR.ps1') -GameDir $GameDir -HubConfirmed:$HubConfirmed

# Detached cache warmer. Use the same typed catalogue, channel, asset selection,
# publication policy and cache keys as the PowerShell Hub scan. No UI or game
# state is changed. The bounded rotating prewarm leaves stale sources for the
# ordinary scan worker instead of keeping a startup process alive indefinitely.
$ErrorActionPreference='SilentlyContinue'
$ProgressPreference='SilentlyContinue'
try {
    $script:scriptDir=$PSScriptRoot
    $global:scriptDir=$PSScriptRoot
    . (Join-Path $PSScriptRoot 'Modules\HubState.ps1')
    if(-not (Get-HubVersionCacheRoot)){return}
    . (Join-Path $PSScriptRoot 'Modules\Helpers.ps1')
    . (Join-Path $PSScriptRoot 'Modules\Filter.ScanSources.ps1')
    . (Join-Path $PSScriptRoot 'Modules\Catalog.ps1')
    $global:allGameData=@($ownGames)+@($ownGamesGP)+@($externalGames)
    $global:PrewarmDeadline=[DateTime]::UtcNow.AddSeconds(60)
    Invoke-RotatingOnlinePrewarm
} catch { }
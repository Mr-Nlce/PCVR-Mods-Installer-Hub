# Stable-ID screenshots and offline Game Info supplement manual overrides.
# They do not change game identity, state, portrait/header priority or launch.
function Initialize-CatalogMedia {
    param([object[]]$Games,[object[]]$Sources)
    $byId=@{}
    foreach($source in $Sources){
        if($source.Id){$byId[[string]$source.Id]=$source}
    }
    foreach($game in $Games){
        if($byId.ContainsKey([string]$game.Id)){
            foreach($field in @('ScreenshotUrl','GameInfoText')){
                if(-not $game.$field -and $byId[[string]$game.Id].$field){$game.$field=[string]$byId[[string]$game.Id].$field}
            }
        }
    }
}
Initialize-CatalogMedia -Games (@($ownGames)+@($ownGamesGP)+@($externalGames)) -Sources @(Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'CatalogMedia.csv'))

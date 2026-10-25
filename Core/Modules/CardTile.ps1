# ============================================================
# CardTile.ps1 - ordered facade for split UI implementation
#
# Core, Lazy and Frosted are needed for the default style. Classic is loaded
# on first use, after the persisted style has been read by Window.
# ============================================================

# HUB-MODULE-PART: CardTile.Core.ps1
# HUB-MODULE-PART: CardTile.Lazy.ps1
# HUB-MODULE-PART: CardTile.Frosted.ps1
# HUB-MODULE-PART: CardTile.Classic.ps1

$__hubModuleParts = @(
    'CardTile.Core.ps1'
    'CardTile.Lazy.ps1'
    'CardTile.Frosted.ps1'
)
foreach ($__hubModulePart in $__hubModuleParts) {
    $__hubPartPath = Join-Path $PSScriptRoot $__hubModulePart
    if (Get-Command Get-HubModuleScript -ErrorAction SilentlyContinue) { . (Get-HubModuleScript $__hubPartPath) } else { . $__hubPartPath }
}
Remove-Variable __hubModulePart, __hubModuleParts, __hubPartPath -ErrorAction SilentlyContinue

$script:HubCardClassicPath = Join-Path $PSScriptRoot 'CardTile.Classic.ps1'
$global:HubCardClassicPath = $script:HubCardClassicPath

# Lazy cards (CardTile.Lazy.ps1): a placeholder now, the full card once it
# scrolls into view. PCVR_HUB_LAZY_CARDS=0 builds every card immediately.
function global:New-GameCard {
    param($game, $isExternal, $window)
    if ($global:HubLazyCards) { return (New-LazyGameCard -game $game -isExternal $isExternal) }
    if ($global:hubStyle -eq 'classic') {
        if (-not (Get-Command New-GameCardClassic -ErrorAction SilentlyContinue)) {
            . $script:HubCardClassicPath
        }
        return (New-GameCardClassic -game $game -isExternal $isExternal -window $window)
    }
    return (New-GameCardFrosted -game $game -isExternal $isExternal -window $window)
}

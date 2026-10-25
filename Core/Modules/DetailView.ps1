# ============================================================
# DetailView.ps1 - ordered facade for split UI implementation
#
# Keep this sequence intact: the parts preserve the exact former
# top-level execution order and share the caller script scope.
# ============================================================

# HUB-MODULE-PART: DetailView.Tiles.ps1
# HUB-MODULE-PART: DetailView.Power.ps1
# HUB-MODULE-PART: DetailView.Actions.ps1
# HUB-MODULE-PART: DetailView.Content.ps1
# HUB-MODULE-PART: DetailView.Launch.ps1
# HUB-MODULE-PART: DetailView.Page.ps1

$__hubModuleParts = @(
    'DetailView.Tiles.ps1'
    'DetailView.Power.ps1'
    'DetailView.Actions.ps1'
    'DetailView.Content.ps1'
    'DetailView.Launch.ps1'
    'DetailView.Page.ps1'
)
foreach ($__hubModulePart in $__hubModuleParts) {
    $__hubPartPath = Join-Path $PSScriptRoot $__hubModulePart
    if (Get-Command Get-HubModuleScript -ErrorAction SilentlyContinue) { . (Get-HubModuleScript $__hubPartPath) } else { . $__hubPartPath }
}
Remove-Variable __hubModulePart, __hubModuleParts, __hubPartPath -ErrorAction SilentlyContinue

# ============================================================
# Window.ps1 - ordered facade for split UI implementation
#
# Keep this sequence intact: the parts preserve the exact former
# top-level execution order and share the caller script scope.
# ============================================================

# HUB-MODULE-PART: Window.Layout.ps1
# HUB-MODULE-PART: Window.BannerEffects.ps1
# HUB-MODULE-PART: Window.Controls.ps1

$__hubModuleParts = @(
    'Window.Layout.ps1'
    'Window.BannerEffects.ps1'
    'Window.Controls.ps1'
)
foreach ($__hubModulePart in $__hubModuleParts) {
    Write-HubTiming ("Window before: {0}" -f $__hubModulePart)
    $__hubPartPath = Join-Path $PSScriptRoot $__hubModulePart
    if (Get-Command Get-HubModuleScript -ErrorAction SilentlyContinue) { . (Get-HubModuleScript $__hubPartPath) } else { . $__hubPartPath }
    Write-HubTiming ("Window after: {0}" -f $__hubModulePart)
}
Remove-Variable __hubModulePart, __hubModuleParts, __hubPartPath -ErrorAction SilentlyContinue

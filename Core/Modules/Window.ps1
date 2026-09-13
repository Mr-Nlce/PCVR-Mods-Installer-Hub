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
    . (Join-Path $PSScriptRoot $__hubModulePart)
    Write-HubTiming ("Window after: {0}" -f $__hubModulePart)
}
Remove-Variable __hubModulePart, __hubModuleParts -ErrorAction SilentlyContinue

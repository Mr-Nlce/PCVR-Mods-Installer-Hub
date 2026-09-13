# ============================================================
# CardTile.ps1 - ordered facade for split UI implementation
#
# Keep this sequence intact: the parts preserve the exact former
# top-level execution order and share the caller script scope.
# ============================================================

# HUB-MODULE-PART: CardTile.Core.ps1
# HUB-MODULE-PART: CardTile.Frosted.ps1
# HUB-MODULE-PART: CardTile.Classic.ps1

$__hubModuleParts = @(
    'CardTile.Core.ps1'
    'CardTile.Frosted.ps1'
    'CardTile.Classic.ps1'
)
foreach ($__hubModulePart in $__hubModuleParts) {
    . (Join-Path $PSScriptRoot $__hubModulePart)
}
Remove-Variable __hubModulePart, __hubModuleParts -ErrorAction SilentlyContinue

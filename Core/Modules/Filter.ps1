# ============================================================
# Filter.ps1 - ordered facade for split UI implementation
#
# Keep this sequence intact: the parts preserve the exact former
# top-level execution order and share the caller script scope.
# ============================================================

# HUB-MODULE-PART: Filter.Banners.ps1
# HUB-MODULE-PART: Filter.Controls.ps1
# HUB-MODULE-PART: Filter.Search.ps1
# HUB-MODULE-PART: Filter.ScanSources.ps1
# HUB-MODULE-PART: Filter.Scan.ps1
# HUB-MODULE-PART: Filter.InstallRefresh.ps1

$__hubModuleParts = @(
    'Filter.Banners.ps1'
    'Filter.Controls.ps1'
    'Filter.Search.ps1'
    'Filter.ScanSources.ps1'
    'Filter.Scan.ps1'
    'Filter.InstallRefresh.ps1'
)
foreach ($__hubModulePart in $__hubModuleParts) {
    . (Join-Path $PSScriptRoot $__hubModulePart)
}
Remove-Variable __hubModulePart, __hubModuleParts -ErrorAction SilentlyContinue

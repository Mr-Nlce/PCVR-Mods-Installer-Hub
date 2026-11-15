function Get-MEVRInstalledVersion {
    param([string]$GameRoot)
    try {
        $win64 = Join-Path $GameRoot 'Game\ME1\Binaries\Win64'
        $manifest = Get-Content -LiteralPath (Join-Path $win64 'ASI\MEVR-install.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $version = [string]$manifest.modVersion
        if ($version -notmatch '^v?[0-9]+(?:\.[0-9]+){2,3}$') { return }
        foreach ($relative in @('Game\ME1\Binaries\Win64','Game\Launcher')) {
            $bin = Join-Path $GameRoot $relative
            $proxy = Get-Item -LiteralPath (Join-Path $bin 'bink2w64.dll') -ErrorAction Stop
            if (-not [IO.File]::Exists((Join-Path $bin 'bink2w64_original.dll')) -or
                $proxy.VersionInfo.CompanyName -match 'RAD Game Tools' -or
                ($proxy.VersionInfo.ProductName -notmatch 'MEVR|LEBinkProxy' -and $proxy.VersionInfo.CompanyName -notmatch 'ME3Tweaks')) { return }
        }
        return $version.TrimStart('v')
    } catch { return }
}

# Prefetch-Versions.ps1
# Detached, silent cache warmer launched next to the Hub at startup.
#
# It ONLY fills the on-disk version caches (.gh_version_cache and
# .web_version_cache) that a later scan reads. It never opens a window,
# never touches a game card, and never marks anything as an update. A mod
# is shown as "Update" ONLY when the user runs a scan from the Hub - this
# script just makes that first scan fast by pre-warming the same 6h caches
# in the background while the Hub and splash are coming up.
#
# Safe by construction: every fetch is wrapped, entries still fresh (< 6h)
# are skipped, and any failure leaves the cache untouched. Worst case the
# first scan simply does the live check itself, exactly as before.

$ErrorActionPreference = "SilentlyContinue"
# This runs detached in the SAME console as the startup splash. Invoke-WebRequest
# would otherwise paint PowerShell's progress bar into that console and flicker
# over the splash, so silence it - we never need progress output here anyway.
$ProgressPreference = "SilentlyContinue"

try {
    $dir = $PSScriptRoot
    $catalog = Join-Path $dir "Modules\Catalog.ps1"
    if (-not (Test-Path $catalog)) { return }
    $text = Get-Content $catalog -Raw

    $ttlHours = 6
    $ua = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" }

    function Get-PfCache($file) {
        $h = @{}
        if (Test-Path $file) {
            try {
                $raw = Get-Content $file -Raw | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) { $h[$p.Name] = $p.Value }
            } catch {}
        }
        return $h
    }
    function Test-PfFresh($entry, $hrs) {
        if (-not $entry -or -not $entry.checked) { return $false }
        try {
            $age = ([DateTime]::UtcNow - [DateTime]::Parse([string]$entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            return ($age -lt $hrs)
        } catch { return $false }
    }
    function Set-PfCache($file, $hash) {
        try {
            $obj = @{}
            foreach ($k in $hash.Keys) { $obj[$k] = $hash[$k] }
            ($obj | ConvertTo-Json) | Set-Content -Path $file -Encoding UTF8 -Force
        } catch {}
    }

    # --- GitHub release tags (the GithubRepo mods) ---
    # Uses the github.com /releases/latest redirect (web, not the API), so it
    # is not bound by the 60/hour unauthenticated API limit. HEAD only.
    $ghFile  = Join-Path $dir ".gh_version_cache"
    $ghCache = Get-PfCache $ghFile
    $repos = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($text, 'GithubRepo\s*=\s*"([^"]+)"')) {
        $r = $m.Groups[1].Value.Trim()
        if ($r -and -not $repos.Contains($r)) { $repos.Add($r) }
    }
    $ghDirty = $false
    foreach ($repo in $repos) {
        if (Test-PfFresh $ghCache[$repo] $ttlHours) { continue }
        try {
            $resp = Invoke-WebRequest -Uri "https://github.com/$repo/releases/latest" -Method Head -UseBasicParsing -TimeoutSec 6 -Headers $ua -EA Stop
            $final = ""
            # Windows PowerShell 5.1 exposes the final URL as BaseResponse.ResponseUri;
            # PowerShell 7 has no such property and uses RequestMessage.RequestUri
            # instead. Reading only the 5.1 name made this fail silently on 7.
            try { $final = [string]$resp.BaseResponse.ResponseUri.AbsoluteUri } catch {}
            if (-not $final) { try { $final = [string]$resp.BaseResponse.RequestMessage.RequestUri.AbsoluteUri } catch {} }
            if (-not $final -and $resp.Headers.Location) { $final = [string]$resp.Headers.Location }
            if ($final -match '/releases/tag/([^/?#]+)') {
                $tag = [System.Uri]::UnescapeDataString($matches[1]).Trim()
                # !!! DO NOT WRITE SOURCE RELEASES INTO THE CACHE !!!
                # RaYRoD-TV published a release "hub-patch-2" containing
                # source ONLY on all of his VR ports - on StarFox64-VR
                # even as the official "latest". Filter.ps1 discards such
                # tags during the main scan - but it ACCEPTS a fresh cache
                # value BEFORE that filter applies.
                # So if the tag lands in the cache here, the tile reports
                # a nonexistent update. Hence the same filter here.
                if ($tag -and ($tag -match '(?i)source|hub-patch|sdk|symbols')) {
                    $tag = $null
                }
                if ($tag) {
                    $ghCache[$repo] = @{ tag = $tag; checked = ([DateTime]::UtcNow).ToString("o") }
                    $ghDirty = $true
                }
            }
        } catch {}
    }
    if ($ghDirty) { Set-PfCache $ghFile $ghCache }

    # --- Website versions (WebVersionUrl mods, e.g. Alien Isolation) ---
    $webFile  = Join-Path $dir ".web_version_cache"
    $webCache = Get-PfCache $webFile
    $urls = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($text, 'WebVersionUrl\s*=\s*"([^"]+)"')) {
        $u = $m.Groups[1].Value.Trim()
        if ($u -and -not $urls.Contains($u)) { $urls.Add($u) }
    }
    $webDirty = $false
    foreach ($url in $urls) {
        if (Test-PfFresh $webCache[$url] $ttlHours) { continue }
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -Headers $ua -EA Stop
            $html = [string]$resp.Content
            $ver = $null
            if     ($html -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { $ver = "v" + $matches[1] }
            elseif ($html -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { $ver = "v" + $matches[1] }
            elseif ($html -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { $ver = "v" + $matches[1] }
            if ($ver) {
                $webCache[$url] = @{ ver = $ver; checked = ([DateTime]::UtcNow).ToString("o") }
                $webDirty = $true
            }
        } catch {}
    }
    if ($webDirty) { Set-PfCache $webFile $webCache }
} catch {}

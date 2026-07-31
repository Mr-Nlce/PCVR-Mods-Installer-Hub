# ============================================================
# PrewarmWorker.ps1 - background online update-check worker
# ============================================================
# Launched by Invoke-CheckInstalledScan as a SEPARATE hidden
# PowerShell process when the foreground scan's ~4s online
# budget ran out before every repo/page was checked. This
# worker finishes the leftover checks with generous timeouts
# (nothing here can block the Hub UI - different process) and
# writes the results into the same on-disk version caches the
# Hub reads (.gh_version_cache / .web_version_cache). The next
# scan / Hub start picks them up from disk and paints the
# update badges.
#
# Self-contained BY DESIGN: no dot-sourcing of Hub modules (they
# carry UI top-level code), no WPF, no globals from the Hub. The
# ONLY contract with the Hub is:
#   - input:  <ScriptDir>\.prewarm_pending.json  (list of checks)
#   - output: merge-writes into the two cache JSON files
#   - lock:   <ScriptDir>\.prewarm_worker.lock   (single instance)
# Cache entry shapes MUST match Filter.ps1's getters exactly:
#   gh :  { "<repo>": { "tag": "<tag>", "checked": "<ISO-o>" } }
#   web:  { "<url>":  { "ver": "<ver>", "checked": "<ISO-o>" } }
# ============================================================
param(
    [Parameter(Mandatory = $true)][string]$ScriptDir
)

$ErrorActionPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$pendingFile = Join-Path $ScriptDir ".prewarm_pending.json"
$lockFile    = Join-Path $ScriptDir ".prewarm_worker.lock"
$ghCacheFile = Join-Path $ScriptDir ".gh_version_cache"
$webCacheFile= Join-Path $ScriptDir ".web_version_cache"

# Merge ONE entry into a cache JSON file: read the file fresh, update the
# key, write it back. Read-fresh-per-write keeps concurrent writes from the
# Hub process from being clobbered wholesale (worst case one key loses a
# race; the 6h TTL re-heals it on a later scan).
function Merge-CacheEntry {
    param([string]$File, [string]$Key, [hashtable]$Entry)
    $all = @{}
    if (Test-Path -LiteralPath $File) {
        try {
            $raw = Get-Content -LiteralPath $File -Raw | ConvertFrom-Json
            foreach ($p in $raw.PSObject.Properties) {
                $h = @{}
                foreach ($ip in $p.Value.PSObject.Properties) { $h[$ip.Name] = [string]$ip.Value }
                $all[$p.Name] = $h
            }
        } catch {}
    }
    $all[$Key] = $Entry
    try { ($all | ConvertTo-Json) | Set-Content -Path $File -Encoding UTF8 -Force } catch {}
}

function Get-GithubTagBackground {
    # Same source as the Hub's getter: the /releases/latest WEB redirect (not
    # the rate-limited API). HEAD only; the tag is in the final URL.
    param([string]$Repo)
    try {
        $resp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest" -Method Head -UseBasicParsing -TimeoutSec 15 -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop 2>$null
        $final = ""
        # Windows PowerShell 5.1 exposes the final URL as BaseResponse.ResponseUri;
        # PowerShell 7 has no such property and uses RequestMessage.RequestUri
        # instead. Reading only the 5.1 name made this fail silently on 7.
        try { $final = [string]$resp.BaseResponse.ResponseUri.AbsoluteUri } catch {}
        if (-not $final) { try { $final = [string]$resp.BaseResponse.RequestMessage.RequestUri.AbsoluteUri } catch {} }
        if (-not $final -and $resp.Headers.Location) { $final = [string]$resp.Headers.Location }
        if ($final -match '/releases/tag/([^/?#]+)') {
            return [System.Uri]::UnescapeDataString($matches[1]).Trim()
        }
    } catch {}
    return $null
}

function Get-WebVersionBackground {
    # Same three patterns, in the same order, as the Hub's getter - so the
    # background result is byte-identical to what a foreground check finds.
    param([string]$Url)
    try {
        $r = [System.Net.HttpWebRequest]::Create($Url)
        $r.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        $r.AllowAutoRedirect = $true
        $r.Timeout          = 15000
        $r.ReadWriteTimeout = 15000
        $resp = $r.GetResponse()
        try {
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            try { $html = $sr.ReadToEnd() } finally { $sr.Close() }
        } finally { $resp.Close() }
        if     ($html -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { return "v" + $matches[1] }
        elseif ($html -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { return "v" + $matches[1] }
        elseif ($html -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { return "v" + $matches[1] }
    } catch {}
    return $null
}

try {
    if (-not (Test-Path -LiteralPath $pendingFile)) { return }
    $items = @()
    try { $items = @(Get-Content -LiteralPath $pendingFile -Raw | ConvertFrom-Json) } catch { $items = @() }

    foreach ($it in $items) {
        try {
            $now = [DateTime]::UtcNow
            if ([string]$it.K -eq "gh") {
                $tag = Get-GithubTagBackground -Repo ([string]$it.A)
                if ($tag) {
                    Merge-CacheEntry -File $ghCacheFile -Key ([string]$it.A) -Entry @{ tag = $tag; checked = $now.ToString("o") }
                }
            } else {
                $ver = Get-WebVersionBackground -Url ([string]$it.A)
                if ($ver) {
                    Merge-CacheEntry -File $webCacheFile -Key ([string]$it.A) -Entry @{ ver = $ver; checked = $now.ToString("o") }
                }
            }
        } catch {}
    }
} finally {
    try { Remove-Item -LiteralPath $pendingFile -Force -EA SilentlyContinue } catch {}
    try { Remove-Item -LiteralPath $lockFile -Force -EA SilentlyContinue } catch {}
}

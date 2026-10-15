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
# UI-independent BY DESIGN: only the WPF-free state/path helper is
# dot-sourced; no UI modules or globals from the Hub are loaded. The
# ONLY runtime contract with the Hub is:
#   - input:  LocalAppData version cache\prewarm_pending.json
#   - output: merge-writes into the two cache JSON files
#   - lock:   LocalAppData version cache\.prewarm_worker.lock
# Cache entry shapes MUST match Filter.ps1's getters exactly:
#   gh :  { "<repo>": { "tag": "<tag>", "checked": "<ISO-o>" } }
#   web:  { "<url>":  { "ver": "<ver>", "checked": "<ISO-o>" } }
# ============================================================
param(
    [Parameter(Mandatory = $true)][string]$ScriptDir
)

$ErrorActionPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$script:scriptDir = $ScriptDir
$global:scriptDir = $ScriptDir
try { . (Join-Path $ScriptDir 'Modules\HubState.ps1') } catch { return }
$runtimeDir = Get-HubVersionCacheRoot
if (-not $runtimeDir) { return }
$pendingFile = Join-Path $runtimeDir ".prewarm_pending.json"
$lockFile    = Join-Path $runtimeDir ".prewarm_worker.lock"
$ghCacheFile = Join-Path $runtimeDir ".gh_version_cache"
$webCacheFile= Join-Path $runtimeDir ".web_version_cache"

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
    param([string]$Repo, [bool]$IncludePrerelease = $false)
    if ($IncludePrerelease) {
        try {
            $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=10" `
                -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 15 -EA Stop
            foreach ($rel in @($rels)) {
                $candidate = [string]$rel.tag_name
                if (-not $rel.draft -and $candidate -and $candidate -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') {
                    return $candidate.Trim()
                }
            }
        } catch {}
        return $null
    }
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
            $stableTag = [System.Uri]::UnescapeDataString($matches[1]).Trim()
            if ($stableTag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') { return $stableTag }
        }
    } catch {}
    return $null
}

function Get-GithubCommitBackground {
    param([string]$Repo, [string]$Branch = 'main')
    try {
        $branchEscaped = [Uri]::EscapeDataString($Branch)
        $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/commits/$branchEscaped" `
            -Headers @{ 'User-Agent'='PCVR-Mods-Hub'; 'Accept'='application/vnd.github+json' } -TimeoutSec 15 -EA Stop
        $dateText = [string]$commit.commit.committer.date
        if (-not $dateText) { $dateText = [string]$commit.commit.author.date }
        if ($dateText) {
            return ([DateTime]::Parse($dateText, $null, [Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()).ToString('yyyy.MM.dd.HHmmss')
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

function Select-BackgroundAssetTag {
    param($Releases,[bool]$IncludePrerelease,[string[]]$Patterns,[string]$VersionPattern)
    foreach($release in @($Releases)){
        if($release.draft -or (-not $IncludePrerelease -and $release.prerelease)){continue}
        $matches=@($release.assets | Where-Object {
            $name=[string]$_.name
            if(-not $name){return $false}
            foreach($pattern in $Patterns){if($name -match $pattern){return $true}}
            return $false
        })
        if($matches.Count -ne 1){continue}
        if($VersionPattern){
            $m=[regex]::Match([string]$matches[0].name,$VersionPattern)
            if($m.Success -and $m.Groups.Count -gt 1 -and $m.Groups[1].Value -match '\d'){return [string]$m.Groups[1].Value}
            continue
        }
        return [string]$release.tag_name
    }
    return $null
}

try {
    if (-not (Test-Path -LiteralPath $pendingFile)) { return }
    $items = @()
    try { $items = @(Get-Content -LiteralPath $pendingFile -Raw | ConvertFrom-Json) } catch { $items = @() }
    # Windows PowerShell 5.1 wraps a JSON array as one Object[] pipeline item.
    if ($items.Count -eq 1 -and $items[0] -is [array]) { $items = $items[0] }

    # The former serial worker could spend 15 seconds on EACH of 190+ sources.
    # An installed game late in that queue could consequently have no version
    # cache for days. Limit network work to eight concurrent requests and five
    # seconds per request; only this hidden worker waits for them.
    Add-Type -AssemblyName System.Net.Http
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $true
    $handler.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
    $client = [Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(5)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('PCVR-Mods-Hub/1.0')
    $fixture = $null
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PREWARM_FIXTURE_RESPONSES -and
        (Test-Path -LiteralPath $env:PCVR_PREWARM_FIXTURE_RESPONSES -PathType Leaf)) {
        $fixture = Get-Content -LiteralPath $env:PCVR_PREWARM_FIXTURE_RESPONSES -Raw | ConvertFrom-Json
    }
    try {
        for ($offset = 0; $offset -lt $items.Count; $offset += 8) {
            $batch = @()
            foreach ($it in @($items | Select-Object -Skip $offset -First 8)) {
                try {
                    $kind = [string]$it.K
                    $repo = [string]$it.A
                    $patterns = @($it.R | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
                    $uri = if ($kind -eq 'gh') {
                        if($patterns.Count -gt 0){"https://api.github.com/repos/$repo/releases?per_page=20"}
                        elseif ([bool]$it.P) { "https://github.com/$repo/releases.atom" }
                        else { "https://github.com/$repo/releases/latest" }
                    } elseif ($kind -eq 'ghcommit') {
                        $branch = if ([string]$it.B) { [string]$it.B } else { 'main' }
                        'https://api.github.com/repos/' + $repo + '/commits/' + [Uri]::EscapeDataString($branch)
                    } else { $repo }
                    $method = if ($kind -eq 'gh' -and -not [bool]$it.P -and $patterns.Count -eq 0) { [Net.Http.HttpMethod]::Head } else { [Net.Http.HttpMethod]::Get }
                    $request = [Net.Http.HttpRequestMessage]::new($method,[Uri]$uri)
                    if ($fixture) {
                        $mock = $fixture.PSObject.Properties[$uri].Value
                        if (-not $mock) { throw "No prewarm fixture response for $uri" }
                        $response = [Net.Http.HttpResponseMessage]::new([Net.HttpStatusCode][int]$mock.Status)
                        $response.RequestMessage = [Net.Http.HttpRequestMessage]::new($method,[Uri][string]$mock.FinalUri)
                        $response.Content = [Net.Http.StringContent]::new([string]$mock.Body)
                        $task = [Threading.Tasks.Task[Net.Http.HttpResponseMessage]]::FromResult($response)
                    } else {
                        $task = $client.SendAsync($request,[Net.Http.HttpCompletionOption]::ResponseHeadersRead)
                    }
                    $batch += [pscustomobject]@{ Item=$it; Request=$request; Task=$task }
                } catch { if ($env:PCVR_HUB_TEST_MODE -eq '1') { Write-Host "[PrewarmTest] request uri '$uri': $($_.Exception.Message)" } }
            }
            foreach ($work in $batch) {
                $response = $null
                try {
                    $response = $work.Task.GetAwaiter().GetResult()
                    if (-not $response.IsSuccessStatusCode) { continue }
                    $it = $work.Item; $kind = [string]$it.K; $key = [string]$it.A
                    $patterns = @($it.R | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
                    $tag = $null
                    if($kind -eq 'gh' -and $patterns.Count -gt 0){
                        $releases=$response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
                        $tag=Select-BackgroundAssetTag -Releases $releases -IncludePrerelease ([bool]$it.P) -Patterns $patterns -VersionPattern ([string]$it.V)
                        if([bool]$it.P){$key+='#pre'}
                        $key+='#asset='+[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($patterns -join '|'))).TrimEnd('=').Replace('/','_').Replace('+','-')
                        if([string]$it.V){$key+='#asset-version='+[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$it.V)).TrimEnd('=').Replace('/','_').Replace('+','-')}
                    } elseif ($kind -eq 'gh' -and -not [bool]$it.P) {
                        $final = [string]$response.RequestMessage.RequestUri.AbsoluteUri
                        if ($final -match '/releases/tag/([^/?#]+)') { $tag = [Uri]::UnescapeDataString($matches[1]).Trim() }
                    } elseif ($kind -eq 'gh') {
                        $atom = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        foreach ($match in [regex]::Matches($atom,'Repository/[0-9]+/([^<]+)')) {
                            $candidate = [Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
                            if ($candidate -and $candidate -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') { $tag = $candidate; break }
                        }
                        $key += '#pre'
                    } elseif ($kind -eq 'ghcommit') {
                        $data = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
                        $dateText = [string]$data.commit.committer.date
                        if (-not $dateText) { $dateText = [string]$data.commit.author.date }
                        if ($dateText) { $tag = ([DateTime]::Parse($dateText,$null,[Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()).ToString('yyyy.MM.dd.HHmmss') }
                        $branch = if ([string]$it.B) { [string]$it.B } else { 'main' }
                        $key += '#commit:' + $branch
                    } else {
                        $html = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        if     ($html -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { $tag = 'v' + $matches[1] }
                        elseif ($html -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { $tag = 'v' + $matches[1] }
                        elseif ($html -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { $tag = 'v' + $matches[1] }
                    }
                    if ($tag -and ($kind -ne 'gh' -or $tag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic')) {
                        $field = if ($kind -eq 'web') { 'ver' } else { 'tag' }
                        $entry = @{ checked = [DateTime]::UtcNow.ToString('o') }
                        $entry[$field] = $tag
                        $file = if ($kind -eq 'web') { $webCacheFile } else { $ghCacheFile }
                        Merge-CacheEntry -File $file -Key $key -Entry $entry
                    }
                } catch {
                    # A failed source keeps its previous cache entry; other
                    # requests in this batch still finish and are recorded.
                    if ($env:PCVR_HUB_TEST_MODE -eq '1') { Write-Host "[PrewarmTest] result: $($_.Exception.Message)" }
                } finally {
                    if ($response) { $response.Dispose() }
                    $work.Request.Dispose()
                }
            }
        }
    } finally { $client.Dispose(); $handler.Dispose() }
} finally {
    try { Remove-Item -LiteralPath $pendingFile -Force -EA SilentlyContinue } catch {}
    try { Remove-Item -LiteralPath $lockFile -Force -EA SilentlyContinue } catch {}
}

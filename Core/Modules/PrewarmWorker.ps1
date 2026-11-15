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
. (Join-Path $ScriptDir 'Modules\Filter.ScanSources.ps1')
$runtimeDir = Get-HubVersionCacheRoot
if (-not $runtimeDir) { return }
$pendingFile = Join-Path $runtimeDir ".prewarm_pending.json"
$lockFile    = Join-Path $runtimeDir ".prewarm_worker.lock"
$ghCacheFile = Join-Path $runtimeDir ".gh_version_cache"
$webCacheFile= Join-Path $runtimeDir ".web_version_cache"
$tsCacheFile=Join-Path $runtimeDir ".ts_version_cache"
$nightlyCacheFile=Join-Path $runtimeDir ".nightly_version_cache"

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
                foreach ($ip in $p.Value.PSObject.Properties) { $h[$ip.Name] = $ip.Value }
                $all[$p.Name] = $h
            }
        } catch {}
    }
    $all[$Key] = $Entry
    try { ($all | ConvertTo-Json -Depth 8) | Set-Content -Path $File -Encoding UTF8 -Force } catch {}
}

function Get-GithubTagBackground {
    # Same source as the Hub's getter: the /releases/latest WEB redirect (not
    # the rate-limited API). HEAD only; the tag is in the final URL.
    param([string]$Repo, [bool]$IncludePrerelease = $false)
    if ($IncludePrerelease) {
        try {
            $rels = Invoke-PCVRRestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=10" `
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
        $commit = Invoke-PCVRRestMethod -Uri "https://api.github.com/repos/$Repo/commits/$branchEscaped" `
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
    if($fixture){
        # The existing isolated HTTP fixture also supplies expanded assets;
        # missing fixture URLs fail locally rather than reaching the network.
        function global:Get-PCVRGitHubMetadataText {
            param([string]$Uri,$Budget)
            $mock=$fixture.PSObject.Properties[$Uri].Value
            if(-not $mock -or [int]$mock.Status -ne 200){throw ('No successful prewarm metadata fixture for '+$Uri)}
            return [pscustomobject]@{Content=[string]$mock.Body;FinalUrl=[string]$mock.FinalUri}
        }
    }

    # Reuse fetched listing responses in the same resolver as the installer
    # and foreground scan. A separate first-card selector could downgrade a
    # normal numeric release even though all three used the same cache key.
    $script:workerRawReplies=@{}
    $script:workerTextTransport=(Get-Command Get-PCVRGitHubText).ScriptBlock
    function global:Get-PCVRGitHubText {
        param([string]$Uri,[switch]$ScanFast)
        if($script:workerRawReplies.ContainsKey($Uri)){return $script:workerRawReplies[$Uri]}
        if($fixture){
            $mock=$fixture.PSObject.Properties[$Uri].Value
            if(-not $mock -or [int]$mock.Status -ne 200){throw ('No successful prewarm text fixture for '+$Uri)}
            return [pscustomobject]@{Content=[string]$mock.Body;FinalUrl=$(if($mock.FinalUri){[string]$mock.FinalUri}else{$Uri})}
        }
        return & $script:workerTextTransport -Uri $Uri -ScanFast:$ScanFast
    }
    if($fixture){function global:Invoke-WebRequest {throw 'The isolated prewarm fixture forbids direct network access.'}}
    try {
        for ($offset = 0; $offset -lt $items.Count; $offset += 8) {
            $batch = @()
            foreach ($it in @($items | Select-Object -Skip $offset -First 8)) {
                try {
                    $kind = [string]$it.K
                    $repo = [string]$it.A
                    $patterns = @($it.R | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
                    $uri = if ($kind -eq 'gh') {
                        "https://github.com/$repo/releases"
                    } elseif ($kind -eq 'ghcommit') {
                        $branch = if ([string]$it.B) { [string]$it.B } else { 'main' }
                        'https://github.com/' + $repo + '/commits/' + [Uri]::EscapeDataString($branch) + '.atom'
                    } elseif($kind -eq 'ts') {
                        'https://thunderstore.io/api/experimental/package/'+$repo+'/'+[string]$it.B+'/'
                    } elseif($kind -eq 'nightly') {
                        'https://github.com/'+$repo+'/releases/latest'
                    } else { $repo }
                    $method = [Net.Http.HttpMethod]::Get
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
                    if($kind -eq 'ts'){
                        $package=$response.Content.ReadAsStringAsync().GetAwaiter().GetResult()|ConvertFrom-Json
                        if($package.latest.version_number){
                            $entry=@{version=[string]$package.latest.version_number;deprecated=[bool]($package.is_deprecated -eq $true);checked=[DateTime]::UtcNow.ToString('o');date=[string]$package.latest.date_created;download=[string]$package.latest.download_url;dependencies=@($package.latest.dependencies|ForEach-Object {[string]$_})}
                            Merge-CacheEntry -File $tsCacheFile -Key ($key+'-'+[string]$it.B) -Entry $entry
                        }
                        continue
                    }elseif($kind -eq 'nightly'){
                        $final=[string]$response.RequestMessage.RequestUri.AbsoluteUri
                        if($final -match '/releases/tag/([^/?#]+)'){
                            $releaseTag=[Uri]::UnescapeDataString($Matches[1])
                            $section=$response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                            $release=Get-PCVRGitHubReleaseFromWeb -Repo $key -Tag $releaseTag -Section $section -Budget ([pscustomobject]@{Fast=$true;End=[DateTime]::UtcNow.AddSeconds(8)})
                            if($release -and $release.tag_name){
                                $assets=@{};foreach($asset in $release.assets){if($asset.name -and $asset.updated_at){$assets[[string]$asset.name]=[string]$asset.updated_at}}
                                Merge-CacheEntry -File $nightlyCacheFile -Key $key -Entry @{Tag=[string]$release.tag_name;Assets=$assets;checked=[DateTime]::UtcNow.ToString('o')}
                            }
                        }
                        continue
                    }elseif($kind -eq 'gh'){
                        $listing=$response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        $script:workerRawReplies['https://github.com/'+[string]$it.A+'/releases']=[pscustomobject]@{Content=$listing;FinalUrl=[string]$response.RequestMessage.RequestUri.AbsoluteUri}
                        $resolved=Resolve-GitHubReleaseAsset -Repo ([string]$it.A) -AssetPatterns $patterns -IncludePrerelease ([bool]$it.P) -TagOrder ([string]$it.O) -SkipReleasesWithoutMatchingAsset -ScanFast
                        if($resolved.Resolved){
                            $tag=[string]$resolved.Tag
                            if([bool]$it.W){$tag=Get-PCVRGitHubSelectedAssetTimestamp -Release $resolved}
                            if([string]$it.V){$match=[regex]::Match([string]$resolved.AssetName,[string]$it.V);$tag=if($match.Success -and $match.Groups.Count -gt 1 -and $match.Groups[1].Value -match '\d'){[string]$match.Groups[1].Value}else{''}}
                            if([string]$it.O -eq 'published' -and $tag -and [string]$it.I){[void](Test-GithubReleaseIsNewer -Repo ([string]$it.A) -Installed ([string]$it.I) -Online $tag -TagOrder 'published')}
                        }
                    } elseif ($kind -eq 'ghcommit') {
                        [xml]$commitFeed=$response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        $entry=@($commitFeed.feed.entry)[0]
                        $dateText=if([string]$entry.id -match '/[a-fA-F0-9]{40,64}$'){[string]$entry.updated}else{''}
                        if ($dateText) { $tag = ([DateTime]::Parse($dateText,$null,[Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()).ToString('yyyy.MM.dd.HHmmss') }
                        $branch = if ([string]$it.B) { [string]$it.B } else { 'main' }
                        $key += '#commit:' + $branch
                    } else {
                        $html = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        if ([string]$it.P) {
                            $m=[regex]::Match($html,[string]$it.P)
                            if($m.Success){
                                $tag=if($m.Groups['version'].Success){$m.Groups['version'].Value}else{$m.Groups[1].Value}
                                if($it.Aliases){$tag=[string]$it.Aliases.PSObject.Properties[$tag].Value}
                                if($tag -notmatch '\d'){$tag=$null}
                            }
                        }
                        elseif ($html -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { $tag = 'v' + $matches[1] }
                        elseif ($html -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { $tag = 'v' + $matches[1] }
                        elseif ($html -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { $tag = 'v' + $matches[1] }
                    }
                    if ($tag -and ($kind -ne 'gh' -or $tag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic')) {
                        if($kind -eq 'gh'){
                            $key=Get-PCVRGithubVersionCacheKey -Repo ([string]$it.A) -IncludePrerelease ([bool]$it.P) -AssetPatterns $patterns -AssetVersionPattern ([string]$it.V) -AssetTimestampVersion ([bool]$it.W) -TagOrder ([string]$it.O)
                        }
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

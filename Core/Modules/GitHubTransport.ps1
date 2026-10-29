# Shared GitHub and publisher HTTP transport for Hub scans and installers.
function global:_Invoke-DownloadWithProgress {
    param([string]$Url, [string]$Destination, [string]$Label, [switch]$GitHubApiAsset,
        [int]$ConnectTimeoutSec=30,[int]$ReadTimeoutSec=120)
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
    $resp = $null; $inStream = $null; $outStream = $null
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.UserAgent = "PCVR-Mods-Hub"
        if ($GitHubApiAsset) { $req.Accept = 'application/octet-stream' }
        $req.AllowAutoRedirect = $true
        $req.Timeout = $ConnectTimeoutSec * 1000
        $req.ReadWriteTimeout = $ReadTimeoutSec * 1000
        $resp = $req.GetResponse()
        $total = [int64]$resp.ContentLength
        $totalMB = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { 0 }
        $inStream  = $resp.GetResponseStream()
        $outStream = [System.IO.File]::Create($Destination)
        $buffer = New-Object byte[] 131072   # 128 KB
        $sofar  = [int64]0
        $read   = 0
        $startTick = [Environment]::TickCount
        $lastTick  = 0
        while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outStream.Write($buffer, 0, $read)
            $sofar += $read
            $now = [Environment]::TickCount
            if (($now - $lastTick) -ge 250) {
                $lastTick = $now
                $sofarMB = [math]::Round($sofar / 1MB, 1)
                $elapsed = [math]::Max(1, ($now - $startTick)) / 1000.0
                $rate    = [math]::Round(($sofar / 1MB) / $elapsed, 2)   # MB/s
                if ($total -gt 0) {
                    $pct = [int](($sofar * 100) / $total)
                    if ($pct -lt 0) { $pct = 0 } elseif ($pct -gt 100) { $pct = 100 }
                    Write-Progress -Id 1 -Activity "Downloading $Label" -Status "$sofarMB MB of $totalMB MB ($pct%) - $rate MB/s" -PercentComplete $pct
                } else {
                    Write-Progress -Id 1 -Activity "Downloading $Label" -Status "$sofarMB MB downloaded - $rate MB/s"
                }
            }
        }
        Write-Progress -Id 1 -Activity "Downloading $Label" -Completed
        try { $outStream.Close() } catch {}; $outStream = $null
        try { $inStream.Close() }  catch {}; $inStream  = $null
        try { $resp.Close() }      catch {}; $resp      = $null
        return ((Test-Path $Destination) -and ((Get-Item $Destination).Length -gt 0))
    } catch {
        try { Write-Progress -Id 1 -Activity "Downloading $Label" -Completed } catch {}
        throw
    } finally {
        if ($outStream) { try { $outStream.Close() } catch {} }
        if ($inStream)  { try { $inStream.Close() }  catch {} }
        if ($resp)      { try { $resp.Close() }      catch {} }
    }
}

# Try independent Windows download transports against the same publisher URL.
# Each transport writes to a disposable staging path; the caller validates the
# payload before moving it to the game. A failed transport never leaves a
# partial archive that could be mistaken for a successful download.
function global:Invoke-PCVRDownloadTransportChain {
    param([string]$Url,[string]$Destination,[string]$Label,[switch]$GitHubApiAsset,[switch]$Metadata,
        [scriptblock]$Validator=$null,[switch]$ScanFast)
    $timeLimit=if($ScanFast){12}elseif($Metadata){45}else{180}
    $failures = New-Object System.Collections.Generic.List[string]
    $methods=if($ScanFast){@('python','curl')}else{@('stream','web','curl','python','bits')}
    foreach ($method in $methods) {
        if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue }
        try {
            switch ($method) {
                'stream' {
                    if (-not (_Invoke-DownloadWithProgress -Url $Url -Destination $Destination -Label $Label -GitHubApiAsset:$GitHubApiAsset `
                        -ConnectTimeoutSec $(if($Metadata){15}else{30}) -ReadTimeoutSec $timeLimit)) { throw 'empty response' }
                }
                'web' {
                    $oldProgress = $ProgressPreference
                    try {
                        $ProgressPreference = 'SilentlyContinue'
                        $headers = if ($GitHubApiAsset) { @{ Accept='application/octet-stream'; 'User-Agent'='PCVR-Mods-Hub' } } else { @{ 'User-Agent'='PCVR-Mods-Hub' } }
                        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -Headers $headers -TimeoutSec $timeLimit -ErrorAction Stop | Out-Null
                    } finally { $ProgressPreference = $oldProgress }
                }
                'curl' {
                    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
                    if (-not $curl) { throw 'curl.exe is unavailable' }
                    $args = @('--location','--fail','--silent','--show-error','--connect-timeout','15','--max-time',[string]$timeLimit)
                    if ($GitHubApiAsset) { $args += @('--header','Accept: application/octet-stream') }
                    $args += @('--output',$Destination,$Url)
                    $oldAction = $ErrorActionPreference
                    try { $ErrorActionPreference = 'Continue'; & $curl.Source @args 2>$null | Out-Null; $code = $LASTEXITCODE }
                    finally { $ErrorActionPreference = $oldAction }
                    if ($code -ne 0) { throw "curl.exe exited with code $code" }
                }
                'python' {
                    $python=Get-Command python.exe -ErrorAction SilentlyContinue
                    $pythonPath=if($python){[string]$python.Source}else{''}
                    if(-not $pythonPath -and $env:USERPROFILE){
                        # Optional local interpreter; the Hub does not need
                        # Python when the other Windows transports work.
                        $candidate=Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
                        if(Test-Path -LiteralPath $candidate -PathType Leaf){$pythonPath=$candidate}
                    }
                    if(-not $pythonPath){throw 'Python is unavailable'}
                    $accept=if($GitHubApiAsset){'application/octet-stream'}else{'*/*'}
                    # Windows PowerShell 5 removes embedded double quotes from
                    # native -c arguments. Python string literals must use
                    # single quotes here or its fallback fails with NameError.
                    $codeText="import sys,urllib.request,shutil; q=urllib.request.Request(sys.argv[1],headers={'User-Agent':'PCVR-Mods-Hub','Accept':sys.argv[3]}); r=urllib.request.urlopen(q,timeout=45); f=open(sys.argv[2],'wb'); shutil.copyfileobj(r,f,131072); f.close(); r.close()"
                    $oldAction=$ErrorActionPreference
                    try {$ErrorActionPreference='Continue'; & $pythonPath -c $codeText $Url $Destination $accept 2>$null | Out-Null; $code=$LASTEXITCODE}
                    finally {$ErrorActionPreference=$oldAction}
                    if($code -ne 0){throw "Python transport exited with code $code"}
                }
                'bits' {
                    if (-not (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue)) { throw 'BITS is unavailable' }
                    $bitsArgs = @{ Source=$Url; Destination=$Destination; Asynchronous=$true; ErrorAction='Stop' }
                    if ($GitHubApiAsset) { $bitsArgs.CustomHeaders = @('Accept: application/octet-stream') }
                    $job = Start-BitsTransfer @bitsArgs
                    try {
                        $deadline = [DateTime]::UtcNow.AddSeconds($timeLimit)
                        while ($job.JobState -in @('Connecting','Transferring','Queued','TransientError') -and [DateTime]::UtcNow -lt $deadline) {
                            Start-Sleep -Milliseconds 400
                            $job = Get-BitsTransfer -JobId $job.JobId -ErrorAction Stop
                        }
                        if ($job.JobState -ne 'Transferred') { throw "BITS stopped in state $($job.JobState)" }
                        Complete-BitsTransfer -BitsJob $job -ErrorAction Stop
                        $job = $null
                    } finally { if ($job) { Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue } }
                }
            }
            if ((Test-Path -LiteralPath $Destination -PathType Leaf) -and (Get-Item -LiteralPath $Destination).Length -gt 0) {
                if($Validator -and -not (& $Validator $Destination)) { throw 'transport returned an invalid publisher file' }
                return $method
            }
            throw 'no nonempty file was saved'
        } catch {
            [void]$failures.Add("${method}: $($_.Exception.Message)")
        }
    }
    if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue }
    throw ('All download transports failed: ' + ($failures -join ' | '))
}

function global:Get-PCVRGitHubText {
    param([Parameter(Mandatory=$true)][string]$Uri,[switch]$ScanFast)
    $headers=@{ 'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
    try {
        $response=Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers $headers -TimeoutSec $(if($ScanFast){5}else{15}) -ErrorAction Stop
        $final=''
        try { $final=[string]$response.BaseResponse.ResponseUri.AbsoluteUri } catch {}
        if(-not $final){try{$final=[string]$response.BaseResponse.RequestMessage.RequestUri.AbsoluteUri}catch{}}
        return [pscustomobject]@{Content=[string]$response.Content; FinalUrl=$final; Transport='web'}
    } catch {
        $firstError=$_.Exception.Message
    }
    # A different transport cannot replenish GitHub's shared API quota.
    # Public-page resolution has its own route; do not hammer the denied API.
    if($Uri -match '^https://api\.github\.com/' -and $firstError -match '(?i)\b403\b|\b429\b|rate.limit'){
        throw ('GitHub REST is unavailable: '+$firstError)
    }
    $temp=Join-Path ([IO.Path]::GetTempPath()) ('.pcvr-github-'+[guid]::NewGuid().ToString('N')+'.txt')
    try {
        $transport=Invoke-PCVRDownloadTransportChain -Url $Uri -Destination $temp -Label 'GitHub release metadata' -Metadata -ScanFast:$ScanFast
        $content=[IO.File]::ReadAllText($temp,[Text.Encoding]::UTF8)
        return [pscustomobject]@{Content=$content; FinalUrl=''; Transport=$transport}
    } catch {
        throw "GitHub metadata GET failed (web: $firstError; alternate transports: $($_.Exception.Message))"
    } finally {
        if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue}
    }
}

# A tag-only check is used for catalog entries whose download is handled by a
# different publisher route. Keep it independent of asset selection, but use
# the same bounded website/alternate-transport ladder as installer metadata.
function global:Resolve-GitHubReleaseTag {
    param([Parameter(Mandatory=$true)][string]$Repo,[switch]$IncludePrerelease,[switch]$ScanFast)
    if($Repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'){return $null}
    $page="https://github.com/$Repo/releases"
    $tag=''
    if(-not $IncludePrerelease){
        try {
            $head=Invoke-WebRequest -Uri "$page/latest" -Method Head -UseBasicParsing `
                -Headers @{'User-Agent'='PCVR-Mods-Hub'} -TimeoutSec $(if($ScanFast){3}else{10}) -ErrorAction Stop
            $final=''
            try{$final=[string]$head.BaseResponse.ResponseUri.AbsoluteUri}catch{}
            if(-not $final){try{$final=[string]$head.BaseResponse.RequestMessage.RequestUri.AbsoluteUri}catch{}}
            if($final -match '/releases/tag/([^/?#]+)'){$tag=[uri]::UnescapeDataString($matches[1])}
        }catch{}
        if(-not $tag){
            try {
                $reply=Get-PCVRGitHubText -Uri "$page/latest" -ScanFast:$ScanFast
                if(([string]$reply.FinalUrl) -match '/releases/tag/([^/?#]+)'){
                    $tag=[uri]::UnescapeDataString($matches[1])
                }elseif(([string]$reply.Content) -match '<meta\s+property="og:url"\s+content="/?[^" ]+/releases/tag/([^"/?#]+)"'){
                    $tag=[uri]::UnescapeDataString($matches[1])
                }
            }catch{}
        }
    }else{
        try {
            $feed=Get-PCVRGitHubText -Uri "$page.atom" -ScanFast:$ScanFast
            foreach($match in [regex]::Matches([string]$feed.Content,'Repository/[0-9]+/([^<]+)')){
                $candidate=[System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
                if($candidate -and $candidate -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic'){$tag=$candidate;break}
            }
        }catch{}
    }
    if(-not $tag){
        try {
            $listing=Get-PCVRGitHubText -Uri $page -ScanFast:$ScanFast
            foreach($section in [regex]::Matches([string]$listing.Content,'(?s)<section id="release-([^"]+)"[^>]*>(.*?)(?=<section id="release-|\z)')){
                if(-not $IncludePrerelease -and [string]$section.Groups[2].Value -notmatch 'releases/latest|Label--success[^>]*>Latest'){continue}
                $candidate=[System.Net.WebUtility]::HtmlDecode($section.Groups[1].Value).Trim()
                if($candidate -and $candidate -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic'){$tag=$candidate;break}
            }
        }catch{}
    }
    if(-not $tag){
        $api="https://api.github.com/repos/$Repo/releases?per_page=10"
        try {
            $releases=Invoke-RestMethod -Uri $api -Headers @{'User-Agent'='PCVR-Mods-Hub'} `
                -TimeoutSec $(if($ScanFast){3}else{20}) -ErrorAction Stop
        }catch{
            try{$reply=Get-PCVRGitHubText -Uri $api -ScanFast:$ScanFast; $releases=ConvertFrom-Json -InputObject ([string]$reply.Content)}catch{$releases=@()}
        }
        foreach($release in @($releases)){
            $candidate=([string]$release.tag_name).Trim()
            if(-not $release.draft -and ($IncludePrerelease -or -not $release.prerelease) -and
                $candidate -and $candidate -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic'){$tag=$candidate;break}
        }
    }
    if($tag -and $tag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic'){return $tag}
    return $null
}


# Resolve the installable asset from the newest eligible GitHub release.
#
# An old pinned URL is only an explicit offline route; it is never the default
# for a catalog entry whose Update badge follows GitHub. Otherwise the card
# can advertise a newer tag while the installer puts an old file back.
# This helper keeps the release identity and delivered asset together.
# AssetPatterns are tried in order, allowing
# an exact product name first and a conservative format fallback last.
#
# ReleaseData exists for deterministic, network-free regression tests.  Normal
# callers omit it and receive the current GitHub release list.
function global:Resolve-GitHubReleaseAsset {
    param(
        [Parameter(Mandatory=$true)][string]$Repo,
        [Parameter(Mandatory=$true)][string[]]$AssetPatterns,
        [string]$FallbackUrl = "",
        [string]$FallbackTag = "known fallback",
        [string]$FallbackAssetName = "",
        [bool]$IncludePrerelease = $false,
        [switch]$SkipReleasesWithoutMatchingAsset,
        [switch]$AllowOfflinePinnedFallback,
        [switch]$ScanFast,
        $ReleaseData = $null
    )

    $page = "https://github.com/$Repo/releases"
    # These publishers explicitly restarted their release numbering. Their
    # release-card order, followed by REST publication dates, takes precedence
    # over numeric sorting. Keep this scoped: other repos rely on numeric
    # sorting when GitHub's latest pointer lags (for example Spec Ops).
    $publisherReset = $Repo -in @('Bateau01/SOMA-VR','thecosmictangerine-cloud/dishonored-2-vr')
    $result = [ordered]@{
        Repo = $Repo
        Url = ""
        Tag = ""
        AssetName = ""
        PageUrl = $page
        Resolved = $false
        ReleaseFound = $false
        SkippedReleaseTags = @()
        Error = ""
    }
    if ($Repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        $result.Error = 'invalid GitHub repository name'
        return [pscustomobject]$result
    }

    # github.com serves release metadata without the unauthenticated REST API
    # quota. Resolve the tag and its expanded asset list there first. Never
    # infer an asset name from a historical filename: the published href is
    # the proof of which file belongs to this release.
    if ($null -eq $ReleaseData) {
        try {
            $webHeaders = @{ 'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
            $webTags = @()
            $publicationTags = @()
            if ($IncludePrerelease) {
                try {
                    $feed=Get-PCVRGitHubText -Uri "$page.atom" -ScanFast:$ScanFast
                    $webTags=@([regex]::Matches([string]$feed.Content,'Repository/[0-9]+/([^<]+)') |
                        ForEach-Object { [System.Net.WebUtility]::HtmlDecode($_.Groups[1].Value).Trim() } |
                        Where-Object { $_ -and $_ -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic' } | Select-Object -Unique -First 20)
                } catch { $result.Error="GitHub Atom feed: $($_.Exception.Message)" }
            } else {
                try {
                    $head = Invoke-WebRequest -Uri "$page/latest" -Method Head -UseBasicParsing -Headers $webHeaders -TimeoutSec $(if($ScanFast){3}else{10}) -ErrorAction Stop
                    $finalUrl=''
                    try { $finalUrl=[string]$head.BaseResponse.ResponseUri.AbsoluteUri } catch {}
                    if(-not $finalUrl){try{$finalUrl=[string]$head.BaseResponse.RequestMessage.RequestUri.AbsoluteUri}catch{}}
                    if($finalUrl -match '/releases/tag/([^/?#]+)'){$webTags=@([uri]::UnescapeDataString($matches[1]))}
                } catch { $result.Error="GitHub latest HEAD: $($_.Exception.Message)" }
                if($webTags.Count -eq 0){
                    try {
                        $latestPage=Get-PCVRGitHubText -Uri "$page/latest" -ScanFast:$ScanFast
                        $finalUrl=[string]$latestPage.FinalUrl
                        if(-not $finalUrl -and $latestPage.Content -match '<meta\s+property="og:url"\s+content="/?[^" ]+/releases/tag/([^"/?#]+)"'){
                            $finalUrl="$page/tag/$($matches[1])"
                        }
                        if($finalUrl -match '/releases/tag/([^/?#]+)'){$webTags=@([uri]::UnescapeDataString($matches[1]))}
                    } catch { $result.Error="GitHub latest GET: $($_.Exception.Message)" }
                }
            }
            if($webTags.Count -eq 0 -or $SkipReleasesWithoutMatchingAsset){
                try {
                    $listing=Get-PCVRGitHubText -Uri $page -ScanFast:$ScanFast
                    $sections=@([regex]::Matches([string]$listing.Content,'(?s)<section id="release-([^"]+)"[^>]*>(.*?)(?=<section id="release-|\z)'))
                    foreach($section in $sections){
                        $sectionText=[string]$section.Groups[2].Value
                        # GitHub's /latest label can lag a release published later when
                        # its tag or draft was created earlier. Inspect every stable
                        # card, then order comparable numeric tags below.
                        if(-not $IncludePrerelease -and $sectionText.Substring(0,[Math]::Min(1500,$sectionText.Length)) -match '(?i)>\s*Pre-release\s*<') { continue }
                        $tag=[System.Net.WebUtility]::HtmlDecode([string]$section.Groups[1].Value)
                        if($publisherReset -and $tag -and $tag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic'){$publicationTags+=$tag}
                        if($tag -and $tag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic' -and $webTags -notcontains $tag){$webTags+= $tag}
                        if($webTags.Count -ge 20){break}
                    }
                } catch { $result.Error="GitHub release listing: $($_.Exception.Message)" }
            }
            # Preserve website order for opaque tags. Comparable numeric tags
            # use their actual version, so 0.9.11 cannot lose to 0.9.9 merely
            # because GitHub's /latest pointer or card order is stale.
            $tagOrdinal=0
            $tagVersions=@($webTags | ForEach-Object {
                $ordinal=$tagOrdinal;$tagOrdinal++
                $m=[regex]::Match([string]$_,'^(?<prefix>[^0-9]*)(?<version>[0-9]+(?:\.[0-9]+)*)(?<suffix>.*)$')
                if($m.Success){
                    $parts=@($m.Groups['version'].Value.Split('.') | ForEach-Object {
                        $part=$_.TrimStart('0');if(-not $part){$part='0'};$part
                    })
                    if(@($parts|Where-Object{$_.Length -gt 20}).Count -eq 0){
                        [pscustomobject]@{Tag=[string]$_;Prefix=$m.Groups['prefix'].Value;Parts=$parts;SortKey='';Order=$ordinal}
                    }
                }
            })
            if($publisherReset -and $publicationTags.Count -gt 0){$webTags=@(@($publicationTags)+@($webTags) | Select-Object -Unique)}
            # For a reset publisher, HEAD /latest alone cannot establish the
            # current generation. If release cards were unavailable, continue
            # to the REST publication-date fallback instead of accepting an
            # old cached redirect immediately.
            if($publisherReset -and $publicationTags.Count -eq 0){$webTags=@()}
            if(-not $publisherReset -and $webTags.Count -gt 1 -and $tagVersions.Count -eq $webTags.Count -and
                @($tagVersions | Select-Object -ExpandProperty Prefix -Unique).Count -eq 1){
                # System.Version truncates/rejects a fifth component (Star Fox
                # 0.0.8.8.1) and excluded a single component (GEVR vr457).
                # Normalize numeric components as equal-width strings instead;
                # equal numeric versions retain the original publisher order.
                $width=($tagVersions|ForEach-Object{@($_.Parts).Count}|Measure-Object -Maximum).Maximum
                foreach($item in $tagVersions){
                    $padded=@($item.Parts|ForEach-Object{$_.PadLeft(20,'0')})
                    while($padded.Count -lt $width){$padded+='00000000000000000000'}
                    $item.SortKey=$padded -join '.'
                }
                $webTags=@($tagVersions | Sort-Object -Property @{Expression={$_.SortKey};Descending=$true},Order | ForEach-Object Tag)
            }
            foreach($webTag in $webTags){
                $assetsPage=Get-PCVRGitHubText -Uri "$page/expanded_assets/$([uri]::EscapeDataString($webTag))" -ScanFast:$ScanFast
                $assetLinks = @([regex]::Matches([string]$assetsPage.Content, 'href=["'']([^"'']+/releases/download/[^"'']+)["'']') | ForEach-Object {
                    [System.Net.WebUtility]::HtmlDecode($_.Groups[1].Value)
                } | Where-Object {
                    $candidate = [string]$_
                    if ($candidate -match '^https?://') {
                        $uri = [uri]$candidate
                        if ($uri.Host -ne 'github.com') { return $false }
                        $candidate = $uri.AbsolutePath
                    }
                    $path = [uri]::UnescapeDataString(($candidate -split '[?#]')[0])
                    $path.StartsWith("/$Repo/releases/download/$webTag/", [StringComparison]::OrdinalIgnoreCase)
                } | Select-Object -Unique)
                foreach ($pattern in $AssetPatterns) {
                    if (-not $pattern) { continue }
                    $matchedLinks = @($assetLinks | Where-Object {
                        $assetName = [uri]::UnescapeDataString(([string]$_ -split '[?#]')[0].Split('/')[-1])
                        $assetName -match $pattern
                    })
                    if ($matchedLinks.Count -eq 1) {
                        $link = [string]$matchedLinks[0]
                        $result.Url = if ($link -match '^https?://') { $link } else { 'https://github.com' + $link }
                        $result.Tag = $webTag
                        $result.AssetName = [uri]::UnescapeDataString(($link -split '[?#]')[0].Split('/')[-1])
                        $result.PageUrl = "$page/tag/$([uri]::EscapeDataString($webTag))"
                        $result.Resolved = $true
                        $result.ReleaseFound = $true
                        $result.Error = ''
                        return [pscustomobject]$result
                    }
                }
                $result.ReleaseFound = $true
                $result.Tag = $webTag
                $result.PageUrl = "$page/tag/$([uri]::EscapeDataString($webTag))"
                $result.Error = "release '$webTag' has no unambiguous matching asset on the publisher page"
                if(-not $SkipReleasesWithoutMatchingAsset){break}
                $result.SkippedReleaseTags += $webTag
            }
        } catch {
            $result.Error = "GitHub website: $($_.Exception.Message)"
        }
    }
    try {
        $releases = $ReleaseData
        if ($null -eq $releases) {
            $apiUrl="https://api.github.com/repos/$Repo/releases?per_page=20"
            try {
                $releases = Invoke-RestMethod -Uri $apiUrl `
                    -Headers @{ 'User-Agent'='PCVR-Mods-Hub'; 'Accept'='application/vnd.github+json' } `
                    -TimeoutSec $(if($ScanFast){3}else{20}) -ErrorAction Stop
            } catch {
                # The REST endpoint can be reachable through a different
                # transport even when PowerShell's REST client fails TLS.
                $jsonReply=Get-PCVRGitHubText -Uri $apiUrl -ScanFast:$ScanFast
                $releases=ConvertFrom-Json -InputObject ([string]$jsonReply.Content) -ErrorAction Stop
            }
        }
        $eligible = @($releases | Where-Object {
            $_ -and -not [bool]$_.draft -and ($IncludePrerelease -or -not [bool]$_.prerelease) -and
            ([string]$_.tag_name) -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic'
        } | Sort-Object -Property published_at -Descending)
        $release = $null
        $asset = $null
        foreach ($candidate in $eligible) {
            $candidateAsset = $null
            foreach ($pattern in $AssetPatterns) {
                if (-not $pattern) { continue }
                $matches = @($candidate.assets | Where-Object { ([string]$_.name) -match $pattern })
                if ($matches.Count -eq 1 -and $matches[0].browser_download_url) {
                    $candidateAsset = $matches[0]
                    break
                }
            }
            if ($candidateAsset) {
                $release = $candidate
                $asset = $candidateAsset
                break
            }
            if (-not $SkipReleasesWithoutMatchingAsset) {
                $release = $candidate
                break
            }
            if ($candidate.tag_name) { $result.SkippedReleaseTags += [string]$candidate.tag_name }
        }
        if (-not $release -and $eligible.Count -gt 0) { $release = $eligible[0] }
        if (-not $release) {
            $result.Error = 'no eligible GitHub release was returned'
            $result.Url = $result.PageUrl
            return [pscustomobject]$result
        }

        $result.ReleaseFound = $true
        if ($release.tag_name) { $result.Tag = [string]$release.tag_name }
        if ($release.html_url) { $result.PageUrl = [string]$release.html_url }

        if (-not $asset) {
            foreach ($pattern in $AssetPatterns) {
                if (-not $pattern) { continue }
                $matches = @($release.assets | Where-Object { ([string]$_.name) -match $pattern })
                if ($matches.Count -eq 1) { $asset = $matches[0]; break }
            }
        }
        if (-not $asset -or -not $asset.browser_download_url) {
            # Do not silently return the old fallback when GitHub positively
            # told us a newer release exists but its packaging changed.  The
            # release page is intentionally not a payload URL: shared download
            # validation rejects its HTML and opens the normal manual/Retry
            # recovery screen for the current release.
            $result.Url = $result.PageUrl
            $result.AssetName = "the installable asset for $($result.Tag)"
            $result.Error = "release '$($result.Tag)' has no unambiguous matching asset"
            return [pscustomobject]$result
        }

        $result.Url = [string]$asset.browser_download_url
        $result.AssetName = [string]$asset.name
        $result.Resolved = $true
        $result.Error = ''
        return [pscustomobject]$result
    } catch {
        $result.Error = (('' + $result.Error + '; GitHub API: ' + $_.Exception.Message).Trim('; '))
        # An auto-update must not turn a failed check into an old download.
        # An explicitly pinned route may opt into its reviewed offline file.
        if ($AllowOfflinePinnedFallback -and $FallbackUrl -and -not $result.ReleaseFound) {
            $result.Url = $FallbackUrl
            $result.Tag = $FallbackTag
            $result.AssetName = $FallbackAssetName
        } elseif (-not $result.Url) {
            $result.Url = $result.PageUrl
        }
        return [pscustomobject]$result
    }
}



# Compatibility metadata for older per-game selectors. Public release pages
# are the primary source; REST is optional and never the only install gate.
function global:Get-PCVRGitHubMetadataText {
    param([string]$Uri,$Budget)
    if(-not $Budget.Fast){return Get-PCVRGitHubText -Uri $Uri}
    $remaining=($Budget.End-[DateTime]::UtcNow).TotalSeconds
    if($remaining -le 0){throw 'GitHub metadata time budget exhausted; background/manual recovery remains available.'}
    $r=Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{'User-Agent'='PCVR-Mods-Hub'} -TimeoutSec ([Math]::Max(1,[int][Math]::Ceiling($remaining))) -ErrorAction Stop
    $final='';try{$final=[string]$r.BaseResponse.ResponseUri.AbsoluteUri}catch{}
    if(-not $final){try{$final=[string]$r.BaseResponse.RequestMessage.RequestUri.AbsoluteUri}catch{}}
    return [pscustomobject]@{Content=[string]$r.Content;FinalUrl=$final}
}

function global:ConvertFrom-PCVRGitHubReleaseSection {
    param([string]$Repo,[string]$Tag,[string]$Section,[string]$AssetHtml)
    $page='https://github.com/'+$Repo+'/releases/tag/'+[uri]::EscapeDataString($Tag)
    $assets=@();$seen=@{}
    $rows=@([regex]::Matches($AssetHtml,'(?s)<li\b[^>]*>.*?</li>')|ForEach-Object {$_.Value})
    if(-not $rows.Count){$rows=@($AssetHtml)}
    foreach($row in $rows){
        foreach($m in [regex]::Matches($row,'href=["'']([^"'']+/releases/download/[^"'']+)["'']')){
            $href=[Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
            if($href -match '^/[^/]'){$href='https://github.com'+$href}
            $u=$null;if(-not [uri]::TryCreate($href,[UriKind]::Absolute,[ref]$u)){continue}
            if($u.Scheme -ne 'https' -or $u.Host -ne 'github.com'){continue}
            $path=[uri]::UnescapeDataString($u.AbsolutePath)
            if(-not $path.StartsWith('/'+$Repo+'/releases/download/'+$Tag+'/',[StringComparison]::OrdinalIgnoreCase)){continue}
            $name=[uri]::UnescapeDataString($u.Segments[-1])
            if($seen.ContainsKey($name)){continue};$seen[$name]=$true
            $stamp=([regex]::Match($row,'<relative-time\b[^>]*datetime=["'']([^"'']+)')).Groups[1].Value
            $digest=([regex]::Match($row,'(?i)sha256:[a-f0-9]{64}')).Value
            $size=$null;$plain=[Net.WebUtility]::HtmlDecode([regex]::Replace($row,'<[^>]+>',' '))
            $sm=[regex]::Match($plain,'(?i)([0-9]+(?:\.[0-9]+)?)\s*(Bytes?|[KMGT]B)\b')
            if($sm.Success){
                $factor=switch($sm.Groups[2].Value.ToUpperInvariant()){'KB'{1KB}'MB'{1MB}'GB'{1GB}'TB'{1TB}default{1}}
                $size=[int64][Math]::Round([double]::Parse($sm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)*$factor)
            }
            $assets+=[pscustomobject]@{name=$name;browser_download_url=$href;updated_at=$stamp;created_at=$stamp;digest=$digest;size=$size;size_is_approximate=($null -ne $size);id=$null;url=$null}
        }
    }
    $published=([regex]::Match($Section,'<relative-time\b[^>]*datetime=["'']([^"'']+)')).Groups[1].Value
    $heading=$Section.Substring(0,[Math]::Min(3000,$Section.Length))
    $pre=$heading -match '(?i)>\s*Pre-release\s*<'
    $markdown=([regex]::Match($Section,'(?s)<div\b[^>]*class="[^"]*markdown-body[^"]*"[^>]*>(.*?)</div>')).Groups[1].Value
    $markdown=[regex]::Replace($markdown,'(?s)<a\b[^>]*href="([^"]+)"[^>]*>(.*?)</a>','$2 ($1)')
    $markdown=[regex]::Replace($markdown,'(?i)</p>|<br\s*/?>|</li>',"`n")
    $body=[Net.WebUtility]::HtmlDecode([regex]::Replace($markdown,'<[^>]+>',' ')).Trim()
    return [pscustomobject]@{tag_name=$Tag;name=$Tag;html_url=$page;draft=$false;prerelease=[bool]$pre;published_at=$published;created_at=$published;body=$body;assets=@($assets);MetadataSource='github.com'}
}

function global:Get-PCVRGitHubReleaseFromWeb {
    param([string]$Repo,[string]$Tag,[string]$Section,$Budget)
    $fragment=Get-PCVRGitHubMetadataText -Uri ('https://github.com/'+$Repo+'/releases/expanded_assets/'+[uri]::EscapeDataString($Tag)) -Budget $Budget
    $release=ConvertFrom-PCVRGitHubReleaseSection -Repo $Repo -Tag $Tag -Section $Section -AssetHtml ([string]$fragment.Content)
    # An empty asset list is legitimate (source-only releases); a login/error
    # page is not. Never manufacture an installable asset or its identity.
    if(-not $release.assets.Count -and $fragment.Content -notmatch '(?i)/archive/refs/tags/|Source code|<ul\b'){
        throw 'The public release asset list could not be read.'
    }
    return $release
}

function global:Invoke-PCVRRestMethod {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Uri,$Headers,[int]$TimeoutSec=25)
    if($Uri -notmatch '^https://api\.github\.com/repos/(?<repo>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)/(?<route>releases(?:/latest|/tags/[^?#]+)?|commits/[^?#]+)(?:\?(?<query>[^#]*))?$'){
        return Invoke-RestMethod @PSBoundParameters
    }
    $repo=$matches.repo;$route=$matches.route;$query=$matches.query
    $budget=[pscustomobject]@{Fast=($TimeoutSec -le 8);End=[DateTime]::UtcNow.AddSeconds([Math]::Max(1,$TimeoutSec))}
    try{
        if($route.StartsWith('commits/')){
            $branch=$route.Substring(8)
            $feed=Get-PCVRGitHubMetadataText -Uri ('https://github.com/'+$repo+'/commits/'+$branch+'.atom') -Budget $budget
            [xml]$xml=$feed.Content;$entry=@($xml.feed.entry)[0]
            $sha=([regex]::Match([string]$entry.id,'/([a-fA-F0-9]{40,64})$')).Groups[1].Value
            $date=[string]$entry.updated;$parsed=[DateTime]::MinValue
            if(-not $sha -or -not [DateTime]::TryParse($date,[ref]$parsed)){throw 'The public commit feed did not contain a verified commit/date.'}
            return [pscustomobject]@{sha=$sha;commit=[pscustomobject]@{committer=[pscustomobject]@{date=$date};author=[pscustomobject]@{date=$date}};MetadataSource='github.com'}
        }
        $base='https://github.com/'+$repo+'/releases'
        if($route -ne 'releases'){
            $tag=if($route.StartsWith('releases/tags/')){[uri]::UnescapeDataString($route.Substring(14))}else{''}
            $url=if($tag){$base+'/tag/'+[uri]::EscapeDataString($tag)}else{$base+'/latest'}
            $reply=Get-PCVRGitHubMetadataText -Uri $url -Budget $budget
            if(-not $tag){
                if($reply.FinalUrl -match '/releases/tag/([^/?#]+)'){$tag=[uri]::UnescapeDataString($matches[1])}
                elseif($reply.Content -match '<meta\s+property="og:url"\s+content="[^" ]+/releases/tag/([^"/?#]+)"'){$tag=[Net.WebUtility]::HtmlDecode([uri]::UnescapeDataString($matches[1]))}
            }
            if(-not $tag){throw 'The current stable release tag could not be read from the publisher page.'}
            $section=([regex]::Match([string]$reply.Content,'(?s)<section id="release-'+[regex]::Escape([Net.WebUtility]::HtmlEncode($tag))+'"[^>]*>(.*?)(?=<section id="release-|\z)')).Value
            if(-not $section -and $route.StartsWith('releases/tags/') -and [string]$reply.FinalUrl -notmatch ('/releases/tag/'+[regex]::Escape([uri]::EscapeDataString($tag))+'(?:[?#]|$)')){throw 'The requested exact release tag was not confirmed.'}
            $release=Get-PCVRGitHubReleaseFromWeb -Repo $repo -Tag $tag -Section $section -Budget $budget
            if($route -eq 'releases/latest' -and $release.prerelease){throw 'The stable release route returned a prerelease.'}
            return $release
        }
        $limit=30;$pageNumber=1
        if($query -match '(?:^|&)per_page=(\d+)'){$limit=[Math]::Min(100,[Math]::Max(1,[int]$matches[1]))}
        if($query -match '(?:^|&)page=(\d+)'){$pageNumber=[Math]::Max(1,[int]$matches[1])}
        $skip=($pageNumber-1)*$limit;$releases=@();$seen=@{};$ordinal=0
        for($webPage=1;$webPage -le [Math]::Ceiling(($skip+$limit)/10.0);$webPage++){
            $listing=Get-PCVRGitHubMetadataText -Uri ($base+$(if($webPage -gt 1){'?page='+$webPage}else{''})) -Budget $budget
            $sections=@([regex]::Matches([string]$listing.Content,'(?s)<section id="release-([^"]+)"[^>]*>(.*?)(?=<section id="release-|\z)'))
            if(-not $sections.Count){throw 'The public release list could not be read.'}
            foreach($section in $sections){
                $tag=[Net.WebUtility]::HtmlDecode($section.Groups[1].Value)
                if($seen.ContainsKey($tag)){continue};$seen[$tag]=$true
                $ordinal++;if($ordinal -le $skip){continue}
                $releases+=Get-PCVRGitHubReleaseFromWeb -Repo $repo -Tag $tag -Section $section.Value -Budget $budget
                if($releases.Count -ge $limit){break}
            }
            if($releases.Count -ge $limit -or $sections.Count -lt 10){break}
        }
        # Preserve the object/array contract of Invoke-RestMethod on PS5.1.
        return ,$releases
    }catch{
        $webError=$_.Exception.Message
        $remaining=if($budget.Fast){[int][Math]::Floor(($budget.End-[DateTime]::UtcNow).TotalSeconds)}else{$TimeoutSec}
        if($remaining -le 0){throw ('GitHub public metadata could not be checked: '+$webError)}
        try{return Invoke-RestMethod -Uri $Uri -Headers $Headers -TimeoutSec $remaining -ErrorAction Stop}
        catch{throw ('GitHub public metadata could not be checked (website: '+$webError+'; optional REST: '+$_.Exception.Message+'). Retry or use the official release page/manual file.')}
    }
}

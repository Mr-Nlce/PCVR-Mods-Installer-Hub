# -------------------------------------------------------
# Scale factor (S=1.0, M=1.5, L=2.0)
# -------------------------------------------------------
$global:SCALE = 1.0

# -------------------------------------------------------
# Steam preview hover manager (singleton state).
# When the user pauses on a card with a SteamId, the card
# scales up via RenderTransform and shows the Steam header
# image (with optional trailer fade-in for HasVideo cards).
# Only one card may be enlarged at a time; only one
# MediaElement is ever active.
# -------------------------------------------------------
$global:HoverActiveCard   = $null
$global:HoverTimer        = $null
$global:HoverPendingCard  = $null
$global:HoverMediaElement = $null
$global:HoverDelayMs      = 600

# Anomaly VR stores its VR mod under <gameDir>\MODS\ as a versioned
# folder named "amomaly_aoe_vr <version>" (the "amomaly" typo is
# upstream). To detect an available update we read the actually-
# installed version from that folder name and let the normal version
# comparison (installed vs the catalog Mod string) flag an update.
# This is Anomaly-specific - no other game uses this scheme. Returns
# the highest installed version string (e.g. "0.3.5") or $null.
function global:Get-AnomalyInstalledModVersion {
    param([string]$GameDir)
    if (-not $GameDir) { return $null }
    $modsDir = Join-Path $GameDir "MODS"
    if (-not (Test-Path $modsDir)) { return $null }
    $best = $null
    try {
        $dirs = Get-ChildItem -Path $modsDir -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^amomaly_aoe_vr\s+(\d+\.\d+(?:\.\d+)*)' }
        foreach ($d in $dirs) {
            $m = [regex]::Match($d.Name, '^amomaly_aoe_vr\s+(\d+\.\d+(?:\.\d+)*)')
            if ($m.Success) {
                $vStr = $m.Groups[1].Value
                try {
                    $vObj = [version]$vStr
                    if (-not $best -or $vObj -gt $best.Obj) {
                        $best = @{ Obj = $vObj; Str = $vStr }
                    }
                } catch { }
            }
        }
    } catch { }
    if ($best) { return $best.Str }
    return $null
}

function global:Get-SteamHeaderUrl {
    param([string]$SteamId)
    "https://cdn.akamai.steamstatic.com/steam/apps/$SteamId/header.jpg"
}
function global:Get-SteamPortraitUrl {
    param([string]$SteamId)
    "https://cdn.akamai.steamstatic.com/steam/apps/$SteamId/library_600x900.jpg"
}
# Fallback CDN: Steam migrated newer titles to Fastly. Akamai 404s
# silently for some games (often newer indie releases, e.g. Moto
# Rush Reborn) so we keep a fastly URL ready as a second attempt.
function global:Get-SteamHeaderUrlFastly {
    param([string]$SteamId)
    "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$SteamId/header.jpg"
}
function global:Get-SteamPortraitUrlFastly {
    param([string]$SteamId)
    "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$SteamId/library_600x900.jpg"
}

# Per-process caches so opening the same detail page twice doesn't
# refetch. Description and screenshot are both populated by the
# same /appdetails fetch so we cache both side-by-side.
if (-not $global:SteamDescCache) { $global:SteamDescCache = @{} }
if (-not $global:SteamScreenshotCache) { $global:SteamScreenshotCache = @{} }

# Load the persisted Steam store info (short description + screenshot
# URL) from Assets\cache\steam_info.json into the in-memory caches, so
# we never re-hit the /appdetails API for an app we've already seen.
# Path is built directly from $script:scriptDir so this is independent
# of when the cache-dir helpers load. Silent + best-effort: a missing
# or malformed file just leaves the caches empty (first-run behaviour).
function global:Import-SteamInfoCache {
    $base = if ($global:scriptDir) { $global:scriptDir } else { $script:scriptDir }
    if (-not $base) { return }
    $file = Join-Path $base "Assets\cache\steam_info.json"
    if (-not (Test-Path $file)) { return }
    try {
        $raw = Get-Content $file -Raw -ErrorAction Stop
        if (-not $raw) { return }
        $obj = $raw | ConvertFrom-Json
        foreach ($p in $obj.PSObject.Properties) {
            $sid = $p.Name
            $val = $p.Value
            # Stored as { desc = "..."; shot = "..." } per SteamId.
            if ($null -ne $val) {
                if (-not $global:SteamDescCache.ContainsKey($sid)) {
                    $global:SteamDescCache[$sid] = $val.desc
                }
                if (-not $global:SteamScreenshotCache.ContainsKey($sid)) {
                    $global:SteamScreenshotCache[$sid] = $val.shot
                }
            }
        }
    } catch { }
}
Import-SteamInfoCache

# Process-wide decoded-bitmap cache for LOCAL images only. A
# BitmapImage from a file:// URI loads synchronously, so it's safe
# to Freeze() immediately and share across controls. Remote
# (http) images are intentionally NOT cached here - freezing an
# async-downloading BitmapImage is unsafe and could block the UI
# thread; WPF already serves repeat remote loads from its WinINET
# HTTP cache. Local artwork (bundled hub images) is what benefits:
# without this, each tile rebuild on an S/M/L change re-decodes
# the same file from disk.
if (-not $global:BitmapCache) { $global:BitmapCache = @{} }

function global:Get-CachedBitmap {
    param([string]$Url)
    if (-not $Url) { return $null }
    # Only cache local file URIs - see note above.
    if ($Url -notmatch '^file:') { return $null }
    if ($global:BitmapCache.ContainsKey($Url)) { return $global:BitmapCache[$Url] }
    try {
        $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmp.BeginInit()
        $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bmp.UriSource = New-Object System.Uri $Url
        $bmp.EndInit()
        if ($bmp.CanFreeze) { $bmp.Freeze() }
        $global:BitmapCache[$Url] = $bmp
        return $bmp
    } catch {
        return $null
    }
}

# --- On-disk image cache --------------------------------------------
# Steam header/portrait art is downloaded at display time. First-load
# network races sometimes leave a banner blank (it's there after a
# restart, served from the HTTP cache). To make that permanent: the
# first time art loads OK we save it to Assets\cache\, and later runs
# load the local file synchronously - no network, no race. The cache
# folder is SEPARATE from any manually-bundled Assets\*.jpg so we never
# touch hand-placed art (games with no Steam page). All four functions
# are global so they're visible from background/delegate contexts.
function global:Get-ImageCacheDir {
    $base = if ($global:scriptDir) { $global:scriptDir } else { $script:scriptDir }
    if (-not $base) { return $null }
    $dir = Join-Path $base "Assets\cache"
    if (-not (Test-Path $dir)) {
        try { New-Item -ItemType Directory -Path $dir -Force | Out-Null } catch { }
    }
    return $dir
}

# Stable per-game/per-kind cache file path. Keyed on SteamId so it
# never collides with the manual <Name>_header.jpg convention.
function global:Get-ImageCachePath {
    param([string]$SteamId, [string]$Kind)  # Kind: "header" | "portrait" | "screenshot"
    if (-not $SteamId) { return $null }
    $safeKind = switch ($Kind) {
        "portrait"   { "portrait" }
        "screenshot" { "screenshot" }
        default      { "header" }
    }
    return (Join-Path (Get-ImageCacheDir) "steam_${SteamId}_${safeKind}.jpg")
}

# If a non-empty cached file exists, return its file:// URI; else $null.
function global:Get-CachedImageUri {
    param([string]$SteamId, [string]$Kind)
    $p = Get-ImageCachePath -SteamId $SteamId -Kind $Kind
    if ($p -and (Test-Path $p)) {
        try {
            if ((Get-Item $p).Length -gt 0) {
                return ([System.Uri]$p).AbsoluteUri
            }
        } catch { }
    }
    return $null
}

# Best-effort background download of a URL into the cache file. Uses
# WebClient.DownloadFileAsync (kept referenced until done so it isn't
# GC'd mid-transfer); validates + atomically moves a .tmp into place so
# a half-written file is never a valid cache hit. No-ops if already
# cached, already local, or no SteamId.
function global:Save-ImageToCache {
    param([string]$Url, [string]$SteamId, [string]$Kind)
    if (-not $Url -or -not $SteamId) { return }
    if ($Url -match '^file:') { return }
    $dest = Get-ImageCachePath -SteamId $SteamId -Kind $Kind
    if (-not $dest) { return }
    if (Test-Path $dest) { return }
    if (-not $global:ImageCacheInFlight) { $global:ImageCacheInFlight = @{} }
    if ($global:ImageCacheInFlight.ContainsKey($dest)) { return }
    $global:ImageCacheInFlight[$dest] = $true
    if (-not $global:ImageCacheClients) {
        $global:ImageCacheClients = New-Object System.Collections.ArrayList
    }
    $tmp = "$dest.tmp"
    try {
        $wc = New-Object System.Net.WebClient
        [void]$global:ImageCacheClients.Add($wc)
        $destCap = $dest
        $tmpCap  = $tmp
        $wcCap   = $wc
        $wc.add_DownloadFileCompleted({
            param($s, $e)
            try {
                if (-not $e.Error -and -not $e.Cancelled -and
                    (Test-Path $tmpCap) -and ((Get-Item $tmpCap).Length -gt 0)) {
                    Move-Item -Path $tmpCap -Destination $destCap -Force
                } else {
                    Remove-Item $tmpCap -ErrorAction SilentlyContinue
                }
            } catch {
                try { Remove-Item $tmpCap -ErrorAction SilentlyContinue } catch { }
            } finally {
                try { $global:ImageCacheInFlight.Remove($destCap) } catch { }
                try { [void]$global:ImageCacheClients.Remove($wcCap); $wcCap.Dispose() } catch { }
            }
        }.GetNewClosure())
        $wc.DownloadFileAsync((New-Object System.Uri $Url), $tmp)
    } catch {
        try { $global:ImageCacheInFlight.Remove($dest) } catch { }
        try { Remove-Item $tmp -ErrorAction SilentlyContinue } catch { }
    }
}

# Warm the on-disk image cache in ONE background runspace. Called once
# after the window renders. We compute the work list on the UI thread
# (which games, which dest files are missing, which URLs to try) and
# hand the runspace a plain array of @{ Dest; Urls } items plus nothing
# else - no UI objects, no callbacks, no shared scope. The runspace
# tries each URL until one downloads, writes via .tmp -> move, and
# exits. This is the deliberately-decoupled design: the earlier crash
# came from a WebClient async event handler firing a PowerShell
# scriptblock on a foreign thread; here there is no such handler.
function global:Start-ImageCacheWarm {
    param([object[]]$Games)
    if (-not $Games -or $Games.Count -eq 0) { return }
    $cacheDir = Get-ImageCacheDir
    if (-not $cacheDir) { return }

    # Build the work list on the UI thread (cheap: path/Test-Path only).
    $work = New-Object System.Collections.ArrayList
    foreach ($g in $Games) {
        if (-not $g.SteamId) { continue }
        $sid = [string]$g.SteamId
        foreach ($kind in @("header", "portrait")) {
            $dest = Get-ImageCachePath -SteamId $sid -Kind $kind
            if (-not $dest) { continue }
            if (Test-Path $dest) { continue }   # already cached
            if ($kind -eq "header") {
                $urls = @(
                    (Get-SteamHeaderUrl $sid),
                    (Get-SteamHeaderUrlFastly $sid)
                )
            } else {
                $urls = @(
                    (Get-SteamPortraitUrl $sid),
                    (Get-SteamPortraitUrlFastly $sid)
                )
            }
            [void]$work.Add(@{ Dest = $dest; Urls = $urls })
        }
    }

    # Second work list: store-info (short description + screenshot).
    # Include any SteamId we don't have a REAL description for yet -
    # that's "never fetched" OR "fetched but came back null" (transient
    # failure, or the earlier buggy run that wrote all-null). The
    # runspace caps retries per id via a tries-counter so a game with
    # genuinely no store page isn't hit forever. An id with a real
    # cached description is skipped here.
    $infoIds = New-Object System.Collections.ArrayList
    foreach ($g in $Games) {
        if (-not $g.SteamId) { continue }
        $sid = [string]$g.SteamId
        if ($global:SteamDescCache.ContainsKey($sid) -and $global:SteamDescCache[$sid]) { continue }
        if ($infoIds -notcontains $sid) { [void]$infoIds.Add($sid) }
    }
    $infoJsonPath = Join-Path $cacheDir "steam_info.json"

    if ($work.Count -eq 0 -and $infoIds.Count -eq 0) { return }

    # The runspace script: pure data in, files out. No host scope.
    $script = {
        param($items, $infoIds, $infoJsonPath)
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = `
                [System.Net.SecurityProtocolType]::Tls12 -bor `
                [System.Net.SecurityProtocolType]::Tls11 -bor `
                [System.Net.SecurityProtocolType]::Tls
        } catch { }
        foreach ($it in $items) {
            $dest = $it.Dest
            $tmp  = "$dest.tmp"
            if (Test-Path $dest) { continue }
            foreach ($u in $it.Urls) {
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.DownloadFile($u, $tmp)
                    $wc.Dispose()
                    if ((Test-Path $tmp) -and ((Get-Item $tmp).Length -gt 0)) {
                        Move-Item -Path $tmp -Destination $dest -Force
                        break
                    } else {
                        Remove-Item $tmp -ErrorAction SilentlyContinue
                    }
                } catch {
                    try { Remove-Item $tmp -ErrorAction SilentlyContinue } catch { }
                }
            }
        }

        # Store-info pass: fetch /appdetails for the missing ids. For
        # each, also download its screenshot into the local cache right
        # away (we only have the screenshot URL AFTER this fetch - that's
        # why info must be fetched before the screenshot file is saved).
        # Merge into a fresh read of the json, flushed incrementally.
        if ($infoIds -and $infoIds.Count -gt 0 -and $infoJsonPath) {
            $cacheDir = [System.IO.Path]::GetDirectoryName($infoJsonPath)
            $store = @{}
            if (Test-Path $infoJsonPath) {
                try {
                    $existing = (Get-Content $infoJsonPath -Raw) | ConvertFrom-Json
                    foreach ($p in $existing.PSObject.Properties) {
                        $t = 0
                        if ($p.Value.tries) { $t = [int]$p.Value.tries }
                        $store[$p.Name] = @{ desc = $p.Value.desc; shot = $p.Value.shot; tries = $t }
                    }
                } catch { }
            }
            $changed = $false
            $flushCount = 0
            foreach ($sid in $infoIds) {
                # Self-healing: keep a real description if we have one;
                # retry missing/null entries, capped at 3 tries so a
                # game with genuinely no store page isn't hit forever.
                if ($store.ContainsKey($sid)) {
                    $cur = $store[$sid]
                    if ($cur.desc) { continue }
                    $curTries = 0
                    if ($cur.tries) { $curTries = [int]$cur.tries }
                    if ($curTries -ge 3) { continue }
                }
                $d = $null; $s = $null
                $hit429 = $false
                try {
                    $url = "https://store.steampowered.com/api/appdetails?appids=$sid&l=english"
                    # Same method proven reliable in the main-process
                    # fetch: Invoke-RestMethod + direct $resp.$sid access.
                    $resp = Invoke-RestMethod -Uri $url -TimeoutSec 8 -ErrorAction Stop
                    $entry = $resp.$sid
                    if ($entry -and $entry.success -and $entry.data) {
                        $data = $entry.data
                        if ($data.short_description) {
                            $d = [System.Net.WebUtility]::HtmlDecode($data.short_description)
                        }
                        if ($data.screenshots -and $data.screenshots.Count -gt 0) {
                            $s = $data.screenshots[0].path_thumbnail
                        }
                    }
                } catch {
                    # If Steam rate-limited us (429), back off hard so the
                    # background warm stops competing with the user. A
                    # user opening a game gets priority on the rate budget.
                    if ("$($_)" -match '429') { $hit429 = $true }
                }
                # Download the screenshot into the local cache so the
                # description panel image works offline next launch.
                if ($s -and $cacheDir) {
                    try {
                        $shotDest = Join-Path $cacheDir "steam_${sid}_screenshot.jpg"
                        if (-not (Test-Path $shotDest)) {
                            $shotTmp = "$shotDest.tmp"
                            $swc = New-Object System.Net.WebClient
                            $swc.DownloadFile($s, $shotTmp)
                            $swc.Dispose()
                            if ((Test-Path $shotTmp) -and ((Get-Item $shotTmp).Length -gt 0)) {
                                Move-Item -Path $shotTmp -Destination $shotDest -Force
                            } else {
                                Remove-Item $shotTmp -ErrorAction SilentlyContinue
                            }
                        }
                    } catch {
                        try { Remove-Item $shotTmp -ErrorAction SilentlyContinue } catch { }
                    }
                }
                $prevTries = 0
                if ($store.ContainsKey($sid) -and $store[$sid].tries) {
                    $prevTries = [int]$store[$sid].tries
                }
                if ($d) {
                    $store[$sid] = @{ desc = $d; shot = $s; tries = 0 }
                } elseif ($hit429) {
                    # Rate-limited, not the game's fault - keep the entry
                    # absent/unchanged so it's retried, don't burn a try.
                    if (-not $store.ContainsKey($sid)) {
                        # leave it out entirely so a later pass retries it
                    }
                } else {
                    $store[$sid] = @{ desc = $null; shot = $s; tries = ($prevTries + 1) }
                }
                $changed = $true
                $flushCount = ($flushCount + 1)
                # Flush the json periodically so it exists/grows during
                # the pass (not only at the very end) - survives an
                # early check or the Hub closing mid-pass.
                if (($flushCount % 10) -eq 0) {
                    try {
                        $tmpJson = "$infoJsonPath.tmp"
                        ($store | ConvertTo-Json -Depth 4 -Compress) |
                            Set-Content -Path $tmpJson -Encoding UTF8
                        Move-Item -Path $tmpJson -Destination $infoJsonPath -Force
                    } catch { }
                }
                if ($hit429) {
                    Start-Sleep -Milliseconds 5000   # back off hard, yield to user clicks
                } else {
                    Start-Sleep -Milliseconds 600    # gentle steady pace
                }
            }
            if ($changed) {
                try {
                    $tmpJson = "$infoJsonPath.tmp"
                    ($store | ConvertTo-Json -Depth 4 -Compress) |
                        Set-Content -Path $tmpJson -Encoding UTF8
                    Move-Item -Path $tmpJson -Destination $infoJsonPath -Force
                } catch { }
            }
        }
    }

    try {
        $ps = [PowerShell]::Create()
        [void]$ps.AddScript($script).AddArgument($work.ToArray()).AddArgument($infoIds.ToArray()).AddArgument($infoJsonPath)
        # Keep a reference so the runspace isn't collected mid-run; the
        # async result is fire-and-forget (we never read it back).
        if (-not $global:ImageWarmPS) { $global:ImageWarmPS = New-Object System.Collections.ArrayList }
        [void]$global:ImageWarmPS.Add($ps)
        [void]$ps.BeginInvoke()
    } catch { }
}

# Internal helper: do a single /appdetails fetch and seed both
# caches. Idempotent. IMPORTANT: distinguishes a genuine "no data"
# (Steam says success=false -> cache null, don't refetch) from a
# TRANSIENT failure (429 rate-limit while the background warm is
# hammering Steam, timeout, network blip -> do NOT cache, so the
# next time the user opens this game it tries again). Caching a
# transient failure as null was why some games stayed blank even
# after reconnecting.
function global:_Steam-FetchAppDetails {
    param([string]$SteamId)
    if (-not $SteamId) { return }
    if ($global:SteamDescCache.ContainsKey($SteamId)) { return }
    # This fetch runs SYNCHRONOUSLY on the UI thread when a detail page
    # opens before the background warm has cached this id. Two guards keep
    # a dead network from freezing every page open:
    #   1. Respect the scan-wide circuit breaker - if online checks already
    #      failed this scan, don't try Steam either.
    #   2. Steam-wide cooldown - after ONE transient failure, skip all
    #      Steam detail fetches for 60s. Worst case is a single 4s wait
    #      per minute across ALL detail pages (instead of 2x4s per page).
    # Skipped pages simply show no description/screenshot yet; the
    # background warm (or a later open) fills them in - shown later, never
    # frozen now.
    if ($global:HubScanOnlineDown) { return }
    if ($global:SteamFetchDownUntil -and ([DateTime]::UtcNow -lt $global:SteamFetchDownUntil)) { return }
    try {
        $url = "https://store.steampowered.com/api/appdetails?appids=$SteamId&l=english"
        $resp = Invoke-RestMethod -Uri $url -TimeoutSec 4 -ErrorAction Stop
        $entry = $resp.$SteamId
        if ($entry -and $entry.success -and $entry.data) {
            $data = $entry.data
            $desc = $null
            if ($data.short_description) {
                $desc = [System.Net.WebUtility]::HtmlDecode($data.short_description)
            }
            $global:SteamDescCache[$SteamId] = $desc
            $shotUrl = $null
            if ($data.screenshots -and $data.screenshots.Count -gt 0) {
                # First screenshot tends to be representative
                $shotUrl = $data.screenshots[0].path_thumbnail
            }
            $global:SteamScreenshotCache[$SteamId] = $shotUrl
        } else {
            # Steam responded but reports no usable data for this app
            # (private depot, delisted, etc.) - cache null so we don't
            # keep asking for something that genuinely has nothing.
            $global:SteamDescCache[$SteamId] = $null
            $global:SteamScreenshotCache[$SteamId] = $null
        }
    } catch {
        # Transient failure (429/timeout/network). Do NOT cache the id -
        # leave the entry absent so a later open retries once Steam
        # recovers - but arm the 60s cooldown so the very next page open
        # doesn't eat another synchronous timeout on the UI thread.
        $global:SteamFetchDownUntil = [DateTime]::UtcNow.AddSeconds(60)
    }
}

# True if the free DOS Daggerfall (Steam app 1812390) is present on disk -
# either via its Steam appmanifest or the actual DAGGER.exe game files.
# Daggerfall Unity (and our VR build) reads this original 1996 game data.
# Used to suppress the "you'll need Daggerfall installed first" hint when
# the player already has it: the VR build lives in a SEPARATE folder, so
# the normal install-state scan (which looks at the mod folder) never sees
# the base game.
function global:Test-DosDaggerfallOnDisk {
    $steam = $null
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { $steam = $p; break } } catch {}
    }
    if (-not $steam) { return $false }
    $libs = @($steam)
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        try {
            $content = Get-Content $vdf -Raw
            foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace '\\\\', '\'
                if (Test-Path $p) { $libs += $p }
            }
        } catch {}
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        if (Test-Path (Join-Path $lib "steamapps\appmanifest_1812390.acf")) { return $true }
        if (Test-Path (Join-Path $lib "steamapps\common\The Elder Scrolls Daggerfall\DF\DAGGER\DAGGER.exe")) { return $true }
    }
    return $false
}

# Fetch the short Steam store description for an app id. Returns
# $null if no SteamId or the request fails.
function global:Get-SteamShortDescription {
    param([string]$SteamId)
    if (-not $SteamId) { return $null }
    _Steam-FetchAppDetails -SteamId $SteamId
    return $global:SteamDescCache[$SteamId]
}

# Fetch a representative screenshot URL (the first one Steam
# returns) for the given app id. Returns $null if unavailable.
function global:Get-SteamScreenshot {
    param([string]$SteamId)
    if (-not $SteamId) { return $null }
    _Steam-FetchAppDetails -SteamId $SteamId
    return $global:SteamScreenshotCache[$SteamId]
}

# Resolve which image URL to load for a game's portrait/header.
# Priority:
#   1. PortraitUrl / HeaderUrl on the game definition (manual override)
#   2. Steam default if SteamId set
#   3. $null - caller must handle (fall back to title placeholder)
# A LocalImage path resolves to a file:// URI rooted at $script:scriptDir,
# letting us bundle hub-side artwork (e.g. for tools that have no Steam page).
function global:Get-GameImageUrl {
    param($Game, [string]$Kind)  # Kind: "portrait" | "header"
    $override = $null
    if ($Kind -eq "portrait") {
        $override = $Game.PortraitUrl
    } else {
        $override = $Game.HeaderUrl
    }
    if ($override) {
        if ($override -match '^https?://') { return $override }
        # Relative path: resolve against script root and convert to file:// URI
        $abs = Join-Path $script:scriptDir $override
        if (Test-Path $abs) {
            return ([System.Uri]$abs).AbsoluteUri
        }
        # Fall through if file missing - try Steam next
    }
    if ($Game.SteamId) {
        if ($Kind -eq "portrait") {
            return (Get-SteamPortraitUrl $Game.SteamId)
        } else {
            return (Get-SteamHeaderUrl $Game.SteamId)
        }
    }
    return $null
}

# Tear down the currently-enlarged card. Disposes the
# MediaElement so the network stream is closed.
function global:End-CardPreview {
    if ($global:HoverMediaElement) {
        try { $global:HoverMediaElement.Stop()  } catch { }
        try { $global:HoverMediaElement.Close() } catch { }
        $global:HoverMediaElement.Source = $null
        $global:HoverMediaElement = $null
    }
    if ($global:HoverActiveCard) {
        $card = $global:HoverActiveCard
        $previewHost = $card.Resources.Item("previewHost")
        if ($previewHost) {
            $previewHost.Visibility = [System.Windows.Visibility]::Collapsed
            $img = $card.Resources.Item("previewImage")
            if ($img) { $img.Source = $null }
        }
        # Restore the elements we hid behind the preview image
        $famPill = $card.Resources.Item("famPill")
        if ($famPill) { $famPill.Visibility = [System.Windows.Visibility]::Visible }
        $infoPill = $card.Resources.Item("infoPill")
        if ($infoPill) { $infoPill.Visibility = [System.Windows.Visibility]::Visible }
        $authorText = $card.Resources.Item("authorText")
        if ($authorText) { $authorText.Visibility = [System.Windows.Visibility]::Visible }
        $modText = $card.Resources.Item("modText")
        if ($modText) { $modText.Visibility = [System.Windows.Visibility]::Visible }
        $addonBanner = $card.Resources.Item("addonBanner")
        if ($addonBanner) { $addonBanner.Visibility = [System.Windows.Visibility]::Visible }

        $card.RenderTransform = $null
        [System.Windows.Controls.Panel]::SetZIndex($card, 0)
        $card.Effect = $card.Resources.Item("savedEffect")
        $card.Resources.Remove("savedEffect") | Out-Null
        $global:HoverActiveCard = $null
    }
}

function global:Start-CardPreview {
    param($Card)
    if ($Card -eq $global:HoverActiveCard) { return }
    End-CardPreview

    $hdrUrl = $Card.Resources.Item("previewHeaderUrl")
    if (-not $hdrUrl) { return }
    # Prefer the locally cached header if the background cache-warm has
    # written it since this card was built. previewHeaderUrl was frozen
    # at card-creation time - before the warm finished - so it can still
    # point at a CDN URL (akamai) that WPF fails to load, even though the
    # detail page (which re-resolves at open time) now loads cleanly from
    # the cache. Re-resolving here makes the hover behave like the detail
    # page. Only for Steam-image games (previewSteamId is null for cards
    # with a bundled HeaderUrl, e.g. Halo CE, so their art is untouched).
    $hoverSidEarly = $Card.Resources.Item("previewSteamId")
    if ($hoverSidEarly) {
        try {
            $cachedHover = Get-CachedImageUri -SteamId $hoverSidEarly -Kind "header"
            if ($cachedHover) { $hdrUrl = $cachedHover }
        } catch { }
    }
    $hasVideo = [bool]$Card.Resources.Item("hasVideo")

    if ($Card.Resources.Contains("savedEffect")) { $Card.Resources.Remove("savedEffect") }
    $Card.Resources.Add("savedEffect", $Card.Effect)
    $Card.Effect = $null

    # Hide overlays that the steam image would otherwise cover/cut.
    # Restored in End-CardPreview.
    $famPill = $Card.Resources.Item("famPill")
    if ($famPill) { $famPill.Visibility = [System.Windows.Visibility]::Hidden }
    $infoPill = $Card.Resources.Item("infoPill")
    if ($infoPill) { $infoPill.Visibility = [System.Windows.Visibility]::Hidden }
    $authorText = $Card.Resources.Item("authorText")
    if ($authorText) { $authorText.Visibility = [System.Windows.Visibility]::Hidden }
    # modText is stashed for Jedi Knight + 15 long-title games
    # whose wrapped titles push the mod version under the preview
    # image. Hidden = slot is preserved.
    $modText = $Card.Resources.Item("modText")
    if ($modText) { $modText.Visibility = [System.Windows.Visibility]::Hidden }
    # Same for the addon banner (HL2VR + Unleashed family); without
    # this the blue "+ add-on" pill clips through the preview image.
    $addonBanner = $Card.Resources.Item("addonBanner")
    if ($addonBanner) { $addonBanner.Visibility = [System.Windows.Visibility]::Hidden }

    $scale = New-Object System.Windows.Media.ScaleTransform 1.4, 1.4
    $Card.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
    $Card.RenderTransform = $scale
    [System.Windows.Controls.Panel]::SetZIndex($Card, 1000)

    $shadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $shadow.Color = [System.Windows.Media.Color]::FromRgb(0,0,0)
    $shadow.BlurRadius = 24
    $shadow.ShadowDepth = 6
    $shadow.Opacity = 0.6
    $Card.Effect = $shadow

    $previewHost = $Card.Resources.Item("previewHost")
    if ($previewHost) {
        $previewHost.Visibility = [System.Windows.Visibility]::Visible
        $img = $Card.Resources.Item("previewImage")
        if ($img) {
            try {
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.UriSource = New-Object System.Uri $hdrUrl
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                # Mirror the detail hero's fallback chain so a game whose
                # header.jpg fails on BOTH CDNs still shows something on
                # hover instead of a blank banner: fastly header ->
                # portrait -> one retry at the primary URL.
                $hoverSid     = $Card.Resources.Item("previewSteamId")
                $hoverPortrait = $Card.Resources.Item("previewPortraitUrl")
                # Cache-first portrait too (the akamai portrait URL frozen
                # at card creation can fail the same way the header does).
                if ($hoverSid) {
                    try {
                        $cachedPort = Get-CachedImageUri -SteamId $hoverSid -Kind "portrait"
                        if ($cachedPort) { $hoverPortrait = $cachedPort }
                    } catch { }
                }
                $hdrUrlCap    = $hdrUrl
                $imgRef   = $img
                $bmp.Add_DownloadFailed({
                    param($s, $e)
                    # 1) Fastly header (akamai sometimes 404s/hiccups)
                    if ($hoverSid) {
                        try {
                            $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                            $hb.BeginInit()
                            $hb.UriSource = New-Object System.Uri (Get-SteamHeaderUrlFastly $hoverSid)
                            $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                            $hb.EndInit()
                            $imgRef.Source = $hb
                            return
                        } catch { }
                    }
                    # 2) Portrait - what the detail page falls back to
                    if ($hoverPortrait) {
                        try {
                            $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                            $hb.BeginInit()
                            $hb.UriSource = New-Object System.Uri $hoverPortrait
                            $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                            $hb.EndInit()
                            $imgRef.Source = $hb
                            return
                        } catch { }
                    }
                    # 3) One retry at the primary URL (transient TLS/CDN)
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hb.UriSource = New-Object System.Uri $hdrUrlCap
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        $hb.EndInit()
                        $imgRef.Source = $hb
                    } catch { }
                }.GetNewClosure())
                $bmp.EndInit()
                $img.Source = $bmp
            } catch { }
        }
        # Trailer playback in hover preview is disabled - see comment
        # in Show-DiscoverDetail. Steam moved to per-game hashed .webm
        # URLs that WPF MediaElement cannot decode anyway.
    }
    $global:HoverActiveCard = $Card
}

# -------------------------------------------------------
# Read game-specific README from disk and split into
# sections (## headings). Returns hashtable of section
# name -> body string. Empty hashtable if file missing.
# Used by the Discover detail view.
# -------------------------------------------------------
function global:Read-GameReadme {
    param($Game)
    $sections = [ordered]@{}
    # Resolve the folder that may contain a README. Two cases:
    #   1) Regular games with a Bat field -> README sits next to the
    #      installer .bat / .ps1
    #   2) External games (Type=steam) without a Bat but with an
    #      AddonInstaller -> README sits in the addon folder. Used
    #      for the HL2VR family which gets its README from the
    #      HL2VRU folder so all three cards (base + Ep1 + Ep2)
    #      surface the same combined info on their detail pages.
    $modDir = $null
    if ($Game.Bat) {
        $batPath = Join-Path $script:scriptDir $Game.Bat
        $modDir  = Split-Path -Parent $batPath
    } elseif ($Game.AddonInstaller) {
        $addonPath = Join-Path $script:scriptDir $Game.AddonInstaller
        $modDir    = Split-Path -Parent $addonPath
    } elseif ($Game.ReadmeDir) {
        # Guide-only entries (e.g. Wabbajack modlists) have no
        # installer but still ship a README in a dedicated folder.
        $modDir = Join-Path $script:scriptDir $Game.ReadmeDir
    }
    if (-not $modDir -or -not (Test-Path $modDir)) { return $sections }
    $readme = Get-ChildItem -Path $modDir -Filter "README*.md" -ErrorAction SilentlyContinue |
              Select-Object -First 1
    if (-not $readme) { return $sections }
    try {
        $raw = Get-Content $readme.FullName -Raw -Encoding UTF8
    } catch { return $sections }
    # Stash the README's folder so callers can resolve relative
    # image paths like ![alt](ControllerLayout.webp) to absolute
    # ones during rendering.
    $sections["_baseDir"] = $modDir
    # Split on lines that begin with "## " (h2). The first chunk
    # before any h2 is the tagline; we record it under "_tagline".
    $lines = $raw -split "`r?`n"
    $current = "_tagline"
    $buffer = New-Object System.Collections.ArrayList
    $inFence = $false
    foreach ($line in $lines) {
        # Track code fences so that '##' comment lines INSIDE a fenced
        # config block aren't mistaken for section headings (which would
        # tear the block apart).
        if ($line -match '^\s*```') {
            $inFence = -not $inFence
            [void]$buffer.Add($line)
            continue
        }
        if (-not $inFence -and $line -match '^\s*>>>\s?(.*)$') {
            # Flavour quip: pull it out into its own key so it is
            # always rendered as the closing accent box, regardless of
            # which (possibly skipped, e.g. "More info") section it
            # textually sits under in the markdown.
            $sections["_quip"] = $matches[1].Trim()
            continue
        }
        if (-not $inFence -and $line -match '^##\s+(.+)$') {
            if ($buffer.Count -gt 0) {
                $sections[$current] = ($buffer -join "`n").Trim()
            }
            $current = $matches[1].Trim()
            $buffer = New-Object System.Collections.ArrayList
        } elseif (-not $inFence -and $line -match '^#\s+') {
            # Skip the h1 title line entirely (we already have $Game.Title)
            continue
        } else {
            [void]$buffer.Add($line)
        }
    }
    if ($buffer.Count -gt 0) {
        $sections[$current] = ($buffer -join "`n").Trim()
    }
    return $sections
}

# -------------------------------------------------------
# Color helpers

# -------------------------------------------------------
# Color helpers: derive tinted card backgrounds, family pill
# colors, and brushes used for the new visual states.
# All helpers stay self-contained - no globals, no caches -
# so callers can rebuild brushes any time without side-effects.
# -------------------------------------------------------

# Convert hex string ("#rrggbb") to a System.Windows.Media.Color.
# Returns black-with-zero-alpha if parsing fails (defensive).
function global:ConvertTo-MediaColor {
    param([string]$Hex)
    try {
        return [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    } catch {
        return [System.Windows.Media.Color]::FromArgb(0,0,0,0)
    }
}

# Returns a glow-safe version of an accent colour. Very dark accents
# (e.g. Iron Lung's deep red #aa3333) produce a glow that's invisible
# against the dark card background. If the colour's perceived
# brightness is below a threshold we lighten it toward white just
# enough to read as a halo, while keeping its hue. Bright accents are
# returned unchanged. Always returns a System.Windows.Media.Color.
function global:Get-GlowColor {
    param([string]$Hex)
    $c = ConvertTo-MediaColor $Hex
    try {
        # Perceived luminance (Rec. 601).
        $lum = (0.299 * $c.R) + (0.587 * $c.G) + (0.114 * $c.B)
        $minLum = 140.0
        if ($lum -lt $minLum -and $lum -gt 0) {
            # Scale the channels up so luminance reaches the floor,
            # then clamp. Keeps the hue ratio, just brighter.
            $factor = $minLum / $lum
            $r = [int][math]::Min(255, $c.R * $factor)
            $g = [int][math]::Min(255, $c.G * $factor)
            $b = [int][math]::Min(255, $c.B * $factor)
            return [System.Windows.Media.Color]::FromRgb($r, $g, $b)
        }
    } catch {}
    return $c
}

# Attach a "shine sweep" hover effect to any clickable Border.
# The sweep reads whatever the button's Background looks like at
# MouseEnter time (so it adapts to install/update/VR-Ready/etc
# state without knowing about them) and animates a brighter band
# diagonally across. On MouseLeave the original background is
# restored exactly - this never causes a permanent color change.
#
# Skip cases (helper bails out, leaves button untouched):
#   - Background is null (no fill to sweep over)
#   - Background is a non-SolidColorBrush (already a gradient -
#     someone else is animating, don't fight)
#   - Button is disabled (IsEnabled false)
#
# If the same button has its own MouseEnter handler that does
# state-aware work (e.g. the Install card-button which also pulses
# the accent cap), that handler should run AFTER subscribing to
# this so it can override the simple sweep with its richer one.
# The Install button keeps its bespoke version; this helper is
# for everywhere else.
function global:Add-SweepHover {
    param(
        [System.Windows.Controls.Border]$Border,
        [int]$DurationMs = 700,
        # Peak intensity = how much white-mix the sweep introduces.
        # 0.18 reads as a soft shine on dark buttons; 0.30 is more
        # noticeable on mid-tones; 0.45 is for transparent/very
        # dark fills where you want a clear band.
        [double]$PeakMix = 0.22
    )
    if (-not $Border) { return }

    $Border.Add_MouseEnter({
        if (-not $this.IsEnabled) { return }
        $bg = $this.Background
        if (-not $bg) { return }
        # Only sweep over solid colors. If something else has
        # already painted a gradient (custom hover, in-flight
        # animation), don't compete.
        if (-not ($bg -is [System.Windows.Media.SolidColorBrush])) { return }

        $base = $bg.Color
        # Peak: same color shifted toward white. The mix amount
        # is read from a per-button override if present, else
        # from a sensible default.
        $mix = if ($this.Resources.Contains("sweepPeakMix")) {
            [double]$this.Resources.Item("sweepPeakMix")
        } else { 0.22 }
        $peak = [System.Windows.Media.Color]::FromArgb(
            $base.A,
            [byte]([Math]::Min(255, [int]([Math]::Round($base.R + (255 - $base.R) * $mix)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($base.G + (255 - $base.G) * $mix)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($base.B + (255 - $base.B) * $mix))))
        )

        # Stash the resting brush. Key is namespaced so it can't
        # collide with the Install button's own preHoverBrush
        # which uses the same string; this helper is registered
        # via "swvBrush" only.
        if ($this.Resources.Contains("swvBrush")) {
            $this.Resources.Remove("swvBrush") | Out-Null
        }
        $this.Resources.Add("swvBrush", $bg)

        # Build the five-stop sweep: two outer anchors at base
        # color, three inner stops (lead/peak/tail) animated.
        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object System.Windows.Point 0, 0
        $brush.EndPoint   = New-Object System.Windows.Point 1, 1
        $sOutA = New-Object System.Windows.Media.GradientStop $base, 0.0
        $sLead = New-Object System.Windows.Media.GradientStop $base, 0.0
        $sPeak = New-Object System.Windows.Media.GradientStop $peak, 0.0
        $sTail = New-Object System.Windows.Media.GradientStop $base, 0.0
        $sOutB = New-Object System.Windows.Media.GradientStop $base, 1.0
        $brush.GradientStops.Add($sOutA) | Out-Null
        $brush.GradientStops.Add($sLead) | Out-Null
        $brush.GradientStops.Add($sPeak) | Out-Null
        $brush.GradientStops.Add($sTail) | Out-Null
        $brush.GradientStops.Add($sOutB) | Out-Null
        $this.Background = $brush

        $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
        if ($this.Resources.Contains("sweepDuration")) {
            $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds([int]$this.Resources.Item("sweepDuration")))
        }
        $aLead = New-Object System.Windows.Media.Animation.DoubleAnimation -0.35, 1.05, $dur
        $aPeak = New-Object System.Windows.Media.Animation.DoubleAnimation -0.20, 1.20, $dur
        $aTail = New-Object System.Windows.Media.Animation.DoubleAnimation -0.05, 1.35, $dur
        $sLead.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aLead)
        $sPeak.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aPeak)
        $sTail.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aTail)
    })

    $Border.Add_MouseLeave({
        # Restore exactly what was there on Enter. If nothing
        # was stashed, leave the button alone - means MouseEnter
        # bailed out (disabled / null bg / non-solid brush) and
        # we have no business changing anything now.
        if ($this.Resources.Contains("swvBrush")) {
            $orig = $this.Resources.Item("swvBrush")
            if ($orig) { $this.Background = $orig }
            $this.Resources.Remove("swvBrush") | Out-Null
        }
    })
}

# Soft glow hover for state-aware buttons (filter pills, nav).
# Unlike Add-SweepHover, the *background* is left untouched - that
# matters for filters where bg encodes active/inactive state. We
# only flip the border to the accent color and brighten the text
# and any inline icons (Paths) inside the button. On leave we
# restore exactly what we stashed, so no permanent drift even if
# the button's state changed mid-hover.
function global:Add-GlowHover {
    param(
        [System.Windows.Controls.Border]$Border,
        # Accent for the hover-border. Default is the Hub's
        # ambient grey-purple - filters can pass their own.
        [string]$AccentHex = "#5566aa",
        # Optional: hex of the background that means "already
        # active/selected". When the button currently has this
        # background, the glow MouseEnter is skipped entirely.
        # Used for toggle-groups like S/M/L where active state is
        # bg-encoded and we don't want to glow over a selection.
        [string]$SkipWhenBgIs = $null
    )
    if (-not $Border) { return }

    # Walk the visual tree of the button and pick out the things
    # we want to brighten on hover. Returns @{TextBlocks=@(); Paths=@()}.
    $collectChildren = {
        param($root)
        $tbs = New-Object System.Collections.ArrayList
        $paths = New-Object System.Collections.ArrayList
        $shapes = New-Object System.Collections.ArrayList
        $stack = New-Object System.Collections.Stack
        $stack.Push($root)
        while ($stack.Count -gt 0) {
            $node = $stack.Pop()
            if ($node -is [System.Windows.Controls.TextBlock]) {
                [void]$tbs.Add($node)
            } elseif ($node -is [System.Windows.Shapes.Path]) {
                [void]$paths.Add($node)
            } elseif ($node -is [System.Windows.Shapes.Shape]) {
                # Other Shape subclasses (Ellipse, Rectangle, Line)
                # use Fill instead of Stroke for their visible color.
                # DiscoverBtn's icon-dots are Ellipses. Path is its
                # own branch above because it commonly uses Stroke.
                [void]$shapes.Add($node)
            }
            if ($node -is [System.Windows.Controls.Panel]) {
                foreach ($child in $node.Children) { $stack.Push($child) }
            } elseif ($node -is [System.Windows.Controls.Border]) {
                if ($node.Child) { $stack.Push($node.Child) }
            } elseif ($node -is [System.Windows.Controls.Canvas]) {
                # Canvas is a Panel subclass, but include it
                # explicitly here so the iteration stays correct
                # if Panel-detection misses for any reason.
                foreach ($child in $node.Children) { $stack.Push($child) }
            }
        }
        return @{ TextBlocks = $tbs; Paths = $paths; Shapes = $shapes }
    }

    $Border.Add_MouseEnter({
        if (-not $this.IsEnabled) { return }
        # Skip when the button is already in its "active" state -
        # caller passes a SkipWhenBgIs hex; if the current bg
        # matches, the glow would compete with the selection
        # signal. We compare by RGB bytes, not by brush identity:
        # a freshly-converted brush from the same hex is a different
        # instance.
        $skipHex = $this.Resources.Item("ghSkipBg")
        if ($skipHex -and ($this.Background -is [System.Windows.Media.SolidColorBrush])) {
            try {
                $skipCol = [System.Windows.Media.ColorConverter]::ConvertFromString($skipHex)
                $cur = $this.Background.Color
                if ($cur.R -eq $skipCol.R -and $cur.G -eq $skipCol.G -and $cur.B -eq $skipCol.B) {
                    return
                }
            } catch {}
        }

        # Stash so MouseLeave can restore. Border thickness is NOT
        # touched - layout shifts ripple through the whole row and
        # cause neighboring buttons to jitter. Callers must give
        # their button a 1px transparent border in XAML so this
        # helper only flips BorderBrush.
        if ($this.Resources.Contains("ghBdBrush")) { $this.Resources.Remove("ghBdBrush") | Out-Null }
        $this.Resources.Add("ghBdBrush", $this.BorderBrush)

        $accent = $this.Resources.Item("ghAccentHex")
        if (-not $accent) { $accent = "#5566aa" }
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)

        # Brighten all text, stroke-paths and shape fills. Stash
        # originals on each element so restore can find them later.
        $collected = & $this.Resources.Item("ghCollect") $this
        foreach ($tb in $collected.TextBlocks) {
            if (-not $tb.Resources.Contains("ghFg")) {
                $tb.Resources.Add("ghFg", $tb.Foreground)
            }
            $tb.Foreground = [System.Windows.Media.Brushes]::White
        }
        foreach ($p in $collected.Paths) {
            if (-not $p.Resources.Contains("ghStroke")) {
                $p.Resources.Add("ghStroke", $p.Stroke)
            }
            $p.Stroke = [System.Windows.Media.Brushes]::White
        }
        foreach ($s in $collected.Shapes) {
            if (-not $s.Resources.Contains("ghFill")) {
                $s.Resources.Add("ghFill", $s.Fill)
            }
            $s.Fill = [System.Windows.Media.Brushes]::White
        }
    })

    $Border.Add_MouseLeave({
        if ($this.Resources.Contains("ghBdBrush")) {
            $orig = $this.Resources.Item("ghBdBrush")
            if ($orig) { $this.BorderBrush = $orig }
            $this.Resources.Remove("ghBdBrush") | Out-Null
        }

        $collected = & $this.Resources.Item("ghCollect") $this
        foreach ($tb in $collected.TextBlocks) {
            if ($tb.Resources.Contains("ghFg")) {
                $orig = $tb.Resources.Item("ghFg")
                if ($orig) { $tb.Foreground = $orig }
                $tb.Resources.Remove("ghFg") | Out-Null
            }
        }
        foreach ($p in $collected.Paths) {
            if ($p.Resources.Contains("ghStroke")) {
                $orig = $p.Resources.Item("ghStroke")
                if ($orig) { $p.Stroke = $orig }
                $p.Resources.Remove("ghStroke") | Out-Null
            }
        }
        foreach ($s in $collected.Shapes) {
            if ($s.Resources.Contains("ghFill")) {
                $orig = $s.Resources.Item("ghFill")
                if ($orig) { $s.Fill = $orig }
                $s.Resources.Remove("ghFill") | Out-Null
            }
        }
    })

    # Persist collector + accent + skip-bg on the button so closures find them.
    if ($Border.Resources.Contains("ghCollect")) { $Border.Resources.Remove("ghCollect") | Out-Null }
    if ($Border.Resources.Contains("ghAccentHex")) { $Border.Resources.Remove("ghAccentHex") | Out-Null }
    if ($Border.Resources.Contains("ghSkipBg")) { $Border.Resources.Remove("ghSkipBg") | Out-Null }
    $Border.Resources.Add("ghCollect", $collectChildren)
    $Border.Resources.Add("ghAccentHex", $AccentHex)
    if ($SkipWhenBgIs) {
        $Border.Resources.Add("ghSkipBg", $SkipWhenBgIs)
    }
}

# Reduce eye-strain on saturated accents when used as a button fill.
# Pure #ff0000 / #ffff00 / #00ff00 etc are great as theme stamps but
# painful as a 200x40 solid block. We desaturate ~30% and pull
# brightness down ~10%, only when the source is in the "too punchy"
# zone (high sat AND high val). Mild colors pass through.
function global:Get-DampenedAccentHex {
    param([string]$Hex)
    $c = ConvertTo-MediaColor $Hex
    $r = $c.R / 255.0; $g = $c.G / 255.0; $b = $c.B / 255.0
    $max = [Math]::Max([Math]::Max($r, $g), $b)
    $min = [Math]::Min([Math]::Min($r, $g), $b)
    $v = $max
    $delta = $max - $min
    $s = if ($max -eq 0) { 0 } else { $delta / $max }
    # Only dampen if saturation > 0.7 AND value > 0.75 (the truly punchy ones)
    if ($s -le 0.7 -or $v -le 0.75) { return $Hex }

    # Compute hue
    $h = 0.0
    if ($delta -ne 0) {
        if ($max -eq $r) {
            $h = (($g - $b) / $delta) % 6
        } elseif ($max -eq $g) {
            $h = ($b - $r) / $delta + 2
        } else {
            $h = ($r - $g) / $delta + 4
        }
        $h *= 60
        if ($h -lt 0) { $h += 360 }
    }

    # Dampen: -30% sat, -10% val
    $s = [Math]::Max(0.0, $s * 0.70)
    $v = [Math]::Max(0.0, $v * 0.90)

    # HSV -> RGB
    $cc = $v * $s
    $x = $cc * (1 - [Math]::Abs((($h / 60) % 2) - 1))
    $m = $v - $cc
    if     ($h -lt  60) { $r2 = $cc; $g2 = $x;  $b2 = 0  }
    elseif ($h -lt 120) { $r2 = $x;  $g2 = $cc; $b2 = 0  }
    elseif ($h -lt 180) { $r2 = 0;   $g2 = $cc; $b2 = $x }
    elseif ($h -lt 240) { $r2 = 0;   $g2 = $x;  $b2 = $cc }
    elseif ($h -lt 300) { $r2 = $x;  $g2 = 0;   $b2 = $cc }
    else                { $r2 = $cc; $g2 = 0;   $b2 = $x  }
    $rr = [int]([Math]::Round(($r2 + $m) * 255))
    $gg = [int]([Math]::Round(($g2 + $m) * 255))
    $bb = [int]([Math]::Round(($b2 + $m) * 255))
    return ("#{0:X2}{1:X2}{2:X2}" -f $rr, $gg, $bb)
}

# ---------------------------------------------------------------
# PC Power Scale: rough hardware-tier hint for each game.
# The scale runs LOW -> BASIC -> SOLID -> STRONG -> HIGH -> EXTREME.
# Each tier has a representative GPU/CPU pair shown in the detail
# view. Some games span two tiers (e.g. "SOLID-STRONG" for ones
# whose appetite varies a lot by settings) - those get a range
# instead of a single marker.
#
# A returned object has:
#   StartIdx  - 0..5, the leftmost tier index
#   EndIdx    - 0..5, the rightmost tier index (== StartIdx for single-tier)
#   IsRange   - bool ($true if EndIdx > StartIdx)
# ---------------------------------------------------------------
$global:PowerTiers = @(
    @{ Key="LOW";     Label="LOW";        Gpu="GTX 1070";          Cpu="i7-7700 / R5 1600" },
    @{ Key="BASIC";   Label="BASIC";      Gpu="GTX 1080 / RTX 2060";Cpu="i7-8700K / R5 3600" },
    @{ Key="SOLID";   Label="SOLID";      Gpu="RTX 3060 Ti";       Cpu="R5 5600 / i5-12400F" },
    @{ Key="STRONG";  Label="STRONG";     Gpu="RTX 4070 / Super";  Cpu="R5 7600 / i5-13600K" },
    @{ Key="HIGH";    Label="HIGH";       Gpu="RTX 4080 / Super";  Cpu="R7 7800X3D" },
    @{ Key="EXTREME"; Label="EXTREME";    Gpu="RTX 4090 / 5090";   Cpu="R7 9800X3D+" }
)

function global:Get-PowerTierIndex {
    param([string]$Key)
    for ($i = 0; $i -lt $global:PowerTiers.Count; $i++) {
        if ($global:PowerTiers[$i].Key -eq $Key) { return $i }
    }
    return 2  # default = SOLID
}

# Resolve a game's power-tier band based on Martin's manual tier
# classification. Each title maps to one of:
#   LOW (0), BASIC (1), SOLID (2), STRONG (3), HIGH (4), EXTREME (5)
# Returns @{StartIdx, EndIdx, IsRange}. Preliminary games (marked
# with -P below) get a +/-1 range to reflect uncertainty.
function global:Get-PowerTier {
    param($Game, [string]$Category = "")  # "MC" | "GP" | "EXT"
    $title = if ($Game.Title) { $Game.Title } else { "" }
    $mod   = if ($Game.Mod)   { $Game.Mod }   else { "" }

    # Tier per game title. Suffix -P = preliminary, gets a range.
    # Source: Martin's compiled tier list. Edit here when revising.
    $tierMap = @{
        # ---- LOW ----
        "Dredge VR"                               = "LOW"
        "Hexen II VR"                             = "LOW"
        "Lunistice VR"                            = "LOW"

        # ---- BASIC ----
        "Alba VR"                      = "BASIC"
        "No One Lives Forever 2 VR"    = "BASIC"
        "Richard Burns Rally VR"       = "BASIC"
        "Amnesia VR"                   = "BASIC"
        "Apollo Justice: Ace Attorney Trilogy VR" = "BASIC"
        "Art of Rally VR"              = "BASIC"
        "Ashes 2063 VR"                = "BASIC"
        "Astrodogs VR"                 = "BASIC"
        "Mouse P.I. For Hire VR"       = "STRONG"
        "New Star GP VR"                = "BASIC"
        "Super Mario 64 VR"            = "BASIC"
        "Star Fox 64 VR"               = "BASIC"
        "Bendy VR"                     = "SOLID"
        "Cloudpunk VR"                 = "BASIC"
        "Cloudpunk: City of Ghosts VR" = "BASIC"
        "Daggerfall VR"                = "BASIC"
        "Decimate Drive VR"            = "BASIC"
        "Doom 3 BFG VR"                = "BASIC"
        "Doom VR"                      = "BASIC"
        "Doom 2 VR"                    = "BASIC"
        "Dusk HD (DLC) VR"             = "BASIC"
        "Echo Generation 2 VR"         = "STRONG"
        "Firewatch VR"                 = "BASIC"
        "Garry's Mod VR"               = "BASIC"
        "Ghosts n Goblins Resurrection VR" = "BASIC"
        "Gunfire Reborn"               = "BASIC"
        "Half-Life VR"                 = "BASIC"
        "Halo CE VR"                   = "BASIC"
        "Heretic VR"                   = "BASIC"
        "Iron Lung VR"                 = "BASIC"
        "Hexen VR"                     = "BASIC"
        "Hytale VR"                    = "SOLID"
        "Hollow Knight VR"             = "BASIC"
        "Horizon Chase Turbo"          = "BASIC"
        "Hypogea VR"                   = "BASIC"
        "I Can Gun VR"                 = "BASIC"
        "Jedi Knight: Jedi Academy VR" = "BASIC"
        "Jedi Knight: Jedi Outcast VR" = "BASIC"
        "Life is Strange: BtS"         = "BASIC"
        "Mirage Feathers VR"           = "BASIC"
        "Morrowind VR"                 = "BASIC"
        "Neon White VR"                = "BASIC"
        "Paperklay VR"                 = "BASIC"
        "PEAK VR"                      = "BASIC"
        "Penumbra: Overture VR"        = "BASIC"
        "Perfect Dark VR"              = "BASIC"
        "Portal 2 VR"                  = "BASIC"
        "Quake 2 VR"                   = "BASIC"
        "Quake 3 VR"                   = "BASIC"
        "Quake VR"                     = "BASIC"
        "Receiver VR"                  = "BASIC"
        "Rogue Flight VR"              = "BASIC"
        "Sayonara Wild Hearts"         = "BASIC"
        "Saints Row: The Third VR"     = "SOLID"
        "Selaco VR"                   = "SOLID"
        "Shipbreaker VR"              = "SOLID"
        "Slime Rancher VR"             = "BASIC"
        "Slyders VR"                   = "BASIC"
        "Moto Rush Reborn VR"          = "BASIC"
        "Stanley Parable VR"           = "BASIC"
        "StreetDog BMX VR"             = "BASIC"
        "Strife VR"                    = "BASIC"
        "Sunrise GP VR"                = "BASIC"
        "Super Polygon Grand Prix VR"  = "BASIC"
        "Tomb Raider 1 VR"             = "BASIC"
        "Yooka-Laylee VR"              = "BASIC"

        # ---- SOLID ----
        "Dark Souls Remastered" = "SOLID"
        "Portal 2: Community Edition VR" = "SOLID"
        "Freespace 2 VR" = "SOLID"
        "Dark Souls II VR" = "SOLID"
        "Star Wars: X-Wing VR"         = "SOLID"
        "7 Days to Die VR"             = "SOLID"
        "Alien: Isolation VR"          = "SOLID"
        "Another Crab's Treasure"      = "SOLID"
        "Black Mesa Source VR"         = "SOLID"
        "Circuit Superstars VR"        = "SOLID"
        "Content Warning VR"           = "SOLID"
        "Cruelty Squad VR"             = "SOLID"
        "Descenders VR"                = "SOLID"
        "Dino Trauma VR"               = "SOLID"
        "Driftwood VR"                 = "SOLID"
        "Far Cry VR"                   = "SOLID"
        "Half-Life 2 VR"               = "SOLID"
        "HL2 VR Ep. One"               = "SOLID"
        "HL2 VR Ep. Two"               = "SOLID"
        "Hollow Knight Silksong"       = "SOLID"
        "Left 4 Dead 2 VR"             = "SOLID"
        "Lethal Company VR"            = "SOLID"
        "Mega Man Star Force Legacy VR"= "SOLID"
        "Moros Protocol VR"            = "SOLID"
        "Outer Wilds VR"               = "SOLID"
        "Outward DE VR"                = "SOLID"
        "Raft VR"                      = "SOLID"
        "Ratchet & Clank VR"           = "SOLID"
        "Receiver 2 VR"                = "SOLID"
        "R.E.P.O. VR"                  = "SOLID"
        "Risk of Rain 2"               = "SOLID"
        "Road Redemption VR"           = "SOLID"
        "Skate Story VR"               = "SOLID"
        "Sonic P-06 VR"                = "SOLID"
        "Star Racer VR"                = "SOLID"
        "Techtonica VR"                = "SOLID"
        "Tinykin VR"                   = "SOLID"
        "Tormented Souls VR"           = "SOLID"
        "Total Chaos VR"               = "SOLID"
        "Trombone Champ VR"            = "BASIC"
        "ULTRAKILL VR"                 = "SOLID"
        "World of Warcraft VR"         = "SOLID"
        "Vivecraft"                    = "SOLID"

        # ---- STRONG ----
        "Metroid Prime VR"             = "STRONG"
        "Nuclear Option VR" = "STRONG"
        "The Dark Mod VR" = "STRONG"
        "Watch Dogs VR" = "STRONG"
        "Far Cry Primal VR" = "STRONG"
        "Dark Souls III VR" = "STRONG"
        "Anomaly VR"                   = "STRONG"
        "Anomaly GAMMA"                = "HIGH"
        "Bomb Rush Cyberfunk"          = "STRONG"
        "Breath of the Wild VR"        = "HIGH"
        "Crysis VR"                    = "STRONG"
        "Deep Rock Galactic VR"        = "STRONG"
        "Devil May Cry 5 VR"           = "STRONG"
        "Elden Ring VR"               = "STRONG"
        "Far Cry 4 VR"                = "STRONG"
        "Far Cry 5 VR"                = "STRONG"
        "Far Cry New Dawn VR"         = "STRONG"
        "Final Fantasy XIV VR"         = "STRONG"
        "Grounded VR"                 = "STRONG"
        "Horizon Zero Dawn VR"        = "STRONG"
        "House of the Dead Remake VR"  = "STRONG"
        "House of the Dead 2 Remake VR" = "STRONG"
        "Kerbal Space Program"         = "STRONG"
        "Monster Hunter Stories 3 VR"  = "STRONG"
        "Onimusha 2 VR"                = "STRONG"
        "Panzer Dragoon Remake"        = "STRONG"
        "Paranoia Place VR"            = "STRONG"
        "Resident Evil 2R VR"             = "STRONG"
        "Resident Evil 3R VR"             = "STRONG"
        "Resident Evil 7 VR"              = "STRONG"
        "RE Village VR"                   = "STRONG"
        "Spiderman Miles Morales VR"  = "STRONG"
        "Spiderman Remastered"     = "STRONG"
        "Street Fighter 6 VR"          = "STRONG"
        "Subnautica VR"                = "STRONG"
        "Subnautica: Below Zero"       = "STRONG"
        "Unmourned VR"                 = "STRONG"
        "Uncharted: Legacy of Thieves VR" = "STRONG"
        "Valheim VR"                   = "STRONG"
        "Watch Dogs 2 VR"             = "STRONG"

        # ---- HIGH ----
        "Stray VR" = "HIGH"
        "Grand Theft Auto V VR" = "HIGH"
        "Forza Horizon 6 VR" = "HIGH"
        "Ready Or Not VR" = "HIGH"
        "Cyberpunk 2077"              = "HIGH"
        "Skyrim VR" = "HIGH"
        "Doom Eternal VR" = "HIGH"
        "Atomic Heart VR"             = "HIGH"
        "Death Stranding VR"          = "HIGH"
        "Far Cry 6 VR"                = "HIGH"
        "FF VII Remake VR"            = "HIGH"
        "Ghost of Tsushima VR"        = "HIGH"
        "Ghostwire: Tokyo VR"         = "HIGH"
        "High on Life VR"             = "HIGH"
        "Horizon Zero Dawn Remastered VR" = "HIGH"
        "GTFO VR"                      = "HIGH"
        "Kunitsu-Gami: Path of the Goddess VR" = "HIGH"
        "Metal: Hellsinger VR"         = "HIGH"
        "Monster Hunter Rise VR"       = "HIGH"
        "Pragmata VR"                  = "HIGH"
        "RE Requiem VR"                   = "HIGH"
        "Resident Evil 4R VR"             = "HIGH"
        "Road to Vostok VR"            = "HIGH"
        "Spiderman 2 VR"              = "HIGH"
        "TLOU Part I VR"              = "HIGH"
        "TLOU Part II VR"             = "HIGH"
        "Watch Dogs Legion VR"        = "HIGH"

        # ---- EXTREME ----
        "Doom: The Dark Ages" = "EXTREME"
        "Hogwarts Legacy VR" = "EXTREME"
        "Avatar: Frontiers of Pandora VR" = "EXTREME"
        "Dragon's Dogma 2 VR"          = "EXTREME"
        "Escape from Tarkov VR"        = "EXTREME"
        "FF VII Rebirth VR"           = "EXTREME"
        "Horizon Forbidden West VR"   = "EXTREME"
        "Indiana Jones: Great Circle VR" = "EXTREME"
        "Kingdom Come: Deliverance II VR" = "EXTREME"
        "Monster Hunter Wilds"         = "EXTREME"
        "Star Wars Outlaws VR"        = "EXTREME"
        "Starfield VR"                 = "EXTREME"
    }

    $tier = $tierMap[$title]
    if ($tier) {
        # Backwards-compat: tolerate stray "-P" suffixes from older
        # versions of the map. We no longer expose ranges; everything
        # collapses to a single tier.
        if ($tier.EndsWith("-P")) {
            $tier = $tier.Substring(0, $tier.Length - 2)
        }
        $idx = Get-PowerTierIndex -Key $tier
        return @{ StartIdx=$idx; EndIdx=$idx; IsRange=$false }
    }

    # ---- Fallback for titles not in the map ----
    # REFramework family - modern RE Engine titles tend to be heavy
    # in VR. Default to STRONG.
    if ($mod -match 'REFramework|REF-nightly|REF auto-update') {
        return @{ StartIdx=3; EndIdx=3; IsRange=$false }
    }
    # Luke Ross fallback - LR titles are AAA games, default to STRONG.
    if ($title -match '^LR:' -or $mod -match 'R\.E\.A\.L\.') {
        return @{ StartIdx=3; EndIdx=3; IsRange=$false }
    }
    # UEVR Deluxe is a generic injector - depends entirely on the
    # host game. Range Strong->Extreme reflects the breadth: simple
    # UE4 titles run on Strong; demanding UE5 titles can humble even
    # an RTX 5090 down to 50fps. UEVR is the only legitimate range
    # case in the hub.
    if ($title -eq 'UEVR Deluxe') {
        return @{ StartIdx=3; EndIdx=5; IsRange=$true }
    }
    # Dolphin VR + ReduX is a GameCube/Wii VR emulator. Range
    # Solid->Strong since GameCube titles are light but stereo
    # rendering + Wii resolution scaling can push it higher.
    if ($title -eq 'Dolphin VR + ReduX') {
        return @{ StartIdx=2; EndIdx=3; IsRange=$true }
    }
    # UUVR / Rai Pal is a universal Unity VR injector - like UEVR,
    # the cost depends entirely on the host game. Range Solid->Strong:
    # light indie Unity titles run on Solid, heavier ones plus the VR
    # stereo overhead push toward Strong.
    if ($title -eq 'UUVR / Rai Pal') {
        return @{ StartIdx=2; EndIdx=3; IsRange=$true }
    }
    # Default: SOLID (middle-ground for anything else)
    return @{ StartIdx=2; EndIdx=2; IsRange=$false }
}

# Build a vertical LinearGradientBrush card background:
# - top: tint color at $TopAlpha (0..1) over the base
# - middle (60%): tint color at $MidAlpha
# - bottom: pure base color
# This is what gives each card its accent wash.
function global:New-CardTintBrush {
    param(
        [string]$BaseHex   = "#16161a",
        [string]$TintHex   = "#ffffff",
        [double]$TopAlpha  = 0.10,
        [double]$MidAlpha  = 0.02
    )
    $base = ConvertTo-MediaColor $BaseHex
    $tint = ConvertTo-MediaColor $TintHex

    if ($global:hubStyle -eq 'classic') {
        # Classic style: the original top->base vertical gradient.
        # Manually blend tint over base at given alpha so we end up with
        # a fully opaque gradient (no surprises with WPF compositing).
        $blend = {
            param($a)
            [byte]([Math]::Round($tint.R * $a + $base.R * (1 - $a)))
            [byte]([Math]::Round($tint.G * $a + $base.G * (1 - $a)))
            [byte]([Math]::Round($tint.B * $a + $base.B * (1 - $a)))
        }
        $top = & $blend $TopAlpha
        $mid = & $blend $MidAlpha
        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object System.Windows.Point 0, 0
        $brush.EndPoint   = New-Object System.Windows.Point 0, 1
        $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb($top[0],$top[1],$top[2])), 0.0))   | Out-Null
        $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb($mid[0],$mid[1],$mid[2])), 0.6))   | Out-Null
        $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop $base, 1.0))                                                               | Out-Null
        return $brush
    }

    # Frosted style: calm FLAT fill (no gradient). The vertical top->base
    # gradient made the grid look busy, so we blend the tint over the base
    # ONCE at the average of the old top/mid alphas - each state keeps about
    # its previous colour weight, just as a calm solid fill.
    $a = ($TopAlpha + $MidAlpha) / 2.0
    # Deep low-luminance accents (reds) almost vanish at the faint default
    # tint over the near-black base. Lift only that faint default tint for
    # such accents so red tiles stay visible; the stronger state tints
    # (amber/green/blue, avg >= 0.09) are already clear and left untouched.
    $lum = ($tint.R * 0.299 + $tint.G * 0.587 + $tint.B * 0.114) / 255.0
    if ($a -lt 0.09 -and $lum -lt 0.45) {
        $a = $a + (0.45 - $lum) * 0.30
    }
    $r = [byte]([Math]::Round($tint.R * $a + $base.R * (1 - $a)))
    $g = [byte]([Math]::Round($tint.G * $a + $base.G * (1 - $a)))
    $b = [byte]([Math]::Round($tint.B * $a + $base.B * (1 - $a)))
    $col = [System.Windows.Media.Color]::FromRgb($r, $g, $b)
    $brush = New-Object System.Windows.Media.SolidColorBrush $col
    return $brush
}

# Mod families -> short label for the family pill.
# 1) Explicit override: a Pill="..." field on the game hash wins
#    (used for short codes like "7D2DVR", "DRGVR"). The pill text
#    is also auto-added to Tags so search picks it up.
# 2) Otherwise: infer from the Mod string (R.E.A.L. VR -> Luke Ross, etc.)
# 3) Fallback: first word of the Mod string, or "Mod".
function global:Get-ModFamily {
    param($Game, $IsExternal)
    if ($Game.Pill) { return $Game.Pill }
    if ($IsExternal) { return "External" }
    if (-not $Game.Mod) { return "Mod" }
    if ($Game.Title -eq "UUVR / Rai Pal")     { return "Unity" }
    if ($Game.Mod -match "R\.E\.A\.L\.")       { return "Luke Ross" }
    if ($Game.Mod -match "REFramework|^REF( |-)|REF-nightly") { return "REFramework" }
    if ($Game.Mod -match "UEVR")             { return "UEVR" }
    if ($Game.Mod -match "BepInEx")          { return "BepInEx" }
    # Otherwise: take first word of the mod string
    $first = ($Game.Mod -split "\s+")[0]
    if ($first.Length -gt 0) { return $first }
    return "Mod"
}

# Find similar games for the detail page. Scoring mix:
#   +10  same Author (e.g. all praydog games)
#    +5  same mod family (Luke Ross, REFramework, ...)
#    +2  per shared tag
#    +1  same Controls type (MC / GP)
# Top 3 returned, excluding the source game itself.
function global:Get-SimilarGames {
    param($Game, [int]$Count = 3)
    $allGames = @()
    $allGames += $ownGames
    $allGames += $ownGamesGP
    $allGames += $externalGames

    $sourceFam   = Get-ModFamily -Game $Game -IsExternal $false
    $sourceTags  = @()
    if ($Game.Tags) { $sourceTags = $Game.Tags }

    # Genre vocabulary - tags that describe what KIND of game it
    # is, not which specific game. Matches on these score high
    # because two games sharing "horror" or "roguelite" really
    # are similar; matching on a specific game-name variant
    # ("ror2", "gunfire") just means same game.
    $genreVocab = @(
        "roguelite", "roguelike", "rogue-lite", "rogue-like",
        "fps", "shooter", "first person shooter",
        "horror", "survival horror", "psychological horror",
        "coop", "co-op", "multiplayer",
        "survival", "open world",
        "exploration", "adventure", "walking sim", "narrative",
        "puzzle", "mystery", "metroidvania",
        "stealth", "platformer", "rpg", "souls-like",
        "comedy", "story", "atmospheric",
        "bullet hell", "twin stick",
        "underwater", "space", "fantasy", "sci-fi", "cyberpunk",
        "fast paced", "action", "racing",
        "indie"
    )

    $scored = @()
    foreach ($g in $allGames) {
        if ($g.Title -eq $Game.Title) { continue }
        $score = 0

        # Same author = +6 (was +10 - too dominant)
        if ($g.Author -and $Game.Author -and $g.Author -eq $Game.Author) {
            $score += 6
        }

        # Same mod family = +2 (was +5). Useful as tiebreaker but
        # not enough alone - all Source Engine mods aren't similar
        # just because they share the engine.
        $candFam = Get-ModFamily -Game $g -IsExternal $false
        if ($candFam -eq $sourceFam) { $score += 2 }

        # Tag overlap - genre tags weighted higher than other tags.
        if ($g.Tags) {
            foreach ($t in $g.Tags) {
                if ($sourceTags -contains $t) {
                    $tLower = $t.ToString().ToLower()
                    if ($genreVocab -contains $tLower) {
                        $score += 8   # genre match - strong signal
                    } else {
                        $score += 1   # game-name variant or specific tag
                    }
                }
            }
        }

        # Same control scheme = +1 (weak filter, just preference)
        if ($g.Controls -and $Game.Controls -and $g.Controls -eq $Game.Controls) {
            $score += 1
        }

        # Tool-affinity bonus: both entries are universal VR tools
        # (external, no specific SteamId - meaning they mod many
        # games rather than one). UEVR <-> Dolphin VR is the case
        # that triggers this today. +12 puts the tool peer above
        # generic-tag-match noise (~8) but below strong genre
        # overlap (~24+), so themed similar-games still win when
        # they exist.
        $sourceIsTool = ($Game.Type -eq "external") -and (-not $Game.SteamId)
        $candIsTool   = ($g.Type    -eq "external") -and (-not $g.SteamId)
        if ($sourceIsTool -and $candIsTool) {
            $score += 12
        }

        if ($score -gt 0) {
            $scored += [PSCustomObject]@{ Game = $g; Score = $score }
        }
    }

    $top = $scored | Sort-Object -Property Score -Descending | Select-Object -First $Count
    return ($top | ForEach-Object { $_.Game })
}

# ----------------------------------------------------------------
# Soft hover for pills whose active state already uses a colored
# border (the filter row's All/MC/GP/Installed and the S/M/L
# switcher). For those, the Add-GlowHover helper would paint the
# same accent border on hover that we use for the active state,
# making it impossible to tell active from "merely hovered". This
# helper only brightens the background a touch - just enough for
# the user to feel "yes I am pointing at something interactive"
# without competing with the active-state visual.
#
# Implementation note: we stash + restore Background and Foreground
# on Resources of the Border and its inner TextBlocks, mirroring
# the same restore strategy as Add-GlowHover. Border thickness is
# never touched (layout-stable). The brightened bg is a 7% white
# tint, vs the resting 3% - subtle but noticeable on the dark hub.
# ----------------------------------------------------------------
function global:Add-SoftHover {
    param(
        [System.Windows.Controls.Border]$Border,
        # Optional override: hex of a brighter background to use on
        # hover. Default is a 7% white tint (~2x brighter than the
        # 3% glass base) which works against the dark hub bg.
        [string]$HoverBgHex = "#12ffffff"
    )
    if (-not $Border) { return }

    # Collect all TextBlocks under the border. Same walker shape as
    # Add-GlowHover for consistency.
    $collectTbs = {
        param($root)
        $tbs = New-Object System.Collections.ArrayList
        $stack = New-Object System.Collections.Stack
        $stack.Push($root)
        while ($stack.Count -gt 0) {
            $node = $stack.Pop()
            if ($node -is [System.Windows.Controls.TextBlock]) {
                [void]$tbs.Add($node)
            }
            if ($node -is [System.Windows.Controls.Panel]) {
                foreach ($ch in $node.Children) { $stack.Push($ch) }
            } elseif ($node -is [System.Windows.Controls.Border]) {
                if ($node.Child) { $stack.Push($node.Child) }
            }
        }
        return $tbs
    }

    $Border.Add_MouseEnter({
        if (-not $this.IsEnabled) { return }
        # Stash + brighten the background
        if ($this.Resources.Contains("shBg")) { $this.Resources.Remove("shBg") | Out-Null }
        $this.Resources.Add("shBg", $this.Background)
        $hex = $this.Resources.Item("shHoverHex")
        if (-not $hex) { $hex = "#12ffffff" }
        $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($hex)
        # Brighten text by one notch - only for text that wasn't
        # already pure white (i.e. inactive pills). The active pill
        # is white already, so we leave it alone.
        $collected = & $this.Resources.Item("shCollect") $this
        foreach ($tb in $collected) {
            $cur = $tb.Foreground
            $isWhite = $false
            if ($cur -is [System.Windows.Media.SolidColorBrush]) {
                $c = $cur.Color
                if ($c.R -eq 255 -and $c.G -eq 255 -and $c.B -eq 255) { $isWhite = $true }
            }
            if (-not $isWhite) {
                if (-not $tb.Resources.Contains("shFg")) {
                    $tb.Resources.Add("shFg", $tb.Foreground)
                }
                $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
            }
        }
    })

    $Border.Add_MouseLeave({
        if ($this.Resources.Contains("shBg")) {
            $orig = $this.Resources.Item("shBg")
            if ($orig) { $this.Background = $orig }
            $this.Resources.Remove("shBg") | Out-Null
        }
        $collected = & $this.Resources.Item("shCollect") $this
        foreach ($tb in $collected) {
            if ($tb.Resources.Contains("shFg")) {
                $orig = $tb.Resources.Item("shFg")
                if ($orig) { $tb.Foreground = $orig }
                $tb.Resources.Remove("shFg") | Out-Null
            }
        }
    })

    if ($Border.Resources.Contains("shCollect"))  { $Border.Resources.Remove("shCollect")  | Out-Null }
    if ($Border.Resources.Contains("shHoverHex")) { $Border.Resources.Remove("shHoverHex") | Out-Null }
    $Border.Resources.Add("shCollect",  $collectTbs)
    $Border.Resources.Add("shHoverHex", $HoverBgHex)
}

# ----------------------------------------------------------------
# Give a Border-based button a subtle "physical edge" highlight by
# replacing its solid border with a vertical-gradient BorderBrush:
# brighter at the top, fading to the original border color at the
# bottom. Reads as the catch-light on a slightly raised key, with
# no overlay layer competing with the icon/text content.
#
# Why not a Child overlay: earlier attempts wrapped the content
# in a Grid with a highlight Border on top. That gets pushed inside
# the host's Padding, landing the highlight stripe on top of the
# text instead of on the button's edge. Using BorderBrush keeps the
# highlight where borders actually live: between Margin and Padding.
#
# Why not a gradient Background: Add-SweepHover requires a Solid
# ColorBrush as Background to animate the sweep. Mutating Background
# to a gradient breaks the sweep. BorderBrush is untouched by Sweep
# Hover so the two effects coexist.
#
# IMPORTANT: this needs the host to already have a BorderBrush set
# (so we can read its color as the "fade-to" stop) and a non-zero
# BorderThickness (so the brush is actually visible). For buttons
# with BorderThickness=0 (the solid blue Update / Get on Steam) we
# bump thickness up to 1 because the highlight wouldn't otherwise
# render. The original solid color is preserved as the bottom stop.
# ----------------------------------------------------------------
function global:Add-ButtonGloss {
    param(
        [System.Windows.Controls.Border]$Border,
        # How much white to mix into the original border color at
        # the top stop. 0.45 reads as a clear catch-light on solid
        # buttons; 0.25 is muted, fitting the slate variants where
        # we don't want any extra visual weight.
        [double]$Intensity = 0.35
    )
    if (-not $Border) { return }

    # Read the existing border color so we have something to fade
    # back to. If there's no border brush set (BorderThickness=0
    # case), fall back to the button's own background tint so the
    # highlight blends naturally into the lower half.
    $baseBrush = $Border.BorderBrush
    if (-not ($baseBrush -is [System.Windows.Media.SolidColorBrush])) {
        $bg = $Border.Background
        if ($bg -is [System.Windows.Media.SolidColorBrush]) {
            $baseBrush = New-Object System.Windows.Media.SolidColorBrush $bg.Color
        } else {
            # Last-resort default: a neutral dark.
            $baseBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
        }
    }
    $baseColor = $baseBrush.Color

    # Top stop: mix the base color with white by $Intensity. This
    # keeps the hue consistent with the button's color family - a
    # green button gets a green-tinted highlight, blue stays blue,
    # slate stays slate. Pure white at the top edge would look
    # disconnected on warmer buttons.
    $topColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, [int]([Math]::Round($baseColor.R + (255 - $baseColor.R) * $Intensity)))),
        [byte]([Math]::Min(255, [int]([Math]::Round($baseColor.G + (255 - $baseColor.G) * $Intensity)))),
        [byte]([Math]::Min(255, [int]([Math]::Round($baseColor.B + (255 - $baseColor.B) * $Intensity))))
    )

    # Vertical gradient: bright top, original base at 50% downward
    # so the highlight stays a thin band at the top edge rather
    # than washing the whole border.
    $grad = New-Object System.Windows.Media.LinearGradientBrush
    $grad.StartPoint = New-Object System.Windows.Point 0, 0
    $grad.EndPoint   = New-Object System.Windows.Point 0, 1
    $sTop = New-Object System.Windows.Media.GradientStop
    $sTop.Color = $topColor
    $sTop.Offset = 0.0
    $sMid = New-Object System.Windows.Media.GradientStop
    $sMid.Color = $baseColor
    $sMid.Offset = 0.5
    $sBot = New-Object System.Windows.Media.GradientStop
    $sBot.Color = $baseColor
    $sBot.Offset = 1.0
    [void]$grad.GradientStops.Add($sTop)
    [void]$grad.GradientStops.Add($sMid)
    [void]$grad.GradientStops.Add($sBot)

    # If the host had BorderThickness=0 (solid colored buttons like
    # Update Mod and Get on Steam) we'd render nothing at all -
    # set thickness to 1 so the gradient border can show. Width on
    # all sides for visual symmetry.
    $bt = $Border.BorderThickness
    if ($bt.Top -eq 0 -and $bt.Bottom -eq 0 -and $bt.Left -eq 0 -and $bt.Right -eq 0) {
        $Border.BorderThickness = [System.Windows.Thickness]::new(1)
    }
    $Border.BorderBrush = $grad
}

# ----------------------------------------------------------------
# Build a small monochrome icon (WPF Path) for use inside Detail-
# view action buttons. Each icon is hand-tuned to fit a 14x14
# box; ViewBox keeps the geometry crisp at any final size. The
# stroke approach (Fill=None + Stroke) reads better than fills
# at this tiny scale - hair-thin strokes stay legible.
#
# Available kinds:
#   "download"  - arrow pointing down with a base line (Install Mod)
#   "external"  - small square + outgoing arrow (Mod Page)
#   "steam"     - circle with smaller inner circle (Open in Steam)
#   "update"    - two arrows up/down (Update Mod)
#   "check"     - check mark (VR Ready, Get on Steam)
#   "play"      - right-pointing triangle (Start in VR)
# ----------------------------------------------------------------
function global:New-ActionIcon {
    param(
        [ValidateSet("download","external","steam","update","check","play")]
        [string]$Kind,
        [string]$ColorHex = "#FFFFFF",
        [double]$Size = 14,
        [double]$StrokeThickness = 1.8
    )
    $vb = New-Object System.Windows.Controls.Viewbox
    $vb.Width  = $Size
    $vb.Height = $Size
    $vb.Stretch = [System.Windows.Media.Stretch]::Uniform
    $vb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $canvas = New-Object System.Windows.Controls.Canvas
    $canvas.Width  = 14
    $canvas.Height = 14

    $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ColorHex)

    $geo = switch ($Kind) {
        "download" { "M 7,1 L 7,10 M 3,7 L 7,11 L 11,7 M 1,13 L 13,13" }
        "external" { "M 9,3 L 13,3 L 13,7 M 13,3 L 7,9 M 11,9 L 11,12 L 2,12 L 2,4 L 5,4" }
        "steam"    { "M 7,1 A 6,6 0 1 0 7,13 A 6,6 0 1 0 7,1 M 7,5 A 2,2 0 1 0 7,9 A 2,2 0 1 0 7,5" }
        "update"   { "M 2,4 L 4,2 L 6,4 M 4,2 L 4,12 M 12,10 L 10,12 L 8,10 M 10,12 L 10,2" }
        "check"    { "M 2.5,7 L 6,10.5 L 11.5,3.5" }
        "play"     { "M 4,2 L 4,12 L 12,7 Z" }
        default    { "" }
    }
    $path = New-Object System.Windows.Shapes.Path
    $path.Stroke = $brush
    $path.StrokeThickness = $StrokeThickness
    $path.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
    $path.StrokeEndLineCap   = [System.Windows.Media.PenLineCap]::Round
    $path.StrokeLineJoin     = [System.Windows.Media.PenLineJoin]::Round
    if ($Kind -eq "play") {
        # Play icon is filled, not stroked - reads as a solid arrow.
        $path.Fill = $brush
        $path.Stroke = $null
    }
    $path.Data = [System.Windows.Media.Geometry]::Parse($geo)
    [void]$canvas.Children.Add($path)
    $vb.Child = $canvas
    return $vb
}

# -------------------------------------------------------
# Helper: create a game card
# -------------------------------------------------------

# ---------------------------------------------------------------
# Hub-settings persistence. Lives here in Helpers.ps1 (loads
# first) so that Window.ps1 and other early modules can read the
# user's saved S/M/L preferences during their initial setup.
# OverviewPage.ps1 redefines these identically further down; both
# versions are safe because they share the same .json file.
# ---------------------------------------------------------------
if (-not $global:HubSettingsFile) {
    $global:HubSettingsFile = Join-Path $scriptDir ".hub-settings.json"
}
if (-not (Get-Command Get-HubSetting -ErrorAction SilentlyContinue)) {
    function Get-HubSetting {
        param([string]$Key, $Default = $null)
        if (-not (Test-Path $global:HubSettingsFile)) { return $Default }
        try {
            $raw = Get-Content $global:HubSettingsFile -Raw
            $obj = $raw | ConvertFrom-Json
            if ($obj.PSObject.Properties.Name -contains $Key) {
                return $obj.$Key
            }
        } catch { }
        return $Default
    }
    function Set-HubSetting {
        param([string]$Key, $Value)
        $obj = @{}
        if (Test-Path $global:HubSettingsFile) {
            try {
                $raw = Get-Content $global:HubSettingsFile -Raw
                $parsed = $raw | ConvertFrom-Json
                foreach ($p in $parsed.PSObject.Properties) {
                    $obj[$p.Name] = $p.Value
                }
            } catch { }
        }
        $obj[$Key] = $Value
        try {
            $obj | ConvertTo-Json -Compress | Set-Content -Path $global:HubSettingsFile -Encoding UTF8
        } catch { }
    }
}

# -------------------------------------------------------------
# Set-SafeBannerImage
#
# Central, robust image loader for every banner / hero / tile in
# the Hub. Loads the first URL in $Urls into $ImageEl, and on
# DownloadFailed walks the rest of the list, then retries the
# FIRST url one more time (most failures are transient TLS/CDN
# hiccups - the "it showed up after a Hub restart" case).
#
# If $TitleEl is given, it is shown whenever no image is loaded
# yet and hidden once one succeeds, so a banner never renders
# completely blank - at worst it shows the game title.
#
# Params:
#   -ImageEl  WPF Image element to fill (required)
#   -Urls     Ordered list of candidate URLs (first = primary)
#   -TitleEl  Optional TextBlock to use as the blank-state fallback
# -------------------------------------------------------------
function global:Expand-DrivePaths {
    # Drive-letter coverage. A catalog FallbackPath like "C:\Games\X" can
    # really sit on ANY fixed drive (D:, Q:, ...). Given a path list, this
    # returns the originals PLUS the same drive-less tail on every fixed
    # drive, so odd letters are covered. Tokenised entries (STEAM:, GOG:,
    # EPIC:, XBOX:, STEAM_CONTENT...) and UNC paths are passed through
    # untouched - only single-letter "X:\..." roots are expanded.
    param([string[]]$Paths)
    $out = New-Object System.Collections.Generic.List[string]
    $drives = @()
    try {
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
                  Where-Object { $_.Root -match '^[A-Za-z]:\\$' } |
                  ForEach-Object { $_.Root }
    } catch {}
    foreach ($p in $Paths) {
        if (-not $p) { continue }
        if (-not $out.Contains($p)) { $out.Add($p) | Out-Null }
        if ($p -match '^[A-Za-z]:\\(.+)$') {
            $tail = $matches[1]
            foreach ($dr in $drives) {
                $alt = $dr + $tail
                if (-not $out.Contains($alt)) { $out.Add($alt) | Out-Null }
            }
        }
    }
    return $out
}

function global:Set-BannerAmbientColor {
    # Sample the LEFT edge of a decoded banner image and recolor the banner's
    # background + fade gradient to that colour, so the art looks like its own
    # colour bleeds out to the left. Fully guarded: on any failure the static
    # dark gradient/background stays. $BgEl/$FadeEl are derived from the image
    # element name (OvBannerImage -> OvBannerBg / OvBannerFade) by the caller.
    param($BmpSrc, $BgEl, $FadeEl, $Attempt = 0)
    try {
        if (-not $BmpSrc -or -not $BgEl) { return }
        $w = [int]$BmpSrc.PixelWidth; $h = [int]$BmpSrc.PixelHeight
        if ($w -lt 4 -or $h -lt 4) {
            # Bitmap not decoded yet. This is the "first banner at startup has no
            # colour" case: the sample ran before the fresh download finished
            # decoding. Instead of silently bailing, retry on the dispatcher a
            # few times (~2.4s) until PixelWidth is valid, then colour it.
            if ($Attempt -lt 12) {
                $bs = $BmpSrc; $be = $BgEl; $fe = $FadeEl; $na = $Attempt + 1
                $t = New-Object System.Windows.Threading.DispatcherTimer
                $t.Interval = [TimeSpan]::FromMilliseconds(200)
                $t.Add_Tick({ $this.Stop(); Set-BannerAmbientColor $bs $be $fe $na }.GetNewClosure())
                $t.Start()
            }
            return
        }
        $stripW = $w   # WHOLE image: the left edge alone is too often dark/noisy
        $rect = New-Object System.Windows.Int32Rect 0, 0, $stripW, $h
        $crop = New-Object System.Windows.Media.Imaging.CroppedBitmap $BmpSrc, $rect
        $conv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
        $conv.BeginInit()
        $conv.Source = $crop
        $conv.DestinationFormat = [System.Windows.Media.PixelFormats]::Bgra32
        $conv.EndInit()
        $stride = $stripW * 4
        $buf = New-Object 'byte[]' ($stride * $h)
        $conv.CopyPixels($buf, $stride, 0)
        # Find the DOMINANT saturated colour with a coarse quantised histogram,
        # NOT a plain average. Averaging diverse art just yields a muddy grey
        # whose tiny channel imbalance the boost amplifies into a phantom hue
        # (the "everything looks green" problem). Instead each kept pixel votes
        # for its colour bucket, weighted by saturation^2, so vivid art wins
        # over flat backdrops and the tint matches a real colour in the image.
        # Skip near-black (letterbox/backdrop) and near-white (logos/text/sky).
        $bw = @{}; $bR = @{}; $bG = @{}; $bB = @{}; $bN = @{}
        for ($p = 0; ($p + 2) -lt $buf.Length; $p += 64) {   # subsample for speed
            $cb0 = $buf[$p]; $cg0 = $buf[$p + 1]; $cr0 = $buf[$p + 2]
            $sum0 = $cr0 + $cg0 + $cb0
            if ($sum0 -lt 60 -or $sum0 -gt 735) { continue }  # skip near-black AND near-white
            $mxp = [Math]::Max($cr0, [Math]::Max($cg0, $cb0))
            $mnp = [Math]::Min($cr0, [Math]::Min($cg0, $cb0))
            $satp = if ($mxp -gt 0) { ($mxp - $mnp) / $mxp } else { 0.0 }
            $brt = $mxp / 255.0
            $key = '' + [int]($cr0 / 43) + '_' + [int]($cg0 / 43) + '_' + [int]($cb0 / 43)
            $wt = ($satp * $satp * $brt) + 0.02
            if ($bw.ContainsKey($key)) {
                $bw[$key] += $wt; $bR[$key] += $cr0; $bG[$key] += $cg0; $bB[$key] += $cb0; $bN[$key]++
            } else {
                $bw[$key] = $wt; $bR[$key] = [double]$cr0; $bG[$key] = [double]$cg0; $bB[$key] = [double]$cb0; $bN[$key] = 1
            }
        }
        if ($bw.Count -lt 1) {
            # Everything was black/white - fall back to a plain average so we
            # still get *some* colour rather than bailing to flat dark.
            $rt = 0.0; $gt = 0.0; $bt = 0.0; $n = 0
            for ($p = 0; ($p + 2) -lt $buf.Length; $p += 64) {
                $bt += $buf[$p]; $gt += $buf[$p + 1]; $rt += $buf[$p + 2]; $n++
            }
            if ($n -lt 1) { return }
            $ar = $rt / $n; $ag = $gt / $n; $ab = $bt / $n
        } else {
            # Highest-weight (most saturated * most common) bucket wins.
            $bestK = $null; $bestW = -1.0
            foreach ($k in $bw.Keys) { if ($bw[$k] -gt $bestW) { $bestW = $bw[$k]; $bestK = $k } }
            $ar = $bR[$bestK] / $bN[$bestK]
            $ag = $bG[$bestK] / $bN[$bestK]
            $ab = $bB[$bestK] / $bN[$bestK]   # representative dominant art colour
        }
        # (No saturation gate: a grey/metallic left edge is common, and gating
        # it out left ~half the games with no tint at all. We'd rather show the
        # subtle (possibly greyish) tint than nothing - the BgEl tint below is
        # dark enough that a desaturated colour just reads as a neutral ground.)
        # BOOST dark colours up to a visible level, preserving hue, so the
        # gradient actually reads (a dark-red edge becomes a clear red, etc.).
        # Only ever brighten - never darken a colour that is already vivid.
        $mx = [Math]::Max($ar, [Math]::Max($ag, $ab))
        if ($mx -lt 1) { $mx = 1 }
        $boost = 175.0 / $mx
        if ($boost -lt 1.0) { $boost = 1.0 }
        if ($boost -gt 2.2) { $boost = 2.2 }
        $ar = [Math]::Min(255.0, $ar * $boost)
        $ag = [Math]::Min(255.0, $ag * $boost)
        $ab = [Math]::Min(255.0, $ab * $boost)
        # Two tints from the SAME boosted colour:
        #   $amb  - the visible "ambient" band that bleeds off the image edge
        #   $dark - a dark (but still hue-tinted) version for the FAR left, so
        #           the title sits on a dark ground.
        $mk = {
            param($mul)
            $cr = [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round($ar * $mul)))
            $cg = [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round($ag * $mul)))
            $cb = [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round($ab * $mul)))
            [System.Windows.Media.Color]::FromRgb($cr, $cg, $cb)
        }
        $amb  = & $mk 0.90
        $dark = & $mk 0.28
        $BgEl.Fill = New-Object System.Windows.Media.SolidColorBrush $dark
        # NOTE: the per-game ambient FADE overlay is intentionally NOT applied.
        # Painted opaque over the banner middle, it showed an ugly (often
        # desaturated) band on every game. The banner keeps its static dark
        # XAML fade for a clean look; only the subtle BgEl tint above is kept.
    } catch { }
}

function global:Set-SafeBannerImage {
    param(
        [Parameter(Mandatory=$true)]$ImageEl,
        [Parameter(Mandatory=$true)][string[]]$Urls,
        $TitleEl = $null
    )
    if (-not $ImageEl) { return }

    # Derive the sibling background + fade rects from the image's own name
    # (e.g. "OvBannerImage" -> "OvBannerBg" / "OvBannerFade"), so the ambient
    # colour can be applied without threading extra params through every
    # caller. Null when this isn't a named banner image - then skipped.
    $bgRef   = $null
    $fadeRef = $null
    try {
        if ($ImageEl.Name -and $global:window) {
            $bn = $ImageEl.Name -replace 'Image$', ''
            $bgRef   = $global:window.FindName($bn + 'Bg')
            $fadeRef = $global:window.FindName($bn + 'Fade')
        }
    } catch { }

    # Reset the banner to a NEUTRAL DARK backdrop up front. This (a) clears any
    # ambient colour left over from a previously-featured game, and (b) means a
    # game whose art never loads shows neutral dark instead of its accent
    # colour. The image's own sampled colour (Set-BannerAmbientColor) overrides
    # this the moment the art decodes - sync or async - so it always wins.
    if ($bgRef) {
        try { $bgRef.Fill = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(15, 15, 21)) } catch { }
    }
    # The banner FADE keeps its static dark XAML gradient (a clean dark->clear
    # fade). We deliberately do NOT override it here - the code-built fade just
    # duplicated the XAML fade and was the hook the ambient recolor used to
    # paint a band across every banner. The BgEl reset above still clears any
    # leftover per-game tint.

    # Dedupe while preserving order, drop empties.
    $seen = @{}
    $clean = @()
    foreach ($u in $Urls) {
        if ($u -and -not $seen.ContainsKey($u)) {
            $seen[$u] = $true
            $clean += $u
        }
    }
    if ($clean.Count -eq 0) {
        if ($TitleEl) { $TitleEl.Visibility = [System.Windows.Visibility]::Visible }
        return
    }

    $imgRef   = $ImageEl
    $titleRef = $TitleEl
    $urlsCap  = $clean

    # Start with the title overlay visible; the first image that
    # decodes hides it. If every candidate fails it stays visible
    # instead of leaving a blank box.
    if ($titleRef) { $titleRef.Visibility = [System.Windows.Visibility]::Visible }

    # Sequential loader with DELAYED RETRY PASSES. Key insight (from
    # observed behaviour): a banner that's blank on first launch is
    # present after a Hub restart - the image URL is valid, the first
    # load just lost a race with cold network/CDN latency, and the
    # restart serves it from WPF's HTTP cache. So the fix isn't more
    # URLs, it's giving each candidate another try after a short pause.
    # Within a pass we walk every candidate (each attempt has its own
    # DownloadFailed/DecodeFailed handler advancing to the next). When a
    # pass is exhausted we wait a growing delay, then run another pass -
    # up to $maxPass passes total. Only after the last pass do we give
    # up and leave the title overlay showing.
    # Recursion without shared state: the loader takes ITSELF as $self
    # (a plain $tryLoad+GetNewClosure captures $null before assignment;
    # a $script: loader gets clobbered by a concurrent banner load).
    $maxPass = 3
    $passDelaysMs = @(400, 1200)   # pause before pass 2, then before pass 3
    $loader = {
        param($self, $i, $pass)
        if ($i -ge $urlsCap.Count) {
            if ($pass -lt ($maxPass - 1)) {
                # Wait a bit, then retry the whole list again. The pause
                # is what lets a transient first-load failure recover.
                $delay = $passDelaysMs[[Math]::Min($pass, $passDelaysMs.Count - 1)]
                $t = New-Object System.Windows.Threading.DispatcherTimer
                $t.Interval = [TimeSpan]::FromMilliseconds($delay)
                $t.Add_Tick({
                    $this.Stop()
                    & $self $self 0 ($pass + 1)
                }.GetNewClosure())
                $t.Start()
            } else {
                # All passes exhausted - leave the title fallback up.
                try {
                    $imgRef.Source = $null
                    if ($titleRef) { $titleRef.Visibility = [System.Windows.Visibility]::Visible }
                } catch { }
            }
            return
        }
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmpUri = New-Object System.Uri $urlsCap[$i]
            $bmp.UriSource = $bmpUri
            if ($bmpUri.IsFile) {
                # Local cache file: load fully now (no network; frees the
                # file handle immediately after decode).
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            } else {
                # Remote URL: load ASYNC. With OnLoad, EndInit() blocks the
                # UI thread until the (sometimes cold/slow) Steam CDN
                # responds - and each remote candidate blocks again, which
                # is the intermittent 10-15s startup freeze. OnDemand
                # returns immediately; the DownloadCompleted/DownloadFailed
                # handlers below drive the title overlay and the fallback.
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
            }
            $bmp.Add_DownloadCompleted({
                param($s, $e)
                if ($titleRef) { $titleRef.Visibility = [System.Windows.Visibility]::Collapsed }
                # Banner colour is now curated per-game (set in Set-BannerForGame
                # from BannerColors.ps1); no runtime image sampling.
            }.GetNewClosure())
            $bmp.Add_DownloadFailed({
                param($s, $e)
                & $self $self ($i + 1) $pass
            }.GetNewClosure())
            # DecodeFailed catches a downloaded-but-corrupt image, which
            # DownloadFailed alone misses.
            $bmp.Add_DecodeFailed({
                param($s, $e)
                & $self $self ($i + 1) $pass
            }.GetNewClosure())
            $bmp.EndInit()
            $imgRef.Source = $bmp
            # Banner colour is curated per-game (Set-BannerForGame /
            # BannerColors.ps1); the bitmap is no longer sampled for colour.
        } catch {
            # Synchronous failure (bad URI etc.) - skip to next.
            & $self $self ($i + 1) $pass
        }
    }

    & $loader $loader 0 0
}

# ------------------------------------------------------------
# Start-LoggedInstaller
# ------------------------------------------------------------
# Launch an installer through Run-Installer.ps1 so its console output is saved
# to <HubRoot>\Logs\<Title>-<timestamp>.log. Returns the launched (wrapper)
# process so callers can poll HasExited for post-install refresh.
# Branch logic matches the legacy launch sites exactly:
#   Bat -like 'LukeRossVR\*'    -> powershell -File <bat> -GameTitle
#   Bat -like 'REFrameworkVR\*' -> powershell -File REFrameworkVR-core.ps1 (+Title/Folder/Exe)
#   else                        -> cmd /c <bat>
# A RequiresAdmin standard install keeps its elevated (RunAs) launch, which
# cannot be tee'd (the elevated child owns its own console); left unlogged on
# purpose rather than break elevation.
function global:Start-LoggedInstaller {
    param($Game, [string]$BatPath, [switch]$RequiresAdmin)
    if (-not $Game -or [string]::IsNullOrWhiteSpace($BatPath)) { return $null }

    # Logs dir from the known Core path (passed to the wrapper as an absolute
    # path so it never depends on the wrapper's own $PSCommandPath).
    $logsDir = Join-Path $global:scriptDir "Logs"

    $title = [string]$Game.Title
    if ($Game.Bat -like "LukeRossVR\*") {
        $kind = "LukeRoss"; $ps1 = ""
    } elseif ($Game.Bat -like "REFrameworkVR\*") {
        $kind = "Ref"; $ps1 = Join-Path (Split-Path $BatPath -Parent) "REFrameworkVR-core.ps1"
    } else {
        $kind = "Bat"; $ps1 = ""
    }
    $folder = if ($Game.SteamFolder) { [string]$Game.SteamFolder } else { "" }
    $exe    = if ($Game.GameExe)     { [string]$Game.GameExe }     else { "" }

    $wrapper = $global:RunInstallerPath
    $argString =
        "-NoProfile -ExecutionPolicy Bypass -File `"$wrapper`" " +
        "-Title `"$title`" -Kind $kind -BatPath `"$BatPath`" -Ps1Path `"$ps1`" " +
        "-GameTitle `"$title`" -GameFolder `"$folder`" -GameExe `"$exe`" -LogsDir `"$logsDir`""

    if ($RequiresAdmin -and $kind -eq "Bat") {
        # Elevated install (e.g. Alien Isolation, which needs admin for a
        # Windows 11 registry fix): run the WRAPPER itself elevated - one UAC
        # prompt. The elevated wrapper spawns the installer .bat (which
        # inherits elevation, no second prompt) while Tee-Object inside the
        # elevated process still captures everything to Logs\. A bare
        # 'Start-Process $BatPath -Verb RunAs' could not be logged, because
        # output cannot be piped across the UAC elevation boundary.
        try {
            return (Start-Process "powershell.exe" -ArgumentList $argString -Verb RunAs -PassThru -ErrorAction Stop)
        } catch {
            # UAC declined or elevation failed: fall back to the un-elevated
            # wrapper. The installer detects it is not elevated and prints its
            # "needs admin" notice - and that now lands in the log too.
            try { return (Start-Process "powershell.exe" -ArgumentList $argString -PassThru) } catch { return $null }
        }
    }

    try { return (Start-Process "powershell.exe" -ArgumentList $argString -PassThru) } catch { return $null }
}

function global:Get-BannerColorForGame {
    param($Game)
    if (-not $Game) { return $null }
    if (-not $global:BannerColorMap) { return $null }
    $key = $null
    $hdr = [string]$Game.HeaderUrl
    if ($hdr -and ($hdr -notmatch '^https?://')) {
        $base = Split-Path $hdr -Leaf
        $base = $base -replace '_header\.\w+$', ''
        if ($base) { $key = 'name:' + $base }
    }
    if ((-not $key -or -not $global:BannerColorMap.ContainsKey($key)) -and $Game.SteamId) {
        $key = 'steam:' + [string]$Game.SteamId
    }
    if ($key -and $global:BannerColorMap.ContainsKey($key)) { return $global:BannerColorMap[$key] }
    return $null
}

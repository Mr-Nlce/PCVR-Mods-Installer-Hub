# ---------------------------------------------------------------
# "My Games": user-added non-Hub games (custom launcher)
# ---------------------------------------------------------------
# Lets the user add ANY game (Skyrim VR, native VR titles, other
# launchers) to the Hub and start it from there. Strictly a launcher:
# no install, no scan, no update badge, no mod detection.
#
# Off by default. Turned on from the Help & Feedback menu
# ("My Games (Beta)", setting key customGamesEnabled). While it is off
# no section, tile or handler exists - only this file is parsed.
#
# DATA LIVES OUTSIDE THE CATALOG AND OUTSIDE THE INSTALL FOLDER:
#   %LOCALAPPDATA%\PCVR Mods Installer Hub\CustomGames\CustomGames.json
#   %LOCALAPPDATA%\PCVR Mods Installer Hub\CustomGames\Art\<id>-<kind>.<ext>
# The Hub updater never touches it, Catalog.ps1 never sees it, and the
# scan / update / install code never iterates over it.
#
# This file holds the data side only (no WPF), so it is testable
# without a window. The UI is CustomGames.UI.ps1, loaded at the end.
#
# To remove the whole feature: delete the "CustomGames.ps1" line in
# VRModHub.ps1 plus CustomGames.ps1 and CustomGames.UI.ps1.
# ---------------------------------------------------------------

$global:CustomGamesSchema = 1

# Steam entries that are not games (runtimes, redistributables, SteamVR
# itself). Hidden in the import list unless "Show tools" is ticked.
$global:CustomGamesSteamToolIds = @(
    '228980',   # Steamworks Common Redistributables
    '250820',   # SteamVR
    '1070560',  # Steam Linux Runtime 1.0 (scout)
    '1391110',  # Steam Linux Runtime 2.0 (soldier)
    '1628350',  # Steam Linux Runtime 3.0 (sniper)
    '1493710',  # Proton Experimental
    '1826330',  # Proton EasyAntiCheat Runtime
    '1161040',  # Proton BattlEye Runtime
    '431960',   # Wallpaper Engine
    '1905180'   # OBS Studio
)
$global:CustomGamesSteamToolPattern = '^(Proton\b|Steam Linux Runtime|Steamworks Common|SteamVR\b|Steam Audio|Source SDK|Dedicated Server|.*\bDedicated Server$)'

# ---------------------------------------------------------------
# Storage
# ---------------------------------------------------------------
function global:Get-CustomGamesRoot {
    if ($global:CustomGamesRootOverride) {
        $root = [string]$global:CustomGamesRootOverride
    } else {
        $runtime = $null
        try { $runtime = Get-HubRuntimeRoot } catch { }
        if (-not $runtime) { return $null }
        $root = [IO.Path]::Combine($runtime, 'CustomGames')
    }
    try {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            New-Item -ItemType Directory -Path $root -Force -ErrorAction Stop | Out-Null
        }
    } catch { return $null }
    return $root
}

function global:Get-CustomGamesStorePath {
    $root = Get-CustomGamesRoot
    if (-not $root) { return $null }
    return [IO.Path]::Combine($root, 'CustomGames.json')
}

function global:Get-CustomGamesArtRoot {
    $root = Get-CustomGamesRoot
    if (-not $root) { return $null }
    $art = [IO.Path]::Combine($root, 'Art')
    try {
        if (-not (Test-Path -LiteralPath $art -PathType Container)) {
            New-Item -ItemType Directory -Path $art -Force -ErrorAction Stop | Out-Null
        }
    } catch { return $null }
    return $art
}

function global:New-CustomGameId {
    return ('custom-' + ([guid]::NewGuid().ToString('N').Substring(0, 12)))
}

function global:Test-CustomGameUri {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    # A drive letter ("C:\...") is a path, not a scheme.
    if ($Value -match '^[A-Za-z]:[\\/]') { return $false }
    return ($Value -match '^[A-Za-z][A-Za-z0-9+.\-]{1,}:')
}

# Normalizes any hashtable / object into the stored shape. Unknown
# fields are dropped, missing ones get defaults. Never throws.
function global:ConvertTo-CustomGameRecord {
    param($Source)
    $get = {
        param($name, $default)
        if ($null -eq $Source) { return $default }
        $v = $null
        if ($Source -is [System.Collections.IDictionary]) {
            if ($Source.Contains($name)) { $v = $Source[$name] }
        } else {
            $p = $Source.PSObject.Properties[$name]
            if ($p) { $v = $p.Value }
        }
        if ($null -eq $v) { return $default }
        return $v
    }
    $launchType = ([string](& $get 'launchType' 'exe')).Trim().ToLowerInvariant()
    if (@('steam', 'exe', 'uri') -notcontains $launchType) { $launchType = 'exe' }
    $playCount = 0
    try { $playCount = [int](& $get 'playCount' 0) } catch { $playCount = 0 }
    return [pscustomobject][ordered]@{
        id          = ([string](& $get 'id' '')).Trim()
        title       = ([string](& $get 'title' '')).Trim()
        launchType  = $launchType
        steamAppId  = ([string](& $get 'steamAppId' '')).Trim()
        exePath     = ([string](& $get 'exePath' '')).Trim().Trim('"')
        uri         = ([string](& $get 'uri' '')).Trim()
        arguments   = ([string](& $get 'arguments' '')).Trim()
        workingDir  = ([string](& $get 'workingDir' '')).Trim().Trim('"')
        runAsAdmin  = [bool](& $get 'runAsAdmin' $false)
        portrait    = ([string](& $get 'portrait' '')).Trim()
        wide        = ([string](& $get 'wide' '')).Trim()
        icon        = ([string](& $get 'icon' '')).Trim()
        accent      = ([string](& $get 'accent' '')).Trim()
        source      = ([string](& $get 'source' 'manual')).Trim()
        added       = ([string](& $get 'added' '')).Trim()
        lastPlayed  = ([string](& $get 'lastPlayed' '')).Trim()
        playCount   = $playCount
    }
}

# Returns a list of problems; empty list = valid.
function global:Test-CustomGameRecord {
    param($Record)
    $errors = @()
    if (-not $Record) { return @('No entry.') }
    if ([string]::IsNullOrWhiteSpace($Record.title)) { $errors += 'A name is required.' }
    switch ($Record.launchType) {
        'steam' {
            if ($Record.steamAppId -notmatch '^\d{1,10}$') { $errors += 'A numeric Steam App ID is required.' }
        }
        'exe' {
            if ([string]::IsNullOrWhiteSpace($Record.exePath)) { $errors += 'A program path is required.' }
        }
        'uri' {
            if (-not (Test-CustomGameUri $Record.uri)) { $errors += 'A link like com.epicgames.launcher://... or steam://... is required.' }
        }
    }
    if ($Record.steamAppId -and $Record.steamAppId -notmatch '^\d{1,10}$') {
        $errors += 'The Steam App ID must be a number.'
    }
    if ($Record.accent -and $Record.accent -notmatch '^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$') {
        $errors += 'The accent colour must look like #44cc66.'
    }
    return @($errors)
}

function global:Read-CustomGames {
    $global:CustomGamesLoadError = $null
    $path = Get-CustomGamesStorePath
    if (-not $path) {
        $global:CustomGamesLoadError = 'No writable data folder.'
        return @()
    }
    foreach ($candidate in @($path, "$path.bak")) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try {
            $raw = [IO.File]::ReadAllText($candidate)
            if ([string]::IsNullOrWhiteSpace($raw)) { continue }
            $doc = $raw | ConvertFrom-Json -ErrorAction Stop
            $list = @()
            $items = $doc.games
            # Windows PowerShell 5.1 can wrap arrays as {"value":[...],"Count":n}.
            if ($items -and $items.PSObject.Properties['value'] -and $items.PSObject.Properties['Count']) { $items = $items.value }
            foreach ($g in @($items)) {
                if ($null -eq $g) { continue }
                $rec = ConvertTo-CustomGameRecord $g
                if (-not $rec.id) { $rec.id = New-CustomGameId }
                $list += $rec
            }
            if ($candidate -ne $path) {
                $global:CustomGamesLoadError = 'CustomGames.json was unreadable - restored from CustomGames.json.bak.'
            }
            return @($list)
        } catch {
            $global:CustomGamesLoadError = ('Could not read {0}: {1}' -f [IO.Path]::GetFileName($candidate), $_.Exception.Message)
        }
    }
    return @()
}

# Atomic write: temp file, then replace (keeps the previous file as .bak).
function global:Save-CustomGames {
    param([object[]]$Games)
    $path = Get-CustomGamesStorePath
    if (-not $path) { throw 'No writable data folder for My Games.' }
    $doc = [ordered]@{
        schema = $global:CustomGamesSchema
        games  = [object[]]@(@($Games) | Where-Object { $_ } | ForEach-Object { ConvertTo-CustomGameRecord $_ })
    }
    $json = $doc | ConvertTo-Json -Depth 6
    $tmp = "$path.tmp"
    [IO.File]::WriteAllText($tmp, $json, [Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        [IO.File]::Replace($tmp, $path, "$path.bak")
    } else {
        [IO.File]::Move($tmp, $path)
    }
}

function global:Get-CustomGame {
    param([string]$Id)
    return (@(Read-CustomGames) | Where-Object { $_.id -eq $Id } | Select-Object -First 1)
}

# Finds an existing entry that points at the same thing.
function global:Find-CustomGameDuplicate {
    param($Record, [object[]]$Games)
    foreach ($g in @($Games)) {
        if ($Record.id -and $g.id -eq $Record.id) { continue }
        if ($Record.launchType -eq 'steam' -and $g.launchType -eq 'steam' -and
            $Record.steamAppId -and $g.steamAppId -eq $Record.steamAppId) { return $g }
        if ($Record.launchType -eq 'exe' -and $g.launchType -eq 'exe' -and $Record.exePath -and
            [string]::Equals($g.exePath, $Record.exePath, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($g.arguments, $Record.arguments, [StringComparison]::OrdinalIgnoreCase)) { return $g }
        if ($Record.launchType -eq 'uri' -and $g.launchType -eq 'uri' -and $Record.uri -and
            [string]::Equals($g.uri, $Record.uri, [StringComparison]::OrdinalIgnoreCase)) { return $g }
    }
    return $null
}

# Adds or replaces (same id) one entry. Returns the stored record.
function global:Save-CustomGame {
    param($Game, [switch]$AllowDuplicate)
    $rec = ConvertTo-CustomGameRecord $Game
    $problems = @(Test-CustomGameRecord $rec)
    if ($problems.Count -gt 0) { throw ($problems -join ' ') }
    $all = @(Read-CustomGames)
    if (-not $AllowDuplicate) {
        $dup = Find-CustomGameDuplicate -Record $rec -Games $all
        if ($dup) { throw ('"{0}" is already in My Games.' -f $dup.title) }
    }
    if (-not $rec.id) { $rec.id = New-CustomGameId }
    if (-not $rec.added) { $rec.added = (Get-Date).ToString('s') }
    $next = @()
    $replaced = $false
    foreach ($g in $all) {
        if ($g.id -eq $rec.id) { $next += $rec; $replaced = $true } else { $next += $g }
    }
    if (-not $replaced) { $next += $rec }
    Save-CustomGames -Games $next
    return $rec
}

# Removes the entry and ONLY the art files this feature created for it
# (inside its own Art folder). Never touches the game folder.
function global:Remove-CustomGame {
    param([string]$Id)
    if (-not $Id) { return $false }
    $all = @(Read-CustomGames)
    $keep = @($all | Where-Object { $_.id -ne $Id })
    if ($keep.Count -eq $all.Count) { return $false }
    Save-CustomGames -Games $keep
    $art = Get-CustomGamesArtRoot
    if ($art) {
        foreach ($f in @(Get-ChildItem -LiteralPath $art -File -Filter "$Id-*" -ErrorAction SilentlyContinue)) {
            try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop } catch { }
        }
    }
    return $true
}

function global:Set-CustomGamePlayed {
    param([string]$Id)
    $all = @(Read-CustomGames)
    $hit = $false
    foreach ($g in $all) {
        if ($g.id -eq $Id) {
            $g.lastPlayed = (Get-Date).ToString('s')
            $g.playCount = [int]$g.playCount + 1
            $hit = $true
        }
    }
    if ($hit) { Save-CustomGames -Games $all }
    return $hit
}

# Favorites first; within both groups keep the familiar recent-play order.
function global:Get-CustomGamesSorted {
    param([object[]]$Games)
    $played = @($Games | Where-Object { $_.lastPlayed } | Sort-Object -Property @{ Expression = { $_.lastPlayed }; Descending = $true }, @{ Expression = { $_.title } })
    $rest = @($Games | Where-Object { -not $_.lastPlayed } | Sort-Object -Property title)
    $ordered = @($played + $rest)
    $favoriteIds = @($global:FavoriteGameIds)
    return @(@($ordered | Where-Object { $favoriteIds -contains [string]$_.id }) +
             @($ordered | Where-Object { $favoriteIds -notcontains [string]$_.id }))
}

# ---------------------------------------------------------------
# Launch
# ---------------------------------------------------------------
# Returns what to start, or an Error text. Pure - starts nothing.
function global:Resolve-CustomGameLaunch {
    param($Game)
    $g = ConvertTo-CustomGameRecord $Game
    $result = [ordered]@{ Kind = $null; FilePath = $null; Arguments = ''; WorkingDirectory = ''; RunAsAdmin = $false; Error = $null }
    switch ($g.launchType) {
        'steam' {
            if ($g.steamAppId -notmatch '^\d+$') { $result.Error = 'No valid Steam App ID.'; break }
            $result.Kind = 'uri'
            if ($g.arguments) {
                # steam://run/<id>//<args>/ passes launch options for this start only.
                $result.FilePath = ('steam://run/{0}//{1}/' -f $g.steamAppId, [Uri]::EscapeDataString($g.arguments))
            } else {
                $result.FilePath = ('steam://rungameid/{0}' -f $g.steamAppId)
            }
        }
        'uri' {
            if (-not (Test-CustomGameUri $g.uri)) { $result.Error = 'No valid link.'; break }
            $result.Kind = 'uri'
            $result.FilePath = $g.uri
        }
        default {
            if (-not $g.exePath) { $result.Error = 'No program path.'; break }
            if (-not (Test-Path -LiteralPath $g.exePath -PathType Leaf)) {
                $result.Error = ('Program not found: {0}' -f $g.exePath); break
            }
            $result.Kind = 'exe'
            $result.FilePath = $g.exePath
            $result.Arguments = $g.arguments
            $wd = $g.workingDir
            if (-not $wd -or -not (Test-Path -LiteralPath $wd -PathType Container)) {
                $wd = [IO.Path]::GetDirectoryName($g.exePath)
            }
            $result.WorkingDirectory = $wd
            $result.RunAsAdmin = [bool]$g.runAsAdmin
        }
    }
    return [pscustomobject]$result
}

# 'ok' | 'missing' - only exe entries can be checked locally.
function global:Get-CustomGameAvailability {
    param($Game)
    if ($Game.launchType -eq 'exe') {
        if (-not $Game.exePath -or -not (Test-Path -LiteralPath $Game.exePath -PathType Leaf)) { return 'missing' }
    }
    return 'ok'
}

# ---------------------------------------------------------------
# Steam import
# ---------------------------------------------------------------
function global:Get-CustomGamesSteamLibraries {
    if ($global:CustomGamesSteamLibrariesOverride) { return @($global:CustomGamesSteamLibrariesOverride) }
    if (Get-Command Get-HubSteamLibraries -ErrorAction SilentlyContinue) {
        try { return @(Get-HubSteamLibraries) } catch { }
    }
    return @()
}

function global:Get-CustomGamesSteamRoot {
    if ($global:CustomGamesSteamRootOverride) { return [string]$global:CustomGamesSteamRootOverride }
    if (Get-Command Get-HubSteamInstallPath -ErrorAction SilentlyContinue) {
        try { return (Get-HubSteamInstallPath) } catch { }
    }
    return $null
}

# Top-level "key" "value" pairs of an appmanifest_*.acf.
function global:Read-SteamAcfValues {
    param([string]$Path)
    $values = @{}
    try {
        $text = [IO.File]::ReadAllText($Path)
        # Only the first nesting level ("AppState" { ... }) - nested blocks
        # like UserConfig / InstalledDepots carry their own "name" keys.
        $depth = 0
        foreach ($line in ($text -split "`r?`n")) {
            $t = $line.Trim()
            if ($t -eq '{') { $depth++; continue }
            if ($t -eq '}') { $depth--; continue }
            if ($depth -ne 1) { continue }
            $m = [regex]::Match($t, '^"([^"]+)"\s+"((?:[^"\\]|\\.)*)"')
            if ($m.Success) {
                $key = $m.Groups[1].Value.ToLowerInvariant()
                if (-not $values.ContainsKey($key)) {
                    $values[$key] = ($m.Groups[2].Value -replace '\\\\', '\')
                }
            }
        }
    } catch { }
    return $values
}

# Steam AppIDs that already have a Hub catalog entry.
function global:Get-CustomGamesCatalogSteamIds {
    $ids = @{}
    foreach ($g in @($global:CustomGamesCatalogGames)) {
        if ($g -and $g.SteamId) { $ids[[string]$g.SteamId] = [string]$g.Title }
    }
    return $ids
}

function global:Get-SteamInstalledApps {
    $catalogIds = Get-CustomGamesCatalogSteamIds
    $existing = @{}
    foreach ($g in @(Read-CustomGames)) {
        if ($g.steamAppId) { $existing[$g.steamAppId] = $true }
    }
    $seen = @{}
    $apps = @()
    foreach ($lib in @(Get-CustomGamesSteamLibraries)) {
        if (-not $lib) { continue }
        $steamapps = [IO.Path]::Combine([string]$lib, 'steamapps')
        if (-not (Test-Path -LiteralPath $steamapps -PathType Container)) { continue }
        foreach ($acf in @(Get-ChildItem -LiteralPath $steamapps -File -Filter 'appmanifest_*.acf' -ErrorAction SilentlyContinue)) {
            $v = Read-SteamAcfValues -Path $acf.FullName
            $appId = [string]$v['appid']
            if (-not $appId) {
                $m = [regex]::Match($acf.Name, 'appmanifest_(\d+)\.acf')
                if ($m.Success) { $appId = $m.Groups[1].Value }
            }
            if (-not $appId -or $seen.ContainsKey($appId)) { continue }
            $seen[$appId] = $true
            $name = [string]$v['name']
            if (-not $name) { $name = "Steam app $appId" }
            $installDir = $null
            if ($v['installdir']) { $installDir = [IO.Path]::Combine($steamapps, 'common', [string]$v['installdir']) }
            $isTool = ($global:CustomGamesSteamToolIds -contains $appId) -or ($name -match $global:CustomGamesSteamToolPattern)
            $apps += [pscustomobject]@{
                AppId        = $appId
                Name         = $name
                InstallDir   = $installDir
                Library      = [string]$lib
                IsTool       = [bool]$isTool
                HubTitle     = if ($catalogIds.ContainsKey($appId)) { $catalogIds[$appId] } else { $null }
                AlreadyAdded = [bool]$existing.ContainsKey($appId)
            }
        }
    }
    return @($apps | Sort-Object -Property Name)
}

# Imports picked Steam apps in one write. Returns the number added.
function global:Import-SteamAppsAsCustomGames {
    param([object[]]$Apps)
    $all = @(Read-CustomGames)
    $added = 0
    foreach ($app in @($Apps)) {
        if (-not $app -or [string]$app.AppId -notmatch '^\d+$') { continue }
        $rec = ConvertTo-CustomGameRecord @{
            id = (New-CustomGameId); title = [string]$app.Name; launchType = 'steam'
            steamAppId = [string]$app.AppId; source = 'steam'; added = (Get-Date).ToString('s')
        }
        if (Find-CustomGameDuplicate -Record $rec -Games $all) { continue }
        $all += $rec
        $added++
    }
    if ($added -gt 0) { Save-CustomGames -Games $all }
    return $added
}

# ---------------------------------------------------------------
# Artwork
# ---------------------------------------------------------------
$global:CustomGamesArtExtensions = @('.jpg', '.jpeg', '.png', '.bmp', '.gif')

# Copies a user-picked image into the feature's own Art folder.
# Returns the stored file name (relative to Art), never the source path,
# so the entry keeps working after the original is moved or deleted.
function global:Import-CustomGameArt {
    param([string]$Id, [string]$SourcePath, [ValidateSet('portrait', 'wide')][string]$Kind)
    if (-not $Id -or -not $SourcePath) { throw 'Missing image or entry.' }
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) { throw ('Image not found: {0}' -f $SourcePath) }
    $ext = [IO.Path]::GetExtension($SourcePath).ToLowerInvariant()
    if ($global:CustomGamesArtExtensions -notcontains $ext) { throw ('Unsupported image type {0} - use JPG or PNG.' -f $ext) }
    $art = Get-CustomGamesArtRoot
    if (-not $art) { throw 'No writable data folder for artwork.' }
    foreach ($old in @(Get-ChildItem -LiteralPath $art -File -Filter "$Id-$Kind.*" -ErrorAction SilentlyContinue)) {
        try { Remove-Item -LiteralPath $old.FullName -Force -ErrorAction Stop } catch { }
    }
    $name = "$Id-$Kind$ext"
    Copy-Item -LiteralPath $SourcePath -Destination ([IO.Path]::Combine($art, $name)) -Force -ErrorAction Stop
    return $name
}

function global:Resolve-CustomGameArtPath {
    param([string]$Name)
    if (-not $Name) { return $null }
    $art = Get-CustomGamesArtRoot
    if (-not $art) { return $null }
    $p = [IO.Path]::Combine($art, [IO.Path]::GetFileName($Name))
    if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }
    return $null
}

# Steam's own local artwork cache - works offline. Covers the old flat
# layout (<id>_library_600x900.jpg) and the newer per-app folders
# (<id>\library_600x900.jpg, sometimes one hash folder deeper).
function global:Get-SteamLocalArtPath {
    param([string]$AppId, [ValidateSet('portrait', 'wide', 'hero')][string]$Kind)
    if ($AppId -notmatch '^\d+$') { return $null }
    $steam = Get-CustomGamesSteamRoot
    if (-not $steam) { return $null }
    $cache = [IO.Path]::Combine($steam, 'appcache', 'librarycache')
    if (-not (Test-Path -LiteralPath $cache -PathType Container)) { return $null }
    $file = switch ($Kind) { 'portrait' { 'library_600x900' } 'wide' { 'header' } default { 'library_hero' } }
    foreach ($candidate in @(
        [IO.Path]::Combine($cache, "${AppId}_$file.jpg"),
        [IO.Path]::Combine($cache, $AppId, "$file.jpg")
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    $appDir = [IO.Path]::Combine($cache, $AppId)
    if (Test-Path -LiteralPath $appDir -PathType Container) {
        $hit = Get-ChildItem -LiteralPath $appDir -Recurse -Depth 1 -File -Filter "$file*.jpg" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function global:ConvertTo-CustomGameUri {
    param([string]$Path)
    if (-not $Path) { return $null }
    if (Get-Command ConvertTo-HubFileUri -ErrorAction SilentlyContinue) {
        try { return (ConvertTo-HubFileUri -Path $Path) } catch { }
    }
    try { return ([Uri]::new([IO.Path]::GetFullPath($Path))).AbsoluteUri } catch { return $null }
}

# Ordered candidate list for the tile image. The loader
# (Set-SafeBannerImage) walks it until one decodes; if none does, the
# tile keeps its generated title card.
function global:Get-CustomGameArtUris {
    param($Game, [ValidateSet('portrait', 'wide')][string]$Kind = 'portrait')
    $uris = @()
    $own = if ($Kind -eq 'portrait') { $Game.portrait } else { $Game.wide }
    $p = Resolve-CustomGameArtPath $own
    if ($p) { $uris += (ConvertTo-CustomGameUri $p) }
    $appId = [string]$Game.steamAppId
    if ($appId -match '^\d+$') {
        $local = Get-SteamLocalArtPath -AppId $appId -Kind $Kind
        if ($local) { $uris += (ConvertTo-CustomGameUri $local) }
        $hubKind = if ($Kind -eq 'portrait') { 'portrait' } else { 'header' }
        if (Get-Command Get-CachedImageUri -ErrorAction SilentlyContinue) {
            try { $c = Get-CachedImageUri -SteamId $appId -Kind $hubKind; if ($c) { $uris += $c } } catch { }
        }
        if ($Kind -eq 'portrait') {
            $uris += "https://cdn.akamai.steamstatic.com/steam/apps/$appId/library_600x900.jpg"
            $uris += "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/library_600x900.jpg"
        } else {
            $uris += "https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg"
            $uris += "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/header.jpg"
        }
    }
    return @($uris | Where-Object { $_ })
}

# Exe icon as PNG, for entries without any artwork. Windows only.
function global:Export-CustomGameExeIcon {
    param([string]$Id, [string]$ExePath)
    if (-not $Id -or -not $ExePath -or -not (Test-Path -LiteralPath $ExePath -PathType Leaf)) { return $null }
    $art = Get-CustomGamesArtRoot
    if (-not $art) { return $null }
    $name = "$Id-icon.png"
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
        if (-not $icon) { return $null }
        $bmp = $icon.ToBitmap()
        try { $bmp.Save([IO.Path]::Combine($art, $name), [System.Drawing.Imaging.ImageFormat]::Png) }
        finally { $bmp.Dispose(); $icon.Dispose() }
        return $name
    } catch { return $null }
}

# Stable accent per entry when the user picked none.
function global:Get-CustomGameAccent {
    param($Game)
    if ($Game.accent -match '^#[0-9A-Fa-f]{6}') { return [string]$Game.accent }
    $palette = @('#7c5cff', '#2fa8c8', '#44cc66', '#dd6600', '#c84a8a', '#c7a13a', '#3a8add', '#9a6ad8')
    $seed = 0
    foreach ($ch in ([string]$Game.title).ToCharArray()) { $seed = ($seed * 31 + [int]$ch) % 2147483647 }
    return $palette[$seed % $palette.Count]
}

# ---------------------------------------------------------------
# UI (WPF) - only loaded when a window exists
# ---------------------------------------------------------------
if ($global:window -and -not $global:CustomGamesSkipUi) {
    try {
        if (Get-Command Get-HubModuleScript -ErrorAction SilentlyContinue) { . (Get-HubModuleScript (Join-Path $PSScriptRoot 'CustomGames.UI.ps1')) } else { . (Join-Path $PSScriptRoot 'CustomGames.UI.ps1') }
    } catch {
        try { Write-HubTiming ("customgames: UI disabled after error: {0}" -f $_.Exception.Message) } catch { }
    }
}

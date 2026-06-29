# ===============================================================
# Banner + Discover Overview page
# ===============================================================

# Genre buckets - rendering order on the Overview page. Tags
# from each game are matched against these substrings (case-
# insensitive). One game can land in multiple rows.
$global:OverviewGenres = @(
    @{ Key="HORROR";    Label="Horror & survival";   Match=@("horror", "survival") },
    @{ Key="ACTION";    Label="Action & shooter";    Match=@("action", "fps", "shooter", "fast paced", "fighting") },
    @{ Key="ADVENTURE"; Label="Adventure & story";   Match=@("adventure", "story", "narrative", "exploration", "walking sim", "atmospheric") },
    @{ Key="RPG";       Label="RPG";                 Match=@("rpg", "souls-like", "open world") },
    @{ Key="COOP";      Label="Co-op & multiplayer"; Match=@("coop", "multiplayer") },
    @{ Key="PUZZLE";    Label="Puzzle & platformer"; Match=@("puzzle", "platformer") },
    @{ Key="SIM";       Label="Simulation & racing"; Match=@("sim", "racing", "sports", "fishing", "driving") }
)

# 4-bucket PC power filter, mapped from 6 underlying tiers.
$global:OverviewPowerBuckets = @(
    @{ Key="LOW";     Label="Low";     Color="#66cc66"; Tiers=@("LOW","BASIC") },
    @{ Key="SOLID";   Label="Solid";   Color="#ddcc44"; Tiers=@("SOLID") },
    @{ Key="HIGH";    Label="High";    Color="#dd6644"; Tiers=@("STRONG","HIGH") },
    @{ Key="EXTREME"; Label="Extreme"; Color="#dd3333"; Tiers=@("EXTREME") }
)

# Bucket index lookup - used for cumulative filter ("show me
# everything up to my PC's level"). LOW=0, SOLID=1, HIGH=2,
# EXTREME=3.
function global:Get-OverviewPowerBucketIndex {
    param([string]$Key)
    for ($i = 0; $i -lt $global:OverviewPowerBuckets.Count; $i++) {
        if ($global:OverviewPowerBuckets[$i].Key -eq $Key) { return $i }
    }
    return -1
}

function global:Get-GamePowerBucket {
    param($Game)
    if (-not (Get-Command Get-PowerTier -ErrorAction SilentlyContinue)) { return "SOLID" }
    $tier = Get-PowerTier -Game $Game
    if (-not $tier -or $tier.StartIdx -eq $null) { return "SOLID" }
    switch ($tier.StartIdx) {
        0 { return "LOW" }
        1 { return "LOW" }
        2 { return "SOLID" }
        3 { return "HIGH" }
        4 { return "HIGH" }
        5 { return "EXTREME" }
        default { return "SOLID" }
    }
}

function global:Test-OverviewGameInGenre {
    param($Game, $Genre)
    if (-not $Game.Tags) { return $false }
    if ($Genre.Match.Count -eq 0) { return $true }
    foreach ($tag in $Game.Tags) {
        $tagLower = $tag.ToString().ToLower()
        foreach ($m in $Genre.Match) {
            if ($tagLower -like "*$m*") { return $true }
        }
    }
    return $false
}

function global:New-OverviewTile {
    param($Game)
    $sizeKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $dim = $global:OverviewTileSizes[$sizeKey]
    if (-not $dim) { $dim = $global:OverviewTileSizes["M"] }

    $tile = New-Object System.Windows.Controls.Border
    $tile.Width  = $dim.W
    $tile.Height = $dim.H
    # Vertical margin big enough that the hover glow (drop-shadow,
    # blur radius ~14) can render above and below the tile without
    # being clipped by the row's StackPanel/ScrollViewer. Without
    # this the glow only reads on the left and right sides.
    $tile.Margin = [System.Windows.Thickness]::new(0, 14, 10, 14)
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $tile.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
    # Border stays 1px in every state - only color changes - so the
    # press glow doesn't shift the tile geometry.
    $tile.BorderThickness = [System.Windows.Thickness]::new(1)
    $tile.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32")
    $tile.Cursor = [System.Windows.Input.Cursors]::Hand
    # ClipToBounds must stay false so the hover glow (drop-shadow
    # effect) can render outside the tile rectangle. The image
    # inside is already constrained by the parent grid + Stretch
    # mode so visible content does not bleed out.
    $tile.ClipToBounds = $false

    $grid = New-Object System.Windows.Controls.Grid
    # Inner grid clips so the image and gradient stay inside the
    # tile's rounded rectangle. The outer Border keeps
    # ClipToBounds = false so the hover drop-shadow can render
    # outside the tile geometry.
    $grid.ClipToBounds = $true
    $tile.Child = $grid

    $portraitUrl = Get-GameImageUrl -Game $Game -Kind "portrait"
    $headerUrl   = Get-GameImageUrl -Game $Game -Kind "header"
    if ($portraitUrl) {
        $img = New-Object System.Windows.Controls.Image
        $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
        $urls = @()
        if ($Game.SteamId) {
            $cachedPortrait = Get-CachedImageUri -SteamId $Game.SteamId -Kind "portrait"
            if ($cachedPortrait) { $urls += $cachedPortrait }
        }
        $urls += $portraitUrl
        if ($Game.SteamId) { $urls += (Get-SteamPortraitUrlFastly $Game.SteamId) }
        if ($headerUrl) { $urls += $headerUrl }
        Set-SafeBannerImage -ImageEl $img -Urls $urls
        $grid.Children.Add($img) | Out-Null

        $gradRect = New-Object System.Windows.Shapes.Rectangle
        $gradRect.Height = 65
        $gradRect.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $gb = New-Object System.Windows.Media.LinearGradientBrush
        $gb.StartPoint = New-Object System.Windows.Point 0, 0
        $gb.EndPoint   = New-Object System.Windows.Point 0, 1
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,0,0,0)), 0.0)) | Out-Null
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(240,0,0,0)), 1.0)) | Out-Null
        $gradRect.Fill = $gb
        $grid.Children.Add($gradRect) | Out-Null
    }

    # Controls pill top-left, native hub colors
    $ctrlLabel = switch ($Game.Controls) {
        "MC"   { "MOTION" }
        "GP"   { "GAMEPAD" }
        "BOTH" { "BOTH" }
        default { "" }
    }
    $ctrlBgHex = switch ($Game.Controls) {
        "MC"   { "#44cc66" }
        "GP"   { "#dd6600" }
        "BOTH" { "#8888ff" }
        default { "#888888" }
    }
    $ctrlFgHex = switch ($Game.Controls) {
        "MC"   { "#0a1a0a" }
        default { "#ffffff" }
    }
    if ($ctrlLabel) {
        $ctrlPill = New-Object System.Windows.Controls.Border
        $ctrlPill.CornerRadius = [System.Windows.CornerRadius]::new(2)
        $ctrlPill.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
        $ctrlPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $ctrlPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $ctrlPill.Margin = [System.Windows.Thickness]::new(6, 6, 0, 0)
        $ctrlPill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ctrlBgHex)
        $ctrlTxt = New-Object System.Windows.Controls.TextBlock
        $ctrlTxt.Text = $ctrlLabel
        $ctrlTxt.FontSize = 8
        $ctrlTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $ctrlTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ctrlFgHex)
        $ctrlTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $ctrlPill.Child = $ctrlTxt
        $grid.Children.Add($ctrlPill) | Out-Null
    }

    # FREE pill bottom-right for free-to-play titles. Uses the exact
    # same style as the FREE badge everywhere else (CardTile): mint
    # green border, translucent green fill, bold green text. The title
    # sits bottom-left, so this balances it on the same baseline.
    if ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title)) {
        $freePill = New-Object System.Windows.Controls.Border
        $freePill.CornerRadius = [System.Windows.CornerRadius]::new(2)
        $freePill.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
        $freePill.BorderThickness = [System.Windows.Thickness]::new(1)
        $freePill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freePill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 52, 211, 153))
        $freePill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $freePill.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $freePill.Margin = [System.Windows.Thickness]::new(0, 0, 6, 7)
        $freeTxt = New-Object System.Windows.Controls.TextBlock
        $freeTxt.Text = "FREE"
        $freeTxt.FontSize = 8
        $freeTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $freePill.Child = $freeTxt
        $grid.Children.Add($freePill) | Out-Null
    }

    $titleTxt = New-Object System.Windows.Controls.TextBlock
    $titleTxt.Text = $Game.Title
    $titleTxt.FontSize = 11
    $titleTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $titleTxt.Foreground = [System.Windows.Media.Brushes]::White
    $titleTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $titleTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $titleTxt.Margin = [System.Windows.Thickness]::new(8, 0, 8, 7)
    $titleTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $grid.Children.Add($titleTxt) | Out-Null

    # Press-flash overlay tinted in the game's own accent color.
    # Sits on top of image + title; hidden until press (Opacity=0).
    # Each game now glows in its own theme color when clicked.
    $flash = New-Object System.Windows.Shapes.Rectangle
    $flashHex = if ($Game.Accent) { $Game.Accent } else { "#ffcc66" }
    $flash.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($flashHex)
    $flash.Opacity = 0
    $flash.IsHitTestVisible = $false
    $flash.RadiusX = 5
    $flash.RadiusY = 5
    $grid.Children.Add($flash) | Out-Null

    $tile.Resources.Add("game", $Game)
    $tile.Resources.Add("flash", $flash)

    # Glow: an outer drop-shadow tinted to the game's accent
    # colour. Pre-attached with Opacity 0 so it costs nothing at
    # idle, then faded in on MouseEnter. We pre-brighten the
    # accent toward white so dark accents still read as a glow,
    # and keep the blur tight so it reads as a clean rim, not a
    # soft halo. ShadowDepth = 0 paints the shadow evenly around
    # all four sides instead of biasing one direction.
    $accentRaw = if ($Game.Accent) { $Game.Accent } else { "#ffcc66" }
    $accentColor = [System.Windows.Media.ColorConverter]::ConvertFromString($accentRaw)
    # Brighten 50% toward white so it actually glows.
    $glowR = [byte]([Math]::Round($accentColor.R * 0.5 + 255 * 0.5))
    $glowG = [byte]([Math]::Round($accentColor.G * 0.5 + 255 * 0.5))
    $glowB = [byte]([Math]::Round($accentColor.B * 0.5 + 255 * 0.5))
    $glowColor = [System.Windows.Media.Color]::FromRgb($glowR, $glowG, $glowB)
    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color = $glowColor
    $glow.BlurRadius = 14
    $glow.ShadowDepth = 0
    $glow.Opacity = 0
    $tile.Effect = $glow
    $tile.Resources.Add("glow", $glow)

    # Closures must capture these before any event handler is
    # attached - GetNewClosure() snapshots variables at the time
    # the script block is created, not when it runs.
    $gameCapture = $Game
    $flashCap = $flash
    $glowCap = $glow

    $tile.Add_MouseLeftButtonUp({
        # Defer one dispatcher tick at Background priority so the
        # press visuals commit a frame before navigation runs.
        $global:DetailOrigin = "OVERVIEW"
        $gameCap = $gameCapture
        $disp = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        [void]$disp.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{ Show-DiscoverDetail -Game $gameCap }.GetNewClosure()
        )
    }.GetNewClosure())

    # Press: tinted overlay flash at 10% opacity + glow stays lit.
    # Tag marks the tile as "pressed" so MouseLeave below doesn't
    # tear down the visual feedback while the page is loading.
    # An auto-reset timer runs after 2.6s to clear ALL state
    # (flash + scale + glow + border + tag) no matter what -
    # prevents stuck visuals when the user returns from the
    # detail page.
    $tile.Add_MouseLeftButtonDown({
        $flashCap.Opacity = 0.10
        $this.Tag = "pressed"
        $tileCap = $this
        $fcap = $flashCap
        $gcap = $glowCap
        $resetT = New-Object System.Windows.Threading.DispatcherTimer
        $resetT.Interval = [TimeSpan]::FromMilliseconds(1200)
        $resetT.Add_Tick({
            $this.Stop()
            $fcap.Opacity = 0
            $gcap.Opacity = 0
            $tileCap.Tag = $null
            $tileCap.RenderTransform = $null
            $tileCap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32")
        }.GetNewClosure())
        $resetT.Start()
    }.GetNewClosure())

    $tile.Add_MouseEnter({
        # Hover: scale up, hide the static border, light up the glow.
        $sc = New-Object System.Windows.Media.ScaleTransform 1.06, 1.06
        $this.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $this.RenderTransform = $sc
        $this.BorderBrush = [System.Windows.Media.Brushes]::Transparent
        $glowCap.Opacity = 0.95
    }.GetNewClosure())
    $tile.Add_MouseLeave({
        # During "pressed" we keep ALL visuals (scale + flash +
        # glow) intact so the press reads as confirmed while the
        # detail page is loading. The 2.6s auto-reset is the only
        # path that clears glow during pressed - guarantees no
        # stuck glow when the user comes back.
        if ($this.Tag -eq "pressed") { return }
        $flashCap.Opacity = 0
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32")
        $this.RenderTransform = $null
        $glowCap.Opacity = 0
    }.GetNewClosure())

    return $tile
}

# Random featured-game pick. Excludes UEVR and Pragmata since
# those are too buggy / preliminary to feature. Heavily favors
# motion-controls titles (70/30) since most users come for the
# immersive option - gamepad still appears, just less often.
#
# Shuffle UX: when the user clicks Shuffle, the random pick is
# allowed to return the SAME title that is currently on the
# banner, which makes the click look like a no-op and forces a
# second click. We exclude $global:OvBannerGame from the pool
# (when the pool has more than one game) so every shuffle click
# advances to a different title.
function global:Get-FeaturedRandomGame {
    $pool = @()
    $pool += $ownGames
    $pool += $ownGamesGP
    $pool += $externalGames
    $blockTitles = @("UEVR", "Pragmata VR")
    $currentTitle = if ($global:OvBannerGame) { $global:OvBannerGame.Title } else { $null }

    $motionPool  = @()
    $gamepadPool = @()
    foreach ($g in $pool) {
        $skip = $false
        foreach ($bad in $blockTitles) {
            if ($g.Title -eq $bad) { $skip = $true; break }
        }
        if ($skip -or -not $g.Title) { continue }
        # BOTH counts as motion - it has motion-control support too.
        if ($g.Controls -eq "MC" -or $g.Controls -eq "BOTH") {
            $motionPool += $g
        } elseif ($g.Controls -eq "GP") {
            $gamepadPool += $g
        } else {
            # Unknown / unset controls fall in with motion as the
            # better default - hub games largely support motion.
            $motionPool += $g
        }
    }

    # Strip the currently-displayed game so a shuffle never lands
    # on itself. Only filter when the resulting pool would still
    # have entries left - tiny single-game pools degrade to the
    # original behaviour.
    if ($currentTitle) {
        $motionFiltered  = @($motionPool  | Where-Object { $_.Title -ne $currentTitle })
        $gamepadFiltered = @($gamepadPool | Where-Object { $_.Title -ne $currentTitle })
        if ($motionFiltered.Count  -gt 0) { $motionPool  = $motionFiltered }
        if ($gamepadFiltered.Count -gt 0) { $gamepadPool = $gamepadFiltered }
    }

    # 70/30 split. If a pool is empty, fall back to the other.
    $useMotion = (Get-Random -Minimum 0 -Maximum 100) -lt 70
    if ($useMotion -and $motionPool.Count -gt 0) {
        return $motionPool[(Get-Random -Minimum 0 -Maximum $motionPool.Count)]
    }
    if (-not $useMotion -and $gamepadPool.Count -gt 0) {
        return $gamepadPool[(Get-Random -Minimum 0 -Maximum $gamepadPool.Count)]
    }
    # Fallback: whichever pool has games
    $either = if ($motionPool.Count -gt 0) { $motionPool } else { $gamepadPool }
    if ($either.Count -eq 0) { return $null }
    return $either[(Get-Random -Minimum 0 -Maximum $either.Count)]
}

# Genre-aware banner pick - filters the random pool to games that
# match one of the genre's tag synonyms, so when the user clicks
# "Action & shooter" on the Explore page the featured banner shows
# an action game rather than whatever ALL-pool random pulled.
# Falls back to the unfiltered random pick if the filtered pool
# ends up empty (which shouldn't happen for the canonical genres
# but is cheap insurance).
function global:Get-FeaturedRandomGameForGenre {
    param([string]$GenreKey)

    if (-not $GenreKey -or $GenreKey -eq "ALL") {
        return Get-FeaturedRandomGame
    }

    # Look up the genre's match-list (the same synonyms used to
    # bucket games into rows on the Explore page).
    $genreDef = $null
    foreach ($g in $global:OverviewGenres) {
        if ($g.Key -eq $GenreKey) { $genreDef = $g; break }
    }
    if (-not $genreDef -or -not $genreDef.Match) {
        return Get-FeaturedRandomGame
    }

    $pool = @()
    $pool += $ownGames
    $pool += $ownGamesGP
    $pool += $externalGames
    $blockTitles = @("UEVR", "Pragmata VR")
    $currentTitle = if ($global:OvBannerGame) { $global:OvBannerGame.Title } else { $null }

    $matchedPool = @()
    foreach ($g in $pool) {
        $skip = $false
        foreach ($bad in $blockTitles) {
            if ($g.Title -eq $bad) { $skip = $true; break }
        }
        if ($skip -or -not $g.Title -or -not $g.Tags) { continue }

        # Use the exact same matcher the rows use (substring against
        # the genre's synonyms) so the banner pool is identical to the
        # genre row - otherwise tags like "simulation" land in the SIM
        # row but never on the SIM banner.
        if (Test-OverviewGameInGenre -Game $g -Genre $genreDef) { $matchedPool += $g }
    }

    # Same anti-no-op as Get-FeaturedRandomGame: drop the current
    # banner game from the pool when there's an alternative left.
    if ($currentTitle -and $matchedPool.Count -gt 1) {
        $matchedPool = @($matchedPool | Where-Object { $_.Title -ne $currentTitle })
    }

    if ($matchedPool.Count -eq 0) {
        return Get-FeaturedRandomGame
    }
    return $matchedPool[(Get-Random -Minimum 0 -Maximum $matchedPool.Count)]
}

# Fill a banner with a random game's art and meta.
function global:Set-BannerForGame {
    param($Game, $TitleEl, $SubEl, $ImageEl, $BgEl, $DotEl, $KickerEl, [string]$KickerPrefix = "FEATURED VR MOD")
    if (-not $Game) { return }
    if ($TitleEl) {
        # Fit the title to the banner width by dropping whole trailing
        # words rather than letting WPF cut mid-word with an ellipsis
        # (e.g. "Apollo Justice: Ace Attorney Trilogy ..."). We measure
        # with FormattedText and step back word by word until it fits.
        $fullTitle = [string]$Game.Title
        $fitted = $fullTitle
        try {
            $maxW = if ($TitleEl.MaxWidth -and $TitleEl.MaxWidth -gt 0 -and -not [double]::IsInfinity($TitleEl.MaxWidth)) { $TitleEl.MaxWidth } else { 400 }
            $tf = New-Object System.Windows.Media.Typeface(
                $TitleEl.FontFamily, $TitleEl.FontStyle, $TitleEl.FontWeight, $TitleEl.FontStretch)
            $measure = {
                param($txt)
                $ppd = 1.0
                try { $ppd = [System.Windows.Media.VisualTreeHelper]::GetDpi($TitleEl).PixelsPerDip } catch { $ppd = 1.0 }
                $ft = New-Object System.Windows.Media.FormattedText(
                    $txt, [System.Globalization.CultureInfo]::CurrentCulture,
                    [System.Windows.FlowDirection]::LeftToRight, $tf,
                    $TitleEl.FontSize, [System.Windows.Media.Brushes]::White, $ppd)
                return $ft.WidthIncludingTrailingWhitespace
            }
            if ((& $measure $fitted) -gt $maxW) {
                $words = $fitted -split '\s+'
                while ($words.Count -gt 1) {
                    $words = $words[0..($words.Count - 2)]
                    $candidate = ($words -join ' ')
                    if ((& $measure $candidate) -le $maxW) { $fitted = $candidate; break }
                    $fitted = $candidate
                }
            }
        } catch { $fitted = $fullTitle }
        $TitleEl.Text = $fitted
    }
    if ($SubEl) {
        # Whitelist of real genre/mood words. Anything not in
        # this set is treated as a name-slug or mod-slug and
        # filtered out. Keeps the subtitle reading like a steam
        # genre line ("Action  -  Fast Paced").
        $genreWords = @(
            "action", "action rpg", "adventure", "anime", "arcade",
            "atmospheric", "bmx", "boomer shooter", "bullet hell",
            "cartoon", "casual", "classic", "climbing", "collectathon",
            "combat", "comedy", "comic", "competitive", "coop", "co-op",
            "crafting", "cyberpunk", "dark fantasy", "downhill",
            "driving", "exploration", "fan game", "fantasy", "farming",
            "fast paced", "fast-paced", "fighting", "first-person",
            "fishing", "fps", "graffiti", "hack and slash", "hacking",
            "horror", "hunting", "indie", "japanese", "jrpg",
            "lightsaber", "medieval", "metroidvania", "mining", "mmo",
            "mmorpg", "multiplayer", "music", "mystery", "narrative",
            "ocean", "open world", "physics", "platformer",
            "post-apocalyptic", "prehistoric", "puzzle", "racing",
            "rail shooter", "rally", "realistic", "retro", "rhythm",
            "roguelike", "roguelite", "rpg", "samurai", "sandbox",
            "sci-fi", "shooter", "simulation", "skating", "souls-like",
            "soulslike", "space", "speedrun", "sports", "stealth",
            "story", "strategy", "stylish", "submersed", "superhero",
            "supernatural", "survival", "survival horror", "top down",
            "top-down", "tropical", "turn-based", "underwater",
            "viking", "visual novel", "walking sim", "wildlife",
            "zombies"
        )
        $tags = @()
        $seen = @{}
        # Some genre tokens are acronyms and should always render in
        # all-caps - title-casing "fps" produces the visually wrong
        # "Fps". Anything not in this list goes through the normal
        # ToTitleCase path.
        $acronymGenres = @("fps", "rpg", "mmo", "mmorpg", "jrpg")
        # If the game has an ImprovementTag ("+ VR improvement", set on
        # entries like Fallout 4 VR and Skyrim VR where we only ship VR
        # improvement modlists for an already-VR base game), cap genre
        # tags at 2 to leave room for a blue "VR improvement" tag in
        # third position - matches the card-tile blue banner.
        $maxGenreTags = if ($Game.ImprovementTag -or $Game.InjectorTag) { 2 } else { 3 }
        # Track the individual words already shown as genre pills, so a
        # compound genre ("survival horror") suppresses its loose
        # components ("horror", "survival") and no word repeats across
        # pills. Split on spaces only - hyphenated genres ("souls-like",
        # "sci-fi", "first-person") are single concepts, not compounds.
        $usedGenreWords = @{}
        if ($Game.Tags) {
            foreach ($t in $Game.Tags) {
                $tl = $t.ToString().ToLower().Trim()
                if (-not ($genreWords -contains $tl)) { continue }
                if ($seen.ContainsKey($tl)) { continue }
                # Skip if any word of this genre is already on a pill we
                # picked (compound-vs-component overlap, e.g. "horror"
                # after "survival horror").
                $gWords = $tl -split '\s+'
                $gOverlap = $false
                foreach ($gw in $gWords) { if ($usedGenreWords.ContainsKey($gw)) { $gOverlap = $true; break } }
                if ($gOverlap) { continue }
                $seen[$tl] = $true
                foreach ($gw in $gWords) { $usedGenreWords[$gw] = $true }
                if ($acronymGenres -contains $tl) {
                    $tags += $tl.ToUpper()
                } else {
                    $tags += [Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($tl)
                }
                if ($tags.Count -ge $maxGenreTags) { break }
            }
        }
        # Render: genre tags in the normal subtitle gray, plus an
        # optional blue "VR improvement" run for ImprovementTag games.
        $SubEl.Inlines.Clear()
        # Middle dot (U+00B7) separator, built from char code to keep the
        # source ASCII-only. Genre tags render SemiBold so they read as a
        # crisp "Action . Adventure . Shooter" line on the banner.
        $dotSep = "  " + [char]0x00B7 + "  "
        if ($tags.Count -gt 0) {
            $genreRun = New-Object System.Windows.Documents.Run
            $genreRun.Text = ($tags -join $dotSep)
            $genreRun.FontWeight = [System.Windows.FontWeights]::SemiBold
            [void]$SubEl.Inlines.Add($genreRun)
        }
        if ($Game.ImprovementTag) {
            if ($tags.Count -gt 0) {
                $sepRun = New-Object System.Windows.Documents.Run
                $sepRun.Text = $dotSep
                [void]$SubEl.Inlines.Add($sepRun)
            }
            $impRun = New-Object System.Windows.Documents.Run
            $impRun.Text = "VR improvement"
            $impRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            [void]$SubEl.Inlines.Add($impRun)
        }
        # Universal VR injectors (UUVR / UEVR) get a blue "VR Injector"
        # run in the third slot - same blue-run pattern as the
        # ImprovementTag above, so the banner reads e.g.
        # "Action  -  Adventure  -  VR Injector" with the last in blue.
        if ($Game.InjectorTag) {
            if ($tags.Count -gt 0) {
                $sepRun = New-Object System.Windows.Documents.Run
                $sepRun.Text = $dotSep
                [void]$SubEl.Inlines.Add($sepRun)
            }
            $injRun = New-Object System.Windows.Documents.Run
            $injRun.Text = "VR Injector"
            $injRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            [void]$SubEl.Inlines.Add($injRun)
        }
    }
    if ($ImageEl) {
        $headerUrl   = Get-GameImageUrl -Game $Game -Kind "header"
        $portraitUrl = Get-GameImageUrl -Game $Game -Kind "portrait"
        # Candidate chain, tried in order by Set-SafeBannerImage (which
        # walks the WHOLE list and does delayed retry passes for
        # transient CDN hiccups). FIRST candidate is the local disk
        # cache (Assets\cache\) if we've successfully loaded this art
        # before - it loads synchronously from file, so once seen a
        # banner is never blank again. Then the network sources: the
        # catalog/header URL, BOTH Steam header CDNs (akamai + fastly -
        # one frequently 404s where the other serves), then portraits
        # as a last resort so the banner shows *something*. On a
        # successful network load Set-SafeBannerImage saves it to the
        # cache for next time.
        $urls = @()
        if ($Game.SteamId) {
            $cachedHeader = Get-CachedImageUri -SteamId $Game.SteamId -Kind "header"
            if ($cachedHeader) { $urls += $cachedHeader }
        }
        $urls += $headerUrl
        if ($Game.SteamId) {
            $urls += (Get-SteamHeaderUrl $Game.SteamId)          # akamai header
            $urls += (Get-SteamHeaderUrlFastly $Game.SteamId)    # fastly header
        }
        if ($portraitUrl) { $urls += $portraitUrl }
        if ($Game.SteamId) {
            $urls += (Get-SteamPortraitUrlFastly $Game.SteamId)  # fastly portrait
        }
        # No TitleEl here: these banners already show the title as a
        # permanent text overlay beside the art, so we only need the
        # robust URL chain + retry, not a blank-state title swap.
        # Drop empty/null candidates (a game with no header/portrait and
        # no SteamId yields none) and only load art when something remains -
        # otherwise the banner just shows its colour gradient.
        $urls = @($urls | Where-Object { $_ })
        if ($urls.Count -gt 0) {
            Set-SafeBannerImage -ImageEl $ImageEl -Urls $urls
        }
    }
    # Banner background: a CURATED per-game colour (BannerColors.ps1), picked
    # from each game's own header art offline + hand-QA'd, built into a
    # horizontal gradient that runs from neutral dark on the left (under the
    # title) to the game's colour on the right (under the artwork). This is
    # fixed per game - no runtime image sampling - so there is no phantom-green
    # / muddy-dark guessing and no banding from random sampled tones. Games
    # with no curated colour (e.g. PEAK) fall back to flat neutral dark.
    if ($BgEl) {
        try {
            $neutral = [System.Windows.Media.Color]::FromRgb(15, 15, 21)
            $curHex  = Get-BannerColorForGame -Game $Game
            if ($curHex) {
                $c  = [System.Windows.Media.ColorConverter]::ConvertFromString($curHex)
                # Work in HSV so darkening preserves the hue properly AND we can
                # "de-olive" warm tones: a dark yellow/gold reads perceptually as
                # muddy olive (looks green), so for yellow/gold hues we pull the
                # hue toward amber as we darken. Real greens (hue >= 79: Yooka,
                # Grounded, Cruelty) are left alone; red/blue are unaffected.
                $rr = $c.R / 255.0; $gg = $c.G / 255.0; $bb = $c.B / 255.0
                $cmax = [Math]::Max($rr, [Math]::Max($gg, $bb))
                $cmin = [Math]::Min($rr, [Math]::Min($gg, $bb))
                $dl   = $cmax - $cmin
                $hue0 = 0.0
                if ($dl -gt 0) {
                    if ($cmax -eq $rr)     { $hue0 = 60.0 * ((($gg - $bb) / $dl) % 6.0) }
                    elseif ($cmax -eq $gg) { $hue0 = 60.0 * ((($bb - $rr) / $dl) + 2.0) }
                    else                   { $hue0 = 60.0 * ((($rr - $gg) / $dl) + 4.0) }
                }
                if ($hue0 -lt 0) { $hue0 += 360.0 }
                $sat0 = if ($cmax -gt 0) { $dl / $cmax } else { 0.0 }
                $mkTone = {
                    param($targetV, $deolive)
                    $h = $hue0
                    if ($deolive -gt 0 -and $h -ge 35 -and $h -le 78) { $h = $h + (28.0 - $h) * $deolive }
                    $s = [Math]::Min($sat0, 0.85)
                    $v = $targetV / 255.0
                    $hh = $h / 60.0
                    $cc = $v * $s
                    $xx = $cc * (1.0 - [Math]::Abs(($hh % 2.0) - 1.0))
                    $mm = $v - $cc
                    if ($hh -lt 1)     { $r1 = $cc; $g1 = $xx; $b1 = 0.0 }
                    elseif ($hh -lt 2) { $r1 = $xx; $g1 = $cc; $b1 = 0.0 }
                    elseif ($hh -lt 3) { $r1 = 0.0; $g1 = $cc; $b1 = $xx }
                    elseif ($hh -lt 4) { $r1 = 0.0; $g1 = $xx; $b1 = $cc }
                    elseif ($hh -lt 5) { $r1 = $xx; $g1 = 0.0; $b1 = $cc }
                    else               { $r1 = $cc; $g1 = 0.0; $b1 = $xx }
                    [System.Windows.Media.Color]::FromRgb(
                        [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round(($r1 + $mm) * 255))),
                        [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round(($g1 + $mm) * 255))),
                        [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round(($b1 + $mm) * 255))))
                }
                $amb  = & $mkTone 115 0.2    # brightest - sits BEHIND the artwork (mostly hidden)
                $mid  = & $mkTone 78  0.5    # gentle, visible tint just before the artwork
                $deep = & $mkTone 28  0.65   # dark, see-through ground under the title (left)
                $grad = New-Object System.Windows.Media.LinearGradientBrush
                $grad.StartPoint = New-Object System.Windows.Point 0, 0.5
                $grad.EndPoint   = New-Object System.Windows.Point 1, 0.5
                # Subtle wash that spans the row but stays SEE-THROUGH: held dark
                # under the title (left third) so it reads on a near-neutral dark
                # ground, a gentle mid tint across the centre, and the bright end
                # tucked behind the artwork so there is never a solid colour block
                # over the text.
                [void]$grad.GradientStops.Add((New-Object System.Windows.Media.GradientStop $deep, 0.0))
                [void]$grad.GradientStops.Add((New-Object System.Windows.Media.GradientStop $deep, 0.30))
                [void]$grad.GradientStops.Add((New-Object System.Windows.Media.GradientStop $mid, 0.66))
                [void]$grad.GradientStops.Add((New-Object System.Windows.Media.GradientStop $amb, 1.0))
                $grad.Freeze()
                $BgEl.Fill = $grad
            } else {
                $BgEl.Fill = New-Object System.Windows.Media.SolidColorBrush $neutral
            }
        } catch { }
    }

    $ctrlColor = switch ($Game.Controls) {
        "MC"   { "#44cc66" }
        "GP"   { "#dd6600" }
        "BOTH" { "#8888ff" }
        default { "#dd6600" }
    }
    $ctrlText = switch ($Game.Controls) {
        "MC"   { "MOTION CONTROLS" }
        "GP"   { "GAMEPAD" }
        "BOTH" { "MOTION + GAMEPAD" }
        default { "" }
    }
    if ($DotEl) {
        try {
            $DotEl.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ctrlColor)
            # Keep the pulsing glow (set up once at load) tinted to match.
            if ($DotEl.Effect -is [System.Windows.Media.Effects.DropShadowEffect]) {
                $DotEl.Effect.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($ctrlColor)
            }
        } catch { }
    }
    if ($KickerEl) {
        $KickerEl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ctrlColor)
        # Plain-string path for normal games. For free-to-play games we
        # switch to Inlines so the trailing FREE token can carry its own
        # green color (TextBlock.Text is single-color, .Inlines is per-Run).
        $isFreeBanner = ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title))
        if ($isFreeBanner) {
            $KickerEl.Inlines.Clear()
            $baseText = if ($ctrlText) { "$KickerPrefix  -  $ctrlText" } else { $KickerPrefix }
            $baseRun = New-Object System.Windows.Documents.Run
            $baseRun.Text = $baseText
            [void]$KickerEl.Inlines.Add($baseRun)
            $freeSepRun = New-Object System.Windows.Documents.Run
            $freeSepRun.Text = "  -  "
            [void]$KickerEl.Inlines.Add($freeSepRun)
            $freeKickRun = New-Object System.Windows.Documents.Run
            $freeKickRun.Text = "FREE"
            $freeKickRun.FontWeight = [System.Windows.FontWeights]::Bold
            $freeKickRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34d399")
            [void]$KickerEl.Inlines.Add($freeKickRun)
        } else {
            # Clear any prior Inlines so a previous FREE banner doesn't
            # leak into a non-FREE one when the banner rotates.
            $KickerEl.Inlines.Clear()
            if ($ctrlText) {
                $KickerEl.Text = "$KickerPrefix  -  $ctrlText"
            } else {
                $KickerEl.Text = $KickerPrefix
            }
        }
    }
}

# Fill the VR-mod-list banner.
function global:Set-ListBanner {
    $game = Get-FeaturedRandomGame
    if (-not $game) { return }
    $global:ListBannerGame = $game
    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("ListBannerTitle")) `
        -SubEl    ($window.FindName("ListBannerSubtitle")) `
        -ImageEl  ($window.FindName("ListBannerImage")) `
        -BgEl     ($window.FindName("ListBannerBg")) `
        -DotEl    ($window.FindName("ListBannerCtrlDot")) `
        -KickerEl ($window.FindName("ListBannerKicker")) `
        -KickerPrefix "FEATURED VR MOD"
}

# Re-render the list banner that's ALREADY showing, without picking a
# new random game. Used when only the list S/M/L size changed so the
# title re-fits to the new font but the featured game does NOT shuffle.
function global:Refresh-ListBannerSameGame {
    $game = $global:ListBannerGame
    if (-not $game) { return }
    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("ListBannerTitle")) `
        -SubEl    ($window.FindName("ListBannerSubtitle")) `
        -ImageEl  ($window.FindName("ListBannerImage")) `
        -BgEl     ($window.FindName("ListBannerBg")) `
        -DotEl    ($window.FindName("ListBannerCtrlDot")) `
        -KickerEl ($window.FindName("ListBannerKicker")) `
        -KickerPrefix "FEATURED VR MOD"
}

# Fill the library (portrait grid view) banner.
function global:Set-LibBanner {
    $game = Get-FeaturedRandomGame
    if (-not $game) { return }
    $global:LibBannerGame = $game
    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("LibBannerTitle")) `
        -SubEl    ($window.FindName("LibBannerSubtitle")) `
        -ImageEl  ($window.FindName("LibBannerImage")) `
        -BgEl     ($window.FindName("LibBannerBg")) `
        -DotEl    ($window.FindName("LibBannerCtrlDot")) `
        -KickerEl ($window.FindName("LibBannerKicker")) `
        -KickerPrefix "FEATURED VR MOD"
}

# Re-render the library banner that's ALREADY showing, without
# picking a new random game. Used when only the size changed (S/M/L)
# so the title re-fits to the new font size but the featured game
# does NOT shuffle.
function global:Refresh-LibBannerSameGame {
    $game = $global:LibBannerGame
    if (-not $game) { Set-LibBanner; return }
    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("LibBannerTitle")) `
        -SubEl    ($window.FindName("LibBannerSubtitle")) `
        -ImageEl  ($window.FindName("LibBannerImage")) `
        -BgEl     ($window.FindName("LibBannerBg")) `
        -DotEl    ($window.FindName("LibBannerCtrlDot")) `
        -KickerEl ($window.FindName("LibBannerKicker")) `
        -KickerPrefix "FEATURED VR MOD"
}

# Fill the Overview page banner.
function global:Set-OvBanner {
    $game = Get-FeaturedRandomGame
    if (-not $game) { return }
    $global:OvBannerGame = $game
    $global:OvBannerKickerText = "FEATURED PICK"
    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("OvBannerTitle")) `
        -SubEl    ($window.FindName("OvBannerSubtitle")) `
        -ImageEl  ($window.FindName("OvBannerImage")) `
        -BgEl     ($window.FindName("OvBannerBg")) `
        -DotEl    ($window.FindName("OvBannerCtrlDot")) `
        -KickerEl ($window.FindName("OvBannerKicker")) `
        -KickerPrefix "FEATURED PICK"
}

# Re-render the banner that's ALREADY showing, without picking a new
# random game. Used when only the layout/size changed (S/M/L toggle)
# so the title re-fits to the new font size but the featured game
# does NOT shuffle. Falls back to a fresh pick only if nothing is
# showing yet.
function global:Refresh-OvBannerSameGame {
    $game = $global:OvBannerGame
    if (-not $game) { Set-OvBannerForActiveGenre; return }
    $kicker = if ($global:OvBannerKickerText) { $global:OvBannerKickerText } else { "FEATURED PICK" }
    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("OvBannerTitle")) `
        -SubEl    ($window.FindName("OvBannerSubtitle")) `
        -ImageEl  ($window.FindName("OvBannerImage")) `
        -BgEl     ($window.FindName("OvBannerBg")) `
        -DotEl    ($window.FindName("OvBannerCtrlDot")) `
        -KickerEl ($window.FindName("OvBannerKicker")) `
        -KickerPrefix $kicker
}

# Banner refresh tied to the active genre filter. Called from the
# genre-chip click handler so when the user picks "Action & shooter"
# on the Explore page the banner changes to a game that fits that
# genre. ALL gets the original featured-random behaviour.
function global:Set-OvBannerForActiveGenre {
    $genreKey = if ($global:OvActiveGenre) { $global:OvActiveGenre } else { "ALL" }
    if ($genreKey -eq "ALL") {
        Set-OvBanner
        return
    }
    if ($genreKey -eq "FREE") {
        $pool = @(); $pool += $ownGames; $pool += $ownGamesGP; $pool += $externalGames
        $freePool = @($pool | Where-Object { $_.Title -and ($global:FREE_GAME_TITLES -contains $_.Title) })
        if ($freePool.Count -eq 0) { return }
        $cur = if ($global:OvBannerGame) { $global:OvBannerGame.Title } else { $null }
        if ($cur -and $freePool.Count -gt 1) { $freePool = @($freePool | Where-Object { $_.Title -ne $cur }) }
        $game = $freePool[(Get-Random -Minimum 0 -Maximum $freePool.Count)]
        $global:OvBannerGame = $game
        $kicker = "BROWSING FREE GAMES"
        $global:OvBannerKickerText = $kicker
        Set-BannerForGame -Game $game `
            -TitleEl  ($window.FindName("OvBannerTitle")) `
            -SubEl    ($window.FindName("OvBannerSubtitle")) `
            -ImageEl  ($window.FindName("OvBannerImage")) `
            -BgEl     ($window.FindName("OvBannerBg")) `
            -DotEl    ($window.FindName("OvBannerCtrlDot")) `
            -KickerEl ($window.FindName("OvBannerKicker")) `
            -KickerPrefix $kicker
        return
    }
    $game = Get-FeaturedRandomGameForGenre -GenreKey $genreKey
    if (-not $game) { return }
    $global:OvBannerGame = $game

    # Use the genre's display label as the kicker so the banner
    # reads "BROWSING ACTION AND SHOOTER" or similar - makes the
    # filter state visible above the title. Fall back to the key
    # if no label is set.
    $genreLabel = $genreKey
    foreach ($g in $global:OverviewGenres) {
        if ($g.Key -eq $genreKey) {
            if ($g.Label) { $genreLabel = $g.Label }
            break
        }
    }
    $kicker = ("BROWSING " + $genreLabel.ToUpper())
    $global:OvBannerKickerText = $kicker

    Set-BannerForGame -Game $game `
        -TitleEl  ($window.FindName("OvBannerTitle")) `
        -SubEl    ($window.FindName("OvBannerSubtitle")) `
        -ImageEl  ($window.FindName("OvBannerImage")) `
        -BgEl     ($window.FindName("OvBannerBg")) `
        -DotEl    ($window.FindName("OvBannerCtrlDot")) `
        -KickerEl ($window.FindName("OvBannerKicker")) `
        -KickerPrefix $kicker
}

# ---------------------------------------------------------------
# Hub settings file: small JSON next to VRModHub.ps1 storing
# user toggles (checkOnStartup, banner disable flags, etc.).
# Created on first write, never shipped in the release ZIP.
# Defined here near the top of the post-XAML code so any
# subsequent UI wiring can read/write settings.
# ---------------------------------------------------------------
$global:HubSettingsFile = Join-Path $scriptDir ".hub-settings.json"

function global:Get-HubSetting {
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

function global:Set-HubSetting {
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


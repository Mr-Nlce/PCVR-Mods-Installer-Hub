# Populate a TextBlock with text + clickable hyperlinks. Splits the
# input on URL patterns (http://, https://) and emits a Run for
# each plain-text chunk and a Hyperlink for each URL. The Hyperlink
# fires Start-Process on its NavigateUri when clicked so the user's
# default browser opens the page.
#
# Without this helper, README text was rendered as plain-text in
# a single TextBlock - URLs printed but were not clickable, which
# tripped up users who expected them to behave like links.
function global:Set-TextBlockWithLinks {
    param(
        [System.Windows.Controls.TextBlock]$TextBlock,
        [string]$Text,
        [string]$AccentHex = $null,
        [double]$BaseFont = 14,
        $Game = $null,
        $LinkSession = $null,
        [switch]$Literal,
        [switch]$NoRegister
    )
    if (-not $TextBlock) { return }
    $TextBlock.Inlines.Clear()
    if ([string]::IsNullOrEmpty($Text)) { return }

    # One path index for the entire README, shared by paragraphs and tables.
    # Keeping original text lets scan completion refresh links without losing
    # formatting, controller pills, scroll position or the current S/M/L size.
    if (-not $LinkSession -and $Game) {
        $LinkSession = New-ReadmeLinkSession -Game $Game -Texts @($Text)
    }
    if ($LinkSession) {
        $Game = $LinkSession.Game
        if (-not $NoRegister) { [void]$LinkSession.Blocks.Add(@{ Control=$TextBlock; Text=$Text; Accent=$AccentHex; Literal=[bool]$Literal }) }
    }
    $spanStyle = if ($Literal) { 'code' } else { 'text' }
    $spans = @(Get-ReadmeInlineSpans -Text $Text -Style $spanStyle -Literal:$Literal)
    $spans = @(Add-ReadmePathSpans -Spans $spans -Session $LinkSession)

    # Typography pass: prettify dashes and arrows in prose. Runs after
    # url/bold/code are split out so it only touches plain text spans -
    # code spans (paths, commands like --flag) and URLs keep their literal
    # ASCII. "->" -> real arrow; " -- " and a spaced " - " used as a
    # sentence break -> em-dash. List bullets never reach here (the readme
    # parser strips "- " before calling this), so a " - " here is mid-line.
    # When an accent colour is supplied, the dash/arrow GLYPH is emitted as
    # its own 'accentsym' span so it renders tinted instead of plain white;
    # the surrounding spaces stay in the text spans. Without an accent the
    # glyph is just inlined as normal text.
    $emdash = [char]0x2014
    $arrow  = [char]0x2192
    $typoSplit = {
        param($inSpans)
        $out = New-Object System.Collections.Generic.List[object]
        foreach ($s in $inSpans) {
            if ($s.Kind -ne 'text') { $out.Add($s) | Out-Null; continue }
            $t = $s.Text
            # Normalise the three source forms to a single sentinel glyph
            # first, then split on the glyph so each becomes its own span.
            $t = $t -replace '\s*->\s*', (' ' + $arrow + ' ')
            $t = $t -replace '\s--\s',   (' ' + $emdash + ' ')
            $t = $t -replace '\s-\s',    (' ' + $emdash + ' ')
            if (-not $AccentHex) { $out.Add(@{ Kind='text'; Text=$t }) | Out-Null; continue }
            $cur = 0
            $matches = [regex]::Matches($t, "[$emdash$arrow]")
            if ($matches.Count -eq 0) { $out.Add(@{ Kind='text'; Text=$t }) | Out-Null; continue }
            foreach ($m in $matches) {
                if ($m.Index -gt $cur) {
                    $out.Add(@{ Kind='text'; Text=$t.Substring($cur, $m.Index - $cur) }) | Out-Null
                }
                $out.Add(@{ Kind='accentsym'; Text=$m.Value }) | Out-Null
                $cur = $m.Index + $m.Length
            }
            if ($cur -lt $t.Length) {
                $out.Add(@{ Kind='text'; Text=$t.Substring($cur) }) | Out-Null
            }
        }
        return $out
    }
    if (-not $Literal) { $spans = & $typoSplit $spans }


    foreach ($s in $spans) {
        switch ($s.Kind) {
            'text' {
                $run = New-Object System.Windows.Documents.Run $s.Text
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'accentsym' {
                # Em-dash / arrow tinted in the game's accent colour so the
                # separator reads as a soft themed glyph instead of a hard
                # white bar. SemiBold gives it just enough presence.
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontWeight = [System.Windows.FontWeights]::SemiBold
                try {
                    $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                } catch { }
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'bold' {
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontWeight = [System.Windows.FontWeights]::Bold
                $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e8e8f0")
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'boldcode' {
                # **`x`** - bold weight + monospace + warm code tint.
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontWeight = [System.Windows.FontWeights]::Bold
                $run.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'code' {
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'local' {
                $color = if ($s.Style -in @('code','boldcode')) { '#e6c992' } else { '#e99583' }
                $localLink = New-UninstallGuideLink -Text $s.Text -Target $s.Target -Game $Game -AccentHex $color
                if ($s.Style -in @('code','boldcode')) { $localLink.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas, Cascadia Mono, Courier New') }
                if ($s.Style -in @('bold','boldcode')) { $localLink.FontWeight = [System.Windows.FontWeights]::Bold }
                [void]$TextBlock.Inlines.Add($localLink)
            }
            'pill' {
                # Controller-button key-cap: small neutral grey rounded
                # pill. Neutral (not accent) so single letters stay
                # legible regardless of the game's accent colour. All
                # dimensions are derived from $BaseFont (the surrounding
                # readme text size) so the pill grows/shrinks with S/M/L
                # instead of staying a fixed size while the text scales.
                # Reference ratios are tuned at BaseFont 14 (= the old
                # fixed values: font 10.5, height 17, pad 6/1, radius 8,
                # line 13).
                $pillFont   = [math]::Round($BaseFont * 0.75, 1)
                $pillHeight = [int][math]::Round($BaseFont * 1.214)
                $pillPadX   = [int][math]::Round($BaseFont * 0.43)
                $pillRadius = [math]::Round($BaseFont * 0.571, 1)
                $pillLine   = [int][math]::Round($BaseFont * 0.929)
                $pill = New-Object System.Windows.Controls.Border
                $pill.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a36")
                $pill.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
                $pill.BorderThickness = [System.Windows.Thickness]::new(1)
                $pill.CornerRadius    = [System.Windows.CornerRadius]::new($pillRadius)
                $pill.Padding         = [System.Windows.Thickness]::new($pillPadX, 1, $pillPadX, 1)
                $pill.Height          = $pillHeight
                $pill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $ptxt = New-Object System.Windows.Controls.TextBlock
                $ptxt.Text = $s.Text
                $ptxt.FontSize = $pillFont
                $ptxt.FontWeight = [System.Windows.FontWeights]::SemiBold
                $ptxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddde6")
                $ptxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $ptxt.TextAlignment = [System.Windows.TextAlignment]::Center
                $ptxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                $ptxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $ptxt.MinWidth = 8
                $ptxt.Margin = [System.Windows.Thickness]::new(0)
                $ptxt.Padding = [System.Windows.Thickness]::new(0)
                $ptxt.LineHeight = $pillLine
                $ptxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
                $pill.Child = $ptxt
                $container = New-Object System.Windows.Documents.InlineUIContainer $pill
                $container.BaselineAlignment = [System.Windows.BaselineAlignment]::Center
                $TextBlock.Inlines.Add($container) | Out-Null
            }
            'destination' {
                # !!! A MARKDOWN LINK - [label](address) - AND IT HAD NO
                # BRANCH HERE. Get-ReadmeInlineSpans reports a bare URL as
                # 'url' but a markdown link as 'destination', and the switch
                # only knew the first. Every [text](url) in every readme fell
                # through the switch and vanished ENTIRELY - not just the
                # link, the label with it. Same rendering as 'url': the label
                # is shown, the address is where it goes.
                $mdLink = New-ReadmeWebLink -Text $s.Text -Address $s.Address
                if ($s.Style -in @('code','boldcode')) { $mdLink.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas, Cascadia Mono, Courier New') }
                if ($s.Style -in @('bold','boldcode')) { $mdLink.FontWeight = [System.Windows.FontWeights]::Bold }
                $TextBlock.Inlines.Add($mdLink) | Out-Null
            }
            'url' {
                $hyperlink = New-ReadmeWebLink -Text $s.Text -Address $s.Address
                if ($s.Style -in @('code','boldcode')) { $hyperlink.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas, Cascadia Mono, Courier New') }
                if ($s.Style -in @('bold','boldcode')) { $hyperlink.FontWeight = [System.Windows.FontWeights]::Bold }
                $TextBlock.Inlines.Add($hyperlink) | Out-Null
            }
        }
    }
}

function global:Get-YouTubeId {
    param([string]$Url)
    if (-not $Url) { return $null }
    $m = [regex]::Match($Url, '(?:v=|youtu\.be/|embed/|shorts/|live/)([A-Za-z0-9_-]{11})')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# Compact "Watch VR gameplay" strip shown at the top of the description
# (directly under the Game Info row) for any catalog entry that sets a
# VideoUrl. The primary image is the real YouTube thumbnail; on any load
# failure it swaps to the game's Steam header, and if that is unavailable
# too the dark tile plus the red play button still read cleanly - so the
# strip looks right even offline. The whole strip opens the video.
# !!! TWO VIDEOS SIDE BY SIDE (2026-08-29). Tiles that carry two mods for
# one game often have footage of each - Steam build and GOG build, old
# fork and new fork. -Which picks the second one, so the caller can build
# both cards and lay them out next to each other.
#
# Only VideoUrl2 turns the second card on. Every existing entry has just
# VideoUrl and is untouched.
function global:New-VideoStripElement {
    param($Game, [string]$AccentHex = "#cdb77a", [ValidateSet("Primary","Secondary")][string]$Which = "Primary")
    if ($Which -eq "Secondary") {
        if (-not $Game.VideoUrl2) { return $null }
        # A shallow copy with the second video's fields in the primary
        # slots - the body below then needs no second code path.
        $alt = @{}
        foreach ($k in $Game.Keys) { $alt[$k] = $Game[$k] }
        $alt.VideoUrl   = $Game.VideoUrl2
        $alt.VideoLabel = if ($Game.VideoLabel2) { $Game.VideoLabel2 } else { "Watch VR gameplay" }
        $Game = $alt
    }
    try {
        if (-not $Game.VideoUrl) { return $null }
        $vid = Get-YouTubeId -Url $Game.VideoUrl
        # Where the video lives, for the subtitle line. YouTube clips get a
        # real thumbnail; anything else (e.g. the Reddit-hosted Hytale clip)
        # has none, so the strip falls back to the game's own header image,
        # cropped to the thumbnail box by UniformToFill.
        $provider = "YouTube"
        if (-not $vid) {
            if ($Game.VideoUrl -match 'redd\.it|reddit\.com') { $provider = "Reddit" }
            else {
                try { $provider = ([Uri]$Game.VideoUrl).Host -replace '^www\.', '' } catch { $provider = "the web" }
            }
        }
        $conv = New-Object System.Windows.Media.BrushConverter
        $accentBrush = try { $conv.ConvertFromString($AccentHex) } catch { [System.Windows.Media.Brushes]::Goldenrod }
        $restBorder = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(0x2A, 0xFF, 0xFF, 0xFF))

        $card = New-Object System.Windows.Controls.Border
        $card.CornerRadius = [System.Windows.CornerRadius]::new(10)
        $card.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(0x40, 0x32, 0x35, 0x48))
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
        $card.BorderBrush = $restBorder
        $card.Padding = [System.Windows.Thickness]::new(10)
        $card.Margin = [System.Windows.Thickness]::new(0,0,0,14)
        $card.Cursor = [System.Windows.Input.Cursors]::Hand

        # A Grid gives the text a finite star-width. The previous horizontal
        # StackPanel measured it at infinity, so two half-width video cards
        # could overflow the detail pane instead of wrapping their labels.
        $row = New-Object System.Windows.Controls.Grid
        $thumbCol = New-Object System.Windows.Controls.ColumnDefinition
        $thumbCol.Width = New-Object System.Windows.GridLength(132)
        $textCol = New-Object System.Windows.Controls.ColumnDefinition
        $textCol.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $row.ColumnDefinitions.Add($thumbCol) | Out-Null
        $row.ColumnDefinitions.Add($textCol) | Out-Null

        $thumbWrap = New-Object System.Windows.Controls.Border
        $thumbWrap.Width = 132; $thumbWrap.Height = 74
        $thumbWrap.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $thumbWrap.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x22,0x2A,0x30))
        $thumbWrap.ClipToBounds = $true
        $thumbGrid = New-Object System.Windows.Controls.Grid

        $img = New-Object System.Windows.Controls.Image
        $img.Stretch = "UniformToFill"
        $fallbackUrl = $null
        try {
            if (Get-Command Get-GameImageUrl -ErrorAction SilentlyContinue) {
                $fallbackUrl = Get-GameImageUrl -Game $Game -Kind "header"
            }
        } catch {}
        if (-not $fallbackUrl -and $Game.SteamId) {
            $fallbackUrl = "https://cdn.cloudflare.steamstatic.com/steam/apps/$($Game.SteamId)/header.jpg"
        }
        $cached = $null
        if ($vid -and (Get-Command Get-YtThumbCachePath -ErrorAction SilentlyContinue)) {
            try { $cp = Get-YtThumbCachePath -Id $vid; if ($cp -and (Test-Path -LiteralPath $cp)) { $cached = $cp } } catch {}
        }
        $primary = if ($cached) { $cached } elseif ($vid) { "https://img.youtube.com/vi/$vid/mqdefault.jpg" } else { $fallbackUrl }
        if ($primary) {
            try {
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $primaryUri = [Uri]$primary
                $bmp.UriSource = $primaryUri
                $bmp.DecodePixelWidth = 264
                $bmp.CacheOption = if ($primaryUri.IsFile) {
                    [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                } else {
                    [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
                }
                $bmp.EndInit()
                if (-not $cached -and $fallbackUrl) {
                    $bmp.Add_DownloadFailed({
                        param($s, $e)
                        try {
                            $fb = New-Object System.Windows.Media.Imaging.BitmapImage
                            $fb.BeginInit()
                            $fbUri = [Uri]$fallbackUrl
                            $fb.UriSource = $fbUri
                            $fb.DecodePixelWidth = 264
                            $fb.CacheOption = if ($fbUri.IsFile) { [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad } else { [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand }
                            $fb.EndInit()
                            $img.Source = $fb
                        } catch {}
                    }.GetNewClosure())
                }
                $img.Source = $bmp
            } catch {}
            if (-not $cached -and $fallbackUrl) {
                $img.Add_ImageFailed({
                    param($s, $e)
                    try {
                        $fb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $fb.BeginInit()
                        $fbUri = [Uri]$fallbackUrl
                        $fb.UriSource = $fbUri
                        $fb.DecodePixelWidth = 264
                        $fb.CacheOption = if ($fbUri.IsFile) { [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad } else { [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand }
                        $fb.EndInit()
                        $s.Source = $fb
                    } catch {}
                }.GetNewClosure())
            }
        }
        $thumbGrid.Children.Add($img) | Out-Null

        $play = New-Object System.Windows.Controls.Border
        $play.Width = 40; $play.Height = 28
        $play.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $play.Background = if ($vid) {
            [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xCC,0x00,0x00))
        } else {
            [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(0xD0,0x11,0x11,0x18))
        }
        $play.HorizontalAlignment = "Center"; $play.VerticalAlignment = "Center"
        $tri = New-Object System.Windows.Controls.TextBlock
        $tri.Text = [string][char]0x25B6
        $tri.Foreground = if ($vid) { [System.Windows.Media.Brushes]::White } else { $accentBrush }
        $tri.FontSize = 13
        $tri.HorizontalAlignment = "Center"; $tri.VerticalAlignment = "Center"
        $play.Child = $tri
        $thumbGrid.Children.Add($play) | Out-Null

        $thumbWrap.Child = $thumbGrid
        [System.Windows.Controls.Grid]::SetColumn($thumbWrap, 0)
        $row.Children.Add($thumbWrap) | Out-Null

        $txt = New-Object System.Windows.Controls.StackPanel
        $txt.VerticalAlignment = "Center"
        $txt.Margin = [System.Windows.Thickness]::new(12,0,0,0)
        $t1 = New-Object System.Windows.Controls.TextBlock
        # Default says VR because nearly every clip IS a VR capture. A game
        # whose only footage is flat gameplay sets VideoLabel in the catalog
        # so the strip does not promise VR footage the video never shows.
        $t1.Text = if ($Game.VideoLabel) { [string]$Game.VideoLabel } else { "Watch VR gameplay" }
        $t1.Foreground = $accentBrush
        $t1.FontSize = 14; $t1.FontWeight = "SemiBold"
        $t1.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $t2 = New-Object System.Windows.Controls.TextBlock
        $t2.Text = "See it in action on $provider"
        $t2.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x8A,0x8A,0x95))
        $t2.FontSize = 12; $t2.Margin = [System.Windows.Thickness]::new(0,2,0,0)
        $t2.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $txt.Children.Add($t1) | Out-Null; $txt.Children.Add($t2) | Out-Null
        [System.Windows.Controls.Grid]::SetColumn($txt, 1)
        $row.Children.Add($txt) | Out-Null

        $card.Child = $row

        $videoUrl = $Game.VideoUrl
        $card.Add_MouseLeftButtonUp({ try { Start-Process $videoUrl } catch {} }.GetNewClosure())
        $card.Add_MouseEnter({ $this.BorderBrush = $accentBrush }.GetNewClosure())
        $card.Add_MouseLeave({ $this.BorderBrush = $restBorder }.GetNewClosure())

        return $card
    } catch { return $null }
}

function global:New-DetailSection {
    param(
        [string]$Heading,
        [string]$Body,
        [string]$AccentHex = "#666677",
        $Game = $null,
        $LinkSession = $null,
        $AppendChild = $null,
        [string]$ImageBaseDir = $null,
        [switch]$PreserveSubheadings
    )
    if (-not $LinkSession) {
        $LinkSession = New-ReadmeLinkSession -Game $Game -Texts @($Heading, $Body) -BaseDir $ImageBaseDir
    }
    # Markdown -> nice typography. Source is ASCII via [char]
    # escapes so the release audit stays clean. The actual
    # bold/code inline parsing happens in Set-TextBlockWithLinks
    # below; this scope only handles per-line layout:
    #   * `- foo`  / `* foo`   -> indented bullet with U+2022 dot
    #   * `1. foo` / `2. foo`  -> indented number with extra space
    # Headings (`## ...`) inside the body are stripped - the
    # section already has a heading at the top.
    $bullet = [char]0x2022
    $bulletReplace = "  $bullet "

    # Single function used by all three rendering paths below
    # (image-mode pre-chunk, image-mode tail, no-image body).
    # Removes leading hash headings, normalises bullets and
    # numbered steps, collapses 3+ blank lines to 2. The bold
    # markers `**...**` and inline code `` ` `` are LEFT in -
    # Set-TextBlockWithLinks renders them as real bold / mono runs.
    # Sentinel char that marks a "code block line" - renderBody
    # turns these into monospace rows with a subtle chip bg. Using
    # a control char keeps it from ever colliding with real text.
    $codeMark = [char]0x0001
    # A copyable launch-command line (single-line launch args or a
    # console command). Renders as a code chip with click-to-copy.
    $copyMark = [char]0x0005
    # A flavour "quip" line (markdown prefix '>>> '). Rendered as a
    # single accent-coloured box with no heading at the very end.
    $quipMark = [char]0x0006
    # Grouped two-mod READMEs opt in to preserving their level-3 headings.
    # This keeps one author-labelled H2 per mod while its Overview / Install /
    # Controls subsections remain visibly separated inside that group.
    $subheadingMark = [char]0x0007
    # Table sentinels: $tableMark prefixes a markdown table row, with
    # cells joined by $cellSep. $tableHdr marks the header row so it
    # renders bolder. The |---| separator line is dropped.
    $tableMark = [char]0x0002
    $tableHdr  = [char]0x0003
    $cellSep   = [char]0x0004
    $formatBody = {
        param([string]$txt)
        if (-not $txt) { return $txt }
        $txt = $txt -replace "`r`n", "`n"
        $lines = $txt -split "`n"
        $out = New-Object System.Collections.Generic.List[string]
        $blankRun = 0
        $inStep = $false   # are we inside a numbered step (for continuation indent)?
        $inBullet = $false # are we inside a bullet (for continuation indent)?
        $inFence = $false  # are we inside a ``` code fence?
        $copyFence = $false # is the current fence a copyable launch command?
        $lastWasParagraph = $false  # was the previous emitted line a plain paragraph?
        for ($li = 0; $li -lt $lines.Count; $li++) {
            $raw = $lines[$li]
            $line = $raw
            # Code fence toggle: a line that is just ``` (optionally
            # with a language tag like ```bash). Don't emit the
            # fence marker line itself.
            if ($line -match '^[ \t]*```') {
                if (-not $inFence) {
                    # Opening a fence: look ahead to decide whether
                    # this is a COPYABLE launch command. Only single
                    # non-empty content lines that look like launch
                    # parameters / console commands qualify - NOT
                    # multi-line config blocks, file paths, or cvar
                    # dumps. Heuristic: exactly one content line, and
                    # it starts with '-' (launch args like
                    # "-overridenohmd -dx11") or "download_depot" /
                    # "steam" style console commands.
                    $content = New-Object System.Collections.Generic.List[string]
                    $j = $li + 1
                    while ($j -lt $lines.Count -and ($lines[$j] -notmatch '^[ \t]*```')) {
                        if (($lines[$j] -replace '[ \t]+$', '').Trim() -ne '') {
                            $content.Add($lines[$j].Trim()) | Out-Null
                        }
                        $j++
                    }
                    $copyFence = $false
                    if ($content.Count -eq 1) {
                        $c0 = $content[0]
                        if ($c0 -match '^-' -or $c0 -match '^(?i)(download_depot|app_update|steam|steamcmd)\b') {
                            $copyFence = $true
                        }
                    }
                }
                $inFence = -not $inFence
                if (-not $inFence) { $copyFence = $false }
                $inStep = $false
                continue
            }
            if ($inFence) {
                # Inside a fence: keep the line verbatim (trim only
                # trailing ws) and tag it as a code line. A copyable
                # launch command gets $copyMark instead of $codeMark.
                $mark = if ($copyFence) { $copyMark } else { $codeMark }
                $out.Add($mark + ($line -replace '[ \t]+$', '')) | Out-Null
                $lastWasParagraph = $false
                $inStep = $false
                $inBullet = $false
                continue
            }
            if ($PreserveSubheadings -and $line -match '^[ \t]*###[ \t]+(.+?)\s*$') {
                $out.Add($subheadingMark + $Matches[1].Trim()) | Out-Null
                $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                continue
            }
            if ($line -match '^[ \t]*#{1,6}[ \t]+\S') { continue }
            $line = $line -replace '[ \t]+$', ''
            # Markdown table row: a line that starts with '|' and has
            # at least one more '|'. The |---|---| separator line is
            # dropped. Each row becomes a $tableMark-tagged line with
            # cells joined by $cellSep; the first row of a table is
            # tagged as the header.
            $tt = $line.TrimStart()
            if ($tt -match '^\|.*\|' ) {
                # Separator row (only -, :, |, spaces) -> drop, but it
                # confirms the row above was a header.
                if ($tt -match '^\|[\s:|-]+\|?\s*$' -and ($tt -match '-')) {
                    if ($out.Count -gt 0 -and $out[$out.Count - 1].Length -gt 0 -and $out[$out.Count - 1][0] -eq $tableMark) {
                        $out[$out.Count - 1] = $tableHdr + $out[$out.Count - 1].Substring(1)
                    }
                    $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                    continue
                }
                # Data/header row: split on '|', drop the empty first
                # and last fields from the leading/trailing pipes.
                $cells = $tt -split '\|'
                $cells = $cells[1..($cells.Count - 1)]
                if ($cells.Count -gt 0 -and $cells[$cells.Count - 1].Trim() -eq '') {
                    $cells = $cells[0..($cells.Count - 2)]
                }
                $cells = $cells | ForEach-Object { $_.Trim() }
                $out.Add($tableMark + ($cells -join $cellSep)) | Out-Null
                $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                continue
            }
            # Flavour quip: a line beginning with '>>> '. Rendered as a
            # standalone accent box at the end. Strip the marker.
            if ($line -match '^[ \t]*>>>[ \t]?') {
                $qtext = $line -replace '^[ \t]*>>>[ \t]?', ''
                $out.Add($quipMark + $qtext.Trim()) | Out-Null
                $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                continue
            }
            $hadIndent = ($line -match '^[ \t]+\S')
            $trimmed = $line.TrimStart()
            if ($trimmed -eq '') {
                $blankRun++
                if ($blankRun -le 1) { $out.Add('') | Out-Null }
                $inStep = $false
                $inBullet = $false
                $lastWasParagraph = $false
                continue
            }
            $blankRun = 0
            if ($trimmed -match '^[-*][ \t]+(.*)$') {
                $out.Add($bulletReplace + $Matches[1]) | Out-Null
                $inStep = $false
                $inBullet = $true
                $lastWasParagraph = $false
            } elseif ($trimmed -match '^(\d+)\.[ \t]+(.*)$') {
                # Numbered step: flush-left "N. text" - no leading
                # indent, so 1..9 all start at the same column.
                $out.Add($Matches[1] + ". " + $Matches[2]) | Out-Null
                $inStep = $true
                $inBullet = $false
                $lastWasParagraph = $false
            } elseif (($inStep -or $inBullet) -and $hadIndent) {
                # Continuation line of the current step/bullet.
                # Markdown soft-wraps it, so append to the previous
                # line's text with a space rather than emitting a
                # separate hard-break line - the TextBlock then
                # wraps it naturally and the bullet/step stays as
                # one indented block.
                if ($out.Count -gt 0) {
                    $out[$out.Count - 1] = $out[$out.Count - 1] + " " + $trimmed
                } else {
                    $out.Add($trimmed) | Out-Null
                }
                $lastWasParagraph = $false
            } else {
                # Plain paragraph line. In Markdown a single newline
                # inside a paragraph is a soft wrap (renders as a
                # space), not a hard break - only blank lines split
                # paragraphs. So if the previous emitted line was
                # also a plain paragraph line, append to it with a
                # space rather than starting a new element.
                if ($lastWasParagraph -and $out.Count -gt 0) {
                    $out[$out.Count - 1] = $out[$out.Count - 1] + " " + $trimmed
                } else {
                    $out.Add($trimmed) | Out-Null
                }
                $inStep = $false
                $inBullet = $false
                $lastWasParagraph = $true
            }
        }
        return (($out -join "`n").Trim())
    }

    # ---- size config (drives heading + body scale together) ----
    $rmCfg0 = $global:DetailTextSizes[$global:DetailSize]
    if (-not $rmCfg0) { $rmCfg0 = $global:DetailTextSizes["M"] }
    # Heading sits a few pt above the body and scales with it.
    $headFont = [int]$rmCfg0.Font + 1

    # ---- per-line body renderer -------------------------------
    # Renders a cleaned body string line-by-line into $target:
    #   * "  <dot> text"  (level-1)  -> accent dot + text
    #   * "<square> text" (level-2)  -> dim square + indented text
    #   * "N. text"       (step)     -> outline number badge + text
    #   * anything else              -> plain wrapped paragraph
    # Bold (**) and code (` `) inside each line are rendered as
    # real runs by Set-TextBlockWithLinks. Every text block is
    # registered for live S/M/L resizing.
    $sq = [char]0x25AA   # small black square (level-2 bullet)
    # Cap all readme text at one comfortable reading width so long
    # sentences don't shoot across the whole pane once they sit
    # below the Similar Games column. ~720px keeps lines roughly
    # the same length as the top "What this installer does" block.
    # Readme text width scales with the window so a maximised
    # window doesn't leave a huge empty band on the right, but is
    # clamped so lines never get fatiguingly long. ~65% of the
    # window width, between 720 (small) and 1040 (large) - the
    # upper bound adds roughly 5-6 words per line vs the floor.
    $readmeMaxW = 720
    try {
        $winW = 0
        if ($global:discoverDetail -and $global:discoverDetail.ActualWidth -gt 0) {
            $winW = $global:discoverDetail.ActualWidth
        } elseif ($global:window -and $global:window.ActualWidth -gt 0) {
            $winW = $global:window.ActualWidth
        }
        if ($winW -gt 0) {
            $calc = [int]($winW * 0.78)
            if ($calc -lt 720)  { $calc = 720 }
            if ($calc -gt 1040) { $calc = 1040 }
            $readmeMaxW = $calc
        }
    } catch { }
    $renderBody = {
        param($target, [string]$cleaned)
        if (-not $cleaned) { return }
        $cfg = $global:DetailTextSizes[$global:DetailSize]
        if (-not $cfg) { $cfg = $global:DetailTextSizes["M"] }
        # Reset between tables: any non-table line ends the current one, so
        # two tables never share a container and therefore never share
        # column widths.
        $tableHost = $null
        $bodyLines = $cleaned -split "`n"
        for ($lineIndex = 0; $lineIndex -lt $bodyLines.Count; $lineIndex++) {
            $ln = $bodyLines[$lineIndex]
            $isTableRow = $ln.Length -gt 0 -and ($ln[0] -eq $tableMark -or $ln[0] -eq $tableHdr)
            if (-not $isTableRow) { $tableHost = $null }
            if ($ln.Length -gt 0 -and $ln[0] -eq $subheadingMark) {
                $sub = New-Object System.Windows.Controls.TextBlock
                Set-TextBlockWithLinks -TextBlock $sub -Text $ln.Substring(1) -LinkSession $LinkSession -AccentHex $AccentHex -BaseFont ([int]$cfg.Font + 1)
                $sub.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $sub.FontSize = [int]$cfg.Font + 1
                $sub.FontWeight = [System.Windows.FontWeights]::SemiBold
                $sub.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $sub.Margin = [System.Windows.Thickness]::new(0, 12, 0, 3)
                $sub.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $target.Children.Add($sub) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($sub) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($sub) | Out-Null }
                continue
            }
            # Code-fence line: sentinel-prefixed. Render as a
            # monospace row inside a subtle dark chip so launch
            # options / commands stand out as copy-pasteable code.
            # Plain code-fence line ($codeMark): a monospace chip for
            # config blocks, paths, cvars. Known paths and web addresses can
            # be opened; commands and settings remain literal text.
            if ($ln.Length -gt 0 -and $ln[0] -eq $codeMark) {
                $codeText = $ln.Substring(1)
                # Blank line inside a fence: skip it rather than draw an
                # empty chip box.
                if ($codeText.Trim() -eq '') { continue }
                $codeBox = New-Object System.Windows.Controls.Border
                $codeBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                $codeBox.BorderThickness = [System.Windows.Thickness]::new(1)
                $codeBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                $codeBox.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $codeBox.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
                $codeBox.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
                $codeBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $ctb = New-Object System.Windows.Controls.TextBlock
                Set-TextBlockWithLinks -TextBlock $ctb -Text $codeText -LinkSession $LinkSession -Literal -BaseFont $cfg.Font
                $ctb.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $ctb.FontSize = $cfg.Font
                $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $ctb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $codeBox.Child = $ctb
                $target.Children.Add($codeBox) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ctb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($ctb) | Out-Null }
                continue
            }

            # Copyable launch command ($copyMark): a single-line launch
            # parameter or console command. Click anywhere on the chip
            # to copy it. The hover tooltip says "Copy", so no icon is
            # needed; a brief "Copied!" confirms the action.
            if ($ln.Length -gt 0 -and $ln[0] -eq $copyMark) {
                $codeText = $ln.Substring(1)
                $codeBox = New-Object System.Windows.Controls.Border
                $codeBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                $codeBox.BorderThickness = [System.Windows.Thickness]::new(1)
                $codeBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                $codeBox.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $codeBox.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
                $codeBox.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
                $codeBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $codeBox.Cursor = [System.Windows.Input.Cursors]::Hand
                $codeBox.ToolTip = "Copy on click"
                $cgrid = New-Object System.Windows.Controls.Grid
                $cc0 = New-Object System.Windows.Controls.ColumnDefinition
                $cc0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
                $cc1 = New-Object System.Windows.Controls.ColumnDefinition
                $cc1.Width = [System.Windows.GridLength]::Auto
                $cgrid.ColumnDefinitions.Add($cc0)
                $cgrid.ColumnDefinitions.Add($cc1)
                $ctb = New-Object System.Windows.Controls.TextBlock
                $ctb.Text = $codeText
                $ctb.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $ctb.FontSize = $cfg.Font
                $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $ctb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $ctb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                [System.Windows.Controls.Grid]::SetColumn($ctb, 0)
                $cgrid.Children.Add($ctb) | Out-Null
                # Status label only (no icon - the tooltip already says
                # "Copy"). Flips to "Copied!" briefly on click.
                $copyStatus = New-Object System.Windows.Controls.TextBlock
                $copyStatus.Text = ""
                $copyStatus.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $copyStatus.FontSize = [int]$cfg.Font - 2
                $copyStatus.FontWeight = [System.Windows.FontWeights]::SemiBold
                $copyStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fcf80")
                $copyStatus.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $copyStatus.Margin = [System.Windows.Thickness]::new(10, 0, 2, 0)
                [System.Windows.Controls.Grid]::SetColumn($copyStatus, 1)
                $cgrid.Children.Add($copyStatus) | Out-Null
                $codeBox.Child = $cgrid
                $codeBox.Tag = [PSCustomObject]@{ Text = $codeText; Status = $copyStatus; Box = $codeBox }
                $codeBox.Add_MouseLeftButtonUp({
                    param($s, $e)
                    try {
                        $info = $s.Tag
                        [System.Windows.Clipboard]::SetText($info.Text)
                        $info.Status.Text = "Copied!"
                        # Confirming glow: briefly tint the chip green so
                        # there's a clear visual signal the copy worked.
                        $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16301f")
                        $s.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fcf80")
                        $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
                        $glow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#5fcf80")
                        $glow.BlurRadius = 14
                        $glow.ShadowDepth = 0
                        $glow.Opacity = 0.85
                        $s.Effect = $glow
                        $tmr = New-Object System.Windows.Threading.DispatcherTimer
                        $tmr.Interval = [TimeSpan]::FromSeconds(1.6)
                        $tmr.Tag = $info
                        $tmr.Add_Tick({
                            param($ts, $te)
                            $ts.Stop()
                            $ts.Tag.Status.Text = ""
                            # Revert the glow + tint cleanly.
                            $b = $ts.Tag.Box
                            $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                            $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                            $b.Effect = $null
                        })
                        $tmr.Start()
                    } catch {}
                })
                $codeBox.Add_MouseEnter({
                    param($s, $e)
                    # Don't fight the green confirm glow if it's active.
                    if ($null -ne $s.Effect) { return }
                    $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#24242e")
                    $s.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a46")
                })
                $codeBox.Add_MouseLeave({
                    param($s, $e)
                    # Leave the confirm glow intact if it's showing.
                    if ($null -ne $s.Effect) { return }
                    $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                    $s.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                })
                $target.Children.Add($codeBox) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ctb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($ctb) | Out-Null }
                continue
            }
            if ($ln.Trim() -eq '') { continue }

            # Flavour quip ($quipMark): a single accent-coloured box
            # with no heading, used as a closing one-liner. Consistent
            # look across all readmes.
            if ($ln.Length -gt 0 -and $ln[0] -eq $quipMark) {
                $qtext = $ln.Substring(1)
                $qBox = New-Object System.Windows.Controls.Border
                $qBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161e")
                $qBox.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 0)
                $qBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $qBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
                $qBox.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
                $qBox.Margin = [System.Windows.Thickness]::new(0, 14, 0, 4)
                $qBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $qBox.MaxWidth = $readmeMaxW
                # Accent bar on the left edge for a clean, branded look.
                $qBox.BorderThickness = [System.Windows.Thickness]::new(3, 0, 0, 0)
                $qtb = New-Object System.Windows.Controls.TextBlock
                Set-TextBlockWithLinks -TextBlock $qtb -Text $qtext -LinkSession $LinkSession -AccentHex $AccentHex -BaseFont ([int]$cfg.Font + 1)
                $qtb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $qtb.FontSize = [int]$cfg.Font + 1
                $qtb.FontStyle = [System.Windows.FontStyles]::Italic
                $qtb.FontWeight = [System.Windows.FontWeights]::SemiBold
                $qtb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $qtb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $qBox.Child = $qtb
                $target.Children.Add($qBox) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($qtb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($qBox) | Out-Null }
                continue
            }

            if ($isTableRow) {
                # One Grid for the ENTIRE table: independent row Grids can
                # negotiate different star widths during WPF's arrange pass.
                if (-not $tableHost) {
                    $tableRows = New-Object 'System.Collections.Generic.List[object]'
                    $columnCount = 0
                    $textHeavy = $false
                    for ($look = $lineIndex; $look -lt $bodyLines.Count; $look++) {
                        $row = $bodyLines[$look]
                        if (-not $row.Length -or ($row[0] -ne $tableMark -and $row[0] -ne $tableHdr)) { break }
                        $rowCells = $row.Substring(1) -split ([regex]::Escape([string]$cellSep))
                        $columnCount = [Math]::Max($columnCount, $rowCells.Count)
                        $lengths = @($rowCells | ForEach-Object {
                            $visible = (@(Get-ReadmeInlineSpans $_) | ForEach-Object { $_.Text }) -join ''
                            if ($visible.Length -ge 64) { $textHeavy = $true }
                            # A raw URL should not outweigh a description just
                            # because its destination happens to be very long.
                            if ($visible -match '^https?://\S+$') { [Math]::Min(48, $visible.Length) }
                            else { $visible.Length }
                        })
                        [void]$tableRows.Add($lengths)
                    }
                    $weights = @(for ($ci = 0; $ci -lt $columnCount; $ci++) {
                        if ($textHeavy) {
                            $values = @($tableRows | ForEach-Object { if ($ci -lt $_.Count) { $_[$ci] } })
                            $stats = $values | Measure-Object -Maximum -Average
                            [Math]::Max(1, ($stats.Maximum + $stats.Average) / 2)
                        } elseif ($ci -eq 0 -and $columnCount -gt 1) { 1.2 }
                        else { 1.0 }
                    })
                    if ($textHeavy) {
                        # Keep labels readable, while giving a long prose
                        # column up to 2.5 times a short one's width. The floor
                        # also keeps labels intact at the largest text size.
                        $floor = ($weights | Measure-Object -Maximum).Maximum * 0.4
                        $weights = @($weights | ForEach-Object { [Math]::Max($floor, $_) })
                    }
                    $tableHost = New-Object System.Windows.Controls.Grid
                    $tableHost.Tag = 'readme-table'
                    $tableHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                    $tableHost.MaxWidth = $readmeMaxW
                    $tableHost.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
                    # !!! TWO KINDS OF TABLE, AND THEY NEED OPPOSITE TREATMENT.
                    #
                    # A PROSE table (a cell of 64+ characters) has to wrap, so
                    # it takes the full reading width and shares it out by the
                    # weights worked out above.
                    #
                    # A SHORT table - every controls list is one - has nothing
                    # to wrap. Stretching it across the page pushed "Right
                    # Trigger" half a screen away from "Fire weapon" and left a
                    # gulf between the two. Those columns size to their content
                    # instead, so the table is only as wide as it needs to be
                    # and the pairs stay side by side. No width binding either:
                    # the grid shrinks to fit rather than filling the page.
                    if ($textHeavy) {
                        $widthBinding = [System.Windows.Data.Binding]::new('ActualWidth')
                        $widthBinding.Source = $target
                        [void]$tableHost.SetBinding([System.Windows.FrameworkElement]::WidthProperty, $widthBinding)
                        foreach ($weight in $weights) {
                            $cd = New-Object System.Windows.Controls.ColumnDefinition
                            $cd.Width = [System.Windows.GridLength]::new($weight, [System.Windows.GridUnitType]::Star)
                            [void]$tableHost.ColumnDefinitions.Add($cd)
                        }
                    } else {
                        for ($ci = 0; $ci -lt $columnCount; $ci++) {
                            $cd = New-Object System.Windows.Controls.ColumnDefinition
                            $cd.Width = [System.Windows.GridLength]::Auto
                            [void]$tableHost.ColumnDefinitions.Add($cd)
                        }
                    }
                    $target.Children.Add($tableHost) | Out-Null
                    if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($tableHost) | Out-Null }
                }
                $isHdr = ($ln[0] -eq $tableHdr)
                $cells = $ln.Substring(1) -split ([regex]::Escape([string]$cellSep))
                # Defensive: an all-empty header row (e.g. "| | |") would
                # render as a blank highlighted bar - skip it entirely.
                if ($isHdr -and (($cells | Where-Object { $_.Trim() -ne '' }).Count -eq 0)) { continue }
                $rowIndex = $tableHost.RowDefinitions.Count
                $rd = New-Object System.Windows.Controls.RowDefinition
                $rd.Height = [System.Windows.GridLength]::Auto
                [void]$tableHost.RowDefinitions.Add($rd)
                $rowBorder = New-Object System.Windows.Controls.Border
                if ($isHdr) {
                    $rowBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                } else {
                    $rowBorder.Background = [System.Windows.Media.Brushes]::Transparent
                }
                $rowBorder.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 1)
                $rowBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                $rowBorder.IsHitTestVisible = $false
                [System.Windows.Controls.Grid]::SetRow($rowBorder, $rowIndex)
                [System.Windows.Controls.Grid]::SetColumnSpan($rowBorder, $columnCount)
                [void]$tableHost.Children.Add($rowBorder)
                for ($ci = 0; $ci -lt $cells.Count; $ci++) {
                    $ctb = New-Object System.Windows.Controls.TextBlock
                    Set-TextBlockWithLinks -TextBlock $ctb -Text $cells[$ci] -AccentHex $AccentHex -BaseFont $cfg.Font -LinkSession $LinkSession
                    $ctb.FontSize = $cfg.Font
                    $ctb.LineHeight = $cfg.LineHeight
                    $ctb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                    # An Auto column measures with unlimited width, so a long
                    # cell in a short table would run past the page instead of
                    # wrapping. Capping the cell keeps the wrap working while
                    # the column still hugs whatever is shorter than the cap.
                    if (-not $textHeavy) { $ctb.MaxWidth = [Math]::Max(160, $readmeMaxW * 0.55) }
                    $cellPadding = if ($textHeavy -and -not $isHdr) { 8 } else { 5 }
                    $ctb.Margin = [System.Windows.Thickness]::new(8, $cellPadding, 12, $cellPadding + 1)
                    $ctb.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
                    $ctb.TextAlignment = [System.Windows.TextAlignment]::Left
                    $ctb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                    if ($isHdr) {
                        $ctb.FontWeight = [System.Windows.FontWeights]::SemiBold
                        $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                    } else {
                        $ctb.FontWeight = [System.Windows.FontWeights]::Medium
                        $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
                    }
                    [System.Windows.Controls.Grid]::SetRow($ctb, $rowIndex)
                    [System.Windows.Controls.Grid]::SetColumn($ctb, $ci)
                    $tableHost.Children.Add($ctb) | Out-Null
                    if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ctb) | Out-Null }
                }
                continue
            }

            $isB1 = $ln -match ('^\s*' + [regex]::Escape($bullet) + '\s+(.*)$')
            $b1text = if ($isB1) { $Matches[1] } else { $null }
            # Level-2 bullet: starts with the square marker
            $isB2 = $ln -match ('^\s*' + [regex]::Escape($sq) + '\s+(.*)$')
            $b2text = if ($isB2) { $Matches[1] } else { $null }
            # Numbered step
            $isStep = $ln -match '^(\d+)\.\s+(.*)$'
            $stepNum = if ($isStep) { $Matches[1] } else { $null }
            $stepTxt = if ($isStep) { $Matches[2] } else { $null }

            if ($isStep) {
                $row = New-Object System.Windows.Controls.DockPanel
                $row.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)
                $badgeSize = [int]$cfg.Font + 8
                $badge = New-Object System.Windows.Controls.Border
                [System.Windows.Controls.DockPanel]::SetDock($badge, 'Left')
                $badge.Width = $badgeSize
                $badge.Height = $badgeSize
                $badge.CornerRadius = [System.Windows.CornerRadius]::new($badgeSize / 2)
                $badge.BorderThickness = [System.Windows.Thickness]::new(1.5)
                $badge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $badge.Background = [System.Windows.Media.Brushes]::Transparent
                $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
                $badge.Margin = [System.Windows.Thickness]::new(0, 1, 10, 0)
                $bnum = New-Object System.Windows.Controls.TextBlock
                $bnum.Text = $stepNum
                $bnum.FontSize = [int]$cfg.Font - 2
                $bnum.FontWeight = [System.Windows.FontWeights]::Bold
                $bnum.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $bnum.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                $bnum.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $badge.Child = $bnum
                $row.Children.Add($badge) | Out-Null
                $stb = New-Object System.Windows.Controls.TextBlock
                Set-TextBlockWithLinks -TextBlock $stb -Text $stepTxt -AccentHex $AccentHex -BaseFont $cfg.Font -LinkSession $LinkSession
                $stb.FontSize = $cfg.Font
                $stb.LineHeight = $cfg.LineHeight
                $stb.FontWeight = [System.Windows.FontWeights]::Medium
                $stb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $stb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
                $stb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $stb.MaxWidth = $readmeMaxW
                $stb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $row.Children.Add($stb) | Out-Null
                $target.Children.Add($row) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($stb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($stb) | Out-Null }
                continue
            }

            if ($isB1 -or $isB2) {
                $row = New-Object System.Windows.Controls.DockPanel
                $leftMargin = if ($isB2) { 22 } else { 0 }
                $row.Margin = [System.Windows.Thickness]::new($leftMargin, 3, 0, 3)
                $mk = New-Object System.Windows.Controls.TextBlock
                [System.Windows.Controls.DockPanel]::SetDock($mk, 'Left')
                if ($isB2) {
                    $mk.Text = "$sq"
                    $mk.FontSize = [int]$cfg.Font - 3
                    $mk.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a8a98")
                } else {
                    $mk.Text = "$bullet"
                    $mk.FontSize = $cfg.Font
                    $mk.FontWeight = [System.Windows.FontWeights]::Bold
                    $mk.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                }
                $mk.LineHeight = $cfg.LineHeight
                $mk.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
                $mk.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
                $mk.MinWidth = 10
                $row.Children.Add($mk) | Out-Null
                $btb = New-Object System.Windows.Controls.TextBlock
                $bodyText = if ($isB2) { $b2text } else { $b1text }
                Set-TextBlockWithLinks -TextBlock $btb -Text $bodyText -AccentHex $AccentHex -BaseFont $cfg.Font -LinkSession $LinkSession
                $btb.FontSize = $cfg.Font
                $btb.LineHeight = $cfg.LineHeight
                $btb.FontWeight = [System.Windows.FontWeights]::Medium
                $btb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $btb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
                $btb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $btb.MaxWidth = $readmeMaxW
                $btb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $row.Children.Add($btb) | Out-Null
                $target.Children.Add($row) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($btb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($btb) | Out-Null }
                continue
            }

            # Plain paragraph line
            $ptb = New-Object System.Windows.Controls.TextBlock
            Set-TextBlockWithLinks -TextBlock $ptb -Text $ln -AccentHex $AccentHex -BaseFont $cfg.Font -LinkSession $LinkSession
            $ptb.FontSize = $cfg.Font
            $ptb.LineHeight = $cfg.LineHeight
            $ptb.FontWeight = [System.Windows.FontWeights]::Medium
            $ptb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $ptb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
            $ptb.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $ptb.MaxWidth = $readmeMaxW
            $ptb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $ptb.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
            $target.Children.Add($ptb) | Out-Null
            if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ptb) | Out-Null }
            if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($ptb) | Out-Null }
        }
    }
    $box = New-Object System.Windows.Controls.Border
    $box.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $box.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
    $box.BorderThickness = [System.Windows.Thickness]::new(1)
    $box.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $box.Padding = [System.Windows.Thickness]::new(14, 10, 14, 12)
    $box.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)

    $stack = New-Object System.Windows.Controls.StackPanel
    $box.Child = $stack

    # Accent left bar in heading row
    $headRow = New-Object System.Windows.Controls.StackPanel
    $headRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $headRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
    $bar = New-Object System.Windows.Controls.Border
    $bar.Width = 3
    $bar.CornerRadius = [System.Windows.CornerRadius]::new(2)
    $bar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
    $bar.Margin = [System.Windows.Thickness]::new(0, 1, 8, 1)
    $headRow.Children.Add($bar) | Out-Null

    $h = New-Object System.Windows.Controls.TextBlock
    Set-TextBlockWithLinks -TextBlock $h -Text $Heading -LinkSession $LinkSession -AccentHex $AccentHex -BaseFont $headFont
    $h.FontSize = $headFont
    $h.FontWeight = [System.Windows.FontWeights]::SemiBold
    $h.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0f0f4")
    $h.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $headRow.Children.Add($h) | Out-Null
    $stack.Children.Add($headRow) | Out-Null
    # Register the heading so Apply-DetailSize can rescale it with
    # the body. We tag it as a heading so the resizer knows to use
    # font+1 rather than the plain body size.
    if ($null -ne $global:DetailReadmeTextBlocks) {
        $h.Tag = "heading"
        $global:DetailReadmeTextBlocks.Add($h) | Out-Null
    }

    # Body rendering: split out markdown image syntax
    # `![alt](path)` so we can show the image as a real Image
    # control instead of leaving it as visible text. Anything
    # between two image tokens (or before/after them) is rendered
    # as a normal TextBlock with the existing bullet/bold cleanup.
    $imgRegex = '!\[[^\]]*\]\(([^)]+)\)'
    $imgMatches = [regex]::Matches($Body, $imgRegex)

    if ($imgMatches.Count -gt 0 -and $ImageBaseDir) {
        $cursor = 0
        foreach ($m in $imgMatches) {
            # Text before the image
            if ($m.Index -gt $cursor) {
                $textChunk = $Body.Substring($cursor, $m.Index - $cursor)
                $cleaned = & $formatBody $textChunk
                & $renderBody $stack $cleaned
            }
            # The image itself (resolve relative to the README's folder)
            $rel = $m.Groups[1].Value
            $abs = if ([System.IO.Path]::IsPathRooted($rel)) { $rel } else { Join-Path $ImageBaseDir $rel }
            if (Test-Path $abs) {
                try {
                    $img = New-Object System.Windows.Controls.Image
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.UriSource = New-Object System.Uri($abs, [System.UriKind]::Absolute)
                    $bmp.EndInit()
                    if ($bmp.CanFreeze) { $bmp.Freeze() }
                    $img.Source = $bmp
                    $img.Stretch = [System.Windows.Media.Stretch]::Uniform
                    $img.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                    # Inline preview grows with the window like the
                    # readme text ($readmeMaxW is 0.78x window width,
                    # clamped 720-1040), but is capped at the image's
                    # NATIVE width so the layout text never upscales
                    # into a blurry mess. Landscape control charts
                    # (~1400px wide) use the full responsive range;
                    # tall portrait charts stop at their real width.
                    $nativeW = 900
                    try { if ($bmp.PixelWidth -gt 0) { $nativeW = [int]$bmp.PixelWidth } } catch { }
                    $imgCap = if ($readmeMaxW -gt 0) { [Math]::Min($readmeMaxW, $nativeW) } else { [Math]::Min(900, $nativeW) }
                    $img.MaxWidth = $imgCap
                    $img.Cursor = [System.Windows.Input.Cursors]::Hand
                    $img.ToolTip = "Click to enlarge"
                    # Keep the tooltip short-lived so it doesn't linger
                    # after the mouse moves away.
                    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($img, 300)
                    [System.Windows.Controls.ToolTipService]::SetShowDuration($img, 1500)
                    $img.Margin = [System.Windows.Thickness]::new(0, 4, 0, 8)
                    # Stash the absolute path on the control so the
                    # click handler can find it without closure
                    # capture (PS5 quirks with $abs in closures).
                    $img.Tag = $abs
                    $img.Add_MouseLeftButtonUp({
                        param($s, $e)
                        $path = $s.Tag
                        if (-not $path -or -not (Test-Path $path)) { return }
                        try {
                            # Lightbox window: borderless, near-fullscreen,
                            # dark backdrop. Click anywhere or press Esc
                            # closes. We size the window to fit the
                            # working area minus a 60px margin so the
                            # image always has breathing room.
                            $sb = [System.Windows.SystemParameters]
                            $wa = $sb::WorkArea
                            $win = New-Object System.Windows.Window
                            $win.WindowStyle  = [System.Windows.WindowStyle]::None
                            $win.AllowsTransparency = $true
                            $win.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cc000000")
                            $win.ShowInTaskbar = $false
                            $win.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
                            $win.Left   = $wa.Left + 30
                            $win.Top    = $wa.Top + 30
                            $win.Width  = $wa.Width - 60
                            $win.Height = $wa.Height - 60
                            $win.Topmost = $true
                            $win.ResizeMode = [System.Windows.ResizeMode]::NoResize
                            try {
                                if ($global:window) { $win.Owner = $global:window }
                            } catch {}
                            $grid = New-Object System.Windows.Controls.Grid
                            $bigImg = New-Object System.Windows.Controls.Image
                            $bigBmp = New-Object System.Windows.Media.Imaging.BitmapImage
                            $bigBmp.BeginInit()
                            $bigBmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                            $bigBmp.UriSource = New-Object System.Uri($path, [System.UriKind]::Absolute)
                            $bigBmp.EndInit()
                            if ($bigBmp.CanFreeze) { $bigBmp.Freeze() }
                            $bigImg.Source = $bigBmp
                            $bigImg.Stretch = [System.Windows.Media.Stretch]::Uniform
                            $bigImg.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                            $bigImg.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
                            $bigImg.Margin = [System.Windows.Thickness]::new(20)
                            $grid.Children.Add($bigImg) | Out-Null
                            # Hint label in top-right corner
                            $hint = New-Object System.Windows.Controls.TextBlock
                            $hint.Text = "Click anywhere or press Esc to close"
                            $hint.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
                            $hint.FontSize = 12
                            $hint.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
                            $hint.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
                            $hint.Margin = [System.Windows.Thickness]::new(0, 12, 18, 0)
                            $hint.IsHitTestVisible = $false
                            $grid.Children.Add($hint) | Out-Null
                            $win.Content = $grid
                            $win.Add_MouseLeftButtonUp({ param($a, $b) try { $a.Close() } catch {} })
                            $win.Add_KeyDown({
                                param($a, $b)
                                if ($b.Key -eq [System.Windows.Input.Key]::Escape) {
                                    try { $a.Close() } catch {}
                                }
                            })
                            $win.Show()
                            $win.Focus() | Out-Null
                        } catch {}
                    })
                    $stack.Children.Add($img) | Out-Null
                } catch {
                    # Fall back: show the markdown literal so the
                    # info isn't lost - better than silently
                    # eating the image.
                    $fb = New-Object System.Windows.Controls.TextBlock
                    $fb.Text = $m.Value
                    $fb.FontSize = 13
                    $fb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#777788")
                    $fb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                    $fb.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
                    $stack.Children.Add($fb) | Out-Null
                }
            }
            $cursor = $m.Index + $m.Length
        }
        # Tail text after the last image
        if ($cursor -lt $Body.Length) {
            $tail = $Body.Substring($cursor)
            $cleaned = & $formatBody $tail
            & $renderBody $stack $cleaned
        }
    } else {
        # No images: render the cleaned body line-by-line so
        # bullets, sub-bullets and numbered steps get their proper
        # markers/badges.
        $cleanBody = & $formatBody $Body
        & $renderBody $stack $cleanBody
    }

    if ($AppendChild) {
        $stack.Children.Add($AppendChild) | Out-Null
    }

    return $box
}


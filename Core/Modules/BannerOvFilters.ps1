# ---------------------------------------------------------------
# Banner hover-close: after dwelling on a banner for 5 seconds,
# show a small Close + Always-disable overlay top-right. Close
# hides the banner for this session; Always disable persists
# the choice to .hub-settings.json so the banner stays hidden
# on future launches.
# ---------------------------------------------------------------
function global:Setup-BannerHoverClose {
    param(
        $Banner,
        $Overlay,
        $CloseBtn,
        $DisableBtn,
        [string]$SettingKey
    )
    if (-not $Banner -or -not $Overlay -or -not $CloseBtn -or -not $DisableBtn) { return }

    $showTimer = New-Object System.Windows.Threading.DispatcherTimer
    $showTimer.Interval = [TimeSpan]::FromSeconds(5)
    $hideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $hideTimer.Interval = [TimeSpan]::FromMilliseconds(800)

    $showTimer.Add_Tick({
        $showTimer.Stop()
        $Overlay.Visibility = [System.Windows.Visibility]::Visible
    }.GetNewClosure())

    $hideTimer.Add_Tick({
        $hideTimer.Stop()
        $Overlay.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    $Banner.Add_MouseEnter({
        $hideTimer.Stop()
        if ($Overlay.Visibility -ne [System.Windows.Visibility]::Visible) {
            $showTimer.Stop()
            $showTimer.Start()
        }
    }.GetNewClosure())

    $Banner.Add_MouseLeave({
        $showTimer.Stop()
        if ($Overlay.Visibility -eq [System.Windows.Visibility]::Visible) {
            $hideTimer.Stop()
            $hideTimer.Start()
        }
    }.GetNewClosure())

    # Close = hide for this session only
    $CloseBtn.Add_MouseLeftButtonUp({
        $Banner.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())
    $CloseBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $CloseBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })

    # Always disable = hide + persist
    $DisableBtn.Add_MouseLeftButtonUp({
        $Banner.Visibility = [System.Windows.Visibility]::Collapsed
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key $SettingKey -Value $true
        }
    }.GetNewClosure())
    $DisableBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $DisableBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })
}

# Filter chip - bigger, bolder, with a colored left accent bar
# so the genre pills feel more like editorial features and
# less like flat radio buttons.


function global:New-OvFilterChip {
    param(
        [string]$Label,
        [string]$Key,
        [bool]$IsActive,
        [string]$AccentColor = "#dd6600",
        $IconGeometry = $null
    )

    # Size tracks the Explore S/M/L setting so the chips grow and shrink
    # with the rest of the Explore view. The M values match the original
    # fixed design exactly, so M looks identical to before.
    $szKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $sz = switch ($szKey) {
        "S"     { @{ Font = 11.0; Icon = 13; Corner = 5; Bar = 4; MinH = 26; LblL = 11; LblLIcon = 7; LblR = 12; LblV = 5; IconL = 10 } }
        "L"     { @{ Font = 12.5; Icon = 15; Corner = 6; Bar = 5; MinH = 30; LblL = 13; LblLIcon = 8; LblR = 14; LblV = 6; IconL = 12 } }
        default { @{ Font = 12.0; Icon = 14; Corner = 5; Bar = 4; MinH = 28; LblL = 12; LblLIcon = 7; LblR = 13; LblV = 5; IconL = 11 } }
    }

    $chip = New-Object System.Windows.Controls.Border
    $chip.CornerRadius = [System.Windows.CornerRadius]::new($sz.Corner)
    $chip.Padding = [System.Windows.Thickness]::new(0)
    $chip.Margin = [System.Windows.Thickness]::new(0, 0, 8, 8)
    $chip.Cursor = [System.Windows.Input.Cursors]::Hand
    $chip.BorderThickness = [System.Windows.Thickness]::new(1)
    if ($IsActive) {
        $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a1a08")
        $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentColor)
    } else {
        $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
        $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    }

    # Inner grid: colored accent bar on left + optional icon + label.
    $inner = New-Object System.Windows.Controls.Grid
    $inner.MinHeight = $sz.MinH
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = New-Object System.Windows.GridLength $sz.Bar
    $inner.ColumnDefinitions.Add($col1) | Out-Null

    if ($IconGeometry) {
        $colIcon = New-Object System.Windows.Controls.ColumnDefinition
        $colIcon.Width = [System.Windows.GridLength]::Auto
        $inner.ColumnDefinitions.Add($colIcon) | Out-Null
    }

    $colLbl = New-Object System.Windows.Controls.ColumnDefinition
    $colLbl.Width = [System.Windows.GridLength]::Auto
    $inner.ColumnDefinitions.Add($colLbl) | Out-Null

    $accentBar = New-Object System.Windows.Shapes.Rectangle
    $accentBar.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentColor)
    [System.Windows.Controls.Grid]::SetColumn($accentBar, 0)
    $inner.Children.Add($accentBar) | Out-Null

    $iconPath = $null
    if ($IconGeometry) {
        $iconPath = New-Object System.Windows.Shapes.Path
        $iconPath.Data = $IconGeometry
        $iconPath.StrokeThickness    = 1.5
        $iconPath.StrokeLineJoin     = [System.Windows.Media.PenLineJoin]::Round
        $iconPath.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
        $iconPath.StrokeEndLineCap   = [System.Windows.Media.PenLineCap]::Round
        $iconPath.Width   = $sz.Icon
        $iconPath.Height  = $sz.Icon
        $iconPath.Stretch = [System.Windows.Media.Stretch]::Uniform
        $iconPath.SnapsToDevicePixels = $true
        $iconPath.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $iconPath.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $iconPath.Margin = [System.Windows.Thickness]::new($sz.IconL, 0, 0, 0)
        if ($IsActive) {
            $iconPath.Stroke = [System.Windows.Media.Brushes]::White
        } else {
            $iconPath.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentColor)
        }
        [System.Windows.Controls.Grid]::SetColumn($iconPath, 1)
        $inner.Children.Add($iconPath) | Out-Null
    }

    $txt = New-Object System.Windows.Controls.TextBlock
    $txt.Text = $Label.ToUpper()
    $txt.FontSize = $sz.Font
    $txt.FontWeight = [System.Windows.FontWeights]::Bold
    $txt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    if ($iconPath) {
        $txt.Margin = [System.Windows.Thickness]::new($sz.LblLIcon, $sz.LblV, $sz.LblR, $sz.LblV)
    } else {
        $txt.Margin = [System.Windows.Thickness]::new($sz.LblL, $sz.LblV, $sz.LblR, $sz.LblV)
    }
    $txt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    if ($IsActive) {
        $txt.Foreground = [System.Windows.Media.Brushes]::White
    } else {
        $txt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bbbbbb")
    }
    $lblColIdx = if ($iconPath) { 2 } else { 1 }
    [System.Windows.Controls.Grid]::SetColumn($txt, $lblColIdx)
    $inner.Children.Add($txt) | Out-Null

    $chip.Child = $inner

    $chip.Resources.Add("filterKey", $Key)
    $chip.Resources.Add("filterText", $txt)
    $chip.Resources.Add("filterAccent", $AccentColor)
    if ($iconPath) {
        $chip.Resources.Add("filterIcon", $iconPath)
    }

    # Soft glow hover - border + text brighten on enter, restore on leave.
    Add-GlowHover -Border $chip -AccentHex $AccentColor
    return $chip
}

function global:Update-OvFilterChips {
    param($ChipPanel, [string]$ActiveKey)
    if (-not $ChipPanel) { return }
    foreach ($chip in $ChipPanel.Children) {
        # The power panel also carries the GPU rating controls at the end
        # of the row. They are not filter chips and have no filterKey, so
        # skip them - otherwise the else-branch below would repaint them
        # in chip colours every time the selection changes.
        if (-not $chip.Resources.Contains("filterKey")) { continue }
        $key  = $chip.Resources.Item("filterKey")
        $txt  = $chip.Resources.Item("filterText")
        $acc  = $chip.Resources.Item("filterAccent")
        $icon = $null
        if ($chip.Resources.Contains("filterIcon")) {
            $icon = $chip.Resources.Item("filterIcon")
        }
        if ($key -eq $ActiveKey) {
            $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a1a08")
            $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($acc)
            if ($txt)  { $txt.Foreground = [System.Windows.Media.Brushes]::White }
            if ($icon) { $icon.Stroke    = [System.Windows.Media.Brushes]::White }
        } else {
            $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
            $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
            if ($txt)  { $txt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bbbbbb") }
            if ($icon) { $icon.Stroke    = [System.Windows.Media.BrushConverter]::new().ConvertFromString($acc) }
        }
        # Drop any glow-hover stashes so a pending MouseLeave restore
        # can't clobber what we just set.
        if ($chip.Resources.Contains("ghBdBrush")) {
            $chip.Resources.Remove("ghBdBrush") | Out-Null
        }
        if ($txt -and $txt.Resources.Contains("ghFg")) {
            $txt.Resources.Remove("ghFg") | Out-Null
        }
    }
}

# Genre accent colors - one ramp per bucket so the chips feel
# personal rather than uniform orange. Kept as a flat key->color
# map so external callers (e.g. Set-OvBannerForActiveGenre and
# Power-filter chip construction) stay drop-in compatible. Icon
# shapes are built programmatically in New-OvGenreIcon below.
$global:OvGenreColors = @{
    "ALL"       = "#dd6600"
    "HORROR"    = "#cc3344"
    "ACTION"    = "#dd6600"
    "ADVENTURE" = "#44aa88"
    "RPG"       = "#aa66dd"
    "COOP"      = "#44aadd"
    "PUZZLE"    = "#dd9922"
    "SIM"       = "#88aa44"
    "FREE"      = "#34D399"
    "NEW"       = "#38BDF8"
}

# Genre icons. Built programmatically as Geometry objects -
# combining EllipseGeometry/LineGeometry/RectangleGeometry inside
# a GeometryGroup. Avoids the Path Mini-Language parser entirely,
# which silently produced empty geometries in this PowerShell
# host. All shapes live inside a 16x16 viewbox and scale to the
# Path's Width/Height via Stretch=Uniform.
function global:New-OvGenreIcon {
    param([string]$Key)

    $g = New-Object System.Windows.Media.GeometryGroup
    $g.FillRule = [System.Windows.Media.FillRule]::Nonzero

    $addRect = {
        param($x, $y, $w, $h)
        $r = New-Object System.Windows.Media.RectangleGeometry
        $r.Rect = New-Object System.Windows.Rect $x, $y, $w, $h
        $g.Children.Add($r) | Out-Null
    }
    $addLine = {
        param($x1, $y1, $x2, $y2)
        $l = New-Object System.Windows.Media.LineGeometry
        $l.StartPoint = New-Object System.Windows.Point $x1, $y1
        $l.EndPoint   = New-Object System.Windows.Point $x2, $y2
        $g.Children.Add($l) | Out-Null
    }
    $addEllipse = {
        param($cx, $cy, $rx, $ry)
        $e = New-Object System.Windows.Media.EllipseGeometry
        $e.Center = New-Object System.Windows.Point $cx, $cy
        $e.RadiusX = $rx
        $e.RadiusY = $ry
        $g.Children.Add($e) | Out-Null
    }

    switch ($Key) {
        "ALL" {
            # 2x2 grid of small squares
            & $addRect 2 2 5 5
            & $addRect 9 2 5 5
            & $addRect 2 9 5 5
            & $addRect 9 9 5 5
        }
        "HORROR" {
            # Tombstone: rounded-top stone + cross inset. Reads as
            # "RIP / horror" cleanly - earlier ghost-with-eyes
            # version was reading as a smiley emoji.
            # Stone outline as a single PathGeometry: vertical sides
            # + arc top.
            $stone = New-Object System.Windows.Media.PathGeometry
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = New-Object System.Windows.Point 3, 14
            $fig.IsClosed = $true
            $l1 = New-Object System.Windows.Media.LineSegment
            $l1.Point = New-Object System.Windows.Point 3, 6
            $fig.Segments.Add($l1) | Out-Null
            $arc = New-Object System.Windows.Media.ArcSegment
            $arc.Point = New-Object System.Windows.Point 13, 6
            $arc.Size  = New-Object System.Windows.Size 5, 4
            $arc.SweepDirection = [System.Windows.Media.SweepDirection]::Clockwise
            $arc.IsLargeArc = $false
            $arc.IsStroked  = $true
            $fig.Segments.Add($arc) | Out-Null
            $l2 = New-Object System.Windows.Media.LineSegment
            $l2.Point = New-Object System.Windows.Point 13, 14
            $fig.Segments.Add($l2) | Out-Null
            $stone.Figures.Add($fig) | Out-Null
            $g.Children.Add($stone) | Out-Null
            # Cross inset (vertical longer, horizontal shorter)
            & $addLine 8 6 8 12
            & $addLine 5.5 8.5 10.5 8.5
        }
        "ACTION" {
            # Crosshair: outer circle + 4 ticks + center dot
            & $addEllipse 8 8 5 5
            & $addLine 8 1 8 4
            & $addLine 8 12 8 15
            & $addLine 1 8 4 8
            & $addLine 12 8 15 8
            & $addEllipse 8 8 0.8 0.8
        }
        "ADVENTURE" {
            # Pine tree: 3 stacked triangle layers + small trunk.
            # Unambiguous wilderness/adventure symbol that reads
            # clearly even in 16x16. Earlier compass/map/flag/peak
            # attempts were too easily confused with other shapes.
            $tree = New-Object System.Windows.Media.PathGeometry
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = New-Object System.Windows.Point 8, 1.5
            $fig.IsClosed = $true
            # Down-left to first layer bottom
            $segs = @(
                @(4, 6), @(6, 6),
                @(3, 9.5), @(5.5, 9.5),
                @(2.5, 13), @(13.5, 13),
                @(10.5, 9.5), @(13, 9.5),
                @(10, 6), @(12, 6)
            )
            foreach ($pt in $segs) {
                $seg = New-Object System.Windows.Media.LineSegment
                $seg.Point = New-Object System.Windows.Point $pt[0], $pt[1]
                $fig.Segments.Add($seg) | Out-Null
            }
            $tree.Figures.Add($fig) | Out-Null
            $g.Children.Add($tree) | Out-Null
            # Trunk
            & $addRect 7 13 2 1.5
        }
        "RPG" {
            # Sword: vertical blade + horizontal crossguard + pommel
            & $addLine 8 2 8 11
            & $addLine 5 5 11 5
            & $addLine 6 13 10 13
            & $addLine 8 11 8 14
        }
        "COOP" {
            # Two distinct person silhouettes (head + shoulders),
            # clearly separated. Earlier "two heads + shared
            # shoulders curve" was reading as one frowning face.
            # Person 1 (left)
            & $addEllipse 4.5 5 2 2
            & $addRect 1.5 8 6 6
            # Person 2 (right)
            & $addEllipse 11.5 5 2 2
            & $addRect 8.5 8 6 6
        }
        "PUZZLE" {
            # Simpler puzzle piece: square with circular bump on the
            # right side
            & $addRect 2 4 8 8
            & $addEllipse 11 8 2 2
        }
        "SIM" {
            # Steering wheel: outer ring + inner hub + 4 spokes
            & $addEllipse 8 8 6 6
            & $addEllipse 8 8 1.8 1.8
            & $addLine 8 2 8 6.2
            & $addLine 8 9.8 8 14
            & $addLine 2 8 6.2 8
            & $addLine 9.8 8 14 8
        }
        "FREE" {
            # Gift box: lid + body + a vertical ribbon down the
            # front + a two-loop bow on top. Reads as "free gift"
            # and pairs with the green FREE accent.
            & $addRect 2.6 5 10.8 2.6     # lid
            & $addRect 3.6 7.6 8.8 5.8    # body
            & $addLine 8 5 8 13.4         # ribbon down the front
            # Bow: two Bezier loops meeting at the knot (8,5).
            $bow = New-Object System.Windows.Media.PathGeometry
            $lf = New-Object System.Windows.Media.PathFigure
            $lf.StartPoint = New-Object System.Windows.Point 8, 5
            $lf.IsClosed = $true
            $lb1 = New-Object System.Windows.Media.BezierSegment
            $lb1.Point1 = New-Object System.Windows.Point 6.4, 2.4
            $lb1.Point2 = New-Object System.Windows.Point 3.6, 3
            $lb1.Point3 = New-Object System.Windows.Point 4.6, 4.6
            $lf.Segments.Add($lb1) | Out-Null
            $lb2 = New-Object System.Windows.Media.BezierSegment
            $lb2.Point1 = New-Object System.Windows.Point 5.2, 5.4
            $lb2.Point2 = New-Object System.Windows.Point 6.8, 5
            $lb2.Point3 = New-Object System.Windows.Point 8, 5
            $lf.Segments.Add($lb2) | Out-Null
            $bow.Figures.Add($lf) | Out-Null
            $rf = New-Object System.Windows.Media.PathFigure
            $rf.StartPoint = New-Object System.Windows.Point 8, 5
            $rf.IsClosed = $true
            $rb1 = New-Object System.Windows.Media.BezierSegment
            $rb1.Point1 = New-Object System.Windows.Point 9.6, 2.4
            $rb1.Point2 = New-Object System.Windows.Point 12.4, 3
            $rb1.Point3 = New-Object System.Windows.Point 11.4, 4.6
            $rf.Segments.Add($rb1) | Out-Null
            $rb2 = New-Object System.Windows.Media.BezierSegment
            $rb2.Point1 = New-Object System.Windows.Point 10.8, 5.4
            $rb2.Point2 = New-Object System.Windows.Point 9.2, 5
            $rb2.Point3 = New-Object System.Windows.Point 8, 5
            $rf.Segments.Add($rb2) | Out-Null
            $bow.Figures.Add($rf) | Out-Null
            $g.Children.Add($bow) | Out-Null
        }
        "NEW" {
            # Two clean sparkle crosses: instantly reads as fresh/new at the
            # same small size as the other line icons.
            & $addLine 8 1.5 8 10.5
            & $addLine 3.5 6 12.5 6
            & $addLine 12.5 10.5 12.5 14.5
            & $addLine 10.5 12.5 14.5 12.5
        }
    }

    return $g
}

function global:Build-OvGenreFilter {
    $panel = $window.FindName("OvGenreFilter")
    if (-not $panel) { return }
    $panel.Children.Clear()

    $chips = @(@{ Key="ALL"; Label="All" })
    foreach ($g in $global:OverviewGenres) {
        $chips += @{ Key=$g.Key; Label=$g.Label }
    }
    # FREE and NEW are cross-genre shortcuts. NEW deliberately comes
    # immediately after FREE and uses the same rolling title list as search.
    $chips += @{ Key="FREE"; Label="Free" }
    $chips += @{ Key="NEW"; Label="New" }
    foreach ($c in $chips) {
        $accent = $global:OvGenreColors[$c.Key]
        if (-not $accent) { $accent = "#dd6600" }
        # Build the matching icon geometry from .NET primitives.
        # Returns $null for unknown keys; chip falls back to a
        # label-only layout in that case.
        $iconGeo = $null
        try {
            $iconGeo = New-OvGenreIcon -Key $c.Key
        } catch {
            $iconGeo = $null
        }
        $chip = New-OvFilterChip -Label $c.Label -Key $c.Key `
                                 -IsActive ($c.Key -eq "ALL") `
                                 -AccentColor $accent `
                                 -IconGeometry $iconGeo
        if ($c.Key -eq 'NEW') { $chip.ToolTip = 'Added to the Hub during the last 10.5 days' }
        $keyCap = $c.Key
        $chip.Add_MouseLeftButtonUp({
            $global:OvActiveGenre = $keyCap
            Update-OvFilterChips -ChipPanel $global:OvGenreFilterPanel -ActiveKey $keyCap
            Apply-OvFilters
            # Refresh the featured banner to a game that fits the
            # active genre (or a random pick again when ALL).
            Set-OvBannerForActiveGenre
        }.GetNewClosure())
        $panel.Children.Add($chip) | Out-Null
    }
    $global:OvGenreFilterPanel = $panel
    if (Get-Command Set-OvHeaderPillStyle -ErrorAction SilentlyContinue) {
        Set-OvHeaderPillStyle -Border ($window.FindName("OvGenreHeader"))
    }
}

function global:Build-OvPowerFilter {
    $panel = $window.FindName("OvPowerFilter")
    if (-not $panel) { return }
    $panel.Children.Clear()

    $chips = @(@{ Key="ALL"; Label="All"; Color="#888888" })
    foreach ($b in $global:OverviewPowerBuckets) {
        $chips += @{ Key=$b.Key; Label=$b.Label; Color=$b.Color }
    }
    foreach ($c in $chips) {
        $chip = New-OvFilterChip -Label $c.Label -Key $c.Key -IsActive ($c.Key -eq "ALL") -AccentColor $c.Color
        $keyCap = $c.Key
        $chip.Add_MouseLeftButtonUp({
            $global:OvActivePower = $keyCap
            Update-OvFilterChips -ChipPanel $global:OvPowerFilterPanel -ActiveKey $keyCap
            Apply-OvFilters
        }.GetNewClosure())
        $panel.Children.Add($chip) | Out-Null
    }
    $global:OvPowerFilterPanel = $panel
    # Rating controls sit at the end of this very row, after a gap.
    Add-OvGpuRateControls -Panel $panel
}

# ---------------------------------------------------------------
# GPU rating for the Explore power filter ("Rate my GPU").
# ---------------------------------------------------------------
# The buttons live at the END of the tier-pill row itself (with a gap),
# not in a row of their own - they belong to that selection.
# The Explore filter uses 4 coarse buckets, the detail page uses the
# 6 PowerTiers. Map a resolved GPU tier index onto a bucket key:
#   tier 0/1 (LOW,BASIC)   -> LOW
#   tier 2   (SOLID)       -> SOLID
#   tier 3/4 (STRONG,HIGH) -> HIGH
#   tier 5   (EXTREME)     -> EXTREME
# A GPU below the scale (-2) still maps to LOW - the honest closest
# bucket. -1 (unknown) has no bucket and is reported as such.
function global:Get-OvBucketKeyForGpuTier {
    param([int]$TierIdx)
    if ($TierIdx -eq -2) { return "LOW" }
    if ($TierIdx -lt 0)  { return $null }
    if ($TierIdx -le 1)  { return "LOW" }
    if ($TierIdx -eq 2)  { return "SOLID" }
    if ($TierIdx -le 4)  { return "HIGH" }
    return "EXTREME"
}

# Run the rating: read the GPU locally (the click is the consent),
# select the matching bucket in the power filter, report inline.
function global:Invoke-OvGpuRate {
    $resTxt = $global:OvRateResultTxt
    $gpu = Get-InstalledGpuName
    $bc = [System.Windows.Media.BrushConverter]::new()
    if (-not $gpu) {
        if ($resTxt) { $resTxt.Text = "No GPU detected"; $resTxt.Foreground = $bc.ConvertFromString("#8a93a3") }
        return
    }
    $idx = Get-GpuTierIndex -Name $gpu
    $key = Get-OvBucketKeyForGpuTier -TierIdx $idx
    if (-not $key) {
        if ($resTxt) { $resTxt.Text = "$gpu - not in the tier list"; $resTxt.Foreground = $bc.ConvertFromString("#8a93a3") }
        return
    }
    $global:OvActivePower = $key
    if ($global:OvPowerFilterPanel) {
        Update-OvFilterChips -ChipPanel $global:OvPowerFilterPanel -ActiveKey $key
    }
    Apply-OvFilters
    if ($resTxt) {
        $tierLabel = if ($idx -ge 0) { $global:PowerTiers[$idx].Label } else { "below LOW" }
        $resTxt.Text = "$gpu - $tierLabel"
        $resTxt.Foreground = $bc.ConvertFromString("#5fd08a")
    }
}

# Paint the "Always rate" toggle to match its persisted state.
function global:Update-OvAlwaysRateVisual {
    param([bool]$On)
    if (-not $global:OvAlwaysRateBtn -or -not $global:OvAlwaysRateTxt) { return }
    $bc = [System.Windows.Media.BrushConverter]::new()
    # Background stays transparent in both states - the border and the
    # label colour carry the on/off distinction. restBorder is updated
    # too so a later MouseLeave restores the correct resting colour.
    $global:OvAlwaysRateBtn.Background = [System.Windows.Media.Brushes]::Transparent
    if ($On) {
        $global:OvAlwaysRateBtn.Resources["restBorder"] = "#6a9ad8"
        $global:OvAlwaysRateBtn.BorderBrush = $bc.ConvertFromString("#6a9ad8")
        $global:OvAlwaysRateTxt.Foreground  = $bc.ConvertFromString("#6a9ad8")
        $global:OvAlwaysRateTxt.Text = "Always: on"
    } else {
        $global:OvAlwaysRateBtn.Resources["restBorder"] = "#4a6a90"
        $global:OvAlwaysRateBtn.BorderBrush = $bc.ConvertFromString("#4a6a90")
        $global:OvAlwaysRateTxt.Foreground  = $bc.ConvertFromString("#8a93a3")
        $global:OvAlwaysRateTxt.Text = "Always rate"
    }
}

# Show/hide the rating controls. Exact Tier mode hides them: there the
# user deliberately browses one tier, so their own GPU is irrelevant.
function global:Update-OvGpuRateVisibility {
    $vis = if ($global:OvPowerMode -eq "exact") {
        [System.Windows.Visibility]::Collapsed
    } else {
        [System.Windows.Visibility]::Visible
    }
    foreach ($el in @($global:OvRateBtn, $global:OvAlwaysRateBtn, $global:OvRateResultHost)) {
        if ($el) { $el.Visibility = $vis }
    }
}

# Build a rating button that matches New-OvFilterChip's geometry
# EXACTLY: same S/M/L size table, same corner radius, same inner
# MinHeight and the same 8px right/bottom margin. That way the buttons
# sit on the same baseline as the tier pills and are the same height,
# and they track the Explore S/M/L setting just like the pills do.
function global:New-OvRateButton {
    param([string]$Label, [bool]$Primary, [double]$LeftMargin)
    $szKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $sz = switch ($szKey) {
        "S"     { @{ Font = 11.0; Corner = 5; MinH = 26; LblL = 11; LblR = 12; LblV = 5 } }
        "L"     { @{ Font = 12.5; Corner = 6; MinH = 30; LblL = 13; LblR = 14; LblV = 6 } }
        default { @{ Font = 12.0; Corner = 5; MinH = 28; LblL = 12; LblR = 13; LblV = 5 } }
    }
    $b = New-Object System.Windows.Controls.Border
    $b.CornerRadius = [System.Windows.CornerRadius]::new($sz.Corner)
    $b.Padding = [System.Windows.Thickness]::new(0)
    $b.Margin = [System.Windows.Thickness]::new($LeftMargin, 0, 8, 8)
    $b.BorderThickness = [System.Windows.Thickness]::new(1)
    # No fill - the outline carries the button. The former hover border
    # is now the resting one; hovering turns it yellow instead.
    $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a6a90")
    $b.Background  = [System.Windows.Media.Brushes]::Transparent
    $b.Cursor = [System.Windows.Input.Cursors]::Hand
    # Resting border colour, so MouseLeave can restore the right one even
    # after "Always rate" has switched this button to its active look.
    $b.Resources["restBorder"] = "#4a6a90"

    $inner = New-Object System.Windows.Controls.Grid
    $inner.MinHeight = $sz.MinH

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $Label
    $t.FontSize = $sz.Font
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $t.Margin = [System.Windows.Thickness]::new($sz.LblL, $sz.LblV, $sz.LblR, $sz.LblV)
    if ($Primary) {
        $t.FontWeight = [System.Windows.FontWeights]::SemiBold
        $t.Foreground = [System.Windows.Media.Brushes]::White
    } else {
        $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a93a3")
    }
    $inner.Children.Add($t) | Out-Null
    $b.Child = $inner

    $b.Add_MouseEnter({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ddcc44")
    })
    $b.Add_MouseLeave({
        $rest = if ($this.Resources.Contains("restBorder")) { $this.Resources.Item("restBorder") } else { "#4a6a90" }
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($rest)
    })
    return @{ Border = $b; Text = $t }
}

# Append the rating controls to the END of the tier-pill panel, after a
# clear gap (~3-4 spaces) so they read as a separate action, not a tier.
function global:Add-OvGpuRateControls {
    param($Panel)
    if (-not $Panel) { return }

    $rate = New-OvRateButton -Label "Rate my GPU" -Primary $true -LeftMargin 26
    $global:OvRateBtn = $rate.Border
    $rate.Border.ToolTip = "Reads your installed GPU name once, locally, and picks the matching power level"
    $rate.Border.Add_MouseLeftButtonUp({ Invoke-OvGpuRate })
    $Panel.Children.Add($rate.Border) | Out-Null

    $alw = New-OvRateButton -Label "Always rate" -Primary $false -LeftMargin 8
    $global:OvAlwaysRateBtn = $alw.Border
    $global:OvAlwaysRateTxt = $alw.Text
    $alw.Border.ToolTip = "Rate automatically every time you open Explore"
    $alw.Border.Add_MouseLeftButtonUp({
        $on = -not [bool](Get-HubSetting -Key "OvGpuRateAlways" -Default $false)
        Set-HubSetting -Key "OvGpuRateAlways" -Value $on
        Update-OvAlwaysRateVisual -On $on
        if ($on) { Invoke-OvGpuRate }
    })
    $Panel.Children.Add($alw.Border) | Out-Null

    # Result text: wrapped in a Grid of the same MinHeight as the pills
    # so it is vertically centred on their line instead of riding high.
    $szKey2 = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $rh = switch ($szKey2) { "S" { 26 } "L" { 30 } default { 28 } }
    $rf = switch ($szKey2) { "S" { 11.0 } "L" { 12.5 } default { 12.0 } }
    $resHost = New-Object System.Windows.Controls.Grid
    $resHost.MinHeight = $rh
    $resHost.Margin = [System.Windows.Thickness]::new(12, 0, 0, 8)
    $res = New-Object System.Windows.Controls.TextBlock
    $res.FontSize = $rf
    $res.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a93a3")
    $res.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $res.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $resHost.Children.Add($res) | Out-Null
    $global:OvRateResultTxt = $res
    $global:OvRateResultHost = $resHost
    $Panel.Children.Add($resHost) | Out-Null

    $alwaysOn = [bool](Get-HubSetting -Key "OvGpuRateAlways" -Default $false)
    Update-OvAlwaysRateVisual -On $alwaysOn
    Update-OvGpuRateVisibility
    if ($alwaysOn -and $global:OvPowerMode -ne "exact") { Invoke-OvGpuRate }
}

# Build a genre row: header + horizontal scroll of tiles + side
# arrows. Mouse wheel forwards to the page so vertical scrolling
# still works.
function global:New-OvGenreRow {
    param($Genre, $Games, [switch]$Deferred)

    $rowStack = New-Object System.Windows.Controls.StackPanel
    $rowStack.Margin = [System.Windows.Thickness]::new(0, 0, 0, 26)
    $rowStack.Resources.Add("genreKey", $Genre.Key)

    $hdr = New-Object System.Windows.Controls.StackPanel
    $hdr.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $hdr.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)

    $hdrTitle = New-Object System.Windows.Controls.TextBlock
    $hdrTitle.Text = $Genre.Label
    $hdrTitle.FontSize = 22
    $hdrTitle.FontWeight = [System.Windows.FontWeights]::Bold
    # White -> light-grey vertical gradient, matching tiles/banners/detail.
    $hdrTitleGrad = New-Object System.Windows.Media.LinearGradientBrush
    $hdrTitleGrad.StartPoint = [System.Windows.Point]::new(0, 0)
    $hdrTitleGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
    $hdrTitleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
    $hdrTitleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(216,222,227), 1))) | Out-Null
    $hdrTitleGrad.Freeze()
    $hdrTitle.Foreground = $hdrTitleGrad
    $hdrTitle.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $hdrTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $hdr.Children.Add($hdrTitle) | Out-Null

    # Count bubble: a small rounded pill instead of a dashed text run.
    # Left margin keeps the same offset from the title as the old "  -  ".
    $countBubble = New-Object System.Windows.Controls.Border
    $countBubble.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $countBubble.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e28")
    $countBubble.BorderThickness = [System.Windows.Thickness]::new(1)
    $countBubble.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2c2c3a")
    $countBubble.Padding = [System.Windows.Thickness]::new(7, 1, 7, 1)
    $countBubble.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
    $countBubble.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $hdrCount = New-Object System.Windows.Controls.TextBlock
    $hdrCount.Text = "$($Games.Count) games"
    $hdrCount.FontSize = 10
    $hdrCount.FontWeight = [System.Windows.FontWeights]::SemiBold
    $hdrCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9a9aae")
    $hdrCount.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $countBubble.Child = $hdrCount
    # Enlarge a little on hover so the count is easier to read.
    Add-HoverScale -Element $countBubble -Scale 1.12
    $hdr.Children.Add($countBubble) | Out-Null

    $rowStack.Children.Add($hdr) | Out-Null

    $rowGrid = New-Object System.Windows.Controls.Grid

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Hidden
    $scroll.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled
    # Forward mouse wheel to the visual parent so vertical page
    # scrolling still works when the cursor is over a row.
    $scroll.Add_PreviewMouseWheel({
        param($s, $e)
        $e.Handled = $true
        $parent = [System.Windows.Media.VisualTreeHelper]::GetParent($s)
        if ($parent) {
            $newEvent = New-Object System.Windows.Input.MouseWheelEventArgs `
                ([System.Windows.Input.Mouse]::PrimaryDevice, $e.Timestamp, $e.Delta)
            $newEvent.RoutedEvent = [System.Windows.UIElement]::MouseWheelEvent
            $parent.RaiseEvent($newEvent)
        }
    })

    $tilesPanel = New-Object System.Windows.Controls.StackPanel
    $tilesPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    # First copy: always present. In -Deferred mode the tiles are added
    # later, one per dispatcher cycle, by the background prewarm - the
    # header count still reflects $Games.Count so the row reads correctly
    # while its tiles stream in.
    if (-not $Deferred) {
        foreach ($g in $Games) {
            $tile = New-OverviewTile -Game $g
            $tilesPanel.Children.Add($tile) | Out-Null
        }
    }
    # Track whether the duplicate-copy has been added. We only add
    # it once we know the row actually overflows the viewport - if
    # everything fits, a duplicate would just show the same titles
    # twice on the page. The Loaded handler below makes the call
    # the moment WPF reports real Viewport/Extent widths.
    $tilesPanel.Tag = @{
        Games          = $Games
        DuplicateAdded = $false
    }
    $scroll.Content = $tilesPanel
    $rowGrid.Children.Add($scroll) | Out-Null

    # Right arrow
    $rightHost = New-Object System.Windows.Controls.Border
    $rightHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $rightHost.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch
    $rightHost.Width = 56
    $rightHost.Cursor = [System.Windows.Input.Cursors]::Hand
    $rightFade = New-Object System.Windows.Media.LinearGradientBrush
    $rightFade.StartPoint = New-Object System.Windows.Point 0, 0.5
    $rightFade.EndPoint   = New-Object System.Windows.Point 1, 0.5
    $rightFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,15,15,18)), 0.0)) | Out-Null
    $rightFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,15,15,18)), 0.7)) | Out-Null
    $rightHost.Background = $rightFade

    $rightBtn = New-Object System.Windows.Controls.Border
    $rightBtn.Width = 30; $rightBtn.Height = 30
    $rightBtn.CornerRadius = [System.Windows.CornerRadius]::new(15)
    $rightBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e2a")
    $rightBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $rightBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    $rightBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $rightBtn.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rightBtn.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $rightTxt = New-Object System.Windows.Controls.TextBlock
    $rightTxt.Text = ">"
    $rightTxt.FontSize = 16
    $rightTxt.FontWeight = [System.Windows.FontWeights]::Bold
    $rightTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $rightTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $rightTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $rightTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rightBtn.Child = $rightTxt

    # End-of-row hint. The row wraps back to the start when the right
    # arrow is clicked at the end - without a sign the user cannot tell
    # a wrap from "nothing happened". The arrow itself briefly turns
    # into a loop glyph, glows, and shows a one-word caption. Nothing
    # new appears elsewhere on screen, and the caption is short because
    # the arrow column is only 56px wide.
    # BUTTON AND CAPTION SHARE ONE GRID CELL, they are NOT stacked. In a
    # vertical stack the caption is part of the layout, so the moment it
    # becomes visible the pair is re-centred and the button jumps UP by
    # half the caption height. Here both sit in the same cell, each
    # centred, and the caption is pushed below the circle by a top
    # margin of its own - so the button stays on the exact same pixel
    # whether the caption shows or not.
    $rightStack = New-Object System.Windows.Controls.Grid
    $rightStack.HorizontalAlignment = $rightBtn.HorizontalAlignment
    $rightStack.VerticalAlignment   = $rightBtn.VerticalAlignment
    $rightStack.Margin = $rightBtn.Margin
    $rightBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $rightBtn.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $rightBtn.Margin = [System.Windows.Thickness]::new(0)
    [void]$rightStack.Children.Add($rightBtn)
    $rightCap = New-Object System.Windows.Controls.TextBlock
    $rightCap.Text = "repeat"
    $rightCap.FontSize = 8
    $rightCap.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $rightCap.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $rightCap.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $rightCap.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    # Centred plus 36 top = 18px below the middle, i.e. just under the
    # 30px circle. The Grid grows for it, the button does not move.
    $rightCap.Margin = [System.Windows.Thickness]::new(0, 36, 0, 0)
    $rightCap.IsHitTestVisible = $false
    $rightCap.Visibility = [System.Windows.Visibility]::Collapsed
    [void]$rightStack.Children.Add($rightCap)
    $rightHost.Child = $rightStack

    # Left arrow - hidden until the user has scrolled away from start
    $leftHost = New-Object System.Windows.Controls.Border
    $leftHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $leftHost.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch
    $leftHost.Width = 56
    $leftHost.Cursor = [System.Windows.Input.Cursors]::Hand
    $leftHost.Visibility = [System.Windows.Visibility]::Collapsed
    $leftFade = New-Object System.Windows.Media.LinearGradientBrush
    $leftFade.StartPoint = New-Object System.Windows.Point 0, 0.5
    $leftFade.EndPoint   = New-Object System.Windows.Point 1, 0.5
    $leftFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,15,15,18)), 0.0)) | Out-Null
    $leftFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,15,15,18)), 0.7)) | Out-Null
    $leftHost.Background = $leftFade

    $leftBtn = New-Object System.Windows.Controls.Border
    $leftBtn.Width = 30; $leftBtn.Height = 30
    $leftBtn.CornerRadius = [System.Windows.CornerRadius]::new(15)
    $leftBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e2a")
    $leftBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $leftBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    $leftBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $leftBtn.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $leftBtn.Margin = [System.Windows.Thickness]::new(4, 0, 0, 0)
    $leftTxt = New-Object System.Windows.Controls.TextBlock
    $leftTxt.Text = "<"
    $leftTxt.FontSize = 16
    $leftTxt.FontWeight = [System.Windows.FontWeights]::Bold
    $leftTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $leftTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $leftTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $leftTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $leftBtn.Child = $leftTxt
    $leftHost.Child = $leftBtn

    $scrollCap = $scroll
    $leftHostCap = $leftHost
    # Shows the wrap hint and takes it back after 1.2 s. One timer per
    # row, reused - restarting it while it runs just extends the hint.
    $rightBtnCap = $rightBtn; $rightTxtCap = $rightTxt; $rightCapCap = $rightCap
    $wrapGlyph   = "$([char]0x21BB)"      # clockwise open circle arrow
    $wrapArrow   = $rightTxt.Text
    $wrapTimer = New-Object System.Windows.Threading.DispatcherTimer
    $wrapTimer.Interval = [TimeSpan]::FromMilliseconds(1200)
    $wrapTimer.Add_Tick({
        $wrapTimer.Stop()
        try {
            $rightTxtCap.Text = $wrapArrow
            $rightTxtCap.FontSize = 16
            $rightBtnCap.Effect = $null
            $rightBtnCap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
            $rightCapCap.Visibility = [System.Windows.Visibility]::Collapsed
        } catch { }
    }.GetNewClosure())
    $showWrapHint = {
        try {
            $rightTxtCap.Text = $wrapGlyph
            # The loop glyph reads smaller than ">" at the same size, so
            # it gets its own FontSize. No vertical offset - the glyph
            # stays centred in the circle, the TextBlock does that on
            # its own.
            $rightTxtCap.FontSize = 19
            $rightBtnCap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ff9a3c")
            $g = New-Object System.Windows.Media.Effects.DropShadowEffect
            $g.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#dd6600")
            $g.BlurRadius = 14; $g.ShadowDepth = 0; $g.Opacity = 0.9
            $rightBtnCap.Effect = $g
            $rightCapCap.Visibility = [System.Windows.Visibility]::Visible
            $wrapTimer.Stop(); $wrapTimer.Start()
        } catch { }
    }.GetNewClosure()

    $rightHostCap = $rightHost
    $rightHost.Add_MouseLeftButtonUp({
        $cur = $scrollCap.HorizontalOffset
        $max = $scrollCap.ScrollableWidth
        if ($max -le 0) { return }
        # No duplicate-copy loop: when the user reaches the end,
        # the next right click wraps to the start. This avoids
        # ever showing the same title twice on screen at once
        # (which used to happen with the seamless duplicate copy
        # design when the viewport was wide).
        if ($cur -ge ($max - 1)) {
            $scrollCap.ScrollToHorizontalOffset(0)
            & $showWrapHint
        } else {
            $scrollCap.ScrollToHorizontalOffset([Math]::Min($cur + 360, $max))
        }
    }.GetNewClosure())
    $leftHost.Add_MouseLeftButtonUp({
        $cur = $scrollCap.HorizontalOffset
        $max = $scrollCap.ScrollableWidth
        if ($cur -le 0 -and $max -gt 0) {
            # At the start - wrap to the end so left-arrow on
            # offset 0 jumps to the tail.
            $scrollCap.ScrollToHorizontalOffset($max)
        } else {
            $scrollCap.ScrollToHorizontalOffset([Math]::Max($cur - 360, 0))
        }
    }.GetNewClosure())
    # ScrollChanged fires not only when the user scrolls but also
    # whenever Extent or Viewport size changes - i.e. on window
    # resize and on visibility-driven layout passes. We use that
    # to drive BOTH arrows from actual overflow (Extent vs Viewport)
    # instead of from a static "Count > 4" heuristic, so resizing
    # the window or filtering tiles correctly hides/shows arrows.
    $scroll.Add_ScrollChanged({
        param($s, $e)
        if ($s.HorizontalOffset -gt 5) {
            $leftHostCap.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $leftHostCap.Visibility = [System.Windows.Visibility]::Collapsed
        }
        # Right arrow visible only when there is something to
        # scroll to. No duplicate copy is added any more - the
        # arrow simply wraps to offset 0 when the user reaches
        # the end (see Add_MouseLeftButtonUp on $rightHost).
        $overflowing = ($s.ScrollableWidth -gt 1)
        if ($overflowing) {
            $rightHostCap.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $rightHostCap.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }.GetNewClosure())

    $rowGrid.Children.Add($leftHost)  | Out-Null
    $rowGrid.Children.Add($rightHost) | Out-Null
    $rowStack.Children.Add($rowGrid) | Out-Null

    # Initial visibility: arrows start hidden. The ScrollChanged
    # handler above sets the right arrow visible on the first
    # layout pass once Extent/Viewport widths are measured, and
    # re-evaluates on every window resize and filter change. The
    # left arrow stays hidden until the user actually scrolls.
    $rightHost.Visibility = [System.Windows.Visibility]::Collapsed

    $rowStack.Resources.Add("scrollViewer", $scroll)
    $rowStack.Resources.Add("tilesPanel", $tilesPanel)
    $rowStack.Resources.Add("leftHost", $leftHost)
    $rowStack.Resources.Add("rightHost", $rightHost)

    return $rowStack
}

function global:Build-OvGenreRows {
    $panel = $window.FindName("OvGenreRows")
    if (-not $panel) { return }
    $panel.Children.Clear()
    $global:OvGenreRowsPanel = $panel

    $allGames = @()
    $allGames += $ownGames
    $allGames += $ownGamesGP
    $allGames += $externalGames
    $global:OvAllGames = $allGames

    foreach ($genre in $global:OverviewGenres) {
        $genreGames = @()
        foreach ($g in $allGames) {
            if (Test-OverviewGameInGenre -Game $g -Genre $genre) { $genreGames += $g }
        }
        if ($genreGames.Count -eq 0) { continue }
        $row = New-OvGenreRow -Genre $genre -Games $genreGames
        $panel.Children.Add($row) | Out-Null
    }
}

# Apply Genre + Power filter PLUS the header filter bar's
# Motion/Gamepad/Installed predicate so the Overview is fully
# integrated with the rest of the hub's controls.
function global:Apply-OvFilters {
    if (-not $global:OvGenreRowsPanel) { return }
    $genreKey = if ($global:OvActiveGenre) { $global:OvActiveGenre } else { "ALL" }
    $powerKey = if ($global:OvActivePower) { $global:OvActivePower } else { "ALL" }
    # FREE and NEW are cross-genre filters: keep every genre row, but show
    # only titles from their shared catalog-derived lists inside each.
    $freeOnly = ($genreKey -eq "FREE")
    $newOnly  = ($genreKey -eq "NEW")
    $crossGenreOnly = ($freeOnly -or $newOnly)

    foreach ($row in $global:OvGenreRowsPanel.Children) {
        $rowGenre = $row.Resources.Item("genreKey")
        $genreOk = ($genreKey -eq "ALL") -or $crossGenreOnly -or ($rowGenre -eq $genreKey)
        if (-not $genreOk) {
            $row.Visibility = [System.Windows.Visibility]::Collapsed
            continue
        }

        $tilesPanel = $row.Resources.Item("tilesPanel")
        $visibleCount = 0
        if ($tilesPanel) {
            # Power filter has two interpretations depending on
            # $global:OvPowerMode:
            #   "cumulative" (default) - "Solid" shows LOW + SOLID,
            #     "High" shows LOW + SOLID + HIGH. User sets their
            #     PC's ceiling once and sees everything they can run.
            #   "exact" - "Solid" shows ONLY Solid-tier games. User
            #     wants to browse a specific tier (curated discovery,
            #     hardware-tier comparison shopping, etc).
            # ALL bypasses the filter entirely in both modes.
            $maxPowerIdx = -1
            $exactPowerIdx = -1
            $isExactMode = ($global:OvPowerMode -eq "exact")
            if ($powerKey -ne "ALL") {
                if ($isExactMode) {
                    $exactPowerIdx = Get-OverviewPowerBucketIndex -Key $powerKey
                } else {
                    $maxPowerIdx = Get-OverviewPowerBucketIndex -Key $powerKey
                }
            }
            foreach ($tile in $tilesPanel.Children) {
                $g = $tile.Resources.Item("game")
                if (-not $g) { continue }
                $show = $true
                if ($freeOnly -and ($global:FREE_GAME_TITLES -notcontains $g.Title)) { $show = $false }
                if ($newOnly -and ($global:NEW_GAME_TITLES -notcontains $g.Title)) { $show = $false }
                if ($maxPowerIdx -ge 0) {
                    $bucket = Get-GamePowerBucket -Game $g
                    $bucketIdx = Get-OverviewPowerBucketIndex -Key $bucket
                    if ($bucketIdx -lt 0 -or $bucketIdx -gt $maxPowerIdx) { $show = $false }
                } elseif ($exactPowerIdx -ge 0) {
                    $bucket = Get-GamePowerBucket -Game $g
                    $bucketIdx = Get-OverviewPowerBucketIndex -Key $bucket
                    if ($bucketIdx -ne $exactPowerIdx) { $show = $false }
                }
                # Header filters: Motion / Gamepad / Installed.
                if ($show -and (Get-Command Test-GamePassesFilter -ErrorAction SilentlyContinue)) {
                    if (-not (Test-GamePassesFilter -GameData $g -Query "")) { $show = $false }
                }
                $tile.Visibility = if ($show) {
                    [System.Windows.Visibility]::Visible
                } else {
                    [System.Windows.Visibility]::Collapsed
                }
                if ($show) { $visibleCount++ }
            }
        }

        $row.Visibility = if ($visibleCount -gt 0) {
            [System.Windows.Visibility]::Visible
        } else {
            [System.Windows.Visibility]::Collapsed
        }

        # Right scroll arrow visibility is driven by the actual
        # overflow of the tile strip in the ScrollViewer - not by
        # a static tile count - so resizing the window or filtering
        # tiles correctly hides/shows the arrow. ScrollChanged fires
        # automatically on the next layout pass and refreshes this
        # again. We poke it here to also cover cases where pure
        # visibility changes don't fire ScrollChanged (e.g. when
        # the overall ExtentWidth happens to stay constant).
        $rightHost = $row.Resources.Item("rightHost")
        $leftHost  = $row.Resources.Item("leftHost")
        $sv = $row.Resources.Item("scrollViewer")
        if ($rightHost -and $sv) {
            if ($visibleCount -eq 0) {
                $rightHost.Visibility = [System.Windows.Visibility]::Collapsed
            } else {
                # InvalidateMeasure schedules a layout pass which
                # then fires ScrollChanged with the up-to-date
                # ExtentWidth / ViewportWidth - the handler does
                # the actual visibility math.
                $sv.InvalidateMeasure()
                # Direct fallback in case the layout pass is
                # deferred (e.g. row currently collapsed but about
                # to become visible).
                if ($sv.ExtentWidth -gt ($sv.ViewportWidth + 1)) {
                    $rightHost.Visibility = [System.Windows.Visibility]::Visible
                } else {
                    $rightHost.Visibility = [System.Windows.Visibility]::Collapsed
                }
            }
        }
        # Reset scroll to start when filter changes; left arrow hidden too.
        if ($sv) { $sv.ScrollToHorizontalOffset(0) }
        if ($leftHost) {
            $leftHost.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }
}

$global:OverviewBuilt = $false
# Build the Explore "chrome" - banner + the genre / power / mode filter
# pills. Cheap next to the genre rows, and guarded so it runs exactly once
# whether the first trigger is the background prewarm or the user opening
# Explore (prevents duplicate filter pills across the two paths).
function global:Build-OverviewChrome {
    if ($global:OvChromeBuilt) { return }
    $global:OvActiveGenre = "ALL"
    $global:OvActivePower = "ALL"
    # Power-filter mode: "cumulative" (default - "your PC, show
    # everything I can run") or "exact" (only games of this specific
    # tier). The two modes share the same tier-pill UI; only the
    # interpretation in Apply-OvFilters differs.
    if (-not $global:OvPowerMode) { $global:OvPowerMode = "cumulative" }
    Set-OvBanner
    Build-OvGenreFilter
    Build-OvPowerFilter
    Build-OvPowerModeToggle
    $global:OvChromeBuilt = $true
}

# Synchronous full build - used when the user opens Explore before the
# background prewarm has finished. Chrome (once) + ALL genre rows in one
# go. Build-OvGenreRows clears the panel first, so it cleanly supersedes
# any partial rows the prewarm added; clearing OvPrewarmActive makes the
# prewarm's remaining queued steps bail via the OverviewBuilt guard.
function global:Build-DiscoverOverview {
    if ($global:OverviewBuilt) { return }
    Build-OverviewChrome
    Build-OvGenreRows
    $global:OvPrewarmActive = $false
    $global:OverviewBuilt = $true
}

# Background prewarm: build the Explore rows incrementally so the UI
# thread keeps rendering banner animations while it works. Kicked off at
# Background priority shortly after the window is interactive (see
# Startup.ps1). The unit of work is deliberately tiny - one empty row
# shell or ONE tile per dispatcher cycle - because a whole row at once
# (~10-20 tiles, each with many Add_ handlers) blocked the thread long
# enough to stutter the animation. See Invoke-OverviewPrewarmStep.
function global:Start-OverviewPrewarm {
    if ($global:OverviewBuilt -or $global:OvPrewarmActive) { return }
    Build-OverviewChrome
    $panel = $window.FindName("OvGenreRows")
    if (-not $panel) { return }
    $panel.Children.Clear()
    $global:OvGenreRowsPanel = $panel
    $allGames = @()
    $allGames += $ownGames
    $allGames += $ownGamesGP
    $allGames += $externalGames
    $global:OvAllGames = $allGames
    # Precompute the genre -> games plan once (cheap: tag/substring tests,
    # no WPF elements). Only genres with at least one game get a row.
    $plan = New-Object System.Collections.Generic.List[object]
    foreach ($genre in $global:OverviewGenres) {
        $genreGames = @()
        foreach ($g in $allGames) {
            if (Test-OverviewGameInGenre -Game $g -Genre $genre) { $genreGames += $g }
        }
        if ($genreGames.Count -gt 0) {
            $plan.Add([pscustomobject]@{ Genre = $genre; Games = $genreGames }) | Out-Null
        }
    }
    $global:OvPrewarmPlan     = $plan
    $global:OvPrewarmGi       = 0       # index into $plan (current genre row)
    $global:OvPrewarmTi       = 0       # index into current row's Games (next tile)
    $global:OvPrewarmCurPanel = $null   # current row's tilesPanel
    $global:OvPrewarmActive   = $true
    Invoke-OverviewPrewarmStep
}

# One prewarm step does the SMALLEST unit of work possible - build a
# single empty row shell, or append ONE tile - then re-queues itself at
# Background priority. A tile costs ~30-50ms (its Add_ handlers) and
# Render outranks Background, so an animation frame paints between every
# tile and the banner effects keep moving instead of stuttering in big
# per-row chunks. If the user opens Explore first, Build-DiscoverOverview
# builds everything synchronously and these steps bail via OverviewBuilt.
function global:Invoke-OverviewPrewarmStep {
    if ($global:OverviewBuilt) { $global:OvPrewarmActive = $false; return }
    $plan = $global:OvPrewarmPlan
    if (-not $plan -or $global:OvPrewarmGi -ge $plan.Count) {
        $global:OverviewBuilt = $true
        $global:OvPrewarmActive = $false
        $global:OvPrewarmCurPanel = $null
        if (Get-Command Apply-OvFilters -ErrorAction SilentlyContinue) { try { Apply-OvFilters } catch { } }
        return
    }
    $entry = $plan[$global:OvPrewarmGi]
    try {
        if (-not $global:OvPrewarmCurPanel) {
            # Build the (empty) row shell and add it now, so the header +
            # arrows appear immediately; tiles stream in on later steps.
            $row = New-OvGenreRow -Genre $entry.Genre -Games $entry.Games -Deferred
            $global:OvGenreRowsPanel.Children.Add($row) | Out-Null
            $global:OvPrewarmCurPanel = $row.Resources.Item("tilesPanel")
            $global:OvPrewarmTi = 0
        } else {
            # Append exactly one tile to the current row.
            $games = $entry.Games
            if ($global:OvPrewarmTi -lt $games.Count) {
                $g = $games[$global:OvPrewarmTi]
                $tile = New-OverviewTile -Game $g
                $global:OvPrewarmCurPanel.Children.Add($tile) | Out-Null
                $global:OvPrewarmTi++
            }
            if ($global:OvPrewarmTi -ge $games.Count) {
                # Row finished - advance to the next genre next step.
                $global:OvPrewarmGi++
                $global:OvPrewarmCurPanel = $null
            }
        }
    } catch {
        # On any error skip to the next genre so the prewarm can't wedge.
        $global:OvPrewarmGi++
        $global:OvPrewarmCurPanel = $null
    }
    if ($global:window) {
        $global:window.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{ Invoke-OverviewPrewarmStep }
        ) | Out-Null
    }
}

# Wire up the power-mode toggle pill. Click flips between cumulative
# ("Your PC") and exact ("Exact Tier") and refreshes both the label
# text and the filtered tile visibility. Subtle hover feedback so
# the user sees the pill is interactive.
# Shared neon-glass styling for the small Explore section-header pills
# (the "GENRE" label box and the "PC POWER ..." mode toggle) so the two
# read as a matched pair: orange accent glass + 1.5px border, with
# corner/padding and the inner text/chevron scaled to the Explore S/M/L
# setting from stored XAML base sizes (idempotent - never compounds).
# Handles a Border whose child is a single TextBlock (GENRE) or a
# StackPanel of TextBlocks + a chevron Path (the toggle).
function global:Set-OvHeaderPillStyle {
    param([System.Windows.Controls.Border]$Border)
    if (-not $Border) { return }
    $ac  = [System.Windows.Media.ColorConverter]::ConvertFromString("#ffaa66")
    $mkA = { param($a) [System.Windows.Media.Color]::FromArgb([byte]$a, $ac.R, $ac.G, $ac.B) }
    $mkGlass = {
        param($topA, $botA)
        $gb = New-Object System.Windows.Media.LinearGradientBrush
        $gb.StartPoint = New-Object System.Windows.Point 0, 0
        $gb.EndPoint   = New-Object System.Windows.Point 0, 1
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ((& $mkA $topA), 0.0))) | Out-Null
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ((& $mkA $botA), 1.0))) | Out-Null
        return $gb
    }
    $szKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $cfg = switch ($szKey) {
        "S"     { @{ Corner = 9;  PadX = 10; PadY = 4; Fac = 0.95 } }
        "L"     { @{ Corner = 12; PadX = 15; PadY = 7; Fac = 1.18 } }
        default { @{ Corner = 10; PadX = 12; PadY = 5; Fac = 1.0  } }
    }
    $Border.CornerRadius    = [System.Windows.CornerRadius]::new($cfg.Corner)
    $Border.Padding         = [System.Windows.Thickness]::new($cfg.PadX, $cfg.PadY, $cfg.PadX, $cfg.PadY)
    $Border.BorderThickness = [System.Windows.Thickness]::new(1.5)
    # No fill - just the outline. A filled box made these section
    # headers read like coloured category chips; the bare border keeps
    # them as quiet labels and cuts down on overall colour.
    $Border.Background      = [System.Windows.Media.Brushes]::Transparent
    $Border.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush (& $mkA 120)
    $kids = New-Object System.Collections.ArrayList
    $child = $Border.Child
    if ($child -is [System.Windows.Controls.TextBlock]) {
        [void]$kids.Add($child)
    } elseif ($child -and $child.Children) {
        foreach ($el in $child.Children) { [void]$kids.Add($el) }
    }
    foreach ($el in $kids) {
        if ($el -is [System.Windows.Controls.TextBlock]) {
            if (-not $el.Resources.Contains("baseFs")) { $el.Resources.Add("baseFs", [double]$el.FontSize) }
            $el.FontSize = [double]$el.Resources.Item("baseFs") * $cfg.Fac
        } elseif ($el -is [System.Windows.Shapes.Path]) {
            if (-not $el.Resources.Contains("baseW")) {
                $el.Resources.Add("baseW", [double]$el.Width)
                $el.Resources.Add("baseH", [double]$el.Height)
            }
            $el.Width  = [double]$el.Resources.Item("baseW") * $cfg.Fac
            $el.Height = [double]$el.Resources.Item("baseH") * $cfg.Fac
        }
    }
}

function global:Apply-OvPowerModeToggleStyle {
    $toggle = $global:OvPowerModeToggleBorder
    if (-not $toggle) { $toggle = $window.FindName("OvPowerModeToggle") }
    Set-OvHeaderPillStyle -Border $toggle
}

function global:Build-OvPowerModeToggle {
    $toggle = $window.FindName("OvPowerModeToggle")
    $label  = $window.FindName("OvPowerModeLabel")
    if (-not $toggle -or -not $label) { return }

    $global:OvPowerModeToggleBorder = $toggle
    $global:OvPowerModeLabelTxt     = $label
    Update-OvPowerModeLabel
    Apply-OvPowerModeToggleStyle

    # Click flips the mode and re-applies the filter. Apply-OvFilters
    # reads $global:OvPowerMode together with $global:OvActivePower
    # to decide cumulative-vs-exact semantics. ALL bypasses both
    # modes, so flipping with ALL active is a no-op visually until
    # the user picks a tier.
    $toggle.Add_MouseLeftButtonUp({
        if ($global:OvPowerMode -eq "cumulative") {
            $global:OvPowerMode = "exact"
        } else {
            $global:OvPowerMode = "cumulative"
        }
        Update-OvPowerModeLabel
        Apply-OvFilters
    })

    # Hover: warm up the bg + border to signal interactivity. The
    # active-mode color (orange for cumulative, brighter orange for
    # exact) lives in Update-OvPowerModeLabel and stays put across
    # hover cycles - we only mutate the chrome.
    $toggle.Add_MouseEnter({
        $global:OvPowerModeToggleBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffaa66")
    })
    $toggle.Add_MouseLeave({
        $oc = [System.Windows.Media.ColorConverter]::ConvertFromString("#ffaa66")
        $global:OvPowerModeToggleBorder.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb([byte]120, $oc.R, $oc.G, $oc.B))
    })
}

# Update the mode-name TextBlock to reflect the current OvPowerMode.
# Color stays in the same warm-orange family for both states - this
# is a soft mode indicator, not a state alert. Cumulative gets a
# softer orange, Exact a brighter saturated one so the user can
# tell modes apart at a glance.
function global:Update-OvPowerModeLabel {
    if (-not $global:OvPowerModeLabelTxt) { return }
    if ($global:OvPowerMode -eq "exact") {
        $global:OvPowerModeLabelTxt.Text = "Exact Tier"
        $global:OvPowerModeLabelTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffb380")
    } else {
        $global:OvPowerModeLabelTxt.Text = "Your PC"
        $global:OvPowerModeLabelTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffaa66")
    }
    # The GPU rating only makes sense in cumulative ("Your PC") mode.
    if (Get-Command Update-OvGpuRateVisibility -ErrorAction SilentlyContinue) {
        Update-OvGpuRateVisibility
    }
}

function global:Show-DiscoverOverview {
    param([string]$Origin = "TILES")
    if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
    # Manual navigation invalidates the forward stack (same as
    # the corresponding logic in Show-DiscoverDetail).
    if ($global:NavForwardStack -and -not $global:NavSuppressForwardClear) {
        $global:NavForwardStack.Clear()
    }
    # Track where the user came from so the back button knows
    # where to return to. Origin is "LIST" if the user opened
    # Explore from the VR-mod-list banner, "TILES" otherwise.
    $global:OverviewOrigin = $Origin
    Build-DiscoverOverview
    # Update the banner's back-button label to match origin.
    if ($global:OverviewBackText) {
        $global:OverviewBackText.Text = if ($Origin -eq "LIST") {
            "Back to mod list"
        } else {
            "Back to library"
        }
    }
    $global:discoverDetail.Visibility    = [System.Windows.Visibility]::Collapsed
    $global:discoverTiles.Visibility     = [System.Windows.Visibility]::Collapsed
    $global:discoverOverview.Visibility  = [System.Windows.Visibility]::Visible
    $global:discoverHost.Visibility      = [System.Windows.Visibility]::Visible
    # Safety sweep: finalize any click-pulse glow that may still be in
    # flight (or stuck) on a card from before we navigated away. The
    # cards are built once and reused, so without this a pulse left on a
    # card would persist - and an Effect on the card Border rasterizes
    # its title into the washed-out, ClearType-less look. Forcing the
    # resolve here makes returning to the grid always glow-clean.
    if ($global:cardGameMap -and (Get-Command Resolve-CardClickGlow -ErrorAction SilentlyContinue)) {
        foreach ($c in @($global:cardGameMap.Keys)) { Resolve-CardClickGlow -Card $c }
    }
    if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
    if (Get-Command Apply-ExploreSize -ErrorAction SilentlyContinue) { Apply-ExploreSize $global:ExploreSize }
}

# Back button - returns to whichever view spawned the overview.
function global:Hide-DiscoverOverview {
    $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed
    $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed
    if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
    if ($global:OverviewOrigin -eq "LIST") {
        # Return to the VR-mod list view.
        $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
    } else {
        # Default: return to the portrait library (tiles).
        $global:discoverTiles.Visibility = [System.Windows.Visibility]::Visible
        $global:discoverHost.Visibility  = [System.Windows.Visibility]::Visible
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
        Build-DiscoverTiles
        Refresh-DiscoverStatuses
    }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
}

# Called from list-card click - opens Discover and goes straight
# to the detail view of the clicked game.
function global:Open-DiscoverDetailFromList {
    param($Game)
    $global:DetailOrigin = "LIST"
    Build-DiscoverTiles
    Refresh-DiscoverStatuses
    $global:discoverHost.Visibility = [System.Windows.Visibility]::Visible
    if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
    Update-FilterBarForMode
    Update-DiscoverBtnState
    Show-DiscoverDetail -Game $Game
}

# Toggle handler
$discoverBtn.Add_PreviewMouseLeftButtonDown({
    # A detail/overview sub-view lives INSIDE discoverHost, so the
    # toggle below only collapses the host and leaves the description
    # page (and its filter-pill selection) alive underneath - it stays
    # "stuck". Tear the sub-view down first, exactly like the header
    # Back button does, so Hide-DiscoverDetail -> Restore-FilterPills
    # resets the pills and the detail does not linger.
    if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue) { Hide-DiscoverDetail }
        return
    }
    if ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverOverview -ErrorAction SilentlyContinue) { Hide-DiscoverOverview }
        return
    }
    if ($discoverHost.Visibility -eq [System.Windows.Visibility]::Visible) {
        if ($global:HoverMediaElement) {
            try { $global:HoverMediaElement.Stop()  } catch { }
            try { $global:HoverMediaElement.Close() } catch { }
            $global:HoverMediaElement.Source = $null
            $global:HoverMediaElement = $null
        }
        $discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
        if ($listScroll) { $listScroll.Visibility = [System.Windows.Visibility]::Visible }
        Update-FilterBarForMode
        Update-DiscoverBtnState
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
        if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
        # Remember the view, exactly like S/M/L does, so someone who only
        # uses one of the two lands there again after a restart.
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "startView" -Value "LIST"
        }
    } else {
        Build-DiscoverTiles
        Refresh-DiscoverStatuses
        $global:discoverDetail.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:discoverOverview) {
            $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed
        }
        $global:discoverTiles.Visibility  = [System.Windows.Visibility]::Visible
        $discoverHost.Visibility = [System.Windows.Visibility]::Visible
        if ($listScroll) { $listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
        Update-FilterBarForMode
        Update-DiscoverBtnState
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
        if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
        if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue) { Apply-LibrarySize $global:LibrarySize }
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "startView" -Value "LIBRARY"
        }
    }
})

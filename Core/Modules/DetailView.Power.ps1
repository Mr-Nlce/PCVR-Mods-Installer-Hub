# Helper: build a stylized info section (heading + body bullets/lines)
# Render the PC Power Scale gauge for a game in the Discover detail
# view. Returns a Border element matching the "Bar gauge" mockup:
# heading row + 6-segment bar with marker(s) + tier labels + GPU/CPU
# sub-panel. A single-tier game gets one marker, a range game gets
# a span between two markers. The active tier(s) are tinted with a
# blue accent ramp for visual continuity with the rest of the UI.
function global:New-PowerScaleBlock {
    param($Game)
    $tier = Get-PowerTier -Game $Game

    # Container card
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $card.Padding = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)

    $stack = New-Object System.Windows.Controls.StackPanel
    $card.Child = $stack

    # ---- Heading row ----
    $headRow = New-Object System.Windows.Controls.DockPanel
    $headRow.LastChildFill = $false
    $headRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)

    $headLeft = New-Object System.Windows.Controls.TextBlock
    $headLeft.Text = "PC Power"
    $headLeft.FontSize = 14
    $headLeft.FontWeight = [System.Windows.FontWeights]::SemiBold
    $headLeft.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
    $headLeft.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    [System.Windows.Controls.DockPanel]::SetDock($headLeft, [System.Windows.Controls.Dock]::Left)
    $headRow.Children.Add($headLeft) | Out-Null

    $headRight = New-Object System.Windows.Controls.TextBlock
    if ($tier.IsRange) {
        $headRight.Text = "$($global:PowerTiers[$tier.StartIdx].Label) -> $($global:PowerTiers[$tier.EndIdx].Label)"
    } else {
        $headRight.Text = $global:PowerTiers[$tier.StartIdx].Label
    }
    $headRight.FontSize = 13
    $headRight.FontWeight = [System.Windows.FontWeights]::SemiBold
    $headRight.Foreground = [System.Windows.Media.Brushes]::White
    $headRight.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    [System.Windows.Controls.DockPanel]::SetDock($headRight, [System.Windows.Controls.Dock]::Right)
    $headRow.Children.Add($headRight) | Out-Null
    $stack.Children.Add($headRow) | Out-Null

    # ---- 6-segment bar with marker(s) ----
    # Shared, mutable state for the bar. MUST be a hashtable, not a
    # $script: variable: every .GetNewClosure() below gets its OWN module
    # scope, so $script:x written in one closure is invisible to another.
    # A hashtable is captured by reference, so both closures see the same
    # object. YouIdx = -1 means "not resolved yet" -> marker stays hidden.
    $barState = @{ YouIdx = -1 }
    # Use a Grid that overlays the segment row + the marker triangle(s).
    $barHost = New-Object System.Windows.Controls.Grid
    $barHost.Height = 18
    $barHost.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

    # Segments: a 6-column UniformGrid for equal widths
    $segGrid = New-Object System.Windows.Controls.Primitives.UniformGrid
    $segGrid.Rows = 1
    $segGrid.Columns = 6
    $segGrid.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $segGrid.Height = 8

    # Active blue ramp (lightest -> darkest as tier index goes up)
    # so the gauge has a natural "fuller = stronger" gradient feel.
    # Inactive segments use a dark slate.
    $activeColors = @(
        "#2a3a48",  # 0 LOW (dim slate-blue)
        "#3a5a78",  # 1 BASIC
        "#4a7aa0",  # 2 SOLID
        "#6a9ad8",  # 3 STRONG
        "#85b3e8",  # 4 HIGH
        "#a8c8f5"   # 5 EXTREME
    )
    $inactiveColor = "#2a2a32"

    # Active segments collected so we can animate them on hover
    # (wave-cascade effect, see card.Add_MouseEnter below).
    $activeSegments = New-Object System.Collections.Generic.List[object]
    # Every segment, in tier order - the GPU comparison recolours the
    # ones beyond the requirement and outlines the required one.
    $allSegs = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt 6; $i++) {
        $seg = New-Object System.Windows.Controls.Border
        $seg.Height = 8
        $isActive = ($i -ge $tier.StartIdx) -and ($i -le $tier.EndIdx)
        # Also fill segments BELOW the start to give a "fill up to here"
        # gauge feel. Without this the bar would have isolated colored
        # cells which reads as broken.
        $isFilled = ($i -le $tier.EndIdx)
        $col = if ($isFilled) { $activeColors[$i] } else { $inactiveColor }
        $seg.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($col)
        # Side margins to make the segments visually distinct (the
        # mockup used 2px gaps via flex - we get the same with margin)
        $seg.Margin = [System.Windows.Thickness]::new(1, 0, 1, 0)
        # Round the very first/last so the bar reads as a pill
        if ($i -eq 0) {
            $seg.CornerRadius = [System.Windows.CornerRadius]::new(2, 0, 0, 2)
            $seg.Margin = [System.Windows.Thickness]::new(0, 0, 1, 0)
        } elseif ($i -eq 5) {
            $seg.CornerRadius = [System.Windows.CornerRadius]::new(0, 2, 2, 0)
            $seg.Margin = [System.Windows.Thickness]::new(1, 0, 0, 0)
        }
        # Each segment scales from its bottom edge during the wave
        # so the "rise" reads as the bar bulging upward, not floating.
        $segScale = New-Object System.Windows.Media.ScaleTransform 1, 1
        $seg.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 1.0
        $seg.RenderTransform = $segScale
        if ($isFilled) { $activeSegments.Add($seg) | Out-Null }
        $allSegs.Add($seg) | Out-Null
        $segGrid.Children.Add($seg) | Out-Null
    }
    $barHost.Children.Add($segGrid) | Out-Null

    # Marker(s): we draw a downward-pointing triangle ABOVE the bar
    # that "points to" the active segment. For a range we draw two
    # markers at the bounds. Done with a Path geometry so we can
    # position-precisely as a fraction of the bar width.
    function New-MarkerTriangle {
        $p = New-Object System.Windows.Shapes.Path
        $p.Fill = [System.Windows.Media.Brushes]::White
        $p.Data = [System.Windows.Media.Geometry]::Parse("M 0,0 L 12,0 L 6,8 Z")
        $p.Width = 12
        $p.Height = 8
        $p.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $p.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        return $p
    }

    # Position the marker once layout is known and re-position on
    # resize. We always render exactly one marker - for range tiers
    # (e.g. "SOLID -> STRONG") the marker sits at the midpoint
    # between the two tier centers, which reads as "somewhere in
    # this band" without cluttering the bar with two arrows.
    $markerCanvas = New-Object System.Windows.Controls.Canvas
    # Tall enough to stack the YOU marker (+ its label) ABOVE the
    # recommendation triangle, so the two never overlap even when the
    # user's GPU tier equals the recommended tier. Bottom band (y>=18)
    # holds the rec triangle at the bar; the YOU marker sits in the
    # upper band. Negative-margin pull keeps the bar spacing unchanged.
    $markerCanvas.Height = 8
    $markerCanvas.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $startIdx = $tier.StartIdx
    $endIdx   = $tier.EndIdx

    # Requirement marker: white triangle ABOVE the bar, pointing down at
    # the required tier. This is the ONLY marker until the user runs the
    # GPU comparison - then it steps aside and the YOU marker takes this
    # exact lane (never two arrows at once). The requirement is then
    # carried by the outlined segment + the RECOMMENDED caption instead.
    $m1 = New-MarkerTriangle
    # TranslateTransform lets the hover animation lift the marker
    # upward (it "jumps" toward the bar) and pulse there.
    $markerLift = New-Object System.Windows.Media.TranslateTransform 0, 0
    $m1.RenderTransform = $markerLift
    $markerCanvas.Children.Add($m1) | Out-Null

    # YOU marker: same lane, hidden until the comparison runs. Its label
    # rides in the gap above the bar via a negative Canvas.Top (the
    # Canvas does not clip), so it costs no extra height.
    # IMPORTANT: created BEFORE the SizeChanged closure below, otherwise
    # GetNewClosure() would capture $null and the marker would stay stuck
    # at x=0 (the left edge of the scale).
    $youMark = New-Object System.Windows.Shapes.Path
    $youMark.Data = [System.Windows.Media.Geometry]::Parse("M 0,0 L 12,0 L 6,8 Z")
    $youMark.Width = 12; $youMark.Height = 8
    $youMark.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fd08a")
    $youMark.Visibility = [System.Windows.Visibility]::Collapsed
    $youMarkLift = New-Object System.Windows.Media.TranslateTransform 0, 0
    $youMark.RenderTransform = $youMarkLift
    $markerCanvas.Children.Add($youMark) | Out-Null

    $youLabel = New-Object System.Windows.Controls.TextBlock
    $youLabel.Text = "YOU"
    $youLabel.FontSize = 8
    $youLabel.FontWeight = [System.Windows.FontWeights]::Bold
    $youLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fd08a")
    $youLabel.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $youLabel.Visibility = [System.Windows.Visibility]::Collapsed
    # Shares the marker's transform so label + arrow bob together.
    $youLabel.RenderTransform = $youMarkLift
    [System.Windows.Controls.Canvas]::SetTop($youLabel, -11)
    $markerCanvas.Children.Add($youLabel) | Out-Null

    $segGrid.Add_SizeChanged({
        param($s, $e)
        $w = $e.NewSize.Width
        if ($w -le 0) { return }
        $segW = $w / 6.0
        $startCenter = $startIdx * $segW + ($segW / 2.0)
        $endCenter   = $endIdx   * $segW + ($segW / 2.0)
        # Midpoint of the range (== startCenter for single-tier games)
        $markerX = ($startCenter + $endCenter) / 2.0
        [System.Windows.Controls.Canvas]::SetLeft($m1, $markerX - 6)
        # Keep the YOU marker aligned once a tier is resolved. This is
        # also the path that positions it when "Always compare" runs
        # during page construction (ActualWidth is still 0 back then).
        if ($barState.YouIdx -ge 0) {
            $youX = $barState.YouIdx * $segW + ($segW / 2.0)
            [System.Windows.Controls.Canvas]::SetLeft($youMark, $youX - 6)
            [System.Windows.Controls.Canvas]::SetLeft($youLabel, $youX - 9)
        }
    }.GetNewClosure())

    $barHost.Children.Add($markerCanvas) | Out-Null
    $stack.Children.Add($barHost) | Out-Null

    # ---- Tier labels under the bar (6 evenly spaced) ----
    $labelGrid = New-Object System.Windows.Controls.Primitives.UniformGrid
    $labelGrid.Rows = 1
    $labelGrid.Columns = 6
    $labelGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 2)
    for ($i = 0; $i -lt 6; $i++) {
        $lbl = New-Object System.Windows.Controls.TextBlock
        $shortLabel = switch ($i) {
            0 { "LOW" }
            1 { "BASIC" }
            2 { "SOLID" }
            3 { "STRONG" }
            4 { "HIGH" }
            5 { "EXTREME" }
        }
        $lbl.Text = $shortLabel
        $lbl.FontSize = 10
        $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $lbl.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $isActive = ($i -ge $tier.StartIdx) -and ($i -le $tier.EndIdx)
        if ($isActive) {
            $lbl.Foreground = [System.Windows.Media.Brushes]::White
            $lbl.FontWeight = [System.Windows.FontWeights]::SemiBold
        } else {
            $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        }
        $labelGrid.Children.Add($lbl) | Out-Null
    }
    $stack.Children.Add($labelGrid) | Out-Null

    # ---- "RECOMMENDED" caption under the recommended tier label ----
    # Same 6-column grid so it lines up exactly with the tier labels.
    # Always shown: before the comparison it reinforces the white arrow,
    # after it (when the arrow becomes YOU) it carries the recommendation.
    $capGrid = New-Object System.Windows.Controls.Primitives.UniformGrid
    $capGrid.Rows = 1
    $capGrid.Columns = 6
    $capGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
    for ($i = 0; $i -lt 6; $i++) {
        $cap = New-Object System.Windows.Controls.TextBlock
        $cap.Text = if ($i -eq $tier.EndIdx) { "RECOMMENDED" } else { "" }
        $cap.FontSize = 8
        $cap.FontWeight = [System.Windows.FontWeights]::Bold
        $cap.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cfe0f7")
        $cap.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $cap.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $capGrid.Children.Add($cap) | Out-Null
    }
    $stack.Children.Add($capGrid) | Out-Null

    # ---- GPU/CPU sub-panel ----
    # Show specs for the active tier (or the high end of a range).
    $specTier = $global:PowerTiers[$tier.EndIdx]

    # Compact one-line recommendation (no boxed panel): "Recommended:
    # <GPU> - <CPU>" plus a small (i) that reveals the disclaimer only
    # on hover over the scale zone, until the user acknowledges it.
    # DockPanel (not StackPanel): after the comparison runs, the
    # "Always compare" pill is re-parented here and docked to the far
    # right of this same line, which lets the whole compare row above
    # the result box disappear.
    $specLine = New-Object System.Windows.Controls.DockPanel
    $specLine.LastChildFill = $false
    $specLine.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)

    $specTb = New-Object System.Windows.Controls.TextBlock
    $specTb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $specTb.FontSize = 12
    $specTb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rl = New-Object System.Windows.Documents.Run "Recommended  "
    $rl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
    $rg = New-Object System.Windows.Documents.Run $specTier.Gpu
    $rg.Foreground = [System.Windows.Media.Brushes]::White
    $rg.FontWeight = [System.Windows.FontWeights]::SemiBold
    $rsep = New-Object System.Windows.Documents.Run "   -   "
    $rsep.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#444450")
    $rc = New-Object System.Windows.Documents.Run $specTier.Cpu
    $rc.Foreground = [System.Windows.Media.Brushes]::White
    $rc.FontWeight = [System.Windows.FontWeights]::SemiBold
    $specTb.Inlines.Add($rl)
    $specTb.Inlines.Add($rg)
    $specTb.Inlines.Add($rsep)
    $specTb.Inlines.Add($rc)
    [System.Windows.Controls.DockPanel]::SetDock($specTb, [System.Windows.Controls.Dock]::Left)
    $specLine.Children.Add($specTb) | Out-Null

    # (i) info marker - dims/greens once acknowledged; clicking it after
    # acknowledgement re-shows the disclaimer strip.
    $infoDot = New-Object System.Windows.Controls.Border
    $infoDot.Width = 16; $infoDot.Height = 16
    $infoDot.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $infoDot.BorderThickness = [System.Windows.Thickness]::new(1)
    $infoDot.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
    $infoDot.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    $infoDot.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $infoDot.Cursor = [System.Windows.Input.Cursors]::Hand
    $infoDotTxt = New-Object System.Windows.Controls.TextBlock
    $infoDotTxt.Text = "i"
    $infoDotTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $infoDotTxt.FontSize = 10
    $infoDotTxt.FontStyle = [System.Windows.FontStyles]::Italic
    $infoDotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
    $infoDotTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $infoDotTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $infoDot.Child = $infoDotTxt
    [System.Windows.Controls.DockPanel]::SetDock($infoDot, [System.Windows.Controls.Dock]::Left)
    $specLine.Children.Add($infoDot) | Out-Null
    $stack.Children.Add($specLine) | Out-Null

    # Disclaimer strip: hidden by default; slides in when the cursor is
    # over the scale zone, ONLY until acknowledged. Acknowledged when the
    # user ticks the box OR clicks Compare / Always. State is global,
    # persisted in the durable Hub state (GpuDisclaimerAck), so once seen it
    # stays quiet on every game page.
    $discAcked = [bool](Get-HubSetting -Key "GpuDisclaimerAck" -Default $false)

    $discBox = New-Object System.Windows.Controls.Border
    $discBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161620")
    $discBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $discBox.BorderThickness = [System.Windows.Thickness]::new(1)
    $discBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $discBox.Padding = [System.Windows.Thickness]::new(11, 9, 11, 9)
    $discBox.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $discBox.Visibility = [System.Windows.Visibility]::Collapsed
    $discRow = New-Object System.Windows.Controls.StackPanel
    $discRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $discBox.Child = $discRow

    # Tick box
    $chk = New-Object System.Windows.Controls.Border
    $chk.Width = 16; $chk.Height = 16
    $chk.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $chk.BorderThickness = [System.Windows.Thickness]::new(1)
    $chk.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
    $chk.Background = [System.Windows.Media.Brushes]::Transparent
    $chk.Cursor = [System.Windows.Input.Cursors]::Hand
    $chk.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $chk.Margin = [System.Windows.Thickness]::new(0, 1, 9, 0)
    $chkMark = New-Object System.Windows.Shapes.Path
    $chkMark.Data = [System.Windows.Media.Geometry]::Parse("M 1,5 L 4,8 L 9,2")
    $chkMark.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fd08a")
    $chkMark.StrokeThickness = 2
    $chkMark.Visibility = [System.Windows.Visibility]::Collapsed
    $chk.Child = $chkMark
    $discRow.Children.Add($chk) | Out-Null

    $discTxt = New-Object System.Windows.Controls.TextBlock
    $discTxt.Text = "Unlike flat games, VR mods are not tested across many systems by a studio, and VR performance depends on many other factors too - treat the scale as a rough indicator, though GPU strength is often one of the most important factors.  (tick to dismiss)"
    $discTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $discTxt.FontSize = 11
    $discTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a93a3")
    $discTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $discTxt.LineHeight = 16
    $discTxt.MaxWidth = 620
    $discRow.Children.Add($discTxt) | Out-Null
    $stack.Children.Add($discBox) | Out-Null

    # If already acknowledged from a previous session, green the (i).
    if ($discAcked) {
        $infoDot.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a4a3f")
        $infoDotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a6a55")
    }

    # Shared ack state. The disclaimer is shown exactly ONCE: on the
    # first click of "Compare my GPU" (or "Always"). From then on it
    # only lives behind the (i), which turns a dim green. Ticking the
    # checkbox closes it. Persisted globally in the durable Hub state, so
    # once it has been shown it stays quiet on every game page.
    $discState = @{ Acked = $discAcked }

    $showDiscOnce = {
        if ($discState.Acked) { return }
        $discState.Acked = $true
        $discBox.Visibility = [System.Windows.Visibility]::Visible
        $infoDot.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a4a3f")
        $infoDotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a6a55")
        try { Set-HubSetting -Key "GpuDisclaimerAck" -Value $true } catch {}
    }.GetNewClosure()

    # Tick the box -> just close the strip (it is already marked shown).
    $chk.Add_MouseLeftButtonUp({
        $chkMark.Visibility = [System.Windows.Visibility]::Visible
        $chk.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a5a44")
        $chk.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#274a37")
        $discBox.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    # The (i) shows/hides the note on demand, any time.
    $infoDot.Add_MouseLeftButtonUp({
        if ($discBox.Visibility -eq [System.Windows.Visibility]::Visible) {
            $discBox.Visibility = [System.Windows.Visibility]::Collapsed
        } else {
            $discBox.Visibility = [System.Windows.Visibility]::Visible
        }
    }.GetNewClosure())

    # ---------------------------------------------------------------
    # GPU comparison (opt-in)
    # ---------------------------------------------------------------
    # The click on "Compare my GPU" IS the consent to read the GPU
    # name (local WMI, once per session, no network). After the click
    # this whole row folds away: the button is done, and "Always
    # compare" moves to the far right of the Recommended line above,
    # so the result box sits directly under it. "Always compare"
    # persists via the durable Hub state
    # and auto-renders the result on every detail page.
    $recIdx   = $tier.EndIdx
    $recTierL = $global:PowerTiers[$recIdx].Label
    $recGpuS  = $global:PowerTiers[$recIdx].Gpu

    $cmpArea = New-Object System.Windows.Controls.StackPanel
    $cmpArea.Margin = [System.Windows.Thickness]::new(0, 8, 0, 0)

    # Both buttons live on the Recommended line from the start - no row
    # of their own. Outline-only styling (transparent fill, light border,
    # yellow on hover) matching the Explore rating buttons.
    $mkGhostBtn = {
        param([string]$Label, [double]$Font, [bool]$Primary)
        $b = New-Object System.Windows.Controls.Border
        $b.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $b.BorderThickness = [System.Windows.Thickness]::new(1)
        $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a6a90")
        $b.Background  = [System.Windows.Media.Brushes]::Transparent
        $b.Padding = [System.Windows.Thickness]::new(10, 4, 10, 4)
        $b.Cursor = [System.Windows.Input.Cursors]::Hand
        $b.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        # Resting border, so MouseLeave restores the right colour even
        # after "Always" switched this button to its active look.
        $b.Resources["restBorder"] = "#4a6a90"
        $t = New-Object System.Windows.Controls.TextBlock
        $t.Text = $Label
        $t.FontSize = $Font
        $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        if ($Primary) {
            $t.FontWeight = [System.Windows.FontWeights]::SemiBold
            $t.Foreground = [System.Windows.Media.Brushes]::White
        } else {
            $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a93a3")
        }
        $b.Child = $t
        $b.Add_MouseEnter({
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ddcc44")
        })
        $b.Add_MouseLeave({
            $rest = if ($this.Resources.Contains("restBorder")) { $this.Resources.Item("restBorder") } else { "#4a6a90" }
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($rest)
        })
        return @{ Border = $b; Text = $t }
    }

    $alwaysPair = & $mkGhostBtn "Always compare" 11 $false
    $alwaysBox  = $alwaysPair.Border
    $alwaysTxt  = $alwaysPair.Text

    $cmpPair = & $mkGhostBtn "Compare my GPU" 11.5 $true
    $cmpBtn  = $cmpPair.Border
    $cmpTxt  = $cmpPair.Text
    $cmpBtn.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)

    # Dock order matters: the first Right-docked child ends up furthest
    # right, so "Always compare" sits at the very end of the line and
    # "Compare my GPU" directly to its left.
    [System.Windows.Controls.DockPanel]::SetDock($alwaysBox, [System.Windows.Controls.Dock]::Right)
    $specLine.Children.Add($alwaysBox) | Out-Null
    [System.Windows.Controls.DockPanel]::SetDock($cmpBtn, [System.Windows.Controls.Dock]::Right)
    $specLine.Children.Add($cmpBtn) | Out-Null

    # A short, always-present one-liner (the full disclaimer lives in the
    # hover strip above). Kept tiny so it never dominates the panel.
    $consent = New-Object System.Windows.Controls.TextBlock
    $consent.Text = "Reads your installed GPU name once, locally."
    $consent.FontSize = 10.5
    $consent.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555562")
    $consent.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $consent.TextWrapping = [System.Windows.TextWrapping]::Wrap
    # Right-aligned: it belongs to the two buttons at the end of the
    # Recommended line above, so it reads as their footnote instead of
    # a stray line under the specs.
    $consent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $consent.TextAlignment = [System.Windows.TextAlignment]::Right
    $consent.Margin = [System.Windows.Thickness]::new(0, 5, 0, 0)
    $cmpArea.Children.Add($consent) | Out-Null

    $resBox = New-Object System.Windows.Controls.Border
    $resBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $resBox.BorderThickness = [System.Windows.Thickness]::new(1)
    $resBox.Padding = [System.Windows.Thickness]::new(12, 10, 12, 10)
    $resBox.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $resBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e0e14")
    $resBox.Visibility = [System.Windows.Visibility]::Collapsed
    $resStack = New-Object System.Windows.Controls.StackPanel
    $resBox.Child = $resStack

    $verdictRow = New-Object System.Windows.Controls.StackPanel
    $verdictRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $badgeBox = New-Object System.Windows.Controls.Border
    $badgeBox.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $badgeBox.Padding = [System.Windows.Thickness]::new(7, 2, 7, 2)
    $badgeTxt = New-Object System.Windows.Controls.TextBlock
    $badgeTxt.FontSize = 10
    $badgeTxt.FontWeight = [System.Windows.FontWeights]::Bold
    $badgeTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $badgeBox.Child = $badgeTxt
    $verdictRow.Children.Add($badgeBox) | Out-Null
    $vHeadTxt = New-Object System.Windows.Controls.TextBlock
    $vHeadTxt.FontSize = 12.5
    $vHeadTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $vHeadTxt.Foreground = [System.Windows.Media.Brushes]::White
    $vHeadTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $vHeadTxt.Margin = [System.Windows.Thickness]::new(9, 1, 0, 0)
    $verdictRow.Children.Add($vHeadTxt) | Out-Null
    $resStack.Children.Add($verdictRow) | Out-Null

    # (No second scale here: the result lights up the "YOU" marker on
    # the original tier bar above. The panel keeps only badge + text.)

    $vBodyTxt = New-Object System.Windows.Controls.TextBlock
    $vBodyTxt.FontSize = 11.5
    $vBodyTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9aa3b3")
    $vBodyTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $vBodyTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $vBodyTxt.LineHeight = 17
    $resStack.Children.Add($vBodyTxt) | Out-Null

    $cmpArea.Children.Add($resBox) | Out-Null
    $stack.Children.Add($cmpArea) | Out-Null

    # Shared state bag for the closures below.
    $cu = @{
        Btn = $cmpBtn; BtnTxt = $cmpTxt; Consent = $consent
        ResBox = $resBox; BadgeBox = $badgeBox; BadgeTxt = $badgeTxt
        HeadTxt = $vHeadTxt; BodyTxt = $vBodyTxt
        # Markers on the ORIGINAL tier bar (only one is ever visible).
        RecMark = $m1; YouMark = $youMark; YouLabel = $youLabel; YouMarkLift = $youMarkLift
        SegGrid = $segGrid; AllSegs = $allSegs; BarState = $barState
        AlwaysBox = $alwaysBox; AlwaysTxt = $alwaysTxt
        SpecLine = $specLine
        RecIdx = $recIdx; RecTier = $recTierL; RecGpu = $recGpuS
        YouIdx = -1; Peak = 1.5
        Done = $false
    }

    $paintAlways = {
        param($cu2, [bool]$on)
        $bc = [System.Windows.Media.BrushConverter]::new()
        # Outline-only in both states: border + label colour carry on/off.
        # restBorder is updated too so a later MouseLeave restores it.
        $cu2.AlwaysBox.Background = [System.Windows.Media.Brushes]::Transparent
        if ($on) {
            $cu2.AlwaysBox.Resources["restBorder"] = "#6a9ad8"
            $cu2.AlwaysBox.BorderBrush = $bc.ConvertFromString("#6a9ad8")
            $cu2.AlwaysTxt.Foreground  = $bc.ConvertFromString("#6a9ad8")
            $cu2.AlwaysTxt.Text = "Always compare: on"
        } else {
            $cu2.AlwaysBox.Resources["restBorder"] = "#4a6a90"
            $cu2.AlwaysBox.BorderBrush = $bc.ConvertFromString("#4a6a90")
            $cu2.AlwaysTxt.Foreground  = $bc.ConvertFromString("#8a93a3")
            $cu2.AlwaysTxt.Text = "Always compare"
        }
    }

    $runCompare = {
        param($cu2)
        if ($cu2.Done) { return }
        $cu2.Done = $true
        $bc = [System.Windows.Media.BrushConverter]::new()

        # The button has done its job - hide it. "Always compare" simply
        # stays where it already is (end of the Recommended line), so
        # nothing needs re-parenting and the result slides up beneath.
        $cu2.Btn.Visibility = [System.Windows.Visibility]::Collapsed
        $cu2.Consent.Visibility = [System.Windows.Visibility]::Collapsed
        $cu2.ResBox.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)

        $gpuName = Get-InstalledGpuName
        $youIdx  = Get-GpuTierIndex -Name $gpuName
        $cu2.YouIdx = $youIdx
        $recIdx2 = $cu2.RecIdx
        $gname = if ($gpuName) { $gpuName } else { "(no GPU found)" }

        $kind = if ($youIdx -eq -1) { "unknown" }
                elseif ($youIdx -eq -2) { "under" }
                elseif ($youIdx -ge $recIdx2) { "good" }
                elseif ($youIdx -eq ($recIdx2 - 1)) { "warn" }
                else { "bad" }

        $fill = "#5fd08a"; $bBg = "#274a37"; $bFg = "#5fd08a"; $edge = "#2f5a42"
        switch ($kind) {
            "good"    { $cu2.Peak = 1.9 }
            "warn"    { $fill = "#e8b45f"; $bBg = "#4a3d27"; $bFg = "#e8b45f"; $edge = "#5a4a2f"; $cu2.Peak = 1.5 }
            "bad"     { $fill = "#e88a6a"; $bBg = "#4a2f27"; $bFg = "#e88a6a"; $edge = "#5a3a2f"; $cu2.Peak = 1.25 }
            "under"   { $fill = "#e88a6a"; $bBg = "#4a2f27"; $bFg = "#e88a6a"; $edge = "#5a3a2f"; $cu2.Peak = 1.25 }
            "unknown" { $bBg = "#33333d"; $bFg = "#8a93a3"; $edge = "#3a3a44" }
        }
        $cu2.ResBox.BorderBrush  = $bc.ConvertFromString($edge)
        $cu2.BadgeBox.Background = $bc.ConvertFromString($bBg)
        $cu2.BadgeTxt.Foreground = $bc.ConvertFromString($bFg)

        if ($kind -eq "unknown") {
            $cu2.BadgeTxt.Text = "NO MATCH"
            $cu2.HeadTxt.Text  = "Couldn't place your GPU"
            $cu2.BodyTxt.Text  = "Your GPU '$gname' is not in the tier list, so it can't be compared. Use the $($cu2.RecTier) guide (around a $($cu2.RecGpu)) as the reference."
            # No marker on the bar - we don't know where it belongs.
            $cu2.YouMark.Visibility = [System.Windows.Visibility]::Collapsed
            $cu2.ResBox.Visibility = [System.Windows.Visibility]::Visible
            return
        }

        $youTier = if ($youIdx -ge 0) { $global:PowerTiers[$youIdx].Label } else { "" }
        if ($kind -eq "good") {
            $cu2.BadgeTxt.Text = "FITS"
            $cu2.HeadTxt.Text  = if ($youIdx -gt $recIdx2) { "Above the recommended tier" } else { "Meets the recommended tier" }
            $cu2.BodyTxt.Text  = "Your '$gname' lands in $youTier, at or above this game's $($cu2.RecTier) guide (~$($cu2.RecGpu)). It should run well."
        } elseif ($kind -eq "warn") {
            $cu2.BadgeTxt.Text = "CLOSE"
            $cu2.HeadTxt.Text  = "One tier below the guide"
            $cu2.BodyTxt.Text  = "Your '$gname' lands in $youTier, one step under this game's $($cu2.RecTier) guide (~$($cu2.RecGpu)). Likely fine with a few settings reduced."
        } elseif ($kind -eq "bad") {
            $cu2.BadgeTxt.Text = "STRETCH"
            $cu2.HeadTxt.Text  = "Below the recommended tier"
            $cu2.BodyTxt.Text  = "Your '$gname' lands in $youTier, below this game's $($cu2.RecTier) guide (~$($cu2.RecGpu)). May run with reduced settings - expect compromises."
        } else {
            $cu2.BadgeTxt.Text = "STRETCH"
            $cu2.HeadTxt.Text  = "Below the tier scale"
            $cu2.BodyTxt.Text  = "Your '$gname' sits below the Hub's LOW tier (~GTX 1070). Most PCVR mods will struggle on it."
        }

        # Light up the YOU marker on the ORIGINAL tier bar. "under"
        # (below the scale) pins it at the far-left LOW segment.
        $markIdx = if ($youIdx -ge 0) { $youIdx } else { 0 }
        $cu2.BarState.YouIdx = $markIdx
        # ONE arrow at a time: the white requirement marker steps aside,
        # the YOU marker takes its lane. The requirement is now carried
        # by the outlined segment + the RECOMMENDED caption underneath.
        $cu2.RecMark.Visibility = [System.Windows.Visibility]::Collapsed
        $cu2.YouMark.Fill = $bc.ConvertFromString($fill)
        $cu2.YouLabel.Foreground = $bc.ConvertFromString($fill)
        $cu2.YouMark.Visibility = [System.Windows.Visibility]::Visible
        $cu2.YouLabel.Visibility = [System.Windows.Visibility]::Visible

        # Outline the required tier segment so the bar itself shows the
        # bar the user has to clear.
        $reqSeg = $cu2.AllSegs[$cu2.RecIdx]
        $reqSeg.BorderThickness = [System.Windows.Thickness]::new(1)
        $reqSeg.BorderBrush = $bc.ConvertFromString("#cfe0f7")
        $rg = New-Object System.Windows.Media.Effects.DropShadowEffect
        $rg.Color = [System.Windows.Media.Color]::FromRgb(207, 224, 247)
        $rg.BlurRadius = 7
        $rg.ShadowDepth = 0
        $rg.Opacity = 0.45
        $reqSeg.Effect = $rg

        # Headroom: everything the user has ABOVE the requirement gets
        # appended in the verdict colour (same colour as arrow + label),
        # so the arrow always lands on a filled, meaningful segment.
        if ($markIdx -gt $cu2.RecIdx) {
            for ($k = $cu2.RecIdx + 1; $k -le $markIdx; $k++) {
                $cu2.AllSegs[$k].Background = $bc.ConvertFromString($fill)
            }
        }

        # Position using the bar's current width (SizeChanged keeps it
        # aligned on later resizes).
        $bw = $cu2.SegGrid.ActualWidth
        if ($bw -gt 0) {
            $segW = $bw / 6.0
            $youX = $markIdx * $segW + ($segW / 2.0)
            [System.Windows.Controls.Canvas]::SetLeft($cu2.YouMark, $youX - 6)
            [System.Windows.Controls.Canvas]::SetLeft($cu2.YouLabel, $youX - 9)
        }
        $cu2.ResBox.Visibility = [System.Windows.Visibility]::Visible
    }

    # (Hover is handled by the ghost-button factory above: light border
    # at rest, yellow while hovered. No extra handlers here - a second
    # MouseEnter would run after that one and undo the yellow.)

    # Click = consent + compare. The FIRST click also surfaces the
    # disclaimer strip once (never again after that).
    $cmpBtn.Add_MouseLeftButtonUp({ & $showDiscOnce; & $runCompare $cu }.GetNewClosure())

    # Always toggle: persist and run immediately when switched on.
    $alwaysBox.Add_MouseLeftButtonUp({
        & $showDiscOnce
        $on = -not [bool](Get-HubSetting -Key "GpuCompareAlways" -Default $false)
        Set-HubSetting -Key "GpuCompareAlways" -Value $on
        & $paintAlways $cu $on
        if ($on) { & $runCompare $cu }
    }.GetNewClosure())

    # Initial paint of the Always toggle; auto-run if persisted on.
    $alwaysOn0 = [bool](Get-HubSetting -Key "GpuCompareAlways" -Default $false)
    & $paintAlways $cu $alwaysOn0
    if ($alwaysOn0) { & $runCompare $cu }

    # ---------------------------------------------------------------
    # Hover animation - "wave cascade"
    # ---------------------------------------------------------------
    # Each active segment scales up vertically with a staggered start
    # so the bar reads as a wave rising from left to right. Marker
    # triangle pulses in sync. All animations loop while the cursor
    # is over the whole card; MouseLeave stops them and resets state.
    # We attach to the OUTER card so the user gets the effect whether
    # they hover over the bar, the heading, or the spec row.
    $animSegments = $activeSegments
    $animMarker   = $m1
    $animMarkerLift = $markerLift
    $animYouLift  = $youMarkLift
    $animLabel    = $headRight
    $card.Add_MouseEnter({
        # Each segment: ScaleY 1 -> 1.6 -> 1 over 1.4s, staggered
        # 110ms apart so the wave reads as a left-to-right ripple.
        for ($i = 0; $i -lt $animSegments.Count; $i++) {
            $seg = $animSegments[$i]
            $st  = $seg.RenderTransform
            $da = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
            $da.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(1400))
            $da.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $da.BeginTime = [TimeSpan]::FromMilliseconds($i * 110)
            $kf1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 1.0, ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.0))
            $kf2 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 1.6, ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.5))
            $kf3 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 1.0, ([System.Windows.Media.Animation.KeyTime]::FromPercent(1.0))
            $da.KeyFrames.Add($kf1) | Out-Null
            $da.KeyFrames.Add($kf2) | Out-Null
            $da.KeyFrames.Add($kf3) | Out-Null
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $da)
        }
        # Marker: lift up ~11px (about 3mm at 96dpi) and pulse there.
        # The lift uses the same 1.4s loop so it rides on top of the
        # wave - the triangle "jumps" toward the bar and bobs.
        $lift = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $lift.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(1400))
        $lift.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $lk1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.0,   ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.0))
        $lk2 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame -11.0, ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.5))
        $lk3 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.0,   ([System.Windows.Media.Animation.KeyTime]::FromPercent(1.0))
        $lift.KeyFrames.Add($lk1) | Out-Null
        $lift.KeyFrames.Add($lk2) | Out-Null
        $lift.KeyFrames.Add($lk3) | Out-Null
        $animMarkerLift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $lift)
        # The YOU marker (once the comparison has run) rides the same bob
        # - only one of the two markers is ever visible, so sharing the
        # animation is safe and keeps the motion identical.
        $animYouLift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $lift)
        # Marker glow pulse.
        if (-not $animMarker.Effect) {
            $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $glow.Color = [System.Windows.Media.Colors]::White
            $glow.BlurRadius = 8
            $glow.ShadowDepth = 0
            $glow.Opacity = 0
            $animMarker.Effect = $glow
        }
        $pulse = New-Object System.Windows.Media.Animation.DoubleAnimation
        $pulse.From = 0
        $pulse.To = 0.95
        $pulse.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
        $pulse.AutoReverse = $true
        $pulse.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $animMarker.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $pulse)
        # Power-tier label (e.g. "SOLID"): glow in soft blue-white so
        # it reads as "lit up" while hovering.
        if (-not $animLabel.Effect) {
            $lglow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $lglow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#bcd4ff")
            $lglow.BlurRadius = 12
            $lglow.ShadowDepth = 0
            $lglow.Opacity = 0
            $animLabel.Effect = $lglow
        }
        $lpulse = New-Object System.Windows.Media.Animation.DoubleAnimation
        $lpulse.From = 0.15
        $lpulse.To = 1.0
        $lpulse.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(900))
        $lpulse.AutoReverse = $true
        $lpulse.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $animLabel.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $lpulse)
    }.GetNewClosure())
    $card.Add_MouseLeave({
        # Ease everything back to idle instead of snapping. A new
        # BeginAnimation REPLACES the looping one and - because no
        # From is set - starts at the current animated value, so the
        # wave settles smoothly from wherever it happens to be.
        # HoldEnd keeps the rest values until the next MouseEnter
        # replaces these with the loops again.
        $ease = New-Object System.Windows.Media.Animation.QuadraticEase
        $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
        $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(450))
        foreach ($seg in $animSegments) {
            $settle = New-Object System.Windows.Media.Animation.DoubleAnimation
            $settle.To = 1.0; $settle.Duration = $dur; $settle.EasingFunction = $ease
            $seg.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $settle)
        }
        $settleY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $settleY.To = 0; $settleY.Duration = $dur; $settleY.EasingFunction = $ease
        $animMarkerLift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $settleY)
        $animYouLift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $settleY)
        if ($animMarker.Effect) {
            $fadeGlow = New-Object System.Windows.Media.Animation.DoubleAnimation
            $fadeGlow.To = 0; $fadeGlow.Duration = $dur; $fadeGlow.EasingFunction = $ease
            $animMarker.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $fadeGlow)
        }
        if ($animLabel.Effect) {
            $fadeGlow2 = New-Object System.Windows.Media.Animation.DoubleAnimation
            $fadeGlow2.To = 0; $fadeGlow2.Duration = $dur; $fadeGlow2.EasingFunction = $ease
            $animLabel.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $fadeGlow2)
        }
    }.GetNewClosure())

    return $card
}

function global:New-SteamTheatreButton {
    param([string]$AccentHex = "#4db8ff")

    # Hover-tooltip mockup that mimics the SteamVR Settings ->
    # Dashboard panel: row with the setting name on the left and
    # an Off/On segmented control on the right, plus a small
    # caption underneath. Replaces the external screenshot we
    # used to bundle for Gunfire and the README mentions of this
    # setting in other games.
    $accent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)

    $tooltip = New-Object System.Windows.Controls.ToolTip
    $tooltip.Background  = [System.Windows.Media.Brushes]::Transparent
    $tooltip.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $tooltip.Padding     = [System.Windows.Thickness]::new(0)
    $tooltip.HasDropShadow = $false

    $tipOuter = New-Object System.Windows.Controls.Border
    $tipOuter.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a24")
    $tipOuter.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $tipOuter.BorderThickness = [System.Windows.Thickness]::new(1)
    $tipOuter.CornerRadius    = [System.Windows.CornerRadius]::new(6)
    $tipOuter.Padding         = [System.Windows.Thickness]::new(8)
    $tipShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $tipShadow.Color = [System.Windows.Media.Color]::FromArgb(180,0,0,0)
    $tipShadow.BlurRadius = 16
    $tipShadow.ShadowDepth = 4
    $tipShadow.Opacity = 0.6
    $tipOuter.Effect = $tipShadow

    $tipInner = New-Object System.Windows.Controls.Border
    $tipInner.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1f2227")
    $tipInner.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $tipInner.Padding      = [System.Windows.Thickness]::new(14, 10, 14, 10)
    $tipInner.MinWidth     = 260

    $tipStack = New-Object System.Windows.Controls.StackPanel
    $tipInner.Child = $tipStack

    # Header line: where to find the setting
    $tipHeader = New-Object System.Windows.Controls.TextBlock
    $tipHeader.Text = "SteamVR Settings -> Dashboard"
    $tipHeader.FontSize = 11
    $tipHeader.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tipHeader.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
    $tipHeader.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $tipHeader.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $tipStack.Children.Add($tipHeader) | Out-Null

    # Setting row: name + Off/On segmented buttons
    $rowGrid = New-Object System.Windows.Controls.Grid
    $rowGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
    $cName = New-Object System.Windows.Controls.ColumnDefinition
    $cName.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $cToggle = New-Object System.Windows.Controls.ColumnDefinition
    $cToggle.Width = [System.Windows.GridLength]::Auto
    $rowGrid.ColumnDefinitions.Add($cName)   | Out-Null
    $rowGrid.ColumnDefinitions.Add($cToggle) | Out-Null

    $nameTxt = New-Object System.Windows.Controls.TextBlock
    $nameTxt.Text = "Present Non-VR Apps on" + [Environment]::NewLine + "Theater Screen Upon Launch"
    $nameTxt.FontSize = 11
    $nameTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
    $nameTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $nameTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $nameTxt.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
    [System.Windows.Controls.Grid]::SetColumn($nameTxt, 0)
    $rowGrid.Children.Add($nameTxt) | Out-Null

    # Off/On segmented control
    $togglePanel = New-Object System.Windows.Controls.StackPanel
    $togglePanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    [System.Windows.Controls.Grid]::SetColumn($togglePanel, 1)
    $togglePanel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $offBtn = New-Object System.Windows.Controls.Border
    $offBtn.Background    = $accent
    $offBtn.CornerRadius  = [System.Windows.CornerRadius]::new(2)
    $offBtn.Padding       = [System.Windows.Thickness]::new(10, 3, 10, 3)
    $offBtn.Margin        = [System.Windows.Thickness]::new(0, 0, 2, 0)
    $offTxt = New-Object System.Windows.Controls.TextBlock
    $offTxt.Text = "Off"
    $offTxt.FontSize = 10
    $offTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $offTxt.Foreground = [System.Windows.Media.Brushes]::Black
    $offTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $offBtn.Child = $offTxt
    $togglePanel.Children.Add($offBtn) | Out-Null

    $onBtn = New-Object System.Windows.Controls.Border
    $onBtn.Background    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $onBtn.CornerRadius  = [System.Windows.CornerRadius]::new(2)
    $onBtn.Padding       = [System.Windows.Thickness]::new(10, 3, 10, 3)
    $onTxt = New-Object System.Windows.Controls.TextBlock
    $onTxt.Text = "On"
    $onTxt.FontSize = 10
    $onTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
    $onTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $onBtn.Child = $onTxt
    $togglePanel.Children.Add($onBtn) | Out-Null

    $rowGrid.Children.Add($togglePanel) | Out-Null
    $tipStack.Children.Add($rowGrid) | Out-Null

    # Footer caption: "Set to OFF" with a top divider
    $footerBorder = New-Object System.Windows.Controls.Border
    $footerBorder.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $footerBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $footerBorder.Margin          = [System.Windows.Thickness]::new(0, 4, 0, 0)
    $footerBorder.Padding         = [System.Windows.Thickness]::new(0, 4, 0, 0)
    $footerTxt = New-Object System.Windows.Controls.TextBlock
    $footerTxt.Text = "Set to OFF"
    $footerTxt.FontSize = 10
    $footerTxt.Foreground = $accent
    $footerTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $footerBorder.Child = $footerTxt
    $tipStack.Children.Add($footerBorder) | Out-Null

    $tipOuter.Child = $tipInner
    $tooltip.Content = $tipOuter

    # The clickable button itself
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius  = [System.Windows.CornerRadius]::new(4)
    $btn.Padding       = [System.Windows.Thickness]::new(10, 6, 10, 6)
    $btn.Margin        = [System.Windows.Thickness]::new(0, 8, 0, 0)
    $btn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
    $accentColor = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
    # Tinted fill: ~12% accent, rest dark
    $tintFill = [System.Windows.Media.Color]::FromArgb(
        [byte]30,
        $accentColor.Color.R, $accentColor.Color.G, $accentColor.Color.B
    )
    $btn.Background = New-Object System.Windows.Media.SolidColorBrush $tintFill
    $tintBorder = [System.Windows.Media.Color]::FromArgb(
        [byte]160,
        $accentColor.Color.R, $accentColor.Color.G, $accentColor.Color.B
    )
    $btn.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush $tintBorder
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btn.ToolTip = $tooltip
    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($btn, 200)
    [System.Windows.Controls.ToolTipService]::SetShowDuration($btn, 600000)

    # Brighten accent a touch for the label so it pops on the dark fill
    $labelColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, $accentColor.Color.R + 30)),
        [byte]([Math]::Min(255, $accentColor.Color.G + 30)),
        [byte]([Math]::Min(255, $accentColor.Color.B + 30))
    )
    $labelBrush = New-Object System.Windows.Media.SolidColorBrush $labelColor

    $btnContent = New-Object System.Windows.Controls.StackPanel
    $btnContent.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    # Info icon (drawn as ellipse + "i")
    $iconBox = New-Object System.Windows.Controls.Grid
    $iconBox.Width = 13; $iconBox.Height = 13
    $iconBox.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $iconBox.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $iconCircle = New-Object System.Windows.Shapes.Ellipse
    $iconCircle.Width = 13; $iconCircle.Height = 13
    $iconCircle.Stroke = $labelBrush
    $iconCircle.StrokeThickness = 1.4
    $iconBox.Children.Add($iconCircle) | Out-Null
    $iconI = New-Object System.Windows.Controls.TextBlock
    $iconI.Text = "i"
    $iconI.FontSize = 9
    $iconI.FontWeight = [System.Windows.FontWeights]::Bold
    $iconI.Foreground = $labelBrush
    $iconI.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $iconI.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconI.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $iconBox.Children.Add($iconI) | Out-Null
    $btnContent.Children.Add($iconBox) | Out-Null

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = "Disable Steam Theatre"
    $lbl.FontSize = 12
    $lbl.FontWeight = [System.Windows.FontWeights]::Medium
    $lbl.Foreground = $labelBrush
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $lbl.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btnContent.Children.Add($lbl) | Out-Null
    $btn.Child = $btnContent

    # Click behaviour: clicking the button should ALSO show the
    # tooltip (not just hover). StaysOpen=true is required because
    # otherwise WPF dismisses the tooltip the instant we set it
    # open from inside a click handler. We then auto-close on
    # MouseLeave OR on any outside click / scroll, so the tooltip
    # behaves like a normal hover-tip even though it was opened
    # via click.
    $tooltipRef = $tooltip
    $btnRef     = $btn
    $btn.Add_MouseLeftButtonUp({
        param($s, $e)
        if ($tooltipRef.IsOpen) {
            # Second click closes it (toggle behaviour).
            $tooltipRef.IsOpen = $false
            $global:OpenTheatreTooltip = $null
            $global:OpenTheatreOwner   = $null
        } else {
            $tooltipRef.PlacementTarget = $this
            $tooltipRef.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
            $tooltipRef.StaysOpen = $true
            $tooltipRef.IsOpen = $true
            $global:OpenTheatreTooltip = $tooltipRef
            $global:OpenTheatreOwner   = $btnRef
        }
        # Don't bubble - otherwise the window-level outside-click
        # handler below would immediately close the tooltip we
        # just opened.
        $e.Handled = $true
    }.GetNewClosure())

    # Close on MouseLeave so the tooltip vanishes once the cursor
    # moves away - matches the user's expectation from regular
    # hover tooltips.
    $btn.Add_MouseLeave({
        if ($tooltipRef.IsOpen) {
            $tooltipRef.IsOpen = $false
            $global:OpenTheatreTooltip = $null
            $global:OpenTheatreOwner   = $null
        }
    }.GetNewClosure())

    Add-StandardHover -Border $btn
    return $btn
}


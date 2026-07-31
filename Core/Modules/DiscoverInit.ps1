# ---------------------------------------------------------------
# Discover view: tile-based browser of all games. Toggled from the
# header's grid icon. Uses the same data set as the list view,
# plus Steam Library portrait art for tiles whose Game.SteamId is
# set. Click on a tile -> detail page with hero image (or trailer
# video if available), README sections, and install/info actions.
# ---------------------------------------------------------------
$global:discoverBtn        = $window.FindName("DiscoverBtn")

# Glow hover for the library/discover toggle. Matches the ambient
# grey-purple accent used by the S/M/L scale buttons so the two
# read as part of the same Hub-level interactive vocabulary.
if ($global:discoverBtn) {
    Add-GlowHover -Border $global:discoverBtn -AccentHex "#5566aa"
}

$global:discoverHost       = $window.FindName("DiscoverHost")
$global:discoverPanel      = $window.FindName("DiscoverTilesPanel")
$global:discoverTiles      = $window.FindName("DiscoverTilesScroll")
$global:discoverDetail     = $window.FindName("DiscoverDetailScroll")
$global:discoverDetailHost = $window.FindName("DiscoverDetailHost")
$global:discoverOverview   = $window.FindName("DiscoverOverviewScroll")
$global:listScroll         = $window.FindName("ListScroll")
$global:DiscoverTilesBuilt = $false

# ---------------------------------------------------------------
# Header back arrow. A small chevron in the filter bar (left of the
# "All" pill) that mirrors the in-page Back button. Hidden on the
# library/home view; on detail/explore pages it starts grey (but is
# already clickable) and lights up white as the in-page Back button
# scrolls up and out of view - it takes over as the back control.
# ---------------------------------------------------------------
$global:HeaderBackBtn   = $window.FindName("HeaderBackBtn")
$global:HeaderBackArrow = $window.FindName("HeaderBackArrow")
$global:OverviewBackBtn = $window.FindName("OverviewBackBtn")

# Same back semantics as the mouse XButton1: detail -> overview or
# library, overview -> library. Pushes the source onto the forward
# stack so XButton2 still replays it.
function global:Invoke-HeaderBack {
    if (-not $global:NavForwardStack) { $global:NavForwardStack = New-Object System.Collections.ArrayList }
    $vis = [System.Windows.Visibility]::Visible
    if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq $vis) {
        [void]$global:NavForwardStack.Add(@{ View = "detail"; Game = $global:currentDetailGame; Origin = $global:DetailOrigin })
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue) { Hide-DiscoverDetail }
        return
    }
    if ($global:discoverOverview -and $global:discoverOverview.Visibility -eq $vis) {
        [void]$global:NavForwardStack.Add(@{ View = "overview"; Origin = $global:OverviewOrigin })
        if (Get-Command Hide-DiscoverOverview -ErrorAction SilentlyContinue) { Hide-DiscoverOverview }
        return
    }
    # Library: no sub-view to leave, so toggle tiles <-> list, exactly
    # like the mouse XButton1 back does on the library.
    if ($global:discoverHost -and $global:discoverHost.Visibility -eq $vis) {
        if ($global:HoverMediaElement) {
            try { $global:HoverMediaElement.Stop()  } catch { }
            try { $global:HoverMediaElement.Close() } catch { }
            $global:HoverMediaElement.Source = $null
            $global:HoverMediaElement = $null
        }
        $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
        if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
        if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
        if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
        return
    }
    if ($global:listScroll -and $global:listScroll.Visibility -eq $vis) {
        if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue) { Build-DiscoverTiles }
        if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
        if ($global:discoverDetail)   { $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed }
        if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
        if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
        $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed
        if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
        if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
        if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
        return
    }
}

# Paint the chevron from grey (#555560, inactive) to white (#f2f2f5,
# handed-over) for a 0..1 whiteness fraction.
function global:Set-HeaderArrowWhiteness {
    param([double]$f)
    if ($f -lt 0) { $f = 0.0 } elseif ($f -gt 1) { $f = 1.0 }
    $r = [byte][int](0x55 + (0xF2 - 0x55) * $f)
    $g = [byte][int](0x55 + (0xF2 - 0x55) * $f)
    $b = [byte][int](0x60 + (0xF5 - 0x60) * $f)
    if ($global:HeaderBackArrow) {
        $global:HeaderBackArrow.Stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($r, $g, $b))
    }
}

# Show/colour the header arrow for the current view. Grey on the
# library (tiles/list), grey -> white on detail/explore as the in-
# page Back button scrolls off (full white once it is half hidden).
function global:Update-HeaderBackArrow {
    if (-not $global:HeaderBackBtn) { return }
    $vis    = [System.Windows.Visibility]::Visible
    $hidden = [System.Windows.Visibility]::Hidden
    $onDetail   = $global:discoverDetail   -and $global:discoverDetail.Visibility   -eq $vis
    $onOverview = $global:discoverOverview -and $global:discoverOverview.Visibility -eq $vis
    if ($onDetail -or $onOverview) {
        $global:HeaderBackBtn.Visibility = $vis
        $sv  = if ($onDetail) { $global:discoverDetail } else { $global:discoverOverview }
        $btn = if ($onDetail) { $global:DetailBackBtn } else { $global:OverviewBackBtn }
        $f = 0.0
        if ($sv -and $btn) {
            try {
                $pt   = $btn.TransformToAncestor($sv).Transform([System.Windows.Point]::new(0, 0))
                $h    = [double]$btn.ActualHeight
                if ($h -le 1) { $h = 36 }
                $half = $h / 2.0
                $top  = [double]$pt.Y
                if ($top -ge 0) { $f = 0.0 }
                elseif ($top -le (-$half)) { $f = 1.0 }
                else { $f = (-$top) / $half }
            } catch { $f = 0.0 }
        }
        Set-HeaderArrowWhiteness $f
        return
    }
    # Library (tiles or list): mouse-back toggles the two list modes,
    # so keep the arrow visible but grey - nothing to hand off from
    # here, it just looks better than an empty gap.
    $onLibrary = ($global:discoverHost -and $global:discoverHost.Visibility -eq $vis) -or
                 ($global:listScroll   -and $global:listScroll.Visibility   -eq $vis)
    if ($onLibrary) {
        $global:HeaderBackBtn.Visibility = $vis
        Set-HeaderArrowWhiteness 0.0
        return
    }
    $global:HeaderBackBtn.Visibility = $hidden
}

# Re-evaluate after a navigation once layout has settled (so the
# in-page Back button exists and can be measured).
function global:Request-HeaderBackArrowUpdate {
    if (-not (Get-Command Update-HeaderBackArrow -ErrorAction SilentlyContinue)) { return }
    if (-not $window) { return }
    $window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Loaded,
        [Action]{ try { Update-HeaderBackArrow } catch { } }
    ) | Out-Null
}

if ($global:HeaderBackBtn) {
    $global:HeaderBackBtn.Add_MouseLeftButtonUp({ try { Invoke-HeaderBack } catch { } })
}
if ($global:discoverDetail) {
    $global:discoverDetail.Add_ScrollChanged({ try { Update-HeaderBackArrow } catch { } })
}
if ($global:discoverOverview) {
    $global:discoverOverview.Add_ScrollChanged({ try { Update-HeaderBackArrow } catch { } })
}
# Initial paint: the Hub opens on the library, so show the grey arrow
# right away once layout has settled.
if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }

# Click-through guard: list-card body click fires on Down, opens
# the detail page; the matching Up event then bubbles into
# whichever detail-page button now sits under the cursor (Steam
# link, info button, etc.).
#
# Strategy: track whether a Down event happened ON the detail
# page. If yes, the Up is part of a real click that started on
# this page - let it through. If the Up has no matching Down on
# this page, it's the trailing half of the navigation click - we
# eat it.
if ($global:discoverDetail) {
    $global:DetailDownSeen = $false
    $global:discoverDetail.Add_PreviewMouseLeftButtonDown({
        $global:DetailDownSeen = $true
    })
    $global:discoverDetail.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        if (-not $global:DetailDownSeen) {
            # Up without a matching Down on this page = orphan
            # event from list-card navigation. Eat it.
            if ($global:DetailOpenedAtMs) {
                $age = [Environment]::TickCount - $global:DetailOpenedAtMs
                if ($age -ge 0 -and $age -lt 500) {
                    $e.Handled = $true
                }
            }
        }
        # Reset for next click
        $global:DetailDownSeen = $false
    })
}

# Theatre-tooltip outside-close: once a "Disable Steam Theatre"
# tooltip is open, any click anywhere else in the window must
# close it. The tooltip itself is in a popup (separate hwnd) and
# the button's own click handler marks its events as Handled, so
# this window-level PreviewMouseDown only fires for genuine
# outside clicks.
$window.Add_PreviewMouseDown({
    if ($global:OpenTheatreTooltip -and $global:OpenTheatreTooltip.IsOpen) {
        try { $global:OpenTheatreTooltip.IsOpen = $false } catch { }
        $global:OpenTheatreTooltip = $null
        $global:OpenTheatreOwner   = $null
    }
})

# Mouse XButton1 (the side "back" button on most mice) acts as
# Back-navigation, mirroring how browsers and explorer use it.
# Detail page open -> back to overview (or to library if the
# overview wasn't the entry point). Overview open -> back to
# library. No-op on the library itself - there's nowhere to go.
#
# Plus XButton2 (forward): re-enters the page the user just left
# via XButton1. We push the source page onto a small forward
# stack on every back navigation; XButton2 pops it. The stack
# is cleared when the user navigates manually (clicking a card
# or the Discover button) - that matches how browsers handle it.
if (-not $global:NavForwardStack) { $global:NavForwardStack = New-Object System.Collections.ArrayList }

$window.Add_PreviewMouseDown({
    $e = $args[1]
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::XButton1) {
        # Back. Snapshot which view we're on so XButton2 can
        # restore it. Also store DetailOrigin so the forward
        # replay knows whether to call the LIST entry-point
        # (which makes discoverHost visible) or the simpler
        # Show-DiscoverDetail (when the host is already up).
        if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
            $snap = @{
                View   = "detail"
                Game   = $global:currentDetailGame
                Origin = $global:DetailOrigin
            }
            [void]$global:NavForwardStack.Add($snap)
            if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue) {
                Hide-DiscoverDetail
                $e.Handled = $true
            }
            return
        }
        if ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
            $snap = @{
                View   = "overview"
                Origin = $global:OverviewOrigin
            }
            [void]$global:NavForwardStack.Add($snap)
            if (Get-Command Hide-DiscoverOverview -ErrorAction SilentlyContinue) {
                Hide-DiscoverOverview
                $e.Handled = $true
            }
            return
        }
        # Simple list <-> tiles toggle. If we're not in a sub-view
        # (detail/overview already returned above), just flip between
        # the two main library modes when the back button is pressed.
        # No stack, no tracking - back/forward just toggle.
        if ($global:discoverHost -and $global:discoverHost.Visibility -eq [System.Windows.Visibility]::Visible) {
            # Currently on tiles -> switch to list
            if ($global:HoverMediaElement) {
                try { $global:HoverMediaElement.Stop()  } catch { }
                try { $global:HoverMediaElement.Close() } catch { }
                $global:HoverMediaElement.Source = $null
                $global:HoverMediaElement = $null
            }
            $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
            if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
            if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
            if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
            $e.Handled = $true
            return
        }
        if ($global:listScroll -and $global:listScroll.Visibility -eq [System.Windows.Visibility]::Visible) {
            # Currently on list -> switch to tiles
            if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue) { Build-DiscoverTiles }
            if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
            if ($global:discoverDetail)   { $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed }
            if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
            if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
            $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed
            if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
            if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
            $e.Handled = $true
            return
        }
        return
    }
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::XButton2) {
        # Forward. First try to replay a popped detail/overview from
        # the stack. If the stack is empty (or the snapshot doesn't
        # match a known view type), fall through to the library
        # toggle below.
        if ($global:NavForwardStack -and $global:NavForwardStack.Count -gt 0) {
            $snap = $global:NavForwardStack[$global:NavForwardStack.Count - 1]
            if ($snap) {
                $global:NavForwardStack.RemoveAt($global:NavForwardStack.Count - 1)
                # Suppress the manual-navigation stack-clear inside the
                # Show-* functions so this one replay call doesn't wipe
                # everything we still want to keep walking forward through.
                $global:NavSuppressForwardClear = $true
                try {
                    if ($snap.View -eq "detail" -and $snap.Game) {
                        # If the detail came from the list-view, use the
                        # LIST entry-point - it sets discoverHost.Visible
                        # and hides the list scroller. Otherwise the simpler
                        # Show-DiscoverDetail is enough (the host is up).
                        if ($snap.Origin -eq "LIST" -and (Get-Command Open-DiscoverDetailFromList -ErrorAction SilentlyContinue)) {
                            Open-DiscoverDetailFromList -Game $snap.Game
                            $e.Handled = $true
                        } elseif (Get-Command Show-DiscoverDetail -ErrorAction SilentlyContinue) {
                            Show-DiscoverDetail -Game $snap.Game
                            $e.Handled = $true
                        }
                        return
                    }
                    if ($snap.View -eq "overview") {
                        if (Get-Command Show-DiscoverOverview -ErrorAction SilentlyContinue) {
                            if ($snap.Origin) {
                                Show-DiscoverOverview -Origin $snap.Origin
                            } else {
                                Show-DiscoverOverview
                            }
                            $e.Handled = $true
                        }
                        return
                    }
                } finally {
                    $global:NavSuppressForwardClear = $false
                }
            }
        }
        # No forward-stack snapshot fits - if we're on a main library
        # view (no sub-view open), toggle to the other one. Forward
        # symmetry with the back button: between list and tiles, both
        # arrows just flip the current view.
        $detailOpen   = ($global:discoverDetail   -and $global:discoverDetail.Visibility   -eq [System.Windows.Visibility]::Visible)
        $overviewOpen = ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible)
        if ($detailOpen -or $overviewOpen) { return }
        if ($global:discoverHost -and $global:discoverHost.Visibility -eq [System.Windows.Visibility]::Visible) {
            if ($global:HoverMediaElement) {
                try { $global:HoverMediaElement.Stop()  } catch { }
                try { $global:HoverMediaElement.Close() } catch { }
                $global:HoverMediaElement.Source = $null
                $global:HoverMediaElement = $null
            }
            $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
            if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
            if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
            if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
            $e.Handled = $true
            return
        }
        if ($global:listScroll -and $global:listScroll.Visibility -eq [System.Windows.Visibility]::Visible) {
            if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue) { Build-DiscoverTiles }
            if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
            if ($global:discoverDetail)   { $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed }
            if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
            if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
            $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed
            if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
            if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
            $e.Handled = $true
            return
        }
    }
})

# Same for scrolling: if the user scrolls the page, the button
# usually leaves the viewport while the tooltip stays anchored
# in screen space - close the tooltip so it doesn't float over
# unrelated content.
$window.Add_PreviewMouseWheel({
    if ($global:OpenTheatreTooltip -and $global:OpenTheatreTooltip.IsOpen) {
        try { $global:OpenTheatreTooltip.IsOpen = $false } catch { }
        $global:OpenTheatreTooltip = $null
        $global:OpenTheatreOwner   = $null
    }
})

# Local refs for handler closures
$discoverBtn        = $global:discoverBtn
$discoverHost       = $global:discoverHost
$listScroll         = $global:listScroll

# DiscoverBtn hover is owned by Add-GlowHover (wired further up
# where the button is found). The previous DIY MouseEnter/Leave
# duplicated the active-state look on hover, which read as "now
# I'm active" rather than "hover" - and worse, fought with the
# Glow helper since both subscribe to the same events.

# Helper: paint the discover button to reflect the active mode.
# Active = gradient orange->blue-grey border (orange = Hub brand,
# blue-grey = neutral interactive accent). Inactive = same idea but
# colors reversed (blue-grey -> orange) and darkened 30%, so it
# reads as "same effect, dimmer" - clear visual relationship to
# the active state, easy to recognize as the off-variant. The
# Add-GlowHover helper wired further up stashes and restores
# BorderBrush on hover, so this gradient brush is preserved across
# hover cycles.
function global:Update-DiscoverBtnState {
    if (-not $global:discoverBtn -or -not $global:discoverHost) { return }
    $active = $global:discoverHost.Visibility -eq [System.Windows.Visibility]::Visible
    if ($active) {
        $global:discoverBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#26262e")
        # Two-stop diagonal gradient: warm Hub orange to cool
        # interactive blue-grey. Subtle but clearly premium.
        $gradBrush = New-Object System.Windows.Media.LinearGradientBrush
        $gradBrush.StartPoint = New-Object System.Windows.Point 0, 0
        $gradBrush.EndPoint   = New-Object System.Windows.Point 1, 1
        $stop1 = New-Object System.Windows.Media.GradientStop
        $stop1.Color = [System.Windows.Media.Color]::FromRgb(244, 122, 30)   # #f47a1e
        $stop1.Offset = 0.0
        $stop2 = New-Object System.Windows.Media.GradientStop
        $stop2.Color = [System.Windows.Media.Color]::FromRgb(85, 102, 170)   # #5566aa
        $stop2.Offset = 1.0
        [void]$gradBrush.GradientStops.Add($stop1)
        [void]$gradBrush.GradientStops.Add($stop2)
        $global:discoverBtn.BorderBrush = $gradBrush
    } else {
        $global:discoverBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
        # Inactive: same idea as active, but reversed direction
        # (blue-grey -> orange) and 30% darker. Reads as "the
        # same effect, dimmed" - signals visual relationship
        # without competing with the active emphasis.
        # Math: rgb * 0.7
        #   #5566aa (85,102,170) * 0.7 -> (60, 71, 119)  = #3c4777
        #   #f47a1e (244,122,30) * 0.7 -> (171, 85, 21)  = #ab5515
        $gradInactive = New-Object System.Windows.Media.LinearGradientBrush
        $gradInactive.StartPoint = New-Object System.Windows.Point 0, 0
        $gradInactive.EndPoint   = New-Object System.Windows.Point 1, 1
        $stopI1 = New-Object System.Windows.Media.GradientStop
        $stopI1.Color = [System.Windows.Media.Color]::FromRgb(60, 71, 119)   # blue-grey * 0.7
        $stopI1.Offset = 0.0
        $stopI2 = New-Object System.Windows.Media.GradientStop
        $stopI2.Color = [System.Windows.Media.Color]::FromRgb(171, 85, 21)   # orange * 0.7
        $stopI2.Offset = 1.0
        [void]$gradInactive.GradientStops.Add($stopI1)
        [void]$gradInactive.GradientStops.Add($stopI2)
        $global:discoverBtn.BorderBrush = $gradInactive
    }
    $global:discoverBtn.Effect = $null
    # Invalidate any stashed glow values - if the user clicked while
    # hovering, MouseLeave would otherwise restore the pre-click
    # border/fill and undo what we just set.
    if ($global:discoverBtn.Resources.Contains("ghBdBrush")) {
        $global:discoverBtn.Resources.Remove("ghBdBrush") | Out-Null
    }
    # Walk inner Rectangles/Ellipses and clear their stashed Fill if any.
    # The icon is now Rectangles (apps glyph) instead of Ellipses (dots);
    # we walk all Shapes so the helper covers both.
    if ($global:discoverBtn.Child) {
        $stack = New-Object System.Collections.Stack
        $stack.Push($global:discoverBtn.Child)
        while ($stack.Count -gt 0) {
            $node = $stack.Pop()
            if ($node -is [System.Windows.Shapes.Shape] -and $node.Resources.Contains("ghFill")) {
                $node.Resources.Remove("ghFill") | Out-Null
            }
            if ($node -is [System.Windows.Controls.Panel]) {
                foreach ($child in $node.Children) { $stack.Push($child) }
            }
        }
    }
}

# Filter bar stays visible in both modes. The S/M/L stack also
# stays visible - in list mode it scales the cards (1.0/1.5/2.0),
# in discover mode it sizes the portrait tiles (S/M/L). The click
# handlers route to the right action based on the active mode.
function global:Update-FilterBarForMode {
    # Both bars stay visible; nothing to collapse. Kept as a hook
    # so future per-mode tweaks have a place to land. Sync button
    # state so the highlighted S/M/L reflects the active mode.
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) {
        Sync-ScaleButtonsToMode
    }
}

# Apply the inactive gradient border immediately at load time so
# the user sees the new look on first paint rather than the XAML
# fallback solid border. Update-DiscoverBtnState reads
# $global:discoverHost.Visibility (Collapsed by default at this
# point = inactive branch = the dimmed reversed-gradient).
if ($global:discoverBtn -and $global:discoverHost) {
    Update-DiscoverBtnState
}


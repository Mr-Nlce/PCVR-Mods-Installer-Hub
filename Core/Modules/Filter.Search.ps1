$searchPlaceholder = $window.FindName("SearchPlaceholder")
# ---------------------------------------------------------------
# Search hint under the box. Two states in one spot:
#   normal  -> the examples line
#   "-name" -> offer to hide that modder for good, with the way back
# Only visible while the box has focus, and it hangs below the pill on
# its own layer, so showing it never moves the header.
# ---------------------------------------------------------------
$searchHintHost  = $window.FindName("SearchHintHost")
$searchHint      = $window.FindName("SearchHint")
$searchHidePanel = $window.FindName("SearchHidePanel")
$searchHideChk   = $window.FindName("SearchHideChk")
$searchHideText  = $window.FindName("SearchHideText")

# Permanently hidden modders live in the durable Hub state, next to the view
# choice and the S/M/L size, and survive a Hub update.
function global:Get-HiddenModders {
    $raw = $null
    try { $raw = Get-HubSetting -Key "hiddenModders" -Default @() } catch {}
    $out = @()
    foreach ($x in @($raw)) { if ($x) { $out += ([string]$x).Trim().ToLower() } }
    return ,$out
}
function global:Set-HiddenModders {
    param([string[]]$List)
    $clean = @()
    foreach ($x in @($List)) { if ($x) { $clean += ([string]$x).Trim().ToLower() } }
    $global:HiddenModders = @($clean | Sort-Object -Unique)
    try { Set-HubSetting -Key "hiddenModders" -Value $global:HiddenModders } catch {}
}
$global:HiddenModders = Get-HiddenModders

# The name behind a "-" or "+" only counts as a MODDER when the catalog
# actually knows it - otherwise "-horror" would offer to hide a modder
# called horror. Genres are excluded here on purpose.
# Shared by the filter and the hint: does the catalog know a modder whose
# name contains this string? Used to decide whether "-luke ross" is one name
# or a name plus a search word.
function global:Test-KnownModderName {
    param([string]$Name)
    $n = ([string]$Name).Trim().ToLower()
    if (-not $n) { return $false }
    foreach ($g in $global:allGameData) {
        if (-not $g) { continue }
        $a = if ($g.Author) { "$($g.Author)".ToLower() } else { "" }
        if ($a -and $a.Contains($n)) { return $true }
    }
    return $false
}

# Stricter than Test-KnownModderName: used to decide whether the "hide this
# modder" box appears at all. Contains() alone matched a single letter - "-l"
# hits half the catalog - so the box popped up while the name was still being
# typed. A modder counts as MEANT only from three characters on, and only when
# a WORD of the author name starts with it ("luk" -> "Luke Ross", but "uke"
# does not).
function global:Resolve-ModderName {
    param([string]$Name)
    $n = ([string]$Name).Trim().ToLower()
    if ($n.Length -lt 3) { return $null }

    if ($n.Contains(" ")) {
        # A fragment with a space ("luke ross") cannot be a single word -
        # compare it against the start of the whole author string.
        $hits = @()
        foreach ($g in $global:allGameData) {
            if (-not $g) { continue }
            $a = if ($g.Author) { "$($g.Author)".ToLower() } else { "" }
            if (-not $a) { continue }
            $a = ($a -replace '\([^)]*\)', ' ').Trim()
            # Compare against each CREDIT, not only the whole field: a
            # two-word alias can sit in second place ("Abyss-c0re / Doom
            # Slayer"), where the field never starts with it.
            foreach ($credit in ($a -split '\s*[+/&,]\s*')) {
                $c = $credit.Trim()
                if ($c -and $c.StartsWith($n) -and ($hits -notcontains $c)) { $hits += $c }
            }
        }
        if ($hits.Count -eq 0) { return $null }
        # @() around the pipeline is not cosmetic: with ONE hit the pipeline
        # returns a plain string, and [0] on a string is its first CHARACTER.
        # That is where "Hide f permanently" came from for "-fholger".
        $sorted = @($hits | Sort-Object Length)
        $shortest = [string]$sorted[0]
        foreach ($h in $hits) { if (-not $h.StartsWith($shortest)) { return $null } }
        return $shortest
    }

    # Single word. An author field can hold SEVERAL credits ("PureDark +
    # Astienth"), and each credit can be a multi-word name ("Luke Ross").
    # So split into credits first, then into words.
    $words      = @()   # distinct matching words
    $incomplete = $false
    foreach ($g in $global:allGameData) {
        if (-not $g) { continue }
        $a = if ($g.Author) { "$($g.Author)".ToLower() } else { "" }
        if (-not $a) { continue }
        # Markers like "(auto-update)" are not part of anybody's name.
        $a = ($a -replace '\([^)]*\)', ' ').Trim()
        foreach ($credit in ($a -split '\s*[+/&,]\s*')) {
            # Hyphen, underscore and # BELONG to these names: dr-89, xen-42,
            # abyss-c0re, #yevhen4817, simply-jos. Splitting them apart left
            # a dozen modders impossible to hide.
            $cw = @($credit -split '[^a-z0-9\._#-]+' | Where-Object { $_ })
            for ($k = 0; $k -lt $cw.Count; $k++) {
                if (-not $cw[$k].StartsWith($n)) { continue }
                if ($words -notcontains $cw[$k]) { $words += $cw[$k] }
                # The word is followed by another word inside the SAME credit,
                # so it is only part of a name ("luke" of "luke ross"). Wait
                # for the rest instead of offering to hide a first name that
                # two different people share.
                if ($k -lt ($cw.Count - 1)) { $incomplete = $true }
            }
        }
    }
    # A fully typed name wins even when longer names also start with it:
    # "rayrod" is a modder in its own right next to "rayrod-tv".
    if (-not $incomplete -and ($words -contains $n)) { return $n }
    if ($incomplete) { return $null }
    # Exactly one modder name, or nothing: "astien" still fits both "astienth"
    # and "astienvr", so nothing is offered until it is unambiguous.
    if ($words.Count -eq 1) { return [string]$words[0] }
    return $null
}

function global:Get-SearchModderTerm {
    param([string]$Text, [string]$Prefix)
    $parts = @(([string]$Text).Trim().ToLower() -split '\s+' | Where-Object { $_ })
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $part = $parts[$i]
        # Prefix "" means: look at the bare words too, so typing the name
        # again - with -, with + or with nothing - brings the box back.
        $isCand = if ($Prefix) { $part.Length -gt 1 -and $part.StartsWith($Prefix) }
                  else { -not ($part.StartsWith("-") -or $part.StartsWith("+")) }
        if (-not $isCand) { continue }
        $term = if ($Prefix) { $part.Substring(1) } else { $part }
        # Attach following words first ("luke ross"), then resolve the whole
        # thing to the modder's real name.
        for ($j = $i + 1; $j -lt $parts.Count; $j++) {
            $nxt = $parts[$j]
            if ($nxt.StartsWith("-") -or $nxt.StartsWith("+")) { break }
            $cand = ($term + " " + $nxt)
            if (Test-KnownModderName -Name $cand) { $term = $cand } else { break }
        }
        $full = Resolve-ModderName -Name $term
        if (-not $full) { continue }
        return $full
    }
    return $null
}

# Examples shown INSIDE the box, one after another, while it has focus and is
# empty. Short on purpose - the pill is narrow, and anything longer gets cut
# off mid-word.
$script:SearchExamples = @("e.g. cyberpunk", "e.g. praydog", "e.g. roomscale", "e.g. free", "e.g. -horror", "e.g. -praydog")
$script:SearchExampleIx = 0
$script:SearchExampleTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:SearchExampleTimer.Interval = [TimeSpan]::FromMilliseconds(2600)
$script:SearchExampleTimer.Add_Tick({
    # Stop as soon as the box is no longer empty or lost focus - the
    # placeholder is hidden then anyway.
    if (-not $searchBox -or -not $searchBox.IsKeyboardFocusWithin -or $searchBox.Text.Length -gt 0) {
        $script:SearchExampleTimer.Stop(); return
    }
    if ($searchPlaceholder) {
        $script:SearchExampleIx = ($script:SearchExampleIx + 1) % $script:SearchExamples.Count
        $searchPlaceholder.Text = $script:SearchExamples[$script:SearchExampleIx]
    }
})

function global:Start-SearchExamples {
    if (-not $searchPlaceholder) { return }
    $script:SearchExampleIx = 0
    $searchPlaceholder.Text = $script:SearchExamples[0]
    $script:SearchExampleTimer.Start()
}
function global:Stop-SearchExamples {
    try { $script:SearchExampleTimer.Stop() } catch {}
    if ($searchPlaceholder) { $searchPlaceholder.Text = "Search" }
}

function global:Update-SearchHint {
    if (-not $searchHintHost) { return }
    if (-not $searchBox.IsKeyboardFocusWithin) {
        $searchHintHost.Visibility = [System.Windows.Visibility]::Collapsed
        return
    }
    $txt = [string]$searchBox.Text

    $minusName = Get-SearchModderTerm -Text $txt -Prefix "-"
    $plusName  = Get-SearchModderTerm -Text $txt -Prefix "+"

    if ($plusName -and ($global:HiddenModders -contains $plusName)) {
        # A hidden modder is being brought back - offer to drop them from
        # the standing list instead of only lifting them for this search.
        $script:searchHintTarget = $plusName
        $script:searchHintMode   = "unhide"
        $searchHideChk.IsChecked = $false
        $searchHideChk.Content   = "Hide $plusName permanently"
        $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
        $searchHidePanel.Visibility = [System.Windows.Visibility]::Visible
        $searchHintHost.Visibility  = [System.Windows.Visibility]::Visible
        return
    }
    $plainName = Get-SearchModderTerm -Text $txt -Prefix ""
    if (-not $minusName -and $plainName -and ($global:HiddenModders -contains $plainName)) {
        # Typing a hidden modder's name plainly: show the box ticked so it can
        # simply be un-ticked.
        $script:searchHintTarget = $plainName
        $script:searchHintMode   = "hide"
        $searchHideChk.IsChecked = $true
        $searchHideChk.Content   = "Hide $plainName permanently"
        $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
        $searchHidePanel.Visibility = [System.Windows.Visibility]::Visible
        $searchHintHost.Visibility  = [System.Windows.Visibility]::Visible
        return
    }
    if ($minusName) {
        $script:searchHintTarget = $minusName
        $script:searchHintMode   = "hide"
        $searchHideChk.IsChecked = ($global:HiddenModders -contains $minusName)
        $searchHideChk.Content   = "Hide $minusName permanently"
        $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
        $searchHidePanel.Visibility = [System.Windows.Visibility]::Visible
        $searchHintHost.Visibility  = [System.Windows.Visibility]::Visible
        return
    }
    $script:searchHintTarget = $null
    $script:searchHintMode   = "examples"
    $searchHidePanel.Visibility = [System.Windows.Visibility]::Collapsed
    $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
    $searchHintHost.Visibility  = [System.Windows.Visibility]::Collapsed
}

if ($searchHideChk) {
    $searchHideChk.Add_Click({
        $name = $script:searchHintTarget
        if (-not $name) { return }
        $list = @($global:HiddenModders)
        if ($script:searchHintMode -eq "unhide") {
            # Ticking the box here MEANS "stop hiding".
            if ($this.IsChecked) { $list = @($list | Where-Object { $_ -ne $name }) }
            elseif ($list -notcontains $name) { $list += $name }
        } else {
            if ($this.IsChecked) { if ($list -notcontains $name) { $list += $name } }
            else { $list = @($list | Where-Object { $_ -ne $name }) }
        }
        Set-HiddenModders -List $list
        Apply-Filter
        Update-SearchHint
    })
}
# SELF-HEALING FOR THE SEARCH BAR (2026-08-20). Reported symptom:
# the bar sometimes gets stuck showing one of the rotating example
# words, looking as if something were selected, and clicking into it
# does nothing.
# HONEST NOTE: the root cause is not proven. What is certain: the
# bar's whole state hangs on GotKeyboardFocus/LostKeyboardFocus, and
# LostKeyboardFocus has an early exit (a click into the hint row) -
# after which the example timer kept running even though the box no
# longer holds keyboard focus. If the window loses focus at that
# moment, an example word stays on screen and nobody can type.
# This handler rebuilds the state on EVERY click on the search pill,
# whatever caused it: force focus, reset timer and placeholder.
# PreviewMouseDown so it also fires when a child would swallow the
# click.
$searchPill = $window.FindName("SearchPill")
if ($searchPill -and $searchBox) {
    $searchPill.Add_PreviewMouseDown({
        try {
            if (-not $searchBox.IsKeyboardFocusWithin) {
                $searchBox.Focus() | Out-Null
                [System.Windows.Input.Keyboard]::Focus($searchBox) | Out-Null
            }
            # Rebuild the state instead of hoping it is right.
            if ($searchBox.Text.Length -eq 0) { Start-SearchExamples } else { Stop-SearchExamples }
            Update-SearchHint
        } catch {}
    })
}

if ($searchBox) {
    $searchBox.Add_GotKeyboardFocus({ Start-SearchExamples; Update-SearchHint })
    $searchBox.Add_LostKeyboardFocus({
        param($sender, $e)
        # If focus moved INTO the hint panel itself, keep it open - collapsing
        # here is what used to swallow the click on the checkbox.
        try {
            $to = $e.NewFocus
            while ($to) {
                if ($to -eq $searchHintHost) {
                    # Focus moved into the hint row - that stays open.
                    # BUT: the example timer used to keep running here even
                    # though the box no longer holds the keyboard. That is
                    # exactly the state that then looks "stuck".
                    try { $script:SearchExampleTimer.Stop() } catch {}
                    return
                }
                $to = [System.Windows.Media.VisualTreeHelper]::GetParent($to)
            }
        } catch {}
        Stop-SearchExamples
        if ($searchHintHost) { $searchHintHost.Visibility = [System.Windows.Visibility]::Collapsed }
    })
}

$searchBox.Add_TextChanged({
    # Typing in the search box while the description (detail) page is
    # open used to leave the detail sitting on top: the live filter ran
    # against the hidden library underneath, so nothing was visible and
    # the detail's filter-pill selection lingered. Tear the detail down
    # the same way the Back button does (Hide-DiscoverDetail ->
    # Restore-FilterPills) and reveal the filtered portrait library so
    # the search is actually visible.
    if ($this.Text.Length -gt 0 -and $global:discoverDetail -and
        $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue)      { Hide-DiscoverDetail }
        if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue)      { Build-DiscoverTiles }
        if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
        if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
        if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
        if ($global:listScroll)       { $global:listScroll.Visibility       = [System.Windows.Visibility]::Collapsed }
        if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
        if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
        if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
        if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue)       { Apply-LibrarySize $global:LibrarySize }
    }
    Apply-Filter
    if (Get-Command Update-SearchHint -ErrorAction SilentlyContinue) { Update-SearchHint }
    if ($searchPlaceholder) {
        $searchPlaceholder.Visibility = if ($this.Text.Length -gt 0) {
            [System.Windows.Visibility]::Collapsed
        } else {
            [System.Windows.Visibility]::Visible
        }
    }
})

# Pressing Enter while on the Explore or Detail page jumps to the
# Library (the Steam portrait list), where the live text filter
# already shows whatever the query matches. On the Library and List
# views the filter is live as you type, so Enter is a no-op there.
# This mirrors the Discover button's "show library" branch so the
# portrait tiles are built, revealed and filtered in one step.
$searchBox.Add_KeyDown({
    param($s, $e)
    if ($e.Key -ne [System.Windows.Input.Key]::Enter) { return }
    $view = if (Get-Command Get-CurrentView -ErrorAction SilentlyContinue) { Get-CurrentView } else { "List" }
    if ($view -ne "Explore" -and $view -ne "Detail") { return }
    $e.Handled = $true
    # Leave the detail/overview sub-view the same way the Back button
    # does - tear it down so Hide-DiscoverDetail -> Restore-FilterPills
    # resets the filter pills. The bare Visibility flip below collapsed
    # the detail but skipped this, so the description's pill selection
    # lingered. (The forced-tiles block right after still lands us on
    # the filtered library, overriding the origin view Hide returns to.)
    if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue) { Hide-DiscoverDetail }
    } elseif ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverOverview -ErrorAction SilentlyContinue) { Hide-DiscoverOverview }
    }
    if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue)      { Build-DiscoverTiles }
    if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
    if ($global:discoverDetail)   { $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed }
    if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
    if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
    if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
    if ($global:listScroll)       { $global:listScroll.Visibility       = [System.Windows.Visibility]::Collapsed }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    if (Get-Command Apply-Filter -ErrorAction SilentlyContinue)            { Apply-Filter }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
    if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue)       { Apply-LibrarySize $global:LibrarySize }
})

# --- Check Installed ---
$checkInstalledBtn  = $window.FindName("CheckInstalledBtn")
$checkInstalledText = $window.FindName("CheckInstalledText")
$checkInstalledCount      = $window.FindName("CheckInstalledCount")
$checkInstalledCountInst  = $window.FindName("CheckInstalledCountInst")
$checkInstalledCountReady = $window.FindName("CheckInstalledCountReady")
$checkInstalledCountSep   = $window.FindName("CheckInstalledCountSep")
$checkInstalledReadyIcon  = $window.FindName("CheckInstalledReadyIcon")
$checkInstalledShimmer    = $window.FindName("CheckInstalledShimmer")
$checkInstalledShimmerXf  = $window.FindName("CheckInstalledShimmerXf")

# Permanent green halo on the counter button. DropShadowEffect with
# no offset = soft outer glow. Pre-scan state ("Check Installed"
# text) gets a dimmed halo - the button is interesting but doesn't
# scream for attention; Invoke-CheckInstalledScan promotes it to
# the full eye-catcher halo after the scan completes. WPF can't
# stack multiple drop shadows like CSS, so we go with a single
# blur and just animate its intensity between the two states.
$ciGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
$ciGlow.Color       = [System.Windows.Media.Color]::FromRgb(74, 222, 128)
$ciGlow.BlurRadius  = 8
$ciGlow.ShadowDepth = 0
$ciGlow.Opacity     = 0.25
$checkInstalledBtn.Effect = $ciGlow

# Periodic shimmer sweep on the counter button.
# Timing:
#   - 1.5s sweep from left edge to past right edge
#   - random 12-60s pause (no movement, parked off-screen right)
#   - then repeats with a fresh random pause each cycle
# Why randomised pause: a fixed 13s interval reads as mechanical/
# clock-like. Varying the pause per cycle keeps the effect feeling
# alive without ever being obtrusive.
# Implementation: single-shot DoubleAnimation on the Transform,
# whose Completed event arms a DispatcherTimer with a random
# interval, which on tick re-runs the sweep. Simple loop.
# An earlier version used RepeatBehavior::Forever with a fixed
# 14.5s key-framed animation - works but pauses are identical
# every cycle, which is exactly what we're moving away from.
#
# Range: X from -100 (hidden off the left edge) to 300 (well past
# the right edge - the shimmer Border is Width=80, and even a wide
# counter button is comfortably under 220px). The TranslateTransform
# is built fresh in code rather than declared in XAML because a
# XAML-parser-frozen Transform silently refuses animations on its
# properties in some WPF versions.
#
# The shimmer Border itself starts with Visibility=Collapsed (set
# in Window.ps1). Invoke-CheckInstalledScan flips it to Visible
# once the counter takes over from the "Check Installed" label.
# The animation loop runs unconditionally though - cheap to leave
# ticking, and the moment the user does their first scan the
# shimmer is already in sync.
$shimmerTx = New-Object System.Windows.Media.TranslateTransform
$shimmerTx.X = -100
$checkInstalledShimmer.RenderTransform = $shimmerTx
$checkInstalledShimmerXf = $shimmerTx

$shimmerRand = New-Object System.Random
$shimmerPauseTimer = New-Object System.Windows.Threading.DispatcherTimer

# Build the sweep animation once and reuse it. Beginning a fresh
# animation each cycle reseats X to -100 automatically via the
# KeyFrame at t=0.
$shimmerSweep = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
$shimmerSweep.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(1500))
$kfS0 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame -100.0, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(0)))
$kfS1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame  300.0, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(1500)))
[void]$shimmerSweep.KeyFrames.Add($kfS0)
[void]$shimmerSweep.KeyFrames.Add($kfS1)

# On sweep completion: park X at 300, arm the pause timer with a
# fresh random 12-60s interval, and wait for tick.
$shimmerSweep.Add_Completed({
    $shimmerTx.BeginAnimation(
        [System.Windows.Media.TranslateTransform]::XProperty,
        $null
    )
    $shimmerTx.X = 300
    $pauseMs = $shimmerRand.Next(12000, 60001)  # 12.000-60.000 ms inclusive
    $shimmerPauseTimer.Interval = [TimeSpan]::FromMilliseconds($pauseMs)
    $shimmerPauseTimer.Start()
}.GetNewClosure())

# On pause-timer tick: stop the timer, kick off another sweep.
$shimmerPauseTimer.Add_Tick({
    $shimmerPauseTimer.Stop()
    $shimmerTx.BeginAnimation(
        [System.Windows.Media.TranslateTransform]::XProperty,
        $shimmerSweep
    )
}.GetNewClosure())

# Kick off the first sweep immediately. From here the Completed ->
# pause-timer -> Tick -> sweep loop runs forever.
$shimmerTx.BeginAnimation(
    [System.Windows.Media.TranslateTransform]::XProperty,
    $shimmerSweep
)

# --- Shimmer opt-out (session + persistent) ---
# Dwell over the counter for 5s and a small overlay appears with
# two chips: "Disable shimmer" (session only) and "Always Disable"
# (writes shimmerDisabled=true to hub-settings.json). Same idiom
# as the banner / recently-played hover overlays.
# script:shimmerDisabled is the session-level flag; reads from the
# persisted setting at startup and can be flipped to true mid-
# session by the user. Invoke-CheckInstalledScan checks this
# before promoting the shimmer to Visible.
$script:shimmerDisabled = $false
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    $script:shimmerDisabled = [bool](Get-HubSetting -Key "shimmerDisabled" -Default $false)
}
$shimmerDisableOverlay  = $window.FindName("ShimmerDisableOverlay")
$shimmerDisableBtn      = $window.FindName("ShimmerDisableBtn")
$shimmerAlwaysDisableBtn= $window.FindName("ShimmerAlwaysDisableBtn")

if ($shimmerDisableOverlay -and $shimmerDisableBtn -and $shimmerAlwaysDisableBtn) {
    $sdShowTimer = New-Object System.Windows.Threading.DispatcherTimer
    $sdShowTimer.Interval = [TimeSpan]::FromSeconds(5)
    $sdHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $sdHideTimer.Interval = [TimeSpan]::FromMilliseconds(800)

    $sdShowTimer.Add_Tick({
        $sdShowTimer.Stop()
        # Only reveal if the shimmer is actually running (i.e. the
        # counter has taken over from "Check Installed"). Otherwise
        # offering to disable a non-running effect is pointless and
        # confusing.
        if ($checkInstalledShimmer -and
            $checkInstalledShimmer.Visibility -eq [System.Windows.Visibility]::Visible) {
            $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Visible
        }
    }.GetNewClosure())

    $sdHideTimer.Add_Tick({
        $sdHideTimer.Stop()
        $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    # Dwell trigger: only count time when the counter is showing
    # the post-scan state. During "Check Installed" the shimmer
    # isn't running so there's nothing to opt out of.
    $checkInstalledBtn.Add_MouseEnter({
        $sdHideTimer.Stop()
        if (-not $checkInstalledShimmer) { return }
        if ($checkInstalledShimmer.Visibility -ne [System.Windows.Visibility]::Visible) { return }
        if ($shimmerDisableOverlay.Visibility -ne [System.Windows.Visibility]::Visible) {
            $sdShowTimer.Stop()
            $sdShowTimer.Start()
        }
    }.GetNewClosure())

    $checkInstalledBtn.Add_MouseLeave({
        $sdShowTimer.Stop()
        if ($shimmerDisableOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
            $sdHideTimer.Stop()
            $sdHideTimer.Start()
        }
    }.GetNewClosure())

    # MouseEnter on overlay itself cancels the hide-timer so the
    # cursor can travel across the button -> overlay gap without
    # the overlay vanishing.
    $shimmerDisableOverlay.Add_MouseEnter({
        $sdHideTimer.Stop()
    }.GetNewClosure())
    $shimmerDisableOverlay.Add_MouseLeave({
        $sdHideTimer.Stop()
        $sdHideTimer.Start()
    }.GetNewClosure())

    # "Disable shimmer" = hide it for this session only. Animation
    # keeps ticking under the hood (cheap, harmless) so a future
    # re-enable would just need Visibility=Visible. We also stop
    # the overlay's own timers and hide it.
    $shimmerDisableBtn.Add_MouseLeftButtonUp({
        if ($checkInstalledShimmer) {
            $checkInstalledShimmer.Visibility = [System.Windows.Visibility]::Collapsed
        }
        $script:shimmerDisabled = $true
        $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $sdShowTimer.Stop()
        $sdHideTimer.Stop()
    }.GetNewClosure())
    $shimmerDisableBtn.Add_MouseEnter({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    $shimmerDisableBtn.Add_MouseLeave({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    })

    # "Always Disable" = same plus persist to hub-settings so the
    # next launch starts without the shimmer entirely.
    $shimmerAlwaysDisableBtn.Add_MouseLeftButtonUp({
        if ($checkInstalledShimmer) {
            $checkInstalledShimmer.Visibility = [System.Windows.Visibility]::Collapsed
        }
        $script:shimmerDisabled = $true
        $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $sdShowTimer.Stop()
        $sdHideTimer.Stop()
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "shimmerDisabled" -Value $true
        }
    }.GetNewClosure())
    $shimmerAlwaysDisableBtn.Add_MouseEnter({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    $shimmerAlwaysDisableBtn.Add_MouseLeave({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    })
}

# Glow hover for Check Installed. Same green accent the button
# itself uses so it reads as part of its identity. The hover is
# harmless during the post-click pulse animation since the helper
# only modifies BorderBrush + Foreground; the pulse drives
# Background.
Add-GlowHover -Border $checkInstalledBtn -AccentHex "#5aa880"


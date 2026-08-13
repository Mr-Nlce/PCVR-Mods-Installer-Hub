# Startup splash shown in the launcher console while the Hub loads
# concurrently. Prints a magenta banner (same rule line as the installer
# headers) plus a progress bar that fills toward the last recorded load
# time, then snaps to 100% the moment the Hub signals its window is up.
# A random loading hint fades in (dim -> bright) on its own line under the
# bar; the bar redraws above it in place, so the hint stays put. The
# launcher console closes right after (the batch ends), so nothing
# lingers in the foreground. The Hub runs in its own minimized console.

# The banner rules, progress circles and star use non-ASCII glyphs
# (U+2550, U+25CF, U+00B7, U+2605). Force UTF-8 output so Windows Terminal
# and conhost render them instead of "?" boxes. Best-effort.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$readyFlag = Join-Path $env:TEMP "PCVRHub_ready.flag"
$lastFile  = Join-Path $env:TEMP "PCVRHub_lastload.txt"

# Clear any stale ready flag from a previous run before polling. The Hub
# takes seconds to cold-start, so it always re-writes this well after.
Remove-Item $readyFlag -Force -ErrorAction SilentlyContinue

# Estimated load time from the last run (default 5s; clamped to a sane
# range so a one-off slow/fast start does not skew the pacing).
$est = 5.0
try {
    if (Test-Path $lastFile) {
        $v = [double]((Get-Content $lastFile -Raw).Trim())
        if ($v -ge 2 -and $v -le 20) { $est = $v }
    }
} catch { }

# Mod count shown in the {N} hints - the real VR-mod tally. Tools and
# external tool entries are deliberately NOT counted, so an auto-count of
# catalog entries reads high. RULE: bump this by +1 with EVERY new game
# tile added to the Hub (games only - never for tools like UEVR).
$tileCount = 225

# Loading hints - one is picked at random each launch. Written to be
# confident and accurate: guided installers (never "one click"), only
# Steam/GOG/Epic for detection, nothing that implies the Hub is shaky.
$hints = @(
    "Drop a ROM or archive on the installer - it takes care of the unpacking.",
    "Every standalone game installs to one tidy folder, never scattered across your drive.",
    "Even a blank-icon launcher gets a proper custom icon on your desktop.",
    "Where a modder accepts tips, their support link sits right on the game page.",
    "A card shows motion or gamepad up front, before you commit.",
    "Recently Played in the way? Hover its heading for 7 seconds - a close option appears on the right.",
    "Guided the whole way and you stay at the wheel. The Hub doesn't do anything without your consent.",
    "Downloads fetch from the source at install time; nothing bulky ships in here.",
    "Split-screen shooters to decompiled N64 ports - all under one roof.",
    "Non-Steam games still land a real desktop shortcut, icon and all.",
    "The magenta rule, top and bottom, is just how the house is dressed.",
    "A button that shimmers is one that wants pressing.",
    "Extraction shows a clean percentage - no raw archive chatter.",
    "Aurora one launch, a meteor shower the next - the banner keeps its own counsel.",
    "Open it and go - no sign-in, no account, no fuss.",
    "The bar breathes as it works - the last stretch closes fast.",
    "Yes, the banner looks different every launch. You're not imagining it.",
    "The bar jumps to 100% right after 92%. Can you spot the frames?",
    "Now and then the counter button catches a shimmer.",
    "Every card lights up when you look at it. Go on, hover one.",
    "Every installer bows out in magenta. Then the new world is yours.",
    "Over fifty banner effects. You get one tonight - lucky dip.",
    "Frosting the glass on every card.",
    "Cutting each card from a single sheet of frosted glass.",
    "Hanging the glass before you walk in.",
    "Slotting the last tile into place.",
    "Polishing portraits until they shine through the frost.",
    "The frost is hand-tuned. You'll notice.",
    "{N} PC VR mods, guides and installers in one place.",
    "{N} games in the library - one home for all of them.",
    "The boring setup parts, handled so you don't have to.",
    "More fallbacks than any installer should reasonably need.",
    "Installed in unusual places? If the Hub can't spot it, try Locate Game.",
    "VR Ready or Needs Mod - every card wears its status.",
    "The info pill is one click from the mod's own page.",
    "Your next install is hiding somewhere in Explore.",
    "The Explore page already knows the good stuff that you need.",
    "One window, a whole PC VR toolbox behind it.",
    "Made for the headset sitting right next to you.",
    "No exe, nothing compiled. Open code, nothing hidden.",
    "Modding PC VR, minus the spreadsheet.",
    "Orbs, embers, meteors - the banner picks its own mood.",
    "Filter by control type, genre or power in Explore. Your shelf, your rules.",
    "{N} cards, frosted and filed.",
    "Nearly there. Headset within reach.",
    "Can't decide? Hit Shuffle in the Explore area and let the Hub pick for you.",
    "Cards scale to S, M or L. Size the shelf to taste.",
    "The Hub remembers the window size and where you left it.",
    "Where it helps, a guide maps the controller bindings, button by button.",
    "Free mods wear a FREE tag. FREE works as a search term, too.",
    "Every game page points you to a few more like it.",
    "A Needs Mod card is one guided install from ready.",
    "Each game gets its own page, art and all.",
    "The Hub spots updates in the background. Installing is your call.",
    "Hover VR Ready and it flips to Start in VR. Hit it, the card sweeps you in.",
    "Steam, GOG or Epic - the scan knows all three homes.",
    "Some mods keep themselves current. Those cards wear an AUTO-UPDATE pill.",
    "A download died? Drag the file onto the installer window and carry on. That's the whole fix.",
    "Reinstalling keeps your saves and ROMs - set aside, put back, like nothing happened.",
    "Search speaks tags: try 'horror', 'racing' or your favourite modder's name.",
    "Every card carries a power tier, so your GPU knows what it's signing up for.",
    "Motion controllers posing as a gamepad? They are marked, you decide if you are interested.",
    "One framework covers a dozen Capcom titles - the Hub keeps them straight.",
    "A blue add-on banner means optional extra content, one click deeper.",
    "Slow mirror tonight? The check finishes in the background and shows the results with the next scan.",
    "Your ROMs stay on your PC. The Hub reads them, never phones them home.",
    "Artwork caches after the first look - the shelf only gets faster.",
    "Some entries hand you to the modder's own page - the Hub knows when to step aside.",
    "If available, controller art is on the game page - learn the buttons before the headset goes on.",
    "Stuck at a prompt? R retries, S skips, O reopens. No dead ends in here.",
    "Every installer ends on a one-liner. Some of them are almost good.",
    "These hints rotate. Keep restarting and you'll collect the set.",
    "Explore sorts by genre rows - scroll sideways, fall down the rabbit hole.",
    "The scan is quick by design: disk first, online second, freeze never.",
    "Update badges land on the tile itself - no digging, no changelog spelunking.",
    "More great VR games in here than Pokemon in Gen 1. Gotta mod 'em all.",
    "{N} entries. Roll for initiative on your next install.",
    "It's dangerous to go alone. Take {N} VR games.",
    "Another game needs your VR mod.",
    "I used to play flat, then I took a headset to the face.",
    "I am sworn to carry your mod files.",
    "Hey, you. You're finally VR."
)
$flavor = ($hints | Get-Random) -replace '\{N\}', $tileCount

# Console width for centering. WindowWidth IS readable here (unlike window
# position/size), so we center against it; on any failure we fall back to a
# sane default and everything still renders, just left-of-centre.
$conW = 100
try { $cw = [Console]::WindowWidth; if ($cw -ge 40 -and $cw -le 400) { $conW = $cw } } catch { }

# Center a single line by padding it with leading spaces. Never returns a
# negative pad (a line wider than the console just starts at column 0).
function Center-Line([string]$text, [int]$width) {
    $pad = [int](($width - $text.Length) / 2)
    if ($pad -lt 0) { $pad = 0 }
    return (" " * $pad) + $text
}

try { [Console]::CursorVisible = $false } catch { }

# Banner: letter-spaced title with solid double-line rules above/below,
# all centered. The rule width tracks the title so they frame it evenly.
$titleText = "PCVR  MODS  INSTALLER  HUB"
$ruleLen   = $titleText.Length + 6
$rule      = [string][char]0x2550 * $ruleLen        # U+2550 solid double line
Write-Host ""
Write-Host ""
Write-Host (Center-Line $rule $conW) -ForegroundColor Magenta
Write-Host (Center-Line $titleText $conW) -ForegroundColor White
Write-Host (Center-Line $rule $conW) -ForegroundColor Magenta
Write-Host ""
Write-Host ""

# Bar sits just under the banner. Remember its absolute row so the loop
# can redraw the bar in place while the hint stays put below it.
$barRow = [Console]::CursorTop
Write-Host ""   # bar row (painted in the loop)

# Gap between the bar and the hint line below it.
Write-Host ""   # gap
Write-Host ""   # gap
Write-Host ""   # gap

# --- Centered loading hint box ----------------------------------------
# The tip is framed in an ASCII box with "HINT" inset in the top rule,
# wrapped to at most two lines. The whole box is centered under the bar
# (indented by $boxLeft so its midpoint matches the console midpoint) and
# sits a few lines below the bar. The frame is drawn ONCE; the loop
# repaints only the inner text region so the border never flickers.
$bw       = 54                                  # inner text width
$boxOuter = $bw + 4                             # full box width incl. walls
$boxLeft  = [int](($conW - $boxOuter) / 2)      # centered indent
if ($boxLeft -lt 0) { $boxLeft = 0 }
$boxIndent = " " * $boxLeft
$hintCol   = $boxLeft + 2                        # text starts just past "| "

function Split-HintTwoLines([string]$t, [int]$w) {
    if ($t.Length -le $w) { return @($t, "") }
    $idx = $t.LastIndexOf(" ", [Math]::Min($w, $t.Length - 1))
    if ($idx -lt 1) { $idx = $w }
    $a = $t.Substring(0, $idx).TrimEnd()
    $b = $t.Substring($idx).TrimStart()
    if ($b.Length -gt $w) { $b = $b.Substring(0, $w) }
    return @($a, $b)
}
$wrap = Split-HintTwoLines $flavor $bw
$hl1  = [string]$wrap[0]
$hl2  = [string]$wrap[1]
# Virtual reveal string (single space rejoins the wrap) drives the typewriter.
$hintFull = if ($hl2) { $hl1 + " " + $hl2 } else { $hl1 }

# A little extra space between the bar and the box.
Write-Host ""
Write-Host ""

# Draw the static frame: top rule (HINT), two text rows, base - all
# indented by $boxIndent so the box is centered.
$blankRow = $boxIndent + "|" + (" " * ($bw + 2)) + "|"
Write-Host ($boxIndent + "+-[ ") -NoNewline -ForegroundColor DarkCyan
Write-Host "HINT" -NoNewline -ForegroundColor Magenta
Write-Host (" ]" + ("-" * (($bw + 2) - 9)) + "+") -ForegroundColor DarkCyan
Write-Host $blankRow -ForegroundColor DarkCyan
$hRow1 = [Console]::CursorTop
Write-Host $blankRow -ForegroundColor DarkCyan
$hRow2 = [Console]::CursorTop
Write-Host $blankRow -ForegroundColor DarkCyan
Write-Host $blankRow -ForegroundColor DarkCyan
Write-Host ($boxIndent + "+" + ("-" * ($bw + 2)) + "+") -ForegroundColor DarkCyan
$afterBox = [Console]::CursorTop

$lastShown = "`0"
$flavDelay = 1.0

$barWidth  = 40
$spin      = '|/-\'
$start     = Get-Date
$hardCap   = [Math]::Max(20, $est * 2.5)   # absolute safety cap (seconds)
$readySeen = $false
$tick      = 0

# --- Sparse twinkling star field --------------------------------------
# A handful of faint stars drawn ONLY in the empty margins - the side
# gutters left/right of the centered content and the band below the hint
# box - never over the banner, bar or box text. Each has a fixed cell and
# a slow sine phase; per frame it picks a glyph (space / . / + / * ) and a
# brightness (DarkGray -> Gray -> White) so it reads as a gentle twinkle.
# Redrawn each loop tick; because cells are fixed and outside the text
# region, nothing flickers or collides with the UI.
$starGlyphs = @(' ', '.', '.', [char]0x00B7, '+', '*')   # dim..bright ramp
$starField  = New-Object System.Collections.Generic.List[object]
try {
    $conH = 30
    try { $wh = [Console]::WindowHeight; if ($wh -ge 12 -and $wh -le 120) { $conH = $wh } } catch {}
    $rnd = New-Object System.Random

    # Vertical text band to avoid: from the first banner row down past the
    # box base. $barRow is a good top anchor; the box bottom is $afterBox.
    $textTop = [Math]::Max(0, $barRow - 6)
    $textBot = $afterBox + 1

    # Horizontal centered-content span (the box is the widest element).
    $contentL = $boxLeft
    $contentR = $boxLeft + $boxOuter

    # Candidate cells: side gutters (any row) + the band below the box.
    # Keep a 1-col/1-row cushion around the content so stars never touch it.
    $maxRow = [Math]::Min($conH - 2, $afterBox + 8)
    $cells = New-Object System.Collections.Generic.List[object]
    for ($ry = 1; $ry -le $maxRow; $ry++) {
        for ($cx = 1; $cx -lt ($conW - 1); $cx++) {
            $inTextRows = ($ry -ge $textTop -and $ry -le $textBot)
            $inContentCols = ($cx -ge ($contentL - 2) -and $cx -le ($contentR + 2))
            if ($inTextRows -and $inContentCols) { continue }   # protected zone
            if ($ry -gt $textBot -or -not $inContentCols) {
                [void]$cells.Add(@{ X = $cx; Y = $ry })
            }
        }
    }

    # Pick ~9 well-spread stars from the candidate pool. A minimum
    # spacing keeps them from landing right next to each other (which
    # reads as a clump, not stars) while staying fully random otherwise.
    $want = 9
    $minGapSq = 9   # squared cell distance; sqrt(9)=3 cells min. apart
    if ($cells.Count -gt 0) {
        $picked = @{}
        $tries = 0
        while ($starField.Count -lt $want -and $tries -lt 400) {
            $tries++
            $idx = $rnd.Next(0, $cells.Count)
            $cx2 = $cells[$idx].X; $cy2 = $cells[$idx].Y
            $k = "${cx2}_${cy2}"
            if ($picked.ContainsKey($k)) { continue }
            # Reject if too close to an already-placed star. Relax the
            # gap late in the search so a cramped candidate pool can't
            # loop forever and end up with too few stars.
            $gap = if ($tries -lt 320) { $minGapSq } else { 2 }
            $tooClose = $false
            foreach ($st in $starField) {
                $dx = [int]$st.X - [int]$cx2
                $dy = [int]$st.Y - [int]$cy2
                if ((($dx * $dx) + ($dy * $dy)) -lt $gap) { $tooClose = $true; break }
            }
            if ($tooClose) { continue }
            $picked[$k] = $true
            [void]$starField.Add(@{
                X = $cx2; Y = $cy2
                Phase = $rnd.NextDouble() * 6.283
                Speed = 0.5 + $rnd.NextDouble() * 1.1
            })
        }
    }
} catch { $starField.Clear() }

while ($true) {
    if (-not $readySeen -and (Test-Path $readyFlag)) { $readySeen = $true }
    $elapsed = ((Get-Date) - $start).TotalSeconds

    if ($readySeen) {
        $frac = 1.0
    } else {
        # Pace toward 92% over the estimate, then crawl so the bar never
        # sits at full while the Hub is still coming up.
        $frac = $elapsed / $est
        if ($frac -gt 0.92) { $frac = 0.92 }
    }

    $fillN  = [int]($frac * $barWidth)
    $filled = [string][char]0x25CF * $fillN                    # U+25CF large filled circle
    $empty  = [string][char]0x00B7 * ($barWidth - $fillN)      # U+00B7 middle dot
    $pct    = [int]($frac * 100)
    $sp     = $spin[$tick % 4]

    $barText = "[{0}{1}] {2,3}%  {3}  loading" -f $filled, $empty, $pct, $sp
    $barLine = Center-Line $barText $conW
    try { [Console]::SetCursorPosition(0, $barRow) } catch { }
    Write-Host ($barLine.PadRight($conW - 1)) -NoNewline -ForegroundColor Green

    # Hint stays blank for $flavDelay seconds, then types itself out across
    # the two boxed rows (~33 chars/sec) with a blinking caret on the active
    # line. Only repaint when the visible text changes (no flicker).
    if ($elapsed -lt $flavDelay) {
        $rev = 0
    } else {
        $rev = [int](($elapsed - $flavDelay) / 0.03)
    }
    if ($rev -gt $hintFull.Length) { $rev = $hintFull.Length }
    $done = $rev -ge $hintFull.Length
    $len1 = $hl1.Length

    if ($rev -le $len1) {
        $s1 = $hl1.Substring(0, $rev)
        $s2 = ""
        $onLine1 = $true
    } else {
        $s1 = $hl1
        $r2 = $rev - $len1 - 1
        if ($r2 -lt 0) { $r2 = 0 }
        if ($r2 -gt $hl2.Length) { $r2 = $hl2.Length }
        $s2 = $hl2.Substring(0, $r2)
        $onLine1 = $false
    }
    $caret = if ($done) { "" } elseif (($tick % 6) -lt 3) { "_" } else { "" }
    if ($onLine1) { $s1 = $s1 + $caret } else { $s2 = $s2 + $caret }

    # Paint into the box's inner text cells (padded to $bw so old glyphs are
    # cleared). White for line 1, grey for the wrapped continuation.
    $show1 = $s1.PadRight($bw); if ($show1.Length -gt $bw) { $show1 = $show1.Substring(0, $bw) }
    $show2 = $s2.PadRight($bw); if ($show2.Length -gt $bw) { $show2 = $show2.Substring(0, $bw) }
    $key = $show1 + "`n" + $show2
    if ($key -ne $lastShown) {
        $lastShown = $key
        try { [Console]::SetCursorPosition($hintCol, $hRow1) } catch { }
        Write-Host $show1 -NoNewline -ForegroundColor White
        try { [Console]::SetCursorPosition($hintCol, $hRow2) } catch { }
        Write-Host $show2 -NoNewline -ForegroundColor Gray
    }

    # Twinkle: repaint each star cell with its current glyph + brightness.
    if ($starField.Count -gt 0) {
        foreach ($st in $starField) {
            $v = ([Math]::Sin($elapsed * $st.Speed + $st.Phase) + 1) / 2
            $gi = [int]($v * ($starGlyphs.Count - 1))
            if ($gi -lt 0) { $gi = 0 } elseif ($gi -ge $starGlyphs.Count) { $gi = $starGlyphs.Count - 1 }
            $col = if ($v -gt 0.72) { "White" } elseif ($v -gt 0.4) { "Gray" } else { "DarkGray" }
            try {
                [Console]::SetCursorPosition($st.X, $st.Y)
                Write-Host ([string]$starGlyphs[$gi]) -NoNewline -ForegroundColor $col
            } catch {}
        }
    }

    if ($readySeen) { break }
    if ($elapsed -ge $hardCap) { break }
    $tick++
    Start-Sleep -Milliseconds 90
}

# Final 100% bar frame + the hint at full brightness, no caret.
$finalBar = "[{0}] 100%  {1}  ready" -f ([string][char]0x25CF * $barWidth), ([char]0x2605)
try { [Console]::SetCursorPosition(0, $barRow) } catch { }
Write-Host ((Center-Line $finalBar $conW).PadRight($conW - 1)) -NoNewline -ForegroundColor Green

$fq1 = $hl1
$fq2 = $hl2
try { [Console]::SetCursorPosition($hintCol, $hRow1) } catch { }
Write-Host ($fq1.PadRight($bw)) -NoNewline -ForegroundColor White
try { [Console]::SetCursorPosition($hintCol, $hRow2) } catch { }
Write-Host ($fq2.PadRight($bw)) -NoNewline -ForegroundColor Gray

# Drop below the whole thing so the console ends cleanly.
try { [Console]::SetCursorPosition(0, $afterBox) } catch { }
try { [Console]::CursorVisible = $true } catch { }
Write-Host ""
Write-Host ""

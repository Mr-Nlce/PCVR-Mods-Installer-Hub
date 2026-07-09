# Startup splash shown in the launcher console while the Hub loads
# concurrently. Prints a magenta banner (same rule line as the installer
# headers) plus a progress bar that fills toward the last recorded load
# time, then snaps to 100% the moment the Hub signals its window is up.
# A random loading hint fades in (dim -> bright) on its own line under the
# bar; the bar redraws above it in place, so the hint stays put. The
# launcher console closes right after (the batch ends), so nothing
# lingers in the foreground. The Hub runs in its own minimized console.

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
# catalog entries reads high. Bump this when the real number changes.
$tileCount = 187

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
    "Hover VR Ready and it flips to Start in VR. Hit it, the card sweeps you in."
)
$flavor = ($hints | Get-Random) -replace '\{N\}', $tileCount

$ruleLen = 60
$rule    = '=' * $ruleLen
Write-Host ""
Write-Host ("  " + $rule) -ForegroundColor Magenta
Write-Host "    PCVR Mods Installer Hub starts ..." -ForegroundColor White
Write-Host ("  " + $rule) -ForegroundColor Magenta
Write-Host ""

# Bar sits just under the banner. Remember its absolute row so the loop
# can redraw the bar in place while the boxed hint stays put below it.
$barRow = [Console]::CursorTop
Write-Host ""   # bar row (painted in the loop)

# Push the hint box clearly lower than the bar so the two read as
# separate zones (loading up top, the tip framed below).
Write-Host ""   # gap
Write-Host ""   # gap
Write-Host ""   # gap
Write-Host ""   # gap
Write-Host ""   # gap
Write-Host ""   # gap
Write-Host ""   # gap

try { [Console]::CursorVisible = $false } catch { }

# --- Boxed loading hint -----------------------------------------------
# The tip is framed in an ASCII box with "HINT" inset in the top rule and
# wrapped to at most two lines, so the right wall always lines up. The
# frame is drawn ONCE; the loop repaints only the inner text region (from
# $hintCol across $bw chars), so the border never flickers or shifts.
$boxIndent = "    "          # 4 spaces - left edge sits under the bar
$bw        = 54              # inner text width (box outer width = bw + 4)
$hintCol   = $boxIndent.Length + 2   # text starts just past "| "

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

# Draw the static frame: top rule (HINT), blank, two text rows, blank, base.
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
    $filled = '#' * $fillN
    $empty  = '.' * ($barWidth - $fillN)
    $pct    = [int]($frac * 100)
    $sp     = $spin[$tick % 4]

    try { [Console]::SetCursorPosition(0, $barRow) } catch { }
    Write-Host ("    [{0}{1}] {2,3}%  {3}  loading" -f $filled, $empty, $pct, $sp) -NoNewline -ForegroundColor Green

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

    if ($readySeen) { break }
    if ($elapsed -ge $hardCap) { break }
    $tick++
    Start-Sleep -Milliseconds 90
}

# Final 100% bar frame + the hint at full brightness, no caret.
try { [Console]::SetCursorPosition(0, $barRow) } catch { }
Write-Host ("    [{0}] 100%  *  ready  " -f ('#' * $barWidth)) -NoNewline -ForegroundColor Green
try { [Console]::SetCursorPosition($hintCol, $hRow1) } catch { }
Write-Host ($hl1.PadRight($bw)) -NoNewline -ForegroundColor White
try { [Console]::SetCursorPosition($hintCol, $hRow2) } catch { }
Write-Host ($hl2.PadRight($bw)) -NoNewline -ForegroundColor Gray

# Drop below the whole box so the console ends cleanly.
try { [Console]::SetCursorPosition(0, $afterBox) } catch { }
try { [Console]::CursorVisible = $true } catch { }
Write-Host ""
Write-Host ""

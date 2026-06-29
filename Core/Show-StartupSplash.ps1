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
$tileCount = 179

# Loading hints - one is picked at random each launch. Written to be
# confident and accurate: guided installers (never "one click"), only
# Steam/GOG/Epic for detection, nothing that implies the Hub is shaky.
$hints = @(
    "Yes, the banner looks different every launch. You're not imagining it.",
    "The bar jumps to 100% right after 92%. Can you spot the frames?",
    "Now and then the counter button catches a shimmer.",
    "Every card lights up when you look at it. Go on, hover one.",
    "Every installer bows out in magenta. Then the new world is yours.",
    "Twenty-eight banner effects. You get one tonight - lucky dip.",
    "Frosting the glass on every card.",
    "Cutting each card from a single sheet of frosted glass.",
    "Hanging the glass before you walk in.",
    "Slotting the last tile into place.",
    "Polishing portraits until they shine through the frost.",
    "The frost is hand-tuned. You'll notice.",
    "{N} PC VR mods, guides and installers in one place.",
    "The boring setup parts, handled so you don't have to.",
    "More fallbacks than any installer should reasonably need.",
    "Installed in unusual places? If the Hub can't spot it, try Locate Game.",
    "VR Ready or Needs Mod - every card wears its status.",
    "The info pill is one click from the mod's own page.",
    "Your next install is hiding somewhere in Explore.",
    "The Explore page already knows the good stuff that you need.",
    "One window, a whole PC VR toolbox behind it.",
    "Built by one very stubbo... I mean n!ce fan of PC VR.",
    "Made for the headset sitting right next to you.",
    "No exe, nothing compiled. Open code, nothing hidden.",
    "Modding PC VR, minus the spreadsheet.",
    "Orbs, embers, meteors - the banner picks its own mood.",
    "Filter by control type, genre or power in Explore. Your shelf, your rules.",
    "{N} cards, frosted and filed.",
    "Nearly there. Headset within reach.",
    "Can't decide? Hit Shuffle and let the Hub pick for you.",
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

# Reserve three rows - bar, gap, hint - and remember their absolute rows
# so the loop can redraw the bar in place while the hint stays below it.
$barRow = [Console]::CursorTop
Write-Host ""   # bar row
Write-Host ""   # gap row 1
Write-Host ""   # gap row 2
Write-Host ""   # gap row 3
$flavRow = [Console]::CursorTop
Write-Host ""   # hint row

try { [Console]::CursorVisible = $false } catch { }

# The hint waits ~1s (so the bar registers first), then types itself out
# (typewriter) under the bar with a blinking caret and sits there steady.
$lastShown = ''
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

    # Hint stays blank for the first $flavDelay seconds so the user sees the
    # bar first, then types itself out (~33 chars/sec) as a bridge, with a
    # blinking caret. Only redraw when the visible text changes (no flicker).
    if ($elapsed -lt $flavDelay) {
        $shown = ''
    } else {
        $reveal = [int](($elapsed - $flavDelay) / 0.03)
        if ($reveal -gt $flavor.Length) { $reveal = $flavor.Length }
        $done   = $reveal -ge $flavor.Length
        $caret  = if ($done) { ' ' } elseif (($tick % 6) -lt 3) { '_' } else { ' ' }
        $shown  = $flavor.Substring(0, $reveal) + $caret
    }
    if ($shown -ne $lastShown) {
        $lastShown = $shown
        try { [Console]::SetCursorPosition(0, $flavRow) } catch { }
        Write-Host ("    " + $shown) -NoNewline -ForegroundColor Cyan
    }

    if ($readySeen) { break }
    if ($elapsed -ge $hardCap) { break }
    $tick++
    Start-Sleep -Milliseconds 90
}

# Final 100% frame + ensure the hint is at full brightness.
try { [Console]::SetCursorPosition(0, $barRow) } catch { }
Write-Host ("    [{0}] 100%  *  ready  " -f ('#' * $barWidth)) -NoNewline -ForegroundColor Green
try { [Console]::SetCursorPosition(0, $flavRow) } catch { }
Write-Host ("    " + $flavor + " ") -NoNewline -ForegroundColor 'Cyan' 

# Drop below everything so the console ends cleanly.
try { [Console]::SetCursorPosition(0, $flavRow + 1) } catch { }
try { [Console]::CursorVisible = $true } catch { }
Write-Host ""
Write-Host ""

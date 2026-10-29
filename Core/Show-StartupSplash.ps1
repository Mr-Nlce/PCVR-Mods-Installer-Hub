# Startup splash shown in the launcher console while the Hub loads
# concurrently. Prints a magenta banner (same rule line as the installer
# headers) plus a progress bar that fills toward the last recorded load
# time, then snaps to 100% the moment the Hub signals its window is up.
# A random loading hint fades in (dim -> bright) on its own line under the
# bar; the bar redraws above it in place, so the hint stays put. The
# launcher console closes right after (the batch ends), so nothing
# lingers in the foreground. The Hub runs in its own minimized console.

param(
    [Parameter(Mandatory = $true)]
    [string]$HubScript,
    [ValidateRange(1, 300)]
    [int]$StartupTimeoutSeconds = 45
)

# The banner rules, progress circles and star use non-ASCII glyphs
# (U+2550, U+25CF, U+00B7, U+2605). Force UTF-8 output so Windows Terminal
# and conhost render them instead of "?" boxes. Best-effort.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$tempRoot = [string]$env:TEMP
if ([string]::IsNullOrWhiteSpace($tempRoot)) {
    try { $tempRoot = [IO.Path]::GetTempPath() } catch { $tempRoot = $PSScriptRoot }
}
$readyFlag = Join-Path $tempRoot "PCVRHub_ready.flag"
$lastFile  = Join-Path $tempRoot "PCVRHub_lastload.txt"

# Clear any stale ready flag BEFORE this script launches the Hub. Keeping
# both operations under one owner removes the old race where the batch could
# start a fast Hub and the splash would then delete its fresh ready signal.
Remove-Item $readyFlag -Force -ErrorAction SilentlyContinue

$hubProcess = $null
try {
    if (-not (Test-Path -LiteralPath $HubScript -PathType Leaf)) {
        throw "Hub script not found: $HubScript"
    }
    $powerShellExe = Join-Path $PSHOME 'powershell.exe'
    if (-not (Test-Path -LiteralPath $powerShellExe -PathType Leaf)) { $powerShellExe = 'powershell.exe' }
    $hubArguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f ($HubScript -replace '"', '""')
    $hubProcess = Start-Process -FilePath $powerShellExe -ArgumentList $hubArguments -WorkingDirectory (Split-Path -Parent $HubScript) -WindowStyle Minimized -PassThru -ErrorAction Stop
} catch {
    Write-Host ""
    Write-Host "The PCVR Mods Hub could not be started." -ForegroundColor Red
    Write-Host ([string]$_.Exception.Message) -ForegroundColor Yellow
    exit 1
}

# Estimated load time from the last run. Fifteen seconds caps only the progress
# pacing; StartupTimeoutSeconds triggers one internal restart if the window
# has still not become ready. A slow run must never
# make the next progress bar crawl for 20-25 seconds and then disappear at the
# halfway point. Normal history within the supported window still self-tunes.
$est = 12.0
try {
    if (Test-Path $lastFile) {
        $v = [double]((Get-Content $lastFile -Raw).Trim())
        if ($v -ge 2 -and $v -le 15) { $est = $v }
    }
} catch { }

function Get-SplashProgressFraction {
    param(
        [double]$ElapsedSeconds,
        [double]$EstimateSeconds,
        [bool]$Ready
    )
    if ($Ready) { return 1.0 }
    if ($EstimateSeconds -lt 0.5) { $EstimateSeconds = 5.0 }
    if ($ElapsedSeconds -le $EstimateSeconds) {
        # Ease out rather than crawl linearly. At half the estimate the bar is
        # already ~76%, while it still reaches 92% exactly at the estimate.
        $ratio = [Math]::Max(0.0, [Math]::Min(1.0, $ElapsedSeconds / $EstimateSeconds))
        $normalizer = 1.0 - [Math]::Exp(-3.0)
        return [Math]::Max(0.0, [Math]::Min(0.92, 0.92 * ((1.0 - [Math]::Exp(-3.0 * $ratio)) / $normalizer)))
    }

    # Continue moving after 92% instead of freezing there. The tail approaches
    # 99% but cannot claim completion before the WPF window is activated.
    $overrun = $ElapsedSeconds - $EstimateSeconds
    $tailSeconds = [Math]::Max(2.0, $EstimateSeconds * 0.5)
    $tail = 1.0 - [Math]::Exp(-$overrun / $tailSeconds)
    return [Math]::Min(0.99, 0.92 + (0.07 * $tail))
}

# Manually audited real-game count shown in the {N} hints.
# Fixed baseline: 352 distinct games as of 2026-10-26. Call of Duty: Black Ops was individually checked absent from all catalogue groups and adds one. Previous baseline: 349 distinct games as of 2026-10-25. Black & White, Dementium II HD, Tomb Raider Legend and FF7 Remake each add one new title; PC2VR is an alternative for the existing HOTD2 and adds none. Previous baseline: 345 distinct games as of 2026-10-25. Dead Space 2, Balatro and Blood West each add one separately checked new title after the 342-game baseline. GRID (2019), GRID Legends and DiRT 4 previously each added one. Forza Horizon 4 adds
# one game; the GrayHorizon alternatives for FH5/FH6 add no distinct games.
# Dishonored 2 adds one
# distinct game after the 337-game baseline. Far Cry 2 adds one game
# after the prior 336-game baseline. Enshrouded, Vampire:
# The Masquerade - Bloodlines, Vampire Hunters and Hitman: Blood Money add
# four distinct games after the prior 332-game baseline. Modern Warfare 2 Campaign Remastered adds
# one distinct game after the prior 330-game baseline. Rustler and Brutal Legend
# each add one distinct game after the prior 325-game baseline. Alan Wake VR adds one
# distinct original game after the prior 324-game baseline. Spec Ops: The Line VR
# adds one distinct Steam game after the prior 323-game baseline. Project
# Zomboid VR added one after the prior 322-game baseline. Teardown and Journey
# each added one distinct Steam game after the prior 320-game baseline. Beyond: Two Souls,
# Fallout 3 and Fallout: New Vegas each add one distinct game to the prior 317.
# Dark Souls II and Spider-Man Remastered already had Luke Ross entries, so
# they are not counted twice. Pokemon Gen 1, Gen 2 and Pinball count as three.
# Never derive this value from
# catalog tiles, mods, installer routes, depots, legacy entries or tools.
# Increment it by exactly one only when a genuinely new game that has never
# appeared anywhere in the Hub is added and individually confirmed as new.
# 2026-10-28: Blur, Hitman: Contracts, Wreckfest and Wreckfest 2 were individually absent and add four. Ratchet already had a museum entry and adds none.
# 2026-10-28: Aliens versus Predator 2 was individually checked absent from every catalog group; adds one.
$tileCount = 357
# Loading hints - one is picked at random each launch. Written to be
# confident and accurate: guided installers (never "one click"), only
# Steam/GOG/Epic for detection, nothing that implies the Hub is shaky.
$hints = @(
    # --- Controls and search (added 2026-08-13) -----------------
    "Put - before a genre or modder in search to exclude it: try racing -horror.",
    "Exclusions stack: resident -praydog -horror keeps narrowing until only courage remains.",
    "Permanently hidden a modder? Search +name to let their games back onto the shelf.",
    "Type -modder and the search hint can remember that exclusion permanently.",
    "Search shortcuts include roomscale, free, wip and new - useful when names tell only half the story.",
    "Two-word modder names work after a minus too: -luke ross is treated as one exclusion.",
    "Start typing while a game page is open and the Hub returns to the filtered shelf.",
    "Scan installed games checks your PC; it does not install anything.",
    "Hover Scan installed games to reveal Scan on Startup - handy after library changes.",
    "Needs Mod means the base game is here, but its VR mod is not.",
    "Updates shows only VR-ready installs for which a newer mod was found.",
    "State filters need one scan first. Until then, the Hub refuses to invent results.",
    "Motion Controls also includes VR controllers mapped to gamepad input.",
    "Gamepad includes native pads and VR-controller-to-gamepad mappings.",
    "Filters and search combine: Gamepad plus racing -horror is a valid life choice.",
    "Click PC POWER in Explore to switch between Your PC and one Exact Tier.",
    "Gems mark polished, native-feeling VR. Search gem when you want the crown jewels.",
    "The little diamond means Polished Gem, not premium currency. No wallet required.",
    "Open Order and choose Show Gems to browse polished, native-feeling VR picks.",
    "Looking for native-feeling VR? Open Order, then Show Gems, and follow the diamonds.",
    "Sort by Release to chase fresh mods, or Added to Hub to inspect the new arrivals.",
    "Alphabetical, Release or Added to Hub: the shelf now accepts orderly suggestions.",
    "Uninstall Now follows the install receipt. Your saves are not invited to the cleanup.",
    "Changed a mod file yourself? Safe uninstall leaves it behind instead of playing detective.",
    "No ownership proof, no reckless delete button. The Hub prefers caution to confetti.",
    "A vanished Update badge means the installed version was actually acknowledged.",
    "Start in VR is option one. Hunting for mystery batch files is officially a fallback.",
    "Gems sparkle; update badges glow; uninstallers clean. The cards have learned manners.",
    "Power tiers are guidance, not prophecy. Resolution and headset still matter.",
    "GPU comparison reads the adapter name locally, and only after you allow it.",
    "Genre and PC Power filters work together when Explore gets a little too exciting.",
    "Shuffle chooses the featured pick. Midnight horror results are between you and chance.",
    "Show opens the featured mod; Explore all games opens the full library.",
    "Featured banner overstayed its welcome? Close it once or disable it permanently.",
    "Recently Played cards launch too - the shortest road back into the headset.",
    "The question-mark menu holds feedback, Discord, style and shortcut controls.",
    "Report a problem can collect the newest log. No archaeological digging required.",
    "Suggest a VR mod opens a short form, because apparently {N} games are not enough.",
    "Desktop Shortcut in Help can create or remove the Hub shortcut at any time.",
    "Click the Hub glasses to switch the header effect on this page.",
    "Help & feedback lets you change header style and speed; both choices survive a restart.",
    "Each Hub page can keep its own header style. Help & feedback also controls the animation speed.",
    "Switch Hub Style in Help & feedback still changes frosted and classic cards.",
    "Featured banners now have Glass, Glass + frost, Hero and Classic styles in Help & feedback.",
    "Glass keeps the featured game's artwork visible; detail pages blend its edges into the header.",
    "S, M and L change shelf density. They do not negotiate with your GPU.",
    "Card size, style, hidden modders and startup scan choices are remembered.",
    "On supported pages, VR / Flat parks the loader without deleting the mod.",
    "Reinstall Mod reruns that game's guided setup when files need refreshing.",
    "Uninstall Guide names the exact files to remove. Guessing DLLs is not a sport.",
    "Click a screenshot for the large view; click again or press Esc to leave.",
    "Click a command block in a guide to copy it. Typos have been formally uninvited.",
    "Mod Page goes straight to the creator's source for releases, notes and issues.",
    "Get on Steam becomes Open in Steam when the game is already on this PC.",
    "ROOMSCALE means the mod supports walking space. The Hub cannot move the coffee table.",
    "WIP means work in progress: expect rough edges and bring useful bug details.",
    "INSTALLED means the base game was found; VR READY means the mod was verified too.",
    "External Installer cards open the creator's project instead of pretending to bundle it.",
    "Some game pages offer several mod choices. Read the labels before choosing a universe.",
    "A blue prerequisite note tells you what must be installed before the VR mod.",
    "Some depot builds need Steam ownership, not an existing install. The page says which.",
    "Disable Steam Theatre if Steam puts the VR launch on one enormous flat screen.",
    "Locate Game records an unusual folder; Clear forgets it without deleting it.",
    "Hover Update Mod to reveal Start in VR - playing now never forces the update.",
    "Dual-mode games can offer Start Current and Start Depot side by side.",
    "Install Mod runs a Hub guide; Get Installer hands you to the external project.",
    "Optional add-ons wait for the base mod. Even alternate realities respect dependencies.",
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
    "The bar reaches 100% only when the Hub window is ready.",
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
    "{N} games with PC VR mods, guides and installers in one place.",
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
    "{N} games, frosted and filed.",
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
    "Motion controllers posing as a gamepad? They are clearly marked, so you can decide whether they interest you.",
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
    "{N} games. Roll for initiative on your next install.",
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

# --- Aurora splash (truecolor VT renderer) ----------------------------
# Design "D Aurora" with the title and hint styling of "B Warp" from the
# splash mockups (2026-10-25). Needs virtual-terminal processing: Windows
# Terminal always has it; a classic console gets it switched on below via
# an in-memory P/Invoke (Reflection.Emit, NOT Add-Type - Add-Type runs csc
# and writes a temp DLL, see the AppUserModelID note in Window.Layout.ps1).
# Anything unexpected - VT refused, window smaller than 80x27, or
# PCVR_HUB_CLASSIC_SPLASH=1 - keeps the classic 16-colour splash below.
#
# Cost control: the hub loads concurrently, so the splash must stay cheap.
# The aurora sky (12 rows of half-blocks = 24 pixel rows) is rebuilt three
# cell rows per tick, so each row refreshes every ~360 ms; the motion is
# slow enough that this reads as smooth. Everything else is written only
# when it actually changes (bar, status, typed hint, star brightness).
function Enable-SplashVirtualTerminal {
    try {
        $asmName = New-Object System.Reflection.AssemblyName 'PCVRSplashVt'
        $asm = [System.AppDomain]::CurrentDomain.DefineDynamicAssembly($asmName, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
        $mod = $asm.DefineDynamicModule('PCVRSplashVtMod')
        $tb  = $mod.DefineType('PCVRSplashVtNative', [System.Reflection.TypeAttributes]::Public)
        $attr = [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::Static
        $defs = @(
            @('GetStdHandle',   [IntPtr], [Type[]]@([int])),
            @('GetConsoleMode', [bool],   [Type[]]@([IntPtr], [uint32].MakeByRefType())),
            @('SetConsoleMode', [bool],   [Type[]]@([IntPtr], [uint32]))
        )
        foreach ($d in $defs) {
            $m = $tb.DefinePInvokeMethod($d[0], 'kernel32.dll', $attr,
                [System.Reflection.CallingConventions]::Standard, $d[1], $d[2],
                [System.Runtime.InteropServices.CallingConvention]::Winapi,
                [System.Runtime.InteropServices.CharSet]::Auto)
            $m.SetImplementationFlags(($m.GetMethodImplementationFlags() -bor [System.Reflection.MethodImplAttributes]::PreserveSig))
        }
        $native = $tb.CreateType()
        $handle = $native.GetMethod('GetStdHandle').Invoke($null, @(-11))
        $args2 = @($handle, [uint32]0)
        if (-not $native.GetMethod('GetConsoleMode').Invoke($null, $args2)) { return $false }
        $mode = [uint32]$args2[1]
        if (($mode -band 4) -ne 0) { return $true }   # ENABLE_VIRTUAL_TERMINAL_PROCESSING
        return [bool]$native.GetMethod('SetConsoleMode').Invoke($null, @($handle, [uint32]($mode -bor 4)))
    } catch { return $false }
}

function ConvertTo-AuroraRgb([string]$hex) {
    return @([Convert]::ToInt32($hex.Substring(1, 2), 16), [Convert]::ToInt32($hex.Substring(3, 2), 16), [Convert]::ToInt32($hex.Substring(5, 2), 16))
}
function Get-AuroraMix($a, $b, [double]$k) {
    if ($k -lt 0) { $k = 0 } elseif ($k -gt 1) { $k = 1 }
    return @([int]($a[0] + ($b[0] - $a[0]) * $k), [int]($a[1] + ($b[1] - $a[1]) * $k), [int]($a[2] + ($b[2] - $a[2]) * $k))
}
function Get-AuroraRamp($stops, [double]$k) {
    if ($k -lt 0) { $k = 0 } elseif ($k -gt 1) { $k = 1 }
    $n = $stops.Count - 1
    $i = [Math]::Min($n - 1, [int][Math]::Floor($k * $n))
    return Get-AuroraMix $stops[$i] $stops[$i + 1] ($k * $n - $i)
}
function Get-AuroraSgr($rgb, [switch]$Background) {
    $lead = if ($Background) { '48' } else { '38' }
    return ([string][char]27) + '[' + $lead + ';2;' + $rgb[0] + ';' + $rgb[1] + ';' + $rgb[2] + 'm'
}

function Split-AuroraHint([string]$t, [int]$w) {
    if ($t.Length -le $w) { return @($t, "") }
    $idx = $t.LastIndexOf(" ", [Math]::Min($w, $t.Length - 1))
    if ($idx -lt 1) { $idx = $w }
    $a = $t.Substring(0, $idx).TrimEnd()
    $b = $t.Substring($idx).TrimStart()
    if ($b.Length -gt $w) { $b = $b.Substring(0, $w) }
    return @($a, $b)
}

function Initialize-AuroraSplash {
    param([int]$Width, [int]$Height, [string]$HintText, [string]$Style = 'aurora')
    $E = [string][char]27
    $script:AuEsc = $E
    $script:AuW = $Width
    $script:AuH = $Height
    $script:AuN = [string[]](0..255 | ForEach-Object { [string]$_ })
    $script:AuBg = @(12, 12, 12)
    $script:AuTeal = ConvertTo-AuroraRgb '#1de9b6'
    $script:AuViolet = ConvertTo-AuroraRgb '#8a5cff'
    $script:AuPink = ConvertTo-AuroraRgb '#ff3ea5'
    $script:AuCyan = ConvertTo-AuroraRgb '#28e0ff'
    $script:AuSyn = @($script:AuPink, (ConvertTo-AuroraRgb '#b04dff'), $script:AuCyan)
    $script:AuSegStops = @($script:AuTeal, $script:AuViolet, $script:AuPink)

    # Ribbon falloff lookup tables (pixel distance in quarter steps, +-32 px)
    # so the sky loop does a table read instead of Math.Exp per pixel.
    $ribbons = @(@(2.6, 0.9), @(2.2, 0.8), @(1.6, 0.45))
    $tables = @()
    foreach ($rb in $ribbons) {
        $tbl = New-Object double[] 257
        for ($i = 0; $i -lt 257; $i++) {
            $dy = ($i - 128) / 4.0
            $v = [Math]::Exp(-($dy * $dy) / (2 * $rb[0] * $rb[0])) * $rb[1] * 0.34
            if ($dy -gt 0) { $v *= [Math]::Exp(-$dy * 0.15) }
            $tbl[$i] = $v
        }
        $tables += , $tbl
    }
    $script:AuT0 = $tables[0]; $script:AuT1 = $tables[1]; $script:AuT2 = $tables[2]
    $script:AuR = New-Object int[] ($Width * 24)
    $script:AuG = New-Object int[] ($Width * 24)
    $script:AuB = New-Object int[] ($Width * 24)
    $script:AuY1 = New-Object double[] $Width
    $script:AuY2 = New-Object double[] $Width
    $script:AuY3 = New-Object double[] $Width
    $script:AuM  = New-Object double[] $Width
    $script:AuRowCursor = 0
    $script:AuSkyBuilt = $false

    # Title (letter-spaced, magenta -> violet -> cyan) on sky row 6, with
    # hairlines on rows 4 and 8 that fade out toward both ends.
    $title = 'P C V R   M O D S   I N S T A L L E R   H U B'
    $script:AuTitle = $title
    $script:AuTx = [int][Math]::Floor(($Width - $title.Length) / 2)
    $script:AuTitleFg = @()
    for ($i = 0; $i -lt $title.Length; $i++) { $script:AuTitleFg += , (Get-AuroraRamp $script:AuSyn ($i / ($title.Length - 1))) }
    $script:AuLineLen = 56
    $script:AuLx = [int][Math]::Floor(($Width - 56) / 2)
    $script:AuHairTop = ConvertTo-AuroraRgb '#8a4fb0'
    $script:AuHairBot = ConvertTo-AuroraRgb '#2f9fc0'
    # Aurora title: letter-spaced bold text on sky row 6 with short fading
    # hairlines (30 columns) on rows 4 and 8. A text cell can show only ONE
    # background colour, so these cells are flat (average of their two sky
    # pixels). To keep them from standing out, the aurora is smoothed
    # vertically inside the title band (rows 4-8, softer on rows 3 and 9):
    # each cell's two pixels are pulled toward their average, so flat and
    # split cells look alike while colour and motion stay.
    $script:AuOv = New-Object bool[] ($Width * 12)
    for ($i = 0; $i -lt $title.Length; $i++) {
        $x = $script:AuTx + $i
        if ($title[$i] -ne ' ' -and $x -ge 0 -and $x -lt $Width) { $script:AuOv[6 * $Width + $x] = $true }
    }
    $script:AuAurLineLen = 30
    $script:AuAurLx = [int][Math]::Floor(($Width - 30) / 2)
    for ($i = 0; $i -lt 30; $i++) {
        $x = $script:AuAurLx + $i
        if ($x -ge 0 -and $x -lt $Width) { $script:AuOv[4 * $Width + $x] = $true; $script:AuOv[8 * $Width + $x] = $true }
    }
    $script:AuSmooth = @(0, 0, 0, 0.45, 0.85, 0.85, 0.85, 0.85, 0.85, 0.45, 0, 0)

    # Bar, status and hint geometry.
    $script:AuSegs = 24
    $script:AuBx = [int][Math]::Floor(($Width - (24 * 2 - 1 + 6)) / 2)
    $script:AuStyle = $Style
    if ($Style -eq 'warp') {
        $script:AuBarRow = 13; $script:AuStatusRow = 15; $script:AuLabelRow = 19
        $script:AuHintRow1 = 21; $script:AuHintRow2 = 22
    } else {
        $script:AuBarRow = 15; $script:AuStatusRow = 17; $script:AuLabelRow = 20
        $script:AuHintRow1 = 22; $script:AuHintRow2 = 23
    }
    $script:AuBarKey = ''
    $script:AuStatusKey = ''
    $script:AuNote = ''
    $wrap = Split-AuroraHint $HintText 60
    $script:AuH1 = [string]$wrap[0]
    $script:AuH2 = [string]$wrap[1]
    $script:AuHx1 = [int][Math]::Floor(($Width - $script:AuH1.Length) / 2)
    $script:AuHx2 = [int][Math]::Floor(($Width - $script:AuH2.Length) / 2)
    $script:AuHintKey = ''
    $script:AuEndRow = if ($Style -eq 'warp') { 25 } else { 26 }

    # Calm stars below the sky: fixed glyph per star, only the brightness
    # breathes (5-9 s period). Kept away from the bar/status band and the hint.
    $script:AuStars = New-Object System.Collections.Generic.List[object]
    $rnd = New-Object System.Random
    $maxRow = [Math]::Min($Height - 2, 28)
    $mid = [int]($Width / 2)
    $tries = 0
    while ($script:AuStars.Count -lt 9 -and $tries -lt 800) {
        $tries++
        $x = 2 + $rnd.Next(0, $Width - 4)
        $y = 13 + $rnd.Next(0, $maxRow - 13 + 1)
        if ($y -ge 14 -and $y -le 18) { continue }
        if ($y -ge 19 -and $y -le 24 -and $x -ge ($mid - 36) -and $x -le ($mid + 36)) { continue }
        $ok = $true
        foreach ($s in $script:AuStars) {
            $dx = ($s.X - $x) * 0.5; $dy = $s.Y - $y
            if (($dx * $dx + $dy * $dy) -lt 12) { $ok = $false; break }
        }
        if (-not $ok) { continue }
        $gr = $rnd.NextDouble(); $tr = $rnd.NextDouble()
        $glyph = if ($gr -lt 0.6) { [string][char]0x00B7 } elseif ($gr -lt 0.88) { '+' } else { '*' }
        $tint = if ($tr -lt 0.7) { '#aab1c9' } elseif ($tr -lt 0.85) { '#ff7ac8' } else { '#6fe6ff' }
        [void]$script:AuStars.Add([pscustomobject]@{ X = $x; Y = $y; G = $glyph; Per = 5 + $rnd.NextDouble() * 4; Ph = $rnd.NextDouble() * 6.283; Tint = (ConvertTo-AuroraRgb $tint); Last = -1 })
    }
    $script:AuMeteorPrev = @()

    # Clear the screen once, hide the cursor and paint the static hint label.
    $label = ([string][char]0x25C6) + '  H I N T  ' + ([string][char]0x25C6)
    $lx = [int][Math]::Floor(($Width - $label.Length) / 2)
    $init = $E + '[0m' + $E + '[2J' + $E + '[3J' + $E + '[?25l' +
            $E + '[' + ($script:AuLabelRow + 1) + ';' + ($lx + 1) + 'H' + (Get-AuroraSgr (Get-AuroraMix $script:AuBg $script:AuPink 0.85)) + $label + $E + '[0m'
    [Console]::Out.Write($init)
    if ($Style -eq 'warp') { Initialize-WarpScene }
    $script:AuClock = [System.Diagnostics.Stopwatch]::StartNew()
}

function Test-AuroraOverlayCell([int]$x, [int]$cr) {
    return $script:AuOv[$cr * $script:AuW + $x]
}

function Get-AuroraCellAverage([int]$x, [int]$cr) {
    $o = ($cr * 2) * $script:AuW + $x; $o2 = $o + $script:AuW
    return @([int](($script:AuR[$o] + $script:AuR[$o2]) / 2), [int](($script:AuG[$o] + $script:AuG[$o2]) / 2), [int](($script:AuB[$o] + $script:AuB[$o2]) / 2))
}

function Add-AuroraSkyRows([System.Text.StringBuilder]$sb, [int]$FirstRow, [int]$Count, [double]$Fade) {
    $W = $script:AuW; $R = $script:AuR; $G = $script:AuG; $B = $script:AuB
    $t0 = $script:AuT0; $t1 = $script:AuT1; $t2 = $script:AuT2
    $Y1 = $script:AuY1; $Y2 = $script:AuY2; $Y3 = $script:AuY3; $M = $script:AuM
    $N = $script:AuN; $E = $script:AuEsc; $Ov = $script:AuOv
    $half = [string][char]0x2580
    for ($cr = $FirstRow; $cr -lt ($FirstRow + $Count) -and $cr -lt 12; $cr++) {
        for ($h = 0; $h -lt 2; $h++) {
            $py = $cr * 2 + $h
            $f = 1.0
            if ($py -gt 18) { $f = (24 - $py) / 6.0 }
            $f = $f * $Fade
            $base = $py * $W
            for ($x = 0; $x -lt $W; $x++) {
                $k = $M[$x] * $f
                $a = $t0[[int](($py - $Y1[$x]) * 4) + 128] * $k
                $b2 = $t1[[int](($py - $Y2[$x]) * 4) + 128] * $k
                $c3 = $t2[[int](($py - $Y3[$x]) * 4) + 128] * $k
                $o = $base + $x
                $R[$o] = [int](12 + 29 * $a + 138 * $b2 + 255 * $c3)
                $G[$o] = [int](12 + 233 * $a + 92 * $b2 + 62 * $c3)
                $B[$o] = [int](12 + 182 * $a + 255 * $b2 + 165 * $c3)
            }
        }
        [void]$sb.Append($E).Append('[').Append($N[$cr + 1]).Append(';1H')
        $lf = -1; $lb = -1
        $top = ($cr * 2) * $W
        $sm = $script:AuSmooth[$cr]
        if ($sm -gt 0) {
            for ($x = 0; $x -lt $W; $x++) {
                $o = $top + $x; $o2 = $o + $W
                $ar = ($R[$o] + $R[$o2]) / 2.0; $ag = ($G[$o] + $G[$o2]) / 2.0; $ab = ($B[$o] + $B[$o2]) / 2.0
                $R[$o] = [int]($R[$o] + ($ar - $R[$o]) * $sm); $R[$o2] = [int]($R[$o2] + ($ar - $R[$o2]) * $sm)
                $G[$o] = [int]($G[$o] + ($ag - $G[$o]) * $sm); $G[$o2] = [int]($G[$o2] + ($ag - $G[$o2]) * $sm)
                $B[$o] = [int]($B[$o] + ($ab - $B[$o]) * $sm); $B[$o2] = [int]($B[$o2] + ($ab - $B[$o2]) * $sm)
            }
        }
        for ($x = 0; $x -lt $W; $x++) {
            $o = $top + $x; $o2 = $o + $W
            if ($Ov[$cr * $W + $x]) {
                $avg = @([int](($R[$o] + $R[$o2]) / 2), [int](($G[$o] + $G[$o2]) / 2), [int](($B[$o] + $B[$o2]) / 2))
                if ($cr -eq 6) {
                    $fg = $script:AuTitleFg[$x - $script:AuTx]
                    [void]$sb.Append($E).Append('[1m').Append((Get-AuroraSgr $fg)).Append((Get-AuroraSgr $avg -Background)).Append($script:AuTitle[$x - $script:AuTx]).Append($E).Append('[22m')
                } else {
                    $mid = ($script:AuAurLineLen - 1) / 2.0
                    $tent = 1 - [Math]::Abs(($x - $script:AuAurLx) - $mid) / $mid
                    $hair = if ($cr -eq 4) { $script:AuHairTop } else { $script:AuHairBot }
                    [void]$sb.Append((Get-AuroraSgr (Get-AuroraMix $avg $hair ($tent * 0.9)))).Append((Get-AuroraSgr $avg -Background)).Append([char]0x2500)
                }
                $lf = -1; $lb = -1
                continue
            }
            $fp = ($R[$o] -shl 16) -bor ($G[$o] -shl 8) -bor $B[$o]
            $bp = ($R[$o2] -shl 16) -bor ($G[$o2] -shl 8) -bor $B[$o2]
            if ($fp -ne $lf -or $bp -ne $lb) {
                [void]$sb.Append($E).Append('[38;2;').Append($N[$R[$o]]).Append(';').Append($N[$G[$o]]).Append(';').Append($N[$B[$o]]).Append(';48;2;').Append($N[$R[$o2]]).Append(';').Append($N[$G[$o2]]).Append(';').Append($N[$B[$o2]]).Append('m')
                $lf = $fp; $lb = $bp
            }
            [void]$sb.Append($half)
        }
        [void]$sb.Append($E).Append('[0m')
    }
}

function Add-AuroraSkyCell([System.Text.StringBuilder]$sb, [int]$x, [int]$cr) {
    $o = ($cr * 2) * $script:AuW + $x; $o2 = $o + $script:AuW
    [void]$sb.Append($script:AuEsc).Append('[').Append($cr + 1).Append(';').Append($x + 1).Append('H')
    [void]$sb.Append((Get-AuroraSgr @($script:AuR[$o], $script:AuG[$o], $script:AuB[$o]))).Append((Get-AuroraSgr @($script:AuR[$o2], $script:AuG[$o2], $script:AuB[$o2]) -Background)).Append([char]0x2580).Append($script:AuEsc).Append('[0m')
}

function Write-AuroraFrame {
    param([double]$Fraction, [bool]$Ready)
    $E = $script:AuEsc
    $T = $script:AuClock.Elapsed.TotalSeconds
    $W = $script:AuW
    $sb = New-Object System.Text.StringBuilder 16384

    if ($script:AuStyle -eq 'warp') {
        Add-WarpScene $sb $T $Fraction
    } else {
        # --- sky: column parameters for this tick, then a slice of rows -----
        for ($x = 0; $x -lt $W; $x++) {
            $script:AuY1[$x] = 9 + 3 * [Math]::Sin($x * 0.07 + $T * 0.35) + 1.5 * [Math]::Sin($x * 0.023 - $T * 0.2)
            $script:AuY2[$x] = 14 + 2.5 * [Math]::Sin($x * 0.05 - $T * 0.28 + 1.3)
            $script:AuY3[$x] = 6 + 2 * [Math]::Sin($x * 0.09 + $T * 0.22 + 2.6)
            $script:AuM[$x]  = 0.55 + 0.45 * [Math]::Sin($x * 0.21 + $T * 0.5 + [Math]::Sin($x * 0.05) * 2)
        }
        # First frame paints the whole sky at full strength in one go (no
        # fade-in, no row-by-row build-up); later frames refresh a slice.
        if (-not $script:AuSkyBuilt) {
            Add-AuroraSkyRows $sb 0 12 1.0
            $script:AuSkyBuilt = $true
        } else {
            Add-AuroraSkyRows $sb $script:AuRowCursor 3 1.0
            $script:AuRowCursor = ($script:AuRowCursor + 3) % 12
        }

        # --- shooting star every 9 s, drawn INTO the sky in half-block pixel
        #     space: one pixel per column (contiguous tail, no gaps), split
        #     between the two neighbouring pixel rows by its fractional height
        #     so it glides instead of stepping. Pixel rows 1-6 = cell rows 0-2,
        #     well above the hairline. Restored from the sky buffer next tick.
        foreach ($c in $script:AuMeteorPrev) { Add-AuroraSkyCell $sb $c[0] $c[1] }
        $script:AuMeteorPrev = @()
        $ph = ($T - 3) % 9
        if ($T -ge 3 -and $ph -lt 1.6) {
            $q = $ph / 1.6
            $hx = 8 + $q * 90
            $hpy = 1.2 + $q * 4.5
            $slope = 4.5 / 90.0
            $fio = [Math]::Sin($q * [Math]::PI)
            $tail = 16
            $cells = @{}
            $hxi = [int][Math]::Round($hx)
            for ($j = 0; $j -le $tail; $j++) {
                $mx = $hxi - $j
                if ($mx -lt 0 -or $mx -ge $W) { continue }
                $py = $hpy - $j * $slope
                $amt = if ($j -le 1) { $fio } else { $fio * [Math]::Pow(1 - $j / ($tail + 1.0), 1.5) * 0.85 }
                $p0 = [int][Math]::Floor($py); $fr = $py - $p0
                foreach ($pp in @(@($p0, (1 - $fr)), @(($p0 + 1), $fr))) {
                    $pyy = [int]$pp[0]
                    if ($pyy -lt 0 -or $pyy -ge 8) { continue }
                    $key = "$mx,$([int][Math]::Floor($pyy / 2))"
                    if (-not $cells.ContainsKey($key)) { $cells[$key] = @($mx, [int][Math]::Floor($pyy / 2), 0.0, 0.0) }
                    $slot = if (($pyy % 2) -eq 0) { 2 } else { 3 }
                    $cells[$key][$slot] = [Math]::Min(1.0, $cells[$key][$slot] + $amt * $pp[1])
                }
            }
            $glow = @(225, 242, 255)
            foreach ($c in $cells.Values) {
                $mx = $c[0]; $my = $c[1]
                if (Test-AuroraOverlayCell $mx $my) { continue }
                $o = ($my * 2) * $W + $mx; $o2 = $o + $W
                $topC = Get-AuroraMix @($script:AuR[$o], $script:AuG[$o], $script:AuB[$o]) $glow $c[2]
                $botC = Get-AuroraMix @($script:AuR[$o2], $script:AuG[$o2], $script:AuB[$o2]) $glow $c[3]
                [void]$sb.Append($E).Append('[').Append($my + 1).Append(';').Append($mx + 1).Append('H')
                [void]$sb.Append((Get-AuroraSgr $topC)).Append((Get-AuroraSgr $botC -Background)).Append([char]0x2580).Append($E).Append('[0m')
                $script:AuMeteorPrev += , @($mx, $my)
            }
        }

        # --- stars: write only when the quantised brightness changes --------
        foreach ($s in $script:AuStars) {
            $v = ([Math]::Sin($T * 6.283 / $s.Per + $s.Ph) + 1) / 2
            $lvl = [int]($v * $v * 15)
            if ($lvl -ne $s.Last) {
                $s.Last = $lvl
                [void]$sb.Append($E).Append('[').Append($s.Y + 1).Append(';').Append($s.X + 1).Append('H')
                [void]$sb.Append((Get-AuroraSgr (Get-AuroraMix $script:AuBg $s.Tint (0.1 + 0.85 * $lvl / 15.0)))).Append($s.G).Append($E).Append('[0m')
            }
        }

        # --- segmented bar + percent ------------------------------------------
        $segs = $script:AuSegs
        $n = $Fraction * $segs; $nf = [int][Math]::Floor($n)
        $pct = [int][Math]::Floor($Fraction * 100)
        $barKey = "$nf|$([int](($n - $nf) * 8))|$pct"
        if ($barKey -ne $script:AuBarKey) {
            $script:AuBarKey = $barKey
            $dim = @(30, 30, 40)
            [void]$sb.Append($E).Append('[').Append($script:AuBarRow + 1).Append(';').Append($script:AuBx + 1).Append('H')
            for ($i = 0; $i -lt $segs; $i++) {
                $col = Get-AuroraRamp $script:AuSegStops ($i / ($segs - 1))
                $c = if ($i -lt $nf) { $col } elseif ($i -eq $nf) { Get-AuroraMix $dim $col ($n - $nf) } else { $dim }
                [void]$sb.Append((Get-AuroraSgr $c)).Append([char]0x25A0)
                if ($i -lt ($segs - 1)) { [void]$sb.Append(' ') }
            }
            [void]$sb.Append('  ').Append((Get-AuroraSgr @(232, 232, 242))).Append(('{0,3}%' -f $pct)).Append($E).Append('[0m')
        }
    }

    # --- status line (also carries restart / slow-start notes) ----------
    if ($Ready) { $status = 'ready  ' + [char]0x2713; $sc = if ($script:AuStyle -eq 'warp') { $script:AuCyan } else { $script:AuTeal } }
    elseif ($script:AuNote) { $status = $script:AuNote; $sc = @(249, 241, 165) }
    else { $d = [int][Math]::Floor($T * 2) % 4; $status = 'loading' + ('.' * $d) + (' ' * (3 - $d)); $sc = @(106, 111, 130) }
    $statusKey = $status
    if ($statusKey -ne $script:AuStatusKey) {
        $script:AuStatusKey = $statusKey
        $sx = [int][Math]::Floor(($W - [Math]::Max(10, $status.Length)) / 2)
        [void]$sb.Append($E).Append('[').Append($script:AuStatusRow + 1).Append(';1H').Append($E).Append('[2K')
        [void]$sb.Append($E).Append('[').Append($script:AuStatusRow + 1).Append(';').Append($sx + 1).Append('H').Append((Get-AuroraSgr $sc)).Append($status).Append($E).Append('[0m')
    }

    # --- typed hint, centred on its final position, blinking caret ------
    $l1 = $script:AuH1; $l2 = $script:AuH2
    $full = if ($l2) { $l1.Length + 1 + $l2.Length } else { $l1.Length }
    $rev = if ($T -lt 1.0) { 0 } else { [Math]::Min($full, [int][Math]::Floor(($T - 1.0) / 0.03)) }
    if ($Ready) { $rev = $full }
    if ($rev -le $l1.Length) { $s1 = $l1.Substring(0, $rev); $s2 = ''; $on1 = $true }
    else { $s1 = $l1; $s2 = $l2.Substring(0, [Math]::Max(0, [Math]::Min($l2.Length, $rev - $l1.Length - 1))); $on1 = $false }
    $caretOn = ($rev -lt $full) -and (($T % 1.0) -lt 0.5)
    $hintKey = "$rev|$caretOn"
    if ($hintKey -ne $script:AuHintKey) {
        $script:AuHintKey = $hintKey
        $caret = (Get-AuroraSgr $script:AuPink) + [char]0x258C
        [void]$sb.Append($E).Append('[').Append($script:AuHintRow1 + 1).Append(';').Append($script:AuHx1 + 1).Append('H').Append((Get-AuroraSgr @(236, 236, 244))).Append($s1)
        if ($on1 -and $caretOn) { [void]$sb.Append($caret) } else { [void]$sb.Append(' ') }
        if ($l2) {
            [void]$sb.Append($E).Append('[').Append($script:AuHintRow2 + 1).Append(';').Append($script:AuHx2 + 1).Append('H').Append((Get-AuroraSgr @(169, 163, 196))).Append($s2)
            if ((-not $on1) -and $caretOn) { [void]$sb.Append($caret) } else { [void]$sb.Append(' ') }
        }
        [void]$sb.Append($E).Append('[0m')
    }

    [Console]::Out.Write($sb.ToString())
}

# --- Warp scene (style "B Warp" from the mockups) ---------------------
# Stars stream slowly outward from the centre (6-12 s per flight, depth
# brightens them), drawn only outside the title / bar / hint zones. Each
# tick only cells whose glyph or brightness changed are written, and cells
# a star has left are blanked. Title and hairlines are static (drawn once).
function Initialize-WarpScene {
    $E = $script:AuEsc; $W = $script:AuW; $H = $script:AuH
    $mid = [int][Math]::Floor($W / 2)
    $script:WpAvoid = @(@(($mid - 37), 3, ($mid + 37), 9), @(($mid - 29), 12, ($mid + 29), 16), @(($mid - 41), 18, ($mid + 41), 23))
    $script:WpCx = $W / 2.0
    $script:WpCy = [Math]::Floor($H / 2.0) - 1
    $script:WpRx = $W / 2.0 + 8
    $script:WpRy = $H / 2.0 + 3
    $script:WpMaxRow = $H - 2
    $script:WpPrev = @{}
    $script:WpStars = New-Object System.Collections.Generic.List[object]
    $rnd = New-Object System.Random
    $tints = @(@(195, 201, 227), @(255, 122, 200), @(111, 230, 255))
    for ($i = 0; $i -lt 70; $i++) {
        $th = $rnd.NextDouble() * 6.283; $tr = $rnd.NextDouble()
        $tint = if ($tr -lt 0.75) { $tints[0] } elseif ($tr -lt 0.88) { $tints[1] } else { $tints[2] }
        [void]$script:WpStars.Add([pscustomobject]@{ Cos = [Math]::Cos($th); Sin = [Math]::Sin($th); V = 0.08 + $rnd.NextDouble() * 0.08; Ph = $rnd.NextDouble(); Tint = $tint })
    }
    # Static title (letter-spaced, magenta -> violet -> cyan) and hairlines.
    $sb = New-Object System.Text.StringBuilder 4096
    [void]$sb.Append($E).Append('[7;').Append($script:AuTx + 1).Append('H')
    for ($i = 0; $i -lt $script:AuTitle.Length; $i++) {
        [void]$sb.Append((Get-AuroraSgr $script:AuTitleFg[$i])).Append($script:AuTitle[$i])
    }
    $L = $script:AuLineLen; $midL = ($L - 1) / 2.0
    foreach ($row in @(@(5, $script:AuHairTop), @(9, $script:AuHairBot))) {
        [void]$sb.Append($E).Append('[').Append($row[0]).Append(';').Append($script:AuLx + 1).Append('H')
        for ($j = 0; $j -lt $L; $j++) {
            $tent = 1 - [Math]::Abs($j - $midL) / $midL
            [void]$sb.Append((Get-AuroraSgr (Get-AuroraMix $script:AuBg $row[1] ($tent * 0.9)))).Append([char]0x2500)
        }
    }
    [void]$sb.Append($E).Append('[0m')
    [Console]::Out.Write($sb.ToString())
}

function Add-WarpScene([System.Text.StringBuilder]$sb, [double]$T, [double]$Fraction) {
    $E = $script:AuEsc; $W = $script:AuW
    $cx = $script:WpCx; $cy = $script:WpCy; $rx = $script:WpRx; $ry = $script:WpRy
    $avoid = $script:WpAvoid; $maxRow = $script:WpMaxRow
    $dot = [string][char]0x00B7
    $now = @{}
    foreach ($s in $script:WpStars) {
        $d = ($T * $s.V + $s.Ph) % 1.0
        $dd = [Math]::Pow($d, 1.7)
        $x = [int][Math]::Round($cx + $s.Cos * $dd * $rx)
        $y = [int][Math]::Round($cy + $s.Sin * $dd * $ry)
        if ($x -lt 0 -or $x -ge $W -or $y -lt 0 -or $y -gt $maxRow) { continue }
        $blocked = $false
        foreach ($r in $avoid) { if ($x -ge $r[0] -and $x -le $r[2] -and $y -ge $r[1] -and $y -le $r[3]) { $blocked = $true; break } }
        if ($blocked) { continue }
        $g = if ($dd -lt 0.4) { $dot } elseif ($dd -lt 0.8) { '+' } else { '*' }
        $lvl = [int]([Math]::Min(1.0, $dd * 1.8) * 15)
        if ($lvl -lt 1) { continue }
        $now[$y * $W + $x] = @($x, $y, $g, $lvl, $s.Tint)
    }
    foreach ($k in $script:WpPrev.Keys) {
        if (-not $now.ContainsKey($k)) {
            $c = $script:WpPrev[$k]
            [void]$sb.Append($E).Append('[').Append($c[1] + 1).Append(';').Append($c[0] + 1).Append('H ')
        }
    }
    foreach ($k in $now.Keys) {
        $c = $now[$k]
        if ($script:WpPrev.ContainsKey($k)) {
            $p = $script:WpPrev[$k]
            if ($p[2] -eq $c[2] -and $p[3] -eq $c[3] -and [object]::ReferenceEquals($p[4], $c[4])) { continue }
        }
        [void]$sb.Append($E).Append('[').Append($c[1] + 1).Append(';').Append($c[0] + 1).Append('H')
        [void]$sb.Append((Get-AuroraSgr (Get-AuroraMix $script:AuBg $c[4] ($c[3] / 15.0 * 0.9)))).Append($c[2]).Append($E).Append('[0m')
    }
    $script:WpPrev = $now

    # Smooth bar: full cells plus one eighth-block cell for sub-cell progress.
    $bw = 46
    $bx = [int][Math]::Floor(($W - ($bw + 6)) / 2)
    $n = $Fraction * $bw; $nf = [int][Math]::Floor($n); $f8 = [int][Math]::Floor(($n - $nf) * 8)
    $pct = [int][Math]::Floor($Fraction * 100)
    $barKey = "$nf|$f8|$pct"
    if ($barKey -ne $script:AuBarKey) {
        $script:AuBarKey = $barKey
        $track = @(26, 26, 36)
        $eighths = [string][char]0x258F + [char]0x258E + [char]0x258D + [char]0x258C + [char]0x258B + [char]0x258A + [char]0x2589
        $stops = @($script:AuCyan, @(122, 108, 255), $script:AuPink)
        [void]$sb.Append($E).Append('[').Append($script:AuBarRow + 1).Append(';').Append($bx + 1).Append('H')
        for ($b = 0; $b -lt $bw; $b++) {
            $col = Get-AuroraRamp $stops ($b / ($bw - 1))
            if ($b -lt $nf) { [void]$sb.Append((Get-AuroraSgr $col)).Append([char]0x2588) }
            elseif ($b -eq $nf -and $f8 -gt 0) { [void]$sb.Append((Get-AuroraSgr $col)).Append((Get-AuroraSgr $track -Background)).Append($eighths[$f8 - 1]).Append($E).Append('[49m') }
            else { [void]$sb.Append((Get-AuroraSgr $track)).Append([char]0x2588) }
        }
        [void]$sb.Append('  ').Append((Get-AuroraSgr @(232, 232, 242))).Append(('{0,3}%' -f $pct)).Append($E).Append('[0m')
    }
}

function Complete-AuroraSplash {
    $E = $script:AuEsc
    [Console]::Out.Write($E + '[0m' + $E + '[' + ($script:AuEndRow + 1) + ';1H' + $E + '[?25h')
}

$useAurora = $false
if ($env:PCVR_HUB_CLASSIC_SPLASH -ne '1') {
    try {
        $auW = [Console]::WindowWidth
        $auH = [Console]::WindowHeight
        if ($auW -ge 80 -and $auW -le 400 -and $auH -ge 27) {
            $vtOk = Enable-SplashVirtualTerminal
            if ($vtOk -or $env:WT_SESSION) {
                # Warp is the everyday splash; the aurora is a rare "shiny"
                # (1 launch in 5). PCVR_HUB_SPLASH_STYLE=warp|aurora forces
                # one style for testing; any other value keeps the roll.
                $forced = ([string]$env:PCVR_HUB_SPLASH_STYLE).Trim().ToLowerInvariant()
                if ($forced -eq 'warp' -or $forced -eq 'aurora') { $auStyle = $forced }
                elseif ((Get-Random -Minimum 0 -Maximum 100) -lt 20) { $auStyle = 'aurora' }
                else { $auStyle = 'warp' }
                Initialize-AuroraSplash -Width $auW -Height $auH -HintText $flavor -Style $auStyle
                $useAurora = $true
            }
        }
    } catch {
        $useAurora = $false
        try { [Console]::Out.Write(([string][char]27) + '[0m' + ([string][char]27) + '[2J' + ([string][char]27) + '[H') } catch { }
    }
}

# Restart / slow-start notes: a status line in the aurora splash, plain
# lines in the classic one (where they print below the frame).
function Write-SplashNote([string]$Text, [string]$Color = 'Yellow') {
    if ($useAurora) { $script:AuNote = $Text }
    else { Write-Host ""; Write-Host $Text -ForegroundColor $Color }
}

if (-not $useAurora) {
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
}

$lastShown = "`0"
$flavDelay = 1.0

$barWidth  = 40
$spin      = '|/-\'
$start     = Get-Date
$readySeen = $false
$hubFailed = $false
$hubRestarted = $false
$slowNoticeShown = $false
$tick      = 0

$starField = New-Object System.Collections.Generic.List[object]
if (-not $useAurora) {
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
}

while ($true) {
    if (-not $readySeen -and (Test-Path $readyFlag)) { $readySeen = $true }
    $elapsed = ((Get-Date) - $start).TotalSeconds

    if (-not $readySeen -and $hubProcess -and $hubProcess.HasExited) {
        # Allow a final filesystem refresh in case the flag write and process
        # exit happened almost together; otherwise report a real failed start.
        Start-Sleep -Milliseconds 100
        if (Test-Path $readyFlag) { $readySeen = $true } else { $hubFailed = $true }
    }

    if (-not $readySeen -and -not $hubFailed -and -not $hubRestarted -and $elapsed -ge $StartupTimeoutSeconds) {
        # Recheck the signal at the boundary. If the first child really is
        # ready, never kill it merely because the splash saw a slow frame.
        if (Test-Path $readyFlag) {
            $readySeen = $true
        } else {
            $hubRestarted = $true
            Write-SplashNote "Restarting Hub startup after a long wait..."
            # Preserve the first process's last completed startup phase before
            # the second attempt replaces the rolling diagnostic file.
            try {
                $phaseLog = Join-Path $tempRoot 'PCVRHub_startup-current.log'
                if (Test-Path -LiteralPath $phaseLog -PathType Leaf) {
                    Copy-Item -LiteralPath $phaseLog -Destination (Join-Path $tempRoot 'PCVRHub_startup-restarted.log') -Force -ErrorAction Stop
                }
            } catch { }
            $oldHubProcess = $hubProcess
            try {
                Stop-Process -Id $oldHubProcess.Id -Force -ErrorAction Stop
                [void]$oldHubProcess.WaitForExit(5000)
            } catch { }
            if ($oldHubProcess.HasExited) {
                # The stale first attempt cannot be allowed to hand its
                # ready flag to the replacement process.
                Remove-Item $readyFlag -Force -ErrorAction SilentlyContinue
                try {
                    $hubProcess = Start-Process -FilePath $powerShellExe -ArgumentList $hubArguments -WorkingDirectory (Split-Path -Parent $HubScript) -WindowStyle Minimized -PassThru -ErrorAction Stop
                    $start = Get-Date
                    $elapsed = 0
                    $est = 12.0
                    $tick = 0
                } catch {
                    Write-SplashNote ("Hub restart could not start: {0}" -f $_.Exception.Message) 'Red'
                    $hubFailed = $true
                }
            } else {
                # Do not open a second Hub if the first cannot be stopped.
                Write-SplashNote "The first Hub is still loading; waiting for its window."
            }
        }
    }
    if ($hubRestarted -and -not $readySeen -and -not $hubFailed -and -not $slowNoticeShown -and $elapsed -ge $StartupTimeoutSeconds) {
        $slowNoticeShown = $true
        Write-SplashNote "The Hub is taking longer than usual. Waiting for its window."
    }

    $frac = Get-SplashProgressFraction -ElapsedSeconds $elapsed -EstimateSeconds $est -Ready $readySeen

    if ($useAurora) {
        try { Write-AuroraFrame -Fraction $frac -Ready $readySeen } catch { }
    } else {

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
    }

    if ($readySeen) { break }
    if ($hubFailed) { break }
    $tick++
    Start-Sleep -Milliseconds 90
}

if ($hubFailed) {
    if ($useAurora) { try { Complete-AuroraSplash } catch { } }
    else { try { [Console]::SetCursorPosition(0, $afterBox) } catch { } }
    try { [Console]::CursorVisible = $true } catch { }
    Write-Host ""
    Write-Host "The Hub closed before its window became ready." -ForegroundColor Red
    Write-Host "Open Core\Logs from Help & Feedback after the next successful start." -ForegroundColor Yellow
    exit 1
}

if ($useAurora) {
    # Final aurora frame: full bar, "ready", hint complete; then reset the
    # terminal colours and park the cursor under the layout.
    try { Write-AuroraFrame -Fraction 1.0 -Ready $true } catch { }
    try { Complete-AuroraSplash } catch { }
    Write-Host ""
    exit 0
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

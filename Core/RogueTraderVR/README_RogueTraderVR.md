# Warhammer 40,000: Rogue Trader VR Mod Installer

Automated installer for RTVR by SolemnScribe - true stereo-3D VR for
Owlcat's Warhammer 40K cRPG. Seated play with keyboard & mouse or
gamepad; the game's UI lives on a floating panel in front of you.
No motion controllers.

## What it does
1. Locates your Rogue Trader install (Steam, GOG, Epic or Xbox - for
   information only; the mods do NOT go into the game folder)
2. Verifies the game has been launched once, so Owlcat's BUILT-IN
   Unity Mod Manager profile folder exists
3. Guides you through the Nexus downloads (Nexus requires a login,
   so downloads are manual) and installs, in order:
   - WASD Movement (required)
   - Toy Box (required)
   - RTVR - the VR mod itself
   - Servo-Skull Camera Controls (asked as optional Y/N at the end)
4. Walks you through the four required camera key rebinds

## Where the mods actually live
Rogue Trader ships with its own built-in Unity Mod Manager. It loads
mods ONLY from your user profile - not from the game folder:

    %USERPROFILE%\AppData\LocalLow\Owlcat Games\Warhammer 40000 Rogue Trader\UnityModManager\

Each mod sits in its own subfolder there (RTVR, WASDMovement,
0ToyBox0, ServoSkullCameraControls). To uninstall a mod, delete its
subfolder.

## Requirements
- Windows 10/11
- **Warhammer 40,000: Rogue Trader** (Steam, GOG, Epic or Xbox/Game
  Pass), launched at least once
- SteamVR installed
- A Nexus Mods account (free) to download the mods
- Note on Nexus: after you click MANUAL DOWNLOAD, Nexus shows a
  REQUIREMENTS page listing the mods that file depends on. That is
  expected - this installer sets those up for you. Just click MANUAL
  DOWNLOAD a second time to start the actual download.
- WASD Movement and Toy Box are REQUIRED by RTVR; Servo-Skull Camera
  Controls is optional (3rd-person over-the-shoulder camera - RTVR
  builds on its camera work and they pair well)

## Mod pages
- RTVR: https://www.nexusmods.com/warhammer40kroguetrader/mods/518
- WASD Movement: https://www.nexusmods.com/warhammer40kroguetrader/mods/334
- Toy Box: https://www.nexusmods.com/warhammer40kroguetrader/mods/1
- Servo-Skull Camera Controls: https://www.nexusmods.com/warhammer40kroguetrader/mods/457

## Required key rebinds (one time, in-game)
In Settings -> Controls rebind these four, or the camera will fight
the WASD character movement:
- Rotate camera left -> **[[A]]**
- Rotate camera right -> **[[D]]**
- Pan camera left -> **[[Q]]**
- Pan camera right -> **[[E]]**

## How to play
1. Start SteamVR
2. Launch with **Start in VR** in the Hub, or normally (Steam may warn it is not VR - click OK)
3. Load into a save - VR starts automatically
4. Play seated with keyboard & mouse or a gamepad

## Shortcuts
Every RTVR shortcut is Ctrl+Alt plus a key, so nothing clashes with
the game's own bindings. Changes are live and saved between sessions.

The essentials:
- **[[Ctrl+Alt+V]]:** start/stop VR manually
- **[[Ctrl+F10]]:** open the mod settings overlay (NOT Shift+F10)
- **[[Left Shift]] (hold):** unlock the mouse cursor
- **[[Ctrl+Alt+C]]:** recenter the view - the one you will reach for
  most, whenever "forward" has drifted
- **[[WASD]]:** move the selected character (via WASD Movement; slow /
  normal / fast walking speeds available in its settings)

Framing and panel (live):
- **[[Ctrl+Alt+[ / ]]]:** world scale down / up (diorama vs life-size)
- **[[Ctrl+Alt+- / =]]:** IPD scale down / up (stereo depth comfort)
- **[[Ctrl+Alt+0]]:** reset world and IPD scale
- **[[Ctrl+Alt+, / .]]:** move the UI panel nearer / farther
- **[[Ctrl+Alt+' / ;]]:** make the panel wider / narrower
- **[[Ctrl+Alt+U]]:** hide/show the UI panel entirely

Comfort and misc:
- **[[Ctrl+Alt+W]]:** entity overtips floating in the world vs flat
  on the panel
- **[[Ctrl+Alt+X]]:** show/hide the desktop mirror manually
- **[[Ctrl+Alt+R]]:** toggle head roll (off can feel steadier)
- **[[Ctrl+Alt+P]]:** dump the UI state to the log - press it while a
  bug is on screen and include GameLogFull.txt in your report

## VR tuning tips
- RTVR's render scale ships at **0.75** - raise it toward 1.0 in the
  mod settings (Ctrl+F10) if your GPU has headroom
- The floating UI panel's size and distance are adjustable in the
  mod settings; world scale / IPD scale too if the world feels off
- In the game's own graphics options:
  - Depth of field: OFF (disorienting in a headset)
  - Camera shake: OFF (comfort)
  - SSR: Low or Off (big performance win)
  - FSR: OFF in VR (use RTVR's render scale instead)
  - Anti-aliasing: SMAA over TAA (less smearing in stereo)
  - Shadow quality and particles: Medium is a sensible balance for
    large combats - drop these before sacrificing render scale

## Important notes
- Seated, pancake-style VR: full stereo 3D world, flat UI on a
  floating panel. No motion controller support.
- Known issues (first public release, per the mod page):
  - Screen fades and cutscene letterbox covers render to the
    desktop, not the headset - transitions may pop rather than fade
  - The "Start the Battle" deployment banner sits at panel-center
    instead of the top; it is fully clickable where it sits
  - Space combat, the sector map and other full-screen views play on
    the UI panel rather than in full stereo (by design for now)
- For full-screen menus a desktop mirror appears in the headset
  automatically (see Ctrl+Alt+X under Shortcuts)
- Toy Box is a big tweak toolbox; RTVR only needs it installed. You
  do not have to enable any cheats.
- The settings panel follows the game's language (English plus 10
  bundled translations)

## Support SolemnScribe
SolemnScribe built both RTVR and the Servo-Skull Camera Controls mod
it grew out of. If you enjoy seeing Rogue Trader in true stereo 3D,
consider supporting the work:
- https://www.patreon.com/cw/solemnscribe

>>> By the Emperor's grace, the void awaits, Lord Captain.

# GoldenEye 007 VR

GEVR is a standalone OpenXR beta that brings the complete Nintendo 64 campaign
to PCVR with stereoscopic rendering, 6DoF head tracking and tracked motion
controllers. The Hub installs only the publisher's runtime. No commercial game
data or ROM is included, copied or downloaded.

## About the Game

Experience the iconic 1997 stealth-action classic re-imagined for modern
virtual reality, placing you directly inside the shoes of MI6's top agent.

## Required ROM

You need a legally owned USA GoldenEye 007 ROM. The publisher documents the
commonly named `GoldenEye (U) [!].z64` dump with an exact size of 12,582,912
bytes and SHA-256
`2CDCEC8A9F0CB6E36337F3EE39D8AD105DC8AFA6BA1C02D466E8F5B771F9A162`.
The official starter accepts `.z64`, `.v64` and `.n64`, validates the selected
file and normalizes it locally when required.

The ROM remains on your computer and is never handled by the Hub. On first
launch, `GevrRomStarter.exe` asks you to select it. Its remembered path, ROM
fingerprint, prepared cache and saves live below `%LOCALAPPDATA%\GEVR`.

## Installation folder

The reviewed vr457 release starts fresh installs with hands/arms enabled, Original weather, Classic enemy AI and instant gesture reload. Physical magazine reload and Tactical AI remain experimental options. Change settings in GEVR Settings and choose Apply; saved choices override new defaults. Keep All Weapons off while placing plastique, because the publisher reports repeated explosions. Loading HD textures for the first time can briefly hitch.

Setup proposes `C:\Games\GoldenEye 007 VR`, but you can choose any other full,
writable folder before files are installed. Updates reuse the previously chosen
folder. The original ROM is not an installation target and is never modified.

The Hub installer follows stable GitHub releases automatically. Use it for Hub-managed updates so the installed release and Hub version receipt stay together. The publisher starter also offers Update, but that changes its runtime outside the Hub's ownership record; use the Hub installer when the Hub manages this copy. It verifies the
launcher, ROM starter, OpenXR loader, versioned boot script and complete runtime
before committing the selected path and exact release tag. Historical file
names, sizes and hashes are archive documentation only and never block a later
valid publisher release.

## Starting the game

Activate the OpenXR runtime you want to use, then choose Start in VR in the
Hub. As the second option, use the GoldenEye 007 VR desktop shortcut. Both
route through the Hub-owned `Start-GEVR-Hub.bat`. It loads the complete
versioned publisher boot, keeps the refresh rate following the active OpenXR
runtime and then runs the official `GevrRomStarter.exe`. Every rendering, input
and gameplay setting from the publisher stays intact. Running `Start-GEVR-Hub.bat` yourself
is only a manual fallback. Do not launch `goldeneye.exe` directly.
`Play-on-monitor.bat` is the flatscreen fallback.

The first launch builds a prepared cache from your ROM. Later starts reuse it.
When a new GEVR release changes its ship tag, the starter rebuilds the cache
automatically while retaining the remembered ROM path and saves.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Walk; move the highlighted item while paused |
| [[Right Stick]] | Turn |
| [[Both Stick Clicks]] | Recenter the VR body and view |
| [[Headset / Roomscale]] | Look, lean and move with full 6DoF tracking |
| [[Motion Controllers]] | Aim the held weapon |
| [[Right Trigger]] | Fire the right-hand weapon. |
| [[Left Trigger]] | Fire the left-hand weapon. |
| [[Right Grip]] | Aim down sights; open a nearby door; press the left watch face or swap the hip gun when positioned there. |
| [[Left Grip]] | Aim a left-hand gun, pick up a weapon or mine, or support a two-handed gun. |
| [[Right Stick Click]] or [[Left Stick Click]] | Hold for that hand's weapon wheel; release to choose. |
| [[A]] | Next right-hand weapon. |
| [[X]] | Next left-hand weapon. |
| [[B]] | Use or activate. Gun reload uses the magazine or chest-cross gesture; tank shells auto-load. |
| [[Y]] or [[Left Menu]] | Open the pause watch. |
| [[Tab]] | Pause and open options on the keyboard |

The vr457 package's `docs/CONTROLS.md` is authoritative for current bindings;
older repository documentation may describe previous mappings. Squeeze a loose
weapon to equip it in that hand; a hip grab holsters or draws that hand's gun.
The left-cuff watch picker shows Laser, Magnet and Repel.

## Tested runtimes and refresh rates

The publisher reports testing with a Pimax Crystal Super through SteamVR
OpenXR, the native PimaxXR runtime, and Quest 3 through Virtual Desktop OpenXR.
The current boot follows the headset rate with `GETV_SIMHZ=query` and no longer
pins 90 Hz. The Hub retains a harmless compatibility clear for older fallback
boots, so the active 72, 80, 90 or other supported OpenXR rate remains in
control. Higher rates remain experimental.

## Beta limitations

- vr456.9 adds an MSAA choice and steadier HD-pack handling; vr456.8 smoothed HD texture loading and made Monitor Off blank cleanly rather
  than freeze on the logo. The publisher ZIP remains ROM-free and retains the
  vr452 boot file; on first launch it rebuilds its image cache from your own USA ROM once.

- Occasional crashes can still occur.
- vr452.4 accepts PNG files from an optional picture pack in an `hdtextures`
  folder beside `goldeneye.exe`; the main ZIP contains no HD texture pack.
  Settings can now be saved with Apply, which relaunches the game.
  The monitor can show both eyes, either eye, or no image while VR/XR runs.
  Rockets remain attached to the gun with a flat crosshair.
- vr452.2 added a startup choice for VR, XR or flat mode. Reset defaults is
  available in the options.
- vr451 added the wrist watch, independent hand cycling and holsters, and mines
  that visibly stick to movable props. vr445.2 added playspace movement,
  melee improvements, Janus spawning and walk/run animation fixes.
- The main ZIP follows the active headset rate. Optional publisher 90/120 Hz
  packages are separate troubleshooting variants; the Hub selects the main ZIP.
- Motion smoothing or Virtual Desktop Space Warp may make play appear half
  speed; turn those features off if that happens.
- Some Dam props may pop in and the water can look murky.
- Water-stage horizon artifacts and invisible doors remain upstream issues.
- Holes shot into glass can appear in only one eye.
- After completing a level and returning to the folder screen, starting another
  mission in the same process can place the player in invalid space. Quit the
  game completely and use Start in VR again.

## Support GEVR

[Support GEVR on Patreon](https://www.patreon.com/cw/GEVR)

## Links and credits

- [GEVR project and releases](https://github.com/no6969el/GEVR/releases)
- [VR gameplay](https://youtu.be/z4B0Ceqrf6I)
- Standalone OpenXR beta and ROM starter by no6969el and the contributors
  credited by the project.

For England, James? No. For the headset.

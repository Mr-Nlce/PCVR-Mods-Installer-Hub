# GoldenEye 007 VR

GEVR is a standalone OpenXR beta that brings the complete Nintendo 64 campaign
to PCVR with stereoscopic rendering, 6DoF head tracking and tracked motion
controllers. The Hub installs only the publisher's runtime. No commercial game
data or ROM is included, copied or downloaded.

## About the Game

Experience the iconic 1997 stealth-action classic re-imagined for modern
virtual reality, placing you directly inside the shoes of MI6's top agent.

## Required ROM

You need a legally owned **USA GoldenEye 007 ROM**. The publisher documents the
commonly named `GoldenEye (U) [!].z64` dump with an exact size of **12,582,912
bytes** and SHA-256
`2CDCEC8A9F0CB6E36337F3EE39D8AD105DC8AFA6BA1C02D466E8F5B771F9A162`.
The official starter accepts `.z64`, `.v64` and `.n64`, validates the selected
file and normalizes it locally when required.

The ROM remains on your computer and is never handled by the Hub. On first
launch, `GevrRomStarter.exe` asks you to select it. Its remembered path, ROM
fingerprint, prepared cache and saves live below `%LOCALAPPDATA%\GEVR`.

## Installation folder

Setup proposes `C:\Games\GoldenEye 007 VR`, but you can choose any other full,
writable folder before files are installed. Updates reuse the previously chosen
folder. The original ROM is not an installation target and is never modified.

The installer follows stable GitHub releases automatically. It verifies the
launcher, ROM starter, OpenXR loader, versioned boot script and complete runtime
before committing the selected path and exact release tag. Historical file
names, sizes and hashes are archive documentation only and never block a later
valid publisher release.

## Starting the game

Activate the OpenXR runtime you want to use, then choose **Start in VR** in the
Hub. As the second option, use the **GoldenEye 007 VR** desktop shortcut. Both
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
| [[Trigger]] | Fire |
| [[Grip / Squeeze]] | Aim down sights |
| [[B]] | Reload |
| [[Menu / System]] | Pause and open options |
| [[Tab]] | Pause and open options on the keyboard |

The vr444.1 release notes are authoritative for current bindings; older release
documentation in the repository may describe previous mappings. [[A]] cycles
forward through weapons and the left-controller [[X]] cycles backward.

## Tested runtimes and refresh rates

The publisher reports testing with a Pimax Crystal Super through SteamVR
OpenXR, the native PimaxXR runtime, and Quest 3 through Virtual Desktop OpenXR.
Its vr444.1 boot follows the headset rate with `GETV_SIMHZ=query` and no longer
pins 90 Hz. The Hub retains a harmless compatibility clear for older fallback
boots, so the active 72, 80, 90 or other supported OpenXR rate remains in
control. Higher rates remain experimental.

## Beta limitations

- Occasional crashes can still occur.
- vr444.1 fixes Frigate hostages remaining stuck with their hands up and makes
  game-window focus at launch more reliable.
- Some Dam props may pop in and the water can look murky.
- Water-stage horizon artifacts and invisible doors remain upstream issues.
- Holes shot into glass can appear in only one eye.
- After completing a level and returning to the folder screen, starting another
  mission in the same process can place the player in invalid space. Quit the
  game completely and use **Start in VR** again.

## Uninstall

Use **Uninstall now** on the game page. It removes only unchanged Hub-owned GEVR
runtime files and restores pre-existing collisions. Changed files are preserved
for safety. Your ROM, `%LOCALAPPDATA%\GEVR` cache, saves and unrelated files are
not removed. Delete those user-owned files manually only if you no longer want
them.

## Links and credits

- [GEVR project and releases](https://github.com/no6969el/GEVR/releases)
- [VR gameplay](https://youtu.be/z4B0Ceqrf6I)
- Standalone OpenXR beta and ROM starter by no6969el and the contributors
  credited by the project.

*For England, James? No. For the headset.*

# A Kingdom for Keflings VR

## About the Game

Help the tiny Keflings build a kingdom while playing as a giant. Gather resources,
assign jobs, unlock blueprints and expand the village into a castle. Game Or Die's
PCVR port places that world in front of you as a living tabletop model. Menus,
blueprints and the tech tree appear on a screen in the world.

## What you need

- The Windows PC game. [NinjaBee on itch.io](https://ninjabee.itch.io/a-kingdom-for-keflings)
  provides a free demo installer; a license key purchased there
  unlocks the full game. The VR package contains no game data or license.
- A headset and a 32-bit OpenXR runtime. Virtual Desktop and SteamVR provide
  one. Start the headset software before the game. Without a usable runtime the
  game can still appear flat on the monitor; check the port log for the reason.
- Estimated PC power tier: Basic. Actual headset performance has not been
  measured by the Hub.

## Install through the Hub

1. Install your own licensed Windows game first. If the Hub cannot find it,
   choose its official NinjaBee itch.io page or provide the folder containing
   `A Kingdom for Keflings.exe`. NinjaBee's installer is a free demo;
   the license key from itch.io unlocks the full game.
2. Choose Install Mod. After confirmation, the Hub downloads the latest stable
   [publisher release](https://github.com/GameOrDie007/A-Kingdom-for-Keflings-VR/releases),
   checks the package, and installs its two DLLs beside the game EXE. Its
   maintenance kit goes into the game's `VR` folder. Existing same-name files
   are backed up and tracked; saves and personal settings remain untouched.
3. Start Virtual Desktop, SteamVR or Meta Quest Link with a 32-bit OpenXR
   runtime, then use Start in VR. The Hub records the installed release only
   after the required files are present; later stable releases appear as updates.

The publisher's `SETUP.bat` remains available in the `VR` maintenance folder
for a manual repair. An older publisher-only installation has no Hub ownership
record: use its own `VR\UNINSTALL.bat` to remove that installation, or run the
Hub installer to adopt identical publisher files and begin Hub tracking.

## Controls

The game can also be played with a gamepad. With VR controllers, the right grip
acts as a pointing mouse and the trigger clicks. The game's own highlight shows
what your gaze or pointer will affect.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Head Look]] | Aim at the world target highlighted by the game |
| [[Right Grip]] held | Point at the world, HUD or menus with the grip mouse |
| [[Right Grip]] tap | Open the tech tree |
| [[Right Trigger]] | Click with the grip mouse |
| [[A]] | Select, pick up or put down |
| [[B]] | Cancel; open pause menu when there is nothing to cancel |
| [[X]] | Kick |
| [[Y]] | Remove the held Kefling's hat to assign a new job |
| [[Left Grip]] | Open blueprints |
| [[Left Grip]] + [[Right Grip]] | Recenter menus |
| [[Menu]] | Open What's Next tutorial help |
| [[Menu]] held | Photo mode hides HUD and menus |

To demolish a building, hold [[Right Grip]], point at the fist icon and pull
[[Right Trigger]]. For left-handed controls, set `leftorium = 1` in
`keflings_vr.ini` after the first game run.

## Settings and limits

The first VR launch creates `keflings_vr.ini` beside the game. Its commented
settings include `world_scale`, `menu_size`, `hud_distance`, `menu_height`,
`menu_tilt` and `draw_distance`. The port normally sets the screen resolution
itself. If you change resolution in the game's options, restart once so the
edges of the world render correctly.

The grip-mouse arrow appears only on the menu screen, although pointing beyond
it can still select a highlighted world object. A brief stall may occur when
closing a menu. If the port fails, run `VR\collect-log.bat` and attach the
resulting `keflings-logs` folder to an
[issue on the publisher repository](https://github.com/GameOrDie007/A-Kingdom-for-Keflings-VR/issues).

Uninstall now removes unchanged Hub-owned files and restores any same-name
files backed up before installation. It keeps the licensed game, saves,
personal settings, changed files and unrelated files. For a publisher-only
installation without a Hub ownership record, use `VR\UNINSTALL.bat` instead.

>>> A giant hand in the kingdom is helpful until it starts redecorating.

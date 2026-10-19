# White Knuckle VR

## About the Game

White Knuckle is a first-person speed-climbing game. This mod adds stereoscopic
OpenXR rendering and tracked hand interactions to the Steam game.

## Current and pinned depot

The installer first offers [1] Current, which follows the newest stable
WhiteKnuckleVR release, or [2] Depot, an independent copy of White Knuckle
Beta 0.61e, Steam build 25612096 (App 3195790, depot 3195791, manifest
8160399169790817040). The depot permanently uses WhiteKnuckleVR v1.2.0
and BepInEx 5.4.23.2 x64. Current mod updates never change this depot.
If your installed Steam game still matches the pinned build, setup can copy it;
otherwise it guides the exact Steam Console download. Both game copies may
coexist, with separate Hub launch choices. The depot copy contains its own
`steam_appid.txt` and is kept outside the normal Steam game folder.
An older `C:\Games\White Knuckle VR 24318677` depot is left untouched; option 2
creates or uses the new `C:\Games\White Knuckle VR 25612096` folder.

A full 6DOF VR conversion for White Knuckle, the speed-climbing game by
Dark Machine Games. By kyanite-rock. Stereo rendering, roomscale movement and
gesture-based motion controls - you climb with your hands.

The design decision behind it: every VR interaction feeds the game's
existing physics system as an input. You move exactly as in the flat game;
the only difference is that your hands do the climbing. That is why buffs and
debuffs keep working out of the box, and why no game file is replaced.

## The first launch is flat - that is not a fault

1. Start the game and wait for the main menu. It stays on the monitor: this
   run writes the mod's three config files. Close the game.
2. Start your VR runtime, then launch again. Now it comes up in VR.

## Current v1.2.1 and pinned depot v1.2.0

Current v1.2.1 fixes the VR settings menu offset and physical climbing orientation. The v1.2.0 release brought the VR mod up to date with White Knuckle Beta 0.61e.
The independent depot freezes this game build, v1.2.0 and BepInEx 5.4.23.2;
future Current updates do not change any pinned depot component.
If the current release cannot be checked online, setup offers the official release page and a versioned ZIP from Downloads for confirmation. It does not silently install the depot's older mod into Current.

The following v1.1.4 changes remain part of the current release:

- Wall jumps no longer change direction with headset rotation.
- Standing on moving platforms no longer judders.
- Player rotation can follow moving platforms; turn it off in the in-game VR
  Settings if you prefer the old behavior.

## Requirements

| | |
|---|---|
| Game | White Knuckle on Steam |
| Runtime | any OpenXR headset - tested on Quest 2 |
| Loader | BepInEx 5, x64 - the installer places it. The x86 and IL2CPP builds do not work. |

## Controls

| Button | Action |
|---|---|
| [[Right Grip]] | Grab a handhold |
| [[Right Trigger]] | Interact with buttons and levers; pick up or use items |
| [[A]] | Jump |
| [[B]] | Quick-pocket right; hold to drop an item; cancel in menus |
| [[Right Stick]] | Smooth or snap turn |
| [[Right Stick Click]] | Toggle crouch; hold for pause when toggle crouch is enabled |
| [[Right Menu]] | Gamepad Select |
| [[Left Grip]] | Grab a handhold |
| [[Left Trigger]] | Interact; pick up or use items |
| [[X]] | Inventory; hold for pause when toggle inventory is enabled |
| [[Y]] | Quick-pocket right; hold to drop an item |
| [[Left Stick]] | Walk and strafe; climb unless Gesture Only is selected |
| [[Left Stick Click]] | Sprint |
| [[Left Menu]] | Pause |

On a Valve Index the triggers climb as well as the grips, and [[X]] / [[Y]]
are the A and B buttons of the left controller. The author has no Index and could
not test this.

## Gestures
While gripping a handhold, your hand is the movement stick and your body
moves opposite your arm:

| Move your hand | You go |
|---|---|
| down | up |
| left | right |
| toward your chest | forward |
| away from you | off the handhold |

There is a dead zone around neutral, so small movements do nothing.

- Dyno / wall jump - flick your hand down and release the grip. A diagonal
  launches you opposite the diagonal. Holding with both hands means doing it with
  both, or letting go with one and dynoing with the other.
- Jump - flick both hands upward.
- Sprint - a mock-running motion with your hands.
- Physical crouch - crouch in real life. Resetting your view resets your
  standing height, so seated play works.
- Throw or drop - while gripping, make a throwing motion and release.
- Hand swap - bring your hands together and press both grips. There is no
  button equivalent for this one.

Every gesture can be turned off or retuned in `ModParameters.json`.
`climbMode` decides how climbing works: Either (gestures, stick overrides),
Gesture Only, or Joystick Only for vanilla stick climbing.

## Settings
Pause in-game for the VR settings screen. Three JSON files in `BepInEx/config/`
hold the rest, written on that first flat launch:

| File | What it holds |
|---|---|
| `VRToggle.json` | `activateVR` and `useMotionControls` - the flat/VR switch |
| `WhiteKnuckleVRSettings.json` | the same settings the in-game menu shows |
| `ModParameters.json` | gesture thresholds and tuning |

Since v1.1.4 the plug-in and its OpenXR dependencies live together under
`BepInEx/plugins/WhiteKnuckleVRMod/`. Older v1.0.2 installs used a loose DLL
and put OpenXR files under `White Knuckle_Data`; the installer parks that old
loose plug-in during an update instead of deleting unknown shared files.

Worth knowing from `ModParameters.json`: `reachMultiplier` (6 by default - needed
so your VR reach matches the flat game), `gripScheme` (`auto` uses the trigger on
Index and the grip elsewhere), and the per-gesture on/off switches.

## Known limitations
- Physical item interactions are not implemented. The author planned them and
  ran into major technical hurdles, so the mod shipped without them.
- Held items are 2D sprites. Every item has a 3D model, but those models are
  not animated the way the sprites are - which is part of why physical items were
  held back.
- Multi-pass rendering. The game's custom shaders are not compiled for
  single-pass stereo, so the mod is performance-intensive. Lower `renderScale` in
  the VR settings menu first.
- Valve Index support is written but untested.

## Support the developer
kyanite-rock develops White Knuckle VR. If you enjoy it, you can support the work:

https://buymeacoffee.com/kyaniterock

## Credits
White Knuckle is by Dark Machine Games. The VR mod is by
kyanite-rock, unofficial and not affiliated with the developer.

https://github.com/kyanite-rock/White_Knuckle_VR

Use Uninstall now on the Hub detail page to remove only files tracked by
the selected Current or Depot installation. A pre-existing loader or changed
user file is preserved. The other route and the normal game remain intact.

>>> Your hands are the only thing between you and the drop.

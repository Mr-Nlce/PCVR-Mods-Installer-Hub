# White Knuckle VR

A full **6DOF VR conversion** for **White Knuckle**, the speed-climbing game by
Dark Machine Games. By **kyanite-rock**. Stereo rendering, roomscale movement and
gesture-based motion controls - you climb with your hands.

**The design decision behind it:** every VR interaction feeds the game's
**existing physics system** as an input. You move exactly as in the flat game;
the only difference is that your hands do the climbing. That is why buffs and
debuffs keep working out of the box, and why no game file is replaced.

## The first launch is flat - that is not a fault

1. Start the game and wait for the **main menu**. It stays on the monitor: this
   run writes the mod's three config files. Close the game.
2. Start your VR runtime, then launch again. Now it comes up in VR.

## Requirements

| | |
|---|---|
| Game | **White Knuckle** on Steam |
| Runtime | any **OpenXR** headset - tested on Quest 2 |
| Loader | **BepInEx 5, x64** - the installer places it. The x86 and IL2CPP builds do **not** work. |

## Controls

**Right controller**
- [[Right Grip]] grab a handhold
- [[Right Trigger]] interact with buttons and levers, pick up items, use a held item
- [[A]] jump
- [[B]] quick-pocket right, or cancel in a menu or terminal
- [[Right Stick]] turn - smooth or snap, set in the VR settings menu
- [[Right Stick Click]] toggle crouch
- [[Right Menu]] maps to the gamepad Select button

**Left controller**
- [[Left Grip]] grab a handhold
- [[Left Trigger]] interact, pick up, use a held item
- [[X]] open and close the inventory. **Hold** it for the pause menu.
- [[Y]] quick-pocket left
- [[Left Stick]] walk and strafe - also climbs, unless `climbMode` is Gesture Only
- [[Left Stick Click]] sprint
- [[Left Menu]] pause

**On a Valve Index** the triggers climb as well as the grips, and [[X]] / [[Y]]
are the A and B buttons of the left controller. The author has no Index and could
not test this.

## Gestures
While gripping a handhold, **your hand is the movement stick** and your body
moves opposite your arm:

| Move your hand | You go |
|---|---|
| down | up |
| left | right |
| toward your chest | forward |
| away from you | off the handhold |

There is a dead zone around neutral, so small movements do nothing.

- **Dyno / wall jump** - flick your hand down and release the grip. A diagonal
  launches you opposite the diagonal. Holding with both hands means doing it with
  both, or letting go with one and dynoing with the other.
- **Jump** - flick both hands upward.
- **Sprint** - a mock-running motion with your hands.
- **Physical crouch** - crouch in real life. Resetting your view resets your
  standing height, so seated play works.
- **Throw or drop** - while gripping, make a throwing motion and release.
- **Hand swap** - bring your hands together and press both grips. There is no
  button equivalent for this one.

Every gesture can be turned off or retuned in `ModParameters.json`.
`climbMode` decides how climbing works: **Either** (gestures, stick overrides),
**Gesture Only**, or **Joystick Only** for vanilla stick climbing.

## Settings
Pause in-game for the VR settings screen. Three JSON files in `BepInEx/config/`
hold the rest, written on that first flat launch:

| File | What it holds |
|---|---|
| `VRToggle.json` | `activateVR` and `useMotionControls` - the flat/VR switch |
| `WhiteKnuckleVRSettings.json` | the same settings the in-game menu shows |
| `ModParameters.json` | gesture thresholds and tuning |

Worth knowing from `ModParameters.json`: `reachMultiplier` (6 by default - needed
so your VR reach matches the flat game), `gripScheme` (`auto` uses the trigger on
Index and the grip elsewhere), and the per-gesture on/off switches.

## Known limitations
- **Physical item interactions are not implemented.** The author planned them and
  ran into major technical hurdles, so the mod shipped without them.
- **Held items are 2D sprites.** Every item has a 3D model, but those models are
  not animated the way the sprites are - which is part of why physical items were
  held back.
- **Multi-pass rendering.** The game's custom shaders are not compiled for
  single-pass stereo, so the mod is performance-intensive. Lower `renderScale` in
  the VR settings menu first.
- Valve Index support is written but untested.

## Support the developer
kyanite-rock develops White Knuckle VR. If you enjoy it, you can support the work:

https://buymeacoffee.com/kyaniterock

## Credits
**White Knuckle** is by **Dark Machine Games**. The VR mod is by
**kyanite-rock**, unofficial and not affiliated with the developer.

https://github.com/kyanite-rock/White_Knuckle_VR

>>> Your hands are the only thing between you and the drop.

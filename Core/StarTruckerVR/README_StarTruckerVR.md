# Star Trucker VR Installer

Automated installer for **StarTruckerVR** by Destroyjevski - a native OpenXR VR mod for **Star Trucker** with stereo 3D, full 6DOF head tracking, gaze-based interaction, and VR-compatible menus/HUD. Played on a **gamepad**, just like flat mode. No original game files are overwritten; removing the mod restores the vanilla game.

## What it does
- Downloads the mod from Nexus Mods (free login gated - opens the Files page for you).
- Locates your Star Trucker install (Steam / GOG / Xbox, with a manual paste fallback).
- Merges the mod's `GameFiles` contents into the game root (adds `Mods`, `MelonLoader`, `version.dll`, the two switch `.bat` files, and the OpenXR plugins).

## Requirements
- **Star Trucker** (Steam / GOG / Xbox - Game Pass)
- A PCVR / OpenXR runtime. **Virtual Desktop with VDXR is the only tested setup**; SteamVR and Quest Link may work but are untested.
- **MelonLoader 0.7.3** is bundled with the mod - don't merge it with a different MelonLoader version or the mod may not load.

## How to play
VR is active immediately after install - no batch file needed. Launch with **Start in VR** in the Hub, or through Steam / GOG normally. Set **VDXR** as your OpenXR runtime in the Virtual Desktop Streamer app first.

> **First launch only:** expect a longer startup (several minutes; the window may stay black) while MelonLoader generates IL2CPP helper files. Don't kill it - later launches are much faster.

## Controls
Gamepad, just like flat mode. Tracked motion controllers are not supported.

- **Head aiming** - picking up objects, cockpit controls, and interactions follow your gaze. A small white dot marks the interaction direction; prompts follow the reticle.
- [[R-Stick]] horizontal turns the character or seated view. Vertical camera input is disabled while walking and seated - **look up and down with your head**.
- [[R3]] recenter the view and place the HUD in your current headset direction ( [[F9]] does the same as a keyboard fallback).
- [[LB]] + [[RB]] + [[D-Pad Right]] / [[D-Pad Left]] adjust the world scale live - see below.
- **Seated:** the VR view inherits the truck's full movement and rotation. Walking inside the truck stays upright.
- **EVA:** the helmet interior follows your headset pose.

## World scale
Hold [[LB]] + [[RB]] and tap [[D-Pad Right]] to make the world look smaller, so you feel taller; [[D-Pad Left]] does the opposite. It moves in steps of 0.05 within a range of 0.5 to 2.0, applies straight away, and saves itself - the value is back on the next launch.

The default is **1.45**, which matches the cabin to a normal seated height and puts the cockpit controls comfortably within reach. Set it to **1.0** for the game's original scale.

The value is stored as `PlayerScale` in `UserData\MelonPreferences.cfg` in the game folder and can be edited there too. That file is not part of the mod package, so re-running the installer for a newer build leaves a scale you have dialled in alone.

## Switching VR / Flat
Close the game first (saves are shared - it's the same install):
- To play flat: run **Play in Flat.bat** in the game folder.
- To return to VR: run **Back to VR.bat** there.

## New since v1.1.0
- **Road beacons, gantries and signs render at full distance** again (v1.2.0).
  They used to appear only very close up: those objects go through the game's
  instanced debris system, which did not know about the VR camera. The camera now
  registers through the game's own secondary-camera interface. The author measured
  no performance cost, so the flat-mode draw distance is simply always used.
- **The EVA helmet interior is visible** (v1.2.1). The game sizes the helmet from
  its own flat field of view, so only the top of the visor ever made it into
  frame - and the world-scale change in 1.1.0 made that fragment fold into itself.
  It is now sized for the view you actually have and scales with world scale, so
  the interior and the power and oxygen readouts are there.
- **The truck shows up in the paint shop and workshop** (v1.2.2), and the paint
  and customization lists show their previews.
- **Cockpit monitors no longer stay black** (v1.1.0). Note that monitors refresh
  every second frame by design, and a short delay before a feed appears is the
  game's own monitor boot sequence.
- **Putting a carried object down returns your view to horizontal** (v1.1.1).

## Known limitations
- Virtual Desktop with VDXR is the only tested runtime; SteamVR and Quest Link are untested.
- No tracked motion-controller support (gamepad / KB&M only).
- Minor menu shimmer and small between-eye sunlight/shadow differences can occur.
- Testing concentrated on the early portion of the game; later-game situations are less tested.

## Info
https://www.nexusmods.com/startrucker/mods/17

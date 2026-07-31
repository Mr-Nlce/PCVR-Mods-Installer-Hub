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
- **Seated:** the VR view inherits the truck's full movement and rotation. Walking inside the truck stays upright.
- **EVA:** the helmet interior follows your headset pose.

## Switching VR / Flat
Close the game first (saves are shared - it's the same install):
- To play flat: run **Play in Flat.bat** in the game folder.
- To return to VR: run **Back to VR.bat** there.

## Known limitations
- Virtual Desktop with VDXR is the only tested runtime; SteamVR and Quest Link are untested.
- No tracked motion-controller support (gamepad / KB&M only).
- Minor menu shimmer and small between-eye sunlight/shadow differences can occur.
- Testing concentrated on the early portion of the game; later-game situations are less tested.

## Info
https://www.nexusmods.com/startrucker/mods/17

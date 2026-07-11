# Techtonica VR

VR mod for **Techtonica** by **3_141 (Xenira)**, distributed via Thunderstore. Adds full motion-controller support, 6DoF VR camera, inverse kinematics for the player body, and SteamVR controller bindings for Index Knuckles and Oculus Touch (Quest 3 maps to the Touch bindings).

## Where to get the game

Techtonica is available on Steam: https://store.steampowered.com/app/1457320/Techtonica/

The game is in early access. The VR mod targets game version 0.4.0-c. Future Techtonica updates may break the mod - the mod itself hasn't seen recent activity, so if a Techtonica patch breaks it, the fix will likely come from the modder rather than us.

## What this installer does

1. **Locates Techtonica** in your Steam libraries (or asks you to point at the folder).
2. **Downloads 6 packages from Thunderstore** - all pinned versions:
   - BepInExPack 5.4.2305 (mod loader)
   - PiVRLoader 0.1.1 (VR camera + controllers)
   - TTIK 0.2.2 (inverse kinematics)
   - PiUtils 0.4.0 (shared helpers)
   - Tobey.UnityAudio 2.0.3 (audio patcher for teleport/snap-turn cues)
   - TechtonicaVR 2.0.0 (the VR mod itself)
3. **Merges each package** into the Techtonica folder.

No game files are bundled with this installer - everything is fetched live from Thunderstore.

## Requirements

- Techtonica owned on Steam (or installed via another launcher with the same folder structure).
- SteamVR installed and running.
- An internet connection during install.

## Note

After installation, **restart the game once** before VR activates. The mod loads on second launch — let Techtonica reach the main menu the first time, then close and relaunch. This is documented behavior of the mod, not a bug.

**Updating from an older mod version?** The mod switched to PiVRLoader for most of its VR functionality — re-install the **entire** mod, preferably on a clean game install (verify the game files in Steam first, then run the installer again).

If audio cues for teleport/snap-turn don't play, verify that Tobey.UnityAudio installed correctly (look for `BepInEx\patchers\Tobey\UnityAudio\`).

## Controls

Edit bindings via the SteamVR dashboard -> Controller Bindings -> Techtonica
VR. Default bindings ship for Valve Index (Knuckles) and Oculus Touch (only
the Knuckles bindings are modder-tested).

**Headlamp gestures:** there are two lamps. For the head lamp, move your
right hand on top of your head and press Use [[Right Trigger]]. For the
shoulder lamp, move your right hand next to your right ear and press Use.

## Current state

The mod is playable but in early development — some things are rough.
- **Working:** 6DOF world rendering, head/hand tracking, smooth locomotion
  + turning, comfort options (teleport, snap turn, vignette), haptics, UI,
  IK with co-op support and finger tracking (TTIK)
- **Missing:** gesture support (e.g. pickaxe-motion mining), object outlines
  (shader broken in VR), primary-hand switching
- **Known issues:** haptics play on both controllers rather than the active
  hand; the game is locked to 60 fps (your monitor's refresh) in windowed
  mode — switch to fullscreen to unlock the framerate

## Configuration

Config lives at `BepInEx\config\de.xenira.techtonicavr.cfg` (some options
moved into the Pi VR Loader mod — see its docs). Highlights: smooth-turn
speed (default 90), snap-turn angle (default 30), vignette toggles (on
teleport / smooth locomotion / snap turn), menu spawn distance/scale, and
**Display Body** (default true; false renders hands only). Delete the cfg
(or a single section) to reset to defaults on next launch.

## Disabling without uninstalling

Edit `BepInEx\config\de.xenira.techtonicavr.cfg` and set `Enabled = false` under `[General]`. This switches the game back to flat mode without removing any files.

## Links

- Mod GitHub: https://github.com/Xenira/TechtonicaVR
- Thunderstore: https://thunderstore.io/c/techtonica/p/3_141/TechtonicaVR/
- Modder support (Liberapay): https://liberapay.com/rip3.141

>>> Dig deep. Automate everything. Atropos has secrets.

# Halo 3 MCC VR Installer

Automated installer for **Halo MCC VR** by pancreations - a native OpenXR VR mod for **Halo: The Master Chief Collection** on Steam. In this alpha, **Halo 3 campaign is the tested path**.

> **Early alpha.** ODST, Halo 2/4/Reach, online play, custom games, Forge, and long sessions are not all validated yet. The code was AI-written under a human modder's direction and is public, unaudited, and MIT-licensed. No game files are patched or redistributed - normal Steam launches stay unmodded.

## What it does
- Resolves the newest release from GitHub (**prerelease-aware** - the mod ships alpha pre-releases), so the Hub can flag updates and re-running updates in place.
- Downloads and unpacks the release, locates your MCC install (Steam library / Xbox / Microsoft Store, with a manual drag & drop fallback), copies the two mod files into a `Halo_MCC_VR` folder inside MCC, and creates the **Halo MCC VR** desktop shortcut. No game files are modified.

## What works
- True per-eye stereo and 6DOF head tracking
- Motion-controller input: snap/smooth turning, melee, grenades, menu control
- Controller-driven weapon aim with a floating VR reticle
- Articulated VR arms, with a free left support hand on the shotgun
- Native HUD with the centered flat reticle hidden
- Free picture-quality scale from 0.35 to 2.00 (supersampling above 1.00), set in `halomccvr.cfg` or the in-game F1 menu

## Requirements
- **Windows 10/11 64-bit**
- The **Steam** version of MCC with **Halo 3** installed *(Xbox / MS Store paths are also detected)*
- A working **OpenXR runtime** (SteamVR / Oculus / VDXR)
- No compiler, CMake, or Visual C++ redistributable needed

> **Sign in to MCC in flat once before installing.** At some point before installing the VR mod, launch Halo: The Master Chief Collection normally (flat) and sign in to the Microsoft service, so it's done and out of the way. On that first flat sign-in, if the sign-in box is off-position on the desktop, click the game window and press **Alt+Enter** to re-center it.

## Required MCC settings
Set these in MCC's own menus (you can change them with the headset on, from inside the VR session):

| Setting | Value |
|---|---|
| Settings > Video > Max Frame Rate | **120** |
| Settings > Video > V-Sync | **Off** |
| Halo 3 > Settings > Field of View | **120** |

> **Do not enable FSR** in MCC's video menu - it breaks the VR image scale. Use the mod's picture-quality presets instead. **FOV 120** is the one that visibly breaks the game if wrong: at a lower FOV the engine stops drawing geometry at the edges, so scenery pops in and out in the headset.

## How to play
1. Start **Steam** and **SteamVR** (or your OpenXR runtime).
2. Launch with **Start in VR** in the Hub, or the **Halo MCC VR** desktop shortcut. Only that route loads the mod (with **anti-cheat OFF**); launching MCC from Steam gives the normal, unmodded game.
3. Press [[F1]] in game (click both thumbsticks) for all settings, including picture quality.

> **Never use this in anti-cheat-enabled matchmaking.**

## Controls (motion controllers)
- [[R-Stick]] snap/smooth turn; aiming and weapon control follow the right hand
- [[R3]] re-center the view
- [[L3]] + [[R3]] toggle the HUD
- Click **both thumbsticks** to open the [[F1]] settings menu (customize your VR experience)
- **Pause:** press the two face buttons on the **left** controller together to drop to 2D; press again to resume in VR
- **Vehicles** need sturdy VR legs - you steer by waving your **right hand** (the right aim stick is tied to that hand)
- Quad-view eye tracking is supported; you can hide the IK rig for floaty hands
- Dual-wield crosshair follows the right hand; two-handed weapon hand placement is adjustable

## Known alpha limitations
- Loading any other Halo game breaks the 3D hook - **test Halo 3 first**
- Right-stick click currently clips/hides your character instead of zooming
- Some toggles in the [[F1]] menu are still rough
- All third-person moments (cutscenes, vehicle riding, turrets, flamethrower) stay third-person

## Uninstall
Close MCC completely, then delete the `Halo_MCC_VR` folder inside your MCC install. No game files were changed.

## Safety note
The files are unsigned, so Windows or antivirus may flag them. Do not disable your security software globally - only allow these files if you trust the source. Checksums are published in the release's `BUILD-INFO.txt`.

## Credits
- **Halo MCC VR** by pancreations (a 3D animator; this mod came from a friend's request). The **code is AI-written** under the modder's direction (see the note above); only the visual art uses no generative AI.
- Inspired by **HaloCEVR** by LivingFray and the proof-of-concept **ReclaimerVR** by Nibre
- Halo is a Microsoft trademark; this project is not affiliated with Microsoft or Halo Studios.

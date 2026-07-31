# Dinkum VR Installer

Automated installer for **DinkumVR v1.0.0** by Destroyjevski - a native OpenXR conversion of Dinkum with stereo 3D and full 6DOF head tracking, an optional bodyless first-person mode and large, VR-readable menus. Played on a **gamepad**, just like the flat game.

This is a ground-up build for Dinkum on Unity 6 (URP), not a revival of the old UUVR setup. No original game files are overwritten; removing the mod restores the vanilla game.

## What it installs
- **DinkumVR mod** - stereo 3D rendering with full 6DOF head tracking
- **BepInEx 5 (Mono, x64)** - mod loader, bundled with the mod and tested against this exact version
- Two mode-switch helpers - `Play in Flat.bat` and `Back to VR.bat`

The mod's `GameFiles` contents go into the **game root folder** (the folder that ends up with a `BepInEx` folder and `winhttp.dll` next to `Dinkum.exe`).

## Requirements
- Dinkum owned on **Steam** (App ID 1062520)
- A free **Nexus Mods** account - the mod is distributed on Nexus
- An **OpenXR runtime**: **Virtual Desktop** with **VDXR** is the only tested setup. SteamVR and Quest Link may work but are untested.

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Nexus Mods files page. Log in (free) and download the DinkumVR file.
3. Back in the installer, confirm the file it found in your Downloads folder, or drag the ZIP onto the window.
4. The installer auto-locates Dinkum on Steam and merges the mod's `GameFiles` into the game root.
5. **Launch normally** - VR is active immediately. Dinkum is a Mono game, so there is no long first launch.

## Controls (gamepad)
- [[R3]] switches between two view modes at any time: third person in true stereo, and a bodyless first person
- [[R-Stick]] turns you left/right - look up, down and around with your head
- Menus float on a panel in front of you and are operated with [[R-Stick]] or [[D-Pad]] plus [[A]] / [[B]], exactly like a controller in flat mode
- The view **auto-recenters on every mode switch**. If your seating has drifted, tap [[R3]] twice

## View modes
- **Third person (default)** - the game's own camera, rendered in true stereo with 6DOF head parallax. You see your character and can lean into the scene like a diorama.
- **First person ([[R3]])** - the camera moves to your character's eyes and the body is hidden, including while riding vehicles. Horizontal turning stays on the right stick; the view does not inherit the body's rotation, so strafing does not drag your head along.

## Switching between VR and flat
VR is active right after installation. To switch, close the game and use the **VR / Flat switch button** on this game's page in the Hub - the active mode is highlighted. It uses the mod's own method (renaming the plugin), so the game runs completely vanilla in flat mode.

**Saves are shared** between VR and flat - it is the same installation.

## Configuring the menus
The menus ship deliberately large so they read well through a headset. Every dial sits in `BepInEx\config\dinkumvr.dinkumvr.cfg`:
- **Ui.PanelWidthMeters** (default 4.0) - main size control
- **Ui.PanelDistanceMeters** (default 1.6) - moves the panel closer or further
- **Ui.UiScale** (default 0.6) - zooms the content inside the panel
- **Ui.PanelHeightOffsetMeters** - shifts the panel up or down for seated play

Delete the config file to get the defaults back.

## Known limitations
- Virtual Desktop with VDXR is the only tested runtime; SteamVR and Quest Link are untested.
- No tracked motion controllers - gamepad, keyboard and mouse are the supported input.
- Clouds are camera-facing billboards, so in the default mode they tilt with your head. `Visuals.CloudBillboardMode` in the config offers alternatives that keep the sky put.
- During cut scenes and scripted moments the camera goes where the game wants it.

## Removing the mod
Close the game, then delete the mod files (the `BepInEx\plugins\DinkumVR` folder, the two switch `.bat` files, and the added OpenXR files). The vanilla game is restored. Only remove BepInEx or the OpenXR files if no other mod depends on them.

## Credits & license
- **DinkumVR** by Destroyjevski
- BepInEx 5 (LGPL-2.1), UnityDoorstop (LGPL-2.1), HarmonyX (MIT), MonoMod (MIT), Mono.Cecil (MIT), Unity OpenXR Plugin (Unity Companion License), Khronos OpenXR Loader (Apache-2.0). Full license texts ship with the mod.

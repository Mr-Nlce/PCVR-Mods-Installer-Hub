# Sayonara Wild Hearts VR

A dreamy, music-driven arcade game by Simogo about riding motorcycles, skateboarding, dance battling, shooting lasers, wielding swords, and breaking hearts at 200 mph - now with stereoscopic VR depth and bHaptics vest support. The pop-album video game in VR.

**Mod**: SayonaraWildHearts_VRMod_bHaptics v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Sayonara Wild Hearts (Steam App 1122720)

## About this mod

A community VR mod by Astienth, distributed via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

This is a **depth-only mod** - it adds stereoscopic 3D and bHaptics vest support, but no motion controls. Controls remain gamepad or keyboard. There is no ViGEmBus dependency.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1253317358735327354/1253317358735327354

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading the mod ZIP from the linked Discord post
4. Auto-locating your Sayonara Wild Hearts install (Steam libraries scanned)
5. **Optionally copying the game folder** (recommended) so flat-screen play stays available from the original folder
6. Extracting the mod files into the chosen folder

## Critical heads-up: the mod blocks flat-screen mode

**Installing this mod into a game folder makes that folder VR-only.** Once the mod is installed, the game can no longer be launched flat-screen from the same folder.

That's why the installer offers to make a copy of the game folder first. The default copy lives at:

```
<original-parent>\Sayonara Wild Hearts VR\
```

The original Steam folder stays untouched, so:
- **Steam** keeps launching the flat-screen version from the original folder
- **The VR build** lives in the copy and is launched via the .exe inside that copy (or via the Hub's "Start in VR" button, which targets the copy because the installer records that path)

If you skip the copy step, the mod installs directly into the original Steam folder, and Steam launches the VR build going forward. To get flat-screen back you'd then need to disable the mod (rename `winhttp.dll`) or verify game files via Steam.

## Controls

**Gamepad or keyboard only - no VR controller support.**

Game controls are unchanged from the flat-screen version.

### Recentering the view

- Hold gamepad **START** for a few seconds
- Or press **Esc** on keyboard
- Or use SteamVR's own recenter function

### Seating

A seated experience is recommended.

## bHaptics

**Vest only** is supported. Launch the bHaptics Player and connect the vest before launching the game. The mod connects to the vest automatically.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Uninstall / temporarily disable

Rename `winhttp.dll` in the **modded** game folder to anything else (e.g. `winhttp_bak.dll`). The mod stops loading. If you installed the mod into a copy of the game folder, you can also just delete the copy entirely.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1253317358735327354/1253317358735327354
- Mod download: https://discord.com/channels/1001138422972432597/1253317358735327354/1253317523835981874

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Heartbreak at 200 BPM. Ride the rhythm.

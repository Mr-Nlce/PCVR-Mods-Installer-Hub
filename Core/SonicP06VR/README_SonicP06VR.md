# Sonic P-06 VR

Sonic P-06 (Project '06) is an unofficial, fan-made remake of the notoriously buggy Sonic the Hedgehog (2006), rebuilt in the Unity engine by programmer Ian "ChaosX" Moris to create a polished, high-quality experience. It fixes broken physics, improves graphics with upscaled textures, and enhances controls for all playable characters.

The VR mod by Astienth adds stereoscopic VR rendering on top, with an experimental first-person view option.

**Mod**: Sonic_P-06_VR v1.0.0 - by Astienth, available on the FarmerTrueVR Discord server  
**Game**: Project 06 by ChaosX - free fan-game, hosted on Google Drive (not on Steam)

## How this differs from other Astienth installers

Sonic P-06 is the only Astienth mod where the base game isn't a Steam title. It's a free fan-remake hosted on Google Drive, and the VR mod download is on the FarmerTrueVR Discord server. So this installer has a few more steps than the others:

1. Download the fan-game ZIP from Google Drive
2. Extract it to a folder of your choice (default: `C:\Games\Sonic P-06 VR`)
3. Join the FarmerTrueVR Discord (one-time, if you're not already in)
4. Pick which mod variant you want (standard or upside-down-bug fix)
5. Drop the mod ZIP in
6. Auto-extract the mod + run Astienth's `Apply Patch.bat` once (xdelta3 binary patch on `data.unity3d`)

## What this Hub installer does

Steps in order:

1. **Fan-game ZIP** - tries to auto-download the Project 06 ZIP from Google Drive. Drive shows a virus-scan confirm page on big files, and the installer follows that confirm-token round-trip automatically. If the auto-download fails (token format change, rate limit, network), it falls back to opening the Drive page in your browser so you can grab the ZIP yourself.

2. **Game install location** - extract Project 06 to the default `C:\Games\Sonic P-06 VR`, or pick a custom folder.

3. **Discord onboarding** - join the FarmerTrueVR server and accept the rules (skip if you're already in).

4. **Variant pick** - Standard (try first) or Upside-down-bug fix (use only if the world appears flipped).

5. **Mod ZIP drag-drop** - download the chosen variant from the Discord post and drop the file into the installer window. Filename is soft-checked against your variant pick.

6. **Mod install + patch** - extract the mod files into the game folder, then run Astienth's `VRPatch\Apply Patch.bat` once (binary `data.unity3d` patch via xdelta3 / vcdiff). The patch script needs the working directory set to the `VRPatch` folder, so the installer launches it that way.

## Game download (Google Drive)

- Project 06 - Silver Release (Patch v1.4): https://drive.google.com/file/d/1klUEs43gzyqgnsDT9tlTyxy0WYPzLGde/view

If the in-installer auto-download fails, open the URL above in your browser and grab the ZIP manually.

## Mod download (Discord)

- Mod info / parent post: https://discord.com/channels/1001138422972432597/1267088216456953907/1316306250354524221
- Mod download (standard): https://discord.com/channels/1001138422972432597/1267088216456953907/1271091116195844199

The upside-down-bug fix variant is attached to the same mod post in Discord. Look for the file with `fixupsidedownbug` in the name.

## Controls

**Gamepad or keyboard only - no VR controller support.**

- **F1** or **double-press START** on gamepad - toggle first-person view on/off
- **F2** or **hold START** on gamepad - recenter view

## Heads-up notes from Astienth

- Some in-game graphics settings introduce bugs - try and error to find what works on your rig.
- Reflections render slightly differently per eye - consider turning reflections **OFF** in the graphics menu.
- For performance, lower in-game settings first; if that's not enough, lower the SteamVR resolution. The headset resolution is set by SteamVR, not by the in-game resolution setting.
- First-person view is experimental - tank movement, left stick rotates, forward = accelerate, backward also accelerates (a known bug, won't bother you in practice). **MOTION SICKNESS warning** for first-person mode.
- If the world appears upside down with the standard variant, re-run this installer and pick the upside-down-bug fix variant in step 4.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1267088216456953907/1316306250354524221

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Built by fans, polished with love. Now go fast.

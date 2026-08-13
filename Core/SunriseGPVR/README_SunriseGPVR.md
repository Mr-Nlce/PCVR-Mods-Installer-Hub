# Sunrise GP VR

A nice-looking cell-shaded little racing game brought into VR. Stereoscopic 3D rendering only - the controls stay flat, so you play with a gamepad or keyboard like the base game.

**Mod**: SunriseGP_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Sunrise GP (Steam App 2670800)

## About this mod

A community VR mod for the cell-shaded racer, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

**No VR controller support** - this mod only renders the game in VR. Use a gamepad or keyboard for control input. There is **no ViGEmBus dependency** because no VR-to-Xbox mapping is taking place.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1362074365952528494/1362074365952528494

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `SunriseGP_VR.zip` from the mod channel
4. Auto-locating your Sunrise GP install (Steam libraries scanned)
5. Extracting the mod files into the game folder

No ViGEmBus step - none required.

## Controls

Game controls are unchanged. Use a **gamepad** or **keyboard**. There is no motion-controller support and no VR-specific hotkeys; the mod just renders the racing game in VR with stereoscopic 3D.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Known issues

- Some menu UI glitches: results screens can overlap other menus. The game itself stays playable.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1362074365952528494/1362074365952528494
- Mod download: https://discord.com/channels/1001138422972432597/1362074365952528494/1374354399308283945

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Engines warm. Sun rising. Take pole position.

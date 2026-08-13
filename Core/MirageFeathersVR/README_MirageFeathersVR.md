# Mirage Feathers VR

A pseudo-3D rail shooter inspired by After Burner, Space Harrier, and Hang-On - now with stereoscopic VR depth and bHaptics support. The base game is a chibi anime air-superiority arcade shooter where targets lock to your crosshair and your ammo is infinite.

**Mod**: MirageFeathers_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Mirage Feathers (Steam App 2719060) - Demo and Full game both supported

## About this mod

A community VR mod for the rail shooter, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

There are **two separate mod ZIPs** on Discord, one for each edition:
- **Demo** version (free Steam demo)
- **Full game** (Steam paid)

Pick the one that matches your copy of the game. The Hub installer asks which you have and links the right download post.

**No VR controller support** - the base game itself is gamepad-only. Use a gamepad or keyboard. There is no ViGEmBus dependency.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1325853693530079232/1325853693530079232

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Picking your edition (Demo / Full game)
4. Downloading the matching mod ZIP from the right Discord post
5. Auto-locating your Mirage Feathers install (Steam libraries scanned)
6. Extracting the mod files into the game folder

The installer soft-warns if the ZIP filename doesn't match the edition you picked (e.g. you picked Full game but dropped in `Mirage_Feathers_Demo_VR.zip`), and lets you continue or pick a different file.

## Heads-up about the VR experience

This mod adds **stereoscopic depth** to the rail shooter - it's not a full 360-degree VR experience. Worth knowing before you install:

- The action stays in front of you. Turning around in VR shows a blank screen behind. This is expected.
- Bullet patterns from heavy enemy fire can feel close to your face. Sitting back a bit helps reaction time.
- Best enjoyed if you like super-scaler arcade shooters (After Burner, Space Harrier, Hang-On) and want stereoscopic depth on top of the original framing.

If you're hoping for a depth-rich, immersive 3D environment like a Panzer Dragoon mod, this won't deliver that - the underlying game is on a one-dimensional rail.

## Features

- bHaptics support
- Stereoscopic depth in a pseudo-3D rail shooter

## Controls

Game controls are unchanged. Use a **gamepad** (recommended - the base game is gamepad-only) or **keyboard**. There is no motion-controller support and no VR-specific hotkeys; the mod just renders the rail-shooter in stereoscopic 3D.

## Configuration

The config file is **created after your first launch** with the mod installed, at:

```
BepInEx\config\MirageFeathers_VR.cfg
```

Tunable options:
- **Reticle size** - adjust the in-game crosshair size to your preference
- **bHaptics behaviour** - tune how the bHaptics vest reacts to in-game events

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1325853693530079232/1325853693530079232
- Demo download: https://discord.com/channels/1001138422972432597/1325853693530079232/1326090177919062099
- Full game download: https://discord.com/channels/1001138422972432597/1325853693530079232/1326090245850005568

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Take wing. The shrine spirits are watching.

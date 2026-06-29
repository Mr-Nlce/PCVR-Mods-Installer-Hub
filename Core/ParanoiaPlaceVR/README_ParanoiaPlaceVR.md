# Paranoia Place VR

A psychological horror game brought into VR with full 6DoF head and hand tracking. Aim at objects with your dominant hand to interact. The atmosphere does the rest.

**Mod**: Paranoia_Place_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Paranoia Place (Steam App 1592290)

## About this mod

A community VR mod for the psychological horror title, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1391728936039485450/1391728936039485450

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Confirming you've launched the base game at least once (required by the mod)
4. Downloading `Paranoia_Place_VR.zip` from the mod channel
5. Auto-locating your Paranoia Place install (Steam libraries scanned)
6. Extracting the mod files into the game folder
7. Installing the bundled ViGEmBus driver - **required** if you want to use VR controllers as input

**Pre-install requirement**: launch Paranoia Place at least once and get past the brightness/setup screen before installing the mod. That setup screen does **not** render in VR, so you have to do the initial config flat first. The installer asks you to confirm.

## Features

- **6DoF head + hand tracking** - aim with your hand to interact
- **bHaptics** support
- **Left-handed mode** - after the first launch with the mod installed, edit `BepInEx\config\Paranoia_Place_VR.cfg` and set `leftHanded = true`
- **Headset rotation for turning** - same config file, set `headsetRotation = true` to physically turn in real life instead of using the right stick

```
[General]

leftHanded      = false   # set true to swap to left-hand dominant
headsetRotation = false   # set true to turn with your head, not the stick
```

## Controls

You can play this game with **VR controllers** (recommended), a **gamepad**, or a **keyboard**.

For VR controllers you **must install ViGEmBus** so the mod can map your VR input to a virtual Xbox pad. The Hub installer can do this for you in step 7.

### VR controller mapping

VR controllers are mapped as a virtual Xbox controller:
- [[A]], [[B]], [[X]], [[Y]] → same buttons
- [[Left Grip]] → LB, [[Right Grip]] → RB
- [[Left Trigger]] → LT, [[Right Trigger]] → RT

### Interaction

The mod provides **full 6DoF head and hand tracking**. Aim at objects with your dominant hand (right by default) to interact with them.

### Recentering

Click **both joysticks at the same time** to recenter the view at any time.

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

- [[Left Stick]] → D-Pad
- [[Left Stick]] click → Back / View button
- [[Right Stick]] click → Start / Menu button

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to something else, for example `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming back.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1391728936039485450/1391728936039485450
- Mod download: https://discord.com/channels/1001138422972432597/1391728936039485450/1391729614811824149

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Trust nothing. Especially the wallpaper.

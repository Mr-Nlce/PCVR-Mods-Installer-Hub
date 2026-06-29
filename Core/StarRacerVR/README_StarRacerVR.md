# Star Racer VR

An F-Zero-inspired retro arcade racer brought into VR. The mod renders the game in VR while keeping the original gamepad-driven control scheme.

**Mod**: StarRacer_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Star Racer (Steam App 2626120)

## About this mod

A community VR mod for the F-Zero-style arcade racer, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

**Single-player only** - split-screen is not supported by the VR mod.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1424109526621360240/1424109638558679142

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `StarRacer_VR.zip` from the mod channel
4. Auto-locating your Star Racer install (Steam libraries scanned)
5. Extracting the mod files into the game folder
6. Installing the bundled ViGEmBus driver - **required** if you want to use VR controllers as input

## Controls

You can play this game with **VR controllers**, a **gamepad**, or **keyboard**.

For VR controllers you **must install ViGEmBus** so the mod can map your VR input to a virtual Xbox pad. The Hub installer can do this for you in step 6.

### VR controller mapping

VR controllers are mapped as a virtual Xbox controller:
- [[A]], [[B]], [[X]], [[Y]] → same buttons
- [[Left Grip]] → LB, [[Right Grip]] → RB
- [[Left Trigger]] → LT, [[Right Trigger]] → RT
- [[Left Stick]] → left stick, [[Right Stick]] → right stick

### Game-specific hotkeys

- **Recenter view**: [[LT]] + [[RT]] + X (gamepad) or VR-controller equivalents
- **Toggle 1st-person view while racing**: [[LB]] + [[RB]] + X (pause first for comfort)
- **Adjust camera offset** (move the camera around the ship for better visibility):
  - Hold [[LB]] + [[RB]]
  - [[Left Stick]] → move camera on horizontal plane
  - [[LT]] → move camera down, [[RT]] → move camera up

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

- [[Left Stick]] → D-Pad
- [[Left Stick]] click → Back / View button
- [[Right Stick]] click → Start / Menu button

### SteamVR rebinding

If using OpenVR/SteamVR, you can rebind any control via the SteamVR input bindings UI.

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
- Mod info post: https://discord.com/channels/1001138422972432597/1424109526621360240/1424109638558679142
- Mod download: https://discord.com/channels/1001138422972432597/1424109526621360240/1457285094082613461

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Hold the line. Pass on the inside. Win the galaxy.

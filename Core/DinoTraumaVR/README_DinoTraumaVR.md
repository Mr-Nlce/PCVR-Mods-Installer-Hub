# Dino Trauma VR

PSX-style boomer-shooter that wears Dino Crisis on its sleeve. Retro FPS, dinosaurs, guns, and a lot of blood. The VR mod attaches a weapon to your right hand and the flashlight + kick to your left, with full motion-controller support and bHaptics.

**Mod**: DinoTrauma_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Dino Trauma (Steam App 2149420)

## About this mod

A community VR mod for the retro PSX-style shooter, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1362075882042167377/1362075882042167377

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `DinoTrauma_VR.zip` from the mod channel
4. Auto-locating your Dino Trauma install (Steam libraries scanned)
5. Extracting the mod files into the game folder
6. Installing the bundled ViGEmBus driver - **required** if you want to use VR controllers as input
7. Optionally swapping in the left-handed config variant (the right-handed default is backed up first)

## Features

- bHaptics support

## Controls

You can play this game with **VR controllers** (recommended) - buttons are mapped as a virtual Xbox controller via ViGEmBus.

For VR controllers you **must install ViGEmBus**. The Hub installer can do this for you in step 6.

### VR controller mapping

VR controllers are mapped as a virtual Xbox controller:
- [[A]], [[B]], [[X]], [[Y]] → same buttons
- [[Left Grip]] → LB, [[Right Grip]] → RB
- [[Left Trigger]] → LT, [[Right Trigger]] → RT

### Hand attachments

By default (right-handed mode):
- **Right hand**: weapons. Aim at objects, doors, and items with your right hand to interact.
- **Left hand**: flashlight + kick.

If you opted into **left-handed mode** during install:
- **Left hand**: weapons. Aim/interact with your left hand.
- **Right hand**: flashlight + kick.

### Game-specific hotkeys

- **Both stick clicks at once**: recenter the VR view
- **[[Right Stick]] click + A**: force-reattach weapons / flashlight / kick (use this if anything detaches)
- **Look up/down + left stick forward**: climb ladders / swim. Ladders can be tricky and may need a few tries.

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

- [[Left Stick]] → D-Pad
- [[Left Stick]] click → Back / View button
- [[Right Stick]] click → Start / Menu button

## Left-handed mode

The Dino Trauma VR mod doesn't have its own left-handed toggle in code (the author confirmed this in Discord). Instead, left-handed mode is achieved by replacing the bundled `BepInEx\config\UnityVR_Bepinex.cfg` with a variant where the right/left hand attach-objects are swapped.

The Hub installer offers this swap as an opt-in at the end of setup. The standard right-handed config is backed up to `BepInEx\config\UnityVR_Bepinex.cfg.righthanded.bak` so you can roll back without redownloading the mod ZIP.

Source post: https://discord.com/channels/1001138422972432597/1362075882042167377/1374444537102995456

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Known issues

- The flashlight doesn't always attach to the left hand. Use **right stick click + A** to force-reattach.
- The camera/player orientation can occasionally be very wrong. Recenter with **both stick clicks** to fix.
- In-game menus with a scrollable list don't work in VR yet (Astienth is working on it).

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to something else, for example `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming back.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1362075882042167377/1362075882042167377
- Mod download: https://discord.com/channels/1001138422972432597/1362075882042167377/1362079563756208429
- Left-handed config post: https://discord.com/channels/1001138422972432597/1362075882042167377/1374444537102995456

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Sixty-five million years and they still want to eat you.

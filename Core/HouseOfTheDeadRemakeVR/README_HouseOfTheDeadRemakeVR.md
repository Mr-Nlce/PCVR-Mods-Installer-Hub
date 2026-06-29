# The House of the Dead: Remake VR

The classic 1997 arcade rail-shooter — re-released as the SEGA-licensed remake — brought into VR with a 3D pistol attached to your right hand and full motion-controller mapping. Aim where you point. Reload with a trigger pull. The undead don't stand a chance.

**Mod**: TheHouseOfTheDead_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: THE HOUSE OF THE DEAD: Remake (Steam App 1694600)

## About this mod

A community VR mod for the rail-shooter remake, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenXR by default; OpenVR is supported via a config edit.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1391730397418881067/1391730397418881067

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `TheHouseOfTheDeadRemake_VR.zip` from the mod channel
4. Auto-locating your House of the Dead Remake install (Steam libraries scanned)
5. Extracting the mod files into the game folder
6. Installing the bundled ViGEmBus driver - **required** if you want to use VR controllers as input

## Features

- **bHaptics** support
- **ForceTube / Provolver** support
- **Left-handed mode** - after the first launch with the mod installed, edit `BepInEx\config\TheHouseOfTheDead_VR.cfg` and set `leftHanded = true`. Only the triggers swap; everything else is identical.

## Controls

You can play this game with **VR controllers** (recommended), a **gamepad**, or a **keyboard**.

For VR controllers you **must install ViGEmBus** so the mod can map your VR input to a virtual Xbox pad. The Hub installer can do this for you in step 6.

### VR controller mapping

VR controllers are mapped as a virtual Xbox controller:
- [[A]], [[B]], [[X]], [[Y]] → same buttons
- [[Left Grip]] → LB, [[Right Grip]] → RB
- [[Left Trigger]] → LT, [[Right Trigger]] → RT

### In-game controls

- **[[Right Trigger]]**: fire / shoot
- **[[Left Trigger]]**: reload
- **D-pad left/right**: change weapon (D-pad available via the hotkey gesture below)
- **Aim with your right hand** - a 3D pistol model is attached to it
- **Both stick clicks at once**: recenter the VR view
- **[[Right Stick]] click + [[Y]] on left controller**: force-recreate the pistol model if it doesn't appear properly

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

- [[Left Stick]] → D-Pad (this is how you change weapons)
- [[Left Stick]] click → Back / View button
- [[Right Stick]] click → Start / Menu button

## Switch to OpenVR (default is OpenXR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenVR
```

(Default is `OpenXR`. Both runtimes are supported.)

## Known issues

- The pistol model sometimes doesn't appear. Use **[[Right Stick]] click + [[Y]] on left controller** to force-recreate it. If that doesn't work, restart the game - it should appear on the second try.
- In Level 1 there's a scene where a door opens and a monkey attacks you. Visibility drops to ~2 meters with no obvious cause. Just keep shooting - the monkey goes down regardless.

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to something else, for example `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming back.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1391730397418881067/1391730397418881067
- Mod download: https://discord.com/channels/1001138422972432597/1391730397418881067/1504351282914136074

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Reload. Aim. The dead are getting closer.

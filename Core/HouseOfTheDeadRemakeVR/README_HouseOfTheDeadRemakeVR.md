# The House of the Dead: Remake VR

**Mod**: TheHouseOfTheDead_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: THE HOUSE OF THE DEAD: Remake (Steam App 1694600)

## About the Game

The classic 1997 arcade rail-shooter was re-released as a SEGA-licensed remake. Shoot your way through its branching stages and rescue survivors.

## About the VR mod

A community VR mod for the rail-shooter remake, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenXR by default; OpenVR is supported via a config edit.

It adds a 3D pistol attached to your right hand and motion-controller mapping. Aim where you point.

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

VR controllers are mapped as a virtual Xbox controller. Aim with your right hand; the pistol model follows it.

| Button | Action |
| --- | --- |
| [[A]], [[B]], [[X]], [[Y]] | Corresponding Xbox face buttons |
| [[Left Grip]] | Xbox LB |
| [[Right Grip]] | Xbox RB |
| [[Right Trigger]] | Fire |
| [[Left Trigger]] | Reload |
| [[D-pad Left]] / [[D-pad Right]] | Change weapon |
| [[Left Stick Click]] + [[Right Stick Click]] | Recenter the VR view |
| [[Right Stick Click]] + [[Y]] on the left controller | Recreate the pistol model if it is missing |

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

| Button | Action |
| --- | --- |
| [[Left Stick]] | D-Pad, including weapon changes |
| [[Left Stick Click]] | Xbox Back / View |
| [[Right Stick Click]] | Xbox Start / Menu |

## Switch to OpenVR (default is OpenXR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenVR
```

(Default is `OpenXR`. Both runtimes are supported.)

## Known issues

- The pistol model sometimes doesn't appear. Use [[Right Stick Click]] + [[Y]] on the left controller to force-recreate it. If that doesn't work, restart the game - it should appear on the second try.
- In Level 1 there's a scene where a door opens and a monkey attacks you. Visibility drops to ~2 meters with no obvious cause. Just keep shooting - the monkey goes down regardless.

## Virtual Desktop troubleshooting

Astienth's [September 2026 support thread](https://discord.com/channels/1001138422972432597/1391730397418881067) distinguishes two runtime paths if the game opens flat on Virtual Desktop:

- For the default `OpenXR` mod setting, select **VDXR** as Virtual Desktop's OpenXR runtime and launch without first starting SteamVR.
- To use SteamVR, set `vrApi = OpenVR` in `BepInEx\config\UnityVR_Bepinex.cfg`, select SteamVR as the Virtual Desktop runtime, and start SteamVR.

These are alternative setups. One user reported a working but unusual configuration, so check your actual Virtual Desktop and mod settings rather than assuming a single universal fix. If VR controllers do not respond, verify Virtual Desktop's **Xbox controller** emulation and the ViGEmBus installation; the same user reported restoring input after reinstalling ViGEm while connected to the headset. This is a reported recovery, not a confirmed requirement for everyone.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1391730397418881067/1391730397418881067
- Mod download: https://discord.com/channels/1001138422972432597/1391730397418881067/1535371792041115658

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Reload. Aim. The dead are getting closer.

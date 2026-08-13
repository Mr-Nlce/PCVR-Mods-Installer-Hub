# Rogue Flight VR

A breathtaking arcade space-combat game inspired by prestige anime - bullet-hell action with style. The VR mod brings it into VR via OpenXR.

**Mod**: RogueFlight_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: ROGUE FLIGHT (Steam App 2784620)

## About this mod

A community VR mod for the gamepad-driven anime space shooter, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Supports OpenXR only - no OpenVR.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1443945389454528634/1443945389454528634

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `RogueFlight_VR.zip` from the mod channel
4. Auto-locating your Rogue Flight install (Steam libraries scanned)
5. Extracting the mod files into the game folder
6. Optionally installing the bundled ViGEmBus driver and enabling VR-controller emulation

## Controls

This is a **gamepad** game. A real Xbox-style gamepad is highly recommended - the game was built around one.

If you don't have a gamepad:
- **Virtual Desktop** users can use VD's built-in gamepad emulation - no extra setup needed in the game.
- **Other runtimes**: install ViGEmBus from the mod ZIP's `BepInEx/redist/` folder. The Hub installer can do this for you in step 6 and will also flip `vrControllersSupport = true` in `UnityVR_Bepinex_IL2CPP.cfg` so your VR controllers act as a virtual Xbox pad.

### Hotkey gesture (only when using VR-controller emulation)

Hold your **left controller close to your head**. When it vibrates, the hotkey is active and the stick layout shifts:

![Controller Layout](ControllerLayout.jpg)

- [[Left Stick]] → D-Pad while hotkey active
- [[Left Stick]] click → Back / View button while hotkey active
- [[Right Stick]] click → Start / Menu button while hotkey active
- Triggers, ABXY, sticks otherwise map directly to their gamepad equivalents.

### Recentering

Click **both joysticks at the same time** to recenter the view at any time. Recentering may be required after loading scenes.

## bHaptics support (Vest only)

The mod supports a **bHaptics vest** (vest only - no other peripherals). To use it: launch the bHaptics player and turn your vest on **before** starting the game.

The shooting effect on the main cannon triggers a lot - if it gets annoying you can disable it by editing `BepInEx\config\RogueFlight_VR.cfg`:

```
gunHaptics = false
```

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1443945389454528634/1443945389454528634
- Mod download: https://discord.com/channels/1001138422972432597/1443945389454528634/1443945903336460330

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Gun the engine. Burn the sky. Anime never dies.

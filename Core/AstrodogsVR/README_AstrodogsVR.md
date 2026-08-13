# Astrodogs VR

A Star Fox-inspired arcade space combat game with dogs in a colorful universe. The VR mod brings it into VR with motion-controller support.

**Mod**: AstroDogs_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Astrodogs (Steam App 1301230)

## About this mod

A community VR mod for the Star Fox-style canine space-combat game, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1424110040935043132/1424110255121367213

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `AstroDogs_VR.zip` from the mod channel
4. Auto-locating your Astrodogs install (Steam libraries scanned)
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

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

- [[Left Stick]] → D-Pad
- [[Left Stick]] click → Back / View button
- [[Right Stick]] click → Start / Menu button

### Recentering

Click **both joysticks at the same time** (gamepad or VR controllers) to recenter the view at any time.

### SteamVR rebinding

If using OpenVR/SteamVR, you can rebind any control via the SteamVR input bindings UI.

### VR-hand ship control mode (optional)

There's an optional mode where your **left joystick is controlled by the rotation of your VR hand** - you tilt your hand to aim/steer. Off by default. Enable it in `BepInEx\config\AstroDogs_VR.cfg`:

```
VRShipControl = true       # off by default
LeftHand      = false      # use right hand by default; set true for left
HandMaxAngle  = 0.4        # sensitivity (max 1.0 = 180 degrees)
offsetHand    = 0.0,0.0,0.0  # rotation offset for the aiming hand
```

- `HandMaxAngle` sets how far you have to tilt your hand to reach max stick value. Lower = more sensitive.
- `offsetHand` shifts the neutral position of your hand. Use this if your natural neutral hand pose isn't what the game treats as centered.

**Live offset adjust in-game**: hold the left joystick click and move the right joystick. It feels strange at first but lets you dial in a comfortable neutral pose without restarting. If anything goes wrong, edit the config back to `0.0,0.0,0.0` and try again.

The left joystick **always overrides** the hand-rotation control - the stick wins in case of an emergency.


## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1424110040935043132/1424110255121367213
- Mod download: https://discord.com/channels/1001138422972432597/1424110040935043132/1425398903125315615

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Bark at the stars. Bite the moons.

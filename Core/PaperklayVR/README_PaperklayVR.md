# Paperklay VR

A cute 3D platformer made by a single developer, inspired by Banjo-Kazooie and old-school 3D platformers. The VR mod adds full motion-controller support with proper VR gestures: hands-above-head to glide, punch forward to attack, quick downward swing in the air to stomp.

**Mod**: Paperklay_VR v1.0.0 (bHaptics) - by Astienth, distributed by Astienth via Discord  
**Game**: PaperKlay (Steam App 1350720)

## About this mod

A community VR mod for the Banjo-inspired 3D platformer, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1380447945215836261/1380447945215836261

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading `PaperKlay_VR_bHaptics.zip` from the mod channel
4. Auto-locating your PaperKlay install (Steam libraries scanned)
5. Extracting the mod files into the game folder
6. Installing the bundled ViGEmBus driver - **required** if you want to use VR controllers as input

## Features

- bHaptics support

## Controls

You can play this game with **VR controllers** (recommended), a **gamepad**, or a **keyboard**.

For VR controllers you **must install ViGEmBus** so the mod can map your VR input to a virtual Xbox pad. The Hub installer can do this for you in step 6.

### VR controller mapping

VR controllers are mapped as a virtual Xbox controller:
- [[A]], [[B]], [[X]], [[Y]] → same buttons
- [[Left Grip]] → LB, [[Right Grip]] → RB
- [[Left Trigger]] → LT, [[Right Trigger]] → RT

### VR motion gestures

The mod adds proper VR gestures on top of the gamepad mapping:

- **Both hands above your head (while airborne)** → activate the **glider**
- **Punch forward with your hand** → trigger the **attack**
- **Quick downward swing while in the air** → trigger the **stomp** attack

You can disable gestures entirely (config below) if you'd rather play with just buttons.

### Recentering

Click **both joysticks at the same time** to recenter the view at any time.

### Hotkey gesture

Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active, and the stick layout shifts:

- [[Left Stick]] → D-Pad
- [[Left Stick]] click → Back / View button
- [[Right Stick]] click → Start / Menu button

## Configuration

The config ships with the mod ZIP, so it's available immediately after install. Edit `BepInEx\config\Paperklay_VR.cfg`:

```
[General]

UseGestures      = true   # turn off to disable motion gestures and use buttons only
LockUpDownCamera = true   # game handles camera Y axis (natural in VR); false = right stick up/down controls camera height
```

### Tips

- `UseGestures = false` is useful if a particular gesture keeps misfiring or you'd just rather have a calmer experience.
- `LockUpDownCamera = true` is the default because letting the game handle the camera vertical axis is generally more natural in VR. Flip it off if you want full manual control.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1380447945215836261/1380447945215836261
- Mod download: https://discord.com/channels/1001138422972432597/1380447945215836261/1388601628793508012

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Folded worlds, soft heroes. Run wild.

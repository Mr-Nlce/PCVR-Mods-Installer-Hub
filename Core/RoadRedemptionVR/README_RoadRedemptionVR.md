# Road Redemption VR

The Road Rash spiritual successor brought into VR with motion-controller weapon swings, bHaptics support, and your choice of third- or first-person view. Throw your arm toward an enemy to crack a baseball bat across their head.

**Mod**: RoadRedemption_VR v1.0.0 (bHaptics) - by Astienth, distributed via GitHub  
**Game**: Road Redemption (Steam App 300380)

## About this mod

A community VR mod by Astienth, distributed publicly on **GitHub** (no Discord login required - this is the only Astienth mod where the download is a direct, public URL):

- Repo: https://github.com/AstienVR/Road_Redemption_VR_bHaptics
- Direct download: https://github.com/AstienVR/Road_Redemption_VR_bHaptics/releases/download/1.0/RoadRedemptionVR.zip

Ships with OpenVR by default; OpenXR is supported via a config edit.

**Important**: this mod is NOT compatible with the Epic Store version of the game. Steam version only.

## What this Hub installer does

The bundled installer walks you through:
1. Auto-locating your Road Redemption install (Steam libraries scanned) and **downloading the mod ZIP directly from GitHub** - no manual download or drag-drop needed
2. Extracting the mod files into the game folder
3. Installing the bundled ViGEmBus driver - **required** if you want to use VR controllers as input

Because the GitHub release URL is public, the installer fetches it via `Invoke-WebRequest` and unpacks it for you. If the download fails (no internet, GitHub unreachable, firewall), the installer prints the URL so you can grab the ZIP by hand and rerun.

## Features

- **Third-person view** (default, like the original game)
- **First-person view** with two immersion levels: basic and full-immersive (head follows player rotation in full mode)
- **bHaptics support** (vest + arms)
- **VR motion-gesture attacks** for melee weapons

## Controls

You can play this game with **VR controllers** (recommended), a **gamepad**, or a **keyboard**.

For VR controllers you **must install ViGEmBus** so the mod can map your VR input to a virtual Xbox pad. The Hub installer can do this for you in step 4.

### VR controller mapping

VR controllers are mapped **EXACTLY** as a virtual Xbox controller:
- [[A]], [[B]], [[X]], [[Y]] → same buttons
- [[Left Grip]] → LB, [[Right Grip]] → RB
- [[Left Trigger]] → LT, [[Right Trigger]] → RT

### VR motion gestures (weapon attacks)

When you have a melee weapon (baseball bat, metal pipe, etc.), throw your arm toward your enemy to swing:

- Throw your **left arm** toward your **left side** → left attack
- Throw your **right arm** toward your **right side** → right attack

### Recentering

Hold [[X]] for **1.5 seconds** to recenter the VR view.

## Configuration

The config file is **created after your first launch** with the mod installed, at:

```
BepInEx\config\RoadRedemption_VR.cfg
```

Options:

```
[General]

firstPersonView      = false   # set true to enable first-person view
firstPersonViewFull  = false   # set true so the head follows player rotation (only matters when firstPersonView = true)
vignette             = false   # set true to add a vignette during turning (motion sickness mitigation)
maxVignetteValue     = 100     # vignette intensity, 0-100, 100 = strongest
fixValveIndex        = false   # set true if UI appears way too large or right in front of your eyes (Valve Index fix)
```

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

## Related communities

- Farmertrue VR Discord: https://discord.gg/G8zZBTGuhP
- Dteyn VR Discord: https://discord.gg/Qt7GT69Pzx

>>> Two wheels, one bat. Pavement remembers.

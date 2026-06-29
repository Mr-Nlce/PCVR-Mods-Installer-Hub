# Starfield VR

**Mod:** starfield2vr v2.0.0 Public
**Author:** mutars (based on PrayDog's REFramework)
**GitHub:** https://github.com/mutars/starfield2vr

## What this installer does

1. Asks which VR runtime you use: **OpenVR (SteamVR)** or **OpenXR** (Oculus / Virtual Desktop / Pimax / etc.) - there are separate mod files for each
2. Asks which store your Starfield install is from: **Steam** or **Xbox Game Pass**
3. Downloads the matching `starfield-vr-{openvr|openxr}-v2.0.0.Public.zip` and copies the contents into the game folder
4. Optionally downloads and launches the **ViGEmBus** driver installer, which is required so that VR motion controllers register as a virtual Xbox gamepad

## Install location

- **Steam:** auto-detected via the registry, typically `...\steamapps\common\Starfield`
- **Xbox Game Pass:** default is `C:\XboxGames\Starfield\Content` - the installer uses that if it exists, otherwise asks

## Prerequisites

- **VR headset runtime set as the default OpenXR engine** (only relevant for the OpenXR path: Oculus app, Virtual Desktop, SteamVR, Varjo Base, etc.)
- **ViGEmBus** driver - the installer offers to fetch and run this for you. If you already have it installed (e.g. DS4Windows users) you can skip that step

## In-game settings (important)

Set these before playing in VR:

| Setting | Value |
|---|---|
| Display | Windowed |
| Frame Generation | **OFF** (never turn this on) |
| VSYNC | OFF |
| Motion Blur | OFF |
| Depth of Field | OFF |
| Dynamic Resolution | OFF (recommended) |

TAA, DLSS and CAS are fine. Frame Generation will break VR - there's no workaround.

## How to play

1. Start your VR runtime (SteamVR / Oculus / Virtual Desktop / etc.)
2. Launch Starfield the usual way for your store
3. Press **F11** on the flat monitor (not in the HMD) for the in-game overlay

## In-game Overlay (F11)

Hotkey is F11 and it only shows on the flat monitor, not in the headset. Options:

- **OpenXR Resolution Scale** - 0.1x to 5.0x (start at 1.0, adjust for your GPU)
- **Desktop Recording Fix** - enable for better desktop mirror quality when streaming or recording
- **Set Standing Origin Key** - recenter your VR position

## Controls

| Control | Action |
|---|---|
| Thumbrest | Left/Right buttons |
| [[Left Grip]] + [[Left Stick]] Button | Switch to flat-screen view |
| [[Left Grip]] + [[Left Stick]] | D-Pad |
| [[Right Grip]] | Aim (trigger left of right stick) |
| [[Left Grip]] + System Button | Xbox Start / system menu (toggles 3rd/1st person) |

Compatible with Oculus Touch, Vive wands, and Valve Index controllers. Quad View is supported for Pimax and Virtual Desktop.

## Features

- Full 6DoF head tracking
- Roomscale with configurable world scale
- Configurable HUD (scale and distance)
- OpenXR resolution scaling
- Decoupled pitch (head movement independent from character rotation)
- Haptic feedback
- Quad View (Pimax / Virtual Desktop)

## Known limitations

- OpenVR is missing controller bindings for some controllers - OpenXR is more polished for motion-controller input

## Video tutorials

- Starfield VR Setup Guide by Good Samaritan: https://youtu.be/UKt2utvotxA
- Starfield VR Tutorial by ParadiseDecay: https://youtu.be/cJ9ccj92xNM

## Requirements

- Starfield (Steam or Xbox Game Pass PC)
- A VR headset with OpenVR or OpenXR support
- ViGEmBus driver (installer offers to set this up)
- Gamepad or VR motion controllers (controller category: KB&M or Gamepad VR)

## Uninstall

Delete the files added to the game folder. For Steam, running "Verify integrity of game files" is the cleanest way to restore the vanilla state.

*The stars are waiting. Constellation awaits, Starborn.*

## Support mutars

mutars develops the starfield2vr mod. If you enjoy their work, consider supporting them:
- Patreon: https://www.patreon.com/c/NoMoreFlat

>>> The stars are waiting. Constellation awaits, Starborn.

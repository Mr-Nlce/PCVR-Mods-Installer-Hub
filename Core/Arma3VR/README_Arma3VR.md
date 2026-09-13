# Arma 3 VR - A3VR Hybrid

An experimental **OpenXR bridge** for 64-bit Arma 3 by **gborgogno**. It
presents Arma's D3D11 output in the headset, publishes headset motion through
Arma's FreeTrack input path and maps motion controllers to native game input.
No VorpX is required.

> **This is not a native engine VR port.** Stop immediately if stereo causes
> eye strain, image divergence, nausea or discomfort.

## What hybrid means

Gameplay stereo is produced with two Arma render-to-texture cameras. Menus and
cinematics use one complete binocular surface so interface controls are not
split between the eyes. The optional controller-absolute weapon proxy mirrors
your equipped weapon while Arma remains authoritative for ammunition, damage,
inventory, movement, collision and mission state.

**PiP must remain enabled.** Moderate borders, scale and latency can vary with
the active OpenXR runtime because this is still a bridge around Arma's renderer.

## Install and start

The Hub offers the GitHub package or Steam Workshop. Do not enable both, and
never load two A3VR variants together.

1. Install A3VR and start the headset with the intended OpenXR runtime active.
2. In the official Arma 3 Launcher, enable **A3VR - Arma 3 Hybrid VR**.
3. Disable BattlEye. The native bridge is unsigned and is not for protected
   matchmaking.
4. Start Arma through the official Launcher.
5. Enable **FreeTrack** in Arma's controller/device list when it appears.
6. In gameplay, hold [[Left Grip]] for 0.65 seconds and choose
   **Recenter HMD + Aim**.

If FreeTrack is missing, close Arma and use the profile/start action offered by
the installer once. The installer can also set up OpenTrack's FreeTrack
registration when this PC has never used head tracking.

Keep keyboard and mouse nearby. Arma has many contextual and mission-specific
actions that have no VR binding, and no controller binding sends Escape.

## Controls

| Input | Action |
|---|---|
| Headset | FreeTrack head rotation and translation |
| [[Right Controller]] | Aim; left controller when left-handed aim is selected |
| [[Right Trigger]] | Fire |
| [[Right Grip]] | Hold native ADS when enabled |
| [[A]] | Reload |
| [[B]] | Throw selected grenade |
| [[Right Stick]] | Smooth turn; flick up/down to change one stance level |
| [[Right Stick Click]] | Change fire mode; accept in supported UI |
| [[Left Stick]] | Move and strafe |
| [[Left Stick Click]] | Sprint; middle-click in supported UI |
| [[Left Trigger]] | Vault / step over |
| [[X]] | Interact / default action |
| [[Y]] | Switch primary weapon / sidearm |
| [[Left Grip]] hold | Open or close A3VR settings |

### Left-grip chords

Hold [[Left Grip]], press the second control, then release both.

| Chord | Action |
|---|---|
| [[Left Grip]] + [[A]] | Toggle equipped laser or flashlight |
| [[Left Grip]] + [[Right Stick Click]] | Deploy or retract weapon / bipod |
| [[Left Grip]] + [[B]] | Toggle VR proxy / Native motion |
| [[Left Grip]] + [[X]] | Open or close map |
| [[Left Grip]] + [[Y]] | Open or close inventory |

In supported controller UI, [[Right Trigger]] clicks, [[Right Stick]] scrolls,
[[Right Stick Click]] accepts and [[Left Stick Click]] sends middle mouse.
Configuration screens, Zeus, Eden and some DLC dialogs still use the mouse.

## New in v1.0.2

- The stereo path stamps each completed Arma backbuffer with the matching
  per-eye OpenXR poses instead of reusing a later pose.
- Controller-absolute proxy gameplay submits from its captured local-space
  pose, allowing the active runtime to reproject the older image correctly.
- The pose stamp refreshes every presented frame even when the shared D3D11
  texture handle does not change.
- Native motion, vehicles, menus and cinematics keep their established
  view-space presentation path.
- Runtime selection remains neutral: Meta OpenXR, SteamVR, VDXR, Pimax, PICO,
  WMR and other conformant runtimes are chosen by Windows, not hard-coded.

## Headset support

- **Primary development route:** Meta Quest over Air Link with Meta OpenXR
- **Community-tested:** VDXR
- **Partially exercised:** SteamVR/OpenXR image and head tracking on Quest 3S
- **Still experimental:** SteamVR controller feel, haptics/audio and other
  headset/runtime combinations

Only one application can own the OpenXR session. If the headset stays black,
confirm the intended runtime is active and close other VR games or overlays.

## Known limits

- Experimental stereo RTT costs more than the old mono surface; PiP is required.
- No independent physical hands, arm IK or manual magazine/bolt interaction.
- Magnified PiP/depth optics are not implemented; use native ADS for scopes.
- Vehicle, door, ladder, medical, Zeus and scripted mission interaction may
  still require keyboard and mouse.
- Generic weapon proxy support cannot guarantee correct geometry and effects
  for every third-party weapon.
- The binaries and PBO are unsigned: keep BattlEye off and avoid protected
  multiplayer.

Mod and full documentation:

https://github.com/gborgogno/a3vr-arma3

>>> Someone already took the high ground. It is always the sniper.

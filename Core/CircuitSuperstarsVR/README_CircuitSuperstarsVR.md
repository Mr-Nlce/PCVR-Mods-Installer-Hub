# Circuit Superstars VR

A top-down (now optionally first-person) arcade racing sim with a charming hand-painted aesthetic, by Original Fire Games. Career mode, championships, customisable cars, and tight handling — all in stereoscopic VR with bHaptics vest support.

**Mod**: CircuitSuperstars_VRMod v1.0.0 - by Astienth, distributed via GitHub  
**Game**: Circuit Superstars (Steam App 1097130)

## About this mod

A community VR mod by Astienth, distributed publicly on **GitHub** (no Discord login required - public download URL):

- Repo (info, README): https://github.com/Astienth/Circuit_Superstars_VR_bHaptics
- Direct download: https://github.com/Astienth/Circuit_Superstars_VR/releases/download/1.0.0/CircuitSuperstars_VRMod.zip

Heads-up: the README is hosted in the `_bHaptics` repo, but the binary release lives in a **different** repo (`Circuit_Superstars_VR`, no `_bHaptics` suffix). Both URLs are correct — that's how Astienth has things set up. The Hub installer uses the download URL as-is.

Ships with OpenVR by default; OpenXR is supported via a config edit.

## What this Hub installer does

The bundled installer walks you through:
1. Auto-locating your Circuit Superstars install (Steam libraries scanned) and **downloading the mod ZIP directly from GitHub** - no manual download or drag-drop needed
2. Extracting the mod files into the game folder

Because the GitHub release URL is public, the installer fetches it via `Invoke-WebRequest` and unpacks it for you. If the download fails (no internet, GitHub unreachable, firewall), the installer prints the URL so you can grab the ZIP by hand and rerun.

**No ViGEmBus step** - this mod doesn't bundle ViGEmBus.

## Before launching

If you have a bHaptics vest, **turn it on before launching the game** - the mod detects it at startup. Only the vest is supported (no arms).

## Controls

**Gamepad or keyboard+mouse only - no VR controller support.** Game controls are unchanged.

### VR-specific hotkeys

- **Double-press START** (gamepad) / **F1** (keyboard) — Toggle first-person view on/off
- **Hold START** (gamepad) / **F2** (keyboard) — Recenter VR view

The default camera is the game's native top-down view, with first-person available as a toggle. Switching back is on the same hotkey.

## Configuration

The mod ships with a config file at:

```
BepInEx\config\CircuitSuperstars_VR.cfg
```

Tunable options:

```
# Vignette tunneling effect in first-person view, used to reduce
# motion sickness during turns. Default ON.
tunneling = true

# Keep the game's horizontal plane level with the real world,
# instead of letting the camera tilt with the car. Some players
# find the level horizon more comfortable in VR.
horizonalView = false
```

(Note: `horizonalView` is the actual variable name in the config file, with that exact spelling. Don't "fix" it to `horizontalView` — the mod won't read it.)

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to anything else, for example `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming back to `winhttp.dll`.

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Tiny cars, huge corners. Mind the apex.

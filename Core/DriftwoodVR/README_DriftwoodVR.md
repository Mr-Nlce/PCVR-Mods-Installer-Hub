# Driftwood VR

High-speed downhill longboarding as Eddy the sloth - now with full body-lean motion controls, stereoscopic VR, and bHaptics support. Lean left and right to steer, lean forward to accelerate, and raise both hands above your head to air break.

**Mod**: Driftwood_VR v1.0 (bHaptics) - by Astienth, distributed via GitHub  
**Game**: Driftwood (Steam App 2223700)

## About this mod

A community VR mod by Astienth, distributed publicly on **GitHub** (no Discord login required - public download URL):

- Repo: https://github.com/Astienth/DriftWood_VR_bHaptics
- Direct download: https://github.com/Astienth/DriftWood_VR_bHaptics/releases/download/1.0/Drifwood_VRMod_bHaptics.zip

Heads-up: the ZIP filename has the typo "Drifwood" (one 'f'), and the repo name capitalises the W. The game itself, the install folder, and the DLL all use the correct two-'f' spelling. The Hub installer handles the URL as-is.

Ships with OpenVR by default; OpenXR is supported via a config edit.

## What this Hub installer does

The bundled installer walks you through:
1. Auto-locating your Driftwood install (Steam libraries scanned) and **downloading the mod ZIP directly from GitHub** - no manual download or drag-drop needed
2. Extracting the mod files into the game folder

Because the GitHub release URL is public, the installer fetches it via `Invoke-WebRequest` and unpacks it for you. If the download fails (no internet, GitHub unreachable, firewall), the installer prints the URL so you can grab the ZIP by hand and rerun.

**No ViGEmBus step** - this mod doesn't bundle ViGEmBus. VR-controller input is wired directly through OpenVR/SteamVR without a virtual-gamepad layer.

## Before launching

If you have bHaptics gear, **turn it on before launching the game** - the mod detects it at startup:
- Launch the bHaptics Player and connect your vest / arms

## Features

- Full body-lean motion controls (steer, accelerate, air break)
- Hand brake on each trigger (left / right)
- Hotkey combos to swap boards / wheels mid-run, skip songs, toggle camera
- bHaptics support (vest + arms)
- First-person / third-person view toggle

## Controls

VR controllers are used directly (not mapped to a virtual gamepad).

### Stick + button mapping

- **[[Left Stick]]** - Steering / accelerate / air brake / UI navigation
  - Up = accelerate
  - Down = air brake
  - Left / right = steer
- **[[Right Stick]]** - Look around. Click = pause menu.
- **[[A]]** - Confirm / Push skate
- **[[B]]** - Cancel / Back
- **[[Y]]** - Map
- **[[X]]** - Hold to restart track / UI function in menus
- **[[Left Trigger]]** - Hand brake left
- **[[Right Trigger]]** - Hand brake right
- **[[Right Grip]]** - HotKey modifier (see combos below)

### Hotkey combinations

- **L stick click + R stick click** - recenter view
- **[[Right Grip]] + L stick click** - toggle first/third person view
- **[[Right Grip]] + L stick up** - switch wheels up
- **[[Right Grip]] + L stick down** - switch wheels down
- **[[Right Grip]] + L stick left** - switch board left
- **[[Right Grip]] + L stick right** - switch board right
- **[[Right Grip]] + Y** - skip song

### Motion gaming

Stand-up VR play is recommended for the lean motions to feel right.

- **Lean left / right in real life** - steer. The left joystick (steering) **always prevails** over motion gaming - they're additive, joystick wins.
- **Lean forward** - accelerate
- **Raise BOTH hands above your head** - air break

### Controller layout image

A picture of the controls is bundled with the mod and dropped into your game root folder as `VRControls.jpg`. The same image is included alongside this README in the Hub installer folder as `ControllerLayout.jpg`.

![Controller layout](ControllerLayout.jpg)


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
- Farmertrue Twitch playthrough: https://www.twitch.tv/videos/2264677373
- Farmertrue YouTube playthrough: https://www.youtube.com/watch?v=6LCPrm4Wrqw

>>> Catch the ramp. Catch the line. Catch some air.

# Descenders VR Mod Installer

Automated installer for the **Descenders VR Mod** by Holydh, v1.0.5 fork by kyanite-rock.

## What it installs
- **DescendersVRMod v1.0.5** — VR camera, world-space UI, post-processing for VR
- **BepInEx 5.x** — bundled with the mod (loaded via winhttp.dll doorstop)
- **VR runtime DLLs** — openvr_api.dll (SteamVR), OVRPlugin.dll (Oculus), OVRGamepad.dll, AudioPluginOculusSpatializer.dll
- **Modified globalgamemanagers** — enables the Oculus/OpenVR XR pipeline (original is backed up)

## How to use
1. Click **Install Mod** on the game tile or detail page
2. Read the controller warning at the start — Descenders has known input quirks
3. Select your VR runtime: **SteamVR** or **Oculus**
4. Steam Properties opens twice: paste launch option, then enable Steam Input override
5. A `Descenders VR` desktop shortcut is created (launches via Steam so launch options apply). Launch with **Start in VR** in the Hub or that shortcut

## Requirements
- Windows 10 / 11
- Steam version of Descenders (Game Pass / Microsoft Store version not supported by this mod)
- VR headset with SteamVR or Oculus runtime running
- One XInput-compatible gamepad (Xbox controller, DualShock/DualSense, VD Gamepad Mode, etc.)

## Controls

This game is **gamepad only** in VR — no motion controls, no keyboard ingame. The mod ships with `OVRGamepad.dll`, an XInput-only Oculus plugin that handles all gamepad input. This causes friction with several setups, **independent of this installer**.

### Rules to avoid dead inputs
- **ONLY one gamepad connected** while playing. Unplug HOTAS, racing wheels, joysticks, second pads. The XInput pipeline only reads slot 0; extra devices push your pad out.
- **Virtual Desktop users**: enable **Gamepad Mode in VD before launching the game**. If you start Descenders first and toggle VD's gamepad mode after, the slot ordering will be wrong.
- **DInput-only pads** (older 8BitDo in DInput mode, vJoy sticks, generic USB pads): use an XInput wrapper like x360ce. Native DirectInput is not supported.
- **Steam Input override = "Enable Steam Input"** is set during installation. Do not disable it — this is the most reliable workaround for non-Xbox pads.
- If the pad dies mid-session: close the game, ensure pad is still in slot 0 (Windows → `joy.cpl`), restart.

### Why this happens
`OVRGamepad.dll` calls Windows `XInputGetState` directly. It does not see DInput, RawInput, or HID. If the Oculus runtime registers Touch controllers as XInput, they can collide with your real pad. Multiple-controller chaos has been a known Descenders issue since 2018, confirmed by the dev team in the Steam forums — this mod inherits it.

## Switching between VR and Flat

Original `globalgamemanagers` is backed up as `globalgamemanagers.flatbackup`.

**To return to flat**:
1. Rename `Descenders_Data\globalgamemanagers` → `globalgamemanagers.vrbackup`
2. Rename `Descenders_Data\globalgamemanagers.flatbackup` → `globalgamemanagers`
3. Rename `BepInEx\plugins\DescendersVRmod.dll` → `DescendersVRmod.dll.off`

**To return to VR**: reverse the renames.

## Config
Edit `BepInEx\config\DescendersVRmod.cfg` after first launch to:
- Disable post-processing for performance gain
- Set custom UI offset / distance / scale defaults

In-game numpad controls for UI position: 2/8 (Y), 4/6 (X), 9/3 (distance), +/- (scale), 0 (reset).

## Credits
- **Holydh** — original mod | https://github.com/Holydh/Descenders_VRmod
- **kyanite-rock** — v1.0.5 fork (compatibility update) | https://github.com/kyanite-rock/DescendersVRMod
- **Flatscreen2VR Discord** — https://discord.gg/5c49tFYKtF

>>> Send it. Send it harder. Send it in VR.

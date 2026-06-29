# Cloudpunk: City of Ghosts VR Installer

Automated installer for Cloudpunk: City of Ghosts VR v1.0.0 by Astienth — gamepad-based VR support for the City of Ghosts DLC. Requires the base Cloudpunk game and its DLC owned on Steam.

## What it installs
- BepInEx (IL2CPP) + CloudpunkVR_CityofGhosts plugin
- SteamVR bindings for Oculus Touch, Vive, Index, and WMR

## Requirements
- Cloudpunk + City of Ghosts DLC owned on Steam
- SteamVR installed

## How to use
Click **Install Mod** on the game tile or detail page and follow the prompts.

## Controls
No motion-controller support — you play with a **gamepad** (recommended) or
keyboard & mouse. With keyboard & mouse the cursor isn't visible, so a
gamepad is the better option. Press the **Menu** action to recenter the VR
view (Start on a gamepad, or Escape on a keyboard).

## Configuration
All settings in `BepInEx\config\`:

**CloudpunkVR.cfg**
- `maxVehicleCharactersDivider` — divide max NPCs/vehicles for better performance
- `RainAndSheetsRenderer` — vertical rain effect, disable if hurting performance

**UnityVR_Bepinex_IL2CPP.cfg**
- `VRUI scale` — size of the VR UI (default 2)
- `Allow HDR` / `Allow MSAA` — visual quality toggles
- `disableTAA` — disable temporal anti-aliasing if causing issues

## Deactivate the VR mod

To turn the mod off you rename two things:

1. In the game root folder, rename `winhttp.dll` to anything else (e.g.
   `winhttp.dll.off`). `winhttp.dll` present = mod active; renamed = mod
   inactive.
2. In `Cloudpunk_Data`, there are two files: `globalgamemanagers` and
   `globalgamemanagers.bak`. The `.bak` is the game's original, unmodified
   file. Rename `globalgamemanagers` to `globalgamemanagers.vr`, then rename
   `globalgamemanagers.bak` to `globalgamemanagers` (drop the extension).
   Only one file may be named `globalgamemanagers` at a time.

To return to VR, reverse the renames.

## More info
https://github.com/Astienth/Cloudpunk-VR/releases

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Back on the streets of Nivalis. The city never sleeps.

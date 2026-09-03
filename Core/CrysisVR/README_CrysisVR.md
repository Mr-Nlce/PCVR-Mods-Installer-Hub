# Crysis VR

A full Virtual Reality conversion of the 2007 Crytek shooter **Crysis** by modder **fholger**. Adds stereoscopic 6DOF rendering and motion-controller support so you can play the whole campaign in VR.

> This is an **external** mod: the Hub links you to fholger's official installer. Download it from the info page, run it, and point it at your Crysis install.

## What you get
- Full 6DOF head tracking and motion-controller support
- Roomscale support
- In-game VR manual and a "VR Settings" menu (accessible from the main menu) to tune the experience
- bHaptics haptic-vest support
- Runs on OpenXR (works with SteamVR and Oculus/Meta runtimes; native runtimes no longer require SteamVR)

## Requirements
- You must **own and install the original Crysis** (2007) - **not** the Remastered version
- A VR headset with OpenXR support
- Steady VR legs: the mod uses **smooth locomotion** and has vehicle sections

## How to install (external)
1. Open the info page and go to the mod's **Releases**.
2. Download the latest `crysis-vrmod-x.y.exe` installer (ignore the other files).
3. Run it and point it at your Crysis folder. On Steam: right-click Crysis -> Manage -> Browse local files.
4. The installer creates VR launchers in `Bin32` and `Bin64`. Use **Start in VR** in the Hub; it opens `Bin64\CrysisVR.exe` with the correct working folder. The 32-bit launcher is also accepted as a valid installed marker.

> It does not matter if the flat game won't launch on its own - just install the mod and play in VR.

## Controls
| Input | Action |
|-------|--------|
| Grip (at a holster) | Cycle weapons - there are **3 weapon holsters**, each holding multiple weapons |
| Right thumbstick | Aim vehicle weapons and stationary guns (instead of head/controller aim) |
| Motion controllers | Standard VR aiming and interaction for on-foot combat |

Open the in-game **VR Settings** menu to configure locomotion, world scale, and comfort options.

## Hardware notes
Crysis in VR is **demanding** - both because it's Crysis and because of how the stereoscopic rendering works. Expect even strong CPUs to cause reprojection. fholger recommends a **Ryzen 7000 / 5800X3D** or **Intel 12th gen or newer**; older CPUs (e.g. Ryzen 3000) will struggle.

## Savegame note
Saves live in `Documents\My Games\Crysis VR`. To migrate old flat-game saves, copy the `SaveGames` folder from `Documents\My Games\Crysis` into the VR folder manually.

## Uninstall
Use **Uninstall now** on this page. It opens the author's generated `Uninstall_CrysisVR.exe`; the Hub does not guess at individual Crysis files.

## Credits
- VR mod by **fholger** (Holger Frydrych) - https://github.com/fholger/crysis_vrmod
- Built on the Crysis Mod SDK with a D3D10->D3D11 bridge to OpenXR
- Original game by Crytek

## Support the developer
fholger maintains these PC VR mods in his spare time. If you enjoy them, consider supporting him:
- Ko-fi: https://ko-fi.com/fholger

>>> Maximum armor. Maximum immersion. Welcome to the island.

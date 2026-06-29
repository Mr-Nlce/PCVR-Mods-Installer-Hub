# Penumbra: Overture VR

Adds head and hand tracking to **Penumbra: Overture**, the classic survival-horror game by Frictional Games. Built in the HTC Vive era; works with modern motion controllers through SteamVR bindings.

## Requirements
- **Penumbra: Overture** on Steam (AppID 22180), owned + installed
- SteamVR
- Motion controllers

## What the installer does
1. Locates your Penumbra: Overture install in Steam (`steamapps\common\Penumbra Overture`).
2. Copies the game out to `C:\Games\Penumbra Overture VR` (the old HPL1 engine can fail under Program Files due to UAC). Your Steam copy stays untouched.
3. Downloads the VR mod and adds its files into the copy's `redist\` folder, and writes `steam_appid.txt` (22180).
4. Creates a desktop shortcut **Penumbra Overture VR** that uses the original game's icon but launches the VR executable.

## How to launch
Start **SteamVR** first, then either:
- Use the Hub's **Start in VR** button (runs `redist\Penumbra_vr.exe`), or
- Use the desktop shortcut **Penumbra Overture VR**.

> Tip: in-game, open **Options -> VR Settings** and disable the monitor mirror for better performance.

## Controls (HTC Vive layout)

### Right Controller
| Button | Action |
|--------|--------|
| [[Trigger]] | Interact / equip pointed-at item |
| [[Grip]] | Open inventory |
| [[Trackpad]] | Sprint (press) / drag items to combine (press) |
| [[Menu]] | Examine the object you are looking at |

### Left Controller
| Button | Action |
|--------|--------|
| [[Trackpad]] | Move |
| [[Grip]] | Quick-equip glowstick / flashlight |

> Built for the HTC Vive; on other headsets remap as needed in **SteamVR -> Controller Bindings**.

## Install location
Installs to `C:\Games\Penumbra Overture VR` (first writable drive: C:/D:/E:).

## Credits
- VR mod by simply-jos, fork/release by newyork167 — https://github.com/newyork167/penumbra_vr
- Original game by Frictional Games
- Source: https://github.com/simply-jos/penumbra_overture_vr

>>> No weapons. No backup. Just you, the cold, and whatever is breathing down there.

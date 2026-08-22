# Penumbra: Overture VR

## Two mods, one page

There are two Penumbra VR mods, and the installer offers both.

| | **simply-jos / newyork167** | **rubocopter (rework)** |
|---|---|---|
| State | the long-standing one | **early alpha** |
| Hands | head and hand tracking | **per-finger animation** |
| Installs into | a **copy** of the game under `C:\Games` | your **Steam** copy |
| Your Steam files | untouched | replaced, with backups |
| Undo | delete the copied folder | `Install-PenumbraVR.bat -Restore` |

**They do not collide.** Both ship a file called `Penumbra_vr.exe`, but never in
the same folder - the old mod works on its own copy of the game, the rework
merges into the Steam installation. You can have both, and which one you play is
simply which copy you launch. Nothing has to be switched off.

### The rework, in short
Per-finger hand animation from the SteamVR skeletal input: on **PS VR2 Sense**,
**Valve Index** and **Touch** controllers every finger follows its own measured
curl. Devices without skeletal input get a synthesized closing sequence - pinky
and ring first, middle follows, index tied to the trigger. All weights run
through a ~70 ms smoother with a soft deadzone, so hands rest fully open and
joints move with a little inertia rather than snapping.

**Only PS VR2 Sense is hardware-validated.** Everything else is expected to work
but has not been confirmed on real hardware.

Two limits come from the source model rather than the mod: ring and middle share
one fused mesh tube, so their tips cannot spread apart, and the thumb chain is
too short to reach the palm - it stays at its bind pose during grips. Vive wands
and the WMR fallback have no per-finger input at all and get the synthesized
sequence only.

The rework backs up every file it replaces under `.penumbravr\backup` in the game
folder and can put them all back with `Install-PenumbraVR.bat -Restore`.


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

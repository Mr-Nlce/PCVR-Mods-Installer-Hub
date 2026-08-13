# Hollow Knight VR

The classic 2D Metroidvania by Team Cherry, now playable in VR with depth-enhanced rendering. The mod separates the game's sprite layers in 3D space so your VR headset perceives depth - the game itself stays 2D, but the world reads as parallax-rich and dimensional through the headset.

**Mod**: HollowKnight_VREnhanced v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Hollow Knight (Steam App 367520) - the original Team Cherry release

## Original Hollow Knight, not Silksong

This entry is for **the original Hollow Knight** (Team Cherry, 2017, App ID 367520). For **Silksong** there's a separate Hub entry with its own installer - they're distinct games and distinct mods.

## About this mod

A community VR mod by Astienth, distributed via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

This is a **depth-enhancement mod for a 2D game** - it doesn't render the game in 3D, it spaces the existing 2D sprite layers apart so the headset reads them with parallax depth. Controls remain gamepad or keyboard. There is no ViGEmBus dependency.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1254790696502693888/1254790696502693888

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading the mod ZIP from the linked Discord post
4. Auto-locating your Hollow Knight install (Steam libraries scanned)
5. **Optionally copying the game folder** (recommended) so flat-screen play stays available from the original folder
6. Extracting the mod files into the chosen folder

## Critical heads-up: the mod blocks flat-screen mode

**Installing this mod into a game folder makes that folder VR-only.** Once the mod is installed, the game can no longer be launched flat-screen from the same folder. Same workflow as Sayonara Wild Hearts VR.

The installer offers to copy the game folder first. The default copy lives at:

```
<original-parent>\Hollow Knight VR\
```

The original Steam folder stays untouched, so:
- **Steam** keeps launching the flat-screen version from the original folder
- **The VR build** lives in the copy and is launched via `hollow_knight.exe` inside that copy (or via the Hub's "Start in VR" button, which targets the copy because the installer records that path)

If you skip the copy step, the mod installs directly into the original Steam folder, and Steam launches the VR build going forward. To get flat-screen back you'd then need to disable the mod (rename `winhttp.dll`) or verify game files via Steam.

## Controls

**Gamepad or keyboard only - no VR controller support.**

Game controls are unchanged from the flat-screen version.

### Recentering the view

Hold three buttons simultaneously: **UP + QUICKMAP + PAUSE**. On a default gamepad layout that's:
- **D-Pad / left stick UP** + **Left shoulder ([[LB]] / L1)** + **Start**

SteamVR's own recenter function also works.

### Seating

A seated experience is recommended.

## Depth tuning (optional)

The mod's per-game config file is **created after your first launch** with the mod, at:

```
BepInEx\config\HollowKnight_VR.cfg
```

Tunable values (defaults shown):

```
# Distance between sprite layers - this is what produces the depth
# effect. Higher = more pronounced depth, lower = flatter.
spaceBetweenMultiplier = 1.65

# Headset distance from the scene (X,Y,Z). If you don't know what
# you're doing, only change Z. INCREASE Z to get CLOSER to the
# scene.
VRCamDistance = 0,0,10

# Relative scale of the world.
worldScale = 1

# Relative scale of the UI.
UIScale = 1
```

And in `BepInEx\config\UnityVR_Bepinex.cfg` you can also edit:

```
# UI offset relative to headset (X,Y,Z). Smaller Z = UI closer to
# you, larger Z = further away.
canvasOffset = 0.0,0.0,1.4
```

### World-scale recipe

Increasing `worldScale` makes the world feel bigger/more present, but reduces the VR camera's 6DoF freedom (a known side effect of how the scaling is implemented). If you want to try a bigger-feeling world, Astienth suggests this combo:

```
worldScale   = 20
UIScale      = 10
canvasOffset = 0.0,0.0,12
```

The three values are interlocked - changing `worldScale` alone without bumping `UIScale` and `canvasOffset` will misalign the UI relative to the world.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1254790696502693888/1254790696502693888
- Mod download: https://discord.com/channels/1001138422972432597/1254790696502693888/1423987649785364562

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Ring the bell. Take up the nail. Hallownest waits.

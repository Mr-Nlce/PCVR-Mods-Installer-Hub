# Singularity VR Installer

Automated installer for **SingularityVR** by letsgosportsteam - a VR mod for **Singularity** (2010, Raven Software, Unreal Engine 3). It is a `d3d9.dll` proxy: it forwards every Direct3D 9 call to the real system library and renders the game in stereo to an OpenXR headset along the way, with 6-DOF head tracking, motion-controller input and a weapon that follows your hand.

**No game files are modified.** Three files go in beside `Singularity.exe`. Uninstalling is deleting one of them.

This is an alpha and has run on very few machines so far.

## Requirements

| | |
|---|---|
| Game | **Singularity (2010)** for PC - Steam or GOG |
| Headset | **Virtual Desktop with VDXR** as the OpenXR runtime - all testing has been on a Quest 3S |
| Runtime | **Visual C++ 2015-2022 Redistributable (x86)** - the installer offers to fetch it |
| OS | Windows 10 or 11 |
| Network | Strongly recommended: a dedicated router with the PC on ethernet, or Virtual Desktop's wired USB connection (currently in beta) |

**This build supports Virtual Desktop with VDXR only.** SteamVR and OpenVR are planned but not in yet.

**The x86 runtime is not optional and not the one you have.** The proxy DLL is 32-bit, so the x64 redistributable that is already on almost every machine will not do. Without the x86 one the game starts with a missing `VCRUNTIME140.dll` and nothing else. The installer checks for it and can install it for you (Windows will ask for admin rights).

## What it does
- Finds Singularity (Steam, GOG or the retail install) and drops `d3d9.dll`, `openxr_loader.dll` and `SingularityVR.ini` into its `Binaries` folder.
- Checks the Visual C++ 2015-2022 x86 runtime and installs it on request.
- Records the install so the Hub can flag new releases - every build of this mod is published as a pre-release, and the Hub is set up to follow those.

## The build of the game matters
The mod hooks the engine at fixed addresses taken from the **international** build (8 July 2010). The **German release is an older build** (28 May 2010), and on it every hook is refused - you get two flat images and no head tracking at all. Measured on such a copy: not a single draw call was ever split. After swapping in the international executable, the same test showed 445,593 split, all with parallax.

The installer checks this for you by checksum. If it finds the German build it offers to fetch the uncut package and swap the executable itself - keeping your original as `Singularity.exe.german.bak`. If the download turns out to be a page rather than a file, it falls back to walking you through it by hand.

## Before you launch - not optional
In the game's **Video Settings**, untick **every** option. **High Quality Decals** above all: it enables dynamic shadows, and those are broken in VR.

Connect Virtual Desktop **first**, then launch the game with no arguments. It starts in VR by itself.

**The first run will be at the wrong resolution.** That is expected. The mod has to inject `-ResX`/`-ResY` before the engine reads the command line - which is before it can ask the headset anything - so it queries the headset during that run and uses the answer on the next launch. Launch once, quit, launch again.

## Controls
Both Touch controllers act as a full gamepad, with haptics. Everything beyond the two long presses is Raven's own binding, passed straight through.

**Left controller**

- [[Left Thumbstick]] move / strafe
- [[L3]] dash
- [[Left Trigger]] aim
- [[Left Grip]] impulse / melee
- [[X]] age / renovate (TMD)
- [[Y]] flashlight - hold about a second for the VR settings menu instead
- [[Menu]] pause menu - hold about a second to recentre your view and seating

**Right controller**

- [[Right Thumbstick]] turn (snap or smooth, set in the settings menu)
- [[Right Thumbstick Up]] cycle weapons
- [[Right Thumbstick Down]] use a health item
- [[R3]] anti-gravity
- [[Right Trigger]] fire
- [[Right Grip]] use / reload
- [[A]] jump - hold about a second to also toggle the laser sight (you jump once on the way, since jump has to stay instant)
- [[B]] crouch

## VR settings
The in-headset panel is the intended way to change anything: weapon position and rotation, turn style, the laser pointer, occlusion mode and more. Changes apply live and are saved automatically to `SingularityVR.ini` beside the DLL.

Two traps if you edit that file by hand: it takes the **first** key of a duplicated name and silently ignores the second, and `AutoResX`/`AutoResY` are the mod's own cache of **your** headset's size - never copy them from someone else's ini.

## Known issues
- Tested on very few machines, so your experience may vary.
- Missing or culled geometry is mostly resolved outside in-engine cutscenes, where it is not fixable yet. If you see geometry missing elsewhere, set **OCCLUSION** to **DRAW ALL** on the **ADVANCED** page of the settings menu.
- Menu rotation: enter a game, pause, exit to the main menu, and the menu can come back rotated.
- If the game dies instantly with no message, that is usually a missing 32-bit `PhysXLoader.dll` - the unmodded game does it too. The project ships `setup_physx.ps1`, which fixes it from a copy already on your machine.
- `d3d9.dll` is unsigned, so SmartScreen and some antivirus will flag it.

## Switching back to flat
Use the **Flat / VR** switch on this game's page in the Hub - it renames `d3d9.dll` to `d3d9.dll.off` and one click brings VR back. To remove the mod entirely, delete `d3d9.dll`, `openxr_loader.dll` and `SingularityVR.ini` from the `Binaries` folder. Nothing else was ever touched.

That rename is also the fastest bug check: park the DLL, run the game at the same resolution, and if the problem is still there it is not this mod.

## Reporting a bug
Open an issue on the project page and attach the log from `%LOCALAPPDATA%\SingularityVR\` - `view_matrix.log` is always the run that just happened. Say which headset, which OpenXR runtime, Steam or GOG, and whether you had already relaunched once.

https://github.com/letsgosportsteam/singularity-vr-mod

## Credits
Singularity is by **Raven Software**, published by Activision. The VR mod is by **letsgosportsteam** and contains no game code or assets.

>>> Time is a weapon here. So is your other hand.

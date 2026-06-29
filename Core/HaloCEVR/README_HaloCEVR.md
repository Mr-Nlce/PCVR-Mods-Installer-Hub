# Halo CE VR

**HaloCEVR** by **LivingFray** - a full VR conversion of the **original 2003 PC version** of Halo: Combat Evolved, with 6DOF aiming and motion controls.

> This is an **external** mod: the Hub links you to the HaloCEVR installer. It injects VR into the game folder.

## Important: which version
HaloCEVR works **only with the original 2003 PC release** of Halo: Combat Evolved (retail). It is **not** compatible with The Master Chief Collection or the Anniversary remaster, and not with Halo Custom Edition.

## What you get
- 6DOF synced stereo view (a true VR camera, no AFR/3D-screen tricks)
- Tracked controllers: 6DOF weapon aiming and grenade aiming
- Functional picture-in-picture scope on appropriate weapons
- Two-handed aiming mode; swap weapons between hands; shoulder weapon holsters
- Motion-controlled melee (head-aimed), flashlight (tap your head), and crouching (detected via motion)
- Detached floating UI layer and floating crosshair
- Joystick-steered vehicles
- Rebindable controls with a left-handed preset
- Snap and smooth turning

## Requirements
- The **original 2003 PC** Halo: Combat Evolved (installed via original CD + product key) plus the **1.10 patch**
- A SteamVR-compatible headset
- **Install outside Program Files** (e.g. `C:\HaloVRMod\Halo`) or the mod's config/log won't generate without running as admin

The retail installer's default location is `C:\Program Files (x86)\Microsoft Games\Halo` (launcher: `halo.exe`). This is the retail "Halo" - **not** "Halo Custom Edition" (`haloce.exe`) and **not** the Master Chief Collection.

## How to install (external)
1. Open the info page and run the installer - it's a 5-in-1 bundle (VR Core by LivingFray, plus optional Chimera, LAA patch, DSOAL spatial audio, and the Halo Refined visuals).
2. Launch once to generate `config.txt` in the VR folder; if you set `LeftHanded=true`, also pick the left-handed SteamVR bindings.

## Known quirks
- Melee/interact use head aiming, not controller aiming
- The crosshair lights red only when you look at an enemy, not when pointing the gun
- On-screen prompts show keyboard bindings, not VR ones
- The tutorial's first "look around" step doesn't detect headset movement - wiggle the mouse to pass it
- Untested in multiplayer (the original PC release had no co-op)

## Credits
- VR mod by **LivingFray** - https://github.com/LivingFray/HaloCEVR
- Bundle installer: https://elliewasteland.github.io/HALOCEVR-Installer/ (Chimera by SnowyMouse, DSOAL by ThreeDeeJay, plus LAA and Halo Refined)
- Original game by Bungie

>>> Reclaimer, the ring is yours to walk. Finish the fight in VR.

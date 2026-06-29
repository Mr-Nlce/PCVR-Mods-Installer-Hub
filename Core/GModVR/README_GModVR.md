# Garry's Mod VR

**Mod:** VRMod x64: Ultimate Edition
**Author:** Abyss-c0re / Doom Slayer (fork of the original VRMod by Catse)
**More info:** https://github.com/Abyss-c0re/vrmod-x64
**Workshop:** https://steamcommunity.com/sharedfiles/filedetails/?id=3442302711

## What this installer does

1. Locates your GarrysMod folder via Steam
2. Checks that you are on the **x64 branch** (bin\win64). If not, opens Steam properties so you can switch to the `x86-64` beta branch
3. Offers to delete old VRMod config (recommended when upgrading from a different VR mod fork)
4. Downloads the latest native modules from GitHub and merges them into your GarrysMod folder
5. Writes `garrysmod/cfg/autoexec.cfg` with performance tweaks and an **F2 bind** for the VRMod menu
6. Opens the Workshop page so you can subscribe to the addon (or one of the two collections, see below)
7. Opens GMod properties and copies `+exec autoexec.cfg` to your clipboard so you can paste it into Launch Options

## Three ways to subscribe to the Workshop side

Directly under the title on the VRMod x64 Workshop page, there is a section labelled "In 2 collections by Doom Slayer" with both collection names. Pick one:

- **Just VRMod x64** - solo, most minimal, subscribe the addon itself
- **VRmodx64_minimalistic** - 28 items, curated must-have VR addons, recommended starting point
- **VRmodx64** - 172 items, the full VR experience. Heavy, may need pruning

Click the collection title, then "Subscribe to all".

## First launch (one-time setup)

1. Start SteamVR
2. Launch Garry's Mod. **The first time**, Steam will ask which executable to launch - pick the 64-bit version
3. Start a new game on any map (Sandbox recommended for the first test)
4. Once you spawn in, press **F2** to open the VRMod menu (the autoexec binds F2 for you)
5. On the first page of the VRMod menu, enable:
   **"Automatically start VR after map opened"**
6. Click **Start VR** once. Height calibration runs.

After this, VR starts automatically every time you load a map. No more menus, no more button presses:
**Start SteamVR -> Launch GMod -> Load a map -> VR runs.**

## Requirements

- Garry's Mod on the **x86-64 beta branch** (Steam -> Properties -> Betas -> `x86-64`)
- SteamVR

## Incompatible addons

Disable these before launching VR or they will break the mod:

- GShaderLibrary and other post-processing addons
- ReShade or any non-VR upscaling tools
- Animation-altering or collision-modifying addons
- Non-standard player models

For the first VR test, disable all other addons to confirm the base setup works, then re-enable them in batches to find any conflicts.

## Tips for better FPS

- Run GMod **windowed** at a **lower desktop resolution**
- Disable VSync and Motion Blur
- Lower Shadows and Water Reflections
- Cap FPS to your headset's refresh rate
- Avoid massive maps with heavy foliage

## If you have issues

The author's standard debugging advice: **disable ALL other addons first** to confirm whether the issue is a VRMod bug or an addon conflict.

- Setup guide video: https://www.youtube.com/watch?v=9ws95fnsqFE (func_dumbass)
- Bug reports: https://steamcommunity.com/sharedfiles/filedetails/discussions/3442302711

>>> Everything is a physics object. Everything is now a VR physics object.

# Echo Generation 2 VR Installer

Automated installer for EchoGeneration2_VR v1.0.0 by Astienth - a VR conversion of Echo Generation 2, a sci-fi deckbuilding RPG.

**OpenXR ONLY** - no OpenVR support. **NOT compatible with the free demo** - you need the full game.

## What it installs
- **EchoGeneration2_VR mod** - VR rendering and input
- **BepInEx (IL2CPP)** - mod loader

The mod files go into the **game root folder** (the folder that ends up with a `BepInEx` folder and `winhttp.dll` at its root).

## Requirements
- Echo Generation 2 owned on Steam (App ID 1115990) - the full game, not the demo
- **OpenXR runtime** - this mod is OpenXR ONLY. Set your OpenXR runtime as the system default (e.g. Virtual Desktop / VDXR).
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `Echo_Generation_2_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates the Echo Generation 2 folder and copies the mod files into the game root.

## Controls
- **KEYBOARD or GAMEPAD only.**
- **Recenter**: press **F1**, or click **both gamepad sticks** at the same time.
- **VR players**: this mod is OpenXR-only and does not read VR controllers directly. To play with your controllers, use **Virtual Desktop** and enable **Input > Use touch controllers as gamepad**.

## Configuration

`<GameRoot>\BepInEx\config\EchoGeneration2_VR.cfg`:
```
disableBloom = false           # true disables the bloom effect if it is too excessive
camOffsetDistance = 2          # higher = closer to the action. Applies during cinematics AND gameplay.
lightingDivider = 6            # higher = darker. Re-simulates post-process effects that can't be added to the VR camera.
```

## Known issues (from Astienth)
- The camera offset can be a little too close during cinematics. The game uses a custom component that dynamically changes the camera FOV to fake a zoom, which is impossible in VR. `camOffsetDistance` is a compromise so combat is not too far.
- The zombie girl's outside scenario is meant to be black-and-white, but not all of the game's post-process effects could be replicated, so that part stays in colour.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Deal the cards. Defy the cosmos.

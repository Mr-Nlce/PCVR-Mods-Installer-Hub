# StreetDog BMX VR Installer

Automated installer for StreetDogBMX_VR v1.0.0 by Astienth - VR conversion of StreetDog BMX, a cartoon-styled BMX game.

This is a basic VR mod - it adds 3D vision but no motion controls. **The mod also works with the Steam demo** of the game.

## What it installs
- **StreetDogBMX_VR mod** - VR rendering
- **BepInEx (IL2CPP)** - mod loader

## Requirements
- StreetDog BMX (full version OR demo) on Steam (App ID 2707870)
- SteamVR or any OpenXR runtime installed
- A **gamepad** (the mod has no VR-controller support and keyboard-only is impractical for a BMX game)
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `StreetDogBMX_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates StreetDog BMX, copies the mod files in, and you're done.

The first launch after installing the mod takes longer than usual - that's normal.

## Controls
- **No VR-controller support** - a gamepad is required.
- **HOLD START** to recenter the view (do this often, especially after a scene change).
- **DOUBLE-PRESS START** to toggle between 1st person and 3rd person view.

## Known issues (from Astienth)
- On launch, you may see a sky instead of the title screen. Pick Play and load the first level - the view fixes itself. The demo always shows this.
- Recenter the view often, especially after a new scene loads.
- **Black-screen rescue**: if one or both eyes are black, press `F1` (left eye) and `F2` (right eye) repeatedly to cycle through textures until both eyes show the correct image. The mod doesn't always pick the right textures automatically.

## Configuration

`BepInEx\config\Streetdog_BMX.cfg`:
```
[General]
firstPersonWorldScale = 2.2   # decrease = bigger world, increase = smaller
```

## Uninstall
Rename `winhttp.dll` in the game root folder to `winhttp_bak.dll` to deactivate the mod (game runs flat). Delete the renamed file plus `BepInEx\` and `winhttp_bak.dll` for a full uninstall.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Pegs grinding, board flipping. The street's your park now.

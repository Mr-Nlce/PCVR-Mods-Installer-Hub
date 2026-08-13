# Lunistice VR Installer

Automated installer for Lunistice_VR v1.0.0 by Astienth - VR conversion of Lunistice, a cute 3D retro platformer.

This is a basic VR mod - it adds 6DoF stereoscopic 3D but no motion controls. **The mod is NOT compatible with the demo** - you need the full version of Lunistice on Steam.

## What it installs
- **Lunistice_VR mod** - VR rendering
- **BepInEx (IL2CPP)** - mod loader

## Requirements
- Lunistice on Steam (App ID 1701800) - **full version, demo will not work**
- SteamVR or any OpenXR runtime installed
- A **gamepad or keyboard** (the mod has no VR-controller support)
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `Lunistice_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Lunistice, copies the mod files in, and you're done.

## Controls
- **No VR-controller support** - use a gamepad or keyboard.
- Press **F1** to recenter the view at any time.

## Configuration

`BepInEx\config\UnityVR_Bepinex_IL2CPP.cfg`:
```
VRCamScale = 1,1,1   # all three values together; <1 = bigger world, >1 = smaller world
VRUI scale = 2       # UI scaling - bump up or down if the UI feels wrong
```

The README states only these two values should be touched in this config.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Hop the moon. Float the stars. Land like a feather.

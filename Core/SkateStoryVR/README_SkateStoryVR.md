# Skate Story VR Installer

Automated installer for SkateStory_VR v1.0.0 by Astienth - VR conversion of Skate Story, an awesome-looking stylized skate game.

This is a basic VR mod - it adds 3D vision but no motion controls. **OpenVR ONLY** - SteamVR must be installed.

## What it installs
- **SkateStoryVR mod** - VR rendering (loaded via custom Doorstop, not BepInEx)
- **winhttp.dll** at game root and a **`VRMod\`** folder with the mod DLLs

## Requirements
- Skate Story owned on Steam (App ID 1263240)
- **SteamVR** installed and running - this mod is **OpenVR ONLY**, OpenXR runtimes alone won't work
- A **gamepad** (the mod has no VR-controller support)
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `SkateStory_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Skate Story, copies the mod files in, and you're done.

## Controls
- **No VR-controller support** - use a gamepad.
- Press **both joysticks at the same time** to recenter the view (insist if it doesn't catch first try).
- **Double-tap Start / Options** to toggle between 3rd-person and 1st-person view.

## Critical first-launch settings
- The in-game **"color bleeding"** option has been reported to cause memory usage issues. Turn it **OFF** if you run into problems.
- **Epilepsy warning**: there are slight flashes on each scene load and in a few areas.
- The mod uses **decoupled pitch**, so some camera angles can feel off compared to the flat game. Look around freely - you're in VR, that's the point.

## Configuration

After the first launch with the mod, a config file is created at `VRMod\VRMod.cfg`:
```
writeLogsEnabled = False
disableEffects   = DepthOfField
```

Available effects you can list (comma-separated) under `disableEffects`:
`VHSPro, AmbientOcclusion, AutoExposure, Bloom, ChromaticAberration, ColorGrading, ComputeBloom, DepthOfField, Grain, LensDistortion, MotionBlur, ScreenSpaceReflections, Vignette`

Also tune the in-game graphics options - those still apply on top of the mod.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Heaven needs a half-pipe. You're the only one who can build it.

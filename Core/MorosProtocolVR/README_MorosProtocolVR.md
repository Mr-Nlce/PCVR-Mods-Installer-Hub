# Moros Protocol VR Installer

Automated installer for MorosProtocol_VR v1.0.0 by Astienth - VR conversion of Moros Protocol, a pixel-art roguelite FPS set in space.

This is a full motion-controller VR mod with bHaptics + ProTube/ForceTube support.

## What it installs
- **MorosProtocol_VR mod** - VR rendering and motion-controller support
- **BepInEx** - mod loader
- **ViGEmBus driver** (optional, but required for VR controllers) - emulates an Xbox controller

## Requirements
- Moros Protocol owned on Steam (App ID 1605250)
- SteamVR or any OpenXR runtime installed
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `MorosProtocol_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Moros Protocol, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.

## Features
- Full motion-controller mapping with hotkey gesture
- bHaptics support: vest, arms, visor
- ProTube / ForceTube device support
- Rebindable controls via SteamVR Inputs

## Controls

VR controllers are mapped as an Xbox gamepad. **Aim with your dominant hand** to shoot, interact with objects, open doors. All controls are rebindable in SteamVR Inputs.

### Hotkey gesture (important!)
Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active. While the hotkey is held:
- **[[Left Stick]]** becomes the **D-Pad**
- **[[Left Stick]] click** becomes the **Back / View** button
- **[[Right Stick]] click** becomes the **Start / Menu** button

### Recenter
**Click both joysticks at the same time** to recenter the view at any moment.

### Layout reference

![Controller layout](ControllerLayout.jpg)

## Configuration

`BepInEx\config\MorosProtocol_VR.cfg`:
```
isLeftHanded         = false         # true for left-hand mode
flashlightsOnHead    = true          # false = flashlight follows dominant hand
handRotationOffsetX  = 40            # weapon angle offset; 40 is a good middle value across controller types
UIPreset             = curvedFollow  # normal | curvedFixed | curvedFollow | noPreset
useCurvedUI          = false         # only matters with noPreset
curvedUIFollowHeadset = false        # only matters with noPreset
```

## Known issues (from Astienth)
- Online co-op is **not tested**.

## Uninstall
Rename `winhttp.dll` in the game root folder to `winhttp_bak.dll` to deactivate the mod (game runs flat). Delete the renamed file plus `BepInEx\` and `winhttp_bak.dll` for a full uninstall.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Welcome to the Phobos. Try not to bleed on the consoles.

# Unmourned VR Installer

Automated installer for Unmourned_VR v1.0.0 by Astienth - VR conversion of Unmourned, a story-driven horror game heavily inspired by Visage.

This is a full motion-controller VR mod with bHaptics vest support.

## What it installs
- **Unmourned_VR mod** - VR rendering and motion-controller support
- **BepInEx (IL2CPP)** - mod loader
- **ViGEmBus driver** (optional, but required for VR controllers) - emulates an Xbox controller

## Requirements
- Unmourned owned on Steam (App ID 3528970)
- **OpenXR runtime** - this mod is OpenXR ONLY. Set SteamVR (or whatever OpenXR runtime you use) as the default OpenXR runtime in its settings.
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## Critical first-launch steps - read BEFORE installing
1. **Launch the game once in flat mode first** and pick your language. The mod can't show the language picker properly in VR.
2. After the mod is installed, launch the game and **wait a few seconds on the title screen**. The option menu opens by itself briefly. This is intentional and required.
3. **The intro cinematic starts upside down**. Click both joysticks to recenter the view as soon as you see text.
4. **Use the D-Pad (via the hotkey gesture, see below)** to navigate menus.

## How to use the installer
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `UnmournedVR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Unmourned, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.

## Features
- Full motion-controller mapping with hotkey gesture
- bHaptics vest support
- OpenXR

## Controls

VR controllers are mapped as an Xbox gamepad. Standard buttons (face buttons, triggers, sticks) work as expected.

### Hotkey gesture (important!)
Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active. While the hotkey is held:
- **[[Left Stick]]** becomes the **D-Pad**
- **[[Left Stick]] click** becomes the **Back / View** button
- **[[Right Stick]] click** becomes the **Start / Menu** button

Use this to navigate menus.

### Recenter
**Click both joysticks at the same time** to recenter the view at any moment.

### Layout reference

![Controller layout](ControllerLayout.jpg)

The same image is also pinned in the Discord post: <https://discord.com/channels/1001138422972432597/1462781954570059990/1462782122740682894>

## Configuration

`BepInEx\config\UnmournedVR.cfg`:
```
handRotationOffsetX = 40    # aim angle offset; 40 is a good middle value for Quest / Index / Vive
leftHanded          = false # true = left-handed mode
```

## Known issues (from Astienth)
- The intro scene is upside down by design (decoupled pitch). Recenter with both-stick click.
- Opening drawers can be tricky depending on hand orientation - try moving around while holding the joystick.
- The Load Save menu is invisible. It still works, you just can't see which slot you're picking. Modder plans to fix this.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Some doors should stay shut. Yours just opened.

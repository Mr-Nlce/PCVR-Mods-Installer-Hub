# Unmourned VR Installer

## About the Game

Legacy installer for Unmourned_VR v1.0.0 by Astienth. The author withdrew the mod download and recommends the game's official VR edition. This entry retains existing mod installations and can reinstall a mod ZIP you already saved; it does not install the separate official VR edition.

This is a full motion-controller VR mod with bHaptics vest support.

## What it installs
- **Unmourned_VR mod** - VR rendering and motion-controller support
- **BepInEx (IL2CPP)** - mod loader
- **ViGEmBus driver** (optional, but required for VR controllers) - emulates an Xbox controller

## Requirements
- Unmourned owned on Steam (App ID 3528970)
- **OpenXR runtime** - this mod is OpenXR ONLY. Set SteamVR (or whatever OpenXR runtime you use) as the default OpenXR runtime in its settings.
- Your own previously downloaded `UnmournedVR.zip`; the former Discord post no longer provides it.

## Critical first-launch steps - read BEFORE installing
1. **Launch the game once in flat mode first** and pick your language. The mod can't show the language picker properly in VR.
2. After the mod is installed, launch the game and **wait a few seconds on the title screen**. The option menu opens by itself briefly. This is intentional and required.
3. **The intro cinematic starts upside down**. Click both joysticks to recenter the view as soon as you see text.
4. **Use the D-Pad (via the hotkey gesture, see below)** to navigate menus.

## How to use the installer
1. Click **Install Mod** on the game tile or detail page.
2. Read the withdrawn-download notice and press [[Enter]].
3. Select your saved `UnmournedVR.zip`, or enter Q to close without changing the game.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Unmourned, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.

## Features
- Full motion-controller mapping with hotkey gesture
- bHaptics vest support
- OpenXR

## Controls

| Button | Action |
|---|---|
| [[Left Stick Click]] + [[Right Stick Click]] | Recenter the view, including the inverted intro. |
| [[Left Stick]] | With the left controller beside your head, D-pad menu input. |
| [[Left Stick Click]] | With the left controller beside your head, Back / View. |
| [[Right Stick Click]] | With the left controller beside your head, Start / Menu. |

The hotkey gesture vibrates the controller while active. The remaining bindings follow the game's Xbox-style mapping.

![Controller layout](ControllerLayout.jpg)

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

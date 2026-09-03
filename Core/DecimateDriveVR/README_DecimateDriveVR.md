# Decimate Drive VR Installer

Automated installer for DecimateDrive_VR v1.0.0 by Astienth - VR conversion of Decimate Drive, an arcade-style horror driving game.

This is a full motion-controller VR mod with bHaptics vest support. **OpenXR ONLY** - no OpenVR support.

## What it installs
- **DecimateDrive_VR mod** - VR rendering and motion-controller support
- **BepInEx (IL2CPP)** - mod loader
- **ViGEmBus driver** (optional, but required for VR controllers) - emulates an Xbox controller

The mod files go into `release\` inside the game folder, next to `release\DecimateDrive.exe`, NOT the Steam folder root.

## Requirements
- Decimate Drive owned on Steam (App ID 2427950)
- **OpenXR runtime** - this mod is OpenXR ONLY. Set SteamVR (or whatever OpenXR runtime you use) as the default OpenXR runtime in its settings.
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `DecimateDrive_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates the `release\` subfolder, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.

## Features
- Full motion-controller mapping
- bHaptics vest support (vest only, not arms or visor)

### bHaptics
Launch the bHaptics Player, turn your vest on, **then** launch the game. Haptic effect on shooting can be disabled in the config (see below) if it feels too repetitive.

## Critical recenter behaviour - read before playing

- Press left [[Y]] to recenter the view at any time.
- **When recentering, LOOK FORWARD!** Whatever direction you are looking at the moment you press [[Y]] becomes the game's forward direction.
- **Recenter after each loading screen** - known issue, Astienth is working on it.

## Controls

VR controllers, mapped roughly as follows:

**Left controller:**
- [[Stick]] — Move
- **[[Y]]** — Recenter view
- **[[X]]** — Menu / Pause

**Right controller:**
- [[Stick]] — Rotate (and adjust sliders L/R while holding in options)
- **[[A]]** — Jump
- **[[B]]** — Toggle sprint
- **[[Trigger]]** — Dash / Select in menus
- **[[Grip]]** — Toggle crouch (or R3 if `swapCrouchInput` is enabled)

### Layout reference

![Controller layout](ControllerLayout.jpg)

## Configuration

`release\BepInEx\config\DecimateDrive_VR.cfg` inside the game folder:
```
leftHanded = false # true = left-hand mode. Note: in menus, validate with LEFT trigger instead of right trigger.
swapCrouchInput = false # true = crouch becomes R3/right-stick-click instead of right grip. Useful for Index controllers where the grip can be too sensitive.
worldScale = 1 # <1 = bigger world, >1 = smaller. Modder suggests trying 0.8 for a more accurate scale.
gunHaptics = true # false disables the bHaptics effect on shooting (the cannon fires a lot, can get tiring)
```

## Known issues (from Astienth)
- **Options menu interaction is fiddly**: select inputs need to be **held down then released** on the option you want. Sliders need to be **held** while you push the joystick left/right.
- Objects between you and the VRUI (e.g. a car after a death) can block your hand clicking on the UI. Move your hand closer to the UI to interact.
- Recenter is needed after each loading screen.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Hands at ten and two. The cars are alive.

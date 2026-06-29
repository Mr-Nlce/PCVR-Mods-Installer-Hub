# House of the Dead 2 Remake VR

VR mod by Astienth for THE HOUSE OF THE DEAD 2: Remake on Steam. Motion controls + laser pointer + bHaptics support. Distributed via the FarmerTrueVR Discord server.

**Steam App ID:** 3376690
**Mod author:** Astienth (FarmerTrueVR Discord)
**Default runtime:** OpenVR (OpenXR optional via config)

## About the game

The House of the Dead 2 remake. On rails shooter, a sega classic remake. The game has some bad reviews and in Astienth's opinion is quite a lazy remake. Not the worst game, but definitely not the best. VR support should make it more fun. Wait for a sale if you can.

## How to install

The Hub installer walks you through it. Manual steps if you want them:

1. Extract the contents of `TheHouseOfTheDead2_VR.zip` into your game root folder.
2. The folder should now have a `BepInEx` folder at its root.
3. If using SteamVR, **launch SteamVR FIRST**. The mod can have trouble starting otherwise.
4. Launch the game normally via Steam.

## Features

- bHaptics (vest only) support
- Built-in laser pointer (right-stick click to toggle)
- Left-handed mode (only triggers swap)

## Controls

- VR controllers map as an Xbox controller (file included in the ZIP with diagram).
- **YOU MUST install ViGEmBus** to use VR controllers. The mod ZIP bundles `ViGEmBus_1.22.0_x64_x86_arm64.exe` under `BepInEx/redist/`. The Hub installer offers to install it for you.
- The in-game options menu shows what each button does when playing with a gamepad.

### Hotkey gesture
Hold your left controller close to the left side of your head (in real life). The controller vibrates - that means hotkey is active. While vibrating:
- [[Left Stick]] = D-Pad
- [[Left Stick]] click = Back button
- [[Right Stick]] click = Start button

### Other controls
- Both joysticks clicked at the same time = recenter view
- [[Right Stick]] click (without hotkey) = toggle laser pointer on/off

## Configuration

Two config files in `BepInEx/config/`:

**TheHouseOfTheDead2_VR.cfg:**
```
[General]
## Enable left handed mode
# Default value: false
# Acceptable values: true, false
leftHanded = false
```

**UnityVR_Bepinex.cfg** (to switch runtime):
```
## Use OpenVR or OpenXR
# Default value: OpenVR
# Acceptable values: OpenXR, OpenVR
vrApi = OpenVR
```

Note: OpenXR can interfere with gamepad controls. OpenVR is the default and recommended.

## Known issues

- The trunk scene with bonus items selection had UI display bugs with the game's postprocess. Astienth removed a few effects, so the scene looks slightly different.
- If you find a scene or menu where you can't select anything, report it on Discord.

## Uninstall / Deactivate

Rename `winhttp.dll` in the game root folder to something else, e.g. `winhttp_bak.dll`. That disables the mod without removing it.

## Credits

VR mod by Astienth. Game by MegaPixel Studio, published by Forever Entertainment. Original arcade game by Sega.

Support the modder: https://www.buymeacoffee.com/astienth4

>>> Reload. Aim. The dead are back for round two.

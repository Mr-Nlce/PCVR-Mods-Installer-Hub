# Panzer Dragoon Remake VR

The legendary Saturn rail shooter remake brought into VR with full 6dof right-hand aiming, motion-based targeting, bHaptics support, and Provolver / ProTubeVR haptic-gun support. Aim with your right hand, hold the left trigger for targeting mode, release for auto-aiming shots.

**Mod**: PanzerDragoonRemakeVR v1.0 (bHaptics + Provolver) - by Astienth, distributed via GitHub  
**Game**: Panzer Dragoon: Remake (Steam App 1178880)

## About this mod

A community VR mod by Astienth, distributed publicly on **GitHub** (no Discord login required - public download URL):

- Repo: https://github.com/Astienth/Panzer_Dragoon_Remake_VR_bHaptics_Provolver
- Direct download: https://github.com/Astienth/Panzer_Dragoon_Remake_VR_bHaptics_Provolver/releases/download/1.0/PanzerDragoonRemakeVR_bHaptics_Provolver.zip

Ships with OpenVR by default; OpenXR is supported via a config edit.

## What this Hub installer does

The bundled installer walks you through:
1. Auto-locating your Panzer Dragoon Remake install (Steam libraries scanned) and **downloading the mod ZIP directly from GitHub** - no manual download or drag-drop needed
2. Extracting the mod files into the game folder

Because the GitHub release URL is public, the installer fetches it via `Invoke-WebRequest` and unpacks it for you. If the download fails (no internet, GitHub unreachable, firewall), the installer prints the URL so you can grab the ZIP by hand and rerun.

**No ViGEmBus step** - this mod doesn't bundle ViGEmBus. VR-controller input is wired directly through OpenVR/SteamVR without a virtual-gamepad layer.

## Before launching

If you have any of the supported haptic devices, **turn them on before launching the game** - the mod detects them at startup:

- **bHaptics** vest + arms: launch the bHaptics Player and connect the devices
- **Provolver / ProTubeVR**: turn the device on

## Features

- Full 6dof right-hand motion aiming
- Targeting mode (hold left trigger, aim, release for auto-aim)
- bHaptics support (vest + arms)
- Provolver / ProTubeVR haptic-gun support
- Left-handed mode (config flag)

## Controls

VR controllers are used directly (not mapped to a virtual Xbox pad).

### Stick + button mapping

- **[[Left Stick]]** - Move dragon (only when looking forward) + navigate menus
- **[[Right Stick]]** - not used
- **[[A]]** - Menu confirm
- **[[B]]** - Menu back
- **[[X]]** - Recenter view
- **[[Y]]** - Pause menu
- **[[Left Grip]]** - Rotate view left
- **[[Right Grip]]** - Rotate view right
- **[[Right Trigger]]** - Shoot single shots
- **[[Left Trigger]]** - Hold for targeting mode, then aim with right hand. Release to shoot auto-aiming shots.

### Motion controls

Full 6dof right-hand controller. Aim and shoot with your right hand.

The "looking forward" condition on the left stick means: if you're rotating your head sideways to look at threats, the dragon won't drift in that direction. Look forward to move; look around freely without changing course.

### Controller layout image

A picture of the controls is bundled with the mod and dropped into your game root folder as `VRControls.jpg`. The same image is included alongside this README in the Hub installer folder as `ControllerLayout.jpg`.

>>> Mount up, Rider. The Empire won't fall on its own.

![Controller layout](ControllerLayout.jpg)


## Left-handed mode

The mod has its own left-handed toggle - no need to swap config files like with Dino Trauma.

Edit the file (created after your first launch with the mod):

```
BepInEx\config\com.astien.PanzerDragoonRemakeVR.cfg
```

And change:

```
leftHanded = false
```

to:

```
leftHanded = true
```

Left and right trigger functions swap, and the gun moves to your left hand.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

## Related communities

- Farmertrue VR Discord: https://discord.gg/G8zZBTGuhP
- Dteyn VR Discord: https://discord.gg/Qt7GT69Pzx


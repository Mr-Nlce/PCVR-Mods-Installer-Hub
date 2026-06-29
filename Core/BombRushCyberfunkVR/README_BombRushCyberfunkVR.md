# Bomb Rush Cyberfunk VR

Team Reptile's Jet Set Radio love letter brought into VR. Default third-person mode keeps the gamepad-driven camera and adds stereoscopic 3D; flip a config flag to switch to first-person with VR controllers as your hands.

**Mod**: BombRushCyberFunk_VR v1.0.0 - by Astienth, distributed via GitHub  
**Game**: Bomb Rush Cyberfunk (Steam App 1353230)

## About this mod

A community VR mod by Astienth, distributed publicly on **GitHub** (no Discord login required - public download URL):

- Repo: https://github.com/AstienVR/Bomb_Rush_Cyberfunk_VR
- Direct download: https://github.com/AstienVR/Bomb_Rush_Cyberfunk_VR/releases/download/1.0.0/BombRushCyberFunk_VR.zip

Ships with OpenVR by default; OpenXR is supported via a config edit.

This is a **power-HIGH** mod - the graffiti world is graphics-heavy in VR. RTX 4080-class GPU recommended.

## What this Hub installer does

The bundled installer walks you through:
1. Auto-locating your Bomb Rush Cyberfunk install (Steam libraries scanned) and **downloading the mod ZIP directly from GitHub** - no manual download or drag-drop needed
2. Extracting the mod files into the game folder

Because the GitHub release URL is public, the installer fetches it via `Invoke-WebRequest` and unpacks it for you. If the download fails (no internet, GitHub unreachable, firewall), the installer prints the URL so you can grab the ZIP by hand and rerun.

**No ViGEmBus step** - this mod doesn't bundle ViGEmBus. Third-person mode uses gamepad input natively, and first-person VR-controller support is wired through OpenVR/SteamVR directly without a virtual-gamepad layer.

## Two view modes

The mod ships with **third-person view as the default** - same camera as the original game, gamepad input, just rendered in stereoscopic 3D. To get the full first-person + VR-hands experience, you have to flip a config flag after your first launch.

### Third-person (default)

- Gamepad input
- Recenter VR view: **hold the START button**

### First-person (`firstPerson = true`)

- VR controllers act as your hands and provide all input
- See controller layout image in this folder (`ControllerLayout.jpg`)

### Full-immersive first-person (`fullImmersive = true`)

- Only meaningful when `firstPerson = true`
- The in-game head fully follows your head movements at all times
- Needs **strong VR legs** - this is the most intense view mode

## Controls

![Controller layout](ControllerLayout.jpg)

### VR controller mapping (first-person mode only)

VR controllers map **EXACTLY** as an Xbox controller:

- [[X]] → Trick 1
- [[Y]] → Trick 2
- [[B]] → Trick 3 / Cancel in menus
- [[A]] → Jump / Validate in menus
- [[Left Stick]] → Move
- [[Right Stick]] → Rotate camera
- [[Left Grip]] → Dash / turbo (LB)
- [[Right Grip]] → Slide (RB)
- [[Left Trigger]] → Toggle style (LT)
- [[Right Trigger]] → Interact (RT)
- **Recenter VR view**: click and HOLD the [[Left Stick]]

### Hotkey gesture (D-Pad replacement)

VR controllers don't have a D-Pad, so it's mapped via a hotkey combo:

1. **Press and HOLD** the right-stick click first
2. Then tilt or click the left stick:
   - **Hotkey + [[Left Stick]] tilt** → D-Pad up / down / left / right
   - **Hotkey + [[Left Stick]] click** → Dance menu

The order matters - press the hotkey first, then engage the left stick.

### Known issue

In the character selection screen the left stick can be a little tricky to trigger. Keep insisting - it'll register.

## Configuration

The config file is **created after your first launch** with the mod installed, at:

```
BepInEx\config\BombRushCyberFunk_VR.cfg
```

Options:

```
[General]

firstPerson    = false   # set true for first-person view + VR hands (default: third-person, gamepad)
fullImmersive  = false   # only with firstPerson = true: head always follows in-game head movement (needs strong VR legs)
```

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to something else, for example `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming back.

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

## Related communities

- Farmertrue VR Discord: https://discord.gg/G8zZBTGuhP
- Dteyn VR Discord: https://discord.gg/Qt7GT69Pzx

>>> Tag the city. Outrun the cops. Drop the beat.

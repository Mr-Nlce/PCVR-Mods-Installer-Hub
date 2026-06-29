# Alien: Isolation VR Mod Installer

GRAND-MotherVR transforms Alien: Isolation into an even more nail-biting
experience, capturing the claustrophobic tension of Sevastopol station.
GRAND (by JayP) builds on Nibre's original MotherVR base, adding 6DOF
motion controls and major graphical and quality-of-life improvements.

## What it installs

- **MotherVR v0.8.1** - base VR mod by Nibre
- **GRAND (latest)** - extended VR mod by JayP (from alienisolationvr.com)
- **Windows 11 registry fix** - auto-detected and applied silently if on Win11

GRAND now only needs a single DLL added to the game folder; shader patching
happens on-the-fly while loading into the game.

## What's new in GRAND v0.6.0

- Added room-scale support (physical crouching is not yet supported).
- Removed the deprecated `[Debug] CameraAim` and `OriginalInteractions`
  options from `grand.ini`.
- The pause menu is now transparent instead of black, so you can see the
  game world while paused.

## Requirements

- **Steam version** of Alien: Isolation (Epic and GOG are NOT supported)
- A headset compatible with SteamVR or Meta/Oculus Link
- A working **MotherVR v0.8.1** installation (handled by this installer)
- Windows 10 or 11

This is a test build - expect some immersion and possibly game-breaking
bugs still.

## Features

- Oculus and SteamVR support
- 6DOF hand tracking and headset tracking
- Standing and seated play, with snap or smooth rotation
- A new control set for modern headsets
- Option to play the original MotherVR mod with just GRAND's graphical
  additions (set `[Debug] OGMotherVRMode = 1` in `grand.ini`)
- Graphical fixes & enhancements:
  - Body visibility (full body / arms + hands / hands only) and HUD
    visibility options
  - Fixed high-resolution rendering; disabled object pop-in and LOD so
    everything renders at max quality
  - In-game 4K shadows option, fixed planar reflections, restored AA modes
    (FXAA, SMAA1x, SMAA2x) plus a new TAA option based on AliasIsolation
  - Smoke/fog effects no longer shift with environment lighting

## First launch

1. Fully load SteamVR Home **before** starting the game, or it may crash
   on startup
2. Launch Alien: Isolation; confirm the MotherVR message
3. In the main menu: Options -> MotherVR -> VR Runtime, choose Oculus or
   SteamVR for your headset
4. If you chose SteamVR: start SteamVR, then restart the game

## Controls

- **Recenter:** [[Left Grip]] + [[Right Grip]] (still occasionally needed after
  certain animations)
- **Flashlight:** hold the right controller near your headset and press
  Interact [[A]], or just press [[RS]]
- **D-pad** (minigames / terminal keypads): hold [[Left Grip]] + use [[Left Stick]]
- Controls are not configurable - the fixed MotherVR control set is used

## Things to note & tweaks (grand.ini)

- The headset auto-recenters when first loading a map; your physical torso
  still needs to face the same direction the whole session. Toggle via
  `[OpenVR] RecenterOnFirstLevelLoad`
- If the camera doesn't move forward after loading or a suit change, press
  [[Left Trigger]] twice (crouch + uncrouch) to reset it
- Smooth turn feels slow by default - set `SmoothRotationSensitivity = 0.4`
- Seated play: if you're above the character, set `HeightOffset = 0.5`
- TAA sharpening via `[TAA] SharpeningStrength`; higher base resolution +
  render scale gives a better result

## Known issues

- **Disable SteamVR Theatre Mode** (VR Settings -> Dashboard -> turn off
  "Present Non-VR Applications on Theater Screen Upon Launch")
- Steam Link + Quest: hands may have the wrong offsets
- Aimed weapons can fail to fire at certain low/high angles
- Index controllers: [[A]]/[[X]] buttons may need manual mapping (ambiguity with
  [[Grip]] button IDs)
- Terminal/rewire activation distance is unchanged, so text can be hard to
  read if activated from too far away
- TAA: noticeable fade-in on terminal screens; glasses and transparent
  objects still shimmer

## More info

https://www.alienisolationvr.com

## Support JayP

JayP develops the GRAND-MotherVR mod, which adds 6DOF motion controls and
major QoL improvements on top of Nibre's original MotherVR base. If you
enjoy the work, consider supporting him:
- https://ko-fi.com/jayp

>>> Sevastopol is quiet. Too quiet. Mind the vents.

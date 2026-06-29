# ULTRAKILL VR Installer

Automated installer for VRTRAKILL_FRAUD v2.0.0 by Squaresweets — full VR support for ULTRAKILL with motion controls.

## What it installs
- **Steam depot build** — pinned ULTRAKILL "first fraud hotfix" (required, current Steam version not supported)
- **BepInEx 5.4.23.2** — mod loader
- **VRTRAKILL_FRAUD v2.0.0** — VR mod with full motion controls

## Requirements
- Steam installed with ULTRAKILL owned
- SteamVR installed
- Internet connection

## How to use
Click **Install Mod** on the game tile or detail page and follow the prompts.

The installer will guide you through the Steam Console depot download, then handle everything else automatically.

## Important: Pinned game version
VRTRAKILL_FRAUD requires the ULTRAKILL build from the "first fraud hotfix". The installer downloads this as a **separate copy** — your retail ULTRAKILL is untouched.

Depot command used:
```
download_depot 1229490 1229491 5628746843149106870
```

## Controls

![Controller layout](ControllerLayout.jpg)

- **Left stick:** Move; press = Jump. **Left face buttons:** [[X]] Whiplash,
  [[Y]] Dash, Stick Switch Arm
- **[[Left Trigger]]:** hold = Punch. **[[Left Grip]]:** hold = Punch
- **Right stick:** turn left/right / navigate the weapon wheel; press = Slide
- **Right buttons:** [[A]] press = last equipped weapon, hold = open weapon
  wheel, double-press = pause; [[B]] Change Variation
- **[[Right Trigger]]:** Primary Fire. **[[Right Grip]]:** Alternative Fire

## First launch
- Start SteamVR **before** launching ULTRAKILL
- Launch via the **desktop shortcut**, NOT via Steam
  (Steam would launch your retail version)

## Known issues
- Portals in mirrors don't render correctly
- Minor flickering when going through portals
- Whiplash is buggy through portals
- Oil and blood (except 7-S) don't render
- HUD sometimes disappears
- No enemy models in shop

## Source
VRTRAKILL_FRAUD: https://github.com/Squaresweets/VRTRAKILL_FRAUD

>>> VIOLENCE. PERFECT DARK. IN VR.

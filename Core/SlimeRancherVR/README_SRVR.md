# Slime Rancher VR Mod Installer

Automated installer for **SRVR** by Atmudia — full 6DOF VR with motion
controls for the *entire* game (not just the short official VR Playground).
Explore the Far, Far Range in immersive VR.

## What it installs
- **SRML v0.2.1** — Slime Rancher mod loader
- **SRVR v1.1** — full VR mod with motion controls

## Features

- **The whole game in 6DOF VR**, not the limited official VR Playground
- **Hand-operated vacpack** — aim and vac slimes with your controller
- **Grab and throw** slimes and food with your hands
- **VR locomotion** with smooth or snap turning
- **Distance grab** — pull objects to you from range (on by default)
- Built using SteamVR + Unity XR, with VR init code shared from VHVR

## How to use

1. Click **Install Mod** on the game tile or detail page
2. The SRML installer GUI opens — follow its prompts
3. SRVR.dll is placed automatically into `SRML\Mods\`
4. The installer launches Slime Rancher once for a required one-time VR patch

## IMPORTANT — First Launch Patch

The game must run **once without SteamVR** to patch itself:
- If prompted: accept VR Playground DLC uninstallation
- When asked to "optimize for VR": choose **NO** (antivirus false positive risk)
- Let the console window finish, then close the game

After this first run, the game will **auto-start SteamVR** when you launch it (**Start in VR** in the Hub or via Steam).

## Playing in VR

1. Start SteamVR (first time only — auto-starts from second launch onwards)
2. Launch Slime Rancher via Steam

## VR configuration

Adjustable in **Options -> Other tab**:
- **Switch Hands** (default off) — swap the primary-hand controls
- **Snap Turn** (default off) — snap turning instead of smooth
- **Snap Turn Angle** (default 45 degrees)
- **Turn Sensitivity** (default 1.0) — smooth-turn speed
- **Distance Grab** (default on) — grab objects from range
- **Height Adjust** (default 0.0) — HMD height offset
- **Static UI Position** (default on) — UI stays fixed in the world instead
  of following the camera

## Play without VR
Add this to your Steam Launch Options:

```
-novr
```

## Source
SRVR: https://github.com/Atmudia/SRVR
SRML: https://github.com/SlimeRancherModding/SRML

>>> Vacpack ready. The plorts won't wrangle themselves.

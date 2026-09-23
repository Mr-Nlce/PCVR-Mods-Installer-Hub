# Valheim VR Mod Installer

Automated installer for **VHVR** by Brandon Mousseau (manicmoose99) &
Maddy25 — native OpenVR support in full stereoscopic 3D, with full motion
controls. Become a Viking and explore the tenth Norse world in first-person VR.

## What it installs

- **BepInExPack Valheim 5.4.2350** — the required mod framework
- **VHVR-Mod v0.10.5** — the current VR mod

## Current release

VHVR 0.10.5 updates the mod for Valheim 1.0.15. BepInExPack Valheim
5.4.2350 carries BepInEx 5.4.23.5 and fixes loading plugins whose semantic
versions contain prerelease suffixes. Its manifest declares no dependencies.

## Requirements

- Valheim owned and installed on Steam
- SteamVR installed, and an HMD that supports OpenVR/SteamVR
- Motion controls supported on Oculus Touch and Valve Index; Vive bindings
  are included but may need tweaking

## How to use

Click **Install Mod** on the game tile or detail page. The installer finds
your Valheim folder and installs BepInExPack and VHVR automatically.

## Features

- **Motion-controlled melee** — swing your weapon to attack, or punch with
  bare hands when unarmed
- **Motion archery** — draw the bow and aim arrows by hand
- **Point-and-click building** — reach around objects to snap pieces into
  hard-to-reach spots
- **Fishing**, plus upper-body and finger tracking
- **Multiplayer motion tracking** — other VR players see your gestures
  (wave hello to your friends). Non-VR players will see you without upper-
  body animations
- **Roomscale options**: roomscale sneak (physically crouch), recenter
  pose, and seated play all configurable

## Controls

Oculus Touch / Index layout:

![Controller layout](ControllerLayout.jpg)

| Button | Action |
|---|---|
| [[Left Stick]] | Move; click to toggle the map |
| [[Y]] hold | Left-hand quick switch |
| [[Left Grip]] | Grab and holster weapons |
| [[Right Stick Left / Right]] | Rotate |
| [[Right Stick Up]] | Sprint |
| [[Right Stick Down]] | Crouch |
| [[Right Stick Click]] | Toggle menu |
| [[A]] | Jump; in build mode hold grip and press to remove an object |
| [[B]] hold | Right-hand quick switch |
| [[Right Grip]] | Grab; while building, hold and rotate with the right stick |
| [[Right Trigger]] | Use / place / primary laser-pointer click |
| [[Left Trigger]] | Click modifier; split inventory stacks |

## Setup tips

- In Valheim's Steam properties, **disable "Use Desktop Game Theatre while
  SteamVR is active"**, or VR may open on the flat theatre screen
- **Disable Vulkan** in Valheim's launch options — VHVR runs on the DirectX
  renderer
- No Steam launch parameter is needed — BepInEx starts automatically

## Compatibility notes

- Texture mods and most content mods generally work
- Mods that change controls or add custom weapons can conflict with motion
  controls, since VHVR modifies core mechanics to implement them
- Valheim updates occasionally break the mod until VHVR is patched — check
  the maintained GitHub releases if something stops working after a game update

## More info

https://github.com/brandonmousseau/vhvr-mod

>>> Odin is watching. Swing that axe in VR!

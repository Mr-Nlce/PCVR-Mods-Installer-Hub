# Valheim VR Mod Installer

Automated installer for **VHVR** by Brandon Mousseau (manicmoose99) &
Maddy25 — native OpenVR support in full stereoscopic 3D, with full motion
controls. Become a Viking and explore the tenth Norse world in first-person VR.

## What it installs

- **BepInExPack Valheim 5.4.2333** — the required mod framework
- **VHVR-Mod v0.9.21** — the VR mod

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

- **Left:** [[Stick]] = Move, press = toggle Map; SteamVR Menu; Toggle
  Inventory; [[Y]] = press & hold for Quick Switch; [[Grip]] = Grab (weapon
  holstering)
- **Right:** [[Stick]] Left/Right = Rotate, Up = Sprint, Down = Crouch, press =
  toggle Menu; [[A]] = Jump (Build Mode: hold Grip to remove object); [[B]] = press
  & hold for Quick Switch; [[Grip]] = Grab (hold while building, then use the
  right stick to rotate objects)
- **Triggers:** Right = Use / place object / left-click with laser pointers;
  Left = click modifier (split inventory stacks); right-click brings up the
  Build Menu in build mode

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
  the Nexus page if something stops working after a game update

## More info

https://www.nexusmods.com/valheim/mods/847

>>> Odin is watching. Swing that axe in VR!

# Deep Rock Galactic - VRG VR Mod Installer

Guided installer for VRG (Full Virtual Reality Mod) by Kosro, HerrFristi,
and Alch3m1st. Rock and Stone, in VR!

## Prerequisites

- **Complete the tutorial cave** in Deep Rock Galactic before running this
  installer — the VR mod will not work correctly without it
- SteamVR installed
- A free mod.io account (linked to Steam)

## What this installer does

1. Backs up your Input.ini (controller config)
2. Downloads and installs Config.zip (VR controller bindings) into the game folder
3. Copies the required Steam Launch Options to your clipboard and guides you through setting them
4. Opens mod.io so you can subscribe to VRG
5. Explains the required two-launch first-time setup

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.

## Required Steam Launch Options

```
-overridenohmd -dx11
```

The installer copies these to your clipboard automatically. DX11 is strongly
recommended over DX12: it is much more stable and usually fixes camera
jittering/shaking and most visual glitches.

## mod.io Setup

After subscribing on mod.io:
1. Launch Deep Rock Galactic (flat, without VR)
2. Go to the Modding menu (gear icon in Space Rig)
3. Find VRG — it may show as Outdated
4. Uncheck **Disable Outdated Mods**
5. Click **Active** next to VRG to enable it
6. Close the game

## Two-Launch First-Time Setup

**Launch 1:** Installs VR bindings — reach the Space Rig, then close the game.
**Launch 2:** Fully working VR — your dwarf spawns directly in VR.

If you cannot move or do anything in VR, you almost certainly skipped the
second launch. The bindings are only applied the *second* time the game
starts.

## Controls

| Action | Button |
|--------|--------|
| Walk | [[Left Stick]] |
| Rotate / rotate map | [[Right Stick]] |
| VR settings menu | [[Right Stick]] Press |
| Mine | Right [[B]] |
| Jump (hold for hover boots) | Right [[A]] |
| Use / reload | Left [[B]] |
| Map in front of you | Left [[A]] |
| Fire | [[Trigger]] |
| Grab weapon / item | [[Grip]] near holster |
| Power attack | [[Trigger]] while swinging pickaxe |
| Recall sentries | Long-press Left [[B]] |
| Useful menu | Hold [[Left Trigger]] (empty hand) |
| Toggle VR off/on | Hold [[Right Stick]] 2 sec (Space Rig) |

You have five holsters: one on each leg, one on the torso, and one behind
each shoulder (the shoulder ones are not visible). To open the Space Rig
menus, press Left [[B]] when standing next to one (like the 'E' key in flat mode).

## Gestures

- **Call Molly:** raise both empty hands for ~1 second
- **Rock & Stone!:** raise the pickaxe and an empty hand above your head
  (or both empty hands in the Space Rig)
- **Shout for attention:** wave a hand above your head
- **Toggle flashlight:** place a hand above your head and pull the trigger

## Performance

- Set **Shadows, Post-processing and Effects** to **Low** — you can keep the
  rest on Ultra without much impact
- If Low still isn't enough, install VRPerfkit (quick and easy): it makes a
  real difference. https://github.com/fholger/vrperfkit
- Try the in-game upscaling setting in the Graphics tab for an extra boost
- On Quest, Virtual Desktop or Steam Link generally run better than
  Oculus/Air Link (Air Link has minor hand-animation and item-offset bugs,
  but is still very playable)

## Troubleshooting

- **Can't move / do anything:** make sure you launched the game a second
  time after installing (bindings apply on the second launch). Also confirm
  Config.zip unzipped fully — Windows' built-in unzipper sometimes misses
  files, so use 7-Zip or copy the files in manually.
- **Stuck on a black loading screen:** press the Right Stick to escape, then
  disable loading-screen masking in the VR options menu and restart.
- **Stuck on the SteamVR screen:** add `-openvr` to the launch options and/or
  set the game EXE to Windows 7 compatibility mode.
- **Camera jitter / shaking:** use DX11, not DX12. If it persists it usually
  means performance is too low — lower settings or use upscaling.
- **Head in the floor/ceiling on spawn:** recenter height in the VR settings
  menu (Left Stick press -> Recenter Height). Putting the headset on before
  the "Press any key" screen avoids it.
- **Crashes:** switch between DX11/DX12 (DX11 is usually more stable), or set
  SteamVR "Throttling behavior" to Fixed.

Note: there is no VRIK — other players see you as a normal flat-screen player.
Keyboard-and-mouse-only play is not currently supported.

## Source

VRG: https://mod.io/g/drg/m/vrg

>>> Rock and Stone, Miner!

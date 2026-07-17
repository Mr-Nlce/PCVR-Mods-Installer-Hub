# Sonic Robo Blast 2 VR Installer

Automated installer for SRB2-VR by RaYRoD-TV - a native PCVR (OpenXR)
port of Sonic Robo Blast 2, the long-running fan-made 3D Sonic
platformer. Built directly on the current official release (2.2.15)
as a fork of STJr/SRB2. Full VR controller support and
quality-of-life fixes, on the same SRB2 2.2.15 base.

## What it does
1. Downloads the latest SRB2-VR full bundle from GitHub (auto-updates
   to whatever release is newest; falls back to a pinned build if the
   API is unreachable)
2. Extracts the complete game to C:\Games\Sonic Robo Blast 2 VR -
   game and all assets included, no Steam copy needed
3. Creates a desktop shortcut
4. Records the release tag so the Hub's tile flips to Update when a
   new release lands

## Why this port
The older SRB2 VR build was never open sourced and its developer
disappeared - it was stuck on an outdated game version and did not
support newer headsets. SRB2-VR fixes that: it tracks the current
SRB2 release, is fully open source (GPL, same as SRB2), and targets
plain OpenXR - so it runs on any conformant runtime (SteamVR,
Virtual Desktop VDXR, Oculus/Meta, Pimax) instead of being tied to
one vendor.

## Requirements
- Windows 10/11, 64-bit
- Any OpenXR runtime (SteamVR, Virtual Desktop, Meta, Pimax)
- No purchase and no base game needed - free, standalone fan game

## How to play
1. Put your headset on
2. Launch via the desktop shortcut or "Start in VR" in the Hub
3. Headset on = boots straight into VR. Headset off = regular SRB2.
4. Options -> VR Options has everything: VR mode Auto/On/Off, world
   scale, screen distance/size, HUD opacity, recenter. The console
   has vr_mode, vr_scale and vr_recenter.

## VR controls (native OpenXR profiles)
Every button does something:
- **[[Left stick]]:** move / **[[Right stick]]:** turn
- **[[A]]:** jump / **[[X]]:** spin
- **[[Right trigger]]:** throw ring (fire) / **[[Left trigger]]:** fire normal
- **[[Right grip]] (hold):** lock on / **[[Left grip]]:** toss flag (CTF)
- **[[B]] / [[Y]] / [[Left-stick click]]:** Custom 1-3
- **[[Right-stick click]]:** switch first/third person
- In menus: sticks work as a d-pad, A or right trigger confirms, B or
  left trigger backs out, left-stick click re-centers the screen
- Native profiles: Quest 3 (Touch Plus), Quest/Rift Touch, Valve
  Index, HP Reverb G2, WMR wands, Vive wands
- A regular gamepad and mouse/keyboard still work too

## What you get
- Head-tracked stereoscopic VR through SRB2's own camera and
  renderer - it feels like the normal game, in VR. First and third
  person, toggled any time.
- Full menus, HUD and console in the headset on a world-locked
  floating screen from the moment the game boots; it re-centers
  automatically when you put the headset on
- The desktop window follows your head while you play, so you can
  record or stream what you actually see (vr_mirror in the console
  turns it off for the old flat view)
- World Scale changes are visible per tap, with a readout showing
  how big the world feels
- The crosshair is off in VR (vr_crosshair brings it back); HUD
  opacity can no longer be set invisible

## Updates
The Hub checks the GitHub latest release in the background and flips
the game tile to Update when a new build lands. Rerun this installer
and pick Update - your saves, addons and settings are kept (SRB2
stores them under your user profile, not in the game folder).

## Mod page
https://github.com/RaYRoD-TV/SRB2-VR

## Credits
Sonic Robo Blast 2 is by Sonic Team Junior - this is a fork of
STJr/SRB2 and all credit for the game belongs to them; the full
bundle repackages their freely distributed 2.2.15 assets unmodified.
Sonic Team Junior is not affiliated with SEGA; no ownership is
claimed of SEGA's intellectual property.

>>> Gotta go fast. The rings are RIGHT there now.

# Super Mario 64 VR

Super Mario 64 in immersive VR, built on the **sm64coopdx** PC port. With a headset on, the game renders in VR and you can lean around and look into the world. With no headset it just runs as the normal flat game - same exe, it works out which one you want on its own.

**Mod**: sm64coopdx VR - by RaYRoD (VR work), on sm64coopdx by the Coop Deluxe Team
**Source**: https://github.com/RaYRoD-TV/sm64coopdx-vr

## About

Tested on Quest 3 and Pimax Dream Air, but it should run with any PCVR / OpenXR runtime. Super Mario 64 belongs to Nintendo - **you bring your own Super Mario 64 US ROM**. Nothing from Nintendo is in the repo or downloaded; coopdx reads the ROM locally when the game starts and it never leaves your machine.

## What this Hub installer does

1. Downloads the latest sm64coopdx VR release from GitHub
2. Installs it to `C:\Games\Super Mario Coop VR` (or a folder you pick)
3. Lets you drop in your Super Mario 64 US `.z64` ROM (set up as `baserom.us.z64`), or skip and drop it on the game window on first run
4. Creates a desktop shortcut

## Providing the ROM

Put your Super Mario 64 US ROM in the game folder named `baserom.us.z64`. On first run you can also just drag any `.z64` onto the game window and it sets that up for you.

## Playing

Launch the `Super Mario Coop VR` desktop shortcut (or `sm64coopdx.exe`). Start your VR runtime first (Quest Link, Virtual Desktop, SteamVR) if you want VR; otherwise you get the flat game. Solo play: click **Play** on the main menu - fully offline, no server screens. Co-op still works (someone can join your IP, or use **Host**).

## VR controller layout

The layout is fixed and works the same on every install:

| Control | Does |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Camera (C buttons) |
| [[A]] | Jump |
| [[B]] | Punch |
| [[Left Trigger]] | Crouch / ground pound (Z) |
| [[Right Trigger]] | R |
| [[Grip]] | Grab and throw objects (when in reach) |
| [[Menu]] (left) | Pause (Start) |
| [[Right Stick]] click | Cycle the VR mode |
| [[X]] / [[Y]] | X / Y |

Menus: move the cursor with a stick, [[A]] select, [[B]] back, triggers flip pages. Rumble plays through the controllers.

Gamepads (DualSense, DualShock 4, Xbox, Switch Pro, any SDL controller) and mouse & keyboard also work - in VR your head moves the view on top of whichever input you use.

## VR menu

All VR settings are in-game: pause and open the **VR** button (right after Cheats). It has the VR mode, diorama distance/size/height, menu & HUD size, stereo depth, head motion, first-person toggles, Hide HUD and camera anti-clip, plus Reset to Default. Cycle the VR mode (Diorama / Third-person / First-person) with **D-pad up** or **F10**. Each mode remembers its own settings, saved between launches.

## Credits

sm64coopdx by the Coop Deluxe Team. VR work by RaYRoD. Super Mario 64 belongs to Nintendo - bring your own ROM.

>>> Wahoo! Grab your cap and go bag every last star.

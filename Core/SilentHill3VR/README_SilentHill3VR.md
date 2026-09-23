# Silent Hill 3 VR

Silent Hill 3 VR adds stereoscopic 6DOF rendering, roomscale movement and
motion-controlled weapons to the original PC game. By NotGodlikeUwU.

## Before setup

You need your own installed copy of Silent Hill 3 with `sh3.exe`. The game
is not sold by the current PC stores, so use **Locate game** on this page,
or drag `sh3.exe` into the installer when asked.

The VR mod requires two components:

- **Silent Hill 3 PC Fix by Steam006.** Its download page is opened when
  needed. Download the ZIP, return to setup and press Enter, or drag the
  downloaded ZIP into the window. The Hub checks the archive and
  handles the archive password.
- **Zealot's Camera Mod.** The Hub downloads, checks and installs v1.0
  automatically.

The VR release itself auto-updates from the author's GitHub releases.
Existing files are backed up before replacement. Your `sh3vr.ini` and
`sh3vr_weapons.ini` settings are retained during updates and removal.

The current **Pre-Release 1.0.2** retains the locomotion and shoot-while-running
work, and fixes the late-game boss fight plus melee weapons. The separate
Steam006 PC fix and Zealot camera mod remain required. If the game shows only
a grey screen, use the included `GRAY SCREEN FIX` configuration as documented
by the publisher. Meta Horizon Link remains reported as potentially incompatible;
use another confirmed OpenXR route if it does not initialize.

## Starting it

Start your chosen OpenXR runtime, then use **Start in VR** here or the
**Silent Hill 3 VR** desktop shortcut. Current builds include SteamVR support.
Meta Quest 3 through Virtual Desktop remains the author's validated setup;
other headsets and runtime combinations still need testing.

Use the **Flat / VR** switch on this page whenever you want to start the
original game without loading the VR layer.

## Controls

- [[Left Stick]] - move and strafe
- [[Right Stick]] - turn
- [[Right Stick Click]] - Tab / camera control
- [[Left Stick Click]] or [[Left Grip]] - run / defend
- [[Left Trigger]] - aim
- [[Right Trigger]] - fire or attack
- [[A]] - action / confirm
- [[B]] - cancel / pause
- [[X]] - inventory
- [[Y]] - map
- [[Left Menu]] - cancel / pause

Press [[F1]] for the Camera Mod menu and [[F2]] to toggle its camera.
Resolution and FPS lock can be adjusted in `sh3vr.ini`. Per-weapon tracked
positions and aim offsets are stored in `sh3vr_weapons.ini` and reload
while the game is running.

## Current pre-release limitations

Some models or textures may disappear in places. The intro environment,
sewer reflections, shadows, blood and muzzle flashes can also render
incorrectly. Knife hit registration and the experimental noise-effect fix
still need testing. A complete playthrough has not yet been validated.

## Removing it

**Remove SH3 VR** removes only the VR layer and restores files that existed
before setup. The PC Fix, Camera Mod, saves and settings stay in place.

After that, **Remove prerequisites** can remove only the PC Fix and Camera
Mod files that this Hub installed. It refuses to run while the VR layer is
still present. Modified files are never silently deleted.

Project page:
https://github.com/NotGodlikeUwU/Silent-Hill-3-VR-Mod

Required PC Fix:
https://community.pcgamingwiki.com/files/file/1331-silent-hill-3-pc-fix-by-steam006/

Camera Mod:
https://github.com/zealottormunds/sh3cammod

Silent Hill 3 and its VR modifications are community projects. They are
not affiliated with or endorsed by Konami.

# Metal Gear Solid V: The Phantom Pain VR

MGS5VR is an experimental native OpenXR mod with true stereo rendering, tracked hands, motion-controlled aiming, a left-wrist HUD and VR-first field controls.

## About the Game

Return to Afghanistan and the Angola-Zaire borderlands as Venom Snake, building Diamond Dogs while infiltrating large open missions. This VR build targets the Steam edition of The Phantom Pain version 1.0.15.4.

## Before installation

- Close the game completely.
- The current publisher build requires The Phantom Pain 1.0.15.4, an active PC OpenXR runtime and the Microsoft Visual C++ x64 runtime.
- Quest 3 with Touch controllers is tested. Other headsets and controllers remain unverified.
- MGS5VR uses `dinput8.dll`. The Hub backs up an existing file, but another proxy mod using that filename cannot operate at the same time.

## How to play

1. Connect the headset and select its software as the active OpenXR runtime.
2. Launch MGSV normally through Steam and use the **Action Type** controller layout.
3. Load **Continue → Resume Game** before entering VR.
4. Tracked VR enters automatically. Optional presentation and recenter bindings
   can be changed in `mgs5vr-controls.ini`.

Title screens, loading screens and some cutscenes can remain on the large in-headset screen before tracked VR is entered.

For a new save, finish the opening hospital prompts and character creation in flat mode before entering VR. If you start directly in VR, press Enter when the bed scene is visible from its shadow on the wall. If character creation appears only as a pale blue-white screen, open the Meta dashboard and complete it on the desktop monitor.

## Controls

![MGS5VR Quest Touch field controls](metal-gear-controls.jpg)

| Button | Action |
|---|---|
| [[Left Stick]] / [[Right Stick]] | Move / turn |
| [[Left Stick Click]] | Sprint |
| [[Right Stick Click]] | Quick dive |
| [[Right Grip]] / [[Right Trigger]] | Ready weapon / fire |
| [[Right Grip]] + [[Left Stick Click]] | Binocular zoom |
| [[B]] | Reload |
| [[Right Stick Down]] tap / hold | Crouch or stand / prone |
| [[Y]] | Interact / pick up |
| [[Left Trigger]] + [[Right Stick]] | Hold trigger and select from the wrist picker |
| [[Menu]] tap / hold | iDroid / pause |
| [[Menu]] + [[A]] hold | Toggle complete native-button mode |

## Current experimental-2026-09-20 update

This build changes sprint to left-stick click, adds right-grip plus left-click
binocular zoom, configurable smooth/snap/off turning and a native vehicle-camera
path. A complete native-button mode is available by holding [[Menu]] + [[A]].
The release also supplies an external `Edit-Controls.cmd` tool that validates
bindings before saving and keeps a backup of the previous controls file.
The September 20 build fixes Steam startup by supplying the game identity on
direct headset launch, restores the tap/hold iDroid and pause behavior, makes
right [[B]] return through iDroid categories and lets a held [[B]] escape the
FOB tutorial lock. Wrist/equipment interaction, binocular eyes, peripheral
world rendering, LOD behavior and default smooth turning were also refined.
Existing settings are preserved. Ground Zeroes, physical punches, binocular
zoom and every full-body command path remain unfinished.

## Recommended display settings

Start with Windowed mode, Post Processing High for anti-aliasing, Depth of Field disabled and Motion Blur off. Image quality and stable frame rate depend on the headset resolution and PC.

## Experimental status

Native binocular marking, powered arms, physical body grabs, enemy motion-hit reactions, sustained vehicle control and every gameplay state are not fully implemented or headset-tested. Motion melee and driving remain experimental. This release does not promise complete campaign coverage or a locked 90 FPS.

## Updates and removal

The installer follows the newest GitHub prerelease and deliberately selects the MGS5VR ZIP rather than the separately attached controls image or SVG. It runs the release's owned-game importer before changing the game folder, then installs the required binocular model/material, controls validator and editor. Updates preserve both `mgs5vr.ini` and `mgs5vr-controls.ini`. Use **Uninstall now** on this page to remove only unchanged MGS5VR-owned files and restore a prior `dinput8.dll`; settings, saves and unrelated files remain.

## Credits and support

- MGS5VR by [nikamigaming-create](https://github.com/nikamigaming-create/MGS5VR)
- [GitHub releases](https://github.com/nikamigaming-create/MGS5VR/releases)
- Community project, not affiliated with Konami.

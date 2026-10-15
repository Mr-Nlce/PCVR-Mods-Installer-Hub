# Little Witch Nobeta VR

## About the Game

*Little Witch Nobeta* is a 3D action shooter and Souls-like adventure. A young witch with no memory of her past explores an ancient castle, dodging enemies while using elemental magic and charged attacks. [NobetaVR by Pk-c](https://github.com/Pk-c/WitchNobetaVR) changes the third-person game into a first-person VR experience with tracked hands. It is still a work in progress.

## What the VR mod adds

- A head-tracked, six-degree-of-freedom first-person view. Movement follows headset direction, and physical room-scale movement follows the character while respecting world collision.
- A staff held by your tracked hands, including physical melee hits and timed parries. The game takes over hand animation for cutscenes and menus.
- Health, stamina and mana on a left-wrist display, plus menus and effects adapted for VR.
- Touch-style controls and a VR settings menu with snap or smooth turning and remapping.

## Install, update and launch

Install your own [Steam copy of Little Witch Nobeta](https://store.steampowered.com/app/1049890/Little_Witch_Nobeta/) first. **Install / Update** on this page takes a Windows package from the [publisher's GitHub releases](https://github.com/Pk-c/WitchNobetaVR/releases), including prereleases, and places its BepInEx and OpenXR files beside `LittleWitchNobeta.exe`. The Hub checks required files before recording the installed version; run the installer again for a later release. Pre-existing files replaced by the Hub are backed up.

Start the game normally through Steam or use **Start in VR** here. On the first modded launch, BepInEx may generate game-specific interop assemblies; the publisher says this can take around fifteen seconds and requires a network connection once. Give that first launch time to finish before deciding it has stalled. The Hub has verified the package layout in an isolated fixture; a live game, headset and controller run has not been confirmed here.

The reviewed [v0.1.1 release](https://github.com/Pk-c/WitchNobetaVR/releases/tag/v0.1.1)
improves the Steam Frame controller mapping. The complete Windows archive keeps
the same BepInEx and OpenXR paths as v0.1.0, so an in-place Hub update preserves
the existing ownership backup and user files.

## Controls

Read these before playing: several actions use holds or combinations that are easy to miss. The mappings below are from the [publisher's controls](https://github.com/Pk-c/WitchNobetaVR#controls).

| Button | Action |
|---|---|
| [[Left Stick]] | Move forward, backward or sideways relative to your gaze |
| [[Right Stick]] | Turn; snap by default, smooth turning in VR settings |
| [[Left Stick Click]] | Run |
| Hold [[Right Stick]] | Open the spell wheel; point toward a spell and release |
| [[A]] | Jump or advance dialogue |
| [[B]] | Dodge; timed use can recover in the air or on the ground |
| [[X]] | Use the selected item |
| [[Y]] | Interact |
| Hold [[Y]] for two seconds | Open the game's pause menu |
| [[Left Trigger]] | Pray; hold to charge a spell ultimate |
| [[Right Trigger]] | Shoot |
| [[Left Grip]] | Cycle items; a tap is enough |
| [[Right Grip]] | Focus the held shot |
| [[Left Grip]] + [[Right Grip]] | Recenter the mod after using the headset's recenter function |
| [[Left Stick Click]] + [[Right Stick Click]] | Open the mod's VR settings |
| [[Swing staff]] | Melee attack; time the swing just before an incoming hit to parry |

At a statue, use [[Left Grip]] / [[Right Grip]] to spend soul essence or trade. Use [[Left Trigger]] / [[Right Trigger]] there to switch costumes.

## Comfort and troubleshooting

- If your body is off center, first recenter the headset through your VR runtime, then press both grips. A cutscene may briefly begin at an awkward viewing angle; turning your head or body can help until normal control returns.
- If a menu will not confirm a choice, make sure the game window has focus.
- The game hands control of the staff back to its own animations during cutscenes and menus. This is expected behavior described by the publisher.
- For help, release notes and current known issues, use the [publisher repository](https://github.com/Pk-c/WitchNobetaVR) or the [Flat2VR discussion](https://discord.com/channels/747967102895390741/1553053055975690260).

[Watch VR gameplay](https://www.youtube.com/watch?v=jdqq6_6R2Xo)

>>> A little magic goes a long way in VR.

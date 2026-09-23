# PowerSlave / Exhumed VR

RazeXR brings the original DOS PowerSlave, also released as Exhumed, to true stereo PC VR with roomscale motion controls and voxel weapons held at the controller. The shared PCVR port supplies 91 hand-weapon models across its seven supported Build-engine games.

## About the Game

Explore ancient Egyptian ruins using the original DOS `STUFF.DAT` in a separate portable VR installation.

## Required edition

This needs the original DOS release. On Steam, use [PowerSlave (DOS Classic Edition)](https://store.steampowered.com/app/1260020/PowerSlave_DOS_Classic_Edition/). The 2022 Nightdive **PowerSlave Exhumed** remaster is a different engine and does not contain compatible data.

GOG/GOG Galaxy copies of the DOS original are also supported. Steam's free soundtrack DLC can supply CD music.

## What the VR port adds

The Windows port combines Raze with Team Beef's RazeXR tracking and input layer, then adds true OpenXR stereo, a desktop mirror, smooth turning, a direct launcher and controller-held voxel weapons. A compatible Exhumed voxel scenery pack is fetched from its author's source rather than bundled. Some sword and mummified-hand views remain flat sprites because no suitable voxel models exist.

PowerSlave's score originally used CD audio. Install Steam's free DOS Classic soundtrack DLC before running setup so the music is copied into the portable VR build; without those tracks the game can otherwise be silent. Virtual Desktop with VDXR on Quest 3 is the author's tested VR route.

## Install and play

The Hub installs the shared engine at `C:\Games\RazeXR PCVR`, copies the compatible original data and creates a direct PowerSlave launcher. No commercial data is bundled. Start your OpenXR runtime first, then use **Start in VR**.

The current publisher build can show yellow `deprecated checktype` script warnings while starting. They come from its bundled Raze game scripts and are non-fatal when the game continues to load.

## Controls

| Button | Action |
|---|---|
| [[Dominant Trigger]] | Fire |
| [[Off-hand Trigger]] | Alternate fire |
| [[A]] | Jump |
| [[B]] | Open / use |
| [[X]] or [[Right Stick Click]] | Crouch |
| [[Y]] | Toggle map |
| [[Left Stick Click]] | Alternate weapon |
| [[Right Stick Up / Down]] | Next / previous weapon |
| [[Dominant Thumbrest]] | Quick kick |

Hold the gun-hand [[Grip]] for the inventory layer: use [[Dominant Stick Down / Up]] to select the next or previous item, [[Grip]] + [[A]] to use it, [[Grip]] + off-hand [[A]] / [[B]] to fly down / up, and [[Grip]] + [[Off-hand Stick Click]] to land.

## Uninstall

Use **Uninstall now**. The portable PowerSlave data and launchers move into a dated recovery folder; the shared engine, other games and original installation remain.

## Credits and links

- VR port and setup: [Game Or Die — RazeXR PCVR](https://github.com/GameOrDie007/RazeXR-PCVR)
- Releases: [current stable downloads](https://github.com/GameOrDie007/RazeXR-PCVR/releases)

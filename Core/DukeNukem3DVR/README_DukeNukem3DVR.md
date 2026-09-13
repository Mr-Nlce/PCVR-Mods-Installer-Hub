# Duke Nukem 3D VR

RazeXR turns the original Build-engine Duke Nukem 3D releases into true stereo PC VR with roomscale motion controls and voxel weapons held at the controller. The shared PCVR port supplies 91 hand-weapon models across its seven supported Build-engine games.

## About the Game

Fight through Duke Nukem 3D in VR. The shared RazeXR setup supports Atomic Edition, the World Tour data and the expansions it can find in copies you own.

## Supported releases

- Steam: 20th Anniversary World Tour and the legacy Megaton Edition.
- GOG: Atomic Edition legacy package.
- ZOOM Platform: Atomic Edition.
- Retail/CD: a folder containing the original `DUKE3D.GRP`.

World Tour adds Alien World Order as episode five. RazeXR also gathers Duke it out in D.C., Life's a Beach, Nuclear Winter and Duke!ZONE II when their data exists across your owned releases.

## What the VR port adds

The Windows port combines Raze with Team Beef's RazeXR tracking and input layer, then adds true OpenXR stereo, a desktop mirror, smooth turning, direct launchers and controller-held voxel weapons. Voxel Duke 3D can replace many enemies and props in the first three episodes; The Birth remains sprite-based where that pack is unfinished. Alien World Order is built only from an installed World Tour copy because its maps, scripts and voices are loose files rather than part of `DUKE3D.GRP`.

Virtual Desktop with VDXR on Quest 3 is the author's tested route. SteamVR and Oculus OpenXR are supported by the engine but have not received the same published test claim.

## Install and play

The Hub installs one shared portable engine at `C:\Games\RazeXR PCVR`, downloads the current stable GitHub release, runs the author's data setup and creates a direct Duke launcher. No commercial game data is bundled. Start your OpenXR runtime first, then use **Start in VR**.

The current publisher build can show yellow `deprecated checktype` script warnings while starting. They come from its bundled Raze game scripts and are non-fatal when the game continues to load.

## Controls

| Input | Action |
|---|---|
| [[Dominant Trigger]] | Fire |
| [[Off-hand Trigger]] | Alternate fire |
| [[A]] | Jump |
| [[B]] | Open / use |
| [[X]] or [[Right Stick Click]] | Crouch |
| [[Y]] | Toggle map |
| [[Left Stick Click]] | Alternate weapon in a shared slot |
| [[Right Stick Up / Down]] | Next / previous weapon |
| [[Dominant Thumbrest]] | Quick kick |

Hold the gun-hand [[Grip]] for the inventory layer: use [[Dominant Stick Down / Up]] to select the next or previous item, [[Grip]] + [[A]] to use it, [[Grip]] + off-hand [[A]] / [[B]] to fly down / up, and [[Grip]] + [[Off-hand Stick Click]] to land.

For seated play, use recenter in RazeXR's VR Options.

## Uninstall

Use **Uninstall now**. The Hub moves the portable Duke data and its launchers into a dated `PCVRHub Recovery` folder. The shared RazeXR engine, other games and every original store installation remain untouched.

## Credits and links

- VR port and setup: [Game Or Die — RazeXR PCVR](https://github.com/GameOrDie007/RazeXR-PCVR)
- Releases: [current stable downloads](https://github.com/GameOrDie007/RazeXR-PCVR/releases)

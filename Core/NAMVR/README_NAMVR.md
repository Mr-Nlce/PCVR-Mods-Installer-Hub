# NAM VR

RazeXR brings the original Build-engine NAM to true stereo PC VR with roomscale motion controls and voxel weapons held at the controller. The shared PCVR port supplies 91 hand-weapon models across its seven supported Build-engine games.

## About the Game

NAM's Vietnam-themed campaign runs from the original `NAM.GRP` in a separate portable VR installation. The obscure NAPALM variant is also recognized when compatible original data is present; it was a separate NAM-derived release rather than DLC bundled with the normal game.

## Supported releases

- Steam: NAM.
- GOG or GOG Galaxy: NAM.
- Another original DOS copy containing `NAM.GRP`.

## What the VR port adds

The Windows port combines Raze with Team Beef's RazeXR tracking and input layer, then adds true OpenXR stereo, a desktop mirror, smooth turning and direct launchers. NAM has no known environment voxel pack, but its weapons still receive the bundled controller-held voxel models created for the VR port.

Virtual Desktop with VDXR on Quest 3 is the author's tested route. SteamVR and Oculus OpenXR are supported by the engine but have not received the same published test claim.

## Install and play

The Hub installs the shared engine at `C:\Games\RazeXR PCVR`, copies compatible data from a game you own and creates a direct NAM launcher. Start your OpenXR runtime first, then use **Start in VR**.

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

Use **Uninstall now**. The portable NAM data and launchers move into a dated recovery folder; the shared engine, other games and original installation remain.

## Credits and links

- VR port and setup: [Game Or Die — RazeXR PCVR](https://github.com/GameOrDie007/RazeXR-PCVR)
- Releases: [current stable downloads](https://github.com/GameOrDie007/RazeXR-PCVR/releases)

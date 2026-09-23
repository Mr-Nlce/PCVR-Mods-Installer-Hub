# World War II GI VR

RazeXR brings World War II GI to true stereo PC VR with roomscale motion controls and voxel weapons held at the controller. The shared PCVR port supplies 91 hand-weapon models across its seven supported Build-engine games.

## About the Game

The original Build-engine campaign runs from your owned `WW2GI.GRP` in the shared portable RazeXR engine.

## Supported releases

- Steam: World War II GI.
- GOG or GOG Galaxy: World War II GI.
- Another original DOS copy containing `WW2GI.GRP`.

Platoon Leader is detected from its original add-on data and receives its own launcher.

## What the VR port adds

The Windows port combines Raze with Team Beef's RazeXR tracking and input layer, then adds true OpenXR stereo, a desktop mirror, smooth turning, separate launchers and bundled controller-held voxel weapons. Platoon Leader was never sold separately: its data is already included with World War II GI. No known environment voxel pack exists for this game, so its world keeps the original Build-engine presentation.

Virtual Desktop with VDXR on Quest 3 is the author's tested route. SteamVR and Oculus OpenXR are supported by the engine but have not received the same published test claim.

## Install and play

The Hub installs the shared engine at `C:\Games\RazeXR PCVR`, copies compatible data and creates a direct WWII GI launcher. No commercial data is bundled. Start your OpenXR runtime first, then use **Start in VR**.

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

Use **Uninstall now**. The portable WWII GI data and launchers move into a dated recovery folder; the shared engine, other games and original installation remain.

## Credits and links

- VR port and setup: [Game Or Die — RazeXR PCVR](https://github.com/GameOrDie007/RazeXR-PCVR)
- Releases: [current stable downloads](https://github.com/GameOrDie007/RazeXR-PCVR/releases)

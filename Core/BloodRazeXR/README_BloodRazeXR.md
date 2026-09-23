# Blood VR

RazeXR brings Blood: One Unit Whole Blood to true stereo PC VR with roomscale motion controls and voxel weapons held at the controller. The shared PCVR port supplies 91 hand-weapon models across its seven supported Build-engine games.

## About the Game

Return as Caleb and carve through cultists, gargoyles and worse with the original Blood data running in the portable RazeXR engine. One Unit Whole Blood already includes the Cryptic Passage expansion; the newer Fresh Supply remaster uses different data and is not supported by this route.

## Supported releases

- Steam: One Unit Whole Blood.
- GOG or GOG Galaxy: One Unit Whole Blood.
- Another original DOS copy containing `BLOOD.RFF`.

Cryptic Passage is detected from its original loose data and receives its own launcher inside RazeXR.

## What the VR port adds

The Windows port combines Raze's Build-engine compatibility with Team Beef's RazeXR head, hand, projection and input work. It adds true OpenXR stereo, a desktop mirror, smooth turning, direct per-game launchers and voxel weapons that move with your dominant hand. Blood's own pickup voxels are reused for part of its hand-weapon set; compatible community voxel scenery can also be collected by the author's setup.

Virtual Desktop with VDXR on Quest 3 is the author's tested route. SteamVR and Oculus OpenXR are supported by the engine but have not received the same published test claim.

## Install and play

The Hub installs one shared portable engine at `C:\Games\RazeXR PCVR`, copies compatible data from a game you own and creates a direct Blood launcher. No commercial game data is bundled. Start your OpenXR runtime first, then use **Start in VR**.

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
| [[Left Stick Click]] | Alternate weapon in a shared slot |
| [[Right Stick Up / Down]] | Next / previous weapon |
| [[Dominant Thumbrest]] | Quick kick |

Hold the gun-hand [[Grip]] for the inventory layer: use [[Dominant Stick Down / Up]] to select the next or previous item, [[Grip]] + [[A]] to use it, [[Grip]] + off-hand [[A]] / [[B]] to fly down / up, and [[Grip]] + [[Off-hand Stick Click]] to land.

For seated play, use recenter in RazeXR's VR Options.

## Uninstall

Use **Uninstall now**. The Hub moves the portable Blood data and launchers into a dated recovery folder while keeping the shared engine, other games and the original installation.

## Credits and links

- VR port and setup: [Game Or Die — RazeXR PCVR](https://github.com/GameOrDie007/RazeXR-PCVR)
- Releases: [current stable downloads](https://github.com/GameOrDie007/RazeXR-PCVR/releases)

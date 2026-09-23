# Redneck Rampage VR

RazeXR brings the Redneck Rampage collection to true stereo PC VR with roomscale motion controls and voxel weapons held at the controller. The shared PCVR port supplies 91 hand-weapon models across its seven supported Build-engine games.

## About the Game

The original Redneck Rampage, Route 66 and Rides Again data can share one portable VR engine while keeping their own direct launchers.

## Supported releases

- Steam: Redneck Rampage and Redneck Rampage Rides Again.
- GOG or GOG Galaxy: Redneck Rampage Collection.
- Other original copies containing `REDNECK.GRP`.

The setup distinguishes Rides Again from the first game and imports Route 66 when its original data is present. Steam's free soundtrack DLC can supply Rides Again music; GOG music may require the separate soundtrack archive described by the author.

## What the VR port adds

The Windows port combines Raze with Team Beef's RazeXR tracking and input layer, then adds true OpenXR stereo, a desktop mirror, smooth turning, separate launchers and bundled controller-held voxel weapons. No known environment voxel pack exists for Redneck Rampage, so scenery stays in its original Build-engine style while the weapons are spatial models in your hand.

Redneck Rampage and Rides Again used CD audio and have no MIDI fallback. GOG owners should also download the separate soundtrack bonus from their library; the author's setup searches common folders and reads the tracks from that archive. Virtual Desktop with VDXR on Quest 3 is the author's tested VR route.

## Install and play

The Hub installs the shared engine at `C:\Games\RazeXR PCVR`, copies compatible owned data and creates a direct launcher. No commercial data is bundled. Start your OpenXR runtime first, then use **Start in VR**.

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

Use **Uninstall now**. Both portable Redneck data folders and their launchers move into a dated recovery folder. RazeXR, its other games and the originals stay installed.

## Credits and links

- VR port and setup: [Game Or Die — RazeXR PCVR](https://github.com/GameOrDie007/RazeXR-PCVR)
- Releases: [current stable downloads](https://github.com/GameOrDie007/RazeXR-PCVR/releases)

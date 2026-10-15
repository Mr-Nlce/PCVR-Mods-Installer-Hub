# Descent 2 VR

## About the Game

Descent 2 continues Parallax's six degrees of freedom tunnel shooter with new mines, weapons and Guide-bot. You pilot a ship through three dimensional labyrinths while fighting robots and searching for an exit. This OpenXR VR port uses your own original PC game data.

## What the Hub installs

The Hub uses Game Or Die's complete, unmodified Descent 1 and 2 VR release. This tile sets up Descent 2 only; the Descent tile uses the same publisher package for the first game. Setup needs descent2.hog and descent2.ham from an original Steam, GOG or PC CD installation. It writes a VR folder next to your game. If that folder is protected, the publisher places it under Documents\Descent 1 and 2 VR\Descent 2. Original game files are not moved or changed. The Hub leaves Steam library integration off; the publisher creates a desktop shortcut. Both game tiles have independent version and removal state.

The reviewed **v1.1 PCVR** package adds no cockpit, modern cockpit, classic
cockpit and behind-the-ship views, an in-headset manual made from your own
`manual.pdf`, swivel-chair turning and invert-look. Existing saves and settings
are retained by the publisher's update route. The standalone Quest/Steam Frame
package is separate from this PCVR route.

## Start and modes

Start Virtual Desktop or SteamVR, put on your headset and use [[Start in VR]] or the publisher's Descent 2 VR desktop shortcut. The VR launcher is Descent 2 VR.cmd in your VR folder. Descent 2 (flat).cmd launches the original flat view. The first launch asks for Modern (hand aiming, smooth textures and colored lighting) or Classic (weapons follow the ship). Change it under pause menu > VR Options. The publisher also offers left handed mode, photo mode, monitor view and, when both games were installed together through its own Setup, Switch Game. Press [[Alt]] + [[Enter]] for a monitor window.

## Controls

Default Quest Touch layout. A/B, X/Y and stick clicks can be remapped under VR Options > Controls. Index and Steam Frame layouts are also supplied.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Fly forward/back and slide left/right |
| [[Right Stick]] | Turn and pitch the ship |
| [[Left Grip]] | Raise the ship |
| [[Right Grip]] | Lower the ship |
| [[Left Grip]] + [[Right Grip]] | Recenter |
| [[Right Trigger]] | Fire primary weapon |
| [[Left Trigger]] | Fire secondary weapon |
| [[A]] / [[B]] | Bank left/right |
| [[X]] / [[Y]] | Next primary/secondary weapon |
| [[Left Stick Click]] | Afterburner |
| [[Right Stick Click]] | Drop a bomb |
| [[Menu]] | Pause menu |
| [[Either Stick]] | Move in menus |
| [[A]] or [[Trigger]] | Choose in menus |
| [[B]] | Go back in menus |
| [[Right Grip]] | Hold to point and click in menus |
| [[Left Stick Click]] in pause menu | Photo mode |

## Setup and troubleshooting

The game must contain descent2.hog and descent2.ham. If automatic detection misses a custom install, paste or drag its folder when the installer asks. Setup and download may take a little while; the installer shows ongoing status. On launch, ensure an OpenXR runtime is active. For problems, run Collect logs.bat in the VR folder and include the resulting desktop ZIP when reporting the issue. The VR Options > Hands and Aim menu can disable the ship's gentle bob. If the mod does not appear, run Scan installed games and check that the original game files and VR folder still exist.

## Links

The author also offers a [Game Or Die Installer](https://github.com/GameOrDie007/Game-Or-Die-Installer/releases), which currently has a one-click Descent route. It installs outside the Hub's guided transaction; use its own maintenance controls for that installation. The Hub setup above remains the supported path for Hub-managed install and removal.

| Button | Action |
| --- | --- |
| [[Publisher]] | https://github.com/GameOrDie007/Descent-1-and-2-VR |
| [[Releases]] | https://github.com/GameOrDie007/Descent-1-and-2-VR/releases |
| [[Flat2VR invite]] | https://discord.gg/uAeQkYBM4n |
| [[Descent discussion]] | https://discord.com/channels/747967102895390741/1556397364682428587 |
| [[VR gameplay]] | https://youtu.be/8ny_fpmIa_A?t=562 |

Guide-bot knows the way out. Whether it tells you is another matter.

# Descent VR

## About the Game

Descent is Parallax's original six degrees of freedom tunnel shooter. You pilot a small ship through twisting mines, fight robots, find hostages and escape before the reactor blows. This VR port uses your own original PC game data and a separate OpenXR runtime by Game Or Die.

## What the Hub installs

The Hub uses the complete, unmodified Descent 1 and 2 VR release. This tile sets up Descent only; the Descent 2 tile uses the same publisher package for the second game. Setup needs descent.hog and descent.pig from an original Steam, GOG or PC CD installation. It writes a VR folder next to your game. If that folder is protected, the publisher places it under Documents\Descent 1 and 2 VR\Descent. Original game files are not moved or changed. The Hub leaves Steam library integration off; the publisher creates a desktop shortcut. The Hub tracks each game's version separately.

The reviewed **v1.1 PCVR** package adds no cockpit, modern cockpit, classic cockpit and behind-the-ship view options, an in-headset Game Manual built from your owned game's `manual.pdf`, swivel-chair turning and invert-look. Existing pilots, saves and settings are retained by the publisher's update route. The Quest/Steam Frame standalone package is separate from the Windows PCVR ZIP selected here.

## Start and modes

The current v1.2.1 PCVR package fixes a crash around the Descent 2 Guide-Bot and the same underlying issue in Descent 1. The in-headset book is now called Game Tome. It retains world size, head steering, motion flying and the FPV stick layout from v1.2; pilots, saves, settings and notes carry over.

Start Virtual Desktop or SteamVR, put on your headset and use [[Start in VR]] or the publisher's Descent VR desktop shortcut. The VR launcher is Descent VR.cmd in your VR folder. Descent (flat).cmd launches the original flat view from the same folder. The first launch asks you to choose Modern (hand aiming, smooth textures and colored lighting) or Classic (weapons follow the ship, as in the original). Change it later under pause menu > VR Options. The publisher also offers left handed mode, photo mode, monitor view and, when both games were installed together through its own Setup, Switch Game. Press [[Alt]] + [[Enter]] for a monitor window.

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
| [[Left Stick Click]] | Fire a flare |
| [[Right Stick Click]] | Drop a bomb |
| [[Menu]] | Pause menu |
| [[Either Stick]] | Move in menus |
| [[A]] or [[Trigger]] | Choose in menus |
| [[B]] | Go back in menus |
| [[Right Grip]] | Hold to point and click in menus |
| [[Left Stick Click]] in pause menu | Photo mode |

## Setup and troubleshooting

The game must contain descent.hog and descent.pig. If automatic detection misses a custom install, paste or drag its folder when the installer asks. The Setup download and file preparation may take a little while; the installer shows ongoing status. On launch, make sure an OpenXR runtime is active. For problems, run the publisher's Collect logs.bat in the VR folder and include the resulting desktop ZIP when reporting the issue. The VR Options > Hands and Aim menu can disable the ship's gentle bob. If the mod does not appear, run Scan installed games and check that the original game files and VR folder still exist.

## Links

The author also offers a [Game Or Die Installer](https://github.com/GameOrDie007/Game-Or-Die-Installer/releases), which currently has a one-click Descent route. It installs outside the Hub's guided transaction; use its own maintenance controls for that installation. The Hub setup above remains the supported path for Hub-managed install and removal.

| Button | Action |
| --- | --- |
| [[Publisher]] | https://github.com/GameOrDie007/Descent-1-and-2-VR |
| [[Releases]] | https://github.com/GameOrDie007/Descent-1-and-2-VR/releases |
| [[Flat2VR invite]] | https://discord.gg/uAeQkYBM4n |
| [[Descent discussion]] | https://discord.com/channels/747967102895390741/1556397364682428587 |
| [[VR gameplay]] | https://youtu.be/8ny_fpmIa_A?t=202 |

The tunnels have six directions. Good luck remembering which way is up.

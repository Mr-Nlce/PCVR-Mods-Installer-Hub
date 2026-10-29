# Dementium II HD VR

## About the Game
Explore William Redmoor's fractured memories, solve puzzles and fight your way out of Bright Dawn Treatment Center.

## Requirements
Steam Windows game, the bundled BepInEx 5 x86 Mono loader, and an active 32-bit OpenXR runtime with OpenGL support. The publisher has tested Quest 3 with VDXR. SteamVR or Meta need the corresponding 32-bit OpenXR/OpenGL support.

## Install and start
1. Choose Install. The Hub finds the game and installs the complete publisher ZIP, including its loader and native VR bridge.
2. Start your headset runtime, then use Start in VR in the Hub. It launches Steam with -force-opengl, which this Unity version requires.
3. Alternative: use the Dementium II HD VR desktop shortcut. To launch from Steam yourself, set -force-opengl in Launch Options first.

Flat / VR changes the documented Doorstop enabled setting and keeps the installation on disk. Close the game before switching.

## Controls
| Button | Action |
|---|---|
| [[Left Stick]] | Walk |
| [[Right Stick]] | Snap or smooth turn |
| [[Right Trigger]] | Fire or attack; click a menu |
| [[Left Trigger]] / [[Left Stick Click]] | Run |
| [[Right Grip]] | Reload |
| [[Left Grip]] | Tap to crouch |
| [[B]] | Use, pick up or open |
| [[X]] | Flashlight |
| [[A]] | Jump |
| [[Y]] | Next weapon |
| [[Right Stick Click]] | Zoom |
| [[Right Stick Up]] / [[Right Stick Down]] | Dagger / sledgehammer |
| [[Left Grip]] + [[Right Stick]] | Select revolver, shotgun, machine gun or flamethrower |
| [[Menu]] | Tap to pause; hold for journal/inventory |
| [[Left Stick Click]] + [[Right Stick Click]] | Tap to recenter; hold 1.2 seconds for VR settings |

Point the right controller at menus and pull its trigger. Weapons and flashlight have six-degree-of-freedom tracking. Weapon offsets can be calibrated in VR settings; that menu is currently difficult to see.

## Help
VR starts flat: verify -force-opengl, an active 32-bit runtime and the native d2xr.dll. Use the Flat / VR switch to ensure the loader is enabled. If required files are missing, inspect the installer log and chosen game folder first. Windows protection history can identify a matching detection; missing files alone do not establish an antivirus cause. Retry setup or hand over the official package on its recovery page.

## Technical details
Runtime files live in the game folder: version.dll and doorstop_config.ini load BepInEx, then BepInEx\plugins\D2VR\D2VR.dll and d2xr.dll. The Hub controller is DementiumIIHDVR\Start-DementiumVR.ps1; the publisher also provides Start Dementium II VR.bat. The plugin metadata supplies the installed version; the bundled sample CFG may name an older build.

## Discord discussion & support
[Flat2VR invite](https://discord.gg/uAeQkYBM4n)
[Dementium II HD discussion](https://discord.com/channels/747967102895390741/1563266841105801357)

## Links
[Mod source and instructions](https://github.com/King-EJ/Dementium-II-HD-VR)
[Publisher releases](https://github.com/King-EJ/Dementium-II-HD-VR/releases)
[VR gameplay](https://youtu.be/nh0v3ACa5ss?t=505)

>>> The hospital discharge paperwork may take a while.

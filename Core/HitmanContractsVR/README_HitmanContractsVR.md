# Hitman: Contracts VR

## About the Game

Agent 47 revisits his darkest contracts with native stereo rendering, tracked hands and controller-driven weapons. This Review Version is still WIP: item handling and weapon transfers remain experimental, and room-scale walking is not implemented.

## What you need

- Your own original PC game. Publisher Setup checks the supported Steam 1.75 or legacy 1.74 executable; a matching label alone is not enough.
- Windows 10/11 x64, tracked controllers and a compatible PC VR connection. Meta Link/Air Link, VDXR and SteamVR/OpenXR profiles are offered.
- Start the normal game once, choose a suitable graphics resolution and close it before installation.

## Install and start

1. Choose [[Install]] or [[Update]]. The Hub finds your game and downloads the latest publisher Review Version, including prereleases.
2. In the clearly marked publisher Setup step, select HitmanContracts.exe and keep the separate ContractsVR folder. Complete Setup before returning to the Hub.
3. Choose [[Start in VR]] in the Hub. Contracts VR Settings opens: select your headset connection, choose Check headset, then Save & play. The Hitman Contracts VR desktop shortcut follows the same route.
4. Original / previous renderer is recommended for stability. DXVK is an optional comparison and may cause flickering, artifacts or crashes. Recheck the connection profile after updates.

## Controls

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move relative to your view; pan the map. |
| [[Left Stick Click]] | Toggle sprint. |
| [[Right Stick]] | Turn; select map buttons; up/down changes optic zoom. |
| [[Right Stick Click]] | Open/close inventory; hold about 650 ms to recenter. |
| [[Right Trigger]] | Fire/use the right-hand weapon. |
| [[Left Trigger]] | Fire the left-hand weapon. |
| [[A]] | Reload; confirm menu/map/inventory selections; leave optics and request reload. |
| [[B]] | Tap to sneak, hold about 450 ms to crouch; go back or leave optics. |
| [[X]] | Hold for the action list and health/ammo by your left hand; select with a stick and release to perform. |
| [[Y]] | Tap to holster/unholster; hold about 650 ms to drop. |
| [[Grip]] | Interact/pick up with that hand; hold near a body to drag, release to let go. |
| [[Left Grip]] | Hold near a right-held long gun fore-end for two-handed support. |
| [[Menu]] | Pause; go back or leave optics. |
| [[Right Trigger]] / [[Left Trigger]] | In map: zoom in / out. |
| [[Left Stick]] / [[Right Stick]] | Navigate menu, inventory and map submenus. |
| [[A]] / [[Right Trigger]] | Confirm/equip. |
| [[B]] / [[Menu]] / [[Right Stick Click]] | Close inventory; return through a submenu. |
| [[X]] / [[Y]] | Next / previous native menu tab. |
| [[F7]] | Keyboard recenter fallback. |
| [[F9]] | Toggle VR output. |

Bring the trigger controller of a sniper rifle near the headset to enter its native scope; lower it to leave. Crosshair is off and Controller help on by default. If the desktop game loses focus, release an input used to focus it and press again.

## Help

Publisher Setup resets launcher.ini, vr.ini and mod.ini. The Hub backs existing settings up under %LOCALAPPDATA%\PCVR Mods Installer Hub\Backups\ContractsVR before opening Setup. Reapply supported choices through the new settings window rather than blindly restoring old INIs. Game saves and recordings remain. For problems use Settings > Support > Create support report. OpenXR controller/runtime support varies; VDXR connection issues are still reported by the publisher.

Unsigned VR files may trigger protection warnings. Missing files can also indicate a copy, path or permissions problem; inspect the log and protection history before assigning a cause. The installer provides Retry and manual-file recovery.

## VR files

The separate publisher [VR folder](.) normally lives at %LOCALAPPDATA%\ContractsVR. [ContractsVR.exe](ContractsVR.exe) is the launch/settings app; the Hub starts it with --settings through [Start-VR.ps1](PCVR-Launcher/Start-VR.ps1). [launch.json](PCVR-Launcher/launch.json) retains the separate original game path. [launcher.ini](launcher.ini) holds the publisher game and connection choices. [Collect-Contracts-Diagnostics.cmd](Collect-Contracts-Diagnostics.cmd) creates the optional support report. The Hub Flat / VR switch chooses a normal game launch after invoking the included renderer-restore tool; Steam copies use steam://rungameid/247430, retail copies their selected HitmanContracts.exe. Uninstall Guide includes restoration of the earlier renderer before publisher removal.

The VR files folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game to select it manually.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [This mod discussion](https://discord.com/channels/747967102895390741/1564060624973996122)

## Links

- [Publisher project](https://github.com/andreystashev/hitman-contracts-vr-showcase)
- [Official releases](https://github.com/andreystashev/hitman-contracts-vr-showcase/releases)
- [Publisher connection and renderer guide](https://github.com/andreystashev/hitman-contracts-vr-showcase/blob/main/INSTALLATION.md)
- [VR gameplay](https://youtu.be/uFUh52hvxfU?t=47)

>>> Another rainy night. Another suspiciously perfect disguise.

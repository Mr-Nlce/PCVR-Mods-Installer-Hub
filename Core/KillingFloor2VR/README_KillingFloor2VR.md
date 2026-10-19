# Killing Floor 2 VR

## About the Game

Killing Floor 2 is a cooperative survival shooter. KF2VR adds tracked aiming and hands through a separate OpenXR launcher. This is an early alpha. The full GitHub package supports Steam Solo, Host and Join in VR; Epic support is experimental Solo VR only. The smaller **Epic Desktop Pack** is for flat-screen joining and does not provide another VR mode.

## Install and update

The Hub installer offers two routes. Choose the full GitHub ZIP for a separate KF2VR launcher that the Hub can start and update. The same ZIP contains Solo, Host and Join; select a mode in its launcher. A complete original Killing Floor 2 installation is required. The publisher launcher checks supported game builds and keeps its native files together. It needs an active OpenXR runtime and can take time to prepare Steam hosting data.

Steam users can instead choose the [KF2VR Workshop item](https://steamcommunity.com/sharedfiles/filedetails/?id=3817663661). Subscribe, run the normal game once to let Steam finish downloading, then run **Setup KF2VR** in `steamapps\workshop\content\232090\3817663661`. It restarts Steam and adds **Play in VR** beside the normal play option. Steam updates that route; run Setup again to remove the Steam launch entry. Do not combine Workshop and GitHub installations or mix files between releases. The Hub does not label the guided Workshop route VR Ready until its actual launch files can be checked.

For the GitHub route, use [[Install]] on this tile to install or check for a newer full release. Use [[Start in VR]] to open KF2VR; choose **VR headset**, then **Play solo**, **Host**, or **Join** in the publisher launcher. Keep the launcher open during play so it can restore files after the game exits. Its **Fix a stuck session** action repairs an interrupted run.

For Epic Solo, the publisher launcher provides **Copy Epic Launch Options**. Paste the line into Epic Library > Killing Floor 2 > Manage > Launch Options, launch within five minutes, and restore the former options after play. Epic Host, Join and Desktop are not supported by this build. Steam Solo/Host/Join and Desktop are in the full ZIP. The separate Epic Desktop Pack is optional flat-screen material for compatible Steam-hosted games and is not installed by this VR route.

## Controls

| Button | Action |
| --- | --- |
| [[Left Trigger]] or [[Right Trigger]] | Fire or use the held item. |
| [[A]] or [[X]] tap | Reload. |
| [[A]] or [[X]] hold | Secondary fire or weapon mode. |
| [[B]] or [[Y]] tap | Previous item. |
| [[B]] or [[Y]] double tap | Stow or use the syringe. |
| [[B]] or [[Y]] hold | Open the weapon wheel. |
| [[Left Grip]] or [[Right Grip]] | Support the weapon or prepare a grenade, depending on the held item. |
| [[Left Stick]] | Move. |
| [[Left Stick Click]] | Sprint. |
| [[Right Stick]] | Turn; up jumps and down crouches. |
| [[Right Stick Click]] | Use the welder near a door or select from the wheel. |
| [[Menu]] | Open the VR menu. If unavailable, centre both sticks, release both triggers, then hold [[Left Stick Click]] + [[Right Stick Click]] for 0.6 seconds. |

The publisher's full controls guide is bundled in the installed launcher under `app\docs\VR_CONTROLS.md`.

## Compatibility and troubleshooting

Use Solo or compatible VAC-off private/custom servers. Do not inject this alpha into VAC-secured servers; experience progression is not guaranteed. Host and Join need matching game and KF2VR releases. Hosting across the internet may need UDP ports 7777 and 27015. An empty host password makes the server public. Share join codes privately.

If [[Start in VR]] cannot find a complete installation, use [[Install]] to repair the GitHub route. The mod's package and original game are separate: do not copy its `app` folder into `Binaries\Win64`. Antivirus software may warn about unsigned VR files. A missing file has several possible causes; check the setup log and file location before treating it as a quarantine event.

## Links

- [Publisher releases](https://github.com/Kvasir94/Killing-Floor-2-VR/releases)
- [Steam Workshop alternative](https://steamcommunity.com/sharedfiles/filedetails/?id=3817663661)
- [Flat2VR discussion](https://discord.com/channels/747967102895390741/1556770175335010444)
- [VR gameplay](https://www.youtube.com/watch?v=JrZemwCTFXU)

The next wave is yours. Keep your squad together.

# PowerWash Simulator VR

Wet Reality XR by onetin84 brings the first PowerWash Simulator into room-scale OpenXR VR with a tracked washer, motion controllers and independent look and spray directions. This beta is playable but still has known limitations.

## About the Game

Build a cleaning business one job at a time. Restore vehicles, playgrounds and buildings with a selection of washers, nozzles and cleaning liquids while following the stories behind each job.

## Before you install

- The publisher tested PowerWash Simulator 1.11.0, Steam build 1394, with a Meta Quest 3 over Virtual Desktop. Other OpenXR headsets and the Xbox / Microsoft Store game build are not publisher-verified.
- Close the game. The Hub checks the game's own OpenXR files, then installs the mod, MelonLoader 0.7.3 and portable .NET 6.0.36 into the game folder. It saves prior colliding files for rollback and removal.
- If the game is under Program Files, Windows may require administrator approval for writing to its folder.

## Install and update

1. Select [[Install]]. The Hub locates the Steam game or the specified Xbox folder and resolves the newest public [GitHub release](https://github.com/onetin84/Wet-Reality-XR-PWS1/releases), including prereleases.
2. Confirm the download of the mod, MelonLoader and portable .NET. The Hub unpacks them into a checked staging area, then verifies the placed files before recording the release version.
3. Start the headset runtime, then use [[Start in VR]]. The Steam route starts the game through Steam. The Xbox route is an unverified fallback.

The first game launch after installing MelonLoader can take a while with little visible game progress while support files are generated. Let it finish. VR normally appears in the main menu automatically. If it does not, close and restart the game with the headset runtime already running.

## Graphics and comfort

Turn VSync off and set the game's FPS limit above the headset refresh rate or to unlimited. Turn off motion blur, depth of field, chromatic aberration and film grain where available. The configurator under WetRealityXR-PWS1 offers left-handed mode, grip alignment, smooth or snap turning, movement vignette, teleport, laser pointer and menu size. Comfort options are off by default.

## Controls

The default layout below is for a right-handed washer. Left-handed mode exchanges hand roles except for the menu button. The included configurator opens the publisher's full quick guide.

| Button | Action |
| --- | --- |
| [[Right Trigger]] | Spray while held; click in menus. |
| [[Right Grip]] | Toggle continuous spray. |
| [[A]] | Jump when comfort teleport is off. |
| [[B]] | Tap to crouch; hold to go prone. |
| [[Right Stick Left]] / [[Right Stick Right]] | Turn smoothly or snap turn. |
| [[Right Stick Up]] | Aim target teleport. |
| [[Right Stick Down]] | Next nozzle. |
| [[Right Stick Click]] | Hold for equipment wheels. |
| [[Left Stick]] | Walk; push fully to sprint. |
| [[Left Trigger]] | Rotate the nozzle. |
| [[Left Grip]] | Highlight dirt, or rotate a carried item. |
| [[X]] | Pick up or put down. |
| [[Y]] | Tap for inventory; go back in menus. Hold for the next washer. |
| [[Left Stick Click]] | Next extension. |
| [[Menu]] | Tap to pause; hold to toggle immersion mode. |
| [[Right Grip]] behind your shoulder | Next washer. |
| [[Right Grip]] at your hip | Draw soap from the holster. |
| [[Left Grip]] near the washer | Next extension. |
| [[Left Grip]] + [[X]] + [[Y]] | Hold to calibrate the washer grip. |

The target teleport respects the game's jump and ladder rules. It does not move through ceilings or directly onto arbitrary high roofs.

## Limitations and troubleshooting

- The game menus float in front of you. The equipment wheel looks distorted from the side, and inventory may flash briefly.
- There is no physical bottle grabbing or belt interaction. Left-handed play has received less testing.
- If the washer position feels wrong, recalibrate with the grip combination or use the configurator's fine adjustments.
- For a missing VR view, start the headset runtime before the game and restart it. For a game launch failure, inspect MelonLoader\Latest.log and the Hub installer log. A missing file does not by itself establish antivirus quarantine.
- Saves and MelonPreferences.cfg are user data. The Hub's Uninstall now button removes unchanged owned files and restores any original files it replaced, while preserving changed files.

## Links

[Publisher and releases](https://github.com/onetin84/Wet-Reality-XR-PWS1) · Join [Flat2VR Modding](https://discord.gg/flat2vr) first, then open the [PowerWash discussion](https://discord.com/channels/747967102895390741/1554332590872465428) · [VR gameplay](https://youtu.be/Zcp_uCqGfwI?t=219)

The grime never stood a chance against your reach.

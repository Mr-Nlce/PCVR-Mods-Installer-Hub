# Ratchet & Clank 1 VR

## About the Game

Ratchet and Clank's original adventure returns as a native PC port, with first-person VR, tracked hands, physical wrench swings and all the familiar planets.

## What you need

- Windows 10/11, a PC VR headset and controllers. Start SteamVR and make it the active OpenXR runtime.
- Your own original US Ratchet & Clank PS2 disc image, SCUS-97199. European/PAL images are not supported. Extract a compressed disc archive to an ISO first.
- About 5 GB of free space for extracted game data. No game assets are downloaded or included.

## Install and start

1. Choose [[Install]]. Choose an installation folder; the suggested location is C:\Games\Ratchet & Clank 1 VR. You can choose another writable folder. The RatchetVR release already contains its matching ReRAC engine and extractor; do not overwrite it with a separately newer vanilla ReRAC build.
2. Choose your supported ISO when asked. The publisher extractor copies the game data; let it finish. A wrong region, unreadable image or missing file can be selected again through recovery.
3. Connect your headset, start SteamVR, then use [[Start in VR]] in the Hub. The Ratchet & Clank 1 VR desktop shortcut uses the same launcher.
4. Use the Hub Flat / VR switch before launching. Both modes keep the same normal saves. Sandbox is optional and has separate saves.

## Controls

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move; physical room movement also moves Ratchet. |
| [[Right Stick Left]] / [[Right Stick Right]] | Snap turn. |
| [[A]] | Jump, double jump, or climb from a ledge. |
| [[Left Trigger]] | Hold to crouch; with [[A]] for long/high jump. |
| [[Left Stick]] + [[Left Trigger]] + [[A]] | Flick sideways/back for a side flip or back flip. |
| [[X]] / [[B]] | Hold for Clank pack hover/strafe or Hydro-Pack boost. |
| [[Grip]] | Grab a ledge while falling; push both hands down to climb, release both grips to let go. |
| [[Right Grip]] | Hold the wrench; swing to hit, release mid-swing to throw, release slowly to put away. |
| [[Right Grip]] | Swing the wrench downward while airborne for Hyper Strike. |
| [[Right Trigger]] | Fire/use a gadget. Hold and throw to toss bombs, mines or Decoys; release slowly to cancel. |
| [[Left Grip]] | Hold near the fore-end to support a large weapon with both hands. |
| [[Right Stick Click]] | Interact; hold for quick select and reach toward a weapon; release to select. |
| [[Right Trigger]] + [[Right Stick Click]] | While holding quick select, change its page. |
| [[Y]] | Pause, skip cutscenes or go back. |
| [[Left Stick Click]] | Map. |
| [[Right Trigger]] / [[A]] | Point at a menu entry and confirm. |
| [[Right Stick]] / [[Right Trigger]] / [[Right Stick Click]] | At vendors: browse / buy / leave. |
| [[Right Grip]] | Hold the wrench on a bolt crank and walk around it. |
| [[Left Stick]] / [[Left Trigger]] / [[Right Trigger]] / [[A]] | Hoverboard: steer / boost / shoot / jump. Leaning also steers. |
| [[Right Stick]] / [[Left Grip]] / [[X]] / [[B]] | Hoverboard: use in the air for tricks; [[Left Stick]] spins. |
| [[Right Stick Click]] | Clank: command robots; Giant Clank: beam. |
| [[Right Trigger]] | Giant Clank missiles. |
| [[F8]] | Recenter. |

Swim with breaststroke motions; stroke upward to dive. Clank punches use physical punches with either hand. VR Options controls helmet/boots, body visibility, movement direction and hoverboard leaning. Camera flip is off by default for comfort. A normal gamepad or keyboard also works.

## Help

Updates replace only owned program files and shaders. The extracted data, normal saves, sandbox saves and user settings are preserved. If a publisher update requires a new extraction, keep your supported ISO available.

Unsigned VR files may trigger protection warnings. Missing files can also indicate a copy, path or permissions problem; inspect the log and protection history before assigning a cause. The installer provides Retry and manual-file recovery.

## VR files

[VR game folder](.) contains [RatchetVR.exe](RatchetVR.exe), its [engine](rerac.exe), [disc extractor](rerac-extract.exe), [game data](data) and [normal saves](saves/normal). The Hub uses [Start-VR.ps1](PCVR-Launcher/Start-VR.ps1); its configuration is [launch.json](PCVR-Launcher/launch.json). It starts RatchetVR.exe with RC_VR=1 in VR or RC_VR=0 in flat mode, and RC_SAVE_DIR=saves/normal. [RatchetVR Sandbox.exe](RatchetVR%20Sandbox.exe) is the optional unlocked sandbox, with separate saves.

The VR files folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game to select it manually.

## Links

- [Publisher project](https://github.com/npiriou/Rerac-vr)
- [Official releases](https://github.com/npiriou/Rerac-vr/releases)
- [ReRAC base project](https://github.com/re-rac/rerac)
- [Report VR issues to the VR modder](https://github.com/npiriou/Rerac-vr/issues)
- [VR gameplay](https://www.youtube.com/watch?v=rdMAJ2T1JdA)

>>> The R.Y.N.O. is still not covered by your warranty.

# Spec Ops: The Line VR

## About the Game

Spec Ops: The Line is a third-person military story shooter. SpecOpsTheLineVR adds stereoscopic first-person VR, six-degree head tracking, motion-controlled aiming and gestures. Menus and cutscenes appear on a virtual screen. The mod is a beta.

**WIP:** Early builds could visibly shake or twitch in the headset. Updates through v0.9.18 address camera, controller and frame-pacing problems, including cover scenes where the view remained behind a wall or a gun could not fire. These are publisher reports, not a headset test by the Hub. The Hub checks the current complete release ZIP when installing or updating. If the image still shakes, run the publisher's `collect_logs.bat` from the downloaded ZIP and report the headset/runtime and scene.

## Requirements and install

- The **Steam PC version only** (Steam app 50300). The publisher supports a specific 2012 Steam executable; the Hub checks its PE build before changing game files. Other builds are not offered.
- Windows 10/11, a connected PC VR headset and two motion controllers. With `runtime auto`, the current mod chooses VDXR when Virtual Desktop Streamer is running, otherwise SteamVR. `runtime openxr` uses your active OpenXR runtime instead; Meta Link support is experimental. Headset coverage has not been verified by the Hub.
- Choose [[Install]] in the Hub. It downloads the **complete** release ZIP (currently `0-SpecOpsTheLineVR.zip`), installs `d3d9.dll` and `openvr_api.dll` beside `Binaries\Win32\SpecOpsTheLine.exe`, and places `specopsvr.ini` there if absent. A separate DLL asset is not a complete initial installation.
- After installation, the Hub displays the required Steam launch options `-windowed ResX=2400 ResY=2500` and copies them to the clipboard. Press [[Enter]] to open **Spec Ops: The Line > Properties**, click the **Launch Options** field, and press [[Ctrl]] + [[V]]. If clipboard access fails, copy the displayed line manually. Press [[Enter]] again after pasting. This nearly square desktop window is the publisher's recommended size for headset clarity; the Hub does not change Steam settings itself.
- Connect your headset through Virtual Desktop, Link or SteamVR, then choose [[Start in VR]] in the Hub. The Hub starts Steam app 50300. SteamVR is not needed when using VDXR or another supported OpenXR runtime.

The publisher default config uses `viewport full` to avoid 16:9 bars, `postfx off` to disable motion blur and depth of field, and `posscale 50` for approximately 1:1 world scale. You can tune `posscale` in `Binaries\Win32\specopsvr.ini`. In v0.9.4 and later, SteamVR's resolution slider sets sharpness; `dynres on` adjusts scene resolution to protect frame rate. For persistent visual or input issues, the publisher documents opt-outs such as `submitpose off`, `vrinput legacy`, `controllerpose raw`, `offcenter off`, `eyestate off`, `dynres off` and `lowlatency off` in that INI. The Hub-installed default sets `autoupdate off` so the Hub can track updates and safely remove its own files. An existing custom INI is preserved; if it has `autoupdate on`, the publisher may update `d3d9.dll` outside the Hub and the Hub will preserve that changed file on removal.

## Controls

The current Basic settings tab includes **Lean out of cover** (`coverlean`, on by default). Lean sideways by about 20 cm or stand up to move the view and gun around cover. OpenXR resolution follows that runtime's own settings; the SteamVR resolution slider applies only to the SteamVR route. Existing personal INI settings are preserved during a Hub update.

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Right Stick]] | Turn. |
| [[Right Trigger]] | Fire. |
| [[Left Trigger]] | Aim. |
| [[Left Grip]] | Throw grenade. |
| [[Right Grip]] | Give squad orders. |
| [[A]] | Action or cover. |
| [[B]] | Melee. |
| [[X]] | Reload. |
| [[Y]] | Next weapon. |
| [[Left Menu]] | Pause. |
| [[Right Stick Click]] + [[Right Stick Direction]] | D-pad actions, including secondary fire and grenade type. |
| [[Left Stick Click]] + [[Right Stick Click]] | Hold for one second to recenter while standing straight and looking ahead. |
| [[Left Stick Click]] + [[Right Stick Click]] | Hold for three seconds to save standing height as well. |
| [[Left Hand Forward Throw]] | Grenade gesture. |
| [[Left Hand Magazine Pull]] | Reload gesture. |
| [[Duck Beside Cover]] | Enter cover. |
| [[Right Hand Over Shoulder]] + [[Right Grip]] | Next weapon gesture. |
| [[Left Hand On Barrel]] | Aim with both hands. |
| [[B]] + [[Y]] (hold one second) | Calibrate a gunstock while looking along it. |

## Removal and support

Choose [[Uninstall now]] in the Hub. The Hub removes only its unchanged owned files and restores any previous files under the same names. User-modified files, unrelated mods, saves and logs remain. Steam launch options are yours to clear manually if desired. The publisher's own uninstaller removes DLL names without Hub ownership checks, so use the Hub button for a Hub installation.

The beta has limited testing of some weapons. The publisher added right-controller aiming for mounted guns and the helicopter minigun in v0.9.3. The publisher's `collect_logs.bat` is in the downloaded package if you need to prepare a bug report; it is not installed into the game by the Hub.

## Links

- [Official source and installation guide](https://github.com/Mavic-Pro/SpecOpsTheLineVR)
- [Current complete release ZIP](https://github.com/Mavic-Pro/SpecOpsTheLineVR/releases)
- [Flat2VR discussion](https://discord.com/channels/747967102895390741/1560952647517732976)
- [Non-VR gameplay video](https://youtu.be/x62UNy3wMns?t=1519) (the supplied clip does not demonstrate the mod)

The line is crossed one step at a time.

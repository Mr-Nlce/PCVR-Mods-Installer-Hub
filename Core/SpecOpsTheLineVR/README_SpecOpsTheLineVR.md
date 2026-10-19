# Spec Ops: The Line VR

## About the Game

Spec Ops: The Line is a third-person military story shooter. SpecOpsTheLineVR adds stereoscopic first-person VR, six-degree head tracking, motion-controlled aiming and gestures. Menus and cutscenes appear on a virtual screen. The mod is a beta.

**WIP:** Early builds could visibly shake or twitch in the headset. The publisher's v0.9.2–v0.9.5 updates address cover camera jumps, head-pose reprojection, controller alignment, frame pacing and a view that could remain inside a wall during scripted scenes. These are publisher reports, not a headset test by the Hub. The Hub checks the current complete release ZIP when installing or updating. If the image still shakes, run the publisher's `collect_logs.bat` from the downloaded ZIP and report the headset/runtime and scene.

## Requirements and install

- The **Steam PC version only** (Steam app 50300). The publisher supports a specific 2012 Steam executable; the Hub checks its PE build before changing game files. Other builds are not offered.
- Windows 10/11, SteamVR and a SteamVR-compatible headset with two motion controllers. The publisher tested Meta Quest 3 over Link; v0.9.4 added default SteamVR Input bindings for Index, Vive and WMR, but these have not been verified by the Hub.
- Choose [[Install]] in the Hub. It downloads the **complete** `SpecOpsTheLineVR.zip` release, installs `d3d9.dll` and `openvr_api.dll` beside `Binaries\Win32\SpecOpsTheLine.exe`, and places `specopsvr.ini` there if absent. The release's separate `d3d9.dll` asset is for the publisher's updater and is not a complete initial installation.
- After installation, the Hub displays the required Steam launch options `-windowed ResX=2400 ResY=2500` and copies them to the clipboard. Press [[Enter]] to open **Spec Ops: The Line > Properties**, click the **Launch Options** field, and press [[Ctrl]] + [[V]]. If clipboard access fails, copy the displayed line manually. Press [[Enter]] again after pasting. This nearly square desktop window is the publisher's recommended size for headset clarity; the Hub does not change Steam settings itself.
- Start SteamVR, put on the headset, then choose [[Start in VR]] in the Hub. The Hub starts Steam app 50300, so Steam performs its normal game launch. The game EXE is not used as a direct Hub launcher.

The publisher default config uses `viewport full` to avoid 16:9 bars, `postfx off` to disable motion blur and depth of field, and `posscale 50` for approximately 1:1 world scale. You can tune `posscale` in `Binaries\Win32\specopsvr.ini`. In v0.9.4 and later, SteamVR's resolution slider sets sharpness; `dynres on` adjusts scene resolution to protect frame rate. For persistent visual or input issues, the publisher documents opt-outs such as `submitpose off`, `vrinput legacy`, `controllerpose raw`, `offcenter off`, `eyestate off`, `dynres off` and `lowlatency off` in that INI. The Hub-installed default sets `autoupdate off` so the Hub can track updates and safely remove its own files. An existing custom INI is preserved; if it has `autoupdate on`, the publisher may update `d3d9.dll` outside the Hub and the Hub will preserve that changed file on removal.

## Controls

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

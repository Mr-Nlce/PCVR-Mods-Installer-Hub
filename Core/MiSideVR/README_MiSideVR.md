# MiSide VR

## About the Game

MiSide is a first-person story game in which the player enters a game world
and meets Mita. Its bright rooms and small activities give way to increasingly
unsettling discoveries. Glitchtest51's VR mod adds full 6DoF headset and
controller tracking, room-scale movement, physical turning and playable
minigames. It remains a work in progress, although the author says most of
the game is playable.

## Requirements and setup

This entry needs the [Steam game](https://store.steampowered.com/app/2527500/)
with `MiSideFull.exe`, SteamVR, and the official Windows x64
BepInEx Unity IL2CPP 6.0.0-pre.2 release. The Hub downloads that specific
loader from [BepInEx](https://github.com/BepInEx/BepInEx/releases/tag/v6.0.0-pre.2)
and the current stable [MiSide VR publisher ZIP](https://github.com/Glitchtest51/MiSide_VR/releases).
Neither download contains the game. The Hub does not substitute a Mono or
32-bit BepInEx package for the required IL2CPP x64 build.

The publisher's installation order matters: install BepInEx in the MiSide
folder, launch MiSide flat once and close it so BepInEx creates its files,
then install the VR plugin. The installer pauses at that point and checks
for generated loader config and a startup log before copying the VR files.
It protects same-name files with an ownership backup, keeps saves and
existing configuration, and leaves unrelated BepInEx plugins alone.

Start SteamVR before launching MiSide from Steam. The author's current
release is 0.9.0; the Hub checks later stable GitHub releases. Quest 3
controls are documented, while other controllers and headsets need their
own verification. A successful file install cannot prove a game or headset
session.

## Controls

These are the author's Quest 3 defaults. Handedness and turning mode can be
changed in `BepInEx/config/com.Glitchtest51.MiSide_VR.cfg` after the first VR
launch. Some interactions map to the game's keyboard actions shown below.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Sprint (Shift) |
| [[Right Stick]] | Turn |
| [[Right Stick Click]] | Sprint (Shift) |
| [[Left Trigger]] | Decline (Q) |
| [[Right Trigger]] | Interact (E, Space or left click) |
| [[X]] | Open the game menu |
| [[A]] | Recalibrate height |
| [[Left Menu Button]] | SteamVR menu |
| [[Right Menu Button]] | Meta system menu |

The author also provides the original
[Quest 3 control diagram](https://github.com/Glitchtest51/MiSide_VR/blob/main/Assets/Quest3Controls.png).
Controller bindings are work in progress and can change with later releases.

## Settings, limitations and recovery

The config file offers left-handed mode, snap or smooth turning and height
calibration. The author lists room-scale motion and IK support as WIP. In the
current release, the SpaceCar UI does not rotate with the camera, Ghost Mita
gluing has an offset, VRIK bones are imperfect, and the pumpkin minigame is
not implemented. Report new problems through
[GitHub Issues](https://github.com/Glitchtest51/MiSide_VR/issues) or the
[publisher Discord](https://discord.gg/EcGQUTBVda).

For Flat2VR discussion, [join Flat2VR](https://discord.gg/uAeQkYBM4n)
first, then open the [MiSide VR thread](https://discord.com/channels/747967102895390741/1556406798725025872).

If the mod does not load, confirm SteamVR was already running and inspect
`BepInEx/LogOutput.log`. If setup reports missing files, use Recovery for the
log, target folder and a retry. Missing files alone do not establish an
antivirus cause. Uninstall now removes the Hub-owned VR plugin and, when
no other plugins need it, the Hub-owned BepInEx loader. The detail page's
Uninstall guide explains what is kept. Saves, user config and unrelated
plugins remain. If other plugins are present, their shared loader remains.

Publisher instructions: https://github.com/Glitchtest51/MiSide_VR

>>> Mita has new ways to keep you from leaving.

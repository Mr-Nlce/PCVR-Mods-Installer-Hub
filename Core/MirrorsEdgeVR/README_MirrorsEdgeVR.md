# Mirror's Edge VR

## About the Game

Mirror's Edge is the original 2008 first-person parkour game from DICE. Run, vault, climb and fight across a bright authoritarian city as Faith. This alpha VR mod adds native stereo rendering, 6DoF head tracking, motion-controlled hands, pistols, melee and experimental physical parkour.

## Requirements

- The original **Mirror's Edge (2008)** for Windows, not Mirror's Edge Catalyst.
- Virtual Desktop connected with **VDXR** selected as the OpenXR runtime. SteamVR and Meta Link / Air Link are not supported by this build.
- Microsoft Visual C++ 2015-2022 Redistributable **x86**. The x64 package alone is insufficient.
- Motion controllers use the Touch layout. Gamepad, keyboard and mouse remain available.

Typical locations:

- Steam: `C:\Program Files (x86)\Steam\steamapps\common\mirrors edge\Binaries\MirrorsEdge.exe`
- EA app: `C:\Program Files\EA Games\Mirror's Edge\Binaries\MirrorsEdge.exe`
- Origin: `C:\Program Files (x86)\Origin Games\Mirror's Edge\Binaries\MirrorsEdge.exe`
- Retail DVD: `C:\Program Files (x86)\EA Games\Mirror's Edge\Binaries\MirrorsEdge.exe`

## Installation and launch

The Hub downloads the newest compatible GitHub prerelease, verifies that `d3d9.dll`, `openxr_loader.dll` and `mevr.ini` are usable, and installs them beside `Binaries\MirrorsEdge.exe`. Existing files are recoverably backed up. An existing `mevr.ini` is preserved so updates do not erase personal VR settings.

1. Start Virtual Desktop and select VDXR.
2. Use **Start in VR** in the Hub. Steam installations use the Steam bootstrap; recognized EA, Origin and retail installations use their recorded executable.
3. The startup screens remain flat. Stereo begins after a level loads.
4. **The first connected launch requires one restart.** Let the mod record the headset resolution, quit the game completely, and use **Start in VR** again. Without this restart, the game can remain in a small flat window inside the headset.

If loading a chapter freezes, disable PhysX in the game's graphics settings. Also turn off the game's VSync and choose a frame cap the PC can hold. Hold [[Y]] for one second to open the VR settings. Do not edit files under `TdGame\Config`; the game checks their integrity.

## Controls

### Left controller

| Button | Action |
|---|---|
| [[Left Stick]] | Move and strafe. |
| [[Left Stick Click]] | Back or open the in-game tutorial menu. |
| [[Left Trigger]] | Crouch or slide; fire a pistol held in the left hand. |
| [[Left Grip]] | Jump with hand tracking off; grip with hand tracking on. |
| [[X]] | Reaction Time. |
| [[Y]] | Weapon action; hold one second for VR settings. |
| [[Menu]] | Pause. |

### Right controller

| Button | Action |
|---|---|
| [[Right Stick Left]] / [[Right Stick Right]] | Smooth or snap turn. |
| [[Right Stick Up]] / [[Right Stick Down]] | Jump or quick-turn with hand tracking on. |
| [[Right Stick Click]] | Weapon zoom where supported. |
| [[Right Trigger]] | Attack or fire the pistol held in that hand. |
| [[Right Grip]] | Quick-turn with tracking off; grip with tracking on. |
| [[A]] | Use or interact. |
| [[B]] | Look at the game's point of interest. |

### Motion interactions and shortcuts

| Button | Action |
|---|---|
| [[Either Grip]] | Pick up, hold, drop or throw a supported pistol. |
| [[Both Grips]] | Disarm when the game's normal disarm conditions are met. |
| [[Arm Swing]] | Run when arm-swing locomotion is enabled. |
| [[Hands Up]] | Jump when arm-swing locomotion is enabled. |
| [[Grip]] + [[Hand Movement]] | Climb ledges and pipes or swing from bars. |
| [[Page Up]] | Recenter the view. |
| [[F6]] | Rescan if stereo does not start after a level loads. |
| [[Pause]] | Hold on the keyboard to exit cleanly. |

Motion hands, gestures and parkour remain experimental. Tracked pistols currently cover the Colt1911 and Glock18c; other weapons retain native handling. Motion hands and arm-swing locomotion are enabled by default and can be changed under **Hands and movement**.

## Uninstall

Use **Uninstall now** on the game page. The Hub removes unchanged files it installed, restores pre-existing collisions, and preserves files changed after installation. The base game, saves and unrelated settings remain untouched.

## Links

- [Project and instructions](https://github.com/letsgosportsteam/mirrors-edge-vr-mod)
- [Releases](https://github.com/letsgosportsteam/mirrors-edge-vr-mod/releases)
- [VR gameplay](https://youtu.be/W2DAaAk7G5I?si=s9c7okVp05Bxo_B5)
- [Flat2VR Modding discussion](https://discord.com/channels/747967102895390741/1535660675085631600)

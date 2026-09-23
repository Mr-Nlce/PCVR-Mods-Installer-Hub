# Deus Ex: Human Revolution - DC VR

**DeusExHRVR v0.3.0 prerelease** by **farmerarmor** adds native same-frame stereo, headset tracking, motion-controller buttons and experimental right-hand weapon aiming to the Director's Cut. It uses the game's own AMD HD3D stereo renderer: both eyes are rendered in one game frame, not alternated through AER.

## About the Game

Deus Ex: Human Revolution is a stealth-action RPG about conspiracy, corporate power and human augmentation. The Director's Cut combines the main campaign with The Missing Link and revised boss encounters.

## Supported game build

This release supports exactly **Steam Director's Cut 2.0.66.0**. The installer verifies the reviewed original or Hub-patched `DXHRDC.exe` SHA-256 before changing anything. The original non-Director's Cut game, GOG builds and other executable versions are not supported by v0.3.0 and are deliberately rejected.

The unmodified game can crash before opening on CPUs with many logical processors. The Hub therefore applies only the established **High Core Count Fix**: five verified bytes at executable offset `864613` change from `E8 46 F0 FF FF` to five `90` NOP bytes. The patched executable has SHA-256 `B883591D023650B91C5C8D052C299AE23FE050DB66A221192035C3A9542D7F28`. This change is included in the same recoverable ownership transaction as the VR files; the original executable is backed up and restored by **Uninstall now**. The implementation and byte location were cross-checked against [DXHR Exe Patcher 1.6](https://www.nexusmods.com/deusexhumanrevolution/mods/28); the Hub does not bundle its Java patcher or enable any of its unrelated optional changes.

The game needs Windows, DirectX 11 and an active OpenXR runtime. Oculus and VDXR are reported working. The current prerelease has black-screen reports with SteamVR, and the author has not yet confirmed that runtime as fixed. Prefer the Oculus runtime or VDXR until a later release says otherwise.

## What setup changes

The Hub downloads the newest installable GitHub release, including prereleases, and installs these four matching publisher files together:

- `d3d11.dll`
- `atidxx32.dll`
- `atiadlxy.dll`
- `DeusExHRVR\DeusExHRVRHost.exe`

Any existing files at those paths and the original `DXHRDC.exe` are backed up with a per-file ownership manifest. The installer also enables DirectX 11/native stereo and disables game VSync and antialiasing for the tested VR configuration. Their previous registry values are recorded and restored by the Hub uninstaller.

On a fresh setup, the Hub creates `DeusExHRVR.ini` with motion controllers enabled, experimental weapon aiming enabled, `WorldUnitsPerMetre=300`, vertical-camera lock enabled, and interaction/movement following the headset. An existing INI is always preserved exactly during updates and removal.

## Start and runtime notes

Use **Start in VR** in the Hub as the primary launch path, then load a save; gameplay enters full VR automatically. The Hub routes the supported Steam installation through Steam so its normal session is preserved. Launching normally through Steam is the fallback. Main and pause menus, hacking, videos, game-over screens and the sniper scope use a 16:9 virtual screen, then return to full VR.

The mod is still a WIP prerelease. Extreme-angle weapon visibility, some lighting/shadow effects, body behavior during physical room movement, occasional weapon disappearance and broader mission coverage still need work. After a cutscene, use [[F9]] or [[Right Stick Click]] if the floor or view needs recentering. Native rumble is not mapped to VR haptics.

## Controls

The motion controllers emulate the game's default Xbox layout, with Y and B exchanged. Keyboard/mouse and a physical gamepad remain available.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Crouch |
| [[Right Stick]] | Turn camera |
| [[Right Stick Click]] | Quick press: iron sight or scope |
| [[Left Trigger]] | Take cover |
| [[Right Trigger]] | Fire |
| [[Left Grip]] | Sprint |
| [[Right Grip]] | Throw grenade |
| [[X]] | Interact or reload |
| [[Y]] | Non-lethal takedown; hold for lethal takedown |
| [[A]] | Jump |
| [[B]] | Holster or draw; hold for quick inventory |
| [[Right Stick Click]] + [[Left Stick]] | D-pad augmentations: up cloaking, down smart vision, left silent movement, right Typhoon |
| [[Left Menu]] short press | Back or in-game menu |
| [[Left Menu]] hold 1.5 seconds | Start or pause menu |
| [[F6]] | Toggle full VR and virtual screen |
| [[F9]] | Recenter |

The diagnostic hotkeys [[F3]], [[F4]], [[F7]], [[F8]] and [[F10]] are described in the upstream README. [[F8]] can write local captures and logs; inspect those files before sharing them.

## Direction and comfort settings

`InteractionAim` and `MovementDirection` can independently use `Mouse`, `Headset` or `Controller`. `LockVerticalCamera=1` keeps mouse/gamepad pitch out of the full-VR camera while retaining headset pitch and normal weapon aiming. `WorldUnitsPerMetre` accepts 10-1000: higher values make the world look smaller; lower values make it look larger.

v0.3.0 adds per-weapon grip calibration. Hold both thumbsticks for one second,
move the controller into the desired grip position and release to save that
weapon's offset; the saved offsets persist in `DeusExHRVR-weapons.ini`.
The comfort profile, SteamVR compatibility, color fixes, immersive sniper scope,
right-stick modifier controls and experimental Luma support from v0.2 remain.
Physical roomscale body movement is not implemented yet.

## Update and removal

The tile follows GitHub prereleases and records the exact installed tag. An update replaces the four owned runtime files and the reviewed high-core executable as one unit and keeps the user's INI. **Uninstall now** removes unchanged Hub-owned files, restores the original `DXHRDC.exe`, pre-existing collisions and original graphics values, and keeps configuration, saves, logs, captures and unrelated mods.

## Links

- [Project and complete upstream documentation](https://github.com/farmerarmor/DeusExHRVR)
- [Releases](https://github.com/farmerarmor/DeusExHRVR/releases)
- [VR gameplay](https://youtu.be/WFYtitqU-EY?t=79)
- [Flat2VR Modding discussion and support](https://discord.com/channels/747967102895390741/1548944616907087902)

# Hitman: Blood Money VR

## About the Game

Agent 47's stealth missions move into VR with tracked hands, physical item handling and a dedicated launcher. This is an early publisher alpha; the Steam edition has the clearest publisher test coverage.

## What you need

- An installed Windows PC copy of Hitman: Blood Money. Supported known EXE builds are checked by the publisher Setup. Start the flat game once and close it before installing.
- A headset and controllers. The publisher tested a Meta Quest with Link; the OpenXR backend is also offered, with possibly different button layouts.
- The official alpha package from [Blood Money VR releases](https://github.com/andreystashev/hitman-blood-money-vr-showcase/releases).

Unsigned VR files may produce antivirus warnings. Missing files can also mean a path, permissions or copy problem; inspect the installer log and security history before assigning a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]] on the tile. The Hub locates the base game, fetches the current alpha ZIP and opens the official publisher Setup only after an Enter prompt.
2. In publisher Setup, select `HitmanBloodMoney.exe`. Keep its default VR folder `%LOCALAPPDATA%\BloodMoneyVR` and finish Setup. The game files are not replaced. If the Hub previously installed the runtime under `%LOCALAPPDATA%\PCVR Mods Installer Hub\BloodMoneyVR`, update that existing folder in place instead.
3. **Use [[Start in VR]] in the Hub.** The matching **Hitman: Blood Money VR** desktop shortcut or `BloodMoneyVR.exe` in the dedicated VR folder starts the same publisher launcher. Steam editions are bootstrapped through Steam by that launcher. The shortcut uses the supplied Hitman icon, kept in the VR folder so it survives Hub updates.
4. Connect the headset, wake the controllers, and keep the game window focused. If headset output does not appear, press [[F9]]. After entering a mission, hold [[Right Stick Click]] for roughly 0.65 seconds to recenter.

**Important VR image settings:** In the game's own options, increase the resolution and enable anti-aliasing. During playtesting, these settings helped avoid a jittering VR image.

The publisher's `Collect-Diagnostics.cmd` sits in the dedicated VR folder. It writes a local diagnostics ZIP under `diagnostics` if you need to report a runtime issue. Settings are in `vr.ini`; `[VR] Backend` supports Auto, Meta and OpenXR.

Alpha 4 (0.1.8.173) improves Steam Link/SteamVR and Virtual Desktop/VDXR startup, controller pointing and stereo output. Open Blood Money VR Settings, select your connection, then choose Save & play. Connect Steam Link in the headset before choosing SteamVR in Settings.

Publisher Setup now resets all seven mod INIs on installation, update and reinstall: modifiers, calibration, audio and weapon-grip choices return to its defaults. Before opening Setup, the Hub saves existing copies under %LOCALAPPDATA%\PCVR Mods Installer Hub\Backups\HitmanBloodMoneyVR. Each dated folder includes the original files and a settings-backup.json listing their original locations. Reapply supported choices in the updated Settings app; do not replace all new defaults blindly. Game saves remain unchanged.

For two-hand inventory, short-click [[Right Stick Click]], browse with [[Right Stick Left]] or [[Right Stick Right]], then hold the grip of the hand that should receive the selected item. Keep holding it while selecting an item for the other hand, and short-click [[Right Stick Click]] again to close. Release a hand's grip *inside* inventory to stow its item; releasing it outside inventory drops it.

## Controls

| Button | Action |
| --- | --- |
| [[Left Stick]] | Walk and strafe relative to your view. |
| [[Left Stick Click]] | Toggle running. |
| [[Right Stick Left]] / [[Right Stick Right]] | Smooth turn. |
| [[Right Stick Click]] | Short press opens or closes inventory; hold about 0.65 seconds to recenter. |
| [[Grip]] | Grab or hold an item; release to drop or throw. |
| [[Weapon-hand Trigger]] | Fire or use the original melee attack. |
| [[A]] | Reload on release; confirm a menu choice. |
| [[B]] | Toggle crouch; go back in menus. |
| [[X]] / [[Y]] | Hold for nearby or personal actions; select with [[Right Stick]] and release to confirm. |
| [[Left Controller Menu]] | Pause or go back. |
| [[F6]] | Open VR options while paused or in a menu. |
| [[F7]] | Recenter. |
| [[F9]] | Toggle headset output. |
| [[F11]] | Toggle tracked hands and VR controls. |

While paused, hold both stick clicks for about 0.65 seconds to open VR settings.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [Blood Money VR discussion](https://discord.com/channels/747967102895390741/1562537911570923620)

## Links

- [Publisher project](https://github.com/andreystashev/hitman-blood-money-vr-showcase)
- [VR gameplay](https://youtu.be/SqO7tFqEDGA?t=24)

>>> Agent 47, your next disguise has a headset.

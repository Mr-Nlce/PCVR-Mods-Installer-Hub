# Gothic II VR

**VR port:** [gothic2-vr by dubrovskiy-yevhen-stakelogic](https://github.com/dubrovskiy-yevhen-stakelogic/gothic2-vr)  
**Current release checked:** [v0.2.0](https://github.com/dubrovskiy-yevhen-stakelogic/gothic2-vr/releases/tag/v0.2.0)  
**Flat2VR discussion:** [Gothic II VR thread](https://discord.com/channels/747967102895390741/1549536264657576046)  
**Video:** [Gothic II gameplay](https://youtu.be/ROqIqK28Nrk?si=mygr6NINC_eo2P45&t=636) — **flat gameplay, not VR footage**.

## About the Game

Gothic II is a fantasy role-playing game set on Khorinis and in the Valley of Mines. This independent PCVR port reads data from your purchased **Gothic II Gold / Night of the Raven** installation and is still an early alpha. A complete playthrough is not yet promised by the publisher.

## Install and update

The Hub checks for the base game's `system\Gothic2.exe` and `Data` folder. It searches Steam Gold, GOG Galaxy Gold, GOG offline Gold, and the two supplied JoWooD retail locations. You can select another folder if necessary. The base game is never overwritten.

The installer resolves the newest matching GitHub release and installs **only the `PCVR` content** from its combined PCVR/Quest ZIP into a separate folder (default `C:\Games\Gothic II VR`). It stores the selected base game path in `launcher-game-path.txt` and keeps existing `VR.ini`, `Gamepad.ini`, `Gothic.ini` and saves during updates. The Hub records owned files and the installed release only after the required runtime files are present. Do not put the PCVR folder inside the base game or the Hub.

For an update, run the same installer again and keep the same PCVR folder. A new GitHub release is offered by the Hub's normal update check. If automatic download fails, the installer offers retry and a manually downloaded publisher ZIP.

The PCVR build needs a Vulkan-capable graphics driver and Microsoft Visual C++ 2015–2022 x64 runtime. SteamVR has been tested by the publisher; Meta Link and Virtual Desktop are offered as runtime routes, while their gameplay remains unverified by the publisher.

## Start in VR

The Hub's **Start in VR** uses `START-PCVR.cmd`, which follows the currently selected OpenXR runtime. The installed PCVR folder also contains `START-STEAMVR.cmd`, `START-OCULUS.cmd` and `START-VIRTUAL-DESKTOP.cmd` for explicit runtime selection. These scripts change the runtime for their process, not the global Windows setting. Connect the headset before starting. Run `CHECK-OPENXR.cmd` in the PCVR folder if the selected runtime cannot find a headset.

## Controls

| Button | Action |
| --- | --- |
| [[Head movement]] | Look |
| [[Left Stick]] | Move and select menu rows |
| [[Left Stick Click]] | Toggle run |
| [[Right Stick]] | Turn |
| [[A]] | Jump; confirm in menus |
| [[B]] | Interact; go back in menus |
| [[X]] | Inventory |
| [[Y]] | Journal |
| [[Right Stick Click]] | Crouch action |
| [[Left Grip]] + [[Right Grip]] + [[Y]] | Open game menu |
| [[Left Stick Click]] + [[Right Stick Click]] | Open VR settings |
| [[Grip]] | Draw, hold, stow or throw a held object |
| [[Left Trigger]] / [[Right Trigger]] | Decrease / increase a VR setting |

Controls can be adjusted in **VR settings > Button mapping**. See the publisher's `CONTROLS.md` in the installed PCVR folder for physical combat, swimming, holsters and all advanced options.

## Uninstall

**Uninstall now** removes only unchanged Hub-owned PCVR files and restores files the Hub replaced. Modified files, profiles, saves, `launcher-game-path.txt`, unrelated content and the purchased Gothic II installation remain. Inspect the separate PCVR folder yourself before deleting any remaining user files.

>>> The Valley of Mines is closer than ever.

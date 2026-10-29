# Spider-Man Remastered - Spidy VR

## About the Game

Marvel's Spider-Man Remastered follows Peter Parker through an open-world New York City. Swinging, traversal, gadgets and close combat drive its story missions and side activities. This Motion Controls entry uses Spidy VR by Ilya Mezerowsky. The existing Luke Ross R.E.A.L. gamepad entry remains a separate Hub choice.

## Requirements and setup

The reviewed Windows package is Spidy v0.6.0. The Hub installs only its Windows runtime package; publisher data and reports are retained on update.

Spidy supports the Steam release of Marvel's Spider-Man Remastered only; the Epic Games Store build differs. The current publisher instructions identify game version 4.630.0.0. The launcher checks the installed build, so a new Steam patch may need a matching Spidy release. A PC VR headset and active OpenXR runtime are required. The author played with Quest 3 via Virtual Desktop and Steam Link/SteamVR. Other SteamVR headsets and Quest Link may work but are less proven. Windows must have roughly 19 GB available to applications from RAM and the page file combined; the launcher shows a memory check.

1. Install the Steam game and close it before setup. Choose [[Get Installer]] in this Hub entry. The Hub resolves the current GitHub Windows release, including prereleases, or you can explicitly choose a downloaded publisher ZIP. The complete Spidy package is placed in a writable folder outside the Steam game. It uses %LOCALAPPDATA%\SpidyVR when that drive has room, with D:\Games\SpidyVR or E:\Games\SpidyVR as space fallbacks. An existing Hub-owned location is reused for updates. The Hub does not copy its files into the game folder.
2. Choose [[Start in VR]] to open Spidy Launcher.exe. Resolve any red checks. Choose the runtime connected to your headset; Automatic usually finds it. The launcher can guide installation of the Microsoft Visual C++ runtime and offers its own desktop and Start-menu shortcuts. Choose Add shortcuts there if wanted.
3. Close Spider-Man if it is already running. Connect the headset, then press START VR in Spidy Launcher. It starts the Steam game. Intro, menus, cutscenes and loading screens appear on a virtual screen; full VR begins during gameplay. The first session asks for body calibration: stand tall, face forward, spread both arms and hold both triggers until the bar fills. [[B]] skips calibration; the SPIDY VR settings tab can request it again after loading a save.
4. Keep the game window in front on the desktop. Click it once if the headset image appears frozen, since another foreground window pauses the game. Press STOP VR or close the game to end the session. Close Spider-Man completely before starting another VR session.

The publisher launcher temporarily uses a small desktop window, disables frame generation and Windows.Gaming.Input during the VR session, then restores those game settings when the game closes. The Hub's Start in VR button opens the publisher launcher; START VR there remains the action that starts the game. Spidy's launcher and the Luke Ross Hub entry have independent install and removal routes. If a previously active game-folder injector affects a Spidy session, first identify and disable that injector through its own controls; Spidy does not require it.

## Controls

| Button | Action |
|---|---|
| [[Either Grip]] | Shoot and hold that hand's web; release to let go or throw a caught object |
| [[Either Trigger]] | Reel in an attached web; otherwise fire a web ball or the selected gadget |
| [[Either Grip]] with Web button set to Trigger | Reel in or fire; [[Either Trigger]] shoots and holds the web instead |
| [[Either Hand]] sharp pull | Zip to the web anchor or yank a caught object |
| [[Either Grip]] with free hand on the web | Climb hand over hand; release the lower grip and reach higher |
| [[Either Fist]] fast punch | Punch the marked enemy; can close a gap up to 10 metres |
| [[Left Stick]] | Walk or run; on a wall, move along it |
| [[Left Stick Click]] | Toggle slow motion while Focus remains |
| [[Right Stick]] | Snap or smooth turn |
| [[Right Stick]] up, held | Zip to a point or vent; with no point, slow time and aim, then release |
| [[Right Stick]] down, held | Heal |
| [[A]] | Jump; hold on the ground and release for a charged leap; confirm menus |
| [[B]] + [[Left Stick]] | Dodge in the selected direction; [[B]] also goes back in menus |
| [[Y]] | Interact or web strike; hold to step up to a nearby object |
| [[X]] held | Select a gadget with that hand, then release; free-hand trigger fires it |
| [[X]] when the game requests [[LB]] + [[RB]] | Throw a prop, tear a door or grate; hold if the prompt requires it |
| [[Either Trigger]] with hand at temple | Scan |
| [[Left Trigger]] + [[Right Trigger]] with hands at chest | Activate suit power when its meter is full |
| [[Either Grip]] held behind hip, then bring hand forward | Draw the phone |
| [[Either Stick]] + [[A]] while the phone is open | Choose and open an app; MENU opens map, suits and skills |
| [[B]] while the phone is open | Go back or put the phone away |
| [[Left Trigger]] / [[Right Trigger]] in the phone | Lower or raise music volume |
| [[Left Trigger]] then [[Right Trigger]] in phone CAMERA | Open the viewfinder, then take a photo; [[Right Stick]] up puts it away |
| [[Menu]] or [[Left Stick Click]] + [[Right Stick Click]] held | Pause; open Settings > SPIDY VR |
| [[Either Grip]] near a wall, then pull | Experimental hand wall climbing, when enabled |
| [[Right Stick]] in the air | Basic FLIPS when enabled; release holds the angle, [[A]] returns upright |
| [[A]] in the air, then [[Left Stick]] | CONTROLLED FLIPS when enabled; [[A]] again returns upright and exits |
| [[Left Trigger]] + [[Right Trigger]] in a T-pose | Body calibration when requested |
| [[A]], [[B]], [[X]], [[Y]] when prompted | Press the named game button; [[LT]] or [[LB]] uses [[Left Trigger]], [[RT]] or [[RB]] uses [[Right Trigger]] |
| [[Left Stick Click]] / [[Right Stick Click]] when prompted | The game's [[L3]] / [[R3]]; [[Right Stick]] supplies requested D-pad directions |

Quest Touch button names are shown. The publisher's linked players' guide has Index, Steam Frame and PS VR2 mappings. Realistic flips retain their own gesture controls and take priority over the two optional flip modes. In SPIDY VR settings, [[Left Stick]] changes a selected value, [[X]] resets it, [[Y]] resets the tab and [[B]] goes back.

## Updates, removal and troubleshooting

The Hub checks publisher GitHub releases, including prereleases. The publisher launcher also offers an optional in-app update bar; close VR and the game before using either update route. Reinstalling through the Hub preserves user-created reports and preferences and refuses to overwrite a publisher file changed since the Hub installed it. [[Uninstall now]] removes only unchanged Hub-owned launcher files, restores any earlier same-name files, and leaves the Steam game, Luke Ross files, reports and settings alone. The Uninstall guide on this detail page explains the retained data.

- Unsupported game version: verify that this is the Steam edition and game version 4.630.0.0. In Steam Properties > Betas, leave the rollback beta if one is selected; verify the game files if an injector changed Spider-Man.exe. Wait for a compatible Spidy release if Steam changed its build. The Hub's VR Ready state proves package files, not in-game build compatibility.
- Headset missing: connect it, start the relevant runtime and choose Re-check in Spidy Launcher. Select the right runtime manually if Automatic chooses incorrectly.
- VR already ran in this game: close Spider-Man.exe fully, then press START VR again. Spidy starts VR only once per game process.
- Menus ignore controllers or the image appears still: bring the game window to the desktop foreground. Launch with the game closed so the publisher can set up controller access and render memory.
- Low frame rate: lower the launcher's Render resolution or the Virtual Desktop streaming quality. Blurry image: try around 125% Render resolution if GPU memory and frame rate permit.
- Unexpected missing files: inspect the Hub installer log and Windows protection history for a matching dated event. A missing file alone does not establish an antivirus cause. The Spidy session reports in its reports folder are useful for publisher support.

## Links

[Publisher project and full instructions](https://github.com/IlyaMez/SpidyVR) · [Releases](https://github.com/IlyaMez/SpidyVR/releases) · Join [Flat2VR Modding](https://discord.gg/flat2vr) first, then open the [Spidy VR discussion](https://discord.com/channels/747967102895390741/1557408964612849695) · [VR gameplay](https://www.youtube.com/watch?v=T82Av8eYjnk)

## Support the developer

Spidy is free. Optional support: [Ilya Mezerowsky on Ko-fi](https://ko-fi.com/ilyamezerowsky).

>>> The city is yours. Take the next swing.

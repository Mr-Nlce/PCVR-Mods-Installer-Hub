# Spider-Man Remastered - Spidy VR

## About the Game

Marvel's Spider-Man Remastered follows Peter Parker through an open-world New York City. Swinging, traversal, gadgets and close combat drive its story missions and side activities. This Motion Controls entry uses Spidy VR by Ilya Mezerowsky. The existing Luke Ross R.E.A.L. gamepad entry remains a separate Hub choice.

## Requirements and setup

The reviewed Windows package is Spidy v0.3.8. Its launcher retains the Auto
aspect-ratio choice for VR and identifies a R.E.A.L. VR mod already present in
the game folder. The release also includes experimental Linux files; the Hub
continues to install only the Windows package for its supported Steam route.

Spidy supports the Steam release of Marvel's Spider-Man Remastered only; the Epic Games Store build differs. The current publisher instructions identify game version 4.630.0.0. The launcher checks the installed build, so a new Steam patch may need a matching Spidy release. A PC VR headset and active OpenXR runtime are required. The author played with Quest 3 via Virtual Desktop and Steam Link/SteamVR. Other SteamVR headsets and Quest Link may work but are less proven. Windows must have roughly 19 GB available to applications from RAM and the page file combined; the launcher shows a memory check.

1. Install the Steam game and close it before setup. Choose [[Get Installer]] in this Hub entry. The Hub resolves the current GitHub Windows release, including prereleases, or you can explicitly choose a downloaded publisher ZIP. The complete Spidy package is placed in a writable folder outside the Steam game. It uses %LOCALAPPDATA%\SpidyVR when that drive has room, with D:\Games\SpidyVR or E:\Games\SpidyVR as space fallbacks. An existing Hub-owned location is reused for updates. The Hub does not copy its files into the game folder.
2. Choose [[Start in VR]] to open Spidy Launcher.exe. Resolve any red checks. Choose the runtime connected to your headset; Automatic usually finds it. The launcher can guide installation of the Microsoft Visual C++ runtime and offers its own desktop and Start-menu shortcuts. Choose Add shortcuts there if wanted.
3. Close Spider-Man if it is already running. Connect the headset, then press START VR in Spidy Launcher. It starts the Steam game. Intro, menus, cutscenes and loading screens appear on a virtual screen; full VR begins during gameplay. The first session asks for body calibration: stand tall, face forward, spread both arms and hold both triggers until the bar fills. [[B]] skips calibration; the SPIDY VR settings tab can request it again after loading a save.
4. Keep the game window in front on the desktop. Click it once if the headset image appears frozen, since another foreground window pauses the game. Press STOP VR or close the game to end the session. Close Spider-Man completely before starting another VR session.

The publisher launcher temporarily uses a small desktop window, disables frame generation and Windows.Gaming.Input during the VR session, then restores those game settings when the game closes. The Hub's Start in VR button opens the publisher launcher; START VR there remains the action that starts the game. Spidy's launcher and the Luke Ross Hub entry have independent install and removal routes. If a previously active game-folder injector affects a Spidy session, first identify and disable that injector through its own controls; Spidy does not require it.

## Controls

| Button | Action |
|---|---|
| [[Either Grip]] press | Shoot and hold that hand's web to swing; while aimed at a prop or thug, catch it. |
| [[Either Grip]] release | Let go of a web or throw a caught prop or thug. |
| [[Either Trigger]] with attached web | Reel in. |
| [[Either Trigger]] without attached web | Shoot one web ball from that hand's wrist. |
| [[Either Grip]] or [[Either Trigger]] after changing Web button to Trigger | Shoot and hold a web with the trigger; the grip then reels in or shoots web balls. The original grip-web layout remains the default. |
| [[Either Hand]] sharp pull | Zip toward the web anchor or yank a caught object to your hand. |
| [[Either Fist]] fast punch | Strike a thug; a faster punch gives stronger knockback. |
| [[Left Stick]] | Walk and run; navigate menus. |
| [[Left Stick Click]] | Toggle slow motion while Focus remains; the meter at the left wrist refills after use. |
| [[Right Stick]] | Snap turn or smooth turn according to SPIDY VR settings. |
| [[A]] | Jump; select in virtual-screen menus. Optional experimental flips use [[A]] or [[Left Stick]] while airborne after Flips is enabled. |
| [[B]] | Interact, use prompts or web strike; back in menus. |
| [[Menu]] | Pause; Start in virtual-screen menus. |
| [[Y]] | Open the game menu with map, suits and skills. |
| [[X]] | Toggle web aim markers; reset a selected SPIDY VR setting in its menu. |
| [[Both Stick Clicks]] | Switch between VR gameplay and the flat game screen. |
| [[Grips]] in virtual-screen menus | Switch menu tabs. |

The web aim markers use a ring with a dot for a valid anchor, a dashed ring for open-air holding, a red cross for a miss and three turning arcs for a catchable target. The left-hand markers are blue and the right-hand markers orange. The launcher and Settings > SPIDY VR control Web button, aim markers, open-air webs, swing speed, weight, turning, vibration, screen size, floating HUD and experimental flips. The SPIDY VR tab appears after loading a save, not in title-screen Options. In the tab, [[Left Stick]] changes the selected setting, [[X]] resets one setting, [[Y]] resets the tab and [[B]] goes back. Catches, web shooter, visible body and punching remain active in current publisher builds.

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

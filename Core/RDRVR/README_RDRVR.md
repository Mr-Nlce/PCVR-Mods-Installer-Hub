# Red Dead Redemption VR

## About the Game

Red Dead Redemption is an open-world Western action adventure about John Marston's pursuit of his former gang across the American frontier. RDRVR by Disonomouss adds native stereo OpenXR rendering, a first-person body, tracked hands, physical guns and holsters, manual reloading, and an in-headset settings menu. Menus, loading and videos appear on a cinema screen; gameplay uses the headset view.

## Requirements and installation

The publisher supports the 2024 PC game from Steam or Rockstar Games Launcher. Epic Games Store and Xbox-app copies are not confirmed by the publisher and are outside this Hub installer's automatic routes. A Windows 10/11 PC, DirectX 12 GPU, PC VR headset and active OpenXR runtime are required. Only Quest 3 with Touch controllers has been tested by the author in a real headset; the mod also offers bindings for Index, Vive, WMR and Pico controllers.

RedHook v0.8 by K3rhos is required and comes from Nexus, not from the RDRVR release. Nexus sign-in may be needed. If the Hub finds a RedHook ZIP in your configured Windows Downloads folder, it shows its filename and asks whether to use it. If you decline or no ZIP is found, drag a different ZIP into the installer or paste its path; Enter opens the Nexus page. The Hub copies the three runtime files and sets `[DirectXHook] Disabled=true` in the newly installed RedHook.ini. If RedHook already exists, the Hub requires all three files and this setting but does not alter that existing configuration. Download the RedHook main file, not the SDK.

1. Install and close the Steam or Rockstar PC game. On this page choose [[Get Installer]]. Read the initial notice before pressing Enter.
2. If RedHook is missing and its ZIP is already in Downloads, answer Yes to use the displayed file. Otherwise drag the main ZIP into the installer or paste its full path; press Enter to open Nexus if you still need to download it. If RedHook already exists with its DirectX hook enabled, set `Disabled=true` under `[DirectXHook]` in RedHook.ini and retry.
3. The Hub resolves the latest RDRVR GitHub Windows release, including prereleases, or accepts a publisher ZIP that you explicitly select. It stages and checks the six needed mod files, copies them beside RDR.exe, protects same-name original files, and records the installed version only after the required files survive the copy check. The game must be closed throughout setup.
4. Start your OpenXR runtime and choose [[Start in VR]]. On Steam this uses the Steam game launch route. For a Rockstar copy, sign in to Rockstar Games Launcher as normal. If direct launch cannot establish its license session, open the game through that launcher.

The mod's initial RDRVR.ini ships with the game folder. Changes in the in-headset menu are saved in `%LOCALAPPDATA%\RDRVR\RDRVR.user.ini` and take precedence. This user file remains after an update or Hub removal. The original game and save files are never part of the mod payload.

The reviewed 0.8.11 release fixes shimmer and hand jitter on a gun carried from outdoors into a building. Its optional two-trigger fist stance lets you punch or block with empty hands; turn that gesture off in the Gestures tab if it conflicts with an unarmed game action. RedHook v0.8 remains required.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move; steer the horse when stick steering is selected. |
| [[Right Stick]] | Smooth or snap turn, including on horseback; while the menu button is held, act as the D-pad. |
| [[Left Stick Click]] | Brake while riding a horse. |
| [[Right Trigger]] | Fire the gun in hand; point at a menu item and select it while the settings laser is active. |
| [[Either Trigger]] with a hand at your mouth | Whistle for the horse; if the other hand aims a gun, the mod briefly releases aim before whistling. |
| [[Either Grip]] | Grab a gun from a holster, hold a round at the chest for manual reloading, or use an item in hand. |
| [[Either Grip]] release near a holster | Put the held gun away. |
| [[Menu]] tap | Send the game's Start input. |
| [[Menu]] hold | Open the RDRVR in-headset settings menu. |
| [[Y]] hold while viewing the wrist HUD | Open the in-headset settings menu. |
| [[Y]] twice with the off-hand wrist HUD visible | Open the satchel when the optional wrist-satchel setting is enabled; [[B]] closes it. |
| [[A]] while [[Menu]] is held | Send the game's Back/map input. |
| [[Both Stick Clicks]] hold for one second | Recenter the VR view. |
| [[Scroll Lock]] | Recenter while the desktop game window has focus. |
| [[F7]] | Open the in-headset settings menu from the keyboard. |

Other controller buttons act as the game's remappable gamepad inputs: [[A]], [[B]], [[X]], [[Y]], [[Left Grip]] as LB, [[Right Grip]] as RB, [[Left Trigger]] as LT and [[Right Trigger]] as RT. The game's rumble reaches the controllers. To reload physically, grip a round at your chest and bring it to the gun's loading point. The menu laser, trigger and right stick operate its tabs and rows. An optional weapon-wheel mode holds a grip to show the wheel, moves the hand toward a weapon and releases to select it. Optional hand throwing releases the grip after readying a throwable with its trigger.

## Comfort, performance and limits

Before playing in VR, open the game graphics settings and set Depth of Field to Off. With it enabled, the headset image can be severely blurred.

The HUD can float in front of you or sit on your wrist. Choose body visibility, handedness, holster placement, turning mode, reticle and gesture options in the headset menu. Current publisher builds add headset-size render presets, a horse whistle, the optional weapon wheel and wrist satchel, and more holster and front-hand choices. Some newer features were tested by the author only in an OpenXR simulator, not yet in a headset. Use FXAA for eye-shaped rendering; changes to render resolution apply from the next start. The author recommends Windowed mode for the new resolution option because Fullscreen can override a smaller requested size. Keep the OpenXR runtime's own resolution scale at its default when using the mod's percentage setting, since the two scales multiply.

Native stereo draws twice per frame. Lowering headset refresh rate to 72 or 80 Hz may help maintain real frames; runtime frame generation can make guns lag behind the hands. Back holster long guns cost extra frame time. DLSS is experimental and may feel laggy; FXAA is the default, with TAA also available.

If the game launches flat, check the installed RDR.exe build, RedHook v0.8, `[DirectXHook] Disabled=true`, and active OpenXR runtime. The mod writes `RDRVR_build_report.txt` and `RDRVR.log` in the game folder; a build it cannot safely recognize causes its hooks to stand down rather than guessing. Send those reports to the publisher issue tracker when reporting a build problem. Rare freezes or very low frame rates have been reported by the author. Changing the game's graphics resolution while in the headset temporarily returns to the cinema screen until a restart. The game sends crash reports to Rockstar even when a mod is installed.

## Updates and removal

The Hub watches RDRVR GitHub releases including prereleases. Close the game before updating. The Hub updates only files in its RDRVR ownership list; a locally changed owned file blocks replacement for review. [[Uninstall now]] removes unchanged Hub-owned RDRVR files, restores any earlier same-name originals, and preserves files changed afterward. RedHook stays installed, matching the publisher's removal behavior. The original game, saves, RedHook and your `%LOCALAPPDATA%\RDRVR` settings remain yours.

## Links

[RDRVR publisher and full documentation](https://github.com/Disonomouss/RDRVR) · [RDRVR releases](https://github.com/Disonomouss/RDRVR/releases) · [RedHook v0.8 on Nexus](https://www.nexusmods.com/reddeadredemption/mods/192?tab=files) · Join [Flat2VR Modding](https://discord.gg/uAeQkYBM4n) first, then open the [RDRVR discussion](https://discord.com/channels/747967102895390741/1557309171555369020) · [VR gameplay](https://youtu.be/s215LWkVHaw?t=53)

>>> The frontier is waiting. Ride into it.

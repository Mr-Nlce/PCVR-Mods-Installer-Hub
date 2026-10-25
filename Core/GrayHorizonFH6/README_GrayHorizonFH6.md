# Forza Horizon 6 VR - GrayHorizon

## About the Game
Explore Japan, join the Horizon festival and take your car collection across scenic roads and dense cities. GrayHorizon adds a head-tracked stereo cockpit and adjustable instrument panels while retaining your gamepad or steering-wheel controls.

## What you need
- Forza Horizon 6 from Steam or Xbox/Game Pass, installed in a writable game/Content folder.
- A connected PC VR headset and active OpenXR runtime. Pimax OpenXR and SteamVR were tested by the publisher; other combinations need confirmation.
- A gamepad or wheel. This is seated cockpit VR with head tracking, without motion-controller driving.
- Close the game and other VR launchers. Remove any competing Forza VR deployment through its own Hub tile/launcher before testing this mod.

## Install and start
1. Choose [[Install]] on this GrayHorizon tile. The installer displays the game folder and store, then guides the required settings before placing the mod.
2. Save those options in the normal game, exit, then return to the installer. It downloads the current stable FH6 package and preserves your existing configuration. Xbox/Game Pass automatically receives the differently named xinput1_4.dll proxy.
3. Use [[Start in VR]] in the Hub with the headset connected. Alternatively use your matching Steam/Xbox library or the Forza Horizon 6 - GrayHorizon VR Desktop shortcut. Switch to cockpit view.
4. After the first headset launch, exit and restart once for the measured field of view and correct picture size. The initial run may look softer.
5. The installer saves the destination file lists before and after installation, their differences and its log in one report in the Hub folder Core\Logs\Untested. Play a few minutes, choose Provide feedback on this page or above the installed candidate tile. It opens the GitHub form and the report folder with forza-horizon-6-grayhorizon-test-result.txt selected; drag the TXT into Installer log after reviewing it. Repeat attempts create a numbered report and preserve your earlier feedback. This candidate has not yet been confirmed on a real game by a Hub tester.

## Required game settings
- Video: V-Sync off, frame rate unlocked, motion blur off.
- Turn off the game's own TAA, FXAA, DLSS, FSR, XeSS, CAS and Frame Generation. Use GrayHorizon's upscaler or AA instead. Turn MSAA off when using an upscaler.
- HDR off in the game; also check Windows HDR if needed. HDR can prevent VR from starting on Meta/Quest runtimes.
- HUD and gameplay > HUD Safe Frame: Horizontal 5 / Vertical 9. The captured HUD needs these exact stock positions.
- Data Out on, IP 127.0.0.1, port 20440. This enables per-car HUD layouts and improves FH5/FH6 tracking.
- Radar position: Center right.
- Already feeding SimHub/a rig? Point the game at the mod's port and enter the old destination in GrayHorizon Settings > Pass Data Out on to. Up to eight destinations can be forwarded.
- Keep Environment Geometry and Environment Texture high if possible to reduce roadside pop-in.

## Controls
Defaults work while the game window has focus. Rebind keys, wheel or gamepad buttons in GrayHorizon Settings.

| Button | Action |
| --- | --- |
| [[F12]] | Open or close the in-headset menu |
| [[F8]] | Toggle VR |
| [[Ctrl]] + [[Space]] | Recenter |
| [[Ctrl]] + [[Up]] / [[Ctrl]] + [[Down]] | Move the seat forward / backward in 1 cm steps |
| [[Ctrl]] + [[Page Up]] / [[Ctrl]] + [[Page Down]] | Raise / lower the seat in 1 cm steps |
| [[F11]] | Toggle the speedometer for this session |
| [[F5]] | Show the frame-rate readout |
| [[F6]] | Show performance over the last 30 seconds |
| [[F9]] | Show or hide the status/settings window |
| [[F3]] | Save a headset screenshot in Pictures/GrayHorizon |
| [[F4]] | Capture large diagnostic files for a problem report |
| [[Up]] / [[Down]] or [[D-pad Up]] / [[D-pad Down]] | Choose a menu row |
| [[Left]] / [[Right]] or [[D-pad Left]] / [[D-pad Right]] | Change a menu setting |
| [[Enter]] or [[A]] | Select |
| [[Esc]] or [[B]] | Go back or close |

## Cockpit and HUD
Choose Adjust HUD in the headset menu to move, resize or hide each floating panel. Leaving the menu saves the current car's layout. Save as default for all cars changes the default while preserving individually edited cars. Data Out is required for distinct per-car HUD layouts; seat adjustments are stored per car.

Bind the menu to a wheel's D-pad in GrayHorizon Settings if desired. The menu button is kept from the game. Other bound buttons normally still reach the game while the VR menu is closed.

## Performance and help
The renderer alternates eyes, so aim for twice the headset refresh rate: 144 game frames per second for a 72 Hz headset. Stereo pairs per second should match the headset rate. High GPU load calls for lower resolution/upscaling scale, trim or foveated rendering; low GPU load with low frame rate usually calls for lower CPU-heavy detail. Dense cities are demanding.

Use the default canted mode and the suggested resolution in GrayHorizon Settings. Start SteamVR resolution at 100%. For a stretched picture or eyes that do not fuse, try plain_views=1; SteamVR enables this correction automatically. For a washed-out or dark headset picture, try the other srgb_swapchain value (1 or 0). A monitor-only mismatch may be Windows Auto HDR.

Incomplete HUD panels mean the stock Safe Frame or radar position needs checking. A newly updated game can remain flat until the mod supports that executable build. The publisher's tested versions are Steam 6.461.691.0 / Store 3.461.691.0.

Use safe_mode=1 to diagnose without optional features. Report the relevant gh6vr.log, game/store version, headset and runtime; FH5/FH6 retain the previous three logs. Online play is at your own risk because the mod hooks rendering and the cockpit camera.

## VR files and updates
[Open the installed game folder](.) and [GrayHorizon Settings](GrayHorizon Settings.exe) become available when their targets exist. [Start GrayHorizon VR](Start GrayHorizon VR.lnk) is the normal-store shortcut used by the Xbox route and the Desktop alternative. Steam copies use the Steam bootstrap directly from the Hub.

Steam keeps gh6vr.ini, logs and HUD/seat files beside ForzaHorizon6.exe. Xbox/Game Pass keeps writable settings/logs in Documents/GrayHorizon/FH6; the Content-folder INI is only a starting copy. The Hub preserves existing configuration. GrayHorizon Settings also offers its own updater while the game is closed. After using that separate updater, repair through the Hub before removal if files are reported as changed.

For temporary flat play, untick VR in GrayHorizon Settings. Full removal is covered by Uninstall guide.

## Links
- [Publisher and current releases](https://github.com/GrayHorizon-mod/Forza-Horizon-VR)
- [Detailed settings](https://github.com/GrayHorizon-mod/Forza-Horizon-VR/blob/main/SETTINGS.md)
- [HUD, seats and wheel-menu guide](https://github.com/GrayHorizon-mod/Forza-Horizon-VR/blob/main/HUD-AND-SEAT.md)
- [Performance guide](https://github.com/GrayHorizon-mod/Forza-Horizon-VR/blob/main/PERFORMANCE.md)

## Support GrayHorizon
- [Optional tip on Ko-fi](https://www.ko-fi.com/GrayHorizon)

The racing line is a suggestion. The guardrail is less flexible.


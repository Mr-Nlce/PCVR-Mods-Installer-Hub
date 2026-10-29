# Bendy and the Ink Machine - VR

## About the Game
Explore Joey Drew Studios, solve its ink-stained puzzles and discover what became of the old animation workshop. Motion-controlled hands bring its doors, weapons and machinery within reach.

## Choose your mod
1. InkVR by StrikeZoneVR is recommended for the current Steam game. It uses OpenXR, physical interactions, tracked hands and body, and VR versions of the chapters and Archives. No depot download is needed.
2. Team Beef BendyVR 1.2.2 uses a separate, fixed Steam depot, normally C:\Games\Bendy VR or your chosen folder. The game build and mod version stay pinned. Existing depot installations remain usable.

The obsolete Team Beef installation on the current Steam build is no longer offered. InkVR setup protects existing same-name files; it does not delete old extracted mod folders or change the independent Team Beef depot.

## Requirements
InkVR requires the current Steam PC game and a connected PC VR headset with its active OpenXR runtime. Quest 3 with Virtual Desktop was tested by the publisher; Quest Link, Air Link and SteamVR are listed. Meta Touch and Index bindings are included. It does not run standalone on Quest. Other store builds are not confirmed for InkVR.

Team Beef requires its mod-compatible older game build, SteamVR and motion controllers. Warning: WMR with Oasis will probably not work with Team Beef. The Reverb G2 test failed to supply its skeletal finger-tracking data; hands stayed on the floor. A future Oasis update may change this. This warning is specific to Team Beef, not an InkVR headset test.

## Install and start
1. Close Bendy and its launcher. Choose Install in the Hub, then InkVR (option 1) or Team Beef Depot (option 2). The depot route keeps your current Steam game separate.
2. Start your headset runtime. Use Start in VR in the Hub; when both routes are installed, choose InkVR or Team Beef Depot.
3. InkVR alternative: use the Bendy InkVR desktop shortcut. For settings, controls, flat play or troubleshooting, open InkVR Launcher and use PLAY WITHOUT VR, VR SETTINGS or VR CHECK as appropriate.
4. Team Beef alternative: the Bendy VR desktop shortcut. Keep SteamVR running first. Ordinary Steam Play runs your retail game, not the dedicated depot.

## Controls
InkVR uses these default controls. Physical interactions can be adjusted in its VR SETTINGS. The launcher also has a CONTROLS page.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] or [[Left Trigger]] | Run |
| [[Right Stick]] | Turn |
| [[Right Stick Click]] | Weapon wheel |
| [[Right Trigger]] | Use weapon; melee can also use a physical swing |
| [[X]] | Interact |
| [[A]] | Jump |
| [[Y]] held | Inventory |
| [[B]] | Back in menus |
| [[Left Grip]] or [[Right Grip]] | Grab and use objects |
| [[Menu]] | Pause |

Team Beef uses SteamVR bindings; the dominant hand operates weapons and the other hand interacts. Check its Advanced Menu and controller bindings for headset-specific assignments.

| Button | Action |
|---|---|
| [[Non-dominant Stick]] | Move |
| [[Non-dominant Stick Click]] or [[Non-dominant Grip]] | Run |
| [[Non-dominant Trigger]] | Interact |
| [[Dominant Stick]] | Turn |
| [[A]] | Jump |
| [[B]] | Seeing Tool in Chapter 5 or New Game+ |
| [[Dominant Trigger]] | Fire or throw |
| [[Y]] | Pause |

## Settings and help
InkVR: use the game's Options > VR SETTINGS for comfort, handedness, world size, body style and graphics. If the scale is wrong, stand up and let the mod recalibrate. Open VR CHECK in InkVR Launcher if installation or runtime selection fails. First launch may take time while BepInEx generates its IL2CPP interop files.

Team Beef: the Advanced Menu offers comfort and handedness settings. Lower expensive post-processing if needed. Its ending cinematic is screen-locked; quit and restart after the credits for New Game+ or Archives. Its openvr_fsr configuration is in the depot game's Bendy and the Ink Machine_Data\Plugins\openvr_mod.cfg.

Missing mod files do not by themselves prove antivirus removal. Check the chosen game folder, installer log and matching protection-history events. Recovery can reopen the official release page and accept its downloaded ZIP.

## VR files
InkVR Start in VR opens InkVR\InkVR Launcher.exe with --play vr inside the current game folder. InkVR Launcher and the complete InkVR-Payload stay together in that child folder, which the publisher explicitly supports for locating its parent game. The installed mod is BepInEx\plugins\InkVR\InkVR.dll; Unity OpenXR runtime files live under the game's data folder. Flat / VR opens the publisher launcher for PLAY IN VR or PLAY WITHOUT VR. Settings and logs are in BepInEx\config and BepInEx\LogOutput.log.

Team Beef Depot starts Bendy and the Ink Machine.exe in its independent depot folder. Keep BendyVRInstall: its BepInEx preloader is referenced by doorstop_config.ini. The Hub displays detected start apps and installation folders as links when present. If the Hub does not find your game, you can choose Locate Game and select its game EXE.

## Support the modders
- StrikeZoneVR on Ko-fi: https://ko-fi.com/strikezonevr
- Team Beef on Patreon: https://www.patreon.com/teambeef

## Links
- InkVR source and documentation: https://github.com/StrikeZoneVR-hub/InkVR
- InkVR releases: https://github.com/StrikeZoneVR-hub/InkVR/releases
- Team Beef documentation: https://github.com/Team-Beef-Studios/BendyVR

>>> Dreams come to life. So does the ink.

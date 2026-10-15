# No One Lives Forever VR

## About the Game

The Operative: No One Lives Forever is a 1960s spy shooter starring Cate Archer. Its missions move between stealth, gadgets, dialogue and firefights against H.A.R.M. You need your own installed copy; neither VR project ships the original game's data. The Hub offers two independent PC VR ports. Install either or both, then choose the matching Play button. They live outside your original game folder.

## ReLith by alex-nax — recommended, option 1

[ReLith releases](https://github.com/alex-nax/relith/releases) provide a modern replacement LithTech engine, with PC VR through OpenXR. It uses your own original NOLF files and does not need the original engine executable after setup. The Hub's current Windows asset is `relith-nolf-windows-vr-0.4.1.zip`; GitHub stable releases are checked for later updates. Start your active OpenXR runtime, then use Play ReLith. ReLith is VR only in this Windows release; a monitor-only mode is planned.

The original installed game folder must provide `lithtech.exe`, `NOLF.REZ`, `NOLF2.REZ` and the `nolfu003.rez` 1.003 patch for the Hub's guided setup. ReLith also needs `nolfu003cres.rez` for menu text; the Hub accepts the documented alternate `nolf003cres.rez` and copies it under the expected name. The optional `NOLFGOTY.REZ` adds the bonus chapter, `Movies` adds cutscenes, and `FontData.fnt` may improve font handling. Those original files are copied into the separate ReLith folder and preserved when the VR engine is removed. If you own the original discs but have no installed game folder, first build a legitimate game-data folder according to the [publisher's Windows guide](https://github.com/alex-nax/relith/blob/main/INSTALL-WINDOWS.md), then select it in the Hub installer. ReLith requires Windows 10/11 x64, an OpenGL 4.5 GPU and the Microsoft Visual C++ 2015–2022 x64 runtime. It ships the Modernizer resource pack; a separate Modernizer download is unnecessary.

### ReLith controls

The Main Hand option switches the hand assignments. The defaults below assume the right hand is the main hand.

| Button | Action |
|---|---|
| [[Left Stick]] | Move in the direction you look. |
| [[Right Stick]] left/right | Snap turn by default; smooth turn is an option. |
| [[Right Stick]] up | Jump. |
| [[Right Stick]] down | Toggle crouch. |
| [[Right Trigger]] | Fire; point at menus and pull to select. |
| [[A]] | Jump. |
| [[B]] | Use or activate; skip a panel cutscene. |
| [[Right Grip]] | Use or activate. |
| [[Left Grip]] | Hold a two-handed weapon with both hands. |
| [[Menu]] | Pause. |

If the game says its data is missing, check that the four required REZ archives sit beside `relith-nolf-vr.exe` in the Hub's ReLith folder. Missing `VCRUNTIME140.dll` or `MSVCP140.dll` calls for Microsoft's x64 redistributable. Blank menu text indicates the `cres` resource is absent. If a flat window appears, check the active OpenXR runtime. The publisher's in-game Feedback screen can send a stateful bug report.

## No One Lives Forever VR by GameOrDie007 — option 2

The author's [Game Or Die Installer](https://github.com/GameOrDie007/Game-Or-Die-Installer/releases) also offers a one-click NOLF VR route. This is an external publisher-managed alternative; the Hub's option 2 below remains the path with Hub-owned install and removal records.

[GameOrDie007's releases](https://github.com/GameOrDie007/No-One-Lives-Forever-VR/releases) retain the classic GOTY engine with native stereo, head tracking and motion-controlled aiming through OpenXR. This route requires the Game of the Year edition patched to 1.004, including `NOLFGOTY.REZ`, `nolfu003.rez` and `lithtech.exe`. The Hub currently uses the verified `No-One-Lives-Forever-VR-1.2-PCVR.zip`. The newer 1.3.1 archive changed to a nested publisher Setup layout and cannot be installed by this route yet; the Hub does not label it installed. The Hub extracts the 1.2 package into its own writable folder and runs the publisher's `tools/setup.ps1` against your original game. That script copies your original files into its separate `game` directory, repairs unset retail graphics variables and, if needed, briefly runs that copy of the flat game to build the font cache. It also generates outfit-specific VR glove textures from your original game data when available. Your original installation is not changed. An installed game folder is the Hub's guided path; for the publisher's disc or ISO route, follow the [upstream setup guide](https://github.com/GameOrDie007/No-One-Lives-Forever-VR) first.

Start Virtual Desktop, SteamVR or Meta Quest Link as the active OpenXR runtime, then use Play NOLF VR. The publisher developed on Quest 3 with Virtual Desktop and reports a SteamVR headset run; other controller mappings may need SteamVR bindings. The original game has not been played end to end in VR. The current release adds a visible body, mirrors, full headset-resolution rendering and a steady right-eye desktop view. Options > VR provides recenter, body, left-handed play, snap/smooth turning, gun size, captions and resolution scaling. Lower Resolution % if performance is poor. The package's `Collect report.bat` writes a support ZIP to the Desktop when a publisher problem occurs.

Version 1.2 adds Cate's hands, body holsters, manual reload, physical punches, a wrist display and gesture-operated sunglasses. VR Options > Physical Play enables these together; the button controls remain usable. VR Options > Controls can remap actions separately for Quest Touch and Steam Frame controllers. Head-directed movement and analog walking support treadmill setups, but the publisher has not validated a physical treadmill. Keep `game\custom` free of unsupported HD texture packs; the publisher reports very long loads or closures with an ESRGAN x4 pack.

### GameOrDie007 controls (default Touch layout)

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Right Stick]] | Turn. |
| [[Right Trigger]] | Fire, or throttle a vehicle. |
| [[X]] | Use or activate; get on or off a vehicle. |
| [[Y]] | Reload. |
| [[A]] | Jump; motorcycle wheelie. |
| [[B]] | Duck. |
| [[Left Grip]] | Run; hold near a pistol for a support hand. |
| [[Left Trigger]] | Flashlight; brake a vehicle. |
| [[Right Stick Click]] | Weapon wheel; point and confirm a weapon. |
| [[Left Menu]] | Pause. |
| [[Left Stick Click]] in pause menu | Hide or restore the menu for photo mode. |
| [[Meta]] hold | Recenter. |
| [[Both Grips]] on a vehicle | Steer with hand motions. |

If its publisher setup reports missing GOTY data, check the 1.004 game edition and patch. If `FontData.fnt` cannot be built, launch the original game flat once, close it, then retry the Hub setup; do not mistake a completed file copy for verified headset function. If the game opens without the headset view, start the active OpenXR runtime before Play NOLF VR. The publisher's [README](https://github.com/GameOrDie007/No-One-Lives-Forever-VR) documents the known cutscene and controller limitations.

The detail page's Uninstall guide and Uninstall now controls remove a chosen Hub-owned VR port. The other port, original game, copied original data, saves, settings and changed files remain. If you remove a port's engine files, the Hub stops marking that port VR Ready after a fresh scan.

>>> H.A.R.M. will have a hard time filing this mission report.

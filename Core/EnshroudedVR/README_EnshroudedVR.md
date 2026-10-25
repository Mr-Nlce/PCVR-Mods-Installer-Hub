# Enshrouded VR

## About the Game

Enshrouded is a survival crafting adventure in a world covered by a deadly Shroud. Momotori's VR mod adds stereo OpenXR rendering, room-scale movement, tracked hands, physical melee and bow combat, fishing, and visible full-body movement for other mod users in multiplayer.

## What you need

- The Steam Windows edition of Enshrouded. Launch the unmodded game once, reach its menu, and close it before installing. The publisher package targets one particular `enshrouded.exe` build; when the game updates, use a matching new VR release.
- A headset and controllers with an active OpenXR runtime. SteamVR is the publisher-tested runtime.
- The publisher ZIP from [Enshrouded VR releases](https://github.com/momotori01/ENSHROUDED-VR-MOD/releases). The Hub copies the complete package beside `enshrouded.exe` and saves the installed version. It preserves your personal `EnshroudedVR\EnshroudedVR.ini` on update.

Unsigned VR files may produce antivirus warnings. A missing file can also be caused by a copy, path, or permissions issue; check the installer log and security history before attributing a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]]. If the game's readable graphics settings are missing, Setup guides you through its one-time flat start: press [[Enter]] to start through Steam, reach the main menu on your monitor, then exit normally. If VR files are already installed, choose **Desktop** (older versions: **Normal**) in the publisher settings first. Setup checks for the settings file again before copying VR files.
2. The publisher ZIP has VR **off** by default. In `Enshrouded VR setting.exe`, choose **motion VR** (older versions: **VR**) for motion controllers. **controller VR FPS / TPS** are headset modes played with an Xbox controller. Keep **Frame mode: Both eyes every frame**; AFW is a publisher test mode. Close the settings program; Setup verifies that VR is enabled.
3. **Use [[Start in VR]] in the Hub.** This opens the publisher settings/updater. Check for updates, keep your desired VR mode selected, then **close the settings window**. The Hub checks the saved mode and starts the game through Steam. Connect your headset and SteamVR first. The menu appears on a screen in the headset; after joining a world, stereo VR begins.

Alternatively, launch the game from Steam after selecting your VR mode. The publisher settings program does not have its own game-start button. Its **Update now** updates the mod; closing it through the Hub's Start in VR flow proceeds to the Steam launch. A missing or disabled VR setup produces a visible explanation instead of silently starting flat.

**First start and shader compilation:** the first normal start compiled shaders for about **30-40 seconds** in testing. Let it finish, reach the main menu and exit normally; slower systems may take longer. During a VR start, a flat panel appears first, followed by **VR is loading** after roughly **10 seconds** in testing, then full VR. These timings are observations, not fixed timeouts.

The settings/update window opens on every Hub **Start in VR** so you can check updates before Steam starts the game. A direct launch from the Steam library bypasses that Hub step; open `Enshrouded VR setting.exe` from the game folder periodically if you use Steam directly. The Hub reads the publisher's installed `EnshroudedVR\version.txt` when scanning, including updates installed through that window.

**Launcher-update:** with the game closed, choose **Update now** in the publisher settings. This downloads and installs the newest VR mod while keeping your settings. The Hub's [[Update]] / [[Reinstall]] route also downloads the current GitHub package and checks its required game build. Both update methods are supported; a game build and VR mod that do not match cannot be made compatible by updating only one of them.

The publisher's `Enshrouded VR setting.exe` is in the game folder, next to `enshrouded.exe`. Use it to change the play mode, picture size, sharpening, or the publisher's own updater and diagnostics. DLSS/FSR 3 quality is set in the game's graphics options. If the game build no longer matches the mod, the publisher disables its hooks and starts the flat game. Update the mod for the new build.

## Controls

| Button | Action |
| --- | --- |
| [[Right Trigger]] | Click headset menus; draw and release the bow; cast or reel while fishing. |
| [[Left Stick Click]] | Open the VR start menu when the left controller is beside your head. |
| [[Left Grip]] | Guard or hold a two-handed weapon; grab the shield or bow at a body holster. |
| [[Right Grip]] | Draw a weapon from the right shoulder holster. |
| [[Right B]] | Hold to open quick slots; point and release to select. |
| [[A]] / [[X]] | Confirm a menu selection. |
| [[B]] / [[Y]] | Go back in menus. |

Swing the weapon for melee attacks. The game's own VR settings provide additional comfort and control options. The publisher documents fishing, parries, bows and throws in its [full guide](https://github.com/momotori01/ENSHROUDED-VR-MOD).

### Controller VR modes

Use the game's normal Xbox-controller bindings in controller VR. In the VR start menu:

| Button | Action |
| --- | --- |
| [[RT]] | Switch between FPS and TPS view. |
| [[D-pad Left]] / [[D-pad Right]] | Adjust the view tilt. |
| [[LT]] | Recenter the view, including its tilt. |
| [[Right Stick Click]] | Toggle pitch lock. |
| [[Left Stick Click]] | Start a VR bug report. |

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [Enshrouded VR discussion](https://discord.com/channels/747967102895390741/1561474522593370142)

## Links

- [Publisher project and detailed guide](https://github.com/momotori01/ENSHROUDED-VR-MOD)
- [VR gameplay](https://www.youtube.com/watch?v=my_yKx7H3IU)

>>> The Shroud is easier to face when both hands are yours.

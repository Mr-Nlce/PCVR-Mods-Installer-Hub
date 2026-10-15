# X4: Foundations VR

## About the Game

X4: Foundations is a space simulation about flying, trading, building stations and commanding fleets. [X4 VR by ToffelsKater](https://github.com/ToffelsKater/X4_VR) adds native stereo and six-degree-of-freedom head tracking to the Steam game. It uses normal X4 keyboard, mouse or gamepad controls; this mod does not add tracked hand controls.

## What works and what you need

The publisher supports Windows 10/11 with Steam X4 9.00 or 8.00. The default runtime is SteamVR/OpenVR; native OpenXR is experimental. The cockpit and walking view are stereo with head tracking. The main menu, full-screen maps, inventory, trading and cutscenes appear on a virtual screen. A launcher manages VR profiles, checks X4 settings, shows headset frame rate and can create a HUD distance extension from your own game files.

The author tested on X4 9.00, Windows 11, Varjo Aero, RTX 3090 and SteamVR. Other headsets and GPUs have less direct evidence. Quest players report success with Virtual Desktop; the publisher reports right-eye jitter through Steam Link. X4 VR is demanding, so the Hub rates it HIGH provisionally.

## Install, update and start

Install your own [Steam copy of X4](https://store.steampowered.com/app/392160/X4_Foundations/) first. The Hub downloads the newest matching Windows `X4_VR-<version>.zip` from [GitHub releases](https://github.com/ToffelsKater/X4_VR/releases), verifies the needed files, and installs its `X4_VR` folder beside `X4.exe`. Re-run Install / Update for a newer release. Existing profiles and user settings are preserved. This is a prebuilt release: Visual Studio and source-build scripts are not needed.

Start headset software, Steam and SteamVR before using Start in VR. The Hub opens `X4VRLauncher.exe`; in its Status box confirm that SteamVR, the head-tracking DLL path and build say ok. Then press Play X4 in VR. A normal Steam library launch runs flat. Do not run the launcher as administrator: the publisher says Windows then drops its VR Vulkan layer and X4 runs flat. On first launcher start, the publisher may set the per-user FreeTrack path; an existing opentrack or TrackIR path is left alone until you choose the launcher's Fix head-tracking path action. If Windows warns about the unsigned launcher, inspect the publisher source and the file before choosing whether to run it.

In X4, set Options > Controls > Head Tracking Support > OpenTrack Support to On, and both FreeTrack head rotation and position factors to 100%. For best image clarity, use fullscreen and a higher render resolution such as NVIDIA DSR 4.00x at 1080p or 2.25x at 1440p, if your GPU can sustain it. Set FOV to 120°, disable Temporal AA, FSR and frame generation, and keep VSync and frame-rate limits off. The launcher can check/fix most graphics settings after backing up `config.xml`, but set the head-tracking factors in game.

## Controls

These are the two VR-specific keys documented by the publisher. X4's ordinary flight, movement and menu controls remain in the game settings.

| Button | Action |
|---|---|
| [[Ctrl]] + [[F12]] | Recenter the view and virtual screen after looking straight ahead |
| [[Ctrl]] + [[F11]] | Switch between stereo and the flat virtual screen |

Use the mod's recenter shortcut instead of X4's own Reset Head Tracking action, which can break calibration. After resetting the seated position in SteamVR, press [[Ctrl]] + [[F12]] again.

## Runtime, performance and limitations

The launcher offers OpenVR (SteamVR) as the default and OpenXR as an experimental alternative. A native OpenXR runtime can skip SteamVR; SteamVR overlays then are unavailable. If the OpenXR picture misbehaves, switch back to OpenVR. Keep X4 focused on the desktop, since background throttling can cause stutter.

The normal stereo mode alternates eyes: at a 90 Hz headset each eye receives 45 rendered frames, with reprojection smoothing head rotation. Fast nearby head movement can show judder. Experimental Pair 90 Hz requires roughly 180 game frames per second and can flash dark frames if that target is missed. The cockpit HUD can be moved farther away with the launcher's HUD distance factor (1–6); small interaction popups may remain close. A narrow black band can appear at the bottom on wide-FOV headsets. For an unsupported camera or difficult menu, use [[Ctrl]] + [[F11]] temporarily.

If performance is poor, lower DSR resolution or X4 graphics settings first. The publisher also suggests a larger NVIDIA shader cache, a high-performance power plan, lower mouse polling rate and avoiding overlay hooks such as RTSS, Overwolf or OBS game capture. X4 8.00/9.00 are supported; other builds may lose some walking, leaning or smooth-eye behavior when code signatures differ.

## Troubleshooting and support

- No head tracking or no picture: confirm OpenTrack Support, start via the launcher, check its DLL-path status and use Fix head-tracking path if needed. The log should contain `X4VR freetrack: first headset pose delivered`.
- A flat screen with black space above and below during a tutorial: while flying or walking, press [[Ctrl]] + [[F11]] once to test whether the mod switches to stereo, then [[Ctrl]] + [[F12]] to recenter. Fullscreen menus and cutscenes intentionally use a virtual screen. If walking stays flat, use the launcher's Report a bug and check `debug-events.log` for `signature mismatch`; a newer X4 build may need a mod update. Another head tracker such as TrackIR, Tobii or vorpX's TrackIR emulation can also interfere with the theater switch. The Hub selects the latest compatible publisher ZIP, currently v0.5.2; check the launcher status and its report rather than assuming the updated mod fixed every headset case. A small black band only at the bottom on wide-FOV headsets is a separate documented limitation.
- Rotation or position factor options are missing after enabling OpenTrack Support: confirm the launcher's head-tracking DLL status, close and restart X4 through Play X4 in VR, and check the exact X4 version. The factors must be set in X4's Controls menu, not in the launcher's graphics-settings fix. If they remain absent, include a screenshot of that menu and the publisher report when asking for support; their absence alone does not identify the cause.
- SteamVR grey room: SteamVR must run first; the log should show `X4VR presenter: first stereo pair submitted`.
- Blurry picture: check fullscreen and your DSR resolution. Quest right-eye jitter over Steam Link is a known publisher limitation; use Virtual Desktop.
- Walking only on the virtual screen: inspect `debug-events.log` inside the `X4_VR\reports\captures\debug-` report folders for `signature mismatch`. That indicates an unsupported X4 build.
- The publisher's Report a bug action packages settings, logs, crash data and a system summary. Review it for personal paths before sharing on [GitHub](https://github.com/ToffelsKater/X4_VR/issues) or the [X4 VR Discord](https://discord.gg/yDmj5bnG7n).

Uninstall now removes unchanged Hub-owned VR files, restores backed-up file collisions, and cleans the FreeTrack value only when it still points at this mod. X4, saves, unrelated extensions and changed user files stay in place. You can set OpenTrack Support back to Off in X4 afterward.

>>> Profitssss are better when you can see the whole sector.

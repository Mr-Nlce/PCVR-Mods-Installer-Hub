# Forsaken VR

## About the Game

Forsaken is a fast six degrees of freedom shooter set in tunnels, arenas and hazardous industrial spaces. GameOrDie007's open source VR port runs natively through OpenXR with stereo rendering, head tracking and motion controls. This Hub entry is for PCVR; the publisher also offers separate Quest and Steam Frame packages.

## What you need

You do **not** need to buy Forsaken Remastered or provide the original 1998 disc. Publisher Setup downloads the free ForsakenX game data (about 130 MB) and installs a separate VR game. If Forsaken Remastered is installed, Setup places VR in its `VR` subfolder and can copy its soundtrack and intro. Without the Remaster, it uses `Documents\Forsaken VR`, or `Games\Forsaken VR` under your user folder when Documents is managed by OneDrive. The Remaster game itself is not patched.

The PCVR release needs Windows and a working OpenXR headset runtime. The publisher tested a Quest 3 through Virtual Desktop/VDXR and a Steam Frame through SteamVR. Other headsets and runtimes require user testing. The publisher's EXE is unsigned and may trigger a Windows or antivirus prompt; a missing file alone does not establish that antivirus removed it.

## Install and start

1. Choose [[Get Installer]] in the Hub. The installer checks the [official PCVR releases](https://github.com/GameOrDie007/Forsaken-VR/releases), uses the current PCVR ZIP and then runs the publisher's Setup with visible progress. It downloads ForsakenX data if needed. Steam and GOG Remastered locations are checked by publisher Setup; no purchased game is required.
2. Let Setup finish. The Hub confirms the VR executable, OpenXR loader, downloaded level data, launcher and recorded version before marking this entry installed. It also sets the **Forsaken VR** desktop shortcut to the installed `game\projectx.exe` with VR arguments and the Forsaken icon, including the default `Documents\Forsaken VR` location.
3. Connect your headset and select a working OpenXR runtime. Choose [[Start in VR]] in the Hub. It launches the separate Forsaken VR runtime with the publisher's VR arguments. The Remaster executable and the flat launcher are never the Hub VR target.

The publisher Setup can be run again to update or repair. It keeps your pilot, saved games, settings and downloaded data. The Hub checks the installed version against the release it actually selected. The current publisher release is v1.1; v1.0 is older.

## Controls

Quest 3 Touch defaults are shown below. Changeable face buttons and stick clicks are in VR Options > Controls. The Steam Frame has its own map in the publisher's [full control guide](https://github.com/GameOrDie007/Forsaken-VR#controls).

| Button | Action |
|---|---|
| [[Left Stick]] | Thrust and strafe. |
| [[Right Stick]] | Yaw and pitch. |
| [[Left Stick Click]] | Next primary weapon. |
| [[Right Stick Click]] | Cycle cockpit, near and far views. |
| [[Right Trigger]] | Fire primary weapon. |
| [[Left Trigger]] | Fire secondary weapon. |
| [[Right Grip]] | Rise without tilting. |
| [[Left Grip]] | Sink without tilting. |
| [[X]] / [[Y]] | Roll left / right. |
| [[A]] | Nitro. |
| [[B]] | Drop a mine. |
| [[Menu]] | Pause; hold to recenter. |
| [[Both Grips]] | Recenter. |

In menus, either stick moves, [[A]] confirms and [[B]] goes back. You can also hold a controller's [[Grip]], point at a row and use its [[Trigger]] to choose it. A gamepad and keyboard/mouse can also be used; bindings are available in the game's F1 menu.

## Comfort and troubleshooting

The in-game pause menu has VR Options for HUD position, view distance, handedness, controls and the menu screen. If text is too small, increase Text Scale or VR panel width. For streamed headsets, check the wireless link if the image judders; network stutter can look like GPU slowdown. SteamVR can take precedence for a launch while it is running. If a download or setup step fails, use the Hub recovery screen to retry or supply the official PCVR ZIP; read the publisher log before assuming antivirus is responsible.

[[Uninstall now]] removes unchanged files recorded as Hub-owned and the matching Hub-configured desktop shortcut. It retains downloaded game data, saves, settings, changed files and Forsaken Remastered. If a required VR runtime file was changed after installation, the Hub leaves it and keeps its state for review.

## Links

- [Publisher project and documentation](https://github.com/GameOrDie007/Forsaken-VR)
- [PCVR releases](https://github.com/GameOrDie007/Forsaken-VR/releases)
- [VR gameplay](https://youtu.be/jCjcgGU_3lw?t=250)

The tunnels are open. Keep your thrusters ready.

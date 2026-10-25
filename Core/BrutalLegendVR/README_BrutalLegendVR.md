# Brutal Legend VR

## About the Game

Brutal Legend is an action adventure with music, driving and stage battles. Nikami's experimental OpenXR preview adds a first-person stereo view, tracked hands, physical axe and guitar actions, and VR menus. The publisher still lists complete campaign and physical headset acceptance as unfinished, so this entry is marked WIP.

## What you need

- The **Steam PC version** of Brutal Legend. The publisher verifies the exact `BrutalLegend.exe` build before touching game files. GOG, itch, Humble and retail editions are not confirmed by this VR preview.
- A connected PC VR headset and an active OpenXR runtime. The current documented controller profile is Quest Link or Air Link with Touch controllers.
- Start the original desktop game once, then close it before installing VR.

The Hub downloads the complete portable package from the publisher's releases. The publisher VR files are installed in `%LOCALAPPDATA%\PCVR Mods Installer Hub\BrutalLegendVR`, outside your Steam game folder. Its VR starter is `Play VR.cmd` there. The detail page links to both after checking the installed files, even if the game scan misses them. If the base game is missing from the scan, use **Locate Game** for the Steam game folder; do not select the separate VR folder there. In Setup select your Steam `BrutalLegend.exe` and choose **Prepare / repair game**. This mandatory step imports your own game model and textures locally; without it, VR cannot start. The Hub checks those prepared assets before reporting completion. The publisher's **Play VR** launcher deploys the game hook when you start VR; it backs up any existing game DLL at that point.

## Install and start

1. Choose [[Install]] on this tile. Read each step and press Enter before the download, runtime installation and publisher Setup. Complete **Prepare / repair game** in the opened publisher window.
2. Connect the headset and select an OpenXR runtime. The publisher's VR settings let you choose the runtime, render resolution, frame limit and guitar position.
3. Choose [[Start in VR]] in the Hub. This calls the package's **Play VR** launcher, which starts its OpenXR host and then the Steam game. The original game EXE on its own is a flat launch.

The installer also creates a **Brutal Legend VR** desktop shortcut to that exact `Play VR.cmd` starter. Use it as an alternative to the Hub's **Start in VR** button. A normal Steam launch starts the flat game. Runtime settings and controls remain separate from the game files.

## Controls

These are the publisher's default Touch bindings. The included controls editor can remap native game actions and VR controls.

| Button | Action |
|---|---|
| [[Left Stick]] | Walk or drive. |
| [[Right Stick]] | Snap turn or navigate vertical options. |
| [[A]] | Accept or interact. |
| [[B]] | Back, evade or block. |
| [[X]] / [[Y]] | Equip or stow axe or guitar on release. |
| [[Right Trigger]] | Use the selected weapon; physical axe swings and guitar strokes also work. |
| [[Left Grip]] | Hold and slide the guitar neck; hold more firmly to reposition it. |
| [[Left Trigger]] | Curl the index finger while holding the guitar neck; target in combat. |
| [[Left Grip]] + [[Right Grip]] | Earthshaker; release before repeating. |
| [[Right Stick Click]] | Open solo selection. |
| [[Right Grip]] | Steer while driving. |
| [[Left Menu]] | Pause. |
| [[Left Menu]] + [[Right Stick Click]] | Recenter. |

## Troubleshooting

If VR does not open, use the package's **Check installation** and read `tools\blvr_xr_host.log` in its runtime folder and `blvr.log` beside the game. A missing file alone does not prove antivirus quarantine; check the installer log and protection history before changing security settings.

One tester saw a Windows error on the first VR launch and a successful second launch. If this occurs, close the error and try **Start in VR** once more. If the error repeats, use **Check installation** and the logs above; the first error alone does not establish its cause.

## Links

- [Publisher project and releases](https://github.com/nikamigaming-create/BrutalLegendVR/releases)

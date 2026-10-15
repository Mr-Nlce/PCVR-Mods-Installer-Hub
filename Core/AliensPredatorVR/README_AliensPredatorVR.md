# Aliens versus Predator VR

## About the Game

Aliens versus Predator lets you play as a Marine, Alien or Predator. Each
campaign gives the same locations a different pace and set of tools: armed
survival, wall-crawling pursuit or a hunter's cloak and vision modes. This
community port adds tracked PCVR play and also supports LAN multiplayer with
other supported builds.

## Requirements and installation

Bassquake's 1.2 Windows x64 PCVR build requires a licensed copy of
Aliens versus Predator Gold Edition or the matching Gold game data from
[Steam](https://store.steampowered.com/app/3730/) or
[GOG](https://www.gog.com/en/game/aliens_versus_predator_classic_2000).
The publisher's ZIP contains no game assets. Keep the game's executable
(`AvP.exe` for retail or `AvP_Classic.exe` for Steam/GOG), plus `AvP_Rifs`,
`fastfile`, `FMVs`, and `language.txt` in the game folder.
The ordinary edition's `language.txt` can crash this port; the installer can
check that the file exists but cannot establish which edition it came from.
Do not use a ROM, game data or language file from an unowned copy.

The Hub downloads only `avpvr-<version>-windows-x64-vr.zip` from the
[publisher release page](https://github.com/Bassquake/Aliens-Versus-Predator-VR/releases).
It adds `avpvr_x64.exe`, the OpenXR loader, SDL, OpenAL and all required
FFmpeg DLLs beside the licensed game data. It backs up same-name files before
replacing them. Saves, profiles, configuration, music and unrelated files
remain untouched. The separate Android, Linux, flat and artwork downloads
are not substituted for the Windows PCVR build.

Version 1.2 fixes joystick deadzone behavior and separates X and Y deadzone settings. Its preliminary RTX Remix work targets a flat x86 build; the Hub continues to select the Windows x64 VR asset.

## Starting VR

Start SteamVR and connect the headset, then use Start in VR in the Hub.
The publisher also documents adding `avpvr_x64.exe` to Steam as a non-Steam
game and enabling Include in VR Library in its shortcut properties.
Steam Link is the publisher's demonstrated PCVR route; Virtual Desktop has
not been tested by the publisher. A real headset run is still needed to
confirm your particular game-data copy and controller mapping.

The publisher says LAN multiplayer can mix PCVR and Quest players. Optional
CD music can be added as `cd_tracks/track01.ogg`, `track02.ogg`, and so on.
Steam and GOG copies may not include the extracted soundtrack. Music is
optional and the Hub does not download it.

## Controls

The publisher's VR control image and v1.1 release notes document these default
mappings. Game controls can be remapped per character under Controls. Reset old
custom bindings to defaults after updating to receive new v1.1 actions, then
reapply your changes. On SteamVR, hold the
taunt/menu button for 0.5 seconds for the mission log or one second for pause.

| Button | Action |
|---|---|
| [[Left Stick]] up/down | Move forward/backward; menu up/down |
| [[Left Stick]] left/right | Strafe |
| [[Left Stick Click]] | Crouch |
| [[Right Stick]] left/right | Snap or smooth turn |
| [[Right Stick]] up/down | Next or previous weapon |
| [[Right Stick Click]] | Marine flare or Predator cloak |
| [[Right Menu Button]] hold | Recenter view |
| [[Y]] | Alien navigate/hunt, Marine image intensifier or Predator vision mode |
| [[Y]] hold | Predator zoom |
| [[X]] | Taunt; hold for mission log or pause in SteamVR |
| [[Left Trigger]] | Marine left pistol |
| [[Left Grip]] | Marine jetpack or Predator grappling hook |
| [[Right Trigger]] | Primary fire |
| [[Right Grip]] | Secondary fire |
| [[B]] | Back in menus; jump in game; hold for Predator disc recall |
| [[A]] | Select in menus; operate switches in game; hold for manual reload |

Manual Reload is an optional in-game control setting. In v1.1, hold [[A]] for
manual reload. Two-handed weapons use [[Left Grip]] near the other controller,
or the opposing grip if Left-Handed Mode is active. The close-controller
requirement can be changed under General VR Configuration. Jetpack missions
do not support two-handed weapons. Predator Wristblades and Alien claws support
physical attacks. The Alien can wall-walk: approach a
wall and press the publisher's [[B]] action. Wall walking and aggressive
turning can be uncomfortable; Controls > General VR Configuration offers
vignette and world-scale settings. Left-Handed Mode is under Controls > General
VR Configuration. The 1.0 default world scale was 1.30.

Version 1.1 also fixes the Alien's post-head-eat zoom, jetpack movement and
ceiling clipping, and Predator arm jitter. It adds stick deadzones and an
option to enlarge mission text. Reset custom bindings to defaults once after
updating, then remap as desired.

## Display and troubleshooting

The game offers crosshair, frame-rate counter, MSAA, texture filtering and
refresh-rate settings under Audio/Video Options. Marine left-arm display,
world scale and wall-walk vignette are under General VR Configuration.
The publisher notes that some HD Redux objects have missing shapes.

If the game closes at startup, check the Gold Edition `language.txt` first,
then confirm that `AvP_Rifs` and `fastfile` contain your licensed game files.
If setup says a required native file is missing, use its Recovery screen to
inspect the log and retry; absence alone does not prove antivirus quarantine.
The detail page's Uninstall now removes unchanged Hub-owned VR files and
restores previous same-name files. Its Uninstall guide explains that
action. Your licensed data, saves, profiles, music and changed files stay.

Publisher instructions: https://github.com/Bassquake/Aliens-Versus-Predator-VR

>>> In space, no one can hear your motion sickness. Watch those walls.

# Final Fantasy VII Remake Intergrade VR

## About the Game
Join Cloud, Tifa, Aerith and Barret in a vast reimagining of Midgar, combining exploration and real-time action with tactical battles against Shinra.

## Requirements
Windows 10/11, a PC headset and an active OpenXR runtime. The mod knows game file version 1.0.0.7. Steam is tested by the publisher; Epic and Xbox are experimental. Xbox installations must enable advanced management features so the game folder can be written. Another EXE build can start without VR.

The mod uses the game's normal gamepad or keyboard/mouse controls, not tracked motion controls. NVIDIA GPUs can use foveated rendering. Experimental DLSS additionally requires an NVIDIA RTX GPU and NVIDIA's nvngx_dlss.dll.

## Install and start
1. Choose Install, then the standard launcher (recommended) or experimental DLSS launcher. The Hub downloads the matching publisher package; it does not mix launcher and drop-in archives.
2. Connect your headset and start its PC runtime. Use Start in VR in the Hub. Alternative: Final Fantasy VII Remake VR desktop shortcut.
3. Leave the publisher launcher's window open while you play. It temporarily installs VR, sets ReShade/Luma aside, starts the selected game with -d3d11, waits for exit and restores your normal files.

The launcher's normal 90-second wait between sessions avoids a known severe slowdown. Its window also waits if another session is still closing. Do not bypass that wait or force-close its cleanup window.

Flat / VR chooses the next session. Flat mode restores an unfinished publisher session first, then starts the same game through its own store. Steam's Launch Options do not apply to the publisher's direct VR launch.

## Controls
| Button | Action |
|---|---|
| [[Home]] / [[Left Stick Click]] + [[Right Stick Click]] | Toggle first/third person |
| [[End]] | Recenter the view |
| [[Insert]] | Toggle stereoscopic rendering |
| [[Delete]] / [[View]] + [[Y]] | Open the VR settings panel |
| [[Touchpad Click]] + [[Triangle]] | PlayStation alternative for settings; Steam Input is recommended |
| [[X]] | Save settings from the settings panel |

The mod normally uses first person during exploration and third person in combat. Changes in the VR settings panel apply immediately; closing the panel asks whether to save them. Your normal game controls remain available.

## Help
Interrupted session: open restore.cmd in the VR files folder, or start the next VR session and let the publisher restore first. Do not delete ff7vr.session.json or the launcher's backups manually.

The game is flat: check its EXE version and the active OpenXR runtime. Epic/Xbox builds may not match the known Steam build. collect-diagnostics.cmd creates a diagnostic ZIP for the modder. Pre-rendered movies can still slow down, and some newer rendering fixes have not been headset-confirmed by the publisher.

## Technical details
The durable VR folder is %LOCALAPPDATA%\PCVR Mods Installer Hub\FF7VR. Start-FF7VR.ps1 calls the publisher ff7vr-launcher.ps1 with the located game folder and its recorded store. start-vr.cmd is the publisher's direct alternative; restore.cmd repairs an interrupted session. ff7vr.ini, VERSION.txt and logs are stored in that VR folder.

During play the publisher temporarily copies xinput1_3.dll and ff7vr.ini beside ff7remake_.exe in End\Binaries\Win64 (or WinGDK), records ff7vr.session.json there and restores your earlier files afterwards. Do not use the absence of those temporary DLLs after exit as evidence that the persistent mod is uninstalled.

There are four publisher ZIPs: standard launcher, DLSS launcher, standard drop-in and DLSS drop-in. The Hub uses the launcher packages. The optional NVIDIA DLSS runtime comes from NVIDIA's official SDK and its licence applies; a pre-existing DLL is retained.

## Links
[Mod source and installation instructions](https://github.com/Gilleece/ff7-remake-vr)
[Detailed publisher guide](https://github.com/Gilleece/ff7-remake-vr/blob/main/docs/guide.md)
[Publisher releases](https://github.com/Gilleece/ff7-remake-vr/releases)
[NVIDIA DLSS SDK](https://github.com/NVIDIA/DLSS)
[VR gameplay](https://youtu.be/mDX-gDUx6Co?t=95)

>>> This train has no brakes. Barret checked.

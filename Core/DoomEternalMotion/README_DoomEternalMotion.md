# DOOM Eternal VR - Motion

## About the Game

DOOM Eternal is a fast first-person shooter built around movement, weapon switching and aggressive combat. This Hub entry offers two independent motion-control mods for the licensed PC game. The existing Luke Ross gamepad entry remains a separate choice in the Library.

## Mod 1: KHARVOX: ARGENT by CactusVRStudios

ARGENT adds stereoscopic OpenXR rendering, roomscale, independently tracked hands, physical melee and two-handed weapon support. Its complete launcher package stays in a writable folder outside the retail game. The Hub installs and updates only this slot when you choose ARGENT; Play ARGENT opens `ArgentLauncher.exe` directly. In the launcher, select the retail `DOOMEternalx64vk.exe`, choose your options and press PLAY. Keep the game window focused for controller input.

Run the retail game once, reach its main menu and sign into Bethesda before the first VR run. Close the game and both VR launchers before installation or update. Steam and Microsoft Store builds are documented; the publisher launcher checks compatibility. The v1.01a release repairs a ladder progression trigger in DOOM Hunter Base and adds optional hand smoothing.

### ARGENT controls (default right-handed layout)

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Left Stick Click]] tap | Mission information. |
| [[Left Stick Click]] hold | Dossier. |
| [[Y]] | Switch weapon mod. |
| [[X]] | Flame Belch. |
| [[Left Trigger]] | Equipment launcher or grenade. |
| [[Left Grip]] near weapon | Two-hand weapon support when Virtual Gunstock is enabled. |
| [[Left Grip]] away from weapon | Switch equipment. |
| [[Left Menu]] | Pause menu. On Index, click the touchpad. |
| [[Right Stick]] left/right | Turn. |
| [[Right Stick]] up | Crucible. |
| [[Right Stick]] down, hold | Open weapon wheel; choose with [[Left Stick]] and release to confirm. |
| [[Right Stick Click]] | Use, melee or Glory Kill. |
| [[B]] | Jump. |
| [[A]] | Dash. |
| [[Right Trigger]] | Fire. |
| [[Right Grip]] in front | Weapon mod or secondary fire. |
| [[Right Grip]] behind shoulder | Reach back, then press grip for the chainsaw. |

In the launcher, Movement offers snap or smooth turning and head-directed or off-hand-directed locomotion. Left Handed Mode can swap buttons only or buttons and sticks. Physical punches require a valid target and the configured speed threshold. The launcher also offers 3D cinematics, a spectator mirror, bHaptics and experimental PSVR2 adaptive triggers. Those accessories are optional.

ARGENT has been tested by its author with VDXR, SteamVR OpenXR and Meta OpenXR. The author recommends VDXR or Meta OpenXR for Quest and SteamVR for Index, and reports problems with Quest through SteamVR. AMD rendering and water effects have known issues. At 100% render scale, FSR is inactive. For lower render scales use FSR or in-game DLSS, not both; stereo DLSS remains experimental. On the SteamVR path, set render resolution in SteamVR because the launcher does not apply its FSR reduction there. If debugging, enable Extended Logging before PLAY and disable it again afterwards. [ARGENT release and publisher instructions](https://github.com/CactusVRStudios/KHARVOX-ARGENT/releases).

## Mod 2: EternalVR by ArcadaLabs-Jason - option 2

EternalVR is a separate OpenXR alpha with stereoscopic rendering, head tracking, motion aiming and a virtual menu panel. Its launcher and Vulkan layer live together outside the retail game; it does not modify DOOM Eternal's files. Choose EternalVR in the Hub installer to install this slot, then Play EternalVR to open `EternalVR.Launcher.exe`. The two mod folders can coexist. The selected Hub Play button chooses the launcher; installation does not switch mods.

If the Luke Ross R.E.A.L. interface appears during an EternalVR session, check
the retail game folder for an active older R.E.A.L. installation such as
`RealRepo\RealVR64.dll`. EternalVR does not depend on Luke Ross. Disable the
older game-folder injection through its existing control before retrying
EternalVR; keep its files and settings until ownership is clear.

The current alpha supports Steam build 25216728 / Rev 3.2 and Microsoft Store or Game Pass 1.0.56.0 according to the publisher. Its launcher refuses an unsupported game build or a mismatched launcher/layer pair. Steam must already be running and signed in for its Steam route. First launch the retail game through Steam or Xbox, reach its main menu, quit and then check the VR launcher. Connect a headset and start its active OpenXR runtime before Launch VR. The launcher uses .NET Framework 4.8; its tested publisher hardware is NVIDIA RTX and Quest 3 with VDXR. Other GPUs, headsets and runtimes may work but are not verified by the author. The mod is for the campaign; entering multiplayer turns VR off for that session.

### EternalVR controls (default Touch layout)

| Button | Action |
|---|---|
| [[Right Trigger]] | Fire. |
| [[Right Grip]] | Weapon mod. |
| [[Right Stick]] left/right | Smooth turn. |
| [[Right Stick]] up | Chainsaw. |
| [[Right Stick]] down, tap | Quick switch to the last weapon. |
| [[Right Stick]] down, hold | Weapon wheel; roll the stick toward a weapon and release. |
| [[Right Stick Click]] | Melee, Glory Kill, Blood Punch or use. |
| [[A]] | Jump. |
| [[B]] | Dash; hold during skippable cutscenes to skip. |
| [[Left Stick]] | Move where your head faces. |
| [[Left Trigger]] | Equipment launcher. |
| [[Left Grip]] | Flame Belch. |
| [[Left Stick Click]] | Crucible. |
| [[X]] tap / hold | Switch equipment / open Dossier. |
| [[Y]] tap / hold | Switch weapon mod / mission information. |
| [[Left Menu]] | Pause. Under SteamVR with Touch controllers, hold [[Y]] instead. |
| [[Both Stick Clicks]] hold 2 seconds | Recenter direction and height. |
| [[Right Hand]] pointing at a menu + [[Right Trigger]] | Point and click on the floating menu. |
| [[B]] or [[Y]] in a menu | Back. |

The launcher has a controls editor, left-hand choices, snap turning, comfort vignette, seated/standing and eye-height settings. Optional hand gestures can throw grenades, swing the Crucible or jump; the publisher says these gestures were not yet tested in a headset. Gamepads remain usable beside the motion controllers. Controller layouts other than Touch have mappings but were not yet tested by the author; see the package's `docs/CONTROLS.md` for their exact differences.

The reviewed **v0.1.62** alpha improves weapon-specific hand placement and stereo glass rendering. Its launcher and OpenXR layer share one build and reject mixed versions. If GitHub cannot be checked, setup offers the official release page and a versioned ZIP from Downloads for confirmation; no old Current fallback is silently installed.

EternalVR keeps profiles, controls, logs and game-settings backups in `%LOCALAPPDATA%\EternalVR`. Let its launcher finish restoring game settings when a session ends before starting the other mod or uninstalling. Its own self-updater may replace launcher files; the Hub reads the publisher `BUILD-INFO.txt` for the actual installed version rather than treating an older Hub stamp as authoritative. The earlier **v0.1.50** alpha removes the invisible square that hid nearby HUD elements, makes stuck startup steps visible in the launcher and stops changing screen shake in the normal flat game. Its v0.1.38 alpha added experimental Parallel Eye Rendering for the Steam version. It remains off in the normal launcher; close that launcher and open `Launch-Parallel-Eye-Test.cmd` in the EternalVR folder to expose the switch. It can use more video memory and show one-eye reflection defects. The new thumb-rest weapon direction follows the game's wheel; remove any custom `weapon_directions` line added for v0.1.37 before using the new defaults. The launcher no longer recommends TAA over DLSS; choose the clearer option for your headset. An unsupported retail update, missing OpenXR runtime, Steam sign-in failure, incompatible overlays, incomplete layer or unrun flat game will be reported by its launcher. Use Export report for problems; read `docs/TROUBLESHOOTING.md` and `docs/KNOWN-ISSUES.md` in the publisher package. On AMD GPUs, the author documents a possible eye-resolution limit and a virtual-display workaround. Lower launcher Resolution first for video-memory errors or poor frame rate. [EternalVR release and publisher instructions](https://github.com/ArcadaLabs-Jason/EternalVR/releases).

The Uninstall guide and Uninstall now controls on this page handle removal of a chosen slot. The Hub shows VR Ready only while the licensed game executable and a launcher's required files and version proof are present. The publisher's game-build check and headset result remain separate from that file-level Hub status.

>>> Rip and tear. The chainsaw finally has a reach of its own.

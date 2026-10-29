# The House of the Dead 2 - PC2VR

## PC2VR by fjdiazt
PC2VR is a separate implementation for the original Windows PC game. It adds an in-headset settings menu, per-mode scene checkpoints, stage/scene selection, resolution/MSAA controls, optional cheats and independent two-hand gun controls. There is no independently verified performance comparison with Icedomega13 here.

Choose Install / update VR mods, then PC2VR. The Hub needs your own folder containing Hod2.exe and Config.exe; drag the game EXE into setup or use Locate Game. The Remake and emulated versions are not supported. Only the original EXE revision documented by this publisher is supported; its own launcher checks that game build.

Use the PC2VR Start in VR action in the Hub. Alternative: The House of the Dead 2 VR - PC2VR desktop shortcut. The publisher's vr\start.bat is also available in the original game folder. The PC2VR Flat / VR switch on this page chooses whether that controller starts PC2VR or the original flat game. Close both game and VR viewer before switching.

The complete PC2VR runtime stays in the original game's vr subfolder. The Hub start controller is vr\Start-PC2VR.ps1. It calls vr\HOTD2VR.exe with --game-exe pointing to this exact original Hod2.exe. It does not launch or change the Icedomega13 VR copy.

## PC2VR controls
| Button | Action |
|---|---|
| [[Either Trigger]] | Fire that hand's gun; confirm a menu selection |
| [[Either Grip]] | Reload that hand's gun |
| [[Either Stick]] | Navigate game menus |
| [[A]] / [[X]] | Start, pause or resume |
| [[B]] / [[Y]] | Skip a scene or go back |
| [[Right Stick Click]] | Recenter |
| [[Left Stick Click]] | Open/close VR Settings |
| [[F8]] | Desktop VR Settings menu |
| [[Arrow Keys]] | Desktop settings navigation |
| [[Enter]] | Desktop settings selection |
| [[Right Ctrl]] | Desktop settings back |

The right controller is Player 1; the left is Player 2. Akimbo joins both by default; turn it off in VR Settings > Controls to join independently. Settings do not pause the game: pause explicitly first. Quit game in VR Settings closes both the game and viewer.

PC2VR checkpoints save the chapter/scene, not a full snapshot of health, inventory or enemies. Keep vr\HOTD2VR.checkpoint.ini and vr\HOTD2VR.original.checkpoint.ini to preserve them. User settings are in vr\HOTD2VR.ini.

## Links
[Publisher source and full instructions](https://github.com/fjdiazt/hotd2-pc2vr)
[Publisher releases](https://github.com/fjdiazt/hotd2-pc2vr/releases)

>>> Suffer like G did. Preferably with both guns loaded.

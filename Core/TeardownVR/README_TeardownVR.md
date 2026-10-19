# Teardown VR

## About the Game

Teardown is a physics sandbox built around breakable voxel environments and creative heists. VR Games For All's mod adds stereoscopic OpenXR rendering, tracked tool aiming, physical interactions, roomscale movement and motion-controller menus. The Hub uses the free public GitHub release.

## What you need

- The **Steam version of Teardown 2.0.1** on Windows 10/11 x64. The publisher has not confirmed other game versions or stores. A later Teardown update can break the mod.
- A working OpenXR runtime and the Microsoft Visual C++ 2015–2022 Redistributable (x64). The publisher tested Quest 3 with Virtual Desktop/VDXR and Meta Quest Link; SteamVR can be selected in the mod settings.
- Performance headroom: the mod renders two game frames per headset frame.

The GitHub release omits two features present only when the publisher builds with game-derived shaders: the stereo particle fix and VR anti-aliasing modes. It uses Teardown's own shaders for those effects. The native `dsound.dll` asset alone is **not** a complete installation: the Lua mod under `mods\teardownvr` is required too. `Teardown-VR.zip` contains the same installer as the separate `Teardown-VR-Installer.exe` asset.

## Install and start

1. Choose [[Install]] in the Hub. It finds the Steam game, downloads the current stable [publisher installer](https://github.com/Pluventi/teardown-vr/releases), runs it for the selected game folder and verifies the DLL plus all three Lua-mod files before recording the installed version. Windows may ask for administrator approval.
2. Connect the headset and select an OpenXR runtime. Choose [[Start in VR]] in the Hub. The Steam copy launches through Steam. On a first installation, the installer also offers **Enter to start Teardown** after showing the steps below.
3. **In the headset**, choose **Play > Mod-Manager**. Scroll down to **Teardown VR** and select it. Click **Deactivated** to switch it to **Activated**. The desktop mirror may not be usable for this step after the VR files are installed. Enable the Lua mod once; later updates normally keep it enabled. Levels then run in immersive VR.

Updates run the matching publisher installer again. The publisher keeps `TeardownVR.ini` settings. If another mod owned `dsound.dll`, the publisher saves it as `dsound.dll.original` and restores it during uninstall. Close Teardown before installation, update or removal.

## Controls

These are the publisher's default right-handed motion controls. Left-handed mode swaps the dominant hand. In-game options can change comfort and turning behavior.

| Button | Action |
|---|---|
| [[Right Trigger]] | Use the held tool; click a pointed-at menu item. |
| [[Right Grip]] | Grab, carry and release an object. |
| [[Left Grip]] | Grab with the physical left hand. |
| [[Right Stick]] left/right | Turn smoothly, or snap-turn if selected. |
| [[Right Stick]] up/down | Change tool; move a held object nearer or farther. |
| [[Right Stick Click]] | Show or hide the VR inventory. Hold for the keys panel. |
| [[Left Stick]] | Move. |
| [[Left Stick Click]] | Hold to recenter; short press repeats the last keys-panel key. |
| [[Left Trigger]] | Crouch while held. |
| [[A]] | Jump. |
| [[B]] | Toggle flashlight; back in menus. |
| [[X]] | Show or hide the 3D level map. |
| [[Y]] | Interact; enter or leave a vehicle. |
| [[Menu]] | Short press pauses; long press opens Teardown VR settings. |
| [[F10]] | Open settings from the keyboard. |
| [[F8]] | Recenter from the keyboard. |

## Removal and troubleshooting

Choose [[Uninstall now]] to run the publisher's matching uninstaller. It removes the VR DLL and Lua files, restores a saved earlier `dsound.dll`, and keeps the base game, saves and `TeardownVR.ini`. A missing file alone does not prove antivirus involvement; check the installer log and Windows protection history before deciding how to recover it. Teardown updates can change the engine hooks and cause missing VR features or a failed start; check `TeardownVR.log` beside the game.

## Links

- [Official source and full guide](https://github.com/Pluventi/teardown-vr)
- [Current public releases](https://github.com/Pluventi/teardown-vr/releases)
- [Flat2VR community thread](https://discord.com/channels/747967102895390741/1560664691594756147)
- [VR gameplay](https://youtu.be/ZMj2zIeCAmw?t=488)

The next wall is merely a suggestion.

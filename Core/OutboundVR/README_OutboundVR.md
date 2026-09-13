# Outbound VR Installer

**OutboundVR** by Destroyjevski converts Outbound to engine-native stereo OpenXR with full 6DOF head tracking. It is played with a gamepad; tracked motion controllers are not implemented.

## What changed in version 2

OutboundVR is now a small standalone `dxgi.dll` beside `Outbound.exe`. It no longer needs BepInEx, Doorstop, a bundled .NET runtime or generated helper files. Startup is therefore close to the flat game's normal startup, including the first launch.

An old 1.x plugin and the new 2.x DLL must not load together. During an update the installer removes only the old `BepInEx\plugins\OutboundVR` plugin location before placing version 2. A shared BepInEx installation and every unrelated mod remain untouched.

Version 2 supports the Steam and Game Pass layouts. The Hub also keeps its existing Epic-folder search as a safe manual fallback, but that store did not receive the same validation in the current mod documentation.

## Requirements

- Outbound for PC
- An XInput gamepad
- A working OpenXR runtime
- **Virtual Desktop with VDXR** is the developed and tested route. Other OpenXR runtimes may work, but have not received comparable testing.

## Installation and launch

The installer opens the Nexus Files page, accepts the downloaded archive, locates the game and copies only the archive's `GameFiles` payload into the folder containing `Outbound.exe`. It verifies `dxgi.dll`, `Outbound_Data\Plugins\x86_64\openxr_loader.dll` and `Outbound_Data\Plugins\x86_64\UnityOpenXR.dll` before claiming success.

Start with **Start in VR** on this game's Hub page or launch it normally through the store. VR is active immediately.

## Controls

- [[R-Stick]] Turn left and right; look vertically with your headset
- [[R3]] Recenter the view and place the HUD in front of you
- [[L3]] + [[R3]] Hide or restore the complete VR HUD and menu panel
- [[D-Pad]] Select keys on the VR keyboard
- [[A]] Enter the selected key
- [[X]] Delete
- [[Y]] Space
- [[Start]] Finish text input

Interactions use head aiming. A small bracket marks the target: cyan means usable and orange means blocked. Menus and the HUD appear on a readable world-space panel, while first-person hands and held tools appear during their original actions.

## Flat play

Close the game, then use the **Flat / VR switch** on this game's Hub detail page. It parks only the mod DLL and keeps the installation ready to restore. Saves are shared because this is still the same game installation.

## Configuration and limitations

Version 2 has no configuration file; the tested values are built in. Motion controllers are unsupported, multiplayer has not been validated, and minor game or streaming hitches can still occur. Hiding the HUD with [[L3]] + [[R3]] hides its complete surface.

## Removing the mod

Use **Uninstall now** beside this guide. It removes the standalone mod and its own documented support files without deleting the game, saves, shared BepInEx installation or unrelated mods. For a temporary flat launch, use the Flat / VR switch instead.

Chart the drift, trust your gut, and roll on into the unknown.

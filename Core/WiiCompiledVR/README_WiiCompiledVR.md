# Mario Kart Wii VR

WiiCompiled OpenXR VR is a locally compiled PC version of Mario Kart Wii, guided by [WheelWizard VR](https://github.com/iChris4/WheelWizard_VR). You must supply your own clean, unmodified PAL `RMCP01` disc image. The Hub does not provide Nintendo ROMs, game files, keys or BIOS data.

## About the Game

Mario Kart Wii combines Grand Prix, Time Trials, multiplayer races, drifting, items and karts or bikes. This PCVR route builds the Base game and the Retro Rewind variant separately from a disc you own. VR racing uses a head tracked cockpit or chase camera; menus and unsupported scenes appear on a virtual screen.

## Requirements and setup

- Windows 10 or 11 x64, approximately 20 GB free while building, an active OpenXR runtime and a connected headset. The publisher lists a GTX 1650, RX 6400 or Arc A310 class GPU and a six thread CPU as its minimum.
- A clean PAL `RMCP01` disc image you dumped yourself. WheelWizard accepts ISO, GCM, GCZ, CISO, WBFS, WIA and RVZ. Other regions and modified images are rejected by the publisher.
- Select [[Install]] to download and open the official WheelWizard VR executable. In WheelWizard, select the disc in Settings, then go to Settings > Other > WiiCompiled (beta) and enable Enable WiiCompiled OpenXR VR (beta). On Home, select Install and wait until both products have compiled. Choose Base game or Retro Rewind on Home to play.
- WheelWizard keeps VR under `%APPDATA%\CT-MKWII\RecompVR\Install` by default. A custom data location is supported. The Hub checks the VR product ID, build state, setup host and Base executable before recording a version. Building can take substantial time; leave WheelWizard open until it finishes.

The normal WiiCompiled backend lives in a separate `Recomp` folder. Only one recompilation switch is active at a time. The VR and normal runtimes have separate graphics settings, caches and binaries, while the effective NAND, saves and Miis are shared. Retro Rewind keeps its separate XML directed saves and ghosts. WheelWizard's Uninstall action preserves user configuration and progress.

WheelWizard VR 2.6.2 updates the launcher layout and mod browser. Its Camera tab groups seat position, character body/hands, hand steering and held-item settings; OpenXR VR contains race view and race intro. The paired WiiCompiled OpenXR VR release is 0.2.46. Existing game data, saves and the PAL-disc requirement remain unchanged.

## Play and controls

[[Start in VR]] launches the publisher's Base product through `WiiCompiled-Setup.exe --launch-base`. Use WheelWizard Home for Retro Rewind, repair, backend choice and updates. Managed WheelWizard launches enable OpenXR with D3D12. If the headset or runtime is unavailable, the game falls back to desktop rendering and explains the failure under F10 > VR. For first person, adjust seat position and driver visibility in WheelWizard Settings > OpenXR VR or in game.

| Button | Action |
|---|---|
| [[F10]] | Open the in game settings bar, including VR, controller mapping, resolution and audio. |
| [[Y]] | Open the headset settings panel with motion controllers. |
| [[Left Stick Click]] + [[Right Stick Click]] | Open the headset settings panel in Gamepad controller mode. |
| [[Left Grip]] / [[Right Grip]] | Hold the cockpit wheel or handlebar when hand steering is enabled. |
| [[A]] | Confirm in menus when using an Xbox style controller mapping. |

Controllers can be remapped in the game's F10 bar. WheelWizard can import a Dolphin `GCPadNew.ini`. For a physical USB steering wheel, choose F10 > Controllers > USB wheel and pedals (player 1), calibrate steering and pedals, and map the paddles for drift and items. The publisher has not yet verified every physical wheel model.

## Limitations and recovery

- VR is experimental. A supported single camera race enters immersive stereo, while menus, loading screens and unsupported scenes remain on a virtual screen. Split screen player 1 receives the immersive view.
- The active OpenXR runtime and headset must be ready before starting. If a launch remains flat, inspect the VR explanation in F10 > VR, then restart after changing runtime settings.
- A missing or outdated Base or Retro Rewind build should be repaired through WheelWizard Home > Install. The Hub does not compile a ROM, replace WheelWizard's product state, or treat a downloaded launcher as VR Ready.
- For removal, use WheelWizard VR's Uninstall for the OpenXR backend. It preserves configuration, shared NAND, saves, Miis and Retro Rewind progress. Do not delete the normal `Recomp` backend or your disc image to remove only VR.

[WiiCompiled publisher documentation](https://github.com/iChris4/Wiicompiled_VR) · [WheelWizard VR releases](https://github.com/iChris4/WheelWizard_VR/releases)

Blue shells are still a problem at 90 frames per second.

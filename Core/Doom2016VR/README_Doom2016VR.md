# DOOM (2016) VR

KHARVOX is a total VR conversion for DOOM (2016) with true stereoscopic rendering, room-scale 6DoF tracking and motion-controller interaction. It runs through a separate launcher and OpenXR layer without copying the VR runtime into the original game folder.

## About the Game

Fight through the UAC facility on Mars and descend into Hell in id Software's fast 2016 reboot. The mod requires a legally acquired Steam installation and its Vulkan game executable `DOOMx64vk.exe`.

## Before installation

- Install DOOM (2016), start it normally at least once and accept its license before the first VR launch. Otherwise loading a save can sometimes appear stuck.
- Close DOOM before running the installer.
- The Hub installs KHARVOX into a separate `DOOM 2016 VR` folder. Do not move its individual files into the game folder.
- Unsigned VR executables can trigger antivirus warnings. The installer checks the required files and offers its standard recovery path if protection software quarantines one.

## Starting VR

1. Start your headset software and make its OpenXR runtime active.
2. Open `KharvoxLauncher.exe` through **Start in VR**, the desktop shortcut or the VR folder.
3. Confirm the detected Steam folder containing `DOOMx64.exe` and `DOOMx64vk.exe`.
4. Start with **SFS (Single Frame Stereo)**, the default and recommended rendering mode. Use **AER** only as a fallback.
5. Launch the game from KHARVOX and keep the DOOM window focused.

Change graphics-quality options only while you are in the main menu. Changing them while a level is loaded can freeze or crash the game. A refresh rate of at least 90 Hz is recommended where the headset and PC permit it.

## Controls

![DOOM 2016 KHARVOX motion controls](doom-2016-controls.jpg)

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Menu / pause |
| [[Y]] | Switch weapon modification |
| [[X]] | Dossier |
| [[Left Trigger]] | Equipment / grenade |
| [[Left Grip]] | Two-hand weapon support |
| [[Left Grip Hold]] | BFG when the hand is not supporting a weapon |
| [[Left Grip Tap]] | Next equipment outside grab range |
| [[Right Stick Left / Right]] | Turn |
| [[Right Stick Up]] | Chainsaw |
| [[Right Stick Down Tap]] | Switch weapon |
| [[Right Stick Down Hold]] | Weapon wheel; aim with the left stick |
| [[Right Stick Click]] | Use / melee / Glory Kill |
| [[B]] | Jump |
| [[A]] | Crouch |
| [[Right Trigger]] | Fire |
| [[Right Grip In Front]] | Weapon mod / secondary fire |
| [[Right Grip Behind Shoulder]] | Draw the selected shoulder weapon |

## Rendering and headset notes

KHARVOX v1.1 keeps **SFS** as the default for NVIDIA and AMD GPUs. **AER** remains available as a fallback, while **Native Stereo has been removed**. Existing custom AER profiles are switched to SFS once after updating; AER can still be selected again afterward. Test SFS first. v1.1 fixes FSR handling in the launcher and includes smaller Vulkan performance fixes; the author also reduced the first-launch low-FPS problem, although the first run can still be heavier than later starts.

SFS uses DOOM's own anti-aliasing, while AER uses SMAA. FSR can be combined with either renderer below 100% render scale; the author recommends starting around 80%. When SteamVR is active, change the resolution in SteamVR because the launcher's RenderScale control is disabled for that route. Virtual Desktop users should select VDXR; Index and PSVR2 users should use SteamVR/OpenXR.

Version 1.0 introduced the major stereo-lighting, shadow, particle and HUD improvements, reduced weapon flicker and position jumps, disabled lens flares in SFS, and added the offhand HUD for life, ammunition and the five-circle progression meter. Earlier releases added the weapon wheel, setup diagnostics and the texture-streaming overflow fix.

## Updates and removal

The Hub resolves the current regular GitHub release and selects only the KHARVOX ZIP asset. It does not reject future publisher builds because their historical size, filename or checksum changed. KHARVOX itself rewrites `KharvoxLayer.json` with the absolute location of its DLL; the installer recognizes that one publisher-generated file during an update without weakening protection for ordinary changed files. Use **Uninstall now** to remove unchanged Hub-owned KHARVOX files. Changed or unknown files and `%LocalAppData%\KHARVOX\settings.json` are preserved; the original Steam installation remains untouched.

## Credits and support

- KHARVOX by [CactusVRStudios](https://github.com/CactusVRStudios/KHARVOX)
- [GitHub releases](https://github.com/CactusVRStudios/KHARVOX/releases)
- [Flat2VR Modding Discord](https://discord.com/invite/ZFSCSDe) for community support
- Community project, not affiliated with id Software or Bethesda.

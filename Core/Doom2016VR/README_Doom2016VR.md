# DOOM (2016) VR

KHARVOX is a total VR conversion for DOOM (2016) with true stereoscopic rendering, room-scale 6DoF tracking and motion-controller interaction. It runs through a separate launcher and OpenXR layer without copying the VR runtime into the original game folder.

## About the Game

Fight through the UAC facility on Mars and descend into Hell in id Software's fast 2016 reboot. The mod requires the Vulkan game executable `DOOMx64vk.exe`. Steam is tested by the author; the Hub also detects GOG, but GOG compatibility is not yet confirmed upstream.

## Before installation

- Install DOOM (2016), start it normally at least once and accept its license before the first VR launch. Otherwise loading a save can sometimes appear stuck.
- Close DOOM before running the installer.
- The Hub installs KHARVOX into a separate `DOOM 2016 VR` folder. Do not move its individual files into the game folder.
- Unsigned VR executables can trigger antivirus warnings. The installer checks the required files and offers its standard recovery path if protection software quarantines one.

## Starting VR

1. Start your headset software and make its OpenXR runtime active.
2. Open `KharvoxLauncher.exe` through **Start in VR**, the desktop shortcut or the VR folder.
3. Confirm the detected Steam folder. For GOG, use **Browse** and select the folder containing `DOOMx64.exe` and `DOOMx64vk.exe`.
4. Start with **AER**, the recommended rendering mode. **Native Stereo** is highly experimental.
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

AER is the default and broadly recommended mode. Native Stereo can produce better geometry in some scenes but is experimental and substantially more demanding. Virtual Desktop and Meta Link are supported Quest routes; SteamVR/OpenXR behavior depends on the active headset runtime. Some AMD and headset combinations may need additional tuning, although release v0.7-beta includes an AMD GPU fix.

## Updates and removal

The Hub resolves the current regular GitHub release and selects only the KHARVOX ZIP asset. It does not reject future publisher builds because their historical size, filename or checksum changed. Use **Uninstall now** to remove unchanged Hub-owned KHARVOX files. Changed or unknown files and `%LocalAppData%\KHARVOX\settings.json` are preserved; the original DOOM installation remains untouched.

## Credits and support

- KHARVOX by [CactusVRStudios](https://github.com/CactusVRStudios/KHARVOX)
- [GitHub releases](https://github.com/CactusVRStudios/KHARVOX/releases)
- [Flat2VR Modding Discord](https://discord.com/invite/ZFSCSDe) for community support
- Community project, not affiliated with id Software or Bethesda.

# Metal: Hellsinger VR

The community **HellsingerVR** mod (by **LivingFray**) for *Metal: Hellsinger* - a rhythm-driven first-person shooter where you shoot, dash and slaughter demons in time with a heavy-metal soundtrack across the eight hells.

> **IMPORTANT - about this mod:** An **official VR version** of Metal: Hellsinger now exists, with further improvements and performance optimizations over this community mod. If you want the most polished experience, get the official release:
> https://store.steampowered.com/app/2878270/Metal_Hellsinger_VR/
>
> This Hub entry is the free community-mod route, installed onto a pinned Steam depot build.

## What you get
- Full motion-control VR via the HellsingerVR mod (BepInEx / SteamVR)
- A pinned Steam depot build that the mod actually works with (the current retail build has broken motion-control weapon rendering)
- Your retail Metal: Hellsinger stays untouched - the VR build lives in its own folder
- Configurable handedness, turning, UI placement, beat vibration and more

## Requirements
- You must **own Metal: Hellsinger on Steam** (needed for the depot download)
- Launch SteamVR before the game to avoid it potentially starting sometimes out of focus
- Motion controllers (Oculus/Meta Touch, Valve Index, Vive supported)

## How to install
1. The installer copies the Steam Console `download_depot` command to your clipboard and opens the Steam Console.
2. Paste it (Ctrl+V) and press Enter; wait for the depot download to finish.
3. The installer moves the build to `C:\Games\Metal Hellsinger VR`, downloads HellsingerVR v0.9.0 and extracts it on top.
4. A desktop shortcut and `steam_appid.txt` are created.

## How to launch
Start **SteamVR** first, then either:
- Use the Hub's **Start in VR** button (runs `Metal.exe`), or
- Use the desktop shortcut **Metal Hellsinger VR**.

> First launch: the game window needs focus to get past the logo/login screen. If pressing a trigger does nothing, click the game window so it has focus.

## Controls

![Controller layout](ControllerLayout.jpg)

The image above shows the full layout. Motion-control bindings (Oculus Touch shown; Index/Vive bindings ship with the mod):

**Left hand**
- **[[Left Stick]]:** Move
- **[[Left Stick]] press:** Dash
- **[[Left Trigger]]:** Fire (left-hand weapon)
- **[[Left Grip]]:** Previous weapon
- **[[X]]:** Last weapon
- **[[Menu]]:** Pause / menu

**Right hand**
- **[[Right Stick]]:** Look / turn
- **[[Right Stick]] press:** Jump
- **[[Right Trigger]]:** Fire (right-hand weapon)
- **[[Right Grip]]:** Next weapon
- **[[A]]:** Slaughter
- **[[B]]:** Reload

**Both hands**
- **[[Both Triggers]]:** Ultimate (fire both at once)

## Config
Edit `BepInEx\config\LivingFray.HellsingerVR.cfg` to tweak the mod:
- **Left handed**, **DisableMotionControls** (play with a gamepad)
- **Snap turn amount** (0 = smooth turning), **Movement type** (head / hand / offhand)
- **Reticle location**, on-hand vs floating **health / ultimate / fury / boss** bars
- **Menu UI Distance**, **Game UI Distance**, **MoveUIVertically**
- **PostProcessingLevel** (0 / 1 / 99) for performance
- **Beat vibration** strength / frequency / length / offset

## Known issues
- **Focus:** the game must have window focus to pass the logo/login screen.
- **Performance:** Metal: Hellsinger is heavy in VR. High -> Mid settings gives the biggest gain (Mid -> Low adds little). vrperfkit helps further at some fidelity cost - get it here: https://github.com/fholger/vrperfkit

## Credits
- Mod by **LivingFray** - https://github.com/LivingFray/HellsingerVR
- SteamVR IL2CPP plugin adapted from DSprtn's SteamVR_Standalone_IL2CPP

>>> Shoot to the beat. Slaughter to the rhythm. Burn through the hells.

# PEAK VR Installer

Installs **PEAK_VR by AstienVR** onto a pinned, mod-compatible copy of PEAK fetched via Steam Console's `download_depot` command. Your normal Steam install is left untouched.

## Why a pinned manifest?

PEAK keeps shipping updates that break the VR mod. The README of v1.0.0 states the mod is no longer compatible with game versions past **1.44.a**. This installer downloads exactly that build (Steam manifest `1663614006819171465`, Depot `3527291`, App `3527290`) via Steam itself, then moves the depot folder into a separate location (`C:\Games\PEAK VR` by default) so a Steam auto-update can't break your VR setup.

## Requirements

- **PEAK owned on Steam**
- **Steam running and logged in** (Steam Console reuses your Steam session - no extra password / Steam Guard prompts)
- **7-Zip** installed (https://www.7-zip.org)
- **SteamVR** installed
- **About 4 GB free disk space**
- **Admin rights** for the ViGEmBus driver install (one UAC prompt)

## What the installer does

1. **7-Zip pre-flight** check
2. **Steam Console** is opened with the `download_depot 3527290 3527291 1663614006819171465` command already in your clipboard. You paste it (Ctrl+V) into the console and press Enter; Steam downloads about 4 GB to `Steam\steamapps\content\app_3527290\depot_3527291\`
3. **Move depot** out of `steamapps\content\` into `C:\Games\PEAK VR` (or wherever you choose), drop `steam_appid.txt` so the EXE can be launched outside Steam's update path
4. **PEAK_VR mod** auto-downloaded from GitHub release v1.0.0, extracted on top (BepInEx pattern: `winhttp.dll` + `BepInEx/` folder)
5. **PeakVersionBypass** (by kirigiri, v1.0.2) auto-downloaded from Thunderstore and dropped into `BepInEx\plugins\`. PEAK refuses to start when its build version doesn't match Steam's expected current version - since we're pinned to 1.44.a, PEAK would otherwise hit an "update required" prompt and never reach gameplay (not even offline). The bypass plugin silences that check
6. **VR config corrected** - the shipped `BepInEx\config\UnityVR_Bepinex.cfg` sets two values that break controllers in practice, so the installer rewrites them: **fixControllerTracking = true** (otherwise controller tracking dies on every scene load) and **controllerType = xbox360** (otherwise the emulated gamepad isn't recognised). If you ever reset the config, set both again by hand
7. **ViGEmBus driver** setup launched interactively (needed for the mod's virtual Xbox-gamepad emulation). UAC prompt expected. If you already have ViGEmBus installed, just close the setup window
8. **Desktop shortcut** to `PEAK.exe` in the pinned folder

## Launching

1. Make sure **Steam is running** (PEAK still authenticates via Steam even from a pinned folder)
2. Start **SteamVR**
3. Launch with **Start in VR** in the Hub, or the **PEAK VR** desktop shortcut

## Runtime + Graphics API combinations

PEAK runs on either Vulkan or D3D12. The VR mod uses OpenVR by default but can also use OpenXR. Some combinations don't work, and which one works for you depends on your hardware and headset. Author's own findings:

| Combination | Result |
|---|---|
| OpenVR + Vulkan | **Recommended** - VR works, flatscreen may not show image |
| OpenVR + D3D12  | No image in headset for the author |
| OpenXR + Vulkan | Crashes for the author |
| OpenXR + D3D12  | VR works, no image on flatscreen |

If the default (OpenVR + Vulkan) doesn't render in your headset, try OpenXR + D3D12 next.

**Switching VR API:** edit `BepInEx\config\UnityVR_Bepinex.cfg` in your install folder, find the line `vrApi = OpenVR` near the top, change to `vrApi = OpenXR`.

**Switching graphics API:** PEAK's own launch options (you'd set `-force-vulkan` or `-force-d3d12` via the shortcut Properties → Target).

**Spectator view:** in `UnityVR_Bepinex.cfg` set `createMirrorView = true` if you want a desktop-side mirror window for streaming / showing friends.

## Mod features

- 3D stereoscopic VR view
- 6DOF head + hand tracking
- Inverse-kinematic VR hands (won't be at exact controller positions due to skeleton constraints + physics)
- bHaptics support
- Left-handed mode (edit `BepInEx\config\PEAK_VR.cfg`, set `leftHanded = true` after first launch)

## Controls

VR controllers are mapped as an Xbox gamepad. With swapped buttons for VR ergonomics:

- [[A]], [[B]], [[X]], [[Y]] - same as Xbox
- [[X]] and [[B]] are swapped in the mod (onscreen icons reflect this)
- **Left and [[Right Trigger]] swapped** (onscreen icons reflect this)
- [[Left Grip]] = LB, [[Right Grip]] = RB
- **Click BOTH thumbsticks** = recenter VR view
- **Hold left hand near your head IRL** = hotkey gesture mode (controller vibrates). While vibrating: [[Left Stick]] = D-Pad, [[Left Stick]] click = back, [[Right Stick]] click = start

**Two laser types:**

- **White laser** - your hand position at all times. Used for kiosks, items, NPCs, throwing
- **Red laser** - attached to shootable items. Use this for aiming guns / projectiles

## UI modes (BepInEx\config\PEAK_VR.cfg)

| UIMode + AttachUIToHand | Behavior |
|---|---|
| `frontOfGameCam` + `false` (default) | UI flat in front of game camera, follows camera not head |
| `frontOfGameCam` + `true` | Stamina + inventory attached to right hand, rest in front of head |
| `headFixed` | Everything fixed to VR head, follows head rotation |

If the headFixed UI is sized wrong, change in-game resolution. Author suggests 1920x1080 as a starting point.

## Troubleshooting

**No "USB device connected" Windows sound when launching VR:** ViGEmBus didn't install correctly. Re-run the installer at `BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe` in your install folder, or reboot and try again

**Black headset / no VR image:** wrong VR API + Graphics API combo for your hardware. Edit `UnityVR_Bepinex.cfg`, try a different `vrApi`, restart. PEAK's graphics API switches via launch flags on the shortcut

**Crashes on launch:** if using Vulkan, run PEAK in flat mode first (rename `winhttp.dll` → `winhttp2.dll`), go into Settings, turn Ambient Occlusion OFF and cap max FPS to 120 or below, quit, rename back, retry

**Performance issues:** lower in-game max FPS to 100 or under, disable Ambient Occlusion, lower headset resolution **in SteamVR** (not in PEAK - game resolution doesn't affect VR rendering quality)

**Hands feel off:** make sure you're properly centered. First use SteamVR's recenter, then click both thumbsticks - in that order

**Virtual Desktop users:** in the headset's Virtual Desktop input section, make sure NO gamepad emulation is checked. PEAK_VR creates its own virtual Xbox gamepad via ViGEmBus; if VD also emulates one, they conflict

**Want to use other mods alongside VR:** put them in `BepInEx/plugins`. Note: compatibility is not guaranteed and the mod author won't help debug other-mod conflicts

**Disable VR temporarily:** rename `winhttp.dll` in the install folder to `winhttp2.dll`. PEAK launches flat. Rename back to re-enable VR

## Known issues

- The mod **locks input to gamepad** - keyboard and mouse won't work in VR (prevents constant input-device switching)
- **Binoculars don't work** in VR
- **Fog has a stereoscopic mismatch** - both eyes see slightly different fog. Disable with `disableFog = true` in `PEAK_VR.cfg`
- **No real-time hand sync between VR players** - intentional, per the author: "PEAK is played by a lot of kids, I won't allow that feature"
- **No hand-movement climbing** - climbing uses gamepad inputs, not physical hand motion

## Multiplayer

You can play VR with non-VR friends. They see your character with normal arm animations. They won't see your real hand movements - the game doesn't sync that, and the mod author won't add it.

## Mod info

- **Author:** AstienVR
- **GitHub:** https://github.com/AstienVR/PEAK_VR
- **Release:** v1.0.0 (last version, mod not maintained past PEAK 1.44.a)

## Important from the mod author

DO NOT UNDER ANY CIRCUMSTANCE COMPLAIN ABOUT BUGS TO THE DEVELOPERS WHILE USING MODS. UNINSTALL MODS IF YOU ENCOUNTER BUGS AND THEN REPORT THEM IF THEY ARE STILL PRESENT.

## Support Astien

If you want to show some support to Astien (the modder also known as Astienth / AstienVR), you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Reach the summit. Try not to fall. See you up top, Scout.

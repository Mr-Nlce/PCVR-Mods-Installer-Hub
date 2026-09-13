# PEAK VR

<!-- hub:keep-order -->

PEAK has three parallel VR install choices. Options 1 and 2 use PeakVR by Andrey04o on different game builds; option 3 is the older PEAK_VR by AstienVR. Each stays in its own location, and the installer asks which one you want.

## OPTION 1 — Current game version — PeakVR by Andrey04o

### Mod Info

> **SUPPORTED AGAIN:** PeakVR 1.5.0 is tested by the author with the current PEAK 2.4.b game build. This is the primary and currently recommended route.

- **Author:** Andrey04o, forked from LCVR by DaXcess
- **Thunderstore:** https://thunderstore.io/c/peak/p/Andrey04o/PeakVR/
- **Game build:** current PEAK 2.4.b, in your normal Steam copy
- **Updates:** automatic - the Hub checks GitHub and Thunderstore and installs the newer stable release

Full 6DOF VR, built on Unity's OpenXR plugin, so it works with a wide range of headsets and runtimes - Oculus, Virtual Desktop, SteamVR and others. Your head and hands come into VR with motion controls, but there is **no physical hand-over-hand climbing** - you still climb the way the base game does. It is not a climbing simulator. Version 1.5.0 restores current-game support and adds VR keyboard/chat support, F11 flat/VR switching and a **Start In VR** setting.

### Requirements

- **PEAK owned on Steam**, current 2.4.b version
- **SteamVR**, the Oculus app, or Virtual Desktop as your OpenXR runtime
- A headset connected before you start

### What the installer does

The Hub pulls PeakVR and its complete dependency graph from the current release manifests. Its three direct requirements are BepInEx (PEAK pack), PEAKLib Core and PEAKLib UI; any required transitive packages are resolved too. Nothing is moved or copied out of Steam - the files go into the game folder you already have.

Each package's installed version is recorded under `BepInEx\.ts_versions\`, so running the installer again only fetches what actually changed. That makes it the update path too. The Hub also checks whether the mod has been marked deprecated on Thunderstore and says so before installing anything.

### Launching

1. Start SteamVR, or your Oculus / Virtual Desktop runtime
2. Launch with **Start in VR** in the Hub, the **PEAK VR** desktop shortcut, or simply PEAK from Steam

### Controls

![Controls](PEAKVR_controls_PeakVR.jpg)

Motion controllers, with a pointer for the menus:

- [[Left Stick]] Move, click to sprint, push forward to leap
- [[Right Stick]] Turn, scroll, click to ping a location
- [[X]] Crouch, [[Y]] Pause
- [[A]] Jump, [[B]] Stash item
- [[Left Trigger]] Drop, hold to throw
- [[Left Grip]] Helping hand, alternate item use
- [[Right Trigger]] Climb, use item
- [[Right Grip]] Interact

### Settings

| Where | Setting |
|---|---|
| Settings > Mod Settings > PEAK VR > VR GRAPHICS | **Make Image Sharper -> Enable**, if the picture looks blurry |
| Steam launch options | **`-force-d3d11`** gives an extra 10-27 FPS, per the mod author |

### Multiplayer

You can play in lobbies together with flat players.

## OPTION 2 — Depot version 2.1.a — PeakVR by Andrey04o

### Mod Info

- **Author:** Andrey04o, forked from LCVR by DaXcess
- **PeakVR release used by the installer:** exact pinned 1.4.1 package
- **Compatible game build:** PEAK 2.1.a, Windows depot manifest `4845579380240751548` from 13 August 2026
- **Install folder:** `C:\Games\PEAK VR 2.1a` by default
- **Status:** last-confirmed fallback if a future PEAK update breaks the current route

This is the same full 6DOF motion-control mod as option 1, but installed onto a separate game build that PeakVR v1.4.1 was explicitly tested against. Steam cannot auto-update this copy and your regular PEAK installation is not changed.

### Requirements

- **PEAK owned on Steam**
- **Steam running and logged in**; Steam Console uses the existing account session
- SteamVR, Oculus, or Virtual Desktop as your OpenXR runtime
- About 4 GB free disk space

### What the installer does

1. Copies `download_depot 3527290 3527291 4845579380240751548` to the clipboard and opens Steam Console
2. Verifies `PEAK.exe`, then moves the downloaded build into `C:\Games\PEAK VR 2.1a` or your chosen separate folder
3. Adds `steam_appid.txt` and records the exact manifest so a different cached depot cannot silently be mistaken for 2.1.a
4. Installs the exact pinned PeakVR 1.4.1 package and its manifest-resolved matching dependency versions
5. Installs and verifies **PeakVersionBypass 1.2.0 by RadiatorExtrem**; without it the pinned game cannot pass PEAK's current-version check. A real PEAK 2.1.a launch reached the responsive main menu with both bypass patches active. If the incompatible kirigiri 1.0.2 DLL is present, rerunning the installer safely replaces it.
6. Creates the desktop shortcut **PEAK VR 2.1a** with `-force-d3d11`

Existing BepInEx configs and additional files in the target are preserved during a reinstall. The current Steam copy and `C:\Games\PEAK VR` legacy depot are never used as this route's target.

### Launching

1. Keep Steam running for ownership authentication
2. Start your OpenXR runtime
3. Use **Depot 2.1a** in the Hub or the **PEAK VR 2.1a** desktop shortcut

If both the current and 2.1.a installs exist, the game tile shows **Current** and **Depot 2.1a**. The legacy 1.44.a build is intentionally shown only on this game's detail page as **Start 1.44.a**.

### Controls

![Controls](PEAKVR_controls_PeakVR.jpg)

- [[Left Stick]] Move, click to sprint, push forward to leap
- [[Right Stick]] Turn, scroll, click to ping a location
- [[X]] Crouch, [[Y]] Pause
- [[A]] Jump, [[B]] Stash item
- [[Left Trigger]] Drop, hold to throw
- [[Left Grip]] Helping hand, alternate item use
- [[Right Trigger]] Climb, use item
- [[Right Grip]] Interact

### Settings

| Where | Setting |
|---|---|
| Settings > Mod Settings > PEAK VR > VR GRAPHICS | **Make Image Sharper -> Enable**, if the picture looks blurry |
| Shortcut / Hub launch | `-force-d3d11` is applied automatically |

### Multiplayer

The mod supports lobbies with flat players, but everybody must be on a mutually compatible PEAK game build. A pinned 2.1.a client may not be able to join players on the current game update.

## OPTION 3 — Depot version 1.44.a — PEAK_VR by AstienVR

### Mod Info

- **Author:** AstienVR
- **GitHub:** https://github.com/AstienVR/PEAK_VR
- **Release:** v1.0.0 (last version, mod not maintained past PEAK 1.44.a)

Installs onto a pinned, mod-compatible copy of PEAK fetched via Steam Console's `download_depot` command. Your normal Steam install is left untouched. Everything from here on belongs to this mod.

### Why a pinned manifest

PEAK keeps shipping updates that break the VR mod. The README of v1.0.0 states the mod is no longer compatible with game versions past **1.44.a**. This installer downloads exactly that build (Steam manifest `1663614006819171465`, Depot `3527291`, App `3527290`) via Steam itself, then moves the depot folder into a separate location (`C:\Games\PEAK VR` by default) so a Steam auto-update can't break your VR setup.

### Requirements

- **PEAK owned on Steam**
- **Steam running and logged in** (Steam Console reuses your Steam session - no extra password / Steam Guard prompts)
- **7-Zip** installed (https://www.7-zip.org)
- **SteamVR** installed
- **About 4 GB free disk space**
- **Admin rights** for the ViGEmBus driver install (one UAC prompt)

### What the installer does

1. **7-Zip pre-flight** check
2. **Steam Console** is opened with the `download_depot 3527290 3527291 1663614006819171465` command already in your clipboard. You paste it (Ctrl+V) into the console and press Enter; Steam downloads about 4 GB to `Steam\steamapps\content\app_3527290\depot_3527291\`
3. **Move depot** out of `steamapps\content\` into `C:\Games\PEAK VR` (or wherever you choose), drop `steam_appid.txt` so the EXE can be launched outside Steam's update path
4. **PEAK_VR mod** auto-downloaded from GitHub release v1.0.0, extracted on top (BepInEx pattern: `winhttp.dll` + `BepInEx/` folder)
5. **PeakVersionBypass** (by kirigiri, v1.0.2) auto-downloaded from Thunderstore and dropped into `BepInEx\plugins\`. PEAK refuses to start when its build version doesn't match Steam's expected current version - since we're pinned to 1.44.a, PEAK would otherwise hit an "update required" prompt and never reach gameplay (not even offline). The bypass plugin silences that check
6. **VR config corrected** - the shipped `BepInEx\config\UnityVR_Bepinex.cfg` sets two values that break controllers in practice, so the installer rewrites them: **fixControllerTracking = true** (otherwise controller tracking dies on every scene load) and **controllerType = xbox360** (otherwise the emulated gamepad isn't recognised). If you ever reset the config, set both again by hand
7. **ViGEmBus driver** setup launched interactively (needed for the mod's virtual Xbox-gamepad emulation). UAC prompt expected. If you already have ViGEmBus installed, just close the setup window
8. **Desktop shortcut** to `PEAK.exe` in the pinned folder

### Launching

1. Make sure **Steam is running** (PEAK still authenticates via Steam even from a pinned folder)
2. Start **SteamVR**
3. Launch with **Start 1.44.a** on the Hub detail page, or the **PEAK VR** desktop shortcut

### Runtime and graphics API

PEAK runs on either Vulkan or D3D12. The VR mod uses OpenVR by default but can also use OpenXR. Some combinations don't work, and which one works for you depends on your hardware and headset. Author's own findings:

| Combination | Result |
|---|---|
| OpenVR + Vulkan | **Recommended** - VR works, flatscreen may not show image |
| OpenVR + D3D12  | No image in headset for the author |
| OpenXR + Vulkan | Crashes for the author |
| OpenXR + D3D12  | VR works, no image on flatscreen |

If the default (OpenVR + Vulkan) doesn't render in your headset, try OpenXR + D3D12 next.

**Switching VR API:** edit `BepInEx\config\UnityVR_Bepinex.cfg` in your install folder, find the line `vrApi = OpenVR` near the top, change to `vrApi = OpenXR`.

**Switching graphics API:** PEAK's own launch options (you'd set `-force-vulkan` or `-force-d3d12` via the shortcut Properties -> Target).

**Spectator view:** in `UnityVR_Bepinex.cfg` set `createMirrorView = true` if you want a desktop-side mirror window for streaming / showing friends.

### Mod features

- 3D stereoscopic VR view
- 6DOF head + hand tracking
- Inverse-kinematic VR hands (won't be at exact controller positions due to skeleton constraints + physics)
- bHaptics support
- Left-handed mode (edit `BepInEx\config\PEAK_VR.cfg`, set `leftHanded = true` after first launch)

### Controls

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

### UI modes

Set in `BepInEx\config\PEAK_VR.cfg`:

| UIMode + AttachUIToHand | Behavior |
|---|---|
| `frontOfGameCam` + `false` (default) | UI flat in front of game camera, follows camera not head |
| `frontOfGameCam` + `true` | Stamina + inventory attached to right hand, rest in front of head |
| `headFixed` | Everything fixed to VR head, follows head rotation |

If the headFixed UI is sized wrong, change in-game resolution. Author suggests 1920x1080 as a starting point.

### Troubleshooting

**No "USB device connected" Windows sound when launching VR:** ViGEmBus didn't install correctly. Re-run the installer at `BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe` in your install folder, or reboot and try again

**Black headset / no VR image:** wrong VR API + Graphics API combo for your hardware. Edit `UnityVR_Bepinex.cfg`, try a different `vrApi`, restart. PEAK's graphics API switches via launch flags on the shortcut

**Crashes on launch:** if using Vulkan, run PEAK in flat mode first (rename `winhttp.dll` -> `winhttp2.dll`), go into Settings, turn Ambient Occlusion OFF and cap max FPS to 120 or below, quit, rename back, retry

**Performance issues:** lower in-game max FPS to 100 or under, disable Ambient Occlusion, lower headset resolution **in SteamVR** (not in PEAK - game resolution doesn't affect VR rendering quality)

**Hands feel off:** make sure you're properly centered. First use SteamVR's recenter, then click both thumbsticks - in that order

**Virtual Desktop users:** in the headset's Virtual Desktop input section, make sure NO gamepad emulation is checked. PEAK_VR creates its own virtual Xbox gamepad via ViGEmBus; if VD also emulates one, they conflict

**Want to use other mods alongside VR:** put them in `BepInEx/plugins`. Note: compatibility is not guaranteed and the mod author won't help debug other-mod conflicts

**Disable VR temporarily:** rename `winhttp.dll` in the install folder to `winhttp2.dll`. PEAK launches flat. Rename back to re-enable VR

### Known issues

- The mod **locks input to gamepad** - keyboard and mouse won't work in VR (prevents constant input-device switching)
- **Binoculars don't work** in VR
- **Fog has a stereoscopic mismatch** - both eyes see slightly different fog. Disable with `disableFog = true` in `PEAK_VR.cfg`
- **No real-time hand sync between VR players** - intentional, per the author: "PEAK is played by a lot of kids, I won't allow that feature"
- **No hand-movement climbing** - climbing uses gamepad inputs, not physical hand motion

### Multiplayer

You can play VR with non-VR friends. They see your character with normal arm animations. They won't see your real hand movements - the game doesn't sync that, and the mod author won't add it.

### Important from the mod author

DO NOT UNDER ANY CIRCUMSTANCE COMPLAIN ABOUT BUGS TO THE DEVELOPERS WHILE USING MODS. UNINSTALL MODS IF YOU ENCOUNTER BUGS AND THEN REPORT THEM IF THEY ARE STILL PRESENT.

### Support Astien

If you want to show some support to Astien (the modder also known as Astienth / AstienVR), you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Reach the summit. Try not to fall. See you up top, Scout.

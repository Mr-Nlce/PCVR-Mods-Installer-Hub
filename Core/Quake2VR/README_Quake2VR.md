# Quake 2 VR

<!-- hub:keep-order -->

The Hub keeps two separate standalone VR ports. They can coexist and never overwrite the Steam or GOG installation.

## Quake II PCVR by GameOrDie007 — recommended

This maintained OpenXR port applies Team Beef's Quake2Quest work to a portable Windows build with motion controls. It supports VDXR, SteamVR and the Oculus OpenXR runtime, and falls back to a flat window when no headset is active.

### Install

1. Select **Install VR mod** and choose **Quake II PCVR**.
2. The installer finds an owned Steam or GOG copy by `baseq2\pak0.pak`.
3. It downloads the current official GitHub release and builds `C:\Games\Quake II PCVR` by default.
4. The official setup copies the base game, available mission packs and soundtrack. If absent, it also downloads Team Beef's optional HD weapon models, world textures and comfort mask from Team Beef's GitHub release.
5. Start the OpenXR runtime, then use **OpenXR** on this page or the **Quake 2 OpenXR VR** desktop shortcut.

The Reckoning and Ground Zero are detected separately. If owned, both appear in the in-game game list and receive their own VR desktop shortcuts. The 2023 remaster's Call of the Machine and Quake II 64 episodes need the remaster engine and are not supported by this port.

### Controls and settings

- [[Weapon-hand stick click]] cycle laser sight off, beam and dot
- [[Weapon-hand grip]] open the weapon wheel
- [[Off-hand stick down]] open the item wheel
- [[Menu button]] open the menu
- [[Alt]] + [[Enter]] switch the desktop mirror between windowed and fullscreen

Open **Options → VR Options** and **Options → PC Options** for render resolution, antialiasing, view distance, HUD height and desktop mirror behavior. Expansion-only weapon offsets can be tuned with the in-headset Weapon Alignment tool and saved without being overwritten by another setup run.

### Current limitations

- Quest 2 can show the id logo, opening cutscene and first menu twice; Quest 3 is confirmed clean on the same build.
- Six expansion-only weapons begin with generic offsets and may need Weapon Alignment tuning.
- The Ground Zero plasma beam graphic begins at the face although its damage trace follows the controller correctly.

## Q2VR by Luke Groeninger and Malcolm Smith — legacy

The second installer option retains the older KMQuake II-based Q2VR build. It uses the Oculus runtime directly on Rift or Quest Link / AirLink. Virtual Desktop, Steam Link, Index, Vive, Pico and WMR require Revive plus the Oculus PC runtime.

1. Select **Install VR mod** and choose **Q2VR legacy**.
2. Choose the small binaries package or the manually supplied legacy HD package.
3. The installer copies your owned `pak0.pak`, detects optional mission packs and creates the correct Oculus or Revive launch route.
4. Use **Legacy** on this page to launch it.

The legacy port mainly provides HMD view and gamepad-style input; the new OpenXR port is the recommended motion-control route.

## Flat play and removal

No file switch is necessary because both VR versions live outside the original game. **Open in Steam** launches flat Quake II. **Uninstall now** lists both installed ports and removes only the selected option's manifest-owned runtime files. Copied PAKs, mission-pack data, music, saves, screenshots and user-edited configurations remain available in the standalone folder.

## Credits

- **Quake II PCVR:** GameOrDie007 — [project, releases and support](https://github.com/GameOrDie007/Quake-II-PCVR)
- **Quake2Quest foundation and optional assets:** Team Beef / DrBeef
- **Legacy Q2VR:** Luke Groeninger and Malcolm Smith — [project page](http://www.malcolm-s.net/q2vr/)
- **Quake II:** id Software

Storm Stroggos — the railgun does the talking.

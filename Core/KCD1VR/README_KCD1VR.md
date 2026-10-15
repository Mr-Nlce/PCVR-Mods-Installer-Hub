# Kingdom Come: Deliverance VR

## About the Game

Kingdom Come: Deliverance is a grounded open-world role-playing game set in medieval Bohemia. KCD1VR adds experimental native stereo OpenXR and 6DoF head tracking to the original game.

## Requirements and support status

- The supported game is **Kingdom Come: Deliverance 1.9.7 on Steam**.
- This is a **WIP** release with gamepad or keyboard and mouse controls. Motion controls are not implemented.
- **v0.1.69 requests OpenXR 1.0**, addressing the API-version error seen with some runtimes in v0.1.67. The publisher confirms the corrected sRGB headset image but has **not tested Virtual Desktop/VDXR**; treat that route as experimental. Meta Quest Link/Air Link with Oculus OpenXR remains the confirmed route. SteamVR support for this release is unconfirmed.
- Steam launch parameters are required. The installer copies and displays them before completion.
- A Quest 3 user reports focus-dependent head latency/stutter and washed-out gamma/contrast with Meta Link. The publisher says the sRGB correction in v0.1.69 fixes the washed-out headset image and confirms it in a headset. The latency report remains a community observation, not a confirmed universal defect.
- That tester found no improvement from HAGS changes or Process Lasso priority changes. ASW behavior varied with focus and framerate, so none of these is presented as a general fix.

## Controls

| Button | Action |
|---|---|
| [[Gamepad]] | Standard game controls |
| [[Keyboard]] + [[Mouse]] | Standard game controls |

## Installation and removal

The installer first asks the publisher's OpenXR tool for the runtime's recommended per-eye resolution, configures DLSS, preserves an existing `KCD1VR.ini`, and manages only a clearly delimited block in `user.cfg`. If the tool cannot read a headset resolution, the installer offers ten common headset presets plus exact manual per-eye width and height; it does not require successful automatic detection. Presets use native panel resolution as a practical fallback, while exact runtime values remain preferable because runtimes can request different sizes for the same hardware. The installer also places `+exec KCD1VR.cfg +exec KCD1VR-dlss.cfg` in Steam's launch options. **Start in VR** opens app 379430 directly through Steam, so Steam applies those saved launch options exactly as it does when you press Play in the Steam library. It does not open an additional Hub launcher window. Directly starting `KingdomCome.exe` is not used because that bypasses Steam's launch options and can leave only a flat 2D VR quad. Virtual Desktop/VDXR remains untested by the publisher; use the confirmed Meta Quest Link/Air Link route if you need a known working runtime. **Uninstall now** removes the managed block, restores pre-existing collisions and leaves saves and unrelated settings untouched.

Menus and explicit dialogue scenes intentionally use a flat, head-locked VR screen. This is expected only for those interfaces. After loading a save and returning to normal gameplay, the world must switch to full stereoscopic VR and fill the headset view. If normal gameplay remains a small flat rectangle, close the game and use **Start in VR** again; the Hub launch route goes through Steam so both root configuration files reach the actual game process before stereo submission.

## Links

- [Project and instructions](https://github.com/farmerarmor/KCD1VR)
- [Releases](https://github.com/farmerarmor/KCD1VR/releases)
- [Gameplay video](https://youtu.be/oSkDdZKN0UY?si=pmD-Ht3bNmItNzx3&t=24)
- [Flat2VR discussion thread](https://discord.com/channels/747967102895390741/1547235772971749497)

# Star Wars Episode I Racer — Racer PCVR

Racer PCVR adds stereoscopic rendering, head tracking and Quest motion controls to the original game.

## Before launch

- A **32-bit OpenXR runtime is required**. Connect Virtual Desktop and select VDXR before starting the game.
- SteamVR cannot load this 32-bit port. The author also considers the Meta/Oculus runtime untested.
- Use **Start in VR** on this page, or launch normally through Steam/GOG. The headset connection must already be active.
- The Steam edition installs its own Windows XP compatibility profile. Its UAC prompt may identify the signed game as **rdroid_gnome release build**; GNOME is Racer's original engine name, not another Hub download. Racer PCVR itself does not request administrator rights.
- For smoother racing, start at 72 Hz. The original physics are tied to frame rate and the game can become CPU-bound at higher refresh rates.

## Quest controls

| Action | Control |
|---|---|
| Steer / navigate menus | [[Left Stick]] |
| Look around | [[Right Stick]] |
| Accelerate | [[Right Trigger]] |
| Brake | [[Left Trigger]] |
| Boost | [[Left Grip]] |
| Repair | [[Right Grip]] |
| Taunt | [[Left Stick Click]] |
| Slide | [[Right Stick Click]] |
| Look back | [[X]] |
| Change camera | [[Y]] |
| Confirm | [[A]] |
| Back / pause | [[B]] |
| Pause | [[Left Menu]] |
| Skip a cutscene | [[Both Grips]] |
| Open PCVR settings | [[F5]] |

## Useful Hub actions

- **VR / Flat** changes the port's official `[vr] no_vr` setting in `SW_RACER_RE.ini`. Gold shows the active mode.
- The main setup can add community tracks immediately after Racer PCVR. **Community tracks** installs or retries them later. It copies only `assets\custom_tracks`; the pack's different `dinput.dll` is never installed over Racer PCVR.
- Do not install the NetizenKing HD cutscene pack: its replacement Smush player crashes with Racer PCVR.
- **Remove PCVR** restores pre-existing files and removes only unchanged files recorded by the PCVR installer. **Remove tracks** does the same for community tracks. Both keep saves, configuration, replacement models and unrelated files.

## Current limitations

- Menus and the HUD use one shared panel rather than separate panels per eye.
- Analog motion-controller steering is experimental.
- The port hides overhead place numbers because they do not render correctly in stereo.
- If a race behaves strangely at high refresh rates, switch Virtual Desktop to 72 Hz.

## Links

- [Racer PCVR mod page](https://github.com/GameOrDie007/Star-Wars-Episode-I-Racer-PCVR)
- [Racer PCVR releases](https://github.com/GameOrDie007/Star-Wars-Episode-I-Racer-PCVR/releases)
- [Community improvement project](https://github.com/tim-tim707/SW_RACER_RE)

>>> Now this is podracing. Sebulba still thinks the track is his.

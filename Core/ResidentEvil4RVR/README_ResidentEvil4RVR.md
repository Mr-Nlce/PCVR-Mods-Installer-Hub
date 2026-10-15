# Resident Evil 4R VR

**REFramework** by **praydog**, with the **RE4VR** motion-control add-on by **Talemann** - turns **Resident Evil 4 (Remake)** into a cinematic, action-heavy VR horror experience. The village ambush, castle siege, and Regenerator encounters are especially intense in VR.

> This is an **external** mod. **Get Installer** starts the download of the author's own **RE4VR 2.1.5** setup (about 98 MB) straight from his site - he asks people to take it from there and nowhere else. The Hub records that the link was opened, not that the external setup completed.

## What you get
- Full VR conversion with head tracking and first-person gameplay enhancements
- **Full 6DOF motion controls** via Talemann's RE4VR add-on
- Optional quality-of-life Lua fixes, offered as part of the installer's setup

## Requirements
- You must **own Resident Evil 4 (Remake)** on Steam
- A PCVR-ready setup with a VR headset
- VR motion controllers (default bindings below)

## How to install
Press **Get Installer** on this game's page - the download starts right away. Run the setup and click Next; it drives itself from there.

**What the current publisher page says:** the setup finds your RE4 folder, removes leftovers from a previous mod install, asks for OpenVR or OpenXR and Steam or Meta, then installs the newest mod build. Its cleanup can remove other mods in the same game folder, so back them up first. Follow any game-version or prerequisite instructions shown by the external setup itself.

The publisher recommends a fresh Steam installation of Resident Evil 4. Both DLCs are optional. The Hub does not run or verify this separate setup, so use its own confirmation and the game's behavior to judge the result.

## If the controllers do nothing
ViGEm was probably just installed. **Restart your PC once.** Then make sure no other controller is connected or switched on before your VR controllers. And keep the game window focused - it stops responding when it loses focus.

## Performance - the resolution is not in the game
The in-game resolution has **no effect** in VR, and resolution is the single biggest lever on your framerate. Set it in your runtime instead:

- **OpenVR:** SteamVR overlay - VR Settings - Video - Render Resolution to *Custom*, then lower it until it plays smoothly
- **OpenXR:** the Meta app

## Graphics options
The mod forces several of these itself. Check them in the game's own settings if something looks wrong:

| | |
|---|---|
| Must be **Off** | Ray Tracing, Motion Blur, VSync, Lens Distortion, Lens Flare, Volumetric Lighting, Depth of Field |
| **Off** if something renders oddly | Screen Space Reflections, Ambient Occlusion |
| Forced | Antialiasing to *None*, FPS to *Variable* (uncapped) |
| Taste, not correctness | Subsurface Scattering, Contact Shadows, Bloom, Film Grain |

Full list: https://www.biohazardvr.com/#settings

**Rainbow, psychedelic colours when VR starts?** That is HDR: https://www.biohazardvr.com/re4#hdr

## Controls (Oculus / Meta Touch - RE4VR default bindings)
These are the official RE4VR default bindings (praydog mod + Talemann VR).

### Left Controller
| Button | Action |
|---|---|
| [[Left Stick]] | Move - click & hold = Run |
| [[Y]] | Open Inventory |
| [[X]] | Open Map; long press = command Ashley; Back / Cancel (menu) |
| [[Left Trigger]] | Quick Weapons (hold [[Left Trigger]] + right stick = shortcuts) |
| [[Left Grip]] | Ready Knife (hold); Two Hand Support (hold weapon) |

### Right Controller
| Button | Action |
|---|---|
| [[Right Stick]] | Turn - click = Toggle crouch / stand |
| [[B]] | Reload; Move Items (in inventory) |
| [[A]] | Interact / Pickup / Select (menu) |
| [[Right Trigger]] | Fire / Attack (when aiming); Attack (quick knife); Parry (when attacked / grabbed) |
| [[Right Grip]] | Ready Aim (hold) |

> Two-handed weapon support: hold [[Left Grip]] near the gun to grab it as a second hand.

## Credits
- REFramework by **praydog** (also behind UEVR) - https://github.com/praydog/REFramework
- RE4VR motion-control add-on by **Talemann**
- Community setup guide: https://www.biohazardvr.com/re4
- Original game by Capcom

## Support the developer
praydog develops REFramework. If you enjoy his work, consider supporting him:
- Patreon: https://www.patreon.com/c/praydog

>>> No straight answers, stranger. Just you, Leon, and the village.

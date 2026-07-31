# Quake 2 VR

**Quake 2 VR v2.0.0** by **Luke Groeninger** and **Malcolm Smith** — a KMQuake II-based VR port of **Quake II** with a VR HMD view, decoupled view/aiming, comfort turning, and gamepad / Oculus Touch input.

> **Runtime note:** Q2VR targets the **Oculus / Meta runtime** (LibOVR), not SteamVR natively. It launches in VR directly only on an **Oculus Rift** or a **Meta Quest connected via Link cable / AirLink**. A Quest over **Virtual Desktop** or **Steam Link**, and every **non-Oculus headset** (Valve Index, HTC Vive, Pico, WMR), needs **Revive** to run it. The installer asks which applies and, for the Revive case, downloads + installs Revive and builds a ready-to-use desktop shortcut that launches the game through Revive's injector.

## Launching
- **Rift / Quest via Link or AirLink:** start the Oculus / Meta app, then launch with **Start in VR** in the Hub or the **Quake 2 VR** desktop shortcut (both run `quake2vr.exe` directly).
- **Virtual Desktop / Steam Link / non-Oculus headset (Revive):** start **SteamVR**, then run the **Quake 2 VR** desktop shortcut — it points at `ReviveInjector.exe` with `quake2vr.exe` as its target, which is the same thing as dragging the EXE onto the injector or using the Revive tray's **Add a shortcut**.
- If VR does not start automatically, open the console with **~** (tilde) and type `vr_enable`.
- In **Options -> VR**, set the aim mode and comfort options (see below).

## Controls
Q2VR is built around a **gamepad** (Xbox / XInput) — Oculus Touch can also be used **as a gamepad**, and, with **VR Controller Support** enabled (default), the Touch controllers aim weapons by **orientation** (no positional weapon tracking).

| Input | Action |
|-------|--------|
| Left stick | Move / strafe |
| Right stick | Turn / aim (depends on aim mode) |
| Right trigger | Fire weapon |
| D-Pad Left / Right | Comfort snap turn (45°, on by default) |
| Face buttons | Jump / use / weapon switch (standard Quake II gamepad layout) |
| ~ (keyboard) | Console (e.g. `vr_enable`) |

**Suggested setup:** `AimMode = Decoupled View/Aiming`. With Oculus Touch, enable **VR Controller Support** for orientation aiming; with a plain gamepad, leave it off and keep **Comfort Turning** on so the D-Pad gives you snap turns. There are many more options under **Options -> VR** (supersampling, auto-crouch, etc.).

## What it installs
Two editions are offered at install time:
- **[1] Binaries only** — the VR build, no HD textures. Downloaded automatically from the official GitHub release.
- **[2] Full / HD textures** — HD model + world textures, music and mods. Hosted on **MEGA**, which cannot be scripted, so the installer opens the page; you download the package and drag the `.zip` into the installer window. This edition also bundles the **Ground Zero** and **The Reckoning** add-on launchers.

Either way the installer then copies **pak0.pak** (and, if present, `players\` and `videos\`) from your **Quake II** install into the q2vr `baseq2` folder. For the full edition, if your Quake II also has the **Ground Zero** (`rogue`) and **The Reckoning** (`xatrix`) data, the installer copies their `pak0.pak` in too, so the add-on launchers work right away. Any add-on whose data is missing is simply left out — it never affects the base game.

## Requirements
- **Quake II** owned and installed — Steam **AppID 2320** (folder `Quake 2`), or GOG (**Quake II Enhanced**). The classic `baseq2\pak0.pak` is what KMQuake II needs.
- A VR headset:
  - **Oculus Rift** or **Meta Quest via Link / AirLink** — runs directly on the Oculus runtime.
  - Anything else (Quest over Virtual Desktop / Steam Link, Valve Index, HTC Vive, Pico, WMR) — needs **Revive** + **SteamVR**. The installer sets this up for you.
- 32-bit MSVC 2012 runtime (most systems already have it)
- A gamepad or Oculus Touch controllers

## Troubleshooting
- No VR at launch: open the console (`~`) and type `vr_enable`. It will try to use the headset display, falling back to the primary monitor.
- Revive shortcut does nothing: make sure **SteamVR is running first**, then launch the shortcut. As a fallback, drag `quake2vr.exe` onto `ReviveInjector.exe` in `C:\Program Files\Revive`, or use the Revive tray icon's **Add a shortcut**.
- Missing data: ensure `baseq2\pak0.pak` exists in the install folder. The installer copies it from your Quake II install; you can also copy it by hand.
- Aim modes marked with `*` in the VR menu (mouse pitch) are broken in multiplayer — avoid them online.

## Credits & sources
- **Quake 2 VR** by Luke Groeninger (project) and Malcolm Smith (this release) — based on KMQuake II, incorporating work from RiftQuake; **Quake II** by id Software
- Project page: http://www.malcolm-s.net/q2vr/
- Binaries download: https://github.com/q2vr/quake2vr/releases/download/v2.0.0a/Quake2VR-2.0.0-bin.zip (fallback mirror: a web.archive copy, plus the author's non-MEGA HTTP host http://www.malcolm-s.net/q2vr/Quake2VR-2.0.0-shareware.zip)
- **Revive** by LibreVR (Oculus-to-OpenVR layer): https://github.com/LibreVR/Revive — installer v3.2.0
- Launch executable `quake2vr.exe`; base data `baseq2\pak0.pak`; Quake II Steam AppID **2320**

>>> Strogg ahead. Rail the Big Gun and take the fight to Stroggos.

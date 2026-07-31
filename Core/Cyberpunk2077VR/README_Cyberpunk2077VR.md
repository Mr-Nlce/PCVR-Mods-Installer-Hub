# Cyberpunk 2077 VR

**CyberpunkVRPort** by **dariulone** — an OpenXR `dxgi.dll` VR proxy for **Cyberpunk 2077** with **6-DoF motion-controlled VR hands** (full-arm VRIK), head tracking with in-engine camera injection, and an in-headset **F10** settings overlay. The installer always pulls the **latest release** from GitHub (the mod updates often), falling back to the known-good v0.0.6 build if GitHub can't be reached.

> Repository: https://github.com/dariulone/cyberpunk-vr-port

## Launching
1. **Start your OpenXR runtime first** — Virtual Desktop / VDXR, SteamVR, etc. — **before** launching the game.
2. Launch **Cyberpunk 2077** normally (Steam, GOG, or the Hub's **Start in VR**). The `dxgi.dll` proxy loads with the game.
3. In-game: **F10** opens the VR settings overlay, **F7** recenters.

If the game opens as a flat desktop window inside the headset, check `bin\x64\cyberpunkvrport.log` for the selected OpenXR runtime.

## Features
- Direct OpenXR integration inside the REDengine render path (Mono + AER).
- Head tracking with in-engine camera injection and runtime FOV-based projection handling.
- Motion-controlled VR hands with full-arm VRIK (VRArmIK-style elbow-swivel heuristic).
- In-headset **F10** overlay with separate tabs:
  - **VRIK** — start/stop hand tracking, live IK calibration (per-hand reach scale, height, elbow swing, elbow pole, wrist rotation offset), Log VR Diag.
  - **HUD** — live VR HUD layout (per-element X / Y / Size on one compact row).
  - **Debug Gizmos** — hand overlay / proxy / debug axes / locator scale.
  - **Tracking / Camera** — movement-control mode and recenter.
- Head-oriented locomotion — optional **Movement Control: HMD** so on-foot movement follows where you look (driving is untouched).
- SteamVR (OpenVR) runtime support, selectable alongside OpenXR.
- Pre-launch render-resolution selector.
- Runtime/hardware diagnostics in the log (OpenXR runtime + system, GPU model + driver, swapchain init, frame-pipeline events).
- Verbose-log toggle — quiet by default for clean tester reports; deep per-frame diagnostics sit behind one checkbox.

## Controls
Motion-controlled VR hands driven directly by the controllers, with a full shoulder → elbow → hand IK chain. Weapons are tracked while held.

| Input | Action |
|-------|--------|
| Motion controllers | 6-DoF VR hands (aim / interact / hold weapons) |
| [[F10]] | In-headset VR settings overlay (VRIK / HUD / Debug / Tracking tabs) |
| [[F7]] | Recenter view |

Open **F10 -> VRIK** to start hand tracking and calibrate per-hand reach scale, height, elbow swing/pole and wrist offset. Optional **Movement Control: HMD** makes on-foot movement follow where you look (driving is untouched).

## What it installs
This is an **in-place mod** — it overlays files into your existing Cyberpunk 2077 folder:
- `bin\x64\dxgi.dll` — the OpenXR VR proxy (camera / stereo)
- `bin\x64\openvr_api.dll` — used only for the SteamVR path
- `red4ext\plugins\CyberpunkVR_Hands\CyberpunkVR_Hands.dll` — the hand-tracking plugin
- `bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_VRIK\` and `...\CyberpunkVRPort_HUD\` — the VRIK + HUD mods

The full hands/HUD experience needs two frameworks; the installer adds them **only if they are missing**:
- **RED4ext** (v1.30.0) — loads `CyberpunkVR_Hands.dll`
- **Cyber Engine Tweaks / CET** (v1.37.1) — runs the VRIK + HUD mods

Camera/stereo VR works from the `dxgi.dll` proxy alone; the motion-controlled hands and VR HUD need RED4ext + CET.

## Requirements
- **Cyberpunk 2077** (PC) — Steam **AppID 1091500** (folder `Cyberpunk 2077`) or GOG (**Cyberpunk 2077**)
- An OpenXR runtime (Virtual Desktop / VDXR, SteamVR, PICO, ...) — started **before** the game
- Motion controllers for the VR hands

## Recommended settings (first launch)
Cyberpunk 2077 is **very** demanding in VR — these settings keep performance from collapsing.

**VR configuration window** (appears on first launch, once the mods are added):
- **VR Runtime:** pick yours. OpenXR (Virtual Desktop) suits most setups.
- **Resolution:** do **not** go too high — the game is heavy. **2560 x 2560** is a good target for most.

**In-game graphics settings:**
- **Quick Preset:** Low (Medium at most)
- **Resolution Scaling:** Off
- Turn **Off**: Ray Tracing, Frame Generation, Film Grain, Chromatic Aberration, Depth of Field, Lens Flare
- Press **Apply** when done
- **Video -> Gamma Correction:** nudge it down a little (the image is otherwise a bit too bright)

**In game (F10 VR menu):**
- Use **Mono** for now — **AER** currently has very poor performance.
- **VRIK** tab: enable VR hand tracking and adjust hand position. The **hand overlay** is on by default so you can line your hands up; once it fits, turn it off under **General -> Enable Hand Overlay**.

It's a lot of toggles, but after this it should run great.

## Troubleshooting
- Flat window in the headset: confirm the OpenXR runtime is running first; check `bin\x64\cyberpunkvrport.log`.
- To force the SteamVR (OpenVR) path: set `xr_runtime=1` in `bin\x64\vrport.ini` and restart.
- Hands look wrong / not tracking: open **F10 -> VRIK**, start hand tracking, and calibrate. Make sure RED4ext + CET are installed.
- Mouse fights head pitch: the overlay's **Disable Mouse-Y** toggle is on by default.

## Credits & sources
- **CyberpunkVRPort** by dariulone — https://github.com/dariulone/cyberpunk-vr-port (latest: https://github.com/dariulone/cyberpunk-vr-port/releases)
- **RED4ext** by WopsS — https://github.com/wopss/RED4ext
- **Cyber Engine Tweaks** by maximegmd — https://github.com/maximegmd/CyberEngineTweaks
- **Cyberpunk 2077** by CD PROJEKT RED; Steam AppID **1091500**

>>> Wake up, samurai. Night City won't burn itself down.

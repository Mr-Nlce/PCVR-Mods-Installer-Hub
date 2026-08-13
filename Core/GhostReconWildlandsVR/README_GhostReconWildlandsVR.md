# Ghost Recon Wildlands VR

## About this mod
**GRW-XR** by Firejumper93 is a native OpenXR VR mod for Tom Clancy's Ghost Recon Wildlands. The game's own AnvilNext 2.0 engine renders head-tracked stereoscopic 3D, injected through a `dxgi.dll` proxy that sits beside the game. No game file is ever modified.

*Sync up, Ghosts - Bolivia in stereo.*

https://github.com/Firejumper93/GhostReconWildlandsVR

## This is an alpha - read this first
It is **not a complete VR experience**. Stereo depth and a fullscreen view work, but this is a development snapshot and every release changes things.

> **The August 2026 game patch (Ubisoft "Last Rites") replaced `GRW.exe`.** The mod
> refuses to touch an executable it does not recognise, so older mod builds simply
> ran flat on the patched game - no crash, no risk, no VR either. Release
> **v0.7.0-alpha** re-derived every engine address against the new executable and
> was verified in the headset on 2026-08-08. The Hub always installs the newest
> release, so you get this by itself.

**Working today**
- Native OpenXR session on the game's own D3D11 device, paced by the headset at 72 Hz
- Full head tracking driving the real game camera, with stereoscopic depth via alternate-eye rendering
- Fullscreen view - the mod overrides the rendered field of view (default 1.92 rad, about 110 degrees) so the image fills the headset instead of floating as a window
- Working scopes: while scoped the mod steps aside, so the optic renders exactly as in the flat game and bullets land on the crosshair. Magnified optics are shown across a comfortable window so they actually magnify
- First-person demo mode, a toggleable camera push that puts the view at the character instead of behind them

**Not there yet**
- **No motion controls.** You play on a gamepad. Aiming from the hip and in ADS follows the game's own aim, not your view, so the true ballistic aim point drifts from your crosshair until the game catches up. While scoped, ballistics are exact.
- **Hiding your head in first person is broken right now.** The game patch recompiled the engine function behind it and its signature no longer matches; rather than guess an address, the mod switches the feature off. You will see hair or a helmet from inside until it is re-derived. The author calls it the top priority for the next release.
- **Two things are awaiting re-verification** after the patch changed weapon handling: the head-bone anchor that follows stand / crouch / prone, and the weapon-identification readings (off by default). If either misbehaves, that is why - report it with your `GRWVR\grwxr-<pid>.log`.
- Wide-angle rendering can look warped toward the edges; the projection geometry is still being tuned.
- First person is a demo: edge culling pop, visible hair and eyelashes, vehicle cabins the camera cannot reach yet. No first-person body rig.
- Tested on exactly one configuration: Meta Quest 3 over Link cable with the Meta Quest Link runtime, RTX 5060 Ti 16 GB, Ryzen 7 9700X. Other headsets and runtimes are untested.

## Solo campaign only
The game ships **Easy Anti-Cheat** for multiplayer. Never run this mod in co-op, PvP or matchmaking. Playing in offline mode (Steam offline, or Ubisoft Connect set to offline) is recommended while the mod is this young.

## What you need first
- Ghost Recon Wildlands, **Steam or Ubisoft Connect**. Since the August 2026 patch both stores ship the byte-identical executable, so one verified address table covers both. Epic is not covered by the author.
- A PC VR headset with an OpenXR runtime.
- **Asynchronous Spacewarp disabled** (Oculus Debug Tool, ASW = Disabled). The mod manages the stale eye itself and ASW compounds artifacts on top of it.
- **FSR upscaling OFF.** The patch added it, and it sits inside the render path the mod manages - untested there.
- The patch's new immersion toggles (reduced highlight glow, throwable sightline preview off, hidden-UI sounds) are fine and recommended in VR.
- A GPU with headroom.

## Before you launch
- Motion blur **off**.
- Window mode **fullscreen or borderless fullscreen** - a bordered window locks the game to your monitor's refresh rate.
- Anti-aliasing is your preference; SMAA and TAA both work under the stereo setup.
- Put the headset on so it is awake and tracking **before** launching - the VR session is created once, at startup.
- Then launch through Steam. The proxy loads itself; there is no launcher.

## Reading the log: the two lines that matter
The log in `GRWVR\` has a heartbeat, `hb <n> frames=<n>`. That frame counter is the game's, not the mod's, and it separates the two things that go wrong here:

- **`frames=0` or `frames=1` minute after minute** - the game is not drawing. The mod is only waiting; whatever is stalling happens before it ever gets a frame. Wildlands hanging on its small startup window (a few hundred pixels wide, visible in the log as `render window found: ... 466 x 310`) is a Ubisoft Connect problem, not a VR one.
- **`VR: runtime = ...` followed by `no headset available (XrResult -35)`** - the OpenXR runtime answered, but no headset was connected at that moment. XrResult -35 means the runtime has no usable headset right now.

The second one is the trap on this game: VR is initialised **on the first frame the game draws**, not when you press Launch. If the game needs ten minutes to get there, your headset and your streaming session have to still be live ten minutes later. With Virtual Desktop that means the VD streamer must still be connected; with Quest Link, the Link session. A headset that went to sleep during the wait produces exactly this error, and then the mod turns VR off.

## Black screen, then a crash a few seconds in
The mod installs its own crash reporter, so a crash leaves evidence. Look in `GRWVR\` inside the game folder: `grwxr-<pid>.log` plus whatever the reporter wrote. The log is written in phases (`Phase 1: load and log only`, `phase 2: installing D3D11 Present hook`, `phase 2 hook installed. Waiting for the first Present.`), so the last phase reached says how far it got before it died.

One thing to rule out first, because it costs nothing: **the headset has to still be awake when the game actually finishes loading**, not just when you click Launch. The VR session is created once, at startup. Wildlands can take a very long time to reach its menu, and a headset that went to sleep during that wait leaves the mod with a session that never becomes ready. Keep the headset on your head or moving until the game is up.

This is an early alpha tested on exactly one machine. If the log shows the mod reaching its VR setup and dying there, that is a report for the author rather than something to fix locally - the GitHub issue form asks for the headset, runtime, GPU, mission and the relevant log lines, which is exactly what the log gives you.

## If the game hangs on the splash screen forever
First, separate the mod from the game - it takes two minutes and tells you which side to look at:

1. Turn the mod off with the **Flat / VR switch** on this game's page in the
   Hub. It does exactly what the author's own disable switch does - it renames
   `dxgi.dll` to `dxgi.dll.off` - so nothing has to be renamed by hand, and one
   click puts it back.
2. Start the game normally.

Still stuck on the splash? Then it is not the VR mod. Wildlands needs Ubisoft Connect, and a sign-in that cannot complete hangs exactly there - check Ubisoft Connect, and whether it is set to offline while the game wants to reach the servers.

Runs fine without the mod? Then the log has the answer. It sits in `GRWVR\grwxr-<pid>.log` inside the game folder, and its **last line** is what matters:
- `session never reached READY` - the headset was asleep or the runtime was not up when the game launched. Put the headset on first, then start.
- `no headset available` - the runtime is there but no headset is connected.
- `camera: 0 matches` - the signature scan did not find the engine's camera; that happens after a game update and needs a new mod build.
- `waiting for a render window` as the last line - the mod is still waiting for the game to open its window, so the game itself has not got that far.

Worth knowing: when the mod's VR setup fails it writes `VR disabled, game unaffected` and lets the game run flat. A permanent hang is therefore not its normal failure path - which is why the test above is the fastest way to find out where the problem really is.

## If the game does not start at all
No window, no error, nothing happens - that is almost always `dxgi_real.dll`. The mod is a `dxgi.dll` proxy that forwards every call to the real Windows library, and that forwarding copy has to be **64-bit**, like the game. A 32-bit copy makes the proxy fail to load and the game exits before it draws anything.

Check the file in your Wildlands folder: right-click `dxgi_real.dll` > Properties > Details should show the same architecture as `GRW.exe`. If in doubt, delete `dxgi_real.dll` and run the installer again - it now takes the copy from the folder matching the game and verifies the result.

To rule the mod out entirely, rename `dxgi.dll` to `dxgi.dll.off` and start the game. If it runs then, the problem is on the mod side, not with your game install.

## Keys in the headset
| Key | Action |
|---|---|
| [[Home]] | Recenter - look where forward should be, then press |
| [[Numpad 9]] / [[Numpad -]] | Eye separation + / - (0.05 steps) |
| [[Numpad *]] | Reset eye separation to the startup value |
| [[Numpad 1]] | Fullscreen field-of-view override on / off |
| [[Numpad +]] / [[Numpad 2]] | Field of view wider / narrower (0.10 rad steps) |
| [[Numpad 8]] | First-person demo mode on / off |
| [[Numpad 7]] / [[Numpad 4]] | First-person camera forward / back (0.10 m) |
| [[Numpad 6]] / [[Numpad 5]] | First-person camera right / left (0.10 m) |
| [[Numpad 3]] / [[Numpad 0]] | First-person camera up / down (0.10 m) |
| [[Numpad /]] | Desktop recording view on / off (experimental) |

Every tuning key prints the exact `grwxr.cfg` line for its current value into the log, so you can make a setting permanent.

## Config file
`GRWVR\grwxr.cfg` in the game folder. All keys optional, defaults in brackets.

| Key | Meaning |
|---|---|
| `ipd_scale` (1.0) | Eye separation multiplier. 0.50 is the author's tuned value |
| `fullscreen_fov` (1.92) | Overridden vertical field of view, in radians |
| `mono_scope_fov` (0.30) | Below this rendered FOV the mod steps aside for a flat scope. 0 disables |
| `scope_display_fov` (0.5236) | Display size of magnified scope content. 0 = angle-correct |
| `fp_forward` (2.20) | First-person forward camera push, metres |
| `fp_side` (-0.40) | First-person sideways offset, cancels the over-shoulder camera |
| `fp_up` (0) | First-person vertical offset |
| `desktop_fov` (0.90) | Field of view of the desktop recording view, radians |

The mod also writes a per-process log to `GRWVR\grwxr-<pid>.log`.

## Switching VR off
Rename `dxgi.dll` in the game folder, e.g. to `dxgi.dll.off`. The game then runs completely unmodified. Rename it back for VR.

## Credits
- **GRW-XR** by Firejumper93 - https://github.com/Firejumper93/GhostReconWildlandsVR
- Ported from **mutars/anvilengine2vr** (MIT), with technique guides from **elliotttate/vrframework**, and diagnostics informed by **dariulone/cyberpunk-vr-port** (MIT) and **pancreations/Halo-MCC-VR** (MIT)
- Khronos OpenXR SDK (Apache 2.0)
- Ghost Recon Wildlands is the property of Ubisoft. This project is not affiliated with, endorsed by or supported by Ubisoft.
## Key points from updates
- **Steam build only.** The Epic and Ubisoft Connect copies are a different
  executable, and every engine address this mod uses belongs to the Steam
  build. There it installs nothing, leaves your game untouched, and you get a
  small flat window with no head tracking - controllers may still respond,
  which makes it look half-working. It is not. The line "This is NOT the
  binary we analysed" in `GRWVR\grwxr-<pid>.log` confirms it.
- **Singleplayer only.** Solo campaign, never co-op, never PvP, never
  matchmaking - the game ships Easy Anti-Cheat for multiplayer.
- **The controllers are an emulated gamepad**, not motion control: sticks,
  triggers, grips and buttons become ordinary gamepad input, so no physical
  pad is needed. Aim direction from the right controller is the only tracked
  input beyond your head - there is no weapon in your hands, aim chases the
  controller rather than tracking it, and aiming down sights hands aiming back
  to your head.
- Fullscreen head-tracked stereo with real depth, true first person with the
  close-range body blur removed.
- **Set these before judging it:** fullscreen window mode (a bordered window
  caps VR at 60), frame limit 72, supersampling 0.90, SMAA or no
  anti-aliasing - **never TAA**. ASW off in the Oculus Debug Tool. The game
  rewrites GRW.ini when you apply menu changes.
- Three hotkeys: Home recenters, Numpad 8 toggles first person, Numpad . head
  aim. Everything else lives in `grwxr.cfg` and reloads about a second after
  saving; `cfg_gui.exe` is a slider editor for it.

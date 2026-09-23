# Ghost Recon Wildlands VR

**GRW-XR** by Firejumper93 is an experimental native OpenXR conversion for
Ghost Recon Wildlands. It uses the game's own D3D11 renderer for head-tracked
stereo, adds a true first-person camera and lets the weapon follow the right
controller. The game itself is not modified; the hook is a recoverable
`dxgi.dll` proxy beside `GRW.exe`.

## Current release and the September 15, 2026 update

GRW-XR v0.11.2-test1 delays VR initialization until the game produces real
frames and adds a black-screen diagnostic path that can fall back to flat mode.
The mod still uses engine addresses tied to exact Wildlands executables, so this
test build is not proof that every later Ubisoft executable is supported.

The installer therefore offers two independent routes:

- **Current:** the normal Steam or Ubisoft Connect installation plus the newest
  GRW-XR prerelease. This remains the right choice after the author publishes a
  release compatible with the September 15 game update.
- **Build 24821571:** a separate Steam depot copy of the last verified game
  build plus pinned GRW-XR v0.11.1. The normal Steam folder is not overwritten.
  This route contains the English or German base campaign; paid DLC depots are
  not part of the Hub download.

If Steam still has build 24821571 locally, setup can verify `GRW.exe` and clone
that complete installation into the separate route. Otherwise it guides you
through the pinned Steam Console downloads. The depot needs roughly 62.3 GiB
of downloads and about 77.3 GiB once assembled.

## Current capabilities and limits

- Fullscreen head-tracked stereo with alternate-eye rendering and configurable
  field of view.
- True first person follows standing, crouching and prone; the local head is
  hidden in the current build.
- The weapon pose follows the right controller and supports a two-hand hold.
- Magnified scopes use a comfortable overlay and current shots pass through it
  correctly.
- Controller buttons are translated to normal gamepad input. There are no
  rendered hands, physical reloads or gesture interactions.
- Hip-fire ballistics still follow the game's aim rather than a fully physical
  muzzle. Aiming through the game's sights remains the accurate route.
- Wide-angle edges, vehicles and some body presentation remain experimental.

## Solo and private co-op only

Use GRW-XR only in singleplayer or a private co-op session. Do not enter PvP or
public matchmaking with the proxy installed. The safest test route is offline
solo play, especially after a game update.

## Before launching

- Put the headset on and make the intended OpenXR runtime active before the game
  reaches its first rendered frame.
- Disable Asynchronous Spacewarp and FSR while establishing a stable baseline.
- Leave the game windowed; the mod prevents exclusive fullscreen because that
  path can black-screen a lower-resolution desktop.
- Turn motion blur off. Start with conservative supersampling and SMAA.

For the pinned route, start **Ghost Recon Wildlands VR 24821571** from the
desktop shortcut or `Start Ghost Recon Wildlands VR Depot.bat`. Steam and
Ubisoft Connect must both be running and signed in. The launcher supplies the
normal Steam-mode argument while keeping the historical files outside Steam's
automatically updated game folder. Because Wildlands authenticates online, a
future Ubisoft backend change can still make an old client unusable even when
its local files remain intact.

## Useful controls

| Button | Action |
|---|---|
| [[F1]] | Open or close the controller-driven settings panel |
| [[F2]] | Toggle first person and recenter |
| [[Home]] | Recenter the view |
| [[Numpad .]] | Toggle 1:1 head aim |
| [[Numpad /]] / [[Numpad *]] | Make the world larger / smaller |
| [[Insert]] | Cycle the live-tuning setting |
| [[Page Up]] / [[Page Down]] | Raise / lower that setting |
| [[Delete]] | Reset that setting |
| [[End]] | Start the guided test run |

`Numpad 0` through `Numpad 9` load complete preset files from
`GRWVR\presets`; an accidental press can therefore change several settings at
once. The live configuration is `GRWVR\grwxr.cfg`.

## Logs and troubleshooting

Run `GRWVR\Collect-Logs.bat` and include its ZIP in a report. A log ending in
`no headset available` means the runtime had no awake headset when VR was
created. A `camera: 0 matches` result usually means a new game executable needs
a matching mod update. If the game hangs even with the Hub's Flat / VR switch
set to Flat, investigate Ubisoft Connect rather than the VR proxy.

## Updates and removal

The Current installer obtains the newest GitHub prerelease. The Build 24821571
route always uses GRW-XR v0.11.1 and never resolves a newer mod into that pinned
game copy. Both preserve an existing `grwxr.cfg`, record their own path and
install version, and keep file ownership recoverable. The Flat / VR switch
parks only the proxy.

**Uninstall now** asks which route to change when both coexist. It removes only
unchanged Hub-owned files and restores any previous proxy without touching
saves or unrelated files. Removing GRW-XR from the depot does not delete its
large historical game-data copy; delete that dedicated folder manually only
when you no longer want it.

## Credits

- GRW-XR: https://github.com/Firejumper93/GhostReconWildlandsVR
- Built with OpenXR and work derived from the credited open-source VR projects.
- Ghost Recon Wildlands belongs to Ubisoft; this community project is not
  affiliated with or supported by Ubisoft.

*Sync up, Ghosts - Bolivia in stereo.*

# Grand Theft Auto V VR

<!-- hub:keep-order -->

Two independent VR setups for your own copy of **Grand Theft Auto V
Legacy**. The current **GTAVR by DeployAbi** is option 1 and adds motion
controls. The older **R.E.A.L. r7 + VRV patcher** remains available as
option 2 for existing users and gamepad play. This entry is **not** for
GTA V Enhanced.

## Option 1 - Current GTA V Legacy - GTAVR by DeployAbi (recommended)

This is the current-build route confirmed by the author in the Flat2VR
thread on **9 September 2026**. The release adds Virtual Desktop support,
motion-controller support and POV support. The author also confirmed that
it works with the then-current Steam version and requires only the single
`GTAVR-Setup-and-Play.exe` download plus your installed game.

The mod is still experimental. Its own executable identifies the motion
gameplay as unverified work in progress, checks the installed GTA build
before activation and stays inert on an unsupported build instead of
injecting with unknown offsets.

### Requirements

- **Grand Theft Auto V Legacy**, Story Mode only. Steam, Epic and Rockstar
  locations are searched; any other valid location can be supplied.
- A working **OpenXR** runtime. Virtual Desktop users select **VDXR** in
  Virtual Desktop Streamer.
- BattlEye disabled and no GTA Online session. This is a Story Mode mod.
- Run GTA and the author launcher as a normal Windows user, not as
  administrator. The launcher's own runtime check warns that an elevated
  game cannot honor its process-local OpenXR selection.

### What the Hub installer does

1. Finds the folder containing `GTA5.exe`.
2. Opens the Flat2VR invite, information thread and Discord download
   post when the reviewed file is not already in Downloads or Archive Input.
3. Rejects HTML/login responses and requires a usable Windows executable;
   changed future builds are not blocked by historical filename, size,
   metadata or checksum values.
4. Keeps the launcher copy under
   `VRLaunch\DeployAbi\GTAVR-Setup-and-Play.exe` and opens it without UAC.
5. You click **Install / Update Everything** in the author window. The Hub
   then requires `gtavr_install_manifest.txt`, `version.dll`, `OVRInject.dll`
   and `GTAVRBridge.asi` before it records VR Ready.

The executable is **not digitally signed**. The Hub never bundles or silently
substitutes it; it validates transport and the files actually installed rather
than rejecting future author builds against a historical fingerprint. The
author launcher contains the VR payload and obtains its own prerequisites.

### Playing and controls

Use **Play GTAVR Motion** on the game page. The Hub parks the older R.E.A.L.
hooks, enables DeployAbi and opens the same author launcher. Click **Play
Story Mode** there.

| Button | Action |
|---|---|
| [[Motion controllers]] | Gameplay movement, buttons and experimental controller aiming |
| [[Delete]], [[F10]] or [[Insert]] | Open or close the in-headset setup overlay |
| [[F11]] | Export the performance report |

The overlay contains the controller bindings, hand alignment, camera,
graphics and runtime settings. Keep both controllers in a comfortable neutral
pose when calibrating hands. The release offers gamepad movement with motion
buttons as a hybrid mode as well as motion-controller gameplay.

The author app stores its settings and logs in `%LOCALAPPDATA%\GTAVR`. This
is behavior of the external mod launcher, not a relocation of the portable
Hub's own data.

## Option 2 - R.E.A.L. r7 plus VRV patcher (older alternative)

This route installs Luke Ross's **R.E.A.L. r7**, ScriptHookV and a community
VRV compatibility patcher. It is retained for existing setups and offers a
gamepad/OpenXR launcher plus the former optional `GTAVR.asi` motion overlay.
Compatibility depends on the exact GTA V Legacy build; option 1 is the
recommended current route.

### Requirements and installation

- Start GTA V Legacy once into Story Mode and close it before installing.
- The installer downloads ScriptHookV and the newest SanguShellz VRV patcher,
  with Francisco Manzanilla's pinned build as the antivirus fallback.
- It runs `RealConfig.bat`, lets you choose a graphics preset and locks the
  generated `settings.xml` read-only so GTA cannot immediately replace the
  square VR resolution.
- The optional older motion overlay is downloaded manually and contributes
  only `GTAVR.asi`; its incompatible `openvr_api.dll` is not copied.

### R.E.A.L. launch choices

- **Play R.E.A.L. Gamepad** selects OpenXR (`VRAPI = 3`) and parks the old
  motion overlay.
- **Play R.E.A.L. Motion** selects OpenVR (`VRAPI = 2`) and enables
  `GTAVR.asi`. This older overlay remains work in progress.

For R.E.A.L., turn off Steam's **Use Desktop Game Theatre while SteamVR is
active** option. Aiming is normally head-driven. Shake your head briefly from
side to side to recenter; in a vehicle, the look-behind action realigns the
car view.

R.E.A.L. hotkeys are disabled at startup. Press [[F11]] once to enable them:

| Button | Action |
|---|---|
| [[F11]] | Enable or disable R.E.A.L. hotkeys |
| [[Num /]] | Recenter headset |
| [[Num 0]] | Toggle position tracking |
| [[Num 2]] | Toggle alternate-eye stereo |
| [[Num .]] | Change zoom override |
| [[T]] | Select dominant aiming eye |
| [[Y]] | Change heading control |
| [[U]] | Toggle pitch control |
| [[I]] | Toggle decoupled third-person camera |
| [[End]] | Toggle vehicle-view gyro stabilization |

## Switching when both setups are installed

Both generations may remain on disk. Use only the Hub's named play buttons:

- Selecting **GTAVR Motion** renames `RealVR.asi` and `GTAVR.asi` to their
  reversible `.off` forms, then removes the author's `gtavr.disabled` marker.
- Selecting either **R.E.A.L.** mode restores `RealVR.asi` and creates
  `gtavr.disabled`, the inert marker recognized by DeployAbi's own loader.
- Nothing is deleted while switching. A running `GTA5.exe` blocks the change,
  so two hook generations can never be changed under a live game process.

Launching `PlayGTAV.exe` or GTA directly bypasses this protection. When both
mods are installed, always start the desired VR route from the Hub.

## Updating

DeployAbi releases are Discord attachments and have no public release API. A
Hub updateround reviews the post, attachment and subsequent author notes; a
new reviewed attachment then changes the release-proof marker
and produces an Update badge only for an installed DeployAbi setup.

The older VRV patcher continues to resolve its GitHub release at install time.
Its GitHub update check is scoped to `RealVR.asi`, so it cannot raise an update
for somebody who installed only DeployAbi.

## Safe removal

For DeployAbi, open
`VRLaunch\DeployAbi\GTAVR-Setup-and-Play.exe` and use its own **Uninstall**
action. It owns `gtavr_install_manifest.txt` and removes its recorded payload.

For the older R.E.A.L. route, compare against its installed package and remove
only its files: `RealVR.ini`, `RealVR.asi` or `RealVR.asi.off`, the `asi`
folder, `RealRepo`, `RealConfig.bat` and its launch files. Restore a
package-created `settings_ori.xml` if one exists. `ScriptHookV.dll`,
`dinput8.dll` and `openvr_api.dll` are shared loader names; verify ownership
before removing them. Never delete GTA V, its whole folder, saves or Rockstar
profile data merely to remove a VR mod.

## Support and credits

- Flat2VR Modding invite: https://discord.gg/uAeQkYBM4n
- GTAVR information and support thread: https://discord.com/channels/747967102895390741/1545350924237668453
- Reviewed GTAVR download post: https://discord.com/channels/747967102895390741/1545350924237668453/1547246592376053770
- **GTAVR Setup and Play** by DeployAbi / Sauce; support: https://ko-fi.com/deployabi
- **R.E.A.L. VR mod** by Luke Ross: https://www.patreon.com/realvr
- **GTA-VRV-Patcher fork** by SanguShellz: https://github.com/SanguShellz/GTA-VRV-Patcher
- Original compatibility patcher by Francisco Manzanilla: https://github.com/FranciscoManzanilla/GTA-VRV-Patcher
- **ScriptHookV** by Alexander Blade: https://dev-c.com/gtav/scripthookv/

>>> Pull off the heist, outrun the stars, and own the streets of Los Santos.

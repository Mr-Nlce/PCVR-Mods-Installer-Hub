# Grand Theft Auto V VR

<!-- hub:keep-order -->

## About the Game

Two independent VR setups for your own copy of Grand Theft Auto V
Legacy. The current GTAVR by DeployAbi is option 1 and adds motion
controls. The older R.E.A.L. r7 + VRV patcher remains available as
option 2 for existing users and gamepad play. This entry is not for
GTA V Enhanced.

## Option 1 - Current GTA V Legacy - GTAVR by DeployAbi (recommended)

This is the current-build route now published on [DeployAbi's GitHub releases](https://github.com/DeployAbi/GTAVR/releases).
The Hub follows the prerelease channel so its update indicator tracks the
same current test builds as the installer. The release adds Virtual Desktop support,
motion-controller support and POV support. The author also confirmed that
it works with the then-current Steam version and requires only the single
`GTAVR-Setup-and-Play.exe` download plus your installed game.

The mod is still experimental. Its own executable identifies the motion
gameplay as unverified work in progress, checks the installed GTA build
before activation and stays inert on an unsupported build instead of
injecting with unknown offsets.
The reviewed `v0.11.19-ffb-test` prerelease requires GTA V Legacy
`1.0.3889.0`; later GitHub releases may document another supported build.

### Requirements

- Grand Theft Auto V Legacy, Story Mode only. Steam, Epic and Rockstar
  locations are searched; any other valid location can be supplied.
- A working OpenXR runtime. Virtual Desktop users select VDXR in
  Virtual Desktop Streamer.
- In Rockstar Games Launcher, open Settings > General and set BattlEye OFF
  before Story Mode modding. BattlEye does not need to be installed or
  reinstalled for Story Mode. Never take this mod into GTA Online.
- On a first install, start the unmodded game into Story Mode once with
  BattlEye off. Reach the world, exit GTA, and only then install the mod.
- The publisher instructs users to run Setup as administrator so it can write
  to protected game folders. The Hub announces the UAC prompt before opening
  Setup; its normal Play button later opens the author launcher separately.

### What the Hub installer does

1. Shows the BattlEye-off and initial flat Story Mode steps. Confirm BattlEye
   is off in the Rockstar launcher before the Hub proceeds.
2. Finds the folder containing `GTA5.exe` and original game archive files.
3. Offers the latest official GitHub prerelease, an explicitly selected local
   `GTAVR-Setup-and-Play.exe`, and the official releases page. If a GitHub
   transfer fails, the manual download screen accepts a dragged or pasted EXE;
   Skip returns to the source choices. No Downloads file is picked silently.
4. Rejects HTML/login responses and requires a usable Windows executable;
   changed future builds are not blocked by historical filename, size,
   metadata or checksum values.
5. After a separate Enter confirmation, Windows asks for administrator
   approval before publisher Setup opens. You click Install / Update Everything
   and then Verify in that window. The Hub requires `gtavr_install_manifest.txt`,
   `version.dll`, `OVRInject.dll` and `GTAVRBridge.asi` before it records the
   release version and VR Ready.
6. Only after the publisher payload passes that check, the Hub keeps its
   launcher copy under `VRLaunch\DeployAbi\GTAVR-Setup-and-Play.exe` and
   prepares the Hub Play action. Installation does not switch the active VR
   mode; selecting a Hub Play button does that later.

The executable is not digitally signed. The current test prerelease's
publisher notes report mixed antivirus verdicts; a detection or missing file
needs its own evidence and diagnosis. The Hub never bundles or silently
substitutes it; it validates transport and the files actually installed rather
than rejecting future author builds against a historical fingerprint. The
author launcher contains the VR payload and obtains its own prerequisites.

### Playing and controls

Use Play GTAVR Motion on the game page. The Hub parks the older R.E.A.L.
hooks, enables DeployAbi and opens the same author launcher. Click Play
Story Mode there.

The publisher says VR engages roughly one minute after the Story Mode world
loads. A flat theater screen during that initial period is expected. If the
world is already running and the headset still waits beyond that period, do
not treat BattlEye installation as the fix. Check that the author's build line
says MATCH, run Verify in Setup with GTA closed, confirm BattlEye is still off,
and select a working OpenXR runtime. Save the launcher's build/Verify result,
the exact time since the world loaded, the headset/runtime name and
`%LOCALAPPDATA%\GTAVR\launcher.log` for diagnosis. The publisher has not
confirmed real-headset operation for this exact prerelease.

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

This route installs Luke Ross's R.E.A.L. r7, ScriptHookV and a community
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

- Play R.E.A.L. Gamepad selects OpenXR (`VRAPI = 3`) and parks the old
  motion overlay.
- Play R.E.A.L. Motion selects OpenVR (`VRAPI = 2`) and enables
  `GTAVR.asi`. This older overlay remains work in progress.

For R.E.A.L., turn off Steam's Use Desktop Game Theatre while SteamVR is
active option. Aiming is normally head-driven. Shake your head briefly from
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

- Selecting GTAVR Motion renames `RealVR.asi` and `GTAVR.asi` to their
  reversible `.off` forms, then removes the author's `gtavr.disabled` marker.
- Selecting either R.E.A.L. mode restores `RealVR.asi` and creates
  `gtavr.disabled`, the inert marker recognized by DeployAbi's own loader.
- Nothing is deleted while switching. A running `GTA5.exe` blocks the change,
  so two hook generations can never be changed under a live game process.

Launching `PlayGTAV.exe` or GTA directly bypasses this protection. When both
mods are installed, always start the desired VR route from the Hub.

## Updating

DeployAbi now publishes the Setup EXE on GitHub. The Hub follows its current
prereleases and compares that release with the installed DeployAbi version.
A downloaded publisher EXE can be chosen directly when GitHub is unavailable.

The older VRV patcher continues to resolve its GitHub release at install time.
Its GitHub update check is scoped to `RealVR.asi`, so it cannot raise an update
for somebody who installed only DeployAbi.

## Safe removal

For DeployAbi, open
`VRLaunch\DeployAbi\GTAVR-Setup-and-Play.exe` and use its own Uninstall
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
- Official current downloads: https://github.com/DeployAbi/GTAVR/releases
- GTAVR Setup and Play by DeployAbi / Sauce; support: https://ko-fi.com/deployabi
- R.E.A.L. VR mod by Luke Ross: https://www.patreon.com/realvr
- GTA-VRV-Patcher fork by SanguShellz: https://github.com/SanguShellz/GTA-VRV-Patcher
- Original compatibility patcher by Francisco Manzanilla: https://github.com/FranciscoManzanilla/GTA-VRV-Patcher
- ScriptHookV by Alexander Blade: https://dev-c.com/gtav/scripthookv/

>>> Pull off the heist, outrun the stars, and own the streets of Los Santos.

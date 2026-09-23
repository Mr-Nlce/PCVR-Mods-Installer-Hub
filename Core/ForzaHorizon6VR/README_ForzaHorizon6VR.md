# Forza Horizon 6 VR

<!-- hub:keep-order -->

Three separate community launchers support the Steam and Microsoft Store /
Game Pass versions. The Hub keeps them in `C:\Games\Forza Horizon 6 VR`
under their own `NALULUNA`, `lufz` and `CheekyRender` folders. You may keep
all three packages installed, and the detail page always shows every choice.

Only **one** launcher proxy can be active inside the retail game at a time:
all three ultimately use `dxgi.dll`. Before changing mods, open the currently
active launcher's uninstall action, remove its game deployment, close it, and
then start the other launcher. Never combine or copy their DLLs by hand.

The original game, saves and graphics settings stay outside these packages.
**Open in Steam** starts flat; no Flat / VR file switch is needed.

## Option 1 - NALULUNA (recommended)

### Setup and launch

The installer opens the free ko-fi page. Set the amount to 0 (or add a tip),
download `fh6vr_<version>.zip`, then drag that ZIP into the installer. Start
NALULUNA through **[[Start in VR]]**, its desktop shortcut or `fh6vr.exe`, and
press **[[Launch]]**. Once you are in a car, press **[[Tab]]** until cockpit
view is active.

https://ko-fi.com/s/03bdcc5fe9

### Settings and controls

- Gamepad or wheel controls the car.
- **[[Ctrl]] + [[Space]]** recenters the headset.
- Start with lower graphics, V-Sync off, an unlimited frame rate, and motion
  blur / film grain off.
- DIBR is the smoother starting point; AFR gives cleaner stereo but halves
  the effective frame rate.
- DLSS Super Resolution is usable. Leave Frame Generation off so it does not
  fight the mod's D3D12 injection path.
- If the map or speedometer is missing in the car, set **HUD Safe Frame
  Vertical** to 25 under **Settings > HUD & Gameplay**.

### Switching or removal

Use NALULUNA's own removal first when switching. **Uninstall now** only removes
the game-folder `dxgi.dll` when it is byte-identical to this installation's
`fh6vrhook.dll`; any unrelated wrapper is left untouched. The separate package
and retail game are handled independently.

## Option 2 - lufz / VRMod

The current **v1.4.2** package includes the latest head-movement hotfix.

### Setup and launch

The Hub downloads the newest lufz release automatically, including the
author's prereleases. Start `vrmod-launcher.exe`, choose **[[+ Add Game]]** and
pick the FH6 install folder, then press **[[Install VR Mod]]**. On Game Pass the
usual folder is `C:\XboxGames\Forza Horizon 6\Content`; Windows may block
selecting `ForzaHorizon6.exe` itself. Steam users may also use **[[+ Add .exe]]**
or **[[Auto-detect Running]]**.

Start SteamVR, launch the game, and press **[[Play in VR]]** after reaching the
main menu, garage or road.

https://github.com/oofz/vrmod-releases/releases

### Settings and controls

- Gamepad or wheel controls the car.
- For OpenXR 6DoF, turn HDR off and set the in-game FOV to maximum.
- Leave Frame Generation off. The launcher clears only obsolete conflicting
  profile values and preserves the rest of your tuning.
- If head tracking sticks, press **[[F8]]** to toggle it off and on.

### Switching or removal

Before switching, select Forza Horizon 6 inside VRMod and run
**[[Uninstall VR Mod]]**. **Uninstall now** opens that author action, waits for
it to finish, and removes the separate lufz package only after
`.vrmod_install.json` is gone from every verified game location.

## Option 3 - CheekyRender by ClarkCheekyKent

### Setup and first launch

The Hub automatically downloads the newest published release, whether the
author labels it stable or prerelease, and installs the four-file payload into
one stable `CheekyRender` folder. Microsoft Visual C++ 2015-2022 Redistributable
(x64) is required.

Prepare the headset and preferred OpenXR runtime, start CheekyRender through
**[[Start in VR]]**, select the FH6 install if detection did not fill it in,
then press **[[Start VR + FH6]]**.

On the first run and after every update, the launcher rebuilds its camera-hook
profile. Follow the status instructions: switch to Driver Camera, switch to Far
Chase Camera, then pause and unpause five times. When it reports that the
profile was updated, restart the game. The next run should report
`generated profile active`.

CheekyRender alpha 3.3 adds an in-launcher setup overlay for this first-run and
post-update profile generation, so the required camera sequence stays visible
while the profile is being prepared.

https://github.com/ClarkCheekyKent/cheeky-render-releases

### Modes and settings

- **Mono** has the best performance and clarity but no stereo depth.
- **AFR-Half** adds stereo at half the per-eye rate. **AFR full rate** needs the
  game to sustain twice the headset refresh rate.
- Unlock the frame rate, turn V-Sync off and start with the in-game FOV sliders
  at maximum. Dropping below the headset target can cause AFR flicker.
- Foveated rendering and peripheral DLAA trade image quality against speed;
  foveated DLSS-SR provides the largest reported performance gain.
- **[[Alt]] + [[Shift]] + [[W]] / [[A]] / [[S]] / [[D]] / [[Q]] / [[E]]**
  adjusts the seating position live.
- This is an early preview tested by the author on Quest 3, Virtual Desktop,
  an NVIDIA 5070 and Game Pass. Other combinations are not yet validated.

### Switching or removal

Use **[[Uninstall Mod]]** in CheekyRender before switching or deleting its
folder. **Uninstall now** opens that author action and verifies that a matching
CheekyRender `dxgi.dll` is no longer deployed before removing only the four
shipped payload files. A different or older `dxgi.dll` is never guessed away;
the separate package is kept for a safe retry. Generated settings are preserved.

All three mods inject render and camera hooks into the running game. There is
no guarantee against future anti-cheat action, and a game update may require a
new mod release. Use them at your own risk and do not ask the official Forza
team to support a broken VR mod.

>>> Chase the horizon, feel every gear change, and let the festival roar.

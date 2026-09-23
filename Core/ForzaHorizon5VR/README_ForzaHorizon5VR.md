# Forza Horizon 5 VR

Two community VR mods bring Forza Horizon 5 to the headset. You own the
game (Steam / Microsoft Store / Game Pass); the Hub installer lets you
choose a mod, obtains or opens its current download and installs it under
`C:\Games\Forza Horizon 5 VR`, deliberately **outside** the retail game.

Both packages can remain installed. Fresh installs use separate
`NALULUNA\` and `lufz\` folders; an existing root-level lufz installation
from an older Hub remains supported and is updated in place. When the Hub
finds both launchers, the game tile and detail page let you choose which
one to start.

## The two mods

- **NALULUNA** - free on ko-fi (enter 0 or any tip). The installer opens
  the current product page; download the newest `fh5vr_<version>.zip` and
  drag it onto the installer. Launcher: `fh5vr.exe`.

  https://ko-fi.com/s/1724b05721
- **lufz / VRMod** - free on GitHub. The installer downloads the newest
  release, including prereleases, automatically. Launcher:
  `vrmod-launcher.exe`.

  https://github.com/oofz/vrmod-releases/releases

There is no universal winner. NALULUNA has dedicated AFR/DIBR rendering
modes and launches the game itself; lufz uses its multi-game VRMod launcher
and offers its own install, tuning and VR-session controls.

## Requirements

- An owned copy of **Forza Horizon 5** (Steam app 1551360, Microsoft
  Store, or PC Game Pass).
- A PC VR headset with a working OpenXR runtime.
- Do not put either launcher package in the retail game folder. Both
  authors expect the launcher to live elsewhere.

## Playing - NALULUNA

1. Use **[[Start in VR]]** in the Hub, the desktop shortcut, or start
   `fh5vr.exe`, then press **[[Launch]]**.
2. Once you are in a car, press **[[Tab]]** until cockpit view is active.
   That is the view displayed in the headset.
3. Press both controller sticks together, or **[[Ctrl]] + [[Space]]**, to
   recenter.

Use **Meta Link at 72 Hz** as the first setup to try. Keep **Sync FPS on**
and SteamVR closed. If SteamVR is unavoidable, disable its Theater Mode and
enable **Force Minimize Game** in the mod. Do not use OpenXR Toolkit.

Choose the rendering mode that fits the PC:

- **AFR** alternates complete left/right eye frames. Stereo is clean, but
  the delivered frame rate per eye is halved. AFR-half adds interpolation.
- **DIBR** reconstructs stereo from depth. It is much lighter, but may show
  artifacts around mirrors, pillars and the steering wheel. DIBR-half is
  the lowest-load option.
- **Mono** has no stereo depth but is useful for troubleshooting.

Keep the custom resolution roughly square or slightly wider, for example
1600 x 1440 or 2160 x 1920. Turn off motion blur, DLSS and frame generation;
raise the mod resolution before raising the game's graphics preset. On the
Microsoft Store / Game Pass build, close Afterburner, RivaTuner and similar
overlay tools.

The currently inspected build supports Steam **1.688.109.0** and Microsoft
Store / Game Pass **3.688.109.0**. A later game update can require a new
NALULUNA build.

## Playing - lufz / VRMod

The current **v1.4.2** package includes the latest head-movement hotfix.

1. Use **[[Start in VR]]** in the Hub, the desktop shortcut, or start
   `vrmod-launcher.exe`.
2. Choose **[[+ Add Game]]** and select the game's install folder. On Game
   Pass this is normally `C:\XboxGames\Forza Horizon 5\Content`, because
   Windows may block selecting the executable itself. On Steam you can also
   use **[[+ Add .exe]]** or **[[Auto-detect Running]]**. Select the FH5 row
   and press **[[Install VR Mod]]** once for that game folder.
3. Start the selected OpenXR runtime and press **[[Play in VR]]**. This can
   launch the game or attach after it is already at the menu, garage or in
   a car. **[[Exit VR]]** returns the session to flat.

For OpenXR 6DoF, turn HDR off, set the in-game FOV to maximum and leave
Frame Generation off. If head tracking becomes stuck, use the launcher's
re-acquire control.

## Controls

Driving uses the normal gamepad or wheel controls:

- **[[LT]]** Brake / reverse
- **[[RT]]** Accelerate
- **[[Left Stick]]** Steering
- **[[A]]** Handbrake on the default layout
- NALULUNA recenter: press **[[Left Stick]] + [[Right Stick]]**, or
  **[[Ctrl]] + [[Space]]**

## Notes and safety

- Both mods inject into the running game and read or change camera and
  rendering data. The authors cannot guarantee that no account action will
  occur. Use them at your own risk.
- NALULUNA copies its own hook into the detected retail game folder as
  `dxgi.dll`. The Hub's uninstaller removes it only when it is byte-identical
  to the selected NALULUNA package; a different DXGI wrapper is preserved.
- A Forza Horizon 5 update can break either mod until its author publishes a
  compatible build. Do not contact the official Forza team about mod issues.

## Flat play and removal

No Flat / VR file switch is needed. **Open in Steam** starts the original
game normally; **Start in VR** opens the selected external launcher.

**Uninstall now** shows NALULUNA and lufz separately:

- NALULUNA: the Hub verifies and removes only its matching game-folder
  `dxgi.dll`, then removes the three archive-owned launcher files. Generated
  `fh5vr.ini` and logs remain available.
- lufz: the Hub opens the author's **Uninstall VR Mod** action first. Only
  after `.vrmod_install.json` is gone does it remove the known launcher
  payload. Generated library/settings files remain available.

The retail game, saves, settings and unrelated wrappers are never deleted.

## Support and credits

- **NALULUNA** - https://ko-fi.com/naluluna/shop
- **lufz / VRMod** - https://github.com/oofz/vrmod-releases
- Forza Horizon 5 by Playground Games / Turn 10.

>>> Viva Mexico - drop the roof, floor it, and chase that horizon.

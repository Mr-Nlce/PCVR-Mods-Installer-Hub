# No One Lives Forever 2 VR

Luke Ross's **R.E.A.L. mod** (Reality Enhancement Augmentation Layer)
turns Monolith's 2002 spy classic *No One Lives Forever 2: A Spy in
H.A.R.M.'s Way* into a full first-person VR experience with roomscale
head tracking. It is layered on top of an existing, **user-provided**
copy of the game - the game is not sold in any store, so you must own
and supply it yourself.

## Before you install

- Start from a **full English install of NOLF2 patched to v1.3**. If a
  localized build is chosen during install (DE / ES / FR / IT), you also
  need the matching localized game + 1.3 patch, or voices and textures
  stay English.
- Install the base game somewhere you have **full write access** (e.g.
  `C:\Games\NOLF2`), **not** inside `Program Files (x86)`. The game saves
  into its own folder.
- The installer auto-detects the common retail location
  (`...\Fox\No One Lives Forever 2\NOLF2.exe`); otherwise you drag your
  game folder (or `NOLF2.exe`) onto it.
- Do **not** use the Widescreen Patch or any other NOLF2 mods - they
  conflict with the VR conversion.
- The installer downloads the mod `.rar` from Luke Ross's GitHub release
  and extracts it into your game folder. A `.rar` extractor is required:
  **7-Zip** (the installer can fetch it automatically) or **WinRAR**.
- Your original files (`autoexec.cfg`, `Lithtech.exe`, `LTMsg.dll`,
  `SndDrv.dll`, `Profiles`) are backed up to `_backup_pre_REAL` first.
  Saves are never deleted; only the stock "Player" profile options reset.

## Launching

During install you pick your headset type. **Meta / Oculus** (Rift, or
Quest via Link / Air Link) runs natively on the Oculus runtime.
**SteamVR headsets** (Valve Index, HTC Vive, Pico, WMR, or Quest over
Virtual Desktop / Steam Link) use **Revive**, which is **bundled inside
the mod** (the `NOLF2Revive` folder) - it is not installed separately.
Revive needs the **Oculus PC runtime** present (no Oculus account
required; you can skip its first-time setup); the installer checks for it
and opens the download page if it is missing. Your choice is saved as
`+VRRevive` in `VRlaunchcmds.txt` (`0` = native Oculus, `1` = Revive).

Start SteamVR first (Meta / Oculus users can skip that), then launch with
**Start in VR** in the Hub or the **No One Lives Forever 2 VR** desktop
shortcut - both run
`Lithtech.exe`. WMR headsets may have issues.

Leave the resolution at the mod's default **1280x960**. To sharpen the
image, edit `VRSuperSampling` (sensible range 1.0-2.0) in
`VRlaunchcmds.txt`; keep `VR.rez` listed last in that file.

## Controls (Xbox controller)

Switch the controller on and connect it **before** starting the game
(steady, non-blinking light) or it will not be recognised. Mouse +
keyboard also work at a desk. Touch / Vive controllers are not supported.

The Left Stick click acts as a **shift**: hold it to reach the alternate
actions below; tap and release it to toggle Sneak (walk / always-run).

**In game**

- [[LS up/down]] - move Forward / Backward
- [[LS left/right]] - step Left / Right
- [[LS click]] - toggle Sneak (tap), or shift modifier (hold)
- [[RS up/down]] - Previous / Next weapon
- [[RS left/right]] - Turn Left / Right (Lean Left / Right while [[LS]] held)
- [[RS click]] - Zoom
- [[D-pad up]] - choose weapon 1 (weapon 5 while [[LS]] held)
- [[D-pad right]] - choose weapon 2 (weapon 6 while [[LS]] held)
- [[D-pad down]] - choose weapon 3
- [[D-pad left]] - choose weapon 4
- [[A]] - Jump
- [[B]] - toggle Crouch
- [[X]] - Action
- [[Y]] - Keychain Light
- [[LB]] - Move body / piece
- [[LT]] - Holster weapon
- [[RB]] - Change ammo
- [[RT]] - Fire
- [[View]] - Pause the game
- [[Menu]] - Mission status

**In menus**

- [[D-pad]] - cursor keys (navigate)
- [[A]] - Enter (select)
- [[B]] - Escape (cancel / back)

**In cutscenes**

- [[View]] - Pause the cutscene
- [[B]] - Escape (open the menu)
- [[RS click]] - Space (skip the cutscene)

**Quick save / load**

- [[LB]] - QuickSave (while paused)
- [[RB]] - QuickLoad (while paused or in menus)

**Keyboard extras**

- [[F3]] - toggle the in-game HUD
- [[F6]] / [[F9]] - QuickSave / QuickLoad (hard-bound by the engine)

> Vive note: if SteamVR has taken the controller **Menu** button for its
> Dashboard, either double-click it quickly to reach Mission status, or
> disable the Dashboard in the SteamVR developer settings.

## Cutscene comfort

The mod adds a full page of VR options. **Cinematic fidelity** controls
how faithfully scripted camera moves and zooms are reproduced: set it to
**Expert** for the director's intended framing (with smooth motion and
zoom), or step down to **Skilled** or lower if involuntary camera
movement or zoom makes you queasy.

## Saves

R.E.A.L. saves are interchangeable with the original v1.3. The mod adds
99 save slots versus the original's 10 - a save in slot 11+ won't be
visible to the unmodded game, so re-save into one of the first 10 (or
quicksave) if you want to continue without the mod. Multiplayer is
disabled.

## Links

- **Mod page / readme:** https://github.com/LukeRoss00/nolf2-real-mod
- **Support Luke Ross:** https://www.patreon.com/realvr

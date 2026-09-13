# Scrap Mechanic VR

**Scrap Mechanic Native VR** by **21Suspect** adds native OpenXR stereo, roomscale head tracking, tracked hands and tools, motion interactions and spatial menus.

The installer keeps three independent routes. The detail-page tile splits **Current** and **1.0.5** when both are installed. The original legacy copy remains available as its own button on this page.

## Option 1 — Current game version — Native VR by 21Suspect

### What this route is

This route modifies the normal, updating Steam installation. The Hub follows the newest stable GitHub release, rejects unusable web responses and starts the downloaded author installer after its executable format has been checked.

The author manager validates the exact supported game executable and owns its managed files, checksums, backups, repair and removal. If a future Scrap Mechanic update is not yet supported, the manager refuses the mismatched build instead of forcing files into it.

### Installing and starting Current

1. Close Scrap Mechanic and choose **Current game version**.
2. In the author window choose **Install VR Mod**, approve the Windows prompt and wait for verification.
3. Close the author window. The Hub checks `Release\smvr_native_vr_v1.addon64` before recording success.
4. Use [[Start Current]] in the split button, or [[Start in VR]] when this is the only installed route.

The Hub launcher selects this exact game root before calling the author manager. It cannot accidentally start a separately installed confirmed copy.

### Current update and removal

Run this installer option again for a newer stable release. Use **Open Current uninstaller** beside the Uninstall Guide, then choose **Uninstall VR Mod** in the author manager. Its verified backup restores original game files; saves are not part of the managed set.

## Option 2 — Last confirmed working version — game 1.0.5 / Native VR 1.4.8

### What this route is

This is the update-round snapshot confirmed on 8 September 2026: Scrap Mechanic **1.0.5.876**, Steam build **24529696**, with Native VR **1.4.8**. It lives in `C:\Games\Scrap Mechanic 1.0.5 VR` by default and does not receive Steam game updates.

Both depots are required: `387992` manifest `3609790474044595719` contains game data, while `387993` manifest `8377913301090149728` contains the Windows executable. The installer downloads and merges both before it opens the author manager pinned to this depot route.

### Installing and starting 1.0.5

1. Choose **Last confirmed working version**.
2. Paste each supplied Steam Console command and wait for its depot to finish.
3. Keep the proposed separate folder or choose another dedicated folder.
4. In the author manager choose **Install VR Mod** and let its verification finish.
5. Use [[1.0.5]] in the split button or the `Scrap Mechanic 1.0.5 VR` desktop shortcut.

The generated launcher writes this copy's exact root immediately before every start. Use **Open 1.0.5 uninstaller** for the same reason: it selects this copy before opening the manager.

## Option 3 — Original legacy depot — pre-1.0 / Native VR 1.17

### What this route is

This preserves the original pairing: Steam build **22163681** plus legacy Native VR **1.17.0** in `C:\Games\Scrap Mechanic VR`. It is not advanced during ordinary update rounds.

Its data depot is `download_depot 387990 387992 4615519036154398529`; its Windows depot is `download_depot 387990 387993 1969835134401920665`. The Hub installs the matching legacy payload only into this dedicated copy.

### Installing and starting Legacy

Choose **Original legacy depot**, complete both Steam Console downloads and keep the legacy copy separate. Use [[Start Legacy]] on the detail page or the `Scrap Mechanic Legacy VR` desktop shortcut. Do not use Steam Play for either depot copy; it opens the current retail game.

To remove the legacy route, back up only custom content you deliberately added, verify the folder is the dedicated legacy copy, then remove only that folder and its shortcut. Never remove the normal Steam game folder.

## Shared runtime, controls and settings

- Use one active 64-bit OpenXR runtime: Meta Quest Link, Virtual Desktop **VDXR**, or SteamVR OpenXR.
- Wake and connect the headset before starting VR.
- [[Left Stick]] moves; [[Right Stick]] turns or scrolls menus.
- [[A]] jumps and operates menus; [[B]] interacts.
- [[Right Trigger]] is the primary action; [[Left Trigger]] is secondary.
- [[X]] and [[Y]] change hotbar items; hold [[Y]] or use [[X]] + [[Y]] for the backpack.
- [[Right Grip]] + [[Right Stick]] raises or lowers the lift.
- Hold [[Both Sticks]] for one second to recenter view and floor.

Current and confirmed settings are in `Release\ScrapMechanicVR.ini`. Set `VerticalStickLook=0` for horizontal stick turning only. The legacy launcher also prepares its required Steam context and vehicle-camera setting.

## Credits

- **Scrap Mechanic Native VR** by 21Suspect: https://github.com/21Suspect/Scrap-Mechanic-Native-VR
- Original project code is MIT licensed. Third-party and Scrap Mechanic assets retain their own rights.
- Unofficial community project; not affiliated with Axolot Games, Meta, Valve, Khronos or ReShade. You must own Scrap Mechanic.

>>> Build it, then climb inside and grab the wrench yourself.

# S.T.A.L.K.E.R. GAMMA VR (Anomaly Gamma)

A motion-controlled VR build of **S.T.A.L.K.E.R. GAMMA**, the large curated
modpack built on S.T.A.L.K.E.R. Anomaly. GAMMA VR is a free, complete,
standalone package; no separate Anomaly installation is required.

The current package is **GAMMA VR v0.3.4** with **AOEVR 0.5.0**.

## What v0.3.4 adds

- **Physical manual reloading for every weapon class**: remove and insert
  magazines, operate bolts, pump shotguns, use break-action weapons and clear
  jams by hand. Magazines remain physical items and keep their ammunition.
- **Physical grenades** are drawn from a body holster and thrown using hand
  movement; throw distance follows the swing.
- **Wearable left-hand HUD** through Wearable Devices 0.8.8 and its VR fixes.
- **Faster stereo rendering** through second-eye hidden-geometry culling,
  shared shadow work and reduced post-processing.
- Improved grips and weapon scaling, HUD fixes, updated weapon shaders and a
  better unjam fix.
- Updated defaults: `vr_cut_dead 44`, debug pointers off and anisotropic
  filtering at x16.
- Fixes for level-change and dual-GPU startup crashes, scope lighting and
  GAMMA water/reflections.

This remains an evolving community VR build. The physical PDA, melee weapons,
physical food/medkit use and extended magazine handling are still planned.

## What the Hub installer does

1. Finds an existing `Gamma VR` installation from the Hub's saved Locate Game
   path, its installer receipt or the standard `C:\Games`, `D:\Games` and
   `E:\Games` locations.
2. Offers the small update only when **v0.3.3 is positively identified**.
   Older or unknown builds use the complete v0.3.4 package.
3. Uses the required Discord sequence: server invite, current download post,
   then Downloads-folder search or drag-and-drop, each behind its own Enter
   confirmation.
4. Rejects only an unreadable/incomplete archive, unsafe archive paths or a
   package missing files required to run v0.3.4. Historical names, sizes and
   hashes are not used as download gates.
5. Stages the package before touching the installation. The v0.3.3 update
   backs up every replaced file and records newly added files in an ownership
   manifest. A complete replacement keeps the previous folder as a recoverable
   same-drive backup.
6. Removes the obsolete `appdata\shaders_cache` from the active update route,
   records v0.3.4 atomically, keeps the language file byte-safe, and refreshes
   the **Anomaly Gamma** desktop shortcut.

## Which package do I need?

| Your situation | Official v0.3.4 package |
|---|---|
| Exact GAMMA VR v0.3.3 installation | `UPDATE FROM v0.3.3 TO v0.3.4.7z` |
| Fresh, older or unknown installation | `STALKER GAMMA VR v0.3.4.7z` (complete package) |

The small archive is **only** an update from v0.3.3. It must not be applied to
v0.3.2 or an unknown build. The complete package needs at least **110 GB of
free space** and should be installed into a short path without spaces, such as
`C:\Games\Gamma VR`.

The current Discord post may offer the complete package through a torrent. If
you do not already have a torrent client, [qBittorrent](https://www.qbittorrent.org/download)
is the recommended free, open-source client and contains no advertising. Let
`STALKER GAMMA VR v0.3.4.7z` finish completely before returning to the
installer; a preallocated but incomplete torrent file is not a readable archive.

## First launch and language

Run `GAMMA VR.bat` at least once after installing or updating. This generates
or refreshes `ModOrganizer.ini` and prepares the build for further changes in
Mod Organizer 2. The installer offers to launch it, but never opens the game
before you choose that action. A black headset for 10–15 seconds during start
and loading screens is normal.

The installer changes `language = rus` to `language = eng` in
`overwrite\gamedata\configs\localization.ltx` without adding a BOM or changing
the file's byte encoding. If the game remains Russian, use its language menu or
make the same plain-text change manually.

## Motion controls

- [[Trigger]] Fire / interact; operate the active manual-reload point
- [[Grip]] Hold a weapon foregrip, ladders and world items
- [[Stick]] Move and smooth/snap turn
- [[A]] / [[X]] Jump / crouch according to the active binding profile
- [[B]] / [[Y]] Reload/holster actions according to the active profile
- [[Left hand]] Wearable HUD and physical inventory
- [[Body holster]] Draw grenades, then throw with real hand movement

Interaction points on weapons can be highlighted and configured in MCM.
Physical reloading can also be disabled there. Check the current in-game VR
bindings because GAMMA's control set is broader than base Anomaly's.

## Support and updates

Join the [Anomaly VR Discord](https://discord.gg/kGhd7GvJ5F), then use the
[current GAMMA VR v0.3.4 download and information post](https://discord.com/channels/1495664880311734313/1511657141990199356/1548102620571373668).
The Hub intentionally sends users through this official post and does not
publish its temporary file-hosting URL.

For a reproducible problem, include `appdata\engineLogs\xray.log` and
`engine_breadcrumbs.log`. The developers accept bug reports for clean builds
without unrelated third-party mods on top.

## Credits

- GAMMA VR package and integration: GAMMA VR community team
- AOEVR 0.5.0 and its contributors
- Manual Reload Project v5 and improved unjam fix: killua._.107
- HUD fixes: NITROYUASH and Juarri
- Weapon Scaling Fix + Grips v0.3.5: Mr.Enry
- Wearable Devices: Sulik, Jeremussy and Wiarubane; VR fixes by Marsy and NITROYUASH
- S.T.A.L.K.E.R. GAMMA and S.T.A.L.K.E.R. Anomaly teams

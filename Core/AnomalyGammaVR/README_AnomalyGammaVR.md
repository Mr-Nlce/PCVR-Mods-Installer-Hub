# S.T.A.L.K.E.R. GAMMA VR (Anomaly Gamma)

## About the Game

GAMMA VR is a standalone, motion-controlled S.T.A.L.K.E.R. GAMMA build based on
Anomaly. No separate flat GAMMA installation is needed. The current package is
**v0.3.5** with **AOEVR 0.5.0**.

## What v0.3.5 changes

- PDA messages appear on the left-wrist Promin display instead of the game
  screen. Tap the display to switch between Health, Mini-map (upgrade required)
  and Messages. Use its Up/Down buttons to scroll messages.
- Adds Wearable Devices Armor Swap Crash Guard v1.1 and PDA Messages v7.4.4.
- Updates Z.H.O.P.A. to v2.3, WearableDevices to v0.8.10, GAMMA VR Inventory
  Actions and Fixes to v2.3, VR More Actions to v9 and the 0.8.10 VR fixes to v5.
- Refreshes default MCM settings; RAD and PSI bars are hidden by default with
  WearableDevices enabled.

The v0.3.4 features remain: physical reloading, throwable grenades, weapon
grips, the wearable HUD and stereo-rendering improvements.

## Choose the correct package

| Existing installation | File on the official download page | Installer route |
|---|---|---|
| None, older than v0.3.4, or unconfirmed | `STALKER GAMMA VR v0.3.5.7z` | Complete install |
| Complete v0.3.4 | `UPDATE FROM v0.3.4 to v0.3.5.7z` | Update over v0.3.4 |

The page also offers `STALKER GAMMA VR.torrent` for obtaining the complete
package. The update archive is **not** a standalone game. The installer offers
it only after finding v0.3.4, Mod Organizer, the game executable, the previous
profile and the manual-reload mod. A folder name or version text alone does not
make an incomplete installation eligible.

The complete archive is about 35 GB and needs **at least 110 GB free** when
unpacked. A short destination without spaces, such as `C:\Games\GammaVR`, is
recommended. Let a torrent finish before selecting its archive in setup.

## What the Hub installer does

1. Finds a saved `Gamma VR` folder or asks for one. It offers the small update
   only for a complete v0.3.4 base; otherwise it requests the full v0.3.5 pack.
2. Opens the Discord server invite, then the
   [official v0.3.5 download post](https://discord.com/channels/1495664880311734313/1511657141990199356/1552472577023156304)
   behind separate Enter prompts. After download, it searches Downloads or
   accepts a pasted file path and asks you to confirm the selected archive.
3. Checks archive readability, safe paths and the files needed for the chosen
   route. It extracts to a staging folder before changing the installation.
4. For an update, it copies the v0.3.5 files over v0.3.4, backs up replaced
   files and records newly added files. It moves only
   `STALKERVR_GAMMA\appdata\shaders_cache` into that recovery backup so the old
   shaders are no longer active. A full replacement retains the former folder
   as a separate recovery backup.
5. Records v0.3.5 only after the installed game, profile and updated mods have
   been verified. It refreshes the desktop shortcut and offers to start
   `GAMMA VR.bat` after an explicit prompt.

Run **`GAMMA VR.bat` at least once after installing or updating**. Its v0.3.5
script regenerates `ModOrganizer.ini` and starts the current Mod Organizer
profile. If you postpone the launch in setup, do it yourself before playing.

The installer changes `language = rus` to `language = eng` in
`overwrite\gamedata\configs\localization.ltx` without adding a BOM. A black
headset for 10–15 seconds during startup or loading can be normal.

## Motion controls

| Button | Action |
|---|---|
| [[Trigger]] | Fire, interact and operate a manual-reload point |
| [[Grip]] | Hold a weapon foregrip, ladder or world item |
| [[Stick]] | Move and turn according to the active binding profile |
| [[A]] / [[X]] | Jump or crouch according to the active binding profile |
| [[B]] / [[Y]] | Reload or holster according to the active binding profile |
| [[Left Trigger]] held | Show full item stats in the inventory |
| [[Left Trigger]] double-click | Drop the selected item |
| [[X]] in inventory | Run Auto-Looter |
| [[Y]] held in inventory | Disassemble the selected item |
| [[Left wrist]] Promin tap | Switch Health, Mini-map and Messages displays |
| [[Promin Up]] / [[Promin Down]] | Scroll PDA messages on the wrist display |
| [[Body holster]] | Draw a grenade, then throw with your hand movement |

Bindings can differ between profiles and can be changed in MCM. The Promin
Mini-map requires its in-game upgrade.

## Support and updates

Use the [Anomaly VR Discord](https://discord.gg/kGhd7GvJ5F) and its
[v0.3.5 release post](https://discord.com/channels/1495664880311734313/1511657141990199356/1552472577023156304)
for the publisher's files and updates. The Hub checks this Discord release
manually; it does not infer a new release from a temporary file-host URL.

For a reproducible problem, include `appdata\engineLogs\xray.log` and
`engine_breadcrumbs.log`. Report problems from a clean build without unrelated
third-party mods.

## Credits

- GAMMA VR package and integration: GAMMA VR community team
- AOEVR 0.5.0 and its contributors
- Manual Reload Project v5 and improved unjam fix: killua._.107
- WearableDevices: Sulik, Jeremussy and Wiarubane; VR fixes by Marsy and NITROYUASH
- PDA Messages: realzelda414; Armor Swap Crash Guard: HEKPOTEXHAPb
- S.T.A.L.K.E.R. GAMMA and S.T.A.L.K.E.R. Anomaly teams

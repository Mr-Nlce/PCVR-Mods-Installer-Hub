# Amnesia VR (Sclerosis)

A free fan-made VR remake of *Amnesia: The Dark Descent*, built in Unity by CreaTeam. Adds full motion controls and room-scale support. Ships its own engine - launches via `Sclerosis.exe`, not the original `Amnesia.exe`.

**Mod**: Sclerosis v1.8.16 - by CreaTeam, distributed via itch.io
**Game**: Amnesia: The Dark Descent (Steam App 57300)

## About this mod

Sclerosis is a complete VR reimplementation of Amnesia, not a runtime injector. It re-uses the original game's assets (which is why an installed copy of Amnesia is required) but runs on its own Unity-based engine with full VR support.

**Development status:** The mod author halted active development in 2024. v1.8.16 is the final released version. No future updates are expected. This installer pins the version explicitly.

The mod page is here:
- https://createam.itch.io/sclerosis-an-amnesia-vr-remake

## Requirements

- **Amnesia: The Dark Descent** (Steam, AppID 57300) - must be **owned and installed**
- The mod uses the original game's data files (textures, models, sounds)
- The original `Amnesia.exe` must exist in the install folder (the installer verifies this)

## What this Hub installer does

1. Opens the itch.io mod page in your browser
2. You manually download `Sclerosis_VR_v1.8.16.zip` (~916 MB) from the page
3. Drag-and-drop the ZIP into the installer window
4. The installer auto-locates `Amnesia: The Dark Descent` in your Steam library
5. Extracts the ZIP contents directly into the Amnesia install folder (next to `Amnesia.exe`)
6. Verifies `Sclerosis.exe` exists post-install

## Launching

- **Via the Hub**: "Start in VR" launches `Sclerosis.exe` directly
- **Desktop shortcut**: An optional "Amnesia VR" shortcut points at `Sclerosis.exe`
- **Do NOT** launch Amnesia through Steam - that runs the flatscreen original game, not the VR mod

## Manual install (if the in-Hub installer fails)

If `Expand-Archive` fails (corrupt ZIP, weird path, antivirus), the manual fallback is:

1. Open `Sclerosis_VR_v1.8.16.zip` with 7-Zip or Windows Explorer
2. Copy every file and folder inside it (Sclerosis.exe, Sclerosis_Data\, UnityPlayer.dll, GameAssembly.dll, baselib.dll, UnityCrashHandler64.exe, Sclerosis_custom_translation\, HOW_TO_INSTALL_SCLEROSIS_VR.txt)
3. Paste them all directly into the folder containing `Amnesia.exe`
4. Double-click `Sclerosis.exe` to launch

>>> Tinderboxes lit. Mind still slipping. Welcome to the dark.

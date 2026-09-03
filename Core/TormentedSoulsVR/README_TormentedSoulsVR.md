# Tormented Souls VR - Installer

Full 6DOF VR conversion for Tormented Souls with motion-controlled
combat and exploration, built from TormentedSoulsVR by cybensis.

## What this installer does

1. Opens Steam Console and downloads the manifest that matches
   the build the VR mod was developed against (May 2023). The
   manifest lives on the public branch, so Steam Console's
   `download_depot` command works directly.
2. Auto-locates the depot folder Steam places on disk and moves
   it to a stable location (default: `C:\Games\Tormented Souls VR`).
   This keeps the VR install separate from any future updates
   Steam applies to your retail Tormented Souls. You can choose
   a different folder during the install.
3. Downloads `TormentedSoulsVR-1.0.0.zip` from GitHub, unpacks
   the wrapper folder, and copies `BepInEx`, the
   `TormentedSouls_Data` overlays, `winhttp.dll` etc. into the
   game's root.
4. Drops a `steam_appid.txt` next to the EXE and creates a
   desktop shortcut so the game launches without prompting Steam
   to reinstall.

## Depot used

- App ID:      1367590 (Tormented Souls)
- Depot ID:    1367591
- Manifest:    8039349334070823642 (public branch, mod-compatible)

The command the installer builds and copies to your clipboard is:

    download_depot 1367590 1367591 8039349334070823642

## What stays untouched

Your retail Tormented Souls install on Steam is left completely
alone. The VR build lives in its own folder under `C:\Games\`
(default `Tormented Souls VR`) so Steam updates can't overwrite
it. You can keep playing the retail version normally.

## Launching

Always launch with **Start in VR** in the Hub or the desktop shortcut (or directly via
`TormentedSouls.exe` from the separate VR build's directory) with SteamVR already
running. Launching through Steam's library would start your
retail copy, not the VR build.

## Controls

- Shooting: hold the left trigger first, then pull the right
  trigger to fire
- Height / rotation recalibration: hold [[Y]] while
  standing (or sitting) at your preferred height and facing
  until the recalibration menu opens

Tested on: Quest 2 with Oculus Touch controllers. Other headsets
should work via standard OpenVR but may need controller bindings
configured manually in SteamVR.

## Credits

- Mod by cybensis
- GitHub: https://github.com/cybensis/TormentedSoulsVR

All mod files are downloaded at install time from official
sources. Nothing is bundled with this installer.

>>> The manor's locked doors await, Caroline.

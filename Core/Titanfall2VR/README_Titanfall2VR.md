# Titanfall 2 VR

CircuitLord's maintained VR conversion brings the single-player campaign
into OpenXR with stereoscopic rendering, tracked hand aiming, full-body IK,
manual reloads and Titan controls. The project uses its own companion app for
installation, updates, removal and VR launch.

The reviewed publisher manifest currently lists companion app 1.2.9 and
Titanfall 2 VR package 1.0.16. Version 1.2.9 warns if Steam, EA App or the
companion runs as administrator, makes launch-time mod updates optional and
shows details for download-list errors. The companion app remains responsible for
downloading and updating the actual profile; the Hub verifies its result.

## About the Game

Titanfall 2 combines fast pilot movement, wall-running and large Titan battles
in Respawn Entertainment's story campaign. The VR profile is separate from the
normal game, which remains available in flat mode.

## Requirements

- A legitimate Titanfall 2 installation through Steam, EA App or Xbox PC.
- EA App installed and signed in; the Steam edition still uses EA App.
- A connected headset and a working OpenXR runtime. Start your preferred VR
  runtime before pressing Launch in VR in the companion app.
- Sufficient writable space in the game folder for Northstar, the TF2VR
  profile and game-derived assets. The publisher app builds these assets from
  your own installed game during its first installation.

## Install and start

1. Use Install Mod in the Hub. The Hub downloads CircuitLord's current
   `CircuitLordVRModInstaller.exe`, puts it beside `Titanfall2.exe`, and opens it.
2. Select Titanfall 2 in the companion app. Check the detected Steam, EA or
   Xbox game path. If EA App is missing, start the game normally once to install
   it and sign in, then refresh the companion app.
3. Press Install or Update in the Titanfall 2 section. The app installs
   Northstar and the mod into a separate `TF2VR` profile. First installation
   builds local assets and can take longer than an update.
4. After the app says Installed, return to the Hub installer and press
   Enter. The Hub checks the publisher's install record and required VR
   files before recording VR Ready.
5. Start in VR in the Hub opens the companion app. With your OpenXR runtime
   ready, use Launch in VR there to start the campaign.

Launching Titanfall 2 normally remains flat and does not load this VR profile.
The old TinyBlkDog Hub alpha is retired only after the new profile is complete;
its personal INI and separate Northstar copy remain for review.

## Controls and campaign saves

The conversion provides tracked hand aiming, manual reloads, full-body IK and
Titan interaction. The new publisher did not publish a complete controller
button table, so the old alpha's button map should not be treated as the new
mod's bindings. Use the in-game prompts and the companion app's help for your
current controller profile.

The current companion app's Campaign saves button checks
`%LOCALAPPDATA%\Respawn\Titanfall2_VR`, separate from the ordinary campaign.
Its code and validation test use this path, although the publisher README still
mentions `Documents\Respawn\Titanfall2_VR`. During installation you can copy
existing campaign progress or start fresh; use that button to inspect or copy
progress later.

## Updates and removal

The companion app checks its own version and the current Titanfall 2 VR package.
Open it from Start in VR and use Update when offered. The Hub checks
the installed TF2VR files and the publisher's version record; merely having
the companion EXE in the game folder is not VR Ready.

Use Open launcher uninstall beside the Hub's uninstall guide, select
Titanfall 2 and press Uninstall in the publisher app. That action removes
the files listed in `.circuitlord-vr-mods\Titanfall2VR.json`. The normal game
and its campaign saves remain. If an old Hub alpha contained modified files,
the migration preserves them instead of deleting them by guesswork.

## If something goes wrong

- If EA App sign-in or first launch interrupts VR launch, finish it on the
  desktop and use the companion app's Launch in VR again.
- If the Hub still says Game installed, finish Install/Update in the
  companion app, return to the Hub installer for verification, then scan again.
- If Steam's or another overlay interferes with VR rendering, close that
  overlay before retrying. Consult the companion app's logs for exact failures.
- Do not load the old alpha and the new TF2VR profile together. The Hub's
  migration removes only the old unchanged Hub-owned plugin once the new
  installation is verified.

## Support CircuitLord

[Support the mod developer on Ko-fi](https://ko-fi.com/circuitlord)

## Links

[CircuitLord's project and releases](https://github.com/CircuitLord/CircuitLordVRModInstaller)

Protocol 3: protect the pilot, then request a Titan.

# Outward VR - Installer

Full 6DOF VR conversion for Outward Definitive Edition with motion-
controlled combat, built from OutwardVR by cybensis.

## What this installer does

1. Asks where to install (default `C:\Games\Outward VR`) and
   fetches DepotDownloader from SteamRE's GitHub releases into a
   temp folder.
2. Prompts you for your Steam username and then hands control to
   DepotDownloader, which logs into Steam (password and Steam
   Guard go into DepotDownloader's own window, not into this
   installer) and downloads Outward Definitive Edition pinned to
   the v1.0 Definitive Edition mono release manifest - the only
   build the VR mod
   is compatible with.
3. Downloads `OutwardVR-0.9.2.zip` from GitHub, unpacks the
   wrapper folder, and copies `BepInEx`, `Outward Definitive
   Edition_Data` overlays, `winhttp.dll` etc. into the downloaded
   `Outward_Defed` sub-folder.
4. Creates a desktop shortcut pointing at the game EXE.

## Launching

Always launch with **Start in VR** in the Hub or the desktop shortcut (or directly via
`Outward VR\Outward_Defed\Outward Definitive Edition.exe`) with
SteamVR already running. This VR install is fully standalone - it
lives outside your Steam library and is not touched by future
Steam updates to Outward.

## Controls

![Controller layout](ControllerLayout.jpg)

A few VR-specific notes the diagram doesn't cover:
- Melee: physically swing your weapon at the target
- Block: hold your weapon parallel to your body, or use [[Right Grip]]
  if motion-controlled blocking feels awkward
- Move by controller direction: an option in the in-game menu if
  you prefer pointing your controller instead of the headset

Supported headsets: Quest 2, Valve Index, HTC Vive (with provided
bindings). Other OpenVR devices should work but may need SteamVR
binding adjustments.

## Why not Steam Console?

Our other depot-based installers (RoR2, Gunfire, Yooka's Option B)
use Steam's built-in `download_depot` console command. That works
fine for manifests on the main public branch, but not here.

Outward's VR-compatible build lives on the `default-mono` public
beta branch. Steam has a long-standing bug where `download_depot`
cannot fetch manifests that exist only on public beta branches -
it errors out with "Failed downloading 1 manifests (No connection)"
regardless of network state (valvesoftware/steam-for-linux#12138).

DepotDownloader is the open-source community workaround and is
explicitly recommended on the Outward VR Nexus and GitHub pages
as the way to install the mod.

## Why not opt into the beta branch in Steam?

The `default-mono` beta branch is now (2025/2026) on a newer
version than the mod was built against. Opting in will download
a newer build that the VR mod can no longer hook into - the game
starts but nothing actually renders in VR. The v1.0 DE mono
release manifest is pinned inside the DepotDownloader command
in this installer, and the installer also lets you paste a
different manifest if the default ever stops working.

## Security note

DepotDownloader is an open-source SteamKit2-based tool with 3000+
GitHub stars and is widely used for legitimate depot downloading.
This installer does not see or store your password or Steam Guard
code - DepotDownloader handles the login entirely in its own
process window. Your Steam username is the only thing this
installer records (in memory, only for the duration of the run,
to pass through to DepotDownloader).

## Credits

- Mod by cybensis
- GitHub: https://github.com/cybensis/OutwardVR
- Nexus:  https://www.nexusmods.com/outward/mods/277
- DepotDownloader by SteamRE:
    https://github.com/SteamRE/DepotDownloader

All tools and mod files are downloaded at install time from
official sources. Nothing is bundled with this installer.

>>> The wilds of Aurai await, Outlander.

# Tomb Raider 1 VR - Installer

Team Beef's OpenXR port of the original Tomb Raider (1996),
built from the BeefRaiderXR open-source release.

## What this installer does

1. Auto-locates a supported source install of the base game. Any
   one of the following is accepted:
   - Tomb Raider (I) on Steam (AppID 224960, folder
     `Tomb Raider (I)`)
   - Tomb Raider I-III Remastered on Steam (AppID 2478970)
   - Tomb Raider 1 on GoG (folder `Tomb Raider 1`)
   - Tomb Raider I-III Remastered on GoG
2. Checks for the `.NET 7.0.20 Desktop Runtime` and silently
   installs it if missing. SauronDesktop, the asset extraction
   tool that ships with BeefRaiderXR, needs this runtime.
3. Checks for 7-Zip and silently installs it if missing. The
   `BeefRaiderXR-1.0.0.7z` archive is a 7z file - normal Windows
   ZIP tools won't extract it.
4. Downloads `BeefRaiderXR-1.0.0.7z` from the Team Beef GitHub
   release and extracts the `BeefRaiderExtractionTool` folder
   into your chosen install location (default:
   `C:\games\Tomb Raider VR`).
5. Launches SauronDesktop with on-screen instructions for the
   one-time asset extraction step. SauronDesktop reads the
   original Tomb Raider data files from your installed copy and
   writes the converted assets into a sibling `BeefRaiderXR`
   folder.
6. Creates a `Tomb Raider VR.lnk` desktop shortcut pointing at
   the BeefRaiderXR.exe so the VR build launches without going
   through Steam.

## SauronDesktop one-time setup

SauronDesktop is unsigned, so Windows SmartScreen may show a
warning when it first runs. Click **More info**, then **Run
anyway**. Inside the SauronDesktop window:

1. Click **Locate from Steam Install** (the button below the
   manual path field).
2. If it says "Game not found", ignore it - the next step still
   works.
3. A bit below is the **Tomb Raider Version** section.
4. Click **Extract Files** and watch the right pane for
   progress. A "DATA Folder: Missing Files (21 of 22 found)"
   warning is harmless - the port still runs fine.
5. Optional: click **Download Audio Tracks** for the OST.
6. Close SauronDesktop when done.

## Install layout

After install, the layout under your chosen folder is:

    <installDir>\BeefRaiderExtractionTool\SauronDesktop.exe
    <installDir>\BeefRaiderExtractionTool\BeefRaiderXR\BeefRaiderXR.exe

The hub records the BeefRaiderXR subfolder in `.installed_path`
so Check Installed picks up custom install locations.

## What stays untouched

Your original Tomb Raider install (Steam or GOG, classic or
Remastered) is read-only during extraction. SauronDesktop only
reads the data files - it never writes back to the source
folder.

## Launching

Always launch via the desktop shortcut or the **Start in VR**
button in the hub. Both target `BeefRaiderXR.exe` directly.
Launching Tomb Raider through Steam or GOG would start the
classic flatscreen game instead.

## Credits

- VR port by Team Beef Studios (BeefRaiderXR)
- GitHub: https://github.com/Team-Beef-Studios/BeefRaiderXR
- Based on OpenLara by xproger:
  https://github.com/XProger/OpenLara

All mod files are downloaded at install time from official
sources. Nothing is bundled with this installer.

## Support Team Beef Studios

Team Beef develops Tomb Raider 1 VR and many other VR ports. If you enjoy their work, consider supporting them:
- https://www.patreon.com/c/teambeef/posts

>>> Lost city. Stolen artifact. Same Lara, new dimension.

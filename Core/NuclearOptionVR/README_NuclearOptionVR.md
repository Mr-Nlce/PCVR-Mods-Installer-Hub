# Nuclear Option VR

**NOVR** by InfernoSuperNova is a reworked build of **UUVR (Universal Unity VR)** designed and optimized specifically for Nuclear Option, the Shockfront Studios combat flight game.

This is an **external mod**: the Hub button links you straight to the official NOVR releases page. There is no Hub installer - you run NOVR's own GUI installer, which handles everything for you (and can update, repair, or uninstall NOVR later).

## Requirements
- Nuclear Option on Steam
- SteamVR (NOVR uses the OpenVR runtime)
- BepInEx **5.x** only - do NOT use 6.x unless the project explicitly says it is supported (the GUI installer handles this for you)

## Recommended: GUI installer
1. Close Nuclear Option before installing or updating.
2. Download the latest installer from the NOVR releases page:
   - Windows: `NOVR.Installer-Win.exe`
   - Linux / Proton: `NOVR.Installer-Linux`
3. Run the installer. On Linux you may need to make it executable first: `chmod +x NOVR.Installer-Linux`.
4. If Nuclear Option is not found automatically, choose the game folder manually - the folder must contain `NuclearOption_Data/Managed`.
5. Click Install.
6. Launch Nuclear Option from Steam.

## What the installer does
- Finds your Nuclear Option install
- Installs BepInEx 5.x if it is missing
- Downloads the latest NOVR release zip
- Installs NOVR into `BepInEx/plugins/NOVR` and `BepInEx/patchers/NOVR`
- Writes the installed version to `BepInEx/plugins/NOVR/version.txt`
- On Linux/Proton, configures the `winhttp` Wine override that BepInEx needs

## Manual zip install (fallback)
Use this only if the GUI installer does not work for your setup.
1. Close Nuclear Option.
2. Install BepInEx 5.x into the game folder - afterwards `Nuclear Option/BepInEx/core` should exist.
3. Download `NOVR.zip` from the latest NOVR release.
4. Extract the contents of `NOVR.zip` into `Nuclear Option/BepInEx` (NOT the game root - the zip already contains `plugins` and `patchers` folders).
5. Confirm these files exist:

```
Nuclear Option/BepInEx/plugins/NOVR/NOVR.dll
Nuclear Option/BepInEx/patchers/NOVR/NOVR.Patcher.dll
```

6. Launch Nuclear Option from Steam.

## First launch behavior
On startup, the NOVR BepInEx patcher copies the required XR support files into `NuclearOption_Data`. These may be overwritten every time the game starts. If the game is already running while installing or rebuilding, Windows can block those files from being replaced - so always close Nuclear Option before installing, updating, or building the mod.

## Credits
- **NOVR** by InfernoSuperNova - https://github.com/InfernoSuperNova/novr
- Fork of **UUVR** by Raicuparta - https://github.com/Raicuparta/uuvr
- Built on BepInEx (downloaded as a managed dependency by the installer)

>>> Arm the payload, bank hard, and rule the contested skies.

# Risk of Rain 2 VR

The installer keeps three independent routes. The detail-page tile splits **Current** and **1.4.1** when both are detected; the original DrBibop depot stays available as a separate legacy button.

## Option 1 — Current game version — Resurrected VRMod by Blowntobytes

### What the installer does

The Hub finds the normal Steam installation, asks Thunderstore for the newest Resurrected VRMod release, reads every manifest and recursively resolves its dependency chain. The package's own 1.0.4 manifest still names an obsolete dependency set, so the installer also applies the mod author's published r2modman-profile versions as minimum compatibility requirements: RoR2BepInExPack 1.43.0, FixPluginTypesSerialization 1.0.4, BepInEx GUI 3.0.3, SeekersPatcher 1.4.1 and MiscFixes 1.5.9. A newer main-package manifest may raise these versions, but never silently downgrade them. The installer warns when the main package or any dependency is marked deprecated, preserves existing BepInEx configuration and leaves unrelated mods alone.

Do not also load a separate r2modman profile containing DrBibop's original VRMod or a second Resurrected VRMod copy.

### Starting Current

Select the OpenXR runtime for the headset: VDXR for Virtual Desktop, Meta/Oculus for Quest Link, SteamVR OpenXR for Index or Vive, or WMR OpenXR for Windows Mixed Reality. Disable Steam Desktop Game Theatre for Risk of Rain 2.

Use [[Start Current]] in the split button, [[Start in VR]] when only this route exists, or launch normally through Steam. The first run places the native OpenXR files; if the headset stays black, close the game and try once more.

If `BepInEx\LogOutput.log` reports that `Newtonsoft.Json, Version=12.0.0.0` cannot be loaded, or shows RoR2BepInExPack 1.9.0, the obsolete dependency graph is still present. Run Current again; a successful repair installs RoR2BepInExPack 1.43.0 and its Newtonsoft runtime in the package-isolated r2modman layout before the Hub marks the route VR Ready. The bare `BepInEx\plugins\RoR2BepInExPack` layout is not valid here because the current preloader removes it during startup.

## Option 2 — Last confirmed working version — game 1.4.1 / Resurrected VRMod 1.0.3

### What the installer does

This is the update-round snapshot confirmed on 8 September 2026: Steam public build **21587608**, depot `632361` manifest `5715419509320521739`, game version **1.4.1**, and Resurrected VRMod **1.0.3**.

The game is copied to `C:\Games\Risk of Rain 2 1.4.1 VR` by default. The complete mod side is frozen: Resurrected VRMod 1.0.3, BepInExPack 5.4.2121, HookGenPatcher 1.2.9 and the compatible author-profile packages BepInEx GUI 3.0.3, FixPluginTypesSerialization 1.0.4, RoR2BepInExPack 1.43.0, SeekersPatcher 1.4.1 and MiscFixes 1.5.9. This route never follows Current auto-updates.

### Starting 1.4.1

Use [[1.4.1]] in the split button or the `Risk of Rain 2 1.4.1 VR` desktop shortcut. Do not use Steam Play for this copy; Steam opens the current retail installation.

## Option 3 — Original legacy depot — VRMod 2.9.2 by DrBibop

### What the installer does

This route preserves the earlier depot manifest `9058106608706845920` and DrBibop VRMod 2.9.2 with its original pinned dependencies. It installs to `C:\Games\Risk of Rain 2 VR` by default and is never advanced during normal update rounds.

### Starting Legacy

Use [[Start Legacy]] on the detail page or the `Risk of Rain 2 Legacy VR` desktop shortcut. SteamVR must be available. Do not use Steam Play, because it starts the current retail copy.

## Controls and settings

- [[Left Stick]] — move
- [[Right Stick]] — turn
- [[Right Trigger]] — primary skill
- [[Left Trigger]] — secondary skill
- [[Left Grip]] — utility skill
- [[Right Grip]] — special skill
- [[A]] — interact / confirm
- [[B]] — jump / back
- [[X]] — equipment / ready
- [[Y]] — pause; hold for scoreboard
- [[Left Stick Click]] — sprint
- [[Right Stick Click]] — ping and recenter

The game settings contain a VR tab for Auto Sprint, dominant hand, turn mode, aim pitch, HUD and seated mode. The configuration is `BepInEx\config\com.DrBibop.VRMod.cfg`; the maintained fork keeps the old internal plugin name for compatibility.

## Removal

For Current, remove only Resurrected VRMod's seven inventoried DLLs: `VRMod.dll`, `VRAPI.dll`, `Unity.XR.OpenXR.dll`, `Unity.XR.CoreUtils.dll`, `Unity.XR.Management.dll`, `Unity.InputSystem.dll` and `VRPatcher.dll`, plus `BepInEx\.ts_versions\Blowntobytes-Resurrected_VRMod`. Keep shared BepInEx, dependencies, configuration, saves and unrelated mods. For either depot, verify the dedicated folder name first and remove only that separate copy plus its matching shortcut. Never delete the normal Steam folder merely to remove VR.

## More information

- Maintained mod: https://thunderstore.io/c/riskofrain2/p/Blowntobytes/Resurrected_VRMod/
- Maintained source: https://github.com/Blowntobytes/RoR2VRMod
- Original mod and credits: https://github.com/DrBibop/RoR2VRMod
- Flat2VR discussion and support: join https://discord.gg/flat2vr, then open https://discord.com/channels/747967102895390741/978017782505545778/978018236576702494

>>> Seek and destroy. It's raining again!

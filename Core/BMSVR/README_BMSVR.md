# Black Mesa Source VR Installer

Automated installer for **Black Mesa Source VR (Beta 2.0)** — Ashok's unofficial VR port of Black Mesa Source: Extended Edition, built on top of the Half-Life 2: Episode 2 VR Mod.

## What it installs
- **The portable Mod Organizer 2 (MO2) instance** that ships bundled with the mod (~4–5 GB extracted)
- **Pre-configured BMS, XEN, and supporting mod profiles** (already inside the bundle)
- **Auto-patched MO2 paths** pointing to your actual HL2VR install (no manual `Tools > Settings` clicks)
- **Auto-patched `mods\XEN\gameinfo.txt`** with your actual Black Mesa install path
- **Optional 5.1 HRTF spatial audio** (DLLs + registry patch)
- **Two desktop shortcuts** (MO2 GUI + direct launch)

## Requirements

**Must be in your Steam library** (free if you own HL2 — adding from store is one click each):
- Half-Life 2 (220) — owned, doesn't need to be installed
- Half-Life 2: Episode One (380) — owned, doesn't need to be installed
- Half-Life 2: Episode Two (420) — owned, doesn't need to be installed
- Half-Life 2: VR Mod - Episode One (2177750) — owned, doesn't need to be installed
- **Half-Life 2: VR Mod - Episode Two (2177760)** — owned **and installed** (provides `ep2vr.exe`, the engine the mod runs on)

**Optional**:
- Black Mesa retail (362890) — only needed for the **2 bonus Xen 1.0 maps**. The full main BMS campaign uses Black Mesa Source assets bundled inside the mod archive and works without retail Black Mesa.

**Other**:
- Windows 10 / 11
- ~5 GB free disk space for the install folder
- VR headset with SteamVR

## How to use

1. Click **Install Mod** on the game tile or detail page
2. Read the prerequisites check at top — it will tell you if any Steam game is missing
3. Choose how to provide the mod archive (it's a .rar file):
   - Open Nexus in browser (you download the ~4 GB .rar), or
   - Enter path to a .rar you already downloaded (drag-and-drop works)
4. Choose install folder (default: `C:\Games\Black Mesa VR`)
5. Wait while the installer extracts and patches everything
6. Optionally enable HRTF surround audio
7. Use the new desktop shortcut to launch

## Why a manual Nexus download

The mod is hosted only on Nexus Mods. Free Nexus accounts cannot download via API, so the installer cannot fetch the file directly. You log in once on Nexus (free), download, then drag the .rar into the installer window.

## What gets auto-patched

This is a Source engine mod with absolute paths baked into config files. The bundled MO2 instance assumes you have HL2VR at `C:\Program Files (x86)\Steam\steamapps\common\Half-Life 2 VR` and Black Mesa at the equivalent path. If yours are elsewhere (different drive, different Steam library), the original install guide tells you to manually edit four things:

- MO2 → Tools → Settings → Paths → Managed Game
- MO2 → Tools → Executables → "Half-Life 2 VR" Binary + Start in
- `mods\XEN\gameinfo.txt` lines 46–50 (Black Mesa paths)

The installer does all of this automatically with regex path-replace, **and** keeps `.bak` copies of every patched file so nothing is unrecoverable.

## Desktop shortcuts

The installer creates two shortcuts:

- **`Black Mesa Source VR`** — uses the `ep2vr.exe` icon, launches the main BMS campaign directly via MO2 CLI. This is what you want 95% of the time.
- **`Black Mesa Source VR (MO2 Settings)`** — uses the Mod Organizer icon, opens the full MO2 GUI for switching to the Xen 1.0 profile, toggling Gonarch's Lair Fix, configuring mods, etc.

## How to play after install

The mod is **multi-profile** because BMS and Xen 1.0 use different mod sets that conflict.

**Simple case (main campaign)**: just use the `Black Mesa Source VR` desktop shortcut. Done.

**To switch profiles** (Xen 1.0 maps, Gonarch's Lair Fix, mod tweaks): open `Black Mesa Source VR (MO2 Settings)`.

- **Top-right dropdown** (executable): always `Half-Life 2 VR`
- **Top-left dropdown** (profile):
  - `Black Mesa Source VR` → main BMS campaign (Hazard Course, Anomalous Materials, Blast Pit, etc.)
  - `Xen 1.0 VR` → bonus retail Black Mesa Xen 1.0 maps (first 2 only, ported back to old Source)
- Click **Run** to launch

## About the optional 5.1 HRTF audio setup

The mod ships with [DSOAL](https://github.com/kcat/dsoal) + OpenAL Soft to restore proper 5.1 surround in VR — Source engine only delivers 2-channel stereo by default. Setting it up requires:

1. Copying `dsound.dll` + `dsoal-aldrv.dll` + `alsoft.ini` into the HL2VR folder (the installer does this).
2. Adding 7 DirectSound CLSID entries to the Windows registry so the game-local `dsound.dll` is loaded instead of the system one.

**The installer does step 2 natively in PowerShell** rather than running the bundled `DirectSound wrapper registry patcher.bat`. Reason: that `.bat` uses `SetACL` with the literal English group name `"Administrators"`, which **fails on non-English Windows** (German `Administratoren`, French `Administrateurs`, etc.) — you get a screen full of `FEHLER: Zugriff verweigert`. The native PowerShell approach writes only to `HKCU` (user-scope, doesn't need ownership changes) using the locale-independent SID `S-1-5-32-544` for any HKLM operations. HKCU has precedence for the current user, so the audio works correctly with HKCU-only writes.

**Caveat**: Windows updates occasionally wipe HKCU classes patches. If 5.1 audio stops working months later, just re-run this installer and pick `Y` for audio setup again. Or run these console commands in-game:

```
snd_legacy_surround 0
snd_surround_speakers 5
```

## Gonarch's Lair (special handling)

The Improved Xen mod's Gonarch is a hacked zombie reskin that breaks normal zombies in the rest of the campaign. So:

1. Tick `Gonarch's Lair Fix` in the MO2 mods list
2. Launch, select `Gonarch's Lair` from in-game chapter menu
3. After the chapter, **untick** `Gonarch's Lair Fix` again before playing other levels

## Known mod limitations (not installer issues)

- NPCs use HL2's simpler AI (less smart than retail Black Mesa)
- Marines/Vortigaunts won't engage Houndeyes/Bullsquids (causes CTD)
- Only HL2VR weapons supported (no Tau Cannon, Gluon Gun, Hivehand, Snarks, etc.)
- G-Man, Blast Pit Tentacle, Ichthyosaur are buggy
- Xen portals don't work — aliens spawn directly
- Dropships replaced with Apaches
- Jump module doesn't work — Xen platforming needs `noclip` cheat
- Map transition end of "Gonarch's Lair" doesn't work — chapter-select to Interloper
- Restart the game after Xen levels or earlier maps will have low gravity

## Updating from Beta 1

The installer is for Beta 2.0. If you have an older Beta 1 install, the official path is to download the **Beta 2.0 Update** archive separately, extract over the MO2 root, and run `update.bat`. This is not handled by this installer — fresh install is recommended.

## Credits

- **Linc** — VR port mod author, MO2 packaging
- **Crowbar Collective** — original Black Mesa Source
- **Hmodder** — Black Mesa Source: Extended Edition (the base this VR port uses)
- **Source VR Mod Team** — HL2:VR Mod and Episode One/Two VR
- **Vladislav "Zloikot" Lisovichenko** — Improved Xen
- Many other modders for Vent Mod, Loop Mod, On a Rail Uncut, Surface Tension Uncut

Mod page: https://www.nexusmods.com/halflife2episode2/mods/4

## Support Ashok

Ashok maintains the Black Mesa VR port. If you enjoy his work, consider supporting him:
- https://www.patreon.com/c/ashok0

>>> Welcome to Black Mesa. The cascade is just the beginning.

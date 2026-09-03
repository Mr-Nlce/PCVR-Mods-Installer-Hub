# Outward VR - Installer

<!-- hub:keep-order -->

Full 6DOF VR for Outward: Definitive Edition with motion-controlled combat.
**Two versions exist**, and the installer asks which one you want.

| | Runs on | Store |
|---|---|---|
| **1. CompoundVR fork** - recommended | current Mono build | Steam (`default-mono`) or a Mono GOG build |
| **2. Original v0.9.2 by cybensis** | an old build, downloaded as a pinned depot | Steam only |

Both can be installed side by side. They live in different folders, and the Hub then
offers a launch button for each.

---

## Mod 1 — CompoundVR fork — by cybensis & archangel

cybensis built the original and stopped at v0.9.2. The maintained CompoundVR fork carries
on from there and runs on the **current Mono build** of Definitive Edition. On Steam, select
`default-mono - Public default branch (mono)` under **Properties → Betas** first. This is
current game content with the Mono scripting backend; it is not the old pinned depot.

The downloaded fork currently contains **BepInEx 5.4.21 for Mono**. It cannot load on
Steam's default IL2CPP build. If the game starts flat and no BepInEx log is created, that
is the reason. The installer now checks for `Assembly-CSharp.dll` and refuses to report a
successful installation on IL2CPP.

### What changed against the original

- **Real hands and held weapons.** The old full-body rig is gone. The weapon in your right
  hand is the weapon you equipped - a lantern, a shield, a two-handed greataxe.
- **Motion controls that respond.** Swing your arm to swing the weapon; hold it out in
  front to block. Fast enough that combat is about timing and spacing.
- **Snap turning**, on by default. Head-bob stays off.
- **A gamepad fallback** when your arms need a break.
- Compatibility and performance fixes for the current game build.

### Installing it

Pick **1** when the installer asks. It finds your Outward install, verifies the Mono build
and copies the mod into it. After changing the Steam branch, wait for Steam's download to
finish and run the installer again so any replaced mod files are restored.

### VR settings and useful folders

The CompoundVR fork does **not** create an `OutwardVR.cfg`. Its adjustable VR options are
inside the in-game pause/options menu:

- **Allow headbob**
- **Move during attack**
- **Move direction: Hand / Headset**

Those choices, including the remembered first-/third-person state, are stored through
Unity PlayerPrefs rather than in a user-facing VR configuration file. Do not look for a
missing mod CFG.

After **Scan games** has found Outward, the paths below are clickable on this detail page:

- Game folder: `Outward_Defed\`
- BepInEx loader settings: `Outward_Defed\BepInEx\config\BepInEx.cfg`
- VR loader log (the quickest way to confirm that OutwardVR loaded):
  `Outward_Defed\BepInEx\LogOutput.log`
- Supplied SteamVR actions and controller bindings:
  `Outward_Defed\Outward Definitive Edition_Data\StreamingAssets\SteamVR\`
- Outward's normal graphics, audio and game options: `Outward_Defed\OptionSettings.oos`

Use SteamVR's **Controller Bindings** screen to change controller mappings instead of
editing the supplied JSON binding files by hand.

### What is still rough

It is a conversion, not a ground-up VR game. You will clip through geometry, find a menu
that renders too close, and see enemies telegraph in ways tuned for a third-person camera.
None of it is a session-breaker, but it is there.

---

## Mod 2 — Original v0.9.2 — by cybensis

The original beta only runs on an **old** Definitive Edition, so this route downloads that
exact build from Steam's depots into its own folder and installs the mod there. Your
current game is left untouched.

> **Steam only.** The depot comes from your Steam account. A GOG copy cannot provide it, so
> this route is not available to GOG owners - use the fork instead.

It plays the way the 2023 beta played, full-body rig and all. Pick this one if you
specifically want that build.

### What this installer does

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

### Launching

Always launch with **Start in VR** in the Hub or the desktop shortcut (or directly via
`Outward VR\Outward_Defed\Outward Definitive Edition.exe`) with
SteamVR already running. This VR install is fully standalone - it
lives outside your Steam library and is not touched by future
Steam updates to Outward.

### Controls

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

### Why not Steam Console?

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

### Why not opt into the beta branch in Steam?

The `default-mono` beta branch is now (2025/2026) on a newer
version than the mod was built against. Opting in will download
a newer build that the VR mod can no longer hook into - the game
starts but nothing actually renders in VR. The v1.0 DE mono
release manifest is pinned inside the DepotDownloader command
in this installer, and the installer also lets you paste a
different manifest if the default ever stops working.

### Security note

DepotDownloader is an open-source SteamKit2-based tool with 3000+
GitHub stars and is widely used for legitimate depot downloading.
This installer does not see or store your password or Steam Guard
code - DepotDownloader handles the login entirely in its own
process window. Your Steam username is the only thing this
installer records (in memory, only for the duration of the run,
to pass through to DepotDownloader).

### Credits

- Mod by cybensis
- GitHub: https://github.com/cybensis/OutwardVR
- Nexus:  https://www.nexusmods.com/outward/mods/277
- DepotDownloader by SteamRE:
    https://github.com/SteamRE/DepotDownloader

All tools and mod files are downloaded at install time from
official sources. Nothing is bundled with this installer.

>>> The wilds of Aurai await, Outlander.

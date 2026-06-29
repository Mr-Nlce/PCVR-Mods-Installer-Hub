# Escape from Tarkov VR (SPT-VR) Installer

Motion-controlled VR for SinglePlayer Tarkov (SPT), built on the open-source SPT-VR mod by cybensis (matsix).

## What it does
1. Locates your separate **SPT** install (drag SPT.Launcher.exe onto the installer) — or helps you set SPT up from scratch via the official SPT Installer
2. Downloads the latest **SPT-VR** release straight from GitHub
3. Merges the mod (BepInEx + EscapeFromTarkov_Data) into your SPT folder
4. Writes a **Start SPT VR.bat** launcher (starts the SPT server, waits for it, then opens the SPT launcher)
5. Creates a **SPT VR** desktop shortcut to that launcher

## Requirements
- A working, up-to-date copy of **Escape from Tarkov** (Steam or BSG Launcher) — the SPT Installer copies and down-patches those files; it never modifies your live install
- **SPT** (SinglePlayer Tarkov) — the installer can set this up for you
- **SteamVR** and a VR headset with **motion controllers**
- A high-end PC — this is a heavy mod (modern CPU, 16GB+ VRAM, 32GB+ RAM recommended)

## Important
- **Never** use this on the live, online Escape from Tarkov — it is offline-only and using VR/mods online can lead to a ban.
- SPT is completely separate from your live game: you can keep updating EFT without affecting SPT.

## Launching
1. Start **SteamVR** and put your headset on.
2. Use the **SPT VR** desktop shortcut (or **Start in VR** in the Hub). It starts the SPT server, waits until it is ready on `127.0.0.1:6969`, then opens the SPT launcher.
3. In the launcher, register/log in to a profile and press **Play**.

The SPT server must be running while you play; the shortcut handles that for self-hosting. If you connect to a **remote / headless Fika** server, start `SPT.Launcher.exe` directly instead.

To uninstall, remove the SPT game folder (the folder containing `SPT.Launcher.exe`).

## Controls

Most controls can be remapped via SteamVR controller bindings.

**Movement**
- **[[Left Stick]]:** Walk
- **[[Right Stick]]:** Look around; click = Sprint; push up = Jump; hold up at a ledge = Vault; pull down = Crouch
- **Prone:** fully crouch, release, then pull down again

**Weapons**
- **[[Right Trigger]]:** Fire
- **[[Left Grip]]:** Support a two-handed weapon when it vibrates; near a sight = change red-dot/holo mode
- **[[Left Trigger]]:** Hold to steady aim (hold breath)
- **[[Right Grip]]:** Hold (when not aiming) for the weapon-interaction menu — check mag, reload, inspect, fix malfunction, toggle firemode
- **[[B]]:** Reload
- **[[A]]:** Toggle firemode (when two-handing)
- **Optic zoom:** pull **[[Right Stick]]** or rotate your left hand near the scope
- **Grenades:** pick from the radial, hold **[[Right Trigger]]** to pull the pin, do a throwing motion and release; **[[Left Trigger]]** cancels

**Interactions**
- **Draw / holster:** hand to hip + **[[Right Grip]]** = pistol; hand to shoulder + **[[Right Grip]]** = primary; hold at shoulder for the weapon radial
- **Quick slots:** hand over your non-dominant shoulder, hold **[[Grip]]**, pick with the stick, release
- **Loot / doors / bodies:** look at the object for a menu (navigate with **[[Right Stick]]**, select with **[[A]]**), or reach with the left hand and **[[Left Grip]]**
- **Visor / night vision:** left hand to head + **[[Left Grip]]**
- **Headlight:** left hand to head + **[[Left Trigger]]**

**Menus**
- **[[A]]:** Select (laser pointer); hold = item sub-menu; double-tap = item display
- **[[X]]:** Inventory (in raid)
- **[[Y]]:** Menu (in raid)
- **[[Right Trigger]]:** Drag items
- **Quick equip:** hold **[[Left Grip]]** + **[[A]]** on an item
- **Quick transfer:** hold **[[Right Grip]]** + **[[A]]** on an item

## Performance tips

SPT-VR is extremely demanding, and the AI is the single biggest performance killer. The largest gains:

- Install a VRAM cleaner: https://hub.sp-tarkov.com/files/file/2876-vram-cleaner/ (also on the Forge: https://forge.sp-tarkov.com/mod/2173/vram-cleaner)
- Set most graphics options to low/off, but keep **textures, shadows, anisotropic filtering** and **LOD/visibility** to taste. Anti-aliasing must be **off or FXAA** - nothing else works. On 10GB VRAM or less, set textures to medium/low.
- In the lower graphics checkboxes enable **Grass shadows**, **High quality color** and **Streets low quality textures**; leave the rest off (volumetric lighting is your choice). On 10GB VRAM or less also enable **Mip Streaming** - it frees a lot of VRAM.
- Use an upscaler: **DLSS** (Nvidia) or **FSR3** (AMD).
- In SteamVR, open the per-app video settings for Tarkov and set the resolution to **100-150%** (lower = much faster). This is one of the heaviest settings; high resolution needs lots of VRAM and stacks with your upscaler.
- Install a bot-spawner mod such as **MOAR** or **ABPS** - they manage AI spawns far better, which is the biggest single gain.
- A **headless Fika client** can help, ideally on a separate PC on your network (32GB+ RAM, decent CPU). Self-hosting headless on your gaming PC wants 64GB+ RAM.
- Disabling a secondary 4K monitor while playing can help a little.

## Recommended hardware

A very heavy mod - it will not run well on low- or mid-range PCs.

- GPU (Nvidia): RTX 30-series or newer, 16GB+ VRAM
- GPU (AMD): RX 7000 (RDNA3/4) or newer, 16GB+ VRAM
- CPU: an AMD X3D chip is strongly recommended (5800X3D, 9800X3D, etc.)
- RAM: 32GB minimum with a separate headless PC; more if self-hosting
- Storage: SSD, NVMe preferred (not critical)

Slightly lower specs may work, but this is what's recommended for a playable experience.

## FAQ

**Which headsets and controllers are supported?**
Most VR headsets work. Quest 2/3, Valve Index and Vive controllers work out of the box; for anything else, set up the control scheme via SteamVR bindings.

**Does it work with the normal (non-SPT) Escape from Tarkov?**
No. Using it on the official online game can get you banned - SPT only.

**Does it support Fika?**
Yes. VR players appear as normal (non-VR) players to others in multiplayer.

**Are other mods compatible?**
Many are. Mods that add new UI often won't work, some new guns may miss features, and some graphics mods can cause issues - remove incompatible mods before reporting bugs. Confirmed working include Fika, Hollywood Graphics/FX, SAIN, Waypoints, Declutterer, BigBrain and Epic's AIO modded scopes (still rough). Best approach: add mods one at a time.

## Credits
- **cybensis (matsix)** — SPT-VR mod — https://github.com/cybensis/SPT-VR
- **SPT team** — SinglePlayer Tarkov
- **Battlestate Games** — Escape from Tarkov
- Support / Discord: https://discord.gg/U8B8h3s6SN

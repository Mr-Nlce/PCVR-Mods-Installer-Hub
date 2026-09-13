# F.E.A.R. VR Installer

<!-- hub:keep-order -->

Two separate VR mods are available. Pick the one that matches your game copy:

| | Game edition | Source |
|---|---|---|
| **Mod 1: thefreemike** | GOG F.E.A.R. Platinum Collection | current stable public release from GitHub, downloaded automatically |
| **Mod 2: DR-89** | Steam Ultimate Shooter Edition | latest open beta from GitHub, downloaded automatically |

Both may be installed at the same time because they use different game and mod folders.
When both real mod markers are present, the Hub shows one launch button for each.

## Mod 1 — F.E.A.R. VR GOG build — by thefreemike

### About this mod

TheFreeMike's public VR mod adds tracked hands, physical weapon handling, stereo VR,
configurable controls and comfort options to the original F.E.A.R. campaign. Choose
**Grip & Holsters** for physical body draws or **Classic Sticky** for conventional weapon
switching. This is the maintained continuation of the former private release candidates.

### Supported game and runtime

- **GOG F.E.A.R. Platinum Collection only.** Steam, retail, the expansions and multiplayer
  are outside this build's supported scope.
- Windows 10 or 11 and a PC VR headset are required. Quest 3 with Touch controllers is
  the author's physically validated baseline; other hardware remains experimental.
- Virtual Desktop: select **VDXR**, connect first and keep SteamVR closed.
- Steam Link or another SteamVR headset: start SteamVR, connect first and use a build with
  Win32/32-bit OpenXR support.
- Meta Quest Link and Air Link are unsupported, including through SteamVR.

### Before installation

Start the unmodified GOG game once, reach its main menu, load a level and then quit. Fix
any flat-game launch problem before adding VR. The author's Setup checks the supported
game executable and should be pointed at the folder containing `FEAR.exe`.

### Installing and updating

The Hub resolves the latest stable public GitHub release and opens the author's native
`F.E.A.R. VR Setup.exe`; its `setup-files` folder must remain beside it. Choose **Install
F.E.A.R. VR** for a new setup or **Upgrade F.E.A.R. VR** for RC6.2 or another earlier
private beta. A direct upgrade preserves the existing backup lineage, saves and profiles.
Do not uninstall an earlier thefreemike build first and do not manually mix release ZIPs.

The release files are unsigned. Keep antivirus protection enabled and review a warning
normally. A SHA-256 match supplied by GitHub can be shown as a positive confirmation, but
a missing or changed digest never blocks a newer release. The Hub records success only
after the actual VR launcher, bridge DLL and generated uninstaller exist and survive the
antivirus recovery check.

### Controls

| Action | Control or setting |
|---|---|
| Menus | Point with a controller and select with its trigger |
| Pause on SteamVR Touch | Press **Right A + Left X** together |
| Pause on the suggested Index layout | Press **Right A + Left A** together |
| Walk / run | The movement stick starts in run mode; with **Tap to Walk**, tap the stick to toggle walking |
| Medkit | Hold the configured utility control; tapping and holding are separate actions |
| Physical weapon use | In **Grip & Holsters**, reach to a body slot and use Grip; the weapon wheel is disabled in this mode |
| Conventional weapon use | In **Classic Sticky**, tap to switch or hold to open the weapon selector |
| Manual reload | Follow the weapon-specific pouch, magazine and chambering prompts |
| Ladder | Hold Grip at the ladder and move the hand; release to let go |
| Reconfigure controls | **Options > VR Settings > Controls & Layout** |

The installed `FEAR-VR-Install` folder contains the full controls, calibration,
troubleshooting, limitations and controller-layout guides. Layouts are saved per reported
controller profile and weapon hand.

### Launching, removal and support

Use the **thefreemike** launch button in the Hub or `F.E.A.R. VR.exe` in the GOG game
folder. To remove it, use **Uninstall thefreemike** on the detail page; the author's
`FEAR-VR-Install\Uninstall F.E.A.R. VR.exe` restores managed originals while retaining
saves, profiles and deliberately preserved changed files.

Project and stable releases: https://github.com/thefreemike31/fear-vr

GitHub issues: https://github.com/thefreemike31/fear-vr/issues

Discord discussion and support: https://discord.gg/NtAnbK6z9B

## Mod 2 — F.E.A.R. VR Steam build — by DR-89

### About this mod

An open-source OpenXR mod for the single-player base game of F.E.A.R. 1.08. It renders
true stereo from the LithTech camera and adds motion controls, a stereo HUD and VR menus.
This is an early open beta; issues are expected.

### Highlights

- Native per-eye stereo rendering, toggleable with [[F8]].
- Relative head tracking with recenter and optional HMD translation.
- Full motion controls for movement, turning, jumping, crouching, sprinting, weapons,
  grenades, slow motion, aiming, firing and interaction.
- Right-hand weapon, aim laser, hand flashlight and shot haptics.
- World-locked VR panel for menus, loading screens and mission briefings.
- A VR settings page inside the Escape menu.

### Requirements

- F.E.A.R. 1.08 Ultimate Shooter Edition on Steam.
- F.E.A.R. Public Tools 1.08. The Hub locates or installs it and performs the required
  Monolith registry step through a visible UAC prompt.
- An OpenXR runtime and headset. SteamVR and VirtualDesktopXR are confirmed.

The installer validates the expected executable build. Unsupported game builds stay
unhooked and run flat instead of being patched blindly.

### HD textures

The author recommends **HD Textures for F.E.A.R. & Extraction Point v2.0.2** by Rivarez.
It is a separate 5.06 GB ModDB download. The Hub can unpack
`HDTextures4FEAR_XP_v2.0.2.rar` and run the texture pack's own installer. Its **Steam
option is on the right and is not preselected**. Select it before clicking Install.

### What the installer does

The newest GitHub release is selected with prereleases included. Current overlay releases
are prepared inside the game; older staged releases remain supported. The real
`fearvr-host.exe` marker is checked in both layouts, and the selected install root is
recorded separately from the GOG mod so neither installation hides the other.

If GitHub cannot be reached, the installer offers a deliberate manual ZIP choice. It does
not silently take an arbitrary archive from Downloads.

### Controls and launching

| Action | Default control |
|---|---|
| Move / sprint | [[Left stick]] / [[Left grip]] |
| Turn / jump / crouch | [[Right stick]]; up jumps and down crouches |
| Recenter | [[Right stick click]] |
| Weapon / reload or grenade | [[A]] / [[B]] |
| Slow motion / pause | [[X]] / [[Y]] |
| Use / aim and fire | [[Right grip]] / [[Right trigger]] |
| Hand flashlight | [[Left trigger click]] |

Start SteamVR or Virtual Desktop first, then use the **DR-89** launch button in the Hub or
the F.E.A.R. VR desktop shortcut. If the VR host crashes, the game may continue flat.
Mouse, keyboard and gamepad remain available.

### Known limitations and source

The D3D9 stereo path and stereo HUD use CPU readback. HMD translation has no world
collision and remains opt-in. The left system button cannot be bound because SteamVR
captures it.

Project and prereleases: https://github.com/DR-89/fear-vr

>>> Slow time. Check the shadows. Alma is already here.

# Warhammer 40,000: Rogue Trader VR

<!-- hub:keep-order -->

Two separate VR mods use Owlcat's built-in Unity Mod Manager. Both may remain on disk. The Hub's Play choices activate one mod at a time in `Params.xml` before starting the game. Close Rogue Trader before switching. The shared game is counted once.

## W40KRT_VR by Beren5556 - option 1

*Lay the Koronus Expanse across your command table.*

### About the Game

This OpenXR beta presents Rogue Trader as a three-dimensional tabletop inspired by Demeo. Motion controllers can move, rotate, tilt and scale the scene, point at characters and menus, and switch between tabletop, closer character and first-person views. The story and combat remain Rogue Trader's own. The publisher describes this as a beta, not a promise that every headset or game build works.

### Requirements

- Steam edition of **Warhammer 40,000: Rogue Trader**, on the build validated by the release. The v0.9.81 package checks game files against Steam build **24257885** before installing. A later game patch may require a new VR release.
- 64-bit Windows 10/11, DirectX 11, a supported OpenXR provider and motion controllers. The v0.9.81 package offers VDXR/Virtual Desktop, Meta Quest Link/Air Link and Pimax OpenXR. SteamVR is not required by this mod.
- The game's Owlcat profile must exist: start the unmodified game once and quit. Close the game before installing, updating, removing or changing VR mods.
- NVIDIA RTX 4080, 5080 or 4090 is the publisher's high-quality recommendation, not a minimum guarantee. Begin with the Performance profile on slower hardware.

### Install and update

1. Open the Hub installer, read the opening notes and choose **[1] W40KRT_VR**. This selection confirms the notes and begins that installer. The Hub finds the Steam game or lets you select the folder containing `WH40KRT.exe`.
2. The Hub resolves a matching GitHub release, including prereleases, and downloads its `W40KRT_VR-...zip` asset. If the download fails, use the retry or manual file option. The attached v0.9.81 package is a reference build; a newer matching prerelease can be installed automatically.
3. The Hub checks the full archive, temporarily disables RTVR in Owlcat's mod settings, then runs the publisher's own installer. If an older W40KRT_VR needs a settings reset, the publisher asks you to approve a verified backup first. Read and answer that prompt.
4. Only after the publisher returns success and the required mod DLL, launcher, metadata and receipt are present does the Hub record the installed version. Its scan and Update badge then refer to this route's version only. The RTVR folder, WASD Movement, Toy Box and saves remain separate.

The Hub keeps a copy of the installed publisher ZIP next to `UnityModManager` as `W40KRT_VR-package.zip`, so the matching publisher uninstaller can be recovered. Missing files after setup do not by themselves prove an antivirus cause. Check the installer log and file paths; review antivirus history if it reports a matching event.

### Play

Connect the headset and controllers in your provider's PC application. Choose **Play Tabletop** in the Hub. That choice enables RTMaquetaXR, disables RTVR if installed, and opens the publisher's `W40KRT-VR-Launcher.exe`. Select the headset and connection there, then launch in DirectX 11. Start Steam first. Normal game launch remains available without VR.

When both mods are installed, the Hub shows separate **Tabletop** and **Gamepad** Play choices. Do not start the other mod while the game is running. The two mods can coexist on disk; the publisher does not claim simultaneous in-game compatibility.

### Motion controls

| Button | Action |
| --- | --- |
| [[Right Trigger]] or [[A]] | Point with the right skull and select. |
| [[Right Trigger]] (hold over a character or ship) | Enter first person. |
| [[B]] | Leave first person, cancel or go back. |
| [[Right Stick]] | Move the party in exploration or scroll menus. |
| [[Left Stick]] | Rotate or tilt the tabletop. |
| [[Left Grip]] or [[Right Grip]] | Grab and move the tabletop. |
| [[Left Grip]] + [[Right Grip]] | Rotate or scale the tabletop with both hands. |
| [[Left Grip]] + [[Left Trigger]] | Open the left action wheel. |
| [[Right Grip]] + [[Right Trigger]] | Open the right action wheel. |
| [[Left Stick Click]] | Switch actions and participants while the left wheel is open. |
| [[Y]] | Show tactical information or highlight interactables. |
| [[X]] | Pause or resume. |
| [[Right Stick Click]] | Toggle contextual reminders. |
| [[Left Trigger]] + [[Right Trigger]] + [[Left Grip]] + [[Right Grip]] | Open VR settings after holding for one second. |
| [[F1]] | Open VR settings from the keyboard. |

Controls change with the current game screen. The mod includes contextual help and an illustrated guide. Optional OFXR frame generation is experimental and off by default; restart the game after changing it.

### Remove W40KRT_VR

Close the game. Extract the saved matching `W40KRT_VR-package.zip` from beside `UnityModManager` to a fresh folder and run its `UNINSTALL.cmd`. That publisher tool removes files owned by RTMaquetaXR and preserves settings, logs, saves and other mods. Do not delete the whole `UnityModManager` folder. The Hub remover clears its route-specific receipts; a later scan also requires actual mod files before showing VR Ready.

Source and release notes: https://github.com/Beren5556/W40KRT_VR/releases

## RTVR by SolemnScribe - option 2

*Command your dynasty in true stereo 3D, Lord Captain.*

### About the Game

Automated installer for RTVR by SolemnScribe - true stereo-3D VR for
Owlcat's Warhammer 40K cRPG. Seated play with keyboard & mouse or
gamepad; the game's UI lives on a floating panel in front of you.
No motion controllers.

### Gamepad and keyboard controls

| Button | Action |
| --- | --- |
| [[A]] | Rotate camera left after the required rebind. |
| [[D]] | Rotate camera right after the required rebind. |
| [[Q]] | Pan camera left after the required rebind. |
| [[E]] | Pan camera right after the required rebind. |
| [[WASD]] | Move the selected character through WASD Movement. |
| [[Ctrl+Alt+V]] | Start or stop VR manually. |
| [[Ctrl+F10]] | Open the RTVR settings overlay. |
| [[Left Shift]] | Unlock the mouse cursor while held. |
| [[Ctrl+Alt+C]] | Recenter the view. |
| [[Ctrl+Alt+Left Bracket]] and [[Ctrl+Alt+Right Bracket]] | Change world scale. |
| [[Ctrl+Alt+-]] and [[Ctrl+Alt+=]] | Change stereo depth scale. |
| [[Ctrl+Alt+0]] | Reset world and stereo depth scale. |
| [[Ctrl+Alt+,]] and [[Ctrl+Alt+.]] | Move the UI panel. |
| [[Ctrl+Alt+U]] | Show or hide the UI panel. |

### What it does
1. Locates your Rogue Trader install (Steam, GOG, Epic or Xbox - for
   information only; the mods do NOT go into the game folder)
2. Verifies the game has been launched once, so Owlcat's BUILT-IN
   Unity Mod Manager profile folder exists
3. Guides you through the Nexus downloads (Nexus requires a login,
   so downloads are manual) and installs, in order:
   - WASD Movement (required)
   - Toy Box (required)
   - RTVR - the VR mod itself
   - Servo-Skull Camera Controls (asked as optional Y/N at the end)
4. Walks you through the four required camera key rebinds

### Where the mods actually live
Rogue Trader ships with its own built-in Unity Mod Manager. It loads
mods ONLY from your user profile - not from the game folder:

    %USERPROFILE%\AppData\LocalLow\Owlcat Games\Warhammer 40000 Rogue Trader\UnityModManager\

Each mod sits in its own subfolder there (RTVR, WASDMovement,
0ToyBox0, ServoSkullCameraControls). To uninstall a mod, delete its
subfolder.

### Requirements
- Windows 10/11
- **Warhammer 40,000: Rogue Trader** (Steam, GOG, Epic or Xbox/Game
  Pass), launched at least once
- SteamVR installed
- A Nexus Mods account (free) to download the mods
- Note on Nexus: after you click MANUAL DOWNLOAD, Nexus shows a
  REQUIREMENTS page listing the mods that file depends on. That is
  expected - this installer sets those up for you. Just click MANUAL
  DOWNLOAD a second time to start the actual download.
- WASD Movement and Toy Box are REQUIRED by RTVR; Servo-Skull Camera
  Controls is optional (3rd-person over-the-shoulder camera - RTVR
  builds on its camera work and they pair well)
- For Toy Box choose the stable **ToyBox 1.7.34** main file. Nexus also
  lists a separate 2.0 Beta rewrite, but RTVR does not currently confirm
  compatibility with that branch, so the installer does not recommend it.

### Mod pages
- RTVR: https://www.nexusmods.com/warhammer40kroguetrader/mods/518
- WASD Movement: https://www.nexusmods.com/warhammer40kroguetrader/mods/334
- Toy Box: https://www.nexusmods.com/warhammer40kroguetrader/mods/1
- Servo-Skull Camera Controls: https://www.nexusmods.com/warhammer40kroguetrader/mods/457

### Required key rebinds (one time, in-game)
In Settings -> Controls rebind these four, or the camera will fight
the WASD character movement:
- Rotate camera left -> **[[A]]**
- Rotate camera right -> **[[D]]**
- Pan camera left -> **[[Q]]**
- Pan camera right -> **[[E]]**

### How to play
1. Start SteamVR
2. Launch with **Start in VR** in the Hub, or normally (Steam may warn it is not VR - click OK)
3. Load into a save - VR starts automatically
4. Play seated with keyboard & mouse or a gamepad

### Shortcuts
Every RTVR shortcut is Ctrl+Alt plus a key, so nothing clashes with
the game's own bindings. Changes are live and saved between sessions.

The essentials:
- **[[Ctrl+Alt+V]]:** start/stop VR manually
- **[[Ctrl+F10]]:** open the mod settings overlay (NOT Shift+F10)
- **[[Left Shift]] (hold):** unlock the mouse cursor
- **[[Ctrl+Alt+C]]:** recenter the view - the one you will reach for
  most, whenever "forward" has drifted
- **[[WASD]]:** move the selected character (via WASD Movement; slow /
  normal / fast walking speeds available in its settings)

Framing and panel (live):
- **[[Ctrl+Alt+[ / ]]]:** world scale down / up (diorama vs life-size)
- **[[Ctrl+Alt+- / =]]:** IPD scale down / up (stereo depth comfort)
- **[[Ctrl+Alt+0]]:** reset world and IPD scale
- **[[Ctrl+Alt+, / .]]:** move the UI panel nearer / farther
- **[[Ctrl+Alt+' / ;]]:** make the panel wider / narrower
- **[[Ctrl+Alt+U]]:** hide/show the UI panel entirely

Comfort and misc:
- **[[Ctrl+Alt+W]]:** entity overtips floating in the world vs flat
  on the panel
- **[[Ctrl+Alt+X]]:** show/hide the desktop mirror manually
- **[[Ctrl+Alt+R]]:** toggle head roll (off can feel steadier)
- **[[Ctrl+Alt+P]]:** dump the UI state to the log - press it while a
  bug is on screen and include GameLogFull.txt in your report

### VR tuning tips
- RTVR's render scale ships at **0.75** - raise it toward 1.0 in the
  mod settings (Ctrl+F10) if your GPU has headroom
- The floating UI panel's size and distance are adjustable in the
  mod settings; world scale / IPD scale too if the world feels off
- In the game's own graphics options:
  - Depth of field: OFF (disorienting in a headset)
  - Camera shake: OFF (comfort)
  - SSR: Low or Off (big performance win)
  - FSR: OFF in VR (use RTVR's render scale instead)
  - Anti-aliasing: SMAA over TAA (less smearing in stereo)
  - Shadow quality and particles: Medium is a sensible balance for
    large combats - drop these before sacrificing render scale

### Important notes
- Seated, pancake-style VR: full stereo 3D world, flat UI on a
  floating panel. No motion controller support.
- Known issues (first public release, per the mod page):
  - Screen fades and cutscene letterbox covers render to the
    desktop, not the headset - transitions may pop rather than fade
  - The "Start the Battle" deployment banner sits at panel-center
    instead of the top; it is fully clickable where it sits
  - Space combat, the sector map and other full-screen views play on
    the UI panel rather than in full stereo (by design for now)
- For full-screen menus a desktop mirror appears in the headset
  automatically (see Ctrl+Alt+X under Shortcuts)
- Toy Box is a big tweak toolbox; RTVR only needs it installed. You
  do not have to enable any cheats.
- The settings panel follows the game's language (English plus 10
  bundled translations)

### Support SolemnScribe
SolemnScribe built both RTVR and the Servo-Skull Camera Controls mod
it grew out of. If you enjoy seeing Rogue Trader in true stereo 3D,
consider supporting the work:
- https://www.patreon.com/cw/solemnscribe

>>> Command your dynasty in true stereo 3D, Lord Captain.

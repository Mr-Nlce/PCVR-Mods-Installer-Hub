# Gloomhaven VR

GloomhavenVR by McFredward turns the digital adaptation into a room-scale
tabletop game. You stand at the board, pick up ability cards and miniatures
with motion controls, and manipulate the game windows as physical panels.

## About the Game

Gloomhaven is a tactical, card-driven dungeon crawler with a long solo or
co-op campaign. The VR mod keeps the original rules, campaign, saves and flat
players while presenting the board at room scale. It includes two VR
environments, mixed-reality options, physical cards and figures, a movable
control board and VR multiplayer support.

The mod is tested against Gloomhaven 1.1.8307.0. All VR players in one session
must use the same GloomhavenVR build; flat-screen players can still join them.

Current v1.0.7 adds campaign city events to the 3D map, keeps character and
quest windows when moving between 2D and 3D maps, improves map button hints
and multiplayer mirroring, and lets short [[B]] / [[Y]] taps rotate area effects.
The legacy stick rotation remains optional. Updating over an older build is
supported; the first updated launch may close and reopen once intentionally.
Multiplayer still requires every VR player to run the same mod version.

## Installer choices

- **Current** installs the newest stable GloomhavenVR release and the exact
  required BepInEx 5.4.23.5 x64 into the normal Steam, Epic or GOG game. This
  is the route for current online multiplayer.
- **Build 20286313** creates a separate Steam copy at
  `C:\Games\Gloomhaven VR 20286313`. It pins Gloomhaven 1.1.8307.0,
  GloomhavenVR v1.0.1 and BepInEx 5.4.23.5. It is intended as a stable solo
  fallback if a later game update breaks the mod; an old client may eventually
  lose online compatibility.

If Steam still has the exact supported build, setup can verify and clone it.
Otherwise it opens Steam Console only after an explanation and uses this
pinned command:

`download_depot 780290 780291 7912725515517904339`

The normal Steam installation is not overwritten by the depot route. The
pinned copy receives its own `steam_appid.txt`, launcher and desktop shortcut.

## Before the first VR start

Setup verifies and commits the complete BepInEx, plugin, patcher, native OpenXR
and asset-bundle payload without requiring a separate flat launch. The first VR
start can take longer while BepInEx generates its runtime files, and the game
may restart once while the mod applies its rendering settings. Disk logging can
be disabled, so a missing `BepInEx\LogOutput.log` is not an installation failure.

Make the intended OpenXR runtime active before starting the game:

- Virtual Desktop: select VDXR in the Streamer settings.
- Meta Quest Link: set Meta Quest Link as the active OpenXR runtime.
- Steam Link: set SteamVR as the OpenXR runtime in SteamVR settings.

The game may restart once when the mod applies compatible rendering settings.
That is expected after a first installation. GloomhavenVR keeps the original
`GH_Data\boot.config` beside it as `boot.config.gloomhavenvr-backup`.

## Controls

![GloomhavenVR motion controls](controls-en.png)

The image shows the default right-main-controller layout. Dominant hand,
movement and turning can be changed under the in-game **VR Options** tab.

| Button | Action |
|---|---|
| [[Left Stick]] | Move through the room |
| [[Right Stick Left / Right]] | Turn |
| [[Right Stick Forward / Back]] | Rise / sink |
| [[Stick Click]] | Hold and move that hand to pull yourself along |
| [[Both Stick Clicks]] | Rotate and zoom the table |
| [[Trigger]] | Take a card or pick up a figure; point and click while using the laser |
| [[Grip]] | Touch a hex; grab a bar to move a window or board |
| [[X]] | Open or close the pause menu and VR Options |
| [[A]] | Ping a hex for every player |
| [[Y]] + [[B]] | Hold for one second to recenter at your current position |

Play the first tutorial after installation; it demonstrates the physical VR
interactions directly at the table.

## Starting and switching modes

Start Current normally through Steam, Epic or GOG. Start the pinned route from
the **Gloomhaven VR 20286313** desktop shortcut. The Hub's Flat / VR switch
parks only BepInEx's `winhttp.dll`; it does not delete the mod or settings.
Inside the mod, VR can also be disabled by setting `Enabled = false` under
`[General]` in `BepInEx\config\dev.gloomhavenvr.cfg`.

## Updates and version tracking

Current follows stable GitHub releases automatically. The Hub reads the
installed `GloomhavenVR.dll` assembly version and records that exact version
only after the complete loader, plugin, patcher, OpenXR natives and asset
bundle have survived verification. The depot never resolves a live mod or
loader update into its pinned copy.

## Troubleshooting

- If the game stays on the monitor or the headset is black, verify the active
  OpenXR runtime first. If that is correct, try `-force-d3d11` as a game launch
  option.
- Keep `BepInEx\LogOutput.log` from the affected run when it exists and you ask for help. For
  repeatable issues, set `[General] LogLevel = Debug` and reproduce once.
- If required files disappear immediately after copying, setup reports the
  exact missing files and offers the shared antivirus-recovery flow. A missing
  file alone is not treated as proof of quarantine.
- All VR participants need the same mod build. A mismatch dialog deliberately
  blocks incompatible multiplayer sessions.

## Discord discussion & support

Join the [Flat2VR Modding community](https://discord.gg/flat2vr), then open the
[Gloomhaven VR channel](https://discord.com/channels/747967102895390741/1549192763680235590).

## Uninstall

Use **Uninstall now** on the game page. If Current and Build 20286313 coexist,
the uninstaller asks which independent route to change. It removes only
unchanged Hub-owned files, restores anything that existed before installation
and restores the mod's original `boot.config` backup. Saves, profiles,
configuration, unrelated BepInEx mods and the base game are preserved.

Removing the mod from Build 20286313 leaves its large game-data copy in place
so it can be reused. Delete that dedicated folder manually only if the
historical game copy is no longer wanted.

## Links and credits

- [GloomhavenVR project and illustrated guide](https://github.com/McFredward/GloomhavenVR)
- [Stable releases](https://github.com/McFredward/GloomhavenVR/releases)
- [VR gameplay](https://www.youtube.com/watch?v=chlkqErbip8)
- GloomhavenVR by McFredward; BepInEx by the BepInEx project.

*The cards are finally in your hands. Try not to exhaust them all at once.*

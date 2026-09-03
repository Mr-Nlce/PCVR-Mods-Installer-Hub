# Dishonored VR

A VR conversion of **Dishonored (2012)** by GingasVR: true stereo rendering, 6DOF head
tracking with lean and peek, motion controls on Arkane's own animation rig, roomscale
walking, and a Blink you aim with your hand. Built as a `d3d9.dll` proxy over a forked DXVK.

> **Alpha.** It works and it is rough in places - see the known issues at the bottom. Not
> affiliated with Arkane or Bethesda; it contains no game assets.

## Start in VR from the Hub, or launch through Steam

**The author supports the Steam version alone** - GOG, Epic and the Xbox app are not
supported at this time, even though the game exists there.

**Preferred:** click **Start in VR** for Dishonored in PCVR Mods Hub. The Hub always sends
Dishonored through Steam. You can also launch it from Steam yourself. Never launch
`Dishonored.exe` directly: that crashes at the menu.

| Headset | How |
|---|---|
| Vive / Index | SteamVR running, then use **Start in VR** or launch from Steam |
| Quest | Virtual Desktop streaming, **SteamVR not running**, then use **Start in VR** or launch from Steam. VD at 72 Hz, SSW off |

The mod picks the backend itself - OpenVR or OpenXR.

## What the installer does

It copies the mod's two folders into your Dishonored install, then offers to apply the
recommended 4032x2268 windowed resolution.

Dishonored should have been started once before setup so it can create the per-user
`DishonoredEngine.ini`. The installer checks for that file before it downloads or changes
anything. If it is missing, press Enter and Dishonored starts once through Steam. When the
main menu appears, quit from the menu, return to the installer, and press Enter to continue.

Before it replaces anything, the Hub keeps a verified `*.hubbak` copy of every differing
file already in the game. This matters for the eight original movie files and for anyone
who already used another `d3d9.dll` wrapper. The reversible ownership list is written to
`.pcvrhub-dishonored-install.tsv` in the game folder; reinstalling or updating preserves the
first backup instead of backing up an older mod version over it.

The resolution helper does **not** touch the game folder: it writes `ResX=4032 ResY=2268
Fullscreen=False` into your per-user `Documents\My Games\Dishonored\...\DishonoredEngine.ini`
and backs it up first.

## The first mission

**The prologue cutscene is glitched in VR.** The mod works around it by teleporting you to
the prison a few seconds into a new game, but some players still get stuck behind it.

If that happens, return to Dishonored's game detail page in the Hub and use **VR / Flat**
to select **Flat**. Play past the opening, quit the game, then use the same Hub switch to
select **VR** and continue.

The Hub switch parks one file, `Binaries\Win32\d3d9.dll`, which is the proxy the game loads at
startup. Nothing is deleted and nothing else is touched. It refuses to run while the game is
open, and it tells you which mode is active before you choose.

## Removing the mod

Close Dishonored first. The install record `.pcvrhub-dishonored-install.tsv` lists every
payload file. A line marked `remove` was introduced by the mod and can be deleted; a line
marked `restore` replaced something that was already there, so restore the adjacent
`<filename>.hubbak` copy instead. In particular, restore the eight original
`DishonoredGame\Movies\*.bik` files and any pre-existing `Binaries\Win32\d3d9.dll`.

The author's resolution helper makes its own backup of `DishonoredEngine.ini`. Restore that
too if you want the old resolution/fullscreen settings back.

## In the headset

[[F5]] recenters and sets your standing height. [[F10]] opens the settings overlay - mouse
only for now, there are no motion controls for it yet.

**Turn Motion Blur off** in the game's video options.

### Controls

| Action | Binding |
|---|---|
| Sword | swing your arm, or [[Right Trigger]] |
| Crouch | duck physically, or [[A]] on the right controller |
| Block / choke | [[Right Stick Click]] |
| Blink | [[Left Trigger]], aimed with your left hand |
| Crossbow, pistol, grenades | [[Left Trigger]], aimed with your hand |
| Interact | [[X]] on the left controller, or [[A]] on Index |
| Weapon wheel | [[Left Trackpad]] on Index, [[Left Grip]] on Quest, then [[Stick]] |
| Health | open the weapon wheel, press [[B]] on the right controller |

Lean by leaning physically. If the range feels short, adjust `RoomDeadM` and `RoomBleedMS`
in `Binaries\Win32\dishonored_vr.ini`.

### Hands sitting wrong

Press [[F5]] to recenter, then [[F10]] → **calibrate hands**, and use the trim settings at the
bottom of the hand section. **Save defaults** at the top when you are happy.

## Known issues in the alpha

- **Hands rotate with your head.** The animation is locked by Arkane and the author cannot
  currently change it; the hands still track position in 6DOF from your controllers.
- Some dynamic lights render inconsistently per eye - pub lamps, for instance.
- Fast-swinging thin objects such as hanging chains can shimmer between the eyes.
- A few vents and small spaces refuse a crouch; use Blink instead.
- **Possession, Devouring Swarm and Windblast aim with your head.** Only Blink is
  hand-aimed so far.
- Cutscene cameras are fixed - no head-look during cinematics.
- Menus occasionally shrink onto your hand, a side effect of the wrist HUD.

## Performance

It renders **4032x2268** in total, 2016x2268 per eye. The author developed it on an RTX 4090
and notes the game is CPU-bound in places. Plan on tuning.

## Credits

**GingasVR** built the mod. **Arkane Studios and Bethesda** made Dishonored. The translation
layer is a fork of **DXVK** (zlib), with **Dear ImGui** (MIT), the **OpenVR SDK** (BSD-3) and
the **OpenXR SDK** (Apache-2.0).

If you enjoy it, his Patreon is where the work is funded.

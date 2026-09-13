# Black Mesa VR

## What this installer does

This installs the current stable **Black Mesa VR** release by
Hochgeschwindigkeitsrennfahrer into the Steam version of Black Mesa. It adds
true stereo rendering, OpenXR, roomscale and 6DOF motion controls. The setup
backs up replaced files, keeps your VR configuration during updates and adds
the required `exec bmvr` line without replacing the rest of `autoexec.cfg`.

The release auto-updates from the author's stable GitHub channel. The Hub does
not contain or redistribute the VR mod archive.

## Start Black Mesa

Close the game during installation. Afterwards use **Start in VR** in the Hub,
the Steam entry, or the **Black Mesa VR** desktop shortcut. All Hub launch
routes use Steam and include the required `-oldgameui` option. The newer menu
can appear upside-down and leave a black world after loading.

If the game's Video menu still reports **Direct3D 9**, add `-enabledxvk` to
Black Mesa's Steam launch options. It is a fallback, not required for everyone.

## Start Black Mesa: Blue Shift

The same VR installation supports Black Mesa: Blue Shift. Install Blue Shift
from its [Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2424633574)
so its `bshift` folder sits inside the Black Mesa folder, then run this setup
again. The detail page will show separate **Black Mesa** and **Blue Shift**
start buttons, and setup adds a **Black Mesa Blue Shift VR** desktop shortcut.
The Blue Shift route starts through Steam with `-game bshift`; Calhoun keeps
bare hands and receives the blue weapon-wheel and wrist-HUD theme.

## OpenXR runtime

- Quest with Virtual Desktop: select **VDXR** in Streamer Options. Selecting
  SteamVR there inverts the world.
- Quest with Meta Link: use the **Oculus OpenXR** runtime.
- Steam Link and native SteamVR headsets: make **SteamVR** the active OpenXR
  runtime before launch.

Use one OpenXR compositor. Leaving the Oculus runtime active while SteamVR is
also running can create a waiting room and a second compositor.

## Controls

- [[Left Stick]] — move
- [[Right Stick]] — snap or smooth turn
- [[Right Trigger]] — attack
- [[Left Trigger]] — use
- [[A]] — reload
- [[B]] — alternate fire
- [[X]] — previous weapon
- [[Y]] or [[Left Menu]] — pause
- [[Left Stick Click]] — sprint; double-tap forward also sprints
- [[Right Stick Click]] — weapon wheel; tap to recenter
- [[Right Grip]] — flashlight

In VR menus, point with a controller and use [[Right Trigger]]. [[A]] confirms
and [[B]] goes back.

## Settings and performance

VR rendering and input settings live in `VR\config.txt`; weapon offsets live
in `VR\viewmodel_offsets.txt`. Setup preserves both. Render-scale changes need
a restart. If old Quest offsets pull weapons too far back, reset that weapon
with [[Numpad 0]].

Open and complex scenes can be demanding. The current release improves frame
times and Xen culling, but performance work continues. Two-handed weapons,
manual reloading and a Long Jump Module HUD indicator are still planned.

## Flat / VR and removal

Use the **VR / Flat** switch on this page for temporary flat play. It parks all
three required VR loaders together and can restore them without reinstalling.

**Uninstall now** removes only files recorded by this Hub setup, restores files
that existed before installation, removes only the `exec bmvr` line it added,
and preserves Black Mesa, Blue Shift, saves and user-edited settings.

The resonance cascade was an accident. The crowbar swings are entirely deliberate.

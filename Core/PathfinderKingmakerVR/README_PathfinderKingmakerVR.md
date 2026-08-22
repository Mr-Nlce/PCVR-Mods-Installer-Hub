# Pathfinder: Kingmaker

Pathfinder: Kingmaker is a party-based CRPG built on the Pathfinder tabletop
rules - you assemble a party of six, work through a long fantasy campaign of
quests and dungeons, and rule a barony of your own between adventures. Combat can
be played in real time with pause or fully turn-based.

**VRMaker** by **PinkMilkProductions** puts the whole campaign in VR. You look
down on the world like a table: grab it with both grips and pull, rotate and scale
it to move around - the way Demeo does. There is also a first-person mode you hold
a button for.

## Set the game's graphics options first

**Do this before anything else** - the Hub's installer walks you through it, and
if the mod is already installed it parks it for a moment so the game starts flat.

In **Settings > Graphics**:

| Setting | Value |
|---|---|
| V-Sync | off |
| Bloom | off |
| Depth of Field | off |
| HBAO | low |

These are **screen-space effects**: the game works them out from one image and
lays the result over both eyes. Left switched on you get blurred text, black
shadows stuck to the buildings, a picture so dark you only see outlines, and the
frame rate collapses.

## Switching back to flat - not the way you would expect

**Renaming or deleting the mod files does not give you the flat game back.**

The mod ships a patcher that rewrites `Kingmaker_Data\globalgamemanagers` and
puts **OpenVR** into Unity's own `enabledVRDevices`. That is the engine's VR
switch - it takes effect at startup, *before* any plugin loads. With the mod
files gone the game still starts in VR mode, but nothing is driving it, and you
get **a blank blue screen instead of the main menu**.

The patcher makes a backup first. To go flat:

    Kingmaker_Data\globalgamemanagers.bak   ->  copy over  ->  globalgamemanagers

To go back to VR, run the Hub's installer again rather than swapping the file
back by hand. The Hub's installer does this swap for you when it needs the game
flat, and puts it back afterwards.

If the `.bak` is ever missing: Steam > Properties > Installed Files > *Verify
integrity of game files*.

## SteamVR, not OpenXR

This mod is built on SteamVR (`openvr_api.dll`, `SteamVR.dll`, its own
`actions.json`). **Start SteamVR before the game.**

Controls are configured for **Oculus Touch** (Quest 2 / 3) and most likely the
**Valve Index**. Anything else can be rebound in SteamVR's own binding interface.
The author tested Quest 2, Quest 3 and a Pimax 5K Super with Index controllers.

## How far along it is

The author's own words: *almost playable start to finish*, about **95% of the way
to a 1.0**. Two known gaps:

- **Kingdom management** is not done - play that part flat
- The **frame rate dips in your own town hub**; elsewhere it held up in his tests

First-person movement is plain continuous walking and turning. There are no
comfort options yet, and menus or loading screens can be janky - worth knowing if
your VR legs are new.

## Controls

| Input | Action |
|---|---|
| [[A]] right | interact |
| [[B]] right | whatever B does |
| [[X]] / [[A]] left | pause - **hold** for first-person mode |
| [[Y]] left | abilities bar - **hold** for the escape menu |
| [[Left Trigger]] | party member select |
| [[Right Trigger]] | in-game menus: stats, equipment, journal |
| both [[Grip]] | hold and move your hands to pull, rotate and scale the world |
| [[Left Stick]] | move |
| [[Right Stick]] | turn - first-person mode only |

In combat, **point your controller** at where you want to go or who to attack.
Think of it as a laser pointer for the mouse.

## What the installer does differently

The release is packaged for **Raicuparta's Rai Manager** - a 37 MB manager
application with the mod tucked inside it. The Hub installs **only the mod** and
leaves the manager alone.

That takes one extra step the manager would normally do: the shipped
`doorstop_config.ini` contains an **absolute path from the author's own machine**
(`C:\VRProjects\VRMaker\...`). Left as it is, BepInEx never loads, the mod does
nothing, and there is no error message at all. The installer rewrites that line to
point at the game's own `BepInEx` folder.

## Which editions work

The author's own manifest lists **Steam** (app 640820) and **GOG**. The Enhanced
Plus Edition on Steam is that same app, so it is covered.

Epic is **not** in his manifest - the Hub knows the path and will find the game
there, but the mod is untested on it.

## Uninstalling

**First**, restore `Kingmaker_Data\globalgamemanagers` from its `.bak` - see the
section above. Skip this and the game will not start properly no matter what else
you delete.

Then, beside `Kingmaker.exe`: delete `winhttp.dll`, `doorstop_config.ini`, the
`BepInEx` folder and the `VRMakerAssets` folder. Then in `Kingmaker_Data\Managed` delete
`SteamVR.dll` and `SteamVR_Actions.dll`, in `Kingmaker_Data\Plugins` delete
`openvr_api.dll` and `SteamVR_Actions.dll`, and in
`Kingmaker_Data\StreamingAssets` delete the `SteamVR` folder.

Once `globalgamemanagers` is back, the game runs flat again straight away - menu
cutscene and all.

## Credits

Mod by **PinkMilkProductions** - https://github.com/PinkMilkProductions/VRMaker

Built on **BepInEx** and **Unity Doorstop**, packaged with **Raicuparta's Rai
Manager**. An unofficial fan project, not affiliated with Owlcat Games.

>>> Your kingdom can wait. The dice cannot.

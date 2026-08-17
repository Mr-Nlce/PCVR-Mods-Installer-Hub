# The Legend of Zelda: Twilight Princess VR

**Dusklight VR** by **JoeyAW** - a VR port of Twilight Princess built on the
Dusklight decompilation. Not an emulator hack: the game runs natively, and it
aims to stay as close to the original as it can while letting you stand inside
it.

## What you get

- Full stereoscopic 3D with tracked controllers
- **Physical sword swinging, shield bashing and aiming** - you aim with your
  right hand
- A flatscreen toggle for any part you would rather not play in the headset
- Quest 2 / 3 bindings

## You supply the game

**This port ships no game data whatsoever.** You need your own dump of the
**GameCube** release - the Wii versions are not supported yet.

Dolphin's wiki explains how to dump a disc you own. Afterwards, Dolphin or
`nodtool` can convert the `.iso` into the much smaller `.rvz`.

## About the download size

The release is **over 500 MB packed and roughly 2 GB unpacked**, and that is not
a mistake on your end: the author ships his complete build folder, compiler
leftovers and all. The parts that actually run the game are a fraction of it.
Nothing is broken if the unpacking takes a few minutes.

The Hub's installer puts it wherever you choose - it is standalone and does not
go into any existing game folder.

## Optional: the 4K texture pack

Henriko Magnifico's pack redraws the game's textures at 4K and works with
Dusklight. The Hub's installer offers to set it up.

**It is large** - around 5 GB unpacked, 1823 texture files. Purely cosmetic; the
game runs fine without it.

The pack is hosted on the author's own site, so the installer opens the page and
picks the file up from your Downloads afterwards:
https://www.henrikomagnifico.com/zelda-twilight-princess-4k

The textures do **not** go into your install folder. They belong here:

    %APPDATA%\TwilitRealm\Dusklight\texture_replacements\HenrikosTP4K_...\

Keep the pack's own **HenrikosTP4K...** folder intact directly below
`texture_replacements`. Do not move its texture or province folders one level
up, because Dusklight expects the pack directory itself to remain there.

And one switch is left to you: in the game, **Settings > Video > Use Texture
Pack**. Without it the files sit there and do nothing.

## Requirements

- Windows, and a GPU that supports **D3D12**
- **Quest 2 or 3** - other headsets are untested, controls especially
- **Virtual Desktop with VDXR** is the author's recommendation for performance;
  SteamVR and Meta Link also work

## Playing

Start your VR software **first**, then launch Dusklight. A window opens on your
desktop - press [[Enter]] there or click **Play** to start. **Nothing appears in
the headset until you do**, so that empty view is expected.

## Known issues - all named by the author

- **Cutscenes are broken in VR.** Link is sometimes loaded out of bounds, and you
  see past the edges of scenes that were never meant to be seen from anywhere but
  the fixed camera. Watch them in flatscreen.
- **Wolf Link sections stay in third person.** He turns his whole body to look
  around, which throws the camera about. The author is open to ideas.
- **After a loading screen the camera can sit too low or too high.** Stand still
  without pressing anything for about three seconds - until the hearts and map
  appear - and it settles.
- Some screenspace effects (water reflections and the like) still need turning
  off one at a time, so expect a few oddities.

## Bugs and help

Discord: https://discord.gg/CxQJ9PjnjA

## Credits

Port by **JoeyAW** - https://github.com/JoeyAW/dusklight-vr

Built on the work of the **Dusklight** team, the **TP decompilation** team, the
GC/Wii decompilation community, the **Aurora** developers, **Automata** and the
TP speedrunning community.

The author is open about having written the code with AI assistance and explains
his reasoning on the project page. No AI-generated assets are used.

An unofficial fan project, not affiliated with Nintendo.

>>> Twilight and light, and you between them - with a sword.

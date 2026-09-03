# Mass Effect 2 VR Installer

Automated installer for MELE2-VR by dhalcyon - Mass Effect 2
Legendary Edition in full head-tracked PCVR. Real stereo depth: look
around Omega and the Citadel, walk the Collector ship, drive the
Hammerhead, stand on the Normandy SR-2. Gamepad only.

> **One download now covers all three games.** dhalcyon ships a single
> `MELE-VR.zip` that contains `MELE1VR.zip`, `MELE2VR.zip` and
> `MELE3VR.zip`. The Hub installer picks the archive for **this** game out
> of it by itself - the other two games are never touched.


Cutscenes and conversations are in VR too, including first-person
conversations. The mod is free, and its author states that updates
will stay free as well.


## From the author

> All three games. Start to finish. Head-tracked, real stereo VR, first-person
> and third-person. ME1, ME2 and ME3 are all playable now in VR.
>
> At the start of the year, I wanted to play all games in proper VR, but no mod
> was available. Now, here we are. Thank you for playing.

## What it does
1. Finds your Mass Effect Legendary Edition install on any store -
   Steam, EA App / EA Play Pro, Origin legacy, Epic, or Xbox / PC
   Game Pass
2. Gets MELE2-VR from the creator's public Patreon post (checks your
   Downloads folder first; otherwise it opens the post and you drag
   the zip in)
3. Places the four mod files in `Game\ME2\Binaries\Win64`, next to
   `Game\ME2\Binaries\Win64\MassEffect2.exe` - asking for Administrator rights
   only if that folder needs them
4. Runs the mod's own interactive setup where you pick the VR mode
   and image quality
5. Confirms the setup is done (the mod turns HDR off for you)

## VR modes and quality
- Modes: Stereo, Mono, AER, DIBR - switchable any time in the
  in-game menu
- Quality: Performance / Balanced / Sharp / Max / Extreme - a
  quality/resolution change means rerunning the installer
- Recommended default: Stereo + Balanced
- First-person gameplay is available as a toggle, but remember: this
  is a third-person game at heart - do not expect a full FPS
  conversion

## HDR (handled for you)
The mod's setup turns HDR OFF automatically - it writes the SDR
setting into the game's own GamerSettings.ini before the launcher
runs, which is more reliable than the in-game menu. HDR is the #1
cause of a blue or doubled headset image, so this matters - but you
do not normally touch it. Only if the setup prints a warning that it
could not write GamerSettings.ini (a permissions case): rerun the
installer as administrator, or turn HDR off yourself in the game's
own video options.

The same setup also forces motion blur, film grain and dynamic
shadows off.

## Eye separation and convergence
Press [[INSERT]] in game, open the **VR** tab and tune Eye Separation
and Convergence until the scale and depth feel right for you.

## Depth of field (optional, has a downside)
If you want depth of field gone, add `DepthOfField=False` under
`[SystemSettings]` in GamerSettings.ini:

    Mass Effect Legendary Edition\Game\ME2\BioGame\Config\GamerSettings.ini

Be aware this can leave the game looking washed out - an Unreal
Engine 3 issue, not a mod bug. The mod's own setup deliberately
leaves this setting alone, so it is your call.

## In-VR controls (keyboard; the game itself plays on gamepad)
- **[[INSERT]]:** open / close the mod menu
- **[[R]]:** recenter your view
- **[[K]]:** toggle the first-person camera
- **[[1]] [[2]] [[3]] [[4]]:** load settings profiles
- **[[BACK]]:** on the gamepad, tap twice to recenter

## Launching in VR
Use "Start in VR" in the Hub, or launch the game normally and pick
Mass Effect 2 in the launcher. On a Steam copy the Hub starts the
game through Steam - so if the EA App layer is not installed yet,
Steam sets that up instead of erroring. On EA / Origin / Epic / Game
Pass copies it uses the game's own launcher. Either way it avoids
starting MassEffect2.exe directly, which would nag about a missing
EA/Origin on a machine that has never run the game.

## Requirements
- Mass Effect Legendary Edition (any store version)
- A VR headset with an OpenXR runtime (SteamVR, Virtual Desktop,
  Meta, Pimax)
- A gamepad

## Mod page
https://www.patreon.com/dhalcyon/posts/mass-effect-vr-167394663

## Support dhalcyon
dhalcyon develops the MELE-VR mods. If you enjoy their work, consider
supporting them:
- Patreon: https://www.patreon.com/dhalcyon

>>> Assemble the team. The Omega-4 relay is a one-way trip.

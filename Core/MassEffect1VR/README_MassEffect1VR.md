# Mass Effect 1 VR Installer

Automated installer for MELE-VR by dhalcyon - Mass Effect 1
Legendary Edition in full head-tracked PCVR. Real stereo depth: look
around the Normandy, walk the Citadel, stand under a Reaper. Gamepad
only.

> **One download now covers all three games.** dhalcyon ships a single
> `MELE-VR.zip` that contains `MELE1VR.zip`, `MELE2VR.zip` and
> `MELE3VR.zip`. The Hub installer picks the archive for **this** game out
> of it by itself - the other two games are never touched.


"You exist because we allow it, and you will end because we demand
it."

The mod currently covers ME1; this installer sets up exactly that.


## From the author

> All three games. Start to finish. Head-tracked, real stereo VR, first-person
> and third-person. ME1, ME2 and ME3 are all playable now in VR.
>
> At the start of the year, I wanted to play all games in proper VR, but no mod
> was available. Now, here we are. Thank you for playing.

### Known: the Ilos conduit run in ME1
In **Stereo** mode the Ilos conduit escape sequence runs **faster than normal**.
Switch to **AER** or **Mono** in the Insert menu for that drive, then switch back
afterwards.

## What it does
1. Finds your Mass Effect Legendary Edition install on any store -
   Steam, EA App / EA Play Pro, Origin legacy, Epic, or Xbox / PC
   Game Pass
2. Gets MELE-VR from the creator's public Patreon post (checks your
   Downloads folder first; otherwise it opens the post and you drag
   the zip in)
3. Places the four mod files in `Game\ME1\Binaries\Win64`, next to
   `Game\ME1\Binaries\Win64\MassEffect1.exe` - asking for Administrator rights
   only if that folder needs them
4. Runs the mod's own interactive setup where you pick the VR mode
   and image quality
5. Confirms the setup is done (the mod turns HDR off for you)

## New in V3

- **Cutscenes and conversations look better in VR.** They now use the
  rendering technique from Mass Effect 2 and 3, with head tracking.
- **Decoupled look works with the mouse.** Before it only worked with a
  controller.
- **A new, lower resolution option** for weaker machines.

The author calls this the hopefully final version.

## VR modes and quality
- Modes: Stereo, Mono, AER, DIBR - switchable any time in the
  in-game menu
- Quality: Low / Performance / Balanced / Sharp / Max (Extreme for
  Stereo only) - a quality/resolution change means rerunning the
  installer
- Recommended default: Stereo + Sharp
- First-person camera is available as a toggle, but remember: this
  is a third-person game at heart - do not expect a full FPS
  conversion

## HDR (handled for you)
The mod's setup turns HDR OFF automatically - it writes the SDR
setting into the game's own GamerSettings.ini before the launcher
runs, which is more reliable than the in-game menu (many installs
do not even show an HDR option there). HDR is the #1 cause of a
blue or doubled headset image, so this matters - but you do not
normally touch it. Only if the setup prints a warning that it could
not write GamerSettings.ini (a permissions case): rerun the
installer as administrator, or turn HDR and Motion Blur off yourself
in the in-game video menu.

## In-VR controls (keyboard; the game itself plays on gamepad)
- **[[INSERT]]:** open / close the mod menu
- **[[R]]:** recenter your view
- **[[K]]:** toggle the first-person camera
- **[[P]]:** toggle depth pop
- **[[1]] [[2]] [[3]] [[4]]:** load settings profiles (rebindable in the
  menu under Profiles)

Depth of field is off by default in this build - toggle it in the menu
under the VR tab, Graphics; the change applies on the next launch.

## Launching in VR
Use "Start in VR" in the Hub, or launch the game normally and pick
Mass Effect 1 in the launcher. On a Steam copy the Hub starts the
game through Steam - so if the EA App layer is not installed yet,
Steam sets that up instead of erroring. On EA / Origin / Epic / Game
Pass copies it uses the game's own launcher. Either way it avoids
starting MassEffect1.exe directly, which would nag about a missing
EA/Origin on a machine that has never run the game.

## Requirements
- Mass Effect Legendary Edition (any store version)
- A VR headset with an OpenXR runtime (SteamVR, Virtual Desktop,
  Meta, Pimax)
- A gamepad

## Mod page
https://www.patreon.com/dhalcyon/posts/mass-effect-vr-167394663

## Support dhalcyon
dhalcyon develops the MELE-VR mod. If you enjoy their work, consider
supporting them:
- Patreon: https://www.patreon.com/dhalcyon

>>> I'm Commander Shepard, and this is my favorite mod on the Citadel.

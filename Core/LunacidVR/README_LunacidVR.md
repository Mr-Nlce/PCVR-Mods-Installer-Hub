# Lunacid VR

Full stereoscopic VR and motion controller support for Lunacid, by **Tesseract**. You swing melee weapons with your own arm, cast spells from your off hand and reach over your shoulder to draw a different weapon. The Hub installs BepInEx 5 and the mod itself.

This is an early beta by the author's own description. It runs, but it is rough in places - the known issues below are worth reading before you start a run you care about.

https://www.nexusmods.com/lunacid/mods/23

## Required settings

**Aesthetic must be "Clean".** Midnight and PSX use a post-processing effect that inverts the view in VR, and the remaining filters are hard on the eyes in a headset. You change it under Options from the main menu, or the Settings tab in-game.

The author also warns that the menu can misreport this: even when it already reads Clean, cycle through the aesthetics with the arrows and land back on Clean. The stored preference does not always match what is displayed.

**SteamVR only.** The mod talks to SteamVR directly - no other OpenXR runtime will bring the game up in VR. Start SteamVR before the game to avoid it potentially starting sometimes out of focus.

## Comfort warning

Where more than eight light sources fall on the same object, the lighting on that object flickers noticeably. The author has removed some of the worst offenders (the hanging lanterns in Terminus Prison, the candles in the Sealed Ballroom, the dynamic light on the Phantoms in Castle Le Fanu, the Sealed Ballroom and the Accursed Tomb), but it can still occur elsewhere. The author advises against this mod if you are sensitive to flashing lights or prone to nausea in VR.

## Launching

Launch with **Start in VR** in the Hub, or from Steam. The game comes up directly in VR once the mod is installed.

## Controls

Defaults for Oculus/Quest Touch and Index Knuckles; Vive wands have their own bindings.

| Action | Button |
| --- | --- |
| Move | [[Left Stick]] |
| Turn | [[Right Stick Left/Right]] |
| Jump | [[Right A]] |
| Swap spell | [[Right B]] |
| Use item | [[Left A]] |
| Open menu | [[Left B]] |
| Previous item | [[Right Stick Up]] |
| Next item | [[Right Stick Down]] |
| Interact / pick up / off-hand ranged | [[Right Grip]] or [[Left Grip]] |
| Attack, block, charge spell, swap weapon | [[Left Trigger]] or [[Right Trigger]] |
| Skip the intro cutscene | [[A]] |

Which grip interacts and which fires the off-hand ranged weapon follows the game's own left/right hand setting.

## How it plays

Most of the game behaves as normal. The parts that changed:

- **Melee** weapons must be physically swung at an enemy, with enough velocity to count. Backstep and thrust no longer do anything.
- **Cooldowns replace charge times** on melee and ranged weapons.
- **Blocking** is holding the trigger on your weapon hand. You can block straight after attacking, you move slower while blocking, and releasing it sets a short cooldown.
- **Swapping weapons**: reach over your shoulder - up to your ear also works on Quest - and press the trigger on your weapon hand.
- **Beam and throwing weapons** (Moonlight, Lucid Blade, Corrupted Dagger, Fishing Spear) fire by holding trigger as if blocking and swinging. The projectile leaves the weapon and flies toward whatever is in the middle of your view. To actually block with Moonlight or Lucid Blade instead of firing, keep your hand close to your chest.
- **Ranged weapons** reload themselves and can be held in two hands by gripping with your off hand.
- **Spells** cast from your off hand when a weapon is equipped, or from either hand when it is not. They fly from your hand toward the first physical barrier in your line of sight.
- **Thrown items** leave your off hand in the direction you are looking.

The mod has its own settings file under `BepInEx\config` in the game folder - worth a look once you have played a little.

## Known issues in this beta

- The endings do not work and have not been tested. Ending E will not work at all.
- Mirror-type reflections have been removed entirely; the game's planar reflection package does not support VR.
- Dialogue cutscenes (the intro and the final boss) show no subtitles or text boxes.
- Swimming is rough, and the underwater visual effect is painful to look at.
- The Marauder Black Flail loses its triple hit and its flail physics.
- The teleporter that builds the infinite maze in the Labyrinth of Ash misfires and drops you out of bounds.

## Other mods

Compatible with most Lunacid mods, except anything built on the Lunatic Modding API. It does work with the randomiser, but create your character with VR disabled first - the randomiser's character creation changes are incompatible with the VR mod.

## Switching back to flat

Use the **VR / Flat** button on the game's page in the Hub. It renames the BepInEx loader, so flat mode pauses every BepInEx mod in Lunacid, not just this one; switching back to VR restores them all.

To remove the VR mod for good, delete `BepInEx\plugins\LUNACID VR\LUNACIDVR.dll`. The installer backed up every game file it replaced as `<name>.hubbak` - restore those if you want the folder exactly as it was.

## Credits & support

Lunacid VR Beta is made by Tesseract (GelatinousTesseract on Nexus Mods). Lunacid itself is by KIRA LLC. If you get on with the mod, endorsing it on its Nexus page costs nothing and is the thing mod authors actually notice:

https://www.nexusmods.com/lunacid/mods/23

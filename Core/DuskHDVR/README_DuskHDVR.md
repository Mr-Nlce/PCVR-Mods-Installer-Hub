# Dusk HD (DLC) VR Installer

Automated installer for Dusk_HD_VR v1.0.0 by Astienth - VR conversion of the **DUSK HD** DLC, a remastered version of DUSK with updated visuals.

**This mod is for the DUSK HD DLC only, NOT classic DUSK.** You need the DLC owned and installed.

This is a full motion-controller VR mod with bHaptics + ProTube/ForceTube support.

## What it installs
- **UnityVR_DuskHD mod** - VR rendering and motion-controller support
- **BepInEx** - mod loader
- **ViGEmBus driver** (optional, but required for VR controllers) - emulates an Xbox controller

The mod files go into `DLC\DUSK HD\` inside the DUSK game folder, NOT the game root.

## Requirements
- Dusk owned on Steam (App ID 519860)
- **DUSK HD DLC** owned and installed (right-click Dusk in your Steam library → Properties → DLC → tick "DUSK HD")
- SteamVR or any OpenVR runtime installed
- Discord account - the mod is distributed through Astienth's posts on the FarmerTrueVR Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `Dusk_HD_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates the DUSK HD DLC subfolder, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.
6. At the end you'll be asked whether to open the optional Roomscale Enabler download post (skip if unsure).

## Features
- Full motion-controller mapping with hotkey gesture
- bHaptics support: vest, arms, visor
- ProTube / ForceTube device support

### bHaptics
Launch the bHaptics Player, turn your devices on, **then** launch the game.

### ProTube
Launch the game **first**, then turn on the devices one by one. The first device recognised is assigned to channel `pistol1`, the second to `pistol2`. With dual wielding: `pistol1` is always the right-hand weapon, `pistol2` the left. With single weapons, audio/haptics go to `pistol1`.

If left-handed mode is enabled, the right-hand weapon goes to the left hand and vice versa - haptics follow the dominant hand: dominant = `pistol1`, non-dominant = `pistol2`. The companion app can change channels but may interfere - report issues to Astienth.

## Critical launch steps - read before playing

1. The **game window must stay focused** while playing - controls stop working if it loses focus.
2. **Enable "allow gamepads"** in the in-game options menu.
3. **Unplug any other input devices** (extra gamepad, racing wheel, flight stick, etc.) - they will interfere with your VR controllers.
4. After launching, on the title screen, **listen for the Windows USB sound** - that confirms the virtual gamepad was recognised. **Wait a few more seconds** before trying to navigate the menus.

## Controls

VR controllers are mapped as an Xbox gamepad **with these exceptions**:
- **VR [[Left Grip]]** = Xbox **RB** (= weapon wheel by default)
- **VR [[Right Grip]]** = Xbox **R3** (= run, when autorun is off)
- **VR [[Right Stick]] click** = Xbox **LB**

**Aim with your dominant hand** to shoot, interact with objects, switches, doors. **Dual-wielded weapons are separated** - one in each hand. The "can shoot" cooldown still applies, so you can't fire both weapons at the exact same instant, but you can chain shots fast.

### Hotkey gesture (important!)
Hold your **left controller close to the left side of your head**. The controller vibrates while the hotkey is active. While the hotkey is held:
- **[[Left Stick]]** becomes the **D-Pad**
- **[[Left Stick]] click** becomes the **Back / View** button
- **[[Right Stick]] click** becomes the **Start / Menu** button

### Layout reference

![Controller layout](ControllerLayout.jpg)

## Configuration

`DLC\DUSK HD\BepInEx\config\UnityVR_DuskHD.cfg` inside the DUSK game folder:
```
handRotationOffsetX = 40 # weapon angle on X axis; 40 is a good middle value across controller types
leftHanded = false # set "leftHanded = true" for left-hand mode
```

## Optional: Roomscale Enabler add-on

Astienth has a separate optional plugin for tweaking roomscale behaviour. Most players don't need it - it's only useful if you want to fine-tune how room-scale movement maps in this game. Comes with a PDF guide.

Download post: https://discord.com/channels/1001138422972432597/1449484957671227555/1449729394322182266

To install: extract the ZIP into `DLC\DUSK HD\` inside the DUSK game folder (the same folder as the main mod). Read the included PDF for usage.

## Known issues (from Astienth)
- No weapon zoom.
- No backflips (decoupled pitch).
- Custom maps may not work because they may not follow the game's naming pattern.
- The mod has not been tested with other mods or maps.

## Compatibility
The modder hasn't tested compatibility with other mods or custom maps. Stock single-player content is what's been verified.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> The cult is hungry. Feed them lead.

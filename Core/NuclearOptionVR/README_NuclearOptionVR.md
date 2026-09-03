# Nuclear Option VR

**NOVR** by **InfernoSuperNova** adds stereoscopic VR to Nuclear Option while keeping the game's normal gamepad, keyboard and HOTAS controls.

## Install

1. Close Nuclear Option.
2. Select **Install Mod** in the Hub.
3. The Hub downloads verified **BepInEx 5** only when needed, then downloads the current `NOVR.zip` and installs its `plugins\NOVR` and `patchers\NOVR` folders.
4. Start Nuclear Option with **Start in VR** here or through Steam.

The small `NOVR.zip` is the complete current NOVR payload. It is much smaller than the retired GUI installer because BepInEx is no longer bundled in that release; the Hub supplies it separately.

## First launch

NOVR's patcher copies its XR support files into `NuclearOption_Data` when the game starts. Let that first start finish before judging the install.

The first VR start can show only a grey view, with the left eye white and the right eye black. Watch the desktop mirror instead of trying to navigate blind. Let the game reach its menu, close it, then launch it in VR once more if the headset view does not recover.

## Controls and starting a flight

NOVR adds VR rendering and head tracking, not motion controls. Use a physical [[Gamepad]], HOTAS, or keyboard and mouse. With a gamepad, switch the first prompt to **Gamepad** and continue normally.

Some later menus and the map remain mouse-first. The reliable route is the desktop mirror with [[Mouse]]:

1. Open or join a mission.
2. Click an airbase on the map.
3. Click **Select Aircraft** at the bottom, choose an aircraft, and continue into the cockpit.

If **Select Aircraft** will not react, this is a [known NOVR cursor-layer issue](https://github.com/InfernoSuperNova/novr/issues/40). Click once elsewhere on the map, close and reopen the map, then retry the button through the desktop mirror. Once inside the cockpit, the game's normal gamepad, keyboard, or HOTAS bindings apply and can be changed under **Settings -> Controls**.

## Flat / VR

Use the **VR / Flat** switch on this page. It parks or restores the BepInEx loader; do not rename files by hand.

## Uninstall

Select **Uninstall now** beside the guide. It removes only NOVR's plugin and patcher folders. Shared BepInEx, configurations, saves and unrelated mods remain. First-launch XR support files are deliberately retained because they may be shared or replaced by the game and are inert without NOVR.

## More info

Project and releases: https://github.com/InfernoSuperNova/novr

> Jets are complicated enough before you strap the cockpit to your face.

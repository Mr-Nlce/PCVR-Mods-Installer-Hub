# The Dark Mod VR

**The Dark Mod** is a free, standalone, open-source stealth game for PC. The project pays homage to the classic games in the **Thief** series (Dark Project) and perfectly captures their dark Gothic-steampunk atmosphere. This entry sets up the **VR version** by Holger Frydrych.

## How this installer works (guided)

The Dark Mod uses its own GUI installer to fetch the game. The VR build is a **custom version** (base `release210` + a custom manifest URL) and that selection cannot be driven fully headless, so this is a **guided** install:

1. Creates the install folder (default `C:\Games\The Dark Mod VR`) and drops `tdm_installer.exe` into it, so the install path is already set.
2. Copies the **VR manifest URL** to your clipboard (paste it with Ctrl+V in the installer).
3. Launches the TDM installer and shows you the 4 steps to click:
   - Tick **Get custom version**
   - Pick **`release210`** as the base version
   - Paste the manifest URL into **Custom manifest URL**
   - Confirm the non-official-build warnings, then the download summary
4. After the install: writes a sample gamepad config (TDM ships none) and creates a **The Dark Mod VR** desktop shortcut to `TheDarkModVRx64.exe`.

> Manifest URL (also shown in the installer window): http://tdm.frydrych.org/releases/vr/manifest.iniz

## Launching

1. Start **SteamVR** / your VR runtime first.
2. Launch with **Start in VR** in the Hub, or the **The Dark Mod VR** desktop shortcut (`TheDarkModVRx64.exe`).
3. If the UI overlay is missing or your head is stuck in a wall/ceiling, **reset your seated position** (SteamVR: **reset seated position**; Oculus: **recenter view**).

## Gamepad controls

Movement is on the **[[Left Stick]]**, camera/aim on the **[[Right Stick]]**. **[[LT]]** is the modifier key — hold it for the weapon actions in the second list.

### Default (no modifier)

- **[[A]]:** Jump
- **[[B]]:** Crouch / hold = Mantle
- **[[X]]:** Attack
- **[[Y]]:** Use inventory item / hold = Inventory grid
- **[[RT]]:** Frob (interact)
- **[[LB]]:** Lean left
- **[[RB]]:** Lean right
- **[[LB]]** + **[[RB]]:** Lean forward
- **[[DPAD Up]]:** Previous inventory item / hold = Clear selection
- **[[DPAD Down]]:** Next inventory item / hold = Drop item
- **[[DPAD Left]]:** Cycle keys
- **[[DPAD Right]]:** Cycle lockpicks
- **[[L3]]:** Run (left-stick click)
- **[[R3]]:** hold = Use spyglass
- **[[Back]]:** Show objectives / hold = Quicksave
- **[[Start]]:** Toggle menu

### Hold [[LT]] (weapons)

- **[[LT]]** + **[[RT]]:** Attack
- **[[LT]]** + **[[RB]]:** Parry
- **[[LT]]** + **[[DPAD Up]]:** Previous weapon / hold = Holster
- **[[LT]]** + **[[DPAD Down]]:** Next weapon
- **[[LT]]** + **[[DPAD Left]]:** Blackjack / hold = Sword
- **[[LT]]** + **[[DPAD Right]]:** Broadhead arrows / hold = Water arrows
- **[[LT]]** + **[[R3]]:** hold = Toggle lantern

The bindings live in `DarkmodPadbinds.cfg` in your install folder — edit it any time. Menus are mouse-emulated: the sticks move the cursor and **[[RT]]** acts as the click.

## Known issues

- Some full-screen effects render only to the UI overlay in front of you instead of to the eyes (e.g. entering the spirit world in the FM **A House of Locked Secrets**).
- The spyglass only renders in 2D.
- If the UI overlay is nowhere to be seen, or your head is stuck in a wall/ceiling, reset your seated position (see **Launching** above).

## Notes on missions

- **Included missions** (Training Mission, A New Job, Tears of St. Lucia): perform reasonably well, no known issues.
- **A House of Locked Secrets:** first two parts perform very well; spirit-world overlay issue noted above.
- **Briarwood Manor:** the exterior is a known heavy scene and will reproject even on top-end hardware; interiors are mostly fine.
- **No Honor Among Thieves:** the spider caves near the start are notoriously heavy and will reproject even on the most powerful hardware.

## Links

- VR mod & docs: https://github.com/fholger/thedarkmodvr
- The Dark Mod: https://www.thedarkmod.com

## Support the developer
fholger maintains these PC VR mods in his spare time. If you enjoy them, consider supporting him:
- Ko-fi: https://ko-fi.com/fholger

# AffinityKiller

AffinityKiller is a simple World of Warcraft 1.12/TurtleWoW addon that automates targeting and spell casting on a configurable list of "Affinity" NPCs via a single macro. It's designed for speed and safety during encounters where you must rapidly target and perform actions on these NPCs, and comes with an in-game configuration UI.

## Features

- Targets the following NPCs (in list/priority order):
  - Black Affinity
  - Blue Affinity
  - Crystal Affinity
  - Green Affinity
  - Mana Affinity
  - Red Affinity
- Lets you configure, per-NPC:
  - Spell to cast (or leave blank to only target)
  - Enable/disable (checkbox)
- Macro-ready: Just use `/ak` in a macro/keypress to target and optionally cast, on the next configured/available Affinity.
- Compact configuration dialog with scroll, checkboxes, and input fields. Open with `/ak config`.
- Settings are saved per account.
- Works on real Vanilla/Turtle (Lua 5.0; no # operator, only table.getn, old script syntax).
- Only uses safe Blizzard API: no automation, no protected or privileged actions.

## Installation

1. Download and unzip the addon folder so you have:
    ```
    Interface/AddOns/AffinityKiller/AffinityKiller.lua
    Interface/AddOns/AffinityKiller/AffinityKiller.toc
    Interface/AddOns/AffinityKiller/README.md
    ```
2. Restart WoW or `/reload`.

## Setup and Usage

1. **Configure Spells:**
   ```
   /ak config
   ```
   - Check each NPC you care about and enter the spell you want to cast. You may include (Rank X) in the spell name if desired.
   - Leave the spell blank to only target that NPC when found.

2. **Use the Macro:**
   Put the following in a macro slot:
   ```
   /ak
   ```

   Every time you press the macro, the addon:
   - If you are already targeting an enabled NPC from the list, it will cast the configured spell (if one is set) or just keep it targeted.
   - Otherwise, it will scan down the (enabled) list, targeting the first found. If a spell is set, it will cast; if not, it will just switch target with no notification.

3. **Slash Command Reference:**
   - `/ak` — Run the main logic (target and cast)
   - `/ak config` — Open config dialog
   - `/ak reset` — Clear all spell mappings (NPCs stay enabled by default)
   - `/ak show` — See current NPC/configured spell/enabled list
   - `/akdebug` — Toggle debug output

## Examples

**An example configuration dialog:**

| ☑ | Black Affinity      | [Lightning Bolt(Rank 5)      ] |
| ☑ | Blue Affinity       | [Frostbolt(Rank 3)            ] |
| ☐ | Crystal Affinity    | [                             ] |
| ☑ | Green Affinity      | [Fireball(Rank 4)             ] |
| ☑ | Mana Affinity       | [Arcane Missiles(Rank 2)      ] |
| ☐ | Red Affinity        | [                             ] |

- Only the checked NPCs are targeted by `/ak`.
- If the spell is blank, the NPC is targeted but no spell is cast.
- If multiple enabled NPCs are nearby, the first matched in the list order is chosen.

**Typical Macro Button:**

Place just `/ak` in the macro on your hotbar. Spam it as needed.

## Limitations

- Must press macro key/button for each action (obeys 1.12 automation restrictions).
- Does not automatically click spells; only calls CastSpellByName (no hardware event bypass).
- Spell names must be typed exactly; include rank if needed for non-default ranks.

## Credits

Developed by request.
Tested on Vanilla/TurtleWoW.

---

Enjoy, and good luck with your Affinities!

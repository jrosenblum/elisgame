# Cyberpunk Tactics Prototype

A small Godot combat sandbox with pixel placeholders, player/enemy phases, melee and ranged units, movement in either order with attacks, automatic counterattacks, and an inspectable combat forecast. The implemented mechanics are the designer-approved temporary rules in [PROTOTYPE_RULES.md](PROTOTYPE_RULES.md).

## Play

Install Godot 4.7.2 or a compatible later Godot 4 release, open `project.godot`, and press **F5**. On macOS, you can also double-click **Play.command**: it looks for Godot in Applications, then the development runtime at `/private/tmp/fire-emblem-godot-runtime/Godot.app`, then `godot` or `godot4` on PATH. Godot itself is not included in this repository; the temporary development runtime may be cleared by macOS.

Click one of the cyan player units, then choose Move or Attack. Movement and attack are separate opportunities; either may come first. An attack requires confirmation through its forecast. You can switch units partway through a turn.

| Input | Action |
| --- | --- |
| Left click | Select a unit, movement tile, or attack target |
| M / A | Choose Move / Attack |
| W | Wait and give up the selected unit's remaining opportunities |
| E | End the player phase, giving up unused opportunities |
| R | Restart the encounter |
| Escape / right click on the battlefield | Cancel a pending selection; completed actions are not undone |

Melee attacks reach exactly one tile. Ranged attacks reach two to three tiles and cannot hit adjacent targets. Walls block movement and shots. A surviving defender counters if its own range and sight line allow it. Counterattacks are free and do not remove the defender's normal action. Defeat all enemies to win; restart restores every unit.

## Change the content

- `data/unit_types.json` contains the temporary melee/ranged stats and ranges.
- `data/test_map.json` contains dimensions, walls, unit types, names, sides, and placements. Tile coordinates start at zero.
- To add a unit using existing behavior, add a map entry with a unique ID and a supported role. To create another map, copy the map JSON and pass its path to `BattleState.setup` in the main scene script.
- Melee/ranged are test roles, not the finalized six-class roster. New mechanics still need a design decision and code; changing data alone does not add hacking or environmental rules.

## Code map

| File | Responsibility |
| --- | --- |
| `scripts/battle_state.gd` | Encounter data, unit opportunities, phase changes, enemy turns, victory/defeat |
| `scripts/grid_rules.gd` | Movement search, occupied tiles, ranges, wall sight lines |
| `scripts/combat_rules.gd` | Temporary damage, hit, and critical-hit calculations |
| `scripts/main.gd` | Selection, actions, forecasts, controls, and enemy-turn pacing |
| `scripts/battle_board.gd` | Battlefield drawing and pointer input |
| `tests/test_battle.gd` | Headless checks of the approved combat rules |
| `tests/test_ui.gd` | Scene-level command, forecast, phase-locking, and layout checks |

## Verify the combat model

Run from this project directory, substituting the path to your Godot executable if it is not on PATH:

```sh
godot --headless --path . --script tests/test_battle.gd
godot --headless --path . --script tests/test_ui.gd
```

Validated on Godot 4.7.2: 98 combat-model checks and 29 scene checks with the rendered-preview option. Headless scene checks skip the single framebuffer-export check. The actual map's seeded encounter simulation reaches completion. The game scene was also rendered and visually inspected.

A native mouse/keyboard smoke test verified unit selection, movement highlights and tile clicks, keyboard shortcuts, enemy-phase progression, attack forecasts and explicit confirmation, counterattacks, cancellation, and movement after attacking. Pointer input also worked after maximizing the window. Restarting immediately after ending the player phase restored round one without delayed enemy actions. This covers the main interaction flow, not an exhaustive playthrough.

The initial prototype focuses on the combat foundation. Weapon/armor effectiveness, hacking, environmental combinations, the full class roster, progression, and the hub remain later work. Read [REQUIREMENTS.md](REQUIREMENTS.md) for the broader direction and unresolved decisions.

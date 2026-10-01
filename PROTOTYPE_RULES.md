# First Combat Prototype Rules Proposal

**Status: Approved by the designer on September 30, 2026 for this prototype.** These are temporary sandbox rules, not final game balance or a finalized stat/class system. They make the first playable milestone concrete. The supplied notes require a choice before unspecified mechanics are implemented.

## Scope

Use Godot 4 and GDScript for a desktop prototype with mouse and keyboard. Build one small combat encounter with procedural pixel placeholders, basic melee/ranged roles, clear movement and target highlights, an attack forecast, combat messages, and restart. Weapon/armor effectiveness, classes beyond these test roles, hacking, environmental effects, cover bonuses, and doubling remain for later experiments.

## Map and turn rules

- A 12 by 9 square grid; three player units and three enemies, each side using two melee units and one ranged unit.
- Start on opposite sides. A few central walls create routes around them. Exact placement may be tuned during implementation and kept in the map data.
- Move orthogonally, with every traversable tile costing one movement point. No diagonal movement, terrain costs, or movement through occupied tiles.
- One continuous movement and one attack per unit per phase, in either order. No splitting a move. A player may switch between units that still have unused opportunities.
- Wait ends that unit's remaining opportunities. End Phase explicitly ends the player phase and forfeits unused opportunities. The phase does not end automatically.
- Enemy units act sequentially in the enemy phase. Movement and attack opportunities refresh at the start of the owning side's phase.
- Walls block both movement and attacks. Shots use a straight tile-to-tile sight line; touching a wall tile blocks the shot, including diagonal corner contact. Units block movement but do not block shots.
- Measure attack range by Manhattan distance: horizontal distance plus vertical distance.

## Temporary test stats

These display labels are provisional and do not reconstruct missing stat headings in the original notes. Both sides use the same templates.

| Role | Health | Attack | Defense | Agility | Speed | Move | Weapon range |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Melee | 24 | 8 | 3 | 8 | 6 | 4 | Exactly 1 tile |
| Ranged | 20 | 7 | 2 | 9 | 5 | 4 | 2 to 3 tiles |

- Damage on a normal hit is `max(0, attacker Attack - defender Defense)`.
- Hit percentage is `clamp(85 + 2 * attacker Agility - 2 * defender Speed, 10, 100)`.
- Critical chance is `clamp(floor(attacker Agility / 2), 0, 20)` percent. A critical hit deals twice normal damage. Roll critical chance only after a successful hit.
- The forecast displays damage, hit, critical chance, and possible counterattack before confirmation.
- Each initiated attack produces one strike. A surviving defender counterattacks once if the attacker is in range and the sight line is clear. A missed first strike can still provoke a counterattack. There are no chains of counterattacks.
- Counterattacks do not consume movement or the normal action, and have no per-phase limit in this test. There are no follow-up attacks from Speed.
- At zero health, a unit is removed from the encounter and cannot counterattack. Defeating every enemy wins; losing every player unit loses. Restart restores the encounter. This has no campaign/permanent-death consequences.

## Minimal enemy behavior

Enemies attack a legal target if one is already in range. Otherwise, they move toward the nearest opponent, preferring a reachable tile that allows an attack, then attack if possible. Ties use a stable ordering so behavior is inspectable. This is a basic test opponent, not final tactical AI.

## Controls and iteration

Click a player unit to select it, choose Move or Attack, then click a highlighted tile or enemy. Confirm attacks through the forecast. Right-click or Escape cancels a pending selection, without undoing a completed action. Provide Wait, End Phase, and Restart buttons, with keyboard shortcuts shown in the interface.

All test stats, weapon ranges, map layouts, and placements live in editable content data. Agreement to this proposal also permits routine adjustments to those temporary values and placements during testing, recorded in the project; changes to mechanics still require a designer choice.

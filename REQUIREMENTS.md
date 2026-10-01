# Cyberpunk Tactical RPG Requirements Draft

This document defines the agreed direction for a Godot game inspired by classic Fire Emblem and a small combat prototype to establish its foundation. The prototype makes the tactical loop playable before adding environmental systems and hacking.

**Status:** Working draft. Confirmed requirements come from the current request and supplied discussion notes. Candidate ideas, recommendations, and unresolved decisions are identified below. An unresolved mechanic must not become a rule through an implementation default; ask the designer when that decision is needed.

**Approved prototype supplement:** On September 30, 2026, the designer authorized implementation and approved the [first prototype rules](PROTOTYPE_RULES.md). That supplement resolves the first build's map, movement, test stats, combat formulas, counterattack details, enemy behavior, and encounter completion. It takes precedence for the prototype where this broader document still lists full-game choices as open. The implementation uses Godot 4.7.2.

## Game direction

| Area | Confirmed direction |
| --- | --- |
| Engine | Godot. The current request settles the older notes' engine uncertainty. |
| Language and prototype target | GDScript; desktop with mouse and keyboard. Specific operating systems and the Godot version remain open. |
| Presentation | Classic 2D pixel graphics in a cyberpunk setting. The notes describe cute pixel characters and environments, with anime-style portraits for eventual dialogue. Placeholder graphics are acceptable for the prototype. |
| Genre | Turn-based, grid-based tactical RPG inspired primarily by classic Fire Emblem. |
| Characters | A roster of distinct characters with different classes. A large recruitable cast belongs to the full-game vision. |
| Combat distinction | Different weapon and armor/defense types replace a literal weapon triangle. The categories and effects remain open. |
| Tactical direction | Simple underlying combat, with complexity arising from unit roles, movement, ranges, blockers, cover, abilities, hacking, and environmental interaction. |
| Content creation | Make new levels, characters, and puzzles easy to create using supported systems. Puzzle gameplay and authoring tools are not yet specified. |
| Development | Small, testable changes; modular systems; data-driven content; version control; readable code and explanations suitable for development with AI assistance. |

The eventual combat experiment asks whether environmental interaction, hacking, destructible objects, and interacting battlefield effects make this familiar tactical foundation more interesting. That question does not require building the full RPG first.

## Confirmed combat rules

### Turn structure

- Combat alternates between a player phase and an enemy phase.
- The player acts first unless a specific scripted event says otherwise. A scripting system is not required for the first test.
- All player units may act during the player phase, in an order chosen by the player.
- Enemies take their turns after the player finishes the player phase. Automatic counterattacks may occur during the opposing side's phase; they do not introduce an initiative system.
- Every unit has one movement and one action per turn. Either may come first: move then attack, attack then move, move then ability, or ability then move.
- Taking an action must not automatically consume an unused movement opportunity.
- Include automatic counterattacks when the attacker is within the defender's weapon range. Remaining eligibility, sequencing, and cost details still need decisions.

The rules for skipping opportunities, ending a unit's turn, switching between partly used units, splitting movement, and automatically ending a phase remain open.

### Attacks and movement

- Support tile-based movement and basic melee and ranged physical attacks in the initial combat foundation.
- Weapon and ability ranges must be limited. Exact ranges, distance measurement, and movement rules need decisions.
- Use map layout and range to discourage destroying a large part of the enemy force from the starting position.
- Eventually demonstrate hit, dodge, critical hits, distinct stats, multiple unit roles, and battlefield blockers in the combat prototype.
- Keep results understandable and closer in feel to classic Fire Emblem than a completely deterministic puzzle game.

The notes favor percentage-based physical hit chances and random critical hits, with Agility contributing to hit/crit and Speed contributing to avoidance. These are design directions to turn into approved formulas. Ordinary attacks generally having high hit chances and evasive builds meaningfully lowering those chances are tuning intentions, not numerical requirements.

### Systems excluded from current scope

Do not introduce an action-point system, initiative timeline, elevation, directional attack bonuses, or backstabs based purely on facing. There is no Luck, Charisma, or Cool stat in the current design. Speed-based doubling is undecided, not an approved feature.

## Characters and combat matchups

These are candidate class concepts, not a finalized roster or set of abilities:

| Candidate class | Described role |
| --- | --- |
| Street samurai | Fast, close-range combat. |
| Heavy | Durable unit with a physical battlefield presence. |
| Gunner | Ranged physical combat. |
| Netrunner | Hacking and electronic/environmental manipulation. |
| Medic | Healing and support. |
| Ninja or infiltrator | Mobility and access; potentially bypasses some barriers or map restrictions. |

The earliest prototype can use basic melee and ranged roles. It does not need all six classes. Exact class names, roster, weapons, and abilities still need confirmation.

The intended full-game character identity combines stats, class, class abilities, and a unique personal ability that may be active or passive. Ability counts and the personal-ability system remain undecided and are not necessary for the first movement/attack loop.

**Source gap:** Several stat headings appear to be missing from the pasted notes. Health is named, and Agility and Speed are named elsewhere. Other descriptions refer to physical offense, physical defense, tech offense, tech resistance, and movement distance, but their canonical stat names must be confirmed. No complete stat schema or numerical values are approved by this draft.

Weapon/defense matchups must be visually understandable: players should generally recognize a suitable attacker without repeatedly opening detailed stat screens. Discussed target concepts include lightly protected biological units, heavy physical armor, cybernetic units, and mechanical units. Whether cybernetic and mechanical targets are separate combat categories remains open.

Some attacker-category headings are also missing from the notes. Do not infer weapon categories or a damage matrix from the listed favorable targets. Exact weapons, armor types, matchup effects, and numerical modifiers must be chosen explicitly.

## Environment and hacking

The intended battlefield has both physical objects and electronic systems. Players should react to and modify them during combat. Extended preparation on a combat map is not the intended normal battle flow.

Candidate objects include barrels, pipes, servers, turrets, doors, sprinklers, cameras, power sources, conduits, access points, and destructible cover. These are a pool of ideas for later experiments, not a list of objects required in the first build.

Candidate interactions include liquid plus electricity, explosions starting fires, and heated water producing mist or steam. Water, blood, and mechanical fluid were discussed as potential liquids. None of their damage, duration, spread, status, visibility, or interaction rules is finalized. Cover protection, destruction, movement blocking, and shot blocking also require explicit rules.

Hacking should eventually have a tactical identity beyond a reskinned ranged damage attack. Two approaches are under consideration:

| Candidate model | Description |
| --- | --- |
| Direct targeting | A hacker targets a device while within hacking range. |
| Network access | A hacker gains access to an access point or network before manipulating its connected devices. |

Network access is appealing in the notes, but not confirmed. Costs, ranges, access persistence, valid targets, and specific effects remain open. Do not build a complicated hacking architecture before choosing the model.

After the foundation works, the prototype should test a small selection of interacting environmental systems and a basic hacking interaction. Choose the actual objects and rules together before implementation; do not implement every candidate.

## Proposed prototype milestones

This is a recommended implementation sequence, not approval of unresolved mechanics or values.

| Milestone | What it proves | Decisions needed first |
| --- | --- | --- |
| First playable combat loop | Select a unit, show reachable tiles, move, select an attack, show valid targets, resolve an attack and applicable counterattack, activate other units, end the phase, let enemies act, and return to the player phase. Include basic melee/ranged roles and blockers. | Godot version and desktop operating systems, grid rules, unit stats and values, movement and attack ranges, basic attack formulas, counterattack details, turn completion rules, minimal enemy behavior, map size and unit counts. |
| Combat roles and matchups | Demonstrate the approved weapon/armor relationships and hit/dodge/crit behavior not already included in the first loop. Make role and defense distinctions readable. | Stat schema and remaining formulas, weapon and defense categories, matchup effects, test roles, doubling choice. |
| Environment and hacking experiment | Demonstrate a small set of environmental systems interacting with one another and a basic hacking interaction. Assess whether they create useful tactical choices. | Selected objects, interaction rules, hacking model, action costs, relevant cover and targeting rules. |

No exact map dimensions, number of combatants, weapon ranges, damage values, or content counts are assigned here. Even temporary test values need explicit agreement before they are used as gameplay rules.

### Acceptance checks for the first playable loop

- A normal encounter begins in the player phase; enemies take their own turns only after it ends, while eligible counterattacks may occur during the player phase.
- The player can choose the activation order of available player units.
- A unit can move then attack, or attack then move, subject to legal movement and targets.
- A unit cannot gain a second movement or action opportunity in the same turn. Whether counterattacks consume these opportunities must be decided separately.
- After a complete player/enemy cycle, units receive their next turn's movement and action opportunities.
- Reachable-tile and valid-target displays agree with the approved movement, blocking, and range rules.
- Both melee and ranged attacks work according to approved parameters; damage and hit outcomes follow the selected formulas.
- An eligible defender automatically counterattacks when the attacker is within its weapon range; an out-of-range defender does not. Apply the approved sequencing and eligibility rules, including the eventual rule for zero health.
- Ending the player phase lets enemies act under the selected minimal behavior, then returns control to the player.
- The agreed rules for units reaching zero health and ending or resetting the encounter work consistently.

These checks verify approved behavior. They do not select formulas, enemy tactics, death rules, or victory conditions.

### Acceptance checks for later experiments

- Approved weapon/armor relationships produce their intended outcomes, and the player can recognize the relevant roles and defense types visually.
- Hit, dodge, and critical-hit behavior can be demonstrated and checked against the approved rules.
- The selected environmental effects interact as specified and communicate the resulting battlefield state clearly.
- Hacking changes the battlefield through the selected model and follows the approved targeting and cost rules.
- Playtesting records whether the chosen interactions create meaningful tactical choices. This is a design assessment, not an assumed success.

## Extensibility and implementation constraints

Keep combat rules, units, map content, presentation/UI, and environmental effects modular. If saving is added later, keep it separate too; saving is not a prototype requirement. Prefer editable data for unit, weapon, class, ability, and environmental-object definitions as those systems are introduced.

Content authoring should support these checks:

- Add a character that uses existing rules by creating or editing content data, without rewriting the turn system.
- Create another level using supported terrain, objects, and encounter data, without changing core combat rules.
- Configure existing supported interactions into new encounters or environmental/access puzzles without duplicating their underlying logic.

The last check applies only after those interactions exist. It does not require a dedicated puzzle engine or editor. New behavior may still require code. Traditional standalone puzzles are not established as a core pillar; their scope needs clarification.

Build only the structure each milestone needs. Keep changes independently testable, avoid unrelated rewrites, and explain the purpose of each system. A complete RPG framework, plugin system, or speculative architecture is not required. Use GDScript in Godot; the specific Godot version remains open.

## Decisions still required

Resolve these in small groups when needed. Recording a decision as open is sufficient for this requirements draft; it is not permission to silently choose it during coding.

| Area | Open decisions |
| --- | --- |
| Development target | Godot version and specific desktop operating systems. GDScript and mouse/keyboard input are confirmed. |
| Grid and movement | Grid geometry; legal movement directions; distance/path rules; occupancy and passing units; blocker behavior. |
| Turn completion | Skipping movement/action; ending turns; switching between partly used units; splitting movement; manual/automatic phase completion. |
| Stats and attacks | Recover missing stat names; initial values; damage, hit, critical-hit, and avoidance formulas; critical damage; whether Speed grants extra attacks and how. |
| Reactions | Automatic counterattacks are confirmed. Remaining decisions include eligibility beyond weapon range, timing, costs, interaction with extra attacks, and what happens when a defender reaches zero health before responding. |
| Weapons and defense | Exact weapon/armor categories, ranges, and interaction matrix; whether cybernetic/mechanical are separate categories. |
| Classes and abilities | Exact roster, class abilities, personal-ability system, and prototype roles. |
| Targeting and cover | Line of sight, shot blockers, protection rules, and visibility effects. |
| Objects | Destruction rules, resulting changes to movement/targeting, and whether interaction consumes an action. |
| Environmental effects | Exact liquid, fire, electricity, explosion, smoke/mist behavior and combinations. |
| Hacking | Direct targeting or network access; targets, range, access rules, effects, and action costs. |
| Enemies and encounter | Minimum AI behavior, map dimensions, unit counts and starting positions. |
| Encounter completion | What happens at zero health; victory/defeat or sandbox completion/reset; no assumption of permanent character death. |
| Authoring | Expected workflow for levels, characters, and puzzles; what puzzle types are actually wanted. |

Grid details, turn-completion edge cases, development target details, and encounter completion are additional gaps identified while organizing the requirements. They are questions to resolve, not new mechanics.

## Full game ideas outside the initial prototype

Keep recruitment systems, dialogue, relationships and potential romance, an explorable central hub, cosmetic outfits, large inventories, complete RPG progression, class trees, branching narrative, and substantial minigames outside the initial combat prototype.

Later concepts include hub access progression, environmental/access puzzles, optional-content restrictions across playthroughs, and brief post-battle exploration or looting before reinforcements arrive. These are future possibilities, not approved systems. Extremely long-range weapons and advanced hacking are also later possibilities, not first-prototype requirements.

## Source and decision authority

This draft uses the current game request, the designer's follow-up choices, and the supplied discussion notes from the original planning conversation. The current request and follow-up choices take precedence where they update the earlier discussion. Preserve open decisions explicitly, and update this document as the designer chooses rules. Implementation of the approved first prototype is now authorized.

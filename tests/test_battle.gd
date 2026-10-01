extends SceneTree

const BattleStateScript = preload("res://scripts/battle_state.gd")
const CombatRulesScript = preload("res://scripts/combat_rules.gd")

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_setup_and_restart()
	_test_movement_and_occupancy()
	_test_both_action_orders()
	_test_wait_and_active_side()
	_test_ranges_and_sight_lines()
	_test_forecast_formulas()
	_test_strike_outcomes()
	_test_counterattack_eligibility()
	_test_counterattacks_preserve_opportunities()
	_test_enemy_behavior()
	_test_phase_cycle()
	_test_encounter_endings()
	_test_complete_encounter()
	if _failures.is_empty():
		print("PASS: %d battle rule checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		printerr("%d of %d battle rule checks failed" % [_failures.size(), _checks])
		quit(1)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _unit(id: String, side: String, pos: Vector2i, ranged := false) -> Dictionary:
	return {
		"id": id, "name": id, "side": side, "role": "ranged" if ranged else "melee",
		"pos": pos, "hp": 200, "max_hp": 200,
		"attack": 8, "defense": 3, "agility": 8, "speed": 6, "move": 4,
		"min_range": 2 if ranged else 1, "max_range": 3 if ranged else 1,
		"moved": false, "acted": false, "waited": false,
	}


func _fresh():
	var battle = BattleStateScript.new()
	battle.setup()
	battle.level = {"name": "Rule fixture", "width": 8, "height": 6, "walls": []}
	battle.units.clear()
	battle.units.append(_unit("player", "player", Vector2i(1, 1)))
	battle.units.append(_unit("enemy", "enemy", Vector2i(2, 1)))
	battle.rng.seed = 1847
	return battle


func _test_setup_and_restart() -> void:
	var battle = BattleStateScript.new()
	battle.setup()
	_check(battle.phase == "player", "A new encounter starts in the player phase")
	_check(battle.level.width == 12 and battle.level.height == 9, "The sandbox loads its 12 by 9 map")
	var player_count := 0
	var enemy_count := 0
	for unit in battle.units:
		if unit.side == "player":
			player_count += 1
		else:
			enemy_count += 1
	_check(player_count == 3 and enemy_count == 3, "The encounter loads three units per side")
	var starting_attack := false
	for attacker in battle.units:
		for defender in battle.units:
			starting_attack = starting_attack or battle.can_attack(attacker.id, defender.id)
	_check(not starting_attack, "The actual encounter starts with no legal attack from either side")
	var original_units: Array = battle.units.duplicate(true)
	var original_round: int = battle.round_number
	battle.units[0].hp = 0
	battle.units[1].moved = true
	battle.phase = "defeat"
	battle.restart()
	_check(battle.phase == "player", "Restart restores the player phase")
	_check(battle.round_number == original_round, "Restart restores the initial round")
	_check(battle.units == original_units, "Restart restores original units, positions, health, and opportunities")


func _test_movement_and_occupancy() -> void:
	var battle = _fresh()
	var player: Dictionary = battle.get_unit("player")
	player.move = 2
	battle.get_unit("enemy").pos = Vector2i(1, 2)
	battle.level.walls.append(Vector2i(2, 1))
	battle.units.append(_unit("ally", "player", Vector2i(0, 1)))
	var reachable: Array = battle.reachable_cells("player")
	_check(reachable.has(Vector2i(1, 0)), "Reachability includes an open orthogonal neighbor")
	_check(reachable.has(Vector2i(2, 0)), "Reachability includes a legal two-step route")
	_check(not reachable.has(Vector2i(2, 1)), "Walls cannot be occupied")
	_check(not reachable.has(Vector2i(1, 2)), "Enemy-occupied tiles cannot be entered")
	_check(not reachable.has(Vector2i(0, 1)), "Ally-occupied tiles cannot be entered")
	_check(not reachable.has(Vector2i(2, 2)), "Movement cannot cut diagonally through blocked neighbors")
	_check(not reachable.has(Vector2i(1, 3)), "Movement cannot pass through an occupied tile")
	_check(not reachable.has(Vector2i(4, 1)), "Tiles beyond the movement allowance are unreachable")
	_check(not battle.move_unit("player", Vector2i(2, 1)), "A move into a wall is rejected")
	_check(not player.moved, "A rejected move does not consume movement")
	_check(battle.move_unit("player", Vector2i(1, 0)), "A valid move succeeds")
	_check(player.pos == Vector2i(1, 0) and player.moved, "Moving updates the live unit and consumes its movement")
	_check(not battle.move_unit("player", Vector2i(2, 0)), "A completed move cannot be split into another move")
	_check(not player.acted, "Movement leaves the normal action available")


func _test_both_action_orders() -> void:
	var battle = _fresh()
	battle.get_unit("enemy").pos = Vector2i(3, 1)
	_check(battle.move_unit("player", Vector2i(2, 1)), "Move-then-attack: movement succeeds")
	_check(battle.attack_unit("player", "enemy"), "Move-then-attack: attack remains available")
	_check(battle.get_unit("player").moved and battle.get_unit("player").acted, "Move-then-attack consumes both opportunities")
	_check(not battle.attack_unit("player", "enemy"), "A unit cannot initiate a second attack")
	battle = _fresh()
	_check(battle.attack_unit("player", "enemy"), "Attack-then-move: attack succeeds")
	_check(not battle.get_unit("player").moved, "An attack does not consume unused movement")
	_check(battle.move_unit("player", Vector2i(1, 2)), "Attack-then-move: movement remains available")
	_check(battle.get_unit("player").moved and battle.get_unit("player").acted, "Attack-then-move consumes both opportunities")


func _test_wait_and_active_side() -> void:
	var battle = _fresh()
	_check(not battle.move_unit("enemy", Vector2i(3, 1)), "An enemy cannot take normal movement during the player phase")
	_check(not battle.attack_unit("enemy", "player"), "An enemy cannot initiate an attack during the player phase")
	_check(not battle.wait_unit("enemy"), "The inactive side cannot spend a normal turn waiting")
	_check(battle.wait_unit("player"), "Wait succeeds for an active player unit")
	_check(not battle.move_unit("player", Vector2i(1, 2)), "Wait forfeits remaining movement")
	_check(not battle.attack_unit("player", "enemy"), "Wait forfeits the remaining attack")
	_check(battle.phase == "player", "Using every player opportunity does not automatically end the phase")
	battle = _fresh()
	battle.units.append(_unit("ally", "player", Vector2i(1, 3)))
	_check(battle.move_unit("player", Vector2i(0, 1)), "The first unit may spend only its movement")
	_check(battle.move_unit("ally", Vector2i(1, 2)), "The player may switch to another available unit")
	battle.get_unit("enemy").pos = Vector2i(0, 2)
	_check(battle.attack_unit("player", "enemy"), "The player may return to a partly used unit")


func _test_ranges_and_sight_lines() -> void:
	var battle = _fresh()
	var player: Dictionary = battle.get_unit("player")
	var enemy: Dictionary = battle.get_unit("enemy")
	player.min_range = 2
	player.max_range = 3
	_check(not battle.can_attack("player", "enemy"), "A range 2–3 weapon cannot attack an adjacent target")
	enemy.pos = Vector2i(3, 1)
	_check(battle.can_attack("player", "enemy"), "A range 2–3 weapon can attack at distance two")
	enemy.pos = Vector2i(4, 1)
	_check(battle.can_attack("player", "enemy"), "A range 2–3 weapon can attack at distance three")
	enemy.pos = Vector2i(3, 3)
	_check(not battle.can_attack("player", "enemy"), "Range uses Manhattan distance rather than diagonal distance")
	_check(battle.can_attack("player", "enemy", Vector2i(3, 1)), "Hypothetical-origin targeting uses the proposed origin")
	_check(player.pos == Vector2i(1, 1), "Hypothetical targeting does not move the unit")
	player.pos = Vector2i(0, 0)
	player.max_range = 8
	enemy.pos = Vector2i(2, 2)
	battle.level.walls.append(Vector2i(1, 0))
	_check(not battle.can_attack("player", "enemy"), "A diagonal sight line touching a wall corner is blocked")
	battle.level.walls.clear()
	battle.level.walls.append(Vector2i(1, 1))
	_check(not battle.can_attack("player", "enemy"), "A wall directly on the sight line blocks attacks")
	battle.level.walls.clear()
	player.pos = Vector2i(0, 1)
	enemy.pos = Vector2i(3, 1)
	battle.units.append(_unit("ally", "player", Vector2i(1, 1)))
	_check(battle.can_attack("player", "enemy"), "An intervening unit does not block shots")
	_check(not battle.can_attack("player", "ally"), "Friendly units are not legal attack targets")
	enemy.hp = 0
	_check(not battle.can_attack("player", "enemy"), "Dead units are not legal attack targets")
	var occupant = battle.unit_at(enemy.pos)
	_check(occupant == null or (occupant is Dictionary and occupant.is_empty()), "Dead units no longer occupy their tile")


func _test_forecast_formulas() -> void:
	var battle = _fresh()
	var player: Dictionary = battle.get_unit("player")
	var enemy: Dictionary = battle.get_unit("enemy")
	var forecast: Dictionary = battle.forecast("player", "enemy")
	_check(forecast.damage == 5, "Normal damage equals Attack minus Defense")
	_check(forecast.hit == 89, "Hit forecast follows the approved Agility/Speed formula")
	_check(forecast.crit == 4, "Critical chance follows floor(Agility / 2)")
	_check(forecast.counter and forecast.counter_damage == 5, "Forecast includes an eligible defender's counterattack")
	_check(forecast.counter_hit == 89 and forecast.counter_crit == 4, "Forecast includes counterattack hit and critical chances")
	player.attack = 1
	player.agility = 0
	enemy.defense = 20
	enemy.speed = 100
	forecast = battle.forecast("player", "enemy")
	_check(forecast.damage == 0, "Defense cannot produce negative damage")
	_check(forecast.hit == 10 and forecast.crit == 0, "Hit has a 10% minimum and critical chance can be zero")
	player.agility = 100
	enemy.speed = 0
	forecast = battle.forecast("player", "enemy")
	_check(forecast.hit == 100 and forecast.crit == 20, "Hit and critical chances respect their upper caps")
	player.agility = 9
	_check(battle.forecast("player", "enemy").crit == 4, "Odd Agility rounds critical chance down")


func _test_counterattack_eligibility() -> void:
	var battle = _fresh()
	var player: Dictionary = battle.get_unit("player")
	var enemy: Dictionary = battle.get_unit("enemy")
	player.agility = 100
	enemy.hp = 1
	var player_hp: int = player.hp
	_check(battle.attack_unit("player", "enemy"), "A lethal attack is resolved")
	_check(enemy.hp == 0, "Lethal damage clamps health to zero")
	_check(player.hp == player_hp, "A defeated defender cannot counterattack")
	battle = _fresh()
	player = battle.get_unit("player")
	enemy = battle.get_unit("enemy")
	player.min_range = 2
	player.max_range = 3
	enemy.pos = Vector2i(3, 1)
	_check(not battle.forecast("player", "enemy").counter, "A melee defender cannot counterattack a range-two attacker")
	player_hp = player.hp
	_check(battle.attack_unit("player", "enemy"), "A ranged attack against a melee defender succeeds")
	_check(player.hp == player_hp, "An out-of-range defender causes no counterattack damage")
	battle = _fresh()
	player = battle.get_unit("player")
	enemy = battle.get_unit("enemy")
	player.agility = 0
	player.speed = 0
	enemy.speed = 100
	enemy.agility = 100
	var predictor := RandomNumberGenerator.new()
	var miss_seed := -1
	for candidate in range(1, 100):
		predictor.seed = candidate
		if not CombatRulesScript.strike(player, enemy, predictor).landed:
			miss_seed = candidate
			break
	_check(miss_seed >= 0, "The deterministic miss fixture finds a missed first strike")
	battle.rng.seed = miss_seed
	player_hp = player.hp
	var enemy_hp: int = enemy.hp
	_check(battle.attack_unit("player", "enemy"), "A missed initiating attack is still a completed action")
	_check(enemy.hp == enemy_hp and player.hp < player_hp, "A missed first strike still provokes an eligible counterattack")
	_check(player.acted, "Missing consumes the initiating unit's action")


func _test_counterattacks_preserve_opportunities() -> void:
	var battle = _fresh()
	var enemy: Dictionary = battle.get_unit("enemy")
	battle.get_unit("player").agility = 100
	battle.get_unit("player").speed = 20
	enemy.agility = 100
	enemy.speed = 0
	var player_hp: int = battle.get_unit("player").hp
	var enemy_hp: int = enemy.hp
	var predictor := RandomNumberGenerator.new()
	predictor.seed = battle.rng.seed
	var first_strike: Dictionary = CombatRulesScript.strike(battle.get_unit("player"), enemy, predictor)
	var counter_strike: Dictionary = CombatRulesScript.strike(enemy, battle.get_unit("player"), predictor)
	_check(battle.attack_unit("player", "enemy"), "A reciprocal attack succeeds")
	_check(battle.get_unit("player").hp < player_hp, "An in-range surviving defender automatically counterattacks")
	_check(enemy.hp == enemy_hp - first_strike.dealt, "The initiator strikes exactly once, without a counterattack chain or Speed follow-up")
	_check(battle.get_unit("player").hp == player_hp - counter_strike.dealt, "The defender strikes exactly once")
	_check(not enemy.moved and not enemy.acted and not enemy.waited, "A counterattack consumes none of the defender's normal opportunities")
	battle.units.append(_unit("ally", "player", Vector2i(2, 2)))
	battle.get_unit("ally").agility = 100
	var ally_hp: int = battle.get_unit("ally").hp
	_check(battle.attack_unit("ally", "enemy"), "A second player may attack the same defender in the same phase")
	_check(battle.get_unit("ally").hp < ally_hp, "A defender may counterattack again in the same phase")
	_check(not enemy.acted, "Repeated counterattacks still preserve the defender's normal action")


func _test_strike_outcomes() -> void:
	var attacker := _unit("attacker", "player", Vector2i.ZERO)
	var defender := _unit("defender", "enemy", Vector2i.RIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1847
	var saw_normal := false
	var saw_critical := false
	var saw_miss := false
	var valid_damage := true
	var valid_misses := true
	for trial in range(256):
		var result: Dictionary = CombatRulesScript.strike(attacker, defender, rng)
		if not result.landed:
			saw_miss = true
			valid_misses = valid_misses and result.dealt == 0 and not result.critical
		elif result.critical:
			saw_critical = true
			valid_damage = valid_damage and result.dealt == 10
		else:
			saw_normal = true
			valid_damage = valid_damage and result.dealt == 5
	_check(saw_normal and saw_critical and saw_miss, "A fixed random sequence exercises normal hits, critical hits, and misses")
	_check(valid_damage, "Critical hits deal twice normal damage and ordinary hits use normal damage")
	_check(valid_misses, "Misses deal no damage and cannot be critical")


func _test_phase_cycle() -> void:
	var battle = _fresh()
	var player: Dictionary = battle.get_unit("player")
	var enemy: Dictionary = battle.get_unit("enemy")
	player.hp = 1000
	enemy.hp = 1000
	player.moved = true
	player.acted = true
	player.waited = true
	enemy.moved = true
	enemy.acted = true
	enemy.waited = true
	var initial_round: int = battle.round_number
	battle.end_player_phase()
	_check(battle.phase == "enemy", "End Phase explicitly starts the enemy phase")
	_check(not enemy.moved and not enemy.acted and not enemy.waited, "Enemy opportunities refresh at the start of their phase")
	_check(not battle.move_unit("player", Vector2i(1, 2)), "Player normal movement is unavailable during the enemy phase")
	var steps := 0
	while battle.phase == "enemy" and steps < 20:
		battle.enemy_step()
		steps += 1
	_check(battle.phase == "player", "The sequential enemy phase returns to the player phase")
	_check(steps < 20, "The enemy phase completes within a finite number of unit steps")
	_check(not player.moved and not player.acted and not player.waited, "Player opportunities refresh on the next player phase")
	_check(battle.round_number == initial_round + 1, "A full phase cycle advances the round once")


func _test_enemy_behavior() -> void:
	var battle = _fresh()
	var enemy: Dictionary = battle.get_unit("enemy")
	enemy.agility = 100
	var original_pos: Vector2i = enemy.pos
	var player_hp: int = battle.get_unit("player").hp
	battle.end_player_phase()
	battle.enemy_step()
	_check(enemy.pos == original_pos and not enemy.moved, "An enemy already in range attacks without moving first")
	_check(enemy.acted and battle.get_unit("player").hp < player_hp, "An enemy attacks a legal target already in range")
	battle = _fresh()
	enemy = battle.get_unit("enemy")
	enemy.pos = Vector2i(5, 1)
	enemy.agility = 100
	original_pos = enemy.pos
	player_hp = battle.get_unit("player").hp
	battle.end_player_phase()
	battle.enemy_step()
	_check(enemy.pos != original_pos and enemy.moved, "An out-of-range enemy moves toward an opponent")
	_check(enemy.acted and battle.get_unit("player").hp < player_hp, "An enemy prefers a reachable tile that permits an attack, then attacks")


func _test_encounter_endings() -> void:
	var battle = _fresh()
	battle.get_unit("player").agility = 100
	battle.get_unit("enemy").hp = 1
	_check(battle.attack_unit("player", "enemy"), "The last enemy can be defeated")
	_check(battle.phase == "victory", "Defeating every enemy ends the encounter in victory")
	_check(not battle.move_unit("player", Vector2i(1, 2)), "Normal movement is disabled after victory")
	battle = _fresh()
	battle.get_unit("player").hp = 1
	battle.get_unit("enemy").agility = 100
	battle.end_player_phase()
	var steps := 0
	while battle.phase == "enemy" and steps < 20:
		battle.enemy_step()
		steps += 1
	_check(battle.phase == "defeat", "Losing every player unit ends the encounter in defeat")


func _test_complete_encounter() -> void:
	var battle = BattleStateScript.new()
	battle.setup()
	battle.rng.seed = 20261001
	var cycles := 0
	var enemy_phase_stalled := false
	while battle.phase == "player" and cycles < 100:
		# Reuse the approved simple AI only as a test driver for player choices.
		# Production player units remain under mouse/keyboard control.
		for unit in battle.units:
			if battle.phase != "player":
				break
			if unit.side == "player" and unit.hp > 0:
				battle._take_enemy_turn(unit)
		if battle.phase != "player":
			break
		battle.end_player_phase()
		var enemy_steps := 0
		while battle.phase == "enemy" and enemy_steps < 10:
			battle.enemy_step()
			enemy_steps += 1
		if battle.phase == "enemy":
			enemy_phase_stalled = true
			break
		cycles += 1
	_check(not enemy_phase_stalled, "The actual encounter's enemy phases complete without stalling")
	_check(battle.phase == "victory" or battle.phase == "defeat", "The actual map reaches an encounter result within 100 automated rounds")
	print("Actual-map simulation: %s at round %d" % [battle.phase, battle.round_number])

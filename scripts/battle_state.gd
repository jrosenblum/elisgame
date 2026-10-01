class_name BattleState
extends RefCounted
## Encounter state and turn transitions. All content is loaded from JSON.

const Grid = preload("res://scripts/grid_rules.gd")
const Combat = preload("res://scripts/combat_rules.gd")

signal changed

var phase: String = "player"
var round_number: int = 1
var units: Array[Dictionary] = []
var level: Dictionary = {}
var logs: Array[String] = []
var rng := RandomNumberGenerator.new()
var _level_path := "res://data/test_map.json"
var _units_path := "res://data/unit_types.json"
var _enemy_order: Array[String] = []
var _enemy_cursor := 0

func setup(level_path: String = "res://data/test_map.json", units_path: String = "res://data/unit_types.json") -> void:
	_level_path = level_path
	_units_path = units_path
	rng.randomize()
	restart()

func restart() -> void:
	var map_data: Dictionary = _read_json(_level_path)
	var types: Dictionary = _read_json(_units_path)
	if map_data.is_empty() or types.is_empty():
		return
	var walls: Array[Vector2i] = []
	for wall in map_data.walls:
		walls.append(Vector2i(int(wall[0]), int(wall[1])))
	level = {"name": map_data.name, "width": int(map_data.width), "height": int(map_data.height), "walls": walls}
	units.clear()
	for entry in map_data.units:
		var unit: Dictionary = types[entry.role].duplicate(true)
		for key in unit.keys():
			unit[key] = int(unit[key])
		unit.merge({"id": entry.id, "name": entry.name, "side": entry.side, "role": entry.role,
			"pos": Vector2i(int(entry.position[0]), int(entry.position[1])), "hp": unit.max_hp,
			"moved": false, "acted": false, "waited": false}, true)
		units.append(unit)
	phase = "player"
	round_number = 1
	_enemy_order.clear()
	_enemy_cursor = 0
	logs.clear()
	_log("Encounter ready. Select a unit. Move and attack in either order.")
	changed.emit()

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot read content: " + path)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		push_error("Invalid JSON content: " + path)
		return {}
	return parser.data

func get_unit(id: String) -> Dictionary:
	for unit in units:
		if unit.id == id:
			return unit
	return {}

func unit_at(cell: Vector2i) -> Dictionary:
	for unit in units:
		if int(unit.hp) > 0 and unit.pos == cell:
			return unit
	return {}

func _occupied(except_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for unit in units:
		if unit.id != except_id and int(unit.hp) > 0:
			result.append(unit.pos)
	return result

func _available(unit: Dictionary) -> bool:
	return not unit.is_empty() and int(unit.hp) > 0 and unit.side == phase and not bool(unit.waited)

func reachable_cells(id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var unit := get_unit(id)
	if not _available(unit) or unit.moved:
		return result
	var distances: Dictionary = Grid.movement_distances(unit.pos, int(unit.move), level, _occupied(id))
	for cell in distances:
		if cell != unit.pos:
			result.append(cell)
	return result

func can_attack(attacker_id: String, defender_id: String, from_cell: Vector2i = Vector2i(-1, -1)) -> bool:
	var attacker := get_unit(attacker_id)
	var defender := get_unit(defender_id)
	if attacker.is_empty() or defender.is_empty() or int(attacker.hp) <= 0 or int(defender.hp) <= 0 or attacker.side == defender.side:
		return false
	var origin: Vector2i = attacker.pos if from_cell == Vector2i(-1, -1) else from_cell
	var span: int = Grid.distance(origin, defender.pos)
	return span >= int(attacker.min_range) and span <= int(attacker.max_range) and Grid.line_clear(origin, defender.pos, level.walls)

func forecast(attacker_id: String, defender_id: String) -> Dictionary:
	var attacker := get_unit(attacker_id)
	var defender := get_unit(defender_id)
	if attacker.is_empty() or defender.is_empty():
		return {}
	var result: Dictionary = Combat.forecast(attacker, defender)
	var counter: Dictionary = Combat.forecast(defender, attacker)
	result["counter"] = can_attack(defender_id, attacker_id)
	result["counter_damage"] = counter.damage
	result["counter_hit"] = counter.hit
	result["counter_crit"] = counter.crit
	return result

func move_unit(id: String, destination: Vector2i) -> bool:
	var unit := get_unit(id)
	if not _available(unit) or destination not in reachable_cells(id):
		return false
	unit.pos = destination
	unit.moved = true
	_log("%s moved to %d, %d." % [unit.name, destination.x + 1, destination.y + 1])
	changed.emit()
	return true

func attack_unit(attacker_id: String, defender_id: String) -> bool:
	var attacker := get_unit(attacker_id)
	if not _available(attacker) or attacker.acted or not can_attack(attacker_id, defender_id):
		return false
	var defender := get_unit(defender_id)
	attacker.acted = true
	_resolve_strike(attacker, defender, false)
	if int(defender.hp) > 0 and can_attack(defender_id, attacker_id):
		_resolve_strike(defender, attacker, true)
	_check_outcome()
	changed.emit()
	return true

func _resolve_strike(attacker: Dictionary, defender: Dictionary, is_counter: bool) -> void:
	var result: Dictionary = Combat.strike(attacker, defender, rng)
	var prefix := "Counter · " if is_counter else ""
	if not result.landed:
		_log("%s%s missed %s." % [prefix, attacker.name, defender.name])
		return
	defender.hp = maxi(0, int(defender.hp) - int(result.dealt))
	_log("%s%s → %s: %d damage%s." % [prefix, attacker.name, defender.name, result.dealt, " · CRITICAL" if result.critical else ""])
	if int(defender.hp) == 0:
		_log("%s removed from the encounter." % defender.name)

func wait_unit(id: String) -> bool:
	var unit := get_unit(id)
	if not _available(unit):
		return false
	unit.moved = true
	unit.acted = true
	unit.waited = true
	_log("%s is waiting." % unit.name)
	changed.emit()
	return true

func end_player_phase() -> void:
	if phase != "player":
		return
	phase = "enemy"
	_refresh_side("enemy")
	_enemy_order.clear()
	for unit in units:
		if unit.side == "enemy" and int(unit.hp) > 0:
			_enemy_order.append(unit.id)
	_enemy_cursor = 0
	_log("Enemy phase.")
	changed.emit()

func enemy_step() -> bool:
	if phase != "enemy":
		return true
	while _enemy_cursor < _enemy_order.size():
		var unit := get_unit(_enemy_order[_enemy_cursor])
		_enemy_cursor += 1
		if int(unit.hp) <= 0:
			continue
		_take_enemy_turn(unit)
		if phase != "enemy":
			return true
		changed.emit()
		return false
	phase = "player"
	round_number += 1
	_refresh_side("player")
	_log("Player phase · round %d." % round_number)
	changed.emit()
	return true

func _refresh_side(side: String) -> void:
	for unit in units:
		if unit.side == side and int(unit.hp) > 0:
			unit.moved = false
			unit.acted = false
			unit.waited = false

func _nearest_opponents(unit: Dictionary) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for other in units:
		if other.side != unit.side and int(other.hp) > 0:
			targets.append(other)
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da: int = Grid.distance(unit.pos, a.pos)
		var db: int = Grid.distance(unit.pos, b.pos)
		return String(a.id) < String(b.id) if da == db else da < db)
	return targets

func _take_enemy_turn(unit: Dictionary) -> void:
	var targets := _nearest_opponents(unit)
	if targets.is_empty():
		_check_outcome()
		return
	for target in targets:
		if can_attack(unit.id, target.id):
			attack_unit(unit.id, target.id)
			unit.waited = true
			return
	var destinations := reachable_cells(unit.id)
	var best_cell: Vector2i = unit.pos
	var best_score := 1000000
	# Prefer a tile with a legal attack, then shortest distance to an opponent.
	# BFS order supplies deterministic ties without adding tactical systems.
	for cell in destinations:
		var nearest := 100000
		var attack_possible := false
		for target in targets:
			nearest = mini(nearest, Grid.distance(cell, target.pos))
			if can_attack(unit.id, target.id, cell):
				attack_possible = true
		var score: int = nearest + (0 if attack_possible else 10000)
		if score < best_score:
			best_score = score
			best_cell = cell
	if best_cell != unit.pos:
		move_unit(unit.id, best_cell)
	targets = _nearest_opponents(unit)
	for target in targets:
		if can_attack(unit.id, target.id):
			attack_unit(unit.id, target.id)
			break
	unit.waited = true

func _check_outcome() -> void:
	var players := 0
	var enemies := 0
	for unit in units:
		if int(unit.hp) > 0:
			if unit.side == "player":
				players += 1
			else:
				enemies += 1
	if enemies == 0:
		phase = "victory"
		_log("VICTORY · All enemies defeated. Restart to play again.")
	elif players == 0:
		phase = "defeat"
		_log("DEFEAT · All player units defeated. Restart to try again.")

func _log(message: String) -> void:
	logs.append(message)
	if logs.size() > 40:
		logs.pop_front()

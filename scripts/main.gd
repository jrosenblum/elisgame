extends Control

const BoardScript = preload("res://scripts/battle_board.gd")
const BattleScript = preload("res://scripts/battle_state.gd")
const BG := Color("0a101c")
const PANEL := Color("111d2c")
const BORDER := Color("293b51")
const TEXT := Color("e4edf6")
const MUTED := Color("8d9eb5")
const CYAN := Color("62eadb")
const AMBER := Color("ffb96a")

var battle: RefCounted = BattleScript.new()
var selected_id: String = ""
var mode: String = "inspect"
var pending_target: String = ""
var _resolving: bool = false
var _board: Control
var _phase_label: Label
var _round_label: Label
var _map_name: Label
var _mode_label: Label
var _unit_name: Label
var _unit_role: Label
var _hp_label: Label
var _health_bar: ProgressBar
var _stats_label: Label
var _turn_label: Label
var _move_button: Button
var _attack_button: Button
var _wait_button: Button
var _end_button: Button
var _forecast_title: Label
var _forecast_values: Label
var _counter_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _log: RichTextLabel
var _enemy_timer: Timer


func _ready() -> void:
	_build_ui()
	_enemy_timer = Timer.new()
	_enemy_timer.wait_time = 0.45
	_enemy_timer.timeout.connect(_enemy_tick)
	add_child(_enemy_timer)
	battle.changed.connect(_refresh)
	battle.setup()
	_refresh()


func _build_ui() -> void:
	var theme_data := Theme.new()
	theme_data.default_font_size = 14
	theme_data.set_color("font_color", "Label", TEXT)
	theme_data.set_color("font_color", "Button", TEXT)
	theme_data.set_color("font_hover_color", "Button", Color.WHITE)
	theme_data.set_color("font_disabled_color", "Button", Color("58697e"))
	theme_data.set_stylebox("normal", "Button", _style(Color("1d2c40"), Color("3d526b"), 5))
	theme_data.set_stylebox("hover", "Button", _style(Color("2a3d52"), CYAN, 5))
	theme_data.set_stylebox("pressed", "Button", _style(Color("27515a"), CYAN, 5))
	theme_data.set_stylebox("disabled", "Button", _style(Color("142030"), Color("223348"), 5))
	theme_data.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, CYAN, 5))
	theme = theme_data
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 26)
	for edge in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	page.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)
	title_box.add_child(_label("CYBERPUNK  /  TACTICS", 26, TEXT))
	title_box.add_child(_label("FIRST COMBAT PROTOTYPE     •     MELEE + RANGED", 11, MUTED))
	var phase_box := VBoxContainer.new()
	phase_box.add_theme_constant_override("separation", 3)
	header.add_child(phase_box)
	_phase_label = _label("PLAYER PHASE", 19, CYAN)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phase_box.add_child(_phase_label)
	_round_label = _label("ROUND 01", 11, MUTED)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phase_box.add_child(_round_label)
	var restart := _button("Restart  [R]", _restart)
	restart.custom_minimum_size = Vector2(114, 38)
	restart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(restart)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(content)
	var board_card: VBoxContainer = _card(content)
	board_card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_card.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.get_parent().custom_minimum_size = Vector2(590, 450)
	var board_heading := HBoxContainer.new()
	board_heading.add_theme_constant_override("separation", 14)
	board_card.add_child(board_heading)
	_map_name = _label("TEST ENCOUNTER", 12, TEXT)
	_map_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_heading.add_child(_map_name)
	board_heading.add_child(_label("■ ALLY", 10, CYAN))
	board_heading.add_child(_label("■ ENEMY", 10, AMBER))
	_board = BoardScript.new()
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.cell_clicked.connect(_on_cell_clicked)
	board_card.add_child(_board)
	_mode_label = _label("Select a unit to begin.", 12, MUTED)
	_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_label.custom_minimum_size.y = 34
	board_card.add_child(_mode_label)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 326
	sidebar.add_theme_constant_override("separation", 12)
	content.add_child(sidebar)
	var unit_card: VBoxContainer = _card(sidebar)
	unit_card.add_theme_constant_override("separation", 4)
	unit_card.add_child(_label("UNIT INSPECTOR", 10, MUTED))
	_unit_name = _label("No unit selected", 22, TEXT)
	unit_card.add_child(_unit_name)
	_unit_role = _label("Click a unit on the battlefield.", 12, MUTED)
	unit_card.add_child(_unit_role)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 10)
	unit_card.add_child(hp_row)
	_health_bar = ProgressBar.new()
	_health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_health_bar.custom_minimum_size.y = 8
	_health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_health_bar.show_percentage = false
	_health_bar.add_theme_stylebox_override("background", _style(Color("28394d"), Color.TRANSPARENT, 2))
	_health_bar.add_theme_stylebox_override("fill", _style(CYAN, Color.TRANSPARENT, 2))
	hp_row.add_child(_health_bar)
	_hp_label = _label("— / — HP", 12, TEXT)
	hp_row.add_child(_hp_label)
	_stats_label = _label("ATK —    DEF —    MOVE —\nAGI —    SPD —    RANGE —", 12, MUTED)
	_stats_label.add_theme_constant_override("line_spacing", 3)
	unit_card.add_child(_stats_label)
	_turn_label = _label("Movement —     Action —", 11, CYAN)
	unit_card.add_child(_turn_label)
	var action_card: VBoxContainer = _card(sidebar)
	action_card.add_theme_constant_override("separation", 6)
	action_card.add_child(_label("UNIT COMMANDS", 10, MUTED))
	var commands := HBoxContainer.new()
	commands.add_theme_constant_override("separation", 7)
	action_card.add_child(commands)
	_move_button = _button("Move [M]", func() -> void: _set_mode("move"))
	_attack_button = _button("Attack [A]", func() -> void: _set_mode("attack"))
	_wait_button = _button("Wait [W]", _wait_selected)
	for button in [_move_button, _attack_button, _wait_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 32
		button.add_theme_font_size_override("font_size", 12)
		commands.add_child(button)
	_end_button = _button("End player phase  [E]", _end_phase)
	_end_button.custom_minimum_size.y = 32
	_end_button.add_theme_color_override("font_color", CYAN)
	action_card.add_child(_end_button)
	var forecast_card: VBoxContainer = _card(sidebar)
	forecast_card.add_theme_constant_override("separation", 4)
	forecast_card.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	forecast_card.add_child(_label("COMBAT FORECAST", 10, MUTED))
	_forecast_title = _label("Choose an attack target", 15, TEXT)
	_forecast_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast_card.add_child(_forecast_title)
	_forecast_values = _label("Select a unit, then use Attack\nto highlight legal targets.", 13, MUTED)
	_forecast_values.add_theme_constant_override("line_spacing", 6)
	forecast_card.add_child(_forecast_values)
	_counter_label = _label("", 12, AMBER)
	_counter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast_card.add_child(_counter_label)
	var forecast_spacer := Control.new()
	forecast_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	forecast_card.add_child(forecast_spacer)
	var confirmation_row := HBoxContainer.new()
	confirmation_row.add_theme_constant_override("separation", 8)
	forecast_card.add_child(confirmation_row)
	_confirm_button = _button("Confirm attack", _confirm_attack)
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.add_theme_font_size_override("font_size", 12)
	_confirm_button.add_theme_stylebox_override("normal", _style(Color("21464d"), CYAN, 5))
	_confirm_button.add_theme_color_override("font_color", CYAN)
	confirmation_row.add_child(_confirm_button)
	_cancel_button = _button("Cancel [Esc]", _cancel)
	_cancel_button.add_theme_font_size_override("font_size", 11)
	confirmation_row.add_child(_cancel_button)
	var log_card: VBoxContainer = _card(page)
	log_card.get_parent().custom_minimum_size.y = 100
	var log_heading := HBoxContainer.new()
	log_card.add_child(log_heading)
	var log_title: Label = _label("BATTLE LOG", 10, MUTED)
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_heading.add_child(log_title)
	log_heading.add_child(_label("LATEST EVENTS", 10, Color("5f7591")))
	_log = RichTextLabel.new()
	_log.custom_minimum_size.y = 51
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_active = true
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.add_theme_font_size_override("normal_font_size", 12)
	_log.add_theme_color_override("default_color", Color("b4c4d7"))
	log_card.add_child(_log)
	var hints := _label("LMB  Select / command     RMB / ESC  Cancel     M  Move     A  Attack     W  Wait     E  End phase     R  Restart", 11, MUTED)
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(hints)


func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(PANEL, BORDER, 8, 12))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	return column


func _style(fill: Color, border: Color, radius: int, padding: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 36
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	return button


func _refresh() -> void:
	var unit: Dictionary = battle.get_unit(selected_id)
	if not unit.is_empty() and int(unit.hp) <= 0:
		selected_id = ""
		unit = {}
	if not pending_target.is_empty() and not battle.can_attack(selected_id, pending_target):
		pending_target = ""
	var player_phase: bool = battle.phase == "player" and not _resolving
	var controllable: bool = player_phase and not unit.is_empty() and unit.side == "player" and not bool(unit.waited)
	var move_available: bool = controllable and not bool(unit.get("moved", true))
	var action_available: bool = controllable and not bool(unit.get("acted", true))
	if not action_available:
		pending_target = ""
		if mode == "attack":
			mode = "inspect"
	if not player_phase:
		mode = "inspect"
		pending_target = ""
	_phase_label.text = str(battle.phase).to_upper() + (" PHASE" if battle.phase in ["player", "enemy"] else "")
	_phase_label.add_theme_color_override("font_color", CYAN if battle.phase in ["player", "victory"] else AMBER)
	_round_label.text = "ROUND %02d   /   %s ALLIES   ·   %s ENEMIES" % [battle.round_number, _alive_count("player"), _alive_count("enemy")]
	_map_name.text = str(battle.level.get("name", "Test encounter")).to_upper()
	_move_button.disabled = not move_available or battle.reachable_cells(selected_id).is_empty()
	_attack_button.disabled = not action_available or not _has_target(selected_id)
	_wait_button.disabled = not controllable or (bool(unit.get("moved", true)) and bool(unit.get("acted", true)))
	_end_button.disabled = not player_phase
	_move_button.text = "Moving…" if mode == "move" else "Move [M]"
	_attack_button.text = "Targeting…" if mode == "attack" else "Attack [A]"
	if unit.is_empty():
		_unit_name.text = "No unit selected"
		_unit_role.text = "Click a unit on the battlefield."
		_hp_label.text = "— / — HP"
		_health_bar.value = 0
		_stats_label.text = "ATK —    DEF —    MOVE —\nAGI —    SPD —    RANGE —"
		_turn_label.text = "Movement —     Action —"
	else:
		var accent: Color = CYAN if unit.side == "player" else AMBER
		_unit_name.text = str(unit.name)
		_unit_name.add_theme_color_override("font_color", accent)
		_unit_role.text = "%s  /  %s" % [str(unit.role).to_upper(), "ALLY" if unit.side == "player" else "ENEMY"]
		_hp_label.text = "%s / %s HP" % [unit.hp, unit.max_hp]
		_health_bar.max_value = float(unit.max_hp)
		_health_bar.value = float(unit.hp)
		_health_bar.add_theme_stylebox_override("fill", _style(accent, Color.TRANSPARENT, 2))
		_stats_label.text = "ATK %s    DEF %s    MOVE %s\nAGI %s    SPD %s    RANGE %s–%s" % [unit.attack, unit.defense, unit.move, unit.agility, unit.speed, unit.min_range, unit.max_range]
		_turn_label.text = "Move: %s    Action: %s" % ["used" if bool(unit.moved) or bool(unit.waited) else "ready", "used" if bool(unit.acted) or bool(unit.waited) else "ready"]
		_turn_label.add_theme_color_override("font_color", accent)
	_refresh_forecast()
	_mode_label.text = _status_message(unit)
	_board.set_view(battle, selected_id, mode, pending_target)
	var recent: Array[String] = []
	for i in range(maxi(0, battle.logs.size() - 12), battle.logs.size()):
		recent.append(str(battle.logs[i]))
	_log.text = "\n".join(recent)
	if battle.phase == "enemy":
		if _enemy_timer.is_stopped():
			_enemy_timer.start()
	else:
		_enemy_timer.stop()


func _refresh_forecast() -> void:
	_confirm_button.visible = not pending_target.is_empty()
	_confirm_button.disabled = _resolving or battle.phase != "player"
	_cancel_button.visible = mode != "inspect" or not pending_target.is_empty()
	if pending_target.is_empty():
		_forecast_title.text = "Choose an attack target"
		_forecast_values.text = "Select a unit, then use Attack\nto highlight legal targets."
		_counter_label.text = "Attack and movement may be used\nin either order."
		_counter_label.add_theme_color_override("font_color", MUTED)
		return
	var attacker: Dictionary = battle.get_unit(selected_id)
	var defender: Dictionary = battle.get_unit(pending_target)
	var preview: Dictionary = battle.forecast(selected_id, pending_target)
	_forecast_title.text = "%s → %s" % [attacker.name, defender.name]
	_forecast_values.text = "DAMAGE     %s\nHIT              %s%%     /     CRIT  %s%%" % [preview.damage, preview.hit, preview.crit]
	_counter_label.add_theme_color_override("font_color", AMBER)
	if bool(preview.counter):
		_counter_label.text = "Counter if defender survives\n%s damage  ·  %s%% hit  ·  %s%% crit" % [preview.counter_damage, preview.counter_hit, preview.counter_crit]
	else:
		_counter_label.text = "No counterattack from this position."


func _status_message(unit: Dictionary) -> String:
	if battle.phase == "victory":
		return "Encounter complete. All enemies defeated. Press R to play again."
	if battle.phase == "defeat":
		return "Encounter ended. All allies defeated. Press R to try again."
	if battle.phase == "enemy":
		return "Enemy phase • resolving one unit at a time."
	if not pending_target.is_empty():
		return "Target armed. Review the forecast, then Confirm attack. Esc cancels."
	if mode == "move":
		return "Choose a highlighted tile to move. Right-click / Esc cancels."
	if mode == "attack":
		return "Choose a highlighted enemy to preview the attack. Right-click / Esc cancels."
	if unit.is_empty():
		return "Select an ally to move or attack. Select an enemy to inspect its stats."
	if unit.side == "enemy":
		return "Inspecting an enemy. Select an ally to issue commands."
	if bool(unit.waited) or (bool(unit.moved) and bool(unit.acted)):
		return "This unit is finished. Select another ally or end the player phase."
	if bool(unit.acted) and not bool(unit.moved):
		return "Action used. This unit can still move before ending its turn."
	return "Use Move, Attack, or Wait. End phase when your squad is ready."


func _alive_count(side: String) -> int:
	var count: int = 0
	for unit in battle.units:
		if unit.side == side and int(unit.hp) > 0:
			count += 1
	return count


func _has_target(unit_id: String) -> bool:
	for other in battle.units:
		if battle.can_attack(unit_id, str(other.id)):
			return true
	return false


func _on_cell_clicked(cell: Vector2i, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		_cancel()
		return
	if _resolving or battle.phase != "player":
		return
	var clicked: Dictionary = battle.unit_at(cell)
	if mode == "move" and cell in battle.reachable_cells(selected_id):
		mode = "inspect"
		pending_target = ""
		battle.move_unit(selected_id, cell)
		_refresh()
		return
	if not clicked.is_empty():
		if mode == "attack" and not _attack_button.disabled and battle.can_attack(selected_id, str(clicked.id)):
			mode = "attack"
			pending_target = str(clicked.id)
		else:
			selected_id = str(clicked.id)
			mode = "inspect"
			pending_target = ""
	elif mode == "inspect":
		selected_id = ""
		pending_target = ""
	_refresh()


func _set_mode(new_mode: String) -> void:
	if _resolving or battle.phase != "player":
		return
	if new_mode == "move" and _move_button.disabled:
		return
	if new_mode == "attack" and _attack_button.disabled:
		return
	mode = new_mode
	pending_target = ""
	_refresh()


func _confirm_attack() -> void:
	if _resolving or battle.phase != "player" or pending_target.is_empty():
		return
	var target_id: String = pending_target
	mode = "inspect"
	pending_target = ""
	_resolving = true
	battle.attack_unit(selected_id, target_id)
	_resolving = false
	_refresh()


func _wait_selected() -> void:
	if _wait_button.disabled:
		return
	mode = "inspect"
	pending_target = ""
	battle.wait_unit(selected_id)
	_refresh()


func _end_phase() -> void:
	if _resolving or battle.phase != "player":
		return
	mode = "inspect"
	pending_target = ""
	selected_id = ""
	battle.end_player_phase()


func _enemy_tick() -> void:
	if battle.phase != "enemy" or _resolving:
		return
	_resolving = true
	battle.enemy_step()
	_resolving = false
	_refresh()


func _cancel() -> void:
	mode = "inspect"
	pending_target = ""
	_refresh()


func _restart() -> void:
	_enemy_timer.stop()
	selected_id = ""
	mode = "inspect"
	pending_target = ""
	_resolving = false
	battle.restart()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			_cancel()
		KEY_M:
			_set_mode("move")
		KEY_A:
			_set_mode("attack")
		KEY_W:
			_wait_selected()
		KEY_E:
			_end_phase()
		KEY_R:
			_restart()
		_:
			return
	get_viewport().set_input_as_handled()

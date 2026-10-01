extends Control

signal cell_clicked(cell: Vector2i, button: int)

const INK := Color("07101c")
const CYAN := Color("62eadb")
const AMBER := Color("ffb96a")
const MUTED := Color("7a8ba4")

var battle: RefCounted
var selected_id: String = ""
var pending_target: String = ""
var interaction_mode: String = "inspect"
var reachable: Array[Vector2i] = []
var _hovered := Vector2i(-1, -1)
var _tile: int = 48
var _origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	mouse_exited.connect(func() -> void:
		_hovered = Vector2i(-1, -1)
		queue_redraw()
	)


func set_view(model: RefCounted, unit_id: String, mode: String, target_id: String) -> void:
	battle = model
	selected_id = unit_id
	interaction_mode = mode
	pending_target = target_id
	reachable.clear()
	if battle != null and interaction_mode == "move" and not selected_id.is_empty():
		reachable = battle.reachable_cells(selected_id)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if battle == null:
		return
	if event is InputEventMouseMotion:
		var cell: Vector2i = _cell_from_point(event.position)
		if cell != _hovered:
			_hovered = cell
			queue_redraw()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _in_bounds(cell) else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			cell_clicked.emit(_cell_from_point(event.position), event.button_index)
			accept_event()


func _get_tooltip(at_position: Vector2) -> String:
	if battle == null:
		return ""
	var cell: Vector2i = _cell_from_point(at_position)
	if not _in_bounds(cell):
		return ""
	var occupant: Dictionary = battle.unit_at(cell)
	if not occupant.is_empty():
		return "%s · %s · %s/%s HP" % [occupant.name, str(occupant.role).capitalize(), occupant.hp, occupant.max_hp]
	if cell in battle.level.get("walls", []):
		return "Wall · blocks movement and line of sight"
	return "Tile %s, %s" % [cell.x + 1, cell.y + 1]


func _in_bounds(cell: Vector2i) -> bool:
	return battle != null and cell.x >= 0 and cell.y >= 0 and cell.x < int(battle.level.get("width", 0)) and cell.y < int(battle.level.get("height", 0))


func _cell_from_point(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x - _origin.x) / _tile), floori((point.y - _origin.y) / _tile))


func _draw() -> void:
	if battle == null or battle.level.is_empty():
		return
	var width: int = int(battle.level.get("width", 0))
	var height: int = int(battle.level.get("height", 0))
	if width <= 0 or height <= 0:
		return
	_tile = maxi(20, floori(minf((size.x - 38.0) / width, (size.y - 32.0) / height)))
	_origin = Vector2(floorf((size.x - width * _tile) / 2.0), floorf((size.y - height * _tile) / 2.0))
	var font: Font = ThemeDB.fallback_font
	for x in range(width):
		draw_string(font, _origin + Vector2(x * _tile + _tile / 2.0 - 4, -8), str(x + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	for y in range(height):
		draw_string(font, _origin + Vector2(-18, y * _tile + _tile / 2.0 + 4), str(y + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var rect := Rect2(_origin + Vector2(cell) * _tile, Vector2(_tile, _tile))
			_draw_floor(rect, x, y)
			if cell in battle.level.get("walls", []):
				_draw_wall(rect, x, y)
			elif cell in reachable:
				draw_rect(rect.grow(-2), Color(CYAN, 0.14))
				draw_rect(rect.grow(-2), Color(CYAN, 0.48), false, 1.0)
				draw_rect(Rect2(rect.get_center() - Vector2(2, 2), Vector2(4, 4)), CYAN)
			if cell == _hovered:
				draw_rect(rect.grow(-1), Color("9fb0c9"), false, 1.0)
	for unit in battle.units:
		if int(unit.get("hp", 0)) <= 0:
			continue
		var cell: Vector2i = unit.pos
		var rect := Rect2(_origin + Vector2(cell) * _tile, Vector2(_tile, _tile))
		var accent: Color = CYAN if unit.side == "player" else AMBER
		if str(unit.id) == selected_id:
			draw_rect(rect.grow(-2), Color(accent, 0.17))
			_draw_brackets(rect.grow(-2), accent, 3.0)
		if interaction_mode == "attack" and battle.can_attack(selected_id, str(unit.id)):
			draw_rect(rect.grow(-3), Color(AMBER, 0.13))
			_draw_brackets(rect.grow(-4), AMBER, 2.0)
		if str(unit.id) == pending_target:
			draw_rect(rect.grow(-1), Color("ff7584"), false, 3.0)
		_draw_unit(rect, unit, accent)
	# A thin frame separates the playable grid from its coordinate labels.
	draw_rect(Rect2(_origin - Vector2.ONE, Vector2(width * _tile + 2, height * _tile + 2)), Color("3a4c63"), false, 1.0)


func _draw_floor(rect: Rect2, x: int, y: int) -> void:
	var floor_color := Color("142231") if (x + y) % 2 == 0 else Color("172735")
	draw_rect(rect, floor_color)
	draw_rect(rect.grow(-0.5), Color("253646"), false, 1.0)
	var p: Vector2 = rect.position
	var s: float = rect.size.x
	# Decorative marks only; no terrain rules are represented by these details.
	if (x * 3 + y * 7) % 5 == 0:
		draw_line(p + Vector2(7, s - 9), p + Vector2(s - 8, s - 9), Color("20313e"), 2)
	if (x + y * 3) % 7 == 0:
		draw_rect(Rect2(p + Vector2(5, 5), Vector2(3, 3)), Color("364355"))


func _draw_wall(rect: Rect2, x: int, y: int) -> void:
	var p: Vector2 = rect.position
	var s: float = rect.size.x
	draw_rect(rect.grow(-2), Color("0a111d"))
	draw_rect(Rect2(p + Vector2(3, 3), Vector2(s - 6, s - 9)), Color("3c465e"))
	draw_rect(Rect2(p + Vector2(3, 3), Vector2(s - 6, 4)), Color("5c667e"))
	draw_rect(Rect2(p + Vector2(3, 7), Vector2(4, s - 13)), Color("48536c"))
	draw_rect(Rect2(p + Vector2(10, 12), Vector2(s - 18, s - 25)), Color("252d43"))
	for i in range(3):
		draw_line(p + Vector2(13, 16 + i * 5), p + Vector2(s - 11, 16 + i * 5), Color("434d67"), 2)
	var neon := Color("ac75cb") if (x + y) % 2 == 0 else Color("52abb8")
	draw_rect(Rect2(p + Vector2(8, s - 10), Vector2(s - 16, 2)), neon)


func _draw_brackets(rect: Rect2, color: Color, thickness: float) -> void:
	var length: float = minf(10, rect.size.x / 4.0)
	for corner in [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]:
		var x_dir: int = 1 if corner.x == rect.position.x else -1
		var y_dir: int = 1 if corner.y == rect.position.y else -1
		draw_line(corner, corner + Vector2(length * x_dir, 0), color, thickness)
		draw_line(corner, corner + Vector2(0, length * y_dir), color, thickness)


func _draw_unit(rect: Rect2, unit: Dictionary, accent: Color) -> void:
	var pixel: int = maxi(1, floori((rect.size.x - 10) / 20.0))
	var origin := Vector2(floorf(rect.get_center().x - pixel * 9), floorf(rect.get_center().y - pixel * 11))
	var exhausted: bool = bool(unit.waited) or (bool(unit.moved) and bool(unit.acted))
	var brightness: float = 0.48 if exhausted else 1.0
	var skin := Color("e3ae93")
	var armor := Color("35475d") if unit.side == "player" else Color("645049")
	var highlight := Color("8498ab") if unit.side == "player" else Color("ba9474")
	var hair := Color("bac9d4") if unit.role == "melee" else Color("696981")
	# Small, deliberately blocky sprites stay legible at the board's native scale.
	_px(origin, pixel, Rect2(3, 19, 14, 3), Color("080f19"), brightness)
	_px(origin, pixel, Rect2(5, 13, 11, 6), INK, brightness)
	_px(origin, pixel, Rect2(6, 17, 4, 4), armor, brightness)
	_px(origin, pixel, Rect2(12, 17, 3, 4), armor, brightness)
	_px(origin, pixel, Rect2(5, 20, 5, 2), Color("607185"), brightness)
	_px(origin, pixel, Rect2(12, 20, 5, 2), Color("607185"), brightness)
	_px(origin, pixel, Rect2(4, 8, 12, 9), INK, brightness)
	_px(origin, pixel, Rect2(5, 9, 10, 7), armor, brightness)
	_px(origin, pixel, Rect2(6, 9, 3, 7), highlight, brightness)
	_px(origin, pixel, Rect2(10, 10, 3, 5), accent, brightness)
	_px(origin, pixel, Rect2(6, 1, 9, 9), INK, brightness)
	_px(origin, pixel, Rect2(7, 3, 7, 5), skin, brightness)
	_px(origin, pixel, Rect2(6, 1, 9, 3), hair, brightness)
	_px(origin, pixel, Rect2(5, 3, 4, 2), hair, brightness)
	_px(origin, pixel, Rect2(10, 5, 5, 2), INK, brightness)
	_px(origin, pixel, Rect2(11, 5, 4, 1), accent, brightness)
	_px(origin, pixel, Rect2(3, 10, 3, 5), armor, brightness)
	if unit.role == "melee":
		_px(origin, pixel, Rect2(15, 7, 2, 10), INK, brightness)
		_px(origin, pixel, Rect2(16, 2, 1, 10), Color("deedf5"), brightness)
		_px(origin, pixel, Rect2(17, 1, 1, 10), accent, brightness)
		_px(origin, pixel, Rect2(14, 11, 5, 2), highlight, brightness)
		_px(origin, pixel, Rect2(14, 13, 2, 2), skin, brightness)
	else:
		_px(origin, pixel, Rect2(13, 10, 7, 4), INK, brightness)
		_px(origin, pixel, Rect2(14, 10, 6, 2), highlight, brightness)
		_px(origin, pixel, Rect2(18, 10, 2, 1), accent, brightness)
		_px(origin, pixel, Rect2(14, 14, 2, 2), skin, brightness)
	var bar := Rect2(rect.position + Vector2(8, rect.size.y - 8), Vector2(rect.size.x - 16, 4))
	draw_rect(bar.grow(1), INK)
	draw_rect(bar, Color("364155"))
	var fraction: float = float(unit.hp) / maxf(1, float(unit.max_hp))
	draw_rect(Rect2(bar.position, Vector2(maxf(1, floorf(bar.size.x * fraction)), bar.size.y)), accent.darkened(1.0 - brightness))
	# Two pips represent the movement and action opportunities already in the model.
	if unit.side == "player":
		var move_color: Color = CYAN if not bool(unit.moved) and not bool(unit.waited) else Color("445064")
		var action_color: Color = CYAN if not bool(unit.acted) and not bool(unit.waited) else Color("445064")
		draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(4, 4)), move_color)
		draw_rect(Rect2(rect.position + Vector2(11, 5), Vector2(4, 4)), action_color)


func _px(origin: Vector2, pixel: int, rect: Rect2, color: Color, brightness: float) -> void:
	draw_rect(Rect2(origin + rect.position * pixel, rect.size * pixel), color.darkened(1.0 - brightness))

class_name GridRules
extends RefCounted
## Geometry only: movement, occupancy, and conservative wall sight lines.

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

static func in_bounds(cell: Vector2i, level: Dictionary) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < int(level.width) and cell.y < int(level.height)

static func movement_distances(origin: Vector2i, budget: int, level: Dictionary, occupied: Array[Vector2i]) -> Dictionary:
	var distances: Dictionary = {origin: 0}
	var frontier: Array[Vector2i] = [origin]
	var cursor := 0
	while cursor < frontier.size():
		var cell: Vector2i = frontier[cursor]
		cursor += 1
		if int(distances[cell]) >= budget:
			continue
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if not in_bounds(next, level) or next in level.walls or next in occupied or distances.has(next):
				continue
			distances[next] = int(distances[cell]) + 1
			frontier.append(next)
	return distances

static func line_clear(origin: Vector2i, target: Vector2i, walls: Array) -> bool:
	# Integer supercover traversal. At exact corners both touched side tiles count.
	var delta := target - origin
	var nx := absi(delta.x)
	var ny := absi(delta.y)
	var sx := signi(delta.x)
	var sy := signi(delta.y)
	var ix := 0
	var iy := 0
	var cell := origin
	while ix < nx or iy < ny:
		var horizontal := (1 + 2 * ix) * ny
		var vertical := (1 + 2 * iy) * nx
		if horizontal == vertical:
			if cell + Vector2i(sx, 0) in walls or cell + Vector2i(0, sy) in walls:
				return false
			cell += Vector2i(sx, sy)
			ix += 1
			iy += 1
		elif horizontal < vertical:
			cell.x += sx
			ix += 1
		else:
			cell.y += sy
			iy += 1
		if cell in walls:
			return false
	return true

extends RefCounted
class_name OilDepositGenerator

const CELL_SIZE := 46
const SPAWN_CHANCE := 0.18
const SEED_SALT := 9187
const MAX_LITERS := 1000.0
# Circle at radius 4 (49 tiles, 9×9 footprint) so fluid lakes read as large as an
# ore vein. All (dx, dy) with dx*dx + dy*dy <= 16.
const SHAPE: Array[Vector2i] = [
	Vector2i(0, -4),
	Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -3), Vector2i(2, -3),
	Vector2i(-3, -2), Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -2), Vector2i(3, -2),
	Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, -1),
	Vector2i(-4, 0), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(-3, 2), Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
	Vector2i(-2, 3), Vector2i(-1, 3), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
	Vector2i(0, 4),
]

var world_seed: int
var salt: int = SEED_SALT
## Per-instance spawn rate (defaults to the const) so e.g. lava can be made more
## common than oil without touching the shared shape/cell logic.
var spawn_chance: float = SPAWN_CHANCE


func _init(p_world_seed: int, p_salt: int = SEED_SALT) -> void:
	world_seed = p_world_seed
	salt = p_salt


func generate_for_chunk(chunk_position: Vector2i) -> Dictionary:
	var result: Dictionary = {}
	var chunk_min := chunk_position * Chunk.SIZE
	var chunk_max := chunk_min + Vector2i(Chunk.SIZE - 1, Chunk.SIZE - 1)
	var margin := 5
	var min_cell_x := floori(float(chunk_min.x - margin) / float(CELL_SIZE))
	var max_cell_x := floori(float(chunk_max.x + margin) / float(CELL_SIZE))
	var min_cell_y := floori(float(chunk_min.y - margin) / float(CELL_SIZE))
	var max_cell_y := floori(float(chunk_max.y + margin) / float(CELL_SIZE))
	for cell_x: int in range(min_cell_x, max_cell_x + 1):
		for cell_y: int in range(min_cell_y, max_cell_y + 1):
			var center := _center_for_cell(Vector2i(cell_x, cell_y))
			if center == Vector2i(999999999, 999999999):
				continue
			for offset: Vector2i in SHAPE:
				var tile := center + offset
				if (
					tile.x < chunk_min.x
					or tile.x > chunk_max.x
					or tile.y < chunk_min.y
					or tile.y > chunk_max.y
				):
					continue
				result[tile] = {
					"center": center,
					"is_center": offset == Vector2i.ZERO,
					"distance": offset.length_squared(),
				}
	return result


func _center_for_cell(cell: Vector2i) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(Vector3i(cell.x, cell.y, world_seed ^ salt)))
	if rng.randf() > spawn_chance:
		return Vector2i(999999999, 999999999)
	var margin := 5
	return Vector2i(
		cell.x * CELL_SIZE + rng.randi_range(margin, CELL_SIZE - margin - 1),
		cell.y * CELL_SIZE + rng.randi_range(margin, CELL_SIZE - margin - 1)
	)

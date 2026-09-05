# res://core/systems/generation/StructureGenerator.gd
## Генерация структур мира: руины и заброшенные лаборатории с сундуками лута.
##
## Структуры — обычные placed-блоки (стены, сундук, иногда верстак/печь),
## детерминированно (от сида) вгенерированные в WorldData.saved_placed_blocks
## один раз на мир (флаг structures_generated). Дальше они живут по всем
## правилам построек: ломаются, лутаются, сохраняются и уходят клиентам
## мультиплеера внутри world info — отдельная сетевая синхронизация не нужна.
##
## Коллизии с миром проверяются по НАСТОЯЩЕЙ генерации чанков: generate_chunk
## детерминирован, поэтому структура никогда не встанет на дерево/жилу/лужу —
## при стриминге чанка эти объекты появятся ровно там же, где мы их видели.
extends RefCounted
class_name StructureGenerator

## Сколько структур пытаемся разместить (успешных обычно ~60-70% от попыток).
const TARGET_COUNT := 24
const MAX_ATTEMPTS := 120
## Минимальная дистанция между структурами и до спавна (в тайлах).
const MIN_SPACING := 96.0
const MIN_SPAWN_DIST := 120.0
## Биомы, где структуры не ставим: вода/пляж и болото (мелкие лужи не видны
## на этапе биом-проверки центра, а в болоте их слишком много).
const FORBIDDEN_BIOMES := ["OceanBiome", "BeachBiome", "SwampBiome"]

## Шаблоны. '#' — каменная стена, 'C' — сундук с лутом, 'W' — верстак,
## 'F' — печь, '.' — пусто. Проёмы в стенах — входы.
const TEMPLATES := {
	"ruin_small": [
		"#####",
		"#...#",
		"#.C.#",
		"#...#",
		"##.##",
	],
	"ruin_broken": [
		"##..#",
		"#....",
		"..C.#",
		"#....",
		"#.###",
	],
	"lab": [
		"#######",
		"#.....#",
		"#.C.F.#",
		"#.....#",
		"#..W..#",
		"###.###",
	],
}
const TEMPLATE_BLOCKS := {"#": "stone_block", "W": "workbench", "F": "furnace"}

## Таблицы лута по тирам зоны (кольца мира). Формат: [id, min, max].
## Неизвестные предметы отфильтровываются по ItemDatabase — таблицу можно
## расширять без страха опечаток.
const LOOT_TABLES := {
	1: [
		["coal", 6, 14], ["iron_ingot", 3, 7], ["copper_ingot", 3, 7],
		["bronze_ingot", 2, 4], ["iron_plate", 2, 5], ["gear", 1, 3],
		["copper_wire", 3, 8],
	],
	2: [
		["steel_ingot", 3, 6], ["coke", 5, 10], ["gold_ingot", 2, 4],
		["silver_ingot", 2, 4], ["circuit_t1", 1, 2], ["iron_plate", 3, 8],
		["insulated_copper_wire", 3, 6], ["gear", 2, 5],
	],
	3: [
		["titanium_ingot", 2, 4], ["mythril_ingot", 1, 3], ["steel_ingot", 4, 8],
		["circuit_t2", 1, 2], ["platinum_plate", 1, 2], ["gold_wire", 2, 4],
		["uranium_processed", 1, 2],
	],
}
## Сундук по тиру зоны: дальше от спавна — вместительнее и богаче.
const CHEST_BLOCK_BY_TIER := {1: "chest_t1", 2: "chest_t2", 3: "chest_t3"}
const LOOT_STACKS_MIN := 3
const LOOT_STACKS_MAX := 5

var _chunk_generator: ChunkGenerator
var _biome_generator: BiomeGenerator
var _rng := RandomNumberGenerator.new()
var _chunk_cache: Dictionary = {}  # Vector2i -> Chunk


func _init(chunk_generator: ChunkGenerator, biome_generator: BiomeGenerator, world_seed: int) -> void:
	_chunk_generator = chunk_generator
	_biome_generator = biome_generator
	_rng.seed = world_seed ^ 0x5772C7  # соль, чтобы не совпадать с другими RNG сида


## Вгенерирует структуры в world.saved_placed_blocks (если ещё не делали).
func generate_into(world: WorldData) -> void:
	if world == null or world.structures_generated:
		return
	var placed_origins: Array[Vector2] = []
	var placed_count := 0
	for _attempt in range(MAX_ATTEMPTS):
		if placed_count >= TARGET_COUNT:
			break
		if _try_place_structure(world, placed_origins):
			placed_count += 1
	world.structures_generated = true
	_chunk_cache.clear()


func _try_place_structure(world: WorldData, placed_origins: Array[Vector2]) -> bool:
	# Случайная точка от внешней части лесного хаба до края хард-секторов.
	var angle := _rng.randf() * TAU
	var radius := _rng.randf_range(
		MIN_SPAWN_DIST + 40.0,
		BiomeGenerator.hard_radius - 60.0
	)
	var center := Vector2i(
		int(cos(angle) * radius), int(sin(angle) * radius)
	)
	var center_v := Vector2(center)
	if center_v.length() < MIN_SPAWN_DIST:
		return false
	for origin: Vector2 in placed_origins:
		if origin.distance_to(center_v) < MIN_SPACING:
			return false

	var zone_tier := _zone_tier_for_radius(radius)
	if zone_tier <= 0:
		return false

	# Лаборатории — только в дальних зонах; в лесном кольце только руины.
	var names: Array = ["ruin_small", "ruin_broken"]
	if zone_tier >= 2:
		names.append("lab")
	var template: Array = TEMPLATES[names[_rng.randi() % names.size()]]
	var h: int = template.size()
	var w: int = (template[0] as String).length()
	@warning_ignore("integer_division")
	var anchor := center - Vector2i(w / 2, h / 2)

	if not _area_clear(world, anchor, w, h):
		return false

	# Ставим блоки шаблона.
	for row in range(h):
		var line: String = template[row]
		for col in range(w):
			var symbol := line[col]
			if symbol == ".":
				continue
			var tile := anchor + Vector2i(col, row)
			var key := "%d,%d" % [tile.x, tile.y]
			if symbol == "C":
				world.saved_placed_blocks[key] = {
					"block_id": str(CHEST_BLOCK_BY_TIER.get(zone_tier, "chest_t1")),
					"facing": 2,
					"extra_data": {"chest_data": _make_loot_chest_data(zone_tier)},
				}
			else:
				var block_id: String = str(TEMPLATE_BLOCKS.get(symbol, "stone_block"))
				world.saved_placed_blocks[key] = {"block_id": block_id, "facing": 2}

	placed_origins.append(center_v)
	return true


## Тир зоны по расстоянию от спавна: 1 — лес, 2 — обычные сектора,
## 3 — хард-сектора.
func _zone_tier_for_radius(radius: float) -> int:
	if radius < BiomeGenerator.forest_radius:
		return 1
	if radius < BiomeGenerator.sector_radius:
		return 2
	if radius < BiomeGenerator.hard_radius:
		return 3
	return 0


## Площадка свободна: разрешённый биом, нет объектов генерации (деревья, жилы,
## лужи), не вода, и рядом нет уже размещённых игроком/структурами блоков.
func _area_clear(world: WorldData, anchor: Vector2i, w: int, h: int) -> bool:
	for row in range(h):
		for col in range(w):
			var tile := anchor + Vector2i(col, row)

			var biome: BiomeData = _biome_generator.get_biome_at(tile.x, tile.y)
			if biome == null or FORBIDDEN_BIOMES.has(biome.biome_name):
				return false

			var chunk := _get_chunk(_tile_to_chunk(tile))
			var local := tile - chunk.position * Chunk.SIZE
			if chunk.object_data.has(local):
				return false
			var terrain: Variant = chunk.terrain_data.get(local)
			if terrain is Vector3i and (terrain as Vector3i).z == GameConstants.TERRAIN_WATER:
				return false

	# Отступ от чужих построек: якоря блоков в пределах рамки + 3 тайла.
	for key: Variant in world.saved_placed_blocks:
		var pos := _parse_key(str(key))
		if pos.x >= anchor.x - 3 and pos.x <= anchor.x + w + 2 \
				and pos.y >= anchor.y - 3 and pos.y <= anchor.y + h + 2:
			return false
	return true


## Сейв-данные сундука с лутом выбранного тира. Слоты заполняются напрямую
## (мимо set_slot_data_at), чтобы не дёргать квест-событие items_stored.
func _make_loot_chest_data(zone_tier: int) -> Dictionary:
	var chest := ChestData.create_for_tier(mini(zone_tier, ChestData.Tier.TIER_3))
	var table: Array = LOOT_TABLES.get(zone_tier, LOOT_TABLES[1])
	var stacks := _rng.randi_range(LOOT_STACKS_MIN, LOOT_STACKS_MAX)
	var slot := 0
	for _i in range(stacks):
		var entry: Array = table[_rng.randi() % table.size()]
		var item_id := str(entry[0])
		if not ItemDatabase.registry.has(item_id):
			continue  # id из таблицы ещё не существует — просто пропускаем
		var count := _rng.randi_range(int(entry[1]), int(entry[2]))
		var stack: Dictionary = ItemDatabase.create_existing_stack(item_id, count)
		if stack.is_empty() or slot >= chest.slot_count:
			continue
		chest.inventory_slots[slot] = stack
		slot += 1
	return chest.to_save_data()


func _get_chunk(chunk_pos: Vector2i) -> Chunk:
	var cached: Variant = _chunk_cache.get(chunk_pos)
	if cached is Chunk:
		return cached
	var chunk := _chunk_generator.generate_chunk(chunk_pos)
	_chunk_cache[chunk_pos] = chunk
	return chunk


func _tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(tile.x) / Chunk.SIZE),
		floori(float(tile.y) / Chunk.SIZE)
	)


func _parse_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i(999999, 999999)
	return Vector2i(int(parts[0]), int(parts[1]))

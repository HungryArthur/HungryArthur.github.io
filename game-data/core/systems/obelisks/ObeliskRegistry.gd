# res://core/systems/obelisks/ObeliskRegistry.gd
extends RefCounted
class_name ObeliskRegistry

## Deterministic placement of fast-travel obelisks across the finite radial world.
## Counts mirror the brief: Forest hub = 1 (centre) + 4 (one per
## cardinal side), each NORMAL directional biome = 2, each HARD biome = 3.
## Positions derive from BiomeGenerator's ring radii so they always land well
## inside the intended biome band (and the wedge centre, away from sector seams).

# The four cardinal directions, each owning a normal + hard biome. Angles are in
# tile space (y points DOWN, so North = -y). See BiomeGenerator._sector.
static var DIRECTIONS: Array = [
	{
		"key": "north", "angle": -PI * 0.5, "label": "Север",
		"normal": "SnowBiome", "hard": "IcyAbyssBiome",
		"normal_name": "Снега", "hard_name": "Ледяная Бездна",
		"normal_color": Color(0.72, 0.88, 0.98), "hard_color": Color(0.45, 0.80, 0.96),
	},
	{
		"key": "south", "angle": PI * 0.5, "label": "Юг",
		"normal": "SwampBiome", "hard": "RottingBogBiome",
		"normal_name": "Болото", "hard_name": "Гниющие Топи",
		"normal_color": Color(0.50, 0.62, 0.28), "hard_color": Color(0.58, 0.36, 0.66),
	},
	{
		"key": "west", "angle": PI, "label": "Запад",
		"normal": "DesertBiome", "hard": "SunnyCanyonBiome",
		"normal_name": "Пустыня", "hard_name": "Солнечный Каньон",
		"normal_color": Color(0.93, 0.82, 0.46), "hard_color": Color(0.96, 0.46, 0.22),
	},
	{
		"key": "east", "angle": 0.0, "label": "Восток",
		"normal": "JungleBiome", "hard": "PrimevalThicketBiome",
		"normal_name": "Джунгли", "hard_name": "Первобытные Дебри",
		"normal_color": Color(0.42, 0.85, 0.32), "hard_color": Color(0.28, 0.62, 0.24),
	},
]

# Angular spread (radians) of the obelisks inside a directional wedge. Kept well
# under 45° so they never cross into a neighbouring sector once noise wobble is added.
const NORMAL_SPREAD := 18.0
const HARD_SPREAD := 22.0

static var _cache: Array = []


## All obelisks as dicts: { id, biome, name, tile: Vector2i, color: Color }.
static func get_all() -> Array:
	if not _cache.is_empty():
		return _cache

	var list: Array = []

	# Forest hub — a single central obelisk (the stable legacy id keeps saves valid).
	list.append(_entry(
		"plains_center", "ForestBiome", "Лесной Обелиск · Центр",
		Vector2i.ZERO, Color(0.24, 0.66, 0.34)
	))

	# Additional forest obelisks on each cardinal side of the hub.
	var forest_r: float = BiomeGenerator.forest_radius * 0.62
	var forest_color := Color(0.24, 0.66, 0.34)
	for d: Dictionary in DIRECTIONS:
		var tile := _polar(float(d["angle"]), forest_r)
		list.append(_entry(
			"forest_%s" % d["key"], "ForestBiome",
			"Лесной Обелиск · %s" % d["label"], tile, forest_color
		))

	# Normal directional sectors — 2 obelisks each, spread inside the wedge.
	var normal_r: float = (BiomeGenerator.forest_radius + BiomeGenerator.sector_radius) * 0.5
	var normal_spread := deg_to_rad(NORMAL_SPREAD)
	for d: Dictionary in DIRECTIONS:
		var offsets := [-normal_spread, normal_spread]
		for i: int in offsets.size():
			var tile := _polar(float(d["angle"]) + offsets[i], normal_r)
			list.append(_entry(
				"normal_%s_%d" % [d["key"], i], str(d["normal"]),
				"%s · %s" % [d["normal_name"], _roman(i + 1)], tile, d["normal_color"]
			))

	# Hard directional sectors — 3 obelisks each (centre + two flanks).
	var hard_r: float = (BiomeGenerator.sector_radius + BiomeGenerator.hard_radius) * 0.5
	var hard_spread := deg_to_rad(HARD_SPREAD)
	for d: Dictionary in DIRECTIONS:
		var offsets := [-hard_spread, 0.0, hard_spread]
		for i: int in offsets.size():
			var tile := _polar(float(d["angle"]) + offsets[i], hard_r)
			list.append(_entry(
				"hard_%s_%d" % [d["key"], i], str(d["hard"]),
				"%s · %s" % [d["hard_name"], _roman(i + 1)], tile, d["hard_color"]
			))

	_cache = list
	return list


## World-space (pixel) centre of an obelisk's tile.
static func world_pos(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x + 0.5) * GameConstants.TILE_SIZE,
		(tile.y + 0.5) * GameConstants.TILE_SIZE
	)


static func _entry(
	id: String, biome: String, obelisk_name: String, tile: Vector2i, color: Color
) -> Dictionary:
	return {"id": id, "biome": biome, "name": obelisk_name, "tile": tile, "color": color}


## Localised obelisk name. Names are baked from parts (biome/direction + roman
## numeral) joined by " · "; translate each part so it follows the current locale.
static func display_name(raw: String) -> String:
	var parts := raw.split(" · ")
	for i in parts.size():
		parts[i] = String(TranslationServer.translate(parts[i]))
	return " · ".join(parts)


static func _polar(angle: float, radius: float) -> Vector2i:
	return Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius))


static func _roman(n: int) -> String:
	return ["I", "II", "III", "IV"][clampi(n - 1, 0, 3)]

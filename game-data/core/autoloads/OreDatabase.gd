extends Node

const DEFINITIONS_PATH := "res://core/resources/ores/definitions/"
# Veins are placed on a grid of DEPOSIT_CELL_SIZE tiles; each cell rolls
# BASE_DEPOSIT_SPAWN_CHANCE for a deposit. Raising the cell size and lowering the
# chance thins veins out so the surface is less cluttered with ore zones.
const DEPOSIT_CELL_SIZE := 40
const BASE_DEPOSIT_SPAWN_CHANCE := 0.28
const DEPOSIT_SEED_SALT := 6151

var definitions: Array[DepositData] = []
var definitions_by_id: Dictionary = {}
var definitions_by_atlas: Dictionary = {}
var total_spawn_weight: int = 0


func _ready() -> void:
	_load_definitions()


func get_by_id(deposit_id: String) -> DepositData:
	return definitions_by_id.get(deposit_id) as DepositData


func get_by_atlas(atlas_x: int) -> DepositData:
	return definitions_by_atlas.get(atlas_x) as DepositData


func get_max_atlas_x() -> int:
	var maximum: int = 0
	for definition: DepositData in definitions:
		maximum = maxi(maximum, definition.atlas_x)
	return maximum


## Picks a deposit by weight. When biome_name is given, only deposits allowed in
## that biome (spawn_biomes empty = any land biome) take part in the draw.
func pick_weighted_definition(rng: RandomNumberGenerator, biome_name: String = "") -> DepositData:
	if definitions.is_empty():
		return null

	var pool: Array[DepositData] = []
	var pool_weight: int = 0
	for definition: DepositData in definitions:
		if biome_name != "" and not _allowed_in_biome(definition, biome_name):
			continue
		pool.append(definition)
		pool_weight += maxi(definition.spawn_weight, 0)

	if pool.is_empty() or pool_weight <= 0:
		return null

	var roll: int = rng.randi_range(1, pool_weight)
	var accumulated_weight: int = 0
	for definition: DepositData in pool:
		accumulated_weight += maxi(definition.spawn_weight, 0)
		if roll <= accumulated_weight:
			return definition
	return pool.back()


func _allowed_in_biome(definition: DepositData, biome_name: String) -> bool:
	return definition.spawn_biomes.is_empty() or biome_name in definition.spawn_biomes


func _load_definitions() -> void:
	definitions.clear()
	definitions_by_id.clear()
	definitions_by_atlas.clear()
	total_spawn_weight = 0

	for file_name in DirScan.resource_files(DEFINITIONS_PATH):
		var resource_value: Resource = load(DEFINITIONS_PATH + file_name)
		if resource_value is DepositData:
			var definition: DepositData = resource_value
			if definition.deposit_id.is_empty() or definition.resource_item_id.is_empty():
				continue
			definitions.append(definition)
			definitions_by_id[definition.deposit_id] = definition
			definitions_by_atlas[definition.atlas_x] = definition
			total_spawn_weight += maxi(definition.spawn_weight, 0)

	definitions.sort_custom(func(a: DepositData, b: DepositData) -> bool:
		return a.atlas_x < b.atlas_x
	)

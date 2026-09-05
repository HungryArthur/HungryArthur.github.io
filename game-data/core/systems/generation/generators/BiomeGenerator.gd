# res://core/systems/generation/generators/BiomeGenerator.gd
extends RefCounted
class_name BiomeGenerator

var noise_manager: NoiseManager
var biomes: Dictionary = {}


func _init(nm: NoiseManager) -> void:
	noise_manager = nm
	_load_biomes_automatically("res://core/worlds/overworld/generation/biomes")


func _load_biomes_automatically(folder_path: String) -> void:
	# DirScan обязателен: в экспорте биомы лежат как *.tres.remap, и старая
	# проверка ends_with(".tres") их пропускала — весь мир заливало водой.
	for file_name in DirScan.resource_files(folder_path):
		var biome_resource = load(folder_path + "/" + file_name)
		if biome_resource is BiomeData:
			biomes[biome_resource.biome_name] = biome_resource
	if biomes.is_empty():
		push_error("[BiomeGenerator] No biomes loaded from: " + folder_path)


# Width (tiles) of the sandy beach ring at the outer world boundary.
const BOUNDARY_BEACH := 22.0

# --- FINITE radial world, centred on spawn (origin 0,0). Concentric rings out
# from the centre, then a hard infinite-ocean boundary. All in tiles; static so
# the live preview tool (tools/BiomePreview) can tune them — bake chosen values
# back here. Ratios mirror the 500/1500/4000/8000 design brief, scaled down to a
# traversable size. ---
static var forest_radius := 480.0   # Forest hub around spawn (outer edge)
static var sector_radius := 1280.0  # outer edge of the NORMAL directional sectors
static var hard_radius := 2560.0    # outer edge of the HARD sectors; beyond = ocean
static var radial_warp := 45.0      # noise wobble on the ring radii (jagged rings)
static var sector_warp := 70.0      # noise wobble on the N/S/W/E sector borders

# Sector ids.
const SECTOR_NORTH := 0
const SECTOR_SOUTH := 1
const SECTOR_WEST := 2
const SECTOR_EAST := 3

# Each hard-sector biome inherits the ore/forage spawn rules of its normal
# sibling (its art/tile is distinct, but it's the same "direction"). Used by
# OreDepositGenerator so we don't have to list every hard biome in every def.
const HARD_TO_BASE := {
	"SunnyCanyonBiome": "DesertBiome",     # запад
	"IcyAbyssBiome": "SnowBiome",          # север
	"RottingBogBiome": "SwampBiome",       # юг
	"PrimevalThicketBiome": "JungleBiome", # восток
}


## The "base" (normal-tier) biome name for ore/forage inheritance. Hard biomes
## map to their normal sibling; everything else maps to itself.
static func base_biome_name(name: String) -> String:
	return HARD_TO_BASE.get(name, name)


# Distance from spawn, wobbled by low-frequency noise so ring edges look jagged.
func _radius(x: int, y: int) -> float:
	return sqrt(float(x) * x + float(y) * y) + noise_manager.get_temperature(x, y) * radial_warp


# Which of the 4 cardinal sectors a position belongs to (split along the
# diagonals). Position is nudged by noise first so the boundaries are not
# perfectly straight diagonal lines.
func _sector(x: int, y: int) -> int:
	var nx: float = float(x) + noise_manager.get_moisture(x, y) * sector_warp
	var ny: float = float(y) + noise_manager.get_temperature(x, y) * sector_warp
	if absf(ny) > absf(nx):
		return SECTOR_NORTH if ny < 0.0 else SECTOR_SOUTH  # −y is up = north
	return SECTOR_WEST if nx < 0.0 else SECTOR_EAST


## Progression tier at a position: 0 = safe forest hub, 1 = normal
## sector, 2 = hard sector, -1 = world-boundary ocean. (Hardness/effects hook
## into this later; layout-only for now.)
func get_zone_tier(x: int, y: int) -> int:
	var r: float = _radius(x, y)
	if r > hard_radius:
		return -1
	if r < forest_radius:
		return 0
	if r < sector_radius:
		return 1
	return 2


## `altitude`/`ocean_level` are accepted for call-site compatibility but the
## finite radial layout no longer uses altitude — land biomes have NO lakes.
## All open water is the world-boundary ocean (here) or small swamp pools
## (handled in ChunkGenerator).
func get_biome_at(
	x: int,
	y: int,
	_altitude: float = NAN,
	_ocean_level: float = -0.15
) -> BiomeData:
	var r: float = _radius(x, y)

	# World boundary: an infinite ocean rings the whole map past the hard zones,
	# with a sandy beach just inside it (except on the frozen north coast).
	if r > hard_radius:
		return _get_biome_safely("OceanBiome")
	if r > hard_radius - BOUNDARY_BEACH and _sector(x, y) != SECTOR_NORTH:
		return _get_biome_safely("BeachBiome")

	# The whole central hub is one continuous forest.
	if r < forest_radius:
		return _get_biome_safely("ForestBiome")

	# Directional sectors. Each direction has a NORMAL biome (r < sector_radius)
	# and a distinct HARD biome behind it (r >= sector_radius), with its own art:
	#   North → Snow / Icy Abyss     West → Desert / Sunny Canyon
	#   South → Swamp / Rotting Bog   East → Jungle / Primeval Thicket
	var hard: bool = r >= sector_radius
	match _sector(x, y):
		SECTOR_NORTH:
			return _get_biome_safely("IcyAbyssBiome" if hard else "SnowBiome")
		SECTOR_SOUTH:
			return _get_biome_safely("RottingBogBiome" if hard else "SwampBiome")
		SECTOR_WEST:
			return _get_biome_safely("SunnyCanyonBiome" if hard else "DesertBiome")
		_:
			return _get_biome_safely("PrimevalThicketBiome" if hard else "JungleBiome")


func _get_biome_safely(biome_name: String) -> BiomeData:
	if biomes.has(biome_name):
		return biomes[biome_name]
	if not biomes.is_empty():
		return biomes.values()[0]
	return null

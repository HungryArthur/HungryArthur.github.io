# res://core/systems/bosses/BossRegistry.gd
extends RefCounted
class_name BossRegistry

## Static data for the biome bosses (roadmap step 7). Killing a biome's boss drops
## the page that unlocks the NEXT biome (see
## docs/normal_world_design.md §3). Positions derive from BiomeGenerator's ring radii,
## like [[project_npcs]] (NpcRegistry) — the boss stands well inside its biome band on
## a clear axis (away from the Forest NPC at -60° and the obelisks).
##
## Only the Ent (Forest → Sand Amulet → Desert) is fully authored now; the rest are
## stubs to be filled as their art/design lands.

# angle (rad, y points down) + radius (px) → world tile, per boss.
const _ENTRIES := {
	"ent": {
		"biome": "ForestBiome",
		"name": "Энт",
		"script": "res://entities/bosses/EntBoss.gd",
		"color": Color(0.30, 0.55, 0.28),   # foliage colour (trunk/bark tones live in EntBoss)
		"angle_deg": 135.0,
		"radius_frac": 0.55,                # fraction across the Forest ring band
		"max_hp": 1200.0,
		"contact_damage": 10.0,
		"speed": 50.0,
		"page_drop": "page_sand_amulet",
		"recipe_reward": "sand_amulet",
		"research_sample": "ent_heart",
		"summoner_item": "ent_totem",
		# Guaranteed on every kill — the Ent is a walking tree, so it drops its wood.
		"loot": {"wood": 24, "wood_plank": 8, "plant_fiber": 12, "coal": 6, "machine_module_efficiency": 1},
		# Rolled per kill. The totem lets a lucky player refight without crafting one.
		"loot_chance": {
			"apple": {"chance": 0.6, "count": 4},
			"ent_totem": {"chance": 0.35, "count": 1},
		},
	},
	"dune_colossus": {
		"biome": "DesertBiome", "name": "Песчаный колосс", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.83, 0.56, 0.20),
		"angle_deg": 180.0, "radius_frac": 0.62, "max_hp": 2200.0, "contact_damage": 13.0, "speed": 62.0,
		"page_drop": "page_thermal_gloves", "recipe_reward": "thermal_gloves", "research_sample": "dune_core", "loot": {"sand": 36, "cactus": 10, "coal": 10},
		"loot_chance": {"machine_module_speed": {"chance": 0.25, "count": 1}},
		"special": {"type": "target_aoe", "range": 440.0, "radius": 112.0, "damage_mult": 1.0, "telegraph": 0.75, "duration": 0.24, "recover": 0.62, "cooldown": 6.0, "burst": 0.35, "fx": "sand_burst", "color": Color(0.95, 0.68, 0.24)},
		"phase_two_special": {"type": "dash", "range": 380.0, "hit_radius": 52.0, "damage_mult": 1.25, "telegraph": 0.55, "duration": 0.50, "recover": 0.75, "cooldown": 8.0, "speed": 500.0, "fx": "sand_charge", "fx_radius": 96.0},
	},
	"frost_warden": {
		"biome": "SnowBiome", "name": "Ледяной страж", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.50, 0.80, 1.0),
		"angle_deg": -90.0, "radius_frac": 0.62, "max_hp": 2500.0, "contact_damage": 14.0, "speed": 64.0,
		"page_drop": "page_miasma_boots", "recipe_reward": "miasma_boots", "research_sample": "frost_core", "loot": {"ice_shard": 32, "iron_ore": 10, "coal": 8},
		"loot_chance": {"machine_module_capacity": {"chance": 0.30, "count": 1}},
		"special": {"type": "self_aoe", "range": 150.0, "radius": 145.0, "damage_mult": 1.0, "telegraph": 0.75, "duration": 0.26, "recover": 0.68, "cooldown": 6.5, "burst": 0.38, "fx": "frost_nova", "color": Color(0.52, 0.86, 1.0)},
		"phase_two_special": {"type": "target_aoe", "range": 440.0, "radius": 84.0, "damage_mult": 1.25, "telegraph": 0.9, "duration": 0.24, "recover": 0.6, "cooldown": 7.0, "burst": 0.4, "fx": "ice_comet", "color": Color(0.72, 0.94, 1.0)},
	},
	"mire_hydra": {
		"biome": "SwampBiome", "name": "Болотная гидра", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.42, 0.72, 0.22),
		"angle_deg": 90.0, "radius_frac": 0.62, "max_hp": 2700.0, "contact_damage": 15.0, "speed": 60.0,
		"page_drop": "page_savage_belt", "recipe_reward": "savage_belt", "research_sample": "hydra_gland", "loot": {"reed": 28, "mushroom": 12, "plant_fiber": 20},
		"loot_chance": {"machine_module_productivity": {"chance": 0.20, "count": 1}},
		"special": {"type": "target_aoe", "range": 460.0, "radius": 88.0, "damage_mult": 1.1, "telegraph": 0.85, "duration": 0.24, "recover": 0.6, "cooldown": 5.5, "burst": 0.45, "fx": "acid_spit", "color": Color(0.48, 0.92, 0.22)},
		"phase_two_special": {"type": "summon", "range": 520.0, "radius": 76.0, "telegraph": 0.72, "duration": 0.15, "recover": 0.8, "cooldown": 15.0, "burst": 0.35, "fx": "hydra_call", "color": Color(0.35, 0.78, 0.20), "mob": "mire_leech", "count": 3},
	},
	"thorn_matriarch": {
		"biome": "JungleBiome", "name": "Шипастая матриархиня", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.18, 0.62, 0.22),
		"angle_deg": 0.0, "radius_frac": 0.62, "max_hp": 2900.0, "contact_damage": 16.0, "speed": 68.0,
		"page_drop": "page_sun_crown", "recipe_reward": "sun_crown", "research_sample": "thorn_heart", "loot": {"tree_resin": 20, "plant_fiber": 28, "wood": 24},
		"special": {"type": "target_aoe", "range": 430.0, "radius": 94.0, "damage_mult": 1.1, "telegraph": 0.8, "duration": 0.22, "recover": 0.58, "cooldown": 5.5, "burst": 0.38, "fx": "thorn_field", "color": Color(0.74, 0.26, 0.34)},
		"phase_two_special": {"type": "dash", "range": 410.0, "hit_radius": 56.0, "damage_mult": 1.3, "telegraph": 0.48, "duration": 0.48, "recover": 0.68, "cooldown": 7.5, "speed": 540.0, "fx": "vine_lunge", "fx_radius": 92.0},
	},
	"solar_tyrant": {
		"biome": "SunnyCanyonBiome", "name": "Солнечный тиран", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(1.0, 0.34, 0.10),
		"angle_deg": 170.0, "radius_frac": 0.58, "max_hp": 4100.0, "contact_damage": 18.0, "speed": 72.0,
		"page_drop": "page_cryo_mantle", "recipe_reward": "cryo_mantle", "research_sample": "solar_core",
		"loot": {"coke": 18, "gold_ore": 12, "purified_resonite": 14},
		"special": {"type": "target_aoe", "range": 500.0, "radius": 110.0, "damage_mult": 1.2, "telegraph": 0.9, "duration": 0.25, "recover": 0.65, "cooldown": 6.0, "burst": 0.45, "fx": "solar_strike", "color": Color(1.0, 0.66, 0.16)},
		"phase_two_special": {"type": "self_aoe", "range": 190.0, "radius": 160.0, "damage_mult": 1.35, "telegraph": 0.82, "duration": 0.28, "recover": 0.72, "cooldown": 8.0, "burst": 0.42, "fx": "sunburst", "color": Color(1.0, 0.88, 0.30)},
	},
	"abyss_leviathan": {
		"biome": "IcyAbyssBiome", "name": "Левиафан бездны", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.30, 0.62, 0.94),
		"angle_deg": -80.0, "radius_frac": 0.58, "max_hp": 4400.0, "contact_damage": 19.0, "speed": 70.0,
		"page_drop": "page_void_respirator", "recipe_reward": "void_respirator", "research_sample": "leviathan_scale",
		"loot": {"ice_shard": 40, "silver_ore": 12, "steel_ingot": 8},
		"special": {"type": "self_aoe", "range": 170.0, "radius": 165.0, "damage_mult": 1.15, "telegraph": 0.8, "duration": 0.26, "recover": 0.68, "cooldown": 6.2, "burst": 0.4, "fx": "icebreaker", "color": Color(0.52, 0.84, 1.0)},
		"phase_two_special": {"type": "dash", "range": 430.0, "hit_radius": 58.0, "damage_mult": 1.35, "telegraph": 0.5, "duration": 0.55, "recover": 0.72, "cooldown": 7.0, "speed": 560.0, "fx": "avalanche_dash", "fx_radius": 100.0},
	},
	"rot_king": {
		"biome": "RottingBogBiome", "name": "Король гнили", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.52, 0.82, 0.16),
		"angle_deg": 100.0, "radius_frac": 0.58, "max_hp": 4700.0, "contact_damage": 20.0, "speed": 66.0,
		"page_drop": "page_primeval_potion", "recipe_reward": "primeval_potion", "research_sample": "rot_crown",
		"loot": {"mushroom": 24, "gunpowder": 14, "nickel_ore": 12},
		"special": {"type": "target_aoe", "range": 470.0, "radius": 102.0, "damage_mult": 1.2, "telegraph": 0.9, "duration": 0.25, "recover": 0.7, "cooldown": 5.8, "burst": 0.45, "fx": "plague_stomp", "color": Color(0.52, 0.94, 0.22)},
		"phase_two_special": {"type": "summon", "range": 520.0, "radius": 82.0, "telegraph": 0.75, "duration": 0.15, "recover": 0.82, "cooldown": 14.0, "burst": 0.35, "fx": "rot_call", "color": Color(0.62, 0.86, 0.20), "mob": "toxic_slime", "count": 2},
	},
	"primal_guardian": {
		"biome": "PrimevalThicketBiome", "name": "Первобытный страж", "script": "res://entities/bosses/BiomeBoss.gd", "color": Color(0.18, 0.48, 0.16),
		"angle_deg": 10.0, "radius_frac": 0.58, "max_hp": 5000.0, "contact_damage": 22.0, "speed": 74.0,
		"research_sample": "primal_core",
		"loot": {"tree_resin": 24, "titanium_ore": 12, "mythril_ore": 8},
		"special": {"type": "self_aoe", "range": 185.0, "radius": 175.0, "damage_mult": 1.25, "telegraph": 0.86, "duration": 0.28, "recover": 0.72, "cooldown": 6.0, "burst": 0.44, "fx": "primal_rift", "color": Color(0.94, 0.58, 0.20)},
		"phase_two_special": {"type": "dash", "range": 450.0, "hit_radius": 60.0, "damage_mult": 1.4, "telegraph": 0.46, "duration": 0.55, "recover": 0.7, "cooldown": 6.8, "speed": 590.0, "fx": "primal_pounce", "fx_radius": 106.0},
	},
}


static func has_boss(id: String) -> bool:
	return _ENTRIES.has(id)


static func get_ids() -> Array:
	return _ENTRIES.keys()


## Full data dict for a boss id (merges the static entry with its computed arena tile).
## Empty dict if unknown.
static func get_data(id: String) -> Dictionary:
	if not _ENTRIES.has(id):
		return {}
	var entry: Dictionary = (_ENTRIES[id] as Dictionary).duplicate(true)
	entry["id"] = id
	entry["tile"] = _arena_tile(entry)
	return entry


static func get_all() -> Array:
	var list: Array = []
	for id: String in _ENTRIES.keys():
		list.append(get_data(id))
	return list


## Instances the node for a boss entry: its own class if the entry names a `script`
## (EntBoss), else the generic Boss. The caller still owns setup()/positioning.
static func create(data: Dictionary) -> Boss:
	var path: String = str(data.get("script", ""))
	if path != "" and ResourceLoader.exists(path):
		var script := load(path) as GDScript
		if script != null:
			var boss := script.new() as Boss
			if boss != null:
				return boss
			push_warning("[BossRegistry] script is not a Boss: " + path)
	return Boss.new()


## Arena tile for a boss: polar offset from world centre (0,0), placed inside its
## biome ring band via radius_frac (0 = inner edge, 1 = outer edge).
static func _arena_tile(entry: Dictionary) -> Vector2i:
	var biome: String = str(entry.get("biome", ""))
	var frac: float = float(entry.get("radius_frac", 0.5))
	var inner: float = 0.0
	var outer: float = BiomeGenerator.forest_radius
	match biome:
		"ForestBiome":
			inner = 0.0
			outer = BiomeGenerator.forest_radius
		_:
			# Directional normal biomes sit in the forest→sector band; refine per boss
			# once the other 8 are authored.
			if biome in BiomeGenerator.HARD_TO_BASE:
				inner = BiomeGenerator.sector_radius
				outer = BiomeGenerator.hard_radius
			else:
				inner = BiomeGenerator.forest_radius
				outer = BiomeGenerator.sector_radius
	var radius: float = lerpf(inner, outer, frac)
	var angle: float = deg_to_rad(float(entry.get("angle_deg", 0.0)))
	return Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius))


## World-space (pixel) centre of a boss's arena tile.
static func world_pos(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x + 0.5) * GameConstants.TILE_SIZE,
		(tile.y + 0.5) * GameConstants.TILE_SIZE
	)

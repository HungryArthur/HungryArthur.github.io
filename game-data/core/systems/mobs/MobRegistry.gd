extends RefCounted
class_name MobRegistry

## Reusable enemy species for the dangerous biomes. The central forest is a
## peaceful starting biome; its former enemies now live farther from spawn.
const ENTRIES := {
	"ForestBiome": [],
	"DesertBiome": [
		{"id": "sand_scarab", "name": "Sand Scarab", "role": "rusher", "hp": 54.0, "damage": 7.0, "speed": 125.0, "color": Color(0.82, 0.61, 0.24), "loot": "sand"},
		{"id": "cactus_stalker", "name": "Cactus Stalker", "role": "brute", "hp": 92.0, "damage": 9.0, "speed": 62.0, "color": Color(0.35, 0.62, 0.28), "loot": "cactus"},
		{"id": "dust_wisp", "name": "Dust Wisp", "role": "skirmisher", "hp": 42.0, "damage": 6.0, "speed": 96.0, "color": Color(0.95, 0.75, 0.38), "loot": "coal_dust"},
	],
	"SnowBiome": [
		{"id": "frost_wolf", "name": "Frost Wolf", "role": "rusher", "hp": 60.0, "damage": 8.0, "speed": 130.0, "color": Color(0.62, 0.85, 0.96), "loot": "ice_shard"},
		{"id": "ice_wisp", "name": "Ice Wisp", "role": "skirmisher", "hp": 48.0, "damage": 7.0, "speed": 102.0, "color": Color(0.45, 0.76, 1.0), "loot": "ice_shard"},
		{"id": "snow_golem", "name": "Snow Golem", "role": "brute", "hp": 110.0, "damage": 10.0, "speed": 54.0, "color": Color(0.82, 0.92, 0.96), "loot": "stone"},
	],
	"SwampBiome": [
		{"id": "bark_beetle", "name": "Bark Beetle", "role": "brute", "hp": 72.0, "damage": 8.0, "speed": 58.0, "color": Color(0.29, 0.20, 0.13), "loot": "coal"},
		{"id": "mire_leech", "name": "Mire Leech", "role": "rusher", "hp": 58.0, "damage": 7.0, "speed": 120.0, "color": Color(0.38, 0.27, 0.20), "loot": "mushroom"},
		{"id": "bog_slime", "name": "Bog Slime", "role": "brute", "hp": 105.0, "damage": 9.0, "speed": 56.0, "color": Color(0.38, 0.72, 0.25), "loot": "reed"},
		{"id": "mosquito_swarm", "name": "Mosquito Swarm", "role": "skirmisher", "hp": 42.0, "damage": 6.0, "speed": 110.0, "color": Color(0.64, 0.30, 0.22), "loot": "plant_fiber"},
	],
	"JungleBiome": [
		{"id": "woodling", "name": "Woodling", "role": "skirmisher", "hp": 32.0, "damage": 4.0, "speed": 88.0, "color": Color(0.34, 0.62, 0.30), "loot": "plant_fiber"},
		{"id": "jungle_panther", "name": "Jungle Panther", "role": "rusher", "hp": 72.0, "damage": 9.0, "speed": 138.0, "color": Color(0.24, 0.24, 0.18), "loot": "plant_fiber"},
		{"id": "vine_lurker", "name": "Vine Lurker", "role": "brute", "hp": 120.0, "damage": 11.0, "speed": 58.0, "color": Color(0.16, 0.58, 0.25), "loot": "tree_resin"},
		{"id": "sporeling", "name": "Sporeling", "role": "skirmisher", "hp": 52.0, "damage": 8.0, "speed": 106.0, "color": Color(0.66, 0.44, 0.78), "loot": "mushroom"},
	],
	"SunnyCanyonBiome": [
		{"id": "ember_beetle", "name": "Ember Beetle", "role": "rusher", "hp": 100.0, "damage": 11.0, "speed": 132.0, "color": Color(1.0, 0.36, 0.10), "loot": "coal"},
		{"id": "ash_hound", "name": "Ash Hound", "role": "rusher", "hp": 86.0, "damage": 10.0, "speed": 145.0, "color": Color(0.34, 0.30, 0.29), "loot": "coke"},
		{"id": "flare_wisp", "name": "Flare Wisp", "role": "skirmisher", "hp": 64.0, "damage": 9.0, "speed": 112.0, "color": Color(1.0, 0.66, 0.18), "loot": "purified_resonite"},
	],
	"IcyAbyssBiome": [
		{"id": "ice_stalker", "name": "Ice Stalker", "role": "rusher", "hp": 104.0, "damage": 12.0, "speed": 140.0, "color": Color(0.42, 0.76, 0.94), "loot": "ice_shard"},
		{"id": "shardling", "name": "Shardling", "role": "skirmisher", "hp": 76.0, "damage": 11.0, "speed": 115.0, "color": Color(0.68, 0.90, 1.0), "loot": "ice_shard"},
		{"id": "frost_golem", "name": "Frost Golem", "role": "brute", "hp": 160.0, "damage": 14.0, "speed": 52.0, "color": Color(0.50, 0.70, 0.84), "loot": "iron_ore"},
	],
	"RottingBogBiome": [
		{"id": "toxic_slime", "name": "Toxic Slime", "role": "brute", "hp": 150.0, "damage": 13.0, "speed": 57.0, "color": Color(0.54, 0.86, 0.18), "loot": "mushroom"},
		{"id": "rot_hound", "name": "Rot Hound", "role": "rusher", "hp": 110.0, "damage": 12.0, "speed": 142.0, "color": Color(0.40, 0.50, 0.20), "loot": "plant_fiber"},
		{"id": "bog_witch", "name": "Bog Witch", "role": "skirmisher", "hp": 84.0, "damage": 11.0, "speed": 108.0, "color": Color(0.55, 0.30, 0.62), "loot": "gunpowder"},
	],
	"PrimevalThicketBiome": [
		{"id": "forest_wolf", "name": "Forest Wolf", "role": "rusher", "hp": 48.0, "damage": 6.0, "speed": 118.0, "color": Color(0.48, 0.40, 0.30), "loot": "wood"},
		{"id": "razor_raptor", "name": "Razor Raptor", "role": "rusher", "hp": 122.0, "damage": 14.0, "speed": 152.0, "color": Color(0.76, 0.40, 0.16), "loot": "plant_fiber"},
		{"id": "ancient_vine", "name": "Ancient Vine", "role": "brute", "hp": 180.0, "damage": 15.0, "speed": 55.0, "color": Color(0.18, 0.42, 0.15), "loot": "tree_resin"},
		{"id": "primal_beetle", "name": "Primal Beetle", "role": "skirmisher", "hp": 96.0, "damage": 13.0, "speed": 118.0, "color": Color(0.62, 0.18, 0.12), "loot": "titanium_ore"},
	],
}


static func has_biome(biome: String) -> bool:
	return ENTRIES.has(biome)


static func get_for_biome(biome: String) -> Array:
	var entries: Variant = ENTRIES.get(biome, [])
	return (entries as Array).duplicate(true) if entries is Array else []


static func get_by_id(mob_id: String) -> Dictionary:
	for biome: String in ENTRIES:
		for entry: Dictionary in ENTRIES[biome]:
			if str(entry.get("id", "")) == mob_id:
				var result := entry.duplicate(true)
				result["biome"] = biome
				return result
	return {}

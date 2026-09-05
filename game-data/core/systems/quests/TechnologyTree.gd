extends RefCounted
class_name TechnologyTree

const STAGES: Array[Dictionary] = [
	{"id": "foundation", "title": "Foundation", "biome": "", "boss": "", "description": "From hand tools to the first complete automated ore line.", "machines": ["furnace", "primitive_drill", "primitive_blast_furnace", "coal_generator", "crusher", "electric_furnace", "conveyor", "bronze_drill"]},
	{"id": "steam", "title": "Steam Age", "biome": "ForestBiome", "boss": "", "research": {"wood": 40, "copper_ore": 20}, "description": "Scale the first electric workshop with steam processing and precision parts.", "machines": ["primitive_crusher", "mechanical_water_pump", "steam_water_pump", "mechanical_inserter", "steam_boiler", "high_pressure_steam_boiler", "steam_furnace", "steam_crusher", "steam_press", "steam_assembler", "steam_turbine", "coke_oven", "fluid_tank_t1"], "components": ["fluid_pipe", "fluid_pipe_t2", "fluid_valve", "steam_machine_casing", "bronze_boiler_tube", "pressure_valve", "steam_piston", "precision_flywheel", "steam_research_core", "steam_science_pack"]},
	{"id": "electricity", "title": "Electricity", "biome": "ForestBiome", "boss": "ent", "research": {"ent_heart": 1, "steam_science_pack": 6}, "description": "Expand the starter grid with rubber, faster belts, and low-voltage electronics.", "machines": ["extractor", "conveyor_t2", "machine_module_efficiency"], "components": ["electrical_science_pack"]},
	{"id": "automation", "title": "Automation", "biome": "DesertBiome", "boss": "dune_colossus", "research": {"dune_core": 1, "electrical_science_pack": 8}, "description": "Mass-produce electrical parts to unlock routing, compression, and fluid mixing.", "machines": ["compressor", "mixer", "conveyor_t3", "conveyor_splitter", "machine_module_speed"], "components": ["automation_science_pack"]},
	{"id": "industry", "title": "Heavy Industry", "biome": "SnowBiome", "boss": "frost_warden", "research": {"frost_core": 1, "automation_science_pack": 10}, "description": "Automate components and dense materials before building multi-step ore processing.", "machines": ["centrifuge", "ore_washer", "ore_melter", "magnetic_separator", "conveyor_t4", "machine_module_capacity"], "components": ["industrial_science_pack"]},
	{"id": "chemistry", "title": "Industrial Chemistry", "biome": "SwampBiome", "boss": "mire_hydra", "research": {"hydra_gland": 1, "industrial_science_pack": 12}, "description": "Use crushing, washing, separation, or centrifuging to turn ore directly into dust before chemistry.", "machines": ["chemical_reactor", "distillation_column", "machine_module_productivity"], "components": ["chemical_science_pack"]},
	{"id": "bioengineering", "title": "Bioengineering", "biome": "JungleBiome", "boss": "thorn_matriarch", "research": {"thorn_heart": 1, "chemical_science_pack": 12}, "description": "Convert oil and coke products into advanced materials for renewable production.", "machines": ["farming_station", "cobblestone_generator", "solar_panel"], "components": ["bio_science_pack"]},
	{"id": "solar_industry", "title": "Solar Industry", "biome": "SunnyCanyonBiome", "boss": "solar_tyrant", "research": {"solar_core": 1, "bio_science_pack": 14}, "description": "Combine agricultural output, productivity modules, and electronics into sustainable industry.", "machines": ["advanced_solar_panel", "energy_storage_t2"], "components": ["solar_science_pack"]},
	{"id": "abyss_engineering", "title": "Abyss Engineering", "biome": "IcyAbyssBiome", "boss": "abyss_leviathan", "research": {"leviathan_scale": 1, "solar_science_pack": 16}, "description": "Scale solar generation and energy storage before attempting molecular processing.", "machines": ["molecular_transformer", "elite_solar_panel", "energy_storage_t3", "fluid_tank_t4"], "components": ["abyss_science_pack"]},
	{"id": "frontier", "title": "Frontier Technology", "biome": "RottingBogBiome", "boss": "rot_king", "research": {"rot_crown": 1, "abyss_science_pack": 18}, "description": "Feed dense matter and high-tier electronics into a stable late-game production line.", "machines": ["ultimate_solar_panel", "conveyor_t5"], "components": ["frontier_science_pack"]},
	{"id": "quantum", "title": "Quantum Logistics", "biome": "PrimevalThicketBiome", "boss": "primal_guardian", "research": {"primal_core": 1, "frontier_science_pack": 20}, "description": "Complete the Overworld factory chain to unlock quantum storage and logistics.", "machines": ["quantum_solar_panel", "me_controller", "me_drive", "me_terminal", "me_crafting_terminal", "me_pattern_terminal", "me_molecular_assembler", "me_interface", "me_import_bus", "me_export_bus", "me_cable", "me_item_cell_1k", "me_item_cell_4k", "me_item_cell_16k", "me_item_cell_64k", "me_fluid_cell_1k", "me_fluid_cell_4k", "me_fluid_cell_16k", "me_fluid_cell_64k"]},
]


static func refresh_unlocks() -> void:
	if MultiplayerManager.is_client():
		return
	var save := SaveManager.current_save
	if save == null:
		return
	for stage: Dictionary in STAGES:
		var stage_id := str(stage["id"])
		if is_stage_condition_met(stage) and not save.researched_technologies.has(stage_id):
			save.researched_technologies.append(stage_id)
			ProgressionTelemetry.record_event("technology_unlocked", stage_id, 1)
			if stage_id != "foundation":
				NotificationCenter.push(
					"progress",
					TranslationServer.translate("Technology unlocked"),
					TranslationServer.translate(str(stage["title"])),
					"success"
				)


static func is_stage_unlocked(stage_id: String) -> bool:
	if GameData.admin_mode:
		return true
	refresh_unlocks()
	var save := SaveManager.current_save
	return stage_id == "foundation" or (save != null and save.researched_technologies.has(stage_id))


static func is_stage_condition_met(stage: Dictionary) -> bool:
	if not is_stage_world_condition_met(stage):
		return false
	return ResearchSystem.is_completed(str(stage.get("id", "")))


static func is_stage_world_condition_met(stage: Dictionary) -> bool:
	if str(stage.get("id", "")) == "foundation":
		return true
	var biome := str(stage.get("biome", ""))
	if not biome.is_empty():
		var world := SaveManager.current_world
		if world == null or not world.discovered_biomes.has(biome):
			return false
	var boss := str(stage.get("boss", ""))
	if not boss.is_empty():
		var save := SaveManager.current_save
		if save == null or not save.defeated_bosses.has(boss):
			return false
	return true


static func stage_for_item(item_id: String) -> String:
	for stage: Dictionary in STAGES:
		for collection: String in ["machines", "components"]:
			if (stage.get(collection, []) as Array).has(item_id):
				return str(stage["id"])
	return ""


static func stage_title(stage_id: String) -> String:
	for stage: Dictionary in STAGES:
		if str(stage.get("id", "")) == stage_id:
			return TranslationServer.translate(str(stage.get("title", stage_id.capitalize())))
	return stage_id.replace("_", " ").capitalize()


static func is_item_unlocked(item_id: String) -> bool:
	var stage_id := stage_for_item(item_id)
	return stage_id.is_empty() or is_stage_unlocked(stage_id)


static func requirement_text(stage: Dictionary) -> String:
	var requirements := PackedStringArray()
	var biome := str(stage.get("biome", ""))
	if not biome.is_empty():
		requirements.append(TranslationServer.translate("Discover") + ": " + BiomeProgression.display_name(biome))
	var boss := str(stage.get("boss", ""))
	if not boss.is_empty():
		var boss_data := BossRegistry.get_data(boss)
		requirements.append(TranslationServer.translate("Defeat") + ": " + TranslationServer.translate(str(boss_data.get("name", boss.capitalize()))))
	var research: Dictionary = stage.get("research", {})
	if not research.is_empty():
		requirements.append(TranslationServer.translate("Analyze") + ": " + InventoryCost.describe(research))
	return TranslationServer.translate("Available from the start") if requirements.is_empty() else " • ".join(requirements)

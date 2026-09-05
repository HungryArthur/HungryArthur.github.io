extends RefCounted
class_name EquipmentBonusSystem

const ZERO := {
	"move_speed": 0.0,
	"attack_damage": 0.0,
	"damage_reduction": 0.0,
	"mining_power": 0,
	"max_health": 0.0,
	"dash_cooldown": 0.0,
	"loot_bonus": 0.0,
}

const ITEM_BONUSES := {
	"gas_mask": {"damage_reduction": 0.04},
	"heat_suit": {"max_health": 10.0},
	"insulated_suit": {"damage_reduction": 0.08},
	"sand_amulet": {"move_speed": 0.05},
	"thermal_gloves": {"mining_power": 1},
	"miasma_boots": {"move_speed": 0.08},
	"savage_belt": {"max_health": 15.0},
	"sun_crown": {"attack_damage": 0.12},
	"cryo_mantle": {"damage_reduction": 0.12},
	"void_respirator": {"dash_cooldown": 0.15},
}

const SETS := {
	"frontier": {
		"title": "Frontier set",
		"items": ["sand_amulet", "thermal_gloves", "miasma_boots", "savage_belt"],
		"thresholds": {2: {"move_speed": 0.08}, 4: {"max_health": 20.0, "loot_bonus": 0.10}},
	},
	"ascendant": {
		"title": "Ascendant set",
		"items": ["sun_crown", "cryo_mantle", "void_respirator"],
		"thresholds": {2: {"attack_damage": 0.15}, 3: {"damage_reduction": 0.10, "dash_cooldown": 0.15}},
	},
}


static func calculate(stacks: Array) -> Dictionary:
	var result := ZERO.duplicate(true)
	var equipped_ids := PackedStringArray()
	for value: Variant in stacks:
		if not (value is Dictionary):
			continue
		var item_id := str((value as Dictionary).get("id", ""))
		if item_id.is_empty():
			continue
		equipped_ids.append(item_id)
		_merge(result, ITEM_BONUSES.get(item_id, {}))
	for set_data: Dictionary in SETS.values():
		var count := 0
		for item_id: String in set_data["items"]:
			if equipped_ids.has(item_id):
				count += 1
		for threshold: int in set_data["thresholds"]:
			if count >= threshold:
				_merge(result, set_data["thresholds"][threshold])
	return result


static func active_set_lines(stacks: Array) -> PackedStringArray:
	var ids := PackedStringArray()
	for value: Variant in stacks:
		if value is Dictionary:
			ids.append(str((value as Dictionary).get("id", "")))
	var lines := PackedStringArray()
	for set_data: Dictionary in SETS.values():
		var count := 0
		for item_id: String in set_data["items"]:
			if ids.has(item_id):
				count += 1
		lines.append("%s: %d/%d" % [TranslationServer.translate(str(set_data["title"])), count, (set_data["items"] as Array).size()])
	return lines


static func current(tree: SceneTree) -> Dictionary:
	if tree == null:
		return ZERO.duplicate(true)
	var equipment := tree.get_first_node_in_group("armor_ui")
	if equipment == null:
		return ZERO.duplicate(true)
	return calculate(equipment.get("slots") as Array)


static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key: String in source:
		target[key] = float(target.get(key, 0.0)) + float(source[key])

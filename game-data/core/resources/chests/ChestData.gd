extends Resource
class_name ChestData

signal inventory_changed(slot_index: int)
signal tier_changed(new_tier: int)

enum Tier {
	TIER_1 = 1,
	TIER_2 = 2,
	TIER_3 = 3,
}

const CHEST_T1_ID := "CHEST_T1"
const CHEST_T2_ID := "CHEST_T2"
const CHEST_T3_ID := "CHEST_T3"
const MODIFIER_T2_ID := "CHEST_MODIFIER_T2"
const MODIFIER_T3_ID := "CHEST_MODIFIER_T3"

@export var chest_tier: int = Tier.TIER_1
@export var slot_count: int = 30
@export var inventory_slots: Array = []
@export var display_name: String = "Chest Tier 1"
@export var icon: Texture2D
@export var unique_chest_id: String = ""
@export var request_enabled: bool = false
@export var request_item_id: String = ""
@export var request_target_stock: int = 64
@export var provider_enabled: bool = false
@export var provider_item_id: String = ""
@export var provider_min_stock: int = 0
@export var provider_priority: int = 0
@export var request_rules: Array[Dictionary] = []
@export var provider_rules: Array[Dictionary] = []


static func create_for_tier(tier: int) -> ChestData:
	var data := ChestData.new()
	data.unique_chest_id = _generate_unique_id()
	data.configure_tier(tier, false)
	return data


func configure_tier(tier: int, preserve_inventory: bool = true) -> void:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(tier)
	var normalized_tier: int = tier if definition != null else Tier.TIER_1
	var previous_slots: Array = inventory_slots.duplicate(true) if preserve_inventory else []

	chest_tier = normalized_tier
	slot_count = get_slot_count_for_tier(chest_tier)
	display_name = get_display_name_for_tier(chest_tier)
	icon = _get_tier_icon(chest_tier)

	inventory_slots = previous_slots
	inventory_slots.resize(slot_count)
	if unique_chest_id.is_empty():
		unique_chest_id = _generate_unique_id()
	ensure_logistics_rule_capacity()

	tier_changed.emit(chest_tier)
	inventory_changed.emit(-1)


func upgrade_to_tier(target_tier: int) -> bool:
	if target_tier != chest_tier + 1 or not ChestDatabase.has_tier(target_tier):
		return false
	configure_tier(target_tier, true)
	return true


func get_slot_data_at(index: int) -> Variant:
	if index < 0 or index >= slot_count:
		return null
	return inventory_slots[index]


func set_slot_data_at(index: int, item_data: Variant) -> void:
	if index < 0 or index >= slot_count:
		return
	var previous_count := _stack_count(inventory_slots[index])
	inventory_slots[index] = item_data
	inventory_changed.emit(index)
	var added_count := maxi(_stack_count(item_data) - previous_count, 0)
	if added_count > 0:
		QuestManager.report_event("items_stored", "", added_count)


func auto_insert_item(incoming_item: Dictionary) -> Variant:
	var incoming_count := int(incoming_item.get("count", 0))
	var leftover: Variant = InventoryStacking.insert(inventory_slots, slot_count, incoming_item)
	inventory_changed.emit(-1)
	var leftover_count := _stack_count(leftover)
	var inserted_count := maxi(incoming_count - leftover_count, 0)
	if inserted_count > 0:
		QuestManager.report_event("items_stored", "", inserted_count)
	return leftover


func _stack_count(stack_value: Variant) -> int:
	if stack_value is Dictionary:
		return int((stack_value as Dictionary).get("count", 0))
	return 0


func extract_from_slot(index: int, amount: int) -> Dictionary:
	var slot_value: Variant = get_slot_data_at(index)
	if not (slot_value is Dictionary) or amount <= 0:
		return {}

	var slot_stack: Dictionary = slot_value
	var available: int = int(slot_stack.get("count", 0))
	var extracted_count: int = mini(amount, available)
	if extracted_count <= 0:
		return {}

	var extracted_stack: Dictionary = slot_stack.duplicate(true)
	extracted_stack["count"] = extracted_count

	if extracted_count >= available:
		set_slot_data_at(index, null)
	else:
		var remaining_stack: Dictionary = slot_stack.duplicate(true)
		remaining_stack["count"] = available - extracted_count
		set_slot_data_at(index, remaining_stack)

	return extracted_stack


func is_empty() -> bool:
	for slot_value: Variant in inventory_slots:
		if slot_value is Dictionary and int(slot_value.get("count", 0)) > 0:
			return false
	return true


func logistics_rule_capacity() -> int:
	return get_logistics_rule_capacity_for_tier(chest_tier)


func ensure_logistics_rule_capacity() -> void:
	var capacity := logistics_rule_capacity()
	request_rules = _normalized_request_rules(request_rules, capacity)
	provider_rules = _normalized_provider_rules(provider_rules, capacity)
	_sync_legacy_logistics_fields()


func request_rule(index: int) -> Dictionary:
	ensure_logistics_rule_capacity()
	return request_rules[index].duplicate(true) if index >= 0 and index < request_rules.size() else {}


func provider_rule(index: int) -> Dictionary:
	ensure_logistics_rule_capacity()
	return provider_rules[index].duplicate(true) if index >= 0 and index < provider_rules.size() else {}


func set_request_rule(index: int, rule: Dictionary) -> void:
	ensure_logistics_rule_capacity()
	if index < 0 or index >= request_rules.size():
		return
	request_rules[index] = _normalized_request_rule(rule)
	_sync_legacy_logistics_fields()


func set_provider_rule(index: int, rule: Dictionary) -> void:
	ensure_logistics_rule_capacity()
	if index < 0 or index >= provider_rules.size():
		return
	provider_rules[index] = _normalized_provider_rule(rule)
	_sync_legacy_logistics_fields()


func to_save_data() -> Dictionary:
	ensure_logistics_rule_capacity()
	var saved_slots: Dictionary = {}
	for index: int in range(slot_count):
		var slot_value: Variant = inventory_slots[index]
		if slot_value is Dictionary:
			saved_slots[str(index)] = ItemDatabase.stack_to_save(slot_value)

	return {
		"unique_chest_id": unique_chest_id,
		"chest_tier": chest_tier,
		"slot_count": slot_count,
		"display_name": display_name,
		"inventory_slots": saved_slots,
		"request_enabled": request_enabled,
		"request_item_id": request_item_id,
		"request_target_stock": request_target_stock,
		"provider_enabled": provider_enabled,
		"provider_item_id": provider_item_id,
		"provider_min_stock": provider_min_stock,
		"provider_priority": provider_priority,
		"request_rules": request_rules.duplicate(true),
		"provider_rules": provider_rules.duplicate(true),
	}


static func from_save_data(saved_data: Dictionary) -> ChestData:
	var tier: int = int(saved_data.get("chest_tier", Tier.TIER_1))
	var data: ChestData = create_for_tier(tier)
	data.unique_chest_id = str(saved_data.get("unique_chest_id", data.unique_chest_id))

	# Honour a persisted slot_count/display_name that differs from the tier default.
	# Real chests save values matching their tier (a no-op here); fixed-size buffers
	# like the primitive drill's rely on this to survive a save/load.
	var saved_count: int = int(saved_data.get("slot_count", data.slot_count))
	if saved_count > 0 and saved_count != data.slot_count:
		data.slot_count = saved_count
		data.inventory_slots.resize(saved_count)
	data.display_name = str(saved_data.get("display_name", data.display_name))
	data.request_item_id = str(saved_data.get("request_item_id", "")).strip_edges()
	data.request_target_stock = clampi(int(saved_data.get("request_target_stock", 64)), 1, 9999)
	data.request_enabled = bool(saved_data.get("request_enabled", false)) \
		and not data.request_item_id.is_empty()
	data.provider_item_id = str(saved_data.get("provider_item_id", "")).strip_edges()
	data.provider_min_stock = clampi(int(saved_data.get("provider_min_stock", 0)), 0, 9999)
	data.provider_priority = clampi(int(saved_data.get("provider_priority", 0)), -2, 2)
	data.provider_enabled = bool(saved_data.get("provider_enabled", false))
	var saved_request_rules: Variant = saved_data.get("request_rules", [])
	var request_rule_values: Array = (saved_request_rules as Array).duplicate(true) \
		if saved_request_rules is Array and not (saved_request_rules as Array).is_empty() else [{
			"enabled": data.request_enabled,
			"item_id": data.request_item_id,
			"target_stock": data.request_target_stock,
		}]
	var saved_provider_rules: Variant = saved_data.get("provider_rules", [])
	var provider_rule_values: Array = (saved_provider_rules as Array).duplicate(true) \
		if saved_provider_rules is Array and not (saved_provider_rules as Array).is_empty() else [{
			"enabled": data.provider_enabled,
			"item_id": data.provider_item_id,
			"minimum_stock": data.provider_min_stock,
			"priority": data.provider_priority,
		}]
	data.request_rules = data._normalized_request_rules(
		request_rule_values, data.logistics_rule_capacity()
	)
	data.provider_rules = data._normalized_provider_rules(
		provider_rule_values, data.logistics_rule_capacity()
	)
	data._sync_legacy_logistics_fields()

	var saved_slots_value: Variant = saved_data.get("inventory_slots", {})
	if saved_slots_value is Dictionary:
		var saved_slots: Dictionary = saved_slots_value
		for key_variant: Variant in saved_slots.keys():
			var index: int = int(str(key_variant))
			if index < 0 or index >= data.slot_count:
				continue
			var slot_save_value: Variant = saved_slots[key_variant]
			if slot_save_value is Dictionary:
				data.inventory_slots[index] = ItemDatabase.stack_from_save(slot_save_value)
	return data


static func upgrade_saved_data(saved_data: Dictionary, target_tier: int) -> Dictionary:
	var upgraded: Dictionary = saved_data.duplicate(true)
	upgraded["chest_tier"] = target_tier
	upgraded["slot_count"] = get_slot_count_for_tier(target_tier)
	upgraded["display_name"] = get_display_name_for_tier(target_tier)
	return upgraded


static func get_slot_count_for_tier(tier: int) -> int:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(tier)
	if definition != null:
		return definition.slot_count
	match tier:
		Tier.TIER_2:
			return 60
		Tier.TIER_3:
			return 90
		_:
			return 30


static func get_logistics_rule_capacity_for_tier(tier: int) -> int:
	match tier:
		Tier.TIER_2:
			return 4
		Tier.TIER_3:
			return 8
		_:
			return 2


func _normalized_request_rules(values: Array, capacity: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in capacity:
		var value: Variant = values[index] if index < values.size() else {}
		result.append(_normalized_request_rule(value as Dictionary if value is Dictionary else {}))
	return result


func _normalized_provider_rules(values: Array, capacity: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in capacity:
		var value: Variant = values[index] if index < values.size() else {}
		result.append(_normalized_provider_rule(value as Dictionary if value is Dictionary else {}))
	return result


func _normalized_request_rule(rule: Dictionary) -> Dictionary:
	var item_id := str(rule.get("item_id", "")).strip_edges()
	return {
		"enabled": bool(rule.get("enabled", false)) and not item_id.is_empty(),
		"item_id": item_id,
		"target_stock": clampi(int(rule.get("target_stock", 64)), 1, 9999),
	}


func _normalized_provider_rule(rule: Dictionary) -> Dictionary:
	return {
		"enabled": bool(rule.get("enabled", false)),
		"item_id": str(rule.get("item_id", "")).strip_edges(),
		"minimum_stock": clampi(int(rule.get("minimum_stock", 0)), 0, 9999),
		"priority": clampi(int(rule.get("priority", 0)), -2, 2),
	}


func _sync_legacy_logistics_fields() -> void:
	if not request_rules.is_empty():
		var request := request_rules[0]
		request_enabled = bool(request.get("enabled", false))
		request_item_id = str(request.get("item_id", ""))
		request_target_stock = int(request.get("target_stock", 64))
	if not provider_rules.is_empty():
		var provider := provider_rules[0]
		provider_enabled = bool(provider.get("enabled", false))
		provider_item_id = str(provider.get("item_id", ""))
		provider_min_stock = int(provider.get("minimum_stock", 0))
		provider_priority = int(provider.get("priority", 0))


static func get_display_name_for_tier(tier: int) -> String:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(tier)
	if definition != null:
		return definition.display_name
	return "Chest Tier %d" % maxi(tier, Tier.TIER_1)


static func get_item_id_for_tier(tier: int) -> String:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(tier)
	if definition != null:
		return definition.item_id
	match tier:
		Tier.TIER_2:
			return CHEST_T2_ID
		Tier.TIER_3:
			return CHEST_T3_ID
		_:
			return CHEST_T1_ID


static func get_block_id_for_tier(tier: int) -> String:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(tier)
	if definition != null:
		return definition.block_id
	return get_item_id_for_tier(tier).to_lower()


static func get_tier_for_block_id(block_id: String) -> int:
	var registered_tier: int = ChestDatabase.get_tier_for_block_id(block_id)
	if registered_tier > 0:
		return registered_tier
	match block_id.to_lower():
		"chest_t2":
			return Tier.TIER_2
		"chest_t3":
			return Tier.TIER_3
		_:
			return Tier.TIER_1


static func get_tier_for_item_id(item_id: String) -> int:
	var registered_tier: int = ChestDatabase.get_tier_for_item_id(item_id)
	if registered_tier > 0:
		return registered_tier
	match item_id.to_upper():
		CHEST_T2_ID:
			return Tier.TIER_2
		CHEST_T3_ID:
			return Tier.TIER_3
		_:
			return Tier.TIER_1


static func get_modifier_for_upgrade(current_tier: int) -> String:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(current_tier)
	if definition != null:
		return definition.upgrade_modifier_id
	match current_tier:
		Tier.TIER_1:
			return MODIFIER_T2_ID
		Tier.TIER_2:
			return MODIFIER_T3_ID
		_:
			return ""


static func get_previous_chest_item_id(target_tier: int) -> String:
	if target_tier <= Tier.TIER_1:
		return ""
	return get_item_id_for_tier(target_tier - 1)


static func is_chest_item_id(item_id: String) -> bool:
	if ChestDatabase.is_chest_item_id(item_id):
		return true
	var normalized_id: String = item_id.to_upper()
	return normalized_id in [CHEST_T1_ID, CHEST_T2_ID, CHEST_T3_ID]


static func _get_tier_icon(tier: int) -> Texture2D:
	var definition: ChestTierDefinition = ChestDatabase.get_definition(tier)
	if definition != null and definition.icon != null:
		return definition.icon
	var item_id: String = get_item_id_for_tier(tier)
	var item_value: Variant = ItemDatabase.registry.get(item_id)
	if item_value is ItemData:
		return item_value.texture
	return null


static func _generate_unique_id() -> String:
	var timestamp: String = str(Time.get_unix_time_from_system()).replace(".", "")
	return "chest-%s-%d" % [timestamp, randi()]

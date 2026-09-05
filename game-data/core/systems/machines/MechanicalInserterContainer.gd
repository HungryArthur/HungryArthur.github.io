extends MachineContainer
class_name MechanicalInserterContainer

const TRANSFER_INTERVAL := 1.5
const MAX_FILTER_IDS := 24

var source_grid_pos := Vector2i.ZERO
var facing := 2
var carried: Dictionary = {}
var transfer_progress := 0.0
var processing_active := false
var transfer_serial := 0
var filter_ids := PackedStringArray()
var filter_mode := "allow"
var enabled := true
var status_key := "Waiting for source"
var request_target_active := false
var request_pending := false
var requested_item_id := ""
var provider_deferred := false
var _reported_conveyor_request := false


func _init() -> void:
	tick_interval = 0.1


func _exit_tree() -> void:
	IngredientDemandReservations.release_stack(carried)
	super._exit_tree()


func set_source_grid_pos(grid_pos: Vector2i) -> void:
	source_grid_pos = grid_pos


func set_facing(new_facing: int) -> void:
	facing = ((new_facing % 4) + 4) % 4


func tick(delta: float) -> void:
	processing_active = false
	if not enabled:
		status_key = "Disabled"
		return
	transfer_progress += delta
	if transfer_progress < TRANSFER_INTERVAL:
		return
	transfer_progress = fmod(transfer_progress, TRANSFER_INTERVAL)

	if not carried.is_empty():
		carried = _push_to_target(carried)
		if not carried.is_empty():
			status_key = "Destination blocked"
			return
		_mark_transfer_complete()
		return

	var extracted := _pull_from_source()
	if extracted.is_empty():
		if provider_deferred:
			status_key = "Waiting for higher priority provider"
		elif request_target_active:
			status_key = "Waiting for requested ingredient" if request_pending else "Ingredient demand satisfied"
		else:
			status_key = "Waiting for matching item" if not filter_ids.is_empty() else "Waiting for source"
		return
	carried = _push_to_target(extracted)
	if carried.is_empty():
		_mark_transfer_complete()
	else:
		status_key = "Destination blocked"


func _mark_transfer_complete() -> void:
	processing_active = true
	status_key = "Supplying requested ingredient" if request_target_active and not requested_item_id.is_empty() else "Transferring"
	transfer_serial += 1
	QuestManager.report_event("item_transferred", "mechanical_inserter", 1)
	if request_target_active and not requested_item_id.is_empty():
		QuestManager.report_event("ingredient_request_fulfilled", requested_item_id, 1)


func _pull_from_source() -> Dictionary:
	request_target_active = false
	request_pending = false
	requested_item_id = ""
	provider_deferred = false
	var request_context := _target_request_context()
	request_target_active = bool(request_context.get("active", false))
	var requests := request_context.get("requests", {}) as Dictionary
	request_pending = not requests.is_empty()
	if request_target_active and not request_pending:
		return {}
	var source := _block_at(source_grid_pos - WorldBlock.FACING_DIRS[facing])
	if source == null:
		return {}
	if source.chest_inventory != null:
		if request_target_active:
			for item_id: String in _requested_item_order(requests):
				if not accepts_item(item_id) or not source.chest_inventory.can_supply_item(item_id):
					continue
				if _higher_priority_provider_available(item_id, request_context, source):
					provider_deferred = true
					requested_item_id = item_id
					continue
				for slot_index in source.chest_inventory.get_slot_count():
					var requested_stack: Variant = source.chest_inventory.get_slot_data_at(slot_index)
					if requested_stack is Dictionary and int((requested_stack as Dictionary).get("count", 0)) > 0 \
						and str((requested_stack as Dictionary).get("id", "")) == item_id:
						requested_item_id = item_id
						return _reserve_requested_stack(
							source.chest_inventory.pull_supply_item(slot_index, 1),
							item_id,
							request_context
						)
			return {}
		for slot_index in source.chest_inventory.get_slot_count():
			var stack_value: Variant = source.chest_inventory.get_slot_data_at(slot_index)
			if stack_value is Dictionary and int((stack_value as Dictionary).get("count", 0)) > 0 \
					and accepts_item(str((stack_value as Dictionary).get("id", ""))) \
					and source.chest_inventory.can_supply_item(str((stack_value as Dictionary).get("id", ""))):
				return source.chest_inventory.pull_supply_item(slot_index, 1)
	if source.machine is ConveyorContainer:
		var conveyor := source.machine as ConveyorContainer
		var item_id := str(conveyor.carried.get("id", ""))
		if accepts_item(item_id) and _request_accepts(item_id, requests):
			requested_item_id = item_id if request_target_active else ""
			return _reserve_requested_stack(conveyor.pull_carried_item(1), item_id, request_context)
	if source.machine != null:
		for slot_index in source.machine.slots.size():
			var slot := source.machine.slots[slot_index] as MachineSlot
			if slot != null and slot.role == MachineSlot.Role.OUTPUT and not slot.is_empty() \
					and accepts_item(str(slot.item.get("id", ""))) \
					and _request_accepts(str(slot.item.get("id", "")), requests):
				requested_item_id = str(slot.item.get("id", "")) if request_target_active else ""
				return _reserve_requested_stack(
					source.machine.pull_item(slot_index, 1),
					str(slot.item.get("id", "")),
					request_context
				)
	return {}


func _reserve_requested_stack(stack: Dictionary, item_id: String, context: Dictionary) -> Dictionary:
	if stack.is_empty() or not request_target_active or IngredientDemandReservations.has_reservation(stack):
		return stack
	var reservation := IngredientDemandReservations.reserve(context, item_id, int(stack.get("count", 0)))
	return IngredientDemandReservations.attach_to_stack(stack, reservation) if not reservation.is_empty() else stack


func _higher_priority_provider_available(
		item_id: String,
		request_context: Dictionary,
		current_source: WorldBlock
) -> bool:
	if current_source.chest_inventory == null or not is_inside_tree():
		return false
	var target_keys := _request_target_keys(request_context, item_id)
	if target_keys.is_empty():
		return false
	var current_priority := current_source.chest_inventory.supply_priority(item_id)
	for node: Node in get_tree().get_nodes_in_group("world_block"):
		var candidate_block := node as WorldBlock
		if candidate_block == null or candidate_block.machine == self \
			or not (candidate_block.machine is MechanicalInserterContainer):
			continue
		var candidate := candidate_block.machine as MechanicalInserterContainer
		if not candidate.enabled or not candidate.carried.is_empty() or not candidate.accepts_item(item_id):
			continue
		var candidate_source := candidate._block_at(
			candidate.source_grid_pos - WorldBlock.FACING_DIRS[candidate.facing]
		)
		if candidate_source == null or candidate_source == current_source \
			or candidate_source.chest_inventory == null \
			or candidate_source.chest_inventory.supply_priority(item_id) <= current_priority \
			or not candidate_source.chest_inventory.can_supply_item(item_id):
			continue
		var candidate_keys := _request_target_keys(candidate._target_request_context(), item_id)
		for target_key: Variant in target_keys:
			if candidate_keys.has(target_key):
				return true
	return false


func _request_target_keys(context: Dictionary, item_id: String) -> Dictionary:
	var result := {}
	var allocations := context.get("allocations", {}) as Dictionary
	var entries: Array = allocations.get(item_id, []) if allocations.get(item_id, []) is Array else []
	for entry_value: Variant in entries:
		if entry_value is Dictionary:
			var target_key := str((entry_value as Dictionary).get("key", ""))
			if not target_key.is_empty():
				result[target_key] = true
	return result


func _target_request_context() -> Dictionary:
	var target := _block_at(source_grid_pos + WorldBlock.FACING_DIRS[facing])
	if target == null:
		return {"active": false, "requests": {}}
	var context: Dictionary = {"active": false, "requests": {}}
	if target.chest_inventory != null and target.chest_inventory.has_method("ingredient_request_context"):
		var chest_context: Variant = target.chest_inventory.ingredient_request_context()
		if chest_context is Dictionary:
			context = chest_context as Dictionary
	elif target.machine != null and target.machine.has_method("ingredient_request_context"):
		var context_value: Variant = target.machine.ingredient_request_context()
		if context_value is Dictionary:
			context = context_value as Dictionary
	elif target.machine != null and target.machine.has_method("uses_ingredient_requests") \
		and bool(target.machine.uses_ingredient_requests()):
		var request_value: Variant = target.machine.ingredient_requests() \
			if target.machine.has_method("ingredient_requests") else {}
		context = {
			"active": true,
			"requests": request_value if request_value is Dictionary else {},
		}
	if not _reported_conveyor_request and target.machine is ConveyorContainer \
		and bool(context.get("active", false)) and not (context.get("requests", {}) as Dictionary).is_empty():
		_reported_conveyor_request = true
		QuestManager.report_event("conveyor_demand_signal", "ingredient", 1)
	return context


func _requested_item_order(requests: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for item_value: Variant in requests:
		result.append(str(item_value))
	result.sort_custom(func(first: String, second: String) -> bool:
		var first_count := int(requests.get(first, 0))
		var second_count := int(requests.get(second, 0))
		return first < second if first_count == second_count else first_count > second_count
	)
	return result


func _request_accepts(item_id: String, requests: Dictionary) -> bool:
	return not request_target_active or int(requests.get(item_id, 0)) > 0


func _push_to_target(stack: Dictionary) -> Dictionary:
	var target := _block_at(source_grid_pos + WorldBlock.FACING_DIRS[facing])
	if target == null:
		return stack
	if target.machine is ConveyorContainer:
		return (target.machine as ConveyorContainer).try_accept(stack)
	if target.chest_inventory != null:
		var context := target.chest_inventory.ingredient_request_context()
		if bool(context.get("active", false)) \
			and int((context.get("requests", {}) as Dictionary).get(str(stack.get("id", "")), 0)) <= 0 \
			and not IngredientDemandReservations.reservation_matches_context(stack, context):
			return stack
		var payload := IngredientDemandReservations.payload_without_reservation(stack)
		var leftover: Variant = target.chest_inventory.push_item(payload)
		if not leftover is Dictionary or (leftover as Dictionary).is_empty():
			IngredientDemandReservations.release_stack(stack)
			return {}
		return stack
	if target.machine != null:
		if target.machine.has_method("ingredient_request_context"):
			var context_value: Variant = target.machine.ingredient_request_context()
			if context_value is Dictionary and bool((context_value as Dictionary).get("active", false)) \
				and int(((context_value as Dictionary).get("requests", {}) as Dictionary).get(str(stack.get("id", "")), 0)) <= 0 \
				and not IngredientDemandReservations.reservation_matches_context(stack, context_value as Dictionary):
				return stack
		var input_slot := target.machine.find_input_slot_for(str(stack.get("id", "")))
		if input_slot >= 0:
			var payload := IngredientDemandReservations.payload_without_reservation(stack)
			var leftover := target.machine.push_item(input_slot, payload)
			if leftover.is_empty():
				IngredientDemandReservations.release_stack(stack)
				return {}
			return stack
	return stack


func _block_at(grid_pos: Vector2i) -> WorldBlock:
	var manager := get_tree().get_first_node_in_group("world_interaction")
	if manager == null or not manager.has_method("get_block_at"):
		return null
	return manager.get_block_at(grid_pos) as WorldBlock


func configure_filter(ids: PackedStringArray, mode: String = "allow", is_enabled: bool = true) -> void:
	filter_ids = _sanitized_filter_ids(ids)
	filter_mode = "block" if mode == "block" else "allow"
	enabled = is_enabled
	status_key = "Disabled" if not enabled else "Waiting for source"
	wake()


func accepts_item(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	if filter_ids.is_empty():
		return true
	var listed := filter_ids.has(item_id)
	return not listed if filter_mode == "block" else listed


func _sanitized_filter_ids(ids: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for raw_id: String in ids:
		var item_id := raw_id.strip_edges().to_lower().replace(" ", "_").left(64)
		if not item_id.is_empty() and not result.has(item_id):
			result.append(item_id)
		if result.size() >= MAX_FILTER_IDS:
			break
	return result


func network_config_data() -> Dictionary:
	var config := super.network_config_data()
	config["filter_ids"] = Array(filter_ids)
	config["filter_mode"] = filter_mode
	config["enabled"] = enabled
	config["facing"] = facing
	return config


func apply_network_config(config: Dictionary) -> void:
	super.apply_network_config(config)
	configure_filter(
		PackedStringArray(config.get("filter_ids", [])),
		str(config.get("filter_mode", "allow")),
		bool(config.get("enabled", true))
	)
	set_facing(clampi(int(config.get("facing", facing)), 0, 3))
	_sync_owner_facing()


func _sync_owner_facing() -> void:
	var block := get_parent() as WorldBlock
	if block != null and block.facing != facing:
		block.set_facing(facing)


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	if not carried.is_empty():
		data["carried"] = carried.duplicate(true)
	data["transfer_progress"] = transfer_progress
	data["filter_ids"] = Array(filter_ids)
	data["filter_mode"] = filter_mode
	data["enabled"] = enabled
	data["facing"] = facing
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	var carried_value: Variant = data.get("carried", {})
	carried = (carried_value as Dictionary).duplicate(true) if carried_value is Dictionary else {}
	IngredientDemandReservations.restore_stack(carried)
	transfer_progress = clampf(float(data.get("transfer_progress", 0.0)), 0.0, TRANSFER_INTERVAL)
	filter_ids = _sanitized_filter_ids(PackedStringArray(data.get("filter_ids", [])))
	filter_mode = "block" if str(data.get("filter_mode", "allow")) == "block" else "allow"
	enabled = bool(data.get("enabled", true))
	set_facing(clampi(int(data.get("facing", facing)), 0, 3))
	status_key = "Disabled" if not enabled else "Waiting for source"
	_sync_owner_facing()

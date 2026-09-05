extends ConveyorContainer
class_name ConveyorSplitterContainer

## A 1→2 conveyor splitter. Items are fed in from the back (opposite `facing`) and
## handed out to the two SIDE tiles — left `(facing+3)%4` and right `(facing+1)%4`.
## Delivery alternates round-robin, so a steady input stream is split evenly between
## the two outputs (if one side is blocked, the whole item goes to the other).
##
## Everything else — belt power draw, power conduction along a line, the freeze-when-
## unpowered behaviour — is inherited unchanged from ConveyorContainer.

## Which side gets tried first next: 0 = left, 1 = right. Toggles on each hand-off.
var _next_output: int = 0
var output_filters: Array[PackedStringArray] = [PackedStringArray(), PackedStringArray()]
var output_priorities: Array[int] = [0, 0]


func _init() -> void:
	machine_title = "CONVEYOR SPLITTER"
	requires_power = true
	power_capacity = 4.0


## Side output directions, in the order they should be tried this cycle.
func _output_order() -> Array:
	var left_dir: int = (facing + 3) % 4
	var right_dir: int = (facing + 1) % 4
	if output_priorities[0] != output_priorities[1]:
		return [left_dir, right_dir] if output_priorities[0] > output_priorities[1] else [right_dir, left_dir]
	return [left_dir, right_dir] if _next_output == 0 else [right_dir, left_dir]


func configure_output(side: int, ids: PackedStringArray, output_priority: int) -> void:
	if side < 0 or side >= 2:
		return
	output_filters[side] = _sanitized_filter_ids(ids)
	output_priorities[side] = clampi(output_priority, -10, 10)


func network_config_data() -> Dictionary:
	var config := super.network_config_data()
	config["output_filters"] = [Array(output_filters[0]), Array(output_filters[1])]
	config["output_priorities"] = output_priorities.duplicate()
	return config


func apply_network_config(config: Dictionary) -> void:
	super.apply_network_config(config)
	var filters: Variant = config.get("output_filters", [])
	if filters is Array and filters.size() >= 2:
		output_filters[0] = _sanitized_filter_ids(PackedStringArray(filters[0]))
		output_filters[1] = _sanitized_filter_ids(PackedStringArray(filters[1]))
	var priorities: Variant = config.get("output_priorities", [])
	if priorities is Array and priorities.size() >= 2:
		output_priorities[0] = clampi(int(priorities[0]), -10, 10)
		output_priorities[1] = clampi(int(priorities[1]), -10, 10)


func _side_for_direction(direction: int) -> int:
	return 0 if direction == (facing + 3) % 4 else 1


func _output_accepts(direction: int, item_id: String) -> bool:
	var side := _side_for_direction(direction)
	var ids := output_filters[side]
	return ids.is_empty() or ids.has(item_id)


func _ingredient_request_context(visited: Dictionary, remaining: int) -> Dictionary:
	if remaining <= 0 or visited.has(get_instance_id()):
		return _empty_request_context()
	visited[get_instance_id()] = true
	var combined_allocations: Dictionary = {}
	var active := false
	for direction: int in _output_order():
		var target := _block_at(source_grid_pos + WorldBlock.FACING_DIRS[direction])
		var context := _request_context_from_block(target, visited, remaining - 1)
		active = active or bool(context.get("active", false))
		for item_value: Variant in (context.get("allocations", {}) as Dictionary):
			var item_id := str(item_value)
			if accepts_item(item_id) and _output_accepts(direction, item_id):
				var entries: Array = combined_allocations.get(item_id, [])
				entries.append_array((context.get("allocations", {}) as Dictionary).get(item_value, []))
				combined_allocations[item_id] = entries
	return IngredientDemandReservations.context_from_allocations(active, combined_allocations)


func _try_deliver() -> void:
	var item_id := str(carried.get("id", ""))
	var requested_outputs: Array[int] = []
	var passive_outputs: Array[int] = []
	for dir_value: int in _output_order():
		if not _output_accepts(dir_value, item_id):
			continue
		var target: Vector2i = source_grid_pos + WorldBlock.FACING_DIRS[dir_value]
		var block := _block_at(target)
		if block == null:
			continue
		var context := _request_context_from_block(
			block,
			{get_instance_id(): true},
			INGREDIENT_DEMAND_MAX_NODES - 1
		)
		if bool(context.get("active", false)):
			if int((context.get("requests", {}) as Dictionary).get(item_id, 0)) > 0 \
				or IngredientDemandReservations.reservation_matches_context(carried, context):
				requested_outputs.append(dir_value)
		else:
			passive_outputs.append(dir_value)
	for dir_value: int in requested_outputs + passive_outputs:
		var target: Vector2i = source_grid_pos + WorldBlock.FACING_DIRS[dir_value]
		var block := _block_at(target)
		if block == null:
			continue
		var leftover: Dictionary = _hand_off(block, target)
		if leftover.is_empty():
			QuestManager.report_event("conveyor_item_moved", "", 1)
			carried = {}
			progress = 0.0
			_clear_item_sprite()
			# Continue after the side that actually accepted the item. If the preferred
			# side was blocked, this avoids selecting the fallback side twice in a row.
			_next_output = 1 - _side_for_direction(dir_value)
			return
	# Neither side could take it: keep carrying (progress stays pinned at 1.0).


## Item travels from the back edge to the centre (0→0.5), then out along whichever
## side is first in line this cycle (0.5→1.0).
func _position_item_sprite() -> void:
	if _item_sprite == null:
		return
	var half: float = float(GameConstants.TILE_SIZE) * 0.5
	var in_vec := Vector2(WorldBlock.FACING_DIRS[(facing + 2) % 4])
	var out_vec := Vector2(WorldBlock.FACING_DIRS[_output_order()[0]])
	if progress < 0.5:
		_item_sprite.position = in_vec * lerpf(half, 0.0, progress * 2.0)
	else:
		_item_sprite.position = out_vec * lerpf(0.0, half, (progress - 0.5) * 2.0)


func to_save_data() -> Dictionary:
	var data: Dictionary = super.to_save_data()
	data["next_output"] = _next_output
	data["output_filters"] = [Array(output_filters[0]), Array(output_filters[1])]
	data["output_priorities"] = output_priorities.duplicate()
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	_next_output = int(data.get("next_output", 0)) & 1
	var saved_filters: Array = data.get("output_filters", [])
	if saved_filters.size() >= 2:
		output_filters[0] = PackedStringArray(saved_filters[0])
		output_filters[1] = PackedStringArray(saved_filters[1])
	var saved_priorities: Array = data.get("output_priorities", [])
	if saved_priorities.size() >= 2:
		output_priorities[0] = clampi(int(saved_priorities[0]), -10, 10)
		output_priorities[1] = clampi(int(saved_priorities[1]), -10, 10)

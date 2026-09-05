extends SteamMachineContainer
class_name SteamAssemblerContainer

const INPUT_SLOT_COUNT := 4
const ASSEMBLY_OUTPUT_SLOT := INPUT_SLOT_COUNT
const PROCESS_TIME := 5.0
const STEAM_PER_SECOND := 1.5
const INGREDIENT_REQUEST_BATCHES := 4
const RECIPE_DISTRIBUTION_SCAN_INTERVAL_MSEC := 500
const RECIPE_DISTRIBUTION_CLAIM_TIMEOUT_MSEC := 1200
static var _recipe_distribution_claims: Dictionary = {}

const RECIPE_ORDER := [
	"bronze_rod",
	"bronze_ring",
	"bronze_bolt",
	"bronze_pipe",
	"small_bronze_gear",
	"bronze_bearing",
	"bronze_rotor",
	"mechanical_drive_unit",
	"mechanical_control_unit",
	"steel_rod",
	"steel_ring",
	"steel_pipe",
	"steel_bearing",
	"steel_rotor",
	"steam_drive_unit",
	"steam_control_unit",
	"bronze_boiler_tube",
	"thermal_unit",
	"fluid_manifold",
	"steam_machine_casing",
	"steam_research_core",
	"steam_science_pack",
]

const ASSEMBLY_RECIPES := {
	"bronze_rod": {
		"inputs": {"bronze_ingot": 1},
		"output_count": 2,
	},
	"bronze_ring": {
		"inputs": {"bronze_rod": 1},
		"output_count": 2,
	},
	"bronze_bolt": {
		"inputs": {"bronze_plate": 1},
		"output_count": 4,
	},
	"bronze_pipe": {
		"inputs": {"bronze_plate": 2},
		"output_count": 2,
	},
	"small_bronze_gear": {
		"inputs": {"bronze_plate": 1, "bronze_bolt": 1},
		"output_count": 1,
	},
	"bronze_bearing": {
		"inputs": {"bronze_ring": 2, "bronze_rod": 1},
		"output_count": 2,
	},
	"bronze_rotor": {
		"inputs": {"bronze_plate": 4, "bronze_ring": 1, "bronze_bolt": 2},
		"output_count": 1,
	},
	"mechanical_drive_unit": {
		"inputs": {"small_bronze_gear": 2, "bronze_bearing": 2, "bronze_rotor": 1, "bronze_rod": 2},
		"output_count": 1,
	},
	"mechanical_control_unit": {
		"inputs": {"small_bronze_gear": 2, "bronze_bearing": 2, "bronze_rod": 1, "insulated_copper_wire": 2},
		"output_count": 1,
	},
	"steel_rod": {
		"inputs": {"steel_ingot": 1},
		"output_count": 2,
	},
	"steel_ring": {
		"inputs": {"steel_rod": 1},
		"output_count": 2,
	},
	"steel_pipe": {
		"inputs": {"steel_plate": 2},
		"output_count": 2,
	},
	"steel_bearing": {
		"inputs": {"steel_ring": 2, "steel_rod": 1},
		"output_count": 2,
	},
	"steel_rotor": {
		"inputs": {"steel_plate": 4, "steel_ring": 1, "bolt": 2},
		"output_count": 1,
	},
	"steam_drive_unit": {
		"inputs": {"mechanical_drive_unit": 1, "steam_piston": 2, "precision_flywheel": 1, "pressure_valve": 1},
		"output_count": 1,
	},
	"steam_control_unit": {
		"inputs": {"mechanical_control_unit": 1, "pressure_valve": 1, "bronze_pipe": 2, "bronze_bolt": 4},
		"output_count": 1,
	},
	"bronze_boiler_tube": {
		"inputs": {"bronze_pipe": 2, "copper_plate": 1, "bronze_bolt": 2},
		"output_count": 2,
	},
	"thermal_unit": {
		"inputs": {"furnace": 1, "bronze_boiler_tube": 2, "copper_plate": 2, "bronze_bolt": 4},
		"output_count": 1,
	},
	"fluid_manifold": {
		"inputs": {"bronze_pipe": 4, "bronze_ring": 2, "bronze_bolt": 4, "pressure_valve": 1},
		"output_count": 1,
	},
	"steam_machine_casing": {
		"inputs": {"bronze_plate": 8, "bronze_pipe": 4, "refractory_brick": 2},
		"output_count": 1,
	},
	"steam_research_core": {
		"inputs": {"pressure_valve": 1, "steam_piston": 1, "precision_flywheel": 1, "small_bronze_gear": 2},
		"output_count": 1,
	},
	"steam_science_pack": {
		"inputs": {"steam_research_core": 1, "steel_plate": 2, "coke": 2, "bronze_plate": 2},
		"output_count": 1,
	},
}

var selected_recipe_id := ""
var last_status := "No recipe selected"
var crafts_done := 0
var recipe_distribution_enabled := false
var recipe_distribution_blocked := false
var recipe_distribution_waiting_for_output := false
var recipe_distribution_assigned_item_id := ""
var recipe_distribution_order_count := 0
var recipe_distribution_producer_count := 0
var recipe_distribution_group_key := ""
var _recipe_distribution_next_scan_msec := 0
var _recipe_distribution_reported := false
var ingredient_requests_enabled := false


func _init() -> void:
	configure("STEAM ASSEMBLER", {}, PROCESS_TIME, STEAM_PER_SECOND)
	var allowed_inputs := PackedStringArray()
	for output_id: String in RECIPE_ORDER:
		for input_id: String in (ASSEMBLY_RECIPES[output_id]["inputs"] as Dictionary):
			if not allowed_inputs.has(input_id):
				allowed_inputs.append(input_id)
	slots.clear()
	for _slot_index in INPUT_SLOT_COUNT:
		var input_slot := MachineSlot.new()
		input_slot.role = MachineSlot.Role.INPUT
		input_slot.filter = allowed_inputs.duplicate()
		slots.append(input_slot)
	var output_slot := MachineSlot.new()
	output_slot.role = MachineSlot.Role.OUTPUT
	slots.append(output_slot)


func _exit_tree() -> void:
	_release_recipe_distribution_claim()
	super._exit_tree()


func set_recipe(output_id: String) -> bool:
	if not ASSEMBLY_RECIPES.has(output_id):
		return false
	selected_recipe_id = output_id
	process_timer = 0.0
	last_status = "Waiting for ingredients"
	wake()
	notify_network_config_changed()
	QuestManager.report_event("machine_recipe_selected", output_id, 1)
	return true


func configure_ingredient_requests(enabled: bool) -> void:
	ingredient_requests_enabled = enabled
	wake()


func uses_ingredient_requests() -> bool:
	return ingredient_requests_enabled and not selected_recipe_id.is_empty()


func ingredient_requests() -> Dictionary:
	var requests: Dictionary = {}
	if not uses_ingredient_requests():
		return requests
	var recipe := selected_recipe()
	if recipe.is_empty():
		return requests
	for item_value: Variant in (recipe.get("inputs", {}) as Dictionary):
		var item_id := str(item_value)
		var desired := int(recipe["inputs"][item_value]) * INGREDIENT_REQUEST_BATCHES
		var missing := maxi(desired - _count_input(item_id), 0)
		if missing > 0 and find_input_slot_for(item_id) >= 0:
			requests[item_id] = missing
	return requests


func ingredient_request_context() -> Dictionary:
	if not uses_ingredient_requests():
		return IngredientDemandReservations.context_from_allocations(false, {})
	return IngredientDemandReservations.target_context(_ingredient_request_target_key(), ingredient_requests())


func _ingredient_request_target_key() -> String:
	var block := get_parent() as WorldBlock
	return "assembler:%d:%d" % [block.grid_pos.x, block.grid_pos.y] \
		if block != null else "assembler-instance:%d" % get_instance_id()


func configure_stock_control(enabled: bool, item_id: String, target: int, priority: int = 0) -> void:
	_release_recipe_distribution_claim()
	super.configure_stock_control(enabled, item_id, target, priority)
	_recipe_distribution_next_scan_msec = 0
	if recipe_distribution_enabled and is_inside_tree():
		refresh_stock_control(true)


func configure_recipe_distribution(enabled: bool) -> void:
	recipe_distribution_enabled = enabled
	_recipe_distribution_next_scan_msec = 0
	if recipe_distribution_enabled:
		_release_stock_control_claim()
		if is_inside_tree():
			refresh_stock_control(true)
	else:
		_release_recipe_distribution_claim()
		_reset_recipe_distribution_state()
		if is_inside_tree():
			super.refresh_stock_control(true)
	wake()


func refresh_stock_control(force: bool = false) -> void:
	if not recipe_distribution_enabled:
		super.refresh_stock_control(force)
		return
	_refresh_recipe_distribution(force)


func selected_recipe() -> Dictionary:
	return ASSEMBLY_RECIPES.get(selected_recipe_id, {}) as Dictionary


func tick(delta: float) -> void:
	processing_active = false
	if selected_recipe_id.is_empty():
		last_status = "No recipe selected"
		process_timer = 0.0
		return
	var recipe := selected_recipe()
	if recipe.is_empty():
		last_status = "Invalid recipe"
		process_timer = 0.0
		return
	if not _has_ingredients(recipe.get("inputs", {}) as Dictionary):
		last_status = "Requesting ingredients" if ingredient_requests_enabled \
			and not ingredient_requests().is_empty() else "Missing ingredients"
		process_timer = 0.0
		return
	if not _output_has_space(selected_recipe_id, int(recipe.get("output_count", 1))):
		last_status = "Output blocked"
		process_timer = 0.0
		return
	if not has_steam():
		last_status = "No Steam"
		process_timer = 0.0
		return

	processing_active = true
	last_status = "Assembling"
	input_tanks[0].extract(steam_per_second * delta)
	fluid_changed.emit()
	process_timer += delta
	if process_timer < process_time:
		return
	process_timer = fmod(process_timer, process_time)
	_complete_assembly(recipe)


func _has_ingredients(required: Dictionary) -> bool:
	for item_id: String in required:
		if _count_input(item_id) < int(required[item_id]):
			return false
	return true


func _count_input(item_id: String) -> int:
	var total := 0
	for slot_index in INPUT_SLOT_COUNT:
		var slot := slots[slot_index] as MachineSlot
		if not slot.is_empty() and str(slot.item.get("id", "")) == item_id:
			total += int(slot.item.get("count", 0))
	return total


func _consume_input(item_id: String, amount: int) -> void:
	var remaining := amount
	for slot_index in INPUT_SLOT_COUNT:
		if remaining <= 0:
			break
		var slot := slots[slot_index] as MachineSlot
		if slot.is_empty() or str(slot.item.get("id", "")) != item_id:
			continue
		var extracted := slot.extract(remaining)
		remaining -= int(extracted.get("count", 0))
		slot_changed.emit(slot_index)


func _output_has_space(output_id: String, output_count: int) -> bool:
	var output := slots[ASSEMBLY_OUTPUT_SLOT] as MachineSlot
	if output.is_empty():
		return true
	return str(output.item.get("id", "")) == output_id and output.space_for(output_id) >= output_count


func _complete_assembly(recipe: Dictionary) -> void:
	for item_id: String in (recipe.get("inputs", {}) as Dictionary):
		_consume_input(item_id, int(recipe["inputs"][item_id]))
	var output_count := int(recipe.get("output_count", 1))
	var output := slots[ASSEMBLY_OUTPUT_SLOT] as MachineSlot
	var leftover := output.insert(ItemDatabase.create_existing_stack(selected_recipe_id, output_count))
	if not leftover.is_empty():
		last_status = "Output blocked"
		return
	crafts_done += 1
	slot_changed.emit(ASSEMBLY_OUTPUT_SLOT)
	QuestManager.report_event("item_processed", selected_recipe_id, output_count)
	QuestManager.report_event("component_assembled", selected_recipe_id, output_count)


func network_config_data() -> Dictionary:
	var config := super.network_config_data()
	config["selected_recipe_id"] = selected_recipe_id
	return config


func apply_network_config(config: Dictionary) -> void:
	_release_recipe_distribution_claim()
	recipe_distribution_enabled = false
	ingredient_requests_enabled = false
	super.apply_network_config(config)
	var requested_recipe := str(config.get("selected_recipe_id", selected_recipe_id))
	if ASSEMBLY_RECIPES.has(requested_recipe):
		selected_recipe_id = requested_recipe
		process_timer = 0.0
	configure_recipe_distribution(false)
	configure_ingredient_requests(false)


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["selected_recipe_id"] = selected_recipe_id
	data["crafts_done"] = crafts_done
	return data


func from_save_data(data: Dictionary) -> void:
	_release_recipe_distribution_claim()
	recipe_distribution_enabled = false
	ingredient_requests_enabled = false
	super.from_save_data(data)
	var saved_recipe := str(data.get("selected_recipe_id", ""))
	selected_recipe_id = saved_recipe if ASSEMBLY_RECIPES.has(saved_recipe) else ""
	crafts_done = maxi(int(data.get("crafts_done", 0)), 0)
	last_status = "Waiting for ingredients" if not selected_recipe_id.is_empty() else "No recipe selected"
	configure_recipe_distribution(false)
	configure_ingredient_requests(false)


func _refresh_recipe_distribution(force: bool = false) -> void:
	stock_control_waiting_for_priority = false
	if not stock_control_enabled or not ASSEMBLY_RECIPES.has(stock_control_item_id):
		_release_recipe_distribution_claim()
		_reset_recipe_distribution_state()
		stock_control_missing_storage = not stock_control_enabled
		stock_control_blocked = true
		last_status = "Production plan needs a stock target"
		return
	var now := Time.get_ticks_msec()
	if not force and now < _recipe_distribution_next_scan_msec:
		_resolve_recipe_distribution_claim(now)
		return
	_recipe_distribution_next_scan_msec = now + RECIPE_DISTRIBUTION_SCAN_INTERVAL_MSEC
	var previous_group_key := recipe_distribution_group_key
	var snapshot := _logistics_stock_snapshot(stock_control_item_id)
	stock_control_current_count = int(snapshot.get("count", 0))
	stock_control_storage_count = int(snapshot.get("storage_count", 0))
	stock_control_network_nodes = int(snapshot.get("network_nodes", 0))
	stock_control_network_key = str(snapshot.get("network_key", ""))
	recipe_distribution_group_key = _distribution_group_key(snapshot)
	if previous_group_key != recipe_distribution_group_key:
		_release_recipe_distribution_claim(previous_group_key)
	stock_control_missing_storage = not bool(snapshot.get("has_storage", false))
	if stock_control_missing_storage:
		_release_recipe_distribution_claim()
		recipe_distribution_blocked = true
		stock_control_blocked = true
		recipe_distribution_assigned_item_id = ""
		recipe_distribution_order_count = 0
		recipe_distribution_producer_count = 0
		last_status = "No connected output storage"
		return
	stock_control_running = stock_control_current_count < stock_control_target
	_resolve_recipe_distribution_claim(now)


func _resolve_recipe_distribution_claim(now: int) -> void:
	if recipe_distribution_group_key.is_empty():
		return
	var machine_id := get_instance_id()
	var claims := _recipe_distribution_claims.get(recipe_distribution_group_key, {}) as Dictionary
	for claim_id: Variant in claims.keys():
		var claim := claims[claim_id] as Dictionary
		var reference := claim.get("machine_ref") as WeakRef
		if now - int(claim.get("last_seen", 0)) > RECIPE_DISTRIBUTION_CLAIM_TIMEOUT_MSEC \
			or reference == null or reference.get_ref() == null:
			claims.erase(claim_id)
	var rank := _stock_control_rank()
	claims[machine_id] = {
		"machine_id": machine_id,
		"machine_ref": weakref(self),
		"order_item_id": stock_control_item_id,
		"target": stock_control_target,
		"current": stock_control_current_count,
		"priority": stock_control_priority,
		"rank_x": rank.x,
		"rank_y": rank.y,
		"last_seen": now,
	}
	_recipe_distribution_claims[recipe_distribution_group_key] = claims
	var assignments := _build_recipe_distribution_assignments(claims)
	recipe_distribution_order_count = int(assignments.get("order_count", 0))
	recipe_distribution_producer_count = int(assignments.get("producer_count", 0))
	stock_control_registered_producers = claims.size()
	stock_control_active_producers = recipe_distribution_producer_count
	stock_control_producer_limit = recipe_distribution_producer_count
	var machine_assignments := assignments.get("machines", {}) as Dictionary
	var assigned_item_id := str(machine_assignments.get(machine_id, ""))
	_apply_distributed_recipe(assigned_item_id)
	if not _recipe_distribution_reported and recipe_distribution_order_count >= 2 \
		and recipe_distribution_producer_count >= 2:
		_recipe_distribution_reported = true
		QuestManager.report_event("recipe_distribution_configured", "shared", 1)


func _build_recipe_distribution_assignments(claims: Dictionary) -> Dictionary:
	var participants: Array[Dictionary] = []
	var orders: Dictionary = {}
	for value: Variant in claims.values():
		if not value is Dictionary:
			continue
		var claim := value as Dictionary
		participants.append(claim)
		var item_id := str(claim.get("order_item_id", ""))
		if not ASSEMBLY_RECIPES.has(item_id):
			continue
		var order := orders.get(item_id, {
			"item_id": item_id,
			"target": 0,
			"current": 0,
		}) as Dictionary
		order["target"] = maxi(int(order.get("target", 0)), int(claim.get("target", 0)))
		order["current"] = maxi(int(order.get("current", 0)), int(claim.get("current", 0)))
		orders[item_id] = order
	participants.sort_custom(_distribution_claim_before)
	var active_orders: Array[Dictionary] = []
	for order_value: Variant in orders.values():
		var order := order_value as Dictionary
		var target := maxi(int(order.get("target", 0)), 1)
		var current := maxi(int(order.get("current", 0)), 0)
		if current >= target:
			continue
		order["deficit_ratio"] = float(target - current) / float(target)
		order["assigned"] = 0
		active_orders.append(order)
	active_orders.sort_custom(_distribution_order_before)
	var machine_assignments: Dictionary = {}
	var remaining := participants.duplicate()
	for order: Dictionary in active_orders:
		if remaining.is_empty():
			break
		var selected_index := 0
		for index: int in remaining.size():
			if str(remaining[index].get("order_item_id", "")) == str(order.get("item_id", "")):
				selected_index = index
				break
		var producer := remaining.pop_at(selected_index) as Dictionary
		machine_assignments[int(producer.get("machine_id", 0))] = str(order.get("item_id", ""))
		order["assigned"] = int(order.get("assigned", 0)) + 1
	while not remaining.is_empty() and not active_orders.is_empty():
		var best_order := active_orders[0]
		var best_score := -1.0
		for order: Dictionary in active_orders:
			var score := float(order.get("deficit_ratio", 0.0)) / float(int(order.get("assigned", 0)) + 1)
			if score > best_score:
				best_score = score
				best_order = order
		var producer := remaining.pop_front() as Dictionary
		machine_assignments[int(producer.get("machine_id", 0))] = str(best_order.get("item_id", ""))
		best_order["assigned"] = int(best_order.get("assigned", 0)) + 1
	return {
		"machines": machine_assignments,
		"order_count": active_orders.size(),
		"producer_count": machine_assignments.size(),
	}


func _apply_distributed_recipe(item_id: String) -> void:
	recipe_distribution_assigned_item_id = item_id
	recipe_distribution_waiting_for_output = false
	if item_id.is_empty():
		recipe_distribution_blocked = true
		stock_control_blocked = true
		last_status = "Production plan fulfilled"
		return
	if item_id != selected_recipe_id:
		var output := slots[ASSEMBLY_OUTPUT_SLOT] as MachineSlot
		if not output.is_empty() and str(output.item.get("id", "")) != item_id:
			recipe_distribution_waiting_for_output = true
			recipe_distribution_blocked = true
			stock_control_blocked = true
			last_status = "Waiting to switch recipe output"
			return
		selected_recipe_id = item_id
		process_timer = 0.0
		last_status = "Waiting for ingredients"
	recipe_distribution_blocked = false
	stock_control_blocked = false


func _distribution_group_key(snapshot: Dictionary) -> String:
	var ids := Array(snapshot.get("storage_ids", [])).duplicate()
	ids.sort()
	var parts := PackedStringArray()
	for storage_id: Variant in ids:
		parts.append(str(storage_id))
	return ",".join(parts)


func _distribution_claim_before(first: Dictionary, second: Dictionary) -> bool:
	var first_priority := int(first.get("priority", 0))
	var second_priority := int(second.get("priority", 0))
	if first_priority != second_priority:
		return first_priority > second_priority
	var first_y := int(first.get("rank_y", 0))
	var second_y := int(second.get("rank_y", 0))
	if first_y != second_y:
		return first_y < second_y
	return int(first.get("rank_x", 0)) < int(second.get("rank_x", 0))


func _distribution_order_before(first: Dictionary, second: Dictionary) -> bool:
	var first_deficit := float(first.get("deficit_ratio", 0.0))
	var second_deficit := float(second.get("deficit_ratio", 0.0))
	if not is_equal_approx(first_deficit, second_deficit):
		return first_deficit > second_deficit
	return RECIPE_ORDER.find(str(first.get("item_id", ""))) < RECIPE_ORDER.find(str(second.get("item_id", "")))


func _release_recipe_distribution_claim(group_key: String = "") -> void:
	var claim_key := recipe_distribution_group_key if group_key.is_empty() else group_key
	if claim_key.is_empty():
		return
	var claims := _recipe_distribution_claims.get(claim_key, {}) as Dictionary
	claims.erase(get_instance_id())
	if claims.is_empty():
		_recipe_distribution_claims.erase(claim_key)
	else:
		_recipe_distribution_claims[claim_key] = claims


func _reset_recipe_distribution_state() -> void:
	recipe_distribution_blocked = false
	recipe_distribution_waiting_for_output = false
	recipe_distribution_assigned_item_id = ""
	recipe_distribution_order_count = 0
	recipe_distribution_producer_count = 0
	recipe_distribution_group_key = ""


static func normalized_recipes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for output_id: String in RECIPE_ORDER:
		var recipe := ASSEMBLY_RECIPES[output_id] as Dictionary
		var inputs := (recipe.get("inputs", {}) as Dictionary).duplicate(true)
		var first_input := str(inputs.keys()[0]) if not inputs.is_empty() else ""
		result.append({
			"input": first_input,
			"input_count": int(inputs.get(first_input, 1)),
			"inputs": inputs,
			"output": output_id,
			"output_count": int(recipe.get("output_count", 1)),
		})
	return result

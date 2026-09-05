extends Node
class_name MachineContainer

## Emitted whenever a slot's item content changes (not progress bars).
signal slot_changed(slot_index: int)

## Machines tick at a fixed rate instead of every frame: a big base has hundreds
## of containers, and per-frame ticks waste CPU. Machine logic is delta-driven,
## so a coarser tick with a bigger delta produces the same rates. Containers
## that move visuals every frame (conveyors) set tick_interval to 0.0.
const DEFAULT_TICK_INTERVAL := 0.1
const ITEM_OUTPUT_CONTROL_MIN_GAP := 0.05
const STOCK_CONTROL_SCAN_INTERVAL_MSEC := 500
const STOCK_CONTROL_RESUME_RATIO := 0.75
const STOCK_CONTROL_MAX_NETWORK_NODES := 512
const STOCK_CONTROL_CLAIM_TIMEOUT_MSEC := 1200
const STOCK_CONTROL_MAX_ACTIVE_PRODUCERS := 4
const ME_CONNECTION_SCAN_INTERVAL_MSEC := 400
static var _stock_control_claims: Dictionary = {}

## Сон простаивающих машин: у которой нечего делать — тикает в 5 раз реже.
## Логика машин делта-зависима, поэтому редкий тик с крупным delta даёт те же
## скорости производства; сон лишь укрупняет шаг симуляции. Засыпание — после
## IDLE_GRACE секунд простоя подряд (см. is_idle), пробуждение — мгновенно при
## push_item/pull_item (wake) либо самим тиком, когда работа появилась.
const IDLE_TICK_MULTIPLIER := 5.0
const IDLE_GRACE := 2.0
const REMOTE_DISTANCE := 1600.0
const REMOTE_TICK_INTERVAL := 0.5
const MODULE_LIMIT := 3
const MODULE_ITEMS := {
	"speed": "machine_module_speed",
	"efficiency": "machine_module_efficiency",
	"capacity": "machine_module_capacity",
	"productivity": "machine_module_productivity",
}

var slots: Array = []  # Array[MachineSlot]

var tick_interval: float = DEFAULT_TICK_INTERVAL
var _tick_accum := 0.0
var _idle_for := 0.0
var module_levels: Dictionary = {
	"speed": 0,
	"efficiency": 0,
	"capacity": 0,
	"productivity": 0,
}
var simulation_sleeping := false
var last_tick_usec := 0
var _distance_check_timer := 0.0
var _productivity_progress := 0.0
var item_output_control_enabled := false
var item_output_start_below := 0.25
var item_output_stop_above := 0.85
var item_output_control_running := true
var item_output_control_blocked := false
var stock_control_enabled := false
var stock_control_item_id := ""
var stock_control_target := 200
var stock_control_priority := 0
var stock_control_running := true
var stock_control_blocked := false
var stock_control_missing_storage := false
var stock_control_waiting_for_priority := false
var stock_control_current_count := 0
var stock_control_storage_count := 0
var stock_control_network_nodes := 0
var stock_control_network_key := ""
var stock_control_registered_producers := 0
var stock_control_active_producers := 0
var stock_control_producer_limit := 1
var me_automation_connected := false
var me_automation_online := false
var me_automation_interface_pos := Vector2i.ZERO
var me_automation_network_nodes := 0
var me_automation_drive_count := 0
var _stock_control_next_scan_msec := 0
var _me_connection_next_scan_msec := 0
var _last_reported_producer_limit := 1


func _ready() -> void:
	add_to_group("factory_machine")
	# Random phase so all machines on the map don't tick in the same frame.
	_tick_accum = randf() * tick_interval


func _exit_tree() -> void:
	_release_stock_control_claim()


func _process(delta: float) -> void:
	_update_distance_sleep(delta)
	var active_interval := tick_interval
	if simulation_sleeping:
		active_interval = maxf(active_interval, REMOTE_TICK_INTERVAL)
	if active_interval <= 0.0:
		_run_machine_tick(delta)
		return
	_tick_accum += delta
	var interval := active_interval
	if _idle_for >= IDLE_GRACE:
		interval *= IDLE_TICK_MULTIPLIER
	if _tick_accum < interval:
		return
	var step := _tick_accum
	_tick_accum = 0.0
	_run_machine_tick(step)
	if is_idle():
		_idle_for += step
	else:
		_idle_for = 0.0


## Переопределяется наследниками: true = машине сейчас нечего делать и её тик
## можно замедлить. По умолчанию false — генераторы, ME-узлы и всё, у чего нет
## явного признака простоя, тикают с обычной частотой.
func is_idle() -> bool:
	return false


## Сбрасывает накопленный простой — следующий тик пройдёт с обычной частотой.
## Зовётся при внешних событиях (предмет загружен/выгружен), чтобы спящая
## машина отреагировала без задержки.
func wake() -> void:
	_idle_for = 0.0


## Override in subclasses to implement machine logic.
func tick(_delta: float) -> void:
	pass


func automation_allows_tick() -> bool:
	# Machines have no internal automation controls. External logistics decides
	# when to insert ingredients and extract results; ME automation is owned by an
	# adjacent Interface containing an encoded processing pattern.
	return true


func on_automation_blocked() -> void:
	pass


func has_item_output_control() -> bool:
	for slot: MachineSlot in slots:
		if slot.role == MachineSlot.Role.OUTPUT:
			return true
	return false


func automation_requires_me_connection() -> bool:
	return item_output_control_enabled or stock_control_enabled


## Refreshes the physical automation link. A regular machine is connected only
## when an online ME Interface touches its footprint; a bare cable is not a bus.
func refresh_me_automation_connection(force: bool = false) -> void:
	if not is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if not force and now < _me_connection_next_scan_msec:
		return
	_me_connection_next_scan_msec = now + ME_CONNECTION_SCAN_INTERVAL_MSEC
	var owner_block := get_parent() as WorldBlock
	var manager := get_tree().get_first_node_in_group("me_network")
	if owner_block == null or manager == null or not manager.has_method("connection_for_machine"):
		_clear_me_automation_connection()
		return
	var connection: Dictionary = manager.connection_for_machine(owner_block)
	me_automation_connected = bool(connection.get("connected", false))
	me_automation_online = bool(connection.get("online", false))
	me_automation_interface_pos = connection.get("interface_pos", Vector2i.ZERO)
	me_automation_network_nodes = int(connection.get("network_nodes", 0))
	me_automation_drive_count = int(connection.get("drive_count", 0))


func me_automation_status() -> String:
	refresh_me_automation_connection()
	if not me_automation_connected:
		return "disconnected"
	if not me_automation_online:
		return "offline"
	if me_automation_drive_count <= 0:
		return "no_storage"
	return "online"


func _clear_me_automation_connection() -> void:
	me_automation_connected = false
	me_automation_online = false
	me_automation_interface_pos = Vector2i.ZERO
	me_automation_network_nodes = 0
	me_automation_drive_count = 0


func configure_item_output_control(enabled: bool, start_below: float, stop_above: float) -> void:
	item_output_control_enabled = enabled and has_item_output_control()
	item_output_stop_above = clampf(stop_above, ITEM_OUTPUT_CONTROL_MIN_GAP, 1.0)
	item_output_start_below = clampf(start_below, 0.0, item_output_stop_above - ITEM_OUTPUT_CONTROL_MIN_GAP)
	_update_item_output_control_state()
	_me_connection_next_scan_msec = 0
	refresh_me_automation_connection(true)
	wake()


func item_output_fill_ratio() -> float:
	var ratio := 0.0
	for slot: MachineSlot in slots:
		if slot.role != MachineSlot.Role.OUTPUT or slot.is_empty():
			continue
		var capacity := slot.max_stack_override
		if capacity <= 0:
			capacity = int(slot.item.get("max_stack", 64))
		ratio = maxf(ratio, float(slot.item.get("count", 0)) / maxf(float(capacity), 1.0))
	return clampf(ratio, 0.0, 1.0)


func configure_stock_control(enabled: bool, item_id: String, target: int, priority: int = 0) -> void:
	_release_stock_control_claim()
	stock_control_enabled = enabled and has_item_output_control() and not item_id.is_empty()
	stock_control_item_id = item_id if stock_control_enabled else ""
	stock_control_target = clampi(target, 1, 9999)
	stock_control_priority = clampi(priority, -1, 1)
	_stock_control_next_scan_msec = 0
	_me_connection_next_scan_msec = 0
	if is_inside_tree():
		refresh_stock_control(true)
	else:
		stock_control_missing_storage = false
		stock_control_blocked = stock_control_enabled and not stock_control_running
	wake()


func refresh_stock_control(force: bool = false) -> void:
	if not stock_control_enabled:
		stock_control_running = true
		stock_control_blocked = false
		stock_control_missing_storage = false
		stock_control_waiting_for_priority = false
		stock_control_current_count = 0
		stock_control_storage_count = 0
		stock_control_network_nodes = 0
		stock_control_network_key = ""
		stock_control_registered_producers = 0
		stock_control_active_producers = 0
		stock_control_producer_limit = 1
		_release_stock_control_claim()
		return
	if not is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if not force and now < _stock_control_next_scan_msec:
		_refresh_stock_control_claim(now)
		return
	_stock_control_next_scan_msec = now + STOCK_CONTROL_SCAN_INTERVAL_MSEC
	var previous_network_key := stock_control_network_key
	refresh_me_automation_connection(true)
	var snapshot := _me_stock_snapshot(stock_control_item_id)
	stock_control_current_count = int(snapshot.get("count", 0))
	stock_control_storage_count = int(snapshot.get("storage_count", 0))
	stock_control_network_nodes = int(snapshot.get("network_nodes", 0))
	var next_network_key := str(snapshot.get("network_key", ""))
	if previous_network_key != next_network_key:
		_release_stock_control_claim(previous_network_key)
	stock_control_network_key = next_network_key
	stock_control_missing_storage = not bool(snapshot.get("has_storage", false))
	if not bool(snapshot.get("connected", false)) \
		or not bool(snapshot.get("online", false)) \
		or stock_control_missing_storage:
		stock_control_running = false
		stock_control_blocked = true
		stock_control_waiting_for_priority = false
		_release_stock_control_claim()
		return
	var resume_count := floori(float(stock_control_target) * STOCK_CONTROL_RESUME_RATIO)
	if stock_control_running and stock_control_current_count >= stock_control_target:
		stock_control_running = false
	elif not stock_control_running and stock_control_current_count <= resume_count:
		stock_control_running = true
	_refresh_stock_control_claim(now)


func _me_stock_snapshot(item_id: String) -> Dictionary:
	var owner_block := get_parent() as WorldBlock
	var manager := get_tree().get_first_node_in_group("me_network")
	if owner_block != null and manager != null and manager.has_method("machine_stock_snapshot"):
		return manager.machine_stock_snapshot(owner_block, item_id)
	return {
		"connected": false,
		"online": false,
		"count": 0,
		"has_storage": false,
		"storage_count": 0,
		"network_nodes": 0,
		"network_key": "",
	}


func install_module(module_type: String) -> bool:
	if not module_levels.has(module_type) or int(module_levels[module_type]) >= MODULE_LIMIT:
		return false
	module_levels[module_type] = int(module_levels[module_type]) + 1
	wake()
	notify_network_config_changed()
	QuestManager.report_event("module_installed", module_type, 1)
	return true


func remove_module(module_type: String) -> bool:
	if not module_levels.has(module_type) or int(module_levels[module_type]) <= 0:
		return false
	module_levels[module_type] = int(module_levels[module_type]) - 1
	wake()
	notify_network_config_changed()
	return true


func get_module_level(module_type: String) -> int:
	return int(module_levels.get(module_type, 0))


func processing_speed_multiplier() -> float:
	return 1.0 + 0.20 * get_module_level("speed")


func energy_use_multiplier() -> float:
	return maxf(0.45, 1.0 - 0.15 * get_module_level("efficiency") + 0.10 * get_module_level("speed"))


func capacity_multiplier() -> float:
	return 1.0 + 0.35 * get_module_level("capacity")


func productivity_bonus() -> float:
	return 0.08 * get_module_level("productivity")


func module_summary() -> String:
	return "Speed +%d%%  •  Energy %d%%  •  Capacity +%d%%  •  Bonus +%d%%" % [
		roundi((processing_speed_multiplier() - 1.0) * 100.0),
		roundi(energy_use_multiplier() * 100.0),
		roundi((capacity_multiplier() - 1.0) * 100.0),
		roundi(productivity_bonus() * 100.0),
	]


func network_config_data() -> Dictionary:
	return {
		"modules": module_levels.duplicate(true),
	}


func apply_network_config(config: Dictionary) -> void:
	var modules_value: Variant = config.get("modules", {})
	if modules_value is Dictionary:
		var modules := modules_value as Dictionary
		for module_type: String in MODULE_ITEMS:
			module_levels[module_type] = clampi(int(modules.get(module_type, module_levels[module_type])), 0, MODULE_LIMIT)
	_clear_legacy_automation_settings()
	wake()


func notify_network_config_changed() -> void:
	if not MultiplayerManager.is_active():
		return
	var block := get_parent() as WorldBlock
	if block != null:
		MultiplayerManager.submit_machine_config(block.grid_pos, network_config_data())


func _run_machine_tick(delta: float) -> void:
	if not automation_allows_tick():
		on_automation_blocked()
		last_tick_usec = 0
		return
	var output_before := _output_counts()
	var power_before := module_power_level()
	var started := Time.get_ticks_usec()
	tick(delta * processing_speed_multiplier())
	last_tick_usec = Time.get_ticks_usec() - started
	apply_module_energy_rebate(power_before)
	_apply_productivity(output_before)


func module_power_level() -> float:
	return -1.0


func apply_module_energy_rebate(_power_before: float) -> void:
	pass


func _output_counts() -> Dictionary:
	var result: Dictionary = {}
	for index in slots.size():
		var slot: MachineSlot = slots[index]
		if slot.role == MachineSlot.Role.OUTPUT and not slot.is_empty():
			result[index] = int(slot.item.get("count", 0))
	return result


func _apply_productivity(before: Dictionary) -> void:
	var bonus := productivity_bonus()
	if bonus <= 0.0:
		return
	for index in slots.size():
		var slot: MachineSlot = slots[index]
		if slot.role != MachineSlot.Role.OUTPUT or slot.is_empty():
			continue
		var produced := int(slot.item.get("count", 0)) - int(before.get(index, 0))
		if produced <= 0:
			continue
		_productivity_progress += float(produced) * bonus
		var extra := floori(_productivity_progress)
		if extra <= 0:
			continue
		_productivity_progress -= extra
		var extra_stack := slot.item.duplicate(true)
		extra_stack["count"] = extra
		slot.insert(extra_stack)
		slot_changed.emit(index)


func _update_distance_sleep(delta: float) -> void:
	_distance_check_timer -= delta
	if _distance_check_timer > 0.0:
		return
	_distance_check_timer = 1.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var owner_block := get_parent() as Node2D
	simulation_sleeping = player != null and owner_block != null and owner_block.global_position.distance_squared_to(player.global_position) > REMOTE_DISTANCE * REMOTE_DISTANCE


# ── Automation API ────────────────────────────────────────────────────────────
# These are the only entry-points belts / pipes / arms should use.

## Push a stack into slot_idx. Returns the leftover (empty = fully consumed).
## Respects slot roles: cannot push into OUTPUT slots.
func push_item(slot_idx: int, stack: Dictionary) -> Dictionary:
	if not _valid(slot_idx):
		return stack
	var s: MachineSlot = slots[slot_idx]
	if s.role == MachineSlot.Role.OUTPUT:
		return stack
	var before := int(stack.get("count", 0))
	var leftover := s.insert(stack)
	# Будим машину только если что-то реально вошло: конвейер, упирающийся в
	# полный вход, не должен держать заблокированную машину бодрствующей.
	if int(leftover.get("count", 0)) < before:
		wake()
	slot_changed.emit(slot_idx)
	return leftover

## Pull up to `amount` items from slot_idx. Returns what was taken.
## Respects slot roles: cannot pull from INPUT slots.
func pull_item(slot_idx: int, amount: int = 64) -> Dictionary:
	if not _valid(slot_idx):
		return {}
	var s: MachineSlot = slots[slot_idx]
	if s.role == MachineSlot.Role.INPUT:
		return {}
	var result := s.extract(amount)
	if not result.is_empty():
		wake()  # выход освободился — заблокированная машина может продолжить
		automation_allows_tick()
		slot_changed.emit(slot_idx)
	return result

## Returns the best slot index to push item_id into, or -1 if none accepts it.
func find_input_slot_for(item_id: String) -> int:
	# Prefer a non-empty slot with the same item first (stack consolidation)
	for i in slots.size():
		var s: MachineSlot = slots[i]
		if s.role in [MachineSlot.Role.INPUT, MachineSlot.Role.BUFFER, MachineSlot.Role.FUEL]:
			if not s.is_empty() and s.item.get("id") == item_id and s.space_for(item_id) > 0:
				return i
	# Then any empty compatible slot
	for i in slots.size():
		var s: MachineSlot = slots[i]
		if s.role in [MachineSlot.Role.INPUT, MachineSlot.Role.BUFFER, MachineSlot.Role.FUEL]:
			if s.is_empty() and s.accepts(item_id):
				return i
	return -1

## Returns the first non-empty OUTPUT slot index, or -1.
func find_output_slot() -> int:
	for i in slots.size():
		if slots[i].role == MachineSlot.Role.OUTPUT and not slots[i].is_empty():
			return i
	return -1


## Push every OUTPUT slot into the block on a machine's facing side. Processing
## machines call this from tick(); belts never pull, so the producer owns output.
func eject_outputs_to(source_grid_pos: Vector2i, facing: int, distance: int = 1) -> void:
	if not is_inside_tree():
		return
	var wim: Node = get_tree().get_first_node_in_group("world_interaction")
	if wim == null or not wim.has_method("get_block_at"):
		return
	var direction := WorldBlock.FACING_DIRS[((facing % 4) + 4) % 4]
	var target_tile := source_grid_pos + direction * maxi(distance, 1)
	var block := wim.get_block_at(target_tile) as WorldBlock
	if block == null:
		return
	for index: int in slots.size():
		var slot: MachineSlot = slots[index]
		if slot.role != MachineSlot.Role.OUTPUT or slot.is_empty():
			continue
		var before := int(slot.item.get("count", 0))
		var leftover := _push_output_stack(block, slot.peek())
		if int(leftover.get("count", 0)) == before:
			continue
		slot.item = leftover
		slot_changed.emit(index)
		wake()


func _push_output_stack(block: WorldBlock, stack: Dictionary) -> Dictionary:
	if block.machine is ConveyorContainer:
		return (block.machine as ConveyorContainer).try_accept(stack)
	if block.chest_inventory != null:
		var left: Variant = block.chest_inventory.push_item(stack)
		return left if left is Dictionary else {}
	if block.machine != null:
		var input_index := block.machine.find_input_slot_for(str(stack.get("id", "")))
		if input_index >= 0:
			return block.machine.push_item(input_index, stack)
	return stack


# ── Serialization ─────────────────────────────────────────────────────────────

func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for i in slots.size():
		if not slots[i].is_empty():
			data[str(i)] = slots[i].to_save_data()
	data["modules"] = module_levels.duplicate(true)
	data["productivity_progress"] = _productivity_progress
	return data

func from_save_data(data: Dictionary) -> void:
	for i in slots.size():
		slots[i].from_save_data(data.get(str(i), {}))
	var saved_modules: Variant = data.get("modules", {})
	if saved_modules is Dictionary:
		for module_type: String in MODULE_ITEMS:
			module_levels[module_type] = clampi(int(saved_modules.get(module_type, 0)), 0, MODULE_LIMIT)
	_productivity_progress = clampf(float(data.get("productivity_progress", 0.0)), 0.0, 0.999)
	_clear_legacy_automation_settings()


## Migration for saves made while automation settings lived inside every
## machine. They are intentionally ignored so an old hidden toggle cannot leave
## a machine permanently stopped after the UI has been removed.
func _clear_legacy_automation_settings() -> void:
	_release_stock_control_claim()
	item_output_control_enabled = false
	item_output_control_running = true
	item_output_control_blocked = false
	stock_control_enabled = false
	stock_control_item_id = ""
	stock_control_running = true
	stock_control_blocked = false
	stock_control_missing_storage = false
	stock_control_waiting_for_priority = false
	stock_control_network_key = ""


func _update_item_output_control_state() -> void:
	if not item_output_control_enabled or not has_item_output_control():
		item_output_control_running = true
		item_output_control_blocked = false
		return
	var fill_ratio := item_output_fill_ratio()
	if item_output_control_running and fill_ratio >= item_output_stop_above:
		item_output_control_running = false
	elif not item_output_control_running and fill_ratio <= item_output_start_below:
		item_output_control_running = true
	item_output_control_blocked = not item_output_control_running


func _apply_item_output_control_data(data: Dictionary) -> void:
	configure_item_output_control(
		bool(data.get("item_output_control_enabled", false)),
		float(data.get("item_output_start_below", 0.25)),
		float(data.get("item_output_stop_above", 0.85))
	)
	var fill_ratio := item_output_fill_ratio()
	if item_output_control_enabled and fill_ratio > item_output_start_below and fill_ratio < item_output_stop_above:
		item_output_control_running = bool(data.get("item_output_control_running", item_output_control_running))
		item_output_control_blocked = not item_output_control_running


func _apply_stock_control_data(data: Dictionary) -> void:
	stock_control_enabled = bool(data.get("stock_control_enabled", false)) and has_item_output_control()
	stock_control_item_id = str(data.get("stock_control_item_id", "")) if stock_control_enabled else ""
	stock_control_target = clampi(int(data.get("stock_control_target", 200)), 1, 9999)
	stock_control_priority = clampi(int(data.get("stock_control_priority", 0)), -1, 1)
	stock_control_running = bool(data.get("stock_control_running", true))
	stock_control_blocked = stock_control_enabled and not stock_control_running
	stock_control_missing_storage = false
	stock_control_waiting_for_priority = false
	stock_control_network_key = ""
	_stock_control_next_scan_msec = 0
	if stock_control_enabled and stock_control_item_id.is_empty():
		stock_control_enabled = false
		stock_control_running = true
		stock_control_blocked = false
	elif is_inside_tree():
		refresh_stock_control(true)


func _logistics_stock_snapshot(item_id: String) -> Dictionary:
	var owner_block := get_parent() as WorldBlock
	var result := {
		"count": 0,
		"has_storage": false,
		"storage_count": 0,
		"network_nodes": 0,
		"storage_ids": [],
		"network_key": "",
	}
	if owner_block == null:
		return result
	var manager := get_tree().get_first_node_in_group("world_interaction")
	if manager == null or not manager.has_method("get_block_at"):
		return result
	var owner_tiles: Dictionary = {}
	for tile: Vector2i in owner_block.footprint():
		owner_tiles[tile] = true
	var queue: Array[WorldBlock] = []
	var visited: Dictionary = {}
	for tile: Vector2i in owner_block.footprint():
		for direction: Vector2i in WorldBlock.FACING_DIRS:
			var neighbor := manager.get_block_at(tile + direction) as WorldBlock
			if neighbor == null or neighbor == owner_block or not is_instance_valid(neighbor):
				continue
			if neighbor.chest_inventory == null:
				if _is_logistics_output_from(neighbor, owner_tiles, item_id):
					queue.append(neighbor)
			else:
				_count_stock_storage(neighbor, item_id, result, visited)
	while not queue.is_empty() and visited.size() < STOCK_CONTROL_MAX_NETWORK_NODES:
		var block := queue.pop_front() as WorldBlock
		if block == null or not is_instance_valid(block):
			continue
		var key := block.get_instance_id()
		if visited.has(key):
			continue
		visited[key] = true
		result["network_nodes"] = int(result["network_nodes"]) + 1
		for target_pos: Vector2i in _logistics_output_positions(block, item_id):
			var target := manager.get_block_at(target_pos) as WorldBlock
			if target == null or target == owner_block or not is_instance_valid(target):
				continue
			if target.chest_inventory != null:
				_count_stock_storage(target, item_id, result, visited)
			elif target.machine is ConveyorContainer or target.machine is MechanicalInserterContainer:
				queue.append(target)
	var storage_ids := result["storage_ids"] as Array
	storage_ids.sort()
	var key_parts := PackedStringArray()
	for storage_id: Variant in storage_ids:
		key_parts.append(str(storage_id))
	result["network_key"] = "%s|%s" % [item_id, ",".join(key_parts)] if not storage_ids.is_empty() else ""
	return result


func _is_logistics_output_from(block: WorldBlock, source_tiles: Dictionary, item_id: String) -> bool:
	if block.machine is MechanicalInserterContainer:
		var inserter := block.machine as MechanicalInserterContainer
		return inserter.enabled and inserter.accepts_item(item_id) \
			and source_tiles.has(inserter.source_grid_pos - WorldBlock.FACING_DIRS[inserter.facing])
	if block.machine is ConveyorContainer:
		var conveyor := block.machine as ConveyorContainer
		return conveyor.accepts_item(item_id) \
			and source_tiles.has(conveyor.source_grid_pos - WorldBlock.FACING_DIRS[conveyor.facing])
	return false


func _logistics_output_positions(block: WorldBlock, item_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if block.machine is MechanicalInserterContainer:
		var inserter := block.machine as MechanicalInserterContainer
		if inserter.enabled and inserter.accepts_item(item_id):
			result.append(inserter.source_grid_pos + WorldBlock.FACING_DIRS[inserter.facing])
	elif block.machine is ConveyorSplitterContainer:
		var splitter := block.machine as ConveyorSplitterContainer
		if splitter.accepts_item(item_id):
			for direction: int in [(splitter.facing + 3) % 4, (splitter.facing + 1) % 4]:
				if splitter._output_accepts(direction, item_id):
					result.append(splitter.source_grid_pos + WorldBlock.FACING_DIRS[direction])
	elif block.machine is ConveyorContainer:
		var conveyor := block.machine as ConveyorContainer
		if conveyor.accepts_item(item_id):
			result.append(conveyor.source_grid_pos + WorldBlock.FACING_DIRS[conveyor.facing])
	return result


func _count_stock_storage(
	block: WorldBlock,
	item_id: String,
	result: Dictionary,
	visited: Dictionary
) -> void:
	var key := block.get_instance_id()
	if visited.has(key) or block.chest_inventory == null:
		return
	visited[key] = true
	result["has_storage"] = true
	result["storage_count"] = int(result["storage_count"]) + 1
	(result["storage_ids"] as Array).append(key)
	for slot_index: int in block.chest_inventory.get_slot_count():
		var value: Variant = block.chest_inventory.get_slot_data_at(slot_index)
		if value is Dictionary and str((value as Dictionary).get("id", "")) == item_id:
			result["count"] = int(result["count"]) + int((value as Dictionary).get("count", 0))


func _refresh_stock_control_claim(now: int) -> void:
	stock_control_waiting_for_priority = false
	if not stock_control_running or stock_control_network_key.is_empty():
		stock_control_blocked = not stock_control_running
		stock_control_registered_producers = 0
		stock_control_active_producers = 0
		stock_control_producer_limit = 1
		_release_stock_control_claim()
		return
	var machine_id := get_instance_id()
	var claims := _stock_control_claims.get(stock_control_network_key, {}) as Dictionary
	for claim_id: Variant in claims.keys():
		var claim := claims[claim_id] as Dictionary
		if now - int(claim.get("last_seen", 0)) > STOCK_CONTROL_CLAIM_TIMEOUT_MSEC:
			claims.erase(claim_id)
	var rank := _stock_control_rank()
	claims[machine_id] = {
		"machine_id": machine_id,
		"priority": stock_control_priority,
		"rank_x": rank.x,
		"rank_y": rank.y,
		"target": stock_control_target,
		"last_seen": now,
	}
	_stock_control_claims[stock_control_network_key] = claims
	var ordered: Array[Dictionary] = []
	var effective_target := stock_control_target
	for claim_value: Variant in claims.values():
		if claim_value is Dictionary:
			var claim := claim_value as Dictionary
			ordered.append(claim)
			effective_target = maxi(effective_target, int(claim.get("target", effective_target)))
	ordered.sort_custom(_stock_claim_before)
	stock_control_producer_limit = _producer_limit_for_deficit(effective_target, stock_control_current_count)
	stock_control_registered_producers = ordered.size()
	stock_control_active_producers = mini(stock_control_producer_limit, stock_control_registered_producers)
	var producer_rank := ordered.size()
	for index: int in ordered.size():
		if int(ordered[index].get("machine_id", 0)) == machine_id:
			producer_rank = index
			break
	stock_control_waiting_for_priority = producer_rank >= stock_control_producer_limit
	stock_control_blocked = stock_control_waiting_for_priority
	if stock_control_producer_limit > _last_reported_producer_limit:
		_last_reported_producer_limit = stock_control_producer_limit
		if stock_control_producer_limit >= 2:
			QuestManager.report_event("stock_producer_scaling", "multi", 1)


func _stock_claim_before(first: Dictionary, second: Dictionary) -> bool:
	var first_priority := int(first.get("priority", 0))
	var second_priority := int(second.get("priority", 0))
	if first_priority != second_priority:
		return first_priority > second_priority
	var first_y := int(first.get("rank_y", 0))
	var second_y := int(second.get("rank_y", 0))
	if first_y != second_y:
		return first_y < second_y
	return int(first.get("rank_x", 0)) < int(second.get("rank_x", 0))


func _producer_limit_for_deficit(target: int, current_count: int) -> int:
	var deficit_ratio := float(maxi(target - current_count, 0)) / maxf(float(target), 1.0)
	if deficit_ratio > 0.75:
		return 4
	if deficit_ratio > 0.50:
		return 3
	if deficit_ratio > 0.25:
		return 2
	return 1


func _stock_control_rank() -> Vector2i:
	var owner_block := get_parent() as WorldBlock
	return owner_block.grid_pos if owner_block != null else Vector2i.ZERO


func _release_stock_control_claim(network_key: String = "") -> void:
	var claim_key := stock_control_network_key if network_key.is_empty() else network_key
	if claim_key.is_empty():
		return
	var claims := _stock_control_claims.get(claim_key, {}) as Dictionary
	claims.erase(get_instance_id())
	if claims.is_empty():
		_stock_control_claims.erase(claim_key)
	else:
		_stock_control_claims[claim_key] = claims


# ── Internal ──────────────────────────────────────────────────────────────────

func _valid(idx: int) -> bool:
	return idx >= 0 and idx < slots.size()

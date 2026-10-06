# res://core/systems/me/MENetworkManager.gd
## Discovers ME networks (controller + cables + drives + terminals, all adjacent)
## and exposes an aggregated storage API for terminals and drives.
## Channels are intentionally unlimited — connectivity is all that matters.
extends Node
class_name MENetworkManager

const ME_BLOCK_IDS: Dictionary = {
	"me_controller": true,
	"me_cable": true,
	"me_drive": true,
	"me_terminal": true,
	"me_crafting_terminal": true,
	"me_pattern_terminal": true,
	"me_import_bus": true,
	"me_export_bus": true,
	"me_interface": true,
	"me_molecular_assembler": true,
}

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]

const SERVICE_INTERVAL := 0.4   # seconds between bus item moves
const MOVE_AMOUNT := 64         # items moved per bus per service
const WIRELESS_RANGE_TILES := 24.0
const MOVE_LITERS := 50.0       # liters moved per bus per service

var _wim: Node = null
var _networks: Array = []              # connected components, storage and automation devices
var _block_to_net: Dictionary = {}     # grid_pos -> index into _networks
var _service_accum: float = 0.0
var wireless_sessions: Dictionary = {}


func _ready() -> void:
	add_to_group("me_network")
	_wim = get_tree().get_first_node_in_group("world_interaction")


func _process(delta: float) -> void:
	if _wim == null:
		_wim = get_tree().get_first_node_in_group("world_interaction")
		return
	_rebuild()
	_service_accum += delta
	if _service_accum >= SERVICE_INTERVAL:
		_service_accum = 0.0
		_service_buses()


func _rebuild() -> void:
	_networks.clear()
	_block_to_net.clear()
	var placed: Dictionary = _wim._placed_blocks
	var visited: Dictionary = {}

	for start_pos: Vector2i in placed.keys():
		if visited.has(start_pos):
			continue
		var start_blk: WorldBlock = placed.get(start_pos) as WorldBlock
		if start_blk == null or not ME_BLOCK_IDS.has(start_blk.block_id):
			continue

		# Flood-fill one ME component.
		var drives: Array = []
		var buses: Array = []
		var interfaces: Array = []
		var pattern_terminals: Array = []
		var crafting_terminals: Array = []
		var assemblers: Array = []
		var online := false
		var controllers: Array[WorldBlock] = []
		var queue: Array[Vector2i] = [start_pos]
		visited[start_pos] = true
		var members: Array[Vector2i] = []

		while not queue.is_empty():
			var cur: Vector2i = queue.pop_front()
			members.append(cur)
			var blk: WorldBlock = placed.get(cur) as WorldBlock
			if blk != null:
				if blk.machine is MEDriveContainer:
					drives.append(blk)
				elif blk.machine is MEInterfaceContainer:
					interfaces.append(blk)
				elif blk.machine is MEPatternTerminalContainer:
					pattern_terminals.append(blk)
				elif blk.machine is MECraftingTerminalContainer:
					crafting_terminals.append(blk)
				elif blk.machine is MEAssemblerContainer:
					assemblers.append(blk)
				elif blk.machine is MEBusContainer:
					buses.append(blk)
				elif blk.machine is MEControllerContainer:
					controllers.append(blk)
					online = online or (blk.machine as MEControllerContainer).is_online()
			for dir: Vector2i in DIRS:
				var npos: Vector2i = cur + dir
				if visited.has(npos):
					continue
				var nblk: WorldBlock = placed.get(npos) as WorldBlock
				if nblk == null or not ME_BLOCK_IDS.has(nblk.block_id):
					continue
				visited[npos] = true
				queue.append(npos)

		var net_index := _networks.size()
		interfaces.sort_custom(func(first: WorldBlock, second: WorldBlock) -> bool:
			return (first.machine as MEInterfaceContainer).priority \
				> (second.machine as MEInterfaceContainer).priority
		)
		_networks.append({
			"online": online,
			"controllers": controllers,
			"members": members,
			"drives": drives,
			"buses": buses,
			"interfaces": interfaces,
			"pattern_terminals": pattern_terminals,
			"crafting_terminals": crafting_terminals,
			"assemblers": assemblers,
		})
		for pos: Vector2i in members:
			_block_to_net[pos] = net_index
		_update_energy(_networks[net_index])


func _update_energy(network: Dictionary) -> void:
	var demand := MEControllerContainer.IDLE_DRAIN
	var active_workers: Dictionary = {}
	for terminal: WorldBlock in network.get("crafting_terminals", []):
		for job: Dictionary in (terminal.machine as MECraftingTerminalContainer).jobs:
			if not MECraftingTerminalContainer.is_active(job):
				continue
			for batch: Dictionary in job.get("running", []):
				if str(batch["kind"]) == "craft":
					active_workers[MECraftingService.position(batch["machine"])] = true
	for pos: Vector2i in network.get("members", []):
		var block := _wim._placed_blocks.get(pos) as WorldBlock
		if block == null:
			continue
		if block.machine is MEAssemblerContainer:
			var worker := block.machine as MEAssemblerContainer
			var active := active_workers.has(pos) or (not worker.recipe_id.is_empty() and worker.last_status == "crafting")
			demand += (9.0 if active else 1.0) * worker.energy_use_multiplier()
		elif block.machine is MEBusContainer:
			var bus := block.machine as MEBusContainer
			demand += (2.0 * bus.transfer_multiplier() if bus.last_service_active else 0.5) * bus.energy_use_multiplier()
		elif block.block_id != "me_controller":
			demand += 0.1 if block.block_id == "me_cable" else 1.0
	for pos: Vector2i in wireless_sessions.values():
		if pos in network.get("members", []):
			demand += 4.0
	var controllers: Array = network.get("controllers", [])
	var powered := 0
	for block: WorldBlock in controllers:
		if (block.machine as MEControllerContainer).is_online():
			powered += 1
	var effective := 0.0
	for block: WorldBlock in controllers:
		var controller := block.machine as MEControllerContainer
		controller.network_drain = demand / maxi(powered, 1)
		if controller.is_online():
			effective += controller.network_drain * controller.energy_use_multiplier()
	network["energy_demand"] = effective if powered > 0 else demand


func energy_demand_at(grid_pos: Vector2i) -> float:
	return float(_network_at(grid_pos).get("energy_demand", 0.0))


## Handheld access uses the nearest powered controller with an installed terminal.
## The chosen controller is kept for the whole session, including range checks.
func wireless_terminal_for(world_pos: Vector2) -> Dictionary:
	var result: Dictionary = {}
	var nearest := WIRELESS_RANGE_TILES * GameConstants.TILE_SIZE + 0.001
	for network: Dictionary in _networks:
		if not bool(network.get("online", false)):
			continue
		var terminal: WorldBlock = null
		for pos: Vector2i in network["members"]:
			var block := _wim._placed_blocks.get(pos) as WorldBlock
			if block != null and block.block_id in ["me_terminal", "me_crafting_terminal"]:
				terminal = block
				if block.block_id == "me_crafting_terminal":
					break
		if terminal == null:
			continue
		for controller: WorldBlock in network.get("controllers", []):
			var distance := world_pos.distance_to((Vector2(controller.grid_pos) + Vector2(0.5, 0.5)) * GameConstants.TILE_SIZE)
			if distance < nearest and (controller.machine as MEControllerContainer).is_online():
				nearest = distance
				result = {"terminal": terminal, "controller": controller}
	return result


func wireless_connection_valid(controller: WorldBlock, terminal: WorldBlock, world_pos: Vector2) -> bool:
	return is_instance_valid(controller) and is_instance_valid(terminal) \
		and _wim._placed_blocks.get(controller.grid_pos) == controller \
		and _wim._placed_blocks.get(terminal.grid_pos) == terminal \
		and is_same(_network_at(controller.grid_pos), _network_at(terminal.grid_pos)) \
		and world_pos.distance_to((Vector2(controller.grid_pos) + Vector2(0.5, 0.5)) * GameConstants.TILE_SIZE) <= WIRELESS_RANGE_TILES * GameConstants.TILE_SIZE


func _network_at(grid_pos: Vector2i) -> Dictionary:
	if _block_to_net.has(grid_pos):
		return _networks[_block_to_net[grid_pos]]
	return {}


func is_online_at(grid_pos: Vector2i) -> bool:
	var net := _network_at(grid_pos)
	return bool(net.get("online", false))


## Returns the ME gateway touching a normal machine. Merely running a cable next
## to a machine is not enough: automation becomes available through an Interface,
## mirroring the pattern-provider boundary used by AE-style logistics systems.
func connection_for_machine(machine_block: WorldBlock) -> Dictionary:
	var disconnected := {
		"connected": false,
		"online": false,
		"interface": null,
		"interface_pos": Vector2i.ZERO,
		"network_nodes": 0,
		"drive_count": 0,
	}
	if machine_block == null or _wim == null:
		return disconnected
	var best := disconnected
	var best_priority := -2147483648
	var checked: Dictionary = {}
	for tile: Vector2i in machine_block.footprint():
		for dir: Vector2i in DIRS:
			var pos := tile + dir
			if checked.has(pos):
				continue
			checked[pos] = true
			var candidate: WorldBlock = _wim._placed_blocks.get(pos) as WorldBlock
			if candidate == null or not (candidate.machine is MEInterfaceContainer):
				continue
			var net := _network_at(candidate.grid_pos)
			if net.is_empty():
				continue
			var candidate_priority := (candidate.machine as MEInterfaceContainer).priority
			var candidate_online := bool(net.get("online", false))
			var best_online := bool(best.get("online", false))
			if best.get("connected", false) and best_online and not candidate_online:
				continue
			if best.get("connected", false) and best_online == candidate_online \
				and candidate_priority <= best_priority:
				continue
			best_priority = candidate_priority
			best = {
				"connected": true,
				"online": candidate_online,
				"interface": candidate,
				"interface_pos": candidate.grid_pos,
				"network_nodes": (net.get("members", []) as Array).size(),
				"drive_count": (net.get("drives", []) as Array).size(),
			}
	return best


## Snapshot consumed by normal machine automation and its compact UI.
func machine_stock_snapshot(machine_block: WorldBlock, item_id: String) -> Dictionary:
	var connection := connection_for_machine(machine_block)
	var result := {
		"connected": bool(connection.get("connected", false)),
		"online": bool(connection.get("online", false)),
		"count": 0,
		"has_storage": int(connection.get("drive_count", 0)) > 0,
		"storage_count": int(connection.get("drive_count", 0)),
		"network_nodes": int(connection.get("network_nodes", 0)),
		"network_key": "",
		"interface_pos": connection.get("interface_pos", Vector2i.ZERO),
	}
	if not bool(result["connected"]):
		return result
	var interface_pos: Vector2i = result["interface_pos"]
	if not item_id.is_empty():
		result["count"] = int(list_items(interface_pos).get(item_id, 0))
	result["network_key"] = "me:%d:%s" % [
		int(_block_to_net.get(interface_pos, -1)), item_id,
	]
	return result


## Aggregated { item_id: count } across every cell in the network.
func list_items(grid_pos: Vector2i) -> Dictionary:
	var totals: Dictionary = {}
	var net := _network_at(grid_pos)
	for drive_value: Variant in net.get("drives", []):
		var drive: WorldBlock = drive_value
		for cell_value: Variant in (drive.machine as MEDriveContainer).get_cells():
			var contents: Dictionary = MEStorageCell.contents_of(cell_value)
			for item_id_value: Variant in contents.keys():
				var item_id := str(item_id_value)
				totals[item_id] = int(totals.get(item_id, 0)) + int(contents[item_id])
	return totals


## Used/max types and items summed over all cells, for the UI header.
func capacity_at(grid_pos: Vector2i) -> Dictionary:
	var net := _network_at(grid_pos)
	var types_used := 0
	var types_max := 0
	var items_used := 0
	var items_max := 0
	for drive_value: Variant in net.get("drives", []):
		var drive: WorldBlock = drive_value
		for cell_value: Variant in (drive.machine as MEDriveContainer).get_cells():
			var cap := MEStorageCell.capacity_for(str(cell_value.get("id", "")))
			var contents := MEStorageCell.contents_of(cell_value)
			types_used += MEStorageCell.used_types(contents)
			types_max += int(cap.get("types", 0))
			items_used += MEStorageCell.used_items(contents)
			items_max += int(cap.get("items", 0))
	return {
		"types_used": types_used, "types_max": types_max,
		"items_used": items_used, "items_max": items_max,
	}


## Inserts a stack into the network. Returns the leftover stack (empty = stored).
func insert(grid_pos: Vector2i, stack: Dictionary) -> Dictionary:
	if stack.is_empty():
		return {}
	if InventoryStacking.has_stored_state(stack):
		return stack.duplicate(true)
	var net := _network_at(grid_pos)
	if not bool(net.get("online", false)):
		return stack
	var item_id := str(stack.get("id", ""))
	var remaining := int(stack.get("count", 0))
	if item_id.is_empty() or remaining <= 0:
		return {}

	# Priority wins first; only drives within the same priority prefer an existing
	# stack over an empty type slot.
	var ordered_drives := _ordered_drives(net, true)
	for priority: int in _drive_priorities(ordered_drives):
		for prefer_existing: bool in [true, false]:
			for drive_value: Variant in ordered_drives:
				var drive: WorldBlock = drive_value
				if (drive.machine as MEDriveContainer).priority != priority:
					continue
				for cell_value: Variant in (drive.machine as MEDriveContainer).get_cells():
					if remaining <= 0:
						break
					var has_item := MEStorageCell.contents_of(cell_value).has(item_id)
					if prefer_existing != has_item:
						continue
					remaining -= MEStorageCell.insert(cell_value, item_id, remaining)
			if remaining <= 0:
				break
		if remaining <= 0:
			break

	if remaining <= 0:
		return {}
	var leftover := stack.duplicate(true)
	leftover["count"] = remaining
	return leftover


## Simulate one craft on independent cell snapshots before consuming anything.
## `network_output` is the result (or the remainder after player inventory space).
## Respect both item and type limits, plus the same drive priorities as live I/O.
## Returns ready, offline, missing, or full. No live cell is changed.
func check_craft(grid_pos: Vector2i, recipe: CraftingRecipe, network_output: Dictionary, job: Dictionary = {}) -> String:
	var net := _network_at(grid_pos)
	if not bool(net.get("online", false)):
		return "offline"
	var available := available_items(grid_pos, job)
	var needs: Dictionary = {}
	for index: int in recipe.ingredient_ids.size():
		var ingredient := str(recipe.ingredient_ids[index])
		needs[ingredient] = int(needs.get(ingredient, 0)) + (recipe.ingredient_counts[index] if index < recipe.ingredient_counts.size() else 1)
	for ingredient: String in needs:
		if int(available.get(ingredient, 0)) < int(needs[ingredient]):
			return "missing"
	var snapshots: Dictionary = {}
	var extract_drives := _ordered_drives(net, false)
	for drive: WorldBlock in extract_drives:
		snapshots[drive] = (drive.machine as MEDriveContainer).get_cells().duplicate(true)
	for index: int in recipe.ingredient_ids.size():
		var item_id := str(recipe.ingredient_ids[index])
		var needed: int = recipe.ingredient_counts[index] if index < recipe.ingredient_counts.size() else 1
		for drive: WorldBlock in extract_drives:
			for cell: Dictionary in snapshots[drive]:
				needed -= MEStorageCell.extract(cell, item_id, needed)
		if needed > 0:
			return "missing"
	if network_output.is_empty():
		return "ready"
	if InventoryStacking.has_stored_state(network_output):
		return "full"
	var item_id := str(network_output.get("id", ""))
	var remaining := int(network_output.get("count", 0))
	var insert_drives := _ordered_drives(net, true)
	for priority: int in _drive_priorities(insert_drives):
		for prefer_existing: bool in [true, false]:
			for drive: WorldBlock in insert_drives:
				if (drive.machine as MEDriveContainer).priority != priority:
					continue
				for cell: Dictionary in snapshots[drive]:
					if prefer_existing != MEStorageCell.contents_of(cell).has(item_id):
						continue
					remaining -= MEStorageCell.insert(cell, item_id, remaining)
					if remaining <= 0:
						return "ready"
	return "full"


## Extracts up to `count` of item_id. Returns how many were actually taken.
func extract(grid_pos: Vector2i, item_id: String, count: int, job: Dictionary = {}) -> int:
	var net := _network_at(grid_pos)
	if not bool(net.get("online", false)) or count <= 0:
		return 0
	count = mini(count, int(available_items(grid_pos, job).get(item_id, 0)))
	if not job.is_empty():
		count = mini(count, int(job["reserved"].get(item_id, 0)))
	var taken := 0
	for drive_value: Variant in _ordered_drives(net, false):
		var drive: WorldBlock = drive_value
		for cell_value: Variant in (drive.machine as MEDriveContainer).get_cells():
			if taken >= count:
				break
			taken += MEStorageCell.extract(cell_value, item_id, count - taken)
	if not job.is_empty():
		job["reserved"][item_id] = int(job["reserved"].get(item_id, 0)) - taken
	return taken


## Reservations are logical: items stay in removable cells and never disappear
## when an order is cancelled or its terminal is removed from the network.
func available_items(grid_pos: Vector2i, own_job: Dictionary = {}) -> Dictionary:
	var result := list_items(grid_pos)
	for terminal: WorldBlock in _network_at(grid_pos).get("crafting_terminals", []):
		for job: Dictionary in (terminal.machine as MECraftingTerminalContainer).jobs:
			if not MECraftingTerminalContainer.is_active(job) or is_same(job, own_job):
				continue
			for item_id: String in job["reserved"]:
				result[item_id] = maxi(int(result.get(item_id, 0)) - int(job["reserved"][item_id]), 0)
	return result


func crafting_recipes_at(grid_pos: Vector2i) -> Dictionary:
	var recipes: Dictionary = {}
	for recipe: CraftingRecipe in CraftingDatabase.recipes:
		if not QuestManager.is_recipe_available(recipe) or recipes.has(recipe.result_item_id):
			continue
		var inputs: Dictionary = {}
		for index: int in recipe.ingredient_ids.size():
			var ingredient := str(recipe.ingredient_ids[index])
			inputs[ingredient] = int(inputs.get(ingredient, 0)) + (recipe.ingredient_counts[index] if index < recipe.ingredient_counts.size() else 1)
		recipes[recipe.result_item_id] = {"kind": "craft", "output": recipe.result_item_id, "output_count": recipe.result_count, "inputs": inputs}
	# Explicit processing patterns take precedence over general crafting recipes.
	for iface: WorldBlock in _network_at(grid_pos).get("interfaces", []):
		var target := adjacent_target(iface)
		if target == null or target.machine == null:
			continue
		for pattern: Dictionary in (iface.machine as MEInterfaceContainer).patterns:
			var decoded := (iface.machine as MEInterfaceContainer)._decoded_recipe(target, pattern)
			if decoded.is_empty():
				continue
			var output := str(decoded["output"])
			var inputs := processing_inputs(decoded)
			var valid := false
			for actual: Dictionary in MachineRecipes.recipes_for_output(target.block_id, output):
				if processing_matches(actual, decoded):
					valid = true
			if not valid:
				continue
			var worker := {"provider": [iface.grid_pos.x, iface.grid_pos.y], "machine": [target.grid_pos.x, target.grid_pos.y], "machine_id": target.block_id}
			if recipes.has(output) and str(recipes[output]["kind"]) == "processing":
				if processing_matches(recipes[output], decoded):
					recipes[output]["workers"].append(worker)
				continue
			recipes[output] = {
				"kind": "processing", "output": output, "output_count": decoded["output_count"], "inputs": inputs,
				"fluids": decoded.get("fluids", {}).duplicate(true), "catalyst": str(decoded.get("catalyst", "")), "workers": [worker],
				"provider": [iface.grid_pos.x, iface.grid_pos.y], "machine": [target.grid_pos.x, target.grid_pos.y],
				"machine_id": target.block_id,
			}
	return recipes


static func processing_inputs(recipe: Dictionary) -> Dictionary:
	var inputs: Dictionary = recipe.get("inputs", {})
	if not inputs.is_empty():
		var normalized: Dictionary = {}
		for item_id: String in inputs:
			normalized[item_id] = maxi(int(inputs[item_id]), 1)
		return normalized
	var item_id := str(recipe.get("input", ""))
	return {item_id: maxi(int(recipe.get("input_count", 1)), 1)} if not item_id.is_empty() else {}


static func processing_fluids(recipe: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for fluid: String in recipe.get("fluids", {}):
		result[fluid] = float(recipe["fluids"][fluid])
	return result


static func processing_matches(first: Dictionary, second: Dictionary) -> bool:
	return processing_inputs(first) == processing_inputs(second) \
		and processing_fluids(first) == processing_fluids(second) \
		and str(first.get("catalyst", "")) == str(second.get("catalyst", "")) \
		and str(first.get("output", "")) == str(second.get("output", "")) \
		and is_equal_approx(float(first.get("output_count", 1)), float(second.get("output_count", 1)))


func preview_craft(grid_pos: Vector2i, item_id: String, count: int) -> Dictionary:
	var plan := MECraftPlanner.new().plan(item_id, count, available_items(grid_pos), crafting_recipes_at(grid_pos), available_fluids(grid_pos))
	var errors: PackedStringArray = plan["errors"]
	if not is_online_at(grid_pos):
		errors.append("offline")
	if _network_at(grid_pos).get("assemblers", []).is_empty():
		for step: Dictionary in plan["steps"]:
			if str(step["kind"]) == "craft":
				errors.append("no_assembler")
				break
	plan["errors"] = errors
	plan["ready"] = errors.is_empty() and (plan["missing"] as Dictionary).is_empty() and (plan["missing_fluids"] as Dictionary).is_empty()
	return plan


func request_craft(grid_pos: Vector2i, item_id: String, count: int) -> int:
	if _wim == null:
		return -1
	var terminal := _wim._placed_blocks.get(grid_pos) as WorldBlock
	if terminal == null or not terminal.machine is MECraftingTerminalContainer:
		return -1
	# Recalculate on submit: the preview does not reserve resources.
	return (terminal.machine as MECraftingTerminalContainer).enqueue(preview_craft(grid_pos, item_id, count))


# ── Fluid storage ─────────────────────────────────────────────────────────────

## Aggregated { fluid_id: liters } across every fluid cell in the network.
func list_fluids(grid_pos: Vector2i) -> Dictionary:
	var totals: Dictionary = {}
	var net := _network_at(grid_pos)
	for drive_value: Variant in net.get("drives", []):
		var drive: WorldBlock = drive_value
		for cell_value: Variant in (drive.machine as MEDriveContainer).get_fluid_cells():
			var contents: Dictionary = MEStorageCell.fluids_of(cell_value)
			for fluid_id_value: Variant in contents.keys():
				var fluid_id := str(fluid_id_value)
				totals[fluid_id] = float(totals.get(fluid_id, 0.0)) + float(contents[fluid_id])
	return totals


## Used/max liters summed over all fluid cells, for the UI header.
func fluid_capacity_at(grid_pos: Vector2i) -> Dictionary:
	var net := _network_at(grid_pos)
	var liters_used := 0.0
	var liters_max := 0.0
	for drive_value: Variant in net.get("drives", []):
		var drive: WorldBlock = drive_value
		for cell_value: Variant in (drive.machine as MEDriveContainer).get_fluid_cells():
			var cap := MEStorageCell.fluid_capacity_for(str(cell_value.get("id", "")))
			liters_used += MEStorageCell.used_liters(MEStorageCell.fluids_of(cell_value))
			liters_max += float(cap.get("liters", 0.0))
	return {"liters_used": liters_used, "liters_max": liters_max}


## Inserts liters of a fluid into the network. Returns how much was stored.
func insert_fluid(grid_pos: Vector2i, fluid_id: String, liters: float) -> float:
	var net := _network_at(grid_pos)
	if not bool(net.get("online", false)) or fluid_id.is_empty() or liters <= 0.0:
		return 0.0
	var remaining := liters
	# Same priority semantics as item storage.
	var ordered_drives := _ordered_drives(net, true)
	for priority: int in _drive_priorities(ordered_drives):
		for prefer_existing: bool in [true, false]:
			for drive_value: Variant in ordered_drives:
				var drive: WorldBlock = drive_value
				if (drive.machine as MEDriveContainer).priority != priority:
					continue
				for cell_value: Variant in (drive.machine as MEDriveContainer).get_fluid_cells():
					if remaining <= 0.0001:
						break
					var has_fluid := MEStorageCell.fluids_of(cell_value).has(fluid_id)
					if prefer_existing != has_fluid:
						continue
					remaining -= MEStorageCell.insert_fluid(cell_value, fluid_id, remaining)
			if remaining <= 0.0001:
				break
		if remaining <= 0.0001:
			break
	return liters - remaining


## Extracts up to `liters` of fluid_id. Returns how much was actually taken.
func extract_fluid(grid_pos: Vector2i, fluid_id: String, liters: float, job: Dictionary = {}) -> float:
	var net := _network_at(grid_pos)
	if not bool(net.get("online", false)) or liters <= 0.0:
		return 0.0
	liters = minf(liters, float(available_fluids(grid_pos, job).get(fluid_id, 0.0)))
	if not job.is_empty():
		liters = minf(liters, float(job.get("reserved_fluids", {}).get(fluid_id, 0.0)))
	var taken := 0.0
	for drive_value: Variant in _ordered_drives(net, false):
		var drive: WorldBlock = drive_value
		for cell_value: Variant in (drive.machine as MEDriveContainer).get_fluid_cells():
			if taken >= liters - 0.0001:
				break
			taken += MEStorageCell.extract_fluid(cell_value, fluid_id, liters - taken)
	if not job.is_empty():
		job["reserved_fluids"][fluid_id] = maxf(float(job["reserved_fluids"].get(fluid_id, 0.0)) - taken, 0.0)
	return taken


## Container transfers keep the physical container and every unaccepted liter.
## The returned stack replaces the source slot/cursor; no item-cell entry is made.
func pour_fluid_container(grid_pos: Vector2i, stack: Dictionary) -> Dictionary:
	var result := {"stack": stack.duplicate(true), "moved": 0.0, "reason": "invalid_container"}
	if not is_online_at(grid_pos):
		result["reason"] = "offline"
		return result
	var fluid := str(stack.get("fluid_id", ""))
	var amount := float(stack.get("fluid_amount", 0.0))
	if int(stack.get("count", 1)) != 1 or float(stack.get("fluid_capacity", 0.0)) <= 0.0:
		return result
	if fluid.is_empty() or amount <= 0.0001:
		result["reason"] = "empty_container"
		return result
	if not FluidDatabase.container_accepts(stack, fluid):
		return result
	if float(fluid_capacity_at(grid_pos)["liters_max"]) <= 0.0:
		result["reason"] = "no_fluid_cell"
		return result
	var stored := insert_fluid(grid_pos, fluid, amount)
	var updated := stack.duplicate(true)
	updated["fluid_amount"] = maxf(amount - stored, 0.0)
	if float(updated["fluid_amount"]) <= 0.0001:
		updated["fluid_id"] = ""
		updated["fluid_amount"] = 0.0
	result["stack"] = FluidDatabase.apply_bucket_display(updated)
	result["moved"] = stored
	result["reason"] = "full" if stored <= 0.0001 else "partial" if amount - stored > 0.0001 else "ready"
	return result


func fill_fluid_container(grid_pos: Vector2i, stack: Dictionary, fluid: String) -> Dictionary:
	var result := {"stack": stack.duplicate(true), "moved": 0.0, "reason": "invalid_container"}
	if not is_online_at(grid_pos):
		result["reason"] = "offline"
		return result
	if int(stack.get("count", 1)) != 1 or not FluidDatabase.container_accepts(stack, fluid):
		return result
	var carried := str(stack.get("fluid_id", ""))
	var amount := float(stack.get("fluid_amount", 0.0))
	if amount > 0.0001 and not carried.is_empty() and carried != fluid:
		result["reason"] = "different_fluid"
		return result
	var space := maxf(float(stack.get("fluid_capacity", 0.0)) - amount, 0.0)
	if space <= 0.0001:
		result["reason"] = "container_full"
		return result
	var taken := extract_fluid(grid_pos, fluid, space)
	if taken <= 0.0001:
		result["reason"] = "reserved" if float(list_fluids(grid_pos).get(fluid, 0.0)) > 0.0001 else "missing"
		return result
	var updated := stack.duplicate(true)
	updated["fluid_id"] = fluid
	updated["fluid_amount"] = amount + taken
	result["stack"] = FluidDatabase.apply_bucket_display(updated)
	result["moved"] = taken
	result["reason"] = "ready"
	return result


func available_fluids(grid_pos: Vector2i, own_job: Dictionary = {}) -> Dictionary:
	var result := list_fluids(grid_pos)
	for terminal: WorldBlock in _network_at(grid_pos).get("crafting_terminals", []):
		for job: Dictionary in (terminal.machine as MECraftingTerminalContainer).jobs:
			if not MECraftingTerminalContainer.is_active(job) or is_same(job, own_job):
				continue
			for fluid: String in job.get("reserved_fluids", {}):
				result[fluid] = maxf(float(result.get(fluid, 0.0)) - float(job["reserved_fluids"][fluid]), 0.0)
	return result


func _ordered_drives(net: Dictionary, for_insert: bool) -> Array:
	var drives: Array = (net.get("drives", []) as Array).duplicate()
	drives.sort_custom(func(first: WorldBlock, second: WorldBlock) -> bool:
		var first_priority := (first.machine as MEDriveContainer).priority
		var second_priority := (second.machine as MEDriveContainer).priority
		return first_priority > second_priority if for_insert \
			else first_priority < second_priority
	)
	return drives


func _drive_priorities(ordered_drives: Array) -> Array[int]:
	var priorities: Array[int] = []
	for drive_value: Variant in ordered_drives:
		var priority := ((drive_value as WorldBlock).machine as MEDriveContainer).priority
		if not priority in priorities:
			priorities.append(priority)
	return priorities


# ── Bus servicing ─────────────────────────────────────────────────────────────

func _service_buses() -> void:
	if _wim != null:
		for block: WorldBlock in _wim._placed_blocks.values():
			if block.machine != null:
				block.machine.me_request_output_locked = false
				block.machine.me_request_fluid_output_locked = false
	var owners: Dictionary = {}
	# A saved batch retains its machine even if topology now places the worker
	# in a different component. Another network cannot collect or overwrite it.
	for network: Dictionary in _networks:
		for terminal: WorldBlock in network.get("crafting_terminals", []):
			for job: Dictionary in (terminal.machine as MECraftingTerminalContainer).jobs:
				if not MECraftingTerminalContainer.is_active(job):
					continue
				MECraftingService._migrate(job)
				for batch: Dictionary in job["running"]:
					owners[MECraftingService.position(batch["machine"])] = batch
					var target := MECraftingService.block_at(self, batch["machine"])
					if target != null and target.machine != null and str(batch["kind"]) == "processing":
						target.machine.me_request_output_locked = true
						target.machine.me_request_fluid_output_locked = str(job["steps"][int(batch["step"])]["output"]).begins_with("fluid:")
	for net_value: Variant in _networks:
		var net: Dictionary = net_value
		for assembler_value: Variant in net.get("assemblers", []):
			var assembler_block := assembler_value as WorldBlock
			if assembler_block != null and assembler_block.machine is MEAssemblerContainer:
				(assembler_block.machine as MEAssemblerContainer).begin_pattern_service()
		var claimed: Dictionary = MECraftingService.service(self, net, SERVICE_INTERVAL, owners)
		if not bool(net.get("online", false)):
			for terminal_value: Variant in net.get("pattern_terminals", []):
				var terminal_block := terminal_value as WorldBlock
				if terminal_block != null and terminal_block.machine is MEPatternTerminalContainer:
					(terminal_block.machine as MEPatternTerminalContainer).service(self, net.get("assemblers", []))
			_finish_pattern_service(net)
			continue
		for bus_value: Variant in net.get("buses", []):
			_service_bus(bus_value as WorldBlock)
		for iface_value: Variant in net.get("interfaces", []):
			var iface := iface_value as WorldBlock
			if not claimed.has(iface.grid_pos):
				_service_interface(iface)
		for terminal_value: Variant in net.get("pattern_terminals", []):
			var terminal_block := terminal_value as WorldBlock
			if terminal_block != null and terminal_block.machine is MEPatternTerminalContainer:
				(terminal_block.machine as MEPatternTerminalContainer).service(self, net.get("assemblers", []))
		_finish_pattern_service(net)
		_update_energy(net)


func _finish_pattern_service(net: Dictionary) -> void:
	for assembler_value: Variant in net.get("assemblers", []):
		var assembler_block := assembler_value as WorldBlock
		if assembler_block != null and assembler_block.machine is MEAssemblerContainer:
			(assembler_block.machine as MEAssemblerContainer).finish_pattern_service()


func _service_bus(bus: WorldBlock) -> void:
	if bus == null or not (bus.machine is MEBusContainer):
		return
	var cont: MEBusContainer = bus.machine
	cont.last_service_active = false
	var target: WorldBlock = _adjacent_target(bus)
	if target == null:
		return
	if target.machine != null and target.machine.me_request_output_locked:
		return
	match cont.bus_kind:
		"import":
			# Item filters are a whitelist (empty = pull everything).
			_do_import(bus, target, cont.filters, PackedStringArray())
			_do_import_fluids(bus, target, cont.fluid_filters)
		"export":
			_do_export(bus, target, cont.filters)
			_do_export_fluids(bus, target, cont.fluid_filters)


## Runs one pattern-provider pass for an ME Interface block.
func _service_interface(iface: WorldBlock) -> void:
	if iface == null or not (iface.machine is MEInterfaceContainer):
		return
	var target: WorldBlock = _adjacent_target(iface)
	if target != null and target.machine != null and target.machine.me_request_output_locked:
		return
	(iface.machine as MEInterfaceContainer).service(self, iface.grid_pos, target)


## Pulls one stack out of the target inventory into the network.
## `include` — whitelist (empty = everything); `exclude` — never pull these.
func _do_import(
	bus: WorldBlock,
	target: WorldBlock,
	include: PackedStringArray,
	exclude: PackedStringArray
) -> void:
	var amount := roundi(MOVE_AMOUNT * (bus.machine as MEBusContainer).transfer_multiplier())
	var count := target.chest_inventory.get_slot_count() if target.chest_inventory != null else target.machine.slots.size() if target.machine != null else 0
	for index: int in count:
		var stack: Dictionary = {}
		if target.chest_inventory != null:
			var data: Variant = target.chest_inventory.get_slot_data_at(index)
			if data is Dictionary:
				stack = data.duplicate(true)
		elif target.machine.slots[index].role == MachineSlot.Role.OUTPUT:
			stack = target.machine.slots[index].peek()
		var item := str(stack.get("id", ""))
		if stack.is_empty() or item in exclude or (not include.is_empty() and not item in include):
			continue
		stack["count"] = mini(int(stack["count"]), amount)
		var leftover := insert(bus.grid_pos, stack)
		var stored := int(stack["count"]) - int(leftover.get("count", 0))
		if stored > 0:
			(bus.machine as MEBusContainer).last_service_active = true
			if target.chest_inventory != null:
				target.chest_inventory.pull_item(index, stored)
			else:
				target.machine.pull_item(index, stored)
		return


## Pushes each filtered item from the network into the target inventory.
func _do_export(bus: WorldBlock, target: WorldBlock, filters: PackedStringArray) -> void:
	for filter_value: Variant in filters:
		var item_id := str(filter_value)
		if item_id.is_empty():
			continue
		var taken: int = extract(bus.grid_pos, item_id, roundi(MOVE_AMOUNT * (bus.machine as MEBusContainer).transfer_multiplier()))
		if taken <= 0:
			continue
		var stack: Dictionary = ItemDatabase.create_existing_stack(item_id, taken)
		var leftover: Dictionary = _push_to_target(target, stack)
		if int(leftover.get("count", 0)) < taken:
			(bus.machine as MEBusContainer).last_service_active = true
		if not leftover.is_empty():
			insert(bus.grid_pos, leftover)  # target full → return remainder


## Drains the neighbour's output/storage tanks into network fluid cells.
## `include` — whitelist of fluid ids (empty = every fluid).
func _do_import_fluids(bus: WorldBlock, target: WorldBlock, include: PackedStringArray) -> void:
	if not (target.machine is FluidMachineContainer):
		return
	var machine: FluidMachineContainer = target.machine
	var budget := MOVE_LITERS * (bus.machine as MEBusContainer).transfer_multiplier()
	for fluid_id_value: Variant in machine.get_output_fluid_ids():
		if budget <= 0.0001:
			break
		var fluid_id := str(fluid_id_value)
		if not include.is_empty() and not (fluid_id in include):
			continue
		var available: float = minf(machine.get_available_output(fluid_id), budget)
		if available <= 0.0:
			continue
		# Сначала резервируем место в ячейках, потом забираем у машины ровно
		# столько — жидкость не теряется, если сеть переполнена.
		var stored: float = insert_fluid(bus.grid_pos, fluid_id, available)
		if stored <= 0.0:
			continue
		var pulled: float = machine.pull_fluid(fluid_id, stored)
		if pulled < stored:
			extract_fluid(bus.grid_pos, fluid_id, stored - pulled)
		budget -= pulled
		(bus.machine as MEBusContainer).last_service_active = pulled > 0.0


## Pushes each filtered fluid from the network into the neighbour's input tanks.
func _do_export_fluids(bus: WorldBlock, target: WorldBlock, filters: PackedStringArray) -> void:
	if not (target.machine is FluidMachineContainer):
		return
	var machine: FluidMachineContainer = target.machine
	var budget := MOVE_LITERS * (bus.machine as MEBusContainer).transfer_multiplier()
	for filter_value: Variant in filters:
		if budget <= 0.0001:
			break
		var fluid_id := str(filter_value)
		if fluid_id.is_empty() or not machine.can_accept_fluid(fluid_id):
			continue
		var taken: float = extract_fluid(bus.grid_pos, fluid_id, budget)
		if taken <= 0.0:
			continue
		var accepted: float = machine.push_fluid(fluid_id, taken)
		if accepted < taken:
			insert_fluid(bus.grid_pos, fluid_id, taken - accepted)  # target full → return
		budget -= accepted
		(bus.machine as MEBusContainer).last_service_active = accepted > 0.0


## Public lookup for the UI: the block a bus/interface at this position feeds.
func adjacent_target(bus: WorldBlock) -> WorldBlock:
	return _adjacent_target(bus)


## First adjacent non-ME block that exposes an inventory.
func _adjacent_target(bus: WorldBlock) -> WorldBlock:
	var placed: Dictionary = _wim._placed_blocks
	for dir: Vector2i in DIRS:
		var nb: WorldBlock = placed.get(bus.grid_pos + dir) as WorldBlock
		if nb == null or ME_BLOCK_IDS.has(nb.block_id):
			continue
		if nb.chest_inventory != null or nb.machine != null:
			return nb
	return null


func _push_to_target(target: WorldBlock, stack: Dictionary) -> Dictionary:
	if stack.is_empty():
		return {}
	if target.chest_inventory != null:
		var leftover: Variant = target.chest_inventory.auto_insert_item(stack)
		return leftover if leftover is Dictionary else {}
	if target.machine != null:
		var item_id := str(stack.get("id", ""))
		var slot: int = target.machine.find_input_slot_for(item_id)
		if slot < 0:
			return stack
		return target.machine.push_item(slot, stack)
	return stack


func _pull_from_target(
	target: WorldBlock,
	amount: int,
	include: PackedStringArray,
	exclude: PackedStringArray
) -> Dictionary:
	if target.chest_inventory != null:
		for i in target.chest_inventory.get_slot_count():
			var data: Variant = target.chest_inventory.get_slot_data_at(i)
			if data is Dictionary and not (data as Dictionary).is_empty():
				var item_id := str((data as Dictionary).get("id", ""))
				if item_id in exclude:
					continue
				if not include.is_empty() and not (item_id in include):
					continue
				return target.chest_inventory.pull_item(i, amount)
		return {}
	if target.machine != null:
		var slot: int = target.machine.find_output_slot()
		if slot < 0:
			return {}
		var out_slot: MachineSlot = target.machine.slots[slot]
		var out_id := str(out_slot.item.get("id", ""))
		if out_id in exclude:
			return {}
		if not include.is_empty() and not (out_id in include):
			return {}
		return target.machine.pull_item(slot, amount)
	return {}

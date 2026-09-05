extends RefCounted
class_name ProductionChainAnalyzer

const IRON_LINE_CAPACITY_PER_MINUTE := 20.0
const RESEARCH_LINE_CAPACITY_PER_MINUTE := 60.0 / SteamAssemblerContainer.PROCESS_TIME
const STEEL_LINE_CAPACITY_PER_MINUTE := 60.0 / (CokeOvenContainer.PROCESS_TIME * 2.0) * 2.0


static func iron_line_snapshot(tree: SceneTree) -> Dictionary:
	var blocks: Array[WorldBlock] = []
	var grid_lookup: Dictionary = {}
	for node: Node in tree.get_nodes_in_group("world_block"):
		var block := node as WorldBlock
		if block == null or not is_instance_valid(block):
			continue
		blocks.append(block)
		for tile: Vector2i in block.footprint():
			grid_lookup[tile] = block
	return analyze_iron_line(blocks, grid_lookup)


static func research_line_snapshot(tree: SceneTree) -> Dictionary:
	var blocks: Array[WorldBlock] = []
	var grid_lookup: Dictionary = {}
	for node: Node in tree.get_nodes_in_group("world_block"):
		var block := node as WorldBlock
		if block == null or not is_instance_valid(block):
			continue
		blocks.append(block)
		for tile: Vector2i in block.footprint():
			grid_lookup[tile] = block
	return analyze_research_line(blocks, grid_lookup)


static func steel_line_snapshot(tree: SceneTree) -> Dictionary:
	var blocks: Array[WorldBlock] = []
	var grid_lookup: Dictionary = {}
	for node: Node in tree.get_nodes_in_group("world_block"):
		var block := node as WorldBlock
		if block == null or not is_instance_valid(block):
			continue
		blocks.append(block)
		for tile: Vector2i in block.footprint():
			grid_lookup[tile] = block
	return analyze_steel_line(blocks, grid_lookup)


static func analyze_iron_line(blocks: Array[WorldBlock], grid_lookup: Dictionary) -> Dictionary:
	var result := {
		"crusher_ready": false,
		"furnace_ready": false,
		"storage_ready": false,
		"connected": false,
		"reason": "Build a Steam Crusher",
		"bottleneck": "",
		"bottleneck_block": null,
		"capacity_per_minute": IRON_LINE_CAPACITY_PER_MINUTE,
	}
	var by_id: Dictionary = {}
	var adjacency: Dictionary = {}
	for block: WorldBlock in blocks:
		var block_key := block.get_instance_id()
		by_id[block_key] = block
		adjacency[block_key] = []
		if block.machine is SteamCrusherContainer:
			result["crusher_ready"] = true
		elif block.machine is SteamFurnaceContainer:
			result["furnace_ready"] = true
		if block.chest_inventory != null:
			result["storage_ready"] = true

	for block: WorldBlock in blocks:
		_connect_logistics(block, grid_lookup, adjacency)

	if not bool(result["crusher_ready"]):
		return result
	if not bool(result["furnace_ready"]):
		result["reason"] = "Build a Steam Furnace"
		return result
	if not bool(result["storage_ready"]):
		result["reason"] = "Connect an output chest"
		return result

	for component: Array in _components(adjacency):
		var line := _line_from_component(component, by_id)
		if line.is_empty():
			continue
		result["connected"] = true
		_apply_line_status(result, line)
		return result

	result["reason"] = "Logistics disconnected"
	return result


static func analyze_research_line(blocks: Array[WorldBlock], grid_lookup: Dictionary) -> Dictionary:
	var result := {
		"core_assembler_ready": false,
		"pack_assembler_ready": false,
		"storage_ready": false,
		"connected": false,
		"reason": "Configure Research Core Assembler",
		"bottleneck": "",
		"bottleneck_block": null,
		"capacity_per_minute": RESEARCH_LINE_CAPACITY_PER_MINUTE,
	}
	var by_id: Dictionary = {}
	var adjacency: Dictionary = {}
	for block: WorldBlock in blocks:
		var block_key := block.get_instance_id()
		by_id[block_key] = block
		adjacency[block_key] = []
		if block.machine is SteamAssemblerContainer:
			var assembler := block.machine as SteamAssemblerContainer
			if assembler.selected_recipe_id == "steam_research_core":
				result["core_assembler_ready"] = true
			elif assembler.selected_recipe_id == "steam_science_pack":
				result["pack_assembler_ready"] = true
		if block.chest_inventory != null:
			result["storage_ready"] = true

	for block: WorldBlock in blocks:
		_connect_logistics(block, grid_lookup, adjacency)

	if not bool(result["core_assembler_ready"]):
		return result
	if not bool(result["pack_assembler_ready"]):
		result["reason"] = "Configure Steam Pack Assembler"
		return result
	if not bool(result["storage_ready"]):
		result["reason"] = "Connect Research Output Chest"
		return result

	for component: Array in _components(adjacency):
		var line := _research_line_from_component(component, by_id)
		if line.is_empty():
			continue
		result["connected"] = true
		_apply_research_line_status(result, line)
		return result

	result["reason"] = "Research logistics disconnected"
	return result


static func analyze_steel_line(blocks: Array[WorldBlock], grid_lookup: Dictionary) -> Dictionary:
	var result := {
		"coke_oven_ready": false,
		"blast_furnace_ready": false,
		"press_ready": false,
		"storage_ready": false,
		"creosote_buffer_ready": false,
		"creosote_boiler_ready": false,
		"creosote_recovery": false,
		"creosote_block": null,
		"connected": false,
		"reason": "Build a Coke Oven",
		"bottleneck": "",
		"bottleneck_block": null,
		"capacity_per_minute": STEEL_LINE_CAPACITY_PER_MINUTE,
	}
	var by_id: Dictionary = {}
	var adjacency: Dictionary = {}
	var coke_oven_block: WorldBlock = null
	for block: WorldBlock in blocks:
		var block_key := block.get_instance_id()
		by_id[block_key] = block
		adjacency[block_key] = []
		if block.machine is CokeOvenContainer:
			result["coke_oven_ready"] = true
			coke_oven_block = block
		elif block.machine is PrimitiveBlastFurnaceContainer:
			result["blast_furnace_ready"] = true
		elif block.machine is SteamPressContainer:
			result["press_ready"] = true
		if block.chest_inventory != null:
			result["storage_ready"] = true

	for block: WorldBlock in blocks:
		_connect_logistics(block, grid_lookup, adjacency)
	if coke_oven_block != null:
		result["creosote_block"] = coke_oven_block
		var recovery := _creosote_recovery_from(coke_oven_block, grid_lookup)
		result["creosote_buffer_ready"] = bool(recovery.get("buffer_ready", false))
		result["creosote_boiler_ready"] = bool(recovery.get("boiler_ready", false))
		result["creosote_recovery"] = bool(recovery.get("ready", false))

	if not bool(result["coke_oven_ready"]):
		return result
	if not bool(result["blast_furnace_ready"]):
		result["reason"] = "Build a Primitive Blast Furnace"
		return result
	if not bool(result["press_ready"]):
		result["reason"] = "Connect a Steam Press"
		return result
	if not bool(result["storage_ready"]):
		result["reason"] = "Connect a Steel Output Chest"
		return result

	for component: Array in _components(adjacency):
		var line := _steel_line_from_component(component, by_id)
		if line.is_empty():
			continue
		result["connected"] = true
		_apply_steel_line_status(result, line)
		return result

	result["reason"] = "Steel logistics disconnected"
	return result


static func _connect_logistics(block: WorldBlock, grid_lookup: Dictionary, adjacency: Dictionary) -> void:
	if block.machine is MechanicalInserterContainer:
		var inserter := block.machine as MechanicalInserterContainer
		_connect(block, grid_lookup.get(inserter.source_grid_pos - WorldBlock.FACING_DIRS[inserter.facing]) as WorldBlock, adjacency)
		_connect(block, grid_lookup.get(inserter.source_grid_pos + WorldBlock.FACING_DIRS[inserter.facing]) as WorldBlock, adjacency)
		return
	if block.machine is ConveyorSplitterContainer:
		var splitter := block.machine as ConveyorSplitterContainer
		for direction: int in [(splitter.facing + 3) % 4, (splitter.facing + 1) % 4]:
			_connect(block, grid_lookup.get(splitter.source_grid_pos + WorldBlock.FACING_DIRS[direction]) as WorldBlock, adjacency)
		return
	if block.machine is ConveyorContainer:
		var conveyor := block.machine as ConveyorContainer
		_connect(block, grid_lookup.get(conveyor.source_grid_pos + WorldBlock.FACING_DIRS[conveyor.facing]) as WorldBlock, adjacency)


static func _connect(first: WorldBlock, second: WorldBlock, adjacency: Dictionary) -> void:
	if first == null or second == null or first == second:
		return
	var first_key := first.get_instance_id()
	var second_key := second.get_instance_id()
	if not adjacency.has(first_key) or not adjacency.has(second_key):
		return
	var first_neighbors := adjacency[first_key] as Array
	var second_neighbors := adjacency[second_key] as Array
	if not first_neighbors.has(second_key):
		first_neighbors.append(second_key)
	if not second_neighbors.has(first_key):
		second_neighbors.append(first_key)


static func _components(adjacency: Dictionary) -> Array[Array]:
	var components: Array[Array] = []
	var visited: Dictionary = {}
	for start_key: Variant in adjacency:
		if visited.has(start_key):
			continue
		var component: Array = []
		var queue: Array = [start_key]
		visited[start_key] = true
		while not queue.is_empty():
			var current: Variant = queue.pop_front()
			component.append(current)
			for neighbor: Variant in adjacency[current]:
				if visited.has(neighbor):
					continue
				visited[neighbor] = true
				queue.append(neighbor)
		components.append(component)
	return components


static func _line_from_component(component: Array, by_id: Dictionary) -> Dictionary:
	var crusher: WorldBlock = null
	var furnace: WorldBlock = null
	var storage: WorldBlock = null
	var inserters: Array[WorldBlock] = []
	var conveyors: Array[WorldBlock] = []
	for block_key: Variant in component:
		var block := by_id.get(block_key) as WorldBlock
		if block == null:
			continue
		if block.machine is SteamCrusherContainer:
			crusher = block
		elif block.machine is SteamFurnaceContainer:
			furnace = block
		elif block.machine is MechanicalInserterContainer:
			inserters.append(block)
		elif block.machine is ConveyorContainer:
			conveyors.append(block)
		if block.chest_inventory != null:
			storage = block
	if crusher == null or furnace == null or storage == null or inserters.size() < 2:
		return {}
	return {
		"crusher": crusher,
		"furnace": furnace,
		"storage": storage,
		"inserters": inserters,
		"conveyors": conveyors,
	}


static func _research_line_from_component(component: Array, by_id: Dictionary) -> Dictionary:
	var core_assembler: WorldBlock = null
	var pack_assembler: WorldBlock = null
	var storage: WorldBlock = null
	var inserters: Array[WorldBlock] = []
	var conveyors: Array[WorldBlock] = []
	for block_key: Variant in component:
		var block := by_id.get(block_key) as WorldBlock
		if block == null:
			continue
		if block.machine is SteamAssemblerContainer:
			var assembler := block.machine as SteamAssemblerContainer
			if assembler.selected_recipe_id == "steam_research_core":
				core_assembler = block
			elif assembler.selected_recipe_id == "steam_science_pack":
				pack_assembler = block
		elif block.machine is MechanicalInserterContainer:
			inserters.append(block)
		elif block.machine is ConveyorContainer:
			conveyors.append(block)
		if block.chest_inventory != null:
			storage = block
	if core_assembler == null or pack_assembler == null or storage == null or inserters.size() < 2:
		return {}
	return {
		"core_assembler": core_assembler,
		"pack_assembler": pack_assembler,
		"storage": storage,
		"inserters": inserters,
		"conveyors": conveyors,
	}


static func _steel_line_from_component(component: Array, by_id: Dictionary) -> Dictionary:
	var coke_oven: WorldBlock = null
	var blast_furnace: WorldBlock = null
	var press: WorldBlock = null
	var storage: WorldBlock = null
	var inserters: Array[WorldBlock] = []
	var conveyors: Array[WorldBlock] = []
	for block_key: Variant in component:
		var block := by_id.get(block_key) as WorldBlock
		if block == null:
			continue
		if block.machine is CokeOvenContainer:
			coke_oven = block
		elif block.machine is PrimitiveBlastFurnaceContainer:
			blast_furnace = block
		elif block.machine is SteamPressContainer:
			press = block
		elif block.machine is MechanicalInserterContainer:
			inserters.append(block)
		elif block.machine is ConveyorContainer:
			conveyors.append(block)
		if block.chest_inventory != null:
			storage = block
	if coke_oven == null or blast_furnace == null or press == null or storage == null or inserters.size() < 3:
		return {}
	return {
		"coke_oven": coke_oven,
		"blast_furnace": blast_furnace,
		"press": press,
		"storage": storage,
		"inserters": inserters,
		"conveyors": conveyors,
	}


static func _creosote_recovery_from(coke_block: WorldBlock, grid_lookup: Dictionary) -> Dictionary:
	var result := {"buffer_ready": false, "boiler_ready": false, "ready": false}
	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}
	for tile: Vector2i in coke_block.footprint():
		for direction: Vector2i in WorldBlock.FACING_DIRS:
			var neighbor_pos := tile + direction
			var neighbor := grid_lookup.get(neighbor_pos) as WorldBlock
			if neighbor == null or neighbor.block_id != "fluid_pipe" or visited.has(neighbor_pos):
				continue
			visited[neighbor_pos] = true
			queue.append(neighbor_pos)
	while not queue.is_empty():
		var current := queue.pop_front() as Vector2i
		for direction: Vector2i in WorldBlock.FACING_DIRS:
			var neighbor_pos := current + direction
			var neighbor := grid_lookup.get(neighbor_pos) as WorldBlock
			if neighbor == null or neighbor == coke_block:
				continue
			if neighbor.block_id == "fluid_pipe":
				if not visited.has(neighbor_pos):
					visited[neighbor_pos] = true
					queue.append(neighbor_pos)
			elif neighbor.machine is FluidTankContainer:
				result["buffer_ready"] = true
			elif neighbor.machine is SteamBoilerContainer:
				result["boiler_ready"] = true
	result["ready"] = bool(result["buffer_ready"]) and bool(result["boiler_ready"])
	return result


static func _apply_line_status(result: Dictionary, line: Dictionary) -> void:
	var crusher := line["crusher"] as WorldBlock
	var furnace := line["furnace"] as WorldBlock
	for conveyor_block: WorldBlock in line["conveyors"]:
		if (conveyor_block.machine as ConveyorContainer).jammed:
			_set_bottleneck(result, "Conveyor jam", conveyor_block)
			return
	for inserter_block: WorldBlock in line["inserters"]:
		var inserter := inserter_block.machine as MechanicalInserterContainer
		if inserter.status_key == "Destination blocked":
			_set_bottleneck(result, "Inserter output blocked", inserter_block)
			return

	var crusher_info := MachineTelemetry.snapshot(crusher.machine)
	var furnace_info := MachineTelemetry.snapshot(furnace.machine)
	var crusher_reason := str(crusher_info.get("reason", ""))
	var furnace_reason := str(furnace_info.get("reason", ""))
	if crusher_reason == "Output blocked":
		_set_bottleneck(result, "Crusher output blocked", crusher)
		return
	if furnace_reason == "Output blocked":
		_set_bottleneck(result, "Furnace output blocked", furnace)
		return
	if crusher_reason == "No Steam":
		_set_bottleneck(result, "Crusher has no steam", crusher)
		return
	if furnace_reason == "No Steam":
		_set_bottleneck(result, "Furnace has no steam", furnace)
		return
	if crusher_reason == "No Input":
		_set_bottleneck(result, "Add iron ore to the crusher", crusher)
		return
	if furnace_reason == "No Input":
		_set_bottleneck(result, "Waiting for ore or dust", furnace)
		return
	result["reason"] = "Iron line is running" if bool(crusher_info.get("active", false)) or bool(furnace_info.get("active", false)) else "Iron line is ready"
	result["bottleneck"] = "Steam Crusher limits throughput"
	result["bottleneck_block"] = crusher


static func _apply_research_line_status(result: Dictionary, line: Dictionary) -> void:
	var core_block := line["core_assembler"] as WorldBlock
	var pack_block := line["pack_assembler"] as WorldBlock
	for conveyor_block: WorldBlock in line["conveyors"]:
		if (conveyor_block.machine as ConveyorContainer).jammed:
			_set_bottleneck(result, "Research conveyor jam", conveyor_block)
			return
	for inserter_block: WorldBlock in line["inserters"]:
		var inserter := inserter_block.machine as MechanicalInserterContainer
		if inserter.status_key == "Destination blocked":
			_set_bottleneck(result, "Research inserter output blocked", inserter_block)
			return

	var core := core_block.machine as SteamAssemblerContainer
	var pack := pack_block.machine as SteamAssemblerContainer
	if core.last_status == "Output blocked":
		_set_bottleneck(result, "Core assembler output blocked", core_block)
		return
	if pack.last_status == "Output blocked":
		_set_bottleneck(result, "Pack assembler output blocked", pack_block)
		return
	if not core.has_steam():
		_set_bottleneck(result, "Core assembler has no steam", core_block)
		return
	if not pack.has_steam():
		_set_bottleneck(result, "Pack assembler has no steam", pack_block)
		return
	if core.last_status in ["Missing ingredients", "Waiting for ingredients"]:
		_set_bottleneck(result, "Core assembler needs precision parts", core_block)
		return
	if pack.last_status in ["Missing ingredients", "Waiting for ingredients"]:
		_set_bottleneck(result, "Pack assembler needs core steel and coke", pack_block)
		return
	result["reason"] = "Research line is running" if core.processing_active or pack.processing_active else "Research line is ready"
	result["bottleneck"] = "Steam Assemblers limit throughput"
	result["bottleneck_block"] = core_block


static func _apply_steel_line_status(result: Dictionary, line: Dictionary) -> void:
	var coke_block := line["coke_oven"] as WorldBlock
	var blast_block := line["blast_furnace"] as WorldBlock
	var press_block := line["press"] as WorldBlock
	for conveyor_block: WorldBlock in line["conveyors"]:
		if (conveyor_block.machine as ConveyorContainer).jammed:
			_set_bottleneck(result, "Steel conveyor jam", conveyor_block)
			return
	for inserter_block: WorldBlock in line["inserters"]:
		var inserter := inserter_block.machine as MechanicalInserterContainer
		if inserter.status_key == "Destination blocked":
			_set_bottleneck(result, "Steel inserter output blocked", inserter_block)
			return

	var coke_oven := coke_block.machine as CokeOvenContainer
	var blast_furnace := blast_block.machine as PrimitiveBlastFurnaceContainer
	var press := press_block.machine as SteamPressContainer
	var coke_output := coke_oven.slots[CokeOvenContainer.SLOT_OUTPUT] as MachineSlot
	if not coke_output.is_empty() and coke_output.space_for("coke") <= 0:
		_set_bottleneck(result, "Coke oven output blocked", coke_block)
		return
	if not coke_oven.output_tanks.is_empty() and coke_oven.output_tanks[0].space_for("creosote") < CokeOvenContainer.CREOSOTE_PER_COKE:
		_set_bottleneck(result, "Drain creosote from coke oven", coke_block)
		return
	var blast_info := MachineTelemetry.snapshot(blast_furnace)
	var press_info := MachineTelemetry.snapshot(press)
	if str(blast_info.get("reason", "")) == "Output blocked":
		_set_bottleneck(result, "Blast furnace output blocked", blast_block)
		return
	if str(press_info.get("reason", "")) == "Output blocked":
		_set_bottleneck(result, "Steel press output blocked", press_block)
		return
	if not press.has_steam():
		_set_bottleneck(result, "Steel press has no steam", press_block)
		return
	if (coke_oven.slots[CokeOvenContainer.SLOT_INPUT] as MachineSlot).is_empty():
		_set_bottleneck(result, "Add coal to coke oven", coke_block)
		return
	if (blast_furnace.slots[FurnaceContainer.SLOT_FUEL] as MachineSlot).is_empty() and blast_furnace.fuel_remaining <= 0.0:
		_set_bottleneck(result, "Blast furnace needs coke", blast_block)
		return
	if (blast_furnace.slots[FurnaceContainer.SLOT_INPUT] as MachineSlot).is_empty():
		_set_bottleneck(result, "Blast furnace needs iron ingots", blast_block)
		return
	if (press.slots[SteamMachineContainer.SLOT_INPUT] as MachineSlot).is_empty():
		_set_bottleneck(result, "Steel press is waiting for ingots", press_block)
		return
	result["reason"] = "Steel line is running" if coke_oven.processing_active or blast_furnace.is_smelting or press.processing_active else "Steel line is ready"
	result["bottleneck"] = "Coke Oven limits steel throughput"
	result["bottleneck_block"] = coke_block


static func _set_bottleneck(result: Dictionary, reason: String, block: WorldBlock) -> void:
	result["reason"] = reason
	result["bottleneck"] = reason
	result["bottleneck_block"] = block

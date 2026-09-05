extends Node
class_name FluidNetworkManager

const PIPE_IDS: Dictionary = {
	"fluid_pipe": true,
	"fluid_pipe_t2": true,
	"fluid_valve": true,
}
const PIPE_RATES: Dictionary = {
	"fluid_pipe": 12.0,
	"fluid_pipe_t2": 30.0,
	"fluid_valve": 30.0,
}
const DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]
const TRANSFER_RATE := 12.0
const T2_TRANSFER_RATE := 30.0

var _wim: Node = null
var _networks: Array[Dictionary] = []
var _tutorial_report_timer := 0.0


func _ready() -> void:
	_wim = get_tree().get_first_node_in_group("world_interaction")


func get_network_snapshot() -> Array[Dictionary]:
	return _networks.duplicate(true)


func _process(delta: float) -> void:
	if _wim == null:
		_wim = get_tree().get_first_node_in_group("world_interaction")
		return
	_distribute(delta)
	_tutorial_report_timer -= delta
	if _tutorial_report_timer <= 0.0:
		_tutorial_report_timer = 0.75
		_report_healthy_steam_network()


func _report_healthy_steam_network() -> void:
	for network: Dictionary in _networks:
		if not bool(network.get("healthy", false)):
			continue
		QuestManager.report_event("steam_grid_online", "healthy", 1)
		return


func _distribute(delta: float) -> void:
	var placed: Dictionary = _wim._placed_blocks
	var visited: Dictionary = {}
	_networks.clear()
	for grid_pos: Vector2i in placed:
		var block: WorldBlock = placed.get(grid_pos) as WorldBlock
		if block == null or not PIPE_IDS.has(block.block_id) or visited.has(grid_pos):
			continue
		var machines: Array[FluidMachineContainer] = []
		var queue: Array[Vector2i] = [grid_pos]
		var network_tiles: Array[Vector2i] = []
		var conductors: Dictionary = {}
		var attachments: Dictionary = {}
		visited[grid_pos] = true
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			conductors[current] = placed.get(current)
			if not network_tiles.has(current):
				network_tiles.append(current)
			for direction: Vector2i in DIRS:
				var neighbor_pos := current + direction
				var neighbor: WorldBlock = placed.get(neighbor_pos) as WorldBlock
				if neighbor == null:
					continue
				if PIPE_IDS.has(neighbor.block_id):
					if not visited.has(neighbor_pos):
						visited[neighbor_pos] = true
						queue.append(neighbor_pos)
				elif neighbor.machine is FluidMachineContainer:
					var fluid_machine := neighbor.machine as FluidMachineContainer
					if not machines.has(fluid_machine):
						machines.append(fluid_machine)
					var machine_id := fluid_machine.get_instance_id()
					var machine_attachments: Array = attachments.get(machine_id, [])
					var attachment := {
						"conductor": current,
						"machine_pos": neighbor.center_tile(),
					}
					if not machine_attachments.has(attachment):
						machine_attachments.append(attachment)
					attachments[machine_id] = machine_attachments
					if not network_tiles.has(neighbor.center_tile()):
						network_tiles.append(neighbor.center_tile())
		var network_rate := _network_rate(conductors)
		var routing := {"conductors": conductors, "attachments": attachments}
		var transferred := _transfer_network(machines, network_rate * delta, routing)
		_networks.append(_network_stats(machines, network_tiles, transferred, delta, network_rate))


func _transfer_network(
		machines: Array[FluidMachineContainer],
		budget: float,
		routing: Dictionary = {}
) -> Dictionary:
	var transferred: Dictionary = {}
	var network_budget := maxf(budget, 0.0)
	var producers := machines.duplicate()
	producers.sort_custom(func(a: FluidMachineContainer, b: FluidMachineContainer) -> bool:
		var a_ids := a.get_output_fluid_ids()
		var b_ids := b.get_output_fluid_ids()
		var a_priority := a.fluid_output_priority(a_ids[0]) if not a_ids.is_empty() else -1
		var b_priority := b.fluid_output_priority(b_ids[0]) if not b_ids.is_empty() else -1
		return a_priority > b_priority
	)
	for producer_value: Variant in producers:
		if network_budget <= 0.0001:
			break
		var producer := producer_value as FluidMachineContainer
		for fluid_id: String in producer.get_output_fluid_ids():
			var producer_budget := minf(network_budget, producer.get_available_output(fluid_id))
			if producer_budget <= 0.0:
				continue
			var consumers: Array[FluidMachineContainer] = []
			for candidate: FluidMachineContainer in machines:
				if candidate == producer or not candidate.can_accept_fluid(fluid_id):
					continue
				if producer.is_storage_machine() and candidate.is_storage_machine():
					continue
				if not _route_allows_fluid(producer, candidate, fluid_id, routing):
					continue
				consumers.append(candidate)
			consumers.sort_custom(func(a: FluidMachineContainer, b: FluidMachineContainer) -> bool:
				return a.fluid_input_priority(fluid_id) > b.fluid_input_priority(fluid_id)
			)
			for consumer: FluidMachineContainer in consumers:
				var accepted := consumer.push_fluid(fluid_id, producer_budget)
				if accepted <= 0.0:
					continue
				producer.pull_fluid(fluid_id, accepted)
				producer_budget -= accepted
				network_budget -= accepted
				transferred[fluid_id] = float(transferred.get(fluid_id, 0.0)) + accepted
				if producer_budget <= 0.0001 or network_budget <= 0.0001:
					break
	return transferred


func _network_rate(conductors: Dictionary) -> float:
	var network_rate := T2_TRANSFER_RATE
	var found_conductor := false
	for block_value: Variant in conductors.values():
		var block := block_value as WorldBlock
		if block == null:
			continue
		found_conductor = true
		network_rate = minf(network_rate, float(PIPE_RATES.get(block.block_id, TRANSFER_RATE)))
	return network_rate if found_conductor else TRANSFER_RATE


func _route_allows_fluid(
		producer: FluidMachineContainer,
		consumer: FluidMachineContainer,
		fluid_id: String,
		routing: Dictionary
) -> bool:
	if routing.is_empty():
		return true
	var conductors_value: Variant = routing.get("conductors", {})
	var attachments_value: Variant = routing.get("attachments", {})
	if not conductors_value is Dictionary or not attachments_value is Dictionary:
		return false
	var conductors := conductors_value as Dictionary
	var attachments := attachments_value as Dictionary
	var starts_value: Variant = attachments.get(producer.get_instance_id(), [])
	var goals_value: Variant = attachments.get(consumer.get_instance_id(), [])
	if not starts_value is Array or not goals_value is Array:
		return false
	var starts := starts_value as Array
	var goals := goals_value as Array
	if starts.is_empty() or goals.is_empty():
		return false
	var source_fill_ratio := _output_fill_ratio(producer, fluid_id)

	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}
	for attachment_value: Variant in starts:
		if not attachment_value is Dictionary:
			continue
		var attachment := attachment_value as Dictionary
		if not _attachment_allows_entry(attachment, fluid_id, source_fill_ratio, conductors):
			continue
		var conductor_pos: Vector2i = attachment.get("conductor", Vector2i.ZERO)
		if conductors.has(conductor_pos) and not visited.has(conductor_pos):
			visited[conductor_pos] = true
			queue.append(conductor_pos)

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for goal_value: Variant in goals:
			if goal_value is Dictionary and _attachment_allows_exit(
					current, goal_value as Dictionary, fluid_id, source_fill_ratio, conductors
			):
				return true
		for direction: Vector2i in DIRS:
			var neighbor := current + direction
			if visited.has(neighbor) or not conductors.has(neighbor):
				continue
			if not _can_traverse(current, neighbor, fluid_id, source_fill_ratio, conductors):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return false


func _attachment_allows_entry(
		attachment: Dictionary,
		fluid_id: String,
		source_fill_ratio: float,
		conductors: Dictionary
) -> bool:
	var conductor_pos: Vector2i = attachment.get("conductor", Vector2i.ZERO)
	var valve := _valve_at(conductor_pos, conductors)
	if valve == null:
		return true
	var machine_pos: Vector2i = attachment.get("machine_pos", Vector2i.ZERO)
	return valve.allows_fluid(fluid_id, source_fill_ratio) \
		and machine_pos == conductor_pos - WorldBlock.FACING_DIRS[valve.facing]


func _attachment_allows_exit(
		conductor_pos: Vector2i,
		attachment: Dictionary,
		fluid_id: String,
		source_fill_ratio: float,
		conductors: Dictionary
) -> bool:
	if attachment.get("conductor", Vector2i.ZERO) != conductor_pos:
		return false
	var valve := _valve_at(conductor_pos, conductors)
	if valve == null:
		return true
	var machine_pos: Vector2i = attachment.get("machine_pos", Vector2i.ZERO)
	return valve.allows_fluid(fluid_id, source_fill_ratio) \
		and machine_pos == conductor_pos + WorldBlock.FACING_DIRS[valve.facing]


func _can_traverse(
		from_pos: Vector2i,
		to_pos: Vector2i,
		fluid_id: String,
		source_fill_ratio: float,
		conductors: Dictionary
) -> bool:
	var from_valve := _valve_at(from_pos, conductors)
	if from_valve != null:
		if not from_valve.allows_fluid(fluid_id, source_fill_ratio) \
				or to_pos != from_pos + WorldBlock.FACING_DIRS[from_valve.facing]:
			return false
	var to_valve := _valve_at(to_pos, conductors)
	if to_valve != null:
		if not to_valve.allows_fluid(fluid_id, source_fill_ratio) \
				or from_pos != to_pos - WorldBlock.FACING_DIRS[to_valve.facing]:
			return false
	return true


func _output_fill_ratio(machine: FluidMachineContainer, fluid_id: String) -> float:
	var amount := 0.0
	var capacity := 0.0
	for tank: FluidTank in machine.output_tanks + machine.storage_tanks:
		if tank.fluid_id != fluid_id:
			continue
		amount += tank.amount
		capacity += tank.capacity
	return clampf(amount / capacity, 0.0, 1.0) if capacity > 0.0 else 0.0


func _valve_at(grid_pos: Vector2i, conductors: Dictionary) -> FluidValveContainer:
	var block := conductors.get(grid_pos) as WorldBlock
	if block != null and block.machine is FluidValveContainer:
		return block.machine as FluidValveContainer
	return null


func _network_stats(
		machines: Array[FluidMachineContainer],
		tiles: Array[Vector2i],
		transferred: Dictionary,
		delta: float,
		network_rate: float = TRANSFER_RATE
) -> Dictionary:
	var boilers := 0
	var consumers := 0
	var installed_capacity := 0.0
	var online_capacity := 0.0
	var connected_demand := 0.0
	var active_demand := 0.0
	var steam_buffer := 0.0
	var source_steam := 0.0
	var starved: Array[Dictionary] = []
	var fluid_ids := PackedStringArray()
	for machine: FluidMachineContainer in machines:
		for fluid_id: String in machine.get_output_fluid_ids():
			if not fluid_ids.has(fluid_id):
				fluid_ids.append(fluid_id)
		var output_steam := machine.get_available_output("steam")
		source_steam += output_steam
		steam_buffer += output_steam
		if machine is SteamBoilerContainer:
			var boiler := machine as SteamBoilerContainer
			boilers += 1
			installed_capacity += boiler.steam_per_second
			if _boiler_ready(boiler):
				online_capacity += boiler.steam_per_second
		elif machine is SteamMachineContainer:
			var steam_machine := machine as SteamMachineContainer
			consumers += 1
			connected_demand += steam_machine.steam_per_second
			if not steam_machine.input_tanks.is_empty():
				steam_buffer += steam_machine.input_tanks[0].amount
			if _steam_work_waiting(steam_machine):
				active_demand += steam_machine.steam_per_second
				if not steam_machine.has_steam():
					starved.append({
						"name": steam_machine.machine_title,
						"grid_pos": steam_machine.source_grid_pos,
					})
	var elapsed := maxf(delta, 0.0001)
	var total_flow := 0.0
	for fluid_id: Variant in transferred:
		var flow := float(transferred[fluid_id]) / elapsed
		total_flow += flow
		if not fluid_ids.has(str(fluid_id)):
			fluid_ids.append(str(fluid_id))
	var steam_flow := float(transferred.get("steam", 0.0)) / elapsed
	var installed_delivery := minf(installed_capacity, network_rate)
	var buffered_delivery := minf(source_steam / elapsed, network_rate)
	var available_delivery := minf(maxf(online_capacity, maxf(buffered_delivery, steam_flow)), network_rate)
	var connected_deficit := maxf(connected_demand - installed_delivery, 0.0)
	var active_deficit := maxf(active_demand - available_delivery, 0.0)
	var healthy := boilers > 0 and consumers > 0 and connected_deficit <= 0.01 \
		and online_capacity > 0.0 and starved.is_empty()
	return {
		"tiles": tiles,
		"fluids": fluid_ids,
		"boilers": boilers,
		"consumers": consumers,
		"installed_capacity": installed_capacity,
		"online_capacity": online_capacity,
		"connected_demand": connected_demand,
		"active_demand": active_demand,
		"connected_deficit": connected_deficit,
		"active_deficit": active_deficit,
		"steam_flow": steam_flow,
		"total_flow": total_flow,
		"transfer_rate": network_rate,
		"utilization": total_flow / maxf(network_rate, 0.0001),
		"steam_buffer": steam_buffer,
		"starved": starved,
		"starved_count": starved.size(),
		"healthy": healthy,
		"offline": boilers <= 0 and steam_buffer <= 0.01,
	}


func _boiler_ready(boiler: SteamBoilerContainer) -> bool:
	var has_water := boiler.input_tanks[SteamBoilerContainer.TANK_WATER].amount > 0.0
	var has_fuel := boiler.is_burning() \
		or not (boiler.slots[SteamBoilerContainer.SLOT_FUEL] as MachineSlot).is_empty() \
		or boiler.input_tanks[SteamBoilerContainer.TANK_CREOSOTE].amount >= 1.0
	return has_water and has_fuel


func _steam_work_waiting(machine: SteamMachineContainer) -> bool:
	if machine.processing_active:
		return true
	for slot: MachineSlot in machine.slots:
		if slot.role == MachineSlot.Role.INPUT and not slot.is_empty():
			return true
	return false

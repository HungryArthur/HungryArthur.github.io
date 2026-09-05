extends Node
class_name PowerNetworkManager

## Block IDs that conduct electricity but are not machines themselves.
const WIRE_IDS: Dictionary = {
	"tin_wire": true,
	"insulated_tin_wire": true,
	"copper_wire": true,
	"insulated_copper_wire": true,
	"gold_wire": true,
	"insulated_gold_wire": true,
	"fiberglass_wire": true,
}

## Network throughput is limited by its weakest wire. Conveyor-only branches do
## not introduce a cable limit, but still inherit the limit of the wire feeding
## them. Values are EU per second.
const WIRE_CAPACITY_EU_S: Dictionary = {
	"tin_wire": 32.0,
	"insulated_tin_wire": 32.0,
	"copper_wire": 64.0,
	"insulated_copper_wire": 64.0,
	"gold_wire": 256.0,
	"insulated_gold_wire": 256.0,
	"fiberglass_wire": 1024.0,
}

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]

var _wim: Node = null
var _networks: Array[Dictionary] = []
var _tutorial_report_timer := 0.0


func _ready() -> void:
	add_to_group("power_network")
	_wim = get_tree().get_first_node_in_group("world_interaction")


func get_network_snapshot() -> Array[Dictionary]:
	return _networks.duplicate(true)


## A bare wire is hazardous only while its conductor network is connected to a
## generator or an energy storage block. Dead, unfinished wiring is safe to lay.
func is_wire_live(p_grid_pos: Vector2i) -> bool:
	for network: Dictionary in _networks:
		if bool(network.get("offline", true)):
			continue
		var tiles: Array = network.get("tiles", []) as Array
		if tiles.has(p_grid_pos):
			return true
	return false


func _process(delta: float) -> void:
	if _wim == null:
		_wim = get_tree().get_first_node_in_group("world_interaction")
		return
	_distribute(delta)
	_tutorial_report_timer -= delta
	if _tutorial_report_timer <= 0.0:
		_tutorial_report_timer = 0.75
		_report_healthy_grid()


func _report_healthy_grid() -> void:
	var reported_tutorial := false
	var stable_grid := false
	for network: Dictionary in _networks:
		if bool(network.get("offline", false)):
			continue
		if int(network.get("generators", 0)) <= 0 or int(network.get("consumers", 0)) <= 0:
			continue
		if float(network.get("deficit", 0.0)) > 0.01:
			continue
		if not reported_tutorial:
			QuestManager.report_event("power_grid_online", "healthy", 1)
			reported_tutorial = true
		if int(network.get("consumers", 0)) >= 5 and float(network.get("delivered", 0.0)) > 0.0:
			stable_grid = true
	AchievementDB.sync_from_factory(get_tree().get_nodes_in_group("factory_machine").size(), stable_grid)


## A block that carries power through the network: a wire, or a conveyor (belts
## relay power to adjacent belts so a line only needs one connection to a wire).
func _is_conductor(blk: WorldBlock) -> bool:
	if blk == null:
		return false
	return WIRE_IDS.has(blk.block_id) or blk.machine is ConveyorContainer


func _distribute(delta: float) -> void:
	var placed: Dictionary = _wim._placed_blocks
	var wire_visited: Dictionary = {}
	_networks.clear()

	# Reset per-tick stats for generators and storage buffers.
	for gpos: Vector2i in placed.keys():
		var blk: WorldBlock = placed.get(gpos) as WorldBlock
		if blk == null:
			continue
		if blk.machine is GeneratorContainer:
			var gen := blk.machine as GeneratorContainer
			gen.connected_machines = 0
			gen.eu_delivered_last_tick = 0.0
		elif blk.machine is EnergyStorageContainer:
			(blk.machine as EnergyStorageContainer).io_last_tick = 0.0

	for gpos: Vector2i in placed.keys():
		var blk: WorldBlock = placed.get(gpos) as WorldBlock
		# Wires and conveyors both conduct power (belts distribute it down a line,
		# so wiring one belt powers the whole chain). Seed the flood from either.
		if not _is_conductor(blk):
			continue
		if wire_visited.has(gpos):
			continue

		# BFS flood-fill through this conductor network.
		var queue: Array[Vector2i] = [gpos]
		wire_visited[gpos] = true
		var generators: Array = []  # GeneratorContainer
		var consumers:  Array = []  # PoweredMachineContainer (incl. conveyors)
		var storages:   Array = []  # EnergyStorageContainer
		var network_tiles: Array[Vector2i] = []
		var transfer_capacity_eu_s := -1.0

		# A seed conveyor is itself a consumer.
		if blk.machine is ConveyorContainer:
			consumers.append(blk.machine)

		while not queue.is_empty():
			var cur: Vector2i = queue.pop_front()
			if not network_tiles.has(cur):
				network_tiles.append(cur)
			var current_block: WorldBlock = placed.get(cur) as WorldBlock
			if current_block != null and WIRE_CAPACITY_EU_S.has(current_block.block_id):
				var wire_capacity := float(WIRE_CAPACITY_EU_S[current_block.block_id])
				transfer_capacity_eu_s = wire_capacity if transfer_capacity_eu_s < 0.0 \
					else minf(transfer_capacity_eu_s, wire_capacity)
			for dir: Vector2i in DIRS:
				var npos: Vector2i = cur + dir
				if wire_visited.has(npos):
					continue
				var nblk: WorldBlock = placed.get(npos) as WorldBlock
				if nblk == null:
					continue
				if WIRE_IDS.has(nblk.block_id):
					wire_visited[npos] = true
					queue.append(npos)
				elif nblk.machine is ConveyorContainer:
					# Conducts power AND draws it.
					wire_visited[npos] = true
					queue.append(npos)
					if not consumers.has(nblk.machine):
						consumers.append(nblk.machine)
				elif nblk.machine is GeneratorContainer:
					if not generators.has(nblk.machine):
						generators.append(nblk.machine)
					if not network_tiles.has(npos):
						network_tiles.append(npos)
				elif nblk.machine is EnergyStorageContainer:
					if not storages.has(nblk.machine):
						storages.append(nblk.machine)
					if not network_tiles.has(npos):
						network_tiles.append(npos)
				elif nblk.machine is PoweredMachineContainer:
					if not consumers.has(nblk.machine):
						consumers.append(nblk.machine)
					if not network_tiles.has(npos):
						network_tiles.append(npos)

		if generators.is_empty() and storages.is_empty():
			_networks.append({"tiles": network_tiles, "offline": true, "generation": 0.0, "demand": 0.0, "deficit": 0.0, "capacity_eu_s": transfer_capacity_eu_s})
			continue
		if consumers.is_empty() and storages.is_empty():
			_networks.append({"tiles": network_tiles, "offline": false, "generation": 0.0, "demand": 0.0, "deficit": 0.0, "capacity_eu_s": transfer_capacity_eu_s})
			continue

		var stats := _balance(generators, consumers, storages, delta, transfer_capacity_eu_s)
		stats["tiles"] = network_tiles
		stats["offline"] = false
		_networks.append(stats)


## Balances one wire network: generation feeds consumers first, surplus charges
## storage, and storage discharges to cover any remaining consumer deficit.
func _balance(
	generators: Array,
	consumers: Array,
	storages: Array,
	delta: float,
	transfer_capacity_eu_s: float
) -> Dictionary:
	var consumer_room: float = 0.0
	for c: PoweredMachineContainer in consumers:
		consumer_room += maxf(c.effective_power_capacity() - c.power_stored, 0.0)

	var storage_room: float = 0.0
	for s: EnergyStorageContainer in storages:
		storage_room += s.charge_room(delta)

	# Generators only burn fuel when something needs the energy. Каждому
	# передаётся остаток спроса: буферизованные (солнечные) отдают ровно его,
	# и как только спрос закрыт, остальные не тратят топливо.
	var generation: float = 0.0
	var demand: float = consumer_room + storage_room
	var transfer_budget := demand if transfer_capacity_eu_s < 0.0 \
		else minf(demand, transfer_capacity_eu_s * delta)
	if transfer_budget > 0.0:
		for gen: GeneratorContainer in generators:
			if generation >= transfer_budget:
				break
			generation += gen.produce(delta, transfer_budget - generation)
	# Generation serves consumers first; the remainder is surplus for storage.
	var for_consumers: float = minf(minf(generation, consumer_room), transfer_budget)
	var surplus: float = minf(generation - for_consumers, transfer_budget - for_consumers)
	var deficit: float = consumer_room - for_consumers

	# Cover the remaining consumer demand from storage.
	var from_storage: float = 0.0
	var discharge_budget := maxf(transfer_budget - for_consumers, 0.0)
	for s: EnergyStorageContainer in storages:
		if deficit <= 0.0 or discharge_budget <= 0.0:
			break
		var got := s.discharge(minf(deficit, discharge_budget), delta)
		from_storage += got
		deficit -= got
		discharge_budget -= got

	_deliver(consumers, for_consumers + from_storage)

	# Charge storage with leftover generation.
	for s: EnergyStorageContainer in storages:
		if surplus <= 0.0:
			break
		surplus -= s.charge(surplus, delta)

	# Generator UI stats.
	for gen: GeneratorContainer in generators:
		gen.connected_machines = consumers.size() + storages.size()
		gen.eu_delivered_last_tick = gen.eu_per_second if generation > 0.0 else 0.0
	return {
		"generation": generation,
		"demand": consumer_room + storage_room,
		"delivered": for_consumers + from_storage,
		"deficit": maxf(deficit, 0.0),
		"consumers": consumers.size(),
		"generators": generators.size(),
		"storages": storages.size(),
		"capacity_eu_s": transfer_capacity_eu_s,
	}


## Distributes `amount` EU across consumers in proportion to their free buffer
## room, so none overflows while energy is wasted elsewhere.
func _deliver(consumers: Array, amount: float) -> void:
	if amount <= 0.0 or consumers.is_empty():
		return
	var total_room: float = 0.0
	for c: PoweredMachineContainer in consumers:
		total_room += maxf(c.effective_power_capacity() - c.power_stored, 0.0)
	if total_room <= 0.0:
		return
	for c: PoweredMachineContainer in consumers:
		var room := maxf(c.effective_power_capacity() - c.power_stored, 0.0)
		c.receive_power(amount * (room / total_room))

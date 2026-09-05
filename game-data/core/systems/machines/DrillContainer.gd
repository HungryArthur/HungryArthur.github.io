extends PoweredMachineContainer
class_name DrillContainer

## A drill is a 3×3 block placed on a vein core (the centre tile). It auto-mines
## the vein's infinite ore on a timer and ejects it from its OUTPUT side (the
## `facing` direction) into a conveyor/chest; it accepts belt items on its INPUT
## side (opposite). Higher tiers mine faster and reach higher mining levels.

## block_id -> {power, interval, eu_per_s}. power is compared against a deposit's
## mining_level_required; interval is seconds between ore units; eu_per_s is the
## EU drain while actively mining (the primitive tier digs for free). `no_output`
## drills (the primitive tier) have no output side: they cannot eject onto a
## belt/chest and instead accumulate ore in an internal buffer the player opens
## and empties by hand (see `storage`).
const TIERS: Dictionary = {
	"primitive_drill": {"power": 1, "interval": 4.0, "no_output": true},
	"bronze_drill":    {"power": 2, "interval": 3.0, "eu_per_s": 10.0},
	"steel_drill":     {"power": 3, "interval": 2.2, "eu_per_s": 20.0},
	"titanium_drill":  {"power": 4, "interval": 1.5, "eu_per_s": 40.0},
	"advanced_drill":  {"power": 5, "interval": 1.0, "eu_per_s": 80.0},
}

## EU buffer holds this many seconds of active mining.
const POWER_BUFFER_SECONDS := 10.0

const BUFFER_SLOTS := 2

var source_grid_pos: Vector2i = Vector2i.ZERO   # the vein-core / footprint centre
var power: int = 0
var interval: float = 3.0
var eu_per_s: float = 0.0
var facing: int = 2

## Set for the primitive tier: skip output ejection, mine into `storage` instead.
var no_output: bool = false
## Internal buffer for no-output drills (a small ChestInventoryComponent on the
## host WorldBlock, opened via the chest UI). Null for normal drills.
var storage: ChestInventoryComponent = null

var _timer: float = 0.0


func set_facing(new_facing: int) -> void:
	facing = ((new_facing % 4) + 4) % 4


func _init() -> void:
	for _i in BUFFER_SLOTS:
		var slot := MachineSlot.new()
		slot.role = MachineSlot.Role.OUTPUT
		slots.append(slot)


## Drill tier comes from the block id (bronze_drill, steel_drill, ...).
static func tier_power(block_id: String) -> int:
	var cfg: Variant = TIERS.get(block_id)
	return int(cfg.get("power", 0)) if cfg is Dictionary else 0


static func is_drill_block(block_id: String) -> bool:
	return TIERS.has(block_id)


## A no-output drill: mines into an internal buffer instead of ejecting. The host
## WorldBlock gives it a ChestInventoryComponent and opens it via the chest UI.
static func is_buffer_drill(block_id: String) -> bool:
	var cfg: Variant = TIERS.get(block_id)
	return cfg is Dictionary and bool((cfg as Dictionary).get("no_output", false))


func set_block_id(block_id: String) -> void:
	var cfg: Variant = TIERS.get(block_id)
	if cfg is Dictionary:
		power = int(cfg.get("power", 0))
		interval = float(cfg.get("interval", 3.0))
		no_output = bool(cfg.get("no_output", false))
		eu_per_s = float(cfg.get("eu_per_s", 0.0))
		requires_power = eu_per_s > 0.0
		power_capacity = eu_per_s * POWER_BUFFER_SECONDS
		machine_title = block_id.capitalize()


## Wires the internal buffer used by no-output drills (called on placement).
func set_storage(component: ChestInventoryComponent) -> void:
	storage = component


func set_source_grid_pos(grid_pos: Vector2i) -> void:
	source_grid_pos = grid_pos


func tick(delta: float) -> void:
	# Normal drills keep the output flowing out the output side every tick.
	# No-output drills have no output side and skip this entirely.
	if not no_output:
		_eject_output()

	processing_active = false
	if power <= 0:
		return

	var world: Node = get_tree().get_first_node_in_group("world")
	if world == null or not world.has_method("get_ore_core_deposit_at"):
		return
	var deposit: DepositData = world.get_ore_core_deposit_at(source_grid_pos)
	if deposit == null:
		return  # Drill is no longer sitting on a valid core.
	var required_level: int = deposit.mining_level_required
	if world.has_method("get_required_mining_level"):
		required_level = world.get_required_mining_level(source_grid_pos, deposit)
	if power < required_level:
		return  # Tier too low for this ore (hard sectors need advanced drills).

	# Back-pressure: don't mine if the buffer (internal, or slots for normal
	# drills) is full. A full no-output drill just idles until the player empties it.
	if no_output:
		if storage == null or not storage.has_space_for(deposit.resource_item_id):
			return
	elif _buffer_space_for(deposit.resource_item_id) <= 0:
		return

	# Powered tiers spin on EU: no charge — no mining (the cycle pauses, it does
	# not reset). Idle drills (no vein / full buffer) drain nothing.
	if requires_power:
		if power_stored <= 0.0:
			return
		power_stored = maxf(power_stored - eu_per_s * delta, 0.0)
	processing_active = true

	_timer += delta
	if _timer < interval:
		return
	_timer = 0.0

	var result: Dictionary = world.mine_ore_at(source_grid_pos, power, "drill")
	if not bool(result.get("handled", false)) or bool(result.get("blocked", false)):
		return
	var yield_stack: Variant = result.get("yield_stack", {})
	if yield_stack is Dictionary and not (yield_stack as Dictionary).is_empty():
		QuestManager.report_event(
			"mine_yield",
			str((yield_stack as Dictionary).get("id", "")),
			int((yield_stack as Dictionary).get("count", 1))
		)
		if no_output:
			storage.push_item(yield_stack as Dictionary)  # space pre-checked above
		else:
			_store(yield_stack as Dictionary)
			_eject_output()


## Belt items arriving on the drill's INPUT side are merged into its buffer (and
## leave via the output with the ore). Deliveries to any other side are refused.
func accept_from_belt(stack: Dictionary, target_tile: Vector2i) -> Dictionary:
	var input_tile: Vector2i = source_grid_pos - WorldBlock.FACING_DIRS[facing]
	if target_tile != input_tile:
		return stack
	var remaining: Dictionary = stack
	for i in slots.size():
		if remaining.is_empty():
			break
		remaining = slots[i].insert(remaining)
		slot_changed.emit(i)
	return remaining


## [0, 1] progress of the current mining cycle (drives the menu's progress bar).
func process_progress() -> float:
	if interval <= 0.0:
		return 0.0
	return clampf(_timer / interval, 0.0, 1.0)


## True when the ore buffer cannot accept another unit of `item_id`.
func buffer_full_for(item_id: String) -> bool:
	return _buffer_space_for(item_id) <= 0


func _buffer_space_for(item_id: String) -> int:
	var total: int = 0
	for slot: MachineSlot in slots:
		total += slot.space_for(item_id)
	return total


## Tile immediately outside the drill's 3x3 footprint, on the arrow side.
## This is the only automatic output port for powered drill tiers.
func output_grid_pos() -> Vector2i:
	return source_grid_pos + WorldBlock.FACING_DIRS[facing] * 2


## Lightweight output diagnostics for the drill menu and tutorials.
## state: manual | disconnected | connected | blocked
## kind:  conveyor | chest | machine | unsupported
func output_connection_info(item_id: String = "") -> Dictionary:
	if no_output:
		return {"state": "manual", "kind": "manual", "tile": output_grid_pos()}
	var wim: Node = get_tree().get_first_node_in_group("world_interaction")
	if wim == null or not wim.has_method("get_block_at"):
		return {"state": "disconnected", "kind": "none", "tile": output_grid_pos()}
	var block: WorldBlock = wim.get_block_at(output_grid_pos()) as WorldBlock
	if block == null:
		return {"state": "disconnected", "kind": "none", "tile": output_grid_pos()}
	if block.machine is ConveyorContainer:
		var belt := block.machine as ConveyorContainer
		var blocked := not belt.carried.is_empty() or (
			not item_id.is_empty() and not belt.accepts_item(item_id)
		)
		return {
			"state": "blocked" if blocked else "connected",
			"kind": "conveyor",
			"tile": output_grid_pos(),
		}
	if block.chest_inventory != null:
		var blocked := not item_id.is_empty() and not block.chest_inventory.has_space_for(item_id)
		return {
			"state": "blocked" if blocked else "connected",
			"kind": "chest",
			"tile": output_grid_pos(),
		}
	if block.machine != null and block.machine.has_method("find_input_slot_for"):
		var input_slot: int = block.machine.find_input_slot_for(item_id) if not item_id.is_empty() else 0
		return {
			"state": "connected" if input_slot >= 0 else "blocked",
			"kind": "machine",
			"tile": output_grid_pos(),
		}
	return {"state": "blocked", "kind": "unsupported", "tile": output_grid_pos()}


func _store(stack: Dictionary) -> void:
	var remaining: Dictionary = stack
	for i in slots.size():
		if remaining.is_empty():
			break
		remaining = slots[i].insert(remaining)
		slot_changed.emit(i)


## Pushes buffered ore out of the OUTPUT side: the tile just beyond the 3×3
## footprint in the facing direction (a conveyor, chest, or machine input).
func _eject_output() -> void:
	var wim: Node = get_tree().get_first_node_in_group("world_interaction")
	if wim == null or not wim.has_method("get_block_at"):
		return
	var block: WorldBlock = wim.get_block_at(output_grid_pos()) as WorldBlock
	if block == null:
		return
	for i in slots.size():
		var slot: MachineSlot = slots[i]
		if slot.is_empty():
			continue
		var offered: Dictionary = slot.peek()
		var leftover: Dictionary = _push_to(block, offered)
		if block.machine is ConveyorContainer \
				and int(leftover.get("count", 0)) < int(offered.get("count", 0)):
			QuestManager.report_event("drill_output_connected", "conveyor", 1)
		slot.item = leftover
		slot_changed.emit(i)


func _push_to(block: WorldBlock, stack: Dictionary) -> Dictionary:
	if block.machine is ConveyorContainer:
		return (block.machine as ConveyorContainer).try_accept(stack)
	if block.chest_inventory != null:
		var left: Variant = block.chest_inventory.push_item(stack)
		return left if left is Dictionary else {}
	if block.machine != null and block.machine.has_method("find_input_slot_for"):
		var idx: int = block.machine.find_input_slot_for(str(stack.get("id", "")))
		if idx >= 0:
			return block.machine.push_item(idx, stack)
	return stack

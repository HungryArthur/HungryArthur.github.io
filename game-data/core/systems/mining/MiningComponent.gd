extends Node
class_name MiningComponent

## Time-based mining. Holding LMB applies one damage tick per second. The world
## object owns the only HP pool; the held tool's power is literal damage per tick.
##
## LMB works on everything: ore, trees, forage — with any tool and with bare hands.
## Ore vein tiles require a pickaxe of the authored level. They pay out when their
## bar reaches zero and immediately reset, so the same tile can be mined forever.
## Only the central borehole is drill-only.

signal mining_started(deposit: DepositData)
## `bonus` is retained for generic harvestable compatibility; ore never rolls one.
signal mining_yield(yield_stack: Dictionary, world_pos: Vector2, bonus: bool)
signal mining_blocked(reason: String)
signal mining_stopped
## Remaining HP as a 0..1 fraction (1 = untouched tile).
signal progress_changed(progress: float)
## A swing that took HP off — for hit FX (`remaining` is the 0..1 fraction left).
signal hit_landed(grid_pos: Vector2i, remaining: float)
## A swing that did nothing because the tool is wrong, too weak, or targets a core.
signal hit_rejected(reason: String)

## Visual cracks fade after this delay when mining is abandoned.
const REGEN_DELAY := 5.0

var is_mining: bool = false
var mining_target_pos: Vector2i = Vector2i(-9999, -9999)

var _current_deposit: DepositData = null
var _tool_type: String = ""
var _tool_power: int = 0
var _swing_timer: float = 0.0
var _can_damage: bool = true          # false → swings only flash the bar
var _reject_reason: String = ""


func start_mining(grid_pos: Vector2i, tool_power: int, tool_type: String = "pickaxe") -> void:
	var deposit: DepositData = _get_deposit_at(grid_pos)
	if deposit == null:
		return

	mining_target_pos = grid_pos
	_current_deposit = deposit
	_tool_type = tool_type
	_tool_power = maxi(tool_power, 1)
	_reject_reason = _rejection_for(grid_pos, deposit, _tool_power, tool_type)
	_can_damage = _reject_reason == ""
	_swing_timer = 0.0
	is_mining = true
	var remaining := 1.0
	var world := _get_world()
	if world != null and world.has_method("get_mining_health_fraction_at"):
		remaining = float(world.get_mining_health_fraction_at(grid_pos))
	progress_changed.emit(remaining)
	mining_started.emit(deposit)


func stop_mining() -> void:
	if not is_mining:
		return
	is_mining = false
	_current_deposit = null
	_tool_type = ""
	_swing_timer = 0.0
	progress_changed.emit(1.0)
	mining_stopped.emit()


# Called by drills with a fixed power level to produce one yield tick immediately.
func mine_once(grid_pos: Vector2i, tool_power: int, tool_type: String = "pickaxe") -> void:
	var deposit: DepositData = _get_deposit_at(grid_pos)
	if deposit == null:
		return
	var effective_power: int = maxi(tool_power, 1)
	if effective_power < _required_level(grid_pos, deposit):
		return
	_execute_mine_at(grid_pos, deposit, effective_power, tool_type)


func _process(delta: float) -> void:
	if not is_mining:
		return
	_swing_timer += delta
	while is_mining and _swing_timer >= ToolTierSystem.MINING_DAMAGE_INTERVAL:
		_swing_timer -= ToolTierSystem.MINING_DAMAGE_INTERVAL
		_swing()


## One mining tick after a complete second of holding the action.
func _swing() -> void:
	if not _can_damage:
		hit_rejected.emit(_reject_reason)
		return
	_execute_mine_at(mining_target_pos, _current_deposit, _tool_power, _tool_type)


## Kept for compatibility with older network packets. Authoritative mining ticks
## now update the world's single HP pool through apply_remote_mine instead.
func apply_remote_hit(grid_pos: Vector2i, damage: float) -> void:
	if is_mining and grid_pos == mining_target_pos and damage > 0.0:
		var world := _get_world()
		if world != null and world.has_method("get_mining_health_fraction_at"):
			var remaining := float(world.get_mining_health_fraction_at(grid_pos))
			progress_changed.emit(remaining)
			hit_landed.emit(grid_pos, remaining)


## "" when the tool may damage this tile, else the reason the swings bounce off.
## Generic hand-mined objects accept any tool, but ore has an explicit split:
## vein tiles require a pickaxe and the central borehole requires a drill.
func _rejection_for(
	grid_pos: Vector2i,
	deposit: DepositData,
	power: int,
	tool_type: String
) -> String:
	if _is_ore_core(grid_pos) and tool_type != "drill":
		return "requires_drill"
	if _is_ore_body(grid_pos) and tool_type != deposit.required_tool:
		return "requires_pickaxe"
	if power < _required_level(grid_pos, deposit):
		return "too_weak"
	return ""


## True for an infinite hand-mineable vein tile (not the central borehole).
func _is_ore_body(grid_pos: Vector2i) -> bool:
	var world: Node = _get_world()
	if world == null:
		return false
	return world.has_method("is_ore_body_at") and bool(world.is_ore_body_at(grid_pos))


## True only for the centre tile that accepts a placed drill.
func _is_ore_core(grid_pos: Vector2i) -> bool:
	var world: Node = _get_world()
	if world == null:
		return false
	return world.has_method("is_ore_core_at") and bool(world.is_ore_core_at(grid_pos))


func _execute_mine_at(
	grid_pos: Vector2i,
	deposit: DepositData,
	power: int,
	tool_type: String
) -> void:
	if deposit == null:
		stop_mining()
		return

	var world: Node = _get_world()
	if world == null:
		stop_mining()
		return

	var result: Dictionary = world.mine_ore_at(grid_pos, power, tool_type)
	if not bool(result.get("handled", false)):
		stop_mining()
		return

	if bool(result.get("blocked", false)):
		mining_blocked.emit(str(result.get("reason", "")))
		stop_mining()
		return

	var remaining := float(result.get("health_fraction", 0.0))
	hit_landed.emit(grid_pos, remaining)
	progress_changed.emit(remaining)

	var yield_stack: Dictionary = result.get("yield_stack", {}) as Dictionary
	var world_pos: Vector2 = result.get("world_pos", Vector2.ZERO)
	mining_yield.emit(yield_stack, world_pos, bool(result.get("bonus", false)))

	# Optional secondary drop (e.g. an apple off a chopped tree) rides the same
	# yield path so it lands in the inventory and shows its own floating label.
	var extra_stack: Dictionary = result.get("extra_yield_stack", {}) as Dictionary
	if not extra_stack.is_empty():
		mining_yield.emit(extra_stack, world_pos, false)

	# Finite resources (trees, forage) vanish once exhausted. Stop right away so
	# the progress bar doesn't run an extra empty cycle on the cleared tile.
	# Infinite ore deposits keep returning a deposit here, so mining continues.
	if _get_deposit_at(grid_pos) == null:
		stop_mining()


func _get_deposit_at(grid_pos: Vector2i) -> DepositData:
	var world: Node = _get_world()
	if world == null or not world.has_method("get_deposit_at"):
		return null
	return world.get_deposit_at(grid_pos) as DepositData


## Mining level required at this tile — hard sectors raise it (via World).
func _required_level(grid_pos: Vector2i, deposit: DepositData) -> int:
	var world: Node = _get_world()
	if world != null and world.has_method("get_required_mining_level"):
		return int(world.get_required_mining_level(grid_pos, deposit))
	return deposit.mining_level_required


func _get_world() -> Node:
	if get_tree() == null:
		return null
	return get_tree().get_first_node_in_group("world")

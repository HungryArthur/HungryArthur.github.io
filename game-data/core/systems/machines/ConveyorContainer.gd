extends PoweredMachineContainer
class_name ConveyorContainer

## A conveyor carries one item stack across its tile in the direction it faces,
## then hands it to whatever sits on the next tile (another conveyor, a chest, a
## machine input, or a drill's input port). Items are pushed onto belts by the
## source (e.g. a drill output); belts themselves don't pull.
##
## Tier 1 is a slow mechanical belt and needs no EU. Higher tiers draw `tier` EU/s
## from the electrical network; an unpowered belt stops and freezes its animation.

## Default seconds to move an item across the tile (overridden per tier).
const CROSS_TIME := 0.8
const INGREDIENT_DEMAND_MAX_NODES := 128

var source_grid_pos: Vector2i = Vector2i.ZERO
var facing: int = 2
## Travel direction items enter from (set by the WorldBlock belt visual). -1 when
## fed inline / unknown; a perpendicular value makes the carried item turn.
var incoming_dir: int = -1

var carried: Dictionary = {}
var progress: float = 0.0

## Tier drives power draw (tier EU/s) and speed (cross_time). Set via configure_belt.
var tier: int = 1
var cross_time: float = CROSS_TIME
var eu_per_second: float = 1.0
## Whether the belt had enough power to run last tick (drives the visual freeze).
var running: bool = false
var filter_ids := PackedStringArray()
var filter_mode := "allow"
var priority := 0
var jammed := false
var jam_time := 0.0
var downstream_request_active := false
var downstream_requested_types := 0
var downstream_requested_total := 0

var _item_sprite: Sprite2D = null
static var _solid_tex: ImageTexture = null


func _init() -> void:
	machine_title = "CONVEYOR"
	requires_power = true
	power_capacity = 4.0
	# Belts slide the carried item's sprite across the tile — that must update
	# every frame or the movement turns into visible steps.
	tick_interval = 0.0


func _exit_tree() -> void:
	IngredientDemandReservations.release_stack(carried)
	super._exit_tree()


## Applies a tier's power/speed from the block definition (called by WorldBlock).
func configure_belt(p_tier: int, p_cross_time: float) -> void:
	tier = maxi(1, p_tier)
	cross_time = maxf(0.05, p_cross_time)
	eu_per_second = float(tier)
	requires_power = tier > 1
	# A couple of seconds of buffer so brief network dips don't stutter the belt.
	power_capacity = maxf(4.0, eu_per_second * 2.0) if requires_power else 0.0


func set_source_grid_pos(grid_pos: Vector2i) -> void:
	source_grid_pos = grid_pos


func set_facing(new_facing: int) -> void:
	facing = ((new_facing % 4) + 4) % 4


func set_incoming_dir(new_dir: int) -> void:
	incoming_dir = new_dir
	_position_item_sprite()


## Try to place a stack on this belt. Returns leftover (empty = fully accepted).
func try_accept(stack: Dictionary) -> Dictionary:
	if stack.is_empty():
		return {}
	if not accepts_item(str(stack.get("id", ""))):
		return stack
	if not carried.is_empty():
		return stack
	var accepted_stack := stack.duplicate(true)
	var leftover: Dictionary = {}
	if not IngredientDemandReservations.has_reservation(accepted_stack):
		var context := ingredient_request_context()
		if bool(context.get("active", false)):
			var item_id := str(accepted_stack.get("id", ""))
			if int((context.get("requests", {}) as Dictionary).get(item_id, 0)) <= 0:
				return stack
			var reservation := IngredientDemandReservations.reserve(context, item_id, int(accepted_stack.get("count", 0)))
			if reservation.is_empty():
				return stack
			var accepted_count := int(reservation.get("amount", 0))
			var offered_count := int(accepted_stack.get("count", 0))
			if accepted_count < offered_count:
				leftover = accepted_stack.duplicate(true)
				leftover["count"] = offered_count - accepted_count
				accepted_stack["count"] = accepted_count
			accepted_stack = IngredientDemandReservations.attach_to_stack(accepted_stack, reservation)
	else:
		IngredientDemandReservations.restore_stack(accepted_stack)
	carried = accepted_stack
	progress = 0.0
	_refresh_item_sprite()
	return leftover


## Automation output used by inserters. The visual and progress are reset when the
## carried stack is fully removed so no ghost item remains on the belt.
func pull_carried_item(amount: int = 1) -> Dictionary:
	if carried.is_empty() or amount <= 0:
		return {}
	var original_stack := carried.duplicate(true)
	var take := mini(amount, int(carried.get("count", 0)))
	var result := carried.duplicate(true)
	result["count"] = take
	carried["count"] = int(carried.get("count", 0)) - take
	if int(carried.get("count", 0)) <= 0:
		carried = {}
		progress = 0.0
		_clear_item_sprite()
	else:
		var split := IngredientDemandReservations.split_stack(original_stack, result, carried)
		result = split.get("extracted", result) as Dictionary
		carried = split.get("remaining", carried) as Dictionary
		_refresh_item_sprite()
	return result


func tick(delta: float) -> void:
	running = _consume_power(delta)
	_sync_belt_visual()
	if not running:
		jammed = false
		jam_time = 0.0
		_sync_jam_visual()
		return
	if not running or carried.is_empty():
		jammed = false
		jam_time = 0.0
		_sync_jam_visual()
		return
	progress = minf(progress + delta / cross_time, 1.0)
	_position_item_sprite()
	if progress >= 1.0:
		_try_deliver()
		jammed = not carried.is_empty()
		jam_time = jam_time + delta if jammed else 0.0
	else:
		jammed = false
		jam_time = 0.0
	_sync_jam_visual()


func configure_filter(ids: PackedStringArray, mode: String = "allow", belt_priority: int = 0) -> void:
	filter_ids = _sanitized_filter_ids(ids)
	filter_mode = "block" if mode == "block" else "allow"
	priority = clampi(belt_priority, -10, 10)


func network_config_data() -> Dictionary:
	var config := super.network_config_data()
	config["filter_ids"] = Array(filter_ids)
	config["filter_mode"] = filter_mode
	config["priority"] = priority
	return config


func apply_network_config(config: Dictionary) -> void:
	super.apply_network_config(config)
	filter_ids = _sanitized_filter_ids(PackedStringArray(config.get("filter_ids", [])))
	filter_mode = "block" if str(config.get("filter_mode", "allow")) == "block" else "allow"
	priority = clampi(int(config.get("priority", 0)), -10, 10)


func _sanitized_filter_ids(ids: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for raw_id: String in ids:
		var item_id := raw_id.strip_edges().to_lower().replace(" ", "_").left(64)
		if not item_id.is_empty() and not result.has(item_id):
			result.append(item_id)
		if result.size() >= 24:
			break
	return result


func accepts_item(item_id: String) -> bool:
	if filter_ids.is_empty():
		return true
	var listed := filter_ids.has(item_id)
	return not listed if filter_mode == "block" else listed


func ingredient_request_context() -> Dictionary:
	var context := _ingredient_request_context({}, INGREDIENT_DEMAND_MAX_NODES)
	downstream_request_active = bool(context.get("active", false))
	var requests := context.get("requests", {}) as Dictionary
	downstream_requested_types = requests.size()
	downstream_requested_total = 0
	for amount: Variant in requests.values():
		downstream_requested_total += int(amount)
	return context


func uses_ingredient_requests() -> bool:
	return bool(ingredient_request_context().get("active", false))


func ingredient_requests() -> Dictionary:
	return ingredient_request_context().get("requests", {}) as Dictionary


func _ingredient_request_context(visited: Dictionary, remaining: int) -> Dictionary:
	if remaining <= 0 or visited.has(get_instance_id()):
		return _empty_request_context()
	visited[get_instance_id()] = true
	var target := _block_at(source_grid_pos + WorldBlock.FACING_DIRS[facing])
	var context := _request_context_from_block(target, visited, remaining - 1)
	return _filtered_request_context(context)


func _request_context_from_block(block: WorldBlock, visited: Dictionary, remaining: int) -> Dictionary:
	if block == null or remaining < 0:
		return _empty_request_context()
	if block.machine is ConveyorContainer:
		return (block.machine as ConveyorContainer)._ingredient_request_context(visited, remaining)
	if block.chest_inventory != null and block.chest_inventory.has_method("ingredient_request_context"):
		var chest_context: Variant = block.chest_inventory.ingredient_request_context()
		if chest_context is Dictionary:
			return chest_context as Dictionary
	if block.machine != null and block.machine.has_method("ingredient_request_context"):
		var context_value: Variant = block.machine.ingredient_request_context()
		if context_value is Dictionary:
			return context_value as Dictionary
	return _empty_request_context()


func _filtered_request_context(context: Dictionary) -> Dictionary:
	var allocations := (context.get("allocations", {}) as Dictionary).duplicate(true)
	for item_value: Variant in allocations.keys():
		if not accepts_item(str(item_value)):
			allocations.erase(item_value)
	return IngredientDemandReservations.context_from_allocations(bool(context.get("active", false)), allocations)


func _empty_request_context() -> Dictionary:
	return IngredientDemandReservations.context_from_allocations(false, {})


func _block_at(grid_pos: Vector2i) -> WorldBlock:
	var manager := get_tree().get_first_node_in_group("world_interaction")
	if manager == null or not manager.has_method("get_block_at"):
		return null
	return manager.get_block_at(grid_pos) as WorldBlock


## Draws this belt's tier EU for the frame. Returns false (belt stalls) when the
## buffer can't cover it. A running belt always draws, even while empty.
func _consume_power(delta: float) -> bool:
	if not requires_power:
		return true
	var need: float = eu_per_second * delta
	if power_stored < need:
		return false
	power_stored -= need
	return true


## Tells the WorldBlock to run (globally synced) or freeze its belt animation.
func _sync_belt_visual() -> void:
	var parent: Node = get_parent()
	if parent != null and parent.has_method("set_belt_running"):
		parent.set_belt_running(running)


func _sync_jam_visual() -> void:
	var parent: Node = get_parent()
	if parent != null and parent.has_method("set_belt_jammed"):
		parent.set_belt_jammed(jammed and jam_time >= 0.35)


func _try_deliver() -> void:
	var target: Vector2i = source_grid_pos + WorldBlock.FACING_DIRS[facing]
	var block := _block_at(target)
	if block == null:
		return
	var leftover: Dictionary = _hand_off(block, target)
	if leftover.is_empty():
		QuestManager.report_event("conveyor_item_moved", "", 1)
		carried = {}
		progress = 0.0
		_clear_item_sprite()
	else:
		carried = leftover


func _hand_off(block: WorldBlock, target_tile: Vector2i) -> Dictionary:
	var stack: Dictionary = carried.duplicate(true)
	# Next conveyor.
	if block.machine is ConveyorContainer:
		var conveyor := block.machine as ConveyorContainer
		var context := conveyor.ingredient_request_context()
		if bool(context.get("active", false)) \
			and int((context.get("requests", {}) as Dictionary).get(str(stack.get("id", "")), 0)) <= 0 \
			and not IngredientDemandReservations.reservation_matches_context(stack, context):
			return stack
		return conveyor.try_accept(stack)
	# Drill input port (only accepts on its designated input side).
	if block.machine != null and block.machine.has_method("accept_from_belt"):
		var payload := IngredientDemandReservations.payload_without_reservation(stack)
		var leftover: Dictionary = block.machine.accept_from_belt(payload, target_tile)
		if leftover.is_empty():
			IngredientDemandReservations.release_stack(stack)
			return {}
		return stack
	# Chest.
	if block.chest_inventory != null:
		var context := block.chest_inventory.ingredient_request_context()
		if bool(context.get("active", false)) \
			and int((context.get("requests", {}) as Dictionary).get(str(stack.get("id", "")), 0)) <= 0 \
			and not IngredientDemandReservations.reservation_matches_context(stack, context):
			return stack
		var payload := IngredientDemandReservations.payload_without_reservation(stack)
		var left: Variant = block.chest_inventory.push_item(payload)
		if not left is Dictionary or (left as Dictionary).is_empty():
			IngredientDemandReservations.release_stack(stack)
			return {}
		return stack
	# Generic machine input slot.
	if block.machine != null and block.machine.has_method("find_input_slot_for"):
		if block.machine.has_method("ingredient_request_context"):
			var context_value: Variant = block.machine.ingredient_request_context()
			if context_value is Dictionary and bool((context_value as Dictionary).get("active", false)) \
				and int(((context_value as Dictionary).get("requests", {}) as Dictionary).get(str(stack.get("id", "")), 0)) <= 0 \
				and not IngredientDemandReservations.reservation_matches_context(stack, context_value as Dictionary):
				return stack
		var slot_idx: int = block.machine.find_input_slot_for(str(stack.get("id", "")))
		if slot_idx >= 0:
			var payload := IngredientDemandReservations.payload_without_reservation(stack)
			var leftover := block.machine.push_item(slot_idx, payload)
			if leftover.is_empty():
				IngredientDemandReservations.release_stack(stack)
				return {}
			return stack
	return stack


# ── Visuals ───────────────────────────────────────────────────────────────────

func _refresh_item_sprite() -> void:
	if carried.is_empty():
		_clear_item_sprite()
		return
	var parent := get_parent()
	if not (parent is Node2D):
		return
	if _item_sprite == null:
		_item_sprite = Sprite2D.new()
		_item_sprite.z_index = 6
		(parent as Node2D).add_child(_item_sprite)
	var tex: Variant = carried.get("texture")
	if tex is Texture2D:
		_item_sprite.texture = tex
		_item_sprite.self_modulate = Color.WHITE
	else:
		_item_sprite.texture = _get_solid_tex()
		_item_sprite.self_modulate = carried.get("color", Color.WHITE)
	# Scale down to ~half a tile so the item reads as "on" the belt.
	var tex_w: float = float(maxi(_item_sprite.texture.get_width(), 1))
	_item_sprite.scale = Vector2.ONE * (float(GameConstants.TILE_SIZE) * 0.5 / tex_w)
	_position_item_sprite()


func _position_item_sprite() -> void:
	if _item_sprite == null:
		return
	var half := float(GameConstants.TILE_SIZE) * 0.5
	var out_vec := Vector2(WorldBlock.FACING_DIRS[facing])
	# Inline / unknown feed: slide straight across the tile.
	if incoming_dir < 0 or incoming_dir == facing or incoming_dir == (facing + 2) % 4:
		_item_sprite.position = out_vec * lerpf(-half, half, progress)
		return
	# Corner: travel from the incoming edge to the centre, then out along facing.
	var in_vec := Vector2(WorldBlock.FACING_DIRS[incoming_dir])
	if progress < 0.5:
		_item_sprite.position = in_vec * lerpf(-half, 0.0, progress * 2.0)
	else:
		_item_sprite.position = out_vec * lerpf(0.0, half, (progress - 0.5) * 2.0)


func _clear_item_sprite() -> void:
	if _item_sprite != null and is_instance_valid(_item_sprite):
		_item_sprite.queue_free()
	_item_sprite = null


func _get_solid_tex() -> ImageTexture:
	if _solid_tex == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_solid_tex = ImageTexture.create_from_image(img)
	return _solid_tex


# ── Save / load ───────────────────────────────────────────────────────────────

func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["filter_ids"] = Array(filter_ids)
	data["filter_mode"] = filter_mode
	data["priority"] = priority
	if not carried.is_empty():
		data["carried"] = carried.duplicate(true)
		data["progress"] = progress
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	filter_ids = _sanitized_filter_ids(PackedStringArray(data.get("filter_ids", [])))
	filter_mode = "block" if str(data.get("filter_mode", "allow")) == "block" else "allow"
	priority = clampi(int(data.get("priority", 0)), -10, 10)
	var carried_value: Variant = data.get("carried", {})
	if carried_value is Dictionary and not (carried_value as Dictionary).is_empty():
		carried = (carried_value as Dictionary).duplicate(true)
		IngredientDemandReservations.restore_stack(carried)
		progress = clampf(float(data.get("progress", 0.0)), 0.0, 1.0)
		_refresh_item_sprite()
	else:
		carried = {}
		progress = 0.0
		_clear_item_sprite()

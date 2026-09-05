extends Node
class_name WorldInteractionManager

const WORLD_BLOCK_SCENE := preload("res://entities/blocks/WorldBlock.tscn")
const DROPPED_ITEM_SCENE := preload("res://entities/items/DroppedItem.tscn")
const MANUAL_DROP_START_DISTANCE := 36.0
const MANUAL_DROP_IMPULSE_DISTANCE := 28.0
const MANUAL_DROP_PICKUP_DELAY := 0.75
const BLOCK_DROP_PICKUP_DELAY := 0.35
## Tool power of a bare-hand punch (a sword passes its own power instead).
const HAND_ATTACK_POWER := 1

@export var build_radius_tiles: int = 4

var player: Node2D
var placed_blocks_root: Node2D
var dropped_items_root: Node2D
var build_preview_overlay: BuildPreviewOverlay
var hotbar_ui: Node

var _placed_blocks: Dictionary = {}
var _preview_block_id: String = ""

# --- Протяжка линий (drag-строительство) ---
# Зажатая ПКМ после успешной установки 1x1-блока продолжает ставить блоки по
# пути курсора. Поворотные блоки (ленты/трубы) получают facing по направлению
# движения, а предыдущий блок этой же протяжки доворачивается на углах — так
# линия лент строится одним движением, с корректными поворотами.
var _drag_building := false
var _drag_last_tile := Vector2i.ZERO
var _drag_placed: Dictionary = {}  # Vector2i -> true: тайлы текущей протяжки

## Цепочки апгрейда «на месте»: ПКМ блоком старшего тира по машине младшего
## заменяет её с переносом содержимого и возвратом старого блока в инвентарь.
## Сундуки не здесь — у них свой апгрейд через UI.
const UPGRADE_CHAINS: Array = [
	["conveyor", "conveyor_t2", "conveyor_t3", "conveyor_t4", "conveyor_t5"],
	["primitive_drill", "bronze_drill", "steel_drill", "advanced_drill", "titanium_drill"],
	["solar_panel", "advanced_solar_panel", "elite_solar_panel",
		"ultimate_solar_panel", "quantum_solar_panel"],
	["energy_storage_t1", "energy_storage_t2", "energy_storage_t3"],
	["fluid_tank_t1", "fluid_tank_t2", "fluid_tank_t3", "fluid_tank_t4", "fluid_tank_t5"],
	["fluid_pipe", "fluid_pipe_t2"],
	["mechanical_water_pump", "steam_water_pump", "water_pump"],
]

# Mining subsystem
var _mining_component: MiningComponent
var _progress_canvas: CanvasLayer
var _progress_bar: ProgressBar
var _world_label_root: Node2D
var _damage_overlay: MiningDamageOverlay

# Block breaking uses the same one-damage-tick-per-second rule as world resources.
var _is_breaking: bool = false
var _breaking_target: Vector2i = Vector2i(-9999, -9999)
var _break_timer: float = 0.0

# Rejected-hit feedback: the bar flashes red instead of draining when the held tool
# is too weak / of the wrong type, with the floating label throttled to one per
# REJECT_LABEL_COOLDOWN so a held mouse button doesn't spam the screen.
const BAR_BLINK_TIME := 0.18
const REJECT_LABEL_COOLDOWN := 1.5
var _bar_blink: float = 0.0
var _reject_label_timer: float = 0.0


func _ready() -> void:
	add_to_group("world_interaction")
	_setup_mining_component()
	call_deferred("_register_existing_blocks")
	# Пинги «смотри сюда»: свои и от тиммейтов (сигнал эмитится и локально).
	MultiplayerManager.map_ping_received.connect(_on_map_ping)


## Показывает пинг в мире и на карте. Для своих пингов имя не подписываем.
func _on_map_ping(peer_id: int, pos: Vector2) -> void:
	var display_name := ""
	if peer_id != MultiplayerManager.my_peer_id():
		display_name = MultiplayerManager.peer_display_name(peer_id)
	var label_root := _get_label_root()
	if label_root != null:
		PingWorldMarker.spawn(label_root, pos, display_name)
	var map_ui := get_tree().get_first_node_in_group("map_ui")
	if map_ui != null and map_ui.has_method("add_ping"):
		map_ui.add_ping(pos, display_name)


func _setup_mining_component() -> void:
	_mining_component = MiningComponent.new()
	add_child(_mining_component)
	_mining_component.mining_yield.connect(_on_mining_yield)
	_mining_component.mining_blocked.connect(_on_mining_blocked)
	_mining_component.mining_started.connect(_on_mining_started)
	_mining_component.mining_stopped.connect(_on_mining_stopped)
	_mining_component.progress_changed.connect(_on_mining_progress_changed)
	_mining_component.hit_rejected.connect(_on_mining_hit_rejected)
	_mining_component.hit_landed.connect(_on_mining_hit_landed)

	_progress_canvas = CanvasLayer.new()
	_progress_canvas.layer = 10
	add_child(_progress_canvas)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(64, 8)
	_progress_bar.size = Vector2(64, 8)
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	_progress_canvas.add_child(_progress_bar)


func _process(delta: float) -> void:
	_update_build_preview()
	_check_mining_state()
	_check_breaking_state(delta)
	_update_drag_build()
	_update_progress_bar_position()
	_update_bar_blink(delta)


func _check_mining_state() -> void:
	if not _mining_component.is_mining:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mining_component.stop_mining()
		return
	if not _is_grid_in_build_radius(_mining_component.mining_target_pos):
		_mining_component.stop_mining()
		return
	# Sweeping the cursor onto another tile retargets instead of stubbornly hitting
	# the tile the click started on.
	var under_cursor: Vector2i = _world_to_grid(_get_mouse_world_position())
	if under_cursor == _mining_component.mining_target_pos:
		return
	if _is_mouse_over_ui() or not _is_grid_in_build_radius(under_cursor):
		return
	if _try_start_breaking(under_cursor):
		return
	_try_start_mining(under_cursor)


func _update_progress_bar_position() -> void:
	if _progress_bar == null:
		return
	var target_pos: Vector2i
	if _mining_component.is_mining:
		target_pos = _mining_component.mining_target_pos
	elif _is_breaking:
		target_pos = _breaking_target
	else:
		_progress_bar.visible = false
		return

	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_pos: Vector2 = _grid_to_world_center(target_pos)
	var screen_pos: Vector2 = canvas_transform * world_pos
	_progress_bar.position = screen_pos + Vector2(-32.0, -float(GameConstants.TILE_SIZE) - 12.0)
	_progress_bar.visible = true


func _input(event: InputEvent) -> void:
	if GameChat.is_blocking_input():
		return
	if get_tree().paused:
		return

	if not event is InputEventMouseButton or not event.pressed:
		return
	if _is_mouse_over_ui():
		return

	var world_pos: Vector2 = _get_mouse_world_position()
	var grid_pos: Vector2i = _world_to_grid(world_pos)

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.alt_pressed:
			# Alt+ЛКМ — пинг «смотри сюда» (виден тиммейтам в мире и на карте).
			MultiplayerManager.send_map_ping(world_pos)
			get_viewport().set_input_as_handled()
		elif _try_start_breaking(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_attack():
			get_viewport().set_input_as_handled()
		elif _try_harvest_crop(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_start_mining(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_punch():
			get_viewport().set_input_as_handled()
		elif InventorySlot.held_item != null:
			if drop_held_item_near_player(event.shift_pressed):
				get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _try_use_bucket(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_till(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_plant(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_use_item():
			get_viewport().set_input_as_handled()
		elif _try_upgrade_block(grid_pos):
			get_viewport().set_input_as_handled()
		elif _try_place_block(grid_pos):
			_begin_drag_build(grid_pos)
			get_viewport().set_input_as_handled()


func _try_start_mining(grid_pos: Vector2i) -> bool:
	if not _is_grid_in_build_radius(grid_pos):
		return false

	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("get_deposit_at"):
		return false

	var deposit: DepositData = world_node.get_deposit_at(grid_pos)
	if deposit == null:
		return false

	# Cancel any in-progress mining; the new target starts its own full second.
	if _mining_component.is_mining:
		_mining_component.stop_mining()

	var tool_data: Dictionary = _get_mining_tool_data()
	_mining_component.start_mining(
		grid_pos,
		int(tool_data.get("power", 0)),
		str(tool_data.get("tool_type", ""))
	)
	# Play the matching tool action animation toward the mined tile while held.
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if _mining_component.is_mining and player_node != null \
			and player_node.has_method("begin_tool_action"):
		player_node.begin_tool_action(
			str(tool_data.get("tool_type", "")),
			_grid_to_world_center(grid_pos)
		)
	return true


# --- Mining signal handlers ---

func _on_mining_yield(yield_stack: Dictionary, world_pos: Vector2, bonus: bool) -> void:
	if yield_stack.is_empty():
		return
	_give_ore_yield(yield_stack, world_pos)
	var item_name: String = tr(str(yield_stack.get("name", "")))
	var amount: int = int(yield_stack.get("count", 1))
	FloatingMiningLabel.spawn_yield(item_name, amount, world_pos, _get_label_root())
	if bonus:
		# The deposit rolled its bonus drop — until now nothing told the player.
		FloatingMiningLabel.spawn_bonus(world_pos, _get_label_root())
	QuestManager.report_event("mine_yield", str(yield_stack.get("id", "")), amount)


## A landed swing: cracks + flash + shards on the tile.
func _on_mining_hit_landed(grid_pos: Vector2i, remaining: float) -> void:
	var tool_type := str(_get_mining_tool_data().get("tool_type", ""))
	AudioManager.play_sfx("chop_axe" if tool_type == "axe" else "mine_pickaxe", -4.0)
	var overlay: MiningDamageOverlay = _get_damage_overlay()
	if overlay == null:
		return
	if remaining <= 0.0:
		overlay.clear_tile(grid_pos)
		return
	overlay.mark_hit(grid_pos, remaining)


## A teammate's mining swing (from NetSync): chips our copy of that tile's pool so
## two players felling one tree share its HP instead of each running a private one.
func apply_remote_mine_hit(grid_pos: Vector2i, damage: float) -> void:
	_mining_component.apply_remote_hit(grid_pos, damage)


## Lives under the world node so it draws in world space; created on first use
## because the world only exists after this manager's _ready.
func _get_damage_overlay() -> MiningDamageOverlay:
	if _damage_overlay != null and is_instance_valid(_damage_overlay):
		return _damage_overlay
	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null:
		return null
	_damage_overlay = MiningDamageOverlay.new()
	_damage_overlay.name = "MiningDamageOverlay"
	world_node.add_child(_damage_overlay)
	return _damage_overlay

func _on_mining_blocked(reason: String) -> void:
	var world_pos: Vector2 = _get_mouse_world_position()
	FloatingMiningLabel.spawn_blocked(reason, world_pos, _get_label_root())


func _on_mining_started(_deposit: DepositData) -> void:
	pass


func _on_mining_stopped() -> void:
	if _progress_bar != null:
		_progress_bar.visible = false
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node != null and player_node.has_method("end_tool_action"):
		player_node.end_tool_action()


## `progress` is the tile's REMAINING health (1 = untouched), so the bar drains.
func _on_mining_progress_changed(progress: float) -> void:
	if _progress_bar != null:
		_progress_bar.value = progress * 100.0


## A swing that bounced off: flash the bar, and remind why once in a while.
func _on_mining_hit_rejected(reason: String) -> void:
	_flash_progress_bar()
	if _reject_label_timer > 0.0:
		return
	_reject_label_timer = REJECT_LABEL_COOLDOWN
	FloatingMiningLabel.spawn_blocked(
		reason, _grid_to_world_center(_mining_component.mining_target_pos), _get_label_root()
	)


## Turns the progress bar red for a moment — the "this tool can't dent it" tell.
func _flash_progress_bar() -> void:
	_bar_blink = BAR_BLINK_TIME
	if _progress_bar != null:
		_progress_bar.modulate = Color(1.0, 0.45, 0.35)


func _update_bar_blink(delta: float) -> void:
	if _reject_label_timer > 0.0:
		_reject_label_timer = maxf(0.0, _reject_label_timer - delta)
	if _bar_blink <= 0.0:
		return
	_bar_blink = maxf(0.0, _bar_blink - delta)
	if _bar_blink <= 0.0 and _progress_bar != null:
		_progress_bar.modulate = Color.WHITE


func _get_label_root() -> Node2D:
	if _world_label_root != null and is_instance_valid(_world_label_root):
		return _world_label_root

	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node != null:
		_world_label_root = world_node as Node2D
	return _world_label_root


# --- Melee attack (LMB while a sword is the active item) ---

func _try_attack() -> bool:
	var stack: Variant = _get_current_stack()
	if not (stack is Dictionary):
		return false
	var weapon_type := str((stack as Dictionary).get("tool_type", ""))
	if weapon_type not in ["sword", "spear", "hammer", "wand"]:
		return false
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node != null and player_node.has_method("attack_with_weapon"):
		player_node.attack_with_weapon(weapon_type, int((stack as Dictionary).get("power", 1)))
	return true


## Bare-hand (or tool-as-club) punch, tried only after mining/breaking so LMB keeps
## working on the world. Fires just when a "hittable" is actually in reach, which is
## what makes an empty hand a usable — if weak — weapon.
func _try_punch() -> bool:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node == null or not player_node.has_method("swing_attack"):
		return false
	return bool(player_node.swing_attack(HAND_ATTACK_POWER, true))


# --- Use item (non-block "use" on RMB, e.g. opening the codex) ---

## Dispatches the held item's `use_action` (from ItemData). Returns true if handled.
func _try_use_item() -> bool:
	var stack: Variant = _get_current_stack()
	if not (stack is Dictionary):
		return false
	# Eating food refills hunger (checked before use_action so edible tools/plants
	# that also carry an action still get eaten on RMB when the player is hungry).
	if _try_eat_food(stack as Dictionary):
		return true
	var action: String = str((stack as Dictionary).get("use_action", ""))
	if action == "":
		return false
	# "summon_boss:<id>" — re-summon a defeated boss with a totem (consumed on success).
	if action.begins_with("summon_boss:"):
		return _try_summon_boss(action.trim_prefix("summon_boss:"))
	if action.begins_with("unlock_biome_access:"):
		return _try_unlock_biome_access(action.trim_prefix("unlock_biome_access:"), stack as Dictionary)
	match action:
		"open_codex":
			var codex: Node = get_tree().get_first_node_in_group("codex_ui")
			if codex != null and codex.has_method("open"):
				codex.open()
				return true
	return false


func _try_unlock_biome_access(biome: String, stack: Dictionary) -> bool:
	var save := SaveManager.current_save
	var item_id := str(stack.get("id", ""))
	if save == null or item_id.is_empty():
		return false
	if save.permanent_biome_access.has(item_id):
		return true
	if not BiomeProgression.is_biome_unlocked(biome):
		NotificationCenter.push("progress", tr("Biome locked"), BiomeProgression.requirement_text(biome), "warning")
		return true
	save.permanent_biome_access.append(item_id)
	_consume_current_stack(1)
	NotificationCenter.push("progress", tr("Permanent biome protection"), BiomeProgression.display_name(biome), "success")
	return true


## --- Farming (hoe till / plant / harvest) ---

func _get_world_node() -> Node:
	return get_tree().get_first_node_in_group("world")


## Hoe on bare ground (RMB) tills it into a farm plot. Returns true if it tilled.
func _try_till(grid_pos: Vector2i) -> bool:
	if not _is_grid_in_build_radius(grid_pos):
		return false
	if _held_tool_type() != "hoe":
		return false
	var world_node: Node = _get_world_node()
	if world_node == null or not world_node.has_method("till_at"):
		return false
	return bool(world_node.till_at(grid_pos))


## Using a plantable vegetable (RMB) on an empty farm plot sows it and consumes one.
func _try_plant(grid_pos: Vector2i) -> bool:
	if not _is_grid_in_build_radius(grid_pos):
		return false
	var stack: Variant = _get_current_stack()
	if not (stack is Dictionary):
		return false
	var item_id: String = str((stack as Dictionary).get("id", ""))
	if item_id.is_empty() or not CropDatabase.is_plantable(item_id):
		return false
	var world_node: Node = _get_world_node()
	if world_node == null or not world_node.has_method("plant_at"):
		return false
	var crop: CropData = CropDatabase.get_by_plant_item(item_id)
	if crop == null:
		return false
	if not bool(world_node.plant_at(grid_pos, crop.crop_id)):
		return false
	_consume_current_stack(1)
	return true


## LMB on a farm plot harvests a ripe crop (and consumes the click either way, so
## you never punch your own field). Returns true when the tile is a farm plot.
func _try_harvest_crop(grid_pos: Vector2i) -> bool:
	if not _is_grid_in_build_radius(grid_pos):
		return false
	var world_node: Node = _get_world_node()
	if world_node == null or not world_node.has_method("is_farm_tile"):
		return false
	if not bool(world_node.is_farm_tile(grid_pos)):
		return false
	var yield_stack: Dictionary = world_node.harvest_crop_at(grid_pos) as Dictionary
	if not yield_stack.is_empty():
		var world_pos: Vector2 = _grid_to_world_center(grid_pos)
		_give_ore_yield(yield_stack, world_pos)
		FloatingMiningLabel.spawn_yield(
			tr(str(yield_stack.get("name", ""))),
			int(yield_stack.get("count", 1)),
			world_pos,
			_get_label_root()
		)
	return true


## Eats one unit of the held stack if it's food and the player isn't already full.
## Refills hunger by the item's food_value and consumes one from the active stack.
func _try_eat_food(stack: Dictionary) -> bool:
	var food_value: int = int(stack.get("food_value", 0))
	if food_value <= 0:
		return false
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node == null or not player_node.has_method("add_hunger"):
		return false
	# Don't waste food when already full.
	if player_node.has_method("get_hunger") and player_node.has_method("get_max_hunger"):
		if float(player_node.get_hunger()) >= float(player_node.get_max_hunger()):
			return false
	player_node.add_hunger(float(food_value))
	_consume_current_stack(1)
	return true


## Re-summons the named boss via BossManager and consumes one totem on success. The
## click is still "handled" (returns true) if the boss is already alive, so it won't
## fall through to block placement — but nothing is consumed in that case.
func _try_summon_boss(boss_id: String) -> bool:
	var mgr: Node = get_tree().get_first_node_in_group("boss_manager")
	if mgr == null or not mgr.has_method("summon"):
		return false
	if mgr.has_method("is_alive") and mgr.is_alive(boss_id):
		return true  # already present — don't waste the totem
	if mgr.summon(boss_id):
		if hotbar_ui == null:
			hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
		if hotbar_ui != null and hotbar_ui.has_method("consume_active_item"):
			hotbar_ui.consume_active_item(1)
		return true
	return false


# --- Block placement ---

func _try_place_block(grid_pos: Vector2i) -> bool:
	var block_id: String = _get_current_block_id()
	if block_id.is_empty():
		return false
	if not can_place_block_at(grid_pos, block_id):
		return false
	if placed_blocks_root == null:
		return false

	var current_stack_value: Variant = _get_current_stack()
	if not (current_stack_value is Dictionary):
		return false
	var current_stack: Dictionary = current_stack_value.duplicate(true)

	var block: WorldBlock = _instantiate_block_scene()
	if block == null:
		return false
	var size: Vector2i = _block_size(block_id)
	var anchor: Vector2i = _anchor_for(grid_pos, size)
	var facing := _player_facing()
	placed_blocks_root.add_child(block)
	block.setup(block_id, anchor, facing)
	block.apply_placed_item_stack(current_stack)
	_register_block_footprint(block)
	QuestManager.report_event("block_placed", block_id, 1)
	_update_map_block(block.center_tile(), block_id)
	_refresh_connectors_around(grid_pos)

	if _get_current_stack() != null:
		_consume_current_stack(1)
	AudioManager.play_sfx("block_place")
	MultiplayerManager.broadcast_block_placed(anchor, block_id, block.facing)
	return true


# --- Протяжка линий -----------------------------------------------------------

## Начинает протяжку после успешной ручной установки. Только 1x1-блоки:
## многотайловые машины ставятся поштучно.
func _begin_drag_build(grid_pos: Vector2i) -> void:
	var block: WorldBlock = _placed_blocks.get(grid_pos) as WorldBlock
	if block == null or block.size != Vector2i.ONE:
		return
	_drag_building = true
	_drag_last_tile = grid_pos
	_drag_placed = {grid_pos: true}


func _stop_drag_build() -> void:
	_drag_building = false
	_drag_placed = {}


## Пока ПКМ зажата — ставит блоки по пути курсора (шаг только по осям, чтобы
## линия была непрерывной даже при быстром движении мыши).
func _update_drag_build() -> void:
	if not _drag_building:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_stop_drag_build()
		return
	if GameChat.is_blocking_input() or get_tree().paused or _is_mouse_over_ui():
		return
	var target := _world_to_grid(_get_mouse_world_position())
	while _drag_last_tile != target:
		var diff := target - _drag_last_tile
		var step := Vector2i(signi(diff.x), 0) if absi(diff.x) >= absi(diff.y) \
			else Vector2i(0, signi(diff.y))
		var next := _drag_last_tile + step
		if not _drag_step_to(next):
			return
		_drag_last_tile = next


## Один шаг протяжки. false — протяжка остановлена (кончились блоки и т.п.).
func _drag_step_to(next: Vector2i) -> bool:
	var block_id := _get_current_block_id()
	if block_id.is_empty() or _block_size(block_id) != Vector2i.ONE:
		_stop_drag_build()
		return false
	# Занятый/непригодный тайл не прерывает протяжку — линия продолжится за ним.
	if _try_place_block(next):
		_drag_placed[next] = true
	return true


# --- Апгрейд машин на месте -----------------------------------------------------

## Цепочка апгрейда, содержащая block_id (пустой массив — блок не апгрейдится).
func _chain_of(block_id: String) -> Array:
	for chain: Array in UPGRADE_CHAINS:
		if chain.has(block_id):
			return chain
	return []


## ПКМ блоком старшего тира по машине того же семейства: замена на месте с
## переносом содержимого (та же ориентация, тот же якорь), старый блок — в
## инвентарь. Возвращает false, если апгрейд неприменим.
func _try_upgrade_block(grid_pos: Vector2i) -> bool:
	var target: WorldBlock = _placed_blocks.get(grid_pos) as WorldBlock
	if target == null or not is_instance_valid(target):
		return false
	if not _is_grid_in_build_radius(grid_pos):
		return false
	var new_id := _get_current_block_id()
	if new_id.is_empty() or new_id == target.block_id:
		return false
	var chain := _chain_of(target.block_id)
	var new_i := chain.find(new_id)
	if new_i < 0 or new_i <= chain.find(target.block_id):
		return false
	# Размеры должны совпадать: при смене футпринта центр машины сместился бы
	# (дрель съехала бы с ядра жилы) — такие переходы ставятся вручную.
	if _block_size(new_id) != target.size:
		return false

	var anchor: Vector2i = target.grid_pos

	var facing: int = target.facing
	var old_extra: Dictionary = target.get_extra_save_data()
	var old_data: BlockData = _get_block_data(target.block_id)
	var refund_id: String = old_data.drop_item_id if old_data != null else ""

	# Убираем старый блок (без дропа — содержимое переносим или возвращаем).
	var old_center: Vector2i = target.center_tile()
	for tile: Vector2i in target.footprint():
		if _placed_blocks.get(tile) == target:
			_placed_blocks.erase(tile)
	target.queue_free()
	_remove_map_block(old_center)
	MultiplayerManager.broadcast_block_removed(anchor)

	# Ставим новый на тот же якорь с той же ориентацией.
	var block: WorldBlock = _instantiate_block_scene()
	placed_blocks_root.add_child(block)
	block.setup(new_id, anchor, facing)
	_register_block_footprint(block)

	# Содержимое: переносим, когда тип хранилища совпадает; иначе оно уедет
	# внутри возвращаемого предмета (как при ручной поломке).
	var transferred := (old_extra.has("machine_data") and block.machine != null) \
		or (old_extra.has("chest_data") and block.chest_inventory != null)
	if transferred:
		block.load_extra_save_data(old_extra)

	_update_map_block(block.center_tile(), new_id)
	_refresh_connectors_around(anchor)
	QuestManager.report_event("block_placed", new_id, 1)
	_consume_current_stack(1)
	MultiplayerManager.broadcast_block_placed(anchor, new_id, facing)
	if transferred and not old_extra.is_empty():
		MultiplayerManager.broadcast_machine_state(anchor, old_extra)

	# Возврат старого блока в инвентарь (остаток — дропом под ноги).
	if not refund_id.is_empty() and ItemDatabase.registry.has(refund_id):
		var refund: Dictionary = ItemDatabase.create_existing_stack(refund_id, 1)
		if not transferred and not old_extra.is_empty():
			if old_extra.has("chest_data"):
				refund["chest_data"] = old_extra["chest_data"]
			elif old_extra.has("machine_data"):
				refund["machine_data"] = old_extra["machine_data"]
		_give_ore_yield(refund, _grid_to_world_center(anchor))
	return true


# --- Multi-tile / rotation helpers ---

func _block_size(block_id: String) -> Vector2i:
	var data: BlockData = _get_block_data(block_id)
	if data != null and data.size.x > 0 and data.size.y > 0:
		return data.size
	return Vector2i.ONE


func _block_rotatable(block_id: String) -> bool:
	var data: BlockData = _get_block_data(block_id)
	return data != null and data.rotatable


## Top-left tile so an (odd-sized) block is centred on the clicked tile.
func _anchor_for(grid_pos: Vector2i, size: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	return grid_pos - Vector2i(size.x / 2, size.y / 2)


func _footprint(anchor: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for dx in range(size.x):
		for dy in range(size.y):
			tiles.append(anchor + Vector2i(dx, dy))
	return tiles


func _register_block_footprint(block: WorldBlock) -> void:
	for tile: Vector2i in block.footprint():
		_placed_blocks[tile] = block


## Facing for normal placement follows the direction the local player is looking.
func _player_facing() -> int:
	if not is_instance_valid(player) or not player.has_method("get_facing_vector"):
		return 2
	var direction_value: Variant = player.call("get_facing_vector")
	if direction_value is Vector2:
		var direction := Vector2i(
			roundi((direction_value as Vector2).x),
			roundi((direction_value as Vector2).y)
		)
		var facing := WorldBlock.FACING_DIRS.find(direction)
		if facing >= 0:
			return facing
	return 2


## Redraws wire/cable connections for a tile and its 4 neighbours after a change.
func _refresh_connectors_around(grid_pos: Vector2i) -> void:
	var around: Array[Vector2i] = [
		grid_pos,
		grid_pos + Vector2i(1, 0), grid_pos + Vector2i(-1, 0),
		grid_pos + Vector2i(0, 1), grid_pos + Vector2i(0, -1),
	]
	for pos: Vector2i in around:
		var block: Variant = _placed_blocks.get(pos)
		if block is WorldBlock and block.has_method("refresh_connections"):
			block.refresh_connections()


func _refresh_all_connectors() -> void:
	for block_value: Variant in _placed_blocks.values():
		if block_value is WorldBlock and block_value.has_method("refresh_connections"):
			block_value.refresh_connections()


func register_existing_blocks() -> void:
	if placed_blocks_root == null:
		return
	_placed_blocks.clear()
	for child in placed_blocks_root.get_children():
		if child is WorldBlock:
			var block: WorldBlock = child as WorldBlock
			_register_block_footprint(block)
			_update_map_block(block.center_tile(), block.block_id)
	_refresh_all_connectors()


func _register_existing_blocks() -> void:
	if not _placed_blocks.is_empty():
		return
	register_existing_blocks()


func load_placed_blocks(saved_blocks: Dictionary) -> void:
	if placed_blocks_root == null:
		return

	_placed_blocks.clear()
	for child in placed_blocks_root.get_children():
		child.queue_free()

	for key_variant: Variant in saved_blocks.keys():
		var key_text: String = str(key_variant)
		var grid_pos: Vector2i = _parse_grid_key(key_text)
		var saved_value: Variant = saved_blocks[key_variant]
		var block_id: String = ""
		var saved_health: int = -1
		var saved_extra_data: Dictionary = {}

		var saved_facing: int = 2
		if saved_value is Dictionary:
			block_id = str(saved_value.get("block_id", ""))
			saved_health = int(saved_value.get("health", -1))
			saved_facing = int(saved_value.get("facing", 2))
			var extra_data_value: Variant = saved_value.get("extra_data", {})
			if extra_data_value is Dictionary:
				saved_extra_data = extra_data_value
		else:
			block_id = str(saved_value)

		if block_id.is_empty():
			continue

		var block: WorldBlock = _instantiate_block_scene()
		if block == null:
			continue

		placed_blocks_root.add_child(block)
		block.setup(block_id, grid_pos, saved_facing)
		if not saved_extra_data.is_empty():
			block.load_extra_save_data(saved_extra_data)
		if saved_health > 0:
			block.health = saved_health
		_register_block_footprint(block)
		_update_map_block(block.center_tile(), block_id)

	_refresh_all_connectors()


func serialize_placed_blocks() -> Dictionary:
	var saved_blocks: Dictionary = {}
	var seen: Dictionary = {}
	for grid_key: Vector2i in _placed_blocks.keys():
		var block: WorldBlock = _placed_blocks[grid_key] as WorldBlock
		if block == null or not is_instance_valid(block):
			continue
		# A multi-tile block is registered under every footprint tile — save once.
		var id: int = block.get_instance_id()
		if seen.has(id):
			continue
		seen[id] = true

		saved_blocks[_grid_key(block.grid_pos)] = {
			"block_id": block.block_id,
			"facing": block.facing,
			"health": block.health,
			"extra_data": block.get_extra_save_data(),
		}
	return saved_blocks


func can_place_block_at(grid_pos: Vector2i, block_id: String = "") -> bool:
	var world_node: Node = get_tree().get_first_node_in_group("world")
	var size: Vector2i = _block_size(block_id)
	var footprint: Array[Vector2i] = _footprint(_anchor_for(grid_pos, size), size)

	# The whole footprint must be free of other blocks and the player.
	for tile: Vector2i in footprint:
		if _placed_blocks.has(tile):
			return false
		if _is_player_on_grid(tile):
			return false

	if block_id == "oil_pump":
		return (
			world_node != null
			and world_node.has_method("is_oil_center_at")
			and bool(world_node.is_oil_center_at(grid_pos))
		)
	if block_id == "water_pump" or block_id == "mechanical_water_pump":
		return (
			world_node != null
			and world_node.has_method("is_water_tile")
			and bool(world_node.is_water_tile(grid_pos))
		)
	# Drills go only on a vein core (the clicked centre tile), tier permitting.
	# Their footprint is allowed to overlap the surrounding ore body.
	if DrillContainer.is_drill_block(block_id):
		if world_node == null or not world_node.has_method("get_ore_core_deposit_at"):
			return false
		var core_deposit: DepositData = world_node.get_ore_core_deposit_at(grid_pos)
		if core_deposit == null:
			return false
		var required_level: int = core_deposit.mining_level_required
		if world_node.has_method("get_required_mining_level"):
			required_level = world_node.get_required_mining_level(grid_pos, core_deposit)
		return DrillContainer.tier_power(block_id) >= required_level

	if world_node == null:
		return true
	# Generic blocks: no water, no blocking world object — except the infinite vein
	# body, which counts as buildable ground (so conveyors can ring a drill).
	for tile: Vector2i in footprint:
		if world_node.has_method("is_water_tile") and bool(world_node.is_water_tile(tile)):
			return false
		if world_node.has_method("has_world_object_at") and bool(world_node.has_world_object_at(tile)):
			if not (world_node.has_method("is_ore_body_at") and bool(world_node.is_ore_body_at(tile))):
				return false
	return true


## ЛКМ по установленному игроком блоку начинает разбор. Удержание продолжает
## удары в том же ритме, что и обычная добыча.
func _try_start_breaking(grid_pos: Vector2i) -> bool:
	if not _placed_blocks.has(grid_pos):
		return false
	if not _is_grid_in_build_radius(grid_pos):
		return false

	# A fresh click starts a full one-second damage interval on the new tile.
	if _mining_component.is_mining:
		_mining_component.stop_mining()

	_breaking_target = grid_pos
	_break_timer = 0.0
	_is_breaking = true
	# Same swing animation as mining — breaking a block is just hitting it.
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node != null and player_node.has_method("begin_tool_action"):
		player_node.begin_tool_action(_held_tool_type(), _grid_to_world_center(grid_pos))
	return true


## Keeps swinging at the target block while the button is held and it stays valid.
func _check_breaking_state(delta: float) -> void:
	if not _is_breaking:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_breaking()
		return
	if not _is_grid_in_build_radius(_breaking_target):
		_stop_breaking()
		return
	if not _placed_blocks.has(_breaking_target):
		_stop_breaking()
		return

	# Same retarget rule as mining: follow the cursor onto the next block/deposit.
	var under_cursor: Vector2i = _world_to_grid(_get_mouse_world_position())
	if under_cursor != _breaking_target and not _is_mouse_over_ui() \
			and _is_grid_in_build_radius(under_cursor):
		if _placed_blocks.has(under_cursor) and _try_start_breaking(under_cursor):
			return
		if _try_start_mining(under_cursor):
			_stop_breaking()
			return

	_break_timer += delta
	while _is_breaking and _break_timer >= ToolTierSystem.MINING_DAMAGE_INTERVAL:
		_break_timer -= ToolTierSystem.MINING_DAMAGE_INTERVAL
		_breaking_swing()


## One hit after a complete second. Correct-tool power is literal damage; a hand,
## wrong tool, or no-tool block always receives one damage.
func _breaking_swing() -> void:
	var block: WorldBlock = _placed_blocks.get(_breaking_target) as WorldBlock
	if block == null or not is_instance_valid(block):
		_stop_breaking()
		return

	var damage: int = _get_tool_damage(block.required_tool)
	var overlay: MiningDamageOverlay = _get_damage_overlay()
	if block.apply_damage(damage):
		if overlay != null:
			overlay.clear_tile(_breaking_target)
		_destroy_block(block, _breaking_target)
		_stop_breaking()
		return
	if overlay != null:
		overlay.mark_hit(_breaking_target, block.health_fraction())
	if _progress_bar != null:
		_progress_bar.value = block.health_fraction() * 100.0


func _stop_breaking() -> void:
	if not _is_breaking:
		return
	_is_breaking = false
	_breaking_target = Vector2i(-9999, -9999)
	_break_timer = 0.0
	if _progress_bar != null and not _mining_component.is_mining:
		_progress_bar.visible = false
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node != null and player_node.has_method("end_tool_action"):
		player_node.end_tool_action()


## Removes a broken block from the world and spawns its drop.
func _destroy_block(block: WorldBlock, grid_pos: Vector2i) -> void:
	AudioManager.play_sfx("machine_remove" if block.machine != null else "block_break")
	var drop_stack: Dictionary = block.get_drop_stack()
	var center: Vector2i = block.center_tile()
	var anchor: Vector2i = block.grid_pos
	for tile: Vector2i in block.footprint():
		if _placed_blocks.get(tile) == block:
			_placed_blocks.erase(tile)
	block.queue_free()
	_remove_map_block(center)
	_refresh_connectors_around(grid_pos)
	MultiplayerManager.broadcast_block_removed(anchor)

	if not drop_stack.is_empty():
		_spawn_dropped_item(drop_stack, _grid_to_world_center(center), Vector2.ZERO, BLOCK_DROP_PICKUP_DELAY)


## Ставит блок по сетевому событию от другого игрока: без расхода инвентаря,
## без проверок радиуса. Занятый футпринт (гонка одновременных установок) —
## событие молча пропускается, у отправителя блок останется только у него.
func apply_remote_place(anchor: Vector2i, block_id: String, facing: int) -> void:
	if placed_blocks_root == null or block_id.is_empty():
		return
	for tile: Vector2i in _footprint(anchor, _block_size(block_id)):
		if _placed_blocks.has(tile):
			return
	var block: WorldBlock = _instantiate_block_scene()
	if block == null:
		return
	placed_blocks_root.add_child(block)
	block.setup(block_id, anchor, facing)
	_register_block_footprint(block)
	_update_map_block(block.center_tile(), block_id)
	_refresh_connectors_around(anchor)


## Применяет пришедшее по сети состояние машины/сундука к блоку по якорю.
func apply_remote_machine_state(anchor: Vector2i, extra_data: Dictionary) -> void:
	var block: WorldBlock = _placed_blocks.get(anchor) as WorldBlock
	if block != null and is_instance_valid(block) and not extra_data.is_empty():
		block.load_extra_save_data(extra_data)


## Применяет снимок состояний всех машин от хоста (формат
## serialize_placed_blocks). skip_anchor — блок, с которым локальный игрок
## сейчас работает в меню: его не трогаем, чтобы не затирать правки под руками.
func apply_remote_machine_snapshot(blocks: Dictionary, skip_anchor: Variant) -> void:
	for key_variant: Variant in blocks:
		var anchor: Vector2i = _parse_grid_key(str(key_variant))
		if skip_anchor is Vector2i and anchor == skip_anchor:
			continue
		var entry: Variant = blocks[key_variant]
		if not (entry is Dictionary):
			continue
		var extra: Variant = (entry as Dictionary).get("extra_data", {})
		if extra is Dictionary and not (extra as Dictionary).is_empty():
			apply_remote_machine_state(anchor, extra)


## Убирает блок по сетевому событию: без дропа — лут получает тот, кто ломал.
func apply_remote_destroy(anchor: Vector2i) -> void:
	var block: WorldBlock = _placed_blocks.get(anchor) as WorldBlock
	if block == null or not is_instance_valid(block):
		return
	var center: Vector2i = block.center_tile()
	for tile: Vector2i in block.footprint():
		if _placed_blocks.get(tile) == block:
			_placed_blocks.erase(tile)
	block.queue_free()
	_remove_map_block(center)
	_refresh_connectors_around(anchor)


func _give_ore_yield(stack: Dictionary, world_pos: Vector2) -> void:
	var remaining: Variant = stack.duplicate(true)

	if hotbar_ui == null:
		hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("auto_insert_item"):
		remaining = hotbar_ui.auto_insert_item(remaining)
		if remaining == null or int(remaining.get("count", 0)) <= 0:
			return

	var inventory_ui: Node = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_ui and inventory_ui.has_method("auto_insert_item"):
		remaining = inventory_ui.auto_insert_item(remaining)
		if remaining == null or int(remaining.get("count", 0)) <= 0:
			return

	if remaining is Dictionary and not remaining.is_empty():
		_spawn_dropped_item(remaining, world_pos, Vector2.ZERO, BLOCK_DROP_PICKUP_DELAY)


func drop_held_item_near_player(drop_single: bool = false) -> bool:
	if _get_dropped_items_root() == null:
		return false
	if InventorySlot.held_item == null or not (InventorySlot.held_item is Dictionary):
		return false

	var stack: Dictionary = InventorySlot.held_item.duplicate(true)
	if drop_single:
		stack["count"] = 1
	if stack.is_empty():
		return false
	if not _spawn_stack_near_player(stack):
		return false

	if drop_single:
		InventorySlot.consume_from_held(1)
	else:
		InventorySlot.clear_held_item_static()
	return true


func _spawn_stack_near_player(stack: Dictionary) -> bool:
	var spawn_pos: Vector2 = _get_mouse_world_position()
	var impulse: Vector2 = Vector2.ZERO
	if is_instance_valid(player):
		var drop_direction: Vector2 = _get_mouse_world_position() - player.global_position
		if drop_direction.length_squared() < 1.0:
			drop_direction = Vector2.DOWN
		drop_direction = drop_direction.normalized()
		spawn_pos = player.global_position + drop_direction * MANUAL_DROP_START_DISTANCE
		impulse = drop_direction * MANUAL_DROP_IMPULSE_DISTANCE
	return _spawn_dropped_item(stack, spawn_pos, impulse, MANUAL_DROP_PICKUP_DELAY, true)


func _spawn_dropped_item(
	stack: Dictionary,
	world_pos: Vector2,
	impulse: Vector2 = Vector2.ZERO,
	pickup_delay: float = BLOCK_DROP_PICKUP_DELAY,
	wait_for_player_to_leave: bool = false
) -> bool:
	if stack.is_empty():
		return false
	var root: Node2D = _get_dropped_items_root()
	if root == null:
		push_warning("WorldInteractionManager: cannot spawn dropped item without DroppedItems root.")
		return false

	var item: DroppedItem = DROPPED_ITEM_SCENE.instantiate() as DroppedItem
	if item == null:
		push_error("WorldInteractionManager: DroppedItem scene has wrong root type.")
		return false

	root.add_child(item)
	item.setup(stack, world_pos, impulse, pickup_delay, wait_for_player_to_leave)
	# Мультиплеер: регистрируем дроп у арбитра (хоста) и показываем остальным.
	item.net_id = MultiplayerManager.broadcast_drop_spawned(
		stack, world_pos, impulse, pickup_delay, wait_for_player_to_leave
	)
	return true


## Остаток стека, не влезший в инвентарь при сетевом подборе: перевыброс новым
## дропом на том же месте. wait=true — не всасывается обратно, пока стоим рядом.
func respawn_leftover_drop(stack: Dictionary, world_pos: Vector2) -> void:
	_spawn_dropped_item(stack, world_pos, Vector2.ZERO, DroppedItem.DEFAULT_PICKUP_DELAY, true)


## Спавнит копию ЧУЖОГО дропа по сетевому событию — без повторной рассылки.
func spawn_remote_drop(payload: Dictionary) -> void:
	var net_id := str(payload.get("id", ""))
	if net_id.is_empty():
		return
	# Дубликат (например, из world info и из RPC разом) — пропускаем.
	for existing: Node in get_tree().get_nodes_in_group("dropped_items"):
		if existing is DroppedItem and (existing as DroppedItem).net_id == net_id:
			return
	var stack: Dictionary = MultiplayerManager.stack_from_net(payload.get("stack", {}))
	if stack.is_empty():
		return
	var root: Node2D = _get_dropped_items_root()
	if root == null:
		return
	var item: DroppedItem = DROPPED_ITEM_SCENE.instantiate() as DroppedItem
	if item == null:
		return
	root.add_child(item)
	item.setup(
		stack,
		payload.get("pos", Vector2.ZERO),
		payload.get("impulse", Vector2.ZERO),
		float(payload.get("delay", DroppedItem.DEFAULT_PICKUP_DELAY)),
		bool(payload.get("wait", false))
	)
	item.net_id = net_id


func _get_dropped_items_root() -> Node2D:
	if is_instance_valid(dropped_items_root):
		return dropped_items_root

	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null:
		world_node = get_tree().root.find_child("World", true, false)
	if world_node == null:
		return null

	var existing_root: Node = world_node.get_node_or_null("Entities/DroppedItems")
	if existing_root is Node2D:
		dropped_items_root = existing_root as Node2D
		return dropped_items_root

	var entities_root: Node = world_node.get_node_or_null("Entities")
	if not (entities_root is Node2D):
		return null

	var created_root: Node2D = Node2D.new()
	created_root.name = "DroppedItems"
	entities_root.add_child(created_root)
	dropped_items_root = created_root
	return dropped_items_root


func get_block_at(grid_pos: Vector2i) -> WorldBlock:
	return _placed_blocks.get(grid_pos) as WorldBlock


func _instantiate_block_scene() -> WorldBlock:
	return WORLD_BLOCK_SCENE.instantiate() as WorldBlock


func _get_block_data(block_id: String) -> BlockData:
	var database: Node = get_node_or_null("/root/BlockDatabase")
	if database == null or not database.has_method("get_block"):
		return null
	return database.get_block(block_id) as BlockData


func _update_build_preview() -> void:
	if build_preview_overlay == null:
		return

	if GameChat.is_blocking_input() or get_tree().paused or _is_mouse_over_ui():
		_preview_block_id = ""
		build_preview_overlay.clear_overlay()
		return

	var grid_pos: Vector2i = _world_to_grid(_get_mouse_world_position())
	var block_id: String = _get_current_block_id()

	# Превью появляется только для предмета-блока в активной руке.
	if not block_id.is_empty():
		# Рамка накрывает весь футпринт (доменная печь 2×2, дрель 3×3), поэтому
		# передаём якорь футпринта, а не тайл под курсором.
		var size: Vector2i = _block_size(block_id)
		_preview_block_id = block_id
		build_preview_overlay.show_build_hover(
			block_id,
			_anchor_for(grid_pos, size),
			can_place_block_at(grid_pos, block_id),
			_player_facing(),
			_block_rotatable(block_id),
			size
		)
	else:
		_preview_block_id = ""
		build_preview_overlay.clear_overlay()


func _try_use_bucket(grid_pos: Vector2i) -> bool:
	if not _is_grid_in_build_radius(grid_pos):
		return false
	if _placed_blocks.has(grid_pos):
		return false
	var stack_value: Variant = _get_current_stack()
	if not (stack_value is Dictionary):
		return false
	var stack: Dictionary = stack_value.duplicate(true)
	var capacity := float(stack.get("fluid_capacity", 0.0))
	if capacity <= 0.0:
		return false
	var current_amount := float(stack.get("fluid_amount", 0.0))
	if current_amount >= capacity:
		return false
	var current_fluid := str(stack.get("fluid_id", ""))
	var world_node := get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("collect_fluid_at"):
		return false
	var collected: Dictionary = world_node.collect_fluid_at(
		grid_pos, capacity - current_amount
	) as Dictionary
	if collected.is_empty():
		return false
	var fluid_id := str(collected.get("fluid_id", ""))
	if not current_fluid.is_empty() and current_fluid != fluid_id:
		return false
	stack["fluid_id"] = fluid_id
	stack["fluid_amount"] = current_amount + float(collected.get("amount", 0.0))
	_set_current_stack(FluidDatabase.apply_bucket_display(stack))
	return true


func _set_current_stack(stack: Variant) -> void:
	if InventorySlot.held_item != null:
		InventorySlot.held_item = stack
		InventorySlot._update_held_preview_static()
		return
	if hotbar_ui == null:
		hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("set_active_item"):
		hotbar_ui.set_active_item(stack)


func _update_map_block(grid_pos: Vector2i, block_id: String) -> void:
	var map_ui := get_tree().get_first_node_in_group("map_ui")
	if map_ui and map_ui.has_method("set_player_block"):
		map_ui.set_player_block(grid_pos, block_id)


func _remove_map_block(grid_pos: Vector2i) -> void:
	var map_ui := get_tree().get_first_node_in_group("map_ui")
	if map_ui and map_ui.has_method("remove_player_block"):
		map_ui.remove_player_block(grid_pos)


func _get_mouse_world_position() -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * get_viewport().get_mouse_position()


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / float(GameConstants.TILE_SIZE)),
		floori(world_pos.y / float(GameConstants.TILE_SIZE))
	)


func _grid_to_world_center(grid_pos: Vector2i) -> Vector2:
	var half: float = GameConstants.TILE_SIZE * 0.5
	return Vector2(
		grid_pos.x * GameConstants.TILE_SIZE + half,
		grid_pos.y * GameConstants.TILE_SIZE + half
	)


func _grid_key(grid_pos: Vector2i) -> String:
	return "%d,%d" % [grid_pos.x, grid_pos.y]


func _parse_grid_key(key_text: String) -> Vector2i:
	var parts: PackedStringArray = key_text.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _is_mouse_over_ui() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false

	if hovered.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false

	if hovered.name in [&"HUD", &"Notifications", &"BossUI"]:
		return false

	return true


func _get_current_stack() -> Variant:
	if InventorySlot.held_item != null:
		return InventorySlot.held_item
	if hotbar_ui == null:
		hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("get_active_item"):
		return hotbar_ui.get_active_item()
	return null


func _get_current_block_id() -> String:
	var stack: Variant = _get_current_stack()
	if stack == null or not (stack is Dictionary):
		return ""
	return str(stack.get("block_id", ""))


func _consume_current_stack(amount: int) -> void:
	if InventorySlot.held_item != null:
		InventorySlot.consume_from_held(amount)
		return
	if hotbar_ui == null:
		hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("consume_active_item"):
		hotbar_ui.consume_active_item(amount)


func _get_mining_tool_data() -> Dictionary:
	var stack: Variant = _get_current_stack()
	if stack == null or not (stack is Dictionary):
		return {"tool_type": "", "power": 0}
	var bonuses := EquipmentBonusSystem.current(get_tree())
	return {
		"tool_type": str(stack.get("tool_type", "")),
		"power": maxi(int(stack.get("power", 1)) + int(bonuses.get("mining_power", 0)), 1),
	}


## Damage one one-second tick does to a placed block.
func _get_tool_damage(required_tool: String) -> int:
	var stack: Variant = _get_current_stack()
	if stack == null or not (stack is Dictionary):
		return ToolTierSystem.mining_damage(1, "", required_tool)
	var tool_type: String = str(stack.get("tool_type", ""))
	var power: int = maxi(int(stack.get("power", 1)), 1)
	return ToolTierSystem.mining_damage(power, tool_type, required_tool)


## Tool type of the held item ("" for bare hands / non-tools) — used to pick the
## swing animation.
func _held_tool_type() -> String:
	var stack: Variant = _get_current_stack()
	if stack is Dictionary:
		return str((stack as Dictionary).get("tool_type", ""))
	return ""


## Tool power of the held item (1 for bare hands).
func _held_tool_power() -> int:
	var stack: Variant = _get_current_stack()
	if stack is Dictionary:
		return maxi(int((stack as Dictionary).get("power", 1)), 1)
	return 1


func _is_grid_in_build_radius(grid_pos: Vector2i) -> bool:
	if not is_instance_valid(player):
		return false
	var player_grid: Vector2i = _world_to_grid(player.global_position)
	return (
		abs(grid_pos.x - player_grid.x) <= build_radius_tiles
		and abs(grid_pos.y - player_grid.y) <= build_radius_tiles
	)


func _is_player_on_grid(grid_pos: Vector2i) -> bool:
	if not is_instance_valid(player):
		return false
	return _world_to_grid(player.global_position) == grid_pos

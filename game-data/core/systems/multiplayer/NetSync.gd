# res://core/systems/multiplayer/NetSync.gd
# Игровая сторона мультиплеера. Game.gd добавляет эту ноду только при активной
# сессии. Транспорт и RPC живут в автолоаде MultiplayerManager — здесь спавн
# пупетов чужих игроков, применение сетевых событий мира и выход при обрыве.
extends Node
class_name NetSync

const PLAYER_SCENE := preload("res://entities/player/Player.tscn")
const MENU_SCENE_PATH := "res://ui/menus/Main.tscn"

const JOIN_COLOR := Color(0.6, 1.0, 0.6)
const LEAVE_COLOR := Color(1.0, 0.75, 0.5)

## Пока меню машины открыто, её состояние рассылается с этим интервалом.
const MACHINE_SYNC_INTERVAL := 0.5
## Хост раз в столько секунд шлёт снимок всех машин — гасит дрейф автономной
## симуляции (печи/дрели тикают у каждого пира независимо).
const MACHINES_SNAPSHOT_INTERVAL := 10.0
const PROGRESSION_SYNC_INTERVAL := 1.0

var world: Node2D = null
var local_player: Node2D = null

# peer_id -> нода пупета (Player.tscn с is_puppet = true).
var _puppets: Dictionary = {}

# Блок, чьё меню сейчас открыто у ЛОКАЛЬНОГО игрока (null — меню закрыто).
var _active_block: WorldBlock = null
var _machine_accum := 0.0
var _snapshot_accum := 0.0
var _progression_accum := 0.0
var _progression_signature := ""

# Переподключение после обрыва: пока диалог открыт, игра на паузе. Флаг
# _keep_session_on_exit не даёт _exit_tree старой сцены закрыть только что
# восстановленную сессию при перезаходе в Game.tscn.
var _keep_session_on_exit := false
var _reconnect_ui: CanvasLayer = null
var _reconnect_status: Label = null
var _reconnect_buttons: Array[Button] = []


func _ready() -> void:
	add_to_group("net_sync")
	MultiplayerManager.player_joined.connect(_on_player_joined)
	MultiplayerManager.player_left.connect(_on_player_left)
	MultiplayerManager.player_state_received.connect(_on_player_state)
	MultiplayerManager.remote_block_placed.connect(_on_remote_block_placed)
	MultiplayerManager.remote_block_removed.connect(_on_remote_block_removed)
	MultiplayerManager.remote_ore_mined.connect(_on_remote_ore_mined)
	MultiplayerManager.remote_ore_hit.connect(_on_remote_ore_hit)
	MultiplayerManager.remote_drop_spawned.connect(_on_remote_drop_spawned)
	MultiplayerManager.drop_claimed.connect(_on_drop_claimed)
	MultiplayerManager.remote_machine_state.connect(_on_remote_machine_state)
	MultiplayerManager.machine_state_submitted.connect(_on_machine_state_submitted)
	MultiplayerManager.remote_machines_snapshot.connect(_on_remote_machines_snapshot)
	MultiplayerManager.machine_config_submitted.connect(_on_machine_config_submitted)
	MultiplayerManager.factory_progression_received.connect(_on_factory_progression_received)
	MultiplayerManager.disconnected.connect(_on_disconnected)

	# Игроки, вошедшие в мир раньше нас (клиент всегда застаёт хоста).
	for peer_id: int in MultiplayerManager.players:
		_spawn_puppet(peer_id, MultiplayerManager.peer_display_name(peer_id))

	# Дропы, лежавшие в мире до нашего входа (из снапшота хоста).
	for payload: Variant in MultiplayerManager.pending_world_drops:
		if payload is Dictionary:
			_on_remote_drop_spawned(payload)
	MultiplayerManager.pending_world_drops.clear()

	MultiplayerManager.announce_self()


func _exit_tree() -> void:
	# Уход из игровой сцены = конец сессии: хост закрывает сервер, клиент
	# отключается. Повторный вызов после обрыва связи безопасен.
	# Исключение — перезаход в Game.tscn после успешного reconnect: новая сцена
	# продолжает уже восстановленное подключение.
	if _keep_session_on_exit:
		return
	MultiplayerManager.disconnect_net()


func _process(delta: float) -> void:
	_machine_accum += delta
	if _machine_accum >= MACHINE_SYNC_INTERVAL:
		_machine_accum = 0.0
		_tick_active_machine()

	if MultiplayerManager.is_server():
		_snapshot_accum += delta
		if _snapshot_accum >= MACHINES_SNAPSHOT_INTERVAL:
			_snapshot_accum = 0.0
			_broadcast_machines_snapshot()
		_progression_accum += delta
		if _progression_accum >= PROGRESSION_SYNC_INTERVAL:
			_progression_accum = 0.0
			_broadcast_progression_if_changed()


# ─────────────────────────────────────────────
#  МАШИНЫ И СУНДУКИ
# ─────────────────────────────────────────────

## Зовётся InteractionPrompt при открытии меню машины/сундука: пока меню
## открыто, состояние блока рассылается, а клиент сразу просит у хоста свежее.
func notify_menu_opened(block: WorldBlock) -> void:
	if block == null:
		return
	_active_block = block
	_machine_accum = 0.0
	MultiplayerManager.request_machine_state(block.grid_pos)


func _tick_active_machine() -> void:
	if _active_block == null:
		return
	if not is_instance_valid(_active_block):
		_active_block = null
		return
	MultiplayerManager.broadcast_machine_state(
		_active_block.grid_pos, _active_block.get_extra_save_data()
	)
	# ME-меню меняет состояние ЧУЖИХ блоков (диски, контроллер), а не только
	# открытого — рассылаем всю ME-сеть, пока терминал открыт.
	if str(_active_block.interact_type).begins_with("me_"):
		_broadcast_me_blocks()
	# Все меню закрыты — состояние выше стало финальным, снимаем слежение.
	var prompt: Variant = get_tree().get_first_node_in_group("interaction_prompt")
	if prompt == null or not prompt.any_menu_open():
		_active_block = null


func _broadcast_me_blocks() -> void:
	for node: Node in get_tree().get_nodes_in_group("world_block"):
		var block: WorldBlock = node as WorldBlock
		if block == null or not is_instance_valid(block) or block == _active_block:
			continue
		if not str(block.interact_type).begins_with("me_"):
			continue
		MultiplayerManager.broadcast_machine_state(
			block.grid_pos, block.get_extra_save_data()
		)


func _broadcast_machines_snapshot() -> void:
	var im: Variant = _interaction_manager()
	if im != null and im.has_method("serialize_placed_blocks"):
		MultiplayerManager.broadcast_machines_snapshot(im.serialize_placed_blocks())


func _on_remote_machine_state(anchor: Vector2i, extra_data: Dictionary) -> void:
	var im: Variant = _interaction_manager()
	if im != null and im.has_method("apply_remote_machine_state"):
		im.apply_remote_machine_state(anchor, extra_data)


func _on_remote_machines_snapshot(blocks: Dictionary) -> void:
	var im: Variant = _interaction_manager()
	if im == null or not im.has_method("apply_remote_machine_snapshot"):
		return
	# Блок, с которым игрок сейчас работает, снимком не затираем.
	var skip: Variant = null
	if _active_block != null and is_instance_valid(_active_block):
		skip = _active_block.grid_pos
	im.apply_remote_machine_snapshot(blocks, skip)


func _on_machine_config_submitted(anchor: Vector2i, config: Dictionary, sender_peer_id: int) -> void:
	if not MultiplayerManager.is_server():
		return
	var im: Variant = _interaction_manager()
	if im == null or not im.has_method("get_block_at"):
		return
	var block := im.get_block_at(anchor) as WorldBlock
	if block == null or block.machine == null:
		return
	if sender_peer_id != 1:
		var puppet := _puppets.get(sender_peer_id) as Node2D
		var max_distance := float(GameConstants.TILE_SIZE) * 10.0
		if puppet == null or puppet.global_position.distance_squared_to(block.global_position) > max_distance * max_distance:
			MultiplayerManager.broadcast_machine_state(anchor, block.get_extra_save_data())
			return
	block.machine.apply_network_config(_validated_machine_config(block.machine, config))
	MultiplayerManager.broadcast_machine_state(anchor, block.get_extra_save_data())


func _on_machine_state_submitted(anchor: Vector2i, extra_data: Dictionary, sender_peer_id: int) -> void:
	if not MultiplayerManager.is_server():
		return
	var im: Variant = _interaction_manager()
	if im == null or not im.has_method("get_block_at"):
		return
	var block := im.get_block_at(anchor) as WorldBlock
	if block == null or not _peer_can_edit_block(sender_peer_id, block):
		if block != null:
			MultiplayerManager.broadcast_machine_state(anchor, block.get_extra_save_data())
		return
	var validated_config: Dictionary = {}
	if block.machine != null:
		var machine_data: Variant = extra_data.get("machine_data", {})
		validated_config = _validated_machine_config(block.machine, machine_data if machine_data is Dictionary else {})
	block.load_extra_save_data(extra_data)
	if block.machine != null:
		block.machine.apply_network_config(validated_config)
	MultiplayerManager.broadcast_machine_state(anchor, block.get_extra_save_data())


func _peer_can_edit_block(sender_peer_id: int, block: WorldBlock) -> bool:
	if sender_peer_id == 1:
		return true
	var puppet := _puppets.get(sender_peer_id) as Node2D
	var max_distance := float(GameConstants.TILE_SIZE) * 10.0
	return puppet != null and puppet.global_position.distance_squared_to(block.global_position) <= max_distance * max_distance


func _validated_machine_config(machine: MachineContainer, requested: Dictionary) -> Dictionary:
	var validated := machine.network_config_data()
	var requested_modules: Variant = requested.get("modules", {})
	if requested_modules is Dictionary:
		var modules: Dictionary = validated.get("modules", {}).duplicate(true)
		for module_type: String in MachineContainer.MODULE_ITEMS:
			var current := machine.get_module_level(module_type)
			modules[module_type] = clampi(int(requested_modules.get(module_type, current)), maxi(0, current - 1), mini(MachineContainer.MODULE_LIMIT, current + 1))
		validated["modules"] = modules
	if machine is ConveyorContainer:
		validated["filter_ids"] = requested.get("filter_ids", validated.get("filter_ids", []))
		validated["filter_mode"] = requested.get("filter_mode", validated.get("filter_mode", "allow"))
		validated["priority"] = requested.get("priority", validated.get("priority", 0))
	if machine is ConveyorSplitterContainer:
		validated["output_filters"] = requested.get("output_filters", validated.get("output_filters", []))
		validated["output_priorities"] = requested.get("output_priorities", validated.get("output_priorities", []))
	if machine is MechanicalInserterContainer:
		validated["filter_ids"] = requested.get("filter_ids", validated.get("filter_ids", []))
		validated["filter_mode"] = requested.get("filter_mode", validated.get("filter_mode", "allow"))
		validated["enabled"] = bool(requested.get("enabled", validated.get("enabled", true)))
		validated["facing"] = clampi(int(requested.get("facing", validated.get("facing", 2))), 0, 3)
	if machine is SteamAssemblerContainer:
		var recipe_id := str(requested.get("selected_recipe_id", validated.get("selected_recipe_id", "")))
		if SteamAssemblerContainer.ASSEMBLY_RECIPES.has(recipe_id):
			validated["selected_recipe_id"] = recipe_id
	return validated


func _broadcast_progression_if_changed() -> void:
	TechnologyTree.refresh_unlocks()
	var save := SaveManager.current_save
	var world_data := SaveManager.current_world
	if save == null or world_data == null:
		return
	var technologies := Array(save.researched_technologies)
	var bosses := Array(save.defeated_bosses)
	var recipes := Array(save.unlocked_recipes)
	var permanent_access := Array(save.permanent_biome_access)
	var biomes := Array(world_data.discovered_biomes.keys())
	technologies.sort()
	bosses.sort()
	recipes.sort()
	permanent_access.sort()
	biomes.sort()
	var signature := JSON.stringify([technologies, bosses, recipes, permanent_access, biomes])
	if signature == _progression_signature:
		return
	_progression_signature = signature
	MultiplayerManager.broadcast_factory_progression({
		"researched_technologies": technologies,
		"defeated_bosses": bosses,
		"unlocked_recipes": recipes,
		"permanent_biome_access": permanent_access,
		"discovered_biomes": world_data.discovered_biomes.duplicate(true),
	})


func _on_factory_progression_received(state: Dictionary) -> void:
	if not MultiplayerManager.is_client():
		return
	var save := SaveManager.current_save
	var world_data := SaveManager.current_world
	if save == null or world_data == null:
		return
	save.researched_technologies.clear()
	for technology: Variant in state.get("researched_technologies", []):
		var technology_id := str(technology)
		if not save.researched_technologies.has(technology_id):
			save.researched_technologies.append(technology_id)
	save.defeated_bosses.clear()
	for boss_value: Variant in state.get("defeated_bosses", []):
		var boss_id := str(boss_value)
		if not save.defeated_bosses.has(boss_id):
			save.defeated_bosses.append(boss_id)
	save.unlocked_recipes.clear()
	for recipe_value: Variant in state.get("unlocked_recipes", []):
		var recipe_id := str(recipe_value)
		if not save.unlocked_recipes.has(recipe_id):
			save.unlocked_recipes.append(recipe_id)
	save.permanent_biome_access.clear()
	for access_value: Variant in state.get("permanent_biome_access", []):
		var access_id := str(access_value)
		if not save.permanent_biome_access.has(access_id):
			save.permanent_biome_access.append(access_id)
	var discovered_value: Variant = state.get("discovered_biomes", {})
	if discovered_value is Dictionary:
		world_data.discovered_biomes = (discovered_value as Dictionary).duplicate(true)
	var map_system := get_tree().get_first_node_in_group("map_system")
	if map_system != null:
		if map_system.has_method("_rebuild_boss_markers"):
			map_system.call("_rebuild_boss_markers")
		if map_system.has_method("_refresh_legend"):
			map_system.call("_refresh_legend")


# ─────────────────────────────────────────────
#  ПУПЕТЫ УДАЛЁННЫХ ИГРОКОВ
# ─────────────────────────────────────────────

func _spawn_puppet(peer_id: int, display_name: String) -> void:
	if _puppets.has(peer_id) or world == null:
		return
	var puppet: Player = PLAYER_SCENE.instantiate()
	puppet.is_puppet = true
	puppet.name = "RemotePlayer_%d" % peer_id
	# Стартуем на позиции локального игрока — первый же пакет состояния
	# передвинет пупета куда нужно (дальше PUPPET_SNAP_DIST — телепортом).
	if local_player != null:
		puppet.position = local_player.global_position
	world.add_child(puppet)
	puppet.add_child(_make_name_label(display_name))
	_puppets[peer_id] = puppet


func _make_name_label(display_name: String) -> Label:
	var label := Label.new()
	label.text = display_name
	label.custom_minimum_size = Vector2(120, 0)
	label.position = Vector2(-60, -46)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	return label


func _remove_puppet(peer_id: int) -> void:
	var puppet: Variant = _puppets.get(peer_id)
	_puppets.erase(peer_id)
	if puppet is Node and is_instance_valid(puppet):
		puppet.queue_free()


func _on_player_joined(peer_id: int, display_name: String) -> void:
	_spawn_puppet(peer_id, display_name)
	_chat_message("%s joined the game" % display_name, JOIN_COLOR)


func _on_player_left(peer_id: int, display_name: String) -> void:
	_remove_puppet(peer_id)
	_chat_message("%s left the game" % display_name, LEAVE_COLOR)


func _on_player_state(peer_id: int, state: Dictionary) -> void:
	# Состояние может прийти раньше announce — тогда пупета ещё нет, пропускаем.
	var puppet: Variant = _puppets.get(peer_id)
	if puppet is Node and is_instance_valid(puppet):
		puppet.apply_network_state(state)


# ─────────────────────────────────────────────
#  СОБЫТИЯ МИРА
# ─────────────────────────────────────────────

func _on_remote_block_placed(anchor: Vector2i, block_id: String, facing: int) -> void:
	var im: Variant = _interaction_manager()
	if im != null:
		im.apply_remote_place(anchor, block_id, facing)


func _on_remote_block_removed(anchor: Vector2i) -> void:
	var im: Variant = _interaction_manager()
	if im != null:
		im.apply_remote_destroy(anchor)


func _on_remote_ore_mined(global_tile_pos: Vector2i, tool_power: int, tool_type: String) -> void:
	if world != null and world.has_method("apply_remote_mine"):
		world.apply_remote_mine(global_tile_pos, tool_power, tool_type)


## Чужой удар по тайлу: снимаем HP из нашего пула того же тайла (ресурс не выдаём —
## его выдаст тот, кто добьёт, отдельным тиком добычи).
func _on_remote_ore_hit(global_tile_pos: Vector2i, damage: float) -> void:
	var im: Variant = _interaction_manager()
	if im != null and im.has_method("apply_remote_mine_hit"):
		im.apply_remote_mine_hit(global_tile_pos, damage)


func _on_remote_drop_spawned(payload: Dictionary) -> void:
	var im: Variant = _interaction_manager()
	if im != null and im.has_method("spawn_remote_drop"):
		im.spawn_remote_drop(payload)


## Вердикт арбитра: наш запрос удовлетворён — забираем предмет; чужой — копия
## исчезает (сам предмет уже у победителя).
func _on_drop_claimed(net_id: String, claimer_peer_id: int) -> void:
	for node: Node in get_tree().get_nodes_in_group("dropped_items"):
		if not (node is DroppedItem):
			continue
		var drop: DroppedItem = node as DroppedItem
		if drop.net_id != net_id:
			continue
		if claimer_peer_id == MultiplayerManager.my_peer_id():
			drop.network_finish_pickup()
		else:
			drop.network_despawn()
		return


func _interaction_manager() -> Variant:
	if world != null and "interaction_manager" in world:
		return world.interaction_manager
	return get_tree().get_first_node_in_group("world_interaction")


# ─────────────────────────────────────────────
#  СЛУЖЕБНОЕ
# ─────────────────────────────────────────────

func _chat_message(text: String, color: Color) -> void:
	var chat: Variant = get_tree().get_first_node_in_group("game_chat")
	if chat != null and chat.has_method("add_colored_message"):
		chat.add_colored_message(text, color)


## Сервер пропал (клиентская сторона): предлагаем переподключиться к тому же
## хосту или выйти в главное меню. Без сохранённых параметров подключения
## (теоретический случай) — сразу в меню, как раньше.
func _on_disconnected() -> void:
	if MultiplayerManager.can_reconnect():
		_show_reconnect_dialog()
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU_SCENE_PATH)


# ─────────────────────────────────────────────
#  ДИАЛОГ ПЕРЕПОДКЛЮЧЕНИЯ
# ─────────────────────────────────────────────

func _show_reconnect_dialog() -> void:
	if _reconnect_ui != null:
		return
	get_tree().paused = true

	_reconnect_ui = CanvasLayer.new()
	_reconnect_ui.layer = 100
	_reconnect_ui.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reconnect_ui.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reconnect_ui.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = tr("Connection to host lost")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_reconnect_status = Label.new()
	_reconnect_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_reconnect_status)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	vbox.add_child(buttons)

	var retry := Button.new()
	retry.text = tr("Reconnect")
	retry.pressed.connect(_on_reconnect_pressed)
	buttons.add_child(retry)

	var menu_btn := Button.new()
	menu_btn.text = tr("Back to Menu")
	menu_btn.pressed.connect(_on_reconnect_menu_pressed)
	buttons.add_child(menu_btn)

	_reconnect_buttons = [retry, menu_btn]
	add_child(_reconnect_ui)
	retry.grab_focus()


func _on_reconnect_pressed() -> void:
	_set_reconnect_buttons_disabled(true)
	_reconnect_status.text = tr("Reconnecting...")
	if not MultiplayerManager.world_info_received.is_connected(_on_reconnect_world_info):
		MultiplayerManager.world_info_received.connect(_on_reconnect_world_info)
	if not MultiplayerManager.join_failed.is_connected(_on_reconnect_failed):
		MultiplayerManager.join_failed.connect(_on_reconnect_failed)
	MultiplayerManager.reconnect()


func _on_reconnect_world_info() -> void:
	# Мир хоста получен заново (SaveManager уже перенастроен в _rpc_world_info) —
	# перезаходим в игровую сцену, сохранив живое подключение.
	_disconnect_reconnect_signals()
	_keep_session_on_exit = true
	get_tree().paused = false
	LoadingScreen.change_scene(get_tree(), "res://game/Game.tscn", "Подключение к миру...")


func _on_reconnect_failed(reason: String) -> void:
	_disconnect_reconnect_signals()
	_set_reconnect_buttons_disabled(false)
	_reconnect_status.text = tr("Failed: ") + reason


func _on_reconnect_menu_pressed() -> void:
	_disconnect_reconnect_signals()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE_PATH)


func _disconnect_reconnect_signals() -> void:
	if MultiplayerManager.world_info_received.is_connected(_on_reconnect_world_info):
		MultiplayerManager.world_info_received.disconnect(_on_reconnect_world_info)
	if MultiplayerManager.join_failed.is_connected(_on_reconnect_failed):
		MultiplayerManager.join_failed.disconnect(_on_reconnect_failed)


func _set_reconnect_buttons_disabled(disabled: bool) -> void:
	for btn: Button in _reconnect_buttons:
		if is_instance_valid(btn):
			btn.disabled = disabled

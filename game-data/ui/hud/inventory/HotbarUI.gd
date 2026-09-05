# res://ui/hud/inventory/HotbarUI.gd
## Хотбар показывает первую строку общего инвентаря. Остальные три строки
## остаются обычными слотами сумки и не подменяют активную панель.
## Собственного хранилища у хотбара НЕТ: всё лежит в InventoryUI, локальный
## `slots` остаётся пустым (чтобы крафт не считал предметы дважды).
extends InventoryContainer

const TOTAL_HOTBAR_SLOTS = 9

const HOTBAR_BG := Color(0.08, 0.13, 0.18, 0.94)
const HOTBAR_BORDER := Color(0.28, 0.72, 0.78)

@onready var hotbar_grid: GridContainer = %HotbarGrid

var active_hotbar_index: int = 0
var _inv_cached: Node = null


func _ready() -> void:
	add_to_group("hotbar_ui")

	if has_node("Background"):
		get_node("Background").gui_input.connect(_on_background_gui_input)

	var hints: Array = []
	for i in range(TOTAL_HOTBAR_SLOTS):
		hints.append(i + 1)
	_init_container(TOTAL_HOTBAR_SLOTS, hotbar_grid, hints)
	# Инвентарь — соседний узел HUD: подключаемся после построения сцены.
	call_deferred("_late_init")


func _late_init() -> void:
	var inv: Node = _inv()
	if inv != null and not inv.inventory_changed.is_connected(_on_inventory_changed):
		inv.inventory_changed.connect(_on_inventory_changed)
	_apply_row()


func _inv() -> Node:
	if _inv_cached == null or not is_instance_valid(_inv_cached):
		_inv_cached = get_tree().get_first_node_in_group("inventory_ui")
	return _inv_cached


## Индекс первого слота активной строки в инвентаре.
func _base() -> int:
	return 0


func _on_inventory_changed(_slot_index: int) -> void:
	_refresh_all_slots()
	update_item_preview(get_active_item())


func _input(event: InputEvent) -> void:
	if get_tree().paused or GameChat.is_blocking_input() or _any_menu_open() or _is_text_input_focused():
		return
	if event is InputEventKey and (not event.pressed or event.is_echo()):
		return
	if event is InputEventMouseButton and not event.pressed:
		return

	var next_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		next_index = (active_hotbar_index - 1 + TOTAL_HOTBAR_SLOTS) % TOTAL_HOTBAR_SLOTS
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		next_index = (active_hotbar_index + 1) % TOTAL_HOTBAR_SLOTS
	elif event.is_action_pressed("mouse_wheel_up"):
		# Геймпадный эквивалент прокрутки из InputMap.
		next_index = (active_hotbar_index - 1 + TOTAL_HOTBAR_SLOTS) % TOTAL_HOTBAR_SLOTS
	elif event.is_action_pressed("mouse_wheel_down"):
		next_index = (active_hotbar_index + 1) % TOTAL_HOTBAR_SLOTS
	else:
		for i in range(TOTAL_HOTBAR_SLOTS):
			if event.is_action_pressed("hotbar_%d" % (i + 1)):
				next_index = i
				break
	if next_index >= 0:
		_select_hotbar_slot(next_index)
		get_viewport().set_input_as_handled()


## Подключает хотбар к первой строке, красит её и гарантирует, что один слот
## остаётся активным сразу после создания интерфейса.
func _apply_row() -> void:
	for i in range(mini(TOTAL_HOTBAR_SLOTS, grid.get_child_count())):
		var slot: Node = grid.get_child(i)
		if slot is InventorySlot:
			(slot as InventorySlot).set_section_tint(HOTBAR_BG, HOTBAR_BORDER)
	_refresh_all_slots()
	var inv: Node = _inv()
	if inv != null and inv.has_method("set_active_row"):
		inv.set_active_row(0)
	_update_hotbar_selection()
	update_item_preview(get_active_item())


# ── Прокси хранилища: все данные живут в InventoryUI ─────────────────────────

func get_slot_data_at(index: int) -> Variant:
	var inv: Node = _inv()
	if inv == null or index < 0 or index >= TOTAL_HOTBAR_SLOTS:
		return null
	return inv.get_slot_data_at(_base() + index)


func set_slot_data_at(index: int, data: Variant) -> void:
	var inv: Node = _inv()
	if inv == null or index < 0 or index >= TOTAL_HOTBAR_SLOTS:
		return
	inv.set_slot_data_at(_base() + index, data)
	if grid != null and grid.get_child_count() > index:
		grid.get_child(index).display_item(data)
	inventory_changed.emit(index)


## Ключ подлинного слота хранилища — совпадает с ключом того же слота в сетке
## инвентаря, чтобы drag-распределение не задело один слот дважды.
func canonical_slot_key(index: int) -> String:
	var inv: Node = _inv()
	if inv == null:
		return "%d:%d" % [get_instance_id(), index]
	return "%d:%d" % [inv.get_instance_id(), _base() + index]


func _refresh_all_slots() -> void:
	if grid == null:
		return
	for index: int in range(mini(TOTAL_HOTBAR_SLOTS, grid.get_child_count())):
		var slot_node: Node = grid.get_child(index)
		if slot_node.has_method("display_item"):
			slot_node.display_item(get_slot_data_at(index))


## Подбор сначала заполняет активную строку; остаток отправляется в сумку.
func auto_insert_item(incoming_item: Dictionary) -> Variant:
	var inv: Node = _inv()
	if inv == null or not inv.has_method("insert_into_row"):
		return incoming_item
	return inv.insert_into_row(_base(), incoming_item)


func accepts_item(data) -> bool:
	return true


func get_first_empty_slot_index() -> int:
	for i in range(TOTAL_HOTBAR_SLOTS):
		if get_slot_data_at(i) == null:
			return i
	return -1


# ── Сейв ─────────────────────────────────────────────────────────────────────
# Хранилища у хотбара больше нет — quickbar-сейв пуст; старые quickbar-сейвы
# переносятся в инвентарь при загрузке (легаси-миграция).

func to_save_data() -> InventorySaveData:
	var save_data := InventorySaveData.new()
	save_data.size = 0
	return save_data


func from_save_data(save_data: InventorySaveData) -> void:
	_refresh_all_slots()
	if save_data == null or save_data.slots.is_empty():
		return
	var inv: Node = _inv()
	if inv == null:
		return
	for key: Variant in save_data.slots:
		var stack: Dictionary = ItemDatabase.stack_from_save(save_data.slots[key])
		if stack.is_empty():
			continue
		var leftover: Variant = inv.auto_insert_item(stack)
		if leftover is Dictionary and int((leftover as Dictionary).get("count", 0)) > 0:
			_drop_leftover(leftover)


## Инвентарь полон (старый формат был больше) — выбрасываем остаток у игрока,
## чтобы ничего не потерять.
func _drop_leftover(stack: Dictionary) -> void:
	var wim: Node = get_tree().get_first_node_in_group("world_interaction")
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if wim != null and player != null and wim.has_method("respawn_leftover_drop"):
		wim.call_deferred("respawn_leftover_drop", stack, player.global_position)


# ── Активный предмет ─────────────────────────────────────────────────────────

func _select_hotbar_slot(index: int) -> void:
	active_hotbar_index = clampi(index, 0, TOTAL_HOTBAR_SLOTS - 1)
	_update_hotbar_selection()
	update_item_preview(get_active_item())


func get_active_item() -> Variant:
	return get_slot_data_at(active_hotbar_index)


func set_active_item(item_data: Variant) -> void:
	set_slot_data_at(active_hotbar_index, item_data)


func consume_active_item(amount: int = 1) -> void:
	var item: Variant = get_active_item()
	if item == null or not item is Dictionary:
		return

	item["count"] = int(item.get("count", 1)) - amount
	if item["count"] <= 0:
		set_active_item(null)
	else:
		set_active_item(item)


func _update_hotbar_selection() -> void:
	for i in range(TOTAL_HOTBAR_SLOTS):
		var slot_node = grid.get_child(i)
		if slot_node and slot_node.has_method("set_active"):
			slot_node.set_active(i == active_hotbar_index)


func update_item_preview(item_data: Variant) -> void:
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui and inv_ui.has_method("update_item_preview"):
		inv_ui.update_item_preview(item_data)


func _is_text_input_focused() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit


## True while any blocking menu is open, so mouse-wheel / number-key hotbar
## selection is suppressed. Reuses InteractionPrompt's menu list (single source
## of truth) and falls back to false if the prompt isn't in the tree yet.
func _any_menu_open() -> bool:
	var prompt := get_tree().get_first_node_in_group("interaction_prompt")
	return prompt != null and prompt.any_menu_open()

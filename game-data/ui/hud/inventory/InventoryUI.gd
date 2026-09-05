# res://ui/hud/inventory/InventoryUI.gd
## Инвентарь-хранилище на 4 строки по 9 слотов (36).
## Первая строка всегда отображается хотбаром, остальные три — в сумке.
extends InventoryContainer

const TOTAL_INV_SLOTS = 36
const VISIBLE_SLOTS = 27
const ROW_SIZE = 9
const SLOT_BG := Color(0.08, 0.13, 0.18, 0.94)
const SLOT_BORDER := Color(0.24, 0.48, 0.54)

@onready var inventory_grid: GridContainer = %InventoryGrid

var player_preview: PlayerPreviewPanel = null
## Строка хранилища, которую показывает хотбар. В обычной игре это всегда 0.
var _active_row: int = -1

func _ready() -> void:
	add_to_group("inventory_ui")

	if has_node("Background"):
		get_node("Background").gui_input.connect(_on_background_gui_input)

	# 27 видимых узлов, но хранилище — все 36 слотов.
	_init_container(VISIBLE_SLOTS, inventory_grid)
	slots.resize(TOTAL_INV_SLOTS)
	slot_count = TOTAL_INV_SLOTS
	_apply_layout()

	_build_player_preview()

	if has_node("Background"):
		get_node("Background").hide()
	if player_preview:
		player_preview.hide()


# ── Раскладка видимых строк ──────────────────────────────────────────────────

## Строка хранилища, отданная хотбару (с защитой от рассинхрона сигналов).
func _hotbar_storage_row() -> int:
	return _active_row if _active_row >= 0 and _active_row < 4 else 0


## Показываем все строки, кроме той, которая сейчас находится в хотбаре.
func _display_rows() -> Array:
	var hb := _hotbar_storage_row()
	var rows: Array = []
	for row in range(4):
		if row != hb:
			rows.append(row)
	return rows


## Перепривязывает видимые узлы к строкам хранилища и перерисовывает их.
func _apply_layout() -> void:
	if grid == null:
		return
	var rows := _display_rows()
	for d in range(mini(VISIBLE_SLOTS, grid.get_child_count())):
		@warning_ignore("integer_division")
		var storage: int = int(rows[d / ROW_SIZE]) * ROW_SIZE + (d % ROW_SIZE)
		var node: Node = grid.get_child(d)
		if node is InventorySlot:
			(node as InventorySlot).slot_index = storage
		if node.has_method("display_item"):
			node.display_item(slots[storage])
	_apply_section_styles()


func _apply_section_styles() -> void:
	for d in range(mini(VISIBLE_SLOTS, grid.get_child_count())):
		var node: Node = grid.get_child(d)
		if not (node is InventorySlot):
			continue
		var slot := node as InventorySlot
		slot.set_section_tint(SLOT_BG, SLOT_BORDER)


## Зовётся хотбаром при инициализации раскладки.
func set_active_row(row: int) -> void:
	_active_row = row
	_apply_layout()


# ── Хранилище: внешние индексы = индексы хранилища (0..35) ──────────────────

func set_slot_data_at(index: int, data: Variant) -> void:
	if index < 0 or index >= slot_count:
		return
	slots[index] = data
	_refresh_storage_slot(index)
	inventory_changed.emit(index)


## Обновляет видимый узел, привязанный к данному слоту хранилища (если он
## сейчас отображается; слот из строки хотбара рисует сам хотбар).
func _refresh_storage_slot(index: int) -> void:
	if grid == null:
		return
	for d in range(mini(VISIBLE_SLOTS, grid.get_child_count())):
		var node: Node = grid.get_child(d)
		if node is InventorySlot and (node as InventorySlot).slot_index == index:
			node.display_item(slots[index])
			return


func _refresh_all_slots() -> void:
	_apply_layout()


func from_save_data(save_data: InventorySaveData) -> void:
	slots.fill(null)
	if save_data != null:
		for i in range(slot_count):
			if save_data.slots.has(i):
				slots[i] = ItemDatabase.stack_from_save(save_data.slots[i])
	_apply_layout()


# ── Фильтр ручного переноса ──────────────────────────────────────────────────

func accepts_item_at(index: int, data) -> bool:
	return true


# ── Авто-вставка с секциями ──────────────────────────────────────────────────

## Все предметы используют одно общее пространство без скрытых секций.
func auto_insert_item(incoming_item: Dictionary) -> Variant:
	if not accepts_item(incoming_item):
		return incoming_item
	var leftover: Variant = _insert_into_range(incoming_item, 0, slot_count)
	_refresh_all_slots()
	inventory_changed.emit(-1)
	return leftover


## Вставка в конкретную строку хранилища (окно хотбара). start — первый слот.
func insert_into_row(start: int, item: Dictionary) -> Variant:
	if not accepts_item(item):
		return item
	var leftover: Variant = _insert_into_range(item, start, mini(start + ROW_SIZE, slot_count))
	_refresh_all_slots()
	inventory_changed.emit(-1)
	return leftover


func _insert_into_range(item: Dictionary, start: int, end: int) -> Variant:
	var sub: Array = slots.slice(start, end)
	var leftover: Variant = InventoryStacking.insert(sub, sub.size(), item)
	for i in range(sub.size()):
		slots[start + i] = sub[i]
	return leftover


## Перенос предмета ИЗ хотбара в сумку. Хранилище общее, поэтому обычный
## auto_insert_item застакал бы предмет обратно в строку хотбара (в т.ч. сам на
## себя) — здесь активная строка хотбара исключается из целевых слотов.
func insert_excluding_hotbar_row(item: Dictionary) -> Variant:
	if not accepts_item(item):
		return item
	var hb_row := _hotbar_storage_row()
	var row_order: Array = [0, 1, 2, 3]
	var indices: Array = []
	for row: int in row_order:
		if row == hb_row:
			continue
		for col in range(ROW_SIZE):
			indices.append(row * ROW_SIZE + col)
	var leftover: Variant = _insert_into_indices(item, indices)
	_refresh_all_slots()
	inventory_changed.emit(-1)
	return leftover


## Вставка в произвольный (не обязательно непрерывный) список слотов хранилища
## в заданном порядке приоритета; возвращает остаток.
func _insert_into_indices(item: Dictionary, indices: Array) -> Variant:
	var sub: Array = []
	for idx: int in indices:
		sub.append(slots[int(idx)])
	var leftover: Variant = InventoryStacking.insert(sub, sub.size(), item)
	for i in range(indices.size()):
		slots[int(indices[i])] = sub[i]
	return leftover


# ── Превью игрока и ввод ─────────────────────────────────────────────────────

## Player preview (equipment + portrait) sits above the inventory grid and only
## appears with the main inventory — never in crafting / recipe-book / chest menus.
func _build_player_preview() -> void:
	player_preview = PlayerPreviewPanel.new()
	player_preview.anchor_left = 0.5
	player_preview.anchor_right = 0.5
	player_preview.anchor_top = 1.0
	player_preview.anchor_bottom = 1.0
	player_preview.grow_horizontal = Control.GROW_DIRECTION_BOTH
	player_preview.offset_left = -190.0
	player_preview.offset_right = 190.0
	player_preview.offset_top = -498.0
	player_preview.offset_bottom = -250.0
	add_child(player_preview)


func _unhandled_input(event: InputEvent) -> void:
	if GameChat.is_blocking_input():
		return
	var chest_ui: Node = get_tree().get_first_node_in_group("chest_ui")
	if chest_ui and chest_ui.visible:
		return
	# Don't toggle while a menu has borrowed the inventory slots (embed).
	var recipe_book: Node = get_tree().get_first_node_in_group("recipe_book_ui")
	if recipe_book and recipe_book.visible:
		return
	if event is InputEventKey and event.pressed and not event.is_echo() and event.is_action("inventory"):
		if has_node("Background"):
			var bg = get_node("Background")
			bg.visible = !bg.visible
			if player_preview:
				player_preview.visible = bg.visible
				if bg.visible:
					player_preview.refresh()
			if not bg.visible:
				AudioManager.play_sfx("ui_close", -4.0)
				InventorySlot._hide_tooltip()
				_return_held_item_to_inventory()
		get_viewport().set_input_as_handled()


func _return_held_item_to_inventory() -> void:
	if InventorySlot.held_item != null and not InventorySlot.held_item.is_empty():
		var leftovers = auto_insert_item(InventorySlot.held_item)
		var slot_instance = grid.get_child(0) if grid.get_child_count() > 0 else null

		if leftovers == null or leftovers.get("count", 0) <= 0:
			if slot_instance and slot_instance.has_method("_clear_held_item"):
				slot_instance._clear_held_item()
			else:
				InventorySlot.held_item = null
		else:
			InventorySlot.held_item = leftovers
			if slot_instance and slot_instance.has_method("_update_held_preview_count"):
				slot_instance._update_held_preview_count()

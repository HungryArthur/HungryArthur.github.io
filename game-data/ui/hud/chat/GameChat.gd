extends Control
class_name GameChat

const FADE_DELAY := 7.0
const FADE_DURATION := 1.0
const PLAYER_DISPLAY_NAME := "Игрок"
const MAX_VISIBLE_SUGGESTIONS := 8

static var is_open: bool = false

@onready var chat_stack: VBoxContainer = %ChatStack
@onready var chat_panel: PanelContainer = %ChatPanel
@onready var chat_history: RichTextLabel = %ChatHistory
@onready var suggestions_panel: PanelContainer = %SuggestionsPanel
@onready var suggestions_list: VBoxContainer = %SuggestionsList
@onready var chat_input: LineEdit = %ChatInput

var _fade_timer: float = 0.0
var _suggestions: PackedStringArray = PackedStringArray()
var _suggestion_index: int = 0
var _cycling_suggestions: bool = false


func _ready() -> void:
	add_to_group("game_chat")
	chat_input.hide()
	chat_input.text_submitted.connect(_on_message_submitted)
	chat_input.text_changed.connect(_on_input_text_changed)
	MultiplayerManager.chat_received.connect(_on_net_chat_received)
	MultiplayerManager.upnp_completed.connect(_on_upnp_completed)
	# Хост мог получить результат UPnP, ещё пока грузилась игровая сцена.
	var status: Dictionary = MultiplayerManager.upnp_status
	if not status.is_empty():
		_on_upnp_completed(bool(status.get("ok", false)), str(status.get("ip", "")))
	_apply_chat_alpha(0.0)
	_set_open_state(false)


func _process(delta: float) -> void:
	if is_open:
		_apply_chat_alpha(1.0)
		return

	if _fade_timer > 0.0:
		_fade_timer = maxf(0.0, _fade_timer - delta)
		_apply_chat_alpha(1.0)
		return

	var current_alpha: float = chat_stack.modulate.a
	if current_alpha <= 0.0:
		return

	var fade_step: float = delta / FADE_DURATION
	_apply_chat_alpha(maxf(0.0, current_alpha - fade_step))


static func is_blocking_input() -> bool:
	return is_open


func _input(event: InputEvent) -> void:
	if not is_open:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if _is_enter_key(event):
				_open_chat()
				get_viewport().set_input_as_handled()
			# «chat» привязан к физической «/», чтобы открывать чат на любой
			# раскладке (на русской этот же физический клавиш даёт другой символ).
			elif event.is_action("chat"):
				chat_input.text = "/"
				_open_chat()
				get_viewport().set_input_as_handled()
		return

	if not event is InputEventKey or not event.pressed:
		return
	if event.is_echo() and event.keycode != KEY_UP and event.keycode != KEY_DOWN:
		return

	if event.keycode == KEY_ESCAPE:
		_close_chat(false)
		get_viewport().set_input_as_handled()
		return

	if _suggestions.is_empty():
		return

	if event.keycode == KEY_TAB:
		_apply_selected_suggestion()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_UP:
		_cycle_suggestion(-1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_DOWN:
		_cycle_suggestion(1)
		get_viewport().set_input_as_handled()


func insert_item_into_inventories(item_data: Dictionary) -> Variant:
	var stack: Variant = item_data.duplicate(true)
	var hotbar: Node = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar and hotbar.has_method("auto_insert_item"):
		stack = hotbar.auto_insert_item(stack)
		if stack == null or int(stack.get("count", 0)) <= 0:
			return null

	var inventory: Node = get_tree().get_first_node_in_group("inventory_ui")
	if inventory and inventory.has_method("auto_insert_item"):
		return inventory.auto_insert_item(stack)

	return stack


func add_player_message(message: String) -> void:
	add_colored_message("[%s]: %s" % [_local_display_name(), message], Color.WHITE)


## Имя локального игрока: профиль в мультиплеере, иначе старое "Игрок".
func _local_display_name() -> String:
	if MultiplayerManager.is_active():
		return MultiplayerManager.local_display_name()
	return PLAYER_DISPLAY_NAME


## Итог автопроброса порта у хоста: показываем внешний адрес для друзей
## или подсказку, что порт придётся пробросить вручную.
func _on_upnp_completed(ok: bool, external_ip: String) -> void:
	if not MultiplayerManager.is_active() or not MultiplayerManager.is_server():
		return
	var port: int = int(MultiplayerManager.upnp_status.get("port", MultiplayerManager.DEFAULT_PORT))
	if ok and not external_ip.is_empty():
		add_colored_message(
			"Порт открыт! Друг может подключиться по адресу: %s:%d" % [external_ip, port],
			Color(0.6, 1.0, 0.6)
		)
	else:
		add_colored_message(
			"UPnP не сработал: для игры через интернет пробрось UDP-порт %d на роутере вручную (по локальной сети всё работает и так)." % port,
			Color(1.0, 0.8, 0.5)
		)


func _on_net_chat_received(peer_id: int, text: String) -> void:
	add_colored_message(
		"[%s]: %s" % [MultiplayerManager.peer_display_name(peer_id), text],
		Color(0.8, 0.9, 1.0)
	)


func add_colored_message(message: String, color: Color) -> void:
	var color_hex: String = color.to_html(false)
	chat_history.append_text("[color=#%s]%s[/color]\n" % [color_hex, message])
	_scroll_history_to_bottom()
	_notify_message_shown()


func clear_history() -> void:
	chat_history.clear()
	_apply_chat_alpha(0.0 if not is_open else 1.0)


func _open_chat() -> void:
	_set_open_state(true)
	chat_input.show()
	chat_input.grab_focus()
	chat_input.caret_column = chat_input.text.length()
	_update_suggestions(chat_input.text)
	_apply_chat_alpha(1.0)
	_fade_timer = 0.0


func _close_chat(clear_input: bool) -> void:
	if clear_input:
		chat_input.clear()
	chat_input.release_focus()
	chat_input.hide()
	_hide_suggestions()
	_set_open_state(false)
	_fade_timer = FADE_DELAY
	_apply_chat_alpha(1.0)


func _on_message_submitted(text: String) -> void:
	_submit_text(text)


func _on_input_text_changed(new_text: String) -> void:
	if _cycling_suggestions:
		return
	_update_suggestions(new_text)


func _submit_text(text: String) -> void:
	var parsed: Dictionary = ChatCommandParser.parse_line(text)
	if parsed.get("empty", false):
		_close_chat(true)
		return

	if parsed.get("is_command", false):
		ChatCommands.execute(parsed, self)
	else:
		var message: String = parsed.get("message", "")
		add_player_message(message)
		MultiplayerManager.send_chat(message)

	_close_chat(true)


func _update_suggestions(text: String) -> void:
	_suggestions = ChatCommandSuggestions.get_matches(text)
	_suggestion_index = 0

	if not is_open or _suggestions.is_empty():
		_hide_suggestions()
		return

	_show_suggestions()


func _show_suggestions() -> void:
	suggestions_panel.show()
	for child in suggestions_list.get_children():
		child.queue_free()

	var total := _suggestions.size()
	var visible_count := mini(total, MAX_VISIBLE_SUGGESTIONS)
	var window_start := clampi(_suggestion_index - visible_count + 1, 0, total - visible_count)

	for i in range(visible_count):
		var actual_idx := window_start + i
		var label := Label.new()
		label.text = _suggestions[actual_idx]
		label.add_theme_font_size_override("font_size", 14)
		if actual_idx == _suggestion_index:
			label.add_theme_color_override("font_color", Color("ffff55"))
		else:
			label.add_theme_color_override("font_color", Color("aaaaaa"))
		suggestions_list.add_child(label)


func _hide_suggestions() -> void:
	_suggestions = PackedStringArray()
	_suggestion_index = 0
	suggestions_panel.hide()
	for child in suggestions_list.get_children():
		child.queue_free()


func _cycle_suggestion(direction: int) -> void:
	if _suggestions.is_empty():
		return

	_suggestion_index = (_suggestion_index + direction) % _suggestions.size()
	if _suggestion_index < 0:
		_suggestion_index = _suggestions.size() - 1

	_cycling_suggestions = true
	chat_input.text = _suggestions[_suggestion_index]
	chat_input.caret_column = chat_input.text.length()
	_cycling_suggestions = false

	_show_suggestions()


func _apply_selected_suggestion() -> void:
	if _suggestions.is_empty():
		return

	var suggestion: String = _suggestions[_suggestion_index]
	chat_input.text = ChatCommandSuggestions.apply_completion(chat_input.text, suggestion)
	chat_input.caret_column = chat_input.text.length()
	_update_suggestions(chat_input.text)


func _notify_message_shown() -> void:
	if is_open:
		_apply_chat_alpha(1.0)
		return
	_fade_timer = FADE_DELAY
	_apply_chat_alpha(1.0)


func _scroll_history_to_bottom() -> void:
	await get_tree().process_frame
	chat_history.scroll_to_line(chat_history.get_line_count())


func _apply_chat_alpha(alpha: float) -> void:
	chat_stack.modulate.a = alpha


func _set_open_state(open: bool) -> void:
	is_open = open
	mouse_filter = MOUSE_FILTER_STOP if open else MOUSE_FILTER_IGNORE


func _is_enter_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER

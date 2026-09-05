extends Node2D
class_name LogisticsNetworkOverlay

const ROUTE_ACTIVE := Color(0.36, 0.96, 0.50, 0.90)
const ROUTE_TRANSIT := Color(0.16, 0.86, 1.0, 0.96)
const ROUTE_MISSING := Color(1.0, 0.67, 0.16, 0.96)
const ROUTE_BLOCKED := Color(1.0, 0.20, 0.14, 0.98)
const REQUESTER_COLOR := Color(0.76, 0.34, 1.0, 0.96)
const PROVIDER_COLOR := Color(0.18, 0.68, 1.0, 0.96)
const SELECTED_COLOR := Color(1.0, 0.92, 0.30, 1.0)
const CAMERA_FOCUS_DURATION := 0.35
const FILTER_ALL := 0
const FILTER_BLOCKAGES := 1
const FILTER_SHORTAGES := 2
const FILTER_PRIORITY := 3
const FILTER_COUNT := 4
const PROBLEM_SNOOZE_SECONDS := 60.0

var manager: LogisticsNetworkManager = null
var enabled := false
var _panel: PanelContainer = null
var _label: Label = null
var _refresh_timer := 0.0
var _snapshot: Dictionary = {}
var _selected_problem_index := -1
var _selected_problem_key := ""
var _selected_tile := Vector2i.ZERO
var _has_selected_problem := false
var _selection_phase := 0.0
var _camera: Camera2D = null
var _camera_tween: Tween = null
var _problem_filter := FILTER_ALL
var _snoozed_problem_expiry: Dictionary = {}


func setup(logistics_manager: LogisticsNetworkManager) -> void:
	manager = logistics_manager
	z_index = 92
	_build_hud()
	set_process(true)
	set_process_unhandled_input(true)


func open_from_notification(problem_keys: Array, problem_filter: int) -> void:
	enabled = true
	_panel.show()
	_problem_filter = clampi(problem_filter, FILTER_ALL, FILTER_PRIORITY)
	for key_value: Variant in problem_keys:
		_snoozed_problem_expiry.erase(str(key_value))
	_update_snapshot()
	var problems := _filtered_problems()
	var target_index := -1
	for key_value: Variant in problem_keys:
		for index: int in problems.size():
			if _problem_key(problems[index] as Dictionary) == str(key_value):
				target_index = index
				break
		if target_index >= 0:
			break
	if target_index < 0 and not problems.is_empty():
		target_index = 0
	if target_index >= 0:
		_focus_problem(problems, target_index, true)
	else:
		_clear_problem_focus(true)
	_refresh_label()
	queue_redraw()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 70
	add_child(canvas)
	_panel = PanelContainer.new()
	_panel.name = "LogisticsOverlayInfo"
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -330.0
	_panel.offset_top = 226.0
	_panel.offset_right = 330.0
	_panel.offset_bottom = 394.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.05, 0.075, 0.95)
	style.border_color = Color(0.64, 0.34, 0.92, 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(_panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 12)
	_panel.add_child(_label)
	_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if GameChat.is_blocking_input() or get_tree().paused:
		return
	if event.is_action_pressed("toggle_logistics_overlay"):
		enabled = not enabled
		_panel.visible = enabled
		if enabled:
			QuestManager.report_event("logistics_overlay_opened", "logistics", 1)
			_update_snapshot()
		else:
			_clear_problem_focus(true)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if not enabled:
		return
	if event.is_action_pressed("logistics_next_problem"):
		_select_problem(1)
	elif event.is_action_pressed("logistics_previous_problem"):
		_select_problem(-1)
	elif event.is_action_pressed("logistics_cycle_problem_filter"):
		_cycle_problem_filter()
	elif event.is_action_pressed("logistics_snooze_problem"):
		_snooze_selected_problem()
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not enabled:
		return
	_selection_phase = fmod(_selection_phase + delta * 3.5, TAU)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.25
		_update_snapshot()
	_pin_camera_to_selected()
	queue_redraw()


func _update_snapshot() -> void:
	if manager == null:
		return
	_snapshot = manager.get_network_snapshot()
	_prune_snoozed_problems()
	_reconcile_problem_selection()
	_refresh_label()


func _refresh_label() -> void:
	var shortages := _snapshot.get("shortages", []) as Array
	var top_entries := PackedStringArray()
	for entry_value: Variant in shortages.slice(0, 3):
		if not entry_value is Dictionary:
			continue
		var entry := entry_value as Dictionary
		top_entries.append(tr("%s: %d missing / %d incoming / %d supplied") % [
			_item_name(str(entry.get("item_id", ""))),
			int(entry.get("missing", 0)),
			int(entry.get("in_transit", 0)),
			int(entry.get("supply", 0)),
		])
	var shortage_text := tr("No active shortages.") if top_entries.is_empty() \
		else tr("Top shortages: %s") % "  •  ".join(top_entries)
	var health_text := tr("All requested items have a configured supply.")
	if int(_snapshot.get("blocked_routes", 0)) > 0:
		health_text = tr("Blocked logistics routes need attention.")
	elif int(_snapshot.get("uncovered_types", 0)) > 0:
		health_text = tr("Some requested items have no available provider.")
	var problem_text := tr("No logistics problems to navigate.")
	var problems := _filtered_problems()
	if _has_selected_problem and _selected_problem_index >= 0 \
			and _selected_problem_index < problems.size():
		var problem := problems[_selected_problem_index] as Dictionary
		problem_text = tr("%d/%d • %s • %s • tile %d:%d • [ / ] navigate • [\\] filter") % [
			_selected_problem_index + 1,
			problems.size(),
			_filter_name(),
			_problem_title(problem),
			_selected_tile.x,
			_selected_tile.y,
		]
	elif not problems.is_empty():
		problem_text = tr("%s: %d problems • [ / ] navigate • [\\] filter") % [
			_filter_name(),
			problems.size(),
		]
	else:
		problem_text = tr("%s: no matching problems • [\\] filter") % _filter_name()
	var snooze_text := tr("No hidden problems. • [I] hide selected for 60s")
	if not _snoozed_problem_expiry.is_empty():
		snooze_text = tr("Hidden: %d • next returns in %ds • [I] hide selected") % [
			_snoozed_problem_expiry.size(),
			_nearest_snooze_seconds(),
		]
	_label.text = "%s\n%s\n%s\n%s\n%s\n%s" % [
		tr("LOGISTICS [L]  •  Requesters: %d  •  Providers: %d  •  Demand routes: %d") % [
			int(_snapshot.get("requesters", 0)),
			int(_snapshot.get("providers", 0)),
			(_snapshot.get("routes", []) as Array).size(),
		],
		tr("Missing: %d  •  In transit: %d  •  Supply: %d  •  Blocks: %d  •  Priority waits: %d") % [
			int(_snapshot.get("missing_total", 0)),
			int(_snapshot.get("in_transit_total", 0)),
			int(_snapshot.get("supply_total", 0)),
			int(_snapshot.get("blocked_routes", 0)),
			int(_snapshot.get("priority_waits", 0)),
		],
		shortage_text,
		health_text,
		problem_text,
		snooze_text,
	]


func _draw() -> void:
	if not enabled or _snapshot.is_empty():
		return
	for route_value: Variant in _snapshot.get("routes", []):
		if not route_value is Dictionary:
			continue
		var route := route_value as Dictionary
		var tile := route.get("tile", Vector2i.ZERO) as Vector2i
		var facing := clampi(int(route.get("facing", 2)), 0, 3)
		var start := _tile_center(tile)
		var finish := start + Vector2(WorldBlock.FACING_DIRS[facing]) * GameConstants.TILE_SIZE
		var color := _route_color(route)
		draw_line(start, finish, Color(color.r, color.g, color.b, 0.64), 6.0, true)
		draw_circle(start.lerp(finish, 0.62), 3.5, color)
	for tile_value: Variant in _snapshot.get("provider_tiles", []):
		if tile_value is Vector2i:
			_draw_endpoint(tile_value as Vector2i, PROVIDER_COLOR, false)
	for tile_value: Variant in _snapshot.get("requester_tiles", []):
		if tile_value is Vector2i:
			_draw_endpoint(tile_value as Vector2i, REQUESTER_COLOR, true)
	for tile_value: Variant in _snapshot.get("blocked_tiles", []):
		if not tile_value is Vector2i:
			continue
		var center := _tile_center(tile_value as Vector2i)
		draw_line(center - Vector2(7, 7), center + Vector2(7, 7), ROUTE_BLOCKED, 3.0, true)
		draw_line(center + Vector2(-7, 7), center + Vector2(7, -7), ROUTE_BLOCKED, 3.0, true)
	for problem_value: Variant in _filtered_problems():
		if problem_value is Dictionary:
			_draw_problem_marker(problem_value as Dictionary)
	if _has_selected_problem:
		_draw_selected_problem()


func _draw_endpoint(tile: Vector2i, color: Color, requester: bool) -> void:
	var center := _tile_center(tile)
	draw_circle(center, 9.0, Color(0.02, 0.03, 0.05, 0.92))
	draw_circle(center, 6.0, color)
	if requester:
		draw_arc(center, 11.0, 0.0, TAU, 20, color, 2.0)


func _route_color(route: Dictionary) -> Color:
	if bool(route.get("jammed", false)):
		return ROUTE_BLOCKED
	if int(route.get("in_transit", 0)) > 0:
		return ROUTE_TRANSIT
	if int(route.get("missing", 0)) > 0:
		return ROUTE_MISSING
	return ROUTE_ACTIVE


func _select_problem(step: int) -> void:
	var problems := _filtered_problems()
	if problems.is_empty():
		_clear_problem_focus(false)
		_refresh_label()
		return
	if not _has_selected_problem:
		_selected_problem_index = 0 if step >= 0 else problems.size() - 1
	else:
		_selected_problem_index = wrapi(_selected_problem_index + step, 0, problems.size())
	_focus_problem(problems, _selected_problem_index, true)
	_refresh_label()
	queue_redraw()


func _focus_problem(problems: Array, index: int, report_quest: bool) -> void:
	_selected_problem_index = clampi(index, 0, problems.size() - 1)
	var problem := problems[_selected_problem_index] as Dictionary
	_selected_problem_key = _problem_key(problem)
	_selected_tile = problem.get("tile", Vector2i.ZERO) as Vector2i
	_has_selected_problem = true
	_focus_camera(_selected_tile)
	if report_quest:
		QuestManager.report_event("logistics_problem_focused", "problem", 1)


func _reconcile_problem_selection() -> void:
	if not _has_selected_problem:
		return
	var problems := _filtered_problems()
	for index: int in problems.size():
		var problem := problems[index] as Dictionary
		if _problem_key(problem) != _selected_problem_key:
			continue
		_selected_problem_index = index
		_selected_tile = problem.get("tile", Vector2i.ZERO) as Vector2i
		return
	_clear_problem_focus(true)


func _cycle_problem_filter() -> void:
	_problem_filter = wrapi(_problem_filter + 1, 0, FILTER_COUNT)
	_reconcile_problem_selection()
	_refresh_label()
	queue_redraw()


func _filtered_problems() -> Array:
	var filtered: Array = []
	for problem_value: Variant in _snapshot.get("problems", []):
		if not problem_value is Dictionary:
			continue
		var problem := problem_value as Dictionary
		if _problem_matches_filter(problem) and not _is_problem_snoozed(problem):
			filtered.append(problem)
	return filtered


func _problem_matches_filter(problem: Dictionary) -> bool:
	var kind := str(problem.get("kind", ""))
	match _problem_filter:
		FILTER_BLOCKAGES:
			return kind == "conveyor_jam" or kind == "inserter_blocked"
		FILTER_SHORTAGES:
			return kind == "shortage" or kind == "uncovered_shortage"
		FILTER_PRIORITY:
			return kind == "priority_wait"
	return true


func _filter_name() -> String:
	match _problem_filter:
		FILTER_BLOCKAGES:
			return tr("Blockages")
		FILTER_SHORTAGES:
			return tr("Shortages")
		FILTER_PRIORITY:
			return tr("Priority waits")
	return tr("All problems")


func _snooze_selected_problem() -> void:
	var problems := _filtered_problems()
	if not _has_selected_problem or _selected_problem_index < 0 \
			or _selected_problem_index >= problems.size():
		return
	var previous_index := _selected_problem_index
	_snooze_problem(problems[_selected_problem_index] as Dictionary)
	var remaining := _filtered_problems()
	if remaining.is_empty():
		_clear_problem_focus(true)
	else:
		_focus_problem(remaining, mini(previous_index, remaining.size() - 1), false)
	_refresh_label()
	queue_redraw()


func _snooze_problem(problem: Dictionary) -> void:
	_snoozed_problem_expiry[_problem_key(problem)] = _now_seconds() + PROBLEM_SNOOZE_SECONDS


func _is_problem_snoozed(problem: Dictionary) -> bool:
	return float(_snoozed_problem_expiry.get(_problem_key(problem), 0.0)) > _now_seconds()


func _prune_snoozed_problems() -> void:
	if _snoozed_problem_expiry.is_empty():
		return
	var active_keys := {}
	for problem_value: Variant in _snapshot.get("problems", []):
		if problem_value is Dictionary:
			active_keys[_problem_key(problem_value as Dictionary)] = true
	var now := _now_seconds()
	for key_value: Variant in _snoozed_problem_expiry.keys():
		var key := str(key_value)
		if float(_snoozed_problem_expiry.get(key, 0.0)) <= now or not active_keys.has(key):
			_snoozed_problem_expiry.erase(key)


func _nearest_snooze_seconds() -> int:
	var remaining := int(ceil(PROBLEM_SNOOZE_SECONDS))
	var now := _now_seconds()
	for expiry_value: Variant in _snoozed_problem_expiry.values():
		remaining = mini(remaining, maxi(int(ceil(float(expiry_value) - now)), 0))
	return remaining


func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0


func _problem_key(problem: Dictionary) -> String:
	var tile := problem.get("tile", Vector2i.ZERO) as Vector2i
	return "%s|%d:%d|%s" % [
		str(problem.get("kind", "")),
		tile.x,
		tile.y,
		str(problem.get("item_id", "")),
	]


func _problem_title(problem: Dictionary) -> String:
	match str(problem.get("kind", "")):
		"conveyor_jam":
			return tr("Conveyor jam")
		"inserter_blocked":
			return tr("Inserter destination blocked")
		"uncovered_shortage":
			return tr("No provider for %s") % _item_name(str(problem.get("item_id", "")))
		"shortage":
			return tr("Shortage: %s") % _item_name(str(problem.get("item_id", "")))
		"priority_wait":
			return tr("Waiting for higher priority provider")
	return tr("Logistics problem")


func _focus_camera(tile: Vector2i) -> void:
	_camera = get_viewport().get_camera_2d()
	if _camera == null or not (_camera.get_parent() is Node2D):
		return
	if _camera_tween != null:
		_camera_tween.kill()
	var camera_parent := _camera.get_parent() as Node2D
	var target_position := _tile_center(tile) - camera_parent.global_position
	_camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "position", target_position, CAMERA_FOCUS_DURATION)


func _pin_camera_to_selected() -> void:
	if not _has_selected_problem or _camera == null or not is_instance_valid(_camera) \
			or not (_camera.get_parent() is Node2D):
		return
	if _camera_tween != null and _camera_tween.is_running():
		return
	var camera_parent := _camera.get_parent() as Node2D
	_camera.position = _tile_center(_selected_tile) - camera_parent.global_position


func _clear_problem_focus(reset_camera: bool) -> void:
	_selected_problem_index = -1
	_selected_problem_key = ""
	_has_selected_problem = false
	if not reset_camera or _camera == null or not is_instance_valid(_camera):
		return
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "position", Vector2.ZERO, CAMERA_FOCUS_DURATION)


func _draw_selected_problem() -> void:
	var center := _tile_center(_selected_tile)
	var radius := 13.0 + sin(_selection_phase) * 2.5
	draw_circle(center, radius + 2.0, Color(0.02, 0.03, 0.05, 0.72), false, 4.0, true)
	draw_arc(center, radius, 0.0, TAU, 28, SELECTED_COLOR, 3.0, true)
	draw_circle(center, 3.0, SELECTED_COLOR)


func _draw_problem_marker(problem: Dictionary) -> void:
	var tile := problem.get("tile", Vector2i.ZERO) as Vector2i
	var center := _tile_center(tile)
	var color := ROUTE_MISSING
	match str(problem.get("kind", "")):
		"conveyor_jam", "inserter_blocked":
			color = ROUTE_BLOCKED
		"priority_wait":
			color = SELECTED_COLOR
	draw_arc(center, 13.0, 0.0, TAU, 20, Color(0.02, 0.03, 0.05, 0.82), 5.0, true)
	draw_arc(center, 13.0, 0.0, TAU, 20, color, 2.0, true)


func _item_name(item_id: String) -> String:
	var item := ItemDatabase.registry.get(item_id) as ItemData
	return tr(item.name) if item != null else item_id


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * GameConstants.TILE_SIZE) + Vector2.ONE * (GameConstants.TILE_SIZE * 0.5)

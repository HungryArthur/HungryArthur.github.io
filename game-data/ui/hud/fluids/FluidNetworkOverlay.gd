extends Node2D
class_name FluidNetworkOverlay

const HEALTHY := Color(0.20, 0.90, 0.95, 0.90)
const LOADED := Color(1.0, 0.72, 0.18, 0.94)
const STARVED := Color(1.0, 0.20, 0.14, 0.96)
const OFFLINE := Color(0.42, 0.46, 0.55, 0.76)

var manager: FluidNetworkManager
var enabled := false
var _panel: PanelContainer
var _label: Label
var _refresh_timer := 0.0
var _flow_phase := 0.0


func setup(fluid_manager: FluidNetworkManager) -> void:
	manager = fluid_manager
	z_index = 91
	_build_hud()
	set_process(true)
	set_process_unhandled_input(true)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 70
	add_child(canvas)
	_panel = PanelContainer.new()
	_panel.name = "FluidOverlayInfo"
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -300.0
	_panel.offset_top = 106.0
	_panel.offset_right = 300.0
	_panel.offset_bottom = 214.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.075, 0.94)
	style.border_color = Color(0.20, 0.84, 0.94, 0.92)
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
	if not event.is_action_pressed("toggle_fluid_overlay"):
		return
	if GameChat.is_blocking_input() or get_tree().paused:
		return
	enabled = not enabled
	_panel.visible = enabled
	if enabled:
		QuestManager.report_event("fluid_overlay_opened", "steam", 1)
		_update_summary()
	queue_redraw()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not enabled:
		return
	_flow_phase = fmod(_flow_phase + delta * 0.75, 1.0)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.2
		_update_summary()
	queue_redraw()


func _update_summary() -> void:
	if manager == null:
		return
	var networks := manager.get_network_snapshot()
	if networks.is_empty():
		_label.text = "%s\n%s" % [
			tr("STEAM NETWORK [K]"),
			tr("No fluid pipe networks detected."),
		]
		return
	var boilers := 0
	var consumers := 0
	var installed_capacity := 0.0
	var online_capacity := 0.0
	var connected_demand := 0.0
	var active_demand := 0.0
	var flow := 0.0
	var buffer := 0.0
	var starved := 0
	var peak_utilization := 0.0
	var loaded_pipe_rate := FluidNetworkManager.TRANSFER_RATE
	var starved_names := PackedStringArray()
	for network: Dictionary in networks:
		boilers += int(network.get("boilers", 0))
		consumers += int(network.get("consumers", 0))
		installed_capacity += float(network.get("installed_capacity", 0.0))
		online_capacity += float(network.get("online_capacity", 0.0))
		connected_demand += float(network.get("connected_demand", 0.0))
		active_demand += float(network.get("active_demand", 0.0))
		flow += float(network.get("steam_flow", 0.0))
		buffer += float(network.get("steam_buffer", 0.0))
		starved += int(network.get("starved_count", 0))
		var utilization := float(network.get("utilization", 0.0))
		if utilization >= peak_utilization:
			peak_utilization = utilization
			loaded_pipe_rate = float(network.get("transfer_rate", FluidNetworkManager.TRANSFER_RATE))
		for entry_value: Variant in network.get("starved", []):
			if not entry_value is Dictionary:
				continue
			var machine_name := tr(str((entry_value as Dictionary).get("name", "Steam Machine")))
			if not starved_names.has(machine_name):
				starved_names.append(machine_name)
	var status_text := tr("All connected steam machines are supplied.")
	if starved > 0:
		status_text = tr("Without steam: %d — %s") % [starved, ", ".join(starved_names.slice(0, 3))]
	elif connected_demand > installed_capacity + 0.01:
		status_text = tr("Installed boilers cannot cover connected demand.")
	_label.text = "%s\n%s\n%s\n%s" % [
		tr("STEAM NETWORK [K]  •  Networks: %d  •  Boilers: %d  •  Machines: %d") % [networks.size(), boilers, consumers],
		tr("Capacity: %.1f/%.1f L/s  •  Demand: %.1f active / %.1f connected") % [online_capacity, installed_capacity, active_demand, connected_demand],
		tr("Steam flow: %.1f L/s  •  Pipe limit: %.1f L/s  •  Load: %.0f%%  •  Buffer: %.1f L") % [flow, loaded_pipe_rate, peak_utilization * 100.0, buffer],
		status_text,
	]


func _draw() -> void:
	if not enabled or manager == null:
		return
	for network: Dictionary in manager.get_network_snapshot():
		var tiles: Array = network.get("tiles", [])
		var tile_set: Dictionary = {}
		for tile_value: Variant in tiles:
			if tile_value is Vector2i:
				tile_set[tile_value] = true
		var color := _network_color(network)
		var flow_strength := clampf(
			float(network.get("total_flow", 0.0)) / maxf(float(network.get("transfer_rate", 1.0)), 0.0001),
			0.0,
			1.0
		)
		for tile_value: Variant in tiles:
			if not tile_value is Vector2i:
				continue
			var tile := tile_value as Vector2i
			var start := _tile_center(tile)
			for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				if tile_set.has(tile + direction):
					var finish := _tile_center(tile + direction)
					draw_line(start, finish, Color(color.r, color.g, color.b, 0.50), 7.0, true)
					if flow_strength > 0.01:
						var offset := float(absi(tile.x * 17 + tile.y * 31) % 100) / 100.0
						var phase := fmod(_flow_phase + offset, 1.0)
						draw_circle(start.lerp(finish, phase), 2.0 + flow_strength * 2.0, color.lightened(0.35))
			draw_circle(start, 5.5, color)
			draw_arc(start, 8.5, 0.0, TAU, 14, Color(0.02, 0.03, 0.05, 0.9), 2.0)


func _network_color(network: Dictionary) -> Color:
	if bool(network.get("offline", false)):
		return OFFLINE
	if int(network.get("starved_count", 0)) > 0 or float(network.get("active_deficit", 0.0)) > 0.01:
		return STARVED
	if float(network.get("connected_deficit", 0.0)) > 0.01 or float(network.get("utilization", 0.0)) >= 0.80:
		return LOADED
	return HEALTHY


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * GameConstants.TILE_SIZE) + Vector2.ONE * (GameConstants.TILE_SIZE * 0.5)

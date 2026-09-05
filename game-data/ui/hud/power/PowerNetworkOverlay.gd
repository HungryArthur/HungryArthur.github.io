extends Node2D
class_name PowerNetworkOverlay

const HEALTHY := Color(0.22, 1.0, 0.55, 0.88)
const LOADED := Color(1.0, 0.76, 0.18, 0.92)
const OVERLOADED := Color(1.0, 0.18, 0.12, 0.95)
const OFFLINE := Color(0.42, 0.46, 0.55, 0.74)

var manager: PowerNetworkManager
var enabled := false
var _label: Label
var _refresh_timer := 0.0


func setup(power_manager: PowerNetworkManager) -> void:
	manager = power_manager
	z_index = 90
	_build_hud()
	set_process(true)
	set_process_unhandled_input(true)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 70
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.name = "PowerOverlayInfo"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -280.0
	panel.offset_top = 18.0
	panel.offset_right = 280.0
	panel.offset_bottom = 98.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.92)
	style.border_color = Color(0.24, 0.72, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(_label)
	panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_power_overlay"):
		return
	if GameChat.is_blocking_input() or get_tree().paused:
		return
	enabled = not enabled
	_label.get_parent().visible = enabled
	if enabled:
		QuestManager.report_event("power_overlay_opened", "power", 1)
	queue_redraw()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not enabled:
		return
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = 0.2
	_update_summary()
	queue_redraw()


func _update_summary() -> void:
	if manager == null:
		return
	var generation := 0.0
	var demand := 0.0
	var deficit := 0.0
	var finite_capacity := 0.0
	var networks := manager.get_network_snapshot()
	for network: Dictionary in networks:
		generation += float(network.get("generation", 0.0))
		demand += float(network.get("demand", 0.0))
		deficit += float(network.get("deficit", 0.0))
		finite_capacity += maxf(float(network.get("capacity_eu_s", -1.0)), 0.0)
	var profile := FactoryProfiler.snapshot(get_tree())
	_label.text = "%s\n%s\n%s" % [
		tr("POWER GRID [G]  •  Networks: %d  •  Generation: %.0f EU  •  Demand: %.0f EU  •  Deficit: %.0f EU  •  Cable limit: %.0f EU/s") % [networks.size(), generation, demand, deficit, finite_capacity],
		tr("GREEN stable  •  YELLOW loaded  •  RED deficit  •  GRAY offline"),
		tr("Factory: %d machines  •  %d active  •  %d sleeping  •  %d jams  •  %.2f ms/tick") % [profile["total"], profile["active"], profile["sleeping"], profile["jammed"], profile["tick_ms"]],
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
		for tile_value: Variant in tiles:
			if not tile_value is Vector2i:
				continue
			var tile := tile_value as Vector2i
			var start := _tile_center(tile)
			for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				if tile_set.has(tile + direction):
					draw_line(start, _tile_center(tile + direction), Color(color.r, color.g, color.b, 0.52), 7.0, true)
			draw_circle(start, 5.5, color)
			draw_arc(start, 8.5, 0.0, TAU, 14, Color(0.02, 0.03, 0.05, 0.9), 2.0)


func _network_color(network: Dictionary) -> Color:
	var demand := float(network.get("demand", 0.0))
	var generation := float(network.get("generation", 0.0))
	var deficit := float(network.get("deficit", 0.0))
	if bool(network.get("offline", false)):
		return OFFLINE
	if deficit > 0.01:
		return OVERLOADED
	if demand > 0.0 and generation / demand < 1.15:
		return LOADED
	return HEALTHY


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * GameConstants.TILE_SIZE) + Vector2.ONE * (GameConstants.TILE_SIZE * 0.5)

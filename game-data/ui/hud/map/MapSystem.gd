# res://ui/hud/map/MapSystem.gd
extends Control

@onready var sub_viewport: SubViewport = $MapSubViewport
@onready var map_camera: Camera2D = $MapSubViewport/MapCamera
@onready var circular_map_container: TextureRect = $MarginContainer/CircularMapContainer
@onready var coordinates_label: Label = $CoordsContainer/CoordinatesLabel
@onready var coords_container: PanelContainer = $CoordsContainer
@onready var directions: Control = $OverlayUI/Directions
@onready var overlay_ui: Control = $OverlayUI
@onready var player_marker: ColorRect = $OverlayUI/PlayerMarker

@onready var map_terrain_layer: TileMapLayer = $MapSubViewport/TerrainTileMapLayer
@onready var map_objects_layer: TileMapLayer = $MapSubViewport/ObjectsTileMapLayer

const MAP_SHADER = preload("res://assets/shaders/circular_mask.gdshader")
const COORDS_BADGE_WIDTH := 96.0
const COORDS_BADGE_HEIGHT := 26.0

var player: Node2D
var shader_material: ShaderMaterial
var is_fullscreen := false
var min_offsets := {}
var zoom_factor := 1.0

# LMB drag panning on the fullscreen map. A press starts a potential drag;
# if the mouse barely moved by release, it counts as a click (obelisk travel).
var _pan_offset := Vector2.ZERO
var _dragging := false
var _drag_screen_travel := 0.0
const DRAG_CLICK_THRESHOLD := 8.0

var _world_data: WorldData
var _info_panel: PanelContainer
var _time_label: Label
var _biome_label: Label
var _world_ref: Node

const BIOME_DISPLAY := {
	"OceanBiome": "Океан",
	"BeachBiome": "Пляж",
	"DesertBiome": "Пустыня",
	"ForestBiome": "Лес",
	"JungleBiome": "Джунгли",
	"SnowBiome": "Снега",
	"SwampBiome": "Болото",
	"SunnyCanyonBiome": "Солнечный Каньон",
	"IcyAbyssBiome": "Ледяная Бездна",
	"RottingBogBiome": "Гниющие Топи",
	"PrimevalThicketBiome": "Первобытные Дебри",
}
var _placed_block_nodes: Dictionary = {}
# Ore-vein cores / fluid centres drawn as square markers. "x,y" -> [atlas_x, source_id]
var _resource_markers: Dictionary = {}
var _resource_marker_nodes: Dictionary = {}
var _placed_blocks_root: Node2D
var _resource_markers_root: Node2D
var _obelisk_markers_root: Node2D
var _boss_markers_root: Node2D
var _ping_markers_root: Node2D
var _boss_marker_nodes: Array[Node2D] = []
var _legend_panel: PanelContainer
var _legend_label: Label

# Сколько секунд пинг «смотри сюда» живёт на карте.
const PING_LIFETIME := 15.0
const PING_COLOR := Color(1.0, 0.85, 0.25)
const PING_SIZE := 60.0

# Fast-travel obelisks drawn on the map (replaces the old manual markers).
var _obelisks_list: Array = []
var _obelisk_discovered: Dictionary = {}
var _obelisk_marker_nodes: Array = []
# Click within this many world-pixels of a discovered obelisk on the fullscreen
# map to teleport there. Obelisks are thousands of px apart, so this is unambiguous.
const OBELISK_CLICK_RANGE := 600.0

# Square-marker colours for ore atlas indices and fluid centres.
const ORE_MAP_COLORS: Dictionary = {
	0: Color(0.62, 0.64, 0.78),  # iron
	1: Color(0.92, 0.52, 0.18),  # copper
	2: Color(0.18, 0.18, 0.18),  # coal
	3: Color(1.00, 0.84, 0.08),  # gold
	4: Color(0.30, 0.85, 0.98),  # mythril
	5: Color(0.68, 0.82, 0.76),  # tin
	6: Color(0.85, 0.85, 0.92),  # silver
	7: Color(0.45, 0.95, 0.45),  # uranium
	8: Color(0.55, 0.80, 0.92),  # titanium
	10: Color(0.45, 0.48, 0.55),  # lead
	11: Color(0.78, 0.80, 0.70),  # nickel
	12: Color(0.82, 0.90, 0.95),  # platinum
	13: Color(0.63, 0.38, 0.95),  # resonite
}
const CRUDE_OIL_COLOR := Color(0.10, 0.10, 0.13)
const LAVA_COLOR := Color(1.00, 0.42, 0.12)
# World-space size of a resource square marker (a bit larger than a tile so it
# stays visible when the map is zoomed out).
const RESOURCE_MARKER_SIZE := 44.0


func _ready() -> void:
	add_to_group("map_ui")
	min_offsets = {
		"left": offset_left,
		"top": offset_top,
		"right": offset_right,
		"bottom": offset_bottom
	}

	var map_texture := sub_viewport.get_texture()
	circular_map_container.texture = map_texture

	shader_material = ShaderMaterial.new()
	shader_material.shader = MAP_SHADER
	shader_material.set_shader_parameter("map_texture", map_texture)
	shader_material.set_shader_parameter("roughness", 0.005)
	circular_map_container.material = shader_material

	_setup_ui_styles()
	_setup_map_roots()
	_setup_info_panel()
	_setup_legend()
	_apply_camera_zoom()


func _setup_info_panel() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.name = "InfoPanel"
	_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_info_panel.anchor_left = 0.5
	_info_panel.anchor_right = 0.5
	_info_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_info_panel.offset_top = 46.0
	_info_panel.offset_bottom = 92.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.08, 0.85)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = Color("3a3a3a")
	_info_panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 1)
	_info_panel.add_child(vb)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 15)
	_time_label.text = "🕓 08:00"
	vb.add_child(_time_label)

	_biome_label = Label.new()
	_biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_biome_label.add_theme_font_size_override("font_size", 12)
	_biome_label.add_theme_color_override("font_color", Color(0.78, 0.80, 0.84))
	_biome_label.text = "—"
	vb.add_child(_biome_label)

	add_child(_info_panel)


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		map_camera.global_position = player.global_position + _pan_offset
		_update_player_marker()
		if shader_material and not is_fullscreen:
			shader_material.set_shader_parameter("map_texture", sub_viewport.get_texture())

		var tile_x := floori(player.global_position.x / float(GameConstants.TILE_SIZE))
		var tile_y := floori(player.global_position.y / float(GameConstants.TILE_SIZE))
		coordinates_label.text = "x: %d  y: %d" % [int(tile_x), int(tile_y)]
		_update_info_panel()


## Keeps the white dot on the player's world position: when the map is panned
## the dot drifts away from the view centre instead of sticking to it.
func _update_player_marker() -> void:
	var vp_size := Vector2(sub_viewport.size)
	# Camera is centred on player + pan, so the player sits pan*zoom from centre.
	var viewport_point := vp_size * 0.5 - _pan_offset * map_camera.zoom.x
	var uv := Vector2(
		viewport_point.x / maxf(vp_size.x, 1.0),
		viewport_point.y / maxf(vp_size.y, 1.0)
	)
	var on_map := uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0
	player_marker.visible = on_map
	if on_map:
		var rect := circular_map_container.get_global_rect()
		player_marker.global_position = rect.position + uv * rect.size - player_marker.size * 0.5


func _update_info_panel() -> void:
	var time_manager := get_node_or_null("/root/TimeManager")
	if _time_label != null and time_manager != null:
		_time_label.text = "🕓 " + str(time_manager.get_time_string())
	if _biome_label == null:
		return
	if _world_ref == null or not is_instance_valid(_world_ref):
		_world_ref = get_tree().get_first_node_in_group("world")
	if (
		_world_ref != null
		and _world_ref.has_method("get_biome_name_at")
		and is_instance_valid(player)
	):
		var raw := str(_world_ref.get_biome_name_at(player.global_position))
		_biome_label.text = str(BIOME_DISPLAY.get(raw, raw))
		_discover_biome(raw)


func load_saved_map(world_data: WorldData) -> void:
	if not world_data:
		return
	if not is_node_ready():
		await ready
	_world_data = world_data as WorldData

	map_terrain_layer.clear()
	map_objects_layer.clear()
	_clear_player_block_nodes()
	_clear_resource_marker_nodes()
	_resource_markers = world_data.saved_map_resources.duplicate(true)

	for key_str: String in world_data.saved_map_terrain:
		var pos := _parse_vector2i(key_str)
		var terrain_value: Variant = world_data.saved_map_terrain[key_str]
		if terrain_value is Array and terrain_value.size() >= 3:
			map_terrain_layer.set_cell(
				pos,
				int(terrain_value[0]),
				Vector2i(int(terrain_value[1]), int(terrain_value[2]))
			)
		else:
			map_terrain_layer.set_cell(pos, int(terrain_value), Vector2i.ZERO)

	for key_str: String in world_data.saved_map_objects:
		var pos := _parse_vector2i(key_str)
		var data: Variant = world_data.saved_map_objects[key_str]
		if data is Array and data.size() >= 3:
			_set_map_object(pos, int(data[0]), int(data[1]), int(data[2]))

	_rebuild_resource_marker_nodes()

	# Manual map markers were replaced by the obelisk fast-travel network.
	_rebuild_obelisk_markers()
	_rebuild_boss_markers()
	_refresh_legend()


func save_current_map(world_data: WorldData) -> void:
	if not world_data:
		return

	world_data.saved_map_terrain.clear()
	world_data.saved_map_objects.clear()

	for pos in map_terrain_layer.get_used_cells():
		var key_str := "%d,%d" % [pos.x, pos.y]
		var source_id: int = map_terrain_layer.get_cell_source_id(pos)
		var atlas: Vector2i = map_terrain_layer.get_cell_atlas_coords(pos)
		world_data.saved_map_terrain[key_str] = [source_id, atlas.x, atlas.y]

	for pos in map_objects_layer.get_used_cells():
		var atlas := map_objects_layer.get_cell_atlas_coords(pos)
		var source_id := map_objects_layer.get_cell_source_id(pos)
		world_data.saved_map_objects["%d,%d" % [pos.x, pos.y]] = [atlas.x, atlas.y, source_id]

	# Manual markers were retired in favour of obelisks; clear any legacy data.
	world_data.saved_map_markers = {}
	world_data.saved_map_resources = _resource_markers.duplicate(true)


func register_chunk_on_map(chunk: Chunk) -> void:
	if not is_instance_valid(map_terrain_layer):
		return

	for local_pos: Vector2i in chunk.terrain_data:
		var terrain_value: Variant = chunk.terrain_data[local_pos]
		var source_id: int
		var atlas: Vector2i
		if terrain_value is Vector3i:
			source_id = terrain_value.z
			atlas = Vector2i(terrain_value.x, terrain_value.y)
		else:
			source_id = int(terrain_value)
			atlas = Vector2i(0, 0)
		var global_tile_pos := (chunk.position * GameConstants.CHUNK_SIZE) + local_pos
		map_terrain_layer.set_cell(global_tile_pos, source_id, atlas)

	for local_pos: Vector2i in chunk.object_data:
		var data: Vector3i = chunk.object_data[local_pos]
		var global_tile_pos := (chunk.position * GameConstants.CHUNK_SIZE) + local_pos
		# Fluid pools store their centre flag in metadata, not the atlas column.
		var fluid_meta: Dictionary = chunk.fluid_deposit_data.get(local_pos, {}) as Dictionary
		var is_center: bool = bool(fluid_meta.get("is_center", false))
		_set_map_object(global_tile_pos, data.x, data.y, data.z, is_center)


func remove_object_at(global_tile_pos: Vector2i) -> void:
	map_objects_layer.erase_cell(global_tile_pos)


func _set_map_object(tile_pos: Vector2i, atlas_x: int, atlas_y: int, source_id: int, is_center: bool = false) -> void:
	if source_id == GameConstants.OBJECT_TREE:
		map_objects_layer.set_cell(tile_pos, source_id, Vector2i(atlas_x, atlas_y))
	elif source_id == GameConstants.OBJECT_ORE and atlas_y == 2:
		# One square marker per vein, placed on the vein core.
		_add_resource_marker(tile_pos, atlas_x, source_id)
	elif _is_fluid_source(source_id) and is_center:
		# One square marker per fluid pool, placed on its centre.
		_add_resource_marker(tile_pos, atlas_x, source_id)


## Records and draws a square marker for an ore core / fluid centre.
func _add_resource_marker(tile_pos: Vector2i, atlas_x: int, source_id: int) -> void:
	var key := "%d,%d" % [tile_pos.x, tile_pos.y]
	if _resource_markers.has(key) and _resource_marker_nodes.has(key):
		return
	_resource_markers[key] = [atlas_x, source_id]
	_spawn_resource_marker_node(tile_pos, atlas_x, source_id)


func _spawn_resource_marker_node(tile_pos: Vector2i, atlas_x: int, source_id: int) -> void:
	if _resource_markers_root == null:
		return
	var key := "%d,%d" % [tile_pos.x, tile_pos.y]
	if _resource_marker_nodes.has(key):
		return
	var color := _resource_marker_color(atlas_x, source_id)
	var half := RESOURCE_MARKER_SIZE * 0.5
	var square := Polygon2D.new()
	square.polygon = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	square.color = color
	square.position = Vector2(tile_pos * GameConstants.TILE_SIZE) + Vector2(
		GameConstants.TILE_SIZE * 0.5, GameConstants.TILE_SIZE * 0.5
	)
	square.z_index = 4
	# Thin dark outline so light ores stay readable over any terrain.
	var border := Polygon2D.new()
	border.polygon = PackedVector2Array([
		Vector2(-half - 3, -half - 3), Vector2(half + 3, -half - 3),
		Vector2(half + 3, half + 3), Vector2(-half - 3, half + 3),
	])
	border.color = Color(0, 0, 0, 0.65)
	border.z_index = 3
	border.position = square.position
	_resource_markers_root.add_child(border)
	_resource_markers_root.add_child(square)
	_resource_marker_nodes[key] = [border, square]


## Oil and lava are separate tileset sources now; colour by source id.
func _is_fluid_source(source_id: int) -> bool:
	return source_id == GameConstants.OBJECT_OIL or source_id == GameConstants.OBJECT_LAVA


func _resource_marker_color(atlas_x: int, source_id: int) -> Color:
	if source_id == GameConstants.OBJECT_LAVA:
		return LAVA_COLOR
	if source_id == GameConstants.OBJECT_OIL:
		return CRUDE_OIL_COLOR
	return ORE_MAP_COLORS.get(atlas_x, Color(0.7, 0.7, 0.7))


func _rebuild_resource_marker_nodes() -> void:
	_clear_resource_marker_nodes()
	for key_value: Variant in _resource_markers.keys():
		var data: Variant = _resource_markers[key_value]
		if not (data is Array) or (data as Array).size() < 2:
			continue
		var tile_pos := _parse_vector2i(str(key_value))
		_spawn_resource_marker_node(tile_pos, int(data[0]), int(data[1]))


func _clear_resource_marker_nodes() -> void:
	for nodes_value: Variant in _resource_marker_nodes.values():
		if nodes_value is Array:
			for node: Variant in nodes_value:
				if node is Node and is_instance_valid(node):
					(node as Node).queue_free()
	_resource_marker_nodes.clear()


## Called by ObeliskManager with the full obelisk list + discovered set so the
## map can draw fast-travel nodes (discovered = bright, undiscovered = faint).
func set_obelisks(list: Array, discovered: Dictionary) -> void:
	_obelisks_list = list
	_obelisk_discovered = discovered.duplicate()
	if is_node_ready():
		_rebuild_obelisk_markers()


func _discover_biome(biome_name: String) -> void:
	if (
		_world_data == null
		or biome_name.is_empty()
		or _world_data.discovered_biomes.has(biome_name)
		or not BiomeProgression.is_biome_unlocked(biome_name)
	):
		return
	_world_data.discovered_biomes[biome_name] = true
	ProgressionTelemetry.record_event("biome_discovered", biome_name, 1)
	_rebuild_boss_markers()
	_refresh_legend()


func _rebuild_boss_markers() -> void:
	for marker: Node2D in _boss_marker_nodes:
		if is_instance_valid(marker):
			marker.queue_free()
	_boss_marker_nodes.clear()
	if _boss_markers_root == null or _world_data == null:
		return
	var defeated: Array = []
	if SaveManager.current_save != null:
		defeated = SaveManager.current_save.defeated_bosses
	for data: Dictionary in BossRegistry.get_all():
		if not _world_data.discovered_biomes.has(str(data.get("biome", ""))):
			continue
		var marker := Node2D.new()
		marker.position = BossRegistry.world_pos(data.get("tile", Vector2i.ZERO))
		marker.z_index = 7
		var is_defeated := str(data.get("id", "")) in defeated
		var color := Color(0.48, 0.52, 0.58, 0.86) if is_defeated else Color(1.0, 0.18, 0.13, 0.95)
		var radius := 54.0
		var diamond := Polygon2D.new()
		diamond.polygon = PackedVector2Array([
			Vector2(0, -radius), Vector2(radius, 0),
			Vector2(0, radius), Vector2(-radius, 0),
		])
		diamond.color = Color(color.r, color.g, color.b, 0.34)
		marker.add_child(diamond)
		var icon := Label.new()
		icon.text = "✓" if is_defeated else "☠"
		icon.position = Vector2(-32, -42)
		icon.size = Vector2(64, 64)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 50)
		icon.add_theme_color_override("font_color", color)
		icon.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		icon.add_theme_constant_override("outline_size", 7)
		marker.add_child(icon)
		_boss_markers_root.add_child(marker)
		_boss_marker_nodes.append(marker)


func refresh_boss_markers() -> void:
	_rebuild_boss_markers()
	_refresh_legend()


func _setup_legend() -> void:
	_legend_panel = PanelContainer.new()
	_legend_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_legend_panel.offset_left = 18.0
	_legend_panel.offset_top = 18.0
	_legend_panel.offset_right = 310.0
	_legend_panel.offset_bottom = 142.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	style.border_color = Color(0.28, 0.48, 0.68, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_legend_panel.add_theme_stylebox_override("panel", style)
	_legend_label = Label.new()
	_legend_label.add_theme_font_size_override("font_size", 12)
	_legend_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	_legend_panel.add_child(_legend_label)
	add_child(_legend_panel)
	_legend_panel.hide()
	_refresh_legend()


func _refresh_legend() -> void:
	if _legend_label == null:
		return
	var discovered_count := 0
	if _world_data != null:
		discovered_count = _world_data.discovered_biomes.size()
	_legend_label.text = tr("WORLD MAP") + "\n" \
		+ tr("Biomes discovered: %d/%d") % [discovered_count, BIOME_DISPLAY.size()] + "\n" \
		+ tr("■ Resources   ◆ Buildings   ◇ Obelisks") + "\n" \
		+ tr("☠ Boss alive   ✓ Boss defeated")


func _rebuild_obelisk_markers() -> void:
	for node: Variant in _obelisk_marker_nodes:
		if node is Node and is_instance_valid(node):
			(node as Node).queue_free()
	_obelisk_marker_nodes.clear()
	if _obelisk_markers_root == null:
		return
	for data: Dictionary in _obelisks_list:
		var is_discovered: bool = _obelisk_discovered.has(str(data["id"]))
		_obelisk_markers_root.add_child(_make_obelisk_marker(data, is_discovered))


func _make_obelisk_marker(data: Dictionary, is_discovered: bool) -> Node2D:
	var tile: Vector2i = data["tile"]
	var node := Node2D.new()
	node.position = Vector2(tile * GameConstants.TILE_SIZE) + Vector2(
		GameConstants.TILE_SIZE * 0.5, GameConstants.TILE_SIZE * 0.5
	)
	node.z_index = 6
	var color: Color = data["color"] if is_discovered else Color(0.5, 0.5, 0.55)
	var marker_size := 70.0 if is_discovered else 40.0

	# Dark diamond outline for contrast over any terrain.
	var border := Polygon2D.new()
	border.polygon = PackedVector2Array([
		Vector2(0, -marker_size - 6), Vector2(marker_size + 6, 0),
		Vector2(0, marker_size + 6), Vector2(-marker_size - 6, 0),
	])
	border.color = Color(0, 0, 0, 0.7)
	node.add_child(border)

	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -marker_size), Vector2(marker_size, 0),
		Vector2(0, marker_size), Vector2(-marker_size, 0),
	])
	diamond.color = color if is_discovered else Color(color.r, color.g, color.b, 0.45)
	node.add_child(diamond)

	if is_discovered:
		var label := Label.new()
		label.text = ObeliskRegistry.display_name(str(data["name"]))
		label.position = Vector2(marker_size + 14, -34)
		label.add_theme_font_size_override("font_size", 52)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", 8)
		node.add_child(label)

	_obelisk_marker_nodes.append(node)
	return node


## On the fullscreen map, clicking near a discovered obelisk teleports there.
func _try_obelisk_teleport(world_pos: Vector2) -> bool:
	var best_id := ""
	var best_dist := OBELISK_CLICK_RANGE
	for data: Dictionary in _obelisks_list:
		var id := str(data["id"])
		if not _obelisk_discovered.has(id):
			continue
		var tile: Vector2i = data["tile"]
		var wp := Vector2(tile * GameConstants.TILE_SIZE) + Vector2(
			GameConstants.TILE_SIZE * 0.5, GameConstants.TILE_SIZE * 0.5
		)
		var dist := wp.distance_to(world_pos)
		if dist < best_dist:
			best_dist = dist
			best_id = id
	if best_id.is_empty():
		return false
	var mgr: Node = get_tree().get_first_node_in_group("obelisk_manager")
	if mgr != null and mgr.has_method("teleport_to"):
		mgr.teleport_to(best_id)
		_toggle_map_mode()  # close the map after travelling
		return true
	return false


## Пинг «смотри сюда» (Alt+ЛКМ): жёлтый ромб с именем игрока, исчезает сам.
func add_ping(world_pos: Vector2, display_name: String) -> void:
	if _ping_markers_root == null:
		return
	var node := Node2D.new()
	node.position = world_pos
	node.z_index = 8

	var border := Polygon2D.new()
	border.polygon = PackedVector2Array([
		Vector2(0, -PING_SIZE - 6), Vector2(PING_SIZE + 6, 0),
		Vector2(0, PING_SIZE + 6), Vector2(-PING_SIZE - 6, 0),
	])
	border.color = Color(0, 0, 0, 0.7)
	node.add_child(border)

	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -PING_SIZE), Vector2(PING_SIZE, 0),
		Vector2(0, PING_SIZE), Vector2(-PING_SIZE, 0),
	])
	diamond.color = PING_COLOR
	node.add_child(diamond)

	if not display_name.is_empty():
		var label := Label.new()
		label.text = display_name
		label.position = Vector2(PING_SIZE + 14, -34)
		label.add_theme_font_size_override("font_size", 52)
		label.add_theme_color_override("font_color", PING_COLOR)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", 8)
		node.add_child(label)

	_ping_markers_root.add_child(node)
	# Пульс + автоудаление. Твин привязан к ноде и умрёт вместе с ней.
	var tween := node.create_tween()
	tween.set_loops(int(PING_LIFETIME / 0.8))
	tween.tween_property(diamond, "scale", Vector2(1.25, 1.25), 0.4)
	tween.tween_property(diamond, "scale", Vector2.ONE, 0.4)
	node.get_tree().create_timer(PING_LIFETIME).timeout.connect(
		func() -> void:
			if is_instance_valid(node):
				node.queue_free()
	)


func set_player_block(tile_pos: Vector2i, block_id: String) -> void:
	remove_player_block(tile_pos)
	if _placed_blocks_root == null:
		return
	var data: BlockData = BlockDatabase.get_block(block_id)
	if data == null:
		return
	var sprite := Sprite2D.new()
	sprite.position = Vector2(tile_pos * GameConstants.TILE_SIZE) + Vector2(
		GameConstants.TILE_SIZE * 0.5,
		GameConstants.TILE_SIZE * 0.5
	)
	sprite.z_index = 3
	if data.texture:
		sprite.texture = data.texture
	else:
		var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(data.color)
		sprite.texture = ImageTexture.create_from_image(image)
		sprite.scale = Vector2(4, 4)
	_placed_blocks_root.add_child(sprite)
	_placed_block_nodes[tile_pos] = sprite


func remove_player_block(tile_pos: Vector2i) -> void:
	var node: Node = _placed_block_nodes.get(tile_pos)
	if node != null and is_instance_valid(node):
		node.queue_free()
	_placed_block_nodes.erase(tile_pos)


func _parse_vector2i(string_val: String) -> Vector2i:
	if string_val.begins_with("(") and string_val.ends_with(")"):
		string_val = string_val.substr(1, string_val.length() - 2)
	var parts := string_val.split(",")
	if parts.size() == 2:
		return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))
	return Vector2i.ZERO


func _input(event: InputEvent) -> void:
	if _is_text_input_focused():
		return

	if event.is_action_pressed("toggle_map"):
		_toggle_map_mode()
		get_tree().root.set_input_as_handled()
		return

	if is_fullscreen and event.is_action_pressed("ui_cancel"):
		_toggle_map_mode()
		get_tree().root.set_input_as_handled()
		return

	if (
		is_fullscreen
		and event is InputEventMouseButton
		and event.pressed
		and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
		and circular_map_container.get_global_rect().has_point(event.position)
	):
		_zoom_at_screen_point(event.position, event.button_index == MOUSE_BUTTON_WHEEL_UP)
		get_viewport().set_input_as_handled()
		return

	if is_fullscreen and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if (
			event.pressed
			and circular_map_container.get_global_rect().has_point(event.position)
		):
			# Alt+ЛКМ по карте — пинг «смотри сюда» в кликнутой точке мира.
			if event.alt_pressed:
				MultiplayerManager.send_map_ping(_map_mouse_to_world(event.position))
				get_viewport().set_input_as_handled()
				return
			_dragging = true
			_drag_screen_travel = 0.0
		elif not event.pressed and _dragging:
			_dragging = false
			# Barely moved between press and release — treat as a click:
			# left click a discovered obelisk on the map to fast-travel to it.
			if _drag_screen_travel <= DRAG_CLICK_THRESHOLD:
				if _try_obelisk_teleport(_map_mouse_to_world(event.position)):
					get_viewport().set_input_as_handled()
					return

	if is_fullscreen and event is InputEventMouseMotion and _dragging:
		_drag_screen_travel += event.relative.length()
		var rect := circular_map_container.get_global_rect()
		var screen_to_viewport := Vector2(sub_viewport.size) / Vector2(
			maxf(rect.size.x, 1.0), maxf(rect.size.y, 1.0)
		)
		# Map moves with the cursor, so the camera shifts the opposite way.
		_pan_offset -= event.relative * screen_to_viewport / map_camera.zoom
		return

	if event is InputEventKey and event.pressed and not event.is_echo() and event.ctrl_pressed:
		if event.keycode in [KEY_EQUAL, KEY_KP_ADD]:
			_zoom_in()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_zoom_out()
			get_viewport().set_input_as_handled()


func _is_text_input_focused() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit


func _toggle_map_mode() -> void:
	is_fullscreen = !is_fullscreen
	_pan_offset = Vector2.ZERO
	_dragging = false
	if _info_panel != null:
		_info_panel.visible = not is_fullscreen
	if _legend_panel != null:
		_legend_panel.visible = is_fullscreen
	if is_fullscreen:
		directions.visible = false
		anchors_preset = PRESET_FULL_RECT
		set_anchors_and_offsets_preset(PRESET_FULL_RECT, LayoutPresetMode.PRESET_MODE_MINSIZE)
		offset_left = 60
		offset_top = 60
		offset_right = -60
		offset_bottom = -60
		var screen_size := get_viewport_rect().size
		sub_viewport.size = Vector2i(screen_size.x - 120, screen_size.y - 120)
		circular_map_container.material = null
		_layout_coords_badge(true)
	else:
		directions.visible = true
		anchors_preset = PRESET_TOP_RIGHT
		offset_left = min_offsets["left"]
		offset_top = min_offsets["top"]
		offset_right = min_offsets["right"]
		offset_bottom = min_offsets["bottom"]
		sub_viewport.size = Vector2i(250, 250)
		circular_map_container.material = shader_material
		_layout_coords_badge(false)

	_apply_camera_zoom()


func _layout_coords_badge(at_top: bool) -> void:
	# Keep coordinates as a compact badge instead of stretching the panel
	# across the fullscreen map.
	coords_container.anchor_left = 0.5
	coords_container.anchor_right = 0.5
	coords_container.anchor_top = 0.0 if at_top else 1.0
	coords_container.anchor_bottom = coords_container.anchor_top
	coords_container.offset_left = -COORDS_BADGE_WIDTH * 0.5
	coords_container.offset_right = COORDS_BADGE_WIDTH * 0.5
	coords_container.offset_top = 12.0 if at_top else 10.0
	coords_container.offset_bottom = coords_container.offset_top + COORDS_BADGE_HEIGHT
	coords_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	coords_container.grow_vertical = (
		Control.GROW_DIRECTION_END if at_top else Control.GROW_DIRECTION_BEGIN
	)


func _setup_map_roots() -> void:
	_placed_blocks_root = Node2D.new()
	_placed_blocks_root.name = "PlacedBlockMarkers"
	sub_viewport.add_child(_placed_blocks_root)
	_resource_markers_root = Node2D.new()
	_resource_markers_root.name = "ResourceMarkers"
	sub_viewport.add_child(_resource_markers_root)
	_obelisk_markers_root = Node2D.new()
	_obelisk_markers_root.name = "ObeliskMarkers"
	sub_viewport.add_child(_obelisk_markers_root)
	_boss_markers_root = Node2D.new()
	_boss_markers_root.name = "BossMarkers"
	sub_viewport.add_child(_boss_markers_root)
	_ping_markers_root = Node2D.new()
	_ping_markers_root.name = "PingMarkers"
	sub_viewport.add_child(_ping_markers_root)


func _map_mouse_to_world(global_mouse: Vector2) -> Vector2:
	var rect := circular_map_container.get_global_rect()
	var local := global_mouse - rect.position
	var uv := Vector2(
		clampf(local.x / maxf(rect.size.x, 1.0), 0.0, 1.0),
		clampf(local.y / maxf(rect.size.y, 1.0), 0.0, 1.0)
	)
	var viewport_point := uv * Vector2(sub_viewport.size)
	return sub_viewport.canvas_transform.affine_inverse() * viewport_point


func _clear_player_block_nodes() -> void:
	for node: Node in _placed_block_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_placed_block_nodes.clear()


func _zoom_in() -> void:
	# Multiplicative steps so a few clicks reach a strong close-up.
	zoom_factor = minf(
		zoom_factor * (1.0 + ResourceSpawnConfig.MAP_ZOOM_STEP),
		ResourceSpawnConfig.MAP_ZOOM_MAX
	)
	_apply_camera_zoom()


func _zoom_out() -> void:
	zoom_factor = maxf(
		zoom_factor / (1.0 + ResourceSpawnConfig.MAP_ZOOM_STEP),
		ResourceSpawnConfig.MAP_ZOOM_MIN
	)
	_apply_camera_zoom()


## Mouse-wheel zoom on the fullscreen map, anchored to the cursor: the world
## point under the mouse stays put while the map scales around it.
func _zoom_at_screen_point(screen_pos: Vector2, zoom_in: bool) -> void:
	var rect := circular_map_container.get_global_rect()
	var local := screen_pos - rect.position
	var uv := Vector2(
		clampf(local.x / maxf(rect.size.x, 1.0), 0.0, 1.0),
		clampf(local.y / maxf(rect.size.y, 1.0), 0.0, 1.0)
	)
	var vp_size := Vector2(sub_viewport.size)
	var offset_from_center := uv * vp_size - vp_size * 0.5
	var old_zoom := map_camera.zoom.x
	var world_under_cursor := map_camera.global_position + offset_from_center / old_zoom

	if zoom_in:
		_zoom_in()
	else:
		_zoom_out()

	var new_zoom := map_camera.zoom.x
	if is_instance_valid(player) and not is_equal_approx(old_zoom, new_zoom):
		var camera_pos := world_under_cursor - offset_from_center / new_zoom
		_pan_offset = camera_pos - player.global_position
		map_camera.global_position = camera_pos


func _apply_camera_zoom() -> void:
	var base_val := (
		ResourceSpawnConfig.MAP_BASE_ZOOM_FULL
		if is_fullscreen
		else ResourceSpawnConfig.MAP_BASE_ZOOM_MINI
	)
	var z := base_val * zoom_factor
	map_camera.zoom = Vector2(z, z)


func _setup_ui_styles() -> void:
	var sb_coords := StyleBoxFlat.new()
	sb_coords.bg_color = Color(0.08, 0.08, 0.08, 0.85)
	sb_coords.content_margin_left = 8
	sb_coords.content_margin_top = 2
	sb_coords.content_margin_right = 8
	sb_coords.content_margin_bottom = 2
	sb_coords.set_corner_radius_all(6)
	sb_coords.set_border_width_all(1)
	sb_coords.border_color = Color("3a3a3a")
	coords_container.add_theme_stylebox_override("panel", sb_coords)
	coordinates_label.add_theme_font_size_override("font_size", 13)

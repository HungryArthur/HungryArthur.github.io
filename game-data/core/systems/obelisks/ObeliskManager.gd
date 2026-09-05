# res://core/systems/obelisks/ObeliskManager.gd
extends Node2D
class_name ObeliskManager

## Spawns all obelisks into the world, auto-discovers them when the player walks
## up, and performs the actual teleport. The F prompt + opening the travel menu
## live in InteractionPrompt. Discovery is persisted in WorldData.discovered_obelisks.

const DISCOVER_RANGE := 100.0   # walk this close → obelisk is unlocked for travel
const DISCOVER_RANGE_SQ := DISCOVER_RANGE * DISCOVER_RANGE
const FADE_TIME := 0.18         # black-fade half-duration that masks the teleport

var _player: Node2D
var _world_data: WorldData
var _map_system: Node

var _nodes: Dictionary = {}        # id -> Obelisk
var _data_by_id: Dictionary = {}   # id -> registry data dict (O(1) lookups)
var _discovered: Dictionary = {}   # id -> true (shared ref with world_data)

var _fade_rect: ColorRect
var _teleporting: bool = false


func setup(world_data: WorldData, player: Node2D, map_system: Node) -> void:
	_world_data = world_data
	_player = player
	_map_system = map_system
	add_to_group("obelisk_manager")
	if _world_data != null:
		_discovered = _world_data.discovered_obelisks
	for data: Dictionary in ObeliskRegistry.get_all():
		_data_by_id[str(data["id"])] = data
	_spawn_obelisks()
	_push_to_map()
	_refresh_process()


func get_discovered() -> Dictionary:
	return _discovered


func _spawn_obelisks() -> void:
	for data: Dictionary in ObeliskRegistry.get_all():
		var ob := Obelisk.new()
		add_child(ob)
		ob.setup(data)
		ob.global_position = ObeliskRegistry.world_pos(data["tile"])
		ob.set_discovered(_discovered.has(data["id"]))
		_nodes[str(data["id"])] = ob


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	# Auto-unlock obelisks the player walks up to (InteractionPrompt handles the
	# F prompt + opening the travel menu).
	var ppos: Vector2 = _player.global_position
	for id_value: Variant in _nodes.keys():
		var id := str(id_value)
		if _discovered.has(id):
			continue
		var ob: Obelisk = _nodes[id]
		if ppos.distance_squared_to(ob.global_position) <= DISCOVER_RANGE_SQ:
			_discover(id)


## Stops the per-frame proximity scan once every obelisk has been found.
func _refresh_process() -> void:
	set_process(_discovered.size() < _nodes.size())


func _discover(id: String) -> void:
	if _discovered.has(id):
		return
	var data: Dictionary = _data_by_id.get(id, {})
	if not BiomeProgression.is_biome_unlocked(str(data.get("biome", ""))):
		return
	_discovered[id] = true
	if _world_data != null:
		_world_data.discovered_obelisks = _discovered
	if _nodes.has(id):
		(_nodes[id] as Obelisk).set_discovered(true)
	_notify(tr("✦ Открыт обелиск: %s") % ObeliskRegistry.display_name(str(data.get("name", id))))
	_push_to_map()
	_refresh_process()


## Teleports the player to a discovered obelisk, masking the async chunk pop-in
## with a short black fade and forcing the world to refresh visible chunks at the
## destination. Called from the menu and the map.
func teleport_to(id: String) -> void:
	if _teleporting or not _discovered.has(id) or not is_instance_valid(_player):
		return
	var data: Dictionary = _data_by_id.get(id, {})
	if data.is_empty():
		return
	if not BiomeProgression.is_biome_unlocked(str(data.get("biome", ""))):
		_notify(tr("Biome locked") + " — " + BiomeProgression.requirement_text(str(data.get("biome", ""))))
		return
	_teleporting = true
	AudioManager.play_sfx("teleport", -2.0)
	await _fade(0.0, 1.0)
	_player.global_position = ObeliskRegistry.world_pos(data["tile"])
	_player.reset_physics_interpolation()
	_refresh_world_chunks()
	_notify(tr("✦ Перемещение: %s") % ObeliskRegistry.display_name(str(data.get("name", id))))
	# Give the world a frame to activate already-generated chunks before fading in.
	await get_tree().process_frame
	await _fade(1.0, 0.0)
	_teleporting = false


## Nudges the World to rebuild the chunks around the player's new position so the
## destination isn't a blank void while the generator catches up.
func _refresh_world_chunks() -> void:
	var world: Node = get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("world_to_chunk") and world.has_method("update_visible_chunks"):
		world.set("current_chunk", world.world_to_chunk(_player.global_position))
		world.update_visible_chunks()


func _fade(from: float, to: float) -> Signal:
	_ensure_fade_rect()
	_fade_rect.color.a = from
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", to, FADE_TIME)
	return tween.finished


func _ensure_fade_rect() -> void:
	if _fade_rect != null and is_instance_valid(_fade_rect):
		return
	var layer := CanvasLayer.new()
	layer.layer = 128  # above the HUD so the fade covers everything
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)


func _push_to_map() -> void:
	if _map_system != null and _map_system.has_method("set_obelisks"):
		_map_system.set_obelisks(ObeliskRegistry.get_all(), _discovered)


func _notify(text: String) -> void:
	var chat: Node = get_tree().get_first_node_in_group("game_chat")
	if chat != null and chat.has_method("add_colored_message"):
		chat.add_colored_message(text, Color(0.55, 0.85, 1.0))

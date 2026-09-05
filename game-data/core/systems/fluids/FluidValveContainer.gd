extends MachineContainer
class_name FluidValveContainer

const MODE_NORMAL := "normal"
const MODE_OVERFLOW := "overflow"

var source_grid_pos := Vector2i.ZERO
var facing := 2
var filter_id := ""
var enabled := true
var mode := MODE_NORMAL
var overflow_threshold := 0.80


func set_source_grid_pos(grid_pos: Vector2i) -> void:
	source_grid_pos = grid_pos


func set_facing(new_facing: int) -> void:
	facing = ((new_facing % 4) + 4) % 4


func configure(
		p_filter_id: String,
		is_enabled: bool = true,
		p_mode: String = "",
		p_overflow_threshold: float = -1.0
) -> void:
	filter_id = _sanitize_fluid_id(p_filter_id)
	enabled = is_enabled
	if not p_mode.is_empty():
		mode = MODE_OVERFLOW if p_mode == MODE_OVERFLOW else MODE_NORMAL
	if p_overflow_threshold >= 0.0:
		overflow_threshold = clampf(p_overflow_threshold, 0.10, 1.0)
	wake()


func allows_fluid(fluid_id: String, source_fill_ratio: float = 1.0) -> bool:
	if not enabled or fluid_id.is_empty() or (not filter_id.is_empty() and filter_id != fluid_id):
		return false
	return mode != MODE_OVERFLOW or source_fill_ratio + 0.0001 >= overflow_threshold


func is_idle() -> bool:
	return true


func network_config_data() -> Dictionary:
	var config := super.network_config_data()
	config["filter_id"] = filter_id
	config["enabled"] = enabled
	config["facing"] = facing
	config["mode"] = mode
	config["overflow_threshold"] = overflow_threshold
	return config


func apply_network_config(config: Dictionary) -> void:
	super.apply_network_config(config)
	configure(
		str(config.get("filter_id", filter_id)),
		bool(config.get("enabled", enabled)),
		str(config.get("mode", mode)),
		float(config.get("overflow_threshold", overflow_threshold))
	)
	set_facing(clampi(int(config.get("facing", facing)), 0, 3))
	_sync_owner_facing()


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["filter_id"] = filter_id
	data["enabled"] = enabled
	data["facing"] = facing
	data["mode"] = mode
	data["overflow_threshold"] = overflow_threshold
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	configure(
		str(data.get("filter_id", "")),
		bool(data.get("enabled", true)),
		str(data.get("mode", MODE_NORMAL)),
		float(data.get("overflow_threshold", 0.80))
	)
	set_facing(clampi(int(data.get("facing", facing)), 0, 3))
	_sync_owner_facing()


func _sanitize_fluid_id(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_").left(64)


func _sync_owner_facing() -> void:
	var block := get_parent() as WorldBlock
	if block != null and block.facing != facing:
		block.set_facing(facing)

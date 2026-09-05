extends FluidMachineContainer
class_name WaterPumpContainer

const POWER_CONSUMPTION := 10.0
const PUMP_RATE := 8.0
const MECHANICAL_PUMP_RATE := 4.0
const STEAM_PUMP_RATE := 16.0
const STEAM_PER_WATER := 1.0 / 16.0
const STEAM_BUFFER_CAPACITY := 30.0
const STEAM_PUMP_OUTPUT_CAPACITY := 300.0

var pump_rate := PUMP_RATE
var drive_type := "electric"
var _quest_report_timer := 0.0


func _init() -> void:
	machine_title = "WATER PUMP"
	power_capacity = 100.0
	output_tanks = [FluidTank.new(150.0)]


func set_block_id(block_id: String) -> void:
	match block_id:
		"mechanical_water_pump":
			drive_type = "mechanical"
			requires_power = false
			power_capacity = 0.0
			pump_rate = MECHANICAL_PUMP_RATE
			machine_title = "MECHANICAL WATER PUMP"
			input_tanks = []
			output_tanks = [FluidTank.new(150.0)]
		"steam_water_pump":
			drive_type = "steam"
			requires_power = false
			power_capacity = 0.0
			pump_rate = STEAM_PUMP_RATE
			machine_title = "STEAM WATER PUMP"
			input_tanks = [FluidTank.new(STEAM_BUFFER_CAPACITY)]
			output_tanks = [FluidTank.new(STEAM_PUMP_OUTPUT_CAPACITY)]
		_:
			drive_type = "electric"
			requires_power = true
			power_capacity = 100.0
			pump_rate = PUMP_RATE
			machine_title = "WATER PUMP"
			input_tanks = []
			output_tanks = [FluidTank.new(150.0)]


func tick(delta: float) -> void:
	var buffer: FluidTank = output_tanks[0]
	var world := get_tree().get_first_node_in_group("world")
	var available_drive_water := INF
	if drive_type == "steam":
		available_drive_water = input_tanks[0].amount / STEAM_PER_WATER
	var can_run := (
		(not requires_power or power_stored > 0.0)
		and available_drive_water > 0.0
		and buffer.space_for("water") > 0.0
		and world != null
		and world.has_method("is_water_tile")
		and bool(world.is_water_tile(source_grid_pos))
	)
	processing_active = can_run
	if not can_run:
		return
	var produced := minf(minf(pump_rate * delta, buffer.space_for("water")), available_drive_water)
	buffer.insert("water", produced)
	if drive_type == "steam":
		input_tanks[0].extract(produced * STEAM_PER_WATER)
		_quest_report_timer -= delta
		if _quest_report_timer <= 0.0:
			_quest_report_timer = 1.0
			QuestManager.report_event("steam_pump_online", "water", 1)
	elif requires_power:
		power_stored = maxf(power_stored - POWER_CONSUMPTION * delta, 0.0)
	fluid_changed.emit()


func can_accept_fluid(fluid_id: String) -> bool:
	return drive_type == "steam" and fluid_id == "steam" and super.can_accept_fluid(fluid_id)


func push_fluid(fluid_id: String, liters: float) -> float:
	if drive_type != "steam" or fluid_id != "steam":
		return 0.0
	return super.push_fluid(fluid_id, liters)


func fluid_input_priority(fluid_id: String) -> int:
	return adjusted_input_priority(175) if fluid_id == "steam" and can_accept_fluid(fluid_id) else -1


func process_progress() -> float:
	return output_tanks[0].fill_ratio()

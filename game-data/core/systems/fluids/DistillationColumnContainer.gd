extends FluidMachineContainer
class_name DistillationColumnContainer

const POWER_CONSUMPTION := 60.0
const PROCESS_TIME := 5.0
const CRUDE_PER_BATCH := 10.0
const PRODUCTS: Dictionary = {
	"refinery_gas": 1.0,
	"gasoline": 3.0,
	"kerosene": 2.0,
	"diesel": 2.0,
	"heavy_oil": 1.0,
	"bitumen": 1.0,
}

var process_timer := 0.0


func _init() -> void:
	machine_title = "DISTILLATION COLUMN"
	power_capacity = 600.0
	input_tanks = [FluidTank.new(200.0)]
	for _fluid_id: String in PRODUCTS:
		output_tanks.append(FluidTank.new(100.0))


func tick(delta: float) -> void:
	var input: FluidTank = input_tanks[0]
	var can_run := (
		power_stored > 0.0
		and input.fluid_id == "crude_oil"
		and input.amount >= CRUDE_PER_BATCH
		and _outputs_have_space()
	)
	processing_active = can_run
	if not can_run:
		process_timer = 0.0
		return
	power_stored = maxf(power_stored - POWER_CONSUMPTION * delta, 0.0)
	process_timer += delta
	if process_timer >= PROCESS_TIME:
		process_timer = 0.0
		input.extract(CRUDE_PER_BATCH)
		var index := 0
		for fluid_id: String in PRODUCTS:
			output_tanks[index].insert(fluid_id, float(PRODUCTS[fluid_id]))
			index += 1
		fluid_changed.emit()


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0)


func fluid_input_priority(fluid_id: String) -> int:
	return adjusted_input_priority(200) if fluid_id == "crude_oil" and can_accept_fluid(fluid_id) else -1


func can_accept_fluid(fluid_id: String) -> bool:
	return fluid_id == "crude_oil" and super.can_accept_fluid(fluid_id)


func push_fluid(fluid_id: String, liters: float) -> float:
	if fluid_id != "crude_oil":
		return 0.0
	return super.push_fluid(fluid_id, liters)


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))


func _outputs_have_space() -> bool:
	var index := 0
	for fluid_id: String in PRODUCTS:
		if output_tanks[index].space_for(fluid_id) < float(PRODUCTS[fluid_id]):
			return false
		index += 1
	return true

extends FluidMachineContainer
class_name MixerContainer

## Смеситель: большая машина 3×3 клетки. Сплавляет 2-4 жидкости в одну:
## бронза, электрум, топливные смеси. Жидкости приходят по трубам в четыре
## входных бака (каждая жидкость занимает свой бак), результат — в выходной бак.

## Рецепт: {inputs: {fluid: liters, ...}, output, output_liters}.
## Проверяются от самых «широких» (4 жидкости) к простым (2).
const RECIPES: Array[Dictionary] = [
	{"inputs": {"gasoline": 25.0, "diesel": 25.0, "kerosene": 25.0, "heavy_oil": 25.0},
		"output": "fuel_blend", "output_liters": 150.0},
	{"inputs": {"gasoline": 30.0, "diesel": 30.0, "kerosene": 30.0},
		"output": "fuel_blend", "output_liters": 120.0},
	{"inputs": {"gasoline": 40.0, "diesel": 40.0},
		"output": "fuel_blend", "output_liters": 100.0},
	{"inputs": {"molten_copper": 45.0, "molten_tin": 45.0},
		"output": "molten_bronze", "output_liters": 90.0},
	{"inputs": {"molten_gold": 45.0, "molten_silver": 45.0},
		"output": "molten_electrum", "output_liters": 90.0},
]

const POWER_CONSUMPTION := 50.0
const PROCESS_TIME := 5.0
const INPUT_CAPACITY := 200.0
const OUTPUT_CAPACITY := 400.0

var process_timer: float = 0.0


func _init() -> void:
	machine_title = "MIXER"
	power_capacity = 500.0
	input_tanks = [
		FluidTank.new(INPUT_CAPACITY), FluidTank.new(INPUT_CAPACITY),
		FluidTank.new(INPUT_CAPACITY), FluidTank.new(INPUT_CAPACITY),
	]
	output_tanks = [FluidTank.new(OUTPUT_CAPACITY)]
	slots = []


func tick(delta: float) -> void:
	var recipe := _find_recipe()

	processing_active = power_stored > 0.0 and not recipe.is_empty()

	if processing_active:
		power_stored = maxf(power_stored - POWER_CONSUMPTION * delta, 0.0)
		process_timer += delta
		if process_timer >= PROCESS_TIME:
			process_timer = 0.0
			_complete_process(recipe)
	else:
		process_timer = 0.0


func _find_recipe() -> Dictionary:
	var out_tank: FluidTank = output_tanks[0]
	for r: Dictionary in RECIPES:
		var inputs: Dictionary = r.get("inputs", {}) as Dictionary
		if out_tank.space_for(str(r.get("output", ""))) < float(r.get("output_liters", 0.0)):
			continue
		var ok := true
		for fluid_id: String in inputs:
			if _available(fluid_id) < float(inputs[fluid_id]):
				ok = false
				break
		if ok:
			return r
	return {}


func _available(fluid_id: String) -> float:
	var total := 0.0
	for tank: FluidTank in input_tanks:
		if tank.fluid_id == fluid_id:
			total += tank.amount
	return total


func _complete_process(recipe: Dictionary) -> void:
	var inputs: Dictionary = recipe.get("inputs", {}) as Dictionary
	for fluid_id: String in inputs:
		var remaining := float(inputs[fluid_id])
		for tank: FluidTank in input_tanks:
			if tank.fluid_id == fluid_id:
				remaining -= tank.extract(remaining)
			if remaining <= 0.0001:
				break
	output_tanks[0].insert(str(recipe.get("output", "")), float(recipe.get("output_liters", 0.0)))
	fluid_changed.emit()


## Каждая жидкость живёт ровно в одном входном баке.
func can_accept_fluid(fluid_id: String) -> bool:
	return _tank_for(fluid_id) != null


func push_fluid(fluid_id: String, liters: float) -> float:
	var tank: FluidTank = _tank_for(fluid_id)
	if tank == null:
		return 0.0
	var inserted := tank.insert(fluid_id, maxf(liters, 0.0))
	if inserted > 0.0:
		fluid_changed.emit()
	return inserted


func _tank_for(fluid_id: String) -> FluidTank:
	for tank: FluidTank in input_tanks:
		if tank.fluid_id == fluid_id and tank.space_for(fluid_id) > 0.0:
			return tank
	for tank: FluidTank in input_tanks:
		if tank.fluid_id.is_empty():
			return tank
	return null


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


## Строка состояния для жидкостного меню.
func status_text() -> String:
	if processing_active:
		return "Mixing..."
	if power_stored <= 0.0:
		return "No power"
	return "Waiting for fluids"


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

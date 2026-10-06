extends FluidMachineContainer
class_name MixerContainer

## Смеситель: машина 2×2 клетки. Сплавляет 2-4 жидкости в одну:
## бронза, электрум, топливные смеси. Жидкости приходят по трубам в четыре
## входных бака (каждая жидкость занимает свой бак), результат — в выходной бак.

## Рецепт: {inputs: {fluid: liters, ...}, output, output_liters}.
## Проверяются от самых «широких» (4 жидкости) к простым (2).
const DEFAULT_RECIPES: Array[Dictionary] = [
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

static var POWER_CONSUMPTION: float = GameTuning.number("machines", "mixer", "POWER_CONSUMPTION", 50.0)
static var PROCESS_TIME: float = GameTuning.number("machines", "mixer", "PROCESS_TIME", 5.0)
static var INPUT_CAPACITY: float = GameTuning.number("machines", "mixer", "INPUT_CAPACITY", 200.0)
static var OUTPUT_CAPACITY: float = GameTuning.number("machines", "mixer", "OUTPUT_CAPACITY", 400.0)
var process_timer: float = 0.0
## Empty means automatic. Store the actual recipe, so save files survive recipe
## reordering and the three fuel-blend variants remain distinct.
var selected_recipe: Dictionary = {}
var process_recipe: Dictionary = {}


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
	if recipe.is_empty():
		process_timer = 0.0
		process_recipe = {}
	elif not _same_recipe(recipe, process_recipe):
		process_timer = 0.0
		process_recipe = recipe.duplicate(true)
	var fits := not recipe.is_empty() and output_tanks[0].space_for(str(recipe["output"])) + 0.0001 >= float(recipe["output_liters"])
	processing_active = power_stored > 0.0 and fits

	if processing_active:
		process_timer += consume_processing_power(delta, POWER_CONSUMPTION)
		if process_timer >= PROCESS_TIME:
			process_timer -= PROCESS_TIME
			_complete_process(recipe)


func _find_recipe() -> Dictionary:
	var best: Dictionary = {}
	for r: Dictionary in RECIPES:
		var inputs: Dictionary = r.get("inputs", {}) as Dictionary
		if not selected_recipe.is_empty() and not _same_recipe(r, selected_recipe):
			continue
		var ok := true
		for fluid_id: String in inputs:
			if _available(fluid_id) + 0.0001 < float(inputs[fluid_id]):
				ok = false
				break
		if ok and (best.is_empty() or inputs.size() > (best["inputs"] as Dictionary).size()):
			best = r
	return best


func select_recipe(index: int) -> bool:
	if index < -1 or index >= RECIPES.size():
		return false
	var next: Dictionary = {} if index == -1 else RECIPES[index].duplicate(true)
	if next == selected_recipe:
		return true
	selected_recipe = next
	process_recipe = {}
	process_timer = 0.0
	processing_active = false
	wake()
	fluid_changed.emit()
	notify_network_config_changed()
	return true


func selected_recipe_index() -> int:
	if selected_recipe.is_empty():
		return -1
	for index: int in RECIPES.size():
		if _same_recipe(RECIPES[index], selected_recipe):
			return index
	return -2


## ME providers choose the exact encoded variant before delivering its batch.
func select_processing_recipe(fluids: Dictionary, output: String, liters: float) -> bool:
	for index: int in RECIPES.size():
		if _same_recipe(RECIPES[index], {"inputs": fluids, "output": output.trim_prefix("fluid:"), "output_liters": liters}):
			return select_recipe(index)
	return false


static func _same_recipe(first: Dictionary, second: Dictionary) -> bool:
	if first.is_empty() or second.is_empty() or str(first.get("output", "")) != str(second.get("output", "")) or not is_equal_approx(float(first.get("output_liters", 0.0)), float(second.get("output_liters", 0.0))):
		return false
	var left: Dictionary = first.get("inputs", {})
	var right: Dictionary = second.get("inputs", {})
	if left.size() != right.size():
		return false
	for id: String in left:
		if not right.has(id) or not is_equal_approx(float(left[id]), float(right[id])):
			return false
	return true


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
	var tank := _tank_for(fluid_id)
	return tank != null and tank.space_for(fluid_id) > 0.0


func push_fluid(fluid_id: String, liters: float) -> float:
	var tank: FluidTank = _tank_for(fluid_id)
	if tank == null:
		return 0.0
	var inserted := tank.insert(fluid_id, maxf(liters, 0.0))
	if inserted > 0.0:
		wake()
		fluid_changed.emit()
	return inserted


func _tank_for(fluid_id: String) -> FluidTank:
	var used := false
	for recipe: Dictionary in RECIPES:
		used = used or (recipe.get("inputs", {}) as Dictionary).has(fluid_id)
	if not used or not FluidDatabase.exists(fluid_id):
		return null
	for tank: FluidTank in input_tanks:
		if tank.fluid_id == fluid_id:
			return tank
	for tank: FluidTank in input_tanks:
		if tank.fluid_id.is_empty():
			return tank
	return null


## Only explicit player interaction may drain ingredients, never pipe output.
func pull_input_fluid(fluid_id: String, liters: float) -> float:
	if me_request_output_locked:
		return 0.0
	var remaining := maxf(liters, 0.0)
	var taken := 0.0
	for tank: FluidTank in input_tanks:
		if tank.fluid_id == fluid_id:
			var amount := tank.extract(remaining)
			taken += amount
			remaining -= amount
	if taken > 0.0:
		wake()
		fluid_changed.emit()
	return taken


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0)


## Строка состояния для жидкостного меню.
func status_text() -> String:
	if processing_active:
		return "Mixing..."
	if output_control_blocked or item_output_control_blocked or stock_control_blocked:
		return "Stopped by output control"
	if power_stored <= 0.0:
		return "No power"
	if selected_recipe_index() == -2:
		return "Recipe unavailable"
	var recipe := _find_recipe()
	if not recipe.is_empty() and output_tanks[0].space_for(str(recipe["output"])) + 0.0001 < float(recipe["output_liters"]):
		return "Output blocked"
	return "Waiting for fluids"


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	data["mixer_recipe"] = selected_recipe.duplicate(true)
	data["process_recipe"] = process_recipe.duplicate(true)
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = maxf(float(data.get("process_timer", 0.0)), 0.0)
	selected_recipe = (data.get("mixer_recipe", {}) as Dictionary).duplicate(true)
	process_recipe = (data.get("process_recipe", {}) as Dictionary).duplicate(true)
	if process_recipe.is_empty() and process_timer > 0.0:
		process_recipe = _find_recipe().duplicate(true)
	fluid_changed.emit()


func network_config_data() -> Dictionary:
	var config := super.network_config_data()
	config["mixer_recipe"] = selected_recipe.duplicate(true)
	return config


func apply_network_config(config: Dictionary) -> void:
	super.apply_network_config(config)
	if not config.has("mixer_recipe") or me_request_output_locked:
		return
	var requested: Dictionary = config["mixer_recipe"] as Dictionary
	var valid := requested.is_empty()
	for recipe: Dictionary in RECIPES:
		valid = valid or _same_recipe(recipe, requested)
	if valid and requested != selected_recipe:
		selected_recipe = requested.duplicate(true)
		process_recipe = {}
		process_timer = 0.0
		processing_active = false
		wake()
		fluid_changed.emit()


static var RECIPES: Array[Dictionary] = GameTuning.recipe_array("mixer", DEFAULT_RECIPES)

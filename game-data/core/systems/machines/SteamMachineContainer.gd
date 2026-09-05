extends FluidMachineContainer
class_name SteamMachineContainer

## База паровых обрабатывающих машин (дробилка, печь, пресс): слоты вход/выход
## плюс маленький бак пара, который наполняется по трубам от котла. Пар
## расходуется только пока идёт обработка — как EU у электрических машин.

const STEAM_TANK_CAPACITY := 50.0

const SLOT_INPUT := 0
const SLOT_OUTPUT := 1

var recipes: Dictionary = {}   # input_id -> {output, output_count, input_count}
var process_time: float = 5.0
var steam_per_second: float = 2.0
var process_timer: float = 0.0


func _init() -> void:
	requires_power = false
	power_capacity = 0.0


## Вызывается из _init подкласса: задаёт рецепты, бак пара и создаёт слоты.
func configure(p_title: String, p_recipes: Dictionary, p_time: float, p_steam: float) -> void:
	# Бак создаём здесь, а не в _init: инициализатор `input_tanks = []` базового
	# FluidMachineContainer может отработать позже конструктора этого класса и
	# затереть бак — тогда tick() падал бы на input_tanks[0].
	if input_tanks.is_empty():
		input_tanks = [FluidTank.new(STEAM_TANK_CAPACITY)]

	machine_title = p_title
	recipes = p_recipes
	process_time = p_time
	steam_per_second = p_steam

	var s_in := MachineSlot.new()
	s_in.role = MachineSlot.Role.INPUT
	s_in.filter = PackedStringArray(recipes.keys())

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	slots = [s_in, s_out]


func tick(delta: float) -> void:
	var s_in: MachineSlot = slots[SLOT_INPUT]
	var s_out: MachineSlot = slots[SLOT_OUTPUT]

	var in_id: String = s_in.item.get("id", "")
	var recipe: Dictionary = recipes.get(in_id, {}) as Dictionary
	var in_need: int = recipe.get("input_count", 1) as int

	var can_run: bool = (
		not s_in.is_empty()
		and not recipe.is_empty()
		and int(s_in.item.get("count", 0)) >= in_need
	)

	var output_blocked: bool = false
	if can_run and not s_out.is_empty():
		var out_id: String = s_out.item.get("id", "")
		var out_add: int = recipe.get("output_count", 1) as int
		output_blocked = out_id != recipe.get("output", "") \
			or int(s_out.item.get("count", 0)) + out_add > int(s_out.item.get("max_stack", 64))

	processing_active = has_steam() and can_run and not output_blocked

	if processing_active:
		input_tanks[0].extract(steam_per_second * delta)
		fluid_changed.emit()
		process_timer += delta
		if process_timer >= process_time:
			process_timer = 0.0
			_complete_process(s_in, s_out, recipe)
	else:
		process_timer = 0.0


func has_steam() -> bool:
	return not input_tanks.is_empty() and input_tanks[0].amount > 0.0


func steam_progress() -> float:
	return input_tanks[0].fill_ratio() if not input_tanks.is_empty() else 0.0


func process_progress() -> float:
	return clampf(process_timer / process_time, 0.0, 1.0) if processing_active else 0.0


## Паровые машины принимают по трубам только пар.
func can_accept_fluid(fluid_id: String) -> bool:
	return fluid_id == "steam" and super.can_accept_fluid(fluid_id)


func push_fluid(fluid_id: String, liters: float) -> float:
	if fluid_id != "steam":
		return 0.0
	return super.push_fluid(fluid_id, liters)


func fluid_input_priority(fluid_id: String) -> int:
	return adjusted_input_priority(150) if fluid_id == "steam" and can_accept_fluid(fluid_id) else -1


## Переопределяется подклассом (например, паровая печь шлёт item_smelted).
func _complete_process(s_in: MachineSlot, s_out: MachineSlot, recipe: Dictionary) -> void:
	s_in.extract(recipe.get("input_count", 1) as int)
	slot_changed.emit(SLOT_INPUT)

	var output_id: String = recipe.get("output", "") as String
	var output_count: int = recipe.get("output_count", 1) as int

	if not ItemDatabase.registry.has(output_id):
		push_error("%s: unknown output item '%s'" % [machine_title, output_id])
		return

	if s_out.is_empty():
		s_out.item = ItemDatabase.create_existing_stack(output_id, output_count)
	else:
		s_out.item["count"] = int(s_out.item.get("count", 0)) + output_count
	slot_changed.emit(SLOT_OUTPUT)
	QuestManager.report_event("item_processed", output_id, output_count)


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

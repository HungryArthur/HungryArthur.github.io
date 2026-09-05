extends FluidMachineContainer
class_name CokeOvenContainer

## Коксовая печь: медленно пережигает уголь в кокс, побочно капает креозот.
## Без энергии и топлива — просто время. Креозот уходит по трубам
## (например, в котёл как жидкое топливо).

const RECIPES: Dictionary = {
	"coal": {"output": "coke", "output_count": 1, "input_count": 1},
}
const PROCESS_TIME := 15.0
const CREOSOTE_PER_COKE := 1.0
const CREOSOTE_TANK_CAPACITY := 100.0

const SLOT_INPUT := 0
const SLOT_OUTPUT := 1

var process_timer: float = 0.0


func _init() -> void:
	machine_title = "COKE OVEN"
	requires_power = false
	power_capacity = 0.0
	output_tanks = [FluidTank.new(CREOSOTE_TANK_CAPACITY)]

	var s_in := MachineSlot.new()
	s_in.role = MachineSlot.Role.INPUT
	s_in.filter = PackedStringArray(RECIPES.keys())

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	slots = [s_in, s_out]


func tick(delta: float) -> void:
	var s_in: MachineSlot = slots[SLOT_INPUT]
	var s_out: MachineSlot = slots[SLOT_OUTPUT]

	var in_id: String = s_in.item.get("id", "")
	var recipe: Dictionary = RECIPES.get(in_id, {}) as Dictionary
	var in_need: int = recipe.get("input_count", 1) as int

	var can_run: bool = (
		not s_in.is_empty()
		and not recipe.is_empty()
		and int(s_in.item.get("count", 0)) >= in_need
		and output_tanks[0].space_for("creosote") >= CREOSOTE_PER_COKE
	)

	var output_blocked: bool = false
	if can_run and not s_out.is_empty():
		var out_id: String = s_out.item.get("id", "")
		var out_add: int = recipe.get("output_count", 1) as int
		output_blocked = out_id != recipe.get("output", "") \
			or int(s_out.item.get("count", 0)) + out_add > int(s_out.item.get("max_stack", 64))

	processing_active = can_run and not output_blocked

	if processing_active:
		process_timer += delta
		if process_timer >= PROCESS_TIME:
			process_timer = 0.0
			_complete_process(s_in, s_out, recipe)
	else:
		process_timer = 0.0


func _complete_process(s_in: MachineSlot, s_out: MachineSlot, recipe: Dictionary) -> void:
	s_in.extract(recipe.get("input_count", 1) as int)
	slot_changed.emit(SLOT_INPUT)

	var output_id: String = recipe.get("output", "") as String
	var output_count: int = recipe.get("output_count", 1) as int

	if not ItemDatabase.registry.has(output_id):
		push_error("CokeOvenContainer: unknown output item '%s'" % output_id)
		return

	if s_out.is_empty():
		s_out.item = ItemDatabase.create_existing_stack(output_id, output_count)
	else:
		s_out.item["count"] = int(s_out.item.get("count", 0)) + output_count
	slot_changed.emit(SLOT_OUTPUT)
	QuestManager.report_event("item_processed", output_id, output_count)

	var produced_creosote := output_tanks[0].insert("creosote", CREOSOTE_PER_COKE)
	if produced_creosote > 0.0:
		QuestManager.report_event("fluid_produced", "creosote", roundi(produced_creosote))
	fluid_changed.emit()


func creosote_progress() -> float:
	return output_tanks[0].fill_ratio()


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


## Коксовая печь по трубам ничего не принимает — только отдаёт креозот.
func can_accept_fluid(_fluid_id: String) -> bool:
	return false


func push_fluid(_fluid_id: String, _liters: float) -> float:
	return 0.0


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

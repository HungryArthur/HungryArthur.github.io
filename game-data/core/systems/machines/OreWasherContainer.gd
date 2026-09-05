extends FluidMachineContainer
class_name OreWasherContainer

## Промывочная машина: руда + вода -> две обычные пыли металла + одна
## обычная побочная пыль. Отдельных дроблёных/промытых форм руды нет.

const RECIPES: Dictionary = {
	"iron_ore":     {"output": "iron_dust",     "byproduct": "nickel_dust"},
	"copper_ore":   {"output": "copper_dust",   "byproduct": "gold_dust"},
	"tin_ore":      {"output": "tin_dust",      "byproduct": "iron_dust"},
	"gold_ore":     {"output": "gold_dust",     "byproduct": "silver_dust"},
	"silver_ore":   {"output": "silver_dust",   "byproduct": "lead_dust"},
	"titanium_ore": {"output": "titanium_dust", "byproduct": "platinum_dust"},
	"mythril_ore":  {"output": "mythril_dust",  "byproduct": "titanium_dust"},
}
const OUTPUT_COUNT := 2
const POWER_CONSUMPTION := 15.0
const PROCESS_TIME := 4.0
const WATER_PER_OP := 10.0
const WATER_TANK_CAPACITY := 100.0

const SLOT_INPUT := 0
const SLOT_OUTPUT := 1
const SLOT_BYPRODUCT := 2

var process_timer: float = 0.0


func _init() -> void:
	machine_title = "ORE WASHER"
	power_capacity = 150.0
	input_tanks = [FluidTank.new(WATER_TANK_CAPACITY)]

	var s_in := MachineSlot.new()
	s_in.role = MachineSlot.Role.INPUT
	s_in.filter = PackedStringArray(RECIPES.keys())

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	var s_by := MachineSlot.new()
	s_by.role = MachineSlot.Role.OUTPUT

	slots = [s_in, s_out, s_by]


func tick(delta: float) -> void:
	var s_in: MachineSlot = slots[SLOT_INPUT]
	var recipe: Dictionary = RECIPES.get(s_in.item.get("id", ""), {}) as Dictionary

	var can_run: bool = (
		not s_in.is_empty()
		and not recipe.is_empty()
		and input_tanks[0].amount >= WATER_PER_OP
		and _slot_fits(slots[SLOT_OUTPUT], str(recipe.get("output", "")), OUTPUT_COUNT)
		and _slot_fits(slots[SLOT_BYPRODUCT], str(recipe.get("byproduct", "")), 1)
	)

	processing_active = power_stored > 0.0 and can_run

	if processing_active:
		power_stored = maxf(power_stored - POWER_CONSUMPTION * delta, 0.0)
		process_timer += delta
		if process_timer >= PROCESS_TIME:
			process_timer = 0.0
			_complete_process(recipe)
	else:
		process_timer = 0.0


func _complete_process(recipe: Dictionary) -> void:
	(slots[SLOT_INPUT] as MachineSlot).extract(1)
	slot_changed.emit(SLOT_INPUT)
	input_tanks[0].extract(WATER_PER_OP)
	fluid_changed.emit()
	_add_to_slot(SLOT_OUTPUT, str(recipe.get("output", "")), OUTPUT_COUNT)
	_add_to_slot(SLOT_BYPRODUCT, str(recipe.get("byproduct", "")), 1)


func _add_to_slot(slot_idx: int, item_id: String, count: int) -> void:
	if not ItemDatabase.registry.has(item_id):
		push_error("OreWasherContainer: unknown item '%s'" % item_id)
		return
	var slot: MachineSlot = slots[slot_idx]
	if slot.is_empty():
		slot.item = ItemDatabase.create_existing_stack(item_id, count)
	else:
		slot.item["count"] = int(slot.item.get("count", 0)) + count
	slot_changed.emit(slot_idx)
	QuestManager.report_event("item_processed", item_id, count)


func _slot_fits(slot: MachineSlot, item_id: String, count: int) -> bool:
	if slot.is_empty():
		return true
	return slot.item.get("id", "") == item_id \
		and int(slot.item.get("count", 0)) + count <= int(slot.item.get("max_stack", 64))


func water_amount() -> float:
	return input_tanks[0].amount


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


func can_accept_fluid(fluid_id: String) -> bool:
	return fluid_id == "water" and super.can_accept_fluid(fluid_id)


func push_fluid(fluid_id: String, liters: float) -> float:
	if fluid_id != "water":
		return 0.0
	return super.push_fluid(fluid_id, liters)


func fluid_input_priority(fluid_id: String) -> int:
	return adjusted_input_priority(150) if fluid_id == "water" and can_accept_fluid(fluid_id) else -1


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

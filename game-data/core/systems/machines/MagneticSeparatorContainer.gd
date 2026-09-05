extends PoweredMachineContainer
class_name MagneticSeparatorContainer

## Магнитный сепаратор работает напрямую с рудой и выдаёт две обычные пыли
## основного металла плюс одну обычную магнитную побочную пыль.

const RECIPES: Dictionary = {
	"iron_ore":     {"output": "iron_dust",     "byproduct": "nickel_dust"},
	"copper_ore":   {"output": "copper_dust",   "byproduct": "gold_dust"},
	"tin_ore":      {"output": "tin_dust",      "byproduct": "iron_dust"},
	"gold_ore":     {"output": "gold_dust",     "byproduct": "copper_dust"},
	"silver_ore":   {"output": "silver_dust",   "byproduct": "lead_dust"},
	"titanium_ore": {"output": "titanium_dust", "byproduct": "platinum_dust"},
	"mythril_ore":  {"output": "mythril_dust",  "byproduct": "titanium_dust"},
}
const OUTPUT_COUNT := 2
const BYPRODUCT_COUNT := 1
const POWER_CONSUMPTION := 25.0
const PROCESS_TIME := 5.0

const SLOT_INPUT := 0
const SLOT_OUTPUT := 1
const SLOT_BYPRODUCT := 2

var process_timer: float = 0.0


func _init() -> void:
	machine_title = "MAGNETIC SEPARATOR"
	power_capacity = 250.0

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
		and _slot_fits(slots[SLOT_OUTPUT], str(recipe.get("output", "")), OUTPUT_COUNT)
		and _slot_fits(slots[SLOT_BYPRODUCT], str(recipe.get("byproduct", "")), BYPRODUCT_COUNT)
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
	_add_to_slot(SLOT_OUTPUT, str(recipe.get("output", "")), OUTPUT_COUNT)
	_add_to_slot(SLOT_BYPRODUCT, str(recipe.get("byproduct", "")), BYPRODUCT_COUNT)


func _add_to_slot(slot_idx: int, item_id: String, count: int) -> void:
	if not ItemDatabase.registry.has(item_id):
		push_error("MagneticSeparatorContainer: unknown item '%s'" % item_id)
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


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

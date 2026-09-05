extends PoweredMachineContainer
class_name PrimitiveCrusherContainer

## Hand-cranked tier-1 crusher. No electricity required, but slow (8 s).
## Electric crushers process the same recipes faster and with more slots.

const CRUSHER_RECIPES: Dictionary = {
	"iron_ore":    {"output": "iron_dust",          "output_count": 1, "input_count": 1},
	"copper_ore":  {"output": "copper_dust",        "output_count": 1, "input_count": 1},
	"coal":        {"output": "coal_dust",          "output_count": 1, "input_count": 1},
	"coke":        {"output": "coke_dust",          "output_count": 1, "input_count": 1},
	"stone":       {"output": "gravel",             "output_count": 1, "input_count": 1},
	"gravel":      {"output": "sand",               "output_count": 1, "input_count": 1},
}
const PROCESS_TIME := 8.0  # seconds (2× slower than electric crusher)

const SLOT_INPUT  := 0
const SLOT_OUTPUT := 1

var process_timer: float = 0.0


func _init() -> void:
	machine_title  = "PRIMITIVE CRUSHER"
	requires_power = false
	power_capacity = 0.0

	var s_in := MachineSlot.new()
	s_in.role   = MachineSlot.Role.INPUT
	s_in.filter = PackedStringArray(CRUSHER_RECIPES.keys())

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	slots = [s_in, s_out]


func tick(delta: float) -> void:
	var s_in:  MachineSlot = slots[SLOT_INPUT]
	var s_out: MachineSlot = slots[SLOT_OUTPUT]

	var in_id:  String     = s_in.item.get("id", "")
	var recipe: Dictionary = CRUSHER_RECIPES.get(in_id, {}) as Dictionary
	var in_need: int       = recipe.get("input_count", 1) as int

	var can_run: bool = (
		not s_in.is_empty()
		and not recipe.is_empty()
		and int(s_in.item.get("count", 0)) >= in_need
	)

	var output_blocked: bool = false
	if can_run and not s_out.is_empty():
		var out_id:  String = s_out.item.get("id", "")
		var out_add: int    = recipe.get("output_count", 1) as int
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

	var output_id:    String = recipe.get("output", "") as String
	var output_count: int    = recipe.get("output_count", 1) as int

	if not ItemDatabase.registry.has(output_id):
		push_error("PrimitiveCrusherContainer: unknown output item '%s'" % output_id)
		return

	if s_out.is_empty():
		s_out.item = ItemDatabase.create_existing_stack(output_id, output_count)
	else:
		s_out.item["count"] = int(s_out.item.get("count", 0)) + output_count
	slot_changed.emit(SLOT_OUTPUT)
	QuestManager.report_event("item_processed", output_id, output_count)


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

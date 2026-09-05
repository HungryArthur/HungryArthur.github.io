extends PoweredMachineContainer
class_name ElectricFurnaceContainer

## Early electric smelter balanced for one 40 EU/s starter grid.
const SMELT_RECIPES: Dictionary = {
	"iron_ore":           "iron_ingot",
	"copper_ore":         "copper_ingot",
	"gold_ore":           "gold_ingot",
	"silver_ore":         "silver_ingot",
	"tin_ore":            "tin_ingot",
	"mythril_ore":        "mythril_ingot",
	"titanium_ore":       "titanium_ingot",
	"uranium_raw":        "uranium_processed",
	"sand":               "glass",
	"resonite_shard":     "purified_resonite",
	"iron_dust":     "iron_ingot",
	"copper_dust":   "copper_ingot",
	"tin_dust":      "tin_ingot",
	"gold_dust":     "gold_ingot",
	"silver_dust":   "silver_ingot",
	"titanium_dust": "titanium_ingot",
	"mythril_dust":  "mythril_ingot",
	"bronze_dust":   "bronze_ingot",
}
const POWER_CONSUMPTION := 15.0  # EU/second
const PROCESS_TIME       := 2.0  # seconds

const SLOT_INPUT  := 0
const SLOT_OUTPUT := 1

var process_timer: float = 0.0
var source_grid_pos := Vector2i.ZERO
var facing: int = 2


func _init() -> void:
	machine_title = "ELECTRIC FURNACE"
	power_capacity = 150.0  # 10 s buffer at 15 EU/s

	var s_in := MachineSlot.new()
	s_in.role   = MachineSlot.Role.INPUT
	s_in.filter = PackedStringArray(SMELT_RECIPES.keys())

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	slots = [s_in, s_out]


func set_source_grid_pos(grid_pos: Vector2i) -> void:
	source_grid_pos = grid_pos


func set_facing(new_facing: int) -> void:
	facing = ((new_facing % 4) + 4) % 4


func tick(delta: float) -> void:
	eject_outputs_to(source_grid_pos, facing)
	var s_in:  MachineSlot = slots[SLOT_INPUT]
	var s_out: MachineSlot = slots[SLOT_OUTPUT]

	var in_id:     String = s_in.item.get("id", "")
	var result_id: String = SMELT_RECIPES.get(in_id, "") as String
	var can_run: bool = not s_in.is_empty() and not result_id.is_empty()

	var output_blocked: bool = false
	if can_run and not s_out.is_empty():
		var out_id: String = s_out.item.get("id", "")
		output_blocked = out_id != result_id \
			or int(s_out.item.get("count", 0)) >= int(s_out.item.get("max_stack", 64))

	processing_active = power_stored > 0.0 and can_run and not output_blocked

	if processing_active:
		power_stored = maxf(power_stored - POWER_CONSUMPTION * delta, 0.0)
		process_timer += delta
		if process_timer >= PROCESS_TIME:
			process_timer = 0.0
			_complete_smelt(s_in, s_out, result_id)
			eject_outputs_to(source_grid_pos, facing)
	else:
		process_timer = 0.0


func _complete_smelt(s_in: MachineSlot, s_out: MachineSlot, result_id: String) -> void:
	s_in.extract(1)
	slot_changed.emit(SLOT_INPUT)

	if not ItemDatabase.registry.has(result_id):
		push_error("ElectricFurnaceContainer: unknown result '%s'" % result_id)
		return

	if s_out.is_empty():
		s_out.item = ItemDatabase.create_existing_stack(result_id, 1)
	else:
		s_out.item["count"] = int(s_out.item.get("count", 0)) + 1
	slot_changed.emit(SLOT_OUTPUT)
	QuestManager.report_event("item_smelted", result_id, 1)


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

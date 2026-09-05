extends MachineContainer
class_name FurnaceContainer

const SMELT_RECIPES: Dictionary = {
	"iron_ore":          "iron_ingot",
	"copper_ore":        "copper_ingot",
	"gold_ore":          "gold_ingot",
	"silver_ore":        "silver_ingot",
	"tin_ore":           "tin_ingot",
	"mythril_ore":       "mythril_ingot",
	"titanium_ore":      "titanium_ingot",
	"sand":              "glass",
	"resonite_shard":   "purified_resonite",
	# Обычная металлическая пыль — единственная промежуточная форма руды.
	"iron_dust":     "iron_ingot",
	"copper_dust":   "copper_ingot",
	"tin_dust":      "tin_ingot",
	"gold_dust":     "gold_ingot",
	"silver_dust":   "silver_ingot",
	"titanium_dust": "titanium_ingot",
	"mythril_dust":  "mythril_ingot",
	"bronze_dust":   "bronze_ingot",
}
const FUEL_BURN_TIMES: Dictionary = {
	"coal": 5.0,
	"coke": 16.0,
	"coke_dust": 16.0,
}
const SMELT_TIME := 3.0

const SLOT_INPUT  := 0
const SLOT_FUEL   := 1
const SLOT_OUTPUT := 2

# Инстанс-копии таблиц: подклассы (примитивная домна) подменяют их в _init
# и перестраивают слоты через _build_slots().
var smelt_recipes: Dictionary = SMELT_RECIPES
var fuel_burn_times: Dictionary = FUEL_BURN_TIMES
var smelt_time: float = SMELT_TIME

var smelt_timer: float = 0.0
var fuel_remaining: float = 0.0
var is_smelting: bool = false


func _init() -> void:
	_build_slots()


func _build_slots() -> void:
	var input_slot := MachineSlot.new()
	input_slot.role = MachineSlot.Role.INPUT
	input_slot.filter = PackedStringArray(smelt_recipes.keys())

	var fuel_slot := MachineSlot.new()
	fuel_slot.role = MachineSlot.Role.FUEL
	fuel_slot.filter = PackedStringArray(fuel_burn_times.keys())

	var output_slot := MachineSlot.new()
	output_slot.role = MachineSlot.Role.OUTPUT

	slots = [input_slot, fuel_slot, output_slot]


func tick(delta: float) -> void:
	var s_in: MachineSlot  = slots[SLOT_INPUT]  as MachineSlot
	var s_fuel: MachineSlot = slots[SLOT_FUEL]  as MachineSlot
	var s_out: MachineSlot  = slots[SLOT_OUTPUT] as MachineSlot

	var in_id: String    = s_in.item.get("id", "")
	var result_id: String = smelt_recipes.get(in_id, "") as String
	var can_smelt: bool  = not s_in.is_empty() and smelt_recipes.has(in_id)

	var output_blocked: bool = false
	if can_smelt and not s_out.is_empty():
		var out_id: String = s_out.item.get("id", "")
		output_blocked = (out_id != result_id) \
			or (int(s_out.item.get("count", 0)) >= int(s_out.item.get("max_stack", 64)))

	if fuel_remaining > 0.0:
		fuel_remaining = maxf(fuel_remaining - delta, 0.0)

	# Ignite next fuel unit when current one runs out
	if fuel_remaining <= 0.0 and can_smelt and not output_blocked:
		if not s_fuel.is_empty():
			var fuel_id: String = s_fuel.item.get("id", "")
			var burn: float = fuel_burn_times.get(fuel_id, 0.0) as float
			if burn > 0.0:
				s_fuel.extract(1)
				slot_changed.emit(SLOT_FUEL)
				fuel_remaining = burn

	is_smelting = fuel_remaining > 0.0 and can_smelt and not output_blocked

	if is_smelting:
		smelt_timer += delta
		if smelt_timer >= smelt_time:
			smelt_timer = 0.0
			_complete_smelt(result_id)
	else:
		smelt_timer = 0.0


func _complete_smelt(result_id: String) -> void:
	(slots[SLOT_INPUT] as MachineSlot).extract(1)
	slot_changed.emit(SLOT_INPUT)

	if not ItemDatabase.registry.has(result_id):
		push_error("FurnaceContainer: unknown result '%s'" % result_id)
		return

	var s_out: MachineSlot = slots[SLOT_OUTPUT] as MachineSlot
	if s_out.is_empty():
		s_out.item = ItemDatabase.create_existing_stack(result_id, 1)
	else:
		s_out.item["count"] = int(s_out.item.get("count", 0)) + 1
	slot_changed.emit(SLOT_OUTPUT)
	QuestManager.report_event("item_smelted", result_id, 1)


# Progress values in [0, 1] for UI bars
func smelt_progress() -> float:
	return clampf(smelt_timer / smelt_time, 0.0, 1.0) if is_smelting else 0.0

func fuel_progress() -> float:
	var s_fuel: MachineSlot = slots[SLOT_FUEL] as MachineSlot
	var max_burn: float = 5.0
	if not s_fuel.is_empty():
		max_burn = fuel_burn_times.get(s_fuel.item.get("id", ""), 5.0) as float
	return clampf(fuel_remaining / max_burn, 0.0, 1.0) if max_burn > 0.0 else 0.0


func on_automation_blocked() -> void:
	is_smelting = false


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["smelt_timer"] = smelt_timer
	data["fuel_remaining"] = fuel_remaining
	return data

func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	smelt_timer = float(data.get("smelt_timer", 0.0))
	fuel_remaining = float(data.get("fuel_remaining", 0.0))

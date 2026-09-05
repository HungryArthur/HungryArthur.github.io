extends FluidMachineContainer
class_name OreMelterContainer

## Индукционная плавильня: руда / пыль / слитки -> жидкий металл в выходной
## бак (90 л = 1 слиток). Расплав уходит
## по жидкостным трубам в химический реактор (литьё) или смеситель (сплавы).

const INGOT_L := 90.0

## item_id -> {fluid, liters}
const MELT_RECIPES: Dictionary = {
	# Слитки
	"iron_ingot":     {"fluid": "molten_iron",     "liters": INGOT_L},
	"copper_ingot":   {"fluid": "molten_copper",   "liters": INGOT_L},
	"tin_ingot":      {"fluid": "molten_tin",      "liters": INGOT_L},
	"gold_ingot":     {"fluid": "molten_gold",     "liters": INGOT_L},
	"silver_ingot":   {"fluid": "molten_silver",   "liters": INGOT_L},
	"steel_ingot":    {"fluid": "molten_steel",    "liters": INGOT_L},
	"bronze_ingot":   {"fluid": "molten_bronze",   "liters": INGOT_L},
	"titanium_ingot": {"fluid": "molten_titanium", "liters": INGOT_L},
	"mythril_ingot":  {"fluid": "molten_mythril",  "liters": INGOT_L},
	"electrum_ingot": {"fluid": "molten_electrum", "liters": INGOT_L},
	# Руда и пыль (эквивалент одного слитка)
	"iron_ore":     {"fluid": "molten_iron",     "liters": INGOT_L},
	"copper_ore":   {"fluid": "molten_copper",   "liters": INGOT_L},
	"tin_ore":      {"fluid": "molten_tin",      "liters": INGOT_L},
	"gold_ore":     {"fluid": "molten_gold",     "liters": INGOT_L},
	"silver_ore":   {"fluid": "molten_silver",   "liters": INGOT_L},
	"titanium_ore": {"fluid": "molten_titanium", "liters": INGOT_L},
	"mythril_ore":  {"fluid": "molten_mythril",  "liters": INGOT_L},
	"iron_dust":     {"fluid": "molten_iron",     "liters": INGOT_L},
	"copper_dust":   {"fluid": "molten_copper",   "liters": INGOT_L},
	"tin_dust":      {"fluid": "molten_tin",      "liters": INGOT_L},
	"gold_dust":     {"fluid": "molten_gold",     "liters": INGOT_L},
	"silver_dust":   {"fluid": "molten_silver",   "liters": INGOT_L},
	"titanium_dust": {"fluid": "molten_titanium", "liters": INGOT_L},
	"mythril_dust":  {"fluid": "molten_mythril",  "liters": INGOT_L},
	"bronze_dust":   {"fluid": "molten_bronze",   "liters": INGOT_L},
}

const POWER_CONSUMPTION := 40.0
const PROCESS_TIME := 4.0
const TANK_CAPACITY := 540.0  # 6 слитков расплава

const SLOT_INPUT := 0
const SLOT_OUTPUT := 1  # не используется; нужен меню электромашины

var process_timer: float = 0.0


func _init() -> void:
	machine_title = "INDUCTION MELTER"
	power_capacity = 400.0
	output_tanks = [FluidTank.new(TANK_CAPACITY)]

	var s_in := MachineSlot.new()
	s_in.role = MachineSlot.Role.INPUT
	s_in.filter = PackedStringArray(MELT_RECIPES.keys())

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	slots = [s_in, s_out]


func tick(delta: float) -> void:
	var s_in: MachineSlot = slots[SLOT_INPUT]
	var recipe: Dictionary = MELT_RECIPES.get(s_in.item.get("id", ""), {}) as Dictionary
	var tank: FluidTank = output_tanks[0]

	var can_run: bool = (
		not s_in.is_empty()
		and not recipe.is_empty()
		and tank.space_for(str(recipe.get("fluid", ""))) >= float(recipe.get("liters", 0.0))
	)

	processing_active = power_stored > 0.0 and can_run

	if processing_active:
		power_stored = maxf(power_stored - POWER_CONSUMPTION * delta, 0.0)
		process_timer += delta
		if process_timer >= PROCESS_TIME:
			process_timer = 0.0
			s_in.extract(1)
			slot_changed.emit(SLOT_INPUT)
			tank.insert(str(recipe.get("fluid", "")), float(recipe.get("liters", 0.0)))
			fluid_changed.emit()
	else:
		process_timer = 0.0


## Плавильня ничего не принимает по трубам — только отдаёт расплав.
func can_accept_fluid(_fluid_id: String) -> bool:
	return false


func process_progress() -> float:
	return clampf(process_timer / PROCESS_TIME, 0.0, 1.0) if processing_active else 0.0


## Строка состояния для меню машин (уровень расплава в баке).
func status_text() -> String:
	var tank: FluidTank = output_tanks[0]
	if tank.amount <= 0.0:
		return "Tank Empty"
	return "%s: %.0f / %.0f L" % [
		FluidDatabase.get_display_name(tank.fluid_id), tank.amount, tank.capacity
	]


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

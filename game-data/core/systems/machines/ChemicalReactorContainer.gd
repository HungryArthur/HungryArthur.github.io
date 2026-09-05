extends FluidMachineContainer
class_name ChemicalReactorContainer

## Химический реактор: 1-2 жидкости + предмет -> новый предмет.
## Два режима:
##  * ЛИТЬЁ — расплав из плавильни + литейная форма (слот-катализатор, не
##    расходуется) -> пластины / стержни / провода / шестерни;
##  * ХИМИЯ — жидкость(и) + расходуемый предмет -> продукт (бетон, пластики...).
## Жидкости приходят по трубам в два входных бака.

## Рецепт: {item, item_count, catalyst, fluids: {id: liters}, output, output_count}.
## item == "" — предмет не нужен; catalyst == "" — форма не нужна.
const RECIPES: Array[Dictionary] = [
	# ── Литьё: пластины (90 л = 1 слиток) ──
	{"catalyst": "mold_plate", "fluids": {"molten_iron": 90.0},   "output": "iron_plate"},
	{"catalyst": "mold_plate", "fluids": {"molten_copper": 90.0}, "output": "copper_plate"},
	{"catalyst": "mold_plate", "fluids": {"molten_bronze": 90.0}, "output": "bronze_plate"},
	{"catalyst": "mold_plate", "fluids": {"molten_steel": 90.0},  "output": "steel_plate"},
	{"catalyst": "mold_plate", "fluids": {"molten_gold": 90.0},   "output": "gold_plate"},
	# ── Литьё: стержни (45 л = половина слитка, как 2 стержня из слитка) ──
	{"catalyst": "mold_rod", "fluids": {"molten_iron": 45.0},   "output": "iron_rod"},
	{"catalyst": "mold_rod", "fluids": {"molten_copper": 45.0}, "output": "copper_rod"},
	{"catalyst": "mold_rod", "fluids": {"molten_steel": 45.0},  "output": "steel_rod"},
	{"catalyst": "mold_rod", "fluids": {"molten_gold": 45.0},   "output": "gold_rod"},
	{"catalyst": "mold_rod", "fluids": {"molten_bronze": 45.0}, "output": "bronze_rod"},
	# ── Литьё: провода ──
	{"catalyst": "mold_wire", "fluids": {"molten_copper": 30.0},   "output": "copper_wire"},
	{"catalyst": "mold_wire", "fluids": {"molten_gold": 30.0},     "output": "gold_wire"},
	{"catalyst": "mold_wire", "fluids": {"molten_electrum": 45.0}, "output": "electrum_wire"},
	# ── Литьё: шестерни ──
	{"catalyst": "mold_gear", "fluids": {"molten_iron": 180.0},  "output": "gear"},
	{"catalyst": "mold_gear", "fluids": {"molten_bronze": 45.0}, "output": "small_bronze_gear"},
	{"catalyst": "mold_gear", "fluids": {"molten_steel": 45.0},  "output": "small_steel_gear"},
	# ── Химия: жидкость + предмет ──
	{"item": "gravel", "fluids": {"water": 25.0}, "output": "concrete", "output_count": 2},
	{"item": "plastic", "fluids": {"crude_oil": 50.0}, "output": "carbon_plastic"},
	{"item": "stone", "fluids": {"creosote": 20.0}, "output": "refractory_brick"},
	# Углехимия коксовой цепочки: пыль кокса + креозот -> углеволокно.
	{"item": "coke_dust", "fluids": {"creosote": 25.0}, "output": "carbon_fiber"},
	# Плотная железная пластина: сталь + вода закаляют железную пластину.
	{"item": "iron_plate", "fluids": {"molten_steel": 90.0, "water": 20.0},
		"output": "dense_iron_plate"},
]

const POWER_CONSUMPTION := 30.0
const PROCESS_TIME := 4.0
const TANK_CAPACITY := 200.0

const SLOT_INPUT := 0
const SLOT_OUTPUT := 1
const SLOT_CATALYST := 2  # в меню занимает место побочного слота

var process_timer: float = 0.0


func _init() -> void:
	machine_title = "CHEMICAL REACTOR"
	power_capacity = 300.0
	input_tanks = [FluidTank.new(TANK_CAPACITY), FluidTank.new(TANK_CAPACITY)]

	var s_in := MachineSlot.new()
	s_in.role = MachineSlot.Role.INPUT
	s_in.filter = _collect_ids("item")

	var s_out := MachineSlot.new()
	s_out.role = MachineSlot.Role.OUTPUT

	var s_cat := MachineSlot.new()
	s_cat.role = MachineSlot.Role.BUFFER
	s_cat.filter = _collect_ids("catalyst")
	s_cat.max_stack_override = 1

	slots = [s_in, s_out, s_cat]


func _collect_ids(key: String) -> PackedStringArray:
	var ids := PackedStringArray()
	for r: Dictionary in RECIPES:
		var id := str(r.get(key, ""))
		if id != "" and not ids.has(id):
			ids.append(id)
	return ids


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


## Первый рецепт, у которого совпали катализатор, предмет и жидкости,
## а выход помещается в слот.
func _find_recipe() -> Dictionary:
	var s_in: MachineSlot = slots[SLOT_INPUT]
	var s_cat: MachineSlot = slots[SLOT_CATALYST]
	for r: Dictionary in RECIPES:
		var need_cat := str(r.get("catalyst", ""))
		if need_cat != "" and s_cat.item.get("id", "") != need_cat:
			continue
		var need_item := str(r.get("item", ""))
		var need_count := int(r.get("item_count", 1))
		if need_item != "" and (s_in.item.get("id", "") != need_item
				or int(s_in.item.get("count", 0)) < need_count):
			continue
		if not _fluids_available(r.get("fluids", {}) as Dictionary):
			continue
		if not _slot_fits(slots[SLOT_OUTPUT], str(r.get("output", "")), int(r.get("output_count", 1))):
			continue
		return r
	return {}


func _fluids_available(fluids: Dictionary) -> bool:
	for fluid_id: String in fluids:
		var have := 0.0
		for tank: FluidTank in input_tanks:
			if tank.fluid_id == fluid_id:
				have += tank.amount
		if have < float(fluids[fluid_id]):
			return false
	return true


func _complete_process(recipe: Dictionary) -> void:
	var need_item := str(recipe.get("item", ""))
	if need_item != "":
		(slots[SLOT_INPUT] as MachineSlot).extract(int(recipe.get("item_count", 1)))
		slot_changed.emit(SLOT_INPUT)
	var fluids: Dictionary = recipe.get("fluids", {}) as Dictionary
	for fluid_id: String in fluids:
		var remaining := float(fluids[fluid_id])
		for tank: FluidTank in input_tanks:
			if tank.fluid_id == fluid_id:
				remaining -= tank.extract(remaining)
			if remaining <= 0.0001:
				break
	var output_id := str(recipe.get("output", ""))
	var output_count := int(recipe.get("output_count", 1))
	if not ItemDatabase.registry.has(output_id):
		push_error("ChemicalReactorContainer: unknown item '%s'" % output_id)
		return
	var s_out: MachineSlot = slots[SLOT_OUTPUT]
	if s_out.is_empty():
		s_out.item = ItemDatabase.create_existing_stack(output_id, output_count)
	else:
		s_out.item["count"] = int(s_out.item.get("count", 0)) + output_count
	slot_changed.emit(SLOT_OUTPUT)
	fluid_changed.emit()
	QuestManager.report_event("item_processed", output_id, output_count)


func _slot_fits(slot: MachineSlot, item_id: String, count: int) -> bool:
	if slot.is_empty():
		return true
	return slot.item.get("id", "") == item_id \
		and int(slot.item.get("count", 0)) + count <= int(slot.item.get("max_stack", 64))


## Один вид жидкости живёт ровно в одном баке: доливаем в свой, новую — только
## в пустой. Иначе вода заняла бы оба бака и рецепты с двумя жидкостями встали.
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


## Строка состояния для меню машин: содержимое входных баков.
func status_text() -> String:
	var parts: PackedStringArray = []
	for tank: FluidTank in input_tanks:
		if tank.amount > 0.0:
			parts.append("%s %.0f L" % [FluidDatabase.get_display_name(tank.fluid_id), tank.amount])
	if parts.is_empty():
		return "No Fluids"
	return " | ".join(parts)


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["process_timer"] = process_timer
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	process_timer = float(data.get("process_timer", 0.0))

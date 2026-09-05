extends FluidMachineContainer
class_name SteamBoilerContainer

## Паровой котёл: жжёт твёрдое топливо и кипятит воду в пар. Без электричества —
## источник энергии паровой эры. Пар уходит по жидкостным трубам
## (FluidNetworkManager) в паровые машины; вода подаётся насосом или ведром.
## Топливо горит только пока котёл реально кипятит (есть вода и место под пар).

const FUEL_BURN_TIME: Dictionary = {
	"coal": 8.0,
	"coal_dust": 8.0,
	"coke": 16.0,
	"coke_dust": 16.0,
	"compressed_coal": 64.0,
}
const STEAM_PER_SECOND := 4.0   # л/с пара; вода расходуется 1:1
const WATER_TANK_CAPACITY := 100.0
const STEAM_TANK_CAPACITY := 200.0
const HIGH_PRESSURE_STEAM_PER_SECOND := 12.0
const HIGH_PRESSURE_FUEL_BURN_RATE := 2.0
const HIGH_PRESSURE_WATER_TANK_CAPACITY := 300.0
const HIGH_PRESSURE_STEAM_TANK_CAPACITY := 600.0
const HIGH_PRESSURE_CREOSOTE_TANK_CAPACITY := 200.0
## Жидкое топливо: креозот из коксовой печи, 1 л = 2 с горения.
## Твёрдое топливо в слоте имеет приоритет; креозот — резерв.
const CREOSOTE_BURN_PER_LITER := 2.0
const CREOSOTE_TANK_CAPACITY := 100.0

const SLOT_FUEL := 0
const TANK_WATER := 0
const TANK_CREOSOTE := 1

var burn_time_remaining: float = 0.0
var burn_time_total: float = 0.0
var boiler_tier := 1
var steam_per_second := STEAM_PER_SECOND
var fuel_burn_rate := 1.0
var _quest_output_buffer := 0.0


func _init() -> void:
	requires_power = false
	power_capacity = 0.0
	var s_fuel := MachineSlot.new()
	s_fuel.role = MachineSlot.Role.FUEL
	s_fuel.filter = PackedStringArray(FUEL_BURN_TIME.keys())
	slots = [s_fuel]
	_configure_tier(1)


func set_block_id(block_id: String) -> void:
	_configure_tier(2 if block_id == "high_pressure_steam_boiler" else 1)


func _configure_tier(tier: int) -> void:
	boiler_tier = tier
	if boiler_tier >= 2:
		machine_title = "High-Pressure Steam Boiler"
		steam_per_second = HIGH_PRESSURE_STEAM_PER_SECOND
		fuel_burn_rate = HIGH_PRESSURE_FUEL_BURN_RATE
		input_tanks = [
			FluidTank.new(HIGH_PRESSURE_WATER_TANK_CAPACITY),
			FluidTank.new(HIGH_PRESSURE_CREOSOTE_TANK_CAPACITY),
		]
		output_tanks = [FluidTank.new(HIGH_PRESSURE_STEAM_TANK_CAPACITY)]
		return
	machine_title = "STEAM BOILER"
	steam_per_second = STEAM_PER_SECOND
	fuel_burn_rate = 1.0
	input_tanks = [
		FluidTank.new(WATER_TANK_CAPACITY),
		FluidTank.new(CREOSOTE_TANK_CAPACITY),
	]
	output_tanks = [FluidTank.new(STEAM_TANK_CAPACITY)]


func tick(delta: float) -> void:
	var water: FluidTank = input_tanks[TANK_WATER]
	var steam: FluidTank = output_tanks[0]
	var can_boil := water.amount > 0.0 and steam.space_for("steam") > 0.0

	if burn_time_remaining <= 0.0 and can_boil:
		_consume_fuel()

	processing_active = burn_time_remaining > 0.0 and can_boil
	if not processing_active:
		return

	burn_time_remaining = maxf(burn_time_remaining - delta * fuel_burn_rate, 0.0)
	var produced := minf(
		steam_per_second * delta,
		minf(water.amount, steam.space_for("steam"))
	)
	if produced <= 0.0:
		return
	water.extract(produced)
	steam.insert("steam", produced)
	fluid_changed.emit()
	if boiler_tier >= 2:
		_report_high_pressure_output(produced)


func _report_high_pressure_output(produced: float) -> void:
	_quest_output_buffer += produced
	var whole_liters := floori(_quest_output_buffer)
	if whole_liters <= 0:
		return
	_quest_output_buffer -= whole_liters
	QuestManager.report_event("fluid_produced", "high_pressure_steam", whole_liters)


func is_burning() -> bool:
	return burn_time_remaining > 0.0


func burn_progress() -> float:
	if burn_time_total <= 0.0:
		return 0.0
	return clampf(burn_time_remaining / burn_time_total, 0.0, 1.0)


func process_progress() -> float:
	return output_tanks[0].fill_ratio()


## Котёл принимает по трубам воду (в водяной бак) и креозот (в топливный).
## Роутим вручную, чтобы вода не заняла пустой креозотный бак и наоборот.
func can_accept_fluid(fluid_id: String) -> bool:
	match fluid_id:
		"water":
			return input_tanks[TANK_WATER].space_for("water") > 0.0
		"creosote":
			return input_tanks[TANK_CREOSOTE].space_for("creosote") > 0.0
	return false


func push_fluid(fluid_id: String, liters: float) -> float:
	var tank_index := -1
	match fluid_id:
		"water":
			tank_index = TANK_WATER
		"creosote":
			tank_index = TANK_CREOSOTE
	if tank_index < 0:
		return 0.0
	var accepted := input_tanks[tank_index].insert(fluid_id, liters)
	if accepted > 0.0:
		fluid_changed.emit()
	return accepted


func fluid_input_priority(fluid_id: String) -> int:
	return adjusted_input_priority(150) if can_accept_fluid(fluid_id) else -1


## Твёрдое топливо из слота в приоритете; кончилось — жжём креозот из бака.
func _consume_fuel() -> void:
	var s_fuel: MachineSlot = slots[SLOT_FUEL]
	if not s_fuel.is_empty():
		var fuel_id: String = s_fuel.item.get("id", "")
		var burn: float = float(FUEL_BURN_TIME.get(fuel_id, 0.0))
		if burn > 0.0:
			s_fuel.extract(1)
			slot_changed.emit(SLOT_FUEL)
			burn_time_remaining = burn
			burn_time_total = burn
			return
	var creosote: FluidTank = input_tanks[TANK_CREOSOTE]
	if creosote.amount >= 1.0:
		creosote.extract(1.0)
		fluid_changed.emit()
		QuestManager.report_event("fluid_burned", "creosote", 1)
		burn_time_remaining = CREOSOTE_BURN_PER_LITER
		burn_time_total = CREOSOTE_BURN_PER_LITER


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["burn_time_remaining"] = burn_time_remaining
	data["burn_time_total"] = burn_time_total
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	burn_time_remaining = float(data.get("burn_time_remaining", 0.0))
	burn_time_total = float(data.get("burn_time_total", 0.0))

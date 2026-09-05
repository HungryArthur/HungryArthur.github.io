extends GeneratorContainer
class_name CoalGeneratorContainer

## Burns solid fuel to generate EU. Only burns while its network has demand
## (PowerNetworkManager calls produce(delta) only when consumers need power).

const EU_PER_SECOND := 40.0

## Fuel item id → seconds of burn time per item.
const FUEL_BURN_TIME: Dictionary = {
	"coal":      10.0,
	"coal_dust": 10.0,
	"coke":      20.0,
	"coke_dust": 20.0,
	"coal_block": 90.0,
}

const SLOT_FUEL := 0

var burn_time_remaining: float = 0.0
var burn_time_total: float = 0.0


func _init() -> void:
	machine_title = "COAL GENERATOR"
	eu_per_second = EU_PER_SECOND

	var s_fuel := MachineSlot.new()
	s_fuel.role   = MachineSlot.Role.FUEL
	s_fuel.filter = PackedStringArray(FUEL_BURN_TIME.keys())
	slots = [s_fuel]


## Called by PowerNetworkManager when the network needs power.
func produce(delta: float, _demand: float = INF) -> float:
	# Refuel if needed.
	if burn_time_remaining <= 0.0:
		if not _consume_fuel():
			eu_delivered_last_tick = 0.0
			return 0.0

	var burn := minf(delta, burn_time_remaining)
	burn_time_remaining -= burn
	return eu_per_second * burn


func is_burning() -> bool:
	return burn_time_remaining > 0.0


func burn_progress() -> float:
	if burn_time_total <= 0.0:
		return 0.0
	return clampf(burn_time_remaining / burn_time_total, 0.0, 1.0)


func _consume_fuel() -> bool:
	var s_fuel: MachineSlot = slots[SLOT_FUEL]
	if s_fuel.is_empty():
		return false
	var fuel_id: String = s_fuel.item.get("id", "")
	var burn: float = float(FUEL_BURN_TIME.get(fuel_id, 0.0))
	if burn <= 0.0:
		return false
	s_fuel.extract(1)
	slot_changed.emit(SLOT_FUEL)
	burn_time_remaining = burn
	burn_time_total = burn
	return true


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["burn_time_remaining"] = burn_time_remaining
	data["burn_time_total"]     = burn_time_total
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	burn_time_remaining = float(data.get("burn_time_remaining", 0.0))
	burn_time_total     = float(data.get("burn_time_total", 0.0))

extends MachineContainer
class_name EnergyStorageContainer

## A grid energy buffer. The PowerNetworkManager charges it from surplus generation
## and discharges it to cover consumer deficits. `max_io` limits EU/s in or out.
var machine_title: String = "ENERGY STORAGE"
var stored: float = 0.0
var capacity: float = 40000.0
var max_io: float = 128.0           # max EU per second, each direction
var io_last_tick: float = 0.0       # +charging / -discharging this tick (UI stat)


func configure_tier(tier: int) -> void:
	match tier:
		1:
			machine_title = "ENERGY STORAGE T1"
			capacity = 40000.0
			max_io = 128.0
		2:
			machine_title = "ENERGY STORAGE T2"
			capacity = 200000.0
			max_io = 512.0
		3:
			machine_title = "ENERGY STORAGE T3"
			capacity = 1000000.0
			max_io = 2048.0
	stored = clampf(stored, 0.0, capacity)


## EU this buffer can still absorb this tick.
func charge_room(delta: float) -> float:
	return maxf(minf(max_io * delta, capacity - stored), 0.0)


## EU this buffer can still release this tick.
func discharge_room(delta: float) -> float:
	return maxf(minf(max_io * delta, stored), 0.0)


## Absorbs up to `eu` (already capped by the caller to charge_room). Returns taken.
func charge(eu: float, delta: float) -> float:
	var take := clampf(eu, 0.0, charge_room(delta))
	stored += take
	io_last_tick += take
	return take


## Releases up to `eu` (already capped by the caller). Returns supplied.
func discharge(eu: float, delta: float) -> float:
	var give := clampf(eu, 0.0, discharge_room(delta))
	stored -= give
	io_last_tick -= give
	return give


func fill_progress() -> float:
	return clampf(stored / capacity, 0.0, 1.0) if capacity > 0.0 else 0.0


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["stored"] = stored
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	stored = clampf(float(data.get("stored", 0.0)), 0.0, capacity)

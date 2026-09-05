extends GeneratorContainer
class_name SteamTurbineContainer

## Паровая турбина: пар -> EU. Мост между паровой эрой и электричеством —
## котлы остаются полезными после электрификации.
##
## Это генератор для PowerNetworkManager, поэтому пар она получает НЕ через
## жидкостную сеть, а сама тянет его из СОСЕДНИХ жидкостных машин (котёл или
## бак с паром вплотную) во внутренний буфер — как ME-интерфейс работает
## с соседней машиной.

const EU_PER_SECOND := 40.0
const EU_PER_LITER := 10.0            # 4 л/с пара при полной нагрузке
const INTAKE_RATE := 8.0              # л/с всасывания из соседей
const BUFFER_CAPACITY := 100.0

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]

var steam_tank := FluidTank.new(BUFFER_CAPACITY)
var source_grid_pos: Vector2i = Vector2i.ZERO


func _init() -> void:
	machine_title = "STEAM TURBINE"
	eu_per_second = EU_PER_SECOND
	slots = []


func set_source_grid_pos(grid_pos: Vector2i) -> void:
	source_grid_pos = grid_pos


## Каждый тик добираем пар из соседних жидкостных машин в буфер.
func tick(delta: float) -> void:
	var need := minf(INTAKE_RATE * delta, steam_tank.space_for("steam"))
	if need <= 0.0:
		return
	var wim: Node = get_tree().get_first_node_in_group("world_interaction")
	if wim == null or not wim.has_method("get_block_at"):
		return
	for dir: Vector2i in DIRS:
		if need <= 0.0001:
			break
		var nb: WorldBlock = wim.get_block_at(source_grid_pos + dir) as WorldBlock
		if nb == null or not (nb.machine is FluidMachineContainer):
			continue
		var neighbor := nb.machine as FluidMachineContainer
		var got := neighbor.pull_fluid("steam", need)
		if got > 0.0:
			steam_tank.insert("steam", got)
			need -= got


## Вызывается PowerNetworkManager, когда сети нужна энергия.
func produce(delta: float, demand: float = INF) -> float:
	var max_eu := minf(eu_per_second * delta, demand)
	var eu := minf(max_eu, steam_tank.amount * EU_PER_LITER)
	if eu <= 0.0:
		return 0.0
	steam_tank.extract(eu / EU_PER_LITER)
	return eu


func has_steam() -> bool:
	return steam_tank.amount > 0.0


func steam_progress() -> float:
	return steam_tank.fill_ratio()


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["steam_tank"] = steam_tank.to_save_data()
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	var saved: Variant = data.get("steam_tank", {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		steam_tank.from_save_data(saved as Dictionary)

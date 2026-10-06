# res://core/autoloads/WeatherManager.gd
## Погода: ясно / дождь / гроза. Крутится по таймеру у хоста (или в одиночке),
## клиентам мультиплеера состояние приходит по RPC (и в world info при входе).
##
## Эффекты:
##  - визуал: капли и следы в координатах мира (гуще в грозу) + затемнение мира
##    через light_factor() (читает World._update_day_night);
##  - геймплей: солнечные панели вырабатывают меньше (solar_factor(),
##    читает SolarPanelContainer.tick).
extends Node

const WorldRain := preload("res://core/systems/world/WorldRain.gd")

signal weather_changed(new_state: int)

enum { CLEAR, RAIN, STORM }

# Длительности фаз (сек). Дождь заметно короче ясной погоды.
const CLEAR_MIN := 300.0
const CLEAR_MAX := 720.0
const RAIN_MIN := 90.0
const RAIN_MAX := 240.0
## Шанс, что вместо дождя придёт гроза.
const STORM_CHANCE := 0.25

const SOLAR_FACTORS := {CLEAR: 1.0, RAIN: 0.5, STORM: 0.25}
const LIGHT_FACTORS := {CLEAR: 1.0, RAIN: 0.82, STORM: 0.62}
const RAIN_AMOUNT := 260
const STORM_AMOUNT := 600

var state: int = CLEAR

var _time_left := 0.0
var _rng := RandomNumberGenerator.new()
var _rain: Node2D = null
var _check_accum := 0.0


func _ready() -> void:
	_rng.randomize()
	# Первая смена погоды наступает раньше обычного цикла, чтобы новый мир
	# не ждал дождя десять минут.
	_time_left = _rng.randf_range(CLEAR_MIN, CLEAR_MAX) * 0.5
	MultiplayerManager.weather_sync_received.connect(apply_net_state)


func _process(delta: float) -> void:
	# Мир владеет эффектом и удаляет его при выходе в меню.
	_check_accum += delta
	if _check_accum >= 0.5:
		_check_accum = 0.0
		_update_rain()

	# Погоду двигает только хост/одиночка; клиент ждёт RPC.
	if MultiplayerManager.is_client():
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_advance()


func _advance() -> void:
	if state == CLEAR:
		state = STORM if _rng.randf() < STORM_CHANCE else RAIN
		_time_left = _rng.randf_range(RAIN_MIN, RAIN_MAX)
	else:
		state = CLEAR
		_time_left = _rng.randf_range(CLEAR_MIN, CLEAR_MAX)
	_on_state_changed()
	MultiplayerManager.broadcast_weather(state)


## Применяет состояние, пришедшее по сети (RPC хоста или world info при входе).
func apply_net_state(new_state: int) -> void:
	if new_state == state:
		return
	state = clampi(new_state, CLEAR, STORM)
	_on_state_changed()


func _on_state_changed() -> void:
	weather_changed.emit(state)
	_update_rain()


## Множитель выработки солнечных панелей при текущей погоде.
func solar_factor() -> float:
	return float(SOLAR_FACTORS.get(state, 1.0))


## Множитель освещённости мира (умножается на дневной свет TimeManager).
func light_factor() -> float:
	return float(LIGHT_FACTORS.get(state, 1.0))


func is_raining() -> bool:
	return state != CLEAR


# ── Дождь в мире ────────────────────────────────────────────────────────────

func _update_rain() -> void:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if not is_instance_valid(world):
		if is_instance_valid(_rain):
			_rain.queue_free()
		_rain = null
		return
	if is_instance_valid(_rain) and _rain.get_parent() != world:
		_rain.queue_free()
		_rain = null
	if not is_instance_valid(_rain):
		if not is_raining():
			return
		_rain = WorldRain.new()
		_rain.name = "WeatherRain"
		world.add_child(_rain)
	# При прояснении уже летящие капли долетают, а следы успевают исчезнуть.
	_rain.set_weather(is_raining(), state == STORM, STORM_AMOUNT if state == STORM else RAIN_AMOUNT)

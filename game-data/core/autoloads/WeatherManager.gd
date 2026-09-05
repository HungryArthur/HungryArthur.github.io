# res://core/autoloads/WeatherManager.gd
## Погода: ясно / дождь / гроза. Крутится по таймеру у хоста (или в одиночке),
## клиентам мультиплеера состояние приходит по RPC (и в world info при входе).
##
## Эффекты:
##  - визуал: экранный слой дождевых частиц (гуще в грозу) + затемнение мира
##    через light_factor() (читает World._update_day_night);
##  - геймплей: солнечные панели вырабатывают меньше (solar_factor(),
##    читает SolarPanelContainer.tick).
extends Node

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
var _overlay: CanvasLayer = null
var _rain: CPUParticles2D = null
var _check_accum := 0.0


func _ready() -> void:
	_rng.randomize()
	# Первая смена погоды наступает раньше обычного цикла, чтобы новый мир
	# не ждал дождя десять минут.
	_time_left = _rng.randf_range(CLEAR_MIN, CLEAR_MAX) * 0.5
	MultiplayerManager.weather_sync_received.connect(apply_net_state)


func _process(delta: float) -> void:
	# Видимость слоя дождя проверяем редко: мир мог смениться на меню.
	_check_accum += delta
	if _check_accum >= 0.5:
		_check_accum = 0.0
		_update_overlay()

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
	if _rain != null:
		_rain.amount = STORM_AMOUNT if state == STORM else RAIN_AMOUNT
		# Гроза — косой ливень, обычный дождь падает почти вертикально.
		_rain.direction = Vector2(0.22, 1.0) if state == STORM else Vector2(0.05, 1.0)
	_update_overlay()


## Множитель выработки солнечных панелей при текущей погоде.
func solar_factor() -> float:
	return float(SOLAR_FACTORS.get(state, 1.0))


## Множитель освещённости мира (умножается на дневной свет TimeManager).
func light_factor() -> float:
	return float(LIGHT_FACTORS.get(state, 1.0))


func is_raining() -> bool:
	return state != CLEAR


# ── Экранный слой дождя ──────────────────────────────────────────────────────

func _update_overlay() -> void:
	var in_world := get_tree().get_first_node_in_group("world") != null
	var should_show := in_world and is_raining()
	if not should_show:
		if _overlay != null:
			_overlay.visible = false
		return
	if _overlay == null:
		_build_overlay()
	_overlay.visible = true

	# Подгоняем эмиттер под текущий размер окна (мог измениться).
	var vp := get_viewport().get_visible_rect().size
	_rain.position = Vector2(vp.x * 0.5, -24.0)
	# Шире экрана: косой дождь должен долетать и из-за левого края.
	_rain.emission_rect_extents = Vector2(vp.x * 0.62 + 80.0, 8.0)
	_rain.lifetime = maxf(vp.y / 900.0 + 0.3, 0.6)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "WeatherOverlay"
	# Над миром, но ПОД интерфейсом: слой UI в Game.tscn = 50, дождь = 40.
	_overlay.layer = 40
	add_child(_overlay)

	_rain = CPUParticles2D.new()
	_rain.name = "Rain"
	_rain.amount = STORM_AMOUNT if state == STORM else RAIN_AMOUNT
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.direction = Vector2(0.05, 1.0)
	_rain.spread = 4.0
	_rain.gravity = Vector2.ZERO
	_rain.initial_velocity_min = 850.0
	_rain.initial_velocity_max = 1100.0
	_rain.scale_amount_min = 0.8
	_rain.scale_amount_max = 1.2
	_rain.texture = _make_drop_texture()
	_overlay.add_child(_rain)


## Тонкая вертикальная «капля-штрих» 2x12, полупрозрачная голубая.
func _make_drop_texture() -> ImageTexture:
	var img := Image.create(2, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.62, 0.72, 0.92, 0.55))
	return ImageTexture.create_from_image(img)

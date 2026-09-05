extends GeneratorContainer
class_name SolarPanelContainer

## Солнечная панель со встроенным буфером (стиль IC2): выработка всегда идёт
## во внутренний аккумулятор (BUFFER_SECONDS × номинал), даже когда к панели
## ничего не подключено. Сеть при спросе забирает энергию из буфера — ровно
## сколько нужно, без потерь. Тиры (Advanced/Elite/…) наследуют механику,
## меняя только eu_per_second.

const EU_PER_SECOND := 40.0
## Ёмкость буфера в секундах номинальной выработки.
const BUFFER_SECONDS := 30.0

var buffer_stored: float = 0.0


func _init() -> void:
	machine_title = "SOLAR PANEL"
	eu_per_second = EU_PER_SECOND
	slots = []


func buffer_capacity() -> float:
	return eu_per_second * BUFFER_SECONDS


## Панель копит в буфер каждый кадр — подключена она к сети или нет.
## В дождь/грозу выработка падает (WeatherManager.solar_factor).
func tick(delta: float) -> void:
	var rate: float = eu_per_second * WeatherManager.solar_factor()
	buffer_stored = minf(buffer_stored + rate * delta, buffer_capacity())


## Сеть забирает из буфера не больше, чем ей нужно в этот тик, — излишки
## остаются в панели, а не пропадают.
func produce(_delta: float, demand: float = INF) -> float:
	var give: float = minf(buffer_stored, maxf(demand, 0.0))
	buffer_stored -= give
	return give


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["buffer_stored"] = buffer_stored
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	buffer_stored = clampf(float(data.get("buffer_stored", 0.0)), 0.0, buffer_capacity())

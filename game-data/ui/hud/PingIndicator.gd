# res://ui/hud/PingIndicator.gd
## Пинг до хоста в углу экрана. Виден только клиенту мультиплеера;
## в одиночной игре и у хоста лейбл скрыт.
extends Label

const UPDATE_INTERVAL := 0.5
# Пороги подкраски: ниже GOOD_MS — зелёный, ниже WARN_MS — жёлтый, выше — красный.
const GOOD_MS := 60
const WARN_MS := 150

const COLOR_GOOD := Color(0.55, 0.95, 0.55)
const COLOR_WARN := Color(1.0, 0.85, 0.4)
const COLOR_BAD := Color(1.0, 0.45, 0.4)

var _accum := UPDATE_INTERVAL  # первый апдейт сразу


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(delta: float) -> void:
	_accum += delta
	if _accum < UPDATE_INTERVAL:
		return
	_accum = 0.0

	var ping := MultiplayerManager.get_ping_ms()
	visible = ping >= 0
	if not visible:
		return
	text = "Ping: %d ms" % ping
	var color := COLOR_GOOD
	if ping >= WARN_MS:
		color = COLOR_BAD
	elif ping >= GOOD_MS:
		color = COLOR_WARN
	add_theme_color_override("font_color", color)

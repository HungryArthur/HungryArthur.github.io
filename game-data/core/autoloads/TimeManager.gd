# res://core/autoloads/TimeManager.gd
# Drives the in-game clock and day/night cycle.
# Pace: 1 real second = 1 in-game minute, so a full 24h day lasts 24 real minutes.
extends Node

const MINUTES_PER_REAL_SECOND := 1.0
const MINUTES_PER_DAY := 24.0 * 60.0

## Current time of day in minutes since midnight (0 .. 1440). Starts at 08:00.
var minutes: float = 8.0 * 60.0

## Monotonic age of the current world in in-game minutes (never wraps). Persisted in
## the save and restored on load; drives deterministic crop growth (see CropData).
var world_age_minutes: float = 0.0


func _process(delta: float) -> void:
	minutes = fposmod(minutes + delta * MINUTES_PER_REAL_SECOND, MINUTES_PER_DAY)
	world_age_minutes += delta * MINUTES_PER_REAL_SECOND


func get_hours() -> int:
	return int(minutes / 60.0) % 24


func get_minutes() -> int:
	return int(minutes) % 60


func get_time_string() -> String:
	return "%02d:%02d" % [get_hours(), get_minutes()]


## 0.0 at midnight .. 1.0 at noon-and-back, used for clock fraction.
func get_day_fraction() -> float:
	return minutes / MINUTES_PER_DAY


## Daylight strength: 0.0 deep night, 1.0 full day, smoothly ramped at dawn/dusk.
func get_daylight() -> float:
	var hour: float = minutes / 60.0
	if hour < 5.0 or hour >= 21.0:
		return 0.0
	if hour < 8.0:
		return smoothstep(5.0, 8.0, hour)   # dawn
	if hour < 18.0:
		return 1.0                          # full day
	return 1.0 - smoothstep(18.0, 21.0, hour)  # dusk


func is_night() -> bool:
	return get_daylight() < 0.25

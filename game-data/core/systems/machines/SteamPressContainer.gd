extends SteamMachineContainer
class_name SteamPressContainer

## Паровой пресс: катает слитки в пластины выгоднее ручного крафта
## (1 слиток -> 2 пластины против 1:1 на верстаке).

const DEFAULT_RECIPES: Dictionary = {
	"copper_ingot": {"output": "copper_plate", "output_count": 2, "input_count": 1},
	"iron_ingot":   {"output": "iron_plate",   "output_count": 2, "input_count": 1},
	"bronze_ingot": {"output": "bronze_plate", "output_count": 2, "input_count": 1},
	"gold_ingot":   {"output": "gold_plate",   "output_count": 2, "input_count": 1},
	"steel_ingot":  {"output": "steel_plate",  "output_count": 2, "input_count": 1},
	"bronze_ring":  {"output": "pressure_valve",    "output_count": 1, "input_count": 2},
	"bronze_rod":   {"output": "steam_piston",      "output_count": 1, "input_count": 4},
	"bronze_rotor": {"output": "precision_flywheel", "output_count": 1, "input_count": 1},
}
static var PROCESS_TIME: float = GameTuning.number("machines", "steam_press", "PROCESS_TIME", 4.0)
static var STEAM_PER_SECOND: float = GameTuning.number("machines", "steam_press", "STEAM_PER_SECOND", 2.0)
func _init() -> void:
	configure("STEAM PRESS", RECIPES, PROCESS_TIME, STEAM_PER_SECOND)


static var RECIPES: Dictionary = GameTuning.recipe_map("steam_press", DEFAULT_RECIPES)

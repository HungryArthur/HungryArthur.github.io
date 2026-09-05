extends SteamMachineContainer
class_name SteamCrusherContainer

## Паровая дробилка: превращает руду сразу в пыль с удвоением выхода,
## но медленнее и на пару. Мостик между примитивной (×1) и электрической.

const RECIPES: Dictionary = {
	"iron_ore":     {"output": "iron_dust",     "output_count": 2, "input_count": 1},
	"copper_ore":   {"output": "copper_dust",   "output_count": 2, "input_count": 1},
	"tin_ore":      {"output": "tin_dust",      "output_count": 2, "input_count": 1},
	"gold_ore":     {"output": "gold_dust",     "output_count": 2, "input_count": 1},
	"lead_ore":     {"output": "lead_dust",     "output_count": 2, "input_count": 1},
	"nickel_ore":   {"output": "nickel_dust",   "output_count": 2, "input_count": 1},
	"platinum_ore": {"output": "platinum_dust", "output_count": 2, "input_count": 1},
	"titanium_ore": {"output": "titanium_dust", "output_count": 2, "input_count": 1},
	"mythril_ore":  {"output": "mythril_dust",  "output_count": 2, "input_count": 1},
	"coal":        {"output": "coal_dust",          "output_count": 1, "input_count": 1},
	"coke":        {"output": "coke_dust",          "output_count": 1, "input_count": 1},
	"stone":       {"output": "gravel",             "output_count": 1, "input_count": 1},
	"gravel":      {"output": "sand",               "output_count": 1, "input_count": 1},
	"silver_ore":  {"output": "silver_dust", "output_count": 2, "input_count": 1},
}
const PROCESS_TIME := 6.0
const STEAM_PER_SECOND := 2.0


func _init() -> void:
	configure("STEAM CRUSHER", RECIPES, PROCESS_TIME, STEAM_PER_SECOND)

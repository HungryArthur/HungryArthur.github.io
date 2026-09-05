extends SteamMachineContainer
class_name SteamFurnaceContainer

## Паровая печь: плавит то же, что каменная, но быстрее и без топлива в слоте —
## жар даёт пар из котла.

const RECIPES: Dictionary = {
	"iron_ore":           {"output": "iron_ingot",     "output_count": 1, "input_count": 1},
	"copper_ore":         {"output": "copper_ingot",   "output_count": 1, "input_count": 1},
	"gold_ore":           {"output": "gold_ingot",     "output_count": 1, "input_count": 1},
	"silver_ore":         {"output": "silver_ingot",   "output_count": 1, "input_count": 1},
	"tin_ore":            {"output": "tin_ingot",      "output_count": 1, "input_count": 1},
	"mythril_ore":        {"output": "mythril_ingot",  "output_count": 1, "input_count": 1},
	"titanium_ore":       {"output": "titanium_ingot", "output_count": 1, "input_count": 1},
	"sand":               {"output": "glass",          "output_count": 1, "input_count": 1},
	"resonite_shard":     {"output": "purified_resonite", "output_count": 1, "input_count": 1},
	"iron_dust":     {"output": "iron_ingot",     "output_count": 1, "input_count": 1},
	"copper_dust":   {"output": "copper_ingot",   "output_count": 1, "input_count": 1},
	"tin_dust":      {"output": "tin_ingot",      "output_count": 1, "input_count": 1},
	"gold_dust":     {"output": "gold_ingot",     "output_count": 1, "input_count": 1},
	"silver_dust":   {"output": "silver_ingot",   "output_count": 1, "input_count": 1},
	"titanium_dust": {"output": "titanium_ingot", "output_count": 1, "input_count": 1},
	"mythril_dust":  {"output": "mythril_ingot",  "output_count": 1, "input_count": 1},
	"bronze_dust":   {"output": "bronze_ingot",   "output_count": 1, "input_count": 1},
}
const PROCESS_TIME := 2.5
const STEAM_PER_SECOND := 2.0


func _init() -> void:
	configure("STEAM FURNACE", RECIPES, PROCESS_TIME, STEAM_PER_SECOND)


func _complete_process(s_in: MachineSlot, s_out: MachineSlot, recipe: Dictionary) -> void:
	super._complete_process(s_in, s_out, recipe)
	QuestManager.report_event("item_smelted", str(recipe.get("output", "")), 1)

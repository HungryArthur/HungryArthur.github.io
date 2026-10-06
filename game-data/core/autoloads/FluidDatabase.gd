extends Node

const FLUIDS: Dictionary = {
	"water": {"name": "Water", "color": Color(0.20, 0.58, 0.95)},
	"steam": {"name": "Steam", "color": Color(0.82, 0.86, 0.90)},
	"creosote": {"name": "Creosote", "color": Color(0.35, 0.24, 0.10)},
	"crude_oil": {"name": "Crude Oil", "color": Color(0.12, 0.09, 0.07)},
	"lava": {"name": "Lava", "color": Color(0.92, 0.36, 0.08)},
	"refinery_gas": {"name": "Refinery Gas", "color": Color(0.78, 0.88, 0.94)},
	"gasoline": {"name": "Gasoline", "color": Color(0.94, 0.76, 0.25)},
	"kerosene": {"name": "Kerosene", "color": Color(0.72, 0.83, 0.43)},
	"diesel": {"name": "Diesel", "color": Color(0.68, 0.48, 0.17)},
	"heavy_oil": {"name": "Heavy Fuel Oil", "color": Color(0.22, 0.15, 0.10)},
	"bitumen": {"name": "Bitumen", "color": Color(0.06, 0.06, 0.06)},
	# Расплавы металлов (индукционная плавильня). 90 л = 1 слиток.
	"molten_iron": {"name": "Molten Iron", "color": Color(0.86, 0.47, 0.34)},
	"molten_copper": {"name": "Molten Copper", "color": Color(0.92, 0.55, 0.28)},
	"molten_tin": {"name": "Molten Tin", "color": Color(0.80, 0.82, 0.86)},
	"molten_gold": {"name": "Molten Gold", "color": Color(0.98, 0.78, 0.25)},
	"molten_silver": {"name": "Molten Silver", "color": Color(0.86, 0.89, 0.93)},
	"molten_steel": {"name": "Molten Steel", "color": Color(0.62, 0.65, 0.70)},
	"molten_bronze": {"name": "Molten Bronze", "color": Color(0.82, 0.54, 0.26)},
	"molten_titanium": {"name": "Molten Titanium", "color": Color(0.72, 0.78, 0.86)},
	"molten_mythril": {"name": "Molten Mythril", "color": Color(0.46, 0.86, 0.80)},
	"molten_electrum": {"name": "Molten Electrum", "color": Color(0.93, 0.86, 0.46)},
	# Смеси (мультиблок-смеситель).
	"fuel_blend": {"name": "Fuel Blend", "color": Color(0.85, 0.55, 0.15)},
}

## Спрайты «ведро с водой»: id предмета -> текстура заполненного водой ведра.
const BUCKET_WATER_TEXTURES: Dictionary = {
	"iron_bucket": preload("res://assets/textures/items/fluids/iron_bucket_water.png"),
	"bronze_bucket": preload("res://assets/textures/items/fluids/bronze_bucket_water.png"),
}


func exists(fluid_id: String) -> bool:
	return FLUIDS.has(fluid_id)

func container_accepts(stack: Dictionary, fluid_id: String) -> bool:
	if not exists(fluid_id) or float(stack.get("fluid_capacity",0.0))<=0.0: return false
	var id := str(stack.get("id",""))
	if id == "fluid_capsule": return true
	if id=="pressure_cylinder": return fluid_id in ["steam","refinery_gas"]
	if id=="heatproof_canister" or id=="lava_canister": return fluid_id=="lava" or fluid_id.begins_with("molten_")
	if id=="empty_canister" or id=="crude_oil_canister": return fluid_id not in ["steam","refinery_gas","lava"] and not fluid_id.begins_with("molten_")
	if id=="primitive_bucket": return fluid_id=="water"
	if id in ["bronze_bucket","steel_bucket","iron_bucket"]: return fluid_id in ["water","creosote"]
	return false

func container_error(stack: Dictionary, fluid_id: String) -> String:
	if int(stack.get("count",1))!=1: return "Отдели одну ёмкость от стопки"
	if not container_accepts(stack,fluid_id):
		if fluid_id in ["steam","refinery_gas"]: return "Нужен герметичный баллон"
		if fluid_id=="lava" or fluid_id.begins_with("molten_"): return "Нужна жаростойкая ёмкость"
		return "Нужна подходящая канистра"
	var stored := str(stack.get("fluid_id",""))
	if not stored.is_empty() and stored!=fluid_id: return "В ёмкости другая жидкость"
	if float(stack.get("fluid_amount",0.0))>=float(stack.get("fluid_capacity",0.0)): return "Ёмкость заполнена"
	return ""


func get_display_name(fluid_id: String) -> String:
	var data: Dictionary = FLUIDS.get(fluid_id, {}) as Dictionary
	return tr(str(data.get("name", fluid_id.capitalize())))


func get_color(fluid_id: String) -> Color:
	var data: Dictionary = FLUIDS.get(fluid_id, {}) as Dictionary
	return data.get("color", Color.WHITE) as Color


func apply_bucket_display(stack: Dictionary) -> Dictionary:
	var result: Dictionary = stack.duplicate(true)
	var fluid_id := str(result.get("fluid_id", ""))
	var amount := float(result.get("fluid_amount", 0.0))
	var capacity := float(result.get("fluid_capacity", 0.0))
	# base_name/base_description хранят ключи (item.*.name/.desc) — резолвим их
	# в текущую локаль здесь, т.к. ниже они попадают в составные строки.
	var base_name := tr(str(result.get("base_name", result.get("name", "Bucket"))))
	var base_description := tr(str(
		result.get("base_description", result.get("description", "Liquid container."))
	))
	if fluid_id.is_empty() or amount <= 0.0:
		result["fluid_id"] = ""
		result["fluid_amount"] = 0.0
		result["name"] = base_name
		result["description"] = "%s Capacity: %.0f L." % [base_description, capacity]
		result["color"] = result.get("base_color", Color.WHITE)
		var item_res: Variant = result.get("resource")
		if item_res is ItemData:
			result["texture"] = (item_res as ItemData).texture
		return result
	if fluid_id == "water" and BUCKET_WATER_TEXTURES.has(str(result.get("id", ""))):
		result["texture"] = BUCKET_WATER_TEXTURES[str(result.get("id", ""))]
	result["name"] = "%s (%s)" % [base_name, get_display_name(fluid_id)]
	result["description"] = "%s %.1f / %.0f L." % [
		get_display_name(fluid_id), amount, capacity
	]
	result["color"] = get_color(fluid_id)
	return result

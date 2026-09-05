# res://core/systems/world/Chunk.gd
extends RefCounted
class_name Chunk

# Константа размера чанка (16х16 тайлов — идеальный стандарт для оптимизации)
const SIZE = 16 

# Позиция чанка в сетке чанков (например: Vector2i(0, 0) или Vector2i(-1, 4))
var position: Vector2i 

# Сетка тайлов ландшафта (земля, песок, вода)
# Ключ: Vector2i(local_x, local_y) в диапазоне от 0 до 15
# Значение: Vector2i(atlas_x, atlas_y) координаты тайла в твоем TileMap
var terrain_data: Dictionary = {}
var object_data: Dictionary = {}
var ore_state_data: Dictionary = {}
var fluid_deposit_data: Dictionary = {}
var fluid_state_data: Dictionary = {}
var placement_data: Dictionary = {}
var is_dirty: bool = false

func _init(chunk_pos: Vector2i) -> void:
	position = chunk_pos

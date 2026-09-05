extends Area2D
class_name DroppedItem

const MAGNET_RADIUS := 64.0
const PICKUP_RADIUS := 20.0
const MAGNET_SPEED := 220.0
const DEFAULT_PICKUP_DELAY := 0.35

var item_data: Dictionary = {}
var _player: Node2D = null
var _is_being_collected := false
var _pickup_delay: float = 0.0
var _wait_for_player_to_leave: bool = false

## Мультиплеер: сетевой id дропа ("peer_seq"). Пустой — чисто локальный дроп
## (одиночная игра). С id подбор идёт через подтверждение хоста, чтобы один
## предмет нельзя было поднять двум игрокам сразу.
var net_id := ""

@onready var _sprite: Sprite2D = $Sprite2D


func setup(
	stack: Dictionary,
	world_pos: Vector2,
	impulse: Vector2 = Vector2.ZERO,
	pickup_delay: float = DEFAULT_PICKUP_DELAY,
	wait_for_player_to_leave: bool = false
) -> void:
	item_data = stack.duplicate(true)
	global_position = world_pos
	_pickup_delay = pickup_delay
	_wait_for_player_to_leave = wait_for_player_to_leave
	_apply_visual()

	# Небольшой разлёт при выбросе
	if impulse != Vector2.ZERO:
		var tween := create_tween()
		tween.tween_property(self, "global_position", world_pos + impulse, 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _ready() -> void:
	add_to_group("dropped_items")
	collision_layer = CollisionLayers.DROPPED_ITEMS
	collision_mask = CollisionLayers.DROPPED_ITEMS_MASK
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	# Nearby drops are pulled into the player before attempting pickup.
	if _is_being_collected or item_data.is_empty():
		return
	if _pickup_delay > 0.0:
		_pickup_delay = maxf(_pickup_delay - delta, 0.0)
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	if _wait_for_player_to_leave:
		if dist > MAGNET_RADIUS:
			_wait_for_player_to_leave = false
		return

	if dist <= PICKUP_RADIUS:
		_try_pickup()
	elif dist <= MAGNET_RADIUS:
		global_position += to_player.normalized() * MAGNET_SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_try_pickup()


func _try_pickup() -> void:
	# Pickup respects stack limits by keeping leftovers on the ground.
	if _is_being_collected or item_data.is_empty():
		return
	if _pickup_delay > 0.0 or _wait_for_player_to_leave:
		return
	_is_being_collected = true

	# Сетевой дроп: замираем и просим хост. Ответ придёт через NetSync —
	# network_finish_pickup (нам) либо network_despawn (успел другой игрок).
	if not net_id.is_empty() and MultiplayerManager.is_active():
		MultiplayerManager.request_drop_pickup(net_id)
		return

	var leftovers: Variant = _insert_into_inventories(item_data)
	if leftovers == null or leftovers.get("count", 0) <= 0:
		AudioManager.play_sfx("player_pickup")
		queue_free()
	else:
		item_data = leftovers
		_is_being_collected = false
		_apply_visual()


## Хост подтвердил подбор нам: кладём в инвентарь. Невлезший остаток
## перевыбрасывается НОВЫМ сетевым дропом (старый id уже погашен арбитром).
func network_finish_pickup() -> void:
	var leftovers: Variant = _insert_into_inventories(item_data)
	if leftovers is Dictionary and int(leftovers.get("count", 0)) > 0:
		var wim: Variant = get_tree().get_first_node_in_group("world_interaction")
		if wim != null and wim.has_method("respawn_leftover_drop"):
			wim.respawn_leftover_drop(leftovers, global_position)
	queue_free()


## Дроп достался другому игроку (или неизвестен хосту) — просто убираем копию.
func network_despawn() -> void:
	queue_free()


func _insert_into_inventories(stack: Dictionary) -> Variant:
	var remaining: Variant = stack
	var hotbar: Node = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar and hotbar.has_method("auto_insert_item"):
		remaining = hotbar.auto_insert_item(remaining)
		if remaining == null or int(remaining.get("count", 0)) <= 0:
			return null

	var inventory: Node = get_tree().get_first_node_in_group("inventory_ui")
	if inventory and inventory.has_method("auto_insert_item"):
		return inventory.auto_insert_item(remaining)

	return remaining


func _apply_visual() -> void:
	if item_data.has("texture") and item_data["texture"]:
		_sprite.texture = item_data["texture"]
		_sprite.modulate = Color.WHITE
	elif item_data.has("color"):
		_sprite.texture = PlaceholderTexture2D.new()
		_sprite.modulate = item_data["color"]
	else:
		_sprite.texture = PlaceholderTexture2D.new()
		_sprite.modulate = Color(0.85, 0.85, 0.85, 1.0)

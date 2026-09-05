extends CharacterBody2D
class_name Player

enum { DOWN, UP, LEFT, RIGHT }

@onready var anim = $AnimatedSprite2D

## Movement multiplier while wading through swamp water pools.
const SWAMP_SPEED_MULT := 0.45

## Hard-biome exposure: rises while standing in a hazard without the matching suit,
## recovers when safe/protected, and ejects the player at 100. See HazardConfig.
const EXPOSURE_MAX := 100.0
const EXPOSURE_RECOVER := 22.0      # points/sec drained when safe or protected
const EXPOSURE_EJECT_RESET := 55.0  # exposure left right after an eject

## Player health. No damage source exists yet (bosses/enemies come later); combat
## death respawns at the base spawn with loot intact (pure factory: no item loss).
const MAX_HEALTH := 100.0
const STARVATION_MIN_HEALTH := 1.0

## Hunger/satiety survival stat. Drains slowly over time; eating food refills it.
## Below HUNGER_LOW the player slows down; at 0 hunger starvation ticks HP damage.
const MAX_HUNGER := 100.0
const HUNGER_DRAIN := 0.15          # hunger points drained per second
const HUNGER_LOW := 20.0            # below this the player moves slower
const HUNGER_SLOW_MULT := 0.6       # speed multiplier while starving-hungry
const STARVE_DAMAGE_PER_SEC := 2.0  # HP/sec lost while hunger is empty

## Melee (sword) attack: a frontal cone that damages + knocks back "hittable"
## targets (future bosses implement take_hit(damage, knockback)). Tunable here.
## Swing tempo comes from ToolTierSystem.swing_interval(power) — the same rhythm the
## mining/breaking swings use, so hitting a mob and hitting a rock feel like one verb.
const ATTACK_REACH := 46.0
const ATTACK_CONE_DOT := 0.25            # frontal cone width (dot(facing, toTarget))
const ATTACK_DAMAGE_PER_POWER := 8.0     # damage = weapon power × this
const ATTACK_KNOCKBACK := 240.0          # knockback impulse handed to the target
const ATTACK_RECOIL := 130.0             # backward self-recoil (kick) on the player
const RECOIL_FRICTION := 900.0           # how fast the self-recoil decays
## Attack animation lock (sec): keep the swing anim playing this long uninterrupted.
## Slightly under the fastest swing interval so the clip never eats the next swing.
const ATTACK_ANIM_TIME := 0.3

const DASH_SPEED := 540.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 0.85
const DASH_INVULNERABILITY := 0.18

const SPEAR_REACH := 104.0
const SPEAR_CONE_DOT := 0.70
const HAMMER_REACH := 62.0
const HAMMER_CONE_DOT := -0.35
const WAND_PROJECTILE_SCRIPT := preload("res://entities/combat/ArcaneBolt.gd")

## Animated sprite sheet: player.png is a 6×10 grid of 32×32 cells. Rows map to
## animations (edit here if a row is off). Built into SpriteFrames in _ready.
const SHEET_PATH := "res://entities/player/player.png"
## User-authored SpriteFrames (made in the Godot editor). Loaded if present; the
## code-built frames from SHEET_PATH are the fallback if it isn't saved yet.
const FRAMES_PATH := "res://assets/textures/entities/player.tres"
const SHEET_CELL := 32
# Row index per animation. Walk/run rows have 6 frames; attack/death have 4.
const ROW_WALK_DOWN := 0
const ROW_WALK_SIDE := 1     # faces right by default; flipped for left
const ROW_WALK_UP := 2
const ROW_RUN_DOWN := 3
const ROW_RUN_SIDE := 4
const ROW_RUN_UP := 5
const ROW_ATK_SIDE := 6     # attack group is ordered SIDE, DOWN, UP (unlike walk/run)
const ROW_ATK_DOWN := 7
const ROW_ATK_UP := 8
const ROW_DEATH := 9

## Emitted every physics frame so the HUD can show the exposure bar. `hazard` is the
## current HazardConfig descriptor, or {} when safe.
signal exposure_changed(value: float, hazard: Dictionary)
## Emitted whenever HP changes (damage / heal / respawn); drives the HUD health bar.
signal health_changed(current: float, maximum: float)
## Emitted whenever hunger changes (drain / eating / load); drives the HUD hunger bar.
signal hunger_changed(current: float, maximum: float)

var speed := GameConstants.WALK_SPEED
var idle_dir = DOWN
var _world: Node = null

## Мультиплеер: пупет — копия ЧУЖОГО игрока на этой машине. Управляется не
## вводом, а состоянием из сети (apply_network_state). Выставляется NetSync
## ДО add_child, чтобы _ready сразу знал режим.
var is_puppet := false
## Дистанция, дальше которой пупет телепортируется вместо плавного догона.
const PUPPET_SNAP_DIST := 128.0
const PUPPET_LERP_RATE := 14.0
var _net_target_pos := Vector2.ZERO
var _net_frame := 0

var exposure := 0.0
var _last_safe_position := Vector2.ZERO

var health := MAX_HEALTH
var max_health := MAX_HEALTH
var hunger := MAX_HUNGER
var max_hunger := MAX_HUNGER
var _starve_accum := 0.0   # accumulates starvation time so damage lands ~1/sec
var _spawn_position := Vector2.ZERO
var _attack_cooldown := 0.0
var _recoil_velocity := Vector2.ZERO
var _is_dead := false
var _attack_anim_until := 0   # msec; while Time.get_ticks_msec() < this, keep the swing anim
var _tool_action_type := ""   # "pickaxe"/"axe" while mining/harvesting; "" when idle
var _dash_direction := Vector2.DOWN
var _dash_time := 0.0
var _dash_cooldown := 0.0
var _damage_invulnerable_until := 0
var _equipment_bonuses: Dictionary = EquipmentBonusSystem.ZERO.duplicate(true)


func _ready() -> void:
	if is_puppet:
		_setup_puppet()
	else:
		add_to_group("player")
		GameData.player = self
		collision_layer = CollisionLayers.PLAYER
		collision_mask = CollisionLayers.PLAYER_MASK
	y_sort_enabled = true
	anim.position = Vector2(0, -16)
	_last_safe_position = global_position
	# The new sheet bakes its own shadow, so skip the code-drawn one.
	# Prefer the user-authored SpriteFrames; fall back to code-built, then old look.
	var frames: SpriteFrames = null
	if ResourceLoader.exists(FRAMES_PATH):
		frames = load(FRAMES_PATH) as SpriteFrames
	if frames == null:
		frames = _build_sprite_frames()
	if frames != null:
		# One-shot anims are authored with loop=1; disable so `death` (rip) can
		# finish and swings don't loop.
		for one_shot: String in ["rip", "sword_down", "sword_font", "sword_up"]:
			if frames.has_animation(one_shot):
				frames.set_animation_loop(one_shot, false)
		anim.sprite_frames = frames
		_play("idle_down", ["idle_font", "down"])
	else:
		_add_shadow()  # fallback: texture not imported yet, keep old look
	health_changed.emit(health, max_health)
	hunger_changed.emit(hunger, max_hunger)
	call_deferred("refresh_equipment_bonuses")


## Пупет: без камеры, без HUD-нод, без коллизий и без записи в GameData.
## Оставляем только тело со спрайтом, которым двигает сеть.
func _setup_puppet() -> void:
	add_to_group("remote_player")
	collision_layer = 0
	collision_mask = 0
	_net_target_pos = global_position
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam != null:
		cam.enabled = false
	var canvas: Node = get_node_or_null("CanvasLayer")
	if canvas != null:
		canvas.queue_free()
	var inv: Node = get_node_or_null("InventoryComponent")
	if inv != null:
		inv.queue_free()


## Soft contact shadow under the feet so the player reads as standing on ground.
func _add_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.22)
	shadow.z_index = -1
	shadow.position = Vector2(0, -2)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * 9.0, sin(a) * 3.5))
	shadow.polygon = pts
	add_child(shadow)


func _physics_process(delta: float) -> void:
	if is_puppet:
		_puppet_physics(delta)
		return
	_local_physics(delta)
	if MultiplayerManager.is_active():
		_broadcast_state()


func _local_physics(delta: float) -> void:
	_update_exposure(delta)
	_update_hunger(delta)
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _dash_cooldown > 0.0:
		_dash_cooldown = maxf(0.0, _dash_cooldown - delta)

	if _is_dead:
		velocity = Vector2.ZERO
		return  # death animation plays; movement/input frozen until respawn

	if GameChat.is_blocking_input():
		velocity = Vector2.ZERO
		if Time.get_ticks_msec() >= _attack_anim_until:
			_idle()
		return

	_update_speed()
	var direction = Input.get_vector("left", "right", "up", "down")
	if _dash_time <= 0.0 and Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0:
		_start_dash(direction)
	if _dash_time > 0.0:
		_dash_time = maxf(0.0, _dash_time - delta)
		velocity = _dash_direction * DASH_SPEED
		_face(_dash_direction)
		_play_move_anim()
		move_and_slide()
		return
	var attacking: bool = Time.get_ticks_msec() < _attack_anim_until

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		_face(direction)
		if not attacking:
			_play_move_anim()
	else:
		velocity = Vector2.ZERO
		if not attacking:
			# While mining/harvesting and standing still, keep the tool swing looping
			# (re-issuing the same anim doesn't restart it) instead of idling.
			if _tool_action_type != "":
				_play_tool_anim()
			else:
				_idle()

	# Sword self-recoil ("отдача"): kicks the player back on a swing, decaying each
	# frame and layered on top of normal movement.
	if _recoil_velocity.length() > 1.0:
		velocity += _recoil_velocity
		_recoil_velocity = _recoil_velocity.move_toward(Vector2.ZERO, RECOIL_FRICTION * delta)

	move_and_slide()


## Пупет плавно догоняет последнюю сетевую позицию; большие рывки (телепорт,
## потерянные пакеты) применяются мгновенно, чтобы не «размазывать» спрайт.
func _puppet_physics(delta: float) -> void:
	var distance := global_position.distance_to(_net_target_pos)
	if distance > PUPPET_SNAP_DIST:
		global_position = _net_target_pos
		reset_physics_interpolation()
	elif distance > 0.5:
		global_position = global_position.lerp(_net_target_pos, minf(1.0, PUPPET_LERP_RATE * delta))


## Локальный игрок раз в 2 физ. кадра (~30 Гц) рассылает своё состояние.
func _broadcast_state() -> void:
	_net_frame += 1
	if _net_frame % 2 != 0:
		return
	MultiplayerManager.send_player_state({
		"p": global_position,
		"a": String(anim.animation),
		"f": anim.flip_h,
		"s": anim.speed_scale,
	})


## Применяет сетевое состояние к пупету (позиция — целью для лерпа, анимация —
## сразу). Неизвестные анимации молча игнорируются.
func apply_network_state(state: Dictionary) -> void:
	var pos: Variant = state.get("p")
	if pos is Vector2:
		_net_target_pos = pos
	if anim == null or anim.sprite_frames == null:
		return
	anim.flip_h = bool(state.get("f", anim.flip_h))
	anim.speed_scale = float(state.get("s", anim.speed_scale))
	var anim_name := str(state.get("a", ""))
	if not anim_name.is_empty() and anim.sprite_frames.has_animation(anim_name) and String(anim.animation) != anim_name:
		anim.play(anim_name)


func _update_speed() -> void:
	speed = GameConstants.RUN_SPEED if Input.is_action_pressed("run") else GameConstants.WALK_SPEED
	speed *= 1.0 + float(_equipment_bonuses.get("move_speed", 0.0))
	if _is_on_swamp_water():
		speed *= SWAMP_SPEED_MULT
	# Being hungry saps stamina: below the low threshold the player trudges along.
	if hunger < HUNGER_LOW:
		speed *= HUNGER_SLOW_MULT


## Drains hunger over time. While hunger sits at 0 the player starves, losing HP at
## a steady rate until they eat (but never below 1 HP). Refilled by
## eating food (see add_hunger / WorldInteractionManager._try_use_item).
func _update_hunger(delta: float) -> void:
	if _is_dead:
		return
	if hunger > 0.0:
		hunger = maxf(0.0, hunger - HUNGER_DRAIN * delta)
		hunger_changed.emit(hunger, max_hunger)
		_starve_accum = 0.0
		return
	# Empty: accumulate time and apply starvation damage once per whole second.
	_starve_accum += delta
	if _starve_accum >= 1.0:
		var seconds: int = int(_starve_accum)
		_starve_accum -= float(seconds)
		take_starvation_damage(STARVE_DAMAGE_PER_SEC * float(seconds))


func _is_on_swamp_water() -> bool:
	if _world == null or not is_instance_valid(_world):
		_world = get_tree().get_first_node_in_group("world")
	if _world == null or not _world.has_method("is_swamp_water_tile"):
		return false
	var tile := Vector2i(
		floori(global_position.x / GameConstants.TILE_SIZE),
		floori(global_position.y / GameConstants.TILE_SIZE)
	)
	return _world.is_swamp_water_tile(tile)


## Drives the hard-biome exposure meter. Safe tiles (and biomes the player has the
## matching suit for) drain it; unprotected hazard tiles fill it and, at the cap,
## teleport the player back to the last safe tile — no death, no item loss.
func _update_exposure(delta: float) -> void:
	var hazard := _get_hazard_here()

	if hazard.is_empty() or _has_protection(hazard):
		if hazard.is_empty():
			_last_safe_position = global_position
		exposure = maxf(0.0, exposure - EXPOSURE_RECOVER * delta)
		# Unprotected biomes still surface a "danger" bar; protected ones stay calm.
		exposure_changed.emit(exposure, {} if hazard.is_empty() or exposure <= 0.0 else hazard)
		return

	exposure = minf(EXPOSURE_MAX, exposure + float(hazard.get("rate", 14.0)) * delta)
	if exposure >= EXPOSURE_MAX:
		_eject_to_safety()
		exposure = EXPOSURE_EJECT_RESET
	exposure_changed.emit(exposure, hazard)


func _get_hazard_here() -> Dictionary:
	if _world == null or not is_instance_valid(_world):
		_world = get_tree().get_first_node_in_group("world")
	if _world == null or not _world.has_method("get_hazard_at"):
		return {}
	return _world.get_hazard_at(global_position)


## True only when the matching protective suit is EQUIPPED in the armour slot —
## carrying it in the inventory is not enough.
func _has_protection(hazard: Dictionary) -> bool:
	var item_id := str(hazard.get("protection_item", ""))
	if item_id.is_empty():
		return false
	if (
		SaveManager.current_save != null
		and SaveManager.current_save.permanent_biome_access.has(item_id)
	):
		return true
	var armor := get_tree().get_first_node_in_group("armor_ui")
	if armor == null:
		return false
	# New equipment panel exposes has_protection_item (checks suit + mask);
	# fall back to the old single-slot get_equipped().
	if armor.has_method("has_protection_item"):
		return armor.has_protection_item(item_id)
	if not armor.has_method("get_equipped"):
		return false
	var equipped: Variant = armor.get_equipped()
	return equipped is Dictionary and str(equipped.get("id", "")) == item_id


func _eject_to_safety() -> void:
	if _last_safe_position != Vector2.ZERO:
		global_position = _last_safe_position
		reset_physics_interpolation()  # teleport: don't smear across the map
	velocity = Vector2.ZERO


func get_health() -> float:
	return health


func get_max_health() -> float:
	return max_health


func get_hunger() -> float:
	return hunger


func get_max_hunger() -> float:
	return max_hunger


## Sets hunger directly (used on load); clamps and notifies the HUD.
func set_hunger(value: float) -> void:
	hunger = clampf(value, 0.0, max_hunger)
	_starve_accum = 0.0
	hunger_changed.emit(hunger, max_hunger)


## Restores hunger by `amount` (eating food). Ignores non-positive amounts.
func add_hunger(amount: float) -> void:
	if amount <= 0.0:
		return
	hunger = minf(max_hunger, hunger + amount)
	hunger_changed.emit(hunger, max_hunger)


## Forest-base respawn point, set by World at world start. Also seeds the initial
## safe position so exposure ejects don't send the player to the origin.
func set_spawn_point(pos: Vector2) -> void:
	_spawn_position = pos
	if _last_safe_position == Vector2.ZERO:
		_last_safe_position = pos


## Applies combat damage. Combat can kill the player and trigger a base respawn.
func take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0 or _is_dead \
			or Time.get_ticks_msec() < _damage_invulnerable_until:
		return
	var reduced_amount := amount * (1.0 - clampf(float(_equipment_bonuses.get("damage_reduction", 0.0)), 0.0, 0.75))
	health = maxf(0.0, health - reduced_amount)
	health_changed.emit(health, max_health)
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -42), reduced_amount, Color(1.0, 0.30, 0.24))
	AudioManager.play_sfx("player_hurt")
	if health <= 0.0:
		_die()


## Starvation is deliberately non-lethal: reaching 1 HP tells the player to eat
## without making an idle or disconnected player lose their character.
func take_starvation_damage(amount: float) -> void:
	if amount <= 0.0 or health <= STARVATION_MIN_HEALTH or _is_dead:
		return
	health = maxf(STARVATION_MIN_HEALTH, health - amount)
	health_changed.emit(health, max_health)
	AudioManager.play_sfx("player_hurt")


## Plays the death animation, then respawns at base. Movement is frozen meanwhile.
func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	velocity = Vector2.ZERO
	anim.flip_h = false
	anim.speed_scale = 1.0
	if anim.sprite_frames != null and anim.sprite_frames.has_animation("rip"):
		anim.play("rip")
		await anim.animation_finished
	_respawn()
	_is_dead = false
	_idle()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


func refresh_equipment_bonuses(bonuses: Dictionary = {}) -> void:
	var previous_max := max_health
	_equipment_bonuses = bonuses.duplicate(true) if not bonuses.is_empty() else EquipmentBonusSystem.current(get_tree())
	max_health = MAX_HEALTH + float(_equipment_bonuses.get("max_health", 0.0))
	if previous_max > 0.0:
		health = clampf(health * max_health / previous_max, 0.0, max_health)
	health_changed.emit(health, max_health)


## Combat death: full heal, clear exposure, teleport to the base spawn. No item loss.
func _respawn() -> void:
	health = max_health
	exposure = 0.0
	# Refill hunger so a starvation death doesn't loop into another one on respawn.
	set_hunger(max_hunger)
	var target: Vector2 = _spawn_position if _spawn_position != Vector2.ZERO else _last_safe_position
	if target != Vector2.ZERO:
		global_position = target
		reset_physics_interpolation()  # teleport: don't smear across the map
	velocity = Vector2.ZERO
	health_changed.emit(health, max_health)


## Unit vector for the way the player is currently facing (from idle_dir).
func _facing_vector() -> Vector2:
	match idle_dir:
		UP: return Vector2.UP
		LEFT: return Vector2.LEFT
		RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN


## Public facing accessor for systems that orient actions and placed structures.
func get_facing_vector() -> Vector2:
	return _facing_vector()


func _start_dash(input_direction: Vector2) -> void:
	_dash_direction = input_direction.normalized() if input_direction.length() > 0.1 else _facing_vector()
	_dash_time = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN * (1.0 - clampf(float(_equipment_bonuses.get("dash_cooldown", 0.0)), 0.0, 0.6))
	_damage_invulnerable_until = Time.get_ticks_msec() + int(DASH_INVULNERABILITY * 1000.0)
	_recoil_velocity = Vector2.ZERO


func is_dashing() -> bool:
	return _dash_time > 0.0


## Melee swing: damages and KNOCKS BACK every "hittable" target in a frontal cone.
## Targets implement `take_hit(damage: float, knockback: Vector2)`. `power` is the
## weapon's tool power (bare hands pass 1). With `require_target` the swing only
## fires when something is actually in reach — that is how a bare-hand LMB stays
## available for mining/building. Returns true if a swing fired.
func swing_attack(power: int, require_target: bool = false) -> bool:
	return attack_with_weapon("sword", power, require_target)


func attack_with_weapon(weapon_type: String, power: int, require_target: bool = false) -> bool:
	if is_dashing() or _attack_cooldown > 0.0:
		return false
	if weapon_type == "wand":
		return _cast_arcane_bolt(power)
	var config := _weapon_config(weapon_type, power)
	var dir := _facing_vector()
	var targets := _targets_in_cone(dir, float(config["reach"]), float(config["cone_dot"]))
	if require_target and targets.is_empty():
		return false
	_attack_cooldown = ToolTierSystem.swing_interval(power) * float(config["cooldown_mult"])
	_recoil_velocity = -dir * float(config["recoil"])
	_play_combat_animation()
	var area_color := Color(0.55, 0.82, 1.0) if weapon_type == "spear" else Color(1.0, 0.72, 0.28)
	if weapon_type == "hammer":
		area_color = Color(1.0, 0.46, 0.22)
	AttackAreaFX.show_cone(get_parent(), global_position, dir, float(config["reach"]),
		acos(float(config["cone_dot"])), area_color, 0.22)
	for target: Node2D in targets:
		var to := target.global_position - global_position
		var kb_dir := to.normalized() if to.length() > 0.1 else dir
		target.take_hit(float(config["damage"]), kb_dir * float(config["knockback"]))
	return true


func _weapon_config(weapon_type: String, power: int) -> Dictionary:
	var weapon_power := float(maxi(power, 1))
	var damage_multiplier := 1.0 + float(_equipment_bonuses.get("attack_damage", 0.0))
	match weapon_type:
		"spear":
			return {"reach": SPEAR_REACH, "cone_dot": SPEAR_CONE_DOT, "damage": weapon_power * 7.5 * damage_multiplier,
				"knockback": 300.0, "recoil": 90.0, "cooldown_mult": 1.15}
		"hammer":
			return {"reach": HAMMER_REACH, "cone_dot": HAMMER_CONE_DOT, "damage": weapon_power * 11.0 * damage_multiplier,
				"knockback": 460.0, "recoil": 185.0, "cooldown_mult": 1.55}
		_:
			return {"reach": ATTACK_REACH, "cone_dot": ATTACK_CONE_DOT, "damage": weapon_power * ATTACK_DAMAGE_PER_POWER * damage_multiplier,
				"knockback": ATTACK_KNOCKBACK, "recoil": ATTACK_RECOIL, "cooldown_mult": 1.0}


func _cast_arcane_bolt(power: int) -> bool:
	var bolt := WAND_PROJECTILE_SCRIPT.new() as Node2D
	if bolt == null:
		return false
	var parent := get_tree().current_scene
	if parent == null:
		return false
	_attack_cooldown = ToolTierSystem.swing_interval(power) * 1.25
	_play_combat_animation()
	parent.add_child(bolt)
	bolt.global_position = global_position + _facing_vector() * 22.0
	bolt.setup(_facing_vector(), float(maxi(power, 1)) * 7.0 * (1.0 + float(_equipment_bonuses.get("attack_damage", 0.0))))
	return true


func _play_combat_animation() -> void:
	AudioManager.play_sfx("sword_swing")
	anim.speed_scale = 1.0
	match idle_dir:
		UP:
			anim.flip_h = false
			_play("sword_up", ["idle_up"])
		LEFT:
			anim.flip_h = true
			_play("sword_font", ["idle_font"])
		RIGHT:
			anim.flip_h = false
			_play("sword_font", ["idle_font"])
		_:
			anim.flip_h = false
			_play("sword_down", ["idle_down"])
	_attack_anim_until = Time.get_ticks_msec() + int(ATTACK_ANIM_TIME * 1000.0)


## Every "hittable" node inside the frontal attack cone, nearest first.
func _targets_in_cone(dir: Vector2, reach: float = ATTACK_REACH,
		cone_dot: float = ATTACK_CONE_DOT) -> Array[Node2D]:
	var hits: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group("hittable"):
		var target := node as Node2D
		if target == null or not target.has_method("take_hit"):
			continue
		var to: Vector2 = target.global_position - global_position
		var dist: float = to.length()
		if dist > reach:
			continue
		if dist > 0.1 and to.normalized().dot(dir) < cone_dot:
			continue  # outside the frontal cone
		hits.append(target)
	return hits


## Begins the looping swing animation for a mining/harvest tool (pickaxe → ore,
## axe → trees). Faces the mined tile and keeps the clip playing until
## `end_tool_action` is called. Driven by WorldInteractionManager while the LMB
## is held on a deposit.
func begin_tool_action(tool_type: String, target: Vector2) -> void:
	if _is_dead:
		return
	var dir: Vector2 = target - global_position
	if dir.length() > 0.1:
		_face(dir.normalized())
	_tool_action_type = tool_type
	anim.speed_scale = 1.0
	_play_tool_anim()


## Stops the tool swing and drops back to idle. No-op if no tool action is active.
func end_tool_action() -> void:
	if _tool_action_type == "":
		return
	_tool_action_type = ""
	_idle()


## Plays the pickaxe/axe swing for the current facing (flip already set by _face).
## Unknown tool types fall back to the axe clip.
func _play_tool_anim() -> void:
	var prefix: String = "pickaxe" if _tool_action_type == "pickaxe" else "axe"
	match idle_dir:
		UP:
			anim.flip_h = false
			_play(prefix + "_up", ["idle_up"])
		LEFT:
			anim.flip_h = true
			_play(prefix + "_font", ["idle_font"])
		RIGHT:
			anim.flip_h = false
			_play(prefix + "_font", ["idle_font"])
		_:
			anim.flip_h = false
			_play(prefix + "_down", ["idle_down"])


## Updates facing (idle_dir + horizontal flip) from a movement vector — no anim play.
func _face(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		idle_dir = LEFT if direction.x < 0 else RIGHT
		anim.flip_h = direction.x < 0
	elif direction.y < 0:
		idle_dir = UP
		anim.flip_h = false
	else:
		idle_dir = DOWN
		anim.flip_h = false


## Plays the movement animation for the current facing (flip already set by _face).
## The sheet has no separate walk cycle, so `run_*` doubles for both; Shift just
## speeds it up for feedback.
func _play_move_anim() -> void:
	anim.speed_scale = 1.4 if Input.is_action_pressed("run") else 1.0
	match idle_dir:
		UP:
			_play("run_up", ["idle_up"])
		LEFT, RIGHT:
			_play("run_font", ["idle_font"])
		_:
			_play("run_down", ["idle_down"])


func _idle() -> void:
	anim.speed_scale = 1.0
	match idle_dir:
		DOWN:
			anim.flip_h = false
			_play("idle_down", ["run_down"])
		UP:
			anim.flip_h = false
			_play("idle_up", ["run_up"])
		LEFT:
			anim.flip_h = true
			_play("idle_font", ["run_font"])
		RIGHT:
			anim.flip_h = false
			_play("idle_font", ["run_font"])


## Plays `anim_name` if the SpriteFrames has it; otherwise the first available
## fallback. Lets a user-authored SpriteFrames omit animations without crashing.
func _play(anim_name: String, fallbacks: Array = []) -> void:
	var frames: SpriteFrames = anim.sprite_frames
	if frames == null:
		return
	var chosen: String = anim_name
	if not frames.has_animation(chosen):
		chosen = ""
		for fb: String in fallbacks:
			if frames.has_animation(fb):
				chosen = fb
				break
	if chosen != "":
		anim.play(chosen)


func set_skin(_skin_id: String, _skin_color: Color = Color.WHITE) -> void:
	pass


func set_armor_color(_color: Color) -> void:
	pass


## Builds the player's SpriteFrames from player.png (6×10 grid of 32×32 cells).
## Returns null if the texture isn't imported yet (keeps the old look as fallback).
func _build_sprite_frames() -> SpriteFrames:
	var tex: Texture2D = load(SHEET_PATH)
	if tex == null:
		return null
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	# Walk (loops).
	_add_anim(sf, tex, "down",  ROW_WALK_DOWN, 6, 8.0, true)
	_add_anim(sf, tex, "front", ROW_WALK_SIDE, 6, 8.0, true)
	_add_anim(sf, tex, "up",    ROW_WALK_UP,   6, 8.0, true)
	# Run (loops, faster).
	_add_anim(sf, tex, "run_down",  ROW_RUN_DOWN, 6, 12.0, true)
	_add_anim(sf, tex, "run_front", ROW_RUN_SIDE, 6, 12.0, true)
	_add_anim(sf, tex, "run_up",    ROW_RUN_UP,   6, 12.0, true)
	# Attack (one-shot).
	_add_anim(sf, tex, "attack_down",  ROW_ATK_DOWN, 4, 14.0, false)
	_add_anim(sf, tex, "attack_front", ROW_ATK_SIDE, 4, 14.0, false)
	_add_anim(sf, tex, "attack_up",    ROW_ATK_UP,   4, 14.0, false)
	# Death (one-shot).
	_add_anim(sf, tex, "death", ROW_DEATH, 4, 6.0, false)
	# Idle = first frame of each walk direction.
	_add_anim(sf, tex, "idle_down",  ROW_WALK_DOWN, 1, 1.0, false)
	_add_anim(sf, tex, "idle_front", ROW_WALK_SIDE, 1, 1.0, false)
	_add_anim(sf, tex, "idle_up",    ROW_WALK_UP,   1, 1.0, false)
	return sf


## Adds one animation as `count` horizontal 32×32 frames from `row` of the sheet.
func _add_anim(sf: SpriteFrames, tex: Texture2D, anim_name: String, row: int, count: int, fps: float, loop: bool) -> void:
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i: int in range(count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * SHEET_CELL, row * SHEET_CELL, SHEET_CELL, SHEET_CELL)
		sf.add_frame(anim_name, at)

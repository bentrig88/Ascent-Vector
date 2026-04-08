extends EnemyBase

const MOVE_SPEED := 6.0
const PREFERRED_MIN := 6.0
const PREFERRED_MAX := 8.0
const FLEE_RANGE := 4.0
const FIRE_INTERVAL := 0.8
const BURST_COUNT := 3
const BURST_DELAY := 0.15
const DRONE_SEPARATION := 3.0

var _fire_timer: float = 0.0
var _state: String = "kite"  # "kite" | "flee" | "shoot"
var _prev_non_shoot_state: String = "kite"
var _burst_cancelled: bool = false

const PROJECTILE_SCENE = preload("res://scenes/weapons/projectile.tscn")

func _get_enemy_type() -> String:
	return "drone"

func _get_max_health() -> int:
	return 50

func _get_collision_layer_bit() -> int:
	return 5

func _get_health_bar_config() -> Dictionary:
	return {"color": Color(0.1, 0.3, 0.9), "width": 0.5, "height": 0.05, "y": 2.6}

func _enemy_ready() -> void:
	mass = 0.3
	EventBus.player_state_changed.connect(_on_player_state_changed)

func _on_take_damage() -> void:
	_burst_cancelled = true
	_fire_timer = 0.0

func _physics_process(delta: float) -> void:
	if knockback_cooldown > 0.0:
		knockback_cooldown -= delta

	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return

	# Stagger: frozen after being hit
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_fire_timer += delta
	if _fire_timer >= FIRE_INTERVAL:
		_fire_timer = 0.0
		_shoot()

	match _state:
		"kite":
			_do_kite(delta)
		"flee":
			_do_flee(delta)
		"shoot":
			_do_shoot(delta)

	_enforce_drone_separation()
	move_and_slide()

func _do_kite(_delta: float) -> void:
	var dist := global_position.distance_to(_player.global_position)
	if dist < FLEE_RANGE:
		_state = "flee"
		_prev_non_shoot_state = "flee"
		return

	var dir := _player.global_position - global_position
	dir.y = 0.0
	if dist < PREFERRED_MIN:
		velocity = -dir.normalized() * MOVE_SPEED
	elif dist > PREFERRED_MAX:
		velocity = dir.normalized() * MOVE_SPEED
	else:
		var perp := Vector3(-dir.z, 0.0, dir.x).normalized()
		velocity = perp * MOVE_SPEED * 0.3

func _do_flee(_delta: float) -> void:
	var dist := global_position.distance_to(_player.global_position)
	if dist >= PREFERRED_MIN:
		_state = "kite"
		_prev_non_shoot_state = "kite"
		return

	var dir := global_position - _player.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	velocity = dir.normalized() * MOVE_SPEED

func _do_shoot(_delta: float) -> void:
	velocity = Vector3.ZERO

func _shoot() -> void:
	if not _player:
		return
	_fire_burst()

func _fire_burst() -> void:
	_burst_cancelled = false
	for i in range(BURST_COUNT):
		if not is_instance_valid(self) or not _player or not is_inside_tree() or _burst_cancelled:
			return
		var spawn_pos := global_position + Vector3(0.0, 2.0, 0.0)
		var target_pos: Vector3 = _player.global_position + Vector3(0.0, 0.8, 0.0)
		var dir: Vector3 = target_pos - spawn_pos
		if dir.length_squared() < 0.01:
			dir = Vector3.FORWARD
		var proj = PROJECTILE_SCENE.instantiate()
		proj.direction = dir.normalized()
		proj.is_drone_bullet = true
		get_parent().add_child(proj)
		proj.global_position = spawn_pos
		if i < BURST_COUNT - 1:
			await get_tree().create_timer(BURST_DELAY).timeout

func _enforce_drone_separation() -> void:
	for drone in get_tree().get_nodes_in_group("enemy"):
		if drone == self or not drone is CharacterBody3D:
			continue
		if drone.get("mass") == null or drone.mass > 0.5:
			continue
		var sep: Vector3 = global_position - drone.global_position
		sep.y = 0.0
		if sep.length() < DRONE_SEPARATION and sep.length() > 0.001:
			velocity += sep.normalized() * MOVE_SPEED

func _on_player_state_changed(new_state: String) -> void:
	if new_state == "air":
		var dist := global_position.distance_to(_player.global_position) if _player else 999.0
		if dist < FLEE_RANGE + 2.0:
			_state = "flee"
			_prev_non_shoot_state = "flee"

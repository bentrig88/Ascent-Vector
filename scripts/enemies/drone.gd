extends CharacterBody3D

const MOVE_SPEED := 6.0
const PREFERRED_MIN := 6.0
const PREFERRED_MAX := 8.0
const FLEE_RANGE := 4.0
const FIRE_INTERVAL := 1.5
const DRONE_SEPARATION := 3.0

var health: int = 50
var mass: float = 0.3
var knockback_cooldown: float = 0.0

var _player: CharacterBody3D = null
var _fire_timer: float = 0.0
var _state: String = "kite"  # "kite" | "flee" | "shoot"
var _prev_non_shoot_state: String = "kite"

const PROJECTILE_SCENE = preload("res://scenes/weapons/projectile.tscn")

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 16   # Layer 5 (Drone) = bit 4 = 16
	collision_mask = 3     # Walls + Floor = 1+2

	EventBus.player_state_changed.connect(_on_player_state_changed)
	call_deferred("_find_systems")

func _find_systems() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if knockback_cooldown > 0.0:
		knockback_cooldown -= delta

	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
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
		# Move away
		velocity = -dir.normalized() * MOVE_SPEED
	elif dist > PREFERRED_MAX:
		# Move toward
		velocity = dir.normalized() * MOVE_SPEED
	else:
		# In range, slow strafe
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
	# Return to previous state after shoot frame (shoot fires via _fire_timer)

func _shoot() -> void:
	if not _player:
		return
	var proj = PROJECTILE_SCENE.instantiate()
	var dir := (_player.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	proj.direction = dir.normalized()
	proj.global_position = global_position + dir.normalized() * 0.8
	get_parent().add_child(proj)

func _enforce_drone_separation() -> void:
	for drone in get_tree().get_nodes_in_group("enemy"):
		if drone == self or not drone is CharacterBody3D:
			continue
		if drone.get("mass") == null or drone.mass > 0.5:  # only other drones (mass=0.3)
			continue
		var sep: Vector3 = global_position - drone.global_position
		sep.y = 0.0
		if sep.length() < DRONE_SEPARATION and sep.length() > 0.001:
			velocity += sep.normalized() * MOVE_SPEED

func take_damage(amount: int) -> void:
	# Drone immune to layer 6 (melee) — enforced by collision mask in hitbox
	health -= amount
	_flash_white()
	if health <= 0:
		_die()

func _die() -> void:
	var gm := get_tree().get_first_node_in_group("grid_manager")
	var over_pit := false
	if gm:
		over_pit = gm.is_over_pit(global_position)
	EventBus.enemy_died.emit("drone", global_position, over_pit)
	queue_free()

func die_in_pit() -> void:
	EventBus.enemy_died.emit("drone", global_position, true)
	queue_free()

func _flash_white() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if not mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mesh.set_surface_override_material(0, mat)
	await get_tree().process_frame
	mesh.set_surface_override_material(0, null)

func _on_player_state_changed(new_state: String) -> void:
	# Enter flee state earlier in Air Mode since player speed (7) nearly matches drone (6)
	if new_state == "air":
		var dist := global_position.distance_to(_player.global_position) if _player else 999.0
		if dist < FLEE_RANGE + 2.0:
			_state = "flee"
			_prev_non_shoot_state = "flee"

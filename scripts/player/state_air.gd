extends Node

const AIR_SPEED := 7.0
const MAX_HEIGHT := 3.0
const RISE_SPEED := 3.5
const GRAVITY := 9.8
const ENERGY_DRAIN_PER_SEC := 10.0
const FIRE_RATE := 14.0  # shots per second

var player: CharacterBody3D = null
var _fire_timer: float = 0.0
var _energy_drain_accum: float = 0.0

const PROJECTILE_SCENE = preload("res://scenes/weapons/projectile.tscn")

func enter() -> void:
	_fire_timer = 0.0
	_energy_drain_accum = 0.0
	EventBus.player_state_changed.emit("air")

func exit() -> void:
	player.velocity.y = 0.0

func physics_process(delta: float) -> void:
	_handle_movement()
	_handle_height(delta)
	_handle_energy(delta)
	_handle_facing()
	_handle_fire(delta)

func _handle_movement() -> void:
	var input := _get_move_input()
	player.velocity.x = input.x * AIR_SPEED
	player.velocity.z = input.z * AIR_SPEED

func _handle_height(delta: float) -> void:
	var thrusting: bool = Input.is_action_pressed("jetpack") and player.energy > 0

	if thrusting:
		# Rise toward max height
		var current_y := player.global_position.y
		if current_y < MAX_HEIGHT:
			player.velocity.y = RISE_SPEED
		else:
			player.velocity.y = 0.0
	else:
		# Fall with gravity
		player.velocity.y -= GRAVITY * delta
		if player.is_on_floor():
			_land()

func _handle_energy(delta: float) -> void:
	if not Input.is_action_pressed("jetpack"):
		return
	if player.infinite_energy:
		player.energy = 100
		return
	if player.energy <= 0:
		return
	_energy_drain_accum += ENERGY_DRAIN_PER_SEC * delta
	var drain := int(_energy_drain_accum)
	if drain > 0:
		_energy_drain_accum -= drain
		player.energy = max(player.energy - drain, 0)
		EventBus.player_energy_changed.emit(player.energy)

	if player.energy == 0:
		# Out of fuel — check if over pit
		var gm: Node = player.get_grid_manager()
		if gm and gm.is_over_pit(player.global_position):
			player.trigger_fall_sequence()

func _handle_facing() -> void:
	var x := Input.get_axis("aim_left", "aim_right")
	var y := Input.get_axis("aim_up", "aim_down")
	if Vector2(x, y).length_squared() > 0.04:
		player.facing_vector = Vector3(x, 0.0, y).normalized()

func _handle_fire(delta: float) -> void:
	_fire_timer += delta
	if Input.is_action_pressed("fire"):
		if _fire_timer >= 1.0 / FIRE_RATE:
			_fire_timer = 0.0
			_shoot()

const AUTO_AIM_CONE := 0.4  # dot-product threshold (~66° cone)
const AUTO_AIM_RANGE := 20.0

func _shoot() -> void:
	var origin := player.global_position + Vector3(0.0, 0.8, 0.0)
	var aim_dir: Vector3 = player.facing_vector
	var best_target: Node3D = null
	var best_score := -1.0

	# Find the best enemy in the aiming direction (prefers close + aligned)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		var to_enemy: Vector3 = enemy.global_position - origin
		var dist := to_enemy.length()
		if dist < 0.5 or dist > AUTO_AIM_RANGE:
			continue
		var flat_dir := Vector3(to_enemy.x, 0.0, to_enemy.z)
		if flat_dir.length_squared() < 0.1:
			continue
		var dot := flat_dir.normalized().dot(aim_dir)
		if dot > AUTO_AIM_CONE:
			# Score: alignment weighted, with distance bonus for closer targets
			var score := dot + (1.0 - dist / AUTO_AIM_RANGE) * 0.3
			if score > best_score:
				best_score = score
				best_target = enemy

	var proj = PROJECTILE_SCENE.instantiate()
	if best_target and is_instance_valid(best_target):
		# Aim at center mass: drones have mesh/collision offset at y+2.0, grunts at y+0.8
		var target_center: Vector3 = best_target.global_position
		var col_shape := best_target.get_node_or_null("CollisionShape3D")
		if col_shape:
			target_center += col_shape.position
		var to_target: Vector3 = target_center - origin
		proj.direction = to_target.normalized()
	else:
		proj.direction = aim_dir
	player.get_parent().add_child(proj)
	proj.global_position = origin

func _land() -> void:
	var gm = player.get_grid_manager()
	if gm and gm.is_over_pit(player.global_position):
		player.trigger_fall_sequence()
	else:
		var ground_state := player.get_node_or_null("StateGround")
		if ground_state:
			player.transition_to(ground_state)

func _get_move_input() -> Vector3:
	var x := Input.get_axis("move_left", "move_right")
	var z := Input.get_axis("move_up", "move_down")
	# Rotate input by camera Y rotation (45°) so movement is screen-relative
	var raw := Vector3(x, 0.0, z)
	return raw.rotated(Vector3.UP, deg_to_rad(45.0))

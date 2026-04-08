extends EnemyBase

const MOVE_SPEED := 3.5
const ATTACK_DAMAGE := 15
const ATTACK_COOLDOWN := 1.2
const ATTACK_STRIKE := 0.25
const ATTACK_RANGE := 1.5
const PATH_POLL_INTERVAL := 0.1
const SEPARATION_RADIUS := 1.8
const SEPARATION_FORCE := 4.0
const WANDER_SPEED := 1.5
const WANDER_PAUSE_MIN := 1.0
const WANDER_PAUSE_MAX := 3.0

var _grid_manager: Node = null
var _current_path: PackedVector2Array = []
var _path_timer: float = 0.0
var _attack_timer: float = 0.0
var _state: String = "wander"  # "wander" | "chase" | "attack"
var _surround_angle: float = 0.0
var _wander_path: PackedVector2Array = []
var _wander_pause: float = 0.0
var _attack_visual: MeshInstance3D = null
var _is_attacking: bool = false

static var _next_surround_index: int = 0

func _get_enemy_type() -> String:
	return "grunt"

func _get_max_health() -> int:
	return 80

func _get_collision_layer_bit() -> int:
	return 4

func _get_health_bar_config() -> Dictionary:
	return {"color": Color(0.9, 0.15, 0.1), "width": 0.6, "height": 0.06, "y": 1.85}

func _enemy_ready() -> void:
	add_to_group("grunt")
	mass = 1.0

	_surround_angle = _next_surround_index * TAU / 4.0 + randf_range(-0.4, 0.4)
	_next_surround_index = (_next_surround_index + 1) % 8

	# Alert area
	var alert_area := Area3D.new()
	alert_area.name = "AlertArea"
	alert_area.collision_layer = 0
	alert_area.collision_mask = 4
	var alert_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.0, 2.0, 7.0)
	alert_shape.shape = box
	alert_area.add_child(alert_shape)
	add_child(alert_area)
	alert_area.body_entered.connect(_on_alert_body_entered)
	alert_area.body_exited.connect(_on_alert_body_exited)

	if _anim_player:
		_anim_player.animation_finished.connect(_on_attack_anim_finished)

	EventBus.tile_destroyed.connect(_on_tile_destroyed)
	_create_attack_visual()

func _find_extra_systems() -> void:
	_grid_manager = get_tree().get_first_node_in_group("grid_manager")

func _create_attack_visual() -> void:
	_attack_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.3, ATTACK_RANGE)
	_attack_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.15, 0.1, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_attack_visual.set_surface_override_material(0, mat)
	_attack_visual.position = Vector3(0.0, 0.15, ATTACK_RANGE * 0.5 + 0.3)
	_attack_visual.visible = false
	add_child(_attack_visual)

func _physics_process(delta: float) -> void:
	if knockback_cooldown > 0.0:
		knockback_cooldown -= delta

	if not _player:
		_player = get_tree().get_first_node_in_group("player")

	# Check if over a pit
	if _grid_manager and _grid_manager.is_over_pit(global_position):
		die_in_pit()
		return

	# Stagger: frozen after being hit
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		return

	match _state:
		"wander":
			_do_wander(delta)
		"chase":
			_do_chase(delta)
		"attack":
			_do_attack(delta)

	# Face movement direction
	var flat_vel := Vector3(velocity.x, 0.0, velocity.z)
	if flat_vel.length_squared() > 0.01:
		rotation.y = atan2(flat_vel.x, flat_vel.z)

	move_and_slide()

func _on_take_damage() -> void:
	# Cancel attack
	_is_attacking = false
	if _attack_visual:
		_attack_visual.visible = false
	_state = "chase"

func _do_wander(delta: float) -> void:
	if _wander_pause > 0.0:
		_wander_pause -= delta
		velocity = Vector3.ZERO
		return

	if _wander_path.is_empty():
		_pick_wander_target()
		if _wander_path.is_empty():
			_wander_pause = randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
			return

	var next_grid := _wander_path[0] if _wander_path.size() == 1 else _wander_path[1]
	var target_world: Vector3 = _grid_manager.grid_to_world_center(Vector2i(int(next_grid.x), int(next_grid.y)))
	target_world.y = global_position.y

	var dir: Vector3 = (target_world - global_position)
	if dir.length_squared() < 0.1:
		if _wander_path.size() > 1:
			_wander_path = _wander_path.slice(1)
		else:
			_wander_path = PackedVector2Array()
			_wander_pause = randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
		return

	velocity = dir.normalized() * WANDER_SPEED
	_apply_separation()

func _pick_wander_target() -> void:
	if not _grid_manager:
		return
	var target_grid := Vector2i(randi_range(0, 9), randi_range(0, 9))
	if _grid_manager.is_point_solid(target_grid):
		return
	_wander_path = _grid_manager.get_nav_path(global_position, _grid_manager.grid_to_world_center(target_grid))

func _do_chase(delta: float) -> void:
	if not _player:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist <= ATTACK_RANGE:
		_state = "attack"
		_is_attacking = false
		_attack_timer = 0.0
		velocity = Vector3.ZERO
		return

	_path_timer += delta
	if _path_timer >= PATH_POLL_INTERVAL:
		_path_timer = 0.0
		_recalculate_path()

	_follow_path()
	_apply_separation()

func _do_attack(delta: float) -> void:
	if not _player:
		_exit_attack()
		_state = "chase"
		return

	velocity = Vector3.ZERO

	if not _is_attacking:
		var dir := _player.global_position - global_position
		if dir.length_squared() > 0.01:
			rotation.y = atan2(dir.x, dir.z)

	var dist := global_position.distance_to(_player.global_position)

	if not _is_attacking:
		if dist > ATTACK_RANGE * 1.5:
			_exit_attack()
			_state = "chase"
			return
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_begin_attack()

func _begin_attack() -> void:
	_is_attacking = true
	if _anim_player:
		_anim_player.stop()
		_anim_player.play("attack")

# Called by AnimationPlayer method track at t=0.8
func _on_attack_strike() -> void:
	if not _is_attacking:
		return
	if _attack_visual:
		_attack_visual.visible = true
	if _player and global_position.distance_to(_player.global_position) <= ATTACK_RANGE * 1.5:
		EventBus.player_took_damage.emit(ATTACK_DAMAGE, global_position)
	await get_tree().create_timer(ATTACK_STRIKE).timeout
	if is_instance_valid(self) and _attack_visual:
		_attack_visual.visible = false

func _on_attack_anim_finished(anim_name: String) -> void:
	if anim_name == "attack":
		_is_attacking = false
		_attack_timer = ATTACK_COOLDOWN

func _exit_attack() -> void:
	_is_attacking = false
	if _attack_visual:
		_attack_visual.visible = false
	if _anim_player and _anim_player.is_playing():
		_anim_player.stop()
	_restore_body_material()

func _recalculate_path() -> void:
	if not _grid_manager or not _player:
		return
	var offset := Vector3(cos(_surround_angle), 0, sin(_surround_angle)) * ATTACK_RANGE * 0.8
	var target := _player.global_position + offset
	_current_path = _grid_manager.get_nav_path(global_position, target)

func _follow_path() -> void:
	if _current_path.is_empty():
		velocity = Vector3.ZERO
		return

	var next_grid := _current_path[0] if _current_path.size() == 1 else _current_path[1]
	var target_world: Vector3 = _grid_manager.grid_to_world_center(Vector2i(int(next_grid.x), int(next_grid.y)))
	target_world.y = global_position.y

	var dir: Vector3 = (target_world - global_position)
	if dir.length_squared() < 0.01:
		if _current_path.size() > 1:
			_current_path = _current_path.slice(1)
		return

	velocity = dir.normalized() * MOVE_SPEED

func _apply_separation() -> void:
	var separation := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("grunt"):
		if other == self:
			continue
		var diff: Vector3 = global_position - other.global_position
		diff.y = 0.0
		var dist := diff.length()
		if dist < SEPARATION_RADIUS and dist > 0.01:
			separation += diff.normalized() * (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS
	velocity += separation * SEPARATION_FORCE

func _on_alert_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and _state == "wander":
		_state = "chase"

func _on_alert_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and _state in ["chase", "attack"]:
		_exit_attack()
		_state = "wander"
		_wander_path = PackedVector2Array()
		_wander_pause = 0.0

func _on_tile_destroyed(_grid_pos: Vector2i) -> void:
	_path_timer = PATH_POLL_INTERVAL

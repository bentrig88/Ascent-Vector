extends Entity

# --- Stats ---
var energy: int = 100
var facing_vector: Vector3 = Vector3.FORWARD
var is_invincible: bool = false
var god_mode: bool = false
var infinite_energy: bool = false

# --- State machine ---
var current_state: Node = null

# --- Internal ---
var _invincibility_timer: float = 0.0
var _grid_manager: Node = null
var _session_tracker: Node = null
var _is_input_blocked: bool = false
var _face_marker: MeshInstance3D = null
var _sword_pivot: Node3D = null
var _sword_facing_pivot: Node3D = null
var _anim_player: AnimationPlayer = null
var _body_material: Material = null

func _ready() -> void:
	add_to_group("player")
	EventBus.player_took_damage.connect(_on_player_took_damage)
	# Defer group lookups until all sibling nodes have called _ready()
	call_deferred("_find_systems")

	# Get scene nodes
	_face_marker = get_node_or_null("FaceMarker") as MeshInstance3D
	_sword_facing_pivot = get_node_or_null("SwordFacingPivot")
	_sword_pivot = get_node_or_null("SwordFacingPivot/SwordPivot")
	_anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	var body_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if body_mesh:
		_body_material = body_mesh.get_surface_override_material(0)

	# Start in ground state
	var ground_state = preload("res://scripts/player/state_ground.gd").new()
	ground_state.name = "StateGround"
	add_child(ground_state)
	ground_state.player = self

	var air_state = preload("res://scripts/player/state_air.gd").new()
	air_state.name = "StateAir"
	add_child(air_state)
	air_state.player = self

	transition_to(ground_state)

func _physics_process(delta: float) -> void:
	if knockback_cooldown > 0.0:
		knockback_cooldown -= delta

	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false

	if current_state and not _is_input_blocked:
		current_state.physics_process(delta)

	# Update face marker to show facing direction
	if _face_marker:
		_face_marker.position = Vector3(facing_vector.x * 0.35, 1.2, facing_vector.z * 0.35)

	# Rotate sword facing pivot so the blade drags behind the player
	# Skip when spin animation is playing — it controls the pivot rotation
	var is_spinning := _anim_player and _anim_player.is_playing() and _anim_player.current_animation == "spin"
	if _sword_facing_pivot and facing_vector.length_squared() > 0.01 and not is_spinning:
		var target_angle := atan2(facing_vector.x, facing_vector.z)
		_sword_facing_pivot.rotation.y = target_angle + PI  # +PI so blade trails behind

	move_and_slide()

func transition_to(new_state: Node) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func get_state(state_name: String) -> Node:
	return get_node_or_null(state_name)

func _find_systems() -> void:
	_grid_manager = get_tree().get_first_node_in_group("grid_manager")
	_session_tracker = get_tree().get_first_node_in_group("session_tracker")

func swing_sword() -> void:
	if _anim_player and _anim_player.has_animation("slam"):
		_anim_player.stop()
		_restore_body_material()
		_anim_player.play("slam")

func spin_sword() -> void:
	if _anim_player and _anim_player.has_animation("spin"):
		_anim_player.stop()
		_restore_body_material()
		_anim_player.play("spin")

func _restore_body_material() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh and _body_material:
		mesh.set_surface_override_material(0, _body_material)

func _play_hit_flash() -> void:
	if _anim_player and _anim_player.has_animation("hit"):
		# Don't interrupt slam/spin animations
		if _anim_player.is_playing() and _anim_player.current_animation in ["slam", "spin"]:
			return
		_anim_player.stop()
		_anim_player.play("hit")

func block_input() -> void:
	_is_input_blocked = true

func unblock_input() -> void:
	_is_input_blocked = false

func is_input_blocked() -> bool:
	return _is_input_blocked

func get_grid_manager() -> Node:
	return _grid_manager

func _get_max_health() -> int:
	return 100

func _get_collision_layer_bit() -> int:
	return 3  # Player layer

func trigger_fall_sequence() -> void:
	die_in_pit()

func _on_pit_fall_started() -> void:
	_is_input_blocked = true
	is_invincible = true

func _on_pit_fall_finished() -> void:
	# Apply damage after falling (unless god mode)
	if not god_mode:
		health = max(health - 50, 0)
		EventBus.player_health_changed.emit(health)
	EventBus.player_fell.emit()

	# Teleport to nearest solid tile
	if _grid_manager:
		var safe_pos: Vector3 = _grid_manager.get_nearest_solid_to_center()
		global_position = Vector3(safe_pos.x, 0.5, safe_pos.z)

	# Re-enable after respawn
	_is_falling_in_pit = false
	_is_input_blocked = false
	_invincibility_timer = 1.5
	set_collision_layer_value(_get_collision_layer_bit(), true)

	# Transition back to ground
	var ground_state := get_node_or_null("StateGround")
	if ground_state:
		transition_to(ground_state)

	# Check game over
	if health <= 0:
		var waves := 0
		var elapsed := 0.0
		if _session_tracker:
			waves = _session_tracker.waves_survived
			elapsed = _session_tracker.get_elapsed_seconds()
		EventBus.game_over.emit(waves, elapsed)

func _on_player_took_damage(damage: int, source_position: Vector3) -> void:
	if is_invincible or god_mode or health <= 0:
		return
	health = max(health - damage, 0)
	EventBus.player_health_changed.emit(health)
	_play_hit_flash()

	# Apply knockback if not in cooldown
	if knockback_cooldown <= 0.0:
		var kb_system := get_tree().get_first_node_in_group("knockback_system")
		if kb_system:
			kb_system.apply(self, 0.5, source_position)
		knockback_cooldown = 0.3

	# Check if knocked into pit
	if _grid_manager and _grid_manager.is_over_pit(global_position):
		trigger_fall_sequence()
		return

	# Check game over from damage
	if health <= 0:
		var waves := 0
		var elapsed := 0.0
		if _session_tracker:
			waves = _session_tracker.waves_survived
			elapsed = _session_tracker.get_elapsed_seconds()
		EventBus.game_over.emit(waves, elapsed)

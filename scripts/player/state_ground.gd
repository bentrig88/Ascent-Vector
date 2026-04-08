extends Node

const MOVE_SPEED := 4.0

var player: CharacterBody3D = null
var animation_lock_timer: float = 0.0
var buffered_action: String = ""


func enter() -> void:
	EventBus.player_state_changed.emit("ground")

func exit() -> void:
	animation_lock_timer = 0.0
	buffered_action = ""

func physics_process(delta: float) -> void:
	if animation_lock_timer > 0.0:
		animation_lock_timer -= delta
		if animation_lock_timer <= 0.0:
			animation_lock_timer = 0.0
			_execute_buffered()
		# Locked: no movement or rotation, only buffer attacks
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		_handle_attack_input()
		return

	_handle_movement()
	_handle_facing()
	_handle_pit_check()
	_handle_attack_input()
	_handle_jetpack_input()

func _handle_movement() -> void:
	var input := _get_move_input()
	player.velocity.x = input.x * MOVE_SPEED
	player.velocity.z = input.z * MOVE_SPEED

func _handle_facing() -> void:
	# On ground, face movement direction (not aim stick)
	var input := _get_move_input()
	if input.length_squared() > 0.04:
		player.facing_vector = input.normalized()

func _handle_attack_input() -> void:
	# Jetpack input silently discarded during animation lock
	if animation_lock_timer > 0.0:
		# Buffer slam/spin if pressed in the last 0.2s of lock
		if animation_lock_timer <= 0.2:
			if Input.is_action_just_pressed("slam"):
				buffered_action = "slam"
			elif Input.is_action_just_pressed("spin"):
				buffered_action = "spin"
		return

	if Input.is_action_just_pressed("slam"):
		_do_slam()
	elif Input.is_action_just_pressed("spin"):
		_do_spin()

func _do_slam() -> void:
	print("[Player] SLAM!")
	animation_lock_timer = 1.07  # match slam animation length
	player.swing_sword()

func _do_spin() -> void:
	print("[Player] SPIN! Energy: ", player.energy)
	if not player.infinite_energy and player.energy < 20:
		return
	if not player.infinite_energy:
		player.energy = max(player.energy - 20, 0)
		EventBus.player_energy_changed.emit(player.energy)
	animation_lock_timer = 0.6
	player.spin_sword()
	# SlamHitbox is activated via AnimationPlayer method call track in the spin animation

func _execute_buffered() -> void:
	if buffered_action == "slam":
		_do_slam()
	elif buffered_action == "spin":
		_do_spin()
	buffered_action = ""

func _handle_jetpack_input() -> void:
	if animation_lock_timer > 0.0:
		return
	if Input.is_action_just_pressed("jetpack"):
		var air_state := player.get_node_or_null("StateAir")
		if air_state:
			player.transition_to(air_state)

func _handle_pit_check() -> void:
	var gm: Node = player.get_grid_manager()
	if gm and gm.is_over_pit(player.global_position):
		player.trigger_fall_sequence()

func _get_move_input() -> Vector3:
	var x := Input.get_axis("move_left", "move_right")
	var z := Input.get_axis("move_up", "move_down")
	# Rotate input by camera Y rotation (45°) so movement is screen-relative
	var raw := Vector3(x, 0.0, z)
	return raw.rotated(Vector3.UP, deg_to_rad(45.0))

func _get_aim_input() -> Vector2:
	var x := Input.get_axis("aim_left", "aim_right")
	var y := Input.get_axis("aim_up", "aim_down")
	return Vector2(x, y)

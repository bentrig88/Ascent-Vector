extends CharacterBody3D

const MOVE_SPEED := 3.5
const ATTACK_DAMAGE := 15
const ATTACK_COOLDOWN := 1.2
const ATTACK_RANGE := 1.5
const PATH_POLL_INTERVAL := 0.1
const SEPARATION_RADIUS := 1.8
const SEPARATION_FORCE := 4.0

var health: int = 80
var mass: float = 1.0
var knockback_cooldown: float = 0.0

var _player: CharacterBody3D = null
var _grid_manager: Node = null
var _current_path: PackedVector2Array = []
var _path_timer: float = 0.0
var _attack_timer: float = 0.0
var _state: String = "idle"  # "idle" | "chase" | "attack"
var _surround_angle: float = 0.0  # unique offset angle per grunt

static var _next_surround_index: int = 0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("grunt")
	collision_layer = 8    # Layer 4 (Grunt) = bit 3 = 8
	collision_mask = 7     # Walls + Floor + Player = 1+2+4

	# Assign a surround angle so grunts approach from different directions
	_surround_angle = _next_surround_index * TAU / 4.0 + randf_range(-0.4, 0.4)
	_next_surround_index = (_next_surround_index + 1) % 8

	# Alert area: 5x5 tiles = 10x10 world units
	var alert_area := Area3D.new()
	alert_area.name = "AlertArea"
	alert_area.collision_layer = 0
	alert_area.collision_mask = 4  # Player layer
	var alert_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 2.0, 10.0)
	alert_shape.shape = box
	alert_area.add_child(alert_shape)
	add_child(alert_area)
	alert_area.body_entered.connect(_on_alert_body_entered)

	EventBus.tile_destroyed.connect(_on_tile_destroyed)
	call_deferred("_find_systems")

func _find_systems() -> void:
	_grid_manager = get_tree().get_first_node_in_group("grid_manager")
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if knockback_cooldown > 0.0:
		knockback_cooldown -= delta

	if not _player:
		_player = get_tree().get_first_node_in_group("player")

	match _state:
		"idle":
			velocity = Vector3.ZERO
		"chase":
			_do_chase(delta)
		"attack":
			_do_attack(delta)

	move_and_slide()

func _do_chase(delta: float) -> void:
	if not _player:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist <= ATTACK_RANGE:
		_state = "attack"
		velocity = Vector3.ZERO
		return

	# Pathfinding poll
	_path_timer += delta
	if _path_timer >= PATH_POLL_INTERVAL:
		_path_timer = 0.0
		_recalculate_path()

	_follow_path()
	_apply_separation()

func _do_attack(delta: float) -> void:
	if not _player:
		_state = "chase"
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist > ATTACK_RANGE * 1.5:
		_state = "chase"
		return

	velocity = Vector3.ZERO
	_apply_separation()
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = ATTACK_COOLDOWN
		EventBus.player_took_damage.emit(ATTACK_DAMAGE, global_position)

func _recalculate_path() -> void:
	if not _grid_manager or not _player:
		return
	# Aim for an offset position around the player so grunts surround it
	var offset := Vector3(cos(_surround_angle), 0, sin(_surround_angle)) * ATTACK_RANGE * 0.8
	var target := _player.global_position + offset
	_current_path = _grid_manager.get_nav_path(global_position, target)

func _follow_path() -> void:
	if _current_path.is_empty():
		# No path — move directly toward player
		if _player:
			var dir: Vector3 = (_player.global_position - global_position)
			dir.y = 0.0
			if dir.length_squared() > 0.01:
				velocity = dir.normalized() * MOVE_SPEED
		return

	# Current path is in grid coords; convert to world
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

func take_damage(amount: int) -> void:
	health -= amount
	_flash_white()
	if health <= 0:
		_die()

func _die() -> void:
	var gm := get_tree().get_first_node_in_group("grid_manager")
	var over_pit := false
	if gm:
		over_pit = gm.is_over_pit(global_position)
	EventBus.enemy_died.emit("grunt", global_position, over_pit)
	queue_free()

func die_in_pit() -> void:
	EventBus.enemy_died.emit("grunt", global_position, true)
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

func _on_alert_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and _state == "idle":
		_state = "chase"

func _on_tile_destroyed(_grid_pos: Vector2i) -> void:
	_path_timer = PATH_POLL_INTERVAL

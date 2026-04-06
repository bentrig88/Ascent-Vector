extends Node

const GRUNT_SCENE = preload("res://scenes/enemies/grunt.tscn")
const DRONE_SCENE = preload("res://scenes/enemies/drone.tscn")
const SPAWN_DELAY := 3.0
const MIN_SPAWN_DIST := 8.0
const MAX_ENEMIES := 8

var wave_number: int = 0
var enemies_alive: int = 0

var _spawn_timer: float = 0.0
var _waiting_for_spawn: bool = false
var _game_over: bool = false

func _ready() -> void:
	add_to_group("wave_manager")
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	if _waiting_for_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_waiting_for_spawn = false
			start_next_wave()

func start_next_wave() -> void:
	if _game_over:
		return
	wave_number += 1
	var composition := _get_wave_composition(wave_number)
	print("[WaveManager] Starting wave ", wave_number, " composition: ", composition)
	_spawn_wave(composition)
	EventBus.wave_started.emit(wave_number)

func _get_wave_composition(wave: int) -> Dictionary:
	# W1: 4G, W2: 3G+1D, W3: 2G+2D, W4+: +1 alternating (grunt on odd, drone on even)
	var grunts := 0
	var drones := 0
	match wave:
		1: grunts = 4; drones = 0
		2: grunts = 3; drones = 1
		3: grunts = 2; drones = 2
		_:
			grunts = 2
			drones = 2
			var bonus := wave - 3
			if bonus % 2 == 1:
				@warning_ignore("integer_division")
				grunts += (bonus + 1) / 2
			else:
				@warning_ignore("integer_division")
				drones += bonus / 2
	var total := grunts + drones
	if total > MAX_ENEMIES:
		var scale := float(MAX_ENEMIES) / total
		grunts = int(grunts * scale)
		drones = MAX_ENEMIES - grunts
	return {"grunts": grunts, "drones": drones}

func _spawn_wave(composition: Dictionary) -> void:
	var spawn_points := _get_valid_spawn_points()
	print("[WaveManager] Found ", spawn_points.size(), " valid spawn points")
	var spawn_index := 0
	enemies_alive = 0

	for _i in range(composition.grunts):
		if spawn_index >= spawn_points.size():
			break
		var grunt := GRUNT_SCENE.instantiate()
		get_parent().add_child(grunt)
		grunt.global_position = spawn_points[spawn_index]
		enemies_alive += 1
		spawn_index += 1

	for _i in range(composition.drones):
		if spawn_index >= spawn_points.size():
			var fallback_drone := DRONE_SCENE.instantiate()
			get_parent().add_child(fallback_drone)
			fallback_drone.global_position = Vector3(randf_range(-8, 8), 2.0, randf_range(-8, 8))
			enemies_alive += 1
			continue
		var drone := DRONE_SCENE.instantiate()
		var sp := spawn_points[spawn_index]
		get_parent().add_child(drone)
		drone.global_position = Vector3(sp.x, 2.0, sp.z)
		enemies_alive += 1
		spawn_index += 1

	EventBus.enemy_count_changed.emit(enemies_alive)

func _get_valid_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var player := get_tree().get_first_node_in_group("player")
	var player_pos: Vector3 = player.global_position if player else Vector3.ZERO
	var gm := get_tree().get_first_node_in_group("grid_manager")
	if not gm:
		return points

	# Edge tiles: x or z at 0 or 9
	for x in [0, 9]:
		for z in range(10):
			_try_add_spawn(Vector2i(x, z), player_pos, gm, points)
	for z in [0, 9]:
		for x in range(1, 9):
			_try_add_spawn(Vector2i(x, z), player_pos, gm, points)

	points.shuffle()
	return points

func _try_add_spawn(gp: Vector2i, player_pos: Vector3, gm: Node, out: Array[Vector3]) -> void:
	if gm.is_point_solid(gp) or gm.is_over_pit(gm.grid_to_world_center(gp)):
		return
	var world: Vector3 = gm.grid_to_world_center(gp)
	if world.distance_to(player_pos) >= MIN_SPAWN_DIST:
		out.append(Vector3(world.x, 0.5, world.z))

func _on_enemy_died(_type: String, _pos: Vector3, _over_pit: bool) -> void:
	enemies_alive = max(enemies_alive - 1, 0)
	EventBus.enemy_count_changed.emit(enemies_alive)
	if enemies_alive == 0:
		EventBus.wave_cleared.emit(wave_number)
		_waiting_for_spawn = true
		_spawn_timer = SPAWN_DELAY

func _on_game_over(_waves: int, _elapsed: float) -> void:
	_game_over = true
	_waiting_for_spawn = false

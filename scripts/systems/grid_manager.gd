extends Node

const GRID_SIZE := Vector2i(10, 10)
const CELL_SIZE := 2.0
const GRID_ORIGIN := Vector3(-10.0, 0.0, -10.0)  # world pos of grid cell (0,0)

var _astar: AStarGrid2D
var _pit_positions: Dictionary = {}  # Vector2i -> bool

func _ready() -> void:
	add_to_group("grid_manager")
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, GRID_SIZE.x, GRID_SIZE.y)
	_astar.cell_size = Vector2(1, 1)  # Use raw grid indices; we convert to world ourselves
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()

	EventBus.tile_destroyed.connect(_on_tile_destroyed)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	var local := world_pos - GRID_ORIGIN
	return Vector2i(int(local.x / CELL_SIZE), int(local.z / CELL_SIZE))

func grid_to_world_center(grid_pos: Vector2i) -> Vector3:
	return GRID_ORIGIN + Vector3(
		grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5,
		0.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE * 0.5
	)

func is_point_solid(grid_pos: Vector2i) -> bool:
	if not _astar.is_in_boundsv(grid_pos):
		return false
	return _astar.is_point_solid(grid_pos)

func is_over_pit(world_pos: Vector3) -> bool:
	var gp := world_to_grid(world_pos)
	if not _astar.is_in_boundsv(gp):
		return true  # outside the grid counts as a pit
	return _pit_positions.has(gp)

func _clamp_grid(gp: Vector2i) -> Vector2i:
	return Vector2i(clampi(gp.x, 0, GRID_SIZE.x - 1), clampi(gp.y, 0, GRID_SIZE.y - 1))

func get_nav_path(from_world: Vector3, to_world: Vector3) -> PackedVector2Array:
	var from_grid := _clamp_grid(world_to_grid(from_world))
	var to_grid := _clamp_grid(world_to_grid(to_world))
	if _astar.is_point_solid(from_grid) or _astar.is_point_solid(to_grid):
		return PackedVector2Array()
	return _astar.get_point_path(from_grid, to_grid)

func get_nearest_solid_to_center() -> Vector3:
	var center := Vector2i(GRID_SIZE.x / 2, GRID_SIZE.y / 2)
	var best_dist := INF
	var best_pos := grid_to_world_center(center)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var gp := Vector2i(x, y)
			if not is_point_solid(gp) and not _pit_positions.has(gp):
				var dist := float((gp - center).length_squared())
				if dist < best_dist:
					best_dist = dist
					best_pos = grid_to_world_center(gp)

	return best_pos

func destroy_tile(grid_pos: Vector2i) -> void:
	_astar.set_point_solid(grid_pos, true)
	_pit_positions[grid_pos] = true

func _on_tile_destroyed(grid_pos: Vector2i) -> void:
	destroy_tile(grid_pos)
	_spawn_pit(grid_pos)

func _spawn_pit(grid_pos: Vector2i) -> void:
	var pit := Area3D.new()
	pit.name = "Pit_%d_%d" % [grid_pos.x, grid_pos.y]
	pit.collision_layer = 256  # Layer 8 (bit 8 = 256)
	pit.collision_mask = 12    # Player(4) + Grunt(8)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CELL_SIZE, 0.5, CELL_SIZE)
	shape_node.shape = box
	pit.add_child(shape_node)

	get_tree().current_scene.add_child(pit)
	var world_pos := grid_to_world_center(grid_pos)
	pit.global_position = Vector3(world_pos.x, -0.5, world_pos.z)
	pit.body_entered.connect(_on_pit_body_entered.bind(pit))

func _on_pit_body_entered(body: Node3D, _pit: Area3D) -> void:
	if body.has_method("trigger_fall_sequence"):
		body.trigger_fall_sequence()
	elif body.has_method("die_in_pit"):
		body.die_in_pit()

extends Node3D

const FLOOR_TILE_SCENE = preload("res://scenes/environment/floor_tile.tscn")
const GRID_SIZE := 10
const CELL_SIZE := 2.0
# Grid origin: tile (0,0) sits at world (-10, 0, -10)
const GRID_ORIGIN_X := -10.0
const GRID_ORIGIN_Z := -10.0

@onready var floor_anchor: Node3D = $FloorAnchor

func _ready() -> void:
	add_to_group("room")
	_build_walls()
	_spawn_floor_tiles()

func _spawn_floor_tiles() -> void:
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var tile: StaticBody3D = FLOOR_TILE_SCENE.instantiate()
			tile.grid_position = Vector2i(x, z)
			tile.position = Vector3(
				GRID_ORIGIN_X + x * CELL_SIZE + CELL_SIZE * 0.5,
				-0.25,
				GRID_ORIGIN_Z + z * CELL_SIZE + CELL_SIZE * 0.5
			)
			floor_anchor.add_child(tile)

func _build_walls() -> void:
	_make_wall("WallNorth", Vector3(0, 2, -10.5), Vector3(22, 4, 1), true)
	_make_wall("WallSouth", Vector3(0, 2,  10.5), Vector3(22, 4, 1), false)
	_make_wall("WallEast",  Vector3(10.5, 2,  0), Vector3(1, 4, 22), false)
	_make_wall("WallWest",  Vector3(-10.5, 2, 0), Vector3(1, 4, 22), true)

func _make_wall(wall_name: String, pos: Vector3, size: Vector3, show_mesh: bool = true) -> void:
	var wall := StaticBody3D.new()
	wall.name = wall_name
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = pos

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	wall.add_child(col)

	if show_mesh:
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mesh.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.25, 0.4)
		mesh.set_surface_override_material(0, mat)
		wall.add_child(mesh)

	add_child(wall)

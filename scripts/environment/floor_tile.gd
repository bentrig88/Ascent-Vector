extends StaticBody3D

@export var grid_position: Vector2i = Vector2i.ZERO

var tile_hp: int = 2

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	# Give tiles a distinct teal-grey color
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.55)
	mesh_instance.set_surface_override_material(0, mat)
	_create_outline()

func _create_outline() -> void:
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.12, 0.3, 0.3)
	var thickness := 0.04
	var tile_size := 2.0
	var half := tile_size / 2.0
	var height := 0.25  # flush with tile top surface

	# 4 edges: North, South, East, West
	var edges := [
		Vector3(0, height, -half), Vector3(tile_size, thickness, thickness),  # North
		Vector3(0, height, half),  Vector3(tile_size, thickness, thickness),  # South
		Vector3(-half, height, 0), Vector3(thickness, thickness, tile_size),  # West
		Vector3(half, height, 0),  Vector3(thickness, thickness, tile_size),  # East
	]

	for i in range(4):
		var edge := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = edges[i * 2 + 1]
		edge.mesh = box
		edge.position = edges[i * 2]
		edge.set_surface_override_material(0, edge_mat)
		add_child(edge)

func take_slam_damage() -> void:
	tile_hp -= 1
	EventBus.tile_damaged.emit(grid_position, tile_hp)
	if tile_hp == 1:
		_apply_crack_visual()
	elif tile_hp <= 0:
		_destroy()

func _apply_crack_visual() -> void:
	# Tint the tile darker to indicate damage
	if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
		var mat := mesh_instance.get_surface_override_material(0)
		if mat:
			mat = mat.duplicate()
			(mat as StandardMaterial3D).albedo_color = Color(0.45, 0.35, 0.25)
			mesh_instance.set_surface_override_material(0, mat)
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.35, 0.25)
		mesh_instance.set_surface_override_material(0, mat)

func _destroy() -> void:
	# Hide all visuals
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = false
		elif child is CollisionShape3D:
			child.disabled = true
	EventBus.tile_destroyed.emit(grid_position)
	# Keep node alive so pits can reference grid_position; GridManager handles pit spawn

extends Node3D

@export var bar_color: Color = Color(0.9, 0.15, 0.1)
@export var bar_width: float = 0.6
@export var bar_height: float = 0.06
@export var max_health: int = 100

var _fill: MeshInstance3D = null
var _bg: MeshInstance3D = null

func _ready() -> void:
	# Background
	_bg = MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width + 0.04, bar_height + 0.02)
	_bg.mesh = bg_mesh
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.1)
	bg_mat.no_depth_test = true
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.render_priority = 1
	_bg.set_surface_override_material(0, bg_mat)
	add_child(_bg)

	# Fill
	_fill = MeshInstance3D.new()
	var fg_mesh := QuadMesh.new()
	fg_mesh.size = Vector2(bar_width, bar_height)
	_fill.mesh = fg_mesh
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = bar_color
	fg_mat.no_depth_test = true
	fg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_mat.render_priority = 2
	_fill.set_surface_override_material(0, fg_mat)
	add_child(_fill)

func update_health(current: int) -> void:
	if not _fill:
		return
	var ratio := float(current) / float(max_health)
	var fill_mesh := _fill.mesh as QuadMesh
	fill_mesh.size.x = bar_width * ratio
	fill_mesh.center_offset = Vector3(-bar_width * (1.0 - ratio) * 0.5, 0.0, 0.0)

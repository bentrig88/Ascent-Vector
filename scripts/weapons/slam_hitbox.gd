extends Area3D

var _active_timer: float = 0.0
var _is_active: bool = false
var _player: CharacterBody3D = null
var _visual: MeshInstance3D = null

func _ready() -> void:
	collision_layer = 32   # Layer 6 (PlayerMelee) = bit 5 = 32
	collision_mask = 26    # Floor + Grunt + Drone = 2+8+16 = 26
	monitoring = false
	body_entered.connect(_on_body_entered)
	call_deferred("_find_player")

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")

	# Create a visual indicator matching the collision shape
	var col_shape := get_node_or_null("CollisionShape3D")
	if col_shape and col_shape.shape is BoxShape3D:
		_visual = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = (col_shape.shape as BoxShape3D).size
		_visual.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.3, 0.1, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_visual.set_surface_override_material(0, mat)
		_visual.position = col_shape.position
		_visual.visible = false
		add_child(_visual)

func activate(duration: float) -> void:
	_active_timer = duration
	_is_active = true
	monitoring = true
	if _visual:
		_visual.visible = true
	# Screen shake on impact
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if _player:
		var cam := _player.get_node_or_null("ProxyCamera")
		if cam and cam.has_method("start_shake"):
			cam.start_shake(0.15, 0.15)

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		_is_active = false
		monitoring = false
		if _visual:
			_visual.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not _is_active:
		return
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if not _player:
		return
	# Floor tile hit — damage directly
	if body.has_method("take_slam_damage"):
		body.take_slam_damage()
		return

	# Enemy hit
	if body.has_method("take_damage"):
		body.take_damage(40)

	# Knockback
	var kb_system := get_tree().get_first_node_in_group("knockback_system")
	if kb_system:
		kb_system.apply(body, 2.5, _player.global_position)

func _damage_tile_at(grid_pos: Vector2i) -> void:
	# Find the tile node by grid_position
	var room := get_tree().get_first_node_in_group("room")
	if not room:
		return
	var floor_anchor := room.get_node_or_null("FloorAnchor")
	if not floor_anchor:
		return
	for tile in floor_anchor.get_children():
		if tile.has_method("take_slam_damage") and tile.grid_position == grid_pos:
			tile.take_slam_damage()
			break
